--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
 
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
 
-- Example window rules that are useful
 
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
 
    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)
 
hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
 
    no_focus = true,
})
 
hl.layer_rule({
    name = "rofi-popup",
    match = {namespace = "rofi"},
    animation = "slide bottom",
    dim_around = true
})
 
hl.layer_rule({
    name = "notification-center",
    match = {namespace = "swaync-control-center"},
    animation = "slide top"
})