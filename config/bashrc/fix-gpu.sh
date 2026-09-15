#!/bin/bash
# fix-gpu - Fix NVIDIA GeForce MX250 (TU117) para ASUS UX481FL
# Nivel bajo: GRUB (pcie_port_pm=off), modprobe.d (nouveau fuera + KMS nvidia),
# udev (power/control=on) e initramfs. Re-ejecutable / idempotente.
# Uso: sudo bash fix-gpu.sh [--rollback]
set -e

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

GRUB=/etc/default/grub
MOD=/etc/modprobe.d/nvidia.conf
UDRULE=/etc/udev/rules.d/99-gpu-mx250.rules

rollback() {
    echo "== Rollback fix GPU =="
    [ -f "$GRUB.bak-gpu-fix" ] && { cp -a "$GRUB.bak-gpu-fix" "$GRUB"; rm -f "$GRUB.bak-gpu-fix"; update-grub 2>/dev/null || true; echo "   GRUB restaurado"; }
    rm -f "$MOD" "$UDRULE"
    update-initramfs -u 2>/dev/null || true
    udevadm control --reload-rules 2>/dev/null || true
    echo "   modprobe/udev recuperados"
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
# KMS/atomic necesario para Wayland
options nvidia-drm modeset=1
EOF
echo "   modprobe: nouveau fuera, KMS nvidia activo"

# 3) udev: dGPU nunca D3cold
cat > "$UDRULE" << 'EOF'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x1d52", ATTR{power/control}="on"
EOF
udevadm control --reload-rules 2>/dev/null || true
echo "   udev: regla MX250 creada"

# 4) driver nvidia propietario
if dpkg-query -s nvidia-driver >/dev/null 2>&1; then
    echo "   nvidia-driver ya instalado"
else
    apt-get update -qq 2>/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nvidia-driver
    echo "   nvidia-driver instalado"
fi

# 5) initramfs: hornear modprobe para el arranque mas temprano
update-initramfs -u 2>/dev/null || true
echo "   initramfs actualizado"

echo
echo "== Listo. REINICIA para aplicar. =="
echo "   Rollback: sudo bash $0 --rollback"