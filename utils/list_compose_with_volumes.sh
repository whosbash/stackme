#!/bin/bash
# Usage: ./script.sh <directory>
# This script finds all *.yml or *.yaml files within the given directory
# that contain "services:" and "volumes:", counts their lines, and sorts
# the output by line count.

if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

directory="$1"

# Find matching files:
matching_files=$(find "$directory" -type f \( -iname "*.yml" -o -iname "*.yaml" \) \
  -exec grep -q 'services:' {} \; \
  -exec grep -q 'volumes:' {} \; -print)

if [ -z "$matching_files" ]; then
    echo "No matching compose files with volumes found in '$directory'."
    exit 0
fi

# For each file, count lines and output: line_count filename
# Then sort the output numerically by the line count.
for file in $matching_files; do
    line_count=$(wc -l < "$file")
    echo "$line_count $file"
done | sort -n
