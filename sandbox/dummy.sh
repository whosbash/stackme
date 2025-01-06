#!/bin/bash

# Function to display machine specs
generate_machine_specs() {
  echo "Machine Specifications"
  echo "======================="

  # Basic Information
  echo "Hostname: $(hostname)"
  echo "Operating System: $(lsb_release -d | cut -f2)"
  echo "Kernel Version: $(uname -r)"

  # Processor (CPU)
  echo "Model: $(lscpu | grep 'Model name' | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')"
  echo "Cores: $(lscpu | grep '^CPU(s):' | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')"
  echo "Threads: $(lscpu | grep '^Thread(s) per core:' | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')"
  echo "Clock Speed: $(lscpu | grep 'MHz' | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//') MHz"

  # Memory (RAM)
  echo "Total: $(free -h | grep Mem: | awk '{print $2}')"

  # Storage
  echo "Disk Usage:"
  df -h --output=source,fstype,size,used,avail,pcent | grep -E '^/dev'

  # GPU
  if command -v lspci &>/dev/null; then
    echo "$(lspci | grep -i 'vga\|3d\|2d')"
  else
    echo "lspci command not found. GPU info unavailable."
  fi

  # Network
  echo "Ethernet: $(ip -4 addr show | grep 'state UP' -A2 | grep inet | awk '{print $2}')"
  echo "Wi-Fi: $(nmcli device status | grep wifi | awk '{print $1, $3, $4}')"

  # Virtualization and Containers
  if [[ $(lscpu | grep Virtualization) ]]; then
    echo "Virtualization: Enabled ($(lscpu | grep Virtualization | awk '{print $2}') supported)"
  else
    echo "Virtualization: Not supported or disabled"
  fi
  echo "Docker Version: $(docker --version 2>/dev/null || echo "Not installed")"

  # Power (if laptop)
  if command -v upower &>/dev/null; then
    upower -i $(upower -e | grep BAT) | grep -E "state|to full|percentage"
  else
    echo "Battery information unavailable."
  fi

  echo -e "\nSpecifications collected successfully."
}

# Run the function
generate_machine_specs
