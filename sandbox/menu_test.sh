#!/bin/bash

# Define the delimiter character for splitting options and actions
MENU_DELIMITER='|'
NAVIGATION_DELIMITER=' | '

# Default page size
PAGE_SIZE=2

# Global variable to keep track of the previous menu
menu_stack=()
declare -A current_indices

declare -A MENU_OPTIONS
declare -A MENU_ACTIONS
declare -A MENU_DESCRIPTIONS

define_menu() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Missing argument(s). All four arguments are required."
        return 1
    fi

    MENU_OPTIONS["$1"]="$2"
    MENU_ACTIONS["$1"]="$3"
    MENU_DESCRIPTIONS["$1"]="$4"

    # Ensure that all arrays have the same cardinality
    if [[ ${#MENU_OPTIONS[@]} -ne ${#MENU_ACTIONS[@]} ]] || \
        [[ ${#MENU_OPTIONS[@]} -ne ${#MENU_DESCRIPTIONS[@]} ]]; then
        remark="Arrays have inconsistent lengths."
        advice="Ensure MENUS, MENU_ACTIONS, and MENU_DESCRIPTIONS have the same number of elements."
        echo "$remark $advice"
        return 1
    fi
}


# Modify push_menu to accept multiple levels of nesting
push_menu() { 
    if [[ -n "$1" ]]; then
        menu_stack+=("$1")
    else
        echo "Invalid menu name. Cannot push an empty menu."
    fi
}

# Pop menu from stack
pop_menu() {
    if [ ${#menu_stack[@]} -gt 0 ]; then
        unset menu_stack[-1]
    fi
}

# Helper function to check if a menu is already in the stack
is_menu_in_stack() {
    local menu_name=$1
    for menu in "${menu_stack[@]}"; do
        if [[ "$menu" == "$menu_name" ]]; then
            return 0  # menu found
        fi
    done
    return 1  # menu not found
}

# Get current menu
get_current_menu() { echo "${menu_stack[-1]}"; }

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

    echo "$total_options" >&2

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

    echo "current_menu: $current_menu" >&2

    # Check if the current menu has set indices for pagination
    if requires_pagination "$current_menu" "$PAGE_SIZE" "$MENU_DELIMITER"; then
        echo "${current_indices["$current_menu"]}"
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

    echo "set_current_indices"
    echo "menu_name: $menu_name" >&2
    echo "start_idx: $start_idx" >&2
    echo "end_idx: $end_idx" >&2

    # Check if pagination is required for the given menu
    if requires_pagination "$menu_name" "$page_size" "$MENU_DELIMITER"; then
        # Store the start and end indices for the menu
        current_indices["$menu_name"]="$start_idx,$end_idx"
    else
        # If no pagination required, clear the indices for the menu
        current_indices["$menu_name"]=""
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

# Helper function to display navigation options
show_navigation() {
    local start_idx=$1
    local end_idx=$2
    local total_items=$3
    local navigation=()

    # Add "Next Page" option only if there are more items beyond end_idx
    if [ $((end_idx + 1)) -lt $total_items ]; then
        navigation+=("n. Next Page")
    fi

    echo "start_idx $start_idx"

    # Add "Previous Page" option only if there are items before start_idx
    if [ $start_idx -gt 0 ]; then
        navigation+=("p. Previous Page")
    fi

    # Add the back option only if applicable
    if [ ${#menu_stack[@]} -gt 1 ] && [ "$(get_current_menu)" != "Main" ]; then
        navigation+=("b. Back to Previous Menu")
    fi

    # Option to view the history of visited menus
    if [ ${#menu_stack[@]} -gt 1 ]; then
        navigation+=("h. History")
    fi

    # Join and print all options in a single line with the custom delimiter
    if [ ${#navigation[@]} -gt 0 ]; then
        echo "$(join_array "$NAVIGATION_DELIMITER" "${navigation[@]}")"
    fi
}

# Function to navigate pages (next/previous)
navigate_page() {
    local direction=$1
    local menu_name=$2
    local start_idx=$3
    local options=("${!4}")
    local total_options=${#options[@]}

    if [ "$direction" == "previous" ]; then
        new_start_idx=$((start_idx - PAGE_SIZE))
        new_start_idx=$((new_start_idx < 0 ? 0 : new_start_idx))
    elif [ "$direction" == "next" ]; then
        new_start_idx=$((start_idx + PAGE_SIZE))
        new_start_idx=$((
            new_start_idx >= total_options ? total_options - PAGE_SIZE : new_start_idx
        ))
    fi

    # Calculate new end index
    new_end_idx=$((new_start_idx + PAGE_SIZE - 1))
    new_end_idx=$((new_end_idx >= total_options ? total_options - 1 : new_end_idx))

    # Update the current indices with the new start and end
    echo "Indices: $new_start_idx, $new_end_idx"
    set_current_indices "$menu_name" "$new_start_idx" "$new_end_idx"

    show_page \
        "$menu_name" "$new_start_idx" "$new_end_idx" \
        options[@] menu_actions[@] menu_descriptions[@]
}

# Function to return to the current page after showing history
to_current_page() {
    local menu_name=$1
    local options=("${!2}")
    local actions=("${!3}")
    local descriptions=("${!4}")

    # Retrieve the current indices to maintain the current page state
    local indices
    indices="$(get_current_indices)"
    

    local start_idx end_idx
    IFS=',' read -r start_idx end_idx <<<"$indices"

    # Display the current menu page again
    show_page \
        "$menu_name" "$start_idx" "$end_idx" \
        options[@] actions[@] descriptions[@]
}

get_user_choice() {
    local prompt=$1
    local valid_choices=("${!2}")

    while : ; do
        read -p "$prompt" choice
        # Use a more efficient check by directly matching
        if [[ " ${valid_choices[@]} " =~ " $choice " ]]; then
            echo "$choice"
            break
        else
            echo "Invalid choice: '$choice'. Please try again."
        fi
    done
}

# Show the history of visited menus
show_history() {
    echo "History of visited menus:"
    for ((i = 0; i < ${#menu_stack[@]}; i++)); do
        echo "$((i + 1)). ${menu_stack[i]}"
    done
}

# Function to handle user choice
handle_user_choice() {
    local choice=$1
    local menu_name=$2
    local start_idx=$3
    local end_idx=$4
    local menu_options=("${!5}")
    local menu_actions=("${!6}")

    echo "On handle_user_choice: $choice"

    case "$choice" in
        p) navigate_page "previous" "$menu_name" $start_idx menu_options[@] menu_actions[@] ;;
        n) navigate_page "next" "$menu_name" $start_idx menu_options[@] menu_actions[@] ;;
        b) return_to_parent_menu ;;
        h) 
            show_history

            # Use the `to_current_page` function to restore the current menu state
            to_current_page "$menu_name" menu_options[@] menu_actions[@] menu_descriptions[@]
            ;;
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
            fi
            ;;
    esac
}

# Function to exit the program
exit_gracefully() { echo "Exiting program."; exit 0; }

# Helper function to display a page of options
show_page() {
    local menu_name=$1
    local start_idx=$2
    local end_idx=$3
    local menu_options=("${!4}")
    local menu_actions=("${!5}")
    local menu_descriptions=("${!6}")
    local total_options=${#menu_options[@]}

    echo "This page: $start_idx $end_idx"
    
    # Ensure end_idx doesn't exceed the number of options
    end_idx=$((end_idx >= $total_options ? $total_options - 1 : end_idx))

    echo "== Menu \"$menu_name\" =="
    echo ""

    # Display the current page's options
    for ((i = start_idx; i <= end_idx && i < $total_options; i++)); do
        if [[ -n "${menu_descriptions[i]}" ]]; then
            echo "$((i + 1)). ${menu_options[i]} - ${menu_descriptions[i]}"
        else
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done

    echo ""

    # Display navigation options if the menu requires pagination
    show_navigation "$start_idx" "$end_idx" "$total_options"

    # Prompt user and handle choice
    read -p "Select an option (e - Exit): " choice

    echo ""

    echo "On show_page before: $choice"

    handle_user_choice \
        "$choice" "$menu_name" \
        "$start_idx" "$end_idx" \
        menu_options[@] menu_actions[@]
    
    echo "On show_page after: $choice"
}

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

# Return to the parent menu (previous menu)
return_to_parent_menu() {
    if [ ${#menu_stack[@]} -gt 1 ]; then
        pop_menu
        local parent_menu=$(get_current_menu)
        navigate_menu "$parent_menu"
    else
        navigate_menu "Main"
    fi
}

# Manage navigation to different menus
navigate_menu() {
    local menu_name=$1

    # If the menu_stack is empty, set the first menu as the current menu
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

    echo "get_current_indices: $(get_current_indices)"

    echo "On navigate_menu before: $menu_name"

    # Pass the options and actions arrays correctly to the show_page function
    show_page "$menu_name" 0 "$end_idx" options[@] actions[@] descriptions[@]

    echo "On navigate_menu after: $menu_name"
}

# Subtacks Menu
define_menu \
    "Stack A Substacks" \
    "Deploy Substack A|Deploy Substack B" \
    "deploy_substack_a|deploy_substack_b" \
    "|"

substacks_a_menu() { navigate_menu "Stack A Substacks"; }
deploy_substack_a() { echo "Deploying Substack A..."; }
deploy_substack_b() { echo "Deploying Substack B..."; }

# Stacks Menu
define_menu \
    "Stacks" \
    "List Stack A substacks|Deploy Stack B|Deploy Stack C" \
    "substacks_a_menu|deploy_stack_b|deploy_stack_c" \
    "||"

stacks_menu() { navigate_menu "Stacks"; }
deploy_stack_b() { echo "Deploying Stack B..."; }
deploy_stack_c() { echo "Deploying Stack C..."; }

# Settings Menu
define_menu \
    "Settings" \
    "Change Setting 1|Change Setting 2" \
    "change_setting_1|change_setting_2" \
    "||"

settings_menu() { navigate_menu "Settings"; }
change_setting_1() { echo "Changing Setting 1..."; }
change_setting_2() { echo "Changing Setting 2..."; }

# Main Menu
define_menu \
    "Main" \
    "Go to Stacks Menu|Go to Settings Menu" \
    "stacks_menu|settings_menu" \
    "Menu with stacks.|Menu with settings."

main_menu() { navigate_menu "Main"; }

# Start the program by calling the main menu
main_menu

