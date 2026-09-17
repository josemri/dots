#!/usr/bin/env bash

set -euo pipefail

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
    git \
    kitty \
    picom \
    xournalpp \
    dunst \
    rofi \
    keepass2 \
    libreoffice \
    firefox-esr \
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
    bluez \
    ripgrep \
    fzf \
    xorg \
    zsh \
    trash-cli \
    ffmpeg \
    ncdu \
    fuse \
    fastfetch \
    libnotify-bin \
    ncal \
    libspa-0.2-bluetooth \
    jq \
    bc \
    tlp

success "base packages installed"

# --------------------------------------------------
# NVIM NIGHTLY
# --------------------------------------------------
install_neovim_nightly() {
    log "Neovim nightly..."

    cd /tmp
    curl -fsSL -o nvim.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
    sudo rm -rf /usr/local/nvim-linux-x86_64 /usr/local/bin/nvim
    sudo tar -xzf nvim.tar.gz -C /usr/local
    sudo ln -sf /usr/local/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f nvim.tar.gz

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
    DKMS_TREE="/var/lib/dkms/${MODULE}"

    # Reset COMPLETO e idempotente de una instalacion previa.
    # dkms vive en /usr/sbin (fuera del PATH del usuario): siempre via sudo.
    # No se confia en `dkms status` (puede quedar inconsistente tras un fallo
    # y no listar el modulo aunque el arbol exista): se fuerza la limpieza.
    log "Removing any previous ${MODULE} install (DKMS + source)..."
    sudo dkms remove -m "$MODULE" -v "$VERSION" --all 2>/dev/null || true
    sudo rm -rf "$DKMS_TREE"
    sudo rm -rf "$SRC_DIR"

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

    sudo dkms add -m "$MODULE" -v "$VERSION" --force
    sudo dkms build -m "$MODULE" -v "$VERSION"
    sudo dkms install -m "$MODULE" -v "$VERSION" --force

    # Udev rule
    sudo mkdir -p /etc/udev/rules.d
    sudo tee /etc/udev/rules.d/99-asus.rules > /dev/null << 'EOF'
# rules for asus_nb_wmi devices

ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::screenpad", RUN+="/bin/chmod a+w /sys/class/leds/%k/brightness"
EOF

    success "asus-wmi-screenpad installed"
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

configure_tailscale_boot() {
    log "Configuring tailscale socket activation..."

    if ! command -v tailscale >/dev/null 2>&1; then
        warn "tailscale not installed, skipping socket activation"
        return 0
    fi

    # Socket: escucha en el control socket, arranca con sockets.target (~0s at boot)
    sudo tee /etc/systemd/system/tailscaled.socket > /dev/null << 'EOF'
[Unit]
Description=Tailscale Socket

[Socket]
ListenStream=/run/tailscale/tailscaled.sock
SocketMode=0666

[Install]
WantedBy=sockets.target
EOF

    # Drop-in: servicio activado por socket (no arranca solo al boot)
    sudo mkdir -p /etc/systemd/system/tailscaled.service.d
    sudo tee /etc/systemd/system/tailscaled.service.d/20-socket-activate.conf > /dev/null << 'EOF'
[Unit]
Wants=tailscaled.socket

[Service]
Sockets=tailscaled.socket
EOF

    # Deshabilitar y PARAR el servicio -> el daemon suelta el control socket.
    # Si se deja corriendo, el socket ya esta en uso y arrancar la unit .socket
    # falla con 'Job failed' (bind en uso).
    sudo systemctl disable --now tailscaled.service 2>/dev/null || true
    sudo systemctl enable --now tailscaled.socket

    success "tailscale socket-activated (inicia al primer uso, 0s en boot)"
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

setup_zsh() {
    log "Setting up zsh / oh-my-zsh / powerlevel10k..."

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    fi

    mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"

    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi

    for p in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
        [ -d "$ZSH_CUSTOM/plugins/$p" ] || \
            git clone --depth=1 "https://github.com/zsh-users/$p.git" "$ZSH_CUSTOM/plugins/$p"
    done

    success "zsh configured"
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

    sudo chsh -s "$ZSH_PATH" "$USER"

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

enable_tlp() {
    log "Enabling TLP (battery optimization)..."

    sudo systemctl disable --now power-profiles-daemon 2>/dev/null || true
    sudo systemctl enable --now tlp

    success "TLP active"
}

install_gpu_switch() {
    log "Installing gpu-switch command..."

    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/dots/config/bashrc/gpu-switch.sh" "$HOME/.local/bin/gpu-switch"

    success "gpu-switch available as 'gpu-switch'"
}

run_hardware_fixes() {
    log "Applying hardware fixes (ASUS UX481FL)..."

    FIX_DIR="$HOME/dots/config/bashrc/fix"
    [ -d "$FIX_DIR" ] || error "fix dir not found: $FIX_DIR"

    sudo bash "$FIX_DIR/fix-acpi.sh"
    sudo bash "$FIX_DIR/fix-sd-reader.sh"
    sudo bash "$FIX_DIR/fix-gpu.sh"

    success "Hardware fixes applied (REBOOT required)"
}

# --------------------------------------------------
# MAIN
# --------------------------------------------------

#install_neovim_nightly
#install_asus_wmi_screenpad
#configure_networkmanager
configure_tailscale_boot
#configure_pipewire
#configure_bluetooth
#install_dotfiles
#setup_zsh
#set_default_shell
#configure_power_button
#configure_grub
#asus_pen
#enable_tlp
#install_gpu_switch
#run_hardware_fixes

success "completed correctly"
