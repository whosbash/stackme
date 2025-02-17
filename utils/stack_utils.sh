#!/bin/bash

generate_stack_status_stats_percentage() {
  local total_count
  total_count=$(printf '%s\n' "${stack_status[@]}" | wc -l)  # Get total number of items

  if [[ "$total_count" -eq 0 ]]; then
    echo '{}'  # Return empty JSON object if no statuses are present
    return
  fi

  printf '%s\n' "${stack_status[@]}" | jq -R . | jq -s --arg total "$total_count" '
    group_by(.) | map({(.[0]): { count: length, percentage: (length * 100 / ($total | tonumber)) }}) | add
    | { development, beta, stable }'  # Force order of keys
}

sort_by_complexity_and_status(){
  local local folder_path="$1"

  # Initialize an empty JSON object
  json_output="{}"

  # Find files, count unique Mustache variables, and categorize
  while IFS= read -r -d '' file; do
      # Extract unique Mustache variables
      mustache_vars=$(grep -o '{{[^}]*}}' "$file" | sed 's/[{}]//g' | sort -u | tr '\n' ' ')
      
      # Count unique Mustache variables
      unique_count=$(echo "$mustache_vars" | wc -w)

      # Extract tool name from filename (assuming format like 'toolname.config' or similar)
      tool_name=$(basename "$file" | cut -d. -f1)

      # Determine category based on stack_status mapping
      category="${stack_status[$tool_name]:-unknown}"

      # Construct JSON entry
      entry="{\"file\": \"$file\", \"complexity\": $unique_count, \"variables\": \"$mustache_vars\"}"

      # Append to JSON object grouped by category
      json_output=$(echo "$json_output" | jq --arg cat "$category" --argjson entry "$entry" '
          .[$cat] += [$entry] // [$entry]
      ')
  done < <(find "$folder_path" -type f -print0)

  # Pretty-print the JSON output and sort by complexity in descending order
  echo "$json_output" | \
  jq 'to_entries | map({key: .key, value: (.value | sort_by(.complexity) | reverse)}) | from_entries'
}