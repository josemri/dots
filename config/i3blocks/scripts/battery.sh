#!/bin/bash

BAT_PATH="/sys/class/power_supply/BAT0"
PERCENT=$(cat $BAT_PATH/capacity)
STATUS=$(cat $BAT_PATH/status 2>/dev/null)
BAR_LENGTH=10


FILLED=$((PERCENT * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))
BAR=
for ((i = 0; i < FILLED; i++)); do BAR+=█; done
for ((i = 0; i < EMPTY; i++)); do BAR+=░; done

echo "bat:[$BAR $(printf '%3d' "$PERCENT")]"
echo
if [[ "$STATUS" == "Charging" ]]; then
	echo "#EEF527"
elif [ $PERCENT -lt 15 ]; then
	echo "#FF0000"
else
	echo "#FFFFFF"
fi
