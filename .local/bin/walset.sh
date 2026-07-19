#!/bin/bash
shopt -s nullglob

WAL_DIR="$HOME/Pictures/Wallpapers"
CWD="$(pwd)"
ROFI_THEME="$HOME/.config/rofi/type-2/style-walset.rasi"

cd "$WAL_DIR" || exit 1

IFS=$'\n'
SELECTED_WAL=$(for name in *.jpg *.png; do echo -en "$name\0icon\x1f$WAL_DIR/$name\n"; done | rofi -dmenu -show-icons -theme "$ROFI_THEME" -p "")

if [ -n "$SELECTED_WAL" ]; then
	"$HOME/.local/bin/walset-backend.sh" "$WAL_DIR/$SELECTED_WAL"
fi

cd "$CWD" || exit 1
