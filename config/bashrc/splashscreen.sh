#!/bin/bash
# splashscreen - Splash animado (cubo 3D + Tux) para desbloqueo LUKS
# ASUS ZenBook UX481FL / Debian cryptsetup-initramfs.
# Instala assets, hook de initramfs (parcha keyscript al wrapper) y regenera initrd.
# Uso: sudo bash splashscreen.sh   (re-ejecutable, idempotente)
set -e

SRC_DIR="/etc/cryptsetup-initramfs"
HOOK="/etc/initramfs-tools/hooks/crypto-prompt"
[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

echo "== Instalando splash screen de desbloqueo LUKS =="
mkdir -p "$SRC_DIR/frames"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
base64 -d > "$TMP/assets.tar.gz" << 'B64EOF'
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
B64EOF
tar xzf "$TMP/assets.tar.gz" -C "$SRC_DIR"
chmod +x "$SRC_DIR/animate.sh" "$SRC_DIR/askpass-wrapper"
echo "   Assets instalados en $SRC_DIR"

if [ ! -f "$HOOK" ]; then
    cat > "$HOOK" << 'EOF'
#!/bin/sh
PREREQ="cryptroot"
prereqs() { echo "$PREREQ"; }
case "$1" in prereqs) prereqs; exit 0;; esac
. /usr/share/initramfs-tools/hook-functions

mkdir -p "${DESTDIR}/etc/luks-anim/frames"
cp /etc/cryptsetup-initramfs/animate.sh "${DESTDIR}/etc/luks-anim/animate.sh"
chmod +x "${DESTDIR}/etc/luks-anim/animate.sh"
for frame in /etc/cryptsetup-initramfs/frames/[0-9]*.txt; do
    [ -f "$frame" ] || continue
    cp "$frame" "${DESTDIR}/etc/luks-anim/frames/"
done
cp /etc/cryptsetup-initramfs/askpass-wrapper "${DESTDIR}/etc/luks-anim/askpass-wrapper"
chmod +x "${DESTDIR}/etc/luks-anim/askpass-wrapper"

sed -i 's|keyscript="/lib/cryptsetup/askpass"|keyscript="/etc/luks-anim/askpass-wrapper"|' \
    "${DESTDIR}/usr/lib/cryptsetup/functions"
EOF
    chmod +x "$HOOK"
    echo "   Hook creado: $HOOK"
else
    echo "   Hook ya existente (no se toca): $HOOK"
fi

echo "   Regenerando initramfs..."
update-initramfs -u -k all 2>/dev/null || update-initramfs -u 2>/dev/null || \
    mkinitramfs -o /boot/initrd.img-"$(uname -r)"
trap - EXIT
echo "== Listo. Reinicia y veras el cubo 3D + Tux en el desbloqueo. =="
echo "   Rollback: sudo rm -f $HOOK && sudo update-initramfs -u"