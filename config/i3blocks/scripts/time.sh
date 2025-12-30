#!/bin/bash

case $BLOCK_BUTTON in
  1) notify-send "$(date +%D)" "$(cal)" ;;
esac

echo "[$(date '+%H:%M')]"
echo
echo "#ffffff"
