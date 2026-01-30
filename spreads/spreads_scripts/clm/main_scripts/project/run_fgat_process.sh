#!/bin/bash

# This script handles FGAT assimilation process

log "Starting FGAT assimilation process..."

# Your FGAT logic here, including database merging and observation handling
bash "$SCRIPTDIR/fgat_database_merge.sh"

# More FGAT processing steps as needed
