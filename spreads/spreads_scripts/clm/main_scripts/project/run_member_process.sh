#!/bin/bash

# This script handles the processing of each ensemble member.

log "Processing member in directory: $(pwd)"

# Clean up old logs and timing files
rm -f cesm.std* ./logs/run_environment.txt.* ./timing/cesm_timing*

# Run necessary member-specific tasks
if [ "$CONT_RUN" = "FALSE" ]; then
    ./xmlchange CONTINUE_RUN=FALSE
else
    ./xmlchange CONTINUE_RUN=TRUE
fi

# Enable or disable data assimilation for each member
./xmlchange DATA_ASSIMILATION_ATM=TRUE

# Perform date initialization and setup for member
bash "$SCRIPTDIR/initialize_dates.sh"

# Submit the job for this member and capture jobid
jobid=$(bash "$SCRIPTDIR/take_id.sh" ./case.submit)
log "Started with job ID: $jobid"

# Return jobid to the calling script
echo "$jobid"
