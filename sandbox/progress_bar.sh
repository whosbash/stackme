#!/bin/bash

# Function to display a progress bar
progress_bar() {
  local current="$1"        # Current item
  local total="$2"          # Total items
  local elapsed_time="$3"   # Elapsed time in seconds
  local total_width="${4:-50}"  # Total width of the progress bar (default: 50)
  local marker="${5:-#}"    # Custom marker character (default: #)
  local space_char="${6:- }"  # Character for remaining space (default: space)
  local percentage=$((current * 100 / total))  # Calculate percentage

  # Clamp the percentage and current value to prevent invalid ranges
  current=$((current < 0 ? 0 : (current > total ? total : current)))
  percentage=$((percentage > 100 ? 100 : percentage))

  # Calculate the number of markers and spaces
  local filled_width=$((percentage * total_width / 100))
  local empty_width=$((total_width - filled_width))

  # Calculate speed (items per second)
  local speed=0
  if (( elapsed_time > 0 )); then
    speed=$(echo "scale=2; $current / $elapsed_time" | bc)
  fi

  # Round speed to 2 decimal places and ensure 3 digits before the comma
  local rounded_speed=$(printf "%6.2f" "$speed")

  # Check if speed is slower than 0.5 items/sec
  local display_speed_or_time
  if (( $(echo "$speed < 0.5" | bc -l) )); then
    # Display time per item
    if (( current > 0 )); then
      local time_per_item=$(echo "scale=2; $elapsed_time / $current" | bc)
      display_speed_or_time="Time: ${time_per_item} secs/item"
    else
      display_speed_or_time="Time:     0.00 secs/item"
    fi
  else
    # Display speed with 3 digits before the comma and 2 decimal places
    display_speed_or_time="Speed: ${rounded_speed} items/sec"
  fi

  # Create the progress bar
  local filled_part=$(printf "%-${filled_width}s" "" | tr ' ' "$marker")
  local empty_part=$(printf "%-${empty_width}s" "" | tr ' ' "$space_char")

  # Display the progress bar with current and total items, and speed or time
  printf "\r[%-s] %3d%% (%d/%d) ${display_speed_or_time}" "${filled_part}${empty_part}" "$percentage" "$current" "$total"
}

# Simulate progress with delays to avoid flickering
simulate_progress() {
  local total_items="$1"  # Total items to process
  local width="${2:-50}"  # Progress bar width
  local marker="${3:-#}"  # Marker character

  # Start time
  local start_time=$(date +%s)

  for ((i = 1; i <= total_items; i++)); do
    # Calculate elapsed time
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    # Update the progress bar
    progress_bar "$i" "$total_items" "$elapsed_time" "$width" "$marker"

    # Simulate work
    sleep 0.1
  done

  # Ensure progress bar is complete after loop ends
  local elapsed_time=$(( $(date +%s) - start_time ))
  progress_bar "$total_items" "$total_items" "$elapsed_time" "$width" "$marker"
  echo  # Move to the next line
}

# Example usage
total_steps=90
width=50
marker="="

simulate_progress "$total_steps" "$width" "$marker"
