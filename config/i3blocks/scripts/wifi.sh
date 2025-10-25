#!/bin/bash

connection_info=$(nmcli -t -f name,device connection show --active | grep wlo1)
if [ -z "$connection_info" ]; then
echo "<span background='#fdffb6' font_weight='bold'> 󰤭 </span><span background='#fdffb6' font_weight='bold'>none </span>"
else
    ssid=$(echo "$connection_info" | cut -d: -f1)
    signal_strength=$(nmcli -f IN-USE,SIGNAL dev wifi | grep '*' | awk '{print $2}')

     if [ -z "$signal_strength" ]; then
        signal_strength="59"
    fi

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

    echo "<span background='#fdffb6' font_weight='bold'> $icon </span><span background='#fdffb6' font_weight='bold'>$ssid </span>"
    #${signal_strength}%
fi

