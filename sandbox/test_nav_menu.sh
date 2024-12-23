#!/usr/bin/env bash

# Define a global associative array for storing menu items
declare -A MENUS

# Highlight and color variables for styling
highlight_color="\033[1;32m"   # Highlight color (Bright Green)
faded_color="\033[2m"          # Faded color (Dark gray)
error_color="\033[1;31m"       # Error color (Dark red)
title_color="\033[1;36m"       # Title color (Cyan)
reset_color="\033[0m"          # Reset color

up_key="[A"                    # Up Arrow
down_key="[B"                  # Down Arrow
left_key="[D"                  # Left Arrow
right_key="[C"                 # Right Arrow

# Disable canonical mode, set immediate input
stty -icanon min 1 time 0      
trap "stty sane" EXIT          # Ensure terminal settings are restored on script exit

# Function to clean the terminal screen
clean_screen(){
    echo -ne "\033[H\033[J" >&2
}

# Function to display the header
display_header(){
    local header="$1"
    echo -e "$header\n" >&2
}

query_json_value(){
    local menu_item="$1"
    local query="$2"

    echo "$menu_item" | jq -r "$query"
}

get_menu_item_label(){
    local menu_item="$1"
    query_json_value "$menu_item" ".label"
}

get_menu_item_description(){
    local menu_item="$1"
    query_json_value "$menu_item" '.description'
}

get_menu_item_action(){
    local menu_item="$1"
    query_json_value "$menu_item" '.action'
}

# Function to display a message, move the cursor, and read user input
request_input() {
    local message="$1"
    local cursor_move="$2"
    local variable_name="$3"
    
    echo -ne "$message" >&2
    tput cub "$cursor_move"  # Move cursor back to where the message started
    read -rsn1 "$variable_name"  # Read a single character input into the specified variable
}

# Function to request confirmation (yes/no)
request_confirmation() {
    local message="$1"
    local confirm_variable_name="$2"
    local default_value="${3:-false}"

    local user_input=""
    request_input "$message" 0 user_input

    # Use default value if input is empty
    if [[ -z "$user_input" && "$default_value" != "false" ]]; then
        user_input="$default_value"
    fi

    local error_message
    local reason

    # Validate the input
    while [[ ! "$user_input" =~ ^[yYnN]$ ]]; do
        error_message="\nInvalid input \"$user_input\"."
        reason="Please enter 'y' for yes or 'n' for no.\n${reset_color}"
        local invalid_message="${faded_color} "
        echo -ne "$invalid_message" >&2
        tput cub ${#invalid_message}
        request_input "$message" 0 user_input
    done

    # Assign the validated input to the confirmation variable
    printf -v "$confirm_variable_name" "%s" "$user_input"
}


# Function to truncate option text to a max length
truncate_option() {
    local option="$1"
    local max_length=30
    if [[ ${#option} -gt $max_length ]]; then
        echo "${option:0:$((max_length - 3))}..."
    else
        echo "$option"
    fi
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
    local header=$1
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
    jq -n --arg header "$header" --arg page_size "$page_size" --argjson items "$menu_items" '{
        header: $header,
        page_size: $page_size,
        items: $items
    }'
}

# Function to process all lines in parallel and maintain order
display_parallel() {
  local -n _lines=$1  # Array passed by reference
  local -a pids=()     # Array to hold process IDs

  # Process each line in parallel
  for i in "${!_lines[@]}"; do
    line="${_lines[i]}"
    {
      echo -e "$line"
    } &
    pids+=($!)  # Store the process ID for each background process
  done

  # Wait for all processes to finish
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

# Render the menu with page navigation and options
render_menu() {
    # Hide cursor
    tput civis

    local header="$1"
    local current_idx="$2"
    local page_size="$3"
    local menu_options=("${@:4}")
    local num_options=${#menu_options[@]}

    # Prepare static part of the menu (Header and Instructions)
    tput cup 0 0  # Move cursor to top-left
    clean_screen  # Optional, clear screen only if needed
    display_header "$header"  # Display header
    echo -e "${faded_color}Keyboard Shortcuts:${reset_color}" >&2
    echo -e "  ↗/↘: Navigate  ◁/▷: Switch Pages  ↵: Select  q: Quit\n" >&2

    # Determine the range of options to display based on current index
    local start=$((current_idx / page_size * page_size))
    local end=$((start + page_size))
    end=$((end > num_options ? num_options : end))

    # Array to hold the lines for menu options
    local menu_lines=()

    # Collect options with label, description, and additional blank lines for spacing
    for i in $(seq $start $((end - 1))); do
        option_label=$(get_menu_item_label "${menu_options[i]}")
        option_desc=$(get_menu_item_description "${menu_options[i]}")

        # Highlight the current option with an arrow
        if [[ $i -eq $current_idx ]]; then
            option="${highlight_color}→${reset_color} ${option_label}: ${option_desc}"
            menu_lines+=("$option")
        else
            menu_lines+=("  ${option_label}: ${option_desc}")
        fi
    done

    # Fill remaining space if fewer items than page size
    local remaining_space=$((page_size - (end - start)))
    for _ in $(seq 1 $remaining_space); do
        menu_lines+=("")  # Add empty lines to keep layout consistent
    done

    # Display current page and total pages (this will be updated dynamically)
    local total_pages=$(((num_options + page_size - 1) / page_size))
    local current_page=$(((start / page_size) + 1))
    menu_lines+=("\n${fade_color}Page $current_page/$total_pages${reset_color}")

    # Render only the dynamic parts (menu options and page number)
    for line in "${menu_lines[@]}"; do
        echo -e "$line"
    done

    # Ensure the cursor is visible at the end
    tput cnorm
}



navigate_menu() {
    local menu_json="$1"

    # Parse JSON to extract header, page size, and items
    local header
    local page_size
    local menu_items_json

    header=$(jq -r '.header' <<<"$menu_json")
    page_size=$(jq -r '.page_size' <<<"$menu_json")
    menu_items_json=$(jq -r '.items' <<<"$menu_json")

    # Convert JSON array to Bash array
    local menu_options=()
    while IFS= read -r item; do
        menu_options+=("$item")
    done < <(jq -r '.[] | @json' <<<"$menu_items_json")

    local original_menu_options=("${menu_options[@]}")
    local num_options=${#menu_options[@]}
    local current_idx=0

    if [[ $num_options -eq 0 ]]; then
        echo -e "${error_color}Error: No options provided to the menu!${reset_color}" >&2
        exit 1
    fi

    while true; do
        render_menu "$header" $current_idx "$page_size" "${menu_options[@]}"
        read -rsn1 key
        case "$key" in
        $'\x1B') # Start of escape sequence
            read -rsn2 -t 0.1 key
            case "$key" in
            "$up_key")   # Up arrow
                if ((current_idx > 0)); then
                    ((current_idx--))
                fi
                ;;

            "$down_key") # Down arrow
                if ((current_idx < num_options - 1)); then
                    ((current_idx++))
                fi
                ;;

            "$left_key") # Left arrow (previous page)
                if ((current_idx - page_size >= 0)); then
                    current_idx=$(( (current_idx / page_size - 1) * page_size ))
                else
                    current_idx=0
                fi
                ;;

            "$right_key") # Right arrow (next page)
                if ((current_idx + page_size < num_options)); then
                    current_idx=$(( (current_idx / page_size + 1) * page_size ))
                else
                    current_idx=$((num_options - 1))
                fi
                ;;

            esac
            ;;

        "/")  # Start search
            echo -e "${faded_color}Search: ${reset_color}" >&2
            read -r search_key
            if [[ -z "$search_key" ]]; then
                menu_options=("${original_menu_options[@]}")
                continue
            fi
            filtered_options=()
            for option in "${original_menu_options[@]}"; do
                if [[ $option == *"$search_key"* ]]; then
                    filtered_options+=("$option")
                fi
            done
            menu_options=("${filtered_options[@]}")
            if ((current_idx >= ${#menu_options[@]})); then
                current_idx=$(( ${#menu_options[@]} - 1 ))
            fi
            ;;
        "") # Enter key
            option_label=$(get_menu_item_label "${menu_options[current_idx]}")
            question="Are you sure you want to select \"$option_label\"? (y/n)"
            message="${faded_color}$question${reset_color}"

            # Request confirmation from the user using request_confirmation
            request_confirmation "$message" confirm

            while [[ ! "$confirm" =~ ^[yYnN]$ ]]; do
                reason="Invalid input \"$confirm\""
                select_options="Please enter 'y' for yes or 'n' for no."
                invalid_message="${faded_color}$reason\n. $select_options\n${reset_color}"
                echo -ne "$invalid_message" >&2
                tput cub ${#invalid_message}
                
                # Re-prompt for confirmation if the input is invalid
                echo -ne "${faded_color}$message${reset_color}" >&2
                request_confirmation "$message" confirm
            done

            echo >&2

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Perform the action after confirmation
                option_action=$(get_menu_item_action "${menu_options[current_idx]}")
                eval "$option_action"
                sleep 2
                
                clean_screen
                break
            fi
            ;;


        "q")  # q key to exit
            # Ask for confirmation
            request_confirmation "${faded_color}Are you sure you want to exit the menu? (y/n)${reset_color}" confirm_exit false
            
            # Proceed with exit if confirmed
            if [[ "${confirm_exit}" == "y" || "${confirm_exit}" == "Y" ]]; then
                echo -e "${faded_color}Exiting the menu... Goodbye!${reset_color}" >&2
                clean_screen
                break
            fi
            ;;

        *)  # Handle invalid key input
            shoutout="Invalid key pressed!"
            keyboard_options="Please use ↑/↓ to navigate, ←/→ to switch pages, or Enter to select."
            message="${error_color}$shoutout $keyboard_options${reset_color}"
            echo -e "$message" >&2
            sleep 1
            ;;

        esac
    done

    # Show cursor
    tput cnorm 
}

# Settings Menu
item_1="$(build_menu_item "Option 1" "Description 1" "echo 'Option 1 selected'")"
item_2="$(build_menu_item "Option 2" "Description 2" "echo \"Option 2 selected\"")"
item_3="$(build_menu_item "Option 3" "Description 3" "echo \"Option 3 selected\"")"
item_4="$(build_menu_item "Option 4" "Description 4" "echo \"Option 4 selected\"")"
item_5="$(build_menu_item "Option 5" "Description 5" "echo \"Option 5 selected\"")"
item_6="$(build_menu_item "Option 6" "Description 6" "echo \"Option 6 selected\"")"
item_7="$(build_menu_item "Option 7" "Description 7" "echo \"Option 7 selected\"")"
item_8="$(build_menu_item "Option 8" "Description 8" "echo \"Option 8 selected\"")"

page_size=5

menu_object="$(
    build_menu "Main" $page_size \
    "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" "$item_6" "$item_7" "$item_8"
)"

navigate_menu "$menu_object"
