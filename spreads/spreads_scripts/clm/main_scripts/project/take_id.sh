#!/bin/bash

# Extract job ID from the case.submit output

output=$($*)
echo $output | awk '{print $NF}'
