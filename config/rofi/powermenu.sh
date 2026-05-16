#!/bin/bash

options="<span foreground='#f38ba8'>󰐥</span>\n<span foreground='#f6d32d'></span>\n<span foreground='#a6e3a1'></span>"

selection=$(echo -e "$options" | rofi \
    -no-config \
    -dmenu \
    -markup-rows \
    -theme ~/.config/rofi/powermenu.rasi)

if [ -z "$selection" ]; then
  exit 0
fi

case "$selection" in
  *󰐥*) systemctl poweroff ;;
  **) systemctl reboot ;;
  **) i3lock -c 000000 --no-unlock-indicator --ignore-empty-password -n ;;
  *󰗽*) i3-msg exit ;;
  *) exit 1 ;;
esac
