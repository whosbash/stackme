#!/bin/bash

STACKS_TEMPLATE_URL="https://api.github.com/repos/whosbash/stackme/contents/stacks"

download_stack_compose_templates() {
    local destination_folder="$1"
    
    # Ensure the destination folder is provided
    if [[ -z "$destination_folder" ]]; then
        echo "Error: Destination folder not specified."
        return 1
    fi

    # Create the destination folder if it doesn't exist
    mkdir -p "$destination_folder" || {
        echo "Error: Failed to create destination folder $destination_folder."
        return 1
    }

    echo "Fetching file list from GitHub API..."
    # Fetch the file information from the API
    file_urls=$(\
        curl -s -H "Accept: application/vnd.github.v3+json" "$STACKS_TEMPLATE_URL" | \
        jq -r '.[] | select(.type == "file") | .download_url'
    )

    # Check if files were found
    if [[ -z "$file_urls" ]]; then
        echo "No files found at $STACKS_TEMPLATE_URL."
        return 1
    fi

    echo "Found $(echo "$file_urls" | wc -l) files. Starting download..."

    # Time the download process
    start_time=$(date +%s)

    # Prepare a variable to track failed downloads
    failed_downloads=()

    # Download all files in parallel with minimal output
    echo "$file_urls" | xargs -P 10 -I {} bash -c '
        file_name=$(basename "{}")
        if curl -s --fail -o "'"$destination_folder"'/$file_name" "{}"; then 
            echo -n "."  # Success
        else 
            echo -n "x" >&2  # Failure
            echo "$file_name" >> "'"$destination_folder"'/failed_downloads.txt"  # Log failed downloads
        fi
    '

    # End timing and report
    echo  # Move to the next line after the progress bar
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    echo "Download completed in ${elapsed_time} seconds."

    # Display the failed downloads
    if [[ -f "$destination_folder/failed_downloads.txt" ]]; then
        echo "Failed downloads:"
        cat "$destination_folder/failed_downloads.txt"
    fi
}

# Define the GitHub API URL and the destination folder
dest_folder="./downloads"
download_stack_compose_templates "$dest_folder"
