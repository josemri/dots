#!/usr/bin/env bash

set -e

# ==============================
# Variables
# ==============================
GREEN='\033[0;32m'
NC='\033[0m'  # No Color / reset
VERBOSE=false

# Verifica si se pasó -v
if [[ "$1" == "-v" ]]; then
    VERBOSE=true
fi

# ==============================
# Función de logging
# ==============================
log() {
    echo -e "${GREEN}$*${NC}"
}

# ==============================
# Función para ejecutar comandos
# ==============================
run_cmd() {
    if $VERBOSE; then
        "$@" || { echo "   AVISO: fallo: $*" >&2; return 1; }
    else
        "$@" >/dev/null 2>&1 || { echo "   AVISO: fallo: $*" >&2; return 1; }
    fi
}

# ==============================
# Inicio del script
# ==============================
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

log "=============================="
log " sys_cleanup"
log "=============================="

log "[1/12] Updating package lists..."
run_cmd apt-get -y -qq update

log "[2/12] Removing orphaned dependencies..."
run_cmd apt-get -y -qq autoremove

log "[3/12] Cleaning downloaded packages..."
run_cmd apt-get -y -qq autoclean
run_cmd apt-get -y -qq clean

log "[4/12] Removing residual configuration files..."
mapfile -t RC_PKGS < <(dpkg -l | awk '/^rc/ {print $2}')
if [ "${#RC_PKGS[@]}" -gt 0 ]; then run_cmd apt-get -y purge "${RC_PKGS[@]}" || true; fi

log "[5/12] Removing OLD kernels (keeping current + newest fallback)..."
# Nunca se borra el kernel en uso: se protege siempre el que esta arrancado
# (uname -r) y se completan hasta KEEP_KERNELS con los mas recientes. Los demas
# se purgan junto con sus headers EXACTOS (nada de borrar headers de kernels vivos).
KEEP_KERNELS="${KEEP_KERNELS:-2}"
RUNNING=$(uname -r)
mapfile -t KERS < <(for d in /lib/modules/[0-9]*; do echo "${d#/lib/modules/}"; done | sort -Vr)
KEEP=("$RUNNING")
for v in "${KERS[@]}"; do
    ((${#KEEP[@]} < KEEP_KERNELS)) || break
    [[ " ${KEEP[*]} " == *" $v "* ]] || KEEP+=("$v")
done
if [ "${#KERS[@]}" -le "${#KEEP[@]}" ]; then
    echo "   solo hay ${#KERS[@]} kernel(s) instalado(s): nada que purgar (actual=$RUNNING)"
else
    to_purge=()
    for v in "${KERS[@]}"; do
        [[ " ${KEEP[*]} " == *" $v "* ]] && continue
        # headers si existen (mismo uso exacto de esa version)
        for h in "linux-headers-${v%-*}-common" "linux-headers-${v%-*}-common-rt" "linux-headers-$v"; do
            dpkg-query -W -f='${binary:Package}\n' "$h" >/dev/null 2>&1 && to_purge+=("$h")
        done
        to_purge+=("linux-image-$v")
    done
    if [ "${#to_purge[@]}" -gt 0 ]; then
        echo "   protegiendo:      ${KEEP[*]}"
        echo "   purgando ${#to_purge[@]} paquete(s) viejos..."
        run_cmd apt-get -y purge "${to_purge[@]}" || true
    fi
fi

log "[6/12] Removing extra orphaned packages..."
if command -v deborphan &>/dev/null; then
    mapfile -t ORPHANS < <(deborphan)
    if [ "${#ORPHANS[@]}" -gt 0 ]; then run_cmd apt-get -y purge "${ORPHANS[@]}" || true; fi
fi

log "[7/12] Cleaning journal logs (keeping 200MB)..."
run_cmd journalctl --vacuum-size=200M

log "[8/12] Cleaning thumbnail caches..."
run_cmd rm -rf /home/*/.cache/thumbnails || true

log "[9/12] Cleaning pip cache..."
if command -v pip3 &>/dev/null; then run_cmd pip3 cache purge || true; fi
if command -v pip &>/dev/null; then run_cmd pip cache purge || true; fi

log "[10/12] Cleaning npm cache..."
if command -v npm &>/dev/null; then run_cmd npm cache clean --force || true; fi

log "[11/12] Cleaning cargo cache..."
if command -v cargo &>/dev/null; then run_cmd cargo cache -a || true; fi

log "[12/12] Cleaning old log files..."
run_cmd find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || true

log "=============================="
log " Cleanup completed."
log "=============================="
