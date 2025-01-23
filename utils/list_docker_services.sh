#!/bin/bash

# Folder containing docker-compose YAML files
folder="$1"

if [[ -z "$folder" || ! -d "$folder" ]]; then
    echo "Usage: $0 <folder_with_docker_compose_files>"
    exit 1
fi

echo "Listing services in each Docker-Compose YAML file:"
echo

# Iterate through all YAML files in the folder
for file in "$folder"/*.yml "$folder"/*.yaml; do
    if [[ -f "$file" ]]; then
        echo "File: $file"
        # Extract services using yq or grep (fallback)
        if command -v yq &>/dev/null; then
            yq e '.services | keys' "$file"
        else
            grep -E "^[[:space:]]+[^[:space:]]+:" "$file" | grep -A 1 "services:" | awk '{print $1}' | sed 's/://g'
        fi
        echo
    fi
done
