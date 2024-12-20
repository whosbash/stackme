#!/bin/bash

clean_current_menu() {
    local menu_lines=$1  # Number of lines in the current menu

    # Move the cursor up by the number of menu lines
    for ((i = 0; i < menu_lines; i++)); do
        tput cuu1  # Move the cursor up one line
        tput el    # Clear the current line
    done
}

# Function to display a sample menu
display_menu() {
    echo "1. Option 1"
    echo "2. Option 2"
    echo "3. Option 3"
    echo "4. Option 4"
    echo "Select an option:"
}

# Display some text before the menu
echo "This is some text that will remain on the screen."
echo "Another line of text."

# Display the menu
display_menu

# Wait for user input
read -p "Your choice: " choice

# Clear the menu (5 lines in this example)
clean_current_menu 6

# Display a new message or menu
echo "The menu has been cleared."
echo "This is the new content after cleaning the menu."
