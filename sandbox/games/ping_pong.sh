#!/bin/bash

cols=$(tput cols)
rows=$(tput lines)
ball_x=$((cols / 2))
ball_y=$((rows / 2))
ball_dx=1
ball_dy=1
paddle1_y=$((rows / 2))
paddle2_y=$((rows / 2))
score1=0
score2=0
high_score=0
delay=0.1  # Slower gameplay to make it easier
game_over=false
ball_speed_increase=0.005  # Gradual increase in ball speed

# Colors for better aesthetics
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

# Load high score from file
load_high_score() {
  if [[ -f "high_score.txt" ]]; then
    read high_score < high_score.txt
  else
    high_score=0
  fi
}

# Save high score to file
save_high_score() {
  if ((score1 + score2 > high_score)); then
    echo "$((score1 + score2))" > high_score.txt
    high_score=$((score1 + score2))
    echo -e "${CYAN}New High Score!${RESET}"
  fi
}

# Draw the game
draw() {
  clear
  # Draw ball
  tput cup $ball_y $ball_x
  echo -e "${YELLOW}o${RESET}"

  # Draw paddles
  for ((i = -3; i <= 3; i++)); do  # Made paddles larger
    tput cup $((paddle1_y + i)) 2
    echo -e "${GREEN}|${RESET}"  # Player 1 paddle
    tput cup $((paddle2_y + i)) $((cols - 3))
    echo -e "${GREEN}|${RESET}"  # Player 2 paddle
  done

  # Display scores and high score
  tput cup 0 0
  echo -e "${CYAN}Player 1: $score1 | Player 2: $score2 | High Score: $high_score${RESET}"
}

# Move ball
move_ball() {
  ball_x=$((ball_x + ball_dx))
  ball_y=$((ball_y + ball_dy))

  # Bounce off top and bottom walls
  if ((ball_y <= 0 || ball_y >= rows - 1)); then
    ball_dy=$((ball_dy * -1))
  fi

  # Bounce off left wall (Player 1 side)
  if ((ball_x <= 0)); then
    score2=$((score2 + 1))
    ball_x=$((cols / 2))
    ball_y=$((rows / 2))
    ball_dx=$((ball_dx * -1))
    # Gradually increase ball speed after scoring
    ball_dx=$((ball_dx + ball_speed_increase))
    ball_dy=$((ball_dy + ball_speed_increase))
  fi

  # Bounce off right wall (Player 2 side)
  if ((ball_x >= cols - 1)); then
    score1=$((score1 + 1))
    ball_x=$((cols / 2))
    ball_y=$((rows / 2))
    ball_dx=$((ball_dx * -1))
    # Gradually increase ball speed after scoring
    ball_dx=$((ball_dx + ball_speed_increase))
    ball_dy=$((ball_dy + ball_speed_increase))
  fi

  # Bounce off Player 1 paddle
  if ((ball_x == 3 && ball_y >= paddle1_y - 3 && ball_y <= paddle1_y + 3)); then  # Paddle size increased
    ball_dx=$((ball_dx * -1))
    ball_dy=$(((ball_y - paddle1_y) / 2))  # Adjust the bounce based on where the ball hits the paddle
  fi

  # Bounce off Player 2 paddle
  if ((ball_x == cols - 3 && ball_y >= paddle2_y - 3 && ball_y <= paddle2_y + 3)); then  # Paddle size increased
    ball_dx=$((ball_dx * -1))
    ball_dy=$(((ball_y - paddle2_y) / 2))  # Adjust the bounce based on where the ball hits the paddle
  fi
}

# Input handler
read_input() {
  read -rsn1 -t $delay key
  case "$key" in
    w) ((paddle1_y > 2)) && ((paddle1_y--)) ;;  # Move Player 1 paddle up
    s) ((paddle1_y < rows - 3)) && ((paddle1_y++)) ;;  # Move Player 1 paddle down
    i) ((paddle2_y > 2)) && ((paddle2_y--)) ;;  # Move Player 2 paddle up
    k) ((paddle2_y < rows - 3)) && ((paddle2_y++)) ;;  # Move Player 2 paddle down
  esac
}

# Game Over screen
game_over_screen() {
  local msg="Game Over! Final Score: Player 1 - $score1, Player 2 - $score2"
  for ((i = 0; i < ${#msg}; i++)); do
    tput cup $((rows / 2)) $((cols / 2 - 7 + i))
    echo -n "${RED}${msg:$i:1}${RESET}"
    sleep 0.05
  done
  sleep 1
}

# Main loop
trap 'tput cnorm; clear; exit 0' SIGINT
tput civis
load_high_score  # Load high score at the start

while [[ $game_over == false ]]; do
  read_input
  move_ball
  draw
done

# Game Over screen and save high score
game_over_screen
save_high_score  # Save high score if needed
