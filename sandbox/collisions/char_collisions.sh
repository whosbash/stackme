#!/bin/bash

# Collision example: Change a character on collision
# Simplified random movement with overlap detection

tput civis  # Hide cursor
trap 'tput cnorm; clear; exit' INT

rows=10
cols=20
box_row=5
box_col=10
characters=("@" "#" "*")
positions=()

# Draw box
draw_box() {
    for ((i=0; i<=rows; i++)); do
        tput cup $((box_row + i)) $box_col
        echo -n "+"
        tput cup $((box_row + i)) $((box_col + cols))
        echo -n "+"
    done
    for ((j=0; j<=cols; j++)); do
        tput cup $box_row $((box_col + j))
        echo -n "+"
        tput cup $((box_row + rows)) $((box_col + j))
        echo -n "+"
    done
}

# Random movement
move_characters() {
    local i char row col
    for i in "${!characters[@]}"; do
        char="${characters[i]}"
        row=$((RANDOM % rows + box_row + 1))
        col=$((RANDOM % cols + box_col + 1))

        # Check collision
        for pos in "${positions[@]}"; do
            if [[ "$pos" == "$row $col" ]]; then
                char="X"  # Mark collision
                break
            fi
        done

        positions+=("$row $col")
        tput cup $row $col
        echo -n "$char"
    done
}

# Main loop
clear
draw_box
while true; do
    positions=()
    move_characters
    sleep 0.3
    clear
    draw_box
done
