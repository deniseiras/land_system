#!/bin/bash

# This script handles one-shot assimilation process

log "Starting one-shot assimilation..."

# Merge the databases for assimilation
bash "$SCRIPTDIR/database_merge.sh"

# Run assimilation processes
bash "$SCRIPTDIR/run_assimilation_filter.sh"
