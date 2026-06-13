#!/usr/bin/env bash

# Obtener estado del WiFi
wifi_state() {
    nmcli radio wifi
}

# Listar redes disponibles
list_networks() {
    nmcli -t -f SSID,BARS device wifi list | sed '/^:/d' |
    awk -F: '{
        if ($1 == "") next;
        printf "%-6s %s\n", $2, $1
    }'
}

menu() {
    if [[ "$(nmcli -t -f WIFI g)" == "enabled" ]]; then
        printf "connect\nmanual\ndisable\n"
    else
        printf "manual\nenable\n"
    fi | rofi -dmenu -p "[net]"
}

# Conectar a red seleccionada
connect_network() {
    local selected
    selected=$(list_networks | rofi -dmenu -p "Red")
    [ -z "$selected" ] && exit

    # Extraer el SSID: eliminar el primer campo (barras) y los espacios iniciales
    SSID=$(echo "$selected" | awk '{$1=""; sub(/^ /, ""); print}')
    [ -z "$SSID" ] && exit

    PASS=$(rofi -p "" -password -no-fixed-num-lines -dmenu <<< "")
    if [ -z "$PASS" ]; then
        nmcli dev wifi connect "$SSID"
    else
        nmcli dev wifi connect "$SSID" password "$PASS"
    fi
}

# Main
choice=$(menu)

case "$choice" in
    "enable")
        nmcli radio wifi on
        ;;

    "disable")
        nmcli radio wifi off
        ;;

    "connect")
        connect_network
        ;;

    "manual")
		  kitty --class nmtui-term -e nmtui &
        ;;

    *)
        exit 0
        ;;
esac
