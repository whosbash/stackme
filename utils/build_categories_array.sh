#!/bin/bash

source utils/stack_metadata.sh

build_categories_array() {
    # Initialize an empty JSON array for categories
    json_output="[]"

    # Iterate over each category
    for category in "${!categories_to_stacks[@]}"; do
        # Lowercase transformation functions for labels
        lowercase_transform() {
            echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_'
        }

        # Category attributes
        category_name=$(lowercase_transform "$category")
        category_label="${category//_/ }"  # Convert underscores to spaces
        category_emoji="${categories_to_emojis[$category]:-Unknown}"
        category_description="${categories_descriptions[$category]:-No description available}"

        # Initialize an empty JSON array for stacks within this category
        stacks_json="[]"

        # Iterate over stacks assigned to this category
        for name in ${categories_to_stacks[$category]}; do
            stack_name=$(lowercase_transform "$name")
            stack_label="${name//_/ }"  # Convert underscores to spaces
            stack_description="${stack_descriptions[$name]}"  # Stack description
            stack_status="${stack_status[$name]:-Unknown}"

            # Create the stack object
            stack_item=$(jq -n \
                --arg category_name "${category_name:-Unknown}" \
                --arg name "${stack_name:-Unknown}" \
                --arg stack_label "${stack_label:-Unknown}" \
                --arg description "${stack_description:-Unknown}" \
                --arg status "${stack_status:-Unknown}" \
                '{
                    "name": $name,
                    "type": "stack",
                    "category_name": $category_name,
                    "stack_label": $stack_label,
                    "description": $description,
                    "status": $status
                }')

            # Append stack_item to stacks_json
            stacks_json=$(jq -c ". + [$stack_item]" <<< "$stacks_json")
        done

        # Create the category object with stacks inside
        category_item=$(jq -n \
            --arg name "$category_name" \
            --arg category_label "$category_label" \
            --arg description "$category_description" \
            --arg emoji "$category_emoji" \
            --argjson stacks "$stacks_json" \
            '{
                "name": $name,
                "type": "category",
                "category_label": $category_label,
                "emoji": $emoji,
                "description": $description,
                "stacks": $stacks
            }')

        # Append category_item to json_output
        json_output=$(jq -c ". + [$category_item]" <<< "$json_output")
    done

    # Output the final JSON array
    echo "$json_output"
}

# Output the final JSON array with status
time build_categories_array | jq '.' > "./stacks/categories.json"
