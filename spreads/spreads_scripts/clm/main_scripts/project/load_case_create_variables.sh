#!/bin/bash

# This script loads the variables needed from cases_create.sh

# Load case variables from cases_create.sh
load_case_create_variables() {
    source cases_create.sh

    # Replace placeholders in variables
    CLONESROOT=${clonesroot//\${USER}/$USER}
    CLONESROOT=${CLONESROOT//\${CESMEXP}/$CESMEXP}
    case_name=$case_name
    nens=$nens
}

load_case_create_variables
