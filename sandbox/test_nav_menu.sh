#!/usr/bin/env bash

# Define a global associative array for storing menu items
declare -A MENUS

# Highlight and color variables for styling
highlight_color="\033[1;32m"   # Highlight color (Bright Green)
faded_color="\033[2m"          # Faded color (Dark gray)
select_color="\033[1;34m"      # Blue for select (↵)
return_color="\033[1;35m"      # Magenta for return (r)
quit_color="\033[1;31m"        # Red for quit (q)
error_color="\033[1;31m"       # Error color (Dark red)
title_color="\033[1;36m"       # Title color (Cyan)
goto_color="\033[1;36m"        # Go-to page color (Cyan)
help_color="\033[1;35m"        # Help color (Magenta)
reset_color="\033[0m"          # Reset color

# Define arrow keys for navigation
up_key="[A"                    # Up Arrow
down_key="[B"                  # Down Arrow
left_key="[D"                  # Left Arrow
right_key="[C"                 # Right Arrow

# Disable canonical mode, set immediate input
stty -icanon min 1 time 0

# Ensure terminal settings are restored on script exit
trap "stty sane" EXIT

# Function to clean the terminal screen
clean_screen(){
    echo -ne "\033[H\033[J" >&2
}

# Function to strip ANSI escape sequences from a string
strip_ansi() {
    pattern='s/\x1b\[[0-9;]*[mK]//g'
    echo -e "$1" | sed "$pattern"
}

# Function to show help
show_help() {
    echo "Help Menu:"
    echo "↗↘  - Navigate down- and upwards"
    echo "◁▷ - Navigate down- and upwards"
    echo "↵   - Select current option"
    echo "r   - Return to begin of menu"
    echo "/   - Search on current menu"
    echo "q   - Quit the application"
    echo "h   - Show this help menu"
}

ud_nav_option="${highlight_color}↗↘${reset_color}: Nav"
lr_nav_option="${highlight_color}◁▷${reset_color}: Pages"
sel_nav_option="${select_color}↵${reset_color}: Sel"
goto_nav_option="${goto_color}g${reset_color}: Go to Page"
back_option="${return_color}r${reset_color}: Back"
search_option="${quit_color}/${reset_color}: Search"
quit_option="${quit_color}q${reset_color}: Quit"

# Function to display styled and optionally centered text with custom or terminal width
display_text() {
    local text="$1"               # The text to display
    local custom_width="$2"       # Custom width for the text
    local padding=0               # Optional padding around the text
    local center=false            # Set to true to center the text
    local style="${bold_color}"   # Optional style (e.g., bold or colored)

    # Check if additional options are provided
    shift 2  # Skip the first two arguments (text and custom_width)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --center) center=true ;;
            --style) style="$2"; shift ;;
            --padding) padding="$2"; shift ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
        shift
    done

    # If custom width is not provided, use terminal width (tput cols)
    if [[ -z "$custom_width" ]]; then
        custom_width=$(tput cols)
    fi

    # Ensure padding is valid
    if (( padding < 0 )); then
        echo "Padding must be non-negative." >&2
        return 1
    fi

    # Calculate text length with padding
    local padded_text=$(printf "%${padding}s%s%${padding}s" "" "$text" "")
    local text_length=${#padded_text}

    # Ensure the custom width is at least the length of the text
    if (( custom_width < text_length )); then
        echo "Error: Custom width ($custom_width) is smaller than text length ($text_length)." >&2
        return 1
    fi

    # Center the text if needed
    if [[ "$center" == true ]]; then
        local left_padding=$(( (custom_width - text_length) / 2 ))
        padded_text=$(printf "%${left_padding}s%s" "" "$padded_text")
    fi

    # Ensure the text fits within the custom width
    local final_text=$(printf "%-${custom_width}s" "$padded_text")

    # Apply styling and display
    echo -e "${style}${final_text}${reset_color}"
}

# Function to get a specific value from a JSON object
query_json_value(){
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

# 
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
    tput cuf "$cursor_move"  # Move cursor forward by the specified number of characters
    read -rsn1 "$variable_name"  # Read a single character input into the specified variable
}

# Function to request confirmation (yes/no)
request_confirmation() {
    local message="$1"
    local confirm_variable_name="$2"
    local default_value="${3:-false}"

    local user_input=""
    request_input "$message" 1 user_input  # Move 1 character forward

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
        request_input "$message" 1 user_input  # Move 1 character forward
    done

    # Assign the validated input to the confirmation variable
    printf -v "$confirm_variable_name" "%s" "$user_input"
}

# Function to truncate option text to a max length
truncate_option() {
    local option="$1"
    local max_length="${2-50}"
    if [[ ${#option} -gt $max_length ]]; then
        echo "${option:0:$((max_length - 3))}..."
    else
        echo "$option"
    fi
}

# Function to calculate total pages
calculate_total_pages() {
    local total_items="$1"   # Total number of items
    local items_per_page="$2" # Number of items per page

    # Calculate total pages, rounding up if necessary
    total_pages=$(( (total_items + items_per_page - 1) / items_per_page ))

    echo "$total_pages"
}

# Function to check if the current item is the last item on the page
is_last_page_item() {
    local current_item="$1"   # Current item number (1-based index)
    local items_per_page="$2" # Number of items per page
    local total_items="$3"    # Total number of items

    # Calculate the last item number for the current page
    last_item_on_page=$(( current_item / items_per_page * items_per_page ))

    # Adjust if the current page isn't full (for the last page)
    if [ "$current_item" -gt "$last_item_on_page" ]; then
        last_item_on_page=$(( (total_items + items_per_page - 1) / items_per_page * items_per_page ))
    fi

    # Check if the current item is the last item on the page
    if [ "$current_item" -eq "$last_item_on_page" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check if the current item is the first item on the page
is_first_page_item() {
    local current_item="$1"   # Current item number (1-based index)
    local items_per_page="$2" # Number of items per page

    # Check if the current item is the first item on the page
    if [ "$current_item" -eq 1 ]; then
        echo "true"
    else
        echo "false"
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
    jq -n --arg title "$title" --arg page_size "$page_size" --argjson items "$menu_items" '{
        title: $title,
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

# Function to calculate the arrow position in the terminal
get_arrow_position() {
    local current_idx="$1"
    local page_size="$2"
    local header_lines="$3"

    # Calculate the start index for the current page
    local start=$((current_idx / page_size * page_size))

    # Calculate the arrow row position based on header lines and current item
    local arrow_row=$((header_lines + (current_idx - start) + 1))

    echo "$arrow_row"
}

# Render the menu with page navigation and options
render_menu() {
    # Hide cursor
    tput civis

    local title="$1"
    local current_idx="$2"
    local page_size="$3"
    local menu_options=("${@:4}")

    local num_options=${#menu_options[@]}

    # Keyboard shortcuts based on search mode with colors
    ud_nav_option="${highlight_color}↗↘${reset_color}: Nav"
    lr_nav_option="${highlight_color}◁▷${reset_color}: Pages"
    sel_nav_option="${select_color}↵${reset_color}: Sel"
    goto_nav_option="${goto_color}g${reset_color}: Go to Page"
    back_option="${return_color}r${reset_color}: Back"
    search_option="${quit_color}/${reset_color}: Search"
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
    keyboard_options_string=$(join_array " " "${keyboard_options[@]}")

    keyboard_options_without_color=$(strip_ansi "$keyboard_options_string")
    keyboard_length="${#keyboard_options_without_color}"

    # Prepare static part of the menu (Header and Instructions)
    tput cup 0 0  # Move cursor to top-left
    clean_screen  # Optional, clear screen only if needed
    
    echo >&2
    echo "$(display_text "$title" "$keyboard_length" --center)" >&2
    echo >&2
    echo -e "$keyboard_options_string" >&2
    echo >&2

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

        # Add the option (label + description) to the menu
        menu_lines+=("  ${option_label}: ${option_desc}")
    done

    # Fill remaining space if fewer items than page size
    local remaining_space=$((page_size - (end - start)))
    for _ in $(seq 1 $remaining_space); do
        # Add empty lines to keep layout consistent
        menu_lines+=("")
    done

    # Render menu lines and calculate arrow position
    for i in "${!menu_lines[@]}"; do
        # Determine if this is the highlighted option
        local menu_line="${menu_lines[$i]}"
        if [[ $((start + i)) -eq $current_idx ]]; then
            # Add the arrow next to the line
            echo -e "${highlight_color}→${reset_color} ${menu_line}"
        else
            # Render line without an arrow
            echo -e "   ${menu_line}"
        fi
    done

    # Display page count
    echo >&2
    echo -e "$keyboard_options_string" >&2
    echo >&2

    # Render the page navigation footer
    local total_pages=$(((num_options + page_size - 1) / page_size))
    local current_page=$(((start / page_size) + 1))
    local page_text="Page $current_page/$total_pages"

    # Add the centered page text to the menu
    echo -e "\n$(display_text "$page_text" "$keyboard_length" --center)"

    # Ensure the cursor is visible at the end
    tput cnorm
}

navigate_menu() {
    local menu_json="$1"

    # Parse JSON to extract header, page size, and items
    local title
    local page_size
    local menu_items_json

    title=$(jq -r '.title' <<<"$menu_json")
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
    local total_pages=

    if [[ $num_options -eq 0 ]]; then
        message="${error_color}Error: No options provided to the menu!${reset_color}"
        echo -e "$message" >&2
        exit 1
    fi

    while true; do
        render_menu "$title" $current_idx "$page_size" "${menu_options[@]}"
        read -rsn1 key

        local num_options=${#menu_options[@]}

        move_up=false
        move_down=false
        move_left=false
        move_right=false

        # Check and set the booleans using the function
        move_up="$(set_move_boolean "$key" "$up_key")"
        move_down="$(set_move_boolean "$key" "$down_key")"
        move_left="$(set_move_boolean "$key" "$left_key")"
        move_right="$(set_move_boolean "$key" "$right_key")" 

        # Display results
        echo "Move Up: $move_up" >&2
        echo "Move Down: $move_down" >&2
        echo "Move Left: $move_left" >&2
        echo "Move Right: $move_right" >&2
        sleep 1

        case "$key" in
        $'\x1B') # Start of escape sequence
            read -rsn2 -t 0.1 key
            case "$key" in
            "$up_key")   # Up arrow
                if ((current_idx > 0)); then
                    ((current_idx--))
                else
                    current_idx=$((num_options - 1)) # Wrap to the last option
                fi
                ;;

            "$down_key") # Down arrow
                if ((current_idx < num_options - 1)); then
                    ((current_idx++))
                else
                    current_idx=0 # Wrap to the first option
                fi
                ;;

            "$left_key") # Left arrow (previous page)
                if ((current_idx - page_size >= 0)); then
                    current_idx=$(( (current_idx / page_size - 1) * page_size ))
                else
                    # Wrap to the last page
                    current_idx=$(( ((num_options - 1) / page_size) * page_size ))
                fi
                ;;

            "$right_key") # Right arrow (next page)
                if ((current_idx + page_size < num_options)); then
                    current_idx=$(( (current_idx / page_size + 1) * page_size ))
                else
                    # Wrap to the first page
                    current_idx=0
                fi
                ;;

            esac
            ;;

        # "g" key to go to a specific page
        "g")
            # Store the current page index before making any changes
            local previous_idx=$current_idx

            # Prompt for page number input
            echo -ne "${faded_color}Enter the page number: ${reset_color}" >&2
            read -e -r page_number

            # Check if the input is a valid number
            if [[ "$page_number" =~ ^[0-9]+$ ]]; then
                page_number=$((page_number - 1))  # Adjust to zero-indexed
                local max_page=$(( (num_options - 1) / page_size ))

                if ((page_number > max_page)); then
                    # Page doesn't exist (out of bounds)
                    message="${error_color}Page number out of range! Please enter a valid page.${reset_color}"
                    echo -e "$message" >&2
                    sleep 1
                else
                    # Page exists, navigate to it
                    current_idx=$((page_number * page_size))

                    # Render the menu on the new page
                    render_menu "$title" $current_idx "$page_size" "$is_new_page" "${menu_options[@]}"

                    # Ask if the user wants to go back to the current menu
                    echo -ne "${faded_color}Would you like to go back to the current menu (y/n)? ${reset_color}"
                    read -r go_back_choice

                    if [[ "$go_back_choice" == "y" || "$go_back_choice" == "Y" ]]; then
                        # Reset to the previous page if the user wants to go back
                        current_idx=$previous_idx
                        echo -e "${faded_color}Returning to the previous menu...${reset_color}" >&2
                        sleep 1
                    else
                        echo -e "${faded_color}You are now on page $((page_number + 1)).${reset_color}" >&2
                    fi
                fi
            else
                # Invalid input (not a number)
                message="${error_color}Invalid input! Please enter a valid page number.${reset_color}"
                echo -e "$message" >&2
                sleep 1
            fi
            ;;

        # "r" key to reset the menu to original options
        "r")  
            # Reset the menu to the original options
            menu_options=("${original_menu_options[@]}")  
            
            # Reset to the first item (first page)
            current_idx=0


            continue
            ;;

        # Start search
        "/")  
            # Print the prompt with colors using echo
            echo -ne "${faded_color}Search: ${reset_color}" >&2

            # Move the cursor to the end of the printed message using tput
            tput cuf 0

            # Read the user input without printing the escape sequences
            read -e -r search_key

            # Check for 'r' to reset to original menu options
            if [[ "$search_key" == "r" ]]; then
                # Reset the menu to the original options
                menu_options=("${original_menu_options[@]}")  
                continue
            fi

            # If search_key is empty, reset to original options
            if [[ -z "$search_key" ]]; then
                menu_options=("${original_menu_options[@]}")
                continue
            fi

            # Initialize filtered options
            filtered_options=()

            # Filter the options based on the search key
            for option in "${original_menu_options[@]}"; do
                # Skip empty items and filter options
                if [[ -n "$option" && "$option" == *"$search_key"* ]]; then
                    filtered_options+=("$option")
                fi
            done

            # If no options match the search, reset to original options
            if [[ ${#filtered_options[@]} -eq 0 ]]; then
                menu_options=("${original_menu_options[@]}")
            else
                menu_options=("${filtered_options[@]}")
                current_idx=0
            fi
            ;;

        "h")
            show_help
            sleep 3
            ;;

        # Enter key
        "") 
            echo >&2

            option_label=$(get_menu_item_label "${menu_options[current_idx]}")
            question="Are you sure you want to select \"$option_label\"? (y/n)"
            message="${faded_color}$question${reset_color}"

            # Request confirmation from the user using request_confirmation
            request_confirmation "$message" confirm

            while [[ ! "$confirm" =~ ^[yYnN]$ ]]; do
                # Display invalid input message and prompt again
                reason="Invalid input \"$confirm\""
                select_options="Please enter 'y' for yes or 'n' for no."
                invalid_message="${faded_color}$reason\n$select_options\n${reset_color}"

                # Clear the current line and print the invalid message
                echo -e "$invalid_message" >&2

                # Re-display the confirmation prompt
                echo -ne "${faded_color}$message${reset_color}" >&2
                request_confirmation "$message" confirm
            done

            echo >&2

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Perform the action after confirmation
                option_action=$(get_menu_item_action "${menu_options[current_idx]}")
                clean_screen
                
                eval "$option_action"
                sleep 2
                
                break
            fi
            ;;


        # q key to exit
        "q")
            echo >&2

            # Ask for confirmation
            message="${faded_color}Are you sure you want to exit the menu? (y/n)${reset_color}"
            request_confirmation "$message" confirm_exit false

            # Proceed with exit if confirmed
            if [[ "${confirm_exit}" == "y" || "${confirm_exit}" == "Y" ]]; then
                message="${faded_color}Exiting the menu... Goodbye!${reset_color}"
                echo -e "$message" >&2
                clean_screen
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

