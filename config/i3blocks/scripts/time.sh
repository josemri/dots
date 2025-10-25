!/bin/bash

TIME=$(date '+%H:%M')

if [ "$BLOCK_BUTTON" == "1" ]; then
    # Abre rofi con clic izquierdo
    exec terminator -x gnome-calculator
fi

echo "<span background='#ffc6ff' font_weight='bold'> $TIME </span>"


