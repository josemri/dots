#!/bin/bash
# fix-acpi - Parche ACPI ASUS ZenBook UX481FL
# Inyecta SSDT override (DPTF flags: DPPP, DPAP, RFIM...) via initrd table override
# y anade acpi_osi=Linux a GRUB. Re-ejecutable e idempotente.
# Uso: sudo bash fix-acpi.sh
set -e

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }
command -v iasl >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq acpica-tools; }

KV="$(uname -r)"
AML="/boot/fix-acpi-ssdt.aml"
CPIO="/boot/fix-acpi-override.cpio"
INITRD="/boot/initrd.img-$KV"
[ -f "$INITRD" ] || { echo "ERROR: initrd no encontrado: $INITRD"; exit 1; }

echo "== Fix ACPI UX481FL - kernel $KV =="
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/fix.dsl" << 'DSL'
DefinitionBlock ("", "SSDT", 2, "OEM", "DPTF_FIX", 0x00000001)
{
    Name (DPAP, Zero)  Name (DPCP, Zero)  Name (RFIM, Zero)
    Name (PBPE, Zero)  Name (APPE, Zero)  Name (VSPE, Zero)
    Name (PIDE, Zero)  Name (ATPC, Zero)  Name (PTPC, Zero)
}
DSL
iasl -p "$TMP/fix" "$TMP/fix.dsl" >/dev/null 2>&1
install -m 644 "$TMP/fix.aml" "$AML"
echo "   Override: $AML"

[ -f "$INITRD.bak-acpi-fix" ] || { cp "$INITRD" "$INITRD.bak-acpi-fix"; echo "   Respaldo: $INITRD.bak-acpi-fix"; }
mkdir -p "$TMP/kernel/firmware/acpi"
cp "$AML" "$TMP/kernel/firmware/acpi/"
( cd "$TMP" && find kernel | cpio -o -H newc 2>/dev/null ) > "$CPIO"
cat "$CPIO" "$INITRD.bak-acpi-fix" > "$INITRD.new" && mv "$INITRD.new" "$INITRD"
chmod 644 "$INITRD"
echo "   Initrd actualizado"

if ! grep -q "acpi_osi=Linux" /etc/default/grub 2>/dev/null; then
    cp /etc/default/grub /etc/default/grub.bak-acpi-fix
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 acpi_osi=Linux"/' /etc/default/grub
    command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null
    echo "   GRUB: anadido acpi_osi=Linux"
else
    echo "   GRUB: acpi_osi=Linux ya presente"
fi

trap - EXIT
echo "== Listo. Verifica: sudo dmesg | grep -i 'Table Upgrade\\|AE_NOT_FOUND'"
echo "   Rollback: sudo cp $INITRD.bak-acpi-fix $INITRD"
