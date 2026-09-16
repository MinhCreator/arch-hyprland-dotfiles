#!/usr/bin/env bash

# Loop to allow deleting items and instantly refreshing the menu
while true; do
    # Run rofi and get selection and exit status
    selected=$(cliphist list | rofi -dmenu \
        -p "󰅌 Clipboard" \
        -theme ~/.config/rofi/clipboard.rasi \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
        -kb-custom-1 "Alt+d" \
        -kb-custom-2 "Alt+c" \
        -mesg "<b>Alt+d</b>: Delete item  |  <b>Alt+c</b>: Clear all history")
        
    exit_code=$?
    
    # If user closed rofi (Escape, clicked outside, etc.), exit the loop
    if [ $exit_code -eq 1 ] || [ $exit_code -eq 130 ]; then
        break
    fi
    
    # 1. Normal Selection (Enter or Click) -> Copy & Paste
    if [ $exit_code -eq 0 ]; then
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist decode | wl-copy
            
            # Auto-paste: wait briefly for Rofi to close and target window to gain focus
            sleep 0.15
            if command -v wtype &> /dev/null; then
                wtype -M ctrl -k v -m ctrl
            else
                hyprctl dispatch sendshortcut CTRL, v, active
            fi
        fi
        break
    fi
    
    # 2. Custom Key 1 (Alt+d) -> Delete selected item
    if [ $exit_code -eq 10 ]; then
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist delete
        fi
        # Continue loop to reload Rofi list
    fi
    
    # 3. Custom Key 2 (Alt+c) -> Wipe all history (with confirmation)
    if [ $exit_code -eq 11 ]; then
        confirm=$(echo -e "No\nYes" | rofi -dmenu \
            -p "Wipe all history?" \
            -theme ~/.config/rofi/clipboard.rasi \
            -mesg "Are you sure you want to clear your clipboard history?")
            
        if [ "$confirm" = "Yes" ]; then
            cliphist wipe
        fi
        # Continue loop to reload Rofi list
    fi
done
