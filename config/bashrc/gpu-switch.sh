#!/bin/bash
# gpu-switch - Control de la dGPU NVIDIA MX250 via sysfs (driver nvidia)
# Solo driver nvidia: nouveau queda bloqueado por fix-gpu.
#   gpu-switch status          estado actual de la dGPU
#   gpu-switch off             apaga la dGPU (d3cold, cero consumo)
#   gpu-switch on              reactiva la dGPU con driver nvidia
#   gpu-switch offload <cmd>   ejecuta <cmd> con PRIME offload a la dGPU
# Uso: sudo gpu-switch <status|off|on|offload <cmd>>
set -e

DGPU() { grep -l 0x030200 /sys/bus/pci/devices/*/class 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true; }

info() {
    local d="$1" bd dr="" c s
    bd="$(basename "$d")"
    for x in /sys/bus/pci/drivers/*/; do
        [ -e "$x/$bd" ] && dr="$(basename "$x")" && break
    done
    c="$(cat "$d/power/control" 2>/dev/null || echo auto)"
    s="$(cat "$d/power/runtime_status" 2>/dev/null || echo fuera)"
    echo "dGPU $bd  driver:${dr:-ninguno}  estado:$s  (power/control=$c)"
}

case "${1:-status}" in

status)
    d="$(DGPU)"
    [ -n "$d" ] && info "$d" || echo "dGPU fuera del bus (D3cold). Reactivar: sudo gpu-switch on"
    ;;

off)
    d="$(DGPU)"
    [ -n "$d" ] || { echo "dGPU ya fuera del bus"; exit 0; }
    bd="$(basename "$d")"
    for x in /sys/bus/pci/drivers/*/; do
        [ -e "$x/$bd" ] && echo "$bd" > "/sys/bus/pci/drivers/$(basename "$x")/unbind" 2>/dev/null || true
    done
    echo on > "$d/power/control" 2>/dev/null || true
    echo 1 > "$d/remove"
    echo "dGPU apagada (D3cold). Reactivar: sudo gpu-switch on"
    ;;

on)
    d="$(DGPU)"
    if [ -n "$d" ]; then
        info "$d"
        echo "   dGPU ya presente en el bus"
        exit 0
    fi
    echo "Reactivar dGPU..."
    modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm 2>/dev/null || true
    echo 1 > /sys/bus/pci/rescan
    for i in $(seq 1 20); do
        d="$(DGPU)"; [ -n "$d" ] && break; sleep 0.2
    done
    [ -n "$d" ] || { echo "ERROR: la dGPU no reaparece en el bus"; exit 1; }
    bd="$(basename "$d")"
    echo nvidia > "$d/driver_override" 2>/dev/null || true
    [ -e "/sys/bus/pci/drivers/nvidia/$bd" ] || echo "$bd" > /sys/bus/pci/drivers_probe 2>/dev/null || true
    echo on > "$d/power/control" 2>/dev/null || true
    info "$d"
    ;;

offload)
    shift
    [ $# -gt 0 ] || { echo "Uso: gpu-switch offload <comando> [args...]"; exit 1; }
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
    ;;

*)
    echo "Uso: sudo gpu-switch <status|off|on|offload <cmd>>"
    exit 1
    ;;
esac