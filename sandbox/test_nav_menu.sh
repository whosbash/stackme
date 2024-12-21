#!/bin/bash

# Function to display a simple navigation menu
navigate_menu() {
    local menu_options=("$@")
    local num_options=${#menu_options[@]}
    local current_idx=0

    local highlight_color="\033[1;32m" # Bright Green
    local reset_color="\033[0m"       # Reset to default

    # Render the menu
    render_menu() {
        echo -ne "\033[H\033[J" >&2  # Clear screen and move to the top
        # Add a header
        echo -e "\033[1;36m=== Navigation Menu ===\033[0m" >&2
        echo -e "Use ↑/↓ to navigate, Enter to select\n" >&2
        # Render menu options
        for i in "${!menu_options[@]}"; do
            if [[ $i -eq $current_idx ]]; then
                echo -e "${highlight_color}→ ${menu_options[i]}${reset_color}" >&2
            else
                echo -e "  ${menu_options[i]}" >&2
            fi
        done
    }

    # Handle user input
    while true; do
        render_menu
        read -rsn1 key
        
        case "$key" in
        $'\x1B') # Handle arrow keys
            read -rsn2 -t 0.1 key
            case "$key" in
            '[A') # Up arrow
                ((current_idx = (current_idx - 1 + num_options) % num_options))
                ;;
            '[B') # Down arrow
                ((current_idx = (current_idx + 1) % num_options))
                ;;
            esac
            ;;
        "") # Enter key
            break
            ;;
        esac
    done

    # Return the selected option
    echo "${menu_options[current_idx]}"
}

# Example usage
options=("Option 1" "Option 2" "Option 3" "Exit")
selected_option=$(navigate_menu "${options[@]}")

# Handle the selected option
if [[ $selected_option == "Exit" ]]; then
    read -p "Are you sure you want to exit? (y/n): " confirm
    if [[ $confirm != "y" ]]; then
        # Restart menu if user doesn't want to exit
        selected_option=$(navigate_menu "${options[@]}")
    fi
fi

# Output the final selection
echo -e "\nYou selected: $selected_option"
