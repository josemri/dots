#!/bin/bash
# fix-gpu - Fix NVIDIA GeForce MX250 (TU117) para ASUS UX481FL
#
# Estrategia: nvidia NO carga al boot (carga bajo demanda). La dGPU se activa
# solo cuando algo la necesita (Xorg PRIME, CUDA, monitor externo). Esto
# acelera el boot eliminando ~7s de modprobe de módulos nvidia del critical chain.
#
# nvidia-persistenced se auto-inicia via udev cuando el modulo nvidia carga,
# evitando el crash RRTellChanged (remove event de card1 durante init de X).
#
# Re-ejecutable / idempotente. No reinstala nvidia si ya está en la última versión.
# Uso: sudo bash fix-gpu.sh [--rollback]
set -e

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

GRUB=/etc/default/grub
MOD=/etc/modprobe.d/nvidia.conf
PERSIST=/etc/systemd/system/nvidia-persistenced.service.d/10-fix-gpu.conf
UDRULE=/etc/udev/rules.d/99-gpu-mx250.rules
PERSUD=/etc/udev/rules.d/91-nvidia-persistenced.rules

rollback() {
    echo "== Rollback fix GPU =="
    [ -f "$GRUB.bak-gpu-fix" ] && { cp -a "$GRUB.bak-gpu-fix" "$GRUB"; rm -f "$GRUB.bak-gpu-fix"; update-grub 2>/dev/null || true; echo "   GRUB restaurado"; }
    rm -f "$MOD" "$UDRULE" "$PERSUD" "$PERSIST"
    rmdir /etc/systemd/system/nvidia-persistenced.service.d 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    update-initramfs -u 2>/dev/null || true
    udevadm control --reload-rules 2>/dev/null || true
    echo "   modprobe/persistenced/udev recuperados"
    echo "   REINICIA para aplicar."
    exit 0
}
[ "${1:-}" = "--rollback" ] && rollback

echo "== Fix GPU MX250 (TU117) =="

# 1) GRUB: root ports PCIe nunca en D3 (causa del cuelgue)
if grep -q "pcie_port_pm=off" "$GRUB" 2>/dev/null; then
    echo "   GRUB: pcie_port_pm=off ya presente"
else
    cp -a "$GRUB" "$GRUB.bak-gpu-fix"
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB" 2>/dev/null; then
        sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"$/\1 pcie_port_pm=off"/' "$GRUB"
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="pcie_port_pm=off"' >> "$GRUB"
    fi
    grep -q "pcie_port_pm=off" "$GRUB" || { echo "ERROR: no se pudo editar $GRUB"; exit 1; }
    update-grub 2>/dev/null || true
    echo "   GRUB: pcie_port_pm=off anadido"
fi

# 2) modprobe.d: nouveau fuera, nvidia con KMS
cat > "$MOD" << 'EOF'
# NVIDIA MX250: nouveau no sirve sin blob GSP Turing en libre
blacklist nouveau
# KMS/atomic necesario para Wayland (nombre Debian: nvidia-current-drm)
options nvidia-current-drm modeset=1
EOF
echo "   modprobe: nouveau fuera, KMS nvidia activo"

# 3) ELIMINAR nvidia de modules-load.d (carga bajo demanda, no al boot)
rm -f /etc/modules-load.d/nvidia.conf 2>/dev/null || true
echo "   modules-load: nvidia ELIMINADO del boot (carga bajo demanda)"

# 4) nvidia-persistenced: NO arranca al boot.
#    Se auto-inicia via udev cuando el modulo nvidia carga en cualquier momento.
#    El daemon mantiene la GPU inicializada/activa, evitando el remove event
#    de card1 que provoca el segfault RRTellChanged en Xorg.
systemctl disable nvidia-persistenced.service >/dev/null 2>&1 || true
mkdir -p /etc/systemd/system/nvidia-persistenced.service.d
cat > "$PERSIST" << 'EOF'
[Unit]
# Arranque on-demand via udev, NO al boot
After=basic.target

[Service]
Restart=on-failure
RestartSec=2
EOF
systemctl daemon-reload 2>/dev/null || true
echo "   persistenced: deshabilitado del boot (on-demand via udev)"

# 5) udev: auto-iniciar persistenced cuando el modulo nvidia carga
cat > "$PERSUD" << 'EOF'
# Iniciar nvidia-persistenced cuando el modulo nvidia se carga (bajo demanda)
# Ocurra cuando sea: Xorg, CUDA, monitor externo, modprobe manual, etc.
SUBSYSTEM=="module", KERNEL=="nvidia", TAG+="systemd", ENV{SYSTEMD_WANTS}+="nvidia-persistenced.service"
EOF
udevadm control --reload-rules 2>/dev/null || true
echo "   udev: regla persistenced on-demand creada"

# 6) udev: dGPU nunca D3cold (defensa extra por si el PM activo se habilita)
cat > "$UDRULE" << 'EOF'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x1d52", ATTR{power/control}="on"
EOF
echo "   udev: regla MX250 power/control=on creada"

# 7) driver nvidia propietario (requiere componente non-free en fuentes Debian).
#    Solo se instala/actualiza si no esta presente o existe version mas nueva.
NV_PKG=nvidia-driver
NV_INST="$(dpkg-query -W -f='${Version}' $NV_PKG 2>/dev/null || true)"
NV_CAND="$(apt-cache policy $NV_PKG 2>/dev/null | awk '/Candidate:/{print $2}')"
if [ -n "$NV_INST" ] && { [ -z "$NV_CAND" ] || dpkg --compare-versions "$NV_INST" ge "$NV_CAND"; }; then
    echo "   nvidia-driver ya en la ultima version ($NV_INST) - sin reinstalar"
else
    echo "   nvidia-driver: instalando/actualizando (instalada=$NV_INST candidata=$NV_CAND)..."
    # limpiar libs nvidia de otra fuente (sin nvidia-driver) que bloquean el install
    STRAY="$(dpkg -l 2>/dev/null | awk '$2 ~ /^(libnvidia-|libglx-nvidia0|xserver-xorg-video-nvidia|nvidia-vulkan-icd)/ && $1 != "un" {print $2}')"
    if [ -n "$STRAY" ]; then
        echo "   purgando libs nvidia de version extrana ($(echo $STRAY | wc -w))..."
        for i in 1 2 3; do
            DEBIAN_FRONTEND=noninteractive apt-get purge -y $STRAY >/dev/null 2>&1 && break
            sleep 1
        done
    fi

    # habilitar non-free solo en repos debian.org (ignora third-party)
    for s in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$s" ] || continue
        if grep -Eq '^Components:' "$s"; then
            # deb822: anadir non-free al bloque cuyo URIs contenga debian.org
            awk '
                /^URIs:.*deb\.debian\.org|^URIs:.*security\.debian\.org/{u=1}
                /^Components:/ && u {
                    found=0; n=split($0,a," ")
                    for(i=1;i<=n;i++) if(a[i]=="non-free"){found=1;break}
                    if(!found){print $0" non-free"; u=0; next}
                    u=0
                }
                {u=0} 1
            ' "$s" > "$s.tmp" && mv "$s.tmp" "$s"
        else
            # clasico: solo deb lines de debian.org
            awk '/^[[:space:]]*deb .*deb\.debian\.org|^[[:space:]]*deb .*security\.debian\.org/{
                found=0; for(i=1;i<=NF;i++) if($i=="non-free"){found=1;break}
                if(!found){print $0" non-free"; next}
            }1' "$s" > "$s.tmp" && mv "$s.tmp" "$s"
        fi
    done
    apt-get update -qq 2>/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nvidia-driver
    echo "   nvidia-driver instalado/actualizado"
fi

echo
echo "== Listo. REINICIA para aplicar. =="
echo "   Boot rapido: nvidia carga bajo demanda, no al boot."
echo "   persistenced se activa solo cuando la dGPU se usa."
echo "   Rollback: sudo bash $0 --rollback"
