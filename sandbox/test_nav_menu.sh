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
    local prompt="$3"
    
    echo -ne "$message" >&2
    tput cub "$cursor_move"  # Move cursor back to where the message started
    read -rsn1 "$prompt"  # Read a single character input from the user
}

# Function to request confirmation (yes/no)
request_confirmation() {
    local message="$1"
    local confirm_variable_name="$2"
    local default_value="${3:-false}"
    
    # Request input with confirmation message
    request_input "$message" 0 "$confirm_variable_name" "$default_value"
    
    # Validate the input
    while [[ ! "${!confirm_variable_name}" =~ ^[yYnN]$ ]]; do
        invalid_message="${faded_color}\nInvalid input \"${!confirm_variable_name}\". Please enter 'y' for yes or 'n' for no.\n${reset_color}"
        echo -ne "$invalid_message" >&2
        tput cub ${#invalid_message}
        request_input "$message" 0 "$confirm_variable_name" "$default_value"
    done
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
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        reason="Missing argument(s)."
        advice="All three arguments (label, action, description) are required."
        echo "Error: $reason $advice"
        return 1
    fi

    # Create the JSON-like string for this menu item
    json='{"label":"'"$1"'","description":"'"$3"'","action":"'"$2"'"}'
    
    # Return the JSON string
    echo "$json"
}

# Build a JSON array of menu items
build_menu_array() {
    # Capture all arguments as an array
    local items=("$@")

    echo "["$(join_array "," "${items[@]}")"]"
}

# Append a JSON menu array to the MENUS array under a specific key
define_menu() {
    local key=$1
    shift
    local json_array

    if [ $# -eq 0 ]; then
        echo "Error: At least one menu item is required."
        return 1
    fi

    # Build the menu as a JSON array
    json_array=$(build_menu_array "$@")
    MENUS["$key"]="$json_array"
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
    tput civis  # Hide cursor
    
    local header="$1"
    local current_idx="$2"
    local page_size="$3"
    local menu_options=("${@:4}")
    local num_options=${#menu_options[@]}

    tput cup 0 0                    # Move cursor to top-left
    clean_screen                    # Clear screen
    display_header "$header"        # Display header
    echo -e "${faded_color}Keyboard Shortcuts:${reset_color}" >&2
    echo -e "  ↗/↘: Navigate  ◁/▷: Switch Pages  ↵: Select  q: Quit\n" >&2

    local start=$((current_idx / page_size * page_size))
    local end=$((start + page_size))
    end=$((end > num_options ? num_options : end))

    # Array to hold the lines for menu options
    local menu_lines=()

    # Collect options with label, description, and additional blank lines for spacing
    for i in $(seq $start $((end - 1))); do
        option_label=$(get_menu_item_label "${menu_options[i]}")
        option_desc=$(get_menu_item_description "${menu_options[i]}")

        if [[ $i -eq $current_idx ]]; then
            option="${highlight_color}→ ${option_label}: ${option_desc}${reset_color}"
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

    # Display current page and total pages
    local total_pages=$(((num_options + page_size - 1) / page_size))
    local current_page=$(((start / page_size) + 1))
    menu_lines+=("\nPage $current_page of $total_pages${reset_color}")

    # Display navigation indicators
    if ((start > 0 && num_options > page_size)); then
        menu_lines+=("${faded_color}... More options above ...${reset_color}")
    fi
    if ((end < num_options)); then
        menu_lines+=("${faded_color}... More options below ...${reset_color}")
    fi

    # Render all collected lines in parallel
    display_parallel menu_lines
}

# Main navigation loop
navigate_menu() {
    default_message="${title_color}=== Navigation Menu ===${reset_color}"
    local header="${1:-$default_message}"
    shift
    local page_size="$1"
    shift
    local menu_options=("$@")
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

# Example dynamic menu array generation
generate_dynamic_options() {
    local base="$1"
    local count="$2"
    options=()
    for i in $(seq 1 "$count"); do
        options+=("${base} Option $i")
    done
}

menu_items=(
    '{"label": "Option 1", "description": "Description 1", "action": "echo \"Option 1 selected\""}'
    '{"label": "Option 2", "description": "Description 2", "action": "echo \"Option 2 selected\""}'
    '{"label": "Option 3", "description": "Description 3", "action": "echo \"Option 3 selected\""}'
    '{"label": "Option 4", "description": "Description 4", "action": "echo \"Option 4 selected\""}'
    '{"label": "Option 5", "description": "Description 5", "action": "echo \"Option 5 selected\""}'
    '{"label": "Option 6", "description": "Description 6", "action": "echo \"Option 6 selected\""}'
    '{"label": "Option 7", "description": "Description 7", "action": "echo \"Option 7 selected\""}'
    '{"label": "Option 8", "description": "Description 8", "action": "echo \"Option 8 selected\""}'
)

page_size=8
navigate_menu "My Menu" $page_size "${menu_items[@]}"
