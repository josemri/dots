#!/bin/bash

case $BLOCK_BUTTON in
  1) wpctl set-mute @DEFAULT_SINK@ toggle ;;
esac


BAR_LENGTH=10
info=$(wpctl get-volume @DEFAULT_SINK@)

if [[ $info == *MUTED* ]]; then
    # Centrar "MUTE" en una barra de longitud BAR_LENGTH
    left=$(( (BAR_LENGTH-4)/2 ))
    right=$(( BAR_LENGTH-4-left ))
    BAR=$(printf '%*sMUTE%*s' $left '' $right '')
else
    # Extraer número del formato "Volume: 1.25"
    vol=$(echo $info | grep -oP '[0-9.]+')
    
    if [[ $vol == "0.00" ]]; then
        # Barra vacía
        BAR=$(printf ' %.0s' $(seq 1 $BAR_LENGTH))
    elif [[ $vol == "1.00" ]]; then
        # Barra completamente llena
        BAR=$(printf '█%.0s' $(seq 1 $BAR_LENGTH))
    else
        # Calcular barra normalmente
        vol_percent=$(printf "%.0f" $(echo "$vol*100" | bc))
        filled=$(( (vol_percent*BAR_LENGTH + 50)/100 ))
        empty=$(( BAR_LENGTH-filled ))
	BAR=$(printf ' %.0s' $(seq 1 $empty))$(printf '█%.0s' $(seq 1 $filled))
    fi
fi

echo "vol:[$BAR]"
echo
echo "#ffffff"

