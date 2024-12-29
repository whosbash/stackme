#!/bin/bash

# Function to handle SIGINT (Ctrl+C)
handle_sigint() {
  echo -e "\n${RED}Paused! Press 'r' to resume or 'q' to quit.${RESET}"
  while true; do
    read -rsn1 key
    case "$key" in
      r) 
        echo -e "${CYAN}Resuming game...${RESET}"
        return  # Exit the handler and continue the script
        ;;
      q) 
        echo -e "${RED}Exiting game...${RESET}"
        tput cnorm
        exit 0  # Exit the script
        ;;
      *) 
        echo -e "${YELLOW}Invalid choice. Press 'r' to resume or 'q' to quit.${RESET}"
        ;;
    esac
  done
}

trap handle_sigint SIGINT  # Set the custom handler for SIGINT

# Example game loop
game_over=false
while [[ $game_over == false ]]; do
  # Game logic goes here
  read -rsn1 -t 0.1 key
  # Your game logic would be placed here
  echo "Game running. Press Ctrl+C to pause."
  sleep 0.5
done
