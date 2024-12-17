#!/bin/bash

# Function to find unused functions in a script
find_unused_functions() {
  local script="$1"
  local sort_order="${2:-asc}"  # Default to ascending order if not specified

  # Check if the script exists
  if [[ ! -f "$script" ]]; then
    echo "Error: File '$script' does not exist."
    return 1
  fi

  # Extract all function names defined in the script (preserve order of appearance)
  local functions
  functions=$(grep -oP '^\s*[\w_]+\s*\(\)\s*\{' "$script" | awk -F'(' '{print $1}' | sed 's/ //g')

  # Create an array to store function name, usage count, and appearance order
  local function_usage=()

  # Check usage of each function
  for func in $functions; do
    # Use sed to remove comments (everything after '#' and inline comments) and string literals (between '' and "")
    cleaned_script=$(sed -E -e 's/#.*//' -e 's/".*?"//g' -e "s/'.*?'//g" "$script")

    # Count the occurrences of the function name (excluding the definition itself)
    local usage_count
    usage_count=$(echo "$cleaned_script" | grep -oP "[^a-zA-Z0-9_]$func[^a-zA-Z0-9_]" | wc -l)
    
    # Store the function, its count, and appearance order in the array
    function_usage+=("$usage_count $func")
  done

  # Sort by appearance order first, then usage count, and lastly alphabetically if needed
  if [[ "$sort_order" == "desc" ]]; then
    # Sort descending by usage count, then alphabetically by function name if counts are equal
    echo -e "\nFunctions sorted by usage (descending):"
    printf "%s\n" "${function_usage[@]}" | sort -t ' ' -k1,1nr -k2
  else
    # Sort ascending by usage count, then alphabetically by function name if counts are equal
    echo -e "\nFunctions sorted by usage (ascending):"
    printf "%s\n" "${function_usage[@]}" | sort -t ' ' -k1,1n -k2
  fi
}

# Check if the script was provided as an argument
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <script_file> [asc|desc]"
  exit 1
fi

# Call the function with the provided argument
find_unused_functions "$1" "$2"
