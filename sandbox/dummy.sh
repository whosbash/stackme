#!/bin/bash

# Function to create Prometheus scrape_config
create_scrape_config() {
  # Input parameters
  local job_name=""
  local metrics_path="/metrics"       # Default
  local honor_timestamps="true"      # Default
  local honor_labels="false"         # Default
  local scrape_interval="15s"        # Default
  local targets=()

  # Parse named parameters
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --job_name)
        job_name="$2"
        shift 2
        ;;
      --metrics_path)
        metrics_path="$2"
        shift 2
        ;;
      --honor_timestamps)
        honor_timestamps="$2"
        shift 2
        ;;
      --honor_labels)
        honor_labels="$2"
        shift 2
        ;;
      --scrape_interval)
        scrape_interval="$2"
        shift 2
        ;;
      --targets)
        # Split targets into an array
        IFS=',' read -r -a targets <<< "$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        return 1
        ;;
    esac
  done

  # Input validation
  if [[ -z "$job_name" ]]; then
    echo "Error: 'job_name' is required." >&2
    return 1
  fi
  if [[ ${#targets[@]} -eq 0 ]]; then
    echo "Error: At least one target must be provided using --targets." >&2
    return 1
  fi

  # Use jq to create the JSON object
  jq -n \
    --arg job_name "$job_name" \
    --arg metrics_path "$metrics_path" \
    --argjson honor_timestamps "$honor_timestamps" \
    --argjson honor_labels "$honor_labels" \
    --arg scrape_interval "$scrape_interval" \
    --argjson targets "$(printf '%s\n' "${targets[@]}" | jq -R . | jq -s .)" \
    '{
      job_name: $job_name,
      metrics_path: $metrics_path,
      honor_timestamps: $honor_timestamps,
      honor_labels: $honor_labels,
      scrape_interval: $scrape_interval,
      static_configs: [
        {
          targets: $targets
        }
      ]
    }'
}

# Function to add scrape_config to YAML file
add_scrape_config() {
  # Input parameters
  local filename="$1"
  local scrape_config="$2"

  # Step 1: Check if the file exists
  if [[ ! -f "$filename" ]]; then
    echo "File $filename does not exist. Initializing with default content."
    cat <<EOF > "$filename"
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets: []
scrape_configs: 
EOF
  fi

  # Step 2: Check if the job_name already exists
  local job_name
  job_name=$(echo "$scrape_config" | jq -r '.job_name')
  check_existing_job_name "$filename" "$job_name"
  
  if [[ $? -eq 0 ]]; then
    echo "Error: job_name '$job_name' already exists in $filename." >&2
    return 1
  fi

  # Step 3: Add the scrape_config to the YAML file
  yq eval -i ".scrape_configs += [$scrape_config]" "$filename"
  echo "Added scrape_config for job '$job_name' to $filename."
}

# Function to check if a job_name exists in the scrape_configs of a YAML file
check_existing_job_name() {
  # Input parameters
  local filename="$1"
  local job_name="$2"

  # Validate inputs
  if [[ -z "$filename" || -z "$job_name" ]]; then
    echo "Error: Filename and job_name are required." >&2
    return 1
  fi

  # Check if the YAML file exists
  if [[ ! -f "$filename" ]]; then
    echo "Error: File '$filename' does not exist." >&2
    return 1
  fi

  # Gather all existing job_names into an array
  local job_names
  job_names=$(yq eval '.scrape_configs[].job_name' "$filename" 2>/dev/null)

  # Check if the job_name exists in the array
  if echo "$job_names" | grep -qx "$job_name"; then
    return 0 # Key exists
  else
    return 1 # Key does not exist
  fi
}

# Main execution
filename="example.yaml"

# Scrape Config JSON
traefik_scrape_config="$(create_scrape_config --job_name "traefik" --targets "traefik:8082,traefik:8083")"

node_scrape_config="$(create_scrape_config --job_name "node_exporter" \
  --metrics_path "/custom/metrics" \
  --honor_timestamps "false" \
  --honor_labels "true" \
  --scrape_interval "10s" \
  --targets "node1:9100,node2:9100")"

# Add scrape_config to the file
add_scrape_config "$filename" "$traefik_scrape_config"
add_scrape_config "$filename" "$node_scrape_config"

check_existing_job_name "example.yaml" "example_job"
