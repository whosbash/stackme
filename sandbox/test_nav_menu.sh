#!/usr/bin/env bash

highlight_color="\033[1;32m"   # Highlight color (Bright Green)
faded_color="\033[2m"          # Faded color (Dark gray)
error_color="\033[1;31m"       # Error color (Dark red)
title_color="\033[1;36m"       # Title color (Cyan)
reset_color="\033[0m"          # Reset color

up_key="[A"                    # Up Arrow
down_key="[B"                  # Down Arrow
left_key="[D"                  # Left Arrow
right_key="[C"                 # Right Arrow

stty -icanon min 1 time 0      # Disable canonical mode, set immediate input
trap "stty sane" EXIT          # Ensure terminal settings are restored on script exit

clean_screen(){
    echo -ne "\033[H\033[J" >&2
}

display_header(){
    local header="$1"
    echo -e "$header\n" >&2
}

truncate_option() {
    local option="$1"
    local max_length=30
    if [[ ${#option} -gt $max_length ]]; then
        echo "${option:0:$((max_length - 3))}..."
    else
        echo "$option"
    fi
}

# Render the menu with page navigation and options
render_menu() {
    tput civis # Hide cursor
    
    local header="$1"
    local current_idx="$2"
    local page_size="$3"
    local menu_options=("${@:4}")
    local num_options=${#menu_options[@]}

    tput cup 0 0                    # Move cursor to top-left
    clean_screen                    # Clear screen
    display_header "$header"        # Display header
    echo -e "${faded_color}Keyboard Shortcuts:${reset_color}" >&2
    echo -e "  ↑/↓: Navigate  ◀/▶: Switch Pages  Enter: Select  q: Quit\n" >&2

    local start=$((current_idx / page_size * page_size))
    local end=$((start + page_size))
    end=$((end > num_options ? num_options : end))

    # Display options with additional blank lines for spacing
    for i in $(seq $start $((end - 1))); do
        if [[ $i -eq $current_idx ]]; then
            option="${highlight_color}→ $(truncate_option "${menu_options[i]}")${reset_color}"
            echo -e "$option" >&2
        else
            echo -e "  ${menu_options[i]}" >&2
        fi
    done

    # Fill remaining space if fewer items than page size
    local remaining_space=$((page_size - (end - start)))
    for _ in $(seq 1 $remaining_space); do
        echo >&2  # Just fill with empty lines to keep the layout consistent
    done

    # Display current page and total pages
    local total_pages=$(((num_options + page_size - 1) / page_size))
    local current_page=$(((start / page_size) + 1))
    echo -e "\nPage $current_page of $total_pages${reset_color}" >&2

    # Display navigation indicators
    if ((start > 0 && num_options > page_size)); then
        echo -e "${faded_color}... More options above ...${reset_color}" >&2
    fi
    if ((end < num_options)); then
        echo -e "${faded_color}... More options below ...${reset_color}" >&2
    fi
}

validate_option() {
    local selected_option="$1"
    # Add custom validation logic (e.g., check if option exists in the array)
    if [[ " ${options[@]} " =~ " ${selected_option} " ]]; then
        return 0  # Valid option
    else
        return 1  # Invalid option
    fi
}

# Main navigation loop
navigate_menu() {
    message="${title_color}=== Navigation Menu ===${reset_color}"
    local header="${1:-$message}"
    shift
    local page_size="$1"
    shift
    local menu_options=("$@")
    local original_menu_options=("${menu_options[@]}")
    local num_options=${#menu_options[@]}
    local current_idx=0

    if [[ $num_options -eq 0 ]]; then
        echo -e "${error_color}Error: No options provided to the menu!${reset_color}" >&2
        exit 1
    fi

    while true; do
        render_menu "$header" $current_idx "$page_size" "${menu_options[@]}"
        read -rsn1 key
        case "$key" in
        $'\x1B') # Start of escape sequence
            read -rsn2 -t 0.1 key
            case "$key" in
            "$up_key")   # Up arrow
                if ((current_idx > 0)); then
                    ((current_idx--))
                fi
                ;;
            "$down_key") # Down arrow
                if ((current_idx < num_options - 1)); then
                    ((current_idx++))
                fi
                ;;
            "$left_key") # Left arrow (previous page)
                if ((current_idx - page_size >= 0)); then
                    # Move to first item of the previous page
                    current_idx=$(( (current_idx / page_size - 1) * page_size ))
                else
                    # If at the first page, ensure it doesn't go below 0
                    current_idx=0
                fi
                ;;
            "$right_key") # Right arrow (next page)
                if ((current_idx + page_size < num_options)); then
                    # Move to first item of the next page
                    current_idx=$(( (current_idx / page_size + 1) * page_size ))
                else
                    # If at the last page, ensure it doesn't exceed num_options
                    current_idx=$((num_options - 1))
                fi
                ;;
            esac
            ;;

        "/")  # Start search
            echo -e "${faded_color}Search: ${reset_color}" >&2
            read -r search_key
            if [[ -z "$search_key" ]]; then
                menu_options=("${original_menu_options[@]}")  # Reset to original list if search term is empty
                continue
            fi
            # Filter options based on search term
            filtered_options=()
            for option in "${original_menu_options[@]}"; do
                if [[ $option == *"$search_key"* ]]; then
                    filtered_options+=("$option")
                fi
            done
            menu_options=("${filtered_options[@]}")
            # Adjust current_idx if it's out of bounds after filtering
            if ((current_idx >= ${#menu_options[@]})); then
                current_idx=$(( ${#menu_options[@]} - 1 ))  # Reset current_idx to the last option
            fi
            ;;
        "") # Enter key
            option="${menu_options[current_idx]}"
            echo -e "${faded_color}Are you sure you want to select option \"$option\"? (y/n)${reset_color}" >&2
            read -rsn1 confirm

            while [[ ! "$confirm" =~ ^[yYnN]$ ]]; do
                # Warn user if input is not y/n
                echo -e "${faded_color}Invalid input \"$confirm\". Please enter 'y' for yes or 'n' for no.${reset_color}" >&2
                echo -e "${faded_color}Are you sure you want to select this option? (y/n)${reset_color}" >&2
                read -rsn1 confirm
            done

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                clean_screen
                break
            fi
            ;;

        "q") # q key to exit
            echo -e "${faded_color}Exiting the menu... Goodbye!${reset_color}" >&2
            clean_screen
            break
            ;;
        *)
            # Handle invalid key input
            shoutout="Invalid key pressed!"
            keyboard_options="Please use ↑/↓ to navigate, ←/→ to switch pages, or Enter to select."
            message="${error_color}$shoutout $keyboard_options${reset_color}"
            echo -e "$message" >&2
            sleep 1
            ;;
        esac
    done

    # Show cursor
    tput cnorm 

    # Only return the selected option if Enter was pressed
    if [[ "$key" == "" ]]; then
        echo "${menu_options[current_idx]}"
    fi
}

# Example dynamic menu array generation
generate_dynamic_options() {
    local base="$1"
    local count="$2"
    options=()
    for i in $(seq 1 "$count"); do
        options+=("${base} Option $i")
    done
}

header="\033[1;36m=== My Custom Menu ===\033[0m"
page_size=5
generate_dynamic_options "Dynamic" 12  # Generate 12 dynamic options
selected_option=$(navigate_menu "$header" "$page_size" "${options[@]}")

echo -e "\nYou selected: $selected_option"
