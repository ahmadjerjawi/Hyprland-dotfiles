#!/bin/bash

# Simple emoji picker using Rofi + wl-copy or xdotool
# Original style: No themes, no font overrides

# Get emoji choice from list (first column only)
CHOSEN=$(cut -d ';' -f1 ~/.local/share/chars/* | rofi -dmenu -i -l 30 | sed 's/ .*//')

# Exit if nothing selected
[ -z "$CHOSEN" ] && exit

# If an argument is passed, type the emoji
if [ -n "$1" ]; then
    if command -v wtype &> /dev/null; then
        wtype "$CHOSEN"
    elif command -v xdotool &> /dev/null; then
        xdotool type "$CHOSEN"
    else
        notify-send "Error" "No input tool (wtype or xdotool) found"
        exit 1
    fi
else
    printf "%s" "$CHOSEN" | wl-copy
    notify-send "'$CHOSEN' copied to clipboard."
fi
