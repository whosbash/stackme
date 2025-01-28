#!/bin/bash

# Folder containing YAML files
folder="$1"

# Ensure the folder exists
if [[ ! -d "$folder" ]]; then
    echo "Error: Folder '$folder' does not exist."
    exit 1
fi

# Loop through all YAML files in the folder
for yaml_file in "$folder"/*.yaml; do
    # Skip if no YAML files are found
    [[ -e "$yaml_file" ]] || { echo "No YAML files found in $folder."; exit 1; }
    
    echo "File: $yaml_file"

    # Extract volume names using yq or grep/sed
    volume_names=$(yq eval '.volumes | keys' "$yaml_file" 2>/dev/null | grep -v "null" || \
        grep -A 100 'volumes:' "$yaml_file" | awk '/volumes:/,/[^ ]*:/ {print $1}' | grep -v 'volumes:')

    if [[ -z "$volume_names" ]]; then
        echo "  - No volumes found."
    else
        echo "$volume_names" | sed 's/^/    /'
    fi
done
