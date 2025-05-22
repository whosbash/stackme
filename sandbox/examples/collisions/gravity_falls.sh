#!/bin/bash

# Characters "falling" within the box
tput civis
trap 'tput cnorm; clear; exit' INT

rows=10
cols=20
box_row=5
box_col=10
characters=("*" "#" "@")
gravity=0.1

draw_box() {
    for ((i=0; i<=rows; i++)); do
        tput cup $((box_row + i)) $box_col
        echo -n "|"
        tput cup $((box_row + i)) $((box_col + cols))
        echo -n "|"
    done
    for ((j=0; j<=cols; j++)); do
        tput cup $box_row $((box_col + j))
        echo -n "-"
        tput cup $((box_row + rows)) $((box_col + j))
        echo -n "-"
    done
}

falling_characters() {
    local char row col
    for char in "${characters[@]}"; do
        row=$((RANDOM % rows + box_row + 1))
        col=$((RANDOM % cols + box_col + 1))
        while ((row < box_row + rows)); do
            tput cup $row $col
            echo -n "$char"
            sleep $gravity
            tput cup $row $col
            echo -n " "
            ((row++))
        done
    done
}

clear
draw_box
while true; do
    falling_characters
done
