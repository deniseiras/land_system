#!/bin/bash

# Configuration
NUM_CYCLES=300  # Default number of cycles is 5 if not provided
SLEEP_INTERVAL=30   # Interval (in seconds) between job status checks
RUN_ASSIMILATION="true"  # Default is to run assimilation (true); set to false to skip it
RUNDIR="/work/cmcc/spreads-lnd/work_d4o/d4o_all30_v4"  # Replace with the actual run directory path

# Ensure the run directory exists
if [[ ! -d "${RUNDIR}" ]]; then
    echo "Error: Run directory ${RUNDIR} does not exist."
    exit 1
fi

# Function to wait for a job to complete using bjobs
wait_for_job_completion() {
    local job_id=$1
    echo "Waiting for job ID: ${job_id}"

    while true; do
        # Get job status and filter for the specific job ID
        local job_status=$(bjobs "${job_id}" 2>/dev/null | grep -w "${job_id}")
        
        # Check if the job ID is no longer in the queue
        if [[ -z "${job_status}" ]]; then
            echo "Job ${job_id} completed successfully."
            break
        fi

        # Check for EXIT state
        local state=$(echo "${job_status}" | awk '{print $3}')
        if [[ "${state}" == "EXIT" ]]; then
            echo "Error: Job ${job_id} exited with failure."
            break
            #exit 1
        fi

        # Print the job status for debugging
        echo "Job ${job_id} is still active: ${job_status}"
        
        # Wait before checking again
        sleep "${SLEEP_INTERVAL}"
    done
}

# Main loop for DA cycles
for (( cycle=1; cycle<=NUM_CYCLES; cycle++ )); do
    echo "Starting cycle ${cycle}..."
    cd "${RUNDIR}" || { echo "Error: Failed to change to run directory ${RUNDIR}"; exit 1; }
    
    # Submit the case.submit job and capture the job ID
    case_output=$(./case.submit)
    job_id=$(echo "${case_output}" | grep -oP 'Submitted job id is \K[0-9]+')
    
    if [[ -z "${job_id}" ]]; then
        echo "Error: Failed to capture job ID from case.submit output."
        echo "case.submit output:"
        echo "${case_output}"
        exit 1
    fi

    echo "Submitted case.submit job with ID: ${job_id}"

    # Wait for the case.submit job to complete
    wait_for_job_completion "${job_id}"

    # Run the assimilation script if enabled
    if [[ "${RUN_ASSIMILATION}" == "true" ]]; then
        echo "Running assimilation script..."
        assimilation_output=$(./assimilate.csh "${RUNDIR}" 0)
        echo "${assimilation_output}"

        # Check if assimilate.csh ran successfully
        if [[ $? -ne 0 ]]; then
            echo "Error: assimilate.csh failed in cycle ${cycle}."
            exit 1
        fi
        echo "Assimilation step completed for cycle ${cycle}."
    else
        echo "Skipping assimilation step for cycle ${cycle} as per configuration."
    fi

    echo "Cycle ${cycle} completed successfully."
done

echo "All ${NUM_CYCLES} cycles completed."
