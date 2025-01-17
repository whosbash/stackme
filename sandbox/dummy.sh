#!/bin/bash

# Function to display a message, read user input, and handle a timeout
request_input() {
  local message="$1"
  local variable_name="$2"
  local timeout="$3"  # Optional timeout value in seconds

  echo -ne "$message" >&2

  # Use read with or without timeout
  if [[ -n "$timeout" ]]; then
    read -rsn1 -t "$timeout" "$variable_name" || eval "$variable_name=''"  # Timeout or empty input
  else
    read -rsn1 "$variable_name" # No timeout
  fi

  # Trim leading/trailing spaces
  eval "$variable_name=\$(echo -n \"\${$variable_name}\" | tr -d '[:space:]')"
}

# Function to request confirmation (yes/no)
request_confirmation() {
  local message="$1"
  local default_value="${2:-y}"
  local timeout="$3"

  local user_input=''
  request_input "$message" user_input "$timeout"

  # Use default value if input is empty
  if [[ -z "$user_input" ]]; then
    user_input="$default_value"
  fi

  # Validate the input
  while [[ ! "$user_input" =~ ^[yYnN]$ ]]; do
    echo -e "\nInvalid input \"$user_input\". Please enter 'y' for yes or 'n' for no." >&2
    user_input=''
    request_input "$message" user_input "$timeout"
    if [[ -z "$user_input" ]]; then
      user_input="$default_value"
    fi
  done

  # Normalize the input to lowercase and trim spaces
  echo "$user_input" | tr '[:upper:]' '[:lower:]'
}

# Main script usage
variable="$(request_confirmation 'Hello: ' 'y' 5)"
echo "Variable:($variable)"

sleep 2