#!/bin/bash

source utils/stack_metadata.sh

build_stack_array(){
    # Initialize an empty JSON array
    json_output="[]"

    # Iterate over each tool
    for name in "${!stack_descriptions[@]}"; do
        description="${stack_descriptions[$name]}"  # Tool description
        stack_status="${stack_status[$name]:-Unknown}"

        # Find the category for the current tool
        for cat in "${!categories_to_stacks[@]}"; do
            if [[ " ${categories_to_stacks[$cat]} " =~ " $name " ]]; then
                category="$cat"
                break
            fi
        done

        # Lowercase transformation functions for labels
        lowercase_transform() {
            echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_'
        }

        # Create transformed labels
        category_name=$(lowercase_transform "$category")
        
        category_description="${categories_descriptions[$category]:-No description available}"
        category_label="${category//_/ }"  # Convert underscores to spaces
        category_emoji="${categories_to_emojis[$category]:-Unknown}"

        stack_name=$(lowercase_transform "$name")
        stack_label="${name//_/ }"  # Convert underscores to spaces

        # Create the stack object with the category_description
        stack_item=$(jq -n \
            --arg category_name "$category_name" \
            --arg category_label "$category_label" \
            --arg category_emoji "$category_emoji" \
            --arg category_description "$category_description" \
            --arg stack_name "$stack_name" \
            --arg stack_status "$stack_status" \
            --arg stack_label "$stack_label" \
            --arg stack_description "$description" \
            --arg status "$status" \
            '{
                "stack_name": $stack_name,
                "stack_label": $stack_label,
                "stack_description": $stack_description,
                "stack_status": $stack_status,
                "category_emoji": $category_emoji,
                "category_name": $category_name,
                "category_label": $category_label,
                "category_description": $category_description,                
            }')

        # Append the stack_item to the JSON array
        json_output=$(jq -c ". + [$stack_item]" <<< "$json_output")
    done

    # Output the final JSON array
    echo "$json_output"
}

# Output the final JSON array with status
time build_stack_array | jq '.' > "./stacks/stacks.json"

