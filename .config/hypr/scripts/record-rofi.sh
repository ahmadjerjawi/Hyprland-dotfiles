#!/bin/bash
# Function to show notifications for any action
show_notification() {
    notify-send -u normal -i video-display "$1" "$2"
}

# Function to get the focused monitor name
get_focused_monitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
}

# Check if wf-recorder is already running and stop it if it is
if pgrep -x "wf-recorder" > /dev/null; then
    pkill -x wf-recorder
    show_notification "Recording Stopped" "Your recording has been saved to Videos folder"
    exit 0
fi

# Show the menu with options - with much larger size and font
CHOICE=$(echo -e "Focused Screen (No Audio)\nFocused Screen (With Audio)\nFull Screen (No Audio)\nFull Screen (With Audio)\nArea (No Audio)\nArea (With Audio)" | rofi -dmenu -p "Record with wf-recorder" -width 50 -lines 6 -font "DejaVu Sans 14")

# Define the output filename
FILENAME="$HOME/Videos/record_$(date '+%Y-%m-%d_%H-%M-%S').mp4"

# Get the focused monitor for single screen recording
FOCUSED_MONITOR=$(get_focused_monitor)

case "$CHOICE" in
    "Focused Screen (No Audio)")
        show_notification "Recording Started" "Focused screen ($FOCUSED_MONITOR) without audio"
        wf-recorder -o "$FOCUSED_MONITOR" -f "$FILENAME" || show_notification "Recording Failed" "Could not start wf-recorder"
        ;;
    "Focused Screen (With Audio)")
        show_notification "Recording Started" "Focused screen ($FOCUSED_MONITOR) with audio"
        wf-recorder -o "$FOCUSED_MONITOR" --audio -f "$FILENAME" || show_notification "Recording Failed" "Could not start audio recording"
        ;;
    "Full Screen (No Audio)")
        show_notification "Recording Started" "Full screen without audio"
        wf-recorder -f "$FILENAME" || show_notification "Recording Failed" "Could not start wf-recorder"
        ;;
    "Full Screen (With Audio)")
        show_notification "Recording Started" "Full screen with audio"
        wf-recorder --audio -f "$FILENAME" || show_notification "Recording Failed" "Could not start audio recording"
        ;;
    "Area (No Audio)")
        # Capture area and check if selection was cancelled
        GEOMETRY=$(slurp)
        if [ -z "$GEOMETRY" ]; then
            show_notification "Recording Cancelled" "Area selection was cancelled"
            exit 1
        fi
        show_notification "Recording Started" "Selected area without audio"
        wf-recorder -g "$GEOMETRY" -f "$FILENAME" || show_notification "Recording Failed" "Could not start area recording"
        ;;
    "Area (With Audio)")
        # Capture area and check if selection was cancelled
        GEOMETRY=$(slurp)
        if [ -z "$GEOMETRY" ]; then
            show_notification "Recording Cancelled" "Area selection was cancelled"
            exit 1
        fi
        show_notification "Recording Started" "Selected area with audio"
        wf-recorder --audio -g "$GEOMETRY" -f "$FILENAME" || show_notification "Recording Failed" "Could not start area recording with audio"
        ;;
    *)
        # If no option was selected or user pressed ESC
        show_notification "Recording Cancelled" "No option selected"
        exit 1
        ;;
esac

# This will only run if wf-recorder exits naturally (not through pkill)
show_notification "Recording Stopped" "Your recording has been saved to Videos folder"
