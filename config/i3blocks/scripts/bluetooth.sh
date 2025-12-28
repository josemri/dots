#!/bin/bash

if [ ! bluetoothctl show | grep -q "Powered: yes" ]; then
    #echo "[   off   ]󰂲"
    echo ""
    exit 0
fi
connected_device=$(bluetoothctl info | grep "Name" | awk -F ' ' '{print $2}')
if [ -n "$connected_device" ]; then
    echo "[$connected_device]󰂱"
else
    #echo "[  none  ]󰂯"
    echo ""
fi

echo
echo "#ffffff"

