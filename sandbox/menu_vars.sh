#!/bin/bash

# Define a global associative array for storing menu items
declare -A MENUS

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

# Display all menus
display_menus() {
    if [ ${#MENUS[@]} -eq 0 ]; then
        echo "No menu items available." >&2
        return 1
    fi

    for key in "${!MENUS[@]}"; do
        echo "Key: $key"
        echo "${MENUS[$key]}" | jq .  # Use jq for pretty-printing JSON
        echo
    done
}

# Example of defining individual menu items
define_menu_1(){
    item1=$(build_menu_item "Label1" "Action1" "This is the first option")
    item2=$(build_menu_item "Label2" "Action2" "This is the second option")
    item3=$(build_menu_item "Label3" "Action3" "This is the third option")

    # Append the menu items to the MENUS array
    define_menu "Menu 1" "$item1" "$item2" "$item3"
}

define_menus(){
    define_menu_1
}

define_menus

# Display the menu items 
display_menus

