#!/bin/bash

shift_option_text() {
    local text="$1"
    local max_length="${2-50}" # Default max length is 50
    local delay="${3-0.2}"     # Default delay between shifts is 0.2 seconds

    # If the text is shorter than or equal to max_length, display it as-is
    if [[ ${#text} -le $max_length ]]; then
        echo "$text"
        return
    fi

    # Loop to shift the text
    while true; do
        for i in $(seq 0 $(( ${#text} - 1 ))); do
            # Create the substring to display
            local shifted_text="${text:$i:$max_length}"
            
            # Wrap around when the end of the text is reached
            if [[ ${#shifted_text} -lt $max_length ]]; then
                shifted_text+="${text:0:$((max_length - ${#shifted_text}))}"
            fi
    
            # Display the shifted text and wait for the delay
            echo -ne "\r$shifted_text"
            sleep "$delay"
        done
    done
}

shift_option_text "This is a very long option text that should shift to let the user read it fully." 30 0.1
