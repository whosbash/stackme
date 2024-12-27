#!/bin/bash

# Example menu options
menu_options=("Option 1: First description"
              "Option 2: Second description"
              "Option 3: Third description")

# Global variables for cleanup
current_pid=0
current_idx=0

# Cleanup function to restore terminal state and stop background processes
cleanup() {
    tput cnorm  # Restore cursor visibility
    if [[ "$current_pid" -ne 0 ]]; then
        kill "$current_pid" 2>/dev/null  # Stop the background process if it's still running
    fi
    tput reset  # Reset terminal to a clean state (clear screen and reset attributes)
}

finish_session() {
    cleanup
    exit 0;
}

# Trap SIGINT (Ctrl+C) and EXIT (script termination) to invoke the cleanup function
trap finish_session SIGINT

# Function to shift a message in the background
shift_message() {
    local message="$1"
    local max_width="$2"
    local x_position="$3"
    local y_position="$4"
    local shifted_message="$message"
    local shift_offset=0

    tput civis  # Hide the cursor
    while true; do
        # Prepare the shifted message
        local rotated_message="${shifted_message:shift_offset}${shifted_message:0:shift_offset}"
        rotated_message="${rotated_message:0:$max_width}"

        # Move cursor to the specified position and print the message
        tput cup "$y_position" "$x_position"
        printf "%-*s" "$max_width" "$rotated_message"

        # Increment the shift offset
        ((shift_offset++))
        if [[ "$shift_offset" -ge ${#shifted_message} ]]; then
            shift_offset=0
        fi

        sleep 0.15
    done
}

# Function to render the menu
render_menu() {
    local selected_idx="$1"

    clear
    echo "Use Up/Down to navigate, Enter to select."
    echo "-----------------------------------------"

    for i in "${!menu_options[@]}"; do
        if [[ "$i" -eq "$selected_idx" ]]; then
            printf "→ %s\n" "${menu_options[i]}"
        else
            printf "  %s\n" "${menu_options[i]}"
        fi
    done
}

# Main menu loop
while true; do
    # Render the menu
    render_menu "$current_idx"

    # Get terminal dimensions
    terminal_width=$(tput cols)

    # Start the scrolling message for the selected option
    if [[ "$current_pid" -ne 0 ]]; then
        kill "$current_pid" 2>/dev/null  # Kill the previous background process
    fi

    # Dynamically calculate the vertical position for the message
    y_position=$((current_idx + 2))  # Example, this could be more dynamic

    # Start the scrolling message in the background
    shift_message "${menu_options[current_idx]} " "$terminal_width" 2 "$y_position" &
    current_pid=$!  # Store the background process ID

    # Wait for user input
    read -rsn1 key
    case "$key" in
        $'\x1b')  # Detect arrow keys
            read -rsn2 -t 0.2 key
            case "$key" in
                "[A")  # Up arrow
                    ((current_idx--))
                    if [[ "$current_idx" -lt 0 ]]; then
                        current_idx=$((${#menu_options[@]} - 1))
                    fi
                    ;;
                "[B")  # Down arrow
                    ((current_idx++))
                    if [[ "$current_idx" -ge "${#menu_options[@]}" ]]; then
                        current_idx=0
                    fi
                    ;;
            esac
            ;;
        "")  # Enter key
            break
            ;;
    esac
done

# Final cleanup and display the selected option
cleanup
echo "You selected: ${menu_options[current_idx]}"
sleep 2
cleanup
