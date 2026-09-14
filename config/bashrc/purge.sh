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
        "$@"
    else
        "$@" >/dev/null 2>&1
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
run_cmd apt update -y

log "[2/12] Removing orphaned dependencies..."
run_cmd apt autoremove -y

log "[3/12] Cleaning downloaded packages..."
run_cmd apt autoclean -y
run_cmd apt clean -y

log "[4/12] Removing residual configuration files..."
run_cmd dpkg -l | awk '/^rc/ {print $2}' | xargs -r apt purge -y

log "[5/12] Removing OLD kernels (keeping current + newest fallback)..."
# Nunca borramos el kernel en uso ni el de respaldo más reciente:
#   /lib/modules/<versión> = única fuente de verdad de kernels presentes.
# Se conservan los 2 más recientes (actual + fallback) y los demás se purgan
# junto con sus headers EXACTOS (nada de borrar headers de kernels vivos).
KEEP_KERNELS="${KEEP_KERNELS:-2}"
mapfile -t KERS < <(for d in /lib/modules/[0-9]*; do echo "${d#/lib/modules/}"; done | sort -Vr)
if [ "${#KERS[@]}" -le "$KEEP_KERNELS" ]; then
    echo "   solo hay ${#KERS[@]} kernel(s) instalado(s): nada que purgar (actual=${KERS[0]})"
else
    to_purge=()
    for v in "${KERS[@]:$KEEP_KERNELS}"; do
        # headers si existen (mismo uso exacto de esa version)
        for h in "linux-headers-${v%-*}-common" "linux-headers-${v%-*}-common-rt" "linux-headers-$v"; do
            dpkg-query -W -f='${binary:Package}\n' "$h" >/dev/null 2>&1 && to_purge+=("$h")
        done
        to_purge+=("linux-image-$v")
    done
    if [ "${#to_purge[@]}" -gt 0 ]; then
        echo "   protegiendo:      ${KERS[*]:0:$KEEP_KERNELS}"
        echo "   purgando ${#to_purge[@]} paquete(s) viejos..."
        run_cmd apt purge -y "${to_purge[@]}" || true
    fi
fi

log "[6/12] Removing extra orphaned packages..."
if command -v deborphan &>/dev/null; then
    run_cmd deborphan | xargs -r apt purge -y
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
