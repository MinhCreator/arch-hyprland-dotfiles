#!/bin/bash

# Extract album art using playerctl
art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

# Fallback image path (uses your profile avatar as a fallback)
fallback_art="/home/priyam/.config/quickshell/assets/pp/pfp.jpg"
target_art="/tmp/hyprlock_album_art.png"

if [ -z "$art_url" ]; then
    cp "$fallback_art" "$target_art" 2>/dev/null
elif [[ "$art_url" == file://* ]]; then
    file_path="${art_url#file://}"
    cp "$file_path" "$target_art" 2>/dev/null
elif [[ "$art_url" == http://* || "$art_url" == https://* ]]; then
    curl -s -L -o "$target_art" "$art_url"
else
    if [ -f "$art_url" ]; then
        cp "$art_url" "$target_art" 2>/dev/null
    else
        cp "$fallback_art" "$target_art" 2>/dev/null
    fi
fi

# Echo the path for hyprlock
echo "$target_art"
