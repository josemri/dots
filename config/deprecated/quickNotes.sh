#!/bin/bash

HOT_CORNER_X=0
HOT_CORNER_Y=0
TOLERANCE=5
terminator --title "quick_note" -x nvim ~/.quick_note.txt &
NVIM_PID=$!

sleep 0.3
xdotool search --pid $NVIM_PID --name "quick_note" windowactivate type i
while :; do
    eval $(xdotool getmouselocation --shell)
    if (( X > HOT_CORNER_X + TOLERANCE || Y > HOT_CORNER_Y + TOLERANCE )); then
        xdotool search --name "quick_note" windowactivate key Escape
        xdotool search --name "quick_note" windowactivate type :
        xdotool search --name "quick_note" windowactivate type w
        xdotool search --name "quick_note" windowactivate type q
        xdotool search --name "quick_note" windowactivate key Return
        exit 0
    fi
    sleep 0.1
done
