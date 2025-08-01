#!/usr/bin/env bash
#
# ~/.config/hypr/scripts/gaps_control.sh
# Controls window gaps in Hyprland

STATE_FILE="$HOME/.config/hypr/scripts/gaps_state.json"

# —— 1) Create default state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
  mkdir -p "$(dirname "$STATE_FILE")"
  cat > "$STATE_FILE" <<EOF
{
  "saved_in": 5,
  "saved_out": 20,
  "toggled_off": false
}
EOF
fi

# —— 2) JSON helper functions
read_json() {
  jq -r ".$1" "$STATE_FILE"
}

write_json() {
  local tmp
  tmp="$(mktemp)"
  jq ".$1 = $2" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# —— 3) Load current state
saved_in=$(read_json saved_in)
saved_out=$(read_json saved_out)
toggled_off=$(read_json toggled_off)

# —— 4) Process command
cmd="$1"
arg="${2:-0}"  # Default to 0 if no argument provided

# Check if gaps are toggled off for increment/decrement commands
if [[ "$toggled_off" == "true" && ("$cmd" == "inc-both" || "$cmd" == "inc-in" || "$cmd" == "inc-out") ]]; then
  echo "Gaps are currently disabled. Use 'toggle' command to re-enable gaps first."
  exit 0
fi

# Ensure arg is a number
if [[ "$arg" =~ ^-?[0-9]+$ ]] || [[ "$cmd" == "toggle" || "$cmd" == "restore" ]]; then
  case "$cmd" in
    inc-both)
      new_in=$(( saved_in + arg ))
      new_out=$(( saved_out + arg ))

      # Ensure values don't go below 0
      [ "$new_in" -lt 0 ] && new_in=0
      [ "$new_out" -lt 0 ] && new_out=0

      hyprctl keyword general:gaps_in "$new_in"
      hyprctl keyword general:gaps_out "$new_out"
      write_json saved_in "$new_in"
      write_json saved_out "$new_out"
      ;;

    inc-in)
      new_in=$(( saved_in + arg ))
      [ "$new_in" -lt 0 ] && new_in=0

      hyprctl keyword general:gaps_in "$new_in"
      write_json saved_in "$new_in"
      ;;

    inc-out)
      new_out=$(( saved_out + arg ))
      [ "$new_out" -lt 0 ] && new_out=0

      hyprctl keyword general:gaps_out "$new_out"
      write_json saved_out "$new_out"
      ;;

    toggle)
      if [ "$toggled_off" = "false" ]; then
        # Save current values before toggling off
        current_in=$(hyprctl getoption general:gaps_in -j | jq '.int')
        current_out=$(hyprctl getoption general:gaps_out -j | jq '.int')

        # Only update saved values if they're not already 0 (toggled off)
        if [ "$current_in" -ne 0 ] || [ "$current_out" -ne 0 ]; then
          write_json saved_in "$current_in"
          write_json saved_out "$current_out"
        fi

        # Set to zero
        hyprctl keyword general:gaps_in 0
        hyprctl keyword general:gaps_out 0
        write_json toggled_off true
        echo "Gaps disabled. Keybind keys won't affect gaps until toggled back on."
      else
        # Restore saved values
        hyprctl keyword general:gaps_in "$saved_in"
        hyprctl keyword general:gaps_out "$saved_out"
        write_json toggled_off false
        echo "Gaps enabled. Keybind keys will now affect gaps."
      fi
      ;;

    restore)
      # Called at startup to restore previous state
      if [ "$toggled_off" = "true" ]; then
        hyprctl keyword general:gaps_in 0
        hyprctl keyword general:gaps_out 0
      else
        hyprctl keyword general:gaps_in "$saved_in"
        hyprctl keyword general:gaps_out "$saved_out"
      fi
      ;;

    *)
      echo "Usage: $0 {inc-both N|inc-in N|inc-out N|toggle|restore}"
      exit 1
      ;;
  esac
else
  echo "Error: Second argument must be a number"
  exit 1
fi
