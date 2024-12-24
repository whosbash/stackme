#!/bin/bash

# Hide cursor
tput civis

row=5
col=10

# Place the first character
tput cup $row $col
echo -n "A"

# Wait and then remove the character
sleep 1
tput cup $row $col
echo -n " "  # Clear by printing a space

# Place the new character
tput cup $row $col
echo -n "B"

echo

# Restore cursor visibility
tput cnorm
