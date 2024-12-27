#!/bin/bash

# Hide cursor for visual clarity
tput civis

# Define variables
start_row=5                # Starting row (top of the box)
start_col=10               # Starting column (left of the box)
row_count=20               # Height of the box
col_count=40               # Width of the box
sleep_time=0.05            # Delay between updates (reduce for faster updates)

# Extended set of characters (letters, numbers, special characters, emojis)
custom_characters=(
    "@" "#" "*" "+" "&" "%" "$" "!" "🌟" "🔥" "🎉" "💥" "✨" "😊" "❤️" "💻" "🐱" "🐶" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
    "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"
    "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"
    "!" "#" "$" "%" "^" "&" "*" "(" ")" "_" "+" "=" "{" "}" "[" "]" "|" ";" ":" "'" "\"" "<" ">" "," "." "/" "?" "~"
    "🍎" "🍓" "🍍" "🍉" "🍌" "🍒" "🍑" "🍊" "🍋" "🥑" "🍍" "🌍" "🌞" "🌜" "⭐" "🌈" "💫" "💖" "💥" "✨" "💎" "🎵"
    "🦄" "🎨" "📝" "📱" "🎮" "🖥" "🎧" "🎸" "🎻" "🎤" "🎬" "🎭" "🎨" "🧩"
)
custom_colors=("1" "2" "3" "4" "5" "6" "7" "8")  # ANSI color codes (1-7)

# Draw the box
draw_box() {
    # Top border
    tput cup $start_row $start_col
    printf "+"
    for ((col=1; col<=col_count; col++)); do
        printf "-"
    done
    printf "+"

    # Side borders
    for ((row=1; row<=row_count; row++)); do
        tput cup $((start_row + row)) $start_col
        printf "|"
        tput cup $((start_row + row)) $((start_col + col_count + 1))
        printf "|"
    done

    # Bottom border
    tput cup $((start_row + row_count + 1)) $start_col
    printf "+"
    for ((col=1; col<=col_count; col++)); do
        printf "-"
    done
    printf "+"
}

# Initialize positions, directions, and speeds for each character
declare -A positions
declare -A velocities_x
declare -A velocities_y
declare -A colors
declare -A characters

# Function to move a character
move_character() {
    local char=$1
    local current_row=${positions["${char}_row"]}
    local current_col=${positions["${char}_col"]}
    local vel_x=${velocities_x["${char}"]}
    local vel_y=${velocities_y["${char}"]}
    local color=${colors["${char}"]}

    # Erase the character at the current position
    tput cup $current_row $current_col
    echo -n " "

    # Calculate new position using velocity
    local new_row=$((current_row + vel_y))
    local new_col=$((current_col + vel_x))

    # Boundary check and reverse direction if necessary (ensure boundary is respected)
    if ((new_row <= start_row || new_row >= start_row + row_count + 1)); then
        vel_y=$((vel_y * -1))  # Reverse vertical velocity
        new_row=$((current_row + vel_y))  # Recalculate position
    fi
    if ((new_col <= start_col || new_col >= start_col + col_count)); then  # Ensure no overwrite of the right boundary
        vel_x=$((vel_x * -1))  # Reverse horizontal velocity
        new_col=$((current_col + vel_x))  # Recalculate position
    fi

    # Update position and velocity
    positions["${char}_row"]=$new_row
    positions["${char}_col"]=$new_col
    velocities_x["${char}"]=$vel_x
    velocities_y["${char}"]=$vel_y

    # Place the character at the new position with a random color
    tput setaf $color
    tput cup $new_row $new_col
    echo -n "$char"
    tput sgr0
}

# Function to initialize a large number of characters without overlap
initialize_characters() {
    local num_characters=$1
    local character_set=("${!2}")
    local color_set=("${!3}")

    declare -A used_positions  # Array to track used positions

    for ((i = 0; i < num_characters; i++)); do
        local char="${character_set[$((RANDOM % ${#character_set[@]}))]}"
        local color="${color_set[$((RANDOM % ${#color_set[@]}))]}"

        # Random initial position within the box
        local new_row
        local new_col

        # Ensure no overlap
        while true; do
            new_row=$((RANDOM % row_count + start_row + 1))
            new_col=$((RANDOM % col_count + start_col + 1))

            # Check if the position is already used
            if [[ -z "${used_positions["$new_row,$new_col"]}" ]]; then
                break  # Found an unused position
            fi
        done

        # Mark position as used
        used_positions["$new_row,$new_col"]=1

        # Assign random velocity (-1 or 1)
        velocities_x["${char}"]=$((RANDOM % 2 * 2 - 1))
        velocities_y["${char}"]=$((RANDOM % 2 * 2 - 1))

        # Assign color and position
        positions["${char}_row"]=$new_row
        positions["${char}_col"]=$new_col
        colors["${char}"]=$color
        characters["$char"]=1  # Mark character as initialized
    done
}

# Draw the box initially
draw_box

# Initialize a large number of characters
initialize_characters 10 custom_characters[@] custom_colors[@]

# Animation loop
while true; do
    for char in "${!characters[@]}"; do
        move_character "$char"
    done
    sleep $sleep_time
done

tput cnorm