#!/usr/bin/env bash

set -euo pipefail
USER_HOME="$HOME"

# -------- COLORS --------
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

log() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
    exit 1
}

trap 'error "error at line: $LINENO"' ERR

# -------- USER CHECK --------
if [[ $EUID -eq 0 ]]; then
    echo "do not run as root, run as your user"
    exit 1
fi

if ! sudo -v 2>/dev/null; then
    echo "sudo access required"
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
sudo apt update && sudo apt upgrade -y
success "system updated"



# -------- BASE --------

sudo apt install -y linux-headers-$(uname -r)

log "base packages..."

sudo apt install -y \
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
    pipewire-pulse \
    qutebrowser \
    bluez \
    ripgrep \
    fzf \
    xorg \
    trash-cli \
    ffmpeg \
    ncdu \
    fuse \
    fastfetch \
    libnotify-bin \
    ncal \
    libspa-0.2-bluetooth \
    jq \
    bc


success "base packages installed"

# --------------------------------------------------
# NVIM NIGHTLY
# --------------------------------------------------
install_neovim_nightly() {
    log "Neovim nightly..."

    cd /tmp
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    sudo mv nvim-linux-x86_64.appimage "/usr/local/bin/"

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
        sudo dkms remove -m "$MODULE" -v "$VERSION" --all || true
    fi

    if [ -d "$SRC_DIR" ]; then
        log "Removing existing source directory..."
        sudo rm -rf "$SRC_DIR"
    fi

    WORK_DIR=$(mktemp -d)
    cd "$WORK_DIR"

    wget -q https://github.com/Plippo/asus-wmi-screenpad/archive/master.zip -O master.zip
    unzip -q master.zip
    mv asus-wmi-screenpad-master/* .
    rm -rf asus-wmi-screenpad-master master.zip

    sh prepare-for-current-kernel.sh

    sudo mkdir -p "$SRC_DIR"
    sudo cp -r . "$SRC_DIR/"
    cd /
    rm -rf "$WORK_DIR"

    sudo dkms add -m "$MODULE" -v "$VERSION"
    sudo dkms build -m "$MODULE" -v "$VERSION"
    sudo dkms install -m "$MODULE" -v "$VERSION"

    # Udev rule
    sudo mkdir -p /etc/udev/rules.d
    sudo tee /etc/udev/rules.d/99-asus.rules > /dev/null << 'EOF'
# rules for asus_nb_wmi devices

ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
EOF

    success "asus-wmi-screenpad installed (fresh install)"
}

# PIPEWIRE CONFIG
configure_pipewire() {
    log "Configuring PipeWire..."

    systemctl --user enable pipewire wireplumber || {
        warn "Could not enable user services, they will start on next login."
    }

    success "PipeWire will start automatically on next login"
}

configure_bluetooth() {
    log "configuring bluetooth..."

    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth

    success "bluetooth configured"
}

configure_networkmanager() {
   log "configuring networkmanager..."
   
   sudo systemctl enable NetworkManager
   sudo systemctl start NetworkManager
   
   success "networkmanager configured"
}

install_dotfiles() {
    log "Configuring my dotfiles!"

    cd "$HOME"

    # Clone repo if not exists
    if [ ! -d dots ]; then
        git clone https://github.com/josemri/dots.git
    fi

    # Ensure .config exists
    mkdir -p "$HOME/.config"

    # Link files in HOME
    for file in .p10k.zsh .zshrc; do
        SRC="$HOME/dots/$file"
        DEST="$HOME/$file"

        [ -e "$DEST" ] || [ -L "$DEST" ] && rm -rf "$DEST"
        ln -s "$SRC" "$DEST"
    done

    # Link folders and files in .config
    for item in bashrc dunst i3 i3blocks img2.jpg kitty nvim picom rofi xournalpp zathura user-dirs.dirs user-dirs.locale mimeapps.list; do
        SRC="$HOME/dots/config/$item"
        DEST="$HOME/.config/$item"

        if [ -e "$DEST" ] || [ -L "$DEST" ]; then
            rm -rf "$DEST"
        fi

        ln -s "$SRC" "$DEST"
    done

    success "Dotfiles linked!"
}


asus_pen() {
   log "Configuring asus_pen conf"
   sudo mkdir -p /etc/X11/xorg.conf.d
   sudo tee "/etc/X11/xorg.conf.d/50-asus-pen.conf" > /dev/null << 'EOF'
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

    chsh -s "$ZSH_PATH"

    success "Default shell changed to zsh"
}

configure_power_button() {
    log "Configuring power button behavior..."

    LOGIND_CONF="/etc/systemd/logind.conf"

    if sudo grep -q "^[#]*HandlePowerKey=" "$LOGIND_CONF"; then
        sudo sed -i 's|^[#]*HandlePowerKey=.*|HandlePowerKey=ignore|' "$LOGIND_CONF"
    else
        echo "HandlePowerKey=ignore" | sudo tee -a "$LOGIND_CONF" > /dev/null
    fi

    sudo systemctl restart systemd-logind

    success "Power button will no longer shut down the system"
}

configure_grub() {
    log "Configuring GRUB (no timeout)..."

    GRUB_FILE="/etc/default/grub"

    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$GRUB_FILE"

    if sudo grep -q "^GRUB_TIMEOUT_STYLE=" "$GRUB_FILE"; then
        sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$GRUB_FILE"
    else
        echo "GRUB_TIMEOUT_STYLE=hidden" | sudo tee -a "$GRUB_FILE" > /dev/null
    fi

    sudo update-grub

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

rm -f /tmp/nvim-linux-x86_64.appimage

success "completed correctly"
