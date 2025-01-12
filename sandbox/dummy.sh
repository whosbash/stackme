#!/bin/bash

manage_prometheus_config() {
    local file_path=$1    # File path for the Prometheus configuration
    shift                 # Shift to access remaining arguments as targets
    local new_targets=("$@") # New targets passed as arguments

    # If the file does not exist, create a new one with the provided targets
    if [[ ! -f "$file_path" ]]; then
        echo "File does not exist. Creating a new Prometheus configuration file."
        cat <<EOL > "$file_path"
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
  - static_configs:
    - targets: []
    scheme: http
    timeout: 10s
    api_version: v2
scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets: [$(printf '"%s",' "${new_targets[@]}" | sed 's/,$//')]
EOL
        info "Prometheus configuration file created at: $file_path"
        return
    fi

    info "File exists. Checking for duplicate targets and appending new targets if needed."

    # Extract current targets from the file
    current_targets=$(grep -oP '(?<=- targets: \[).*(?=\])' "$file_path" | tr -d '"')

    # Deduplicate targets by combining current and new, ensuring uniqueness
    combined_targets=($(echo "${current_targets[@]}" "${new_targets[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # Replace the targets line in the configuration file
    sed -i.bak "/- targets: \[/c\  - targets: [$(printf '"%s",' "${combined_targets[@]}" | sed 's/,$//')]" "$file_path"

    info "Updated Prometheus configuration file at: $file_path"
}

# Usage
# Replace the target URLs with your actual targets
manage_prometheus_config "./prometheus.yml" "http://localhost:9090" "http://localhost:8080"
cat './prometheus.yml'
manage_prometheus_config "./prometheus.yml" "http://localhost:9100" "http://localhost:9090"
cat './prometheus.yml'