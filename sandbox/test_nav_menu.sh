#!/usr/bin/env bash

# Define a global associative array for storing menu items
declare -A MENUS

# Highlight and color variables for styling
highlight_color="\033[1;32m" # Highlight color (Bright Green)
faded_color="\033[2m"        # Faded color (Dark gray)
select_color="\033[1;34m"    # Blue for select (↵)
back_color="\033[2m"         # Magenta for return (r)
quit_color="\033[1;31m"      # Red for quit (q)
search_color="\033[1;36m"    # Search color (/)
goto_color="\033[1;36m"      # Go-to page color (g)
help_color="\033[1;35m"      # Help color (h)
error_color="\033[1;31m"     # Error color (Dark red)
title_color="\033[1;36m"     # Title color (Cyan)
reset_color="\033[0m"        # Reset color

# Define arrow keys for navigation
up_key="[A"    # Up Arrow
down_key="[B"  # Down Arrow
left_key="[D"  # Left Arrow
right_key="[C" # Right Arrow

# Default menu options
TRUNCATED_DEFAULT_LENGTH=50

COLORED_ARROW="${highlight_color}→${reset_color}"

# Disable canonical mode, set immediate input
stty -icanon min 1 time 0

# Ensure terminal settings are restored on script exit
trap "stty sane" EXIT

# Function to clean the terminal screen
clean_screen() {
  echo -ne "\033[H\033[J" >&2
}

# Function to strip ANSI escape sequences from a string
strip_ansi() {
  pattern='s/\x1b\[[0-9;]*[mK]//g'
  echo -e "$1" | sed "$pattern"
}

# Function to convert "true"/"false" to integer 1/0
to_integer() {
  [[ "$1" == "true" ]] && echo 1 || echo 0
}

# Function to convert a numeric result to "true" or "false"
to_boolean() {
  [[ "$1" -ne 0 ]] && echo "true" || echo "false"
}

# Function to show help
show_help() {
  echo -e "${highlight_color}↗↘${reset_color}  - Navigate down- and upwards"
  echo -e "${highlight_color}◁▷${reset_color}  - Navigate sideways"
  echo -e "${select_color}↵${reset_color}   - Select current option"
  echo -e "${back_color}r${reset_color}   - Return to menu begin"
  echo -e "${search_color}/${reset_color}   - Search on current menu"
  echo -e "${quit_color}q${reset_color}   - Quit the application"
  echo -e "${help_color}h${reset_color}   - Show this help menu"
}

# Function to display styled and optionally centered text with custom or terminal width
display_text() {
  local text="$1"             # The text to display
  local custom_width="$2"     # Custom width for the text
  local padding=0             # Optional padding around the text
  local center=false          # Set to true to center the text
  local style="${bold_color}" # Optional style (e.g., bold or colored)

  # Check if additional options are provided
  shift 2 # Skip the first two arguments (text and custom_width)
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --center) center=true ;;
    --style)
      style="$2"
      shift
      ;;
    --padding)
      padding="$2"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    esac
    shift
  done

  # If custom width is not provided, use terminal width (tput cols)
  if [[ -z "$custom_width" ]]; then
    custom_width=$(tput cols)
  fi

  # Ensure padding is valid
  if ((padding < 0)); then
    echo "Padding must be non-negative." >&2
    return 1
  fi

  # Calculate text length with padding
  local padded_text=$(printf "%${padding}s%s%${padding}s" "" "$text" "")
  local text_length=${#padded_text}

  # Ensure the custom width is at least the length of the text
  if ((custom_width < text_length)); then
    message="Custom width ($custom_width) is smaller than text length ($text_length)."
    echo "Error: $message" >&2
    return 1
  fi

  # Center the text if needed
  if [[ "$center" == true ]]; then
    local left_padding=$(((custom_width - text_length) / 2))
    padded_text=$(printf "%${left_padding}s%s" "" "$padded_text")
  fi

  # Ensure the text fits within the custom width
  local final_text=$(printf "%-${custom_width}s" "$padded_text")

  # Apply styling and display
  echo -e "${style}${final_text}${reset_color}"
}

# Function to get a specific value from a JSON object
query_json_value() {
  local menu_item="$1"
  local query="$2"

  echo "$menu_item" | jq -r "$query"
}

# Function to check the key and set the boolean
set_move_boolean() {
  local key_to_check="$1"
  local key_value="$2"

  if [[ "$key_to_check" = "$key_value" ]]; then
    echo true
  else
    echo false
  fi
}

get_menu_item_label() {
  local menu_item="$1"
  query_json_value "$menu_item" ".label"
}

get_menu_item_description() {
  local menu_item="$1"
  query_json_value "$menu_item" '.description'
}

get_menu_item_action() {
  local menu_item="$1"
  query_json_value "$menu_item" '.action'
}

# Function to display a message, move the cursor, and read user input
request_input() {
  local message="$1"
  local cursor_move="$2"
  local variable_name="$3"

  echo -ne "$message" >&2
  tput cuf "$cursor_move"     # Move cursor forward by the specified number of characters
  read -rsn1 "$variable_name" # Read a single character input into the specified variable
}

# Function to request confirmation (yes/no)
request_confirmation() {
  local message="$1"
  local confirm_variable_name="$2"
  local default_value="${3:-false}"

  local user_input=""
  request_input "$message" 1 user_input # Move 1 character forward

  # Use default value if input is empty
  if [[ -z "$user_input" && "$default_value" != "false" ]]; then
    user_input="$default_value"
  fi

  # Validate the input
  while [[ ! "$user_input" =~ ^[yYnN]$ ]]; do
    # Display the error message and prompt again on a new line
    echo -e "${faded_color}\nInvalid input \"$user_input\"." >&2
    echo -e "Please enter 'y' for yes or 'n' for no.${reset_color}" >&2

    # Re-prompt the user
    request_input "$message" 1 user_input # Move 1 character forward
  done

  # Assign the validated input to the confirmation variable
  printf -v "$confirm_variable_name" "%s" "$user_input"
}

# Function to display invalid input message
display_invalid_input_message() {
    local input=$1
    local prompt_message=$2

    reason="Invalid input \"$input\""
    select_options="Please enter 'y' for yes or 'n' for no."
    invalid_message="${faded_color}$reason\n$select_options\n${reset_color}"

    # Print the invalid message
    echo -e "$invalid_message" >&2
    echo -ne "${faded_color}$prompt_message${reset_color}" >&2
}

# Function to handle confirmation prompt
handle_confirmation_prompt() {
    local prompt_message=$1
    local confirm_var=$2

    while true; do
        # Request confirmation from the user
        request_confirmation "$prompt_message" "$confirm_var"

        # Validate input
        case "${!confirm_var}" in
            [yY]) return 0 ;; # Confirmed
            [nN]) return 1 ;; # Declined
            *) display_invalid_input_message "${!confirm_var}" "$prompt_message" ;;
        esac
    done
}

# Function to truncate option text to a max length
truncate_option() {
  local option="$1"
  local max_length="${2-$TRUNCATED_DEFAULT_LENGTH}"
  if [[ ${#option} -gt $max_length ]]; then
    echo "${option:0:$((max_length - 3))}..."
  else
    echo "$option"
  fi
}

# Function to calculate total pages
calculate_total_pages() {
  local total_items="$1"    # Total number of items
  local items_per_page="$2" # Number of items per page

  # Calculate total pages, rounding up if necessary
  total_pages=$(((total_items + items_per_page - 1) / items_per_page))

  echo "$total_pages"
}

# Function to check if the current item is the first item on the page
is_first_page_item() {
  local current_item="$1" # Current item number (0-based index)
  local items_per_page="$2"

  # Check if the current item is the first item on the page
  # First items are those which are of the form: 0, p, 2p+1, 3p+2, ...
  local first_item_mod=$((current_item % items_per_page))
  if [ "$first_item_mod" -eq 0 ]; then
    echo "1" # Return 1 (true)
  else
    echo "0" # Return 0 (false)
  fi
}

# Function to check if the current item is the last item on the page
is_last_page_item() {
  local current_item="$1"   # Current item number (0-based index)
  local items_per_page="$2" # Items per page
  local total_items="$3"    # Total number of items

  # Calculate the last item index of the current page (0-based)
  # Last items are those which are of the form: p-1, 2p, 3p+1, ...
  local last_item_mod=$(((current_item + 1) % items_per_page))
  if [ "$last_item_mod" -eq 0 ] || [ "$current_item" -eq "$((total_items - 1))" ]; then
    echo "1" # Return 1 (true)
  else
    echo "0" # Return 0 (false)
  fi
}

is_new_page_handler() {
  local key="$1"
  local current_idx="$2"
  local num_options="$3"
  local page_size="$4"

  # Calculate total pages
  local total_pages=$(((num_options + page_size - 1) / page_size)) # ceiling division
  local more_than_one_page=$((total_pages > 1))

  # Get booleans for navigation keys
  local move_up_bool=$(to_integer "$(set_move_boolean "$key" "$up_key")")
  local move_down_bool=$(to_integer "$(set_move_boolean "$key" "$down_key")")
  local move_left_bool=$(to_integer "$(set_move_boolean "$key" "$left_key")")
  local move_right_bool=$(to_integer "$(set_move_boolean "$key" "$right_key")")

  # Check for first and last page items
  is_first_page_item_bool=$(is_first_page_item "$current_idx" "$page_size")
  is_last_page_item_bool=$(is_last_page_item "$current_idx" "$page_size" "$num_options")

  # Determine if there is movement to a new page
  local move_sideways=$((move_left_bool || move_right_bool))
  local move_up_first_page=$((is_first_page_item_bool && move_up_bool))
  local move_down_last_page=$((is_last_page_item_bool && move_down_bool))

  # Determine if it's a new page
  local is_new_page=$((
    more_than_one_page && \
    (move_sideways || move_down_last_page || move_up_first_page)
))

  # Output result
  echo "$is_new_page"
}

# Custom function to join an array into a single string with a delimiter
join_array() {
  local delimiter="$1"
  shift
  local array=("$@")
  local result=""

  for item in "${array[@]}"; do
    if [ -z "$result" ]; then
      result="$item"
    else
      result+="$delimiter$item"
    fi
  done

  echo "$result"
}

# Define individual menu item
build_menu_item() {
  local label="$1"
  local description="$2"
  local action="$3"

  # Validate inputs
  if [ -z "$label" ] || [ -z "$description" ] || [ -z "$action" ]; then
    echo "Error: Missing argument(s). All arguments (label, description, action) are required."
    return 1
  fi

  # Generate JSON object using jq directly
  jq -n \
    --arg label_ "$label" \
    --arg description_ "$description" \
    --arg action_ "$action" \
    '{
        label: $label_,
        description: $description_,
        action: $action_
    }'
}

# Build a JSON array of menu items
build_array_from_items() {
  # Capture all arguments as an array
  local items=("$@")

  echo "["$(join_array "," "${items[@]}")"]"
}

# Append a JSON menu array to the MENUS array under a specific key
build_menu() {
  local title=$1
  shift
  local page_size=$1
  shift
  local json_array

  if [ $# -eq 0 ]; then
    echo "Error: At least one menu item is required."
    return 1
  fi

  # Build the menu as a JSON array
  menu_items=$(build_array_from_items "$@")

  # Create final menu object
  jq -n \
    --arg title "$title" \
    --arg page_size "$page_size" \
    --argjson items "$menu_items" \
    '{
            title: $title,
            page_size: $page_size,
            items: $items
        }'
}

index_to_page() {
  local current_index="$1"
  local page_size="$2"

  # Check for valid inputs
  if [[ -z "$current_index" || -z "$page_size" || "$page_size" -le 0 ]]; then
    echo "Invalid arguments: current_index=$current_index, page_size=$page_size" >&2
    return 1
  fi

  # Calculate the page number (zero-indexed)
  local page_number=$((current_index / page_size + 1))

  # Output the calculated page number
  echo "$page_number"
}

move_cursor() {
  # $1 is the row (line) position
  # $2 is the column position
  echo -e "\033[$1;${2}H"
}

clear_below_line() {
  local line=$1

  # Move the cursor to the desired line (line is zero-indexed)
  tput cup "$line" 0

  # Clear everything below the current line
  tput ed
}


# Function to calculate the arrow position in the terminal
get_arrow_position() {
  local current_idx="$1"
  local page_size="$2"
  local header_row_count="$3"

  # Calculate the start index for the current page
  local start=$((current_idx / page_size * page_size))

  # Calculate the arrow row position based on header lines and current item
  local arrow_row=$((header_row_count + (current_idx - start)))

  echo "$arrow_row"
}

# Function to process all lines in parallel and maintain order
display_parallel() {
  local -n _lines=$1 # Array passed by reference
  local -a pids=()   # Array to hold process IDs

  # Process each line in parallel
  for i in "${!_lines[@]}"; do
    line="${_lines[i]}"
    {
      echo -e "$line"
    } &
    pids+=($!) # Store the process ID for each background process
  done

  # Wait for all processes to finish
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

# Global variables for cleanup
current_pid=0

kill_current_pid(){
  # Start the scrolling message for the selected option
  if [[ "$current_pid" -ne 0 ]]; then
      kill "$current_pid" 2>/dev/null  # Kill the previous background process
  fi
}

# Cleanup function to restore terminal state and stop background processes
cleanup() {
    tput cnorm  # Restore cursor visibility
    kill_current_pid
    tput reset  # Reset terminal to a clean state (clear screen and reset attributes)
}

finish_session() {
    cleanup
    exit 0;
}

# Trap SIGINT (Ctrl+C) and EXIT (script termination) to invoke the cleanup function
trap finish_session SIGINT EXIT

# Function to shift a message in the background
shift_message() {
    local message="$1"
    local max_width="$2"
    local x_position="$3"
    local y_position="$4"
    local shifted_message="$message"
    local shift_offset=0

    tput civis  # Hide the cursor
    while true; do
        # Prepare the shifted message
        local rotated_message="${shifted_message:shift_offset}${shifted_message:0:shift_offset}"
        rotated_message="${rotated_message:0:$max_width}"

        # Move cursor to the specified position and print the message
        tput cup "$y_position" "$x_position"
        printf "%-*s" "$max_width" "$rotated_message"

        # Increment the shift offset
        ((shift_offset++))
        if [[ "$shift_offset" -ge ${#shifted_message} ]]; then
            shift_offset=0
        fi

        sleep 0.15
    done
}

run_shift_message(){
  local current_idx="$1"
  local page_size="$2"
  local header_row_count="$3"
  local menu_options=("${@:4}")

  # Start the scrolling message for the selected option
  kill_current_pid

  # Get the current option
  current_option="${menu_options[current_idx]}"
  item_label="$(get_menu_item_label "$current_option")"
  item_description="$(get_menu_item_description "$current_option")"
  item_label_length="${#item_label}"
  
  # Calculate the arrow row position based on header lines and current item
  # Hard-coded: Try a dynamic approach
  header_row_count="2"
  arrow_position="$(get_arrow_position "$current_idx" "$page_size" "2")"
  horizontal_shift=$((header_row_count+item_label_length+2))

  shift_length="$TRUNCATED_DEFAULT_LENGTH"

  shift_message \
    "$item_description " "$shift_length" "$horizontal_shift" "$arrow_position" &
  current_pid=$!  # Store the background process ID
}

# Render the menu with page navigation and options
render_menu() {
  # Hide cursor
  tput civis

  local title="$1"
  local previous_idx="$2"
  local current_idx="$3"
  local page_size="$4"
  local is_new_page="$5"
  local menu_options=("${@:6}")

  local num_options=${#menu_options[@]}

  # Keyboard shortcuts based on search mode with colors
  ud_nav_option="${highlight_color}↗↘${reset_color}: Nav"
  lr_nav_option="${highlight_color}◁▷${reset_color}: Pages"
  sel_nav_option="${select_color}↵${reset_color}: Sel"
  goto_nav_option="${goto_color}g${reset_color}: Go to Page"
  back_option="${back_color}r${reset_color}: Return"
  search_option="${search_color}/${reset_color}:Search"
  help_option="${help_color}h${reset_color}: Help"
  quit_option="${quit_color}q${reset_color}: Quit"

  # Store keyboard options in an array
  keyboard_options=(
    "$ud_nav_option"
    "$lr_nav_option"
    "$sel_nav_option"
    "$goto_nav_option"
    "$back_option"
    "$search_option"
    "$quit_option"
    "$help_option"
  )

  # Join the options with a space delimiter
  keyboard_options_string=$(join_array ", " "${keyboard_options[@]}")

  keyboard_options_without_color=$(strip_ansi "$keyboard_options_string")
  keyboard_options_length="${#keyboard_options_without_color}"

  keyboard_line_count=2

  kill_current_pid

  # Prepare static part of the menu (Header and Instructions)
  # Clear the entire screen if it's a new page
  if [[ "$is_new_page" == "1" ]]; then
    clear
  fi

  # Move cursor to top-left and render header
  tput cup 0 0

  echo "$(display_text "$title" "$keyboard_options_length" --center)" >&2
  echo >&2

  # FIXME: header count must be dynamics based on the actual header row height 
  header_row_count=2

  # Determine the range of options to display based on the current index
  local start=$((current_idx / page_size * page_size))
  local end=$((start + page_size))
  end=$((end > num_options ? num_options : end))

  # Array to hold the lines for menu options
  local menu_lines=()

  # Collect options with label and description
  for i in $(seq $start $((end - 1))); do
    option_label=$(get_menu_item_label "${menu_options[i]}")
    option_desc=$(get_menu_item_description "${menu_options[i]}")

    truncated_option_desc="$(truncate_option "$option_desc")"

    # Add the option (label + description) to the menu
    option="${option_label}: ${truncated_option_desc}"

    menu_lines+=("$option")
  done

  # Fill remaining space if fewer items than page size
  local remaining_space=$((page_size - (end - start)))
  for _ in $(seq 1 $remaining_space); do
    # Add empty lines to keep layout consistent
    menu_lines+=(" ")
  done

  # Render menu lines and handle arrow position
  for i in "${!menu_lines[@]}"; do
    # Move cursor to the line position
    tput cup $((i + header_row_count)) 0

    local menu_line="${menu_lines[$i]}"
    if [[ $((start + i)) -eq $current_idx ]]; then
      # Add the arrow next to the line
      echo -e "${COLORED_ARROW} ${menu_line}" >&2
    else
      # Render line without an arrow
      echo -e "  ${menu_line} " >&2
    fi
  done

  # Display page count and keyboard options (move cursor to the footer)
  tput cup $((page_size + 3)) 0
  echo -e "$keyboard_options_string" >&2
  echo >&2

  # Render the page navigation footer
  local total_pages=$(((num_options + page_size - 1) / page_size))
  local current_page=$(((start / page_size) + 1))
  local page_text="Page $current_page/$total_pages"
    
  # Move cursor to page text position
  tput cup $((page_size + 4)) 0
  echo -e "\n$(display_text "$page_text" "$keyboard_options_length" --center)" >&2

  page_line_count=2

  idx=$((current_idx))
  current_option_desc=$(get_menu_item_description "${menu_options[$idx]}")

  if [[ ${#current_option_desc} -gt $TRUNCATED_DEFAULT_LENGTH ]]; then
    run_shift_message "$current_idx" "$page_size" "$header_row_count" "${menu_options[@]}"
  else 
    kill_current_pid
  fi
}

handle_arrow_key() {
  local key="$1"
  local current_idx="$2"
  local num_options="$3"
  local page_size="$4"
  local total_pages="$5"

  case "$key" in
    "$up_key")
      if ((current_idx > 0)); then
        ((current_idx--))
      else
        current_idx=$((num_options - 1))  # Wrap to the last option
      fi
      ;;

    "$down_key")
      if ((current_idx < num_options - 1)); then
        ((current_idx++))
      else
        current_idx=0  # Wrap to the first option
      fi
      ;;

    "$left_key")
      if ((total_pages > 1)); then
        if ((current_idx - page_size >= 0)); then
          current_idx=$(((current_idx / page_size - 1) * page_size))  # Navigate to the previous page
        else
          current_idx=$((((num_options - 1) / page_size) * page_size))  # Wrap to the last page
        fi
      fi
      ;;

    "$right_key")
      if ((total_pages > 1)); then
        next_page_start=$(((current_idx / page_size + 1) * page_size))
        if ((next_page_start < num_options)); then
          current_idx=$next_page_start  # Move to the next page
        else
          current_idx=0  # Wrap to the first page
        fi
      fi
      ;;
  esac

  echo "$current_idx"
}

go_to_specific_page() {
  local current_idx="$1"
  local num_options="$2"
  local page_size="$3"
  local title="$4"
  local is_new_page="$5"
  shift 5
  local menu_options=("$@")

  local previous_idx=$current_idx
  echo -ne "${faded_color}Enter the page number: ${reset_color}" >&2
  read -e -r page_number  # Input with no echo

  # Validate input
  if [[ ! "$page_number" =~ ^[1-9][0-9]*$ ]]; then
    echo -e "${error_color}Invalid input! Please enter a positive number.${reset_color}" >&2
    return "$current_idx"
  fi

  page_number=$((page_number - 1))  # Adjust to zero-indexed
  local max_page=$(((num_options - 1) / page_size))
  if ((page_number > max_page)); then
    echo -e "${error_color}Page number out of range! Valid range: 1-$((max_page + 1)).${reset_color}" >&2
    return "$current_idx"
  fi

  # Update current index to new page
  current_idx=$((page_number * page_size))
  render_menu "$title" "$previous_idx" "$current_idx" "$page_size" "$is_new_page" "${menu_options[@]}"

  # Prompt to return to the previous menu
  while true; do
    echo -ne "${faded_color}Would you like to return to the previous menu? (y/n): ${reset_color}" >&2
    read -r go_back_choice
    case "$go_back_choice" in
      [yY])
        current_idx=$previous_idx
        break
        ;;
      [nN])
        break
        ;;
      *)
        echo -e "${error_color}Invalid choice! Please enter 'y' or 'n'.${reset_color}" >&2
        ;;
    esac
  done

  echo "$current_idx"
}

navigate_menu() {
  clean_screen
  
  local menu_json="$1"
  local title page_size menu_items_json
  local menu_options=()
  
  title=$(jq -r '.title' <<<"$menu_json")
  page_size=$(jq -r '.page_size' <<<"$menu_json")
  menu_items_json=$(jq -r '.items' <<<"$menu_json")

  # Convert JSON array to Bash array
  while IFS= read -r item; do
    menu_options+=("$item")
  done < <(jq -r '.[] | @json' <<<"$menu_items_json")

  local original_menu_options=("${menu_options[@]}")
  local num_options=${#menu_options[@]}
  local total_pages=0 is_new_page=0 previous_idx=0 current_idx=0

  if [[ $num_options -eq 0 ]]; then
    message="${error_color}Error: No options provided to the menu!${reset_color}"
    echo -e "$message" >&2
    exit 1
  fi

  while true; do
    render_menu \
        "$title" "$previous_idx" "$current_idx" \
        "$page_size" "$is_new_page" "${menu_options[@]}"

    # Locking the keyboard input to avoid unnecessary display of captured characters
    read -rsn1 key

    # FIXME: Header, keyboard shortcuts and page counting may be dynamic
    menu_line_count=$((page_size+6))
    kill_current_pid
    move_cursor $menu_line_count 0

    # Dynamically calculate the vertical position for the message
    num_options=${#menu_options[@]}
    total_pages="$(calculate_total_pages "$num_options" "$page_size")"

    # Save for later usage
    previous_idx=$current_idx

    case "$key" in
    $'\x1B')  # Detect escape sequences (e.g., arrow keys)
      read -rsn2 -t 0.25 key
      is_new_page=$(is_new_page_handler "$key" "$current_idx" "$num_options" "$page_size")

      # Call the function to handle arrow key input
      current_idx=$(handle_arrow_key "$key" "$current_idx" "$num_options" "$page_size" "$total_pages")
      ;;

    # Go to specific page
    "g")  
        local previous_idx=$current_idx
        echo -ne "${faded_color}Enter the page number: ${reset_color}" >&2
        read -e -r page_number  # Input with no echo
        
        if [[ "$page_number" =~ ^[1-9][0-9]*$ ]]; then
            page_number=$((page_number - 1))
            local max_page=$(((num_options - 1) / page_size))
            if ((page_number > max_page)); then
                echo -e "${error_color}Page number out of range!${reset_color}" >&2
                sleep 1
            else
                # Check if we're already on the same page
                local previous_page=$((previous_idx / page_size))
                if [[ "$previous_page" -eq "$current_page" ]]; then
                    echo -e "${warning_color}You are already on the current page.${reset_color}" >&2
                    sleep 1  # Wait for 1 second before doing nothing
                    clear_below_line $menu_line_count
                    continue  # Skip further execution to prevent changing the page
                fi

                current_idx=$((page_number * page_size))
                is_new_page=1
                render_menu "$title" "$previous_idx" "$current_idx" "$page_size" "$is_new_page" "${menu_options[@]}"
                while true; do
                    echo -ne "${faded_color}Would you like to return to the previous menu? (y/n): ${reset_color}" >&2
                    read -r go_back_choice
                    case "$go_back_choice" in
                    [yY])
                        current_idx=$previous_idx
                        sleep 1
                        break
                        ;;
                    [nN])
                        break
                        ;;
                    *)
                        echo -e "${error_color}Invalid choice!${reset_color}" >&2
                        ;;
                    esac
                done
            fi
        else
            echo -e "${error_color}Invalid input!${reset_color}" >&2
            sleep 1
        fi
        ;;

    # Reset menu options
    "r")
      menu_options=("${original_menu_options[@]}")
      current_idx=0
      continue
      ;;

    # Start search
    "/")
        echo -ne "${faded_color}Search: ${reset_color}" >&2
        read -e -r search_key
        # Clear the line if the prompt disappears after backspace
        echo -ne "\033[2K\r"  # Clears the current line

        if [[ "$search_key" == "r" ]]; then
            menu_options=("${original_menu_options[@]}")
            continue
        fi

        filtered_options=()
        for option in "${original_menu_options[@]}"; do
            label=$(echo "$option" | jq -r '.label // empty')
            description=$(echo "$option" | jq -r '.description // empty')
            if [[ "$label" == *"$search_key"* || "$description" == *"$search_key"* ]]; then
                filtered_options+=("$option")
            fi
        done

        if [[ ${#filtered_options[@]} -eq 0 ]]; then
            menu_options=("${original_menu_options[@]}")
            echo "No matches found, resetting to original options." >&2
            sleep 0.5
        else
            menu_options=("${filtered_options[@]}")
            current_idx=0
        fi

        is_new_page=1
        ;;

    # Show help
    "h")
      show_help
      sleep 3
      is_new_page=1
      ;;

    # Enter key (select option)
    "")
      echo >&2
      option_label=$(get_menu_item_label "${menu_options[current_idx]}")
      question="Are you sure you want to select \"$option_label\"? (y/n)"
      message="${faded_color}$question${reset_color}"
      if handle_confirmation_prompt "$message" confirm; then
          option_action=$(get_menu_item_action "${menu_options[current_idx]}")
          clean_screen
          kill_current_pid
          trap 'echo -e "\n${faded_color}Operation interrupted. Returning to menu.${reset_color}"; return' SIGINT
          (eval "$option_action") || echo -e "${faded_color}Action failed. Returning to menu.${reset_color}"
          trap - SIGINT
          sleep 2
          clean_screen
      fi
      ;;

    # Exit menu
    "q")
      message="${faded_color}Are you sure you want to exit the menu? (y/n)${reset_color}"
      request_confirmation "$message" confirm_exit false
      if [[ "${confirm_exit}" == "y" || "${confirm_exit}" == "Y" ]]; then
        message="${faded_color}Exiting the menu... Goodbye!${reset_color}"
        echo -e "$message" >&2
        finish_session
        break
      fi
      ;;

    *)
      echo >&2
      shoutout="Invalid key pressed!"
      keyboard_options="Please use ↑/↓ to navigate, ←/→ to switch pages, or Enter to select."
      message="${error_color}$shoutout $keyboard_options${reset_color}"
      echo -e "$message" >&2
      sleep 1
      is_new_page=1
      ;;
    esac

    clear_below_line $menu_line_count
  done

  # Show cursor
  tput cnorm
}

# Settings Menu
item_1="$(
    build_menu_item \
    "Option 1" \
    "Very long description 1 to allow truncation on the menu selection line 123" \
    "echo 'Option 1 selected' >&2"
)"
item_2="$(build_menu_item "Option 2" "Description 2" "echo 'Option 2 selected' >&2")"
item_3="$(build_menu_item "Option 3" "Description 3" "echo 'Option 3 selected' >&2")"
item_4="$(build_menu_item "Option 4" "Description 4" "echo 'Option 4 selected' >&2")"
item_5="$(build_menu_item "Option 5" "Description 5" "echo 'Option 5 selected' >&2")"
item_6="$(build_menu_item "Option 6" "Description 6" "echo 'Option 6 selected' >&2")"
item_7="$(build_menu_item "Option 7" "Description 7" "echo 'Option 7 selected' >&2")"
item_8="$(build_menu_item "Option 8" "Description 8" "echo 'Option 8 selected' >&2")"

page_size=5

menu_object="$(
  build_menu "Main" $page_size \
    "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" "$item_6" "$item_7" "$item_8"
)"

navigate_menu "$menu_object"

# Ensure the cursor is visible at the end
tput cnorm