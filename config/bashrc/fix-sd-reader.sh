#!/bin/bash
# fix-sd-reader - Parche lector SD Realtek RTS522A/RTS525A (PCIe) para ASUS UX481FL
#
# El firmware activa RTD3 (autosuspend D3 a los 10s); al reusar el lector el
# chip no reinicializa el subsistema MMC y colapsa el enlace PCIe (se congela
# el sistema). Este script recompila rtsx_pci.ko/rtsx_pci_sdmmc.ko sin ese
# autosuspend (fix upstream RTS525A) + settling 5ms, anade pcie_aspm=off y
# fuerza power/control=on via udev. Re-ejecutable/idempotente; los modulos se
# cargan al reiniciar. Cache de fuentes en $0/../.src/<kernel>.
# Uso: sudo bash fix-sd-reader.sh [--rollback]
set -e

KV="$(uname -r)"; VERS="${KV%%+*}"; HDR="/lib/modules/$KV/build"; MODDIR="/lib/modules/$KV/updates"
BASE="https://raw.githubusercontent.com/gregkh/linux/v$VERS"
SRC="$(cd "$(dirname "$0")" && pwd)/.src/$VERS"
CRD_FILES="rtsx_pcr.c rtsx_pcr.h rts5209.c rts5229.c rtl8411.c rts5227.c rts5249.c rts5260.c rts5260.h rts5261.c rts5261.h rts5228.c rts5228.h rts5264.c rts5264.h"
MMC_FILES="rtsx_pci_sdmmc.c"; INC_FILES="rtsx_pci.h rtsx_common.h"

[ "$(id -u)" = "0" ] || { echo "ERROR: ejecutar con sudo"; exit 1; }

rollback() {
    echo "== Rollback fix SD Reader - kernel $KV =="
    rm -f "$MODDIR/drivers/misc/cardreader/rtsx_pci.ko" "$MODDIR/drivers/mmc/host/rtsx_pci_sdmmc.ko"
    depmod -a 2>/dev/null
    if [ -f /etc/default/grub.bak-sd-fix ]; then
        cp -a /etc/default/grub.bak-sd-fix /etc/default/grub
        command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null 2>&1
        rm -f /etc/default/grub.bak-sd-fix
        echo "   GRUB restaurado"
    fi
    rm -f /etc/udev/rules.d/99-sd-card-reader.rules
    udevadm control --reload-rules 2>/dev/null
    echo "   Reinicia para volver al estado anterior (cache conservada en $SRC)."
    exit 0
}
[ "${1:-}" = "--rollback" ] && rollback

echo "== Fix SD Reader (Realtek RTS522A) - kernel $KV =="

# 1) dependencias y headers
command -v curl >/dev/null 2>&1 || { echo ".. instalando curl"; apt-get update -qq && apt-get install -y -qq curl; }
if ! dpkg-query -W -f='${Status}' "linux-headers-$KV" 2>/dev/null | grep -q "install ok installed"; then
    echo ".. instalando build-essential y linux-headers-$KV"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential "linux-headers-$KV"
else
    command -v make >/dev/null 2>&1 || apt-get install -y -qq build-essential
fi
[ -d "$HDR" ] || { echo "ERROR: headers no disponibles: $HDR"; exit 1; }

# 2) fuentes del driver (cache, offline en re-ejecuciones)
mkdir -p "$SRC"
get() { [ -s "$2" ] && return 0; mkdir -p "$(dirname "$2")" && curl -fsSL --connect-timeout 15 -o "$2" "$BASE/$1" 2>/dev/null; }
FAIL=0
for f in $CRD_FILES; do get "drivers/misc/cardreader/$f" "$SRC/$f" || FAIL=1; done
for f in $MMC_FILES; do get "drivers/mmc/host/$f"      "$SRC/$f" || FAIL=1; done
for f in $INC_FILES;  do get "include/linux/$f"        "$SRC/$f" || FAIL=1; done
if [ "$FAIL" = "1" ]; then
    echo "   descarga incompleta; intentando con linux-source (Debian)..."
    TBZ="$(ls /usr/src/linux-source-*.tar.xz 2>/dev/null | head -1)"
    if [ -z "$TBZ" ]; then
        apt-get install -y -qq linux-source-6.12 || apt-get install -y -qq linux-source
        TBZ="$(ls /usr/src/linux-source-*.tar.xz 2>/dev/null | head -1)"
    fi
    [ -n "$TBZ" ] || { echo "ERROR: sin red y sin linux-source."; exit 1; }
    tar --wildcards -xJf "$TBZ" -C "$SRC" \
        'linux-*/drivers/misc/cardreader/' 'linux-*/drivers/mmc/host/rtsx_pci_sdmmc.c' \
        'linux-*/include/linux/rtsx_pci.h' 'linux-*/include/linux/rtsx_common.h' 2>/dev/null || true
    for f in $CRD_FILES $MMC_FILES $INC_FILES; do
        src=$(find "$SRC" \( -path "*/cardreader/$f" -o -path "*/host/$f" -o -path "*/linux/$f" \) 2>/dev/null | head -1)
        [ -n "$src" ] && mv -f "$src" "$SRC/$f" 2>/dev/null || true
    done
fi
for f in $CRD_FILES $MMC_FILES; do
    [ -s "$SRC/$f" ] || { echo "ERROR: no se pudo obtener el fuente $f"; exit 1; }
done
echo "   Fuentes: $SRC"

# 3) parchear (idempotente) y preparar build externo
BUILD="$(mktemp -d)"; trap 'rm -rf "$BUILD"' EXIT
for f in $CRD_FILES $MMC_FILES; do cp -a "$SRC/$f" "$BUILD/"; done
cat > "$BUILD/Kbuild" << 'EOF'
# rtsx_pci (lector Realtek PCIe) - reconstruccion externa
obj-m += rtsx_pci.o
rtsx_pci-objs := rtsx_pcr.o rts5209.o rts5229.o rtl8411.o rts5227.o rts5249.o rts5260.o rts5261.o rts5228.o rts5264.o
obj-m += rtsx_pci_sdmmc.o
EOF

MARK_PCR='CHK_PCI_PID(pcr, 0x522A) && PCI_PID(pcr) != PID_525A'
if grep -q "$MARK_PCR" "$BUILD/rtsx_pcr.c"; then
    echo "   rtsx_pcr.c ya parcheado"
else
    perl -0pi -e 's{if \(pcr->rtd3_en\)\n(\t+)pm_schedule_suspend\(device, 10000\);}{if (pcr->rtd3_en \&\&\n$1    !CHK_PCI_PID(pcr, 0x522A) \&\& PCI_PID(pcr) != PID_525A)\n$1\tpm_schedule_suspend(device, 10000);}g' "$BUILD/rtsx_pcr.c"
    echo "   Parche RTD3 aplicado (rtsx_pcr.c)"
fi
if grep -q 'mdelay(5);' "$BUILD/rtsx_pci_sdmmc.c"; then
    echo "   rtsx_pci_sdmmc.c ya parcheado"
else
    perl -0pi -e 's{(rtsx_pci_card_power_on\(pcr, RTSX_SD_CARD\);\n\tif \(err < 0\)\n\t\treturn err;\n\n\t)mdelay\(1\);}{$1mdelay(5);}s' "$BUILD/rtsx_pci_sdmmc.c"
    echo "   Parche settling 5ms aplicado (rtsx_pci_sdmmc.c)"
fi

# 4) compilar contra el kernel en ejecucion
LOG="$(cd "$(dirname "$0")" && pwd)/.src/build.log"
echo ".. compilando (puede tardar)"
make -C "$HDR" M="$BUILD" -j"$(nproc)" modules >"$LOG" 2>&1 \
    || { echo "ERROR: compilacion fallo. Log: $LOG"; exit 1; }
[ -s "$BUILD/rtsx_pci.ko" ] && [ -s "$BUILD/rtsx_pci_sdmmc.ko" ] || { echo "ERROR: faltan .ko tras build. Log: $LOG"; exit 1; }

# 5) instalar en updates/ (sobrescribe al stock al arrancar)
mkdir -p "$MODDIR/drivers/misc/cardreader" "$MODDIR/drivers/mmc/host"
install -m 644 "$BUILD/rtsx_pci.ko"       "$MODDIR/drivers/misc/cardreader/rtsx_pci.ko"
install -m 644 "$BUILD/rtsx_pci_sdmmc.ko" "$MODDIR/drivers/mmc/host/rtsx_pci_sdmmc.ko"
depmod -a
echo "   Instalados en $MODDIR"

# 6) GRUB: pcie_aspm=off (evita cuelgues del enlace PCIe)
if grep -q "pcie_aspm=off" /etc/default/grub 2>/dev/null; then
    echo "   GRUB: pcie_aspm=off ya presente"
else
    cp -a /etc/default/grub /etc/default/grub.bak-sd-fix
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 pcie_aspm=off"/' /etc/default/grub
    command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null 2>&1
    echo "   GRUB: anadido pcie_aspm=off"
fi

# 7) udev: nunca autosuspenderse (defensa extra)
cat > /etc/udev/rules.d/99-sd-card-reader.rules << 'EOF'
# Lector SD Realtek PCIe: fuerza power/control=on (nunca D3)
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x522a", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x525a", ATTR{power/control}="on"
EOF
udevadm control --reload-rules 2>/dev/null
echo "   Regla udev: /etc/udev/rules.d/99-sd-card-reader.rules"

trap - EXIT
rm -rf "$BUILD"
echo "== Listo. REINICIA y verifica:"
echo "   lsblk | grep -i mmc   # tarjeta SD visible"
echo "   sudo dmesg | grep -i rtsx"
echo "   Rollback: sudo bash $0 --rollback"