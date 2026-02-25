#!/usr/bin/env bash

wallrizz -z list -d ~/.wallpaper

wallpaper=$(hyprctl hyprpaper listactive | head -1 | awk -F' = ' '{print $2}')

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    printf 'splash = false\nipc = on\npreload = %s\nwallpaper = ,%s\n' "$wallpaper" "$wallpaper" > "$HOME/.config/hypr/hyprpaper.conf"
fi
