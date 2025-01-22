#!/bin/bash

# Define the search directory and the pattern
search_dir="$1"
search_pattern="$2"

# Check if both arguments are provided
if [[ -z "$search_dir" || -z "$search_pattern" ]]; then
    echo "Usage: $0 <search_directory> <search_pattern>"
    exit 1
fi

# Use grep to find files containing the pattern
files=$(grep -rl "$search_pattern" "$search_dir")

# Check if files were found
if [[ -z "$files" ]]; then
    echo "No files found containing the pattern '$search_pattern'."
    exit 0
fi

# Calculate row counts for each file and sort them
echo "Files sorted by row count:"
while IFS= read -r file; do
    row_count=$(wc -l < "$file")
    echo "$row_count $file"
done <<< "$files" | sort -nr
