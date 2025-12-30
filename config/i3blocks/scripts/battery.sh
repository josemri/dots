#!/bin/bash

# Cambia BAT0 si tu batería es otra (BAT1, etc.)
BAT_PATH="/sys/class/power_supply/BAT0"

PERCENT=$(cat $BAT_PATH/capacity)
STATUS=$(cat $BAT_PATH/status 2>/dev/null)

# Largo de la barra
BAR_LENGTH=10

# Segmentos llenos
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
