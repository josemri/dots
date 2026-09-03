#!/bin/bash
# splashscreen - Instala el splash screen custom para el desbloqueo de disco (LUKS)
# para ASUS ZenBook UX481FL / Debian con cryptsetup-initramfs.
#
# El splash es un ASCII-art animado en la consola del initramfs: un cubo 3D
# girando (frames coloreados) + Tux (prompt.txt) + prompt "contraseña:".
#
# Como se implementa:
#   - El hook /etc/initramfs-tools/hooks/crypto-prompt copia los assets al
#     initrd y PARCHEA keyscript en /usr/lib/cryptsetup/functions para que
#     en vez de /lib/cryptsetup/askpass use el wrapper askpass-wrapper.
#   - askpass-wrapper limpia pantalla, lanza animate.sh (frames) en setsid y
#     muestra el prompt real; al acabar mata la animacion.
#
# Uso:   sudo bash splashscreen.sh
# Es re-ejecutable e idempotente.
set -e

SRC_DIR="/etc/cryptsetup-initramfs"
HOOK="/etc/initramfs-tools/hooks/crypto-prompt"

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

echo "== Instalando splash screen de desbloqueo LUKS =="

# 1) Crear directorio de destino
mkdir -p "$SRC_DIR/frames"

# 2) Extraer los assets empaquetados (frames + scripts + prompt + conf)
BASE64_BLOB=$(cat <<'B64EOF'
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
B64EOF
)
echo "$BASE64_BLOB" | base64 -d > /tmp/splash-assets.tar.gz
tar xzf /tmp/splash-assets.tar.gz -C "$SRC_DIR"
rm -f /tmp/splash-assets.tar.gz
chmod +x "$SRC_DIR/animate.sh" "$SRC_DIR/askpass-wrapper"
echo "   Assets instalados en $SRC_DIR"

# 3) Instalar el hook de initramfs (si no existe)
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
    echo "   Hook ya existente: $HOOK (no se toca)"
fi

# 4) Regenerar el initrd para incluir el splash
echo "   Regenerando initramfs..."
update-initramfs -u -k all 2>/dev/null || update-initramfs -u 2>/dev/null || \
    mkinitramfs -o /boot/initrd.img-"$(uname -r)"
echo "== Listo. Reinicia y veras el cubo 3D + Tux en el desbloqueo. =="
echo "   Rollback: sudo rm -f $HOOK && sudo update-initramfs -u"
