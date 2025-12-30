#!/bin/bash
connected_device=$(bluetoothctl info | grep "Name" | awk -F ' ' '{print $2}')
if [ -n "$connected_device" ]; then
    echo "bth:[$connected_device] " #󰂱
else
    echo ""
fi

echo
echo "#ffffff"

