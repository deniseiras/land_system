#!/bin/bash
# Loop over all files starting with "user_nl_datm_streams_"
for file in user_nl_datm_streams_*; do
  # Use sed to perform an in-place global replacement
  sed -i 's/presaero\.hist:year_last=2001/presaero.hist:year_last=2003/g' "$file"
done

