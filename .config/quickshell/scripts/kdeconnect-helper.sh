#!/bin/bash

DEVICE_NAME="ULTRON"

DEVICE_ID=$(kdeconnect-cli -a --id-name-only | grep -w "$DEVICE_NAME" | head -n1 | cut -d' ' -f1)

if [ -z "$DEVICE_ID" ]; then
    echo '{"connected": false, "notifications": []}'
    exit 0
fi

DEVICE_PATH="/modules/kdeconnect/devices/$DEVICE_ID"
BUS="org.kde.kdeconnect"

BATTERY=$(dbus-send --print-reply --dest=$BUS \
    "$DEVICE_PATH/battery" \
    org.freedesktop.DBus.Properties.Get \
    string:org.kde.kdeconnect.device.battery string:charge \
    2>/dev/null | grep -oP 'int32 \K[0-9]+' || echo 0)

CHARGING_RAW=$(dbus-send --print-reply --dest=$BUS \
    "$DEVICE_PATH/battery" \
    org.freedesktop.DBus.Properties.Get \
    string:org.kde.kdeconnect.device.battery string:isCharging \
    2>/dev/null | grep -oP 'boolean \K\w+' || echo false)

if [ "$CHARGING_RAW" = "true" ]; then
    CHARGING_JSON="true"
else
    CHARGING_JSON="false"
fi

NOTIFS_RAW=$(dbus-send --print-reply --dest=$BUS \
    "$DEVICE_PATH/notifications" \
    org.kde.kdeconnect.device.notifications.activeNotifications \
    2>/dev/null)

NOTIFS_JSON="["
FIRST=true

while IFS= read -r line; do
    N_PATH=$(echo "$line" | grep -oP '"/modules/kdeconnect[^"]+notification[^"]*"' | tr -d '"')
    [ -z "$N_PATH" ] && continue

    APP_NAME=$(dbus-send --print-reply --dest=$BUS "$N_PATH" \
        org.freedesktop.DBus.Properties.Get \
        string:org.kde.kdeconnect.device.notification string:appName \
        2>/dev/null | grep -oP 'string "\K[^"]+' | head -n1)

    TITLE=$(dbus-send --print-reply --dest=$BUS "$N_PATH" \
        org.freedesktop.DBus.Properties.Get \
        string:org.kde.kdeconnect.device.notification string:title \
        2>/dev/null | grep -oP 'string "\K[^"]+' | head -n1)

    TICKER=$(dbus-send --print-reply --dest=$BUS "$N_PATH" \
        org.freedesktop.DBus.Properties.Get \
        string:org.kde.kdeconnect.device.notification string:ticker \
        2>/dev/null | grep -oP 'string "\K[^"]+' | head -n1)

    APP_NAME=$(echo "${APP_NAME:-unknown}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    TITLE=$(echo "${TITLE:-}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    TICKER=$(echo "${TICKER:-}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    N_ID=$(basename "$N_PATH")

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        NOTIFS_JSON="$NOTIFS_JSON,"
    fi
    NOTIFS_JSON="$NOTIFS_JSON{\"id\":\"$N_ID\",\"appName\":\"$APP_NAME\",\"title\":\"$TITLE\",\"ticker\":\"$TICKER\"}"
done <<< "$NOTIFS_RAW"

NOTIFS_JSON="$NOTIFS_JSON]"

echo "{\"connected\":true,\"id\":\"$DEVICE_ID\",\"battery\":$BATTERY,\"charging\":$CHARGING_JSON,\"notifications\":$NOTIFS_JSON}"
