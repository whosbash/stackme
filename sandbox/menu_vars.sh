#!/bin/bash

declare -A MENUS

# Define menu with options, actions, and descriptions using a JSON-like array
define_menu() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Error: Missing argument(s). All four arguments (name, label, action, description) are required."
        return 1
    fi

    # Convert name to lowercase for case-insensitive uniqueness
    key_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    # Validate if the name (key) is unique
    if [[ -n "${MENUS[$key_lower]}" ]]; then
        echo "Error: Menu item '$1' (name) already exists. Name must be unique."
        return 1
    fi

    # Store details in a "JSON-like" format with name, label, action, and description
    MENUS["$key_lower"]='{"label":"'"$2"'","action":"'"$3"'","description":"'"$4"'"}'
}

get_value() {
    # Extract the value using jq from the JSON string and handle potential errors
    value=$(echo "$1" | jq -r ".$2" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Invalid JSON structure or missing field '$2'."
        return 1
    fi
    echo "$value"
}

get_label() {
    echo "$(get_value "$1" "label")"
}

get_action() {
    echo "$(get_value "$1" "action")"
}

get_description() {
    echo "$(get_value "$1" "description")"
}

# Display the menu options
display_menu() {
    if [ ${#MENUS[@]} -eq 0 ]; then
        echo "No menu options available."
        return 1
    fi

    for key in "${!MENUS[@]}"; do
        echo "Key: $key"
        
        # Get the JSON-like string stored in the MENU array
        json="${MENUS[$key]}"
        
        # Extract the action, label, and description by indexing into the JSON-like string
        label=$(get_label "$json")
        action=$(get_action "$json")
        description=$(get_description "$json")
        
        # Display the label, action, and description
        echo "Label: $label"
        echo "Action: $action"
        echo "Description: $description"
        echo  # Blank line for readability
    done
}

# Delete a menu item by key
delete_menu_item() {
    if [ -z "$1" ]; then
        echo "Error: Missing key argument. Please provide the key of the menu item to delete."
        return 1
    fi

    # Convert to lowercase for case-insensitive comparison
    key_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if [[ -z "${MENUS[$key_lower]}" ]]; then
        echo "Error: Menu item '$1' not found."
        return 1
    fi

    # Remove the menu item
    unset MENUS["$key_lower"]
    echo "Menu item '$1' has been deleted."
}

# Example of how to define menu options
define_menu "Option1" "Label1" "Action1" "This is the first option"
define_menu "Option2" "Label2" "Action2" "This is the second option"
define_menu "Option3" "Label3" "Action3" "This is the third option"

# Display the menu
display_menu

# Example of deleting a menu item
# Uncomment to test deletion
delete_menu_item "Option2"

# Display the menu after deletion (if any)
display_menu
