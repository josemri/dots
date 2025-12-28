#!/bin/bash
battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)
charging_status=$(cat /sys/class/power_supply/BAT0/status)

if [ "$charging_status" == "Charging" ]; then
	case $battery_percentage in
	[0-9])
		icon="󰢟"
		;;
	1[0-9])
    		icon="󰢜"
    		;;
	2[0-9])
    		icon="󰂆"
    		;;
      	3[0-9])
    		icon="󰂇"
    		;;
   	4[0-9])
    		icon="󰂈"
    		;;
   	5[0-9])
    		icon="󰢝"
    		;;
      	6[0-9])
    		icon="󰂉"
    		;;
   	7[0-9])
    		icon="󰢞"
    		;;
   	8[0-9])
    		icon="󰂊"
    		;;
    	9[0-9])
    		icon="󰂋"
    		;;
    	100)
    		icon="󰁹"
    		;;
	esac
else
    case $battery_percentage in
    	[0-9])
		icon="󰂎"
		;;
	1[0-9])
    		icon="󰁺"
    		;;
	2[0-9])
    		icon="󰁻"
    		;;
      	3[0-9])
    		icon="󰁼"
    		;;
   	4[0-9])
    		icon="󰁽"
    		;;
   	5[0-9])
    		icon="󰁾"
    		;;
      	6[0-9])
    		icon="󰁿"
    		;;
   	7[0-9])
    		icon="󰂀"
    		;;
   	8[0-9])
    		icon="󰂁"
    		;;
    	9[0-9])
    		icon="󰂂"
    		;;
    	100)
    		icon="󰁹"
    		;;
    esac
fi

echo "<span background='#a0c4ff' font_weight='bold'> $icon </span><span background='#a0c4ff' font_weight='bold'>${battery_percentage}% </span>"
