#!/bin/bash
# reinject-acpi - Vuelve a anadir el override ACPI (fix-acpi.sh) al initrd del
# kernel en ejecucion. update-initramfs parte de cero y lo pierde, asi que
# hay que llamarlo despues de cualquier regeneracion del initrd.
# Idempotente: no toca el initrd si el override ya esta.
# Uso: sudo bash reinject-acpi.sh
set -euo pipefail

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

KV="$(uname -r)"
INITRD="/boot/initrd.img-$KV"
OVERRIDE=/boot/fix-acpi-override.cpio
[[ -f $OVERRIDE && -f $INITRD ]] || exit 0
command -v lsinitramfs >/dev/null || { echo "AVISO: falta lsinitramfs (initramfs-tools)"; exit 0; }

LIST=$(mktemp)
TMP=$(mktemp)
trap 'rm -f "$LIST" "$TMP"' EXIT

lsinitramfs "$INITRD" >"$LIST" 2>/dev/null
if grep -q 'kernel/firmware/acpi/fix-acpi-ssdt.aml' "$LIST"; then
    exit 0
fi

cat "$OVERRIDE" "$INITRD" >"$TMP"
install -m 644 "$TMP" "$INITRD"
echo "   initramfs: override ACPI re-inyectado en $INITRD"
