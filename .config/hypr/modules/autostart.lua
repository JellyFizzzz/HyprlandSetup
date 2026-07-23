-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function ()
  -- GNOME KEYRING CONFS
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")  

  hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("swaync")
end)
