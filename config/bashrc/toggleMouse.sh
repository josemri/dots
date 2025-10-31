#!/bin/bash
ID=$(xinput list | grep -i "Touchpad" | grep -o 'id=[0-9]*' | grep -o '[0-9]*');
if [ "$(xinput list-props $ID | grep "Device Enabled" | awk '{print $4}')" -eq 1 ]; then
        xinput disable $ID;
else
        xinput enable $ID;
fi;
