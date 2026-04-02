#!/bin/bash

INTERNAL_DISPLAY="eDP-1"
EXTERNAL_DISPLAY="HDMI-1"
SECONDARY_DISPLAY="DP-1"

options="󰆑 Duplicate main to HDMI
󰞙 Extend main to HDMI
󰞗 Extend main to HDMI
󰞘 Extend main to HDMI
󰛧  Off laptop, 󰡁 On HDMI"

selection=$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/config.rasi -p ">")

if [ -z "$selection" ]; then
  exit 0
fi

case "$selection" in
	"󰆑 Duplicate main to HDMI")
		xrandr --output $INTERNAL_DISPLAY --auto --output $EXTERNAL_DISPLAY --auto --same-as $INTERNAL_DISPLAY
		;;
	"󰞙 Extend main to HDMI")
      xrandr --output $INTERNAL_DISPLAY --auto --output $EXTERNAL_DISPLAY --auto --above $INTERNAL_DISPLAY
		;;
	"󰞗 Extend main to HDMI")
		xrandr --output $INTERNAL_DISPLAY --auto --output $EXTERNAL_DISPLAY --auto --left-of $INTERNAL_DISPLAY
		;;
	"󰞘 Extend main to HDMI")
      xrandr --output $INTERNAL_DISPLAY --auto --output $EXTERNAL_DISPLAY --auto --right-of $INTERNAL_DISPLAY
		;;
	"󰛧  Off laptop, 󰡁 On HDMI") 
		xrandr --output $INTERNAL_DISPLAY --off --output $SECONDARY_DISPLAY --off --output $EXTERNAL_DISPLAY --auto
		;;
	*) exit 1 ;;
esac

nitrogen --restore
