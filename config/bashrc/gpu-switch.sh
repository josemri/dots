#!/bin/bash
# gpu-switch - Control de la dGPU (NVIDIA MX250/GeForce) desde sysfs
#
# La dGPU solo sirve para offload/compute; la pantalla siempre va por Intel
# i915. Usa SOLO interfaces del kernel (sysfs), sin instalar nada:
#   gpu-switch status          estado actual de la dGPU
#   gpu-switch off             apaga la dGPU (d3cold, cero consumo)
#   gpu-switch on              re-activa la dGPU con nouveau (libre)
#   gpu-switch nvidia          usa driver NVIDIA propietario (si instalado)
#   gpu-switch offload <cmd>   ejecuta <cmd> con PRIME offload a la dGPU
#
# Uso: sudo gpu-switch <status|off|on|nvidia|offload <cmd>>
set -e

find_dgpu() {
    grep -rl 0x030200 /sys/bus/pci/devices/*/class 2>/dev/null | head -1 | xargs dirname 2>/dev/null
}

dgpu_state() {
    # rellena DGPU_PATH/BDF, DRIVER, CONTROL, POWER_C; devuelve 1 si no hay dGPU
    DGPU_PATH="$(find_dgpu)"
    [ -n "$DGPU_PATH" ] || { echo "ERROR: dGPU NVIDIA (0x030200) no presente en el bus" >&2; return 1; }
    DGPU_BDF="$(basename "$DGPU_PATH")"
    DRIVER=""
    for d in /sys/bus/pci/drivers/*/; do
        [ -e "$d/$DGPU_BDF" ] && DRIVER="$(basename "$d")" && break
    done
    CONTROL="$(cat "$DGPU_PATH/power/control" 2>/dev/null || echo "auto")"
    POWER_C="$(cat "$DGPU_PATH/power/runtime_status" 2>/dev/null || echo "fuera")"
    MODULES="$(lsmod | awk '$1 ~ /^nvidia/ || $1 == "nouveau" { printf "%s ", $1 }')"
}

show() {
    dgpu_state || true
    echo "== dGPU $DGPU_BDF     driver: ${DRIVER:-ninguno}     estado: $POWER_C   (power/control=$CONTROL) =="
    echo "   Modulos graficos cargados: ${MODULES:-ninguno}"
}

case "${1:-status}" in

status)
    show
    ;;

off)
    echo "== Apagando dGPU (d3cold) =="
    if ! dgpu_state 2>/dev/null; then
        echo "   dGPU ya fuera del bus"
        exit 0
    fi
    if [ -e "$DGPU_PATH/remove" ]; then
        [ -n "$DRIVER" ] && echo "$DGPU_BDF" > "/sys/bus/pci/drivers/$DRIVER/unbind" 2>/dev/null || true
        echo on > "$DGPU_PATH/power/control" 2>/dev/null || true
        echo 1 > "$DGPU_PATH/remove" || { echo "ERROR: no se pudo remover $DGPU_BDF"; exit 1; }
        echo "   dGPU $DGPU_BDF removida del bus (d3cold, cero consumo)."
        echo "   Recuperar: sudo gpu-switch on"
    else
        echo "   dGPU ya fuera del bus"
    fi
    ;;

on)
    echo "== Activando dGPU con nouveau (libre) =="
    dgpu_state 2>/dev/null || true
    if [ -n "$DGPU_PATH" ] && [ "$DRIVER" = "nouveau" ]; then
        echo "   ya activa con nouveau"
        show; exit 0
    fi
    if [ -z "$DGPU_PATH" ]; then
        echo "   rescan del bus PCI..."
        echo 1 > /sys/bus/pci/rescan
        dgpu_state 2>/dev/null || true
        [ -n "$DGPU_PATH" ] || { echo "ERROR: la dGPU no vuelve al bus tras el rescan"; exit 1; }
    fi
    if [ -n "$DRIVER" ] && [ "$DRIVER" != "pcieport" ]; then
        echo "   desvinculando $DRIVER..."
        { rmmod "$DRIVER" 2>/dev/null || echo "$DGPU_BDF" > "/sys/bus/pci/drivers/$DRIVER/unbind" 2>/dev/null; } || true
        dgpu_state 2>/dev/null || true
    fi
    modprobe nouveau 2>/dev/null || true
    echo on > "$DGPU_PATH/power/control" 2>/dev/null || true
    echo nouveau > "$DGPU_PATH/driver_override"
    echo "$DGPU_BDF" > /sys/bus/pci/drivers_probe
    echo "   dGPU activa con nouveau"
    show
    ;;

nvidia)
    echo "== Activando dGPU con NVIDIA (propietario) =="
    modprobe -n nvidia 2>/dev/null || { echo "ERROR: driver NVIDIA no instalado."; echo "   sudo apt install nvidia-kernel-dkms"; exit 1; }
    dgpu_state 2>/dev/null || true
    if [ -n "$DGPU_PATH" ] && [ "$DRIVER" = "nvidia" ]; then
        echo "   ya activa con nvidia"
        show; exit 0
    fi
    if [ -z "$DGPU_PATH" ]; then
        echo "   rescan del bus PCI..."
        echo 1 > /sys/bus/pci/rescan
        dgpu_state 2>/dev/null || true
        [ -n "$DGPU_PATH" ] || { echo "ERROR: la dGPU no vuelve al bus tras el rescan"; exit 1; }
    fi
    if [ -n "$DRIVER" ] && [ "$DRIVER" != "pcieport" ]; then
        echo "   desvinculando $DRIVER..."
        { rmmod "$DRIVER" 2>/dev/null || echo "$DGPU_BDF" > "/sys/bus/pci/drivers/$DRIVER/unbind" 2>/dev/null; } || true
        dgpu_state 2>/dev/null || true
    fi
    for m in nvidia nvidia_modeset nvidia_drm nvidia_uvm; do modprobe "$m" 2>/dev/null || true; done
    echo on > "$DGPU_PATH/power/control" 2>/dev/null || true
    echo nvidia > "$DGPU_PATH/driver_override"
    echo "$DGPU_BDF" > /sys/bus/pci/drivers_probe
    echo "   dGPU activa con nvidia"
    show
    ;;

offload)
    shift
    [ $# -gt 0 ] || { echo "Uso: gpu-switch offload <comando> [args...]"; exit 1; }
    lsmod | grep -qE '^nvidia ' && {
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
    } || { lsmod | grep -qE '^nouveau ' && export DRI_PRIME=1; }
    exec "$@"
    ;;

*)
    echo "Uso: sudo gpu-switch <status|off|on|nvidia|offload <cmd>>"
    exit 1
    ;;
esac