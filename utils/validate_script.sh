#!/bin/bash

# Color Constants
COLOR_RESET="0"
COLOR_RED="31"    # Error
COLOR_GREEN="32"  # Success
COLOR_YELLOW="33" # Warning
COLOR_BLUE="34"   # Info
COLOR_PURPLE="35" # Header

# Fence repeated char
FENCE_CHAR='-'

DEFAULT_LINE_LENGTH=100
DEFAULT_FUNCTION_LENGTH=100
DEFAULT_SPACING=1
DEFAULT_VERBOSE=FALSE

DEPENDENCIES=("curl" "awk" "sed" "shfmt")

# Global counters for warnings and errors
global_warnings=0
global_errors=0


# Function: Repeat a character for a specified length
repeat() {
    local line_length="$1"
    local repeat_char="$2"
    printf "%0.s${repeat_char}" $(seq 1 "$line_length")
}

verbose_print() {
    [[ "$verbose" == "true" ]] && print_message "$COLOR_YELLOW" "$1"
}

# Helper: Display colored messages
print_message() {
    local color="$1"
    local message="$2"
    echo -e "\033[${color}m${message}\033[${COLOR_RESET}m"
}

# Helper: Print a fence line
print_fence() {
    local color="$1"
    local line_length="${2:-$DEFAULT_LINE_LENGTH}" # Default length is 60 if not provided
    local char="${3:-$FENCE_CHAR}"                 # Default character is '-'
    print_message "$color" "$(repeat "$line_length" "$char")"
}

# Function: Print a header with repeated characters
print_header() {
    local header="$1"
    local color="${2:-$COLOR_PURPLE}"
    local repeat_char="${3:--}"
    local line_length="${4:-$DEFAULT_LINE_LENGTH}"

    # Print the header with decorations
    print_fence "$color" "$line_length" "$repeat_char"
    print_message "$color" " $header"
    print_fence "$color" "$line_length" "$repeat_char"
}

# Helper: Increment counters
increment_warnings() {
    global_warnings=$((global_warnings + $1))
}

increment_errors() {
    global_errors=$((global_errors + $1))
}

# File validation functions
validate_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        message="Error: File '$file' does not exist. Please provide a valid file."
        print_message "$COLOR_RED" "$message"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        message="Error: File '$file' is not readable. Check file permissions."
        print_message "$COLOR_RED" "$message"
        return 1
    fi

    return 0
}

validate_file_extension() {
    local file="$1"
    local valid_extensions=("sh" "bash" "zsh")
    local extension="${file##*.}"
    if [[ ! " ${valid_extensions[@]} " =~ " ${extension} " ]]; then
        print_message "$COLOR_RED" \
            "Error: Invalid file extension '$extension'. Only .sh, .bash, .zsh are allowed."
        exit 1
    fi
}

check_best_practices() {
    local file="$1"
    local verbose="$2"

    print_header "Checking for Shell Script Best Practices" "$COLOR_PURPLE"

    validate_file "$file"

    local best_practices_satisfied=true

    # Check for unquoted variables, which might lead to word splitting
    if grep -Pq '\$[a-zA-Z_][a-zA-Z0-9_]*' "$file" | grep -Pv '"'; then
        print_message "$COLOR_YELLOW" "Warning: Some variables are not quoted properly."
        if [[ "$verbose" == "true" ]]; then
            message="Consider using double quotes around variables to prevent word splitting."
            print_message "$COLOR_GREEN" "$message"
        fi
        best_practices_satisfied=false
    fi

    # Check for usage of 'exit' within functions
    # Find functions that contain 'exit' statements without proper status codes
    matching_exit_lines=$(\
        grep -n 'exit\s*[^0-9]*' "$file" | \
        grep -P '^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(.*\)\s*{.*\n*exit'
    )
    
    if [[ -n "$matching_exit_lines" ]]; then
        recommendation="It is recommended to use 'exit 0' for success, or proper status codes."
        claim="'exit' used within functions without a valid status code"
        warning_message="Warning: $claim. $recommendation"
        print_message "$COLOR_YELLOW" "$message"
        if [[ "$verbose" == "true" ]]; then
            example="like 'exit 0' for successful execution."
            explanation="Ensure that 'exit' is used with a proper exit status, $example"
            print_message "$COLOR_GREEN" "$explanation"
        fi
        
        # Display only the functions containing problematic 'exit' usage
        print_message "$COLOR_YELLOW" \
            "The following functions have invalid exit status codes:"
        
        # Filter out the non-relevant lines and 
        # only show the actual functions and problematic 'exit' lines
        echo "$matching_exit_lines" | while read -r line; do
            echo "$line"  # Display only the lines containing exit with improper status
        done
        
        best_practices_satisfied=false
    fi

    # If no issues were found, print a success message
    if [[ "$best_practices_satisfied" == true ]]; then
        print_message "$COLOR_GREEN" "Best practices are followed in the script."
    fi

    echo ""
}

check_dependencies() {
    local file="$1"
    local verbose="$2"

    print_header "Checking for External Dependencies"

    validate_file "$file"

    # Iterate through each dependency in the list
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            print_message "$COLOR_YELLOW" "Warning: Dependency '$dep' is not installed."

            # Notify the user that the dependency will be installed
            print_message "$COLOR_YELLOW" \
                "Attempting to install '$dep'. This requires sudo privileges."

            # Prompt user for confirmation before proceeding with installation
            read -p "Do you want to install '$dep' now? (y/n): " user_input
            if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
                # Attempt to install the dependency using sudo 
                if sudo apt-get install -y "$dep"; then
                    print_message "$COLOR_GREEN" \
                    "Dependency '$dep' has been successfully installed."
                else
                    claim="Failed to install '$dep'"
                    recommendation="Please check your permissions or package manager."
                    print_message "$COLOR_RED" "Error: $claim. $recommendation"
                fi
            else
                print_message "$COLOR_RED" "Skipping installation of '$dep'."
            fi
        else
            print_message "$COLOR_GREEN" "Dependency '$dep' is installed."
        fi
    done
    echo ""
}

check_todo_comments() {
    local file="$1"
    local verbose="$2"

    print_header "Checking for TODO, FIXME, or XXX Comments"

    validate_file "$file"

    # Match TODO, FIXME, or XXX preceded by '#' and spaces
    local todo_comments=$(grep -iE '^[[:space:]]*#[[:space:]]*(TODO|FIXME|XXX)\b' "$file")

    if [[ -n "$todo_comments" ]]; then
        print_message "$COLOR_YELLOW" "Found TODO/FIXME/XXX comments in the code:"
        print_message "$COLOR_YELLOW" "$todo_comments"
    else
        print_message "$COLOR_GREEN" "No TODO/FIXME/XXX comments found."
    fi
    echo ""
}

check_indentation() {
    local file="$1"
    local verbose="$2"

    print_header "Checking for Consistent Indentation"

    validate_file "$file"
    local indentation_error=0
    local line_number=0
    local indent_issue_lines=()

    # Check for inconsistent indentation (accept 2 or 4 spaces)
    while IFS= read -r line; do
        ((line_number++))

        # Match lines with either 2 or 4 spaces but not other combinations
        if [[ "$line" =~ ^[[:space:]]+ && ! "$line" =~ ^([[:space:]]{2}|[[:space:]]{4}) ]]; then
            indentation_error=1
            indent_issue_lines+=("$line_number: $line")  # Store the line number and content
        fi
    done <"$file"

    if [[ "$indentation_error" -eq 1 ]]; then
        message="Inconsistent indentation found. Fixing indentation using shfmt."
        print_message "$COLOR_YELLOW" "Warning: $message"

        # Print the lines with issues
        echo "Indentation issues found at the following lines:"
        for issue in "${indent_issue_lines[@]}"; do
            echo "$issue"
        done
        echo ""

        # Use shfmt to automatically fix the indentation (standardize to 2 spaces)
        shfmt -w -i 2 "$file"

        # Check indentation again after shfmt fixes it
        indentation_error=0
        unset indent_issue_lines
        line_number=0

        while IFS= read -r line; do
            ((line_number++))

            # Check again for inconsistent indentation
            if [[ "$line" =~ ^[[:space:]]+ && ! "$line" =~ ^([[:space:]]{2}|[[:space:]]{4}) ]]; then
                indentation_error=1
                indent_issue_lines+=("$line_number: $line")  # Store the line number and content
            fi
        done <"$file"

        if [[ "$indentation_error" -eq 0 ]]; then
            print_message "$COLOR_GREEN" "Indentation has been fixed and is now consistent."
        else
            print_message "$COLOR_RED" "Indentation issue persists after fixing with shfmt."
            echo "The following lines still have indentation issues:"
            for issue in "${indent_issue_lines[@]}"; do
                echo "$issue"
            done
        fi
    else
        print_message "$COLOR_GREEN" "Indentation is consistent."
    fi
    echo ""
}

# Code quality functions
check_cyclomatic_complexity() {
    local file="$1"
    local verbose="$2"

    print_header "Calculating Cyclomatic Complexity"

    validate_file "$file"

    # Count keywords contributing to complexity
    local keywords="if|elif|else|for|while|case|esac|until|select|do|done|function"
    local complexity_count=$(grep -cEo "\\b($keywords)\\b" "$file")

    print_message "$COLOR_GREEN" "Cyclomatic complexity: $complexity_count"
    echo ""
}

check_function_complexity() {
    local file="$1"
    local verbose="$2"

    print_header "Checking Function Complexity"

    validate_file "$file"

    # Example of simple complexity calculation based on keywords
    local function_complexity=0
    while IFS= read -r line; do
        if [[ "$line" =~ \b(if|for|while|case)\b ]]; then
            ((function_complexity++))
        fi
    done <"$file"

    if [[ "$function_complexity" -gt 5 ]]; then
        print_message "$COLOR_YELLOW" \
            "Function complexity is too high ($function_complexity). Consider refactoring."
    else
        print_message "$COLOR_GREEN" "Function complexity is acceptable."
    fi
    echo ""
}

check_logical_lines() {
    local file="$1"
    local verbose="$2"

    print_header "Counting Logical Lines of Code"

    validate_file "$file"

    # Count non-blank and non-comment lines
    local logical_lines=$(grep -cvE '^\s*(#|$)' "$file")

    print_message "$COLOR_GREEN" "Total logical lines: $logical_lines"
    echo ""
}

check_line_spacing() {
    local file="$1"
    local max_spacing=1 # Maximum allowable blank line spacing

    # Validate the input file
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    print_header "Checking that spacing between lines does not exceed $max_spacing in $file"

    # Initialize variables
    local prev_useful_line=0
    local curr_line_number=0
    local has_error=0

    # Process the file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        curr_line_number=$((curr_line_number + 1))

        # Skip blank lines only
        if [[ -z "$line" ]]; then
            continue
        fi

        # Treat non-blank lines (including comments) as useful lines
        if [[ $prev_useful_line -ne 0 ]]; then
            local spacing=$((curr_line_number - prev_useful_line - 1))

            # Flag an error if spacing exceeds the maximum allowable spacing
            if [[ $spacing -gt $max_spacing ]]; then
                echo "Spacing error: $spacing blank lines between useful lines $prev_useful_line and $curr_line_number (maximum allowed is $max_spacing)."
                has_error=1
            fi
        fi

        # Update the previous useful line tracker
        prev_useful_line=$curr_line_number
    done < "$file"

    # Final message
    if [[ $has_error -eq 0 ]]; then
        print_message "$COLOR_GREEN" "Line spacing check passed."
    else
        print_message "$COLOR_YELLOW" "Line spacing check failed."
    fi
    echo ""
}


check_nesting_depth() {
    local file="$1"
    local verbose="$2"

    print_header "Calculating Nesting Depth"

    validate_file "$file"

    # Simulate nesting depth by tracking braces and keywords
    local depth=0
    local max_depth=0

    while IFS= read -r line; do
        # Increment for opening constructs
        if [[ $line =~ \b(if|for|while|case|function)\b ]]; then
            ((depth++))
            [[ $depth -gt $max_depth ]] && max_depth=$depth
        fi

        # Decrement for closing constructs
        if [[ $line =~ \b(fi|done|esac|;;|})\b ]]; then
            ((depth--))
        fi
    done <"$file"

    print_message "$COLOR_GREEN" "Nesting depth: $max_depth"
    echo ""
}

check_large_lines() {
    local file="$1"
    local max_length="$2"
    local verbose="$3"

    print_header "Checking for Large Lines"

    validate_file "$file"

    # Track the number of large lines
    local lines_found=0

    # Use awk to find lines larger than max_length and print them
    awk -v max_length="$max_length" '
        length($0) > max_length {
            print NR ": " length($0) " characters - " $0
            lines_found++
        }
    ' "$file" > /tmp/large_lines_output.txt

    # Capture the output of awk into a variable
    local output=$(cat /tmp/large_lines_output.txt)

    # If any large lines were found, print them in yellow
    if [[ -n "$output" ]]; then
        print_message "$COLOR_YELLOW" "$output"

        # Count how many lines were found
        local lines_found=$(echo "$output" | grep -c "characters")
        increment_warnings "$lines_found"
    else
        # If no large lines were found, print nothing or an empty message
        print_message "$COLOR_GREEN" "No lines exceeding $max_length characters found."
    fi

    # Clean up temporary file
    rm /tmp/large_lines_output.txt

    echo ""
}

# Function to check the length of functions
check_function_length() {
    local file="$1"          # The shell script file to analyze
    local max_count="$2"     # The maximum number of lines allowed per function
    local verbose="$3"       # If true, will print verbose information

    print_header "Checking Function Length"

    validate_file "$file"

    local awk_script='
    BEGIN { inside_function=0; }
    /^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{/ { inside_function=1; function_name=$1; line_count=0; }
    inside_function { line_count++; }
    /^\}/ { if (inside_function) { inside_function=0; print function_name ":" line_count; } }
    '  

    # Extract function names and line counts using AWK
    function_sizes=$(awk "$awk_script" "$file")

    declare -A function_names_line_counts

    # Parse function names and their respective line counts
    for entry in $function_sizes; do
        function_name=$(echo "$entry" | cut -d ':' -f1)
        line_count=$(echo "$entry" | cut -d ':' -f2)

        # Remove any parentheses or curly brackets from the function name (if any)
        function_name=$(echo "$function_name" | sed 's/[(){}]//g')

        function_names_line_counts["$function_name"]=$line_count
    done

    # Sort the functions by line count in descending order
    sorted_function_names=$(for function_name in "${!function_names_line_counts[@]}"; do
        echo "${function_names_line_counts[$function_name]}:$function_name"
    done | sort -n | cut -d ':' -f2-)

    # Print the function name and row count in the desired format
    for function_name in $sorted_function_names; do
        line_count=${function_names_line_counts[$function_name]}

        # Check if the function exceeds max_count
        if [[ $line_count -gt $max_count && $verbose ]]; then
            print_message "$COLOR_YELLOW" "Function '$function_name' exceeds the max allowed lines ($max_count lines) by $((line_count - max_count)) lines!"
        fi
    done
}

# Process a single file
process_checks() {
    local file="$1"
    local max_line_length="${2:-$DEFAULT_LINE_LENGTH}"
    local max_function_length="${3:-$DEFAULT_FUNCTION_LENGTH}"
    local spacing="${4:-$DEFAULT_SPACING}"
    local verbose="${5:-DEFAULT_VERBOSE}"

    check_cyclomatic_complexity "$file" "$verbose"
    check_logical_lines "$file" "$verbose"
    check_nesting_depth "$file" "$verbose"
    check_large_lines "$file" "$max_line_length" "$verbose"
    check_function_length "$file" "$max_function_length" "$verbose"
    check_function_complexity "$file" "$verbose"
    check_line_spacing "$file" "$spacing" "$verbose" 
    check_best_practices "$file" "$verbose"
    check_dependencies "$file" "$verbose"
    check_todo_comments "$file" "$verbose"
    check_indentation "$file" "$verbose"
}

process_file() {
    local verbose="${1:-DEFAULT_VERBOSE}"
    local max_line_length="${2:-$DEFAULT_LINE_LENGTH}"
    local max_function_length="${3:-$DEFAULT_FUNCTION_LENGTH}"
    local spacing="${4:-$DEFAULT_SPACING}"

    local file="$5"

    print_message "$COLOR_BLUE" "Processing file: $file"
    process_checks "$file" "$max_line_length" "$max_function_length" "$spacing" "$verbose"
    print_message "$COLOR_GREEN" "Processing completed for file: $file"
}

process_multiple_files() {
    local max_line_length="${1:-$DEFAULT_LINE_LENGTH}"
    local max_function_length="${2:-$DEFAULT_FUNCTION_LENGTH}"
    local spacing="${3:-$DEFAULT_SPACING}"
    local verbose="${4:-DEFAULT_VERBOSE}"

    shift
    local files=("$@")

    # Process each file without sourcing the script
    for file in "${files[@]}"; do
        process_file "$max_line_length" "$max_function_length" "$spacing" "$verbose" "$file"
        "$verbose"
    done
}

usage() {
    print_message "$COLOR_PURPLE" "Usage: $0 [OPTIONS] file1 [file2 ...]"
    print_message "$COLOR_PURPLE" ""
    print_message "$COLOR_PURPLE" "Options:"
    print_message "$COLOR_PURPLE" "  -v, --verbose       Enable verbose mode for detailed output"
    print_message "$COLOR_PURPLE" "  -h, --help          Display this help message"
    exit 0
}

# Function to parse arguments and initiate checks
parse_arguments() {
    local verbose=false
    local max_line_length="$DEFAULT_LINE_LENGTH"
    local max_function_length="$DEFAULT_FUNCTION_LENGTH"
    local spacing="$DEFAULT_SPACING"
    local files=()

    # Define getopt options
    TEMP=$(
        getopt -o vhlf: --long verbose,help,max-line-length,max-function-length: -n "$0" -- "$@"
    )
    if [[ $? -ne 0 ]]; then
        usage
    fi

    # Parse options
    eval set -- "$TEMP"

    while true; do
        case "$1" in
        -v | --verbose)
            verbose=true
            shift
            ;;
        -h | --help)
            usage
            ;;
        -l | --max-line-length)
            max_line_length="$2"
            shift 2
            ;;
        -f | --max-function-length)
            max_function_length="$2"
            shift 2
            ;;
        -s | --spacing)
            spacing="$2"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
        esac
    done

    # Remaining arguments are files
    files=("$@")

    # Ensure max-function-length is positive
    if [[ "$max_line_length" -le 0 ]]; then
        echo "Error: max-length must be a positive integer."
        exit 1
    fi

    # Ensure max-function-length is positive
    if [[ "$max_function_length" -le 0 ]]; then
        echo "Error: max-function-length must be a positive integer."
        exit 1
    fi

    # Ensure spacing is either 1 or 2
    if [[ "$spacing" != "1" && "$spacing" != "2" ]]; then
        echo "Error: Spacing must be '1' or '2'."
        exit 1
    fi

    # Ensure at least one file is provided
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Error: No files provided."
        exit 1
    fi

    # Process files
    if [[ ${#files[@]} -eq 1 ]]; then
        process_file "$verbose" "$max_line_length" "$max_function_length" "$spacing" "${files[0]}"
    else
        process_multiple_files \
            "$verbose" "$max_line_length" "$max_function_length" "$spacing" "${files[@]}"
    fi

    # Summary report
    print_header "Summary of Checks:" "$COLOR_BLUE"

    print_message "$COLOR_RED" "Total Errors: $global_errors"
    print_message "$COLOR_YELLOW" "Total Warnings: $global_warnings"
    echo ""
}

# Main function call
parse_arguments "$@"