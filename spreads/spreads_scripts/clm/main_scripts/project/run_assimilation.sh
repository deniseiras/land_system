#!/bin/bash

# Main script to handle assimilation and forecast processes

# Exit on any error and log errors
set -e
trap 'log_error "Error at line $LINENO"' ERR

# Logging function
log() {
    echo "$(date): $1" | tee -a "$SCRIPTDIR/script.log"
}

log_error() {
    echo "$(date): [ERROR] $1" | tee -a "$SCRIPTDIR/script.log" >&2
}

# Function to initialize variables from external scripts
initialize_variables() {
    SCRIPTDIR=$(pwd)
    source "$SCRIPTDIR/load_case_create_variables.sh"
}

# Function to run a cycle for each ensemble member
run_cycle() {
    local cycle=$1
    log "Starting cycle $cycle"

    # Array to hold job IDs
    job_ids=()

    # Submit jobs for all ensemble members
    for member in "${members[@]}"; do
        log "Processing member $member"
        jobid=$(cd "$CLONESROOT/$case_name$member" && bash "$SCRIPTDIR/run_member_process.sh")
        job_ids+=("$jobid")
    done

    # Create a dependency string for all job ids
    dependency_string=$(printf "done(%s) && " "${job_ids[@]}")
    dependency_string="${dependency_string% && }"

    # Wait for all jobs to finish using bsub dependencies
    log "Waiting for jobs: $dependency_string"
    bsub -w "$dependency_string" bash "$SCRIPTDIR/post_cycle_processing.sh"  # Replace with actual post-processing step
}

# Assimilation and Forecast Phases with Retry Logic
run_fgat_process() {
    if [ "$ACTIVATE_ASSI" = "FALSE" ]; then
        log "No assimilation required, proceeding with forecast"
        if [ "$FORECAST" = "TRUE" ]; then
            bash "$SCRIPTDIR/run_forecast.sh"
        fi
    else
        log "Starting assimilation process"

        # Check assimilation flag file for status (similar to original script)
        if grep -q "1" check_assi.flag; then
            log "Check_assi is positive, continuing with the next step"
            sed -i 's/1/0/g' check_assi.flag
        else
            log "Previous assimilation failed, attempting retry"

            for ((attempt=1; attempt<=MAXTRY; attempt++)); do
                log "Attempt $attempt of $MAXTRY"
                ./cases_assimilate.bash "$FGAT"

                # Check the result of the assimilation by inspecting the flag file
                if grep -q "1" check_assi.flag; then
                    log "Assimilation successful on attempt $attempt"
                    sed -i 's/1/0/g' check_assi.flag
                    break
                else
                    log "Assimilation failed on attempt $attempt"
                fi
            done

            # After the max attempts, if still not successful, exit with an error
            if ! grep -q "1" check_assi.flag; then
                log_error "All $MAXTRY attempts failed for assimilation"
                exit 130
            fi
        fi

        # After assimilation, handle forecast phase
        if [ "$FORECAST" = "TRUE" ]; then
            bash "$SCRIPTDIR/run_forecast.sh"
        fi
    fi

    # Clean-up phase if required
    if [ "$CLEANA" = "TRUE" ]; then
        bash "$SCRIPTDIR/clean_up.sh"
    fi
}

# Main function that drives the script
main() {
    initialize_variables

    members=($(seq -f "_%04g" 1 "$nens"))

    for ((ncyc=1; ncyc<=NCYCLES; ncyc++)); do
        run_cycle "$ncyc"
    done

    run_fgat_process
}

# Execute the main function
main "$@"
