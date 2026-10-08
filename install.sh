#!/usr/bin/env bash
#
# instalador de mis dotfiles (debian)
#
# cada paso mira primero como esta el sistema y solo toca lo que no coincide
# con lo que dejaria una instalacion desde cero. si ya esta todo igual, el
# script no modifica nada.
#
# no guarda estado en ningun sitio: cada paso comprueba el sistema real
# (ficheros, symlinks, unidades, dpkg, dkms, modulos compilados) y solo toca
# lo que no cuadra. --force se salta esas comparaciones.
#
# uso:
#   ./install.sh                    solo lo que falte o este desactualizado
#   ./install.sh --no-upgrade       no actualiza el resto del sistema
#   ./install.sh --no-hardware      no ejecuta los fixes de hardware
#   ./install.sh --force            re-aplica nvim, dkms y los fixes de hardware
#   ./install.sh --only nvim,dkms   ejecuta solo los pasos indicados
#   ./install.sh --list             lista los pasos que acepta --only
#
set -euo pipefail

# ------------------------------------------------------------------ ajustes --
REPO_URL="${REPO_URL:-https://github.com/josemri/dots.git}"
REPO_DIR="${REPO_DIR:-$HOME/dots}"
APT_MAX_AGE_DAYS="${APT_MAX_AGE_DAYS:-7}" # cada cuanto se refrescan los indices de apt

FORCE=0
WITH_UPGRADE=1
WITH_HARDWARE=1
LIST=0
ONLY=()
APPLIED=()
DONE=()
CHANGES=0

# -------------------------------------------------------------------- salida --
if [[ -t 1 ]]; then
    C_INFO=$'\e[34m' C_OK=$'\e[32m' C_WARN=$'\e[33m'
    C_ERR=$'\e[31m' C_QUIET=$'\e[2m' C_OFF=$'\e[0m'
else
    C_INFO= C_OK= C_WARN= C_ERR= C_QUIET= C_OFF=
fi

log() { printf '%s[ ..]%s %s\n' "$C_INFO" "$C_OFF" "$1"; }
ok() { printf '%s[ ok]%s %s\n' "$C_OK" "$C_OFF" "$1"; }
skip() { printf '%s[skip]%s %s\n' "$C_QUIET" "$C_OFF" "$1"; }
warn() { printf '%s[warn]%s %s\n' "$C_WARN" "$C_OFF" "$1" >&2; }
die() { printf '%s[fail]%s %s\n' "$C_ERR" "$C_OFF" "$1" >&2; exit 1; }

mark() { CHANGES=$((CHANGES + 1)); }        # el paso en curso ha tocado algo
changed_since() { ((CHANGES > $1)); }      # ¿algo cambio desde la marca $1?
trap 'die "linea $LINENO: $BASH_COMMAND"' ERR

# todo lo temporal vive aqui y se borra al salir, tambien con Ctrl+C
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
trap 'exit 130' INT TERM
tmpfile() { mktemp -p "$WORKDIR"; }

# ------------------------------------------------------------------ opciones --
usage() {
    cat <<'EOF'
uso: install [opciones]

  -u, --no-upgrade      no actualiza el resto del sistema (apt upgrade)
  -n, --no-hardware no ejecuta los fixes de hardware (compilan modulos)
  -f, --force           re-aplica nvim, dkms y los fixes aunque ya esten hechos
  -o, --only <pasos>    solo esos pasos, separados por coma (prefijo: nvim,dkms)
  -l, --list            muestra todos los pasos que se pueden ejecutar con --only
  -h, --help        esto
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--no-upgrade) WITH_UPGRADE=0 ;;
        -n|--no-hardware) WITH_HARDWARE=0 ;;
        -f|--force) FORCE=1 ;;
        -l|--list) LIST=1 ;;
        -o|--only) shift; IFS=, read -r -a ONLY <<<"$1" ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "opcion desconocida: $1" ;;
    esac
    shift
done

# -------------------------------------------------------------- primitivas --
# ensure_file <ruta> [modo]   (contenido por stdin)
#   escribe el contenido solo si el fichero no existe o difiere.
ensure_file() {
    local dest=$1 mode=${2:-644} tmp
    tmp=$(tmpfile)
    cat >"$tmp"
    if sudo cmp -s "$tmp" "$dest"; then return 0; fi
    sudo install -D -m "$mode" "$tmp" "$dest"
    mark
    ok "$dest"
}

# ensure_link <origen> <destino>
#   (re)crea el symlink solo si no apunta ya al origen. si el origen no existe
#   avisa en vez de dejar un symlink roto.
ensure_link() {
    local src=$1 dst=$2
    if [[ ! -e $src ]]; then warn "$src no existe: no se enlaza $dst"; return 0; fi
    if [[ -L $dst && $(readlink -- "$dst") == "$src" ]]; then return 0; fi
    if [[ -e $dst || -L $dst ]]; then sudo rm -rf -- "$dst"; fi
    ln -s -- "$src" "$dst"
    mark
    ok "$dst -> $src"
}

# set_conf <fichero> <clave> <valor> [cabecera_de_seccion]
#   deja la clave con ese valor exacto: sustituye la entrada activa (y colapsa
#   duplicados) y si no existia la inserta tras la cabecera de seccion indicada
#   (p.ej. "[Login]"), o al final del fichero. los comentarios se respetan y no
#   se toca nada si ya coincide.
set_conf() {
    local file=$1 key=$2 value=$3 section=${4:-} new
    new=$(tmpfile)
    sudo awk -v key="$key" -v value="$value" -v section="$section" '
        { line[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                t = line[i]
                sub(/^[ \t]+/, "", t)
                if (t ~ "^" key "=") {
                    if (!done) { out[++n] = key "=" value; done = 1 }
                } else {
                    out[++n] = line[i]
                    if (section != "" && t == section) insert = n + 1
                }
            }
            if (!done) {
                if (insert > 0) {
                    for (i = n; i >= insert; i--) out[i + 1] = out[i]
                    out[insert] = key "=" value
                    n++
                } else {
                    out[++n] = key "=" value
                }
            }
            for (i = 1; i <= n; i++) print out[i]
        }
    ' "$file" >"$new"
    if sudo cmp -s "$new" "$file"; then return 0; fi
    sudo install -m 644 "$new" "$file"
    mark
    ok "$(basename "$file"): $key=$value"
}

# ensure_service [user] <unidad>...
#   habilita y arranca la unidad solo si falta algo. is-enabled tambien dice
#   "masked", en cuyo caso no hay nada que hacer: avisar.
ensure_service() {
    local scope=() unit state
    if [[ ${1:-} == user ]]; then scope=(--user); shift; fi
    for unit in "$@"; do
        state=$(systemctl "${scope[@]}" is-enabled "$unit" 2>/dev/null || true)
        case $state in
            masked)
                warn "$unit esta masked: sudo systemctl unmask $unit"
                continue
                ;;
            enabled | enabled-runtime | static | alias | indirect) ;; # ya habilitada
            *)
                if systemctl "${scope[@]}" enable "$unit"; then mark; else warn "no se pudo habilitar $unit"; fi
                ;;
        esac
        if ! systemctl "${scope[@]}" is-active --quiet "$unit" 2>/dev/null; then
            if systemctl "${scope[@]}" start "$unit"; then mark; else warn "no se pudo arrancar $unit"; fi
        fi
    done
}

# apt: solo refresca los indices si estan viejos y solo instala lo que falta o
# esta por debajo de la version candidata.
apt_lists_stale() {
    local newest=0 f t
    for f in /var/lib/apt/lists/*_InRelease; do
        [[ -e $f ]] || continue
        t=$(stat -c %Y -- "$f")
        if ((t > newest)); then newest=$t; fi
    done
    ((newest == 0)) && return 0
    ((($(date +%s) - newest) / 86400 >= APT_MAX_AGE_DAYS))
}
apt_refresh() {
    if apt_lists_stale; then
        log "apt: refreshing indices"
        sudo apt-get update -qq
        mark
    fi
}
apt_candidate() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}'; }
apt_install() {
    local pkg installed candidate todo=()
    apt_refresh
    for pkg in "$@"; do
        installed=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)
        candidate=$(apt_candidate "$pkg")
        if [[ -z $installed ]]; then
            if [[ $candidate == "(none)" ]]; then
                warn "$pkg no esta en los repos, se omite"
            else
                todo+=("$pkg")
            fi
        elif [[ $candidate != "(none)" ]] && dpkg --compare-versions "$installed" lt "$candidate"; then
            todo+=("$pkg")
        fi
    done
    if [[ ${#todo[@]} -eq 0 ]]; then
        skip "paquetes al dia"
        return 0
    fi
    log "instalando ${#todo[@]}: ${todo[*]}"
    sudo apt-get install -y -qq "${todo[@]}"
    mark
}

# xorg + i3: escritorio y gestor de ventanas
# i3lock: bloqueo de pantalla   xournalpp: notas a mano
# keepass2: gestor de contrasenas   libreoffice: the better office
# librewolf: navegador (repo oficial, ver ensure_librewolf_repo)   zathura: the better pdf viewer
# nitrogen: fondo de pantalla
# brightnessctl: brillo   xclip: portapapeles   network-manager: red
# unzip/zip/curl/wget: utilidades basicas
# dkms + build-essential: headers/kernel para compilar modulos
# pipewire + wireplumber + pipewire-pulse: audio
# bluez + libspa-0.2-bluetooth: bluetooth
# ripgrep + fzf: dependencias de nvim   zoxide: cd con memoria (lo usa .bashrc)
# trash-cli: alias rm   ffmpeg: grabar pantalla y camara
# ncdu: uso de disco   fuse: montajes
# ncal: calendar jq: json   bc: calculos   tlp: bateria

# CHECK rm fuse
PACKAGES=(
    xorg i3 i3blocks i3lock git kitty picom xournalpp rofi keepass2
    libreoffice librewolf zathura nitrogen brightnessctl
    xclip network-manager unzip zip curl wget dkms build-essential pipewire
    wireplumber pipewire-pulse bluez ripgrep fzf zoxide trash-cli ffmpeg ncdu
    fuse ncal libspa-0.2-bluetooth jq bc tlp
)

# librewolf no esta en los repos de debian, asi que se anade el repo oficial
ensure_librewolf_repo() {
    local key=/usr/share/keyrings/librewolf.gpg
    local src=/etc/apt/sources.list.d/librewolf.list
    local before=$CHANGES tmp

    if [[ ! -f $key ]]; then
        log "librewolf: descargando la clave del repositorio"
        tmp=$(tmpfile)
        /usr/lib/apt/apt-helper download-file \
            https://repo.librewolf.net/keyring.gpg "$tmp" >/dev/null ||
            die "no se pudo descargar la clave de librewolf (sin red?)"
        sudo install -D -m 644 "$tmp" "$key"
        mark
        ok "$key"
    fi

    ensure_file "$src" <<'EOF'
deb [signed-by=/usr/share/keyrings/librewolf.gpg] https://repo.librewolf.net librewolf main
EOF

    # un repo recien anadido no esta en los indices de apt
    if changed_since "$before"; then
        log "apt: refreshing indices (repo librewolf)"
        sudo apt-get update -qq
    fi
}

# ------------------------------------------------------------------- pasos ---
step_upgrade_system() {
    if ((WITH_UPGRADE == 0)); then skip "actualizacion del sistema (--no-upgrade)"; return 0; fi
    apt_refresh
    local sim n
    if ! sim=$(apt-get -s -q -y upgrade 2>/dev/null); then
        warn "no se pudo simular apt upgrade, se omite"
        return 0
    fi
    n=$(awk '/upgraded,/{print $1; exit}' <<<"$sim")
    if [[ ${n:-0} == 0 ]]; then
        skip "sistema al dia"
        return 0
    fi
    log "$n actualizaciones del sistema"
    sudo apt-get upgrade -y -qq
    mark
}

step_install_packages() {
    ensure_librewolf_repo
    apt_install "${PACKAGES[@]}"

    # los headers pueden no estar en los repos activos; los fixes de kernel
    # los necesitan, asi que se avisa en vez de reventar el script.
    local hdr="linux-headers-$(uname -r)"
    if [[ -d /lib/modules/$(uname -r)/build ]]; then
        skip "linux-headers: ya instalados"
    elif [[ $(apt_candidate "$hdr") == "(none)" ]]; then
        warn "$hdr no esta en los repos (los fixes de hardware lo necesitan)"
    else
        apt_install "$hdr"
    fi
}

# lanzadores que sobran en el menu y que se ocultan si estan instalados (si
# no lo estan, ni se miran). mismas reglas que los de libreoffice: solo los
# ficheros normales, los symlinks se dejan como estan.
HIDE_MENU_ENTRIES=(
    kitty.desktop
    display-im7.q16.desktop
    debian-uxterm.desktop
    debian-xterm.desktop
    gcr-prompter.desktop
    gcr-viewer.desktop
    org.gnome.Zenity.desktop
    org.pwmt.zathura.desktop
    org.pwmt.zathura-pdf-poppler.desktop
    picom.desktop
    python3.13.desktop
    rofi.desktop
    rofi-theme-selector.desktop
    texdoctk.desktop
    xdg-desktop-portal-gtk.desktop
    xfreerdp3.desktop
    xfreerdp3-file.desktop
	 nitrogen.desktop
)

# oculta un .desktop con Hidden=true, que es justo lo que hace la opcion "no
# mostrar" del menu, pero por script. si el fichero no existe (no esta
# instalado) o es un symlink se salta esa entrada y se sigue con las demas.
# sale con:
#   0 = ha ocultado algo (habia cambio)
#   1 = ya estaba oculto, no hay nada que tocar
#   2 = no existe o no es un fichero normal: entrada skipeada
hide_desktop() {
    local file=$1 before=$CHANGES
    # sin -L: un symlink a un .desktop del sistema lo reescribiria
    [[ -f $file && ! -L $file ]] || return 2
    set_conf "$file" Hidden true "[Desktop Entry]"
    if changed_since "$before"; then return 0; fi
    return 1
}

# todo lo que sobra en el menu se oculta de una vez: los lanzadores de
# libreoffice (writer, calc, impress...) porque abro documentos con el start
# center, y los de HIDE_MENU_ENTRIES porque no los uso por el menu. el start
# center se deja visible porque es el lanzador que si se usa; lo que no este
# instalado se salta y se sigue con el resto.
#
# OJO: estos ficheros son de /usr/share y los Dueene el paquete, asi que un
# upgrade (o un --reinstall) los revierte y este paso hay que re-ejecutarlo.
step_hide_desktop() {
    local dirs dir file name rc note
    local cand=() total=0 hidden=0 startcenter=0
    dirs=(/usr/local/share/applications /usr/share/applications
        "${XDG_DATA_HOME:-$HOME/.local/share/applications}")

    for dir in "${dirs[@]}"; do
        [[ -d $dir ]] || continue

        cand=("$dir"/libreoffice-*.desktop)
        for name in "${HIDE_MENU_ENTRIES[@]}"; do cand+=("$dir/$name"); done

        for file in "${cand[@]}"; do
            if [[ ${file##*/} == libreoffice-startcenter.desktop ]]; then
                startcenter=1
                continue
            fi
            rc=0
            hide_desktop "$file" || rc=$?
            case $rc in
                0) hidden=$((hidden + 1)) total=$((total + 1)) ;;
                1) total=$((total + 1)) ;;
            esac # 2: no instalado, se salta
        done
    done

    note=""
    if ((startcenter)); then note=" (start center visible)"; fi
    if ((total == 0)); then
        skip "menus: sin lanzadores que ocultar"
    elif ((hidden == 0)); then
        skip "menus: $total lanzadores ya ocultos$note"
    else
        log "menus: ocultos $hidden de $total lanzadores$note"
    fi
}

# el commit de un nightly va en el propio binario: "+g<commit>". se compara
# contra el tag nightly de upstream, asi que si el nightly es el mismo que ya
# tengo no se descarga ni se instala nada.
step_nvim_nightly() {
    local remote current=""
    remote=$(git ls-remote https://github.com/neovim/neovim.git refs/tags/nightly | cut -f1) ||
        die "no se pudo consultar el nightly de neovim (sin red?)"

    if command -v nvim >/dev/null; then
        current=$(nvim --version | head -1 | sed 's/.*+g//')
    fi
    if [[ ${current:0:7} == "${remote:0:7}" ]]; then
        skip "nvim nightly al dia (${current:0:9})"
        return 0
    fi

    local arch=x86_64
    [[ $(uname -m) == aarch64 ]] && arch=arm64
    # OJO: en un solo "local" las palabras se expanden antes de asignar, asi
    # que dir no puede referenciar a asset en la misma declaracion.
    local asset=nvim-linux-$arch dir tarball
    dir=/usr/local/$asset
    tarball=$WORKDIR/nvim.tar.gz

    log "nvim: hay nightly nuevo (${current:-sin nvim} -> ${remote:0:9})"
    curl -fsSL --connect-timeout 15 -o "$tarball" \
        "https://github.com/neovim/neovim/releases/download/nightly/$asset.tar.gz"
    sudo rm -rf -- "$dir" /usr/local/bin/nvim
    sudo tar -xzf "$tarball" -C /usr/local
    sudo ln -sfn "$dir/bin/nvim" /usr/local/bin/nvim
    mark
}

# DKMS asus-wmi-screenpad: remapea los botones extra del teclado. dkms status
# ya dice si el modulo esta compilado e instalado, no hace falta mas.
step_asus_wmi_screenpad() {
    local module=asus-wmi version=1.0
    local state src=/usr/src/$module-$version

    # dkms vive en /usr/sbin (fuera del PATH del usuario). su formato es
    # "modulo/version, kernel, arch: estado" (o "modulo, version, kernel,
    # arch: estado" en versiones antiguas), asi que el estado va tras los dos
    # puntos y el modulo es el campo antes de la primera coma.
    state=$(sudo dkms status 2>/dev/null || true)
    if ((FORCE == 0)) &&
        awk -v module="$module" -v version="$version" '
            {
                n = index($0, ":")
                if (!n) next
                head = substr($0, 1, n - 1)
                st = substr($0, n + 1)
                gsub(/^ +| +$/, "", head)
                gsub(/^ +| +$/, "", st)
                nf = split(head, f, ",")
                gsub(/^ +| +$/, "", f[1])
                gsub(/^ +| +$/, "", f[2])
                if (st ~ /^installed/ &&
                    (f[1] == module "/" version ||
                     (f[1] == module && nf > 2 && f[2] == version))) found = 1
            }
            END { exit !found }
        ' <<<"$state"; then
        skip "$module/$version: ya instalado"
    else
        local work
        work=$WORKDIR/asus-wmi
        mkdir -p "$work"
        log "$module/$version: compilando"
        sudo dkms remove -m "$module" -v "$version" --all 2>/dev/null || true
        sudo rm -rf /var/lib/dkms/$module "$src"
        (
            cd "$work"
            wget -q https://github.com/Plippo/asus-wmi-screenpad/archive/master.zip -O master.zip
            unzip -q master.zip
            mv asus-wmi-screenpad-master/* . && rmdir asus-wmi-screenpad-master
            sh prepare-for-current-kernel.sh
        )
        sudo rm -rf -- "$src"
        sudo cp -r -- "$work" "$src"
        sudo chown -R root:root "$src" && sudo chmod -R u+rwX,go+rX "$src"
        sudo dkms add -m "$module" -v "$version" --force
        sudo dkms build -m "$module" -v "$version"
        sudo dkms install -m "$module" -v "$version" --force
        mark
    fi

    # los leds del screenpad solo los root pueden cambiar el brillo
    ensure_file /etc/udev/rules.d/99-asus.rules <<'EOF'
# rules for asus_nb_wmi devices

ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
EOF
    sudo udevadm control --reload-rules 2>/dev/null || true
}

step_networkmanager() { ensure_service NetworkManager; }
step_bluetooth() { ensure_service bluetooth; }
step_pipewire() { ensure_service user pipewire wireplumber; }

step_tailscale() {
    command -v tailscale >/dev/null || { skip "tailscale no esta instalado"; return 0; }

    local before=$CHANGES
    ensure_file /etc/systemd/system/tailscaled.socket <<'EOF'
[Unit]
Description=Tailscale Socket

[Socket]
ListenStream=/run/tailscale/tailscaled.sock
SocketMode=0666

[Install]
WantedBy=sockets.target
EOF
    ensure_file /etc/systemd/system/tailscaled.service.d/20-socket-activate.conf <<'EOF'
[Unit]
Wants=tailscaled.socket

[Service]
Sockets=tailscaled.socket
EOF
    if changed_since "$before"; then sudo systemctl daemon-reload; fi

    # sin --now a proposito: si el usuario esta conectado por tailscale,
    # parar el daemon le cortaria la conexion (incluida esta sesion).
    if systemctl is-enabled --quiet tailscaled.service 2>/dev/null; then
        sudo systemctl disable tailscaled.service
        mark
    fi
    ensure_service tailscaled.socket
}

step_dotfiles() {
    if [[ ! -d $REPO_DIR ]]; then
        log "clonando dotfiles en $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
        mark
    fi

    ensure_link "$REPO_DIR/.bashrc" "$HOME/.bashrc"

    # nitrogen se deja fuera a proposito: sus .cfg son estado, no config
    local item
    for item in bashrc i3 i3blocks kitty mimeapps.list nvim picom rofi \
        tmux user-dirs.dirs user-dirs.locale wp xournalpp zathura; do
        ensure_link "$REPO_DIR/config/$item" "$HOME/.config/$item"
    done
}

step_default_shell() {
    local bash
    bash=$(command -v bash) || die "bash no instalado"
    if [[ $(getent passwd "$USER" | cut -d: -f7) == "$bash" ]]; then return 0; fi
    sudo chsh -s "$bash" "$USER"
    mark
    ok "shell por defecto: $bash (cierra la sesion para aplicarlo)"
}

step_power_button() {
    local before=$CHANGES
    set_conf /etc/systemd/logind.conf HandlePowerKey ignore "[Login]"
    # reiniciar logind es disruptivo: solo si el fichero ha cambiado de verdad
    if changed_since "$before"; then sudo systemctl restart systemd-logind; fi
}

step_grub() {
    local before=$CHANGES
    set_conf /etc/default/grub GRUB_TIMEOUT 0
    set_conf /etc/default/grub GRUB_TIMEOUT_STYLE hidden
    if changed_since "$before"; then sudo update-grub; fi
}

# el stylus se mapea solo a la pantalla secundaria: en las dos es inservible
step_asus_pen() {
    ensure_file /etc/X11/xorg.conf.d/50-asus-pen.conf <<'EOF'
Section "InputClass"

      Identifier "ASUS SPEN"
      MatchProduct "ELAN9009:00 04F3:2C58"
      Driver "wacom"
      Option "Gesture" "off"

EndSection
EOF
}

step_tlp() {
    if systemctl is-active --quiet power-profiles-daemon; then
        sudo systemctl disable --now power-profiles-daemon
        mark
    fi
    ensure_service tlp
}

# efectos que dejan los fixes: initrd parcheado, modulos externos para este
# kernel, reglas de modprobe/udev y los parametros de grub.
hardware_fixes_present() {
    local kernel=$1 f
    for f in /boot/fix-acpi-override.cpio \
        "/lib/modules/$kernel/updates/drivers/misc/cardreader/rtsx_pci.ko" \
        "/lib/modules/$kernel/updates/drivers/mmc/host/rtsx_pci_sdmmc.ko" \
        /etc/modprobe.d/nvidia.conf \
        /etc/systemd/system/nvidia-persistenced.service.d/10-fix-gpu.conf \
        /etc/udev/rules.d/99-gpu-mx250.rules \
        /etc/udev/rules.d/91-nvidia-persistenced.rules \
        /etc/udev/rules.d/99-sd-card-reader.rules; do
        [[ -f $f ]] || return 1
    done
    for f in acpi_osi=Linux pcie_aspm=off pcie_port_pm=off; do
        grep -q -- "$f" /etc/default/grub || return 1
    done
}

# fixes de hardware: tocan initrd, grub y modulos del kernel, asi que se
# saltan mientras sus efectos sigan en su sitio (si editas los scripts, o con
# --force, se vuelven a aplicar).
step_hardware_fixes() {
    if ((WITH_HARDWARE == 0)); then skip "fixes de hardware (--no-hardware)"; return 0; fi
    local dir=$REPO_DIR/config/bashrc/fix kernel
    [[ -d $dir ]] || die "no existe $dir"

    kernel=$(uname -r)
    if ((FORCE == 0)) && hardware_fixes_present "$kernel"; then
        skip "fixes de hardware: ya aplicados en $kernel"
        return 0
    fi

    log "fixes de hardware (compilan modulos, puede tardar)"
    sudo bash "$dir/fix-acpi.sh"
    sudo bash "$dir/fix-sd-reader.sh"
    sudo bash "$dir/fix-gpu.sh"
    mark
}

# -------------------------------------------------------------------- main ---
# STEPS: nombre:funcion:descripcion. el nombre es lo que vale en --only (se
# compara por prefijo) y lo que muestra --list. la descripcion no puede llevar
# dos puntos porque es el separador.
STEPS=(
    "system:step_upgrade_system:apt upgrade del sistema"
    "packages:step_install_packages:instala los paquetes (y el repo de librewolf) y los headers del kernel"
    "nvim:step_nvim_nightly:actualiza neovim al ultimo nightly"
    "dkms:step_asus_wmi_screenpad:modulo asus-wmi-screenpad y regla udev de los leds"
    "network:step_networkmanager:habilita y arranca NetworkManager"
    "bluetooth:step_bluetooth:habilita y arranca bluetooth"
    "pipewire:step_pipewire:habilita pipewire y wireplumber (usuario)"
    "tailscale:step_tailscale:tailscaled por socket y sin autoarranque"
    "dotfiles:step_dotfiles:symlinks de los dotfiles en ~"
    "shell:step_default_shell:bash como shell por defecto"
    "logind:step_power_button:el boton de encendido no apaga"
    "grub:step_grub:grub sin espera (timeout 0)"
    "pen:step_asus_pen:el stylus solo en la pantalla secundaria"
    "tlp:step_tlp:tlp en vez de power-profiles-daemon"
    "hardware-fixes:step_hardware_fixes:fixes de hardware (acpi, sd reader, gpu)"
    "hide-desktop:step_hide_desktop:oculta lanzadores del menu (libreoffice, kitty, rofi...)"
)

# --list: los pasos con su descripcion, alineados. no toca nada ni pide sudo.
list_steps() {
    local step name fn desc max=0
    for step in "${STEPS[@]}"; do
        IFS=: read -r name fn desc <<<"$step"
        if ((${#name} > max)); then max=${#name}; fi
    done
    printf 'pasos (./install.sh --only <nombre o prefijo>):\n\n'
    for step in "${STEPS[@]}"; do
        IFS=: read -r name fn desc <<<"$step"
        printf '  %-*s  %s\n' "$max" "$name" "$desc"
    done
}

run_step() {
    local name=$1 fn=$2 before=$CHANGES want match=0
    for want in "${ONLY[@]}"; do
        if [[ $name == "$want"* ]]; then match=1; fi
    done
    if [[ ${#ONLY[@]} -gt 0 && $match -eq 0 ]]; then return 0; fi

    log "$name"
    "$fn"
    if ((CHANGES > before)); then APPLIED+=("$name"); else DONE+=("$name"); fi
}

banner() {
    [[ -t 1 ]] || return 0
    local colors=(196 202 226 46 51 21 201) line i=0
    while IFS= read -r line; do
        printf '\e[38;5;%sm%s\e[0m\n' "${colors[i++ % ${#colors[@]}]}" "$line"
    done <<'EOF'
       ___           _        _ _       _
      / (_)         | |      | | |     | |
     / / _ _ __  ___| |_ __ _| | |  ___| |__
    / / | | '_ \/ __| __/ _` | | | / __| '_ \
 _ / /  | | | | \__ \ || (_| | | |_\__ \ | | |
(_)_/   |_|_| |_|___/\__\__,_|_|_(_)___/_| |_|
                                    by josemri
EOF
}

main() {
    if ((LIST)); then list_steps; return 0; fi
    if [[ $EUID -eq 0 ]]; then die "no lo ejecutes como root, ejecuta con tu usuario"; fi
    sudo -v || die "hace falta acceso a sudo"

    banner
    local step name fn _
    for step in "${STEPS[@]}"; do
        IFS=: read -r name fn _ <<<"$step"
        run_step "$name" "$fn"
    done

    echo
    log "resumen: ${#APPLIED[@]} aplicados, ${#DONE[@]} ya estaban"
    if [[ ${#APPLIED[@]} -gt 0 ]]; then printf '   aplicados:  %s\n' "${APPLIED[*]}"; fi
    if [[ ${#DONE[@]} -gt 0 ]]; then printf '   sin cambios: %s\n' "${DONE[*]}"; fi
}

main "$@"
