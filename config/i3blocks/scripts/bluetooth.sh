#!/bin/bash

if [ ! bluetoothctl show | grep -q "Powered: yes" ]; then
    echo "<span background='#ffd6a5' font_weight='bold'> 󰂲 </span><span background='#ffd6a5' font_weight='bold'>off </span>"
    exit 0
fi
connected_device=$(bluetoothctl info | grep "Name" | awk -F ' ' '{print $2}')
if [ -n "$connected_device" ]; then
    echo "<span background='#ffd6a5' font_weight='bold'> 󰂱 </span><span background='#ffd6a5' font_weight='bold'>$connected_device </span>"
else
    echo "<span background='#ffd6a5' font_weight='bold'> 󰂯 </span><span background='#ffd6a5' font_weight='bold'>none </span>"
fi

