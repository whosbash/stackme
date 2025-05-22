#!/bin/bash

cols=$(tput cols)
rows=$(tput lines)
player_x=$((cols / 2))
player_y=$((rows - 2))
score=0
delay=0.1
enemy_move_delay=8  # Slower enemy movement
spawn_interval=50   # Increased spawn interval for fewer enemies
max_enemies=5       # Limit the maximum number of enemies on screen
loop_counter=0
spawn_x_min=5       # Minimum spawn x-coordinate
spawn_x_max=$((cols - 5))  # Maximum spawn x-coordinate

declare -A enemy_symbols=(
  [1]="👾"
  [2]="👽"
  [3]="💀"
  [4]="👹"
  [5]="👺"
)  # Different enemy symbols based on strength

enemies=()  # Stores enemy data as "x,y,strength"
bullets=()  # Stores bullet data as "x,y"

# Spawn a new enemy at a random position with random strength
spawn_enemy() {
  if [[ ${#enemies[@]} -lt $max_enemies ]]; then
    local x=$((RANDOM % (spawn_x_max - spawn_x_min + 1) + spawn_x_min))
    local strength=$((RANDOM % 5 + 1))
    enemies+=("$x,1,$strength")
  fi
}

# Draw the game
draw() {
  clear
  # Draw enemies with the corresponding symbol
  for enemy in "${enemies[@]}"; do
    IFS=',' read -r x y strength <<<"$enemy"
    local symbol=${enemy_symbols[$strength]}
    tput cup "$y" "$x"
    echo -n "$symbol"
  done

  # Draw bullets
  for bullet in "${bullets[@]}"; do
    IFS=',' read -r x y <<<"$bullet"
    tput cup "$y" "$x"
    echo "↑"
  done

  # Draw player
  tput cup "$player_y" "$player_x"
  echo "🚀"  # Rocket symbol

  # Display score
  tput cup 0 0
  echo "Score: $score"
}

# Move bullets
move_bullets() {
  new_bullets=()
  for bullet in "${bullets[@]}"; do
    IFS=',' read -r x y <<<"$bullet"
    ((y--))
    if ((y > 0)); then
      new_bullets+=("$x,$y")
    fi
  done
  bullets=("${new_bullets[@]}")
}

# Move enemies vertically down with delay
move_enemies() {
  if ((loop_counter % enemy_move_delay == 0)); then
    new_enemies=()
    for enemy in "${enemies[@]}"; do
      IFS=',' read -r x y strength <<<"$enemy"
      ((y++))
      if ((y >= rows - 1)); then
        # If an enemy reaches the bottom, it's game over
        tput cup $((rows / 2)) $((cols / 2 - 10))
        echo "Game Over! Final Score: $score"
        sleep 2
        tput cnorm
        clear
        exit 0
      fi
      new_enemies+=("$x,$y,$strength")
    done
    enemies=("${new_enemies[@]}")
  fi
}

# Handle collisions
check_collisions() {
  new_bullets=()
  new_enemies=()

  for bullet in "${bullets[@]}"; do
    IFS=',' read -r bx by <<<"$bullet"
    local hit=0
    for i in "${!enemies[@]}"; do
      IFS=',' read -r ex ey strength <<<"${enemies[i]}"
      if ((bx == ex && by == ey)); then
        # Collision detected
        unset 'enemies[i]'
        ((score += strength))  # Add enemy's strength to score
        hit=1
        break
      fi
    done
    if ((hit == 0)); then
      new_bullets+=("$bx,$by")
    fi
  done

  bullets=("${new_bullets[@]}")
  enemies=("${enemies[@]}")

  # Check win condition (no more enemies)
  if [[ ${#enemies[@]} -eq 0 ]]; then
    tput cup $((rows / 2)) $((cols / 2 - 10))
    echo "Congratulations! You win! 🎉 Final Score: $score"
    sleep 2
    tput cnorm
    clear
    exit 0
  fi
}

# Input handler
read_input() {
  read -rsn1 -t $delay key
  case "$key" in
    a) ((player_x > 0)) && ((player_x--)) ;;       # Move left
    d) ((player_x < cols - 2)) && ((player_x++)) ;; # Move right
    w) ((player_y > 1)) && ((player_y--)) ;;       # Move up
    s) ((player_y < rows - 1)) && ((player_y++)) ;; # Move down
    x) bullets+=("$player_x,$((player_y - 1))") ;;  # Fire bullets
  esac
}

# Main loop
trap 'tput cnorm; clear; exit 0' SIGINT
tput civis
while true; do
  # Spawn a new enemy every few loops
  if ((loop_counter % spawn_interval == 0)); then
    spawn_enemy
  fi

  # Ensure enemies are initialized correctly
  if [[ ${#enemies[@]} -eq 0 ]]; then
    spawn_enemy
  fi

  read_input
  move_bullets
  move_enemies
  check_collisions
  draw

  # Increment loop counter
  ((loop_counter++))
done
