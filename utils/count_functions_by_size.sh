#!/bin/bash

count_functions_by_size() {
    local file="$1"          # The shell script file to analyze

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
        echo "$function_name:$line_count"
    done
}

# Example usage:
count_functions_by_size "$1" "$2"
