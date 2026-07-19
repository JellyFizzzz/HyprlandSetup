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

notify-send "Changing theme" "Applying new wallpaper and updating colours..."

# Set wallpaper
awww img "$IMAGE" --transition-type center --transition-duration 1.0 --transition-fps 60

# Generate pywal colours (pushed to terminal too, for wal.vim)
wal -i "$IMAGE" -nte

# Copy colours from wal to waybar dir for easy access
cp ~/.cache/wal/waybar-colours.css ~/.config/waybar/colours/wal-generated.css

# Generate Material You colours (auto-pick primary color, no interactive prompt)
matugen image "$IMAGE" --source-color-index 1

# Refresh waybar
pkill waybar || true
waybar > /dev/null 2>&1 &

# Refresh swaync
pkill swaync || true
swaync > /dev/null 2>&1 &
sleep 0.5

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
        mpv --no-video --loop-file=inf --volume=50 "$AUDIO_FILE" > /dev/null 2>&1 &
        echo $! > "$PIDFILE"
    fi
fi

notify-send "Theme applied" "Wallpaper and theme changed successfully!"
