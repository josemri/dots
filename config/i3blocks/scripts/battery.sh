#!/bin/bash

case $BLOCK_BUTTON in
	1) notify-send "$(cat /sys/class/power_supply/BAT0/status)" "bat: $(cat /sys/class/power_supply/BAT0/capacity)%";;
esac



BAT_PATH="/sys/class/power_supply/BAT0"

PERCENT=$(cat $BAT_PATH/capacity)
STATUS=$(cat $BAT_PATH/status 2>/dev/null)
BAR_LENGTH=10
FILLED=$((PERCENT * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))

BAR=$(printf '%0.s ' $(seq $EMPTY))$(printf '%0.s█' $(seq $FILLED))
echo "bat:[$BAR]"
echo
if [[ "$STATUS" == "Charging" ]]; then
	echo "#EEF527"
elif [ $PERCENT -lt 15 ]; then
	echo "#FF0000"
else
	echo "#FFFFFF"
fi
