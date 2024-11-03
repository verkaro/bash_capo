#!/bin/bash

# Define chromatic scale as an array (C -> B including sharps and flats)
CHROMATIC_SCALE=("C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B")

# Function to transpose a single note or chord
transpose_note() {
    local note=$1
    local steps=$2
    
    # Find the index of the note in the chromatic scale
    for i in "${!CHROMATIC_SCALE[@]}"; do
        if [[ "${CHROMATIC_SCALE[i]}" == "$note" ]]; then
            local index=$i
            break
        fi
    done

    # Calculate the new transposed index
    local new_index=$(( (index + steps + 12) % 12 ))

    # Return the transposed note
    echo "${CHROMATIC_SCALE[new_index]}"
}

# Function to transpose a chord, including bass notes (e.g., G/F# -> A/G#)
transpose_chord() {
    local chord=$1
    local steps=$2
    local main_chord=$chord
    local bass_note=""

    # Check if the chord includes a bass note (e.g., G/F#)
    if [[ "$chord" == */* ]]; then
        main_chord="${chord%%/*}"   # Extract the part before the "/"
        bass_note="${chord##*/}"    # Extract the part after the "/"
    fi

    # Transpose the main chord
    local base_note="${main_chord:0:1}" # Extract first letter of the chord
    local accidental="${main_chord:1:1}" # Check for sharp (#) or flat (b)
    
    if [[ $accidental == "#" || $accidental == "b" ]]; then
        base_note+=$accidental
    fi

    transposed_main=$(transpose_note "$base_note" "$steps")
    transposed_chord="$transposed_main${main_chord:${#base_note}}"

    # Transpose the bass note if present
    if [[ -n "$bass_note" ]]; then
        transposed_bass=$(transpose_note "$bass_note" "$steps")
        echo "$transposed_chord/$transposed_bass"
    else
        echo "$transposed_chord"
    fi
}

# Main function to transpose a line of chords while preserving spacing
transpose_line() {
    local line=$1
    local steps=$2

    # Use regex to match chords and preserve the spacing
    local regex='([A-G][#b]?[mM7]?[0-9]*[\/]?[A-G]?[#b]?[mM7]?[0-9]*)'

    # Read through the line and match chords while preserving spacing
    echo "$line" | sed -E "s/$regex/\n&\n/g" | while IFS= read -r segment; do
        if [[ "$segment" =~ $regex ]]; then
            # If the segment is a chord, transpose it
            transposed_chord=$(transpose_chord "$segment" "$steps")
            echo -n "$transposed_chord"
        else
            # If the segment is spacing, print it as is
            echo -n "$segment"
        fi
    done
    echo
}

# Check for input arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 -steps <steps> OR -fret <fret> <input_file>"
    exit 1
fi

steps=0
input_file=""

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -steps)
            steps=$2
            shift 2
            ;;
        -fret)
            steps=$(( -$2 )) # Transposing down by fret number
            shift 2
            ;;
        *)
            input_file=$1
            shift
            ;;
    esac
done

# Ensure that the input file is provided
if [[ -z "$input_file" ]]; then
    echo "Error: No input file provided."
    echo "Usage: $0 -steps <steps> OR -fret <fret> <input_file>"
    exit 1
fi

# Read from the provided input file
if [[ -n "$input_file" ]]; then
    while IFS= read -r line; do
        if [[ "$line" == %* ]]; then
            # This is a chord line marked by %
            chord_line="${line:2}"  # Strip the % marker and any leading space
            transpose_line "$chord_line" "$steps"
        elif [[ "$line" == \$* ]]; then
            # This is a lyrics line marked by $
            echo "${line:2}"  # Strip the $ marker and print the line as-is
        else
            echo "$line"
        fi
    done < "$input_file"
else
    echo "Error: Unable to read the file."
fi

