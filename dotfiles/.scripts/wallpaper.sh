#!/usr/bin/env bash

wallrizz -z list -d ~/.wallpaper

wallpaper=$(hyprctl hyprpaper listactive | head -1 | awk -F' = ' '{print $2}')

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
splash = false
ipc = on

wallpaper {
    monitor =
    path = $wallpaper
}
EOF
fi
