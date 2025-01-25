#!/bin/bash

# Using a while loop with a pipe
example_using_pipe() {
  local input="one two three"
  local updated_input="zero "

  echo "Before: '$updated_input'"  # This will be empty

  echo "$input" | tr ' ' '\n' | while IFS= read -r word; do
    updated_input="$updated_input$word "
  done

  echo "After: '$updated_input'"  # This will also be empty
}

# Using a while loop without a pipe
example_using_while() {
  local input="one two three"
  local updated_input="zero "

    echo "Before '$updated_input'"  # This will contain the full string
  

  # Using a while loop and reading input directly
  while read -r word; do
    updated_input="$updated_input$word"
  done <<< "$input"  # Use <<< to pass the string directly into the loop

  echo "After '$updated_input'"  # This will also contain the full string
}

example_using_for() {
  local input="one two three"
  local updated_input="zero "

    echo "Before: '$updated_input'"  # This will contain the full string

  # Using a for loop to iterate over words
  for word in $input; do
    updated_input="$updated_input$word "
  done

  echo "After: '$updated_input'"  # This will also contain the full string
}

echo "Example 1: Using a while loop with a pipe"
example_using_pipe

echo "Example 2: Using a while loop without a pipe"
example_using_while

echo "Example 3: Using a for loop"
example_using_for
