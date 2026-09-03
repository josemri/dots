#!/bin/bash
# fix-acpi - Parche ACPI para ASUS ZenBook UX481FL
#
# La BIOS referencia flags globales (DPPP, DPAP, ...) que la DSDT nunca
# define, lo que aborta el framework termico (_SB.IETM.IDSP) con
# AE_NOT_FOUND y deja sin funcionar los perfiles de plataforma.
#
# Este script inyecta un SSDT override que define esos flags, usando el
# metodo oficial del kernel (initrd table override). Es re-ejecutable e
# idempotente.
#
# Uso:  sudo bash fix-acpi.sh
# Lugar: puede copiarse y ejecutarse desde cualquier ruta.
#
# una vez aplicado se puede controlar el modo con:
# cat /sys/firmware/acpi/platform_profile_choices
# echo XXX | sudo tee /sys/firmware/acpi/platform_profile
set -e

AML="/boot/fix-acpi-ssdt.aml"
CPIO="/boot/fix-acpi-override.cpio"
KV="$(uname -r)"
INITRD="/boot/initrd.img-$KV"

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }
command -v iasl >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq acpica-tools; }
[ -f "$INITRD" ] || { echo "ERROR: initrd no encontrado: $INITRD"; exit 1; }

echo "== Fix ACPI UX481FL - kernel $KV =="

# 1) Generar y compilar el SSDT override
TMP="$(mktemp -d)"
cat > "$TMP/fix.dsl" << 'DSL'
DefinitionBlock ("", "SSDT", 2, "OEM", "DPTF_FIX", 0x00000001)
{
    Name (DPAP, Zero)
    Name (DPCP, Zero)
    Name (RFIM, Zero)
    Name (PBPE, Zero)
    Name (APPE, Zero)
    Name (VSPE, Zero)
    Name (PIDE, Zero)
    Name (ATPC, Zero)
    Name (PTPC, Zero)
}
DSL
iasl -p "$TMP/fix" "$TMP/fix.dsl" >/dev/null 2>&1
cp "$TMP/fix.aml" "$AML"
chmod 644 "$AML"
echo "   Override: $AML ($(stat -c%s "$AML") bytes)"

# 2) Construir cpio sin comprimir con el override y concatenarlo delante del initrd
if [ ! -f "$INITRD.bak-acpi-fix" ]; then
    cp "$INITRD" "$INITRD.bak-acpi-fix"
    echo "   Respaldo initrd: $INITRD.bak-acpi-fix"
fi
mkdir -p "$TMP/kernel/firmware/acpi"
cp "$AML" "$TMP/kernel/firmware/acpi/"
( cd "$TMP" && find kernel | cpio -o -H newc 2>/dev/null ) > "$CPIO"
cat "$CPIO" "$INITRD.bak-acpi-fix" > "$INITRD.new"
mv "$INITRD.new" "$INITRD"
chmod 644 "$INITRD"
echo "   Initrd actualizado con override"

# 3) GRUB: acpi_osi=Linux
if ! grep -q "acpi_osi=Linux" /etc/default/grub 2>/dev/null; then
    cp /etc/default/grub /etc/default/grub.bak-acpi-fix
    sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 acpi_osi=Linux"/' /etc/default/grub
    command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null 2>&1
    echo "   GRUB: anadido acpi_osi=Linux"
else
    echo "   GRUB: acpi_osi=Linux ya presente"
fi

rm -rf "$TMP"
echo "== Listo. Reinicia y verifica:"
echo "   sudo dmesg | grep -i 'Table Upgrade\\|Aborting\\|AE_NOT_FOUND'"
echo "   Rollback: sudo cp $INITRD.bak-acpi-fix $INITRD"
