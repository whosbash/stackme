#!/bin/bash

# Global variables for cleanup
x_position=0
y_position=0
max_width=0

# Cleanup function to restore terminal state and clear content
cleanup() {
    # Restore cursor visibility
    tput cnorm
    # Clear the area
    tput cup "$y_position" "$x_position"
    echo -n "$(printf "%${max_width}s" | tr " " " ")"
    clear

    # Exit the script
    exit 0
}

# Trap SIGINT (Ctrl+C) to invoke the cleanup function
trap cleanup SIGINT

# Function to verify if the message is greater than max_width
is_greater_than_max_width() {
    message="$1"
    max_width="$2"
    if [[ ${#message} -gt $max_width ]]; then
        return 0  # True, message is larger than max_width
    else
        return 1  # False, message is within max_width
    fi
}

# Function to shift the message based on the provided logic
shift_message() {
    # Hide cursor
    tput civis

    message="$1"
    max_width="$2"
    x_position="$3"  # Set global x position
    y_position="$4"  # Set global y position

    # Start with text on the left and padding to max_width
    shifted_message="$message"
    padding=" "  # Padding character
    padding_count=$((max_width - ${#shifted_message}))
    display_message="${shifted_message}$(printf "%${padding_count}s" | tr " " "$padding")"

    # Move cursor to the specified position
    tput cup "$y_position" "$x_position"

    # Loop to shift the message left or right as per the rules
    while true; do
        # Move cursor to the specified position again
        tput cup "$y_position" "$x_position"

        # Display the current shifted message on the same line
        echo -n "${display_message:0:$max_width}"

        # Add a space to the left of the message
        shifted_message=" ${shifted_message}"

        # Check if the message violates the max_width
        if [[ ${#shifted_message} -le $max_width ]]; then
            # If no violation, remove one space from the right side
            padding_count=$((max_width - ${#shifted_message}))
            display_message="${shifted_message}$(printf "%${padding_count}s" | tr " " "$padding")"
        else
            # If violation occurs, remove the first character and move the last character to the beginning
            shifted_message="${shifted_message:1}"
            shifted_message="${shifted_message: -1}${shifted_message:0:${#shifted_message}-1}"

            padding_count=$((max_width - ${#shifted_message}))
            display_message="${shifted_message}$(printf "%${padding_count}s" | tr " " "$padding")"
        fi

        # Sleep to slow down the display and make the shift visible
        sleep 0.1
    done
    # Restore cursor visibility
    tput cnorm
}

# Example usage:
read -p "Enter message: " message
read -p "Enter max width: " max_width
read -p "Enter x position: " x_position
read -p "Enter y position: " y_position

# Set global variables for cleanup
max_width="$max_width"
x_position="$x_position"
y_position="$y_position"

clear

shift_message "$message" "$max_width" "$x_position" "$y_position"
