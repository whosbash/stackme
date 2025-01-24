#!/bin/bash

# Function to display a progress bar
progress_bar() {
  local current="$1"         # Current item
  local total="$2"           # Total items
  local elapsed_ns="$3"      # Elapsed time in nanoseconds
  local total_width="${4:-50}"  # Total width of the progress bar (default: 50)
  local marker="${5:-#}"     # Custom marker character (default: #)
  local space_char="${6:- }" # Character for remaining space (default: space)
  
  local percentage=$((current * 100 / total))  # Calculate percentage
  local elapsed_seconds=$(echo "scale=2; $elapsed_ns / 1000000000" | bc)  # Convert ns to seconds
  
  # Clamp the percentage to valid ranges
  percentage=$((percentage > 100 ? 100 : percentage))

  # Calculate the number of markers and spaces
  local filled_width=$((percentage * total_width / 100))
  local empty_width=$((total_width - filled_width))

  # Calculate speed (items per second)
  local speed=0
  if (( $(echo "$elapsed_seconds > 0" | bc -l) )); then
    speed=$(echo "scale=2; $current / $elapsed_seconds" | bc)
  fi

  # Display speed as secs/item if less than 1 item/sec
  local speed_display="N/A"
  if (( $(echo "$speed > 0" | bc -l) )); then
    if (( $(echo "$speed < 1" | bc -l) )); then
      speed_display=$(echo "scale=2; 1 / $speed" | bc)
      speed_display="${speed_display} secs/item"
    else
      speed_display="${speed} items/sec"
    fi
  fi

  # Estimate time remaining
  local time_remaining="N/A"
  if (( current < total && $(echo "$speed > 0" | bc -l) )); then
    time_remaining=$(echo "scale=2; ($total - $current) / $speed" | bc 2>/dev/null)
  fi

  # Calculate the estimated final time
  local estimated_final_time="0"
  if [[ "$time_remaining" != "0" ]]; then
    estimated_final_time=$(echo "$elapsed_seconds + $time_remaining" | bc 2>/dev/null)
  fi

  local formatted_elapsed_time=$(printf "%6.2f" "$elapsed_seconds")
  local formatted_final_time=$(printf "%6.2f" "$estimated_final_time")

  # Create the progress bar
  local filled_part=$(printf "%-${filled_width}s" "" | tr ' ' "$marker")
  local empty_part=$(printf "%-${empty_width}s" "" | tr ' ' "$space_char")

  # Display the progress bar with current, total, speed, elapsed time, and final estimated time
  printf "\r[%-s] %3d%% (%d/%d) Speed: %10s, Elapsed: %6s secs, Final: %6s secs" \
    "${filled_part}${empty_part}" "$percentage" "$current" "$total" "$speed_display" "$formatted_elapsed_time" "$formatted_final_time"
}

# Simulate progress with nanosecond precision
simulate_progress() {
  local total_items="$1"  # Total items to process
  local width="${2:-50}"  # Progress bar width
  local marker="${3:-#}"  # Marker character

  # Start time in nanoseconds
  local start_time=$(date +%s%N)

  for ((i = 1; i <= total_items; i++)); do
    # Current time in nanoseconds
    local current_time=$(date +%s%N)
    local elapsed_ns=$((current_time - start_time))

    # Update the progress bar
    progress_bar "$i" "$total_items" "$elapsed_ns" "$width" "$marker"

    # Simulate work
    sleep 0.1
  done

  # Ensure progress bar is complete after loop ends
  local elapsed_ns=$(( $(date +%s%N) - start_time ))
  progress_bar "$total_items" "$total_items" "$elapsed_ns" "$width" "$marker"
  echo  # Move to the next line

  # Completion message
  echo "Process Completed!"
}

# Example usage
total_steps=90
width=50
marker="="

simulate_progress "$total_steps" "$width" "$marker"
