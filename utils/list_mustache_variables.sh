#!/bin/bash

# Folder containing files to scan for Mustache variables
folder="$1"

if [[ -z "$folder" || ! -d "$folder" ]]; then
    echo "Usage: $0 <folder_with_files>"
    exit 1
fi

echo "Listing Mustache variables in each file:"
echo

# Iterate through all files in the folder
for file in "$folder"/*; do
    if [[ -f "$file" ]]; then
        echo "File: $file"
        # Extract Mustache variables using grep
        grep -oE "\{\{[a-zA-Z0-9_]+\}\}" "$file" | sort | uniq || echo "No Mustache variables found"
        echo
    fi
done
