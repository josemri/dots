#!/bin/bash

case $BLOCK_BUTTON in
  1) i3-msg exec "kitty --class nmtui-term -e nmtui" ;; # clic izquierdo
  3) i3-msg exec "nmcli device wifi rescan" ;; # clic derecho
esac

# conexion activa del primer dispositivo wifi (no fijado a un nombre de interfaz)
connection=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device | awk -F: '$2=="wifi" && $3=="connected" {print $4; exit}')

if [ -n "$connection" ]; then
    echo "net:[$connection]"
else
    echo "net:[off]"
fi

echo
echo "#ffffff"
