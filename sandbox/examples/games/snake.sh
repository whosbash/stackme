#!/bin/bash

# Snake game in Bash
cols=$(tput cols)
rows=$(tput lines)
snake=([0]="10,10")  # Initial snake at position (10, 10)
food_x=$((RANDOM % (cols - 2) + 1))  # Random food position within the box
food_y=$((RANDOM % (rows - 2) + 1))  # Random food position within the box
direction="RIGHT"
score=0
delay=0.1  # Starting speed
speed_increase=0.01  # Speed increase as score grows
game_over=false

# Color variables
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

# Draw the game
draw() {
  clear

  # Draw food (star symbol in yellow)
  tput cup $food_y $food_x
  echo -e "${YELLOW}*${RESET}"

  # Draw snake (head in red, body in green)
  IFS=',' read -r head_x head_y <<<"${snake[0]}"
  tput cup $head_y $head_x
  echo -e "${RED}@${RESET}"  # Snake head

  # Draw the body of the snake in green
  for part in "${snake[@]:1}"; do
    IFS=',' read -r x y <<<"$part"
    tput cup $y $x
    echo -e "${GREEN}#${RESET}"  # Snake body
  done

  # Display score in cyan
  tput cup 0 0
  echo -e "${CYAN}Score: $score${RESET}"
}

# Update snake's position
update_snake() {
  # Get head position
  IFS=',' read -r head_x head_y <<<"${snake[0]}"

  # Move snake based on direction
  case "$direction" in
    UP) ((head_y--)) ;;
    DOWN) ((head_y++)) ;;
    LEFT) ((head_x--)) ;;
    RIGHT) ((head_x++)) ;;
  esac

  # Check for collisions with walls (now considering the border)
  if ((head_x <= 0 || head_x >= cols - 1 || head_y <= 0 || head_y >= rows - 1)); then
    game_over=true
    return
  fi

  # Check for collisions with itself
  for part in "${snake[@]:1}"; do
    IFS=',' read -r x y <<<"$part"
    if ((head_x == x && head_y == y)); then
      game_over=true
      return
    fi
  done

  # Add new head to the snake
  snake=("$head_x,$head_y" "${snake[@]}")

  # Check if snake eats food
  if ((head_x == food_x && head_y == food_y)); then
    ((score++))
    food_x=$((RANDOM % (cols - 2) + 1))  # Reposition food within the box
    food_y=$((RANDOM % (rows - 2) + 1))  # Reposition food within the box
    delay=$(echo "$delay - $speed_increase" | bc)  # Speed up game as score increases
  else
    # Remove the last tail segment to simulate movement
    snake=("${snake[@]:0:${#snake[@]}-1}")
  fi
}

# Input handler
read_input() {
  read -rsn1 -t $delay key
  case "$key" in
    w) if [ "$direction" != "DOWN" ]; then direction="UP"; fi ;;
    s) if [ "$direction" != "UP" ]; then direction="DOWN"; fi ;;
    a) if [ "$direction" != "RIGHT" ]; then direction="LEFT"; fi ;;
    d) if [ "$direction" != "LEFT" ]; then direction="RIGHT"; fi ;;
  esac
}

# Main loop
trap 'tput cnorm; clear; exit 0' SIGINT
tput civis
while ! $game_over; do
  read_input
  update_snake
  draw
done

# Game over message
tput cup $((rows / 2)) $((cols / 2 - 7))
echo -e "${RED}Game Over! Final Score: $score${RESET}"
sleep 2
tput cnorm
clear
