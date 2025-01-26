#!/bin/bash

# Folder containing files to scan for Mustache variables
folder="$1"

if [[ -z "$folder" || ! -d "$folder" ]]; then
    echo "Usage: $0 <folder_with_files>"
    exit 1
fi

echo "Counting and listing files by Mustache variable count:"
echo

# Initialize an empty file count accumulator
declare -A file_counts

# Iterate through all files in the folder
for file in "$folder"/*; do
    if [[ -f "$file" ]]; then
        # Extract unique Mustache variables in the current file
        unique_vars=$(grep -oE "\{\{[a-zA-Z0-9_]+\}\}" "$file" | sort | uniq)
        
        # Count the number of unique variables
        count=$(echo "$unique_vars" | wc -l)
        
        # If count is greater than 0, save the count for the file
        if [[ $count -gt 0 ]]; then
            file_counts["$file"]=$count
        fi
    fi
done

# Sort the files by variable count in descending order and display the result
echo "Files sorted by unique Mustache variable count:"
for file in "${!file_counts[@]}"; do
    echo "${file_counts[$file]}:$file"
done | sort -nr
