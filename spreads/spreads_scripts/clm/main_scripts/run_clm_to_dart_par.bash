#!/bin/bash
#
# This script processes climate model data for DART using LND_DATE_EXT.
# It runs jobs for each ensemble member and processes the outputs accordingly.

# ==============================================
# Input Arguments
# ==============================================
if [ $# -lt 5 ]; then
  echo "Usage: $0 <CASEL> <case_name> <LND_DATE_EXT> <CASESRUNROOT> <nens> <TMPROOT>"
  exit 1
fi

export MOVE='/usr/bin/mv -v'
export COPY='/usr/bin/cp -v --preserve=timestamps'

CASEL=$1
case_name=$2
LND_DATE_EXT=$3
CASESRUNROOT=$4
nens=$5
TMPROOT=$6

#TMPROOT="/work/cmcc/spreads-lnd/CMCC-CM/TMPLAND_EXP60"  # Set the TMPROOT location

echo "inside ./run_clm_to_dart_par.bash ${CASEL} ${case_name} ${LND_DATE_EXT} ${CASESRUNROOT} ${nens} ${TMPROOT}"
string_id=""
job_ids=()  # List to store job IDs

# ==============================================
# Function Definitions
# ==============================================

# Function to take the id of the case.submit processes
take_id() {
  output=$("$@")
  echo 'OUTPUT: ' $output
  echo $output
}

# Function to process data for a specific ensemble member
process_data() {
   local ni=$1  # Pass ensemble index as an argument
   local FILE=$2  # Pass the FILE as an argument
   local OUTPUT=$3  # Pass the OUTPUT as an argument

   # Create a RAM disk directory for faster file operations
   ramdisk_dir="/dev/shm/clm_${ni}_tmp"
   mkdir -p "$ramdisk_dir" || { echo "Error: Unable to create RAM disk directory"; exit 1; }

   # Copy the ensemble restart file into the RAM disk
   echo "Copying $FILE to RAM disk: $ramdisk_dir"
   cp -f "$FILE" "$ramdisk_dir/clm.nc" || { echo "Error: Failed to copy $FILE to RAM disk"; exit 1; }

   # Copy input.nml to RAM disk as well
   cp -f input.nml "$ramdisk_dir/" || { echo "Error: Failed to copy input.nml"; exit 1; }

   # Change to the RAM disk directory to process files
   cd "$ramdisk_dir" || { echo "Error: Failed to change directory to $ramdisk_dir"; exit 1; }

   # Run the clm_to_dart process using the absolute path
   echo "Running clm_to_dart in $ramdisk_dir"
   ${TMPROOT}/clm_to_dart

   # Move the processed file directly to the final output location
   echo "Moving processed file to $OUTPUT"
   mv clm.nc ${TMPROOT}/${OUTPUT} || { echo "Error: Failed to move clm.nc to $OUTPUT"; exit 1; }

   # Clean up the RAM disk
   cd -
   rm -rf "$ramdisk_dir" || { echo "Error: Failed to clean up RAM disk"; exit 1; }

   echo "Processed $OUTPUT using RAM disk"
}

export -f process_data
export -f take_id

# ==============================================
# Main Execution Loop: Iterate over ensemble members
# ==============================================

enscount=1
for ii in $(seq 1 ${nens}); do
  ni=$(printf "%04d" ${ii})  # Zero-padded ensemble index
  FILE="${CASESRUNROOT}/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.r.${LND_DATE_EXT}.nc"
  OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"

  # Check if the input file exists
  if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found!"
    exit 1
  fi

  # Prepare the working directory for this ensemble member
  NDIR="cc_${enscount}"
  WORK_DIR="${TMPROOT}/tmp/${NDIR}"

  # Ensure the directory exists by recreating it
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"

  # Submit the processing job using bsub
  kk=$(bsub -J "process_${NDIR}" -oo "process_${NDIR}.log" << EOF
#!/bin/bash
#BSUB -P R000
#BSUB -W 00:20
#BSUB -n 2
#BSUB -q p_short
#BSUB -R "rusage[mem=240GB]"  # Adjust memory usage to include RAM disk size (10 GB per process)
#BSUB -R "span[ptile=72]"     # Maximize core usage per node
#BSUB -app spreads_filter

# Load necessary modules
source /users_home/cmcc/lg07622/modules_juno.me

# Process the data in RAM disk
process_data "$ni" "$FILE" "$OUTPUT"
EOF
)

jobid=`echo "${kk//<}" | awk '{print $2}'`
if [ $enscount -eq 1 ]; then 
  string_id=$string_id"post_done(${jobid//>})"
else
  string_id=$string_id" && post_done(${jobid//>})"
fi

  ((enscount++))
done

# Join job IDs into a space-separated string for bwait
#job_id_list=$(printf " %s" "${job_ids[@]}")

# Wait for all submitted jobs to finish using bwait
#echo "Waiting for jobs: $job_id_list"
#bwait -w "ended($job_id_list)"

# Wait for all jobs to finish
echo "Waiting for jobs: $string_id"
bw=0
bwait -w "$string_id" || bw=$?
bjobs


# ==============================================
# Post-processing: Move and log output files
# ==============================================

enscount=1
for ii in $(seq 1 ${nens}); do
  ni=$(printf "%04d" ${ii})  # Zero-padded ensemble index
  OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"
  NDIR="cc_${enscount}"

  # Log the restart, history, and vector files
  ls "${OUTPUT}" >> restart_files.txt
  ls "${CASESRUNROOT}/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.h0.${LND_DATE_EXT}.nc" >> history_files.txt
  ls "${CASESRUNROOT}/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.h2.${LND_DATE_EXT}.nc" >> vector_files.txt

  ((enscount++))
done

echo "ALL CLM_TO_DART JOBS FINISHED"

rm -f process_cc_*.log
exit 0
