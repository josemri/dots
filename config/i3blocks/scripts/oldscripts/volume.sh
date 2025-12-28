#!/bin/bash
volume_info=$(amixer get Master)
if echo "$volume_info" | grep -q '\[off\]'; then
    echo "<span background='#9bf6ff' font_weight='bold'> 󰝟 </span><span background='#9bf6ff' font_weight='bold'>mute </span>"
else
    volume_percentage=$(echo "$volume_info" | grep -oP '\[\d+%\]' | head -1 | tr -d '[]' | tr -d '%')
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
    echo "<span background='#9bf6ff' font_weight='bold'> $icon </span><span background='#9bf6ff' font_weight='bold'>$volume_percentage% </span>"
fi
