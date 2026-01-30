#!/bin/bash
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# This script performs an assimilation by directly reading and writing to
# the CLM restart file.
#
# NOTE: 'dart_to_clm' does not currently support updating the 
# prognostic snow variables based on posterior SWE values.
# Consequently, snow DA is not currently supported.
# Implementing snow DA is high on our list of priorities. 

#=========================================================================
# This block is an attempt to localize all the machine-specific
# changes to this script such that the same script can be used
# on multiple platforms. This will help us maintain the script.
#=========================================================================

echo "$(date) -- BEGIN CLM_ASSIMILATE"

# As of CESM2.0, the assimilate.sh is called by CESM - and has
# two arguments: the CASEROOT and the DATA_ASSIMILATION_CYCLE

#source /users_home/cmcc/lg07622/modules_juno.me
module purge
unset LIBRARY_PATH
module load --auto intel-2021.6.0/2021.6.0
module load --auto intel-2021.6.0/libszip/2.1.1-tvhyi
module load --auto impi-2021.6.0/2021.6.0
module load --auto anaconda/3-2022.10
module load --auto intel-2021.6.0/sqlite/3.40.0-v3tky
module load --auto intel-2021.6.0/perl-dbi/1.643-3satl
module load --auto intel-2021.6.0/perl-dbd-sqlite/1.72-3f7xn
module load --auto intel-2021.6.0/jasper/2.0.32-rofnd
module load --auto intel-2021.6.0/libjpeg-turbo/2.1.4-tk73d
export LIBRARY_PATH=":$LD_LIBRARY_PATH" # without this line the build.juno does not find -ljpeg f.ex.
module -t list

shopt -s nullglob # suppress "rm" warnings if wildcard does not match anything

ffgat="FALSE"
echo "FGAT is ${ffgat}"

source /data/cmcc/"$USER"/d4o/install/INTEL/source.me

# Set some env variables
export SCRIPTDIR=$(pwd)
DARTROOT=$(grep "export dartroot=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /; s/USER/$USER/" | awk '{gsub(/[{}]/, "", $3); print $3}')
export DARTROOT=$(echo "$DARTROOT" | sed -e 's/"//g; s/\$//g')
echo " DARTROOT=  $DARTROOT"

CLONESROOT=$(grep "clonesroot=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /; s/USER/$USER/; s/CESMEXP/$CESMEXP/" | awk '{gsub(/[{}]/, "", $3); print $3}')
export CLONESROOT=$(echo "$CLONESROOT" | sed -e 's/"//g; s/\$//g')
echo " CLONESROOT=  $CLONESROOT"

case_name=$(grep "case_name=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /g" | awk '{gsub(/[{}]/, "", $2); print $2}')
export case_name=$(echo "$case_name" | sed -e 's/"//g')
echo " case_name= $case_name"

export NTSLOTS=$(grep "nts=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /" | awk '{print $2}')
echo " NTSLOTS = $NTSLOTS"

CASEROOT0001="$CLONESROOT/${case_name}_0001"
echo " CASEROOT0001= $CASEROOT0001"

cd "$CASEROOT0001" || exit 1
echo " I am inside $(pwd) "

echo " xmlquery start"
export scomp=$(./xmlquery COMP_LND --value)
export CASE=$(./xmlquery CASE --value)
export EXEROOT=$(./xmlquery EXEROOT --value)
export RUNDIR=$(./xmlquery RUNDIR --value)
export archive=$(./xmlquery DOUT_S_ROOT --value)
export TOTALPES=$(./xmlquery TOTALPES --value)

export CONT_RUN=$(./xmlquery CONTINUE_RUN --value)
export CHECK_TIMING=$(./xmlquery CHECK_TIMING --value)
export DATA_ASSIMILATION_CYCLES=$(./xmlquery DATA_ASSIMILATION_CYCLES --value)

export CASEL=${CASE::-5}
export dd4o=/work/cmcc/spreads-lnd/spreads/d4o/flattened/clm

echo " scomp = ${scomp}"
echo " CASE = ${CASE}"
echo " CASEL = ${CASEL}"
echo " EXEROOT = ${EXEROOT}"
echo " RUNDIR = ${RUNDIR}"
echo " archive = ${archive}"
echo " TOTALPES = ${TOTALPES}"

echo " xmlquery end"

export nens=$(grep "nens=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /" | awk '{print $2}')

export TOTALPES=$(echo "$TOTALPES*$nens" | bc)
echo " TOTALPES= $TOTALPES"

TMPROOT=$(grep "tmpdir=" "$SCRIPTDIR/cases_create.sh" | sed -e "s/=/ /; s/USER/$USER/" | awk '{gsub(/[{}]/, "", $2); print $2}')
export TMPROOT=$(echo "$TMPROOT" | sed -e 's/\$//g; s/"//g')
echo " TMPROOT= $TMPROOT"

export CASESRUNROOT=$(echo "$RUNDIR" | sed -e "s/\/${case_name}_0001\/run//g")
echo " CASESRUNROOT= $CASESRUNROOT"

CLONESALL="$CASESRUNROOT/${case_name}_0*/run"
echo " CLONESALL= $CLONESALL"

export MP_DEBUG_NOTIMEOUT=yes

# Check if the CESM evolution finished correctly
cd "$SCRIPTDIR" || exit 1
sh cases_check.sh

chmod 755 "${SCRIPTDIR}/take_f.sh" "${SCRIPTDIR}/run_filter.bash" "${SCRIPTDIR}/run_filter_departures.bash"
chmod 755 "${SCRIPTDIR}/run_filter_all.bash"
chmod 755 "${SCRIPTDIR}/cases_bogus_dep.csh"
chmod 755 "${SCRIPTDIR}/run_filter.bash"
cp "${SCRIPTDIR}/cases_bogus_assim.csh" "${TMPROOT}/."
cp "${SCRIPTDIR}/cases_bogus_dep.csh" "${TMPROOT}/."
cp "${SCRIPTDIR}/cases_bogus_prepy.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_prepy_template.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_post_bs.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/take_f.sh" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_filter.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_filter_departures.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_filter_all.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/rep_inflation.py" "${TMPROOT}/."
cp "${SCRIPTDIR}/rep_input.py" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_clm_to_dart.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_clm_to_dart_par.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_dart_to_clm.bash" "${TMPROOT}/."
cp "${SCRIPTDIR}/run_dart_to_clm_snow.bash" "${TMPROOT}/."

cp -f ${dd4o}/clm_to_dart.dir/clm_to_dart ${TMPROOT}/.
cp -f ${dd4o}/dart_to_clm.dir/dart_to_clm ${TMPROOT}/.
cp -f ${dd4o}/fill_inflation_restart.dir/fill_inflation_restart ${TMPROOT}/.
cp -f ${dd4o}/filter.dir/filter ${TMPROOT}/.

cd "${RUNDIR}" || exit 1
echo "rundir"
pwd

export save_all_in="TRUE"
export save_stages_freq="RESTART_TIMES"
export BASEOBSDIR="/work/cmcc/lg07622/land/datain/d4o/datastore"

export MOVE='/usr/bin/mv -v'
export COPY='/usr/bin/cp -v --preserve=timestamps'
export LINK='/usr/bin/ln -s'
export LIST='/usr/bin/ls '
export REMOVE='/usr/bin/rm -r'

# Most of this syntax can be determined from CASEROOT  ./preview_run
MPI_RUN_COMMAND="mpiexec_mpt -np $TOTALPES omplace -tm open64"

cd ${RUNDIR}

#=========================================================================
# Block 1: Determine time of model state ... from file name of first member
# of the form "./${CASE}.clm2_${ensemble_member}.r.2000-01-06-00000.nc"
#
# Piping stuff through 'bc' strips off any preceeding zeros.
#=========================================================================

export FILE=$(head -n 1 rpointer.lnd)
export LND_DATE_EXT=$(echo "${FILE}" | cut -d "." -f 5)
export LND_DATE=$(echo "${FILE}" | cut -d "." -f 5)
export LND_YEAR=$(echo "${LND_DATE}" | cut -d "-" -f 1)
export LND_MONTH=$(echo "${LND_DATE}" | cut -d "-" -f 2)
export LND_DAY=$(echo "${LND_DATE}" | cut -d "-" -f 3)
export LND_SECONDS=$(echo "${LND_DATE}" | cut -d "-" -f 4)
export LND_HOUR=$(echo "${LND_SECONDS} / 3600" | bc)

echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_SECONDS (seconds)"
echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_HOUR (hours)"

cd ${TMPROOT}

#=========================================================================
# Block 2: Get observation sequence file ... or die right away.
#=========================================================================

# The observation file names have a time that matches the stopping time of CLM.

#if [ "$STOP_N" -ge 24 ]; then
#   OBSDIR=$(printf "%04d%02d" ${LND_YEAR} ${LND_MONTH})
#else
#   OBSDIR=$(printf "%04d%02d_6H" ${LND_YEAR} ${LND_MONTH})
#fi

#OBS_FILE=${baseobsdir}/obs_seq.${LND_DATE_EXT}
#
#${REMOVE} obs_seq.out

#if [ -e "${OBS_FILE}" ]; then
#   ${LINK} ${OBS_FILE} obs_seq.out || exit 2
#else
#   echo "ERROR ... no observation file $OBS_FILE"
#   echo "ERROR ... no observation file $OBS_FILE"
#   #LGG exit 2
#fi

${REMOVE} ${TMPROOT}/*.db

dens=$(printf "%02d" ${nens})
dpart=$(printf "%04d-%02d-%02d" ${LND_YEAR} ${LND_MONTH} ${LND_DAY})
ddir="/work/cmcc/lg07622/land/datain/d4o/datastore/ens_${dens}/${dpart}"

echo ${ddir}
ls ${ddir}/*.db

${COPY} ${ddir}/*.db .

#=========================================================================
# Block 3: Populate a run-time directory with the input needed to run DART.
#=========================================================================

echo "$(date) -- BEGIN COPY BLOCK"

#if [ -e "${CASEROOT}/input.nml" ]; then
#   ${COPY} ${CASEROOT}/input.nml .
#else
#   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
#   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
#   exit 3
#fi

echo "$(date) -- END COPY BLOCK"

# If possible, use the round-robin approach to deal out the tasks.

if [ -n "$TASKS_PER_NODE" ]; then
   if [ ${#TASKS_PER_NODE} -gt 0 ]; then
      ${COPY} input.nml input.nml.$$
      sed -e "s#layout.*#layout = 2#" \
          -e "s#tasks_per_node.*#tasks_per_node = $TASKS_PER_NODE#" input.nml.$$ > input.nml
      ${REMOVE} input.nml.$$
   fi
fi

#=========================================================================
# Block 4: DART INFLATION
# IF we are doing inflation, we must take the output inflation files from
# the previous cycle and rename them for input to the current cycle.
# The inflation values change through time and should be archived.
#
# If we need to run fill_inflation_restart,
# we need the links to the input files. So this has to come pretty early.
#
# Every variable in the DART vector needs an inflation value if we
# run with any of the temporally- or spatially-adaptive inflation schemes.
# This means that the variables marked 'NO_COPY_BACK' must still have
# inflation values. This is achieved by running fill_inflation_restart
# and copying those input inflation files into the output files, which
# filter will update. By continually copying the input inflation files
# to the output inflation files before filter runs, every variable in the
# DART vector will have an inflation value.
#=========================================================================

LND_RESTART_FILENAME=${RUNDIR}/${CASE}.clm2.r.${LND_DATE_EXT}.nc
LND_HISTORY_FILENAME=${RUNDIR}/${CASE}.clm2.h0.${LND_DATE_EXT}.nc
LND_VEC_HISTORY_FILENAME=${RUNDIR}/${CASE}.clm2.h2.${LND_DATE_EXT}.nc

# remove any potentially pre-existing links
unlink clm_restart.nc
unlink clm_history.nc
unlink clm_vector_history.nc

${LINK} ${LND_RESTART_FILENAME} clm_restart.nc || exit 4
${LINK} ${LND_HISTORY_FILENAME} clm_history.nc || exit 4
if [ -s "${LND_VEC_HISTORY_FILENAME}" ]; then
   ${LINK} ${LND_VEC_HISTORY_FILENAME} clm_vector_history.nc || exit 4
fi

# fill_inflation_restart creates files for all the domains in play,
# with names like input_priorinf_[mean,sd]_d0?.nc These should be renamed
# to be similar to what is created during the cycling. fill_inflation_restart
# only takes a second and only runs once.
if [ "$CONT_RUN" == "FALSE" ]; then touch clm_inflation_cookie; fi
if [ -e clm_inflation_cookie ]; then

echo "Running fill_inflation_restart"
   #./run_inflation.bash
   ./fill_inflation_restart
echo "End running fill_inflation_restart"

   for FILE in input_priorinf_*.nc; do
      NEWBASE=$(echo $FILE | sed -e "s#input#output#")
      ${MOVE} ${FILE} clm_${NEWBASE}.1601-01-01-00000.nc
   done

   # Make sure this only happens once. Eat the cookie.
   ${REMOVE} clm_inflation_cookie

   # To help keep track of the most recent inflation file,
   # create a 'pointer file' to hold the name of the most recent.

   domaincount=0
   for FILE in clm_output_priorinf_mean*.nc; do

      domaincount=$((domaincount + 1))

      POINTERFILE=$(printf "priorinf_pointer_d%02d.txt" $domaincount)

      SDFILE=$(echo $FILE | sed -e "s#mean#sd#")

      echo $FILE > $POINTERFILE
      echo $SDFILE >> $POINTERFILE

   done

   # Not supporting posterior inflation at this time.
   ${REMOVE} input_postinf*nc

fi

# We have to potentially deal with files like:
# clm_output_priorinf_mean_d01.${LND_DATE_EXT}.nc
# clm_output_priorinf_mean_d02.${LND_DATE_EXT}.nc
# clm_output_priorinf_mean_d03.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d01.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d02.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d03.${LND_DATE_EXT}.nc


# Check to see if inflation is being used.

MYSTRING=$(grep inf_flavor input.nml)
MYSTRING=$(echo $MYSTRING | sed -e "s#[=,'\.]# #g")
PRIOR_INF=$(echo $MYSTRING | awk '{print $2}')
POSTE_INF=$(echo $MYSTRING | awk '{print $3}')

echo $MYSTRING" "$PRIOR_INF" "$POSTE_INF


if [ "$PRIOR_INF" != 0 ]; then

   # CLM always has at least two domains, but may sometimes have three.
   # Link to the new expected name, if the file does not exist, filter will
   # die and issue a very explicit death message.

   ${REMOVE} input_priorinf_mean*.nc input_priorinf_sd*.nc

   domaincount=1

   for POINTERFILE in priorinf_pointer*.txt; do

      DOMAIN=$(printf "_d%02d" $domaincount)
      INPUT=input_priorinf_mean_${DOMAIN}
      OUTPUT=output_priorinf_mean_${DOMAIN}

      latest_mean=$(head -n 1 $POINTERFILE)
      latest_sd=$(tail -n 1 $POINTERFILE)

      # Create the expected output inflation file.
      # The NO_COPY_BACK variables that are part of the DART vector
      # need to have inflation values. 
      ${COPY} ${latest_mean} output_priorinf_mean${DOMAIN}.nc
      ${COPY} ${latest_sd} output_priorinf_sd${DOMAIN}.nc

      ${LINK} ${latest_mean} input_priorinf_mean${DOMAIN}.nc
      ${LINK} ${latest_sd} input_priorinf_sd${DOMAIN}.nc

      domaincount=$((domaincount + 1))

   done

fi

if [ "$POSTE_INF" != 0 ]; then
   echo "ERROR: assimilate.sh not configured to cycle with posterior inflation."
   exit 4
fi


#=========================================================================
# Block 5: REQUIRED DART namelist settings
#
# "restart_files.txt" is mandatory.
# "history_files.txt" and "history_vector_files.txt" are only needed if
# variables from these files are specified as part of the desired DART state.
# It is an error to specify them if they are not required.
#
# model_nml "clm_restart_filename" and "clm_history_filename" are mandatory
# and are used to determine the domain metadata and *shape* of the variables.
# "clm_vector_history_filename" is used to determine the shape of the
# variables required to be read from the vector history file. If there are no
# vector-based history variables, 'clm_vector_history_filename' is not used.
#
# &filter_nml
#     async                   = 0,
#     obs_sequence_in_name    = 'obs_seq.out'
#     obs_sequence_out_name   = 'obs_seq.final'
#     init_time_days          = -1,
#     init_time_seconds       = -1,
#     first_obs_days          = -1,
#     first_obs_seconds       = -1,
#     last_obs_days           = -1,
#     last_obs_seconds        = -1,
#     input_state_file_list   = "restart_files.txt",
#                               "history_files.txt",
#                               "vector_files.txt"
#     output_state_file_list  = "restart_files.txt",
#                               "history_files.txt",
#                               "vector_files.txt"
# &model_nml
#     clm_restart_filename        = 'clm_restart.nc'
#     clm_history_filename        = 'clm_history.nc'
#     clm_vector_history_filename = 'clm_vector_history.nc'
# &ensemble_manager_nml
#     single_restart_file_in  = .false.
#     single_restart_file_out = .false.
#=========================================================================
# clm always needs a clm_restart.nc, clm_history.nc for geometry information, etc.
# it may or may not need a vector-format history file - depends on user input

${REMOVE} restart_files.txt history_files.txt vector_files.txt
touch restart_files.txt history_files.txt vector_files.txt

#for ii in $(seq 1 ${nens}); do
#  ni=$(printf "%04d" ${ii})
#  FILE=$CASESRUNROOT/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.r.${LND_DATE_EXT}.nc
#  OUTPUT=clm2_${ni}.r.${LND_DATE_EXT}.nc
#  ${COPY} $FILE clm.nc
#  ./run_clm_to_dart.bash
#  ${MOVE} clm.nc $OUTPUT
#
#  ls ${OUTPUT}  >> restart_files.txt
#  ls $CASESRUNROOT/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.h0.${LND_DATE_EXT}.nc >> history_files.txt
#  ls $CASESRUNROOT/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.h2.${LND_DATE_EXT}.nc >> vector_files.txt
#
#done

./run_clm_to_dart_par.bash ${CASEL} ${case_name} ${LND_DATE_EXT} ${CASESRUNROOT} ${nens} ${TMPROOT}

#for FILE in ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc; do
#for FILE in ${RESTARTALL}; do

   # create unique output filename for the copy that has the indeterminate
   # values replaced by the _FillValue. The copies are the files that will
   # be used to construct the DART vector.
#   OUTPUT=$(echo $FILE | sed -e "s/${CASE}.//")
#   OUTPUT=$(echo $FILE | sed -e "s/${CASE}.//")
   
#   echo $FILE
#   echo $OUTPUT

   #${COPY} $FILE clm.nc
   #./run_clm_to_dart.bash
   #${MOVE} clm.nc $OUTPUT

#done

#ls -1 clm2_*.r.${LND_DATE_EXT}.nc  > restart_files.txt
#ls -1 ${CASE}.clm2_*.h0.${LND_DATE_EXT}.nc > history_files.txt
#ls -1 ${CASE}.clm2_*.h2.${LND_DATE_EXT}.nc > vector_files.txt

#=========================================================================
# Block 6: Actually run the assimilation.
#=========================================================================

echo "$(date) -- BEGIN FILTER"
bsub < run_filter.bash
echo "$(date) -- END FILTER"

#=========================================================================
# Block 7: Put the DART posterior into the CLM restart file. The CLM
# restart file is also the prior for the next forecast.
#=========================================================================
# Unlink any potentially pre-existing links
unlink clm_restart.nc
unlink dart_posterior.nc

# Identify if SWE re-partitioning is necessary
REPARTITION=$(grep repartition_swe input.nml | sed -e "s/repartition_swe//g" | sed -e "s/=//g")


if [ "$REPARTITION" != 0 ]; then
   unlink clm_vector_history

   #./run_dart_to_clm_snow.bash ${CASE} ${LND_DATE_EXT}
   echo "./run_dart_to_clm_snow.bash ${CASEL} ${case_name} ${LND_DATE_EXT} ${CASESRUNROOT} ${nens}"
   ./run_dart_to_clm_snow.bash ${CASEL} ${case_name} ${LND_DATE_EXT} ${CASESRUNROOT} ${nens}

   if [ $? -ne 0 ]; then
      echo "ERROR: dart_to_clm failed for ..."
      exit 7
   fi

   for LIST in clm_restart.nc clm_vector_history.nc dart_posterior.nc dart_posterior_vector.nc; do
      unlink $LIST
   done

else

for ii in $(seq 1 ${nens}); do
  ni=$(printf "%04d" ${ii})
  RESTART=$CASESRUNROOT/${case_name}_${ni}/run/${CASEL}_${ni}.clm2.r.${LND_DATE_EXT}.nc
  POSTERIOR=clm2_${ni}.r.${LND_DATE_EXT}.nc
   ${LINK} $POSTERIOR dart_posterior.nc
   ${LINK} $RESTART clm_restart.nc

   ./run_dart_to_clm.bash
   if [ $? -ne 0 ]; then
      echo "ERROR: dart_to_clm failed for $RESTART"
      exit 8
   fi

   unlink dart_posterior.nc
   unlink clm_restart.nc

done


#for RESTART in ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc; do
#
#   POSTERIOR=$(echo $RESTART | sed -e "s/${CASE}.//")
#
#   ${LINK} $POSTERIOR dart_posterior.nc
#   ${LINK} $RESTART clm_restart.nc
#
#   ./run_dart_to_clm.bash
#   if [ $? -ne 0 ]; then
#      echo "ERROR: dart_to_clm failed for $RESTART"
#      exit 8
#   fi
#
#   unlink dart_posterior.nc
#   unlink clm_restart.nc
#done

fi

# Remove the copies that we no longer need. The posterior values are
# in the DART diagnostic files for the appropriate 'stage'.
rm -f clm2_*.r.${LND_DATE_EXT}.nc
rm -f clm2_*.h0.${LND_DATE_EXT}.nc
rm -f clm2_*.h2.${LND_DATE_EXT}.nc

#=========================================================================
# Block 8: Archive the results and prepare pointer inflation files for
# next cycle. Tag the output with the valid time of the model state.
#=========================================================================

# TODO could move each ensemble-member file to the respective member dir.

for FILE in input*mean*nc input*sd*nc input_member*nc forecast*mean*nc forecast*sd*nc forecast_member*nc preassim*mean*nc preassim*sd*nc preassim_member*nc postassim*mean*nc postassim*sd*nc postassim_member*nc analysis*mean*nc analysis*sd*nc analysis_member*nc output*mean*nc output*sd*nc; do

   if [ -e "$FILE" ]; then
      FEXT=${FILE##*.}
      FBASE=${FILE%.*}
      ${MOVE} $FILE clm_${FBASE}.${LND_DATE_EXT}.${FEXT}
   fi
done

# Tag the DART observation file with the valid time of the model state.

${MOVE} obs_seq.final clm_obs_seq.${LND_DATE_EXT}.final
${MOVE} dart_log.out clm_dart_log.${LND_DATE_EXT}.out

echo "Updating inflation pointer files."

domaincount=0
for FILE in clm_output_priorinf_mean*.${LND_DATE_EXT}.nc; do
   domaincount=$((domaincount + 1))
   POINTERFILE=$(printf "priorinf_pointer_d%02d.txt" $domaincount)
   SDFILE=$(echo $FILE | sed -e "s#mean#sd#")
   echo $FILE > $POINTERFILE
   echo $SDFILE >> $POINTERFILE
done

#-------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------

if grep -q "2" "${TMPROOT}/filter.flag"; then # CLOSE THE IF AT THE END
    echo "land assimilation ended successfully, move databases into archive, set check_assi.flag to 1"


   ${MOVE} ${TMPROOT}/*.db ${TMPROOT}/tmp/.

    cd "$SCRIPTDIR"
    cat check_assi.flag
    sed -i 's/0/1/g' check_assi.flag
    echo " wrote 1 in check_assi.flag"
    cat check_assi.flag

    # Ensure the removal of unneeded restart sets and copy of obs_seq.final are finished.
    wait


   echo "$(date) -- END CLM_ASSIMILATE"
fi

exit 0
