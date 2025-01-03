#!/usr/bin/env bash

# Disable canonical mode, set immediate input
stty -icanon min 1 time 0

# Ensure terminal settings are restored on script exit
trap "stty sane" EXIT

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

# Dictionary of arrows
declare -A ARROWS=(
    ["simple"]="→"
    ["sharp"]="➜"
    ["double"]="⇒"
    ["curved"]="↪"
    ["dash"]="➳"
    ["star"]="⋆"
    ["angle"]="▸"
    ["triangle_filled"]="▲"
    ["triangle"]="△"
    ["small_square_filled"]="▪"
    ["medium_empty_square"]="□"
    ["big_empty_square"]="▢"
    ["filled_square"]="■"
    ["square_filled_empty"]="▣"
    ["horiz_crossed_square"]="▤"
    ["vert_crossed_square"]="▥"
    ["crossed_square"]="▦"
    ["diag_square"]="▧"
    ["diag_crossed_square"]="▨"
    ["diamond"]="◆"
    ["cross"]="✗"
    ["dot"]="•"
    ["circle_filled"]="●"
    ["circle_empty"]="○"
    ["circle_filled_empty"]="⊙"
    ["circle_empty_filled"]="⊚"
)

# Define a global associative array for storing menu items
declare -A MENUS

# Define a global array for storing navigation history
menu_navigation_history=()

# Highlight and color variables for styling
highlight_color="\033[1;32m" # Highlight color (Bright Green)
faded_color="\033[2m"        # Faded color (Dark gray)
select_color="\033[1;34m"    # Blue for select (↵)
warning_color="\033[1;33m"   # Warning color (Yellow)
back_color="\033[2m"         # Magenta for return (r)
quit_color="\033[1;31m"      # Red for quit (q)
search_color="\033[1;36m"    # Search color (/)
goto_color="\033[1;36m"      # Go-to page color (g)
help_color="\033[1;35m"      # Help color (h)
error_color="\033[1;31m"     # Error color (Dark red)
title_color="\033[1;36m"     # Title color (Cyan)
reset_color="\033[0m"        # Reset color

# Color definitions for styling
bold="\033[1m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[35m"
normal="\033[0m"

# Define the separator
separator="=============================================="

# Cleanup
current_pid=0

# Define arrow keys for navigation
up_key="[A"    # Up Arrow
down_key="[B"  # Down Arrow
left_key="[D"  # Left Arrow
right_key="[C" # Right Arrow

# Default menu options
TRUNCATED_DEFAULT_LENGTH=50
HAS_TIMESTAMP=true
HEADER_LENGTH=120

# Default arrow
ARROW_OPTION='star'
SELECTED_ARROW="${ARROWS[$ARROW_OPTION]}"
COLORED_ARROW="${highlight_color}${SELECTED_ARROW}${reset_color}"

############################# BEGIN OF DISPLAY-RELATED FUNCTIONS #############################

# Function to display a message with improved formatting
display() {
  local type="$1"
  local text="$2"
  local timestamp="${3:-$HAS_TIMESTAMP}"

  echo -e "$(format "$type" "$text" $timestamp)"
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

# Function to format a message
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

# Function to display styled and optionally centered text with custom or terminal width
display_text() {
  local text="$1"             # The text to display
  local custom_width="$2"     # Custom width for the text
  local padding=0             # Optional padding around the text
  local center=false          # Set to true to center the text
  local style="${bold_color}" # Optional style (e.g., bold or colored)

  # Check if additional options are provided
  shift 2 # Skip the first two arguments (text and custom_width)
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --center) center=true ;;
    --style)
      style="$2"
      shift
      ;;
    --padding)
      padding="$2"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    esac
    shift
  done

  # If custom width is not provided, use terminal width (tput cols)
  if [[ -z "$custom_width" ]]; then
    custom_width=$(tput cols)
  fi

  # Ensure padding is valid
  if ((padding < 0)); then
    echo "Padding must be non-negative." >&2
    return 1
  fi

  # Calculate text length with padding
  local padded_text=$(printf "%${padding}s%s%${padding}s" "" "$text" "")
  local text_length=${#padded_text}

  # Ensure the custom width is at least the length of the text
  if ((custom_width < text_length)); then
    message="Custom width ($custom_width) is smaller than text length ($text_length)."
    echo "Error: $message" >&2
    return 1
  fi

  # Center the text if needed
  if [[ "$center" == true ]]; then
    local left_padding=$(((custom_width - text_length) / 2))
    padded_text=$(printf "%${left_padding}s%s" "" "$padded_text")
  fi

  # Ensure the text fits within the custom width
  local final_text=$(printf "%-${custom_width}s" "$padded_text")

  # Apply styling and display
  echo -e "${style}${final_text}${reset_color}"
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

# Function to display a boxed text
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

################################## END OF DISPLAY-RELATED FUNCTIONS ###############################

################################## BEGIN OF JSON-RELATED FUNCTIONS ################################

# Recursive function to validate JSON against a schema
validate_json_recursive() {
  local json="$1"
  local schema="$2"
  local parent_path="$3" # Track the JSON path for better error reporting
  local valid=true
  local errors=()

  # Extract required keys and properties from the schema
  local required_keys=$(echo "$schema" | jq -r '.required[]? // empty')
  local properties=$(echo "$schema" | jq -c '.properties // empty')
  local additional_properties=$(\
    echo "$schema" | \
    jq -r 'if has("additionalProperties") then .additionalProperties else "true" end'
  )

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
    actual_type=$(echo "$value" | jq -r 'type // empty')

    if [ "$expected_type" = "object" ]; then
      # Recursively validate nested objects
      if [ "$actual_type" = "object" ]; then
        validate_json_recursive "$value" "$sub_schema" "${parent_path}${key}."
      else
        errors+=("Key '${parent_path}${key}' expected type 'object', but got '$actual_type'")
        valid=false
      fi
    elif [ "$expected_type" = "array" ]; then
      # Validate array elements
      validate_array "$value" "$sub_schema" "${parent_path}${key}" errors valid
    else
      # Validate primitive types and handle constraints
      validate_primitive "$value" "$sub_schema" \
        "$expected_type" "$actual_type" "${parent_path}${key}" errors valid
    fi
  done

  # Handle additionalProperties
  if [ "$additional_properties" = "false" ]; then
    for key in $(echo "$json" | jq -r 'keys[]'); do
      if ! echo "$properties" | jq -e "has(\"$key\")" >/dev/null; then
        errors+=(\
          "Extra property '${parent_path}${key}' found, but additionalProperties is false."\
        )
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

# Validate array elements
validate_array() {
  local array="$1"
  local schema="$2"
  local path="$3"
  local -n errors_ref=$4
  local -n valid_ref=$5

  local items_schema=$(echo "$schema" | jq -c '.items // empty')
  local array_length=$(echo "$array" | jq 'length')

  for ((i = 0; i < array_length; i++)); do
    local element=$(echo "$array" | jq -c ".[$i]")
    local element_type=$(echo "$element" | jq -r 'type')
    local expected_type=$(echo "$items_schema" | jq -r '.type // empty')

    if [ "$element_type" != "$expected_type" ] && [ "$expected_type" != "null" ]; then
      errors_ref+=(\
        "Array element ${path}[$i] expected type '$expected_type', but got '$element_type'"\
      )
      valid_ref=false
    fi

    # Recursively validate array elements
    validate_json_recursive "$element" "$items_schema" "${path}[$i]."
  done
}

# Validate primitive types and handle constraints
validate_primitive() {
  local value="$1"
  local schema="$2"
  local expected_type="$3"
  local actual_type="$4"
  local path="$5"
  local -n errors_ref=$6
  local -n valid_ref=$7

  if [ "$expected_type" != "$actual_type" ] && \
    [ "$actual_type" != "null" ]; then
    errors_ref+=("Key '${path}' expected type '$expected_type', but got '$actual_type'")
    valid_ref=false
  fi

  # Handle additional constraints (pattern, enum, etc.)
  handle_constraints "$value" "$schema" "$path" errors_ref valid_ref
}

# Handle additional constraints
handle_constraints() {
  local value="$1"
  local schema="$2"
  local path="$3"
  local -n errors_ref=$4
  local -n valid_ref=$5

  local pattern=$(echo "$schema" | jq -r '.pattern // empty')
  local enum_values=$(echo "$schema" | jq -c '.enum // empty')
  local multiple_of=$(echo "$schema" | jq -r '.multipleOf // empty')

  # Pattern matching
  if [ -n "$pattern" ] && \
    ! [[ "$value" =~ $pattern ]]; then
    errors_ref+=("Key '${path}' does not match pattern '$pattern'")
    valid_ref=false
  fi

  # Enum validation
  if [ "$enum_values" != "null" ] && \
    ! echo "$enum_values" | jq -e ". | index($value)" >/dev/null; then
    errors_ref+=("Key '${path}' value '$value' is not in the allowed values: $enum_values")
    valid_ref=false
  fi

  # MultipleOf constraint
  if [ -n "$multiple_of" ] && \
    (( $(echo "$value % $multiple_of" | bc) != 0 )); then
    errors_ref+=("Key '${path}' value '$value' is not a multiple of $multiple_of")
    valid_ref=false
  fi
}

# Main function to validate a JSON file against a schema
validate_json_from_schema() {
  local json="$1"
  local schema="$2"

  validate_json_recursive "$json" "$schema" ""
}

# Function to decode JSON and base64
query_json64() {
  local item="$1"
  local field="$2"
  echo "$item" | base64 --decode | jq -r "$field" || {
    error "Invalid JSON or base64 input!"
    return 1
  }
}

# Function to convert each element of a JSON array to base64
convert_json_array_to_base64_array() {
  local json_array="$1"
  # Convert each element of the JSON array to base64 using jq
  echo "$json_array" | jq -r '.[] | @base64'
}

# Function to search for an object in a JSON array
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

# Function to get a specific value from a JSON object
query_json_value() {
  local menu_item="$1"
  local query="$2"

  echo "$menu_item" | jq -r "$query"
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

get_variable_value_from_collection(){
  local collected_items="$1"
  local variable_name="$2"

  echo "$(\
    search_on_json_array "$collected_items" 'name' "$variable_name" | jq -r ".value"
  )"
}

# Function to add a JSON object to an array
append_to_json_array() {
  local json_array="$1"
  local json_object="$2"
  echo "$json_array" | jq ". += [$json_object]"
}

# Function to extract variables from a string without curly braces
extract_variables() {
  local compose_string="$1"
  echo "$compose_string" | \
    grep -oE '\{\{[a-zA-Z0-9_]+\}\}' | \
    sed 's/[{}]//g' | \
    sort -u
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

################################## END OF JSON-RELATED FUNCTIONS ################################

############################### BEGIN OF GENERAL UTILITARY FUNCTIONS ############################

# Function to clean the terminal screen
clean_screen() {
  echo -ne "\033[H\033[J" >&2
}

# Function to strip ANSI escape sequences from a string
strip_ansi() {
  pattern='s/\x1b\[[0-9;]*[mK]//g'
  echo -e "$1" | sed "$pattern"
}

# Function to convert "true"/"false" to integer 1/0
to_integer() {
  [[ "$1" == "true" ]] && echo 1 || echo 0
}

# Function to convert a numeric result to "true" or "false"
to_boolean() {
  [[ "$1" -ne 0 ]] && echo "true" || echo "false"
}

############################# END OF GENERAL UTILITARY FUNCTIONS #############################

############################## BEGIN OF EMAIL-RELATED FUNCTIONS ##############################

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

################################## END OF EMAIL-RELATED FUNCTIONS #################################

############################### BEGIN OF SYSTEM-RELATED FUNCTIONS #################################

# Functions for diagnostics
cpu_usage() {
    # Example usage of display_text to show a centered header
    display_text "CPU USAGE" 40 --center --style "${bold_color}${green}"
    echo ""
    uptime
    echo ""
}

memory_usage() {
    echo ""
    free -h
    echo ""
}

# Function to display disk usage
disk_usage() {
    # Get the used, available, and total space in bytes
    read -r used avail total <<< "$(df --output=used,avail,size --block-size=1 / | tail -n1)"

    # Calculate the percentage of space used with decimal precision
    if [[ $total -gt 0 ]]; then
        percentage=$(awk "BEGIN {printf \"%.2f\", ($used / $total) * 100}")
    else
        percentage="0.00"
    fi

    # Convert bytes to gigabytes (with two decimal places)
    used_gb=$(awk "BEGIN {printf \"%.2f\", $used / (1024^3)}")
    avail_gb=$(awk "BEGIN {printf \"%.2f\", $avail / (1024^3)}")
    total_gb=$(awk "BEGIN {printf \"%.2f\", $total / (1024^3)}")

    # Print the results in a structured format
    echo "Used: ${used_gb}G, Available: ${avail_gb}G, Total: ${total_gb}G, Usage: ${percentage}%"
}

# Function to display network usage
network_usage() {
    echo ""
    ip -s link
    echo ""
}

# Function to display top processes
top_processes() {
    echo ""
    
    # Display only the relevant columns: PID, USER, %CPU, %MEM, and COMMAND
    ps aux --sort=-%cpu,-%mem | awk 'NR<=6 {print $1, $2, $3, $4, $11}' | column -t

    echo ""
}

# Function to display security diagnostics
security_diagnostics() {
    echo -e "${blue}Open Ports:${normal}"
    ss -tuln
    echo -e "\n${blue}Failed Login Attempts:${normal}"
    grep "Failed password" /var/log/auth.log | tail -n 5
    echo ""
}

# Function to display storage insights
storage_insights() {
    echo ""
    echo -e "${blue}Largest Files:${normal}"
    du -ah /  | sort -rh | head -n 10
    echo -e "\n${blue}Inode Usage:${normal}"
    df -i
    echo ""
}

# Function to display formatted load average and uptime
load_average() {
    echo ""
    # Extract and format uptime information
    uptime | awk -F'( |,|:)+' '{
        printf "System Uptime: %s days, %s hours, %s minutes\n", $6, $8, $9;
        printf "Logged-in Users: %s\n", $10;
        printf "Load Averages: 1 min: %s, 5 min: %s, 15 min: %s\n", $(NF-2), $(NF-1), $NF;
    }'
    echo ""
}

# Function to display bandwidth usage
bandwidth_usage() {
    if command -v vnstat &> /dev/null; then
        vnstat
    else
        echo -e "${red}vnstat is not installed. Please install it to monitor bandwidth.${normal}"
    fi
    echo ""
}

# Function to update and check VPS packages
update_and_check_vps_packages() {
    # Check for the package manager (apt)
    if command -v apt &> /dev/null; then
        # Check for upgradable packages
        upgradable_packages=$(apt list --upgradable 2>/dev/null)
        if [[ -z "$upgradable_packages" ]]; then
            echo -e "${green}No upgradable packages.${normal}" >&2
        else
            echo -e "${yellow}Upgradable packages detected.${normal}" >&2

            # Ask for confirmation
            message="${yellow}Would you like to update and upgrade the packages? (Y/n)${normal}"
            if handle_confirmation_prompt \
              "$message" "update_packages" "y" "5"; then
                echo ""

                # Update and upgrade without logging output
                echo -e "${yellow}Updating packages...${normal}"
                apt-get update -y > /dev/null 2>&1

                echo -e "${yellow}Upgrading packages...${normal}"
                apt-get upgrade -y > /dev/null 2>&1

                echo -e "${yellow}Removing unused packages...${normal}"
                apt-get autoremove -y > /dev/null 2>&1

                echo -e "${yellow}Cleaning up package cache...${normal}"
                apt-get clean > /dev/null 2>&1

                # Notify update completion
                echo -e "${green}Update complete!${normal}" >&2
            else
                echo -e "${red}Update aborted.${normal}" >&2
            fi
        fi
    else
        echo -e "${red}Package manager not supported.${normal}" >&2
    fi

    echo ""
}

#######################################################################################


# Function to show help
show_help() {
  local menu_options_count="$1"
  local page_size="$2"

  echo -e "${highlight_color}↗↘${reset_color}  - Navigate down- and upwards"

  # Check if there are more items than the page size
  if (( $menu_options_count > page_size )); then
    echo -e "${highlight_color}◁▷${reset_color}  - Navigate sideways"
  fi

  echo -e "${select_color}↵${reset_color}   - Select current option"
  echo -e "${back_color}g${reset_color}   - Go to specific page"
  echo -e "${back_color}r${reset_color}   - Return to menu begin"
  echo -e "${search_color}/${reset_color}   - Search on current menu"
  echo -e "${quit_color}q${reset_color}   - Quit the application"
  echo -e "${help_color}h${reset_color}   - Show this help menu"
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

# Function to build api url
get_api_url() {
  protocol="$1"
  url="$2"
  resource="$3"
  echo "https://$url/api/$resource"
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
  else  
    # Return the response body if successful
    echo "$response_body"
    return 0
  fi
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

# Function to trim leading/trailing spaces
trim() {
  pattern='s/^ *//;s/ *$//'
  echo "$1" | sed "$pattern"
}

# Function to check the key and set the boolean
set_move_boolean() {
  local key_to_check="$1"
  local key_value="$2"

  if [[ "$key_to_check" = "$key_value" ]]; then
    echo true
  else
    echo false
  fi
}

# Function to wait for a specified number of seconds
wait_secs() {
  local seconds=$1
  sleep "$seconds"
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

# Function to clean the local docker environment
clean_docker_environment() {
  highlight "Cleaning local docker environment"
  sanitize

  wait_for_input
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

################################ BEGIN OF VALIDATION-RELATED FUNCTION #############################

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

################################# END OF VALIDATION-RELATED FUNCTION ##############################

############################### BEGIN OF GENERAL UTILITARY FUNCTIONS #############################

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
  required_fields=$(list_stack_compose_required_fields "$stack_name")

  # Generate the JSON schema
  schema=$(generate_config_schema "$required_fields")

  # Step 5: Validate if the provided JSON has all required variables
  validate_json_from_schema "$config_json" "$schema"
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

# Function to confirm and modify prompt information
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

# Function to prompt user and wait for any key press
press_any_key() {
    # Prompt user and wait for any key press
    echo -e "${highlight_color}Press any key to continue...${normal}"
    
    # Wait for a single key press without the need to press Enter
    read -n 1 -s  # -n 1 means read one character, -s means silent mode (no echo)
    
    # Newline for better readability after key press
    echo ""
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

####################################################################

######################################## BEGIN OF MENU UTILS #######################################

# Function to get the label of a menu item
get_menu_item_label() {
  local menu_item="$1"
  query_json_value "$menu_item" ".label"
}

# Function to get the description of a menu item
get_menu_item_description() {
  local menu_item="$1"
  query_json_value "$menu_item" '.description'
}

# Function to get the action of a menu item
get_menu_item_action() {
  local menu_item="$1"
  query_json_value "$menu_item" '.action'
}

# Function to display a message, move the cursor, and read user input with an optional timeout
request_input() {
  local message="$1"
  local cursor_move="$2"
  local variable_name="$3"
  local timeout="$4"  # Optional timeout value in seconds

  echo -ne "$message" >&2
  tput cuf "$cursor_move" # Move cursor forward by the specified number of characters

  if [[ -n "$timeout" ]]; then
    read -rsn1 -t "$timeout" "$variable_name" || eval "$variable_name=''"  # Timeout or empty input
  else
    read -rsn1 "$variable_name" # No timeout
  fi
}

# Function to request confirmation (yes/no)
request_confirmation() {
  local message="$1"
  local confirm_variable_name="$2"
  local default_value="${3:-false}"
  local timeout="$4"

  local user_input=""
  request_input "$message" 1 user_input "$timeout"

  # Use default value if input is empty
  if [[ -z "$user_input" && "$default_value" != "false" ]]; then
    user_input="$default_value"
  fi

  # Validate the input
  while [[ ! "$user_input" =~ ^[yYnN]$ ]]; do
    # Display the error message and prompt again on a new line
    echo -e "${faded_color}\nInvalid input \"$user_input\"." >&2
    echo -e "Please enter 'y' for yes or 'n' for no.${reset_color}" >&2

    # Re-prompt the user
    request_input "$message" 1 user_input # Move 1 character forward
  done

  # Assign the validated input to the confirmation variable
  printf -v "$confirm_variable_name" "%s" "$user_input"
}

# Function to display invalid input message
display_invalid_input_message() {
    local input=$1
    local prompt_message=$2

    reason="Invalid input \"$input\""
    select_options="Please enter 'y' for yes or 'n' for no."
    invalid_message="${faded_color}$reason\n$select_options\n${reset_color}"

    # Print the invalid message
    echo -e "$invalid_message" >&2
    echo -ne "${faded_color}$prompt_message${reset_color}" >&2
}

# Function to handle confirmation prompt
handle_confirmation_prompt() {
    local prompt_message=$1
    local confirm_var=$2
    local default_value=${3:-false}
    local timeout=$4

    while true; do
        # Request confirmation from the user
        request_confirmation "$prompt_message" "$confirm_var" "$default_value" "$timeout"

        # Validate input
        case "${!confirm_var}" in
            [yY]) return 0 ;; # Confirmed
            [nN]) return 1 ;; # Declined
            *) display_invalid_input_message "${!confirm_var}" "$prompt_message" ;;
        esac
    done
}

# Function to truncate option text to a max length
truncate_option() {
  local option="$1"
  local max_length="${2-$TRUNCATED_DEFAULT_LENGTH}"
  if [[ ${#option} -gt $max_length ]]; then
    echo "${option:0:$((max_length - 3))}..."
  else
    echo "$option"
  fi
}

# Function to calculate total pages
calculate_total_pages() {
  local total_items="$1"    # Total number of items
  local items_per_page="$2" # Number of items per page

  # Calculate total pages, rounding up if necessary
  total_pages=$(((total_items + items_per_page - 1) / items_per_page))

  echo "$total_pages"
}

# Function to check if the current item is the first item on the page
is_first_page_item() {
  local current_item="$1" # Current item number (0-based index)
  local items_per_page="$2"

  # Check if the current item is the first item on the page
  # First items are those which are of the form: 0, p, 2p+1, 3p+2, ...
  local first_item_mod=$((current_item % items_per_page))
  if [ "$first_item_mod" -eq 0 ]; then
    echo "1" # Return 1 (true)
  else
    echo "0" # Return 0 (false)
  fi
}

# Function to check if the current item is the last item on the page
is_last_page_item() {
  local current_item="$1"   # Current item number (0-based index)
  local items_per_page="$2" # Items per page
  local total_items="$3"    # Total number of items

  # Calculate the last item index of the current page (0-based)
  # Last items are those which are of the form: p-1, 2p, 3p+1, ...
  local last_item_mod=$(((current_item + 1) % items_per_page))
  if [ "$last_item_mod" -eq 0 ] || [ "$current_item" -eq "$((total_items - 1))" ]; then
    echo "1" # Return 1 (true)
  else
    echo "0" # Return 0 (false)
  fi
}

# Function to check if there is movement to a new page
is_new_page_handler() {
  local key="$1"
  local current_idx="$2"
  local num_options="$3"
  local page_size="$4"

  # Calculate total pages
  local total_pages=$(((num_options + page_size - 1) / page_size)) # ceiling division
  local more_than_one_page=$((total_pages > 1))

  # Get booleans for navigation keys
  local move_up_bool=$(to_integer "$(set_move_boolean "$key" "$up_key")")
  local move_down_bool=$(to_integer "$(set_move_boolean "$key" "$down_key")")
  local move_left_bool=$(to_integer "$(set_move_boolean "$key" "$left_key")")
  local move_right_bool=$(to_integer "$(set_move_boolean "$key" "$right_key")")

  # Check for first and last page items
  is_first_page_item_bool=$(is_first_page_item "$current_idx" "$page_size")
  is_last_page_item_bool=$(is_last_page_item "$current_idx" "$page_size" "$num_options")

  # Determine if there is movement to a new page
  local move_sideways=$((move_left_bool || move_right_bool))
  local move_up_first_page=$((is_first_page_item_bool && move_up_bool))
  local move_down_last_page=$((is_last_page_item_bool && move_down_bool))

  # Determine if it's a new page
  local is_new_page=$((
    more_than_one_page && \
    (move_sideways || move_down_last_page || move_up_first_page)
))

  # Output result
  echo "$is_new_page"
}

# Custom function to join an array into a single string with a delimiter
join_array() {
  local delimiter="$1"
  shift
  local array=("$@")
  local result=""

  for item in "${array[@]}"; do
    if [ -z "$result" ]; then
      result="$item"
    else
      result+="$delimiter$item"
    fi
  done

  echo "$result"
}

# Improved and fancy header display using '=' and '|', with colorized minus signs
show_header() {
    local header="$1"
    local width=${2:-$HEADER_WIDTH}     # Default width to 50 if not provided
    local border_color="\033[1;34m"     # Blue border color
    local header_color="\033[1;37m"     # White text for header
    local reset_color="\033[0m"         # Reset color

    # Create the top and bottom border with colorized minus signs
    local border=$(printf '%*s' $((width-2)) '' | tr ' ' '-')
    local colorized_lu_border="${border//-/${border_color}-}"
    
    # Print top border
    echo -e "${border_color}+${reset_color}${colorized_lu_border}${border_color}+${reset_color}"

    # Print header with padding
    local colorized_side_border="${border_color}|${reset_color}"
    local colorized_header="${header_color}${header}${reset_color}"
    local left_padding=$(( (width - ${#header}) / 2 ))
    local right_padding=$((width - ${#header} - left_padding - 2))
    local spaced_header="$(\
      printf '%*s' $left_padding '')$colorized_header$(printf '%*s' $right_padding '')"

    # Print the header inside borders
    printf "${colorized_side_border}${spaced_header}${colorized_side_border}\n"

    # Print bottom border
    echo -e "${border_color}+${reset_color}${colorized_lu_border}${border_color}+${reset_color}"
}

# Define individual menu item
build_menu_item() {
  local label="$1"
  local description="$2"
  local action="$3"

  # Validate inputs
  if [ -z "$label" ] ||  [ -z "$action" ]; then
    echo "Error: Missing argument(s). Arguments (label, action) are required." >&2
    return 1
  fi

  # Generate JSON object using jq directly
  jq -n \
    --arg label_ "$label" \
    --arg description_ "$description" \
    --arg action_ "$action" \
    '{
        label: $label_,
        description: $description_,
        action: $action_
    }'
}

# Remove one of the redundant build_menu functions
build_menu() {
  local title="$1"
  shift
  local page_size="$1"
  shift
  local json_array

  if [ $# -eq 0 ]; then
    echo "Error: At least one menu item is required."
    return 1
  fi

  # Build the menu as a JSON array
  menu_items=$(build_array_from_items "$@")

  # Create final menu object
  jq -n \
    --arg title "$title" \
    --arg page_size "$page_size" \
    --argjson items "$menu_items" \
    '{
      title: $title,
      page_size: $page_size,
      items: $items
    }'
}

# Append a menu object to the MENUS array
define_menu() {
    local key="$1"
    local menu_object="$2"

    
    MENUS["$key"]+="$menu_object"
}

# Function to get the current menu
get_current_menu() { 
  if [ ${#menu_navigation_history[@]} -gt 0 ]; then
    echo "${menu_navigation_history[-1]}"
  fi
}

# Function to get a specific menu
get_menu() { 
  echo "${MENUS[$1]}"
}

# Modify push_menu to accept multiple levels of nesting
push_menu_in_history() { 
    if [[ -n "$1" ]]; then
        menu_navigation_history+=("$1")
    else
        echo "Invalid menu name. Cannot push an empty menu."
    fi
}

# Pop menu from stack
pop_menu_from_history() {
    if [ ${#menu_navigation_history[@]} -gt 0 ]; then
        unset menu_navigation_history[-1]
    fi
}

# Helper function to check if a menu is already in the stack
is_menu_in_history() {
    local menu_name=$1
    for menu in "${menu_navigation_history[@]}"; do
        if [[ "$menu" == "$menu_name" ]]; then
            return 0  # menu found
        fi
    done
    return 1  # menu not found
}

# Return to the parent menu (previous menu)
return_to_parent_menu() {
    if [ ${#menu_navigation_history[@]} -gt 1 ]; then
        pop_menu
        local parent_menu=$(get_current_menu)
        navigate_menu "$parent_menu"
    else
        navigate_menu "Main"
    fi
}

# Build a JSON array of menu items
build_array_from_items() {
  # Capture all arguments as an array
  local items=("$@")

  echo "["$(join_array "," "${items[@]}")"]"
}

# Append a JSON menu array to the MENUS array under a specific key
build_menu() {
  local title=$1
  shift
  local page_size=$1
  shift
  local json_array

  if [ $# -eq 0 ]; then
    echo "Error: At least one menu item is required."
    return 1
  fi

  # Build the menu as a JSON array
  menu_items=$(build_array_from_items "$@")

  # Create final menu object
  jq -n \
    --arg title "$title" \
    --arg page_size "$page_size" \
    --argjson items "$menu_items" \
    '{
            title: $title,
            page_size: $page_size,
            items: $items
        }'
}

# Function to calculate the page number
index_to_page() {
  local current_index="$1"
  local page_size="$2"

  # Check for valid inputs
  if [[ -z "$current_index" || -z "$page_size" || "$page_size" -le 0 ]]; then
    echo "Invalid arguments: current_index=$current_index, page_size=$page_size" >&2
    return 1
  fi

  # Calculate the page number (zero-indexed)
  local page_number=$((current_index / page_size + 1))

  # Output the calculated page number
  echo "$page_number"
}

# Function to move the cursor
move_cursor() {
  # $1 is the row (line) position
  # $2 is the column position
  echo -e "\033[$1;${2}H"
}

# Function to clear everything below a specific line
clear_below_line() {
  local line=$1

  # Move the cursor to the desired line (line is zero-indexed)
  tput cup "$line" 0

  # Clear everything below the current line
  tput ed
}

# Function to calculate the arrow position in the terminal
get_arrow_position() {
  local current_idx="$1"
  local page_size="$2"
  local header_row_count="$3"

  # Calculate the start index for the current page
  local start=$((current_idx / page_size * page_size))

  # Calculate the arrow row position based on header lines and current item
  local arrow_row=$((header_row_count + (current_idx - start)))

  echo "$arrow_row"
}

# Function to process all lines in parallel and maintain order
display_parallel() {
  local -n _lines=$1 # Array passed by reference
  local -a pids=()   # Array to hold process IDs

  # Process each line in parallel
  for i in "${!_lines[@]}"; do
    line="${_lines[i]}"
    {
      echo -e "$line"
    } &
    pids+=($!) # Store the process ID for each background process
  done

  # Wait for all processes to finish
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

kill_current_pid(){
  # Start the scrolling message for the selected option
  if [[ "$current_pid" -ne 0 ]]; then
      kill "$current_pid" 2>/dev/null  # Kill the previous background process
  fi
}

# Cleanup function to restore terminal state and stop background processes
cleanup() {
    tput cnorm  # Restore cursor visibility
    kill_current_pid
    tput reset  # Reset terminal to a clean state
    echo -e '\e[5 q' # Restore cursor shape
}

# Function to display a great farewell message
farewell_message() {
  farewell_messages=(
    ""
    "🌟 Thank you for using the Deployment Tool Stackme! 🌟"
    ""
    "Your journey doesn't end here: it's just a new beginning."
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

finish_session() {
    cleanup
    exit 0;
}

# Trap SIGINT (Ctrl+C) and EXIT (script termination) to invoke the cleanup function
trap finish_session SIGINT EXIT

# Function to shift a message in the background
shift_message() {
    local message="$1"
    local max_width="$2"
    local x_position="$3"
    local y_position="$4"
    local shifted_message="$message"
    local shift_offset=0

    tput civis  # Hide the cursor
    while true; do
        # Prepare the shifted message
        local rotated_message="${shifted_message:shift_offset}${shifted_message:0:shift_offset}"
        rotated_message="${rotated_message:0:$max_width}"

        # Move cursor to the specified position and print the message
        tput cup "$y_position" "$x_position"
        printf "%-*s" "$max_width" "$rotated_message"

        # Increment the shift offset
        ((shift_offset++))
        if [[ "$shift_offset" -ge ${#shifted_message} ]]; then
            shift_offset=0
        fi

        sleep 0.15
    done
}

# Function to start the scrolling message for the selected option
run_shift_message(){
  local current_idx="$1"
  local page_size="$2"
  local header_row_count="$3"
  local menu_options=("${@:4}")

  # Start the scrolling message for the selected option
  kill_current_pid

  # Get the current option
  current_option="${menu_options[current_idx]}"
  item_label="$(get_menu_item_label "$current_option")"
  item_description="$(get_menu_item_description "$current_option")"
  item_label_length="${#item_label}"
  
  # Calculate the arrow row position based on header lines and current item
  # FIXME: Hard-coded, Try a dynamic approach
  header_row_count="2"
  arrow_position="$(get_arrow_position "$current_idx" "$page_size" "2")"
  horizontal_shift=$((header_row_count+item_label_length+2))

  shift_length="$TRUNCATED_DEFAULT_LENGTH"

  shift_message \
    "$item_description " "$shift_length" "$horizontal_shift" "$arrow_position" &
  current_pid=$!  # Store the background process ID
}

# Helper: Calculate the range of options to display
calculate_display_range() {
  local current_idx="$1"
  local page_size="$2"
  local num_options="$3"

  local start=$((current_idx / page_size * page_size))
  local end=$((start + page_size))
  end=$((end > num_options ? num_options : end))

  echo "$start $end"
}

# Helper: Render menu options
render_options() {
  local start="$1"
  local end="$2"
  local current_idx="$3"
  local header_row_count="$4"
  local menu_options=("${@:5}")

  local menu_lines=()

  for i in $(seq $start $((end - 1))); do
    option_label=$(get_menu_item_label "${menu_options[i]}")
    option_desc=$(get_menu_item_description "${menu_options[i]}")
    truncated_option_desc="$(truncate_option "$option_desc")"
    
    if [[ -z "$option_desc" ]]; then
      option="${option_label}"
    else
      option="${option_label}: ${truncated_option_desc}"
    fi
    
    
    menu_lines+=("$option")
  done

  # Fill remaining space if fewer items than page size
  local remaining_space=$((end - start))
  for _ in $(seq 1 $remaining_space); do
    menu_lines+=(" ")
  done

  # Render each menu line
  for i in "${!menu_lines[@]}"; do
    tput cup $((i + header_row_count)) 0
    local menu_line="${menu_lines[$i]}"
    if [[ $((start + i)) -eq $current_idx ]]; then
      echo -e "${COLORED_ARROW} ${menu_line}" >&2
    else
      echo -e "  ${menu_line} " >&2
    fi
  done
}

# Helper: Render the header with title and keyboard shortcuts
render_header() {
  local title="$1"
  local page_width="$2"
  
  tput cup 0 0
  echo "$(display_text "$title" "$page_width" --center)" >&2
  echo >&2
}

# Function to print a centered header with customizable width
print_centered_header() {
    local text="$1"
    local width="$2"
    local padding

    # Calculate padding for centering
    padding=$(( (width - ${#text}) / 2 ))

    # Print the header with padding
    printf "%-${padding}s" " "  # Left padding
    echo -e "${bold}${green}${text}${normal}"
    printf "%-${padding}s" " "  # Right padding
}

# Render breadcrumb trail
render_breadcrumb() {
  local breadcrumb=""
  for menu in "${menu_navigation_history[@]}"; do
    breadcrumb+="$menu > "
  done
  breadcrumb=${breadcrumb% > }
  echo -e "${highlight_color}Current Path: ${breadcrumb}${reset_color}" >&2
}

# Helper: Render the footer with page count and navigation
render_footer() {
  local current_idx="$1"
  local page_size="$2"
  local page_width="$3"
  local num_options="$4"
  local keyboard_options_string="$5"

  local total_pages=$(((num_options + page_size - 1) / page_size))
  local current_page=$((current_idx / page_size + 1))
  local page_text="Page $current_page/$total_pages"

  # Display keyboard options
  tput cup $((page_size + 3)) 0
  echo -e "$keyboard_options_string" >&2

  render_breadcrumb
  tput cup $((page_size + 4)) 0

  # Display page text
  tput cup $((page_size + 5)) 0
  echo -e "\n$(display_text "$page_text" "$page_width" --center)" >&2
}

# Main: Render the menu with the given parameters
render_menu() {
  tput civis
  local title="$1"
  local current_idx="$2"
  local page_size="$3"
  local is_new_page="$4"
  local menu_options=("${@:5}")

  # Disable keyboard input temporarily
  stty -echo -icanon
  trap "stty echo icanon; tput cnorm; exit" SIGINT SIGTERM EXIT  # Ensure cleanup

  local num_options=${#menu_options[@]}

  current_menu_name="$(get_current_menu)"

  # Prepare keyboard shortcuts
  local ud_nav_option="${highlight_color}↗↘${reset_color}: Nav"
  local sel_nav_option="${select_color}↵${reset_color}: Sel"
  local goto_nav_option=""
  local back_option="${back_color}r${reset_color}: Return"
  local search_option="${search_color}/${reset_color}: Search"
  local help_option="${help_color}h${reset_color}: Help"
  local quit_option=""
  local lr_nav_option=""

  if (( num_options > page_size )); then
    lr_nav_option="${highlight_color}◁▷${reset_color}: Pages"
  fi

  if (( num_options / page_size > 1 )); then
    goto_nav_option="${goto_color}g${reset_color}: Go to Page"
  fi

  if [[ $current_menu_name == "Main" ]]; then
    quit_option="${quit_color}q${reset_color}: Quit"
  else
    quit_option="${quit_color}q${reset_color}: Back"
  fi

  # Combine keyboard options
  local keyboard_options=(
    "$ud_nav_option"
    "$lr_nav_option"
    "$sel_nav_option"
    "$search_option"
    "$goto_nav_option"
    "$back_option"
    "$quit_option"
    "$help_option"
  )
  local keyboard_options_string=$(join_array ", " "${keyboard_options[@]}")
  
  local tmp="$(strip_ansi "$keyboard_options_string")"
  local page_width="${#tmp}"

  # Handle new page rendering
  if [[ "$is_new_page" == "1" ]]; then
    clear
  fi

  # Render header
  render_header "$title" "$page_width"
  echo >&2
  
  # Determine the range of options to display
  local range
  range=$(calculate_display_range "$current_idx" "$page_size" "$num_options")
  local start end
  read -r start end <<< "$range"

  # Render menu options
  local header_row_count=2
  render_options "$start" "$end" "$current_idx" "$header_row_count" "${menu_options[@]}"

  # Render footer
  render_footer "$current_idx" "$page_size" "$page_width" "$num_options" "$keyboard_options_string"

  # Handle option-specific description
  local current_option_desc
  current_option_desc=$(get_menu_item_description "${menu_options[$current_idx]}")
  if [[ ${#current_option_desc} -gt $TRUNCATED_DEFAULT_LENGTH ]]; then
    run_shift_message "$current_idx" "$page_size" "$header_row_count" "${menu_options[@]}"
  else
    kill_current_pid
  fi

  # Re-enable keyboard input
  stty echo icanon
  
  trap - SIGINT SIGTERM EXIT  # Clear trap
}

# Helper: Handle arrow key input
handle_arrow_key() {
  local key="$1"
  local current_idx="$2"
  local num_options="$3"
  local page_size="$4"
  local total_pages="$5"

  case "$key" in
    "$up_key")
      if ((current_idx > 0)); then
        ((current_idx--))
      else
        current_idx=$((num_options - 1))  # Wrap to the last option
      fi
      ;;

    "$down_key")
      if ((current_idx < num_options - 1)); then
        ((current_idx++))
      else
        current_idx=0  # Wrap to the first option
      fi
      ;;

    "$left_key")
      if ((total_pages > 1)); then
        if ((current_idx - page_size >= 0)); then
          # Navigate to the previous page
          current_idx=$(((current_idx / page_size - 1) * page_size))
        else
          # Wrap to the last page
          current_idx=$((((num_options - 1) / page_size) * page_size))
        fi
      fi
      ;;

    "$right_key")
      if ((total_pages > 1)); then
        next_page_start=$(((current_idx / page_size + 1) * page_size))
        if ((next_page_start < num_options)); then
          current_idx=$next_page_start  # Move to the next page
        else
          current_idx=0  # Wrap to the first page
        fi
      fi
      ;;
  esac

  echo "$current_idx"
}

# Function to validate page number
validate_page_number() {
    local page_number="$1"
    local max_page="$2"

    if ! [[ "$page_number" =~ ^[1-9][0-9]*$ ]]; then
        echo "Invalid input! Must be a number."
        return 1
    elif ((page_number > max_page)); then
        echo "Page number out of range!"
        return 1
    fi
    return 0
}

# Function to navigate to a specific page
go_to_specific_page() {
  local current_idx="$1"
  local page_size="$2"
  local title="$3"
  local is_new_page="$4"
  shift 5
  local menu_options=("$@")

  num_options=${#menu_options[@]}
  
  echo -ne "${faded_color}Enter the page number: ${reset_color}" >&2
  read -e -r page_number  # Input with no echo

  # Validate page number
  validate_page_number "$page_number" "$(((num_options - 1) / page_size + 1))"

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  # Update current index to new page
  current_idx=$((page_number * page_size))
  render_menu \
    "$title" "$current_idx" \
    "$page_size" "$is_new_page" "${menu_options[@]}"

  # Prompt to return to the previous menu
  while true; do
    message="Would you like to return to the previous menu? (y/n): "
    echo -ne "${faded_color}$message${reset_color}" >&2
    read -r go_back_choice
    case "$go_back_choice" in
      [yY])
        current_idx=$previous_idx
        break
        ;;
      [nN])
        break
        ;;
      *)
        echo -e "${error_color}Invalid choice! Please enter 'y' or 'n'.${reset_color}" >&2
        ;;
    esac
  done

  echo "$current_idx"
}

handle_enter_key(){
  local menu_item="${menu_options[current_idx]}"

  option_label="$(get_menu_item_label "$menu_item")"
  question="Are you sure you want to select \"$option_label\"? (Y/n)"
  message="${faded_color}$question${reset_color}"
  if handle_confirmation_prompt "$message" confirm 'n'; then
      option_action=$(get_menu_item_action "$menu_item")

      clean_screen
      kill_current_pid

      message="\n${faded_color}Operation interrupted. Exiting script...${reset_color}"
      command="clean_screen; error \"$message\"; return"
      trap "$command" SIGINT

      (eval "$option_action") || echo -e "$message"
      sleep 1

      trap - SIGINT

      clean_screen
  fi
}

handle_quit_key(){
  message="${faded_color}Are you sure you want to exit this menu? (y/n)${reset_color}"
  request_confirmation "$message" confirm_exit false

  if [[ "${confirm_exit}" == "y" || "${confirm_exit}" == "Y" ]]; then
    clean_screen
    current_menu=$(get_current_menu)
    pop_menu_from_history
    previous_menu=$(get_current_menu)

    if [[ "$current_menu" == "Main" ]]; then
      message="${faded_color}Exiting program.${reset_color}"
    else
      message="${faded_color}Returning to $previous_menu menu.${reset_color}"
    fi

    echo -e "$message" >&2
    sleep 0.25

    return 0
  fi

  return 1
}

handle_search_key(){
  local current_idx="$1"                    # Reference to the current index
  local -n menu_options_ref="$2"            # Reference to the menu options array
  local -n original_menu_options_ref="$3"   # Reference to the original menu options array
  
  echo -ne "${faded_color}Search: ${reset_color}" >&2
  read -e -r search_key

  # Clear the line if the prompt disappears after backspace
  echo -ne "\033[2K\r"

  if [[ "$search_key" == "r" ]]; then
    menu_options_ref=("${original_menu_options_ref[@]}")
    return
  fi

  local filtered_options=()
  for option in "${original_menu_options_ref[@]}"; do
    label=$(echo "$option" | jq -r '.label // empty')
    description=$(echo "$option" | jq -r '.description // empty')
    if [[ "$label" == *"$search_key"* || "$description" == *"$search_key"* ]]; then
      filtered_options+=("$option")
    fi
  done

  if [[ ${#filtered_options[@]} -eq 0 ]]; then
    menu_options_ref=("${original_menu_options_ref[@]}")
    warning "No matches found, resetting to original options."
    sleep 0.5
  else
    menu_options_ref=("${filtered_options[@]}")
    current_idx=0
  fi

  echo $current_idx
}

# Enhanced animated transition between menus with spinning loader and text effects
transition_to_menu() {
  local new_menu="$1"
  local progress_bar=""
  local progress_length=30
  local colors=("\033[1;34m" "\033[1;32m" "\033[1;36m" "\033[1;35m" "\033[1;31m")
  local spin_chars=('/' '-' '\\' '|')
  
  # Clear the line and show the initial transition message
  echo -ne "\r${colors[0]}Transitioning to ${new_menu}... ${reset_color}" >&2

  for ((i=0; i<progress_length; i++)); do
    # Update the progress bar
    progress_bar+="="
    
    # Cycle through colors for a smooth transition effect
    color_index=$((i % ${#colors[@]}))
    
    # Add spinning loader
    spin_index=$((i % ${#spin_chars[@]}))
    spin_char="${spin_chars[$spin_index]}"

    message="${spin_char} Transitioning to ${new_menu}... [${progress_bar}]"
    echo -ne "\r${colors[color_index]}$message${reset_color}" >&2

    # Delay to create the animation effect
    sleep 0.05
  done

  # Finalize the transition with a fade-in effect
  message="${spin_char} Transitioning to ${new_menu}... [${progress_bar}] Done!"
  echo -ne "\r${highlight_color}$message${reset_color}\n" >&2
  sleep 0.3
}


# Function to navigate to a specific menu
navigate_menu() {
  local menu_name="$1"

  echo "$menu_name" >&2

  clean_screen
  transition_to_menu "$menu_name"
  clean_screen
  
  menu_json=$(get_menu "$menu_name") || {
    error "Failed to load menu ${menu_name}" >&2
    return 1
  }

  # If the menu_navigation_history is empty, set the first menu as the current menu
  if ! is_menu_in_history "$menu_name"; then
      push_menu_in_history "$menu_name"
  fi

  local title page_size menu_items_json
  local menu_options=()
  local debounce_time=0.25
  
  title=$(jq -r '.title' <<<"$menu_json")
  page_size=$(jq -r '.page_size' <<<"$menu_json")
  menu_items_json=$(jq -r '.items' <<<"$menu_json")

  # Convert JSON array to Bash array
  while IFS= read -r item; do
    menu_options+=("$item")
  done < <(jq -r '.[] | @json' <<<"$menu_items_json")

  local original_menu_options=("${menu_options[@]}")
  local num_options=${#menu_options[@]}

  local total_pages is_new_page=1 previous_idx=0 current_idx=0

  if [[ $num_options -eq 0 ]]; then
    message="${error_color}Error: No options provided to the menu!${reset_color}"
    echo -e "$message" >&2
    exit 1
  fi

  while true; do
    render_menu \
        "$title" "$current_idx" \
        "$page_size" "$is_new_page" "${menu_options[@]}"

    # Locking the keyboard input to avoid unnecessary display of captured characters
    read -rsn1 user_key

    # FIXME: Header, keyboard shortcuts and page counting may be dynamic
    menu_line_count=$((page_size+7))
    kill_current_pid
    move_cursor $menu_line_count 0

    # Dynamically calculate the vertical position for the message
    num_options=${#menu_options[@]}
    total_pages="$(calculate_total_pages "$num_options" "$page_size")"

    # Save for later usage
    previous_idx=$current_idx

    case "$user_key" in
    $'\x1B')  # Detect escape sequences (e.g., arrow keys)
      read -rsn2 -t "$debounce_time" user_key
      is_new_page=$(is_new_page_handler "$user_key" "$current_idx" "$num_options" "$page_size")

      # Call the function to handle arrow key input
      current_idx=$(\
        handle_arrow_key "$user_key" \
          "$current_idx" "$num_options" "$page_size" "$total_pages"
      )
      ;;

    # Go to specific page
    "g")
        previous_idx="$current_idx"

        current_idx="$(
          go_to_specific_page "$current_idx" \
            "$page_size" "$title" "$is_new_page" "$menu_options"
        )"
        
        is_new_page="$current_idx"!="$previous_idx"  
        ;;

    # Reset menu options
    "r")
      menu_options=("${original_menu_options[@]}")
      current_idx=0
      continue
      ;;

    # Start search
    "/")
        current_idx=$(\
          handle_search_key "$current_idx" menu_options original_menu_options
        )

        is_new_page=1
        ;;

    # Show help
    "h")
      show_help "$num_options" "$page_size"
      sleep 2
      ;;

    # Enter key (select option)
    "")
      echo >&2
      handle_enter_key "${menu_options[current_idx]}"
      ;;

    # Exit menu
    "q")
      handle_quit_key

      if [[ "$?" -eq 0 ]]; then
        break
      else
        continue
      fi
      ;;

    *)
      echo >&2
      shoutout="Invalid key pressed!"
      keyboard_options="Please use ↑/↓ to navigate, ←/→ to switch pages, or Enter to select."
      message="${error_color}$shoutout $keyboard_options${reset_color}"
      echo -e "$message" >&2
      sleep 1
      ;;
    esac

    clear_below_line $menu_line_count
  done
}

######################################### END OF MENU UTILS ########################################

################################## BEGIN OF DOCKER DEPLOYMENT UTILS ################################

# Function to get the latest stable version
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
list_stack_compose_required_fields() {
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

################################### END OF DOCKER DEPLOYMENT UTILS ################################

################################ BEGIN OF PORTAINER DEPLOYMENT UTILS ##############################

# Function to check if Portainer credentials are correct
is_portainer_credentials_correct() {
  local portainer_url="$1"
  local credentials="$2"

  if [[ -z "$credentials" ]]; then
    error "No credentials provided."
    return 1
  fi

  if [[ "$credentials" != *"username"* || "$credentials" != *"password"* ]]; then
    error "Invalid credentials format."
    return 1
  fi

  protocol="https"
  content_type="application/json"
  resource='auth'

  url="$(\
    get_api_url "$protocol" "$portainer_url" "$resource"\
  )"

  response=$(\
    curl -k -s -X POST -H "Content-Type: $content_type" -d "$credentials" "$url" \
  )

  # Check if the response contains a valid token
  token=$(echo "$response" | jq -r .jwt)

  if [[ "$token" == "null" || -z "$token" ]]; then
    error "Invalid credentials" >&2
    return 1 # Exit with status 1 for failure
  else
    error "Valid credentials" >&2
    return 0 # Exit with status 0 for success
  fi
}

# Function to signup on portainer
signup_on_portainer(){
  local portainer_url="$1"
  local new_username="$2"
  local new_password="$3"

  local protocol="https"
  local content_type="application/json"
  local credentials="{\"Username\":\"$new_username\",\"Password\":\"$new_password\"}"
  local resource='users/admin/init'

  url="$(get_api_url $protocol $portainer_url $resource)"

  response=$(\
    curl -k -s -X POST "$url" -H "Content-Type: $content_type" -d "$credentials"\
  )

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
  local credentials="$2"

  if [[ -z "$credentials" ]]; then
    error "No credentials provided."
    return 1
  fi

  if [[ "$credentials" != *"username"* || "$credentials" != *"password"* ]]; then
    error "Invalid credentials format."
    return 1
  fi

  if ! is_portainer_credentials_correct "$portainer_url" "$credentials"; then
    error "Invalid credentials."
    return 1
  fi

  local token=""

  protocol="https"
  method="POST"
  content_type="application/json"
  
  resource='auth'

  url="$(get_api_url $protocol $portainer_url $resource)"

  token=$(
    curl -k -s \
      -X POST \
      -H "Content-Type: $content_type" \
      -d "$credentials" "$url" |
      jq -r ".jwt"
  )

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

  url="$(\
    get_api_url "$protocol" "$portainer_url" "$resource" \
  )"

  endpoint_id="$(
    filtered_request "$method" "$url" "$token" \
      "$content_type" "$data" "$jq_filter"
  )"

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

  url="$(\
    get_api_url "$protocol" "$portainer_url" "$resource" \
  )"

  local swarm_id
  swarm_id=$(
    filtered_request "$method" "$url" \
      "$token" "$content_type" "$data" "$jq_filter"
  )

  if [[ -z "$swarm_id" ]]; then
    error "Failed to retrieve Swarm ID."
    exit 1
  fi

  echo "$swarm_id"
}

# Function to get stacks from Portainer
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

  url="$(\
    get_api_url "$protocol" "$portainer_url" "$resource"
  )"

  local swarm_id
  stacks=$(
    request "$method" "$url" \
      "$token" "$content_type" \
      "$data"
  )

  # Check if any stacks were returned
  if [[ "$stacks" -eq 0 ]]; then
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

  if [[ "$token" != "" ]]; then
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
      filtered_request "$method" "$url" "$token" \
        "$content_type" "$data" "$jq_query"
    )

    # Check if stack ID was retrieved
    if [[ -z "$stack_id" ]]; then
      echo ""
      return 1
    fi

    # If stack ID is found, return the ID
    echo "$stack_id"
    return 0
  else
    error "Portainer token is not provided. Skipping stack check."
    return 1
  fi
}

# Function to upload a stack
upload_stack_on_portainer() {
  local portainer_url="$1"
  local credentials="$2"
  local stack_name="$3"
  local compose_file="$4"

  highlight "Uploading stack $stack_name on Portainer $portainer_url"

  token="$(get_portainer_auth_token "$portainer_url" "$credentials")"

  if [[ -z "$token" ]] || [[ "$token" == "" ]]; then
    error "Failed to retrieve Portainer token."
    return 1
  fi

  # Swarm ID and endpoint id is required for Swarm stack deployments
  local swarm_id

  endpoint_id="$(get_portainer_endpoint_id "$portainer_url" "$token")"
  if [[ -z "$endpoint_id" ]]; then
    error "Failed to retrieve Endpoint ID."
    return 1
  fi

  swarm_id=$(get_portainer_swarm_id "$portainer_url" "$token" "$endpoint_id")
  if [[ -z "$swarm_id" ]]; then
    error "Failed to retrieve Swarm ID."
    return 1
  fi

  # Upload the stack
  info "Uploading stack: ${stack_name}..."
  resource="stacks/create/swarm/file"
  content_type="application/json"
  url="$(get_api_url "https" "$portainer_url" "$resource")"

  curl -s -k -X POST \
    -H "Authorization: Bearer $token" \
    -F "Name=$stack_name" \
    -F "file=@$compose_file" \
    -F "SwarmID=$swarm_id" \
    -F "endpointId=$endpoint_id" \
    "$url" &&
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

  request "DELETE" "$url" "$token" "application/json" &&
    success "Stack '$stack_name' deleted successfully." ||
    error "Failed to delete stack '$stack_name'."
}

################################# END OF PORTAINER DEPLOYMENT UTILS ###############################

############################### BEGIN OF GENERAL DEPLOYMENT FUNCTIONS #############################

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

# Function to deploy a traefik service
deploy_stack_pipeline() {
  local stack_name="$1"

  # Generate the n8n service JSON configuration using the helper function
  local config_json
  config_json=$(generate_config_traefik)

  if [ -z "$config_json" ]; then
    failed_stack_configuration_message "$stack_name"
    return 1
  fi

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  echo "$config_json" >&2

  # Deploy the n8n service using the JSON
  build_and_deploy_stack "$stack_name" "$config_json"
}

################################ END OF GENERAL DEPLOYMENT FUNCTIONS ##############################

####################################### BEGIN OF E-MAIL UTILS #####################################

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

# Function to generate HTML for an email
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

######################################## END OF E-MAIL UTILS ######################################

###################################### BEGIN OF SETUP FUNCTIONS ###################################

# Function to check if a package is already installed
is_package_installed() {
  local package="$1"
  dpkg -l | grep -q "$package"
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

# Function to prepare the environment
update_and_install_packages() {
  # Function constants
  local total_steps=3

  # Check if the script is running as root
  if [ "$EUID" -ne 0 ]; then
    failure "Please run this script as root or use sudo."
    exit 1
  fi

  highlight "Preparing environment"

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
  packages=(
    "sudo" "apt-utils" "apparmor-utils" "jq" "python3" 
    "docker" "figlet" "swaks" "netcat" "vnstat"
  )
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

# Function to install Docker
install_docker() {
  # Ensure the script is running with elevated privileges
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root or with sudo." >&2
    return 1
  fi

  info "Installing Docker..."

  # Download and execute the Docker installation script
  if curl -fsSL https://get.docker.com | bash > /dev/null 2>&1; then
    success "Docker installation script executed successfully."
  else
    failure "Failed to download or execute the Docker installation script." >&2
    return 1
  fi

  # Enable Docker service
  if systemctl enable docker > /dev/null 2>&1; then
    success "Docker service enabled to start on boot."
  else
    failure "Failed to enable Docker service." >&2
    return 1
  fi

  # Start Docker service
  if systemctl start docker > /dev/null 2>&1; then
    success "Docker service started successfully."
  else
    failure "Failed to start Docker service." >&2
    return 1
  fi

  success "Docker installation and setup completed successfully."
  return 0
}

# Function to merge server, network, and IP information
get_server_info() {
  local server_array ip_object merged_result

  # Get the server and network information
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

  server_array="$(run_collection_process "$items")"
  if [[ "$server_array" == "[]" ]]; then
    error "Unable to retrieve server and network names."
    exit 1
  fi

  # Print the merged result
  echo "$server_array"
}

# Function to initialize the server information
initialize_server_info() {
  total_steps=6
  server_filename="server_info.json"

  # Step 1: Check if server_info.json exists and is valid
  message="Initialization of server information"
  step_progress 1 $total_steps "$message"
  if [[ -f "$server_filename" ]]; then
    server_info_json=$(cat "$server_filename" 2>/dev/null)
    if jq -e . >/dev/null 2>&1 <<<"$server_info_json"; then
      step_info 1 $total_steps "Valid $server_filename found. Using existing information."
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
    echo "$server_info_json" | jq -r '.[] | select(.name=="server_name") | .value'
  )
  network_name=$(
    echo "$server_info_json" | jq -r '.[] | select(.name=="network_name") | .value'
  )

  # Output results
  if [[ -z "$server_name" || -z "$network_name" ]]; then
    error "Missing server_name or network_name in file $server_filename"
    exit 1
  fi

  # Set Hostname
  step_message="Set Hostname"
  step_progress 2 $total_steps "$step_message"
  hostnamectl set-hostname "$server_name" 2>&1
  handle_exit $? 2 $total_steps "$step_message"

  # Update /etc/hosts
  step_message="Add name to server name in hosts file at path /etc/hosts"
  step_progress 3 $total_steps "$step_message"
  sed -i "s/127.0.0.1[[:space:]]localhost/127.0.0.1 $server_name/g" /etc/hosts 2>&1
  handle_exit $? 3 $total_steps "$step_message"

  # Install docker
  step_message="Installing Docker"
  step_progress 4 $total_steps "$step_message"
  install_docker
  handle_exit $? 4 $total_steps "$step_message"

  # Initialize Docker Swarm
  step_message="Docker Swarm initialization"
  step_progress 5 $total_steps "$step_message"

  if is_swarm_active; then
    step_warning 5 $total_steps "Swarm is already active"
  else
    server_ip=$(
      echo "$server_info_json" | 
      jq -r '.[] | select(.name=="server_ip") | .value'
    )

    docker swarm init 2>&1
    
    handle_exit $? 5 $total_steps "$step_message"
  fi

  # Initialize Network
  message="Network initialization"
  step_progress 6 $total_steps "$message"
  create_network_if_not_exists "$network_name"
  handle_exit $? 6 $total_steps "$step_message"

  success "Server initialization complete"

  wait_for_input
}

####################################### BEGIN OF COMPOSE FILES #####################################

# Function to generate compose file for Traefik
compose_traefik() {
  CERT_PATH="/etc/traefik/letsencrypt/acme.json"
  
  cat <<EOL
version: '3'

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
EOL
}

# Function to generate compose file for Portainer
compose_portainer() {
  cat <<EOL
version: '3'

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
EOL
}

# Function to generate compose file for Redis
compose_redis() {
  cat <<EOL
version: '3'

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
version: '3'

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

compose_whomai(){
  cat <<EOL
version: '3'

services:
  whoami:
    image: traefik/whoami:v1.10
    hostname: '{{.Node.Hostname}}'
    networks:
      - {{network_name}}
    deploy:
      mode: global
      labels:
        - traefik.enable=true
        - traefik.http.routers.whoami.rule=Host(\`{{domain_hostname}}\`)
        - traefik.http.routers.whoami.entrypoints=websecure
        - traefik.http.routers.whoami.priority=1
        - traefik.http.routers.whoami.tls.certresolver=letsencryptresolver
        - traefik.http.services.whoami.loadbalancer.server.port='80'

networks:
  {{network_name}}:
    external: true
EOL
}

######################################## END OF COMPOSE FILES #####################################

############################# BEGIN OF STACK DEPLOYMENT UTILITARY FUNCTIONS #######################

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

get_network_name(){
  server_info_filename='server_info.json'
  server_info_json="$(cat "$server_info_filename")"
  local network_name="$(
    search_on_json_array "$server_info_json" "name" "network_name" | \
    jq -r ".value"
  )"
}

#################################### BEGIN OF STACK CONFIGURATION #################################

# Function to generate configuration files for traefik
generate_config_traefik() {
  local stack_name="traefik"
  local network_name="$(get_network_name)"

  highlight "Gathering $stack_name configuration"

  prompt_items='[
      {
          "name": "email_ssl",
          "label": "E-mail SSL",
          "description": "E-mail to receive SSL notifications",
          "required": "yes",
          "validate_fn": "validate_email_value" 
      }
  ]'

  collected_items="$(run_collection_process "$prompt_items")"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve Traefik configuration."
    return 1
  fi

  email_ssl="$(\
    get_variable_value_from_collection "$collected_items" "email_ssl"
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
  
  highlight "Gathering $stack_name configuration"

  step_info 1 $total_steps "Retrieving Portainer agent version"
  local portainer_agent_version="$(get_latest_stable_version "portainer/agent")"
  info "Portainer agent version: $portainer_agent_version"
  step_success 1 $total_steps "Retrieving Portainer agent version succeeded"
  
  step_info 2 $total_steps "Retrieving Portainer ce version"
  local portainer_ce_version="$(get_latest_stable_version "portainer/portainer-ce")"
  info "Portainer ce version: $portainer_ce_version"
  step_success 2 $total_steps "Retrieving Portainer ce version succeeded"

  local network_name="$(get_network_name)"  

  # Prompting step 
  prompt_items='[
      {
          "name": "portainer_url",
          "label": "Portainer URL",
          "description": "URL to access Portainer remotely",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      }
  ]'

  step_info 3 $total_steps "Prompting required Portainer information"
  collected_items="$(run_collection_process "$prompt_items")"

  if [[ "$collected_items" == "[]" ]]; then
    step_error 3 $total_steps "Unable to prompt Portanier configuration."
    return 1
  fi

  portainer_url="$(\
    get_variable_value_from_collection "$collected_items" "portainer_url" \
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
  local container_port='6379'

  local network_name="$(get_network_name)"

  highlight "Gathering $stack_name configuration"

  total_steps=1

  step_message="Retrieving Redis image version"
  step_info 1 $total_steps 
  local image_version="$(get_latest_stable_version "redis")"
  handle_exit 
  
  info "Redis version: $image_version"

  step_success 1 $total_steps "$step_message succeeded"

  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_name "${stack_name}_${image_version}" \
    --arg image_version "$image_version" \
    --arg container_name "$stack_name" \
    --arg container_port "$container_port" \
    --arg redis_url "redis://redis:$container_port" \
    --arg volume_name "${stack_name}_data" \
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
  local stack_name='postgres'
  local image_version='15'
  local container_port='5432'

  local postgres_user="postgres"
  local postgres_password="$(random_string)"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_name "${stack_name}_$image_version" \
    --arg image_version "$image_version" \
    --arg container_port "$container_port" \
    --arg db_user "$postgres_user" \
    --arg db_password "$postgres_password" \
    --arg volume_name "${stack_name}_data" \
    --arg network_name "$network_name" \
    '{
          "name": $stack_name,
          "variables": {
              "stack_name": $stack_name,
              "image_name": $image_name,
              "image_version": $image_version,
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

generate_config_whoami() {
  local stack_name='whoami'
  local container_port='80'

  network_name="$(get_network_name)"

  jq -n \
    --arg stack_name "$stack_name" \
    --arg container_port "$container_port" \
    --arg network_name "$network_name" \
    '{
          "name": $stack_name,
          "variables": {
              "stack_name": $stack_name,
              "container_port": $container_port,
              "network_name": $network_name
          },
          "dependencies": {},
          "setUp": []
      }'
  
}

#################################### END OF STACK CONFIGURATION ###################################

################################ BEGIN OF STACK DEPLOYMENT FUNCTIONS ##############################

# Function to deploy a traefik service
deploy_stack_traefik() {
  deploy_stack_pipeline 'traefik'
}

# Function to deploy a portainer service
deploy_stack_portainer() {
  deploy_stack_pipeline 'portainer'
}

# Function to deploy a PostgreSQL stack
deploy_stack_postgres() {
  deploy_stack_pipeline 'postgres'
}

# Function to deploy a Redis service
deploy_stack_redis() {
  deploy_stack_pipeline 'redis'
}

# Function to deploy a whoami service
deploy_stack_whoami() {
  deploy_stack_pipeline 'whoami'
}

################################# END OF STACK DEPLOYMENT FUNCTIONS ################################

##################################### BEGIN OF MENU DEFINITIONS ####################################

# Menu Main
define_menu_main(){
  menu_name="Main"

  item_1="$(\
    build_menu_item "Menu 1" "Options of Menu 1" "navigate_menu 'Menu 1'"\
  )"
  item_2="$(\
    build_menu_item "Utilities" "explore" "navigate_menu 'Utilities'"\
  )"
  item_3="$(\
    build_menu_item "VPS Health" "diagnose" "navigate_menu 'VPS health'"\
  )"
  
  page_size=5

  menu_object="$(\
    build_menu "$menu_name" $page_size "$item_1" "$item_2" "$item_3"\
  )"

  define_menu "$menu_name" "$menu_object"
}

# Menu 1
define_menu_1(){
  menu_name="Menu 1"

  item_1="$(
      build_menu_item \
      "Option 1.1" \
      "Very long description 1.1 to allow truncation on the menu selection 123567890" \
      "echo 'Option 1.1 selected' >&2"
  )"
  item_2="$(
    build_menu_item \
    "Option 1.2" \
    "Very long description 1.2 to allow truncation on the menu selection 123567890" \
    "echo 'Option 1.2 selected' >&2")"
  item_3="$(
    build_menu_item "Option 1.3" "Description 1.3" "echo 'Option 1.3 selected' >&2" 
  )"
  item_4="$(
    build_menu_item "Option 1.4" "Description 1.4" "echo 'Option 1.4 selected' >&2" 
  )"
  item_5="$(
    build_menu_item "Option 1.5" "Description 1.5" "echo 'Option 1.5 selected' >&2" 
  )"
  item_6="$(
    build_menu_item "Option 1.6" "Description 1.6" "echo 'Option 1.6 selected' >&2" 
  )"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size \
      "$item_1" "$item_2" "$item_3" \
      "$item_4" "$item_5" "$item_6"
  )"

  define_menu "$menu_name" "$menu_object"
}

# Utilities
define_utilities(){
  menu_name="Utilities"

  item_1="$(build_menu_item "Test SMPT e-mail" "Send" "test_smtp_email")"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size "$item_1" 
  )"

  echo "$menu_object" >&2

  define_menu "$menu_name" "$menu_object"
}

# VPS Health
define_menu_vps_health(){
  menu_name="VPS health"

  item_1="$(
    build_menu_item "CPU Usage" "Current CPU percentage usage" \
    "cpu_usage && press_any_key"
  )"
  item_2="$(
    build_menu_item "Memory Usage" "Current memory percentage usage" \
    "memory_usage && press_any_key"
  )"
  item_3="$(
    build_menu_item "Disk Usage" "Current disk percentage usage" \
    "disk_usage && press_any_key"
  )"
  item_4="$(
    build_menu_item "Network Usage" "Current network usage" \
    "network_usage && press_any_key"
  )"
  item_5="$(\
    build_menu_item "Top Processes" "Processes sorted by CPU and memory usage" \
    "top_processes && press_any_key" \
  )"
  item_6="$(\
    build_menu_item "Security Diagnostics" "" \
    "security_diagnostics && press_any_key")"
  item_7="$(\
    build_menu_item "Load Average" "" \
    "load_average && press_any_key")"
  item_8="$(\
    build_menu_item "Bandwidth Usage" "" \
    "bandwidth_usage && press_any_key"\
  )"
  item_9="$(\
    build_menu_item "Package Updates" "" \
    "update_and_check_vps_packages && press_any_key" \
  )"

  page_size=5

  menu_object="$(
    build_menu "$menu_name" $page_size \
      "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" \
      "$item_6" "$item_7" "$item_8" "$item_9"
  )"

  define_menu "$menu_name" "$menu_object"
}

# Populate MENUS
define_menus(){
    define_menu_main
    define_menu_1
    define_utilities
    define_menu_vps_health
}

start_main_menu(){
    navigate_menu "Main";
    farewell_message
}

###################################### END OF MENU DEFINITIONS ####################################

# Populate MENUS
define_menus

# Start the main menu
start_main_menu

# # Portainer test
# portainer_url="portainer.example.com"
# portainer_username="portainer_username"
# portainer_password="secret_password_shhh"
# 
# credentials="$(
#   jq -n \
#     --arg username "$portainer_username" \
#     --arg password "$portainer_password" \
#     '{"username":$username,"password":$password}'\
# )"
# 
# portainer_auth_token="$(\
#   get_portainer_auth_token "$portainer_url" "$credentials"
# )"
# 
# stack_name='whoami'
# check_portainer_stack_exists "$portainer_url" "$portainer_auth_token" "$stack_name"
# 
# if [[ $? -eq 0 ]]; then
#   echo "Stack $stack_name exists"
#   delete_stack_on_portainer "$portainer_url" "$portainer_auth_token" "$stack_name"
#   check_portainer_stack_exists "$portainer_url" "$portainer_auth_token" "$stack_name"
# 
#   if [[ $? -eq 1 ]]; then
#     success "Stack $stack_name deleted"
#   else
#     error "Stack $stack_name not deleted"
#   fi
# else
#   warning "Stack $stack_name does not exist"
# fi
# 
# upload_stack_on_portainer "$portainer_url" "$credentials" \
#   "$stack_name" ""$(pwd)/sandbox/$stack_name.yaml"" 
# 
# sleep 10
