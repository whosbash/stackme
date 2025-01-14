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
exit_color="\033[1;31m"      # Exit color (x)
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
STACKS_FOLDER="${HOME}/stacks"

# Default arrow
DEFAULT_ARROW_OPTION='diamond'
USER_DEFINED_ARROW=""

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
  wait_for_input
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
  wait_for_input
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
  local message="$3"
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "info" $has_timestamp
}

# Function to display step success message
step_success() {
  local current=$1
  local total=$2
  local message="$3"
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "success" $has_timestamp
}

# Function to display step failure message
step_failure() {
  local current=$1
  local total=$2
  local message="$3"
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "failure" $has_timestamp
}

# Function to display step error message
step_error() {
  local current=$1
  local total=$2
  local message="$3"
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "error" $has_timestamp
}

# Function to display step warning message
step_warning() {
  local current=$1
  local total=$2
  local message="$3"
  local has_timestamp=${4:-$HAS_TIMESTAMP}

  step $current $total "$message" "warning" $has_timestamp
}

# Function to display step success message
step_progress() {
  local current=$1
  local total=$2
  local message="$3"
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

diplay_header(){
  local title="$1"
  display_text "$title" 40 --center --style "${bold_color}${green}"
}

# Function to set the arrow based on user input
set_arrow() {
  if [[ -n "$USER_DEFINED_ARROW" ]]; then
    # If the user provides an arrow option, validate and set it
    if [[ -n "${ARROWS[$USER_DEFINED_ARROW]}" ]]; then
      ARROW_OPTION="$USER_DEFINED_ARROW"
    else
      # Handle invalid user-defined arrow options
      warning "'$USER_DEFINED_ARROW' is not a valid arrow option."
      echo "Available options: ${!ARROWS[@]}"
      warning "Falling back to default arrow: $DEFAULT_ARROW_OPTION"
      ARROW_OPTION="$DEFAULT_ARROW_OPTION"
      sleep 2
    fi
  else
    ARROW_OPTION="$DEFAULT_ARROW_OPTION"
  fi

  SELECTED_ARROW="${ARROWS[$ARROW_OPTION]}"
  COLORED_ARROW="${highlight_color}${SELECTED_ARROW}${reset_color}"
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
    return 1
  fi

  # Ensure valid JSON by passing it through jq
  if ! echo "$config_output" | jq . >/dev/null 2>&1; then
    warning "Invalid JSON in the configuration file '$config_file'. Returning empty JSON."
    echo "{}"
    return 1
  else
    # Return the valid JSON
    echo "$config_output"
    return 0
  fi
}

################################## END OF JSON-RELATED FUNCTIONS ################################

############################# BEGIN OF GENERAL UTILITARY FUNCTIONS ##############################

# Function to create Prometheus scrape_config
create_scrape_config_object() {
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
      --scheme)
        scheme="$2"
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
add_scrape_config_object() {
  # Input parameters
  local filename="$1"
  local scrape_config="$2"

  # Step 1: Check if the file exists
  if [[ ! -f "$filename" ]]; then
    # Step 1: Check if the file exists, and create the directory if necessary
    if [[ ! -f "$filename" ]]; then
      # Extract the directory from the filename
      local dir
      dir=$(dirname "$filename")

      # Ensure the directory exists
      if [[ ! -d "$dir" ]]; then
        echo "Directory $dir does not exist. Creating it."
        mkdir -p "$dir"
      fi
    fi

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
    warning "job_name '$job_name' already exists in $filename." >&2
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

#################################################################################################


############################### BEGIN OF GENERAL UTILITARY FUNCTIONS ############################

# Function to clean the terminal screen
clean_screen() {
  echo -ne "\033[H\033[J" >&2
}

# Function to generate a random string
random_string() {
  local length="${1:-16}"

  local word="$(openssl rand -hex $length)"
  echo "$word"
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

# Function to check the IP address of a domain
check_domain_ip() {
  local domain="$1"
  local expected_ip="$2"

  # Get the IP address of the domain using dig
  resolved_ip=$(dig +short "$domain")

  # Compare the resolved IP with the expected IP
  if [[ "$resolved_ip" == "$expected_ip" ]]; then
    success "The domain '$domain' resolves to '$expected_ip'."
  else
    error "The domain '$domain' does not resolve to '$expected_ip'. Resolved to '$resolved_ip'."
  fi
}

# Function to check if a command is available
is_command_available() {
  local command="$1"
  command -v "$command" >/dev/null 2>&1
}

assert_domain_and_ip(){
  items='[
      {
          "name": "domain_url",
          "label": "Domain URL",
          "description": "URL to access domain remotely",
          "required": "yes",
          "validate_fn": "validate_url_suffix"
      },
      {
          "name": "ip",
          "label": "IP address",
          "description": "String of IP address",
          "required": "yes",
          "validate_fn": ""
      }
  ]'

  collected_items="$(run_collection_process "$items")"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve SMTP test configuration."
    return 1
  fi

  domain_url="$(\
    search_on_json_array "$collected_items" 'name' 'domain_url' | jq -r ".value"
  )"

  ip="$(\
    search_on_json_array "$collected_items" 'name' 'ip' | jq -r ".value"
  )"

  check_domain_ip "$domain_url" "$ip"
}

############################# END OF GENERAL UTILITARY FUNCTIONS #############################

############################## BEGIN OF EMAIL-RELATED FUNCTIONS ##############################

# Function to send an email
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

################################## END OF EMAIL-RELATED FUNCTIONS #################################

############################### BEGIN OF SYSTEM-RELATED FUNCTIONS #################################

# Function to generate a complete HTML representation of machine specifications and resource usage
generate_machine_specs_content() {
  local html_content=""

  # Helper function to create a table
  create_table() {
    local caption="$1"
    local headers="$2"
    local rows="$3"
    echo "<table style='width: 100%; border-collapse: collapse; margin-top: 20px; border: 1px solid #ddd;'>"
    echo "<caption style='font-size: 1.5em; margin-bottom: 10px; font-weight: bold;'>$caption</caption>"
    echo "<thead style='background-color: #f9f9f9;'><tr>$headers</tr></thead>"
    echo "<tbody>$rows</tbody>"
    echo "</table>"
  }

  # Helper function to generate a row
  generate_table_row() {
    local key="$1"
    local value="$2"
    
    # If the value is empty or contains 'N/A', use a default fallback value
    if [[ -z "$value" || "$value" == "N/A" ]]; then
      value="No data available"
    fi

    echo "<tr style='border-bottom: 1px solid #ddd;'><td style='padding: 8px;'>$key</td><td style='padding: 8px;'>$value</td></tr>"
  }

  # Helper function to safely execute a command and return the result
  safe_exec() {
    local cmd="$1"
    
    # Try to execute the command
    result=$(eval "$cmd" 2>/dev/null)
    
    # If no result, return a fallback message
    if [[ -z "$result" || "$result" == "N/A" ]]; then
      result="No data available"
    fi

    echo "$result"
  }

  # Machine Specifications Table
  local machine_specs_rows=""
  machine_specs_rows+=$(
    generate_table_row "Hostname" \
    "$(hostname)"
  )
  machine_specs_rows+=$(
    generate_table_row "Operating System" \
    "$(safe_exec "lsb_release -d | cut -f2")"
  )
  machine_specs_rows+=$(
    generate_table_row "Kernel Version" \
    "$(safe_exec "uname -r")"
  )
  machine_specs_rows+=$(
    generate_table_row "Processor Model" \
    "$(safe_exec "lscpu | awk -F ':' '/Model name/ {gsub(/^[ \t]+/, \"\", \$2); print \$2}'")"
  )
  machine_specs_rows+=$(
    generate_table_row "Processor Cores" \
    "$(safe_exec "lscpu | awk -F ':' '/^CPU\(s\):/ {gsub(/^[ \t]+/, \"\", \$2); print \$2}'")"
  )
  machine_specs_rows+=$(
    generate_table_row "Processor Threads" \
    "$(safe_exec "lscpu | awk -F ':' '/^Thread\(s\) per core:/ {gsub(/^[ \t]+/, \"\", \$2); print \$2}'")"
  )
  machine_specs_rows+=$(
    generate_table_row "Clock Speed" \
    "$(safe_exec "lscpu | grep 'Model name' | grep -o '@ [0-9.]\+GHz' || echo 'N/A'")"
  )
  machine_specs_rows+=$(
    generate_table_row "Total Memory" \
    "$(safe_exec "free -h | awk '/^Mem:/ {print \$2}'")"
  )
  machine_specs_rows+=$(
    generate_table_row "GPU Details" \
    "$(safe_exec "lspci | grep -i 'vga\|3d\|2d' || echo 'GPU information unavailable.'")"
  )
  machine_specs_rows+=$(
    generate_table_row "Docker Version" \
    "$(safe_exec "docker --version || echo 'Not installed'")"
  )

  html_content+=$(create_table "Machine Specifications" "<th>Attribute</th><th>Details</th>" "$machine_specs_rows")

  # Disk Usage Table
  local disk_usage_rows=$(
    df -h --output=source,fstype,size,used,avail,pcent | \
    grep -E '^/dev' | \
    awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>", $1, $2, $3, $4, $5, $6}'
  )
  html_content+=$(create_table "Disk Usage" "<th>Source</th><th>Filesystem Type</th><th>Total Size</th><th>Used</th><th>Available</th><th>Use%</th>" "$disk_usage_rows")

  # Battery Status Table (only if upower is available)
  if command -v upower &>/dev/null; then
    local battery_rows=$(
      upower -i $(upower -e | grep BAT) | grep -E 'state|to full|percentage' | \
      awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); print "<tr><td>" $1 "</td><td>" $2 "</td></tr>"}'
    )
    if [[ -n "$battery_rows" ]]; then
      html_content+=$(create_table "Battery Status" "<th>Status</th><th>Details</th>" "$battery_rows")
    else
      html_content+=$(create_table "Battery Status" "<th>Status</th><th>Details</th>" "<tr><td colspan='2'>No battery information available.</td></tr>")
    fi
  fi

  # Network Information Table (Ethernet and Wi-Fi)
  local ethernet_info=$(safe_exec "ip -4 addr show | grep 'state UP' -A2 | grep inet | awk '{print \$2}' || echo 'No Ethernet connection.'")
  local wifi_info=$(safe_exec "nmcli device status | grep wifi | awk '{print \$1, \$3, \$4}' || echo 'No Wi-Fi connection.'")
  local network_rows=""
  network_rows+=$(generate_table_row "Ethernet" "$ethernet_info")
  network_rows+=$(generate_table_row "Wi-Fi" "$wifi_info")
  html_content+=$(create_table "Network Information" "<th>Type</th><th>Details</th>" "$network_rows")

  # Return the complete HTML content
  echo "$html_content"
}

# Functions for diagnostics
# Show uptime with start and current time
uptime_usage() {
    # Example usage of display_text to show a centered header
    echo ""
    format_="%Y-%m-%d %H:%M:%S"
    echo "$(uptime -p) since $(date -d "$(uptime -s)" +"$format_") to $(date +"$format_")" >&2
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
update_and_check_packages() {
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
  echo -e "${quit_color}q${reset_color}   - Return to previous menu / Quit the application"
  echo -e "${help_color}h${reset_color}   - Show this help menu"
  echo -e "${exit_color}x${reset_color}   - Exit the application"
}

# Function to clean up mustache variables
sanitize_template() {
  local template="$1"
  # Remove any spaces between the mustache braces and the variable name
  template=$(echo "$template" | sed 's/{{\s*\([a-zA-Z0-9_]*\)\s*}}/{{\1}}/g')
  echo "$template"
}

# Function to replace variables in a template
replace_mustache_variables() {
  local template="$1"
  local -n vars_ref="$2" # Associative array passed by reference

  template="$(sanitize_template "$template")"

  # Iterate over the variables and replace each instance of {{KEY}} in the template
  for key in "${!vars_ref[@]}"; do
    value="${vars_ref[$key]}"

    # Escape special characters in the value to prevent issues with sed (if needed)
    value_escaped="$value"

    # Replace instances of {{KEY}} in the template
    # Handle {{key}}, {{ key}}, or {{key }}
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

# Function to validate username
validate_username() {
  local value="$1"

  # Check if the value contains only letters, numbers, and underscores
  if [[ ! "$value" =~ ^[a-zA-Z0-9_]+$ ]]; then
    warn_message="The value '$value' is not a valid username"
    reason="It can only contain letters, numbers, and underscores."
    echo "$warn_message. $reason"
    return 1
  fi

  return 0
}

# Function to validate password
# Function to validate password
validate_password() {
  local value="$1"

  # Common warning message
  local warn_message="The value '$value' is not a valid password"

  # Check if the value contains at least 5 characters
  if [[ ${#value} -lt 5 ]]; then
    local reason="It must be at least 5 characters long."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check if the value contains at least one uppercase letter
  if [[ ! "$value" =~ [A-Z] ]]; then
    local reason="It must contain at least one uppercase letter."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check if the value contains at least one lowercase letter
  if [[ ! "$value" =~ [a-z] ]]; then
    local reason="It must contain at least one lowercase letter."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check if the value contains at least one number
  if [[ ! "$value" =~ [0-9] ]]; then
    local reason="It must contain at least one number."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check if the value contains at least one valid special character
  if [[ ! "$value" =~ [\!\@\#\$\%\^\&\*\(\)\_\+\-\=] ]]; then
    local reason="It must contain at least one valid special character (!@#$%^&*()_+-=)."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check if the value does not contain spaces
  if [[ "$value" =~ [[:space:]] ]]; then
    local reason="It cannot contain spaces."
    echo "$warn_message. $reason"
    return 1
  fi

  # Check for invalid special characters (e.g., '<', '>')
  if [[ "$value" =~ [\<\>] ]]; then
    local reason="It contains invalid special characters (<>)."
    echo "$warn_message. $reason"
    return 1
  fi

  # If all checks pass
  return 0
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

  # Build the JSON object for the individual item
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
    return 1
  fi

  # Return the JSON object
  echo "$item_json"
}

# Function to process a JSON array and collect values into a JSON object
process_prompt_items() {
  local input_json="$1"
  local result_json="{"

  # Iterate over the array of prompt items in the input JSON
  for prompt_item in $(echo "$input_json" | jq -r '.[] | @base64'); do
    # Decode the base64 encoded JSON object for each item
    _jq() {
      echo "$prompt_item" | base64 --decode | jq -r "${1}"
    }

    # Extract values from the prompt item JSON
    name=$(_jq '.name')
    label=$(_jq '.label')
    description=$(_jq '.description')
    value=$(_jq '.value')
    required=$(_jq '.required')
    validate_fn=$(_jq '.validate_fn')

    # Create the prompt item using the create_prompt_item function
    item_json=$(\
      create_prompt_item "$name" "$label" "$description" \
      "$value" "$required" "$validate_fn"\
    )

    # Check if the item creation was successful
    if [[ $? -eq 0 ]]; then
      # Append to result_json, using the 'name' as the key and 'value' as the value
      result_json+="\"$name\": \"$value\","
    else
      echo "Error processing item: $name"
      return 1
    fi
  done

  # Remove the trailing comma and close the JSON object
  result_json="${result_json%,}}"

  # Return the final JSON object
  echo "$result_json"
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
    if [[ "$collected_info" == "[]" ]]; then
      warning "No data collected. Exiting process."
      echo "[]"
      exit 0
    fi

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

# Function to wait for any letter or command to continue
wait_for_input() {
  local prompt_message="$1"

  # If no message is provided, set a default prompt
  if [[ -z "$prompt_message" ]]; then
    prompt_message="Press any key to continue..."
  fi

  # Display the prompt message and wait for user input (one character)
  prompt_message="$(format "question" "$prompt_message")"
  echo -n "$prompt_message" >&2  # Display the message without a newline
  read -n 1 -s user_input    # Wait for a single character input, suppress echo
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
    clean_screen
    farewell_message
    exit 0;
}

# Trap SIGINT (Ctrl+C) and EXIT (script termination) to invoke the cleanup function
trap finish_session SIGINT EXIT

# Trap SIGTERM (KILL) and EXIT (script termination) to invoke the cleanup function
trap finish_session TERM EXIT

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
  local lr_nav_option=""
  local goto_nav_option=""
  local back_option="${back_color}r${reset_color}: Return"
  local search_option="${search_color}/${reset_color}: Search"
  local help_option="${help_color}h${reset_color}: Help"
  local quit_option=""
  local exit_option="${help_color}x${reset_color}: Exit"
  
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
    "$sel_nav_option"
    "$search_option"
    "$back_option"
    "$help_option"
  )

  # Conditionally add non-empty options
  [[ -n "$lr_nav_option" ]] && keyboard_options+=("$lr_nav_option")
  [[ -n "$goto_nav_option" ]] && keyboard_options+=("$goto_nav_option")
  [[ -n "$quit_option" ]] && keyboard_options+=("$quit_option")

  keyboard_options+=("$exit_option")

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
      command="clean_screen; error \"$message\"; wait_for_input; cleanup; clean_screen; return"
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
        echo -ne "${faded_color}Search: ${reset_color}" >&2
        read -e -r search_key

        # Clear the line if the prompt disappears after backspace
        echo -ne "\033[2K\r"

        # Reset to original options if 'r' is pressed
        if [[ "$search_key" == "r" ]]; then
          menu_options=("${original_menu_options[@]}")
          current_idx=0  # Reset the index to 0 if 'r' is pressed
          return
        fi

        local filtered_options=()
        shopt -s nocasematch
        for option in "${original_menu_options[@]}"; do
          # Extract label and description using jq
          label=$(echo "$option" | jq -r '.label // empty')
          description=$(echo "$option" | jq -r '.description // empty')

          # Match search_key against label or description
          if [[ "$label" == *"$search_key"* || "$description" == *"$search_key"* ]]; then
            filtered_options+=("$option")
          fi
        done

        # Turn it off after the loop
        shopt -u nocasematch  

        # If no matches, reset to original options
        if [[ ${#filtered_options[@]} -eq 0 ]]; then
          menu_options_ref=("${original_menu_options[@]}")
          warning "No matches found, resetting to original options."
          sleep 0.5
        else
          # Update filtered options and reset index
          menu_options=("${filtered_options[@]}")
          current_idx=0  # Reset the index after filtering
        fi

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
    "x")
      kill -TERM -$$
      exit 0
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

# Function to map stacks to services and convert to JSON object
map_stacks_to_services() {
  # Fetch all stacks
  stacks=($(docker stack ls --format "{{.Name}}"))

  # Initialize an empty JSON object for the stack to service mapping
  json_object='{}'

  # Check if there are any stacks in the swarm
  if [ ${#stacks[@]} -eq 0 ]; then
    echo "No stacks found in the swarm."
    exit 0
  fi

  # Loop through each stack to list its services and build the JSON object
  for stack in "${stacks[@]}"; do
    # Fetch the services for the current stack
    services=($(docker stack services "$stack" --format "{{.Name}}"))

    # Initialize an empty JSON array to store services for the current stack
    services_json_array='[]'

    # Append each service to the JSON array
    for service in "${services[@]}"; do
      services_json_array=$(append_to_json_array "$services_json_array" "\"$service\"")
    done

    # Add the services JSON array to the main JSON object under the stack key
    json_object=$(echo "$json_object" | jq ". + {\"$stack\": $services_json_array}")
  done

  # Output the final JSON object
  echo "$json_object"
}

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

# Function to deploy a service using a Docker Compose file
deploy_stack_on_swarm() {
  local stack_name="$1"
  local compose_path="$2"

  # Ensure Python is installed
  if ! command -v python3 &>/dev/null; then
    error "Python3 is required but not installed. Please install it and try again."
    exit 1
  fi

  # Deploy the service using Docker stack
  docker stack deploy \
    --detach=false --prune --resolve-image always \
    -c "$compose_path" "$stack_name"

  if [ $? -eq 0 ]; then
    success "Stack $stack_name deployed and running successfully."
  else
    error "Stack $stack_name failed to deploy or is not running correctly."
    return 1
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
    error "Invalid Portainer credentials" >&2
    return 1 # Exit with status 1 for failure
  else
    success "Valid Portainer credentials" >&2
    return 0 # Exit with status 0 for success
  fi
}

# Function to signup on portainer
signup_on_portainer() {
  local portainer_url="$1"
  local username="$2"
  local password="$3"

  echo "Username: $username" >&2
  echo "Password: $password" >&2

  # Prepare credentials in JSON format
  credentials="{\"username\":\"$username\",\"password\":\"$password\"}"
  echo "Credentials: $credentials" >&2

  # Validate and reformat JSON
  credentials=$(echo "$credentials" | jq -c . 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Invalid JSON provided for credentials: $credentials" >&2
    return 1
  fi

  # Setup headers and endpoint
  local protocol="https"
  local content_type="application/json"
  local resource='users/admin/init'
  local header="Content-Type: $content_type"

  info "Signing up on portainer..."

  # Get the URL
  url="$(get_api_url "$protocol" "$portainer_url" "$resource")"
  echo "URL: $url" >&2

  # Make the request
  response=$(curl -s -k -X POST "$url" -H "$header" -d "$credentials")
  echo "Response: $response" >&2

  # Check for existing administrator user in the response
  if [[ "$response" == *"An administrator user already exists"* ]]; then
    echo "Warning: An administrator user already exists." >&2
    return 1
  fi

  # Parse the response and check if it contains the expected fields
  user_info=$(\
    echo "$response" | \
    jq -c 'select(.Id and .Username and .Password and .Role)'
  )
  if [ $? -ne 0 ]; then
    echo "Error: The response does not contain the expected fields." >&2
    return 1
  fi

  # Ensure the password is correctly hashed (checking the format of the password)
  password_hash=$(echo "$response" | jq -r '.Password')
  if [[ "$password_hash" =~ ^\$2a\$10\$ ]]; then
    echo "Administrator user created successfully."
    return 0
  else
    echo "Error: Password hashing failed or response is incorrect." >&2
    return 1
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

# Function to deploy a stack
deploy_stack_on_portainer() {
  local portainer_url="$1"
  local portainer_credentials="$2"
  local stack_name="$3"

  portainer_auth_token="$(\
    get_portainer_auth_token "$portainer_url" "$portainer_credentials"
  )"

  if [[ -z "$portainer_auth_token" ]]; then
    error "Failed to retrieve Portainer token."
    return 1
  fi

  check_portainer_stack_exists "$portainer_url" "$portainer_auth_token" "$stack_name"

  if [[ $? -eq 0 ]]; then
    warning "Stack $stack_name exists"
    return 1
    # delete_stack_on_portainer "$portainer_url" "$portainer_auth_token" "$stack_name"
    # check_portainer_stack_exists "$portainer_url" "$portainer_auth_token" "$stack_name"
    # 
    # if [[ $? -eq 1 ]]; then
    #   success "Stack $stack_name deleted"
    # else
    #   error "Stack $stack_name not deleted"
    # fi
  else
    warning "Stack $stack_name does not exist"
  fi

  upload_stack_on_portainer "$portainer_url" "$credentials" \
    "$stack_name" "$STACKS_FOLDER/$stack_name.yaml" || \
    error "Failed to upload stack '$stack_name'"
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

# Function to remove a failed deployment
remove_compose_if_failed_deployment() {
  local compose_path="$1"
  local exit_code="$2"

  # Ensure exit_code is a valid integer
  if [[ ! "$exit_code" =~ ^[0-9]+$ ]]; then
    error "Invalid exit code: \"$exit_code\". Must be an integer."
    return 1
  fi

  if [ "$exit_code" -ne 0 ]; then
    #rm -f "$compose_path"
    warning "Deployment failed. Docker Compose file \"$compose_path\" was removed."
    wait_for_input
    return 1
  fi
}

# Function to build config and compose files for a service
build_stack_info() {
  local stack_name="$1"

  # Build JSON object
  local json_output
  json_output=$(jq -n \
    --arg config_path "${STACKS_FOLDER}/${stack_name}_config.json" \
    --arg compose_path "${STACKS_FOLDER}/${stack_name}.yaml" \
    --arg compose_func "compose_${stack_name}" \
    '{
      config_path: $config_path,
      compose_path: $compose_path,
      compose_func: $compose_func
    }'
  )

  # Return JSON
  echo "$json_output"
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

# Function to determine if an image is official
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

# Function to fetch stable tags from a response
fetch_stable_tags_from_page() {
  pattern='^[0-9]+\.[0-9]+\.[0-9]+$|^[0-9]+\.[0-9]+$'
  echo "$1" | jq -r '.results[].name' | grep -E "$pattern"
}

# Function to create a Docker network if it doesn't exist
create_network_if_not_exists() {
  local network_name="${1:-$DEFAULT_NETWORK}"

  # Check if the network already exists
  if ! docker network ls --format '{{.Name}}' | grep -wq "$network_name"; then
    info "Creating network: $network_name"

    # Get the IP address
    read -r ip _ <<<$(\
      hostname -I | tr ' ' '\n' | grep -v '^127\.0\.0\.1' | tr '\n' ' '\
    )

    # Create the overlay network
    if docker network create \
      --driver overlay "$network_name" -- 2>&1; then
      success "Network $network_name created successfully."
    else
      error "Failed to create network $network_name."
      wait_for_input
      exit 1 # Exit with error status if network creation fails
    fi
  else
    warning "Network $network_name already exists."
  fi
}

# Function to execute a setUp action
execute_action() {
  local action_json="$1"
  local action_variables="$2"

  # Extract the name and command safely using jq
  local action_name
  action_name=$(echo "$action_json" | jq -r '.name')

  local action_command
  action_command=$(echo "$action_json" | jq -r '.command')

  # Export variables if provided
  if [ -n "$action_variables" ]; then
    for var in $(echo "$action_variables" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"'); do
      local var_name=$(echo "$var" | cut -d'=' -f1)
      local var_value=$(echo "$var" | cut -d'=' -f2)
      export "$var_name"="$var_value"
    done
  fi

  # Use eval safely to execute the command
  eval "$action_command"

  # Check command success
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "Action '$action_name' failed with exit code $exit_code"
  else
    echo "Action '$action_name' executed successfully"
  fi
}

# Function to deploy a service
deploy_stack_pipeline() {
  # Arguments
  local stack_name="$1" # stack name (e.g., redis, postgres)
  local config_json="$2" # JSON data with stack setup cofiguration

  debug "$config_json"

  total_steps=10

  stack_step_progress(){
    stack_step "progress" "$1" "$2"
  }

  stack_step_warning(){
    stack_step "warning" "$1" "$2"
  }
  
  stack_step_error(){
    stack_step "error" "$1" "$2"
  }

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
    handle_exit "$exit_code" "$step" $total_steps "$stack_message"
  }

  # Declare an associative array to hold service variables
  declare -A stack_variables

  debug "$config_json"

  # Parse JSON data and populate associative array
  while IFS="=" read -r key value; do
    stack_variables["$key"]="$value"
  done < <(\
    echo "$config_json" | \
    jq -r '.variables | to_entries | .[] | "\(.key)=\(.value | tostring)"'\
  )

  highlight "Deploying stack '$stack_name'"

  # Step 1: Deploy Dependencies
  stack_step_progress 1 "Checking and deploying dependencies"
  local dependencies=$(echo "$config_json" | jq -c '.dependencies // []')

  # Validate JSON
  if ! echo "$dependencies" | jq empty; then
      stack_step_error 9 "Invalid JSON in dependencies: $dependencies"
      return 1
  fi

  # Check if there are dependencies, and if none, display a message
  if [ "$(echo "$dependencies" | jq length)" -eq 0 ]; then
    stack_step_warning 1 "No dependencies to deploy"
  else
    echo "$dependencies" | jq -c '.[]' | while IFS= read -r dependency; do
      # Check if stack dependency exists on docker
      if ! docker stack ls | grep -q "$dependency"; then
        dependency_message="Deploying dependency: $dependency"
        stack_step_progress 1 "$dependency_message"

        # Fetch JSON for the dependency
        deploy_stack "$dependency"
        stack_handle_exit "$?" 1 "$dependency_message"  
      else
        dependency_message="Dependency \"$dependency\" already exists"
        stack_step_warning 1 "$dependency_message"
      fi
    done
  fi

  # Step 2: Gather setUp actions
  stack_step_progress 2 "Gathering prepare actions"
  local setUp_actions
  prepare_actions=$(echo "$config_json" | jq -r '.prepare?')
  finalize_actions=$(echo "$config_json" | jq -r '.finalize?')

  # Check if jq returned an error
  if [[ $? -ne 0 ]]; then
    stack_step_error 2 "Error parsing prepare actions: $prepare_actions"
    exit 1
  fi

  # Validate JSON
  if ! echo "$prepare_actions" | jq empty; then
      stack_step_error 9 "Invalid JSON in prepare_actions: $prepare_actions"
      return 1
  fi

  # Step 3: Run setUp actions individually
  if [ "$(echo "$prepare_actions" | jq length)" -eq 0 ]; then
    echo "$prepare_actions" | jq -c '.[]' | while IFS= read -r action; do
      # Perform the action (you can define custom functions to execute these steps)
      action_name=$(echo "$action" | jq -r '.name')
      
      message="Executing prepare action: $action_name"
      stack_step_error 3 "$message"

      # Call an appropriate function to handle this setUp action
      execute_action "$action" "$variables"
      stack_handle_exit $? 3 "$message"
    done
  else
    stack_step_warning 3 "No prepare actions defined"
  fi

  # Step 4: Build service-related file paths and Docker Compose template
  message="Building stack filepaths"
  stack_step_progress 4 "$message"
  stack_info="$(build_stack_info "$stack_name")"

  # Extract values from the JSON output
  local config_path=$(echo "$stack_info" | jq -r '.config_path')
  local compose_path=$(echo "$stack_info" | jq -r '.compose_path')
  local compose_template_func=$(echo "$stack_info" | jq -r '.compose_func')

  stack_handle_exit $? 4 "$message"

  # Step 5: Retrieve and substitute variables in Docker Compose template
  message="Creating Docker Compose template"
  stack_step_progress 5 "$message"
  local substituted_template
  substituted_template="$(\
    replace_mustache_variables "$($compose_template_func)" stack_variables \
  )"
  stack_handle_exit "$?" 5 "$message"

  # Step 6: Write the substituted template to the compose file

  # Create folder stacks on home path
  mkdir -p "$STACKS_FOLDER"

  message="Writing Docker Compose template"
  stack_step_progress 6 "$message" 
  echo "$substituted_template" >"$compose_path"
  stack_handle_exit $? 6 "$message"

  # Step 7: Validate the Docker Compose file
  message="Validating Docker Compose file" 
  stack_step_progress 7 "$message" 
  validate_compose_file "$compose_path"
  exit_code="$?"
  stack_handle_exit "$exit_code" 7 "$message"

  remove_compose_if_failed_deployment "$compose_path" "$exit_code" 

  if [ $? -ne 0 ]; then
    return 1
  fi

  # Step 8: Deploy the service on Docker Swarm
  if [ "$stack_name" == "startup" ] || [ "$stack_name" == "portainer" ]; then
    message="Deploying stack on Docker Swarm"
    stack_step_progress 8 "$message"

    deploy_stack_on_swarm "$stack_name" "$compose_path"

  else
    message="Deploying stack on Portainer"
    stack_step_progress 8 "$message"

    # Get Portainer credentials
    portainer_config_json="$(load_json "$STACKS_FOLDER/portainer_config.json")"
    echo "$portainer_config_json" >&2
  
    portainer_url="$(echo "$portainer_config_json" | jq -r '.variables.portainer_url')"
    portainer_credentials="$(echo "$portainer_config_json" | jq -r '.variables.portainer_credentials')"

    upload_stack_on_portainer "$portainer_url" "$portainer_credentials" "$stack_name" "$compose_path"
  fi

  exit_code=0
  stack_handle_exit $exit_code 8 "$message"

  remove_compose_if_failed_deployment "$compose_path" "$exit_code"

  if [ $? -ne 0 ]; then
    return 1
  fi

  # Validate JSON
  if ! echo "$finalize_actions" | jq empty; then
      stack_step_error 9 "Invalid JSON in finalize_actions: $finalize_actions"
      return 1
  fi

  # Step 9: Run finalize actions individually
  if echo "$finalize_actions" | jq -e '. | type == "array" and length > 0' > /dev/null 2>&1; then
    message="Executing finalize actions"
    stack_step_progress 9 "$message"

    echo "$finalize_actions" | jq -c '.[]' | while IFS= read -r action; do
      action_name=$(echo "$action" | jq -r '.name')

      echo "$action" >&2

      message="Executing finalize action: $action_name"
      stack_step_error 9 "$message"

      # Perform the action
      execute_action "$action" "$variables"
      stack_handle_exit $? 9 "$message"
    done
  else
    stack_step_warning 9 "No finalize actions defined"
  fi

  # Step 9: Save service-specific information to a configuration file
  message="Saving stack configuration"
  stack_step_progress 10 "$message"
  write_json "$config_path" "$config_json"
  stack_handle_exit $? 10 "$message"

  # Final Success Message
  deploy_success_message "$stack_name"

  wait_for_input
}

# Function to deploy a traefik service
deploy_stack() {
  local stack_name="$1"

  # Generate the stack JSON configuration
  local config_json
  config_json=$(eval "generate_config_$stack_name")

  if [ -z "$config_json" ]; then
    return 1
  fi

  # Check required fields
  validate_stack_config "$stack_name" "$config_json"

  if [ $? -ne 0 ]; then
    failure "Stack $stack_name configuration validation failed."
    return 1
  fi

  clean_screen

  # Deploy the n8n service using the JSON
  deploy_stack_pipeline "$stack_name" "$config_json"
}

################################ END OF GENERAL DEPLOYMENT FUNCTIONS ##############################

####################################### BEGIN OF E-MAIL UTILS #####################################

BASE_TEMPLATE='<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{email_title}}</title>
  <style>
    body { 
      font-family: Arial, sans-serif; 
      background-color: #f9f9fb; 
      margin: 0; 
      padding: 0; 
      color: #333; 
      line-height: 1.6; /* Improve readability */
    }
    .container { 
      margin: 20px auto; 
      padding: 20px; 
      max-width: 600px; 
      background-color: #ffffff; 
      border-radius: 10px; 
      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1); 
    }
    .header { 
      text-align: center; 
      background-color: #4caf50; 
      color: #ffffff; 
      padding: 20px; 
      border-radius: 10px 10px 0 0; 
    }
    .header img { 
      max-width: 80px; 
      margin-bottom: 10px; 
    }
    .header h1 { 
      font-size: 1.6em; /* Scalable font size */
      margin: 0; 
    }
    .content { 
      padding: 20px; 
      font-size: 1em; /* Adjust for readability */
    }
    .footer { 
      text-align: center; 
      padding: 20px 0; 
      color: #aaaaaa; 
      border-top: 1px solid #eeeeee; 
      font-size: 0.9em; /* Slightly smaller font for footer */
    }
    .footer img { 
      width: 24px; 
      height: 24px; 
      vertical-align: middle; 
    }
    .footer a { 
      text-decoration: none; 
      color: #aaaaaa; 
    }

    /* Button Styling */
    .button {
      display: inline-block; /* Inline-block to size button to its content */
      margin: 20px auto; /* Center button horizontally */
      padding: 12px 25px;
      background-color: #4caf50; /* Green background */
      color: #ffffff; /* White text */
      text-decoration: none; /* No underline */
      font-size: 1em; /* Scalable font size */
      font-weight: bold;
      border-radius: 5px;
      text-align: center;
      cursor: pointer;
      transition: background-color 0.3s ease; /* Smooth hover effect */
    }
    .button:hover {
      background-color: #45a049;
    }
    .button:active {
      background-color: #3e8e41; /* Click feedback */
    }
    .button:focus {
      outline: 3px solid #4caf50; /* Accessibility for keyboard navigation */
      outline-offset: 2px;
    }

    /* Global Link Styling */
    a {
      color: #4caf50; /* Green text */
      font-weight: bold; /* Bold text */
      text-decoration: none; /* No underline */
    }
    a:hover {
      text-decoration: underline; /* Underline on hover */
    }
    a:focus {
      outline: 3px solid #4caf50; /* Accessibility for keyboard navigation */
      outline-offset: 2px;
    }
</style>
</head>
<body>
  <section class="container">
    <header class="header">
      <img src="https://raw.githubusercontent.com/whosbash/stackme/main/images/stackme_tiny.png" alt="StackMe Logo">
      <h1>{{header_title}}</h1>
    </header>
    <section class="content">
      {{email_content}}
    </section>
    <footer class="footer">
      <p>Sent using a Shell Script and the Swaks tool.</p>
      <p>
        <a href="https://github.com/whosbash/stackme" target="_blank">
          <img src="https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png" alt="GitHub Logo">
        </a>
      </p>
    </footer>
  </section>
</body>
</html>'

# Function to generate email
generate_html() {
  local base_template="$1"
  local email_title="$2"
  local header_title="$3"
  local email_content="$4"

  # Prepare an associative array with the replacements
  declare -A email_variables=(
    [email_title]="$email_title"
    [header_title]="$header_title"
    [email_content]="$email_content"
  )

  # Use the replace_mustache_variables function to substitute variables in the template
  local email_html=$(replace_mustache_variables "$base_template" email_variables)

  # Output the final HTML email
  echo "$email_html"
}

# Function to generate HTML for an email
test_smtp_html() {
  # Content for the email
  local email_content="<p>Hi there,</p>
<p>We are thrilled to have you onboard! Explore the amazing features of StackMe and elevate your workflow.</p>
<p>If you have any questions, feel free to submit an issue to 
<a href=\"https://github.com/whosbash/stackme/issues\" title=\"Visit our Issues page on GitHub\">our repository</a>. We're here to help!</p>"

  # Generate the email HTML
  generate_html "$BASE_TEMPLATE" "Welcome to StackMe" "Welcome to StackMe" "$email_content"
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

# Function to generate HTML for an email
generate_test_smtp_hmtl() {
  # Content for the email
  local email_content='<p>Hi there,</p> <p>We are thrilled to have you onboard! Explore the amazing features of StackMe and elevate your workflow.</p> <a href="https://github.com/whosbash/stackme" class="button">Get Started</a> <p>If you have any questions, feel free to submit an issue to <a href="https://github.com/whosbash/stackme/issues" title="Visit our Issues page on GitHub">our repository</a>. We''re here to help!</p>'

  # Generate the email
  generate_html "$BASE_TEMPLATE" "Welcome to StackMe" "Welcome to StackMe" "$email_content"
}

# Function to generate HTML table row
generate_table_row() {
  local category="$1"
  local details="$2"
  echo "<tr><td style='padding: 8px; border: 1px solid #ddd;'>$category</td>
    <td style='padding: 8px; border: 1px solid #ddd;'>$details</td></tr>"
}

# Function to fetch system information
fetch_system_info() {
  local command="$1"
  local default_value="$2"
  command -v "$command" &>/dev/null && eval "$command" || echo "$default_value"
}

format_disk_usage() {
  local header="<table style='width: 100%; border-collapse: collapse; text-align: left;'>
<caption style='font-size: 1.5em; margin-bottom: 10px;'>Disk Usage</caption>
<tr style='background-color: #f2f2f2;'>
  <th>Source</th>
  <th>Filesystem Type</th>
  <th>Total Size</th>
  <th>Used</th>
  <th>Available</th>
  <th>Use%</th>
</tr>"
  local rows=$(df -h --output=source,fstype,size,used,avail,pcent | grep -E '^/dev' | \
    awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5, $6}')
  local footer="</table>"

  echo "$header$rows$footer"
}

# Function to generate the machine specs email
generate_machine_specs_html(){
  # Example usage
  email_content=$(generate_machine_specs_content)
  generate_html "$BASE_TEMPLATE" "VPS Status" "Machine Specifications" "$email_content"
}

# Function to request SMTP information
request_smtp_information(){
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

  echo "$collected_items"
}

# Function to save SMTP information
save_smtp_information(){
  collected_items="$(request_smtp_information)"
  filename="${HOME}/smtp_info.json"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve SMTP configuration."
    return 1
  fi

  smtp_json=$(process_prompt_items "$collected_items")

  info "Saving SMTP configuration to file: $filename"  
  write_json "$filename" "$smtp_json"

  echo "$smtp_json"
}

# Centralized function to retrieve and process SMTP configuration
get_smtp_configuration(){
  # First, try to load SMTP configuration from file
  smtp_json=$(load_smtp_information)

  # If loading fails, request the configuration and save it
  if [[ $? -ne 0 ]]; then
    smtp_json="$(save_smtp_information)"

    if [[ $? -ne 0 ]]; then
      error "Unable to retrieve or save SMTP configuration."
      return 1
    fi
  fi

  echo "$smtp_json"
}

read_json(){
  local filename="$1"

  if [[ -f "$filename" ]]; then
    cat "$filename"
  fi
}

# Function to load SMTP configuration from file
load_smtp_information(){
  filename="${HOME}/smtp_info.json"
  smtp_json=$(read_json "$filename")

  if [[ -z "$smtp_json" ]]; then
    error "Unable to retrieve SMTP configuration from file $filename."
    return 1
  fi

  info "Loaded SMTP configuration from file: $filename"
  
  echo "$smtp_json"
}

# Function to send a test SMTP email
send_smtp_test_email(){
  # Retrieve SMTP configuration (load from file or request and save)
  smtp_json=$(get_smtp_configuration)

  if [[ $? -ne 0 ]]; then
    error "Unable to retrieve SMTP configuration."
    return 1
  fi

  smtp_server="$(echo "$smtp_json" | jq -r ".smtp_server")"
  smtp_port="$(echo "$smtp_json" | jq -r ".smtp_port")"
  username="$(echo "$smtp_json" | jq -r ".username")"
  password="$(echo "$smtp_json" | jq -r ".password")"

  subject="[StackMe] Test SMTP e-mail"
  body="$(generate_test_smtp_hmtl)"

  # Send the test email
  send_email \
    "$username" "$username" "$smtp_server" "$smtp_port" \
    "$username" "$password" "$subject" "$body"
}

# Function to send machine specs email
send_machine_specs_email(){
  # Retrieve SMTP configuration (load from file or request and save)
  smtp_json=$(get_smtp_configuration)

  if [[ $? -ne 0 ]]; then
    error "Unable to retrieve SMTP configuration."
    return 1
  fi

  smtp_server="$(echo "$smtp_json" | jq -r ".smtp_server")"
  smtp_port="$(echo "$smtp_json" | jq -r ".smtp_port")"
  username="$(echo "$smtp_json" | jq -r ".username")"
  password="$(echo "$smtp_json" | jq -r ".password")"

  subject="[StackMe] Machine Specifications"
  body="$(generate_machine_specs_html)"

  # Send the machine specs email
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
  local total_steps=4

  # Check if the script is running as root
  if [ "$EUID" -ne 0 ]; then
    failure "Please run this script as root or use sudo."
    sleep 2
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
  apt_packages=(
    "sudo" "apt-utils" "apparmor-utils" "apache2-utils" "jq" "python3" 
    "docker" "figlet" "swaks" "netcat" "vnstat" "network-manager" "upower"
  )
  step_message="Installing required apt-get packages"
  step_progress 3 $total_steps "$step_message"
  install_all_packages "apt-get" "${apt_packages[@]}"
  handle_exit $? 3 $total_steps "$step_message"

  snap_packages=(
    "yq"
  )
  step_message="Installing required snao packages"
  step_progress 4 $total_steps "$step_message"
  install_all_packages "snap" "${snap_packages[@]}"
  handle_exit $? 4 $total_steps "$step_message"

  success "Packages installed successfully."

  wait_for_input
}

# Function to clean the local docker environment
clean_docker_environment() {
  highlight "Cleaning local docker environment"
  sanitize

  wait_for_input
}

install_docker() {
  # Ensure the script is running with elevated privileges
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root or with sudo." >&2
    return 1
  fi

  info "Starting Docker installation..."

  # Step 1: Check and install prerequisites
  info "Checking prerequisites..."
  if dpkg -l | grep -qE "apt-transport-https|ca-certificates|curl|software-properties-common"; then
    success "Prerequisites are already installed."
  else
    info "Installing prerequisites..."
    if apt-get install -y -qq \
      apt-transport-https ca-certificates curl software-properties-common; then
      success "Prerequisites installed."
    else
      failure "Failed to install prerequisites." >&2
      return 1
    fi
  fi

  # Step 2: Add Docker's official GPG key and repository (if not already added)
  info "Checking Docker GPG key and repository..."
  keyring_path="/usr/share/keyrings/docker-archive-keyring.gpg"
  if [[ -f "$keyring_path" ]] && grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list; then
    success "Docker GPG key and repository are already configured."
  else
    info "Adding Docker GPG key and repository..."
    url="https://download.docker.com/linux/ubuntu/"
    arch="$(dpkg --print-architecture)"
    source="deb [arch=$arch signed-by=$keyring_path] $url $(lsb_release -cs) stable"
    if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor --yes -o "$keyring_path" && \
        echo "$source" | tee /etc/apt/sources.list.d/docker.list > /dev/null; then
      success "Docker repository added."
    else
      failure "Failed to add Docker GPG key or repository." >&2
      return 1
    fi
  fi

  # Step 3: Install Docker (if not already installed)
  info "Checking Docker installation..."
  if command -v docker > /dev/null 2>&1; then
    success "Docker is already installed: $(docker --version)"
  else
    info "Installing Docker..."
    if apt-get update -qq && \
      apt-get install -y -qq docker-ce docker-ce-cli containerd.io; then
      success "Docker installed successfully."
    else
      failure "Failed to install Docker." >&2
      return 1
    fi
  fi

  # Step 4: Enable Docker service
  info "Checking Docker service status..."
  if systemctl is-enabled docker > /dev/null 2>&1; then
    success "Docker service is already enabled."
  else
    info "Enabling Docker service..."
    if systemctl enable docker > /dev/null 2>&1; then
      success "Docker service enabled to start on boot."
    else
      failure "Failed to enable Docker service." >&2
      return 1
    fi
  fi

  # Step 5: Start Docker service
  info "Checking if Docker service is running..."
  if systemctl is-active docker > /dev/null 2>&1; then
    success "Docker service is already running."
  else
    info "Starting Docker service..."
    if systemctl start docker > /dev/null 2>&1; then
      success "Docker service started successfully."
    else
      failure "Failed to start Docker service." >&2
      return 1
    fi
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
  server_filename="${HOME}/server_info.json"

  # Step 1: Check if server_info.json exists and is valid
  message="Initialization of server information"
  step_progress 1 $total_steps "$message"
  if [[ -f "$server_filename" ]]; then
    server_info_json=$(cat "$server_filename" 2>/dev/null)
    if jq -e . >/dev/null 2>&1 <<< "$server_info_json"; then
      step_info 1 $total_steps "Valid $server_filename found. Using existing information."
    else
      step_error "Content on file $server_filename is invalid. Reinitializing..."
      server_info_json=$(get_server_info)
    fi
  else  
    server_info_json=$(get_server_info)
  fi

  if [[ -z "$server_info_json" ]]; then
    error "Unable to retrieve server and network names."
    wait_for_input
    exit 1
  fi

  # Extract server_name and network_name
  server_name="$(get_variable_value_from_collection "$server_info_json" "server_name")"
  network_name="$(get_variable_value_from_collection "$server_info_json" "network_name")"

  # Output results
  if [[ -z "$server_name" || -z "$network_name" ]]; then
    error "Missing server_name or network_name in file $server_filename"
    wait_for_input
    exit 1
  fi

  # Save the server information to a JSON file
  echo "$server_info_json" > "$server_filename"
  step_success 1 $total_steps "Server information saved to file $server_filename"

  # Update /etc/hosts
  step_message="Add name to server name in hosts file at path /etc/hosts"
  step_progress 2 $total_steps "$step_message"
  # Ensure /etc/hosts has the correct entry
  if ! grep -q "^127.0.0.1[[:space:]]$server_name" /etc/hosts; then
    sed -i "/^127.0.0.1[[:space:]]/d" /etc/hosts  # Remove old entries
    echo "127.0.0.1 $server_name" >> /etc/hosts
  else
    step_info 2 $total_steps "$server_name is already present in /etc/hosts"
  fi

  handle_exit $? 2 $total_steps "$step_message"

    # Set Hostname
  step_message="Set Hostname"
  step_progress 3 $total_steps "$step_message"

  current_hostname="$(hostnamectl --static)"

  if [[ "$current_hostname" != "$server_name" ]]; then
    hostnamectl set-hostname "$server_name"
    handle_exit $? 3 $total_steps "Set Hostname"

    step_success 3 $total_steps "Hostname set to $server_name"

    # Allow a brief delay for changes to propagate
    sleep 1
  else
      step_info 3 $total_steps "Hostname is already set to $server_name"
  fi

  # Install docker
  step_message="Installing Docker"
  step_progress 4 $total_steps "$step_message"
  install_docker
  handle_exit $? 4 $total_steps "$step_message"

  # Initialize Docker Swarm
  step_message="Docker Swarm initialization"
  step_progress 5 $total_steps "$step_message"

  read -r ip _ <<<$(
    hostname -I | tr ' ' '\n' | grep -v '^127\.0\.0\.1' | tr '\n' ' '
  )
  if is_swarm_active; then
    step_warning 5 $total_steps "Swarm is already active"
  else
    # server_ip=$(curl ipinfo.io/ip)
    docker swarm init --advertise-addr $ip 2>&1
    
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
compose_startup() {
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
      - "--certificatesresolvers.letsencryptresolver.acme.dnschallenge=true"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
      - "--metrics.prometheus=true" # Enable Prometheus metrics
      - "--metrics.prometheus.buckets=0.1,0.3,1.2,5.0"
      - "--tracing.jaeger=true" # Enable Jaeger tracing
      - "--tracing.jaeger.samplingType=const"
      - "--tracing.jaeger.samplingParam=1"
      - "--tracing.jaeger.localAgentHostPort=jaeger:6831"

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
      - target: 8082 # Expose Prometheus metrics
        published: 8082
        mode: host

    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.dashboard.rule=Host(\`{{url_traefik}}\`)"
        - "traefik.http.routers.dashboard.entrypoints=websecure"
        - "traefik.http.routers.dashboard.service=api@internal"
        - "traefik.http.routers.dashboard.tls.certresolver=letsencryptresolver"
        - "traefik.http.services.dummy-svc.loadbalancer.server.port=9999"
        - "traefik.http.routers.dashboard.middlewares=myauth"
        - "traefik.http.middlewares.myauth.basicauth.users={{dashboard_credentials}}"

  jaeger:
    image: jaegertracing/all-in-one:1.43
    environment:
      - JAEGER_STORAGE_TYPE=elasticsearch
      - JAEGER_ES_SERVER_URL=http://elasticsearch:9200
      - JAEGER_ES_INDEX_PREFIX=jaeger
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200/_cluster/health"]
      interval: 30s
      retries: 3
    ports:
      - "6831:6831/udp" # Jaeger agent
      - "16686:16686"   # Jaeger UI
    networks:
      - {{network_name}}
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.jaeger.rule=Host(\`{{url_jaeger}}\`)"
        - "traefik.http.routers.jaeger.entrypoints=websecure"
        - "traefik.http.routers.jaeger.tls.certresolver=letsencryptresolver"
        - "traefik.http.services.jaeger.loadbalancer.server.port=16686"
    depends_on:
      - elasticsearch

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.10.0
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"
    networks:
      - {{network_name}}
    volumes:
      - es_data:/usr/share/elasticsearch/data
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G

#  kibana:
#    image: docker.elastic.co/kibana/kibana:7.10.0
#    environment:
#      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
#    ports:
#      - "5601:5601"
#    networks:
#      - {{network_name}}
#    deploy:
#      labels:
#        - "traefik.enable=true"
#        - "traefik.http.routers.kibana.rule=Host(\`{{url_kibana}}\`)"
#        - "traefik.http.routers.kibana.entrypoints=websecure"
#        - "traefik.http.routers.kibana.tls.certresolver=letsencryptresolver"
#        - "traefik.http.services.kibana.loadbalancer.server.port=5601"
#    volumes:
#      - es_data:/usr/share/elasticsearch/data
#    depends_on:
#      - elasticsearch
#
#  grafana:
#    image: grafana/grafana
#    ports:
#      - "3000:3000"
#    networks:
#      - {{network_name}}
#    deploy:
#      labels:
#        - "traefik.enable=true"
#        - "traefik.http.routers.grafana.rule=Host(\`{{url_grafana}}\`)"
#        - "traefik.http.routers.grafana.entrypoints=websecure"
#        - "traefik.http.routers.grafana.tls.certresolver=letsencryptresolver"
#        - "traefik.http.services.grafana.loadbalancer.server.port=3000"
#    depends_on:
#      - elasticsearch
#
#  node-exporter:
#    image: prom/node-exporter:latest
#  
#    networks:
#      - {{network_name}}
#  
#    ports:
#      - "9100:9100"
#  
#    deploy:
#      mode: replicated
#      replicas: 1
#      placement:
#        constraints:
#          - node.role == manager
#      labels:
#        - traefik.enable=true
#        - traefik.http.routers.node-exporter.rule=Host(\`{{url_node}}\`)
#        - traefik.http.services.node-exporter.loadbalancer.server.port=9100
#        - traefik.http.routers.node-exporter.service=node-exporter
#        - traefik.http.routers.node-exporter.tls.certresolver=letsencryptresolver
#        - traefik.http.routers.node-exporter.entrypoints=websecure
#        - traefik.http.routers.node-exporter.tls=true

  prometheus:
    image: prom/prometheus:v2.47.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090" # Prometheus web interface
    networks:
      - {{network_name}}

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.prometheus.rule=Host(\`{{url_prometheus}}\`)
        - traefik.http.services.prometheus.loadbalancer.server.port=9090
        - traefik.http.routers.prometheus.service=prometheus
        - traefik.http.routers.prometheus.tls.certresolver=letsencryptresolver
        - traefik.http.routers.prometheus.entrypoints=websecure
        - traefik.http.routers.prometheus.tls=true

volumes:
  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates
  es_data:
    external: true
    name: volume_es_data

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
    #   - 5432:5432
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

compose_whoami(){
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
        - traefik.http.routers.whoami.rule=Host(\`{{domain_name}}\`)
        - traefik.http.routers.whoami.entrypoints=websecure
        - traefik.http.routers.whoami.priority=1
        - traefik.http.routers.whoami.tls.certresolver=letsencryptresolver
        - traefik.http.services.whoami.loadbalancer.server.port=80

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
  local db_user="postgres"

  local container_id
  local db_exists

  # Display a message about the database creation attempt
  info "Creating PostgreSQL database: $db_name in POstgres container"

  # Check if the container is running
  container_id=$(docker ps -q --filter "name=^postgres")
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
  server_info_filename="${HOME}/server_info.json"
  
  if [[ ! -f "$server_info_filename" ]]; then
    error "File $server_info_filename not found."
    return 1
  fi

  server_info_json="$(cat "$server_info_filename")"
  echo "$(
    search_on_json_array "$server_info_json" "name" "network_name" | \
    jq -r ".value"
  )"

  return 0
}

#################################### BEGIN OF STACK CONFIGURATION #################################

manage_prometheus_config_file() {
  local targets=("$@") # New targets passed as arguments

  prometheus_config_path="$STACKS_FOLDER/prometheus.yml"
  prometheus_scrape_config="$(create_scrape_config_object --job_name "prometheus" \
    --metrics_path "/metrics" \
    --honor_timestamps "false" \
    --honor_labels "true" \
    --scrape_interval "10s" \
    --targets "$(join_array ',' "${targets[@]}")")"

  add_scrape_config_object "$prometheus_config_path" "$prometheus_scrape_config"

  return 0
}

# Function to generate configuration files for startup
generate_config_startup() {
  local stack_name="startup"

  highlight "Gathering $stack_name configuration"

  prompt_items='[
      {
          "name": "email_ssl",
          "label": "E-mail SSL",
          "description": "E-mail to receive SSL notifications",
          "required": "yes",
          "validate_fn": "validate_email_value" 
      },
      {
          "name": "url_traefik",
          "label": "Traefik Domain Name",
          "description": "Domain name for Traefik",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      },
      {
          "name": "dashboard_username",
          "label": "Traefik Dashboard Username",
          "description": "Username for Traefik dashboard",
          "required": "yes",
          "validate_fn": "validate_username" 
      },
      {
          "name": "dashboard_password",
          "label": "Traefik Dashboard Password",
          "description": "Password for Traefik dashboard",
          "required": "yes",
          "validate_fn": "validate_password" 
      },
      {
          "name": "url_prometheus",
          "label": "Prometheus Domain Name",
          "description": "Domain name for logs and metrics",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      },
      {
          "name": "url_jaeger",
          "label": "Jaeger Domain Name",
          "description": "Domain for tracing tool",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      },
      {
          "name": "url_kibana",
          "label": "Kibana Domain Name",
          "description": "Domain name for Kibana",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      },
      {
          "name": "url_grafana",
          "label": "Grafana Domain Name",
          "description": "Domain name for Grafana",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      }
  ]'

  collected_items="$(run_collection_process "$prompt_items")"

  if [[ "$collected_items" == "[]" ]]; then
    error "Unable to retrieve Traefik configuration."
    return 1
  fi

  local network_name="$(get_network_name)"

  if [[ -z "$network_name" ]]; then
    reason="Either stackme was not initialized properly or server_info.json file is corrupted."
    error "Unable to retrieve network name. $reason"
    return 1
  fi

  collected_object="$(process_prompt_items "$collected_items")"

  email_ssl="$(echo "$collected_object" | jq -r '.email_ssl')"
  url_traefik="$(echo "$collected_object" | jq -r '.url_traefik')"
  dashboard_username="$(echo "$collected_object" | jq -r '.dashboard_username')"
  dashboard_password="$(echo "$collected_object" | jq -r '.dashboard_password')"
  
  url_jaeger="$(echo "$collected_object" | jq -r '.url_jaeger')"
  url_prometheus="$(echo "$collected_object" | jq -r '.url_prometheus')"
  url_grafana="$(echo "$collected_object" | jq -r '.url_grafana')"
  url_kibana="$(echo "$collected_object" | jq -r '.url_kibana')"

  dashboard_credentials="$(
        htpasswd -nbB "$dashboard_username" "$dashboard_password" | \
        sed -e 's/\$/\$\$/g' -e 's/\\\//\//g'
  )"

  # Ensure everything is quoted correctly
  manage_prometheus_config_file "$url_prometheus" "$url_jaeger"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg email_ssl "$email_ssl" \
    --arg url_traefik "$url_traefik" \
    --arg url_jaeger "$url_jaeger" \
    --arg url_prometheus "$url_prometheus" \
    --arg url_grafana "$url_grafana" \
    --arg url_kibana "$url_kibana" \
    --arg dashboard_credentials "$dashboard_credentials" \
    --arg network_name "$network_name" \
    '{
        "name": $stack_name,
        "variables": {
          "stack_name": $stack_name,
          "email_ssl": $email_ssl,
          "url_traefik": $url_traefik,
          "dashboard_credentials": $dashboard_credentials,
          "url_jaeger": $url_jaeger,
          "url_prometheus": $url_prometheus,
          "url_kibana": $url_kibana,
          "url_grafana": $url_grafana,          
          "network_name": $network_name
        },
        "dependencies": [],
        "prepare": [],
        "finalize": []
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

  # Prompting step 
  prompt_items='[
      {
          "name": "portainer_url",
          "label": "Portainer URL",
          "description": "URL to access Portainer remotely",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      },
      {	
          "name": "portainer_username",
          "label": "Portainer Username",
          "description": "Username to access Portainer remotely",
          "required": "yes",
          "validate_fn": "validate_username" 
      },
      {
          "name": "portainer_password",
          "label": "Portainer Password",
          "description": "Password to access Portainer remotely",
          "required": "yes",
          "validate_fn": "validate_password"
      }
  ]'

  step_info 3 $total_steps "Prompting required Portainer information"
  collected_items="$(run_collection_process "$prompt_items")"

  if [[ "$collected_items" == "[]" ]]; then
    step_error 3 $total_steps "Unable to prompt Portainer configuration."
    return 1
  fi

  portainer_url="$(\
    get_variable_value_from_collection "$collected_items" "portainer_url" \
  )"

  portainer_username="$(\
    get_variable_value_from_collection "$collected_items" "portainer_username"
  )"

  portainer_password="$(\
    get_variable_value_from_collection "$collected_items" "portainer_password"
  )"

  portainer_credentials="$(
    jq -n \
      --arg username "$portainer_username" \
      --arg password "$portainer_password" \
      '{"username": $username, "password": $password}'  
  )"

  local network_name="$(get_network_name)"  

  jq -n \
  --arg stack_name "$stack_name" \
  --arg portainer_agent_version "$portainer_agent_version" \
  --arg portainer_ce_version "$portainer_ce_version" \
  --arg portainer_url "$portainer_url" \
  --arg portainer_username "$portainer_username" \
  --arg portainer_password "$portainer_password" \
  --argjson portainer_credentials "$portainer_credentials" \
  --arg network_name "$network_name" \
  '{
        "variables": {
            "stack_name": $stack_name,
            "portainer_agent_version": $portainer_agent_version,
            "portainer_ce_version": $portainer_ce_version,
            "portainer_url": $portainer_url,
            "portainer_credentials": $portainer_credentials,
            "network_name": $network_name
        },
        "dependencies": ["startup"],
        "prepare": [],
        "finalize": []
    }' | jq . || {
        echo "Failed to generate JSON"
        return 1
    }
}

# Function to generate configuration files for redis
generate_config_redis() {
  local stack_name = 'redis'

  local network_name="$(get_network_name)"

  highlight "Gathering $stack_name configuration"

  total_steps=1

  step_message="Retrieving Redis image version"
  step_info 1 $total_steps 
  local image_version="$(get_latest_stable_version "redis")"
  handle_exit "$?" 1 $total_steps "$step_message"
  
  info "Redis version: $image_version"

  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_version "$image_version" \
    --arg container_port "6379" \
    --arg redis_url "redis://redis:6379" \
    --arg volume_name "${stack_name}_data" \
    --arg network_name "$network_name" \
    '{
            "name": $stack_name,
            "variables": {
                "image_version": $image_version,
                "container_port": $container_port,
                "redis_url": $redis_url,
                "volume_name": $volume_name,
                "network_name": $network_name
            },
            "dependencies": ["startup", "portainer"],
            "prepare": [],
            "finalize": []
        }' | jq . || {
            error "Failed to generate JSON"
            return 1
        }
}

# Function to generate Postgres service configuration JSON
generate_config_postgres() {
  local stack_name='postgres'
  local image_version='15'

  local postgres_user="postgres"
  local postgres_password="$(random_string)"

  # Ensure everything is quoted correctly
  jq -n \
    --arg stack_name "$stack_name" \
    --arg image_version "$image_version" \
    --arg db_user "$postgres_user" \
    --arg db_password "$postgres_password" \
    --arg volume_name "${stack_name}_data" \
    --arg network_name "$network_name" \
    '{
          "name": $stack_name,
          "variables": {
              "stack_name": $stack_name,
              "image_version": $image_version,
              "volume_name": $volume_name,
              "network_name": $network_name,
              "db_user": $db_user,
              "db_password": $db_password
          },
          "dependencies": ["startup", "portainer"],
          "prepare": [],
          "finalize": []
      }' | jq . || {
        error "Failed to generate JSON"
        return 1
    }
}

generate_config_whoami() {
  local stack_name='whoami'
  local container_port='80'

  total_steps=2

  # Prompting step 
  prompt_items='[
      {
          "name": "domain_name",
          "label": "Whoami domain name",
          "description": "URL to access Whoami remotely",
          "required": "yes",
          "validate_fn": "validate_url_suffix" 
      }
  ]'

  step_info 1 $total_steps "Prompting required WhoAmI information"
  collected_items="$(run_collection_process "$prompt_items")"

  if [[ "$collected_items" == "[]" ]]; then
    step_error 1 $total_steps "Unable to prompt Portainer configuration."
    return 1
  fi

  # Step 2: Retrieve network name
  step_info 2 $total_steps "Retrieving network name"
  network_name="$(get_network_name)"

  domain_name="$(\
    get_variable_value_from_collection "$collected_items" "domain_name" \
  )"

  jq -n \
    --arg stack_name "$stack_name" \
    --arg container_port "$container_port" \
    --arg domain_name "$domain_name" \
    --arg network_name "$network_name" \
    '{
          "name": $stack_name,
          "variables": {
              "stack_name": $stack_name,
              "container_port": $container_port,
              "domain_name": $domain_name,
              "network_name": $network_name,
          },
          "dependencies": ["startup", "portainer"],
          "prepare": [],
          "finalize": []
      }' | jq . || {
        error "Failed to generate JSON"
        return 1
    } 
}

#################################### END OF STACK CONFIGURATION ###################################

################################ BEGIN OF STACK DEPLOYMENT FUNCTIONS ##############################

# Function to deploy a traefik service
deploy_stack_startup() {
  cleanup
  clean_screen
  deploy_stack 'startup'
}

# Function to deploy a portainer service
deploy_stack_portainer() {
  cleanup
  clean_screen
  deploy_stack 'portainer'
}

deploy_stack_startup_and_portainer() {
  cleanup
  clean_screen
  deploy_stack 'startup'

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  clean_screen

  deploy_stack 'portainer'
}

# Function to deploy a PostgreSQL stack
deploy_stack_postgres() {
  cleanup
  clean_screen
  deploy_stack 'postgres'
}

# Function to deploy a Redis service
deploy_stack_redis() {
  cleanup
  clean_screen
  deploy_stack 'redis'
}

# Function to deploy a whoami service
deploy_stack_whoami() {
  cleanup
  clean_screen
  deploy_stack 'whoami'
}

################################# END OF STACK DEPLOYMENT FUNCTIONS ################################

##################################### BEGIN OF MENU DEFINITIONS ####################################

# Stacks
define_menu_stacks(){
  menu_name="Stacks"

  item_1="$(
      build_menu_item "Startup" \
      "Traefik & Jager & Prometheus & ElasticSearch & Kibana & Grafana & Portainer" \
      "deploy_stack_startup_and_portainer"
  )"
  item_2="$(
    build_menu_item "postgres" "Deploy" "deploy_stack_postgres" 
  )"
  item_3="$(
    build_menu_item "redis" "Deploy" "deploy_stack_redis" 
  )"
  item_4="$(
    build_menu_item "whoami" "Deploy" "deploy_stack_whoami"
  )"

  page_size=5

  items=(
    "$item_1" "$item_2" "$item_3" "$item_4"
  )

  menu_object="$(build_menu "$menu_name" $page_size "${items[@]}")"

  define_menu "$menu_name" "$menu_object"
}

# Utilities
define_menu_utilities(){
  menu_name="Utilities"

  item_1="$(\
    build_menu_item "Test SMPT e-mail" \
    "Send" "send_smtp_test_email" \
  )"
  item_2="$(
    build_menu_item "Send Machine Specifications" \
    "Send" "send_machine_specs_email"\
  )"

  items=(
    "$item_1" "$item_2"
  )

  page_size=5

  menu_object="$(build_menu "$menu_name" $page_size "${items[@]}")"

  define_menu "$menu_name" "$menu_object"
}

# VPS Health
define_menu_health(){
  menu_name="Health"

  item_1="$(\
    build_menu_item "Machine specifications" "describe" \
    "diplay_header 'Machine specifications' && generate_machine_specs && wait_for_input"
  )"
  item_2="$(
    build_menu_item "Awake Usage" "describe" \
    "diplay_header 'Uptime' && uptime_usage && wait_for_input"
  )"
  item_3="$(
    build_menu_item "Memory Usage" "describe" \
    "diplay_header 'Memory' && memory_usage && wait_for_input"
  )"
  item_4="$(
    build_menu_item "Disk Usage" "describe" \
    "diplay_header 'Disk' && disk_usage && wait_for_input"
  )"
  item_5="$(
    build_menu_item "Network" "describe" \
    "diplay_header 'Network' && network_usage && wait_for_input"
  )"
  item_6="$(\
    build_menu_item "Top Processes" "list" \
    "diplay_header 'Processes' && top_processes && wait_for_input" \
  )"
  item_7="$(\
    build_menu_item "Security" "diagnose" \
    "diplay_header 'Security' && security_diagnostics && wait_for_input")"
  item_8="$(\
    build_menu_item "Load Average" "describe" \
    "diplay_header 'Load Average' && load_average && wait_for_input")"
  item_9="$(\
    build_menu_item "Bandwidth" "describe" \
    "diplay_header 'Bandwidth' && bandwidth_usage && wait_for_input" \
  )"
  item_10="$(\
    build_menu_item "Package Updates" "install" \
    "diplay_header 'Package Updates' && update_and_check_packages && wait_for_input" \
  )"

  page_size=5

  items=(
    "$item_1" "$item_2" "$item_3" "$item_4" "$item_5" \
    "$item_6" "$item_7" "$item_8" "$item_9" "$item_10"
  )

  menu_object="$(
    build_menu "$menu_name" $page_size "${items[@]}"
  )"

  define_menu "$menu_name" "$menu_object"
}

# Menu Main
define_menu_main(){
  menu_name="Main"

  item_1="$(\
    build_menu_item "Stacks" "explore" "navigate_menu 'Stacks'"\
  )"
  item_2="$(\
    build_menu_item "Utilities" "explore" "navigate_menu 'Utilities'"\
  )"
  item_3="$(\
    build_menu_item "Health" "diagnose" "navigate_menu 'Health'"\
  )"
  
  page_size=5

  items=(
    "$item_1" "$item_2" "$item_3"
  )

  menu_object="$(build_menu "$menu_name" $page_size "${items[@]}")"

  define_menu "$menu_name" "$menu_object"
}

# Populate MENUS
define_menus(){
    define_menu_main
    define_menu_stacks
    define_menu_utilities
    define_menu_health
}

start_main_menu(){
    navigate_menu "Main";
    cleanup
    clean_screen
    farewell_message
}

###################################### END OF MENU DEFINITIONS ####################################

# Display help message
usage() {
  joined_arrows="$(join_array "," "${!ARROWS[@]}")"


  usage_messages=(
    "Usage: $0 [options]"
    "Options:"
    "  -i, --install           Install required packages."
    "  -c, --clean             Clean docker environment."
    "  -a, --arrow             Arrow style: {$joined_arrows}."
    "  -h, --help              Display this help message and exit."
  )
  format_array "info" usage_messages

  display_parallel usage_messages
  sleep 1

  exit 1
}

# Parse command-line arguments
parse_args() {
  # Get options using getopt
  OPTIONS=$(getopt -o a:,c,h --long arrow:,clean,help -- "$@")

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
    -c | --clean)
      CLEAN=true
      shift
      ;;
    -a | --arrow)
      USER_DEFINED_ARROW="$2"
      shift 2
      ;;
    -h | --help)
      usage
      break
      ;;
    --)
      shift
      break
      ;;
    *)
      # This will be triggered for any unrecognized option
      info "Unknown option: $1" >&2
      usage
      return 1
      ;;
    esac
  done
}

# Main script execution
main() {
  parse_args "$@"

  set_arrow
  clear

  # Install required packages
  update_and_install_packages
  clear

  # Perform initialization
  server_config_fname="${HOME}/server_info.json"

  initialize_server_info
  clear

  define_menus

  start_main_menu
}

# Call the main function
main "$@"
