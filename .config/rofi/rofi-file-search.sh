#!/usr/bin/env bash

# If an argument is provided, open the file and exit
if [ -n "$1" ]; then
    # Expand ~/ to $HOME/
    file_path="${1/#\~/$HOME}"
    xdg-open "$file_path" >/dev/null 2>&1 &
    exit 0
fi

# List files using fd and format with ~/
fd --type f --follow \
   --exclude node_modules \
   --exclude '.git' \
   --exclude '.cache' \
   --max-depth 5 . "$HOME" | sed "s|^$HOME|~|"
