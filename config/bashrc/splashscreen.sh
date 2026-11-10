#!/bin/bash
# splashscreen - Splash animado (cubo 3D + Tux) para desbloqueo LUKS
# ASUS ZenBook UX481FL / Debian cryptsetup-initramfs.
# Copia los assets de config/cryptsetup/ y el hook de initramfs (parcha el
# keyscript al wrapper). Solo regenera el initrd si algo ha cambiado, y
# reinyecta el override ACPI tras hacerlo.
# Uso: sudo bash splashscreen.sh   (re-ejecutable, idempotente)
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

# el script puede llegar por el symlink ~/.config/bashrc -> repo
HERE=$(dirname "$(readlink -f "$0")")
ASSETS=$HERE/../cryptsetup
REINJECT=$HERE/fix/reinject-acpi.sh
SRC_DIR=/etc/cryptsetup-initramfs
HOOK=/etc/initramfs-tools/hooks/crypto-prompt
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

changed=0

# install_file <origen> <destino> <modo>: copia solo si el destino difiere
install_file() {
    if cmp -s "$1" "$2" 2>/dev/null; then return 0; fi
    install -D -m "$3" "$1" "$2"
    echo "   instalado: $2"
    changed=1
}

echo "== Instalando splash screen de desbloqueo LUKS =="
install_file "$ASSETS/animate.sh" "$SRC_DIR/animate.sh" 755
install_file "$ASSETS/askpass-wrapper" "$SRC_DIR/askpass-wrapper" 755
for frame in "$ASSETS"/frames/*.txt; do
    install_file "$frame" "$SRC_DIR/frames/${frame##*/}" 644
done
# frames sobrantes de una version anterior
for frame in "$SRC_DIR"/frames/[0-9]*.txt; do
    [ -e "$frame" ] || continue
    if [ ! -e "$ASSETS/frames/${frame##*/}" ]; then
        rm -f "$frame"
        echo "   eliminado: $frame"
        changed=1
    fi
done

cat > "$TMP/hook" << 'EOF'
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
install_file "$TMP/hook" "$HOOK" 755

if ((changed)); then
    echo "   regenerando initramfs..."
    update-initramfs -u -k all
    bash "$REINJECT"
else
    echo "   sin cambios: initramfs intacto"
fi

echo "== Listo. Reinicia y veras el cubo 3D + Tux en el desbloqueo. =="
echo "   Rollback: sudo rm -f $HOOK && sudo update-initramfs -u"
