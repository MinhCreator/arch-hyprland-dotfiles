#!/usr/bin/env bash

# ============================================================
#  HDMI & Projector Switcher Script for Hyprland
# ============================================================

# Detect connected HDMI or DP output name
HDMI_PORT=$(hyprctl monitors all | grep -oP 'Monitor \K(HDMI-A-[0-9]|DP-[0-9]|VGA-[0-9])' | head -n1)

if [ -z "$HDMI_PORT" ]; then
    HDMI_PORT=$(ls /sys/class/drm/ | grep -E 'card[0-9]-(HDMI-A|DP)' | grep -v 'eDP' | head -n1 | sed 's/card[0-9]-//')
fi

HDMI_PORT="${HDMI_PORT:-HDMI-A-1}"

set_mode() {
    case "$1" in
        "mirror")
            hyprctl keyword monitor "$HDMI_PORT,preferred,auto,1,mirror,eDP-1"
            hyprctl keyword monitor ",preferred,auto,1,mirror,eDP-1"
            notify-send "Display Mode" "HDMI Mirrored (Projector Mode)" -i video-display
            ;;
        "extend")
            hyprctl keyword monitor "$HDMI_PORT,preferred,auto,1"
            hyprctl keyword monitor ",preferred,auto,1"
            notify-send "Display Mode" "HDMI Extended (Dual Screen)" -i video-display
            ;;
        "projector_only")
            hyprctl keyword monitor "eDP-1,disable"
            hyprctl keyword monitor "$HDMI_PORT,preferred,auto,1"
            hyprctl keyword monitor ",preferred,auto,1"
            notify-send "Display Mode" "Projector / External Only" -i video-display
            ;;
        "laptop_only")
            hyprctl keyword monitor "$HDMI_PORT,disable"
            hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
            notify-send "Display Mode" "Laptop Screen Only" -i video-display
            ;;
        "audio_hdmi")
            HDMI_SINK=$(wpctl status | grep -i 'HDMI' | grep -oP '^\s*\*?\s*\K[0-9]+' | head -n1)
            if [ -n "$HDMI_SINK" ]; then
                wpctl set-default "$HDMI_SINK"
                notify-send "Audio Output" "Switched Audio to HDMI" -i audio-speakers
            else
                # Fallback: search pulse sinks
                HDMI_SINK_PULSE=$(pactl list sinks short | grep -i 'HDMI' | awk '{print $1}' | head -n1)
                if [ -n "$HDMI_SINK_PULSE" ]; then
                    pactl set-default-sink "$HDMI_SINK_PULSE"
                    notify-send "Audio Output" "Switched Audio to HDMI" -i audio-speakers
                else
                    notify-send "Audio Output" "HDMI Audio Sink not detected" -i audio-speakers
                fi
            fi
            ;;
        "audio_laptop")
            SPEAKER_SINK=$(wpctl status | grep -i 'Speaker' | grep -oP '^\s*\*?\s*\K[0-9]+' | head -n1)
            if [ -n "$SPEAKER_SINK" ]; then
                wpctl set-default "$SPEAKER_SINK"
                notify-send "Audio Output" "Switched Audio to Laptop Speakers" -i audio-speakers
            fi
            ;;
    esac
}

if [ -n "$1" ]; then
    set_mode "$1"
    exit 0
fi

ROFI_THEME="$HOME/.config/rofi/tokyonight.rasi"

if [ -f "$ROFI_THEME" ]; then
    CHOSEN=$(echo -e "🖥️ Mirror Screen (Projector Duplicate)\n⏩ Extend Screen (Dual Desktop)\n🎥 Projector / HDMI Only\n💻 Laptop Screen Only\n🔊 Route Audio to HDMI\n🔉 Route Audio to Laptop Speakers" | rofi -dmenu -i -p "HDMI Display Settings" -theme "$ROFI_THEME")
else
    CHOSEN=$(echo -e "🖥️ Mirror Screen (Projector Duplicate)\n⏩ Extend Screen (Dual Desktop)\n🎥 Projector / HDMI Only\n💻 Laptop Screen Only\n🔊 Route Audio to HDMI\n🔉 Route Audio to Laptop Speakers" | rofi -dmenu -i -p "HDMI Display Settings")
fi

case "$CHOSEN" in
    *"Mirror Screen"*)
        set_mode "mirror"
        ;;
    *"Extend Screen"*)
        set_mode "extend"
        ;;
    *"Projector / HDMI Only"*)
        set_mode "projector_only"
        ;;
    *"Laptop Screen Only"*)
        set_mode "laptop_only"
        ;;
    *"Route Audio to HDMI"*)
        set_mode "audio_hdmi"
        ;;
    *"Route Audio to Laptop Speakers"*)
        set_mode "audio_laptop"
        ;;
esac
