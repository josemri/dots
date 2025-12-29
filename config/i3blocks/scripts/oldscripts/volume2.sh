#!/bin/bash

# Largo de la barra
BAR_LENGTH=10

# Obtener info del volumen
volume_info=$(amixer get Master)
if echo "$volume_info" | grep -q '\[off\]'; then
    icon="󰝟"
    volume_percentage=0
else
    volume_percentage=$(echo "$volume_info" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]%' )
    case $volume_percentage in
        [0-9]|1[0-9]|2[0-9])
            icon="󰕿"
            ;;
        3[0-9]|4[0-9]|5[0-9]|6[0-9])
            icon="󰖀"
            ;;
        7[0-9]|8[0-9]|9[0-9]|100)
            icon="󰕾"
            ;;
    esac
fi

# Calcular barra de progreso
FILLED=$((volume_percentage * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))
BAR=$(printf '%0.s ' $(seq $EMPTY))$(printf '%0.s█' $(seq $FILLED))

# Mostrar barra y porcentaje
echo "[$BAR]$icon  "
echo
echo "#ffffff"

