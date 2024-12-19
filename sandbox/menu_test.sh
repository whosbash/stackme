#!/bin/bash

# Define the delimiter character for splitting options and actions
DELIMITER='|'

# Default page size
PAGE_SIZE=2

# Global variable to keep track of the previous menu
menu_stack=()

declare -A MENUS
declare -A MENU_ACTIONS
declare -A MENU_DESCRIPTIONS

define_menu() {
    MENUS["$1"]="$2"
    MENU_ACTIONS["$1"]="$3"
    MENU_DESCRIPTIONS["$1"]="$4"
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
pop_menu() { unset menu_stack[-1]; }

# Get current menu
get_current_menu() { echo "${menu_stack[-1]}"; }

# Helper function to display navigation options
show_navigation() {
    local start_idx=$1
    local end_idx=$2
    local total_items=$3
    local navigation=""

    # Add "Next Page" option only if there are more items beyond end_idx
    if [ $((end_idx + 1)) -lt $total_items ]; then
        navigation+="n. Next Page "
    fi

    # Add "Previous Page" option only if there are items before start_idx
    if [ $start_idx -gt 0 ]; then
        navigation+="p. Previous Page "
    fi

    # Add the back option only if applicable
    if [ ${#menu_stack[@]} -gt 1 ] && [ "$(get_current_menu)" != "Main" ]; then
        navigation+="b. Back to Previous Menu"
    fi

    # Print all options in a single line
    if [ -n "$navigation" ]; then
        echo "$navigation"
    fi
}


# Function to navigate pages (next/previous)
# Function to navigate pages (next/previous)
navigate_page() {
    local direction=$1
    local menu_name=$2
    local start_idx=$3
    local options=("${!4}")
    local total_options=${#options[@]}

    if [ "$direction" == "previous" ]; then
        new_start_idx=$((start_idx - PAGE_SIZE))

        # Ensure we stay within bounds, wrap around if needed
        if [ $new_start_idx -lt 0 ]; then
            new_start_idx=0
        fi
    elif [ "$direction" == "next" ]; then
        new_start_idx=$((start_idx + PAGE_SIZE))
        # Ensure we don't exceed the total options
        if [ $new_start_idx -ge $total_options ]; then
            new_start_idx=$((total_options - (total_options % PAGE_SIZE)))
            if [ $new_start_idx -eq $total_options ]; then
                new_start_idx=$((total_options - PAGE_SIZE))
            fi
        fi
    fi

    # Calculate the new end index
    new_end_idx=$((new_start_idx + PAGE_SIZE - 1))
    if [ $new_end_idx -ge $total_options ]; then
        new_end_idx=$((total_options - 1))
    fi

    # Show the updated page
    show_page "$menu_name" "$new_start_idx" "$new_end_idx" options[@] menu_actions[@] menu_descriptions[@]
}



get_user_choice() {
    local prompt=$1
    local valid_choices=("${!2}")

    while : ; do
        read -p "$prompt" choice
        if [[ " ${valid_choices[@]} " =~ " $choice " ]]; then
            echo "$choice"
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

handle_user_choice() {
    local choice=$1
    local menu_name=$2
    local start_idx=$3
    local end_idx=$4
    local menu_options=("${!5}")
    local menu_actions=("${!6}")
 
    case "$choice" in
        p) navigate_page "previous" "$menu_name" $start_idx menu_options[@] menu_actions[@] ;;
        n) navigate_page "next" "$menu_name" $start_idx menu_options[@] menu_actions[@] ;;
        b) return_to_parent_menu ;;
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

    # Display navigation options
    show_navigation "$start_idx" "$end_idx" "$total_options"

    # Prompt user and handle choice
    read -p "Select an option (e - Exit): " choice
    
    echo ""

    handle_user_choice \
      "$choice" "$menu_name" \
      "$start_idx" "$end_idx" \
      menu_options[@] menu_actions[@]
}


validate_menus() {
    for menu_name in "${!MENUS[@]}"; do
        IFS="$DELIMITER" read -ra menu_options <<< "${MENUS["$menu_name"]}"
        IFS="$DELIMITER" read -ra menu_actions <<< "${MENU_ACTIONS["$menu_name"]}"
        IFS="$DELIMITER" read -ra menu_descriptions <<< "${MENU_DESCRIPTIONS["$menu_name"]}"

        local total_options = ${#menu_options[@]}
        local total_actions = ${#menu_actions[@]}
        local total_descriptions = ${#descriptions[@]}

        # Validate option and action count
        if [ $total_options -ne $total_actions ]; then
            echo "Error: Menu '$menu_name' has mismatched options and actions."
            exit 1
        fi

        # Validate description count
        if [ -n "$total_descriptions" ] && [ $total_options -ne $total_descriptions ]; then
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
        echo "No previous menu to return to."
        exit 0
    fi
}

# Manage navigation to different menus
navigate_menu() {
    local menu_name=$1
    push_menu "$menu_name"

    # Split the options, actions, and descriptions from the associative arrays
    # Use the DELIMITER to parse them correctly
    IFS="$DELIMITER" read -ra options <<< "${MENUS["$menu_name"]}"
    IFS="$DELIMITER" read -ra actions <<< "${MENU_ACTIONS["$menu_name"]}"
    IFS="$DELIMITER" read -ra descriptions <<< "${MENU_DESCRIPTIONS["$menu_name"]}"

    # Calculate the initial end_idx based on PAGE_SIZE
    local total_options=${#options[@]}
    local end_idx=$((PAGE_SIZE - 1))

    # Ensure end_idx doesn't exceed the total options
    end_idx=$((end_idx >= total_options ? total_options - 1 : end_idx))

    # Pass the options and actions arrays correctly to the show_page function
    show_page "$menu_name" 0 "$end_idx" options[@] actions[@] descriptions[@]
}


# Stacks Menu
define_menu \
  "Stacks" \
  "Deploy Stack A|Deploy Stack B|Deploy Stack C" \
  "deploy_stack_a|deploy_stack_b|deploy_stack_c" \
  "||"

stacks_menu() { navigate_menu "Stacks"; }
deploy_stack_a() { echo "Deploying Stack A..."; }
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
