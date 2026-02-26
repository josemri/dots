#!/usr/bin/env bash

set -euo pipefail

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
    pipewire-audio \
    wireplumber \
    qutebrowser \
	bluez \
	bluez-tools \
    ripgrep \
    fd-find \
	fzf \
	xorg


success "base packages installed"

# --------------------------------------------------
# NVIM NIGHTLY
# --------------------------------------------------
install_neovim_nightly() {
    log "Neovim nightly..."

    cd /tmp
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz

    rm -rf /opt/nvim-linux64
    tar -C /opt -xzf nvim-linux64.tar.gz

    ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim

    success "Neovim nightly installed"
}

# --------------------------------------------------
# ASUS WMI SCREENPAD
# --------------------------------------------------
install_asus_wmi_screenpad() {
    log "asus-wmi-screenpad..."

    mkdir -p /usr/src/asus-wmi-1.0
    cd /usr/src/asus-wmi-1.0
    wget 'https://github.com/Plippo/asus-wmi-screenpad/archive/master.zip'
    unzip master.zip
    mv asus-wmi-screenpad-master/* .
    rmdir asus-wmi-screenpad-master
    rm master.zip

	sh prepare-for-current-kernel.sh
	dkms add -m asus-wmi -v 1.0
	dkms build -m asus-wmi -v 1.0
    dkms install -m asus-wmi -v 1.0

	mkdir -p /etc/udev/rules.d
	sudo tee "/etc/udev/rules.d/99-asus.rules" > /dev/null << 'EOF'
# rules for asus_nb_wmi devices

# make screenpad backlight brightness write-able by everyone
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
EOF
	
    success "asus-wmi-screenpad installed"
}

# --------------------------------------------------
# PIPEWIRE CONFIG
# --------------------------------------------------
configure_pipewire() {
    log "Configuring PipeWire..."

	sudo -u "$SUDO_USER" systemctl --user enable --now pipewire wireplumber

    success "PipeWire configured"
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
    else
        log "Dotfiles repo already exists, pulling latest..."
        cd dots
        git pull
        cd ..
    fi

    # Ensure .config exists
    mkdir -p "$USER_HOME/.config"

    # Link files in HOME
    ln -sf "$USER_HOME/dots/.p10k.zsh" "$USER_HOME/.p10k.zsh"
    ln -sf "$USER_HOME/dots/.zshrc" "$USER_HOME/.zshrc"

    # Link folders and files in .config
    for item in bashrc dunst i3 i3blocks img2.jpg kitty nvim picom rofi tmux xournalpp zathura user-dirs.dirs user-dirs.locale mimeapps.list, nitrogen; do
        [ -e "$USER_HOME/dots/config/$item" ] && ln -sf "$USER_HOME/dots/config/$item" "$USER_HOME/.config/$item"
    done

    success "Dotfiles linked!"
}

asus_pen() {
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

# --------------------------------------------------
# MAIN
# --------------------------------------------------

install_neovim_nightly
install_asus_wmi_screenpad
configure_networkmanager
configure_pipewire
configure_bluetooth
install_dotfiles
asus_pen

rm -rf /tmp/*
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.config"
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/dots"

success "completed correctly"
