#!/bin/bash

case $BLOCK_BUTTON in
  1) i3-msg exec "/home/josep/.config/rofi/net.sh" ;; #left
  2) i3-msg exec "nmcli device wifi rescan" ;; #middle
  3) i3-msg exec "kitty --class nmtui-term -e nmtui" ;; #right
esac



# Obtener conexión activa en wlo1
connection_info=$(nmcli -t -f name,device connection show --active | grep wlo1)

if [ "$connection_info" ]; then
    ssid=$(echo "$connection_info" | cut -d: -f1)
    echo "net:[$ssid]"
else
	echo "net:[off]"
fi

echo
echo "#ffffff"
