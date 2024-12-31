#!/usr/bin/env bash

# Define a global associative array for storing menu items
declare -A MENUS

# Define a global array for storing navigation history
menu_navigation_history=()

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

# Color definitions for styling
bold="\033[1m"
green="\033[32m"
yellow="\033[33m"
red="\033[31m"
normal="\033[0m"

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

###############################################################################

# Functions for diagnostics
cpu_usage() {
    # Example usage of display_text to show a centered header
    display_text "CPU USAGE" 40 --center --style "${bold_color}${green}"
    echo ""
    uptime
    echo ""
}

memory_usage() {
    display_text "MEMORY USAGE" 40 --center --style "${bold_color}${green}"
    echo ""
    free -h
    echo ""
}

disk_usage() {
    display_text "DISK USAGE" 40 --center --style "${bold_color}${green}"
    echo ""
    df -h
    echo ""
}

network_usage() {
    display_text "NETWORK USAGE" 40 --center --style "${bold_color}${green}"
    echo ""
    ip -s link
    echo ""
}

top_processes() {
    # Define color and formatting variables
    local bold="\033[1m"
    local green="\033[32m"
    local normal="\033[0m"
    local separator="=============================================="

    # Print a styled header with separators
    echo -e "${bold}${green}${separator}${normal}"
    display_text "TOP 5 PROCESSES BY CPU & MEMORY USAGE" 40 --center --style "${bold_color}${green}"
    echo -e "${bold}${green}${separator}${normal}"

    # Display only the relevant columns: PID, USER, %CPU, %MEM, and COMMAND
    ps aux --sort=-%cpu,-%mem | awk 'NR<=6 {print $1, $2, $3, $4, $11}' | column -t

    # Print an empty line for separation
    echo ""
}

security_diagnostics() {
    display_text "SECURITY DIAGNOSTICS" 40 --center --style "${bold_color}${green}"
    echo -e "${blue}Open Ports:${normal}"
    ss -tuln
    echo -e "\n${blue}Failed Login Attempts:${normal}"
    grep "Failed password" /var/log/auth.log | tail -n 5
    echo ""
}

storage_insights() {
    echo -e "${bold}${green}== STORAGE INSIGHTS ==${normal}"
    echo -e "${blue}Largest Files:${normal}"
    du -ah / | sort -rh | head -n 10
    echo -e "\n${blue}Inode Usage:${normal}"
    df -i
    echo ""
}

load_average() {
    echo -e "${bold}${green}== LOAD AVERAGE & UPTIME ==${normal}"
    uptime
    echo ""
}

bandwidth_usage() {
    echo -e "${bold}${green}== BANDWIDTH USAGE ==${normal}"
    if command -v vnstat &> /dev/null; then
        vnstat
    else
        echo -e "${red}vnstat is not installed. Please install it to monitor bandwidth.${normal}"
    fi
    echo ""
}

update_and_check_vps_packages() {
    # Check for the package manager (apt)
    if command -v apt &> /dev/null; then
        echo -e "${bold}${green}== PACKAGE UPDATES ==${normal}"

        # Check for upgradable packages
        upgradable_packages=$(apt list --upgradable 2>/dev/null)
        if [[ -z "$upgradable_packages" ]]; then
            echo -e "${green}No upgradable packages.${normal}" >&2
        else
            echo -e "${yellow}Upgradable packages detected.${normal}" >&2

            # Ask for confirmation
            message="${yellow}Would you like to update and upgrade the packages? (Y/n)${normal}"
            if handle_confirmation_prompt \
              "$message" "update_packages" "y" "5"; then
                echo ""

                # Notify update start
                echo -e "${yellow}Updating packages...${normal}"

                # Update and upgrade without logging output
                sudo apt update -y > /dev/null 2>&1
                sudo apt upgrade -y > /dev/null 2>&1
                sudo apt autoremove -y > /dev/null 2>&1
                sudo apt clean > /dev/null 2>&1

                # Notify update completion
                echo -e "${green}Update complete!${normal}" >&2
            else
                echo -e "${red}Update aborted.${normal}" >&2
            fi
        fi
    else
        echo -e "${red}Package manager not supported.${normal}" >&2
    fi

    echo ""
}


##############################################################################

# Function to prompt user and wait for any key press
press_any_key() {
    # Prompt user and wait for any key press
    echo -e "${highlight_color}Press any key to continue...${normal}"
    
    # Wait for a single key press without the need to press Enter
    read -n 1 -s  # -n 1 means read one character, -s means silent mode (no echo)
    
    # Newline for better readability after key press
    echo ""
}


# Function to show help
show_help() {
  local menu_options_count="$1"
  local page_size="$2"

  echo -e "${highlight_color}↗↘${reset_color}  - Navigate down- and upwards"

  # Check if there are more items than the page size
  if (( $menu_options_count > page_size )); then
    echo -e "${highlight_color}◁▷${reset_color}  - Navigate sideways"
  fi

  echo -e "${select_color}↵${reset_color}   - Select current option"
  echo -e "${back_color}g${reset_color}   - Go to specific page"
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

# Function to get the label of a menu item
get_menu_item_label() {
  local menu_item="$1"
  query_json_value "$menu_item" ".label"
}

# Function to get the description of a menu item
get_menu_item_description() {
  local menu_item="$1"
  query_json_value "$menu_item" '.description'
}

# Function to get the action of a menu item
get_menu_item_action() {
  local menu_item="$1"
  query_json_value "$menu_item" '.action'
}

# Function to display a message, move the cursor, and read user input with an optional timeout
request_input() {
  local message="$1"
  local cursor_move="$2"
  local variable_name="$3"
  local timeout="$4"  # Optional timeout value in seconds

  echo -ne "$message" >&2
  tput cuf "$cursor_move" # Move cursor forward by the specified number of characters

  if [[ -n "$timeout" ]]; then
    read -rsn1 -t "$timeout" "$variable_name" || eval "$variable_name=''"  # Timeout or empty input
  else
    read -rsn1 "$variable_name" # No timeout
  fi
}


# Function to request confirmation (yes/no)
request_confirmation() {
  local message="$1"
  local confirm_variable_name="$2"
  local default_value="${3:-false}"
  local timeout="$4"

  local user_input=""
  request_input "$message" 1 user_input "$timeout"

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
    local default_value=${3:-false}
    local timeout=$4

    while true; do
        # Request confirmation from the user
        request_confirmation "$prompt_message" "$confirm_var" "$default_value" "$timeout"

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

# Function to check if there is movement to a new page
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

# Improved and fancy header display using '=' and '|', with colorized minus signs
show_header() {
    local header="$1"
    local width=${2:-$HEADER_WIDTH}     # Default width to 50 if not provided
    local border_color="\033[1;34m"     # Blue border color
    local header_color="\033[1;37m"     # White text for header
    local reset_color="\033[0m"         # Reset color

    # Create the top and bottom border with colorized minus signs
    local border=$(printf '%*s' $((width-2)) '' | tr ' ' '-')
    local colorized_lu_border="${border//-/${border_color}-}"
    
    # Print top border
    echo -e "${border_color}+${reset_color}${colorized_lu_border}${border_color}+${reset_color}"

    # Print header with padding
    local colorized_side_border="${border_color}|${reset_color}"
    local colorized_header="${header_color}${header}${reset_color}"
    local left_padding=$(( (width - ${#header}) / 2 ))
    local right_padding=$((width - ${#header} - left_padding - 2))
    local spaced_header="$(\
      printf '%*s' $left_padding '')$colorized_header$(printf '%*s' $right_padding '')"

    # Print the header inside borders
    printf "${colorized_side_border}${spaced_header}${colorized_side_border}\n"

    # Print bottom border
    echo -e "${border_color}+${reset_color}${colorized_lu_border}${border_color}+${reset_color}"
}

# Define individual menu item
build_menu_item() {
  local label="$1"
  local description="$2"
  local action="$3"

  # Validate inputs
  if [ -z "$label" ] ||  [ -z "$action" ]; then
    echo "Error: Missing argument(s). Arguments (label, action) are required." >&2
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

# Remove one of the redundant build_menu functions
build_menu() {
  local title="$1"
  shift
  local page_size="$1"
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

# Append a menu object to the MENUS array
define_menu() {
    local key="$1"
    local menu_object="$2"

    
    MENUS["$key"]+="$menu_object"
}

# Function to get the current menu
get_current_menu() { 
  if [ ${#menu_navigation_history[@]} -gt 0 ]; then
    echo "${menu_navigation_history[-1]}"
  fi
}


# Function to get a specific menu
get_menu() { 
  echo "${MENUS[$1]}"
}

# Modify push_menu to accept multiple levels of nesting
push_menu_in_history() { 
    if [[ -n "$1" ]]; then
        menu_navigation_history+=("$1")
    else
        echo "Invalid menu name. Cannot push an empty menu."
    fi
}

# Pop menu from stack
pop_menu_from_history() {
    if [ ${#menu_navigation_history[@]} -gt 0 ]; then
        unset menu_navigation_history[-1]
    fi
}

# Helper function to check if a menu is already in the stack
is_menu_in_history() {
    local menu_name=$1
    for menu in "${menu_navigation_history[@]}"; do
        if [[ "$menu" == "$menu_name" ]]; then
            return 0  # menu found
        fi
    done
    return 1  # menu not found
}

# Return to the parent menu (previous menu)
return_to_parent_menu() {
    if [ ${#menu_navigation_history[@]} -gt 1 ]; then
        pop_menu
        local parent_menu=$(get_current_menu)
        navigate_menu "$parent_menu"
    else
        navigate_menu "Main"
    fi
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

# Function to calculate the page number
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

# Function to move the cursor
move_cursor() {
  # $1 is the row (line) position
  # $2 is the column position
  echo -e "\033[$1;${2}H"
}

# Function to clear everything below a specific line
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

# Function to start the scrolling message for the selected option
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
  # FIXME: Hard-coded, Try a dynamic approach
  header_row_count="2"
  arrow_position="$(get_arrow_position "$current_idx" "$page_size" "2")"
  horizontal_shift=$((header_row_count+item_label_length+2))

  shift_length="$TRUNCATED_DEFAULT_LENGTH"

  shift_message \
    "$item_description " "$shift_length" "$horizontal_shift" "$arrow_position" &
  current_pid=$!  # Store the background process ID
}

# Helper: Calculate the range of options to display
calculate_display_range() {
  local current_idx="$1"
  local page_size="$2"
  local num_options="$3"

  local start=$((current_idx / page_size * page_size))
  local end=$((start + page_size))
  end=$((end > num_options ? num_options : end))

  echo "$start $end"
}

# Helper: Render menu options
render_options() {
  local start="$1"
  local end="$2"
  local current_idx="$3"
  local header_row_count="$4"
  local menu_options=("${@:5}")

  local menu_lines=()

  for i in $(seq $start $((end - 1))); do
    option_label=$(get_menu_item_label "${menu_options[i]}")
    option_desc=$(get_menu_item_description "${menu_options[i]}")
    truncated_option_desc="$(truncate_option "$option_desc")"
    
    if [[ -z "$option_desc" ]]; then
      option="${option_label}"
    else
      option="${option_label}: ${truncated_option_desc}"
    fi
    
    
    menu_lines+=("$option")
  done

  # Fill remaining space if fewer items than page size
  local remaining_space=$((end - start))
  for _ in $(seq 1 $remaining_space); do
    menu_lines+=(" ")
  done

  # Render each menu line
  for i in "${!menu_lines[@]}"; do
    tput cup $((i + header_row_count)) 0
    local menu_line="${menu_lines[$i]}"
    if [[ $((start + i)) -eq $current_idx ]]; then
      echo -e "${COLORED_ARROW} ${menu_line}" >&2
    else
      echo -e "  ${menu_line} " >&2
    fi
  done
}

# Helper: Render the header with title and keyboard shortcuts
render_header() {
  local title="$1"
  local page_width="$2"
  
  tput cup 0 0
  echo "$(display_text "$title" "$page_width" --center)" >&2
  echo >&2
}

# Function to print a centered header with customizable width
print_centered_header() {
    local text="$1"
    local width="$2"
    local padding

    # Calculate padding for centering
    padding=$(( (width - ${#text}) / 2 ))

    # Print the header with padding
    printf "%-${padding}s" " "  # Left padding
    echo -e "${bold}${green}${text}${normal}"
    printf "%-${padding}s" " "  # Right padding
}

# Render breadcrumb trail
render_breadcrumb() {
  local breadcrumb=""
  for menu in "${menu_navigation_history[@]}"; do
    breadcrumb+="$menu > "
  done
  breadcrumb=${breadcrumb% > }
  echo -e "${highlight_color}Current Path: ${breadcrumb}${reset_color}" >&2
}

# Helper: Render the footer with page count and navigation
render_footer() {
  local current_idx="$1"
  local page_size="$2"
  local page_width="$3"
  local num_options="$4"
  local keyboard_options_string="$5"

  local total_pages=$(((num_options + page_size - 1) / page_size))
  local current_page=$((current_idx / page_size + 1))
  local page_text="Page $current_page/$total_pages"

  # Display keyboard options
  tput cup $((page_size + 3)) 0
  echo -e "$keyboard_options_string" >&2
  echo >&2

  render_breadcrumb
  tput cup $((page_size + 4)) 0
  echo "" >&2

  # Display page text
  tput cup $((page_size + 5)) 0
  echo -e "\n$(display_text "$page_text" "$page_width" --center)" >&2
}

# Main: Render the menu with the given parameters
render_menu() {
  tput civis
  local title="$1"
  local current_idx="$2"
  local page_size="$3"
  local is_new_page="$4"
  local menu_options=("${@:5}")

  local num_options=${#menu_options[@]}

  current_menu_name="$(get_current_menu)"

  # Prepare keyboard shortcuts
  local ud_nav_option="${highlight_color}↗↘${reset_color}: Nav"
  local sel_nav_option="${select_color}↵${reset_color}: Sel"
  local goto_nav_option=""
  local back_option="${back_color}r${reset_color}: Return"
  local search_option="${search_color}/${reset_color}: Search"
  local help_option="${help_color}h${reset_color}: Help"
  local quit_option=""
  local lr_nav_option=""

  if (( num_options > page_size )); then
    lr_nav_option="${highlight_color}◁▷${reset_color}: Pages"
  fi

  if (( num_options / page_size > 1 )); then
    goto_nav_option="${goto_color}g${reset_color}: Go to Page"
  fi

  if [[ $current_menu_name == "Main" ]]; then
    quit_option="${quit_color}q${reset_color}: Quit"
  else
    quit_option="${quit_color}q${reset_color}: Back"
  fi

  # Combine keyboard options
  local keyboard_options=(
    "$ud_nav_option"
    "$lr_nav_option"
    "$sel_nav_option"
    "$search_option"
    "$goto_nav_option"
    "$back_option"
    "$quit_option"
    "$help_option"
  )
  local keyboard_options_string=$(join_array ", " "${keyboard_options[@]}")
  
  local tmp="$(strip_ansi "$keyboard_options_string")"
  local page_width="${#tmp}"

  # Handle new page rendering
  if [[ "$is_new_page" == "1" ]]; then
    clear
  fi

  # Render header
  render_header "$title" "$page_width"
  echo >&2
  
  # Determine the range of options to display
  local range
  range=$(calculate_display_range "$current_idx" "$page_size" "$num_options")
  local start end
  read -r start end <<< "$range"

  # Render menu options
  local header_row_count=2
  render_options "$start" "$end" "$current_idx" "$header_row_count" "${menu_options[@]}"

  # Render footer
  render_footer "$current_idx" "$page_size" "$page_width" "$num_options" "$keyboard_options_string"

  # Handle option-specific description
  local current_option_desc
  current_option_desc=$(get_menu_item_description "${menu_options[$current_idx]}")
  if [[ ${#current_option_desc} -gt $TRUNCATED_DEFAULT_LENGTH ]]; then
    run_shift_message "$current_idx" "$page_size" "$header_row_count" "${menu_options[@]}"
  else
    kill_current_pid
  fi
}

# Helper: Handle arrow key input
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
          # Navigate to the previous page
          current_idx=$(((current_idx / page_size - 1) * page_size))
        else
          # Wrap to the last page
          current_idx=$((((num_options - 1) / page_size) * page_size))
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

# Function to navigate to a specific page
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
    message="Invalid input! Please enter a positive number."
    echo -e "${error_color}${message}${reset_color}" >&2
    return "$current_idx"
  fi

  page_number=$((page_number - 1))  # Adjust to zero-indexed
  local max_page=$(((num_options - 1) / page_size))
  if ((page_number > max_page)); then
    message="Page number out of range! Valid range: 1-$((max_page + 1))."
    echo -e "${error_color}$message${reset_color}" >&2
    return "$current_idx"
  fi

  # Update current index to new page
  current_idx=$((page_number * page_size))
  render_menu \
    "$title" "$current_idx" \
    "$page_size" "$is_new_page" "${menu_options[@]}"

  # Prompt to return to the previous menu
  while true; do
    message="Would you like to return to the previous menu? (y/n): "
    echo -ne "${faded_color}$message${reset_color}" >&2
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

# Enhanced animated transition between menus with spinning loader and text effects
transition_to_menu() {
  local new_menu="$1"
  local progress_bar=""
  local progress_length=30
  local colors=("\033[1;34m" "\033[1;32m" "\033[1;36m" "\033[1;35m" "\033[1;31m")
  local spin_chars=('/' '-' '\\' '|')
  
  # Clear the line and show the initial transition message
  echo -ne "\r${colors[0]}Transitioning to ${new_menu}... ${reset_color}" >&2

  for ((i=0; i<progress_length; i++)); do
    # Update the progress bar
    progress_bar+="="
    
    # Cycle through colors for a smooth transition effect
    color_index=$((i % ${#colors[@]}))
    
    # Add spinning loader
    spin_index=$((i % ${#spin_chars[@]}))
    spin_char="${spin_chars[$spin_index]}"

    echo -ne "\r${colors[color_index]}${spin_char} Transitioning to ${new_menu}... [${progress_bar}]${reset_color}" >&2
    
    # Delay to create the animation effect
    sleep 0.05
  done

  # Finalize the transition with a fade-in effect
  echo -ne "\r${highlight_color}${spin_char} Transitioning to ${new_menu}... [${progress_bar}] Done!${reset_color}\n" >&2
  sleep 0.3
}


# Function to navigate to a specific menu
navigate_menu() {
  local menu_name="$1"

  clean_screen
  transition_to_menu "$menu_name"
  clean_screen
  
  menu_json=$(get_menu "$menu_name")

  # If the menu_navigation_history is empty, set the first menu as the current menu
  if ! is_menu_in_history "$menu_name"; then
      push_menu_in_history "$menu_name"
  fi

  local title page_size menu_items_json
  local menu_options=()
  local debounce_time=0.25
  
  title=$(jq -r '.title' <<<"$menu_json")
  page_size=$(jq -r '.page_size' <<<"$menu_json")
  menu_items_json=$(jq -r '.items' <<<"$menu_json")

  # Convert JSON array to Bash array
  while IFS= read -r item; do
    menu_options+=("$item")
  done < <(jq -r '.[] | @json' <<<"$menu_items_json")

  local original_menu_options=("${menu_options[@]}")
  local num_options=${#menu_options[@]}

  local total_pages="$(calculate_total_pages "$num_options" "$page_size")" 
  local is_new_page=1 previous_idx=0 current_idx=0

  if [[ $num_options -eq 0 ]]; then
    message="${error_color}Error: No options provided to the menu!${reset_color}"
    echo -e "$message" >&2
    exit 1
  fi

  while true; do
    render_menu \
        "$title" "$current_idx" \
        "$page_size" "$is_new_page" "${menu_options[@]}"

    # Locking the keyboard input to avoid unnecessary display of captured characters
    read -rsn1 key

    # Clear stale characters if any
    if [[ $? -eq 142 ]]; then
      key=""  # Clear the key if the read command times out
    fi

    # FIXME: Header, keyboard shortcuts and page counting may be dynamic
    menu_line_count=$((page_size+7))
    kill_current_pid
    move_cursor $menu_line_count 0

    # Dynamically calculate the vertical position for the message
    num_options=${#menu_options[@]}
    total_pages="$(calculate_total_pages "$num_options" "$page_size")"

    # Save for later usage
    previous_idx=$current_idx

    case "$key" in
    $'\x1B')  # Detect escape sequences (e.g., arrow keys)
      read -rsn2 -t "$debounce_time" key
      is_new_page=$(is_new_page_handler "$key" "$current_idx" "$num_options" "$page_size")

      # Call the function to handle arrow key input
      current_idx=$(\
        handle_arrow_key "$key" "$current_idx" "$num_options" "$page_size" "$total_pages"
      )
      ;;

    # Go to specific page
    "g")  
        previous_idx=$current_idx
        echo -ne "${faded_color}Enter the page number: ${reset_color}" >&2
        read -e -r page_number  # Input with no echo
        
        if [[ "$page_number" =~ ^[1-9][0-9]*$ ]]; then
            page_number=$((page_number - 1))
            local max_page=$(((num_options - 1) / page_size))
            if ((page_number > max_page)) ; then
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
                render_menu \
                  "$title" "$current_idx" \
                  "$page_size" "$is_new_page" "${menu_options[@]}"
                while true; do
                    message="Would you like to return to the previous menu? (y/n): "
                    echo -ne "${faded_color}${message}${reset_color}" >&2
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
        echo -ne "\033[2K\r"

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
      show_help "$num_options" "$page_size"
      sleep 2
      ;;

    # Enter key (select option)
    "")
      echo >&2
      option_label=$(get_menu_item_label "${menu_options[current_idx]}")
      question="Are you sure you want to select \"$option_label\"? (Y/n)"
      message="${faded_color}$question${reset_color}"
      if handle_confirmation_prompt "$message" confirm 'n'; then
          option_action=$(get_menu_item_action "${menu_options[current_idx]}")

          clean_screen
          kill_current_pid

          message="\n${faded_color}Operation interrupted. Returning to menu.${reset_color}"
          command="echo -e \"$message\"; return"
          trap "$command" SIGINT

          (eval "$option_action") || echo -e "$message"
          sleep 1

          trap - SIGINT

          clean_screen
          
      fi
      ;;

    # Exit menu
    "q")
      message="${faded_color}Are you sure you want to exit this menu? (y/n)${reset_color}"
      request_confirmation "$message" confirm_exit false
      
      if [[ "${confirm_exit}" == "y" || "${confirm_exit}" == "Y" ]]; then
        clean_screen
        current_menu=$(get_current_menu)
        pop_menu_from_history
        previous_menu=$(get_current_menu)

        if [[ "$current_menu" == "Main" ]]; then
          message="${faded_color}Exiting program.${reset_color}"
        else
          message="${faded_color}Returning to $previous_menu menu.${reset_color}"
        fi

        echo -e "$message" >&2
        sleep 0.25
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
}

# Menus Functions

# Menu Main
define_menu_main(){
  menu_name="Main"

  item_1="$(build_menu_item "Menu 1" "Options of Menu 1" "navigate_menu 'Menu 1'")"
  item_2="$(build_menu_item "Menu 2" "Options of Menu 2" "navigate_menu 'Menu 2'")"
  item_3="$(build_menu_item "VPS Health" "diagnose" "navigate_menu 'VPS health'")"
  
  page_size=5

  menu_object="$(build_menu "$menu_name" $page_size "$item_1" "$item_2" "$item_3")"

  define_menu "$menu_name" "$menu_object"
}

# Menu 1
define_menu_1(){
  menu_name="Menu 1"

  item_1="$(
      build_menu_item \
      "Option 1.1" \
      "Very long description 1.1 to allow truncation on the menu selection 123567890" \
      "echo 'Option 1.1 selected' >&2"
  )"
  item_2="$(build_menu_item "Option 1.2" "Description 1.2" "echo 'Option 1.2 selected' >&2")"
  item_3="$(build_menu_item "Option 1.3" "Description 1.3" "echo 'Option 1.3 selected' >&2")"
  item_4="$(build_menu_item "Option 1.4" "Description 1.4" "echo 'Option 1.4 selected' >&2")"
  item_5="$(build_menu_item "Option 1.5" "Description 1.5" "echo 'Option 1.5 selected' >&2")"
  item_6="$(build_menu_item "Option 1.6" "Description 1.6" "echo 'Option 1.6 selected' >&2")"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size \
      "$item_1" "$item_2" "$item_3" \
      "$item_4" "$item_5" "$item_6"
  )"

  define_menu "$menu_name" "$menu_object"
}

# Menu 2
define_menu_2(){
  menu_name="Menu 2"

  item_1="$(
      build_menu_item \
      "Option 2.1" \
      "Very long description 2.1 to allow truncation on the menu selection 123567890" \
      "echo 'Option 2.1 selected' >&2"
  )"
  item_2="$(build_menu_item "Option 2.2" "Description 2.2" "echo 'Option 2.2 selected' >&2")"
  item_3="$(build_menu_item "Option 2.3" "Description 2.3" "echo 'Option 2.3 selected' >&2")"
  item_4="$(build_menu_item "Option 2.4" "Description 2.4" "echo 'Option 2.4 selected' >&2")"
  item_5="$(build_menu_item "Option 2.5" "Description 2.5" "echo 'Option 2.5 selected' >&2")"
  item_6="$(build_menu_item "Option 2.6" "Description 2.6" "echo 'Option 2.6 selected' >&2")"
  item_7="$(build_menu_item "Option 2.7" "Description 2.7" "echo 'Option 2.7 selected' >&2")"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size \
      "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" "$item_6"
  )"

  define_menu "$menu_name" "$menu_object"
}

# VPS Health
define_menu_vps_health(){
  menu_name="VPS health"

  item_1="$(
    build_menu_item "CPU Usage" "Current CPU percentage usage" \
    "cpu_usage && press_any_key"
  )"
  item_2="$(
    build_menu_item "Memory Usage" "Current memory percentage usage" \
    "memory_usage && press_any_key"
  )"
  item_3="$(
    build_menu_item "Disk Usage" "Current disk percentage usage" \
    "disk_usage && press_any_key"
  )"
  item_4="$(
    build_menu_item "Network Usage" "Current network usage" \
    "network_usage && press_any_key"
  )"
  item_5="$(\
    build_menu_item "Top Processes" "Processes sorted by CPU and memory usage" \
    "top_processes && press_any_key" \
  )"
  item_6="$(build_menu_item "Security Diagnostics" "" \
    "security_diagnostics && press_any_key")"
  item_7="$(build_menu_item "Load Average" "" \
    "load_average && press_any_key")"
  item_8="$(build_menu_item "Bandwidth Usage" "" \
    "bandwidth_usage && press_any_key")"
  item_9="$(build_menu_item "Package Updates" "" \
    "update_and_check_vps_packages && press_any_key")"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size \
      "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" \
      "$item_6" "$item_7" "$item_8" "$item_9"
  )"

  define_menu "$menu_name" "$menu_object"
}

# Populate MENUS
define_menus(){
    define_menu_main
    define_menu_1
    define_menu_2
    define_menu_vps_health
}

start_main_menu(){
    navigate_menu "Main";
}

# Populate MENUS
define_menus

# Start the main menu
start_main_menu
