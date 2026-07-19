#!/bin/bash
PIDFILE="/tmp/wallpaper-audio.pid"

if [ ! -f "$PIDFILE" ]; then
    notify-send "Wallpaper audio" "Nothing is playing."
    exit 0
fi

PID="$(cat "$PIDFILE")"

if ! kill -0 "$PID" 2>/dev/null; then
    # stale pidfile, process already gone
    rm -f "$PIDFILE"
    notify-send "Wallpaper audio" "Nothing is playing."
    exit 0
fi

STATE="$(ps -o stat= -p "$PID" | tr -d ' ')"

if [[ "$STATE" == *T* ]]; then
    kill -CONT "$PID"
    notify-send "Wallpaper audio" "Resumed."
else
    kill -STOP "$PID"
    notify-send "Wallpaper audio" "Paused."
fi
