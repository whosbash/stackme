#!/bin/bash

declare -A MENU

# Define menu with options, actions, and descriptions in a single array
define_menu() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Missing argument(s). All three arguments are required."
        return 1
    fi

    # Generate a unique key by appending the number of existing menu items
    index=$((${#MENU[@]} + 1))
    key="Option$index"

    # Store all details for a single menu option in a formatted string
    MENU["$key"]="$2,$3"  # Action and Description separated by a comma
}

get_action() {
    echo "${MENU[$1]}" | cut -d, -f1
}

get_description() {
    echo "${MENU[$1]}" | cut -d, -f2
}

# Display the menu options
display_menu() {
    if [ ${#MENU[@]} -gt 0 ]; then
        for key in "${!MENU[@]}"; do
            echo "Option: $key"
            
            # Extract the action and description by splitting the stored string
            action=$(get_action "$key")
            description=$(get_description "$key")
            
            # Display the action and description properly formatted
            echo "Action: $action"
            echo "Description: $description"
            echo
        done
    fi
}

# Example of how to define menu options
define_menu "Option1" "Action1" "This is the first option"
define_menu "Option2" "Action2" "This is the second option"
define_menu "Option3" "Action3" "This is the third option"

# Display the menu
display_menu
