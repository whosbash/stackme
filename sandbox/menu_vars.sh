#!/bin/bash

# Define a global associative array for storing menu items
declare -A MENUS

# Define individual menu item
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

# Display all menu items
display_menus() {
    if [ ${#MENUS[@]} -eq 0 ]; then
        echo "No menu items available."
        return 1
    fi

    for key in "${!MENUS[@]}"; do
        echo "Key: $key"
        # Split the items using a while loop and read
        while IFS= read -r item; do
            echo "$item"
        done <<< "${MENUS["$key"]}"
    done
}

# Example of defining individual menu items
define_menu_1(){
    item1=$(define_menu_item "Label1" "Action1" "This is the first option")
    item2=$(define_menu_item "Label2" "Action2" "This is the second option")
    item3=$(define_menu_item "Label3" "Action3" "This is the third option")

    # Append the menu items to the MENUS array
    define_menu "Menu 1" "$item1" "$item2" "$item3"
}

define_menus(){
    define_menu_1
}

define_menus

# Display the menu items 
display_menus
