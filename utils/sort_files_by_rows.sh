#!/bin/bash

# Folder containing the files
folder_path="$1"

# Check if the folder path is provided
if [[ -z "$folder_path" ]]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

# Check if the folder exists
if [[ ! -d "$folder_path" ]]; then
  echo "Error: Folder '$folder_path' does not exist."
  exit 1
fi

# Find all files in the folder, count lines, and sort them
echo "Files sorted by row count:"
find "$folder_path" -type f | while read -r file; do
  # Count lines and print as "row_count file_name"
  row_count=$(wc -l < "$file")
  echo "$row_count $file"
done | sort -n

exit 0
