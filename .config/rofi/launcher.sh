#!/usr/bin/env bash

# 1. Update Rofi widgets dynamically
bash "$HOME/.config/rofi/dynamic_widgets.sh"

# 2. Run Rofi
rofi -show drun -theme "$HOME/.config/rofi/tokyonight.rasi"
