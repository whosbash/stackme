#!/bin/bash

# Function to find and count function usage in a script
find_function_usage() {
  local script_file="$1"

  if [[ ! -f "$script_file" ]]; then
    echo "Error: File '$script_file' not found."
    return 1
  fi

  # Step 1: Gather all function names (definitions)
  local function_names
  function_names=$(grep -oP '^\s*[A-Za-z0-9_]+\(\)\s*\{' "$script_file" | sed -E 's/\(\)\s*\{//' | tr -d ' ')

  echo "Function usage count:"
  
  # Step 2: Iterate through each function name and count occurrences
  while read -r func_name; do
    # Count occurrences of the function name (followed by space or end of line)
    local count
    count=$(grep -oP "\b$func_name\b(?=(\s|$))" "$script_file" | wc -l)
    echo "$func_name: $count"
  done <<< "$function_names"
}

# Example usage
if [[ "$#" -eq 0 ]]; then
  echo "Usage: $0 <script_file>"
  exit 1
fi

find_function_usage "$1"
