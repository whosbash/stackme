#!/bin/bash

# Enable error handling
set -e

######################################### BEGIN OF CONSTANTS ######################################

# Define colors with consistent names
declare -A COLORS=(
  [yellow]="\e[33m"
  [light_yellow]="\e[93m"
  [green]="\e[32m"
  [light_green]="\e[92m"
  [white]="\e[97m"
  [beige]="\e[93m"
  [red]="\e[91m"
  [light_red]="\e[31m"
  [blue]="\e[34m"
  [light_blue]="\e[94m"
  [cyan]="\e[36m"
  [light_cyan]="\e[96m"
  [magenta]="\e[35m"
  [light_magenta]="\e[95m"
  [black]="\e[30m"
  [gray]="\e[90m"
  [dark_gray]="\e[37m"
  [light_gray]="\x1b[38;5;245m"
  [orange]="\x1b[38;5;214m"
  [purple]="\x1b[38;5;99m"
  [pink]="\x1b[38;5;200m"
  [brown]="\x1b[38;5;94m"
  [teal]="\x1b[38;5;80m"
  [gold]="\x1b[38;5;220m"
  [lime]="\x1b[38;5;154m"
  [reset]="\e[0m"
)

# Define text styles
declare -A STYLES=(
  [bold]="\e[1m"
  [dim]="\e[2m"
  [italic]="\e[3m"
  [underline]="\e[4m"
  [hidden]="\e[8m"
  [reverse]="\e[7m"
  [strikethrough]="\e[9m"
  [double_underline]="\e[21m"
  [overline]="\x1b[53m"
  [bold_italic]="\e[1m\e[3m"
  [underline_bold]="\e[4m\e[1m"
  [dim_italic]="\e[2m\e[3m"
  [reset]="\e[0m"
)

# Global variables
HAS_TIMESTAMP=true
DEFAULT_SERVER_NAME="swarm_server"
DEFAULT_NETWORK="swarm_network"
DEFAULT_TYPE='info'
ITEMS_PER_PAGE=10
HEADER_LENGTH=120

########################################## END OF CONSTANTS #######################################

################################ BEGIN OF GENERAL UTILITARY FUNCTIONS #############################

# Function to decode JSON and base64
query_json64() {
  local item="$1"
  local field="$2"
  echo "$item" | base64 --decode | jq -r "$field" || {
    error "Invalid JSON or base64 input!"
    return 1
  }
}

# Function to generate a random string
random_string() {
  local length="${1:-16}"

  local word="$(openssl rand -hex $length)"
  echo "$word"
}

mask_string() {
  local input_string="$1"
  local unmask_length="${2:-4}" # Default to showing last 4 characters
  local mask_char="${3:-*}"    # Default mask character: '*'

  if [[ -z "$input_string" ]]; then
    echo "Input string is required."
    return 1
  fi

  local masked_length=$(( ${#input_string} - unmask_length ))
  if [[ $masked_length -le 0 ]]; then
    echo "$input_string" # Return the original string if it's shorter than the unmask length
    return 0
  fi

  local masked_part=$(printf "%${masked_length}s" | tr ' ' "$mask_char")
  local unmasked_part="${input_string: -$unmask_length}"

  echo "${masked_part}${unmasked_part}"
}

# Function to send a test email using swaks
send_email() {
    local from_email=$1
    local to_email=$2
    local server=$3
    local port=$4
    local user=$5
    local pass=$6
    local subject=$7
    local body=$8

    info "Sending test email..."

    # Attempt to send the email using swaks and capture output and error details
    local output
    output=$(swaks \
        --to "$to_email" \
        --from "$from_email" \
        --server "$server" \
        --port "$port" \
        --auth LOGIN --auth-user "$user" \
        --auth-password "$pass" \
        --tls \
        --header "Subject: $subject" \
        --header "Content-Type: text/html; charset=UTF-8" \
        --data "Content-Type: text/html; charset=UTF-8\n\n$body" 2>&1)

    # Capture the exit status of the swaks command
    local status=$?

    # Check if the email was sent successfully
    if [ $status -eq 0 ]; then
        success "Test email sent successfully to $to_email."
    else
        error "Failed to send test email. Details: $output"
        exit $status
    fi
}

# Function to extract variables from a string without curly braces
extract_variables() {
  local compose_string="$1"
  echo "$compose_string" | grep -oE '\{\{[a-zA-Z0-9_]+\}\}' | sed 's/[{}]//g' | sort -u
}

# Function to replace variables in a template
replace_mustache_variables() {
  local template="$1"
  declare -n variables="$2" # Associative array passed by reference

  # Iterate over the variables and replace each instance of {{KEY}} in the template
  for key in "${!variables[@]}"; do
    value="${variables[$key]}"
    
    # Escape special characters in the value to prevent issues with sed (if needed)
    value_escaped=$(printf '%s' "$value" | sed 's/[&/\]/\\&/g')

    # Replace instances of {{KEY}} in the template
    template="${template//\{\{$key\}\}/$value_escaped}"
  done

  # Output the substituted template
  echo "$template"
}

# Function to validate empty values
validate_empty_value() {
  local value="$1"
  if [[ -z "$value" ]]; then
    echo "The value is empty or not set."
    return 1
  else
    return 0
  fi
}

# Function to validate name values with extensive checks
validate_name_value() {
  local value="$1"

  # Check if the name starts with a number
  if [[ "$value" =~ ^[0-9] ]]; then
    echo "The value '$value' should not start with a number."
    return 1
  fi

  # Check if the name contains invalid characters
  if [[ ! "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9@#\&*_-]*$ ]]; then
    allowed_chars="'@', '#', '&', '*', '_', '-'"
    criterium="Only letters, numbers, and the characters $allowed_chars are allowed."
    error_message="The value '$value' contains invalid characters."
    echo "$error_message $criterium"
    return 1
  fi

  # Check if the name is too short (less than 3 characters)
  if ((${#value} < 3)); then
    echo "The value '$value' is too short. It must be at least 3 characters long."
    return 1
  fi

  # Check if the name is too long (more than 50 characters)
  if ((${#value} > 50)); then
    echo "The value '$value' is too long. It must be at most 50 characters long."
    return 1
  fi

  # Check for spaces in the name
  if [[ "$value" =~ [[:space:]] ]]; then
    echo "The value '$value' contains spaces. Spaces are not allowed."
    return 1
  fi

  # If all validations pass
  return 0
}

# Function to validate email values
validate_email_value() {
  local value="$1"

  # Check if the value matches an email pattern
  if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "The value '$value' is not a valid email address."
    return 1
  fi

  return 0
}

# Function to validate url suffix
validate_url_suffix() {
  local value="$1"

  # Regular expression to match the part after "https://"
  local url_suffix_regex="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(/.*)?$"

  # Check if the value matches the suffix pattern
  if [[ ! "$value" =~ $url_suffix_regex ]]; then
    echo "The value '$value' is not a valid URL suffix (domain and optional path)."
    return 1
  fi

  return 0
}

# Function to validate integer values
validate_integer_value() {
  local value="$1"

  # Check if the value is an integer (allow negative and positive integers)
  if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
    echo "The value '$value' is not a valid integer."
    return 1
  fi

  return 0
}

# Function to validate port availability
validate_port_availability() {
  local port="$1"

  # Check if the port is a valid number between 1 and 65535
  if [[ ! "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
    explanation="Port numbers must be between 1 and 65535."
    echo "The value '$port' is not a valid port number. $explanation"
    return 1
  fi

  # Use netcat (nc) to check if the port is open on localhost
  # The -z flag checks if the port is open (without sending data)
  # The -w1 flag specifies a timeout of 1 second
  nc -z -w1 127.0.0.1 "$port" 2>/dev/null

  # Check the result of the netcat command
  if [[ $? -eq 0 ]]; then
    echo "The port '$port' is already in use."
    return 1
  else
    echo "The port '$port' is available."
    return 0
  fi
}

# Function to validate SMTP server connectivity
validate_smtp_server() {
    local server=$1
    if ping -c 1 "$server" >/dev/null 2>&1; then
        echo "SMTP server $server is reachable."
    else
        echo "Unable to reach SMTP server $server. Please check the server address."
        exit 1
    fi
}

# Function to validate SMTP port
validate_smtp_port() {
    local server=$1
    local port=$2
    if nc -z "$server" "$port" >/dev/null 2>&1; then
        echo "SMTP port $port is open on $server."
    else
        echo "SMTP port $port is not reachable on $server. Please check the port."
        exit 1
    fi
}

# Function to find the next available port
find_next_available_port() {
  local trigger_port="$1"
  local current_port="$trigger_port"

  # Check if the trigger port is valid
  validate_port_availability "$current_port" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    # Return the trigger port if it's available
    echo "$current_port"
    return 0
  fi

  # If trigger port is in use, try subsequent ports
  while true; do
    ((current_port++)) # Increment the port number

    # Ensure the port number stays within the valid range (1-65535)
    if ((current_port > 65535)); then
      echo "No available ports found in the valid range."
      return 1
    fi

    # Check if the current port is available
    validate_port_availability "$current_port"
    if [[ $? -eq 0 ]]; then
      echo "$current_port" # Return the first available port
      return 0
    fi
  done
}

# Function to check if a package is already installed
is_package_installed() {
  local package="$1"
  dpkg -l | grep -q "$package"
}

# Function to run a command and display its output
command() {
  local command="$1"
  local current_step="$2"
  local total_steps="$3"
  local step_message="$4"

  local log_file="/tmp/log.txt"
  local allow_dangerous_commands="${5:no}"

  # Ensure we don't run any destructive commands unintentionally unless explicitly allowed
  if [[ "$allow_dangerous_commands" != "yes" && "$command" =~ (rm|mv|dd|reboot|shutdown) ]]; then
    error "This function does not support potentially destructive commands."
    return 1
  fi

  # Format and display step message
  step_info $current_step $total_steps "$step_message"

  # Run the command and process its output line by line, logging both stdout and stderr
  {
    DEBIAN_FRONTEND=noninteractive $command
  } 2>&1 | while IFS= read -r line; do
    # Format and display each line as it is outputted
    if [[ "$line" =~ ^(Hit|Reading|Fetched|Get|Reading|Building|Done|Fetched).* ]]; then
      format "info" "$line"
    else
      format "normal" "$line"
    fi
  done | tee "$log_file"

  # Get the exit status of the last command run
  exit_code=$?
  handle_exit $? $current_step $total_steps "$step_message"

  # Clean up the log file if needed
  rm -f "$log_file"

  return $exit_code
}

# Function to wait for a specified number of seconds
wait_secs() {
  local seconds=$1
  sleep "$seconds"
}

# Function to extract values from the collection output
extract_value_from_json() {
  local json_data="$1"
  local key="$2"
  echo "$json_data" | jq -r ".[] | select(.name == \"$key\") | .value"
}

# Function to clear previous line
clear_line() {
  tput cuu1 # Move the cursor up one line
  tput el   # Clear the current line
}

# Function to clear multiple previous lines
clear_lines() {
  # Number of lines to clear
  local lines=$1
  for i in $(seq 1 "$lines"); do
    clear_line
  done
}

# Function to install a package
install_package() {
  local command="$1"
  local package="$2"

  # Check if the package is already installed
  if is_package_installed "$package"; then
    warning "Package '$package' is already installed, skipping..."
  else
    info "Starting installation of package: $package"

    # Try to install the package and check for success
    if ! DEBIAN_FRONTEND=noninteractive $command install "$package" -yq >/dev/null 2>&1; then
      error "Failed to install package: $package. Check logs for more details."
      exit 1
    else
      success "Successfully installed package: $package"
    fi
  fi
}

# Function to install all packages and track progress
install_all_packages() {
  # The list of packages to install (passed as arguments)
  local command="$1"
  shift
  local packages=("$@")
  local total_packages=${#packages[@]}
  local installed_count=0

  # Install each package
  for package in "${packages[@]}"; do
    install_package "$command" "$package"
    installed_count=$((installed_count + 1))
  done
}

# Function to wait apt process lock to free
wait_apt_lock() {
  local attempt_interval=${1-5}
  local max_wait_time=${2-60}

  # Wait for the lock to be released or forcefully remove it if needed
  wait_time=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    if [ "$wait_time" -ge "$max_wait_time" ]; then
      error "APT lock held for too long. Attempting to kill process."
      lock_pid=$(lsof /var/lib/dpkg/lock-frontend | awk 'NR==2 {print $2}')
      if [[ -n "$lock_pid" ]]; then
        kill -9 "$lock_pid"
        info "Killed process $lock_pid holding APT lock."
      fi
    fi
    info "Waiting for APT lock to be released..."
    sleep $WAIT_INTERVAL
    wait_time=$((wait_time + attempt_interval))
  done
}

# Function to strip existing ANSI escape sequences (colors and styles) from a string
strip_ansi() {
  pattern='s/\x1b\[[0-9;]*[mK]//g'
  echo -e "$1" | sed "$pattern"
}

# Function to trim leading/trailing spaces
trim() {
  pattern='s/^ *//;s/ *$//'
  echo "$1" | sed "$pattern"
}

# Function to apply color and style to a string, even if it contains existing color codes
colorize() {
  local text="$1"
  local color_name=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  local style_name=$(echo "$3" | tr '[:upper:]' '[:lower:]')

  # Remove any existing ANSI escape sequences (colors or styles) from the text
  text=$(strip_ansi "$text")

  # Get color code, default to reset if not found
  local color_code="${COLORS[$color_name]:-${COLORS[reset]}}"

  # If no style name is provided, use "reset" style as default
  if [[ -z "$style_name" ]]; then
    local style_code="${STYLES[reset]}"
  else
    local style_code="${STYLES[$style_name]:-${STYLES[reset]}}"
  fi

  # Print the text with the chosen color and style
  echo -e "${style_code}${color_code}${text}${STYLES[reset]}${COLORS[reset]}"
}

get_status_icon() {
  local type="$1"

  case "$type" in
  "success") echo "🌟" ;;   # Bright star for success
  "error") echo "🔥" ;;     # Fire icon for error
  "warning") echo "⚠️" ;;   # Lightning for warning
  "info") echo "💡" ;;      # Light bulb for info
  "highlight") echo "🌈" ;; # Rainbow for highlight
  "debug") echo "🔍" ;;     # Magnifying glass for debug
  "critical") echo "💀" ;;  # Skull for critical
  "note") echo "📌" ;;      # Pushpin for note
  "important") echo "⚡" ;; # Rocket for important
  "wait") echo "⌛" ;;      # Hourglass for waiting
  "question") echo "🤔" ;;  # Thinking face for question
  "celebrate") echo "🎉" ;; # Party popper for celebration
  "progress") echo "📈" ;;  # Upwards chart for progress
  "failure") echo "💔" ;;   # Broken heart for failure
  "tip") echo "🍀" ;;       # Four-leaf clover for additional success
  *) echo "🌀" ;;           # Cyclone for undefined type
  esac
}

# Function to get the color code based on the message type
get_status_color() {
  local type="$1"

  case "$type" in
  "success") echo "green" ;;          # Green for success
  "error") echo "light_red" ;;        # Light Red for error
  "warning") echo "yellow" ;;         # Yellow for warning
  "info") echo "teal" ;;              # White for info
  "highlight") echo "cyan" ;;         # Cyan for highlight
  "debug") echo "blue" ;;             # Blue for debug
  "critical") echo "light_magenta" ;; # Light Magenta for critical
  "note") echo "pink" ;;              # Gray for note
  "important") echo "gold" ;;         # Orange for important
  "wait") echo "light_yellow" ;;      # Light Yellow for waiting
  "question") echo "purple" ;;        # Purple for question
  "celebrate") echo "green" ;;        # Green for celebration
  "progress") echo "lime" ;;          # Blue for progress
  "failure") echo "light_red" ;;      # Red for failure
  "tip") echo "light_cyan" ;;         # Light Green for tips
  *) echo "white" ;;                  # Default to white for unknown types
  esac
}

# Function to get the style code based on the message type
get_status_style() {
  local type="$1"

  case "$type" in
  "success") echo "bold" ;;                      # Bold for success
  "info") echo "italic" ;;                       # Italic for info
  "error") echo "bold,italic" ;;                 # Bold and italic for errors
  "critical") echo "bold,underline" ;;           # Bold and underline for critical
  "warning") echo "italic" ;;                    # Underline for warnings
  "highlight") echo "bold,underline" ;;          # Bold and underline for highlights
  "wait") echo "dim,italic" ;;                   # Dim and italic for pending
  "important") echo "bold,underline,overline" ;; # Bold, underline, overline for important
  "question") echo "italic,underline" ;;         # Italic and underline for questions
  "celebrate") echo "bold" ;;                    # Bold for celebration
  "progress") echo "italic" ;;                   # Italic for progress
  "failure") echo "bold,italic" ;;               # Bold and italic for failure
  "tip") echo "bold,italic" ;;                   # Bold and italic for tips
  *) echo "normal" ;;                            # Default to normal style for unknown types
  esac
}

# Function to colorize a message based on its type
colorize_by_type() {
  local type="$1"
  local text="$2"

  colorize "$text" "$(get_status_color "$type")" "$(get_status_style "$type")"
}

format() {
  local type="$1"                            # Message type (success, error, etc.)
  local text="$2"                            # Message text
  local has_timestamp="${3:-$HAS_TIMESTAMP}" # Option to display timestamp (default is false)

  # Get icon based on status
  local icon
  icon=$(get_status_icon "$type")

  # Add timestamp if enabled
  local timestamp=""
  if [ "$has_timestamp" = true ]; then
    timestamp="[$(date '+%Y-%m-%d %H:%M:%S')] "
    # Only colorize the timestamp
    timestamp="$(colorize "$timestamp" "$(get_status_color "$type")" "normal")"
  fi

  # Colorize the main message
  local colorized_message
  colorized_message="$(colorize_by_type "$type" "$text")"

  # Display the message with icon, timestamp, and colorized message
  echo -e "$icon $timestamp$colorized_message"
}

# Function to format an array of messages
format_array() {
  local type="$1"
  local -n arr="$2"  # Use reference to the array

  for i in "${!arr[@]}"; do
    # Apply format to each message in the array
    arr[$i]=$(format "$type" "${arr[$i]}")
  done
}


# Function to display a message with improved formatting
display() {
  local type="$1"
  local text="$2"
  local timestamp="${3:-$HAS_TIMESTAMP}"

  echo -e "$(format "$type" "$text" $timestamp)"
}

# Function to process all lines in parallel and maintain order
display_parallel() {
  local -n _lines=$1  # Array passed by reference
  local -a pids=()   # Array to hold process IDs

  # Process each line in parallel
  for i in "${!_lines[@]}"; do
    line="${_lines[i]}"
    {
      echo -e "$line"
    } &
    pids+=($!)  # Store the process ID for each background process
  done

  # Wait for all processes to finish
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

# Function to process all lines sequentially and ensure ordered output
display_sequential() {
  local -n _lines=$1  # Array passed by reference
  for line in "${_lines[@]}"; do
    echo -e "$line" >&2
  done
}

# Function to display success formatted messages
success() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'success' "$message" $timestamp >&2
}

# Function to display error formatted messages
error() {
  local message="$1"                       # Step message
  local timestamp=""${2:-$HAS_TIMESTAMP}"" # Optional timestamp flag
  display 'error' "$message" $timestamp >&2
}

# Function to display warning formatted messages
warning() {
  local message="$1"                       # Step message
  local timestamp=""${2:-$HAS_TIMESTAMP}"" # Optional timestamp flag
  display 'warning' "$message" $timestamp >&2
}

# Function to display info formatted messages
info() {
  local message="$1"                       # Step message
  local timestamp=""${2:-$HAS_TIMESTAMP}"" # Optional timestamp flag
  display 'info' "$message" $timestamp >&2
}

# Function to display highlight formatted messages
highlight() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'highlight' "$message" $timestamp >&2
}

# Function to display debug formatted messages
debug() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'debug' "$message" $timestamp >&2
}

# Function to display critical formatted messages
critical() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'critical' "$message" $timestamp >&2
}

# Function to display note formatted messages
note() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'note' "$message" $timestamp >&2
}

# Function to display important formatted messages
important() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'important' "$message" $timestamp >&2
}

# Function to display wait formatted messages
holdon() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'wait' "$message" $timestamp >&2
}

# Function to display wait formatted messages
question() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'question' "$message" $timestamp >&2
}

# Function to display celebrate formatted messages
celebrate() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'celebrate' "$message" $timestamp >&2
}

# Function to display progress formatted messages
progress() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'progress' "$message" $timestamp >&2
}

# Function to display failure formatted messages
failure() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'failure' "$message" $timestamp >&2
}

# Function to display tip formatted messages
tip() {
  local message="$1"                     # Step message
  local timestamp="${2:-$HAS_TIMESTAMP}" # Optional timestamp flag
  display 'tip' "$message" $timestamp >&2
}

# Function to display a step with improved formatting
step() {
  local current_step="$1"                # Current step number
  local total_steps="$2"                 # Total number of steps
  local message="$3"                     # Step message
  local type="${4:-DEFAULT_TYPE}"        # Status type (default to 'info')
  local timestamp="${5:-$HAS_TIMESTAMP}" # Optional timestamp flag

  # If 'timestamp' is passed as an argument, prepend the timestamp to the message
  if [ -n "$timestamp" ]; then
    local formatted_message=$(format "$type" "$step_message" true)
  else
    local formatted_message=$(format "$type" "$step_message" false)
  fi

  # Format the step message with the specified color and style
  local message="[$current_step/$total_steps] $message"
  formatted_message=$(format "$type" "$message" $timestamp)

  # Print the formatted message with the icon and message
  echo -e "$formatted_message" >&2
}

# Function to display step info message
step_info() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "info" $has_timestamp
}

# Function to display step success message
step_success() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "success" $has_timestamp
}

# Function to display step failure message
step_failure() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "failure" $has_timestamp
}

# Function to display step error message
step_error() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "error" $has_timestamp
}

# Function to display step warning message
step_warning() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "warning" $has_timestamp
}

# Function to display step success message
step_progress() {
  local current=$1
  local total=$2
  local message=$3
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "progress" $has_timestamp
}

boxed_text() {
  local word=${1:-"Hello"}                        # Default word to render
  local text_style=${2:-"highlight"}              # Default text style
  local border_style=${3:-"simple"}               # Default border style
  local font=${4:-"slant"}                        # Default font
  local min_width=${5:-$(($(tput cols) - 28))}    # Default minimum width

  # Ensure `figlet` exists
  if ! command -v figlet &>/dev/null; then
    error "'figlet' command not found. Please install it to use this function."
    return 1
  fi

  # Define the border styles
  declare -A border_styles=(
  ["simple"]="- - | | + + + +"
  ["asterisk"]="* * * * * * * *"
  ["equal"]="= = | | + + + +"
  ["hash"]="# # # # # # # #"
  ["dotted"]=". . . . . . . ."
  ["starred"]="* * * * * * * *"
  ["boxed-dashes"]="- - - - - - - -"
  ["wave"]="~ ~ ~ ~ ~ ~ ~ ~"
  ["angled"]="/ / \\ \\ / \\ \\ /"
  ["arrowed"]="< > ^ v < > ^ v"
  ["zigzag"]="z z Z Z z Z Z z"
  ["spiky"]="x x x x X X X X"
  ["none"]="         "
  )

  # Extract the border characters
  IFS=' ' read -r \
    top_fence bottom_fence left_fence right_fence \
    top_left_corner top_right_corner \
    bottom_left_corner bottom_right_corner <<<\
     "${border_styles[$border_style]:-${border_styles["simple"]}}"

  # Generate ASCII art
  local ascii_art=$(figlet -f "$font" "$word")
  local art_width=$(echo "$ascii_art" | head -n 1 | wc -c)
  art_width=$((art_width - 1))  # Subtract newline

  # Get terminal width and calculate box width
  local terminal_width=$(tput cols)
  local total_width=$((min_width > art_width ? min_width : art_width))
  total_width=$((total_width > (terminal_width - 2) ? (terminal_width - 2) : total_width))

  # Generate borders
  local top_border="${top_left_corner}$(\
    printf "%-${total_width}s" | tr ' ' "$top_fence"\
  )${top_right_corner}"
  fmt_top_border="$(format "$text_style" "$top_border")"
  
  local bottom_border="${bottom_left_corner}$(\
    printf "%-${total_width}s" | tr ' ' "$bottom_fence"\
  )${bottom_right_corner}"
  fmt_bottom_border="$(format "$text_style" "$bottom_border")"

  # Buffer all lines to an array
  local -a lines=()

  # Add the top border
  lines+=("$fmt_top_border")

  # Add the ASCII art with borders
  while IFS= read -r line; do
    local padding=$(( (total_width - ${#line}) / 2 ))
    line="$(\
      printf "%s%*s%s%*s%s" \
      "$left_fence" "$padding" "" "$line" "$padding" "" "$right_fence"\
    )"
    fmt_line="$(format "$text_style" "$line")"
    lines+=("$fmt_line")
  done <<< "$ascii_art"

  # Add the bottom border
  fmt_bottom_border=$(\
    format "$text_style" "$bottom_border"\
  )
  lines+=("$fmt_bottom_border")

  # Display the lines in parallel
  display_parallel lines
}

header() {
  local word=${1:-"Hello"}                      # Default word to render
  local text_style=${2:-"highlight"}            # Default text style
  local border_style=${3:-"simple"}             # Default border style
  local font=${4:-"slant"}                      # Default font
  local min_width=${5:-$(($(tput cols) - 28))}  # Default minimum width

  boxed_text "$word" "$text_style" "$border_style" "$font" "$min_width"
}

# Function to convert associative array to JSON format
convert_array_to_json() {
  # Use reference to the associative array
  local -n dict=$1
  json_output="{"

  for key in "${!dict[@]}"; do
    value="${dict[$key]}"
    json_output+="\"$key\": \"$value\", "
  done

  # Remove trailing comma if present
  json_output="${json_output%, }"
  json_output+="}"

  echo "$json_output"
}

# Function to convert each element of a JSON array to base64
convert_json_array_to_base64_array() {
  local json_array="$1"
  # Convert each element of the JSON array to base64 using jq
  echo "$json_array" | jq -r '.[] | @base64'
}

search_on_json_array() {
  local json_array_string="$1"
  local search_key="$2"
  local search_value="$3"

  # Validate JSON
  if ! echo "$json_array_string" | jq . >/dev/null 2>&1; then
    echo "Invalid JSON array."
    return 1
  fi

  # Search for an object in the array with the specified key-value pair
  if [[ -n "$search_key" && -n "$search_value" ]]; then
    local matched_item
    matched_item=$(\
      echo "$json_array_string" | \
      jq -c --arg key "$search_key" --arg value "$search_value" \
      '.[] | select(.[$key] == $value)'\
    )

    if [[ -n "$matched_item" ]]; then
      echo "$matched_item"
      return 0
    else
      echo "No matching item found for key '$search_key' and value '$search_value'."
      return 1
    fi
  fi
}

# Function to validate the input and return errors for invalid fields
validate_value() {
  local value="$1"
  local validate_fn="${2-validate_empty_value}"

  # Capture the output from the validation function
  error_message=$($validate_fn "$value")

  # Check the return code of the validation function
  if [[ $? -ne 0 ]]; then
    # If validation failed, capture and print the error message
    echo "$error_message"
    return 1
  fi
  return 0
}

create_error_item() {
  local name="$1"
  local message="$2"
  local validate_fn="$3"

  # Find the line number of the function definition by parsing the current script
  local line_number
  pattern="^[[:space:]]*(function[[:space:]]+|)[[:space:]]*$validate_fn[[:space:]]*\(\)"
  line_number=$(grep -n -E "$pattern" "$BASH_SOURCE" | cut -d: -f1)

  # Escape the message for jq
  local escaped_message
  escaped_message=$(printf '%s' "$message" | jq -R .)

  # Create the error object using jq
  jq -n \
    --arg name "$name" \
    --arg value "$value" \
    --arg message "$escaped_message" \
    --arg line_number "$line_number" \
    --arg validate_fn "$validate_fn" \
    '{
        name: $name,
        message: ($message | fromjson),
        value: $value,
        line_number: $line_number,
        function: $validate_fn
    }'
}

# Function to create a collection item
create_prompt_item() {
  local name="$1"
  local label="$2"
  local description="$3"
  local value="$4"
  local required="$5"
  local validate_fn="${6-validate_empty_value}"

  # Check if the item is required and the value is empty
  if [[ "$required" == "yes" && -z "$value" ]]; then
    error_message="The value for '$name' is required but is empty."
    error_obj=$(create_error_item "$name" "$error_message" "${FUNCNAME[0]}")
    echo "$error_obj"
    return 1
  fi

  # Validate the value using the provided validation function
  validation_output=$(validate_value "$value" "$validate_fn" 2>&1)

  # If validation failed, capture the validation message
  if [[ $? -ne 0 ]]; then
    # Validation failed, use the validation message captured in validation_output
    error_obj=$(create_error_item "$name" "$validation_output" "$validate_fn")
    echo "$error_obj"
    return 1
  fi

  # Build the JSON object by echoing the data and piping it to jq for proper escaping
  item_json=$(echo "
    {
        \"name\": \"$name\",
        \"label\": \"$label\",
        \"description\": \"$description\",
        \"value\": \"$value\",
        \"required\": \"$required\",
        \"validate_fn\": \"$validate_fn\"
    }" | jq .)

  # Check if jq creation was successful
  if [[ $? -ne 0 ]]; then
    echo "Failed to create JSON object"
    return 1 # Return an error code
  fi

  # Return the JSON object
  echo "$item_json"
}

# Function to prompt for user input
prompt_for_input() {
  local item="$1"

  name=$(query_json64 "$item" '.name')
  label=$(query_json64 "$item" '.label')
  description=$(query_json64 "$item" '.description')
  required=$(query_json64 "$item" '.required')
  default_value=$(query_json64 "$item" '.default_value')

  # Assign the 'required' label based on the 'required' field value
  if [[ "$required" == "yes" ]]; then
    required_label="required"
  else
    required_label="optional"
  fi

  local general_info="Prompting $required_label variable $name: $description"
  local explanation="Enter a value, type 'q' to quit"

  # Notify the user if a default value is provided, only if it is non-empty
  if [[ -n "$default_value" && "$default_value" != "null" ]]; then
    explanation="$explanation or Enter to use the default value '$default_value'"
  fi

  local prompt="$explanation: "
  question "$general_info"
  fmt_prompt=$(format 'question' "$prompt")

  while true; do
    read -rp "$fmt_prompt" value
    if [[ "$value" == "q" ]]; then
      echo "q"
      return
    fi

    # Use default value if input is empty and default is provided
    if [[ -z "$value" && -n "$default_value" && "$default_value" != "null" ]]; then
      value="$default_value"
    fi

    if [[ -n "$value" || "$required" == "no" ]]; then
      echo "$value"
      return
    else
      warning "$label is a required field. Please enter a value."
    fi
  done
}

# Function to collect and validate information
collect_prompt_info() {
  local items="$1"
  json_array="[]"

  for item in $(convert_json_array_to_base64_array "$items"); do
    value=$(prompt_for_input "$item")
    if [[ "$value" == "q" ]]; then
      echo "[]"
      return 0
    fi

    json_object=$(
      create_prompt_item \
        "$(query_json64 "$item" '.name')" \
        "$(query_json64 "$item" '.label')" \
        "$(query_json64 "$item" '.description')" \
        "$value" \
        "$(query_json64 "$item" '.required')" \
        "$(query_json64 "$item" '.validate_fn')"
    )

    json_array=$(append_to_json_array "$json_array" "$json_object")
  done

  echo "$json_array"
}

confirm_and_modify_prompt_info() {
  local json_array="$1"

  while true; do
    # Display collected information to stderr (for terminal)
    info "Provided values: "
    max_length=$(
      echo "$json_array" |
        jq -r '.[] | .name' |
        awk '{ print length }' |
        sort -nr | head -n1
    )

    formatted_length=$((max_length + PADDING))

    # Display the collected information with normalized name length
    echo "$json_array" |
      jq -r '.[] | "\(.name): \(.value)"' |
      while IFS=: read -r name value; do
        printf "  %-*s: %s\n" "$formatted_length" "$name" "$value" >&2
      done

    # Ask for confirmation (stderr)
    options="y) Yes, n) No, q) Quit, ? Show options"
    confirmation_msg="$(
      format "question" "Is the information correct? ($options) "
    )"
    read -rp "$confirmation_msg" confirmation

    case "$confirmation" in
    y)
      # Validate the confirmed data before returning
      for item in $(echo "$json_array" | jq -r '.[] | @base64'); do
        _jq() {
          echo "$item" | base64 --decode | jq -r "$1"
        }

        value=$(_jq '.value')
        validate_fn=$(_jq '.validate_fn')

        # Call validate_value function (ensure you have this function implemented)
        validation_output=$(validate_value "$value" "$validate_fn" 2>&1)

        if [[ $? -ne 0 ]]; then
          warning "Validation failed for '$value': $validation_output"
          echo "$json_array" | jq -r ".[] | select(.value == \"$value\")"
          continue # Continue looping to re-modify the invalid value
        fi
      done

      # If no validation failed, output the final JSON to stdout (for file capture)
      echo "$json_array"
      break
      ;;
    n)
      # Ask for the field to modify (stderr)
      field_query="$(
        format "question" "Which field would you like to modify? "
      )"
      read -rp "$field_query" field_to_modify

      # Check if the field exists in the JSON and ask for modification
      current_value=$(
        echo "$json_array" |
          jq -r \
            --arg field "$field_to_modify" \
            '.[] | select(.name == $field) | .value'
      )

      if [[ -n "$current_value" ]]; then
        info "Current value for $field_to_modify: $current_value"

        new_value_query="$(format "question" "Enter new value: ")"
        read -rp "$new_value_query" new_value

        if [[ -n "$new_value" ]]; then
          # Validate new value
          pattern=".[] | select(.name == \"$field_to_modify\") | .validate_fn"
          validate_fn=$(echo "$json_array" | jq -r "$pattern")
          validation_output=$(validate_value "$new_value" "$validate_fn" 2>&1)

          if [[ $? -ne 0 ]]; then
            warning "Validation failed for '$new_value': $validation_output"
            continue
          fi

          # Modify the JSON by updating the value of the specified field
          json_array=$(
            echo "$json_array" |
              jq \
                --arg field "$field_to_modify" \
                --arg value "$new_value" \
                '(.[] | select(.name == $field) | .value) = $value'
          )
        else
          error "Value cannot be empty."
        fi
      else
        warning "Field '$field_to_modify' not found."
      fi
      ;;
    q)
      exit 0
      ;;
    ?)
      # Show the options description again
      info "Options:"
      info "  y) Yes - Confirm the information is correct"
      info "  n) No - Modify a field in the information"
      info "  q) Quit - Exit the program"
      info "  ?) Show options - Display available options"
      ;;
    *)
      error "Invalid input. Please enter 'y', 'n', or 'q'."
      ;;
    esac
  done
}

# Function to collect and validate information, then re-trigger collection for errors
run_collection_process() {
  local items="$1"
  local all_collected_info="[]"
  local has_errors=true

  # Keep collecting and re-requesting info for errors
  while [[ "$has_errors" == true ]]; do
    collected_info="$(collect_prompt_info "$items")"

    # If no values were collected, exit early
    handle_empty_collection "$collected_info"

    # Define the filter functions in jq format
    labels='.name and .label and .description and .value and .required'
    collection_item_filter=".[] | select($labels)"
    error_item_filter='.[] | select(.message and .function)'

    # Separate valid collection items and error objects
    valid_items=$(filter_items "$collected_info" "$collection_item_filter")
    error_items=$(filter_items "$collected_info" "$error_item_filter")

    # Ensure valid JSON formatting by stripping any unwanted characters
    valid_items_json=$(echo "$valid_items" | jq -c .)
    all_collected_info_json=$(echo "$all_collected_info" | jq -c .)

    # Merge valid items with previously collected information
    all_collected_info=$(add_json_objects "$all_collected_info" "$valid_items")

    # Step 1: Extract the names of items with errors from error_items
    error_names=$(echo "$error_items" | jq -r '.[].name' | jq -R -s .)

    # Step 2: Filter the original items to keep only those whose names match the error items
    pattern='[.[] | select(.name as $item_name | $error_names | index($item_name))]'
    items_with_errors=$(echo "$items" | jq --argjson error_names "$error_names" "$pattern")

    # Check if there are still errors left
    if [[ "$(echo "$error_items" | jq 'length')" -eq 0 ]]; then
      has_errors=false
    else
      # If there are still errors, re-trigger the collection process for error items only
      warning "Re-collecting information for items with errors..."
      display_error_items "$error_items"

      items="$items_with_errors"
    fi
  done

  # Step to sort the collected information by the original order (using 'name' for sorting)
  all_collected_info="$(
    sort_array_according_to_other_array "$all_collected_info" "$items" "name"
  )"

  # Return all collected and validated information
  confirmed_info="$(confirm_and_modify_prompt_info "$all_collected_info")"

  echo "$confirmed_info"
}

# Recursive function to validate JSON against a schema
validate_json_recursive() {
  local json="$1"
  local schema="$2"
  local parent_path="$3" # Track the JSON path for better error reporting
  local valid=true
  local errors=()

  # Extract required keys, properties, and additionalProperties from the schema
  local required_keys=$(echo "$schema" | jq -r '.required[]? // empty')
  local properties=$(echo "$schema" | jq -r '.properties // empty')

  jq_query='if has("additionalProperties") then .additionalProperties else true end'
  local additional_properties=$(echo "$schema" | jq -r "$jq_query")

  # Check if required keys are present
  for key in $required_keys; do
    if ! echo "$json" | jq -e ". | has(\"$key\")" >/dev/null; then
      errors+=("Missing required key: ${parent_path}${key}")
      valid=false
    fi
  done

  # Validate each property
  for key in $(echo "$properties" | jq -r 'keys[]'); do
    local expected_type
    local actual_type
    local sub_schema
    local value

    expected_type=$(echo "$properties" | jq -r ".\"$key\".type // empty")
    sub_schema=$(echo "$properties" | jq -c ".\"$key\"")
    value=$(echo "$json" | jq -c ".\"$key\"")
    actual_type=$(echo "$json" | jq -r ".\"$key\" | type // empty")

    if [ "$expected_type" = "object" ]; then
      if [ "$actual_type" = "object" ]; then
        validate_json_recursive "$value" "$sub_schema" "${parent_path}${key}."
      else
        errors+=(
          "Key '${parent_path}${key}' expected type 'object', but got '$actual_type'"
        )
        valid=false
      fi
    elif [ "$expected_type" = "array" ]; then
      if [ "$actual_type" = "array" ]; then
        items_schema=$(echo "$sub_schema" | jq -c '.items')
        array_length=$(echo "$value" | jq 'length')

        for ((i = 0; i < array_length; i++)); do
          element=$(echo "$value" | jq -c ".[$i]")
          element_type=$(echo "$element" | jq -r 'type') # Get type of element

          # Check the expected type for the array items and match with element type
          item_expected_type=$(echo "$items_schema" | jq -r '.type // empty')

          # Handle type mismatch in array elements
          if [ "$item_expected_type" != "$element_type" ]; then
            preamble="Array element ${parent_path}${key}[$i]"
            expected_message="expected type '$item_expected_type'"
            errors+=(
              "$preamble $expected_message, but got '$element_type'"
            )
            valid=false
          else
            # Continue validation for each array element recursively
            validate_json_recursive \
              "$element" "$items_schema" "${parent_path}${key}[$i]."
          fi
        done
      else
        errors+=("Key '${parent_path}${key}' expected type 'array', but got '$actual_type'")
        valid=false
      fi
    else
      # Handle specific cases for 'integer', 'string', 'number', etc.
      if [[ "$expected_type" == "integer" && "$actual_type" == "number" ]]; then
        # Check if the value is not an integer (i.e., it has a fractional part)
        if [[ $(echo "$value" | jq '. % 1 != 0') == "true" ]]; then
          errors+=("Key '${parent_path}${key}' expected type 'integer', but got 'number'")
          valid=false
        fi
      elif [ "$expected_type" != "$actual_type" ] && [ "$actual_type" != "null" ]; then
        # Handle if expected type does not match the actual type
        # Check if expected_type is an array of types, and if the
        # actual type matches any of them
        if [[ "$expected_type" =~ \[.*\] ]]; then
          # Expected type is a list of types (e.g., ["string", "number"])
          # Remove brackets and spaces
          expected_types=$(echo "$expected_type" | sed 's/[\[\]" ]//g')
          for type in $(echo "$expected_types" | tr ',' '\n'); do
            if [ "$type" == "$actual_type" ]; then
              valid=true
              break
            fi
          done

          key_value="Key '${parent_path}${key}'"
          if [ "$valid" = false ]; then
            expected_types="one of the types [${expected_types}]"
            errors+=("$key_value expected $expected_types, but got '$actual_type'")
            valid=false
          fi
        else
          errors+=("$key_value expected type '$expected_type', but got '$actual_type'")
          valid=false
        fi
      fi

      # Handle 'null' type
      if [ "$expected_type" = "null" ] && [ "$actual_type" != "null" ]; then
        errors+=("Key '${parent_path}${key}' expected type 'null', but got '$actual_type'")
        valid=false
      fi

      # Handle additional constraints
      handle_constraints "$value" "$sub_schema" "${parent_path}${key}" errors valid
    fi

  done

  # Handle additional properties when additionalProperties is false
  if [ "$additional_properties" = "false" ]; then
    for key in $(echo "$json" | jq -r 'keys[]'); do
      # Check if the key is not present in the properties of the schema
      if ! echo "$properties" | jq -e ". | has(\"$key\")" >/dev/null; then
        key_msg="Key '${parent_path}${key}'"
        errors+=("$key_msg is an extra property, but additionalProperties is false.")
        valid=false
      fi
    done
  fi

  # Print errors if any
  if [ "$valid" = false ]; then
    for error in "${errors[@]}"; do
      echo "$error"
    done
  fi
}

# Function to handle additional constraints
handle_constraints() {
  local value="$1"
  local schema="$2"
  local key_path="$3"
  local -n errors_ref=$4
  local -n valid_ref=$5

  # Pattern (regex matching)
  local pattern=$(echo "$schema" | jq -r '.pattern // empty')
  if [ -n "$pattern" ]; then
    if ! [[ "$value" =~ $pattern ]]; then
      errors_ref+=("Key '${key_path}' does not match the pattern '$pattern'")
      valid_ref=false
    fi
  fi

  # Enum (fixed values)
  local enum_values=$(echo "$schema" | jq -r '.enum // empty')
  if [ "$enum_values" != "null" ]; then
    if ! echo "$enum_values" | jq -e ". | index($value)" >/dev/null; then
      errors_ref+=("Key '${key_path}' value '$value' is not in the enum list: $enum_values")
      valid_ref=false
    fi
  fi

  # MultipleOf (numerical constraint)
  local multiple_of=$(echo "$schema" | jq -r '.multipleOf // empty')
  if [ -n "$multiple_of" ]; then
    if ! (($(echo "$value % $multiple_of" | bc) == 0)); then
      errors_ref+=("Key '${key_path}' value '$value' is not a multiple of $multiple_of")
      valid_ref=false
    fi
  fi
}

# Main function to validate a JSON file against a schema
validate_json_from_schema() {
  local json="$1"
  local schema="$2"

  validate_json_recursive "$json" "$schema" ""
}

# Function to add JSON objects or arrays
add_json_objects() {
  local json1="$1" # First JSON input
  local json2="$2" # Second JSON input

  # Get the types of the input JSON values
  local type1
  local type2
  type1=$(echo "$json1" | jq -e type 2>/dev/null | tr -d '"')
  type2=$(echo "$json2" | jq -e type 2>/dev/null | tr -d '"')

  # Check if both types were captured successfully
  if [ -z "$type1" ] || [ -z "$type2" ]; then
    echo "One or both inputs are invalid JSON."
    return 1
  fi

  # Perform different operations based on the types of inputs
  local merged
  case "$type1-$type2" in
  object-object)
    # Merge the two JSON objects
    merged=$(jq -sc '.[0] * .[1]' <<<"$json1"$'\n'"$json2")
    ;;
  object-array)
    # Append the object to the array
    merged=$(jq -c '. + [$json1]' --argjson json1 "$json1" <<<"$json2")
    ;;
  array-object)
    # Append the object to the array
    merged=$(jq -c '. + [$json2]' --argjson json2 "$json2" <<<"$json1")
    ;;
  array-array)
    # Concatenate the two arrays
    merged=$(jq -sc '.[0] + .[1]' <<<"$json1"$'\n'"$json2")
    ;;
  *)
    # Unsupported combination
    error "Unsupported JSON types. Please provide valid JSON objects or arrays."
    return 1
    ;;
  esac

  # Output the merged result
  echo "$merged"
}

# Function to sort array1 based on the order of names in array2 using a specified key
sort_array_by_order() {
  local array1="$1"
  local order="$2"
  local key="$3"

  echo "$array1" | jq --argjson order "$order" --arg key "$key" '
    map( .[$key] as $name | {item: ., index: ( $order | index($name) // length) } ) |
    sort_by(.index) | map(.item)
    '
}

# Function to filter items based on the given filter function
filter_items() {
  local items="$1"     # The JSON array of items to filter
  local filter_fn="$2" # The jq filter to apply

  # Apply the jq filter and return the filtered result as an array
  filtered_items=$(echo "$items" | jq "[ $filter_fn ]")
  echo "$filtered_items"
}

# Function to extract values based on a key
extract_values() {
  echo "$1" | jq -r "map(.$2)"
}

# Function to extract a specific field from a JSON array
extract_field() {
  local json="$1"
  local field="$2"
  echo "$json" | jq -r ".[].$field"
}

# Function to filter items based on a field value match
filter_items_by_name() {
  local json="$1"
  local name="$2"
  echo "$json" | jq -c --arg name "$name" '[.[] | select(.name == $name)]'
}

# Function to add a JSON object to an array
append_to_json_array() {
  local json_array="$1"
  local json_object="$2"
  echo "$json_array" | jq ". += [$json_object]"
}

# Function to sort an array based on another array
sort_array_according_to_other_array() {
  local array1="$1"
  local array2="$2"
  local key="$3"
  order="$(extract_values "$array2" "$key")"
  echo "$(sort_array_by_order "$array1" "$order" "$key")"
}

# Function to convert an associative array to JSON
convert_array_to_json() {
  local -n array_ref=$1 # Reference to the associative array
  local json="{"

  # Iterate over array keys and values
  for key in "${!array_ref[@]}"; do
    # Escape key and value and add them to the JSON object
    json+="\"$key\":\"${array_ref[$key]}\","
  done

  # Remove the trailing comma and close the JSON object
  json="${json%,}}"

  echo "$json"
}

# Function to save an associative array to a JSON file
save_array_to_json() {
  local file_path="$1" # File path to save the JSON data
  shift                # Remove the first argument, leaving only the associative array parameters

  # Declare the associative array and populate it
  declare -A input_array
  while [[ $# -gt 0 ]]; do
    key="$1"
    value="$2"
    input_array["$key"]="$value"
    shift 2 # Move to the next key-value pair
  done

  # Convert the associative array to JSON
  local json_content
  json_content=$(convert_array_to_json input_array)

  # Save the JSON content to the specified file
  write_json "$file_path" "$json_content"
}

# Function to write JSON content to a file atomically
write_json() {
  local file_path="$1"
  local json_content="$2"

  # Validate the JSON content
  echo "$json_content" | jq . >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "Invalid JSON content. Aborting save."
    return 1
  fi
  echo "$json_content"
  # Write the JSON content to the specified file using a temporary file for safety
  local temp_file=$(mktemp)
  echo "$json_content" >"$temp_file" && mv "$temp_file" "$file_path"
  chmod 600 "$file_path"

  return 0
}

# Function to load JSON from a file
load_json() {
  local config_file="$1"
  local config_output

  # Check if configuration file exists first
  if [[ -f "$config_file" ]]; then
    config_output=$(cat "$config_file")
  else
    # If file doesn't exist, handle as needed (e.g., return empty JSON or an error)
    warning "Configuration file '$config_file' not found. Returning empty JSON."
    config_output="{}"
  fi

  # Ensure valid JSON by passing it through jq
  if ! echo "$config_output" | jq . >/dev/null 2>&1; then
    warning "Invalid JSON in the configuration file '$config_file'. Returning empty JSON."
    echo "{}"
  else
    # Return the valid JSON
    echo "$config_output"
  fi
}

# Function to load JSON from a file
load_json() {
  local config_file="$1"
  local config_output

  # Check if configuration file exists first
  if [[ -f "$config_file" ]]; then
    config_output=$(cat "$config_file")
  else
    # If file doesn't exist, handle as needed (e.g., return empty JSON or an error)
    warning "Configuration file '$config_file' not found. Returning empty JSON."
    config_output="{}"
  fi

  # Ensure valid JSON by passing it through jq
  if ! echo "$config_output" | jq . >/dev/null 2>&1; then
    warning "Invalid JSON in the configuration file '$config_file'. Returning empty JSON."
    echo "{}"
  else
    # Return the valid JSON
    echo "$config_output"
  fi
}

# Function to load JSON and exit if missing or invalid
load_or_fail_json() {
  local config_file="$1"
  local config
  config=$(load_json "$config_file")

  if [[ "$config" == "{}" ]]; then
    warning "Missing or invalid configuration in '$config_file'. Exiting."
    return 1
  fi

  echo "$config"
}

# Function to display each error item with custom formatting
display_error_items() {
  local error_items="$1" # JSON array of error objects

  # Parse and iterate over each error item in the JSON array
  echo "$error_items" |
    jq -r '.[] | "\(.name): \(.message) (Function: \(.function))"' |
    while IFS= read -r error_item; do
      # Display the error item using the existing error function
      error "$error_item"
    done
}

# Function to handle exit codes and display success or failure messages
handle_exit() {
  local exit_code="$1"
  local current_step="$2" # Current step index (e.g., 3)
  local total_steps="$3"  # Total number of steps (e.g., 4)
  local message="$4"      # Descriptive message for success or failure

  # Validate that current step is less than or equal to total steps
  if [ "$current_step" -gt "$total_steps" ]; then
    warning "Current step ($current_step) exceeds total steps ($total_steps)."
  fi

  local status="success"
  local status_message="$message succeeded"

  if [ "$exit_code" -ne 0 ]; then
    status="error"
    status_message="$message failed"
    error "Error Code: $exit_code"
  fi
  step "$current_step" "$total_steps" "$status_message" "$status"

  # Exit with failure if there's an error
  if [ "$status" == "error" ]; then
    exit 1
  fi
}

# Function to handle empty collections and avoid exiting prematurely
handle_empty_collection() {
  if [[ "$1" == "[]" ]]; then
    warning "No data collected. Exiting process."
    exit 0
  fi
}

# Function to wait for any letter or command to continue
wait_for_input() {
  local prompt_message="$1"

  # If no message is provided, set a default prompt
  if [[ -z "$prompt_message" ]]; then
    prompt_message="Press any key to continue..."
  fi

  # Display the prompt message and wait for user input
  prompt_message="$(format "question" "$prompt_message")"
  read -rp "$prompt_message" user_input
}

email_test_hmtl() {
  echo "<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <title>Welcome to StackSetup</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f9f9fb;
      margin: 0;
      padding: 0;
      color: #333;
    }
    .container {
      margin: 20px auto;
      padding: 20px;
      max-width: 600px;
      background-color: #ffffff;
      border-radius: 10px;
      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }
    .header {
      text-align: center;
      padding: 20px 0;
      background-color: #4caf50;
      color: #ffffff;
    }
    .header img {
      max-width: 80px;
      margin-bottom: 10px;
    }
    .header h1 {
      font-size: 24px;
      margin: 0;
    }
    .content {
      padding: 20px;
    }
    .content p {
      color: #555;
      line-height: 1.6;
      margin: 15px 0;
    }
    .content a.button {
      display: inline-block;
      margin: 20px 0;
      padding: 12px 25px;
      background-color: #4caf50;
      color: #ffffff;
      text-decoration: none;
      border-radius: 5px;
      font-size: 16px;
      text-align: center;
      transition: background-color 0.3s ease;
    }
    .content a.button:hover {
      background-color: #45a049;
    }
    .footer {
      text-align: center;
      padding: 15px 0;
      font-size: 12px;
      color: #aaaaaa;
      border-top: 1px solid #eeeeee;
    }
    .footer a {
      color: #4caf50;
      text-decoration: none;
    }
    .social-icons {
      margin-top: 10px;
    }
    .social-icons a {
      margin: 0 5px;
      display: inline-block;
      text-decoration: none;
    }
    .social-icons img {
      width: 24px;
      height: 24px;
    }
  </style>
</head>
<body>
  <div class='container'>
    <div class='header'>
      <img src='https://via.placeholder.com/80x80' alt='Logo'>
      <h1>Welcome to StackMe</h1>
    </div>
    <div class='content'>
      <p>We are thrilled to have you onboard!</p>
      <p>If you have any questions, feel free to submit an issue to 
      <a href='https://github.com/whosbash/stackme/issues'>our repository</a>. We're here to help!
      </p>
    </div>
    <div class='footer'>
      <p>Sent using a Shell Script and the Swaks tool.</p>
    </div>
  </div>
</body>
</html>"
}

################################# END OF GENERAL UTILITARY FUNCTIONS ##############################

############################### BEGIN OF GENERAL DEPLOYMENT FUNCTIONS #############################

# Function to check if Docker Swarm is active
is_swarm_active() {
  local state=$(\
    docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | \
    tr -d '\n' | tr -d ' '\
  )
  if [[ -z "$state" ]]; then
    echo "Swarm state is empty or undefined." >&2
    return 1
  fi
  if [[ "$state" == "active" ]]; then
    return 0
  else
    return 1
  fi
}

# Function to fetch stable tags from a response
fetch_stable_tags_from_page() {
  pattern='^[0-9]+\.[0-9]+\.[0-9]+$|^[0-9]+\.[0-9]+$'
  echo "$1" | jq -r '.results[].name' | grep -E "$pattern"
}

# Determine if an image is official
is_official_image() {
  # Measure execution time
  local image_name=$1
  local response=""

  # Try fetching the official image first
  response=$(
    curl -fsSL "https://hub.docker.com/v2/repositories/library/${image_name}" 2>/dev/null
  )

  # Check if the response contains 'name' indicating it's an official image
  if [ $? -eq 0 ] && echo "$response" | jq -e '.name' >/dev/null 2>&1; then
    echo "true" # It's an official image
    return
  fi

  # If official image fails, try fetching the non-official image (user/organization image)
  response=$(curl -fsSL "https://hub.docker.com/v2/repositories/${image_name}")

  # If the response contains 'name', it's a valid (non-official) image
  if [ $? -eq 0 ] && echo "$response" | jq -e '.name' >/dev/null 2>&1; then
    echo "false" # It's a non-official image
  else
    # If neither the official nor non-official image is found, return false
    echo "false" # Image not found
  fi
}

# Get the latest stable version
get_latest_stable_version() {
  local image_name=$1
  local base_url=""
  local current_url=""
  local total_count=0
  local stable_tags=()
  local latest_version=""

  # Set the correct base URL
  base_url="https://hub.docker.com/v2/repositories"
  if [ "$(is_official_image "$image_name")" == "true" ]; then
    base_url="$base_url/library/${image_name}/tags?page_size=100"
  else
    base_url="$base_url/${image_name}/tags?page_size=100"
  fi

  # Fetch the first page to determine total pages
  response=$(curl -fsSL "$base_url" || echo "")
  if [ -z "$response" ] || [ "$(echo "$response" | jq -r '.count')" == "null" ]; then
    echo "Image '$image_name' not found or registry unavailable."
    return 1
  fi

  total_count=$(echo "$response" | jq -r '.count')
  total_pages=$(((total_count + 99) / 100))

  # Perform binary search for latest stable version
  low=1
  high=$total_pages
  while [ $low -le $high ]; do
    mid=$(((low + high) / 2))
    current_url="${base_url}&page=$mid"

    # Fetch the page
    response=$(curl -fsSL "$current_url" || echo "")
    if [ -z "$response" ]; then
      # Skip to upper half if the page is invalid
      low=$((mid + 1))
      continue
    fi

    # Extract stable tags
    page_tags=$(fetch_stable_tags_from_page "$response")
    if [ -n "$page_tags" ]; then
      stable_tags+=($page_tags)

      # Search lower half for potentially newer tags
      high=$((mid - 1))
    else
      # Search upper half
      low=$((mid + 1))
    fi
  done

  # Find the latest stable version
  if [ ${#stable_tags[@]} -gt 0 ]; then
    latest_version=$(printf "%s\n" "${stable_tags[@]}" | sort -V | uniq | tail -n 1)
    echo "$latest_version"
    return 0
  else
    echo "No stable version found for $image_name."
    return 1
  fi
}

# Function to check if a stack exists by name
stack_exists() {
  local stack_name="$1"
  # Check if the stack exists by listing stacks and filtering by name
  if docker stack ls --format '{{.Name}}' | grep -q "^$stack_name$"; then
    return 0
  else
    return 1 # Stack does not exist
  fi
}

# Function to list the services of a stack
list_stack_services() {
  local stack_name=$1
  declare -a services_array

  # Check if stack exists
  if ! docker stack ls --format '{{.Name}}' | grep -q "^$stack_name\$"; then
    error "Stack '$stack_name' does not exist."
    return 1
  fi

  info "Fetching services for stack: $stack_name"

  # Get the services associated with the specified stack and store them in an array
  services_array=($(docker stack services "$stack_name" --format '{{.Name}}'))

  # Optionally return the array as a result (useful if called from another script)
  echo "${services_array[@]}"
}

# Function to list the required fields on a stack docker-compose
list_stack_required_fields() {
  local stack_name="$1"
  local function_name="compose_${stack_name}"

  # Check if the function exists
  if declare -f "$function_name" >/dev/null; then
    pattern='\{\{\K[^}]+(?=\}\})'
    # Call the function and extract mustache parameters
    $function_name | grep -oP "$pattern" | sort -u
  else
    error "Function $function_name does not exist."
    return 1
  fi
}

# Function to deploy a service using a Docker Compose file
deploy_stack_on_swarm() {
  local stack_name=$1
  local compose_path=$2

  # Ensure Python is installed
  if ! command -v python3 &>/dev/null; then
    error "Python3 is required but not installed. Please install it and try again."
    exit 1
  fi

  # Deploy the service using Docker stack
  docker stack deploy --prune --resolve-image always -c "$compose_path" "$stack_name"

  if [ $? -eq 0 ]; then
    success "Stack $stack_name deployed and running successfully."
  else
    error "Stack $stack_name failed to deploy or is not running correctly."
    exit 1
  fi
}

# Function to handle all API requests with enhanced error handling
request() {
  local method="$1"       # HTTP method (GET, POST, DELETE, etc.)
  local url="$2"          # Full API URL
  local token="$3"        # Bearer token
  local content_type="$4" # Content-Type header (default: application/json)
  local data="$5"         # Optional JSON data for POST/PUT requests

  # Validate required parameters
  if [[ -z "$method" || -z "$url" || -z "$token" ]]; then
    echo "Missing required parameters"
    return 1
  fi

  # Make the API request using curl, capturing both body and HTTP status code
  response=$(curl -k -s -w "%{http_code}" -X "$method" "$url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: ${content_type:-application/json}" \
    ${data:+-d "$data"})

  # Extract HTTP response code from the response
  http_code="${response: -3}"

  # Extract response body (remove the last 3 characters, which are the HTTP status code)
  response_body="${response%???}"

  # Check if the request was successful (HTTP 2xx response)
  if [[ ! "$http_code" =~ ^2 ]]; then
    echo "API request failed with status code $http_code"
    echo "Response: $response_body"
    return 1
  fi

  # Return the response body if successful
  echo "$response_body"
}

# Function to perform requests on portainer URL
filtered_request() {
  local method="$1"                             # HTTP method (GET, POST, DELETE, etc.)
  local url="$2"                                # Full API URL or resource
  local token="$3"                              # Bearer token for authentication
  local content_type="${4:-'application/json'}" # Content-Type (default: application/json)
  local data="${5:-'{}'}"                       # JSON data for POST/PUT requests (optional)
  local filter=${6:-''}                         # Optional jq filter to extract specific output

  # Make the API request
  response=$(request "$method" "$url" "$token" "$content_type" "$data")

  # Apply the jq filter if provided, otherwise return the raw response
  if [[ -n "$filter" ]]; then
    echo "$response" | jq -r "$filter"
  else
    echo "$response"
  fi
}

# Function to build api url
get_api_url() {
  protocol="$1"
  url="$2"
  resource="$3"
  echo "https://$url/api/$resource"
}

# Function to check if Portainer credentials are correct
is_portainer_credential_correct() {
  local portainer_url="$1"
  local username="$2"
  local password="$3"

  protocol="https"
  content_type="application/json"
  credentials="{\"username\":\"$username\",\"password\":\"$password\"}"
  resource='auth'

  url="$(get_api_url $protocol $portainer_url $resource)"

  response=$(curl -k -s -X POST -H "Content-Type: $content_type" -d "$credentials" "$url")

  # Check if the response contains a valid token
  token=$(echo "$response" | jq -r .jwt)

  if [[ "$token" == "null" || -z "$token" ]]; then
    echo "Invalid credentials"
    return 1 # Exit with status 1 for failure
  else
    echo "Valid credentials"
    return 0 # Exit with status 0 for success
  fi
}

signup_on_portainer(){
  local portainer_url="$1"
  local new_username="$2"
  local new_password="$3"

  local protocol="https"
  local content_type="application/json"
  local credentials="{\"Username\":\"$new_username\",\"Password\":\"$new_password\"}"
  local resource='users/admin/init'

  url="$(get_api_url $protocol $portainer_url $resource)"

  response=$(curl -k -s -X POST "$url" -H "Content-Type: $content_type" -d "$credentials")

  # Check if the response indicates an existing administrator
  if [[ "$response" == *"An administrator user already exists"* ]]; then
    warning "An administrator user already exists."
  else 
    success "Administrator user created successfully."
  fi
}


# Function to retrieve a Portainer authentication token
get_portainer_auth_token() {
  local portainer_url="$1"
  local username="$2"
  local password="$3"

  local max_attempts=3
  local attempts=0

  local token=""

  protocol="https"
  method="POST"
  content_type="application/json"
  credentials="{\"username\":\"$username\",\"password\":\"$password\"}"
  resource='auth'
  jq_filter='.jwt'

  url="$(get_api_url $protocol $portainer_url $resource)"

  while [[ -z "$token" || "$token" == "null" ]]; do
    token=$(
      curl -k -s \
        -X POST \
        -H "Content-Type: $content_type" \
        -d "$credentials" "$url" |
        jq -r .jwt
    )

    ((attempts++))
    if [[ "$attempts" -ge "$max_attempts" ]]; then
      exit 1
    fi
    wait_secs 5
  done

  echo "$token"
}

# Function to retrieve the endpoint ID from Portainer
get_portainer_endpoint_id() {
  local portainer_url="$1"
  local token="$2"

  local endpoint_id
  protocol='https'
  method="GET"
  resource="endpoints"
  content_type="application/json"
  data="{}"
  jq_filter='.[] | select(.Name == "primary") | .Id'

  url="$(get_api_url $protocol $portainer_url $resource)"

  endpoint_id=$(
    filtered_request \
      "$method" "$portainer_url" \ 
    "$token" "$content_type" \
      "$resource" "$data" "$jq_filter"
  )

  if [[ -z "$endpoint_id" ]]; then
    exit 1
  fi

  echo "$endpoint_id"
}

# Function to retrieve the Swarm ID (used during stack deployment)
get_portainer_swarm_id() {
  local portainer_url="$1"
  local token="$2"
  local endpoint_id="$3"

  protocol='https'
  method="GET"
  resource="endpoints/$endpoint_id/docker/swarm"
  content_type='application/json'
  jq_filter='.ID'

  url="$(get_api_url $protocol $portainer_url $resource)"

  local swarm_id
  swarm_id=$(
    filtered_request \
      "$method" "$url" \
      "$token" "$content_type" \
      "$resource" "$data" "$jq_filter"
  )

  if [[ -z "$swarm_id" ]]; then
    error "Failed to retrieve Swarm ID."
    exit 1
  fi

  echo "$swarm_id"
}

# Function to get stacks
get_portainer_swarm_stacks() {
  local portainer_url="$1"
  local token="$2"

  # Fetch the list of stack names from the Portainer API
  local stacks

  protocol='https'
  method="GET"
  resource="stacks"
  content_type='application/json'
  jq_filter='.ID'

  url="$(get_api_url $protocol $portainer_url $resource)"

  local swarm_id
  stacks=$(
    filtered_request \
      "$method" "$url" \
      "$token" "$content_type" \
      "$resource" "$data"
  )

  # Check if any stacks were returned
  if [[ $stacks -eq 0 ]]; then
    echo "No stacks found or failed to retrieve stacks."
    return 1
  fi

  echo "$stacks"
}

# Function to get stacks and check if a specific stack exists
check_portainer_stack_exists() {
  local portainer_url="$1"
  local token="$2"
  local stack_name="$3"

  # Fetch stack names and check if the specified stack exists
  protocol='https'
  method="GET"
  resource="stacks"
  content_type='application/json'
  data='{}'
  jq_query=".[] | select(.Name == \"$stack_name\") | .Id"

  url="$(get_api_url $protocol $portainer_url $resource)"

  # Fetch the stack ID using filtered_request
  local stack_id
  stack_id=$(
    filtered_request \
      "GET" \
      "$(get_api_url 'https' $portainer_url "stacks")" \
      "$token" "application/json" "{}" \
      ".[] | select(.Name == \"$stack_name\") | .Id"
  )

  # Check if stack ID was retrieved
  if [[ -z "$stack_id" ]]; then
    echo ""
    return 1
  fi

  # If stack ID is found, return the ID
  echo "$stack_id"
  return 0
}

# Function to upload a stack
upload_stack_on_portainer() {
  local portainer_url="$1"
  local token="$2"
  local stack_name="$3"
  local compose_file="$4"

  highlight "Uploading stack $stack_name on Portainer $portainer_url"

  # Swarm ID and endpoint id is required for Swarm stack deployments
  local swarm_id

  resource="endpoints"
  jq_query='.[] | select(.Name == "primary") | .Id'
  endpoint_id=$(get_portainer_endpoint_id "$portainer_url" "$token")
  if [[ -z "$endpoint_id" ]]; then
    error "Failed to retrieve Endpoint ID."
    return 1
  fi

  jq_filter='.ID'
  swarm_id=$(get_portainer_swarm_id "$portainer_url" "$token" "$endpoint_id")
  if [[ -z "$swarm_id" ]]; then
    error "Failed to retrieve Swarm ID."
    return 1
  fi

  # Upload the stack
  info "Uploading stack: ${stack_name}..."
  resource="stacks?type=1&method=string&endpointId=${endpoint_id}"

  content_type="application/json"
  data="{
        \"Name\": \"${stack_name}\",
        \"SwarmID\": \"${swarm_id}\",
        \"file\": \"$(<"$compose_file")\"
    }"

  filtered_request "POST" "$portainer_url" "$token" "$content_type" "$data" &&
    success "Stack '$stack_name' uploaded successfully." ||
    error "Failed to upload stack '$stack_name'."

}

# Function to delete a stack
delete_stack_on_portainer() {
  local portainer_url="$1"
  local token="$2"
  local stack_name="$3"

  highlight "Deleting stack '$stack_name' on Portainer $portainer_url"

  # Retrieve stack ID based on the stack name
  info "Retrieving stack ID for '${stack_name}'..."
  local protocol='https'
  local resource="stacks"
  local jq_filter=".[] | select(.Name == \"$stack_name\") | .Id"
  local stack_id

  stack_id=$(check_portainer_stack_exists "$portainer_url" "$token" "$stack_name")

  if [[ -z "$stack_id" ]]; then
    warning "Stack '${stack_name}' not found. Exiting without error."
    return 0
  fi

  # Retrieve Endpoint ID for the stack
  info "Retrieving endpoint ID for stack '${stack_name}'"
  resource="stacks/$stack_id"
  jq_filter=".EndpointId"
  local endpoint_id

  endpoint_id=$(get_portainer_endpoint_id "$portainer_url" "$token")

  if [[ -z "$endpoint_id" ]]; then
    error "Failed to retrieve Endpoint ID for stack '${stack_name}'."
    return 1
  fi

  # Delete the stack
  info "Deleting stack '${stack_name}'"
  resource="stacks/${stack_id}?endpointId=${endpoint_id}"
  url="$(get_api_url $protocol $portainer_url $resource)"

  if filtered_request "DELETE" "$portainer_url" "$token" "application/json"; then
    success "Stack '${stack_name}' deleted successfully."
  else
    error "Failed to delete stack '${stack_name}'."
  fi
}

# Function to display a deploy failed message
deploy_failed_message() {
  stack_name="$1"
  error "Failed to deploy service $stack_name!"
}

# Function to display a deploy success message
deploy_success_message() {
  stack_name="$1"
  success "Successfully deployed stack $stack_name!"
}

# Function to build config and compose files for a service
build_stack_info() {
  local service_name="$1"

  # Build config file
  local config_path="${service_name}_config.json"

  # Build compose file
  local compose_path="${service_name}.yaml"

  # Build compose func name
  local compose_func="compose_${service_name}"

  # Return files
  echo "$config_path $compose_path $compose_func"
}

# Function to validate a Docker Compose file
validate_compose_file() {
  local compose_file="$1"

  # Check if the file exists
  if [ ! -f "$compose_file" ]; then
    error "File '$compose_file' not found."
    exit 1
  fi

  # Validate the syntax of the Docker Compose file
  docker compose -f "$compose_file" config >/dev/null 2>&1

  local EXIT_CODE=$?
  return $EXIT_CODE
}

# Function to remove dangling images and their associated containers
remove_dangling_images() {
  message="Removing dangling images"
  status="success"
  
  # Check if there are any dangling images
  dangling_images=$(docker images --filter 'dangling=true' -q)
  
  if [ -n "$dangling_images" ]; then
    for image in $dangling_images; do
      # Check if any container is using the image
      container_using_image=$(docker ps -a --filter "ancestor=$image" -q)
      
      if [ -n "$container_using_image" ]; then
        # Stop and remove containers using the image
        for container_id in $container_using_image; do
          # Check if container is running
          container_status=$(docker ps --filter "id=$container_id" -q)
          
          if [ -n "$container_status" ]; then
            # Container is running, stop it
            warning "Stopping running container $container_id"
            docker stop "$container_id"
          fi
          
          # Remove the container
          warning "Removing container $container_id"
          docker rm "$container_id" || status="failed"
        done
      fi
      
      # Remove the dangling image
      warning "Removing image $image"
      docker rmi -f "$image" || { \
        error "Failed to remove image $image, possibly still in use."; 
        status="failed"; 
      }
    done
  else
    status="no_dangling_images"
    message="No dangling images found."
  fi
  
  # Return the status and message
  echo "$status"
  echo "$message"
}

# Function to clean docker environment with one confirmation step
sanitize() {
  total_steps=5

  # Ask for confirmation before proceeding
  explanation="This will prune unused containers, networks, volumes, images, and build cache"
  confirmation_query="Are you sure you want to continue? [y/N]"
  message="$explanation. $confirmation_query"
  formatted_message="$(format "question" "$message")"

  read -p "$formatted_message" confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Run commands with explicit permission for destructive operations
    message="Pruning unused containers, networks, volumes, and build cache"
    command="docker system prune --all --volumes -f"
    command "$command" 1 $total_steps "$message" "yes"

    message="Removing dangling images"

    # Call the function and capture its output
    message="Removing dangling images"
    step_info 2 $total_steps "$message"
    
    status_message=$(remove_dangling_images)
    status=$(echo "$status_message" | head -n 1)
    message=$(echo "$status_message" | tail -n 1)

    # Handle status after the function call
    if [[ "$status" == "success" ]]; then
      step_success 2 $total_steps "Cleanup completed successfully: $message"
    elif [[ "$status" == "no_dangling_images" ]]; then
      step_warning 2 $total_steps "No dangling images found."
    else
      step_error 2 $total_steps "$message"
    fi

    message="Removing stopped containers"
    command="docker container prune -f"
    command "$command" 3 $total_steps "$message" "yes"

    message="Removing unused Docker networks"
    command="docker network prune -f"
    command "$command" 4 $total_steps "$message" "yes"

    message="Removing orphaned volumes"
    command="docker volume prune -f"
    command "$command" 5 $total_steps "$message" "yes"
  else
    failure "Aborted by user."
  fi
}

# Function to create a Docker network if it doesn't exist
create_network_if_not_exists() {
  local network_name="${1:-$DEFAULT_NETWORK}"

  # Check if the network already exists
  if ! docker network ls --format '{{.Name}}' | grep -wq "$network_name"; then
    info "Creating network: $network_name"

    # Create the overlay network
    if docker network create --driver overlay "$network_name" 2>/dev/null; then
      success "Network $network_name created successfully."
    else
      error "Failed to create network $network_name."
      return 1 # Exit with error status if network creation fails
    fi
  else
    warning "Network $network_name already exists."
  fi
}

# Function to execute a setUp action
execute_set_up_action() {
  local action="$1" # JSON object representing the setUp action

  # Extract the name, command, and variables from the action
  local action_name
  action_name=$(echo "$action" | jq -r '.name')

  local action_command
  action_command=$(echo "$action" | jq -r '.command')

  # Extract variables if they exist (empty string if not defined)
  local action_variables
  action_variables=$(echo "$action" | jq -r '.variables // empty')

  # If there are variables, export them for the command execution
  if [ -n "$action_variables" ]; then
    # Export each variable safely, ensuring no unintended command execution
    for var in $(echo "$action_variables" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"'); do
      # Escape and export the variable
      local var_name=$(echo "$var" | cut -d'=' -f1)
      local var_value=$(echo "$var" | cut -d'=' -f2)
      export "$var_name"="$var_value"
    done
  fi

  # Safely format the command using printf to avoid eval
  # Substitute the variables in the command
  local formatted_command
  formatted_command=$(printf "%s" "$action_command")

  # Execute the formatted command
  bash -c "$formatted_command"

  # Check if the command executed successfully and handle exit
  local exit_code=$?
}

# Load service configuration from a Docker-Compose stack or a running container
load_stack_config() {
  local stack_name="$1"
  local config_file="${stack_name}_config.json"
  local service_ip
  local config_output

  # Check if configuration file exists first
  if [[ -f "$config_file" ]]; then
    config_output=$(cat "$config_file")
  else
    # Attempt to retrieve service information from docker-compose stack if defined
    service_ip=$(
      docker-compose ps -q "$stack_name" 2>/dev/null |
        xargs docker inspect \
          --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null
    )

    if [[ -n "$service_ip" ]]; then
      debug "Retrieved IP from docker-compose for service '$stack_name': $service_ip"
      config_output=$(generate_service_config_json "$stack_name" "$service_ip")
    else
      # Fallback: Attempt to retrieve IP from running container if not part of stack
      service_ip=$(
        docker inspect \
          --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
          "$stack_name" 2>/dev/null
      )

      if [[ -n "$service_ip" ]]; then
        debug "Retrieved IP from running container for service '$stack_name': $service_ip"
        config_output=$(generate_service_config_json "$stack_name" "$service_ip")
      else
        # If all methods fail, return an empty configuration
        warning "Unable to retrieve configuration for service '$stack_name'."
        config_output="{}"
      fi
    fi
  fi

  # Ensure valid JSON by passing it through jq
  if ! echo "$config_output" | jq . >/dev/null 2>&1; then
    warning "Invalid JSON in the service configuration for '$stack_name'. Returning empty JSON."
    echo "{}"
  else
    # Return the valid JSON
    echo "$config_output"
  fi
}

# Helper function to load service configuration and exit if missing
load_or_fail_stack_config() {
  local stack_name="$1"
  local config
  config=$(load_stack_config "$stack_name")

  if [[ "$config" == "{}" ]]; then
    critical "Missing configuration for stack '$stack_name'. Exiting."
    exit 1
  fi

  echo "$config"
}

# Function to generate a JSON configuration for a service
generate_config_schema() {
  local required_fields="$1"

  # Start the JSON schema structure
  local schema="{\"variables\": {"

  # Generate properties for each required field
  local first=true
  for field in $required_fields; do
    if [ "$first" = true ]; then
      first=false
    else
      schema+=","
    fi
    schema+="\"$field\": {\"type\": \"string\"}"
  done

  # Add dependencies and setUp as always-present fields
  schema+='},
    "dependencies": {},
    "setUp": []}'

  echo "$schema"
}

# Function to extract required fields and generate schema
validate_stack_config() {
  local stack_name="$1"
  local config_json="$2"

  # Get required fields from the stack template
  required_fields=$(list_stack_required_fields "$stack_name")

  # Generate the JSON schema
  schema=$(generate_config_schema "$required_fields")

  # Step 5: Validate if the provided JSON has all required variables
  validate_json_from_schema "$config_json" "$schema"
}

test_smtp_email(){
  items='[
      {
          "name": "smtp_server",
          "label": "SMTP server",
          "description": "Server to receive SMTP requests",
          "required": "yes",
          "validate_fn": "validate_smtp_server",
          "default_value": "smtp.gmail.com"
      },
      {
          "name": "smtp_port",
          "label": "SMTP port",
          "description": "Port on SMTP server",
          "required": "yes",
          "validate_fn": "validate_integer_value",
          "default_value": 587
      },
      {
          "name": "username",
          "label": "SMTP username",
          "description": "Username of SMTP server",
          "required": "yes",
          "validate_fn": "validate_email_value" 
      },
      {
          "name": "password",
          "label": "SMTP password",
          "description": "Password of SMTP server",
          "required": "yes",
          "validate_fn": "validate_empty_value" 
      }
  ]'

  collected_items="$(run_collection_process "$items")"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve SMTP test configuration."
    return 1
  fi

  smtp_server="$(search_on_json_array "$collected_items" 'name' 'smtp_server' | jq -r ".value")"
  smtp_port="$(search_on_json_array "$collected_items" 'name' 'smtp_port' | jq -r ".value")"
  username="$(search_on_json_array "$collected_items" 'name' 'username' | jq -r ".value")"
  password="$(search_on_json_array "$collected_items" 'name' 'password' | jq -r ".value")"

  subject="Setup test e-mail"
  body="$(email_test_hmtl)"

  send_email \
    "$username" "$username" "$smtp_server" "$smtp_port" \
    "$username" "$password" "$subject" "$body"
}

# Function to deploy a service
build_and_deploy_stack() {
  # Arguments
  local stack_name="$1" # Service name (e.g., redis, postgres)
  local stack_json="$2" # JSON data with service variables

  total_steps=9

  stack_step(){
    type="$1"
    step="$2"
    message="$3"
    stack_message="[$stack_name] $message"
    step_progress $step $total_steps "$stack_message"
  }

  stack_handle_exit(){
    exit_code="$1" 
    step="$2"
    message="$3"
    stack_message="[$stack_name] $message"
    handle_exit "$exit_code" 1 $total_steps "$stack_message"
  }

  # Declare an associative array to hold service variables
  declare -A stack_variables

  # Parse JSON data and populate associative array
  while IFS="=" read -r key value; do
    stack_variables["$key"]="$value"
  done < <(echo "$stack_json" | jq -r '.variables | to_entries | .[] | "\(.key)=\(.value)"')

  highlight "Deploying stack '$stack_name'"

  # Step 1: Deploy Dependencies
  stack_step 'progress' 1 "Checking and deploying dependencies"
  step_progress 1 $total_steps "$message"
  local dependencies=$(echo "$stack_json" | jq -r '.dependencies[]?')

  # Check if there are dependencies, and if none, display a message
  if [ -z "$dependencies" ]; then
    stack_step 'warning' 1 "No dependencies to deploy"
  else
    for dependency in $dependencies; do
      dependency_message="Deploying dependency: $dependency"
      stack_step 'progress' 1 "$dependency_message"

      # Fetch JSON for the dependency
      local dep_service_json
      dep_stack_json=$(fetch_service_json "$dependency")

      deploy_stack "$dep" "$dep_stack_json"
      stack_handle_exit "$?" 1 "$dependency_message"
    done
  fi

  # Step 2: Gather setUp actions (if defined in the service JSON)
  stack_step 'progress' 2 "Gathering setUp actions"
  local setUp_actions
  setUp_actions=$(echo "$service_json" | jq -r '.setUp[]?')

  # Debug: Check if jq returned an error
  if [[ $? -ne 0 ]]; then
    stack_step 'error' 2 "Error parsing setUp actions: $setUp_actions"
    exit 1
  fi

  # Step 3: Run setUp actions individually
  if [ -n "$setUp_actions" ]; then
    # Iterate through each action, preserving newlines for better debugging
    IFS=$'\n' read -d '' -r -a actions_array <<<"$setUp_actions"

    for action in "${actions_array[@]}"; do
      # Perform the action (you can define custom functions to execute these steps)
      message="Executing setUp action: $action"
      stack_step 'error' 3 "$message"

      # Call an appropriate function to handle this setUp action
      execute_set_up_action "$action"
      stack_handle_exit $? 3 "$message"
    done
  else
    stack_step 'warning' 3 "No setUp actions defined"
  fi

  # Step 4: Build service-related file paths and Docker Compose template
  message="Building stack filepaths"
  stack_step 'progress' 4 "$message"
  stack_info="$(build_stack_info "$stack_name")"
  local config_path=$(echo "$stack_info" | awk '{print $1}')
  local compose_filepath=$(echo "$stack_info" | awk '{print $2}')
  local compose_template_func=$(echo "$stack_info" | awk '{print $3}')
  stack_handle_exit $? 4 "$message"

  # Step 5: Retrieve and substitute variables in Docker Compose template
  message="Creating Docker Compose template"
  stack_step 'progress' 5 "$message"
  local substituted_template
  substituted_template="$(\
    replace_mustache_variables "$($compose_template_func)" stack_variables \
  )"
  stack_handle_exit $? 5 "$message"

  # Step 6: Write the substituted template to the compose file
  message="Writing Docker Compose template"
  stack_step 'progress' 6 
  compose_path="$(pwd)/$compose_filepath"
  echo "$substituted_template" >"$compose_path"
  stack_handle_exit $? 6 "$message"

  # Step 7: Validate the Docker Compose file
  message="Validating Docker Compose file"
  stack_step 'progress' 7 
  validate_compose_file "$compose_path"
  stack_handle_exit $? 7 "$message"

  # Step 8: Deploy the service on Docker Swarm
  message="Deploying stack on Docker Swarm"
  stack_step 'progress' 8 
  deploy_stack_on_swarm "$stack_name" "$compose_filepath"
  stack_handle_exit $? 8 "$message"

  # Step 9: Save service-specific information to a configuration file
  message="Saving stack configuration"
  stack_step_progress 9 "$message"
  write_json "$config_path" "$stack_json"
  stack_handle_exit $? 9 "$message"

  # Final Success Message
  deploy_success_message "$stack_name"

  wait_for_input
}

################################ END OF GENERAL DEPLOYMENT FUNCTIONS ###############################

################################ BEGIN OF STACK DEPLOYMENT FUNCTIONS ###############################

# Function to get the password from a JSON file
get_postgres_password() {
  local config_file=$1
  password_postgres=$(jq -r '.password' $config_file)
  echo "$password_postgres"
}

# Function to create a PostgreSQL database
create_postgres_database() {
  local db_name="$1"
  local db_user="${2:-postgres}"
  local container_name="${3:-postgres_db}"

  local container_id
  local db_exists

  # Display a message about the database creation attempt
  info "Creating PostgreSQL database: $db_name in container: $container_name"

  # Check if the container is running
  container_id=$(docker ps -q --filter "name=^${container_name}$")
  if [ -z "$container_id" ]; then
    error "Container '${container_name}' is not running. Cannot create database."
    return 1
  fi

  # Check if the database already exists
  db_exists=$(docker exec \
    "$container_id" psql -U "$db_user" -lqt | cut -d \| -f 1 | grep -qw "$db_name")
  if [ "$db_exists" ]; then
    info "Database '$db_name' already exists. Skipping creation."
    return 0
  fi

  # Create the database if it doesn't exist
  info "Creating database '$db_name'..."
  if docker exec "$container_id" \
    psql -U "$db_user" -c "CREATE DATABASE \"$db_name\";" >/dev/null 2>&1; then
    success "Database '$db_name' created successfully."
    return 0
  else
    error "Failed to create database '$db_name'. Please check the logs for details."
    return 1
  fi
}

# Function to generate the set-up actions for n8n
generate_set_up_actions_n8n() {
  local n8n_config_json=$1
  local n8n_instance_id=$2 # New parameter for the n8n instance identifier
  local postgres_db=$(echo "$n8n_config_json" |
    jq -r '.variables.DB_NAME')
  local postgres_user=$(echo "$n8n_config_json" |
    jq -r '.dependencies.postgres.variables.DB_USER')
  local postgres_container=$(echo "$n8n_config_json" |
    jq -r '.dependencies.postgres.variables.CONTAINER_NAME')

  # Escape the variables to prevent issues with special characters
  local escaped_postgres_db
  local escaped_postgres_user
  local escaped_postgres_container

  escaped_postgres_db=$(printf '%q' "$postgres_db")
  escaped_postgres_user=$(printf '%q' "$postgres_user")
  escaped_postgres_container=$(printf '%q' "$postgres_container")

  # Ensure the database name is unique based on the instance ID to prevent conflicts
  local unique_postgres_db="${escaped_postgres_db}_${n8n_instance_id}"

  args="\($unique_postgres_db) \($escaped_postgres_user) \($escaped_postgres_container)"
  command="create_postgres_database $args"

  jq -n \
    --arg POSTGRES_DB "$unique_postgres_db" \
    --arg POSTGRES_USER "$escaped_postgres_user" \
    --arg POSTGRES_CONTAINER "$escaped_postgres_container" \
    --arg INSTANCE_ID "$n8n_instance_id" \
    --arg COMMAND "$command" \
    '{
            "actions": [
                {
                    "name": "Create Postgres Database",
                    "command": "$COMMAND",
                    "variables": {
                        "POSTGRES_DB": "$POSTGRES_DB",
                        "POSTGRES_USER": "$POSTGRES_USER",
                        "POSTGRES_CONTAINER": "$POSTGRES_CONTAINER",
                        "INSTANCE_ID": "$INSTANCE_ID"
                    }
                }
            ]
        }'
}

################################# END OF STACK DEPLOYMENT FUNCTIONS ################################

################################## BEGIN OF CONFIGURATION VARIABLE #################################

# Function to generate configuration files for traefik
generate_config_traefik() {
  local stack_name="traefik" # Default service name
  
  server_info_json="$(cat 'server_info.json')"
  local network_name="$(
    search_on_json_array "$server_info_json" "name" "network_name" | jq -r ".value"
  )"

  items='[
      {
          "name": "email_ssl",
          "label": "E-mail SSL",
          "description": "E-mail to receive SSL notifications",
          "required": "yes",
          "validate_fn": "validate_email_value" 
      }
  ]'

  collected_items="$(run_collection_process "$items")"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve Traefik configuration."
    return 1
  fi
  email_ssl="$(\
    search_on_json_array "$collected_items" 'name' 'email_ssl' | \
    jq -r ".value"
  )"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg email_ssl $email_ssl \
    --arg network_name "$network_name" \
    '{
            "name": $stack_name,
            "variables": {
                "email_ssl": $email_ssl,
                "network_name": $network_name,
            },
            "dependencies": {},
            "setUp": []
        }'
}

# Function to generate configuration files for portainer
generate_config_portainer() {
  local stack_name="portainer"
  
  total_steps=3
  
  highlight 'Gathering portainer configuration'

  step_info 1 $total_steps "Retrieving Portainer agent version"
  local portainer_agent_version="$(get_latest_stable_version "portainer/agent")"
  info "Portainer agent version: $portainer_agent_version"
  step_success 1 $total_steps "Retrieving Portainer agent version succeed"
  
  step_info 2 $total_steps "Retrieving Portainer ce version"
  local portainer_ce_version="$(get_latest_stable_version "portainer/portainer-ce")"
  info "Portainer ce version: $portainer_ce_version"
  step_success 2 $total_steps "Retrieving Portainer ce version succeed"

  server_info_json="$(cat 'server_info.json')"
  local network_name="$(
    search_on_json_array "$server_info_json" "name" "network_name" | jq -r ".value"
  )"

  # Prompting step 
  items='[
      {
          "name": "portainer_url",
          "label": "Portainer URL",
          "description": "URL to access Portainer remotely",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      }
  ]'

  step_info 3 $total_steps "Prompting required Portainer information"
  collected_items="$(run_collection_process "$items")"

  if [[ "$collected_items" == "[]" ]]; then
    step_error 3 $total_steps "Unable to prompt Portanier configuration."
    return 1
  fi
  portainer_url="$(\
    search_on_json_array "$collected_items" 'name' 'portainer_url' | \
    jq -r ".value"
  )"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg portainer_agent_version "$portainer_agent_version" \
    --arg portainer_ce_version "$portainer_ce_version" \
    --arg portainer_url "$portainer_url" \
    --arg network_name "$network_name" \
    '{
          "variables": {
              "stack_name": $stack_name,
              "portainer_agent_version": $portainer_agent_version,
              "portainer_ce_version": $portainer_ce_version,
              "portainer_url": $portainer_url,
              "network_name": $network_name
          },
          "dependencies": {},
          "setUp": []
      }'
}

# Function to generate configuration files for redis
generate_config_redis() {
  local stack_name = 'redis'
  local image_version="${1:-"latest"}"        # Accept image version or default to 6.2.5
  local container_port="${2:-6379}"           # Accept container port or default to 6379
  local network_name="${3:-$DEFAULT_NETWORK}" # Accept network or default to default_network

  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_name "$stack_name_$image_version" \
    --arg image_version "$image_version" \
    --arg container_name "$stack_name" \
    --arg container_port "$container_port" \
    --arg redis_url "$stack_name://$stack_name:$container_port" \
    --arg volume_name "$stack_name_data" \
    --arg network_name "$network_name" \
    '{
            "name": $stack_name,
            "variables": {
                "image_name": $image_name,
                "image_version": $image_version,
                "container_name": $container_name,
                "container_port": $container_port,
                "redis_url": $redis_url,
                "volume_name": $volume_name,
                "network_name": $network_name
            },
            "dependencies": {},
            "setUp": []
        }'
}

# Function to generate Postgres service configuration JSON
generate_config_postgres() {
  local stack_name="postgres"       # Default service name
  local image_version="${1:-"14"}"  # Accept image version or default to 14
  local container_port="${2:-5432}" # Accept container port or default to 5432

  local postgres_user="postgres"
  local postgres_password="$(random_string)"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_name "${stack_name}_$image_version" \
    --arg image_version "$image_version" \
    --arg container_name "$service_name" \
    --arg container_potr "$container_port" \
    --arg db_user "$postgres_user" \
    --arg db_password "$postgres_password" \
    --arg volume_name "${service_name}_data" \
    --arg network_name "$network_name" \
    '{
            "name": $stack_name,
            "variables": {
                "stack_name": $stack_name,
                "image_name": $image_name,
                "image_version": $image_version,
                "container_name": $container_name,
                "container_port": $container_port,
                "volume_name": $volume_name,
                "network_name": $network_name,
                "db_user": $db_user,
                "db_password": $db_password
            },
            "dependencies": {},
            "setUp": []
        }'
}

# Function to generate n8n config
generate_config_n8n() {
  local identifier="$1"
  local stack_name="n8n"
  local instance_label="${stack_name}_${identifier}"
  local image_version="${2:-latest}"          # Default to latest
  local container_port="${3:-5678}"           # Default to 5678
  local protocol = "${4:-http}"               # Default to http
  local editor_url = "$5"                     # Default to EDITOR_URL
  local webhook_url = "$6"                    # Default to WEBHOOK_URL
  local network_name="${7:-$DEFAULT_NETWORK}" # Default to default_network

  # Load Redis and Postgres configs
  local redis_config
  redis_config=$(load_or_fail_stack_config "redis")
  redis_json=$(printf "%s" "$redis_config" | jq -e . 2>/dev/null || echo "{}")

  local postgres_config
  postgres_config=$(load_or_fail_stack_config "postgres")
  postgres_json=$(printf "%s" "$postgres_config" | jq -e . 2>/dev/null || echo "{}")

  # Generate the n8n configuration JSON
  local n8n_config_json
  n8n_config_json=$(
    jq -n \
      --arg INSTANCE_LABEL "$this_stack_name" \
      --arg IMAGE_NAME "${service_name}_$image_version" \
      --arg CONTAINER_PORT "$editor_port" \
      --arg EDITOR_URL "$protocol://$webhook_url" \
      --arg WEBHOOK_URL "$protocol://$editor_url" \
      --arg VOLUME_NAME "${service_name}_data" \
      --arg DB_NAME "${this_service_name}_queue" \
      --arg NETWORK_NAME "$network_name" \
      --argjson REDIS_CONFIG "$redis_json" \
      --argjson POSTGRES_CONFIG "$postgres_json" \
      '{
            "variables": {
                "STACK_LABEL": $SERVICE_NAME,
                "INSTANCE_ID": $INSTANCE_ID,
                "IMAGE_NAME": $IMAGE_NAME,
                "CONTAINER_PORT": $CONTAINER_PORT,
                "SERVICE_URL": $SERVICE_URL,
                "VOLUME_NAME": $VOLUME_NAME,
                "PROTOCOL": 'http',
                "NETWORK_NAME": $NETWORK_NAME,
                "DB_NAME": $DB_NAME,
            },
            "dependencies": {
                "redis": $REDIS_CONFIG,
                "postgres": $POSTGRES_CONFIG
            }
        }'
  )

  # Generate and inject setUp actions dynamically
  local setUp_actions
  setUp_actions=$(generate_set_up_actions_n8n "$n8n_config_json")

  # Check if setUp_actions is valid JSON
  if ! echo "$setUp_actions" | jq empty >/dev/null 2>&1; then
    critical "Invalid setUp actions generated. Exiting."
    exit 1
  fi

  # Combine the main config with setUp actions
  local final_config
  final_config=$(
    echo "$n8n_config_json" |
      jq --argjson SETUP_ACTIONS "$setUp_actions" \
        '. + { "setUp": $SETUP_ACTIONS }'
  )

  echo "$final_config"
}

################################### END OF CONFIGURATION VARIABLE ##################################

####################################### BEGIN OF COMPOSE FILES #####################################

# Function to generate compose file for Traefik
compose_traefik() {
  CERT_PATH="/etc/traefik/letsencrypt/acme.json"
  cat <<EOL
services:

  traefik:
    image: traefik:v2.11.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network={{network_name}}"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.transport.respondingTimeouts.idleTimeout=3600"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=$CERT_PATH"
      - "--certificatesresolvers.letsencryptresolver.acme.email={{email_ssl}}"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"

    volumes:
      - "vol_certificates:/etc/traefik/letsencrypt"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"

    networks:
      - {{network_name}}

    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host

    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=Host(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"


volumes:
  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:
  {{network_name}}:
    external: true
    attachable: true
    name: {{network_name}}
EOL
}

# Function to generate compose file for Portainer
compose_portainer() {
  cat <<EOL
services:

  agent:
    image: portainer/agent:{{portainer_agent_version}}

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes

    networks:
      - {{network_name}}

    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:{{portainer_ce_version}} 
    command: -H tcp://tasks.agent:9001 --tlsskipverify

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

    networks:
      - {{network_name}}

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.portainer.rule=Host(\`{{portainer_url}}\`)"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"
        - "traefik.http.routers.portainer.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.docker.network={{network_name}}"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"


volumes:
  portainer_data:
    external: true
    name: portainer_data
networks:
  {{network_name}}:
    external: true
    attachable: true
    name: {{network_name}}
EOL
}

# Function to generate compose file for Redis
compose_redis() {
  cat <<EOL
services:
  redis:
    image: redis:{{image_version}}
    command: [
        "redis-server",
        "--appendonly",
        "yes",
        "--port",
        "{{container_port}}"
    ]
    volumes:
      - {{volume_name}}:/data
    networks:
      - {{network_name}}

volumes:
  {{volume_name}}:
    external: true
    name: {{volume_name}}

networks:
  {{network_name}}:
    external: true
    name: {{network_name}}
EOL
}

# Function to generate compose file for Postgres
compose_postgres() {
  cat <<EOL
services:
  postgres:
    image: postgres:{{image_version}}
    environment:
      - POSTGRES_PASSWORD={{db_password}}
      - PG_MAX_CONNECTIONS=500
    ## Uncomment the following line to use a custom configuration file
    # ports:
    #   - {{container_port}}:5432
    volumes:
      - {{volume_name}}:/var/lib/postgresql/data
    networks:
      - {{network_name}}

volumes:
  {{volume_name}}:
    external: true

networks:
  {{network_name}}:
    external: true
    name: {{network_name}}
EOL
}

# Function to generate compose file for N8N
compose_n8n() {
  cat <<EOL
version: '3.8'

# Common environment variables definition
x-common-env: &common-env
  DB_TYPE: postgresdb
  DB_POSTGRESDB_DATABASE: {{db_name}}
  DB_POSTGRESDB_HOST: {{db_host}}
  DB_POSTGRESDB_PORT: {{db_port}}
  DB_POSTGRESDB_USER: {{db_user}}
  DB_POSTGRESDB_PASSWORD: {{db_password}}
  N8N_ENCRYPTION_KEY: {{encryption_key}}
  N8N_HOST: {{editor_host}}
  N8N_EDITOR_BASE_URL: {{protocol}}://{{editor_host}}/
  WEBHOOK_URL: {{protocol}}://{{webhook_host}}/
  N8N_PROTOCOL: {{protocol}}
  NODE_ENV: production
  EXECUTIONS_MODE: queue

# Common service dependencies definition
x-common-depends-on: &common-depends-on
  redis:
    condition: service_healthy
  database:
    condition: service_healthy

# Global Deploy Configuration for All Services
x-common-deploy: &common-deploy
  mode: replicated
  replicas: {{replicas}}
  placement:
    constraints:
      - node.role == manager
  resources:
    limits:
      cpus: "1"
      memory: 1024M

services:
  # Editor service
  {{instance_name}}_editor:
    image: n8nio/n8n:{{image_version}}
    command: start
    environment:
      <<: *common-env
      N8N_SMTP_SENDER: {{smtp_sender}}
      N8N_SMTP_USER: {{smtp_user}}
    depends_on: *common-depends-on
    deploy: *common-deploy
    labels:
      - traefik.enable=true
      - traefik.http.routers.{{instance_name}}_editor.rule=Host(\`{{editor_host}}\`)
      - traefik.http.routers.{{instance_name}}_editor.entrypoints=websecure
      - traefik.http.routers.{{instance_name}}_editor.tls.certresolver=letsencryptresolver
      - traefik.http.services.{{instance_name}}_editor.loadbalancer.server.port=5678

  # Webhook service
  webhook:
    image: n8nio/n8n:{{image_version}}
    command: webhook
    environment: *common-env
    depends_on: *common-depends-on
    deploy: *common-deploy
    labels:
      - traefik.enable=true
      - traefik.http.routers.{{instance_name}}_webhook.rule=Host(\`{{webhook_host}}\`)
      - traefik.http.routers.{{instance_name}}_webhook.entrypoints=websecure
      - traefik.http.routers.{{instance_name}}_webhook.tls.certresolver=letsencryptresolver
      - traefik.http.services.{{instance_name}}_webhook.loadbalancer.server.port=5678

  # Worker service
  worker:
    image: n8nio/n8n:{{image_version}}
    command: worker --concurrency=10
    environment: *common-env
    depends_on: *common-depends-on
    deploy: *common-deploy

networks:
  {{network_name}}:
    external: true
    name: {{network_name}}
EOL
}

######################################## END OF COMPOSE FILES #####################################

################################ BEGIN OF STACK DEPLOYMENT FUNCTIONS ##############################

# Function to deploy a traefik service
deploy_stack_traefik() {
  local stack_name='traefik'
  local network_name="${2:-$DEFAULT_NETWORK}"

  # Generate the n8n service JSON configuration using the helper function
  local config_json
  config_json=$(generate_config_traefik)

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  echo "$config_json" >&2

  # Deploy the n8n service using the JSON
  build_and_deploy_stack "$stack_name" "$config_json"
}

# Function to deploy a portainer service
deploy_stack_portainer() {
  local stack_name='portainer'

  # Generate the n8n service JSON configuration using the helper function
  local config_json
  config_json="$(generate_config_portainer)"

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  # Deploy the n8n service using the JSON
  build_and_deploy_stack "$stack_name" "$config_json"
}

# Function to deploy a PostgreSQL stack
deploy_stack_postgres() {
  local stack_name='postgres'
  local image_version="${1:-"14"}"            # Accept image version or default to 14
  local container_port="${2:-5432}"           # Accept container port or default to 5432
  local network_name="${3:-$DEFAULT_NETWORK}" # Accept network or default to DEFAULT_NETWORK

  # Create a JSON object to pass as an argument
  local config_json
  config_json=$(generate_config_postgres "$image_version" "$container_port" "$network_name")

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  # Deploy the PostgreSQL service using the JSON
  build_and_deploy_stack "$stack_name" "$config_json"
}

# Function to deploy a Redis service
deploy_stack_redis() {
  local stack_name='redis'
  local image_version="${1:-"6.2.5"}"         # Accept image version or default to 6.2.5
  local container_port="${2:-6379}"           # Accept container port or default to 6379
  local network_name="${3:-$DEFAULT_NETWORK}" # Accept network or default to DEFAULT_NETWORK

  # Generate the Redis service JSON configuration using the helper function
  local redis_config_json
  config_json=$(generate_config_redis "$image_version" "$container_port" "$network_name")

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  # Deploy the Redis service using the JSON
  build_and_deploy_stack "$stack_name" "$config_json"
}

# Function to deploy a n8n service
deploy_stack_n8n() {
  local stack_name='n8n'
  local network_name="${2:-$DEFAULT_NETWORK}"

  # Generate the n8n service JSON configuration using the helper function
  local n8n_config_json
  n8n_config_json=$(generate_config_n8n)

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  # Deploy the n8n service using the JSON
  build_and_deploy_stack "$augmented_stack_name" "$n8n_config_json"

  important "You must create the login and password in the first access of the N8N"
}

######################################## END OF COMPOSE FILES #####################################

###################################### BEGIN OF SETUP FUNCTIONS ###################################

# Function to prepare the environment
update_and_install_packages() {
  # Function constants
  local total_steps=3

  highlight "Preparing environment"

  # Check if the script is running as root
  if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root or use sudo."
    exit 1
  fi

  # Step 1: Update the system
  step_message="Updating system and upgrading packages"
  step_progress 1 $total_steps "$step_message"
  command "apt-get update -yq" 1 $total_steps "$step_message"

  # Step 3: Autoclean the system
  step_message="Cleaning up package cache"
  step_progress 2 $total_steps "$step_message"
  command "apt-get autoclean -yq --allow-downgrades" 2 $total_steps "$step_message"

  # Check for apt locks on installation
  wait_apt_lock 5 60

  # Install required apt packages quietly
  packages=("sudo" "apt-utils" "apparmor-utils" "jq" "python3" "docker" "figlet" "swaks" "netcat")
  step_message="Installing required apt-get packages"
  step_progress 3 $total_steps "$step_message"
  install_all_packages "apt-get" "${packages[@]}"
  handle_exit $? 3 $total_steps "$step_message"

  success "Packages installed successfully."

  wait_for_input
}

# Function to clean the local docker environment
clean_docker_environment() {
  highlight "Cleaning local docker environment"
  sanitize

  wait_for_input
}

# Function to prompt for server information and process the response
prompt_server_info() {
  local items='[
        { 
            "name": "server_name",
            "label": "Server Name",
            "description": "The name of the server", 
            "required": "yes",
            "validate_fn": "validate_name_value"
        }, 
        { 
            "name": "network_name", 
            "label": "Network Name", 
            "description": "The name of the network for Docker stack", 
            "required": "yes",
            "validate_fn": "validate_name_value"
        }
    ]'

  # Run collection process and capture server info JSON
  run_collection_process "$items"
}

# Function to retrieve the server IP address
get_server_ip() {
  local server_ip=$(hostname -I | awk '{print $1}')
  if [[ -z "$server_ip" ]]; then
    error "Unable to retrieve the server IP address."
    exit 1
  fi
  echo "$server_ip"
}

# Function to merge server, network, and IP information
get_server_info() {
  local server_array ip_object merged_result

  # Get the server and network information
  server_array="$(prompt_server_info)"
  if [[ "$server_array" == "[]" ]]; then
    error "Unable to retrieve server and network names."
    exit 1
  fi

  # Print the merged result
  echo "$server_array"
}

# Function to initialize the server information
initialize_server_info() {
  total_steps=5
  server_filename="server_info.json"

  # Step 1: Check if server_info.json exists and is valid
  message="Initialization of server information..."
  step_progress 1 $total_steps "$message"
  if [[ -f "$server_filename" ]]; then
    server_info_json=$(cat "$server_filename" 2>/dev/null)
    if jq -e . >/dev/null 2>&1 <<<"$server_info_json"; then
      step_info 1 $total_steps "Valid server_info.json found. Using existing information."
    else
      step_error "Content on file $server_filename is invalid. Reinitializing..."
      server_info_json=$(get_server_info)
    fi
  else  
    server_info_json=$(get_server_info)

    # Save the server information to a JSON file
    echo "$server_info_json" >"$server_filename"
    step_success 1 $total_steps "Server information saved to file $server_filename"
  fi

  # Extract server_name and network_name
  server_name=$(\
    echo "$server_info_json" | \
    jq -r '.[] | select(.name=="server_name") | .value'
  )
  network_name=$(
    echo "$server_info_json" | 
    jq -r '.[] | select(.name=="network_name") | .value'
  )

  # Output results
  if [[ -z "$server_name" || -z "$network_name" ]]; then
    error "Missing server_name or network_name in file $server_filename"
    exit 1
  fi

  # Set Hostname
  step_message="Set Hostname"
  step_progress 2 $total_steps "$step_message"
  hostnamectl set-hostname "$server_name" >/dev/null 2>&1
  handle_exit $? 2 $total_steps "$step_message"

  # Update /etc/hosts
  step_message="Add name to server name in hosts file at path /etc/hosts"
  step_progress 3 $total_steps "$step_message"
  sed -i "s/127.0.0.1[[:space:]]localhost/127.0.0.1 $server_name/g" /etc/hosts >/dev/null 2>&1
  handle_exit $? 3 $total_steps "$step_message"

  # Initialize Docker Swarm
  step_message="Docker Swarm initialization"
  step_progress 4 $total_steps "$step_message"

  if is_swarm_active; then
    step_warning 4 $total_steps "Swarm is already active"
  else
    server_ip=$(
      echo "$server_info_json" | 
      jq -r '.[] | select(.name=="server_ip") | .value'
    )

    docker swarm init  >/dev/null 2>&1
    
    handle_exit $? 4 $total_steps "$step_message"
  fi

    # Initialize Network
  message="Network initialization"
  step_progress 5 $total_steps "$message"
  create_network_if_not_exists "$network_name"
  handle_exit $? 5 $total_steps "$step_message"

  success "Server initialization complete"

  wait_for_input
}

# Declare arrays for stack labels (user-friendly) and stack names (internal)
# IMPORTANT: The order of the arrays should match
# NOTE: Add new stacks here
declare -a stack_labels=("SMTP test" "Traefik" "Portainer" "Redis" "Postgres" "N8N")
declare -a stack_names=("smtp" "traefik" "portainer" "redis" "postgres" "n8n")
declare -a stack_descriptions=(
  "A simple email service test."
  "A modern reverse proxy and load balancer for microservices."
  "A web-based management interface for Docker environments."
  "A powerful in-memory data structure store used as a database, cache, and message broker."
  "A relational database management system emphasizing extensibility and SQL compliance."
  "A workflow automation tool that allows you to automate tasks and integrate various services."
)

# Function to deploy the selected stack based on input
deploy_stack() {
  local option="$1"
  case "$option" in
  smtp)
    clear
    header 'SMTP'
    test_smtp_email
    ;;
  traefik)
    clear
    header 'Traefik'
    deploy_stack_traefik
    ;;
  portainer)
    clear
    header 'Portainer'
    deploy_stack_portainer
    ;;
  redis)
    clear
    header 'Redis'
    deploy_stack_redis
    ;;
  postgres)
    clear
    header 'Postgres'
    deploy_stack_postgres
    ;;
  n8n)
    clear
    header 'N8N'
    deploy_stack_n8n
    ;;
  *)
    error "Invalid stack. Available options: ${stack_names[*]}. Provided stack: $stack"
    exit 1
    ;;
  esac
}

# Function to display a great farewell message
farewell_message() {
  farewell_messages=(
    ""
    "🌟 Thank you for using the Deployment Tool OpenStack! 🌟"
    ""
    "Your journey doesn't end here:it's just a new beginning."
    "Remember: Success is the sum of small efforts, repeated day in and day out. 🚀"
    ""
    "We hope to see you again soon. Until then, happy coding and stay curious! ✨"
    ""
  )

  # Format the array of farewell messages
  format_array "celebrate" farewell_messages

  # Display the formatted messages
  display_parallel farewell_messages
}

# Function to choose the stack to install
choose_stack_to_install() {
  # Constants for pagination
  local total_items=${#stack_labels[@]}
  local total_pages=$(((total_items + ITEMS_PER_PAGE - 1) / ITEMS_PER_PAGE))
  local current_page=1
  local type="highlight"

  # If total items fit within one page, disable pagination
  if ((total_items <= $ITEMS_PER_PAGE)); then
    total_pages=1
  fi

  while true; do
    clear
    header 'Main menu'

    # Buffer all lines to an array
    local -a menu_lines=()

    if ((total_pages > 1)); then
      page_message="$(\
        format "$type" \
        "Select the stack to install (Page $current_page of $total_pages):"\
      )"
      
    else
      page_message="$(format "$type" "Select the stack to install:")"
    fi
    menu_lines+=("$page_message")

    fmt_space="$(format "$type" "")"
    menu_lines+=("$fmt_space") 

    # Calculate start and end indices for the current page
    local start_index=$(((current_page - 1) * $ITEMS_PER_PAGE))
    local end_index=$((start_index + $ITEMS_PER_PAGE - 1))
    if ((end_index >= total_items)); then
      end_index=$((total_items - 1))
    fi

    # Display the items for the current page
    for i in $(seq "$start_index" "$end_index"); do
      local label_with_padding=$(printf "%-10s" "${stack_labels[i]}")
      local option="$((i + 1)). $label_with_padding: ${stack_descriptions[i]}"
      fmt_option="$(format "$type" "$option")"
      
      menu_lines+=("$fmt_option") 
    done

    # Navigation options
    fmt_space="$(format "$type" "")"
    menu_lines+=("$fmt_space")
    if ((total_pages > 1)); then
      local navigation_options="[p/P] Previous Page [n/N] Next Page [e/E] Exit"
    else
      local navigation_options="[e/E] Exit"
    fi
    fmt_nav_options="$(format "$type" "$navigation_options")"
    menu_lines+=("$fmt_nav_options")

    display_parallel menu_lines

    # Read user input
    local choice_message="$(format "$type" "Enter your choice: ")"
    read -p "$choice_message" choice    

    options="between $((start_index + 1)) and $((end_index + 1)) or press 'e' to exit."
    explanation="Select an option $options"
    choice_error_message="Invalid choice. $explanation"

    # Handle navigation and selection
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if ((choice >= start_index && choice <= end_index)); then
        local selected_stack_name="${stack_names[$((choice - 1))]}"
        deploy_stack "$selected_stack_name"
        return
      else
        error "$choice_error_message"
        wait_secs 1
      fi
    elif ((total_pages > 1)) && [[ "$choice" == "P" || "$choice" == "p" ]]; then
      if ((current_page > 1)); then
        current_page=$((current_page - 1))
      else
        current_page=$total_pages # Wrap to the last page
      fi
    elif ((total_pages > 1)) && [[ "$choice" == "N" || "$choice" == "n" ]]; then
      if ((current_page < total_pages)); then
        current_page=$((current_page + 1))
      else
        current_page=1 # Wrap to the first page
      fi
    elif [[ "$choice" == "E" || "$choice" == "e" ]]; then
      clear
      farewell_message
      exit 0
    else
      error "$choice_error_message"
      wait_secs 1
    fi
  done
}

# Display help message
usage() {
  usage_messages=(
    "Usage: $0 [options]"
    "Options:"
    "  -i, --install           Install required packages."
    "  -c, --clean             Clean docker environment."
    "  -p, --prepare           Prepare the environment, same as combination '-i -c'."
    "  -u, --startup           Startup server information."
    "  -s, --stack STACK       Specify which stack to install: {${stack_names[*]}}."
    "  -h, --help              Display this help message and exit."
  )
  format_array "info" usage_messages

  display_parallel usage_messages

  exit 1
}

# Parse command-line arguments
parse_args() {
  # Get options using getopt
  OPTIONS=$(\
    getopt \
    -o i,c,p,u,s:,h \
    --long install,clean,prepare,startup,stack:,help -- "$@" 2>/dev/null\
  )
  
  # Check if getopt failed (invalid option)
  if [ $? -ne 0 ]; then
    echo "Invalid option(s) provided."
    usage
    exit 1
  fi

  # Apply the options to positional parameters
  eval set -- "$OPTIONS"

  # Loop through the options
  while true; do
    case "$1" in
    -i | --install)
      INSTALL=true
      shift
      ;;
    -c | --clean)
      CLEAN=true
      shift
      ;;
    -p | --prepare)
      PREPARE=true
      shift
      ;;
    -u | --startup)
      STARTUP=true
      shift
      ;;
    -s | --stack)
      STACK=$2
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    --)
      shift
      break
      ;;
    *)
      # This will be triggered for any unrecognized option
      echo "Unknown option: $1"
      usage
      return 1
      ;;
    esac
  done
}

# Main script execution
main() {
  parse_args "$@"

  # Handle options based on parsed arguments
  if [[ $INSTALL == true ]]; then
    clear
    update_and_install_packages
  fi

  if [[ $CLEAN == true ]]; then
    clear
    clean_docker_environment
  fi

  if [[ $STARTUP == true ]]; then
    clear
    initialize_server_info
  fi

  if [[ $PREPARE == true ]]; then
    clear
    update_and_install_packages
    clean_docker_environment
    initialize_server_info
  fi

  # Set or choose the stack
  if [[ -n $STACK ]]; then
    clear
    
    deploy_stack "$STACK"
  else
    while true; do
      choose_stack_to_install
    done
  fi
}

# Call the main function
main "$@"
