#!/usr/bin/env bash

set -euo pipefail
USER_HOME=$(eval echo ~${SUDO_USER})
LOG_FILE="/var/log/setup.log"

# -------- COLORS --------
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

log() {
    echo -e "${BLUE}[INFO]${RESET} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
    echo "[OK] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
    echo "[WARN] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
    exit 1
}

trap 'error "error at line: $LINENO"' ERR

# -------- ROOT CHECK --------
if [[ $EUID -ne 0 ]]; then
    echo "exec as root"
    exit 1
fi

show_banner() {
   local colors=(196 202 226 46 51 21 201)
   local i=0
   
   while IFS= read -r line; do
       color=${colors[$((i % ${#colors[@]}))]}
       echo -e "\e[38;5;${color}m${line}\e[0m"
       i=$((i+1))
   done << "EOF"
       ___           _        _ _       _     
      / (_)         | |      | | |     | |    
     / / _ _ __  ___| |_ __ _| | |  ___| |__  
    / / | | '_ \/ __| __/ _` | | | / __| '_ \ 
 _ / /  | | | | \__ \ || (_| | | |_\__ \ | | |
(_)_/   |_|_| |_|___/\__\__,_|_|_(_)___/_| |_|
                                   by josemri
                                              
EOF
}

show_banner
log "updating system..."
apt update && apt upgrade -y
success "system updated"



# -------- BASE --------

apt install -y linux-headers-$(uname -r)

log "base packages..."

apt install -y \
    tmux \
    i3 \
    i3blocks \
    zsh \
    git \
    kitty \
    picom \
    xournalpp \
    dunst \
    rofi \
    keepass2 \
    libreoffice \
    thunderbird \
    zathura \
    nitrogen \
    xfce4-screenshooter \
    brightnessctl \
    xclip \
    i3lock \
    network-manager \
    unzip \
    zip \
    curl \
    wget \
    dkms \
    build-essential \
    pipewire \
    wireplumber \
    qutebrowser \
	bluez \
    ripgrep \
	fzf \
	xorg \
	trash-cli \
	ffmpeg \
	ncdu \
	fuse \



success "base packages installed"

# --------------------------------------------------
# NVIM NIGHTLY
# --------------------------------------------------
install_neovim_nightly() {
    log "Neovim nightly..."

    cd /tmp
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage

    if [ ! -d "$USER_HOME/.local/bin" ]; then
        mkdir -p "$USER_HOME/.local/bin"
    fi

    mv nvim-linux-x86_64.appimage "$USER_HOME/.local/bin/nvim"
    chown "$SUDO_USER:$SUDO_USER" "$USER_HOME/.local/bin/nvim"

    success "Neovim nightly installed"
}

# --------------------------------------------------
# ASUS WMI SCREENPAD
# --------------------------------------------------
install_asus_wmi_screenpad() {
    log "asus-wmi-screenpad..."

    MODULE="asus-wmi"
    VERSION="1.0"
    SRC_DIR="/usr/src/${MODULE}-${VERSION}"

    # delete if allready installed
    if dkms status | grep -q "${MODULE}/${VERSION}"; then
        log "Existing DKMS module detected. Removing..."

        dkms remove -m "$MODULE" -v "$VERSION" --all || true
    fi

    if [ -d "$SRC_DIR" ]; then
        log "Removing existing source directory..."
        rm -rf "$SRC_DIR"
    fi

    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR" || exit 1

    wget -q https://github.com/Plippo/asus-wmi-screenpad/archive/master.zip -O master.zip
    unzip -q master.zip
    mv asus-wmi-screenpad-master/* .
    rm -rf asus-wmi-screenpad-master master.zip

    sh prepare-for-current-kernel.sh

    dkms add -m "$MODULE" -v "$VERSION"
    dkms build -m "$MODULE" -v "$VERSION"
    dkms install -m "$MODULE" -v "$VERSION"

    # Udev rule
    mkdir -p /etc/udev/rules.d
    tee /etc/udev/rules.d/99-asus.rules > /dev/null << 'EOF'
# rules for asus_nb_wmi devices

ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
EOF

    success "asus-wmi-screenpad installed (fresh install)"
}

# PIPEWIRE CONFIG
configure_pipewire() {
    log "Configuring PipeWire..."

    # Habilitar para que arranque automáticamente en el próximo login del usuario
    sudo -u "$SUDO_USER" systemctl --user enable pipewire wireplumber || {
        warn "Could not enable user services, they will start on next login."
    }

    success "PipeWire will start automatically on next login"
}

configure_bluetooth() {
    log "configuring bluetooth..."

	systemctl enable bluetooth
    systemctl start bluetooth

	success "bluetooth configured"
}

configure_networkmanager() {
   log "configuring networkmanager..."
   
   systemctl enable NetworkManager
   systemctl start NetworkManager
   
   success "networkmanager configured"
}

install_dotfiles() {
    log "Configuring my dotfiles!"

    USER_HOME=$(eval echo ~${SUDO_USER})

    cd "$USER_HOME"

    # Clone repo if not exists
    if [ ! -d dots ]; then
        git clone https://github.com/josemri/dots.git
	fi

    # Ensure .config exists
    mkdir -p "$USER_HOME/.config"

    # Link files in HOME
    ln -sf "$USER_HOME/dots/.p10k.zsh" "$USER_HOME/.p10k.zsh"
    ln -sf "$USER_HOME/dots/.zshrc" "$USER_HOME/.zshrc"

    # Link folders and files in .config
    for item in bashrc dunst i3 i3blocks img2.jpg kitty nvim picom rofi tmux xournalpp zathura user-dirs.dirs user-dirs.locale mimeapps.list; do
        ln -sf "$USER_HOME/dots/config/$item" "$USER_HOME/.config/$item"
    done

    success "Dotfiles linked!"
}


asus_pen() {
   log "Configuring asus_pen conf"
   mkdir -p /etc/X11/xorg.conf.d
   tee "/etc/X11/xorg.conf.d/50-asus-pen.conf" > /dev/null << 'EOF'
Section "InputClass"

      Identifier "ASUS SPEN"
      MatchProduct "ELAN9009:00 04F3:2C58"
      Driver "wacom"
      Option "Gesture" "off"

EndSection
EOF
}

set_default_shell() {
    log "Setting zsh as default shell..."

    ZSH_PATH=$(command -v zsh)

    if [ -z "$ZSH_PATH" ]; then
        error "zsh not found"
    fi

    chsh -s "$ZSH_PATH" "$SUDO_USER"

    success "Default shell changed to zsh"
}

configure_power_button() {
    log "Configuring power button behavior..."

    LOGIND_CONF="/etc/systemd/logind.conf"

    if grep -q "^[#]*HandlePowerKey=" "$LOGIND_CONF"; then
        # Descomenta y cambia el valor
        sed -i 's|^[#]*HandlePowerKey=.*|HandlePowerKey=ignore|' "$LOGIND_CONF"
    else
        # Si no existe la línea, la añadimos
        echo "HandlePowerKey=ignore" >> "$LOGIND_CONF"
    fi

    systemctl restart systemd-logind

    success "Power button will no longer shut down the system"
}

configure_grub() {
    log "Configuring GRUB (no timeout)..."

    GRUB_FILE="/etc/default/grub"

    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_FILE"

    if grep -q "^GRUB_TIMEOUT_STYLE=" "$GRUB_FILE"; then
        sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$GRUB_FILE"
    else
        echo "GRUB_TIMEOUT_STYLE=hidden" >> "$GRUB_FILE"
    fi

    update-grub

    success "GRUB configured to boot instantly"
}



# --------------------------------------------------
# MAIN
# --------------------------------------------------

install_neovim_nightly
install_asus_wmi_screenpad
configure_networkmanager
configure_pipewire
configure_bluetooth
install_dotfiles
set_default_shell
configure_power_button
configure_grub
asus_pen

rm -rf /tmp/*
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.config"
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/dots"

success "completed correctly"
