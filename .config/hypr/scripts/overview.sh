#!/usr/bin/bash

# A simple script to handle GNOME-like overview behavior for Hyprland's special workspace.
# Usage: overview.sh [show|hide|toggle]

ACTION=$1
SPECIAL_WS="special:magic"
LOG="/tmp/overview.log"

# Get current special workspace name
echo "$(date) --- overview.sh $ACTION ---" >> $LOG
SPECIAL_OPEN=$(/usr/bin/hyprctl monitors -j | /usr/bin/jq -r '.[0].specialWorkspace.name' 2>>$LOG)
echo "$(date) Special open: '$SPECIAL_OPEN'" >> $LOG

case "$ACTION" in
    show)
        if [[ "$SPECIAL_OPEN" != "$SPECIAL_WS" ]]; then
            echo "$(date) Showing magic workspace" >> $LOG
            /usr/bin/hyprctl dispatch togglespecialworkspace magic >> $LOG 2>&1
        else
            echo "$(date) Magic workspace already open, doing nothing" >> $LOG
        fi
        ;;
    hide)
        if [[ "$SPECIAL_OPEN" == "$SPECIAL_WS" ]]; then
            echo "$(date) Hiding magic workspace" >> $LOG
            /usr/bin/hyprctl dispatch togglespecialworkspace magic >> $LOG 2>&1
        else
            echo "$(date) Magic workspace already hidden, doing nothing" >> $LOG
        fi
        ;;
    toggle)
        echo "$(date) Toggling magic workspace" >> $LOG
        /usr/bin/hyprctl dispatch togglespecialworkspace magic >> $LOG 2>&1
        ;;
    *)
        echo "Usage: $0 [show|hide|toggle]"
        exit 1
        ;;
esac
