#!/bin/bash

# Obtener conexión activa en wlo1
connection_info=$(nmcli -t -f name,device connection show --active | grep wlo1)

# Si no hay conexión
if [ "$connection_info" ]; then
    # Obtener SSID
    ssid=$(echo "$connection_info" | cut -d: -f1)
    
    # Obtener fuerza de señal (0-100)
    signal_strength=$(nmcli -f IN-USE,SIGNAL dev wifi | grep '*' | awk '{print $2}')
    [ -z "$signal_strength" ] && signal_strength=59

    # Elegir icono según intensidad
    case $signal_strength in
        [0-9]|1[0-9]|2[0-9])
            icon="󰤟"
            ;;
        3[0-9]|4[0-9]|5[0-9])
            icon="󰤢"
            ;;
        6[0-9]|7[0-9]|8[0-9])
            icon="󰤥"
            ;;
        9[0-9]|100)
            icon="󰤨"
            ;;
    esac

    # Mostrar SSID e icono
    echo "[$ssid]$icon  "
    echo
    echo "#ffffff"
fi

