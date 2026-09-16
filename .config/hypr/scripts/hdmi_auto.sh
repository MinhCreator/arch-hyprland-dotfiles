#!/usr/bin/env bash

# ============================================================
#  HDMI Auto-Detection Event Daemon for Hyprland
# ============================================================

SOCKET=$(ls "$XDG_RUNTIME_DIR"/hypr/*/.socket2.sock 2>/dev/null | head -n1)

if [ -z "$SOCKET" ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
fi

handle_event() {
    case "$1" in
        monitoradded*)
            MON_NAME=$(echo "$1" | cut -d'>' -f2)
            notify-send "HDMI Connected" "External Display ($MON_NAME) plugged in.\nPress [Super + Shift + P] to select display mode." -i video-display -t 6000

            # Automatically configure external display to preferred mode
            hyprctl keyword monitor "$MON_NAME,preferred,auto,1"
            ;;
        monitorremoved*)
            MON_NAME=$(echo "$1" | cut -d'>' -f2)
            notify-send "HDMI Disconnected" "Display ($MON_NAME) removed." -i video-display -t 3000

            # Restore internal display
            hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
            ;;
    esac
}

if [ -S "$SOCKET" ]; then
    socat -u UNIX-CONNECT:"$SOCKET" - | while read -r line; do
        handle_event "$line"
    done
else
    echo "Hyprland socket not found at $SOCKET" >&2
    exit 1
fi
