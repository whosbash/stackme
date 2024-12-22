#!/bin/bash

boxed_text() {
  local word=${1:-"Hello"}        # Default word to render
  local style=${2:-"simple"}      # Default border style
  local font=${3:-"slant"}        # Default font
  local min_width=${4:-30}        # Default minimum width

  # Ensure `figlet` exists
  if ! command -v figlet &>/dev/null; then
    echo "Error: 'figlet' command not found. Please install it to use this function."
    return 1
  fi

  # Define the border styles
  declare -A border_styles=(
    ["simple"]="- - | | + + + +"
    ["asterisk"]="* * * * * * * *"
    ["equal"]="= = | | + + + +"
    ["hash"]="# # # # # # # #"
    ["dotted"]=". . . . . . . ."
    ["none"]="         "
  )

  # Extract the border characters
  IFS=' ' read -r \
    top_fence bottom_fence left_fence right_fence \
    top_left_corner top_right_corner \
    bottom_left_corner bottom_right_corner <<< "${border_styles[$style]:-${border_styles["simple"]}}"

  # Generate ASCII art
  local ascii_art=$(figlet -f "$font" "$word")
  local art_width=$(echo "$ascii_art" | head -n 1 | wc -c)
  art_width=$((art_width - 1))  # Subtract newline

  # Get terminal width and calculate box width
  local terminal_width=$(tput cols)
  local total_width=$((min_width > art_width ? min_width : art_width))
  total_width=$((total_width > (terminal_width - 2) ? (terminal_width - 2) : total_width))

  # Generate borders
  local top_border="${top_left_corner}$(printf "%-${total_width}s" | tr ' ' "$top_fence")${top_right_corner}"
  local bottom_border="${bottom_left_corner}$(printf "%-${total_width}s" | tr ' ' "$bottom_fence")${bottom_right_corner}"

  # Buffer all lines to an array
  local -a lines=()

  # Add the top border
  lines+=("$top_border")

  # Add the ASCII art with borders
  while IFS= read -r line; do
    local padding=$(( (total_width - ${#line}) / 2 ))
    lines+=( "$(printf "%s%*s%s%*s%s" "$left_fence" "$padding" "" "$line" "$padding" "" "$right_fence")" )
  done <<< "$ascii_art"

  # Add the bottom border
  lines+=("$bottom_border")

  # Display the lines in parallel
  display_parallel lines
}


# Function to process all lines in parallel and maintain order
display_parallel() {
  local -n _lines=$1  # Array passed by reference
  local -a pids=()   # Array to hold process IDs

  # Process each line in parallel
  for i in "${!_lines[@]}"; do
    line="${_lines[i]}"
    {
      echo "$line"  # Directly print the line
    } &
    pids+=($!)  # Store the process ID for each background process
  done

  # Wait for all processes to finish
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

# Simple box with default font
boxed_text "Welcome"

# Box with hash borders and different font
boxed_text "Hello" "hash" "big"

# Box with minimum width of 50 characters
boxed_text "Bash" "asterisk" "slant" 50
