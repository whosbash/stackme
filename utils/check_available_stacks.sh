#!/bin/bash

# Function to check the status of a stack (whether it's complete or WIP)
check_stack_status() {
  local stack_name="$1"
  local missing_count=0
  local missing_functions=()
  local required_functions=("compose_file_${stack_name}" "generate_stack_config_${stack_name}" "deploy_stack_${stack_name}")

  echo -e "\n\033[1;34mChecking stack: \033[1;36m$stack_name\033[0m" >&2

  for func in "${required_functions[@]}"; do
    if ! grep -qE "$func" "$script_file"; then
      missing_count=$((missing_count + 1))
      missing_functions+=("$func")
    fi
  done

  if [[ $missing_count -gt 0 ]]; then
    echo -e "\033[1;31mStack Status: WIP\033[0m"
    echo -e "\033[1;33mMissing Functions (\033[1;31m$missing_count\033[1;33m):\033[0m"
    for func in "${missing_functions[@]}"; do
      echo -e "  - \033[1;31m$func\033[0m"
    done
    return 1  # WIP
  else
    echo -e "\033[1;32mStack Status: Complete\033[0m"
    return 0  # Complete
  fi
}

# Identify stacks based on function names and check their status
check_all_stacks() {
  local script_file="$1"

  # Find all function identifiers with the specified pattern
  local all_functions_raw
  all_functions_raw=$( grep -oE '(compose_file_|generate_stack_config_|deploy_stack_)[a-zA-Z0-9]+\(' "$script_file" | sed 's/.$//')

  # Extract unique stack names
  local stacks=()
  for func in $all_functions_raw; do
    stack_name=$(echo "$func" | sed -E 's/^(compose_file_|generate_stack_config_|deploy_stack_)([a-zA-Z0-9]+)$/\2/')
    if [[ ! " ${stacks[@]} " =~ " ${stack_name} " ]]; then
      stacks+=("$stack_name")
    fi
  done

  # Check each stack
  for stack in "${stacks[@]}"; do
    check_stack_status "$stack"
  done
}

# Main script logic
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <script_file>"
  exit 1
fi

script_file="$1"

# Check if the file exists
if [[ ! -f "$script_file" ]]; then
  echo "Error: File '$script_file' does not exist."
  exit 1
fi

# Check all stacks in the provided script file
check_all_stacks "$script_file"
