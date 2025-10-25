#!/bin/bash

# Obtiene el estado del Bluetooth
status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
connected_device=$(bluetoothctl info | grep "Name" | awk -F': ' '{print $2}')

if [[ "$status" == "yes" ]]; then
    if [[ -n "$connected_device" ]]; then
        # Bluetooth conectado a un dispositivo
        text=" Conectado a $connected_device"
        color="#7bbd90"
    else
        # Bluetooth encendido pero sin conexiones
        text=" Encendido"
        color="#6caef0"
    fi
else
    # Bluetooth apagado
    text=" Apagado"
    color="#ff6f6f"
fi

# Produce JSON válido
echo "{\"full_text\": \"$text\", \"background\": \"$color\", \"color\": \"#ffffff\"}"

