#!/bin/bash
connected_device=$(bluetoothctl info | grep "Name" | awk -F ' ' '{print $2}')
if [ -n "$connected_device" ]; then
    echo "bth:[$connected_device] " #󰂱
	 echo
	 echo "#ffffff"
fi
