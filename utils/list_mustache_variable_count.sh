#!/bin/bash

# Check if folder argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

folder_path="$1"

# Find files in the folder, count unique Mustache variables, and sort them
find "$folder_path" -type f -print0 | while IFS= read -r -d '' file; do
    # Extract unique mustache variables (removing {{ and }})
    mustache_vars=$(grep -o '{{[^}]*}}' "$file" | sed 's/[{}]//g' | sort -u | tr '\n' ' ')
    
    # Count unique mustache variables
    unique_count=$(echo "$mustache_vars" | wc -w)

    # Output the count, variables, and filename
    echo "$unique_count $file: $mustache_vars"
done | sort -nr
