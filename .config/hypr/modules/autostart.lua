-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
  hl.exec_cmd("sleep 0.5 && hyprpaper")
  hl.exec_cmd("swaync")
end)
