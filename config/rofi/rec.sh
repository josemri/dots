#!/bin/bash

# ========================================
# CONFIG
# ========================================
PIDFILE="$HOME/.cache/ffmpeg_rec.pid"
OUTDIR="$HOME"
mkdir -p "$OUTDIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ========================================
# PID MANAGEMENT
# ========================================
get_pid() { [[ -f "$PIDFILE" ]] && cat "$PIDFILE"; }

is_recording() {
    pid=$(get_pid)
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

is_paused() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return 1
    state=$(awk '/State:/ {print $2}' /proc/$pid/status 2>/dev/null)
    [[ "$state" == "T" ]]
}

toggle_pause() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return

    if is_paused; then
        kill -SIGCONT "$pid"
    else
        kill -SIGSTOP "$pid"
    fi
}

# deprecated use toggle instead
pause_recording() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return
    kill -SIGSTOP "$pid"
}

# deprecated use toggle instead
resume_recording() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return
    kill -SIGCONT "$pid"
}

stop_recording() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return
    if is_paused; then
        kill -SIGCONT "$pid"
        sleep 0.2
    fi
    kill -SIGINT "$pid" 2>/dev/null
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -TERM "$pid"
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"
    rm -f "$PIDFILE"
}


#deprecated usea stop_recording instead
stop_recording_old() {
    pid=$(get_pid)
    [[ -z "$pid" ]] && return
    kill -SIGINT "$pid" 2>/dev/null
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -TERM "$pid"
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"
    rm -f "$PIDFILE"
}

cleanup_if_dead() {
    pid=$(get_pid)
    [[ -n "$pid" && ! -d "/proc/$pid" ]] && rm -f "$PIDFILE"
}
cleanup_if_dead

# ========================================
# VIDEO SOURCES
# ========================================
monitor_args() {
    local monitor="$1"
    read width height x y <<<$(xrandr | awk -v mon="$monitor" '{if ($1==mon && $2=="connected") {s=($3=="primary"?$4:$3); split(s,a,/[\+x]/); print a[1], a[2], a[3], a[4]}}')
    echo "-video_size ${width}x${height} -framerate 30 -f x11grab -i :0.0+${x},${y}"
}

window_args() {
    wid=$(xwininfo | awk '/Window id:/{print $4}')
    [[ -z "$wid" ]] && { rofi -e "No seleccionaste ninguna ventana"; exit 1; }
    echo "-f x11grab -framerate 30 -window_id $wid -i :0.0"
}

# ========================================
# FFMPEG LAUNCH
# ========================================
run_ffmpeg() {
    local args="$1"
    local name="$2"
    local outfile="$OUTDIR/${name}_${TIMESTAMP}.mp4"

	nohup ffmpeg -y -nostdin \
    $args \
	-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
    -movflags +faststart \
    "$outfile" >/dev/null 2>&1 &

    pid=$!
    sleep 0.5
    if kill -0 $pid 2>/dev/null; then
        echo $pid > "$PIDFILE"
    fi
}

# ===============================
#   SI YA ESTÁ GRABANDO
# ===============================
if is_recording; then
    if is_paused; then
        options="▶ Continue\n⏹ Stop"
    else
        options="⏸ Pause\n⏹ Stop"
    fi

    choice=$(echo -e "$options" | rofi -dmenu -p "Recording...")

    case "$choice" in
        "⏸ Pause") toggle_pause ;;
        "▶ Continue") toggle_pause ;;
        "⏹ Stop") stop_recording ;;
    esac
    exit 0
fi

# ========================================
# MAIN
# ========================================
source_choice=$( (xrandr --listmonitors | tail -n +2 | awk '{print $4}'; echo "camera"; echo "select window") | rofi -dmenu -p ">")
if [[ "$source_choice" == "select window" ]]; then
    video_args=$(window_args)
    source_name="window"
elif [[ "$source_choice" == "camera" ]]; then
	nohup ffplay -window_title "FFplayWindow" /dev/video0 >/dev/null 2>&1 &
	exit 0
else
    video_args=$(monitor_args "$source_choice")
    source_name="$source_choice"
fi


run_ffmpeg "$video_args" "$source_name"

