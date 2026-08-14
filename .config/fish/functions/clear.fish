function clear
	printf '\033[2J\033[3J\033[H'
	kitty @ set-colors --all ~/.cache/wal/colors-kitty.conf 2>/dev/null
end

