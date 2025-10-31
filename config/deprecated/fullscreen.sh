#!/bin/bash

#bindsym Shift+XF86Launch6 exec --no-startup-id ./.config/fullscreen.sh

window_id=$(xdotool selectwindow)
if [ -z "$window_id" ]; then
    exit 1
fi
window_id_hex=$(printf "0x%x\n" "$window_id")
i3-msg "[id=$window_id_hex] floating enable, resize set 1910 1585, move position 5 5"
