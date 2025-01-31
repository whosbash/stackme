#!/bin/bash

# Ensure correct usage: script expects two arguments: script file and pattern
if [ $# -ne 2 ]; then
    echo "Usage: $0 <shell_script_file> <pattern>"
    exit 1
fi

# Assign input arguments to variables
script_file="$1"
pattern="$2"

# Ensure the provided script file exists
if [ ! -f "$script_file" ]; then
    echo "Error: File '$script_file' not found."
    exit 1
fi

# Use grep and regular expressions to match function definitions in the script
# This pattern will match functions in a POSIX-compliant shell style
grep -Er "^\s*$pattern[a-zA-Z0-9_]*\s*\(\)\s*{" "$script_file"
