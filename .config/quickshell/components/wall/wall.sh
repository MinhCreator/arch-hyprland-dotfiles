#!/usr/bin/env bash

SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
SELECTED_PATH="${1:-}"

if [[ -z "$SELECTED_PATH" ]]; then
    quickshell ipc call wallpaper toggle
    exit 0
fi

[[ ! -f "$SELECTED_PATH" ]] && exit 1

ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

# ── Rofi Background Caching ──
CACHE_DIR="$HOME/.cache/quickshell/rofi-bg"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/$(basename "$SELECTED_PATH").jpg"
ROFI_BG="$HOME/.config/rofi/rofi-bg.jpg"

if [[ -f "$CACHE_FILE" ]]; then
    # Instant copy from cache!
    cp "$CACHE_FILE" "$ROFI_BG"
else
    # Generate and save to cache
    magick "$SELECTED_PATH" -strip -scale 100x -blur 0x3 -resize 400x "$CACHE_FILE"
    cp "$CACHE_FILE" "$ROFI_BG"
fi

# Asynchronously pre-generate Rofi background cache for other wallpapers
(
    find "$HOME/Pictures/wallpapers" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | while read -r wall; do
        c_name="$CACHE_DIR/$(basename "$wall").jpg"
        if [[ ! -f "$c_name" ]]; then
            magick "$wall" -strip -scale 100x -blur 0x3 -resize 400x "$c_name" 2>/dev/null
        fi
    done
) &

awww img "$SELECTED_PATH" \
    --transition-type grow \
    --transition-pos bottom-left \
    --transition-duration 1.2 \
    --transition-fps 144 \
    --transition-bezier 0.16,1,0.3,1 \
    --resize crop &

# Run matugen and theme reload asynchronously in the background with low CPU priority
(
    # Use low-res cache file for extremely fast color extraction
    COLOR0=$(nice -n 19 matugen --json hex image "$CACHE_FILE" --source-color-index 0 | jq -r '.colors.primary.default.color' 2>/dev/null)
    COLOR1=$(nice -n 19 matugen --json hex image "$CACHE_FILE" --source-color-index 1 | jq -r '.colors.primary.default.color' 2>/dev/null)

    INDEX=0
    if [[ -n "$COLOR0" && -n "$COLOR1" ]]; then
        g0=$((16#${COLOR0:3:2}))
        b0=$((16#${COLOR0:5:2}))
        g1=$((16#${COLOR1:3:2}))
        b1=$((16#${COLOR1:5:2}))
        diff0=$((g0 - b0))
        diff1=$((g1 - b1))
        if (( diff1 > diff0 + 20 )); then
            INDEX=1
        fi
    fi

    nice -n 19 matugen image "$CACHE_FILE" --source-color-index $INDEX
    quickshell ipc call theme reload
    bash "$HOME/.config/matugen/files/change-icons.sh"
) &

