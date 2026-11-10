#!/bin/bash

# primera interfaz ethernet conectada: el adaptador USB cambia de nombre
INTERFACE=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="ethernet" && $3=="connected" {print $1; exit}')
[ -n "$INTERFACE" ] || exit 0

SPEED=$(cat /sys/class/net/$INTERFACE/speed 2>/dev/null || echo "Unknown")
echo "eth:[$SPEED Mbit/s] "
echo
echo "#ffffff"
