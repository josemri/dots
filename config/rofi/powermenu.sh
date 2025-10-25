#!/bin/bash

options="󰐥 Shutdown\n Reboot\n󰗽 Logout"

selection=$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/power.rasi -p "Power Menu")

if [ -z "$selection" ]; then
  exit 0
fi

case "$selection" in
  "󰐥 Shutdown") systemctl poweroff ;;
  " Reboot") systemctl reboot ;;
  " Lock") i3lock -c 000000 --no-unlock-indicator --ignore-empty-password -n ;;
  "󰗽 Logout") i3-msg exit ;;
  *) exit 1 ;;
esac

