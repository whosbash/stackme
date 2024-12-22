#!/bin/bash

# Define the delimiter character for splitting options and actions
MENU_DELIMITER='|'
NAVIGATION_DELIMITER=' | '

# Default page size
PAGE_SIZE=2

# Color and formatting variables
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"

HEADER_WIDTH=50

# Trap SIGINT and SIGTERM to exit gracefully
trap 'echo "Cleaning up..."; exit 0;' SIGINT SIGTERM

# Global variable to keep track of the previous menu
menu_navigation_history=()
declare -A pagination_indices

declare -A MENU_OPTIONS
declare -A MENU_ACTIONS
declare -A MENU_DESCRIPTIONS

define_menu_item() {
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

# Append menu items to the MENUS array under a specific key
define_menu() {
    local key=$1
    shift

    if [ $# -eq 0 ]; then
        echo "Error: At least one menu item is required."
        return 1
    fi

    # Append items to the MENUS array, using a newline as a delimiter
    for item in "$@"; do
        if [ -n "${MENUS["$key"]}" ]; then
            MENUS["$key"]+=$'\n'
        fi
        MENUS["$key"]+="$item"
    done
}


# Modify push_menu to accept multiple levels of nesting
push_menu() { 
    if [[ -n "$1" ]]; then
        menu_navigation_history+=("$1")
    else
        echo "Invalid menu name. Cannot push an empty menu."
    fi
}

# Pop menu from stack
pop_menu() {
    if [ ${#menu_navigation_history[@]} -gt 0 ]; then
        unset menu_navigation_history[-1]
    fi
}

# Helper function to check if a menu is already in the stack
is_menu_in_stack() {
    local menu_name=$1
    for menu in "${menu_navigation_history[@]}"; do
        if [[ "$menu" == "$menu_name" ]]; then
            return 0  # menu found
        fi
    done
    return 1  # menu not found
}


# Get current menu
get_current_menu() { echo "${menu_navigation_history[-1]}"; }

# Function to check if a menu requires pagination based on page_size and the number of menu options
requires_pagination() {
    local menu_name=$1
    local page_size=$2
    local delimiter=$3

    # Split the menu options based on the custom delimiter and count the number of options
    local total_options=$(
        echo "${MENU_OPTIONS[$menu_name]}" | \
        tr "$delimiter" '\n' | \
        grep -v '^$' | \
        wc -l
    )

    # If the number of options exceeds the page size, pagination is required
    if [[ $total_options -gt $page_size ]]; then
        return 0
    else
        return 1
    fi
}

# Get current indices (start, end) for pagination
get_current_indices() {
    local current_menu
    current_menu=$(get_current_menu)

    # Check if the current menu has set indices for pagination
    if requires_pagination "$current_menu" "$PAGE_SIZE" "$MENU_DELIMITER"; then
        echo "${pagination_indices["$current_menu"]}"
    else
        # Default indices if no pagination or indices are not set
        echo "0,0"
    fi
}

# Set current indices (start, end) for pagination
set_current_indices() {
    local menu_name=$1
    local start_idx=$2
    local end_idx=$3

    # Check if pagination is required for the given menu
    if requires_pagination "$menu_name" "$page_size" "$MENU_DELIMITER"; then
        # Store the start and end indices for the menu
        pagination_indices["$menu_name"]="$start_idx,$end_idx"
    else
        # If no pagination required, clear the indices for the menu
        pagination_indices["$menu_name"]=""

        echo "$(get_current_indices)" >&2
    fi
}

# Function to clear the current menu
clean_current_menu() {
    local menu_lines=$1  # Number of lines in the current menu

    # Move the cursor up by the number of menu lines
    for ((i = 0; i < menu_lines; i++)); do
        tput cuu1  # Move the cursor up one line
    done

    # Clear each line
    for ((i = 0; i < menu_lines; i++)); do
        tput el    # Clear the current line
        tput cud1  # Move the cursor down one line
    done

    # Move the cursor back to the original position
    for ((i = 0; i < menu_lines; i++)); do
        tput cuu1
    done
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
    local spaced_header="$(printf '%*s' $left_padding '')$colorized_header$(printf '%*s' $right_padding '')"

    # Print the header inside borders
    printf "${colorized_side_border}${spaced_header}${colorized_side_border}\n"

    # Print bottom border
    echo -e "${border_color}+${reset_color}${colorized_lu_border}${border_color}+${reset_color}"
}

# Display navigation options with fancy formatting
show_navigation() {
    local start_idx=$1
    local end_idx=$2
    local total_items=$3
    local navigation=()

    # Add navigation options based on conditions
    [[ $((end_idx + 1)) -lt $total_items ]] && navigation+=("n. Next Page")
    [[ $start_idx -gt 0 ]] && navigation+=("p. Previous Page")
    [[ ${#menu_navigation_history[@]} -gt 1 && "$(get_current_menu)" != "Main" ]] && \
        navigation+=("b. Back to Previous Menu")
    [[ ${#menu_navigation_history[@]} -gt 1 ]] && navigation+=("h. History")

    # If there are navigation options, display them with nice formatting
    if [[ ${#navigation[@]} -gt 0 ]]; then
        # Create a dynamic separator using HEADER_WIDTH
        local separator=$(printf '%*s' $HEADER_WIDTH '' | tr ' ' '-')

        # Print separator line before the navigation options
        echo -e "${YELLOW}${separator}${RESET}"

        # Print header for the navigation options
        echo -e "${BOLD}Navigation Options:${RESET}"

        echo -e "${YELLOW}${separator}${RESET}"

        # Print each navigation option with consistent color
        for option in "${navigation[@]}"; do
            echo -e "${GREEN}→${RESET} $option"
        done

        # Print separator line after the navigation options
        echo -e "${YELLOW}${separator}${RESET}"
    fi
}

# Helper function to display a page of options
show_page() {
    local menu_name=$1
    local start_idx=$2
    local end_idx=$3
    local menu_options=("${!4}")
    local menu_actions=("${!5}")
    local menu_descriptions=("${!6}")
    local total_options=${#menu_options[@]}

    # Validate input arrays
    if (( total_options == 0 )); then
        echo "Warning: No menu options available for menu '$menu_name'."
        choice="b"
    fi

    # Ensure indices are within valid range
    result=$(validate_indices "$start_idx" "$end_idx" "$total_options")

    # Extract the updated start_idx and end_idx from the result
    start_idx=$(echo $result | awk '{print $1}')
    end_idx=$(echo $result | awk '{print $2}')
    
    show_header "$menu_name"

    echo ""

    # Display options for the current page
    display_menu_options "$start_idx" "$end_idx" menu_options[@] menu_descriptions[@]

    echo ""

    # Show navigation options
    show_navigation "$start_idx" "$end_idx" "$total_options"

    # Prompt user for choice
    message="Select an option (e - Exit): "
    read -p "$message" choice


    handle_user_choice \
        "$choice" "$menu_name" \
        "$start_idx" "$end_idx" \
        menu_options[@] menu_actions[@]
}

# Simplified function to calculate indices for pagination
calculate_indices() {
    local direction=$1
    local start_idx=$2
    local total_options=$3
    if [[ "$direction" == "previous" ]]; then
        start_idx=$((start_idx - PAGE_SIZE))
        start_idx=$((start_idx < 0 ? 0 : start_idx))
    elif [[ "$direction" == "next" ]]; then
        start_idx=$((start_idx + PAGE_SIZE))
        start_idx=$((start_idx >= total_options ? total_options - PAGE_SIZE : start_idx))
    fi
    local end_idx=$((start_idx + PAGE_SIZE - 1))
    end_idx=$((end_idx >= total_options ? total_options - 1 : end_idx))
    echo "$start_idx,$end_idx"
}

# Function to navigate pages (next/previous)
navigate_page() {
    local direction=$1
    local menu_name=$2
    local start_idx=$3
    local menu_options=("${!4}")
    local menu_actions=("${!5}")
    local menu_descriptions=("${!6}")

    local total_options=${#options[@]}

    # Calculate the new start and end indices based on the direction
    local indices
    indices=$(calculate_indices "$direction" "$start_idx" "$total_options")
    IFS=',' read -r new_start_idx new_end_idx <<<"$indices"

    # If the direction is 'current', we do not need to update the indices
    if [[ "$direction" != "current" ]]; then
        # Update the current indices with the new start and end
        set_current_indices "$menu_name" "$new_start_idx" "$new_end_idx"
    else
        # Retrieve the current indices to maintain the current page state
        indices="$(get_current_indices)"
        IFS=',' read -r new_start_idx new_end_idx <<<"$indices"
    fi

    show_page \
        "$menu_name" "$new_start_idx" "$new_end_idx" \
        options[@] menu_actions[@] menu_descriptions[@]
}

# Show the history of visited menus with fancy formatting
show_history() {
    # Define HEADER_WIDTH for dynamic header and separator length
    local HEADER_WIDTH=${HEADER_WIDTH:-30}  # Default width to 30 if not provided
    local separator=$(printf '%*s' $HEADER_WIDTH '' | tr ' ' '-')

    # Print header
    echo -e "\n${YELLOW}${separator}${RESET}"
    echo -e "${BOLD}History of Visited Menus:${RESET}"
    echo -e "${YELLOW}${separator}${RESET}"

    # Print the menu history with numbering
    if [[ ${#menu_navigation_history[@]} -gt 0 ]]; then
        for ((i = 0; i < ${#menu_navigation_history[@]}; i++)); do
            echo -e "${CYAN}$((i + 1)). ${menu_navigation_history[i]}${RESET}"
        done
    else
        echo -e "${RED}No history available.${RESET}"
    fi

    # Print footer separator
    echo -e "${YELLOW}${separator}${RESET}"
}

# Function to handle user choice
handle_user_choice() {
    local choice=$1
    local menu_name=$2
    local start_idx=$3
    local end_idx=$4
    local menu_options=("${!5}")
    local menu_actions=("${!6}")

    local total_options="${#menu_options[@]}"

    # Validate the user choice and capture the reason for invalid choice
    if ! reason=$(validate_choice "$choice" "$total_options"); then
        echo "Invalid choice: '$choice'. Reason: $reason Please try again." >&2
        navigate_page "current" "$menu_name" "$start_idx" \
            menu_options[@] menu_actions[@] menu_descriptions[@]
        return
    fi


    case "$choice" in
        p) navigate_page "previous" "$menu_name" $start_idx \
            menu_options[@] menu_actions[@] menu_descriptions[@] ;;
        n) navigate_page "next" "$menu_name" $start_idx \
            menu_options[@] menu_actions[@] menu_descriptions[@] ;;
        b) return_to_parent_menu ;;
        h) show_history; navigate_page "current" "$menu_name" "$start_idx" \
            menu_options[@] menu_actions[@] menu_descriptions[@] ;;
        e) exit_gracefully ;;
        *)
            # Ensure we treat the selected option and action as strings
            local selected_option="${menu_options[$((choice - 1))]}"
            local action_function="${menu_actions[$((choice - 1))]}"

            # Call the function if it exists, otherwise show an error
            if type "$action_function" &>/dev/null; then
                "$action_function"

                echo ""

                # After action execution, stay on the same page
                show_page \
                    "$menu_name" "$start_idx" "$end_idx" \
                    menu_options[@] menu_actions[@] menu_descriptions[@]

            else
                echo "Error: Function '$action_function' does not exist for option $choice."
                to_current_page "$menu_name" menu_options[@] menu_actions[@] menu_descriptions[@]
            fi
            ;;
    esac
}

# Function to exit the program
exit_gracefully() { echo "Exiting program."; exit 0; }

validate_menus() {
    for menu_name in "${!MENUS[@]}"; do
        IFS="$MENU_DELIMITER" read -ra menu_options <<< "${MENU_OPTIONS["$menu_name"]}"
        IFS="$MENU_DELIMITER" read -ra menu_actions <<< "${MENU_ACTIONS["$menu_name"]}"
        IFS="$MENU_DELIMITER" read -ra menu_descriptions <<< "${MENU_DESCRIPTIONS["$menu_name"]}"

        local total_options=${#menu_options[@]}
        local total_actions=${#menu_actions[@]}
        local total_descriptions=${#menu_descriptions[@]}

        # Check if option count matches action count
        if [ "$total_options" -ne "$total_actions" ]; then
            echo "Error: Menu '$menu_name' has mismatched options and actions."
            exit 1
        fi

        # If descriptions are provided, ensure the count matches options
        if [ "$total_descriptions" -gt 0 ] && [ "$total_options" -ne "$total_descriptions" ]; then
            echo "Error: Menu '$menu_name' has mismatched options and descriptions."
            exit 1
        fi
    done
}

# Function to validate indices for start and end
validate_indices() {
    local start_idx=$1
    local end_idx=$2
    local total_options=$3

    if (( start_idx < 0 || start_idx >= total_options )); then
        echo "Warning: Invalid start index '$start_idx'. Resetting to 0." >&2
        start_idx=0
    fi

    if (( end_idx <= start_idx || end_idx >= total_options )); then
        end_idx=$((total_options - 1))
    fi

    # Output the updated values
    echo "$start_idx $end_idx"
}

# Function to validate user choice
validate_choice() {
    local choice=$1
    local total_options=$2
    local valid_choices_set="p n b h e"
    local reason=""

    # Check for empty input
    if [[ -z "$choice" ]]; then
        reason="Choice cannot be empty."
        echo "$reason"
        return 1
    fi

    # Check if choice is in the valid set (for commands like 'p', 'n', etc.)
    if [[ "$valid_choices_set" =~ "$choice" ]]; then
        return 0  # Valid choice
    fi

    # Check if choice is a number
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        # Validate choice based on pagination
        local current_menu
        current_menu=$(get_current_menu)

        # Validate choice based on pagination
        if requires_pagination "$current_menu" "$PAGE_SIZE" "$MENU_DELIMITER"; then
            local indices
            indices="$(get_current_indices)"

            local start_idx end_idx
            IFS=',' read -r start_idx end_idx <<<"$indices"

            # Check if start_idx and end_idx are equal to total_options
            if (( start_idx == end_idx && $((start_idx + 1)) == total_options )); then
                reason="Choice $choice is not the valid option $((start_idx+1))."
            else
                # Check if the choice is within the indices of the current page
                if (( choice >= start_idx + 1 && choice <= end_idx + 1 )); then
                    return 0  # Valid choice
                else
                    local range
                    range="$((start_idx + 1)) to $((end_idx + 1))"
                    reason="Choice $choice is not within the valid range of the current page ($range)."
                fi
            fi
        else
            # No pagination: Validate against total options
            if (( choice > 0 && choice <= total_options )); then
                return 0  # Valid choice
            else
                reason="Choice $choice is outside the valid range (1 to $total_options)."
            fi
        fi
    fi

    # If none of the conditions matched, it's an invalid choice
    echo "$reason"
    return 1
}

# Function to display menu options
display_menu_options() {
    local start_idx=$1
    local end_idx=$2
    local menu_options=("${!3}")
    local menu_descriptions=("${!4}")

    for ((i = start_idx; i <= end_idx; i++)); do
        if [[ -n "${menu_descriptions[i]}" ]]; then
            echo "$((i + 1)). ${menu_options[i]}: ${menu_descriptions[i]}"
        else
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}

# Manage navigation to different menus
navigate_menu() {
    local menu_name=$1

    # If the menu_navigation_history is empty, set the first menu as the current menu
    if ! is_menu_in_stack "$menu_name"; then
        push_menu "$menu_name"
    fi

    # Split the options, actions, and descriptions from the associative arrays
    # Use the DELIMITER to parse them correctly
    IFS="$MENU_DELIMITER" read -ra options <<< "${MENU_OPTIONS["$menu_name"]}"
    IFS="$MENU_DELIMITER" read -ra actions <<< "${MENU_ACTIONS["$menu_name"]}"
    IFS="$MENU_DELIMITER" read -ra descriptions <<< "${MENU_DESCRIPTIONS["$menu_name"]}"

    # Calculate the initial end_idx based on PAGE_SIZE
    local total_options=${#options[@]}
    local end_idx=$((PAGE_SIZE - 1))

    # Ensure end_idx doesn't exceed the total options
    end_idx=$((end_idx >= total_options ? total_options - 1 : end_idx))

    # Update the current indices
    set_current_indices "$menu_name" 0 "$end_idx"

    # Pass the options and actions arrays correctly to the show_page function
    show_page "$menu_name" 0 "$end_idx" options[@] actions[@] descriptions[@]
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

# Subtacks Menu
define_menu_substacks_a(){
    substacks_a_menu() { navigate_menu "Stack A Substacks"; }
    deploy_substack_a() { echo "Deploying Substack A..."; }
    deploy_substack_b() { echo "Deploying Substack B..."; }

    item1=$(define_menu_item "Substack A" "deploy_substack_a" "Deploy")
    item2=$(define_menu_item "Substack B" "deploy_substack_b" "Deploy")

    define_menu "Stack A Substacks" "$item1" "$item2"
}

# Stacks Menu
define_menu_stacks(){
    stacks_menu() { navigate_menu "Stacks"; }
    deploy_stack_b() { echo "Deploying Stack B..."; }
    deploy_stack_c() { echo "Deploying Stack C..."; }

    # Substacks A menu items
    item1=$(
        define_menu_item \
            "Stack A substacks" "substacks_a_menu" "Show available subtacks of stack A"
    )
    item2=$(
        define_menu_item \
            "Stack B" "deploy_stack_b" "Deploy"
    )
    item3=$(
        define_menu_item "Stack C" "deploy_stack_c" "Deploy"
    )

    define_menu "Stacks" "$item1" "$item2" "$item3"
}

# Settings Menu
define_menus_setings(){
    settings_menu() { navigate_menu "Settings"; }
    change_setting_1() { echo "Changing Setting 1..."; }
    change_setting_2() { echo "Changing Setting 2..."; }

    item1=$(
        define_menu_item "Setting 1" "change_setting_1" "Apply"
    )
    item2=$(
        define_menu_item "Setting 2" "change_setting_2" "Apply"
    )

    define_menu "Settings" "$item1" "$item2"
}

main_menu() { navigate_menu "Main"; }

define_menu_main(){
    # Main menu items
    item1=$(define_menu_item "Stacks" "stacks_menu" "Show available stacks")
    item2=$(define_menu_item "Settings" "settings_menu" "Show settings")

    # Main Menu
    define_menu "Main" "$item1" "$item2"
}

define_menus(){
    define_menu_main
    define_menu_stacks
    define_menus_setings
    define_menu_substacks_a
}

start_main_menu(){
    main_menu
}

# Populate MENUS
define_menus

# Start the main menu
start_main