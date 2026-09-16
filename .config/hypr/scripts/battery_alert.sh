#!/bin/bash

# Configuration
LOW_LEVEL=20
CRITICAL_LEVEL=10
INTERVAL=60 # Seconds between checks

NOTIFIED_LOW=0
NOTIFIED_CRITICAL=0

while true; do
    # Get battery percentage and status
    BATTERY_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -1)
    CAPACITY=$(cat "$BATTERY_PATH/capacity")
    STATUS=$(cat "$BATTERY_PATH/status")

    if [ "$STATUS" = "Discharging" ]; then
        if [ "$CAPACITY" -le "$CRITICAL_LEVEL" ]; then
            if [ "$NOTIFIED_CRITICAL" -eq 0 ]; then
                notify-send -u critical -i "battery-empty-symbolic" "Battery Critical" "Battery at ${CAPACITY}%. Plug in now!"
                NOTIFIED_CRITICAL=1
                NOTIFIED_LOW=1
            fi
            sleep 120 # Wait longer after critical warning
        elif [ "$CAPACITY" -le "$LOW_LEVEL" ]; then
            if [ "$NOTIFIED_LOW" -eq 0 ]; then
                notify-send -u normal -i "battery-low-symbolic" "Battery Low" "Battery is at ${CAPACITY}%"
                NOTIFIED_LOW=1
            fi
        fi
    else
        # Reset tracking when charging
        NOTIFIED_LOW=0
        NOTIFIED_CRITICAL=0
    fi
    sleep "$INTERVAL"
done
