#!/bin/sh
FRAMES_DIR=/etc/luks-anim/frames
DELAY=0.08

FRAME_LIST=$(ls "$FRAMES_DIR"/[0-9]*.txt 2>/dev/null | sort -V)
[ -z "$FRAME_LIST" ] && exit 0

# Tamaño del terminal
TERMINAL=$(stty size </dev/console 2>/dev/null)
ROWS=$(echo "$TERMINAL" | cut -d' ' -f1)
COLS=$(echo "$TERMINAL" | cut -d' ' -f2)
[ -z "$ROWS" ] && ROWS=24
[ -z "$COLS" ] && COLS=80

# Dimensiones del cubo
CUBE_WIDTH=74
CUBE_HEIGHT=33

# Padding
PAD_H=$(( (COLS - CUBE_WIDTH) / 2 ))
[ "$PAD_H" -lt 0 ] && PAD_H=0
PADDING=$(printf '%*s' "$PAD_H" '')

PAD_V=$(( (ROWS - CUBE_HEIGHT) / 2 ))
[ "$PAD_V" -lt 0 ] && PAD_V=0
TOP_PADDING=$(printf '%*s' "$PAD_V" '' | tr ' ' '\n')

# Ocultar cursor al arrancar
printf '\033[?25l' >/dev/console

# Restaurar cursor al salir (cuando askpass mata el proceso)
trap 'printf "\033[?25h" >/dev/console' EXIT INT TERM

print_frame() {
    printf '\033[H'
    printf '%s\n' "$TOP_PADDING"
    while IFS= read -r line; do
        printf '%s%s\n' "$PADDING" "$line"
    done < "$1"
}

while true; do
    for frame in $FRAME_LIST; do
        print_frame "$frame"
        sleep "$DELAY"
    done
    for frame in $(echo "$FRAME_LIST" | sort -rV | tail -n +2 | head -n -1); do
        print_frame "$frame"
        sleep "$DELAY"
    done
done
