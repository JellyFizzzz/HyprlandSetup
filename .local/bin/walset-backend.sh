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
awww img "$IMAGE" --transition-type="center" --transition-step=1 --transition-fps="60"

# Generate pywal colours (pushed to terminal too, for wal.vim)
wal -i "$IMAGE" -nte

# Generate Material You colours (auto-pick primary color, no interactive prompt)
matugen image "$IMAGE" --source-color-index 1

# Refresh waybar
pkill waybar || true
waybar > /dev/null 2>&1 &

# Refresh swaync
pkill swaync || true
swaync > /dev/null 2>&1 &
sleep 0.5

notify-send "Theme applied" "Wallpaper and theme changed successfully!"
