#!/bin/bash

INTERFACE="enx00e04c68432a"
if ip link show $INTERFACE | grep -q "state UP"; then
    SPEED=$(cat /sys/class/net/$INTERFACE/speed 2>/dev/null || echo "Unknown")
    echo "<span background='#caffbf' font_weight='bold'>  </span><span background='#caffbf' font_weight='bold'>$SPEED Mbit/s </span>"
fi

