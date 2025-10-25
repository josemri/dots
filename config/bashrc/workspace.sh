#!/bin/bash

fm="$1"
sm="$2"
ws_fm="$3"
ws_sm="$4"

if xrandr | grep "^DP-1 connected"; then
	i3-msg "focus output $fm; workspace $ws_fm; focus output $sm; workspace $ws_sm"
else
	i3-msg "focus output $fm; workspace $ws_fm"
fi
