#!/bin/bash

# Player-controlled character
tput civis
trap 'tput cnorm; clear; exit' INT

row=10
col=10
player="P"

move_player() {
    case "$1" in
        w) ((row--)) ;;
        s) ((row++)) ;;
        a) ((col--)) ;;
        d) ((col++)) ;;
    esac
    tput cup $row $col
    echo -n "$player"
}

clear
while true; do
    read -rsn1 key
    tput cup $row $col
    echo -n " "
    move_player "$key"
done
