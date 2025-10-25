#!/bin/bash
if [ ! -n "$(xrandr | grep "DP-1 disconnected")" ]
then
        xrandr --output DP-1 --off
	echo 0 > '/sys/class/leds/asus::screenpad/brightness'
else

	echo 255 > '/sys/class/leds/asus::screenpad/brightness'
	sleep 0.1
        xrandr --output DP-1 --auto --below eDP-1
fi
