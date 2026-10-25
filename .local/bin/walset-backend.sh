#!/bin/bash
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <path-to-image.jpg>"
	exit 1
fi

IMAGE="$1"

if [ ! -f "$IMAGE" ]; then
    notify-send "Error" "File not found: $IMAGE"
    exit 1
fi

# Set wallpaper
awww img "$IMAGE" --transition-type center --transition-duration 1.0 --transition-fps 60

# Generate pywal colours (pushed to terminal too, for wal.vim). The island reads
# ~/.cache/wal/colors.json live, so there is nothing to restart or copy.
wal -i "$IMAGE" -nte
kitty @ --to unix:/tmp/kitty-socket set-colors --all ~/.cache/wal/colors-kitty.conf 2>/dev/null

# Generate Material You colours (auto-pick primary color, no interactive prompt)
matugen image "$IMAGE" --source-color-index 1

# Ambient audio per wallpaper
AUDIO_DIR="$HOME/Music/WallpaperAudio"
BASENAME="$(basename "$IMAGE")"
AUDIO_FILE="$AUDIO_DIR/${BASENAME%.*}.mp3"
PIDFILE="/tmp/wallpaper-audio.pid"

# Always stop any previous ambient track first
if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
fi

if [ -f "$AUDIO_FILE" ]; then
    if ! playerctl status 2>/dev/null | grep -q "Playing"; then
        mpv --no-video --loop-file=inf --volume=100 --af=loudnorm "$AUDIO_FILE" > /dev/null 2>&1 &
        echo $! > "$PIDFILE"
    fi
fi

# One quiet, short-lived notification (low urgency = shortest island popup)
notify-send -u low "Theme applied" "Wallpaper and theme changed successfully!"
