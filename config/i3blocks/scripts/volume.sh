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
    echo "vol:[$BAR]"
else
    # Extraer número del formato "Volume: 1.25"
    vol=$(echo $info | grep -oP '[0-9.]+')
    vol_percent=$(printf "%.0f" $(echo "$vol*100" | bc))
    filled=$(( (vol_percent*BAR_LENGTH + 50)/100 ))
    empty=$(( BAR_LENGTH-filled ))
    BAR=
    for ((i = 0; i < filled; i++)); do BAR+=█; done
    for ((i = 0; i < empty; i++)); do BAR+=░; done
    echo "vol:[$BAR $(printf '%3d' "$vol_percent")]"
fi
echo
echo "#ffffff"

