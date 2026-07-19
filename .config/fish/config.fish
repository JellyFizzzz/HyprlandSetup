if status is-interactive
    set fish_greeting
    starship init fish | source
end

fish_add_path ~/.local/bin ~/.npm-global/bin
set -gx QT_QPA_PLATFORMTHEME gtk3
