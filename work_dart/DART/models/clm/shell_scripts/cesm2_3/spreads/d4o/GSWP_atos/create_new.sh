#!/bin/bash
# This script creates modified copies of an original file by replacing
# occurrences of "EDA_n1" with "EDA_n<N>" and "EDA1" with "EDA<N>"
# in the file. The new files are named user_nl_datm_streams_000N, where N is
# formatted with four digits (e.g., 0002, 0003, ...).
#
# Usage:
#   ./make_new_streams.sh <start> <end>
#
# For example, to create files for N=2 to N=10:
#   ./make_new_streams.sh 2 10
#
# If no arguments are provided, the script will default to N=2 to N=10.

# Set default start and end values
start=2
end=15

# Check if user provided command-line arguments
if [ "$#" -ge 2 ]; then
    start=$1
    end=$2
fi

# Input file name (original file)
input_file="user_nl_datm_streams_0001"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

# Loop over the desired N values
for (( N=start; N<=end; N++ )); do
    # Format the new file name with four digits (e.g., 0002, 0003, ...)
    new_file=$(printf "user_nl_datm_streams_%04d" "$N")
    
    # Use sed to perform two global substitutions:
    #   - Replace all occurrences of "EDA_n1" with "EDA_n<N>"
    #   - Replace all occurrences of "EDA1"   with "EDA<N>"
    #
    # The sed command below does both substitutions in one pass.
    sed -e "s/EDA_n1/EDA_n${N}/g" -e "s/EDA1/EDA${N}/g" "$input_file" > "$new_file"
    
    echo "Created $new_file"
done

