#!/bin/bash

BAR_LENGTH=10

# Obtener info del volumen
volume_info=$(wpctl get-volume @DEFAULT_SINK@)

# Comprobar si está muteado
if echo "$volume_info" | grep -q "MUTED"; then
    icon="󰝟"
    volume_percentage=0
else
    # Extraer decimal
    volume_decimal=$(echo "$volume_info" | awk '{print $2}')

    volume_percentage=${volume_decimal#0.}   # quita el "0."
    if [ ${#volume_percentage} -eq 1 ]; then
        volume_percentage=$((volume_percentage * 10))
    fi

    if (( volume_percentage < 30 )); then
        icon="󰕿"
    elif (( volume_percentage < 70 )); then
        icon="󰖀"
    else
        icon="󰕾"
    fi
fi

# Calcular barra
FILLED=$((volume_percentage * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))
BAR=$(printf '%0.s ' $(seq $EMPTY))$(printf '%0.s█' $(seq $FILLED))

echo "[$BAR]$icon "
echo
echo "#ffffff"

