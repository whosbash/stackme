#!/bin/bash

filter_json_object_by_keys() {
  local json="$1"         # Input JSON string
  local keys=("${@:2}")   # Array of keys (after the first argument)
  local missing_keys=()   # Array to store missing keys
  local filtered_json="{}"  # Resultant JSON object

  # Loop through each key
  for key in "${keys[@]}"; do
    # Convert dotted key to array for getpath
    local jq_path
    jq_path=$(echo "$key" | jq -R 'split(".")')

    # Extract the value for the current key
    local value
    value=$(echo "$json" | jq -r --argjson path "$jq_path" 'try getpath($path) // empty')

    if [[ -z "$value" || "$value" == "null" ]]; then
      # Key is missing; add to missing_keys array
      missing_keys+=("$key")
    else
      # Key exists; add it to the filtered JSON object with the dotted key
      filtered_json=$(echo "$filtered_json" | jq --arg key "$key" --arg value "$value" '. + {($key): $value}')
    fi
  done

  # If there are missing keys, print a warning
  if [[ ${#missing_keys[@]} -gt 0 ]]; then
    echo "The following keys are missing in the JSON: ${missing_keys[*]}" >&2
  fi

  # Return the filtered JSON object
  echo "$filtered_json"
}


load_portainer_url_and_credentials(){
  local portainer_config_json
  portainer_config_json='{
    "name": "portainer",
    "variables": {
        "portainer_agent_version": "2.26.1",
        "portainer_ce_version": "2.26.1",
        "portainer_url": "portainer.persev.info",
        "portainer_credentials": "{\"username\": \"portainer\", \"password\": \"Portainer!54321\"}",
        "network_name": "mynetwork"
    },
    "dependencies": [
        "traefik"
    ],
    "actions": {
        "refresh": [],
        "prepare": [],
        "finalize": [
        {
            "name": "signup_on_portainer",
            "description": "Signup on portainer",
            "command": "signup_on_portainer \"portainer.persev.info\" \"portainer\" \"Portainer!54321\""
        }
        ]
    }
    }'

  portainer_info="$(
    filter_json_object_by_keys "$portainer_config_json" \
      "variables.portainer_url" "variables.portainer_credentials"
  )"

  echo "$portainer_info" >&2

  # Extract the portainer_url as a string
  portainer_url="$(echo "$portainer_info" | jq -r '.["variables.portainer_url"]')"

  # Parse the portainer_credentials string into a JSON object (using fromjson)
  portainer_credentials="$(echo "$portainer_info" | jq -r '.["variables.portainer_credentials"] | fromjson')"

  # Return the filtered JSON with portainer_url and portainer_credentials
  jq -n \
    --arg portainer_url "$portainer_url" \
    --argjson portainer_credentials "$portainer_credentials" \
    '{"portainer_url": $portainer_url, "portainer_credentials": $portainer_credentials}'
}

# Call the function to filter the JSON for specific keys
filtered_json=$(load_portainer_url_and_credentials)

# Output the filtered JSON
echo "$filtered_json"
