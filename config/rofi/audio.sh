#!/usr/bin/env bash

readarray -t SINKS_RAW < <(wpctl status | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E '[0-9]+\.')
[ ${#SINKS_RAW[@]} -eq 0 ] && exit 1

SINKS=()
IDS=()
for line in "${SINKS_RAW[@]}"; do
    CLEAN_LINE=$(echo "$line" | sed 's/^[│*[:space:]]*//')
    ID=$(echo "$CLEAN_LINE" | awk '{print $1}' | tr -d '.')
    NAME=$(echo "$CLEAN_LINE" | sed 's/^[0-9]\+\. //' | sed 's/\[vol:.*\]//' | sed 's/  */ /g')
    SINKS+=("$NAME")
    IDS+=("$ID")
done


CHOICE=$(printf "%s\n" "${SINKS[@]}" | rofi -dmenu -i -p "Audio")
[ -z "$CHOICE" ] && exit 0
CHOICE_CLEAN="$CHOICE"

SINK_ID=$(for i in "${!SINKS[@]}"; do
    [[ "${SINKS[$i]}" == "$CHOICE_CLEAN" ]] && echo "${IDS[$i]}" && break
  done)

wpctl set-default "$SINK_ID"
wpctl status | sed -n '/├─ Streams:/,/Video/p' | grep '>' | awk '{print $1}' | while read -r STREAM; do
    wpctl move "$STREAM" "$SINK_ID" 2>/dev/null
done
