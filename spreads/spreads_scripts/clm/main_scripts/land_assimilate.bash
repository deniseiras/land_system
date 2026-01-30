#!/bin/bash
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is," without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# This script performs an assimilation by directly reading and writing to
# the CLM restart file.
#
# NOTE: 'dart_to_clm' does not currently support updating the
# prognostic snow variables based on posterior SWE values.
# Consequently, snow DA is not currently supported.
# Implementing snow DA is high on our list of priorities.

# ==============================================================================
# Block 0: Set command environment
# ==============================================================================
echo "`date` -- BEGIN CLM_ASSIMILATE"
shopt -s nullglob # suppress "rm" warnings if wildcard does not match anything

ffgat=$1
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
export scomp=$(./xmlquery COMP_ATM --value)
export CASE=$(./xmlquery CASE --value)
export EXEROOT=$(./xmlquery EXEROOT --value)
export RUNDIR=$(./xmlquery RUNDIR --value)
export archive=$(./xmlquery DOUT_S_ROOT --value)
export TOTALPES=$(./xmlquery TOTALPES --value)

export CONT_RUN=$(./xmlquery CONTINUE_RUN --value)
export CHECK_TIMING=$(./xmlquery CHECK_TIMING --value)
export DATA_ASSIMILATION_CYCLES=$(./xmlquery DATA_ASSIMILATION_CYCLES --value)

export CASEL=${CASE::-5}
export dd4o=/work/cmcc/lg07622/LDAS/spreads/d4o/flattened/clm

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

# ==============================================================================
# Block 1: Determine time of current model state from file name of member 1
# ==============================================================================
export FILE=$(head -n 1 rpointer.lnd)
export ATM_DATE_EXT=$(echo "${FILE}" | cut -d "." -f 5)
export ATM_DATE=$(echo "${FILE}" | cut -d "." -f 5)
export ATM_YEAR=$(echo "${ATM_DATE}" | cut -d "-" -f 1)
export ATM_MONTH=$(echo "${ATM_DATE}" | cut -d "-" -f 2)
export ATM_DAY=$(echo "${ATM_DATE}" | cut -d "-" -f 3)
export ATM_SECONDS=$(echo "${ATM_DATE}" | cut -d "-" -f 4)
export ATM_HOUR=$(echo "${ATM_SECONDS} / 3600" | bc)

echo " FILE = ${FILE}"
echo " ATM_DATE_EXT = ${ATM_DATE_EXT}"
echo " ATM_DATE = ${ATM_DATE}"
echo " ATM_YEAR = ${ATM_YEAR}"
echo " ATM_MONTH = ${ATM_MONTH}"
echo " ATM_DAY = ${ATM_DAY}"
echo " ATM_SECONDS = ${ATM_SECONDS}"
echo " ATM_HOUR = ${ATM_HOUR}"

# Remove leading zeros from month/day if necessary
if [ ${ATM_DAY} == "08" ]; then ATM_DAY="8"; fi
if [ ${ATM_MONTH} == "08" ]; then ATM_MONTH="8"; fi
if [ ${ATM_DAY} == "09" ]; then ATM_DAY="9"; fi
if [ ${ATM_MONTH} == "09" ]; then ATM_MONTH="9"; fi

# ==============================================================================
# Block 2: Populate a run-time directory with the input needed to run DART
# ==============================================================================
echo "`date` -- BEGIN COPY BLOCK"
cd ${TMPROOT}
if [ -e input.nml.original ]; then
   sed -e "/#/d;/^\!/d;/^[ ]*\!/d" input.nml.original > input.nml || exit 10
else
   echo "ERROR ... DART required file ${TMPROOT}/input.nml not found ... ERROR"
   exit 11
fi
echo "`date` -- END COPY BLOCK"

# ==============================================================================
# Block 3: LND RESTART and HISTORY FILENAME LOGIC (restore)
# ==============================================================================

LND_RESTART_FILENAME=${CASE}.clm2_0001.r.${LND_DATE_EXT}.nc
LND_HISTORY_FILENAME=${CASE}.clm2_0001.h0.${LND_DATE_EXT}.nc
LND_VEC_HISTORY_FILENAME=${CASE}.clm2_0001.h2.${LND_DATE_EXT}.nc

# remove any pre-existing links
unlink clm_restart.nc
unlink clm_history.nc
unlink clm_vector_history.nc

ln -s "${LND_RESTART_FILENAME}" clm_restart.nc || exit 4
ln -s "${LND_HISTORY_FILENAME}" clm_history.nc || exit 4
if [ -s "${LND_VEC_HISTORY_FILENAME}" ]; then
   ln -s "${LND_VEC_HISTORY_FILENAME}" clm_vector_history.nc || exit 4
fi

# ==============================================================================
# Block 4: DART INFLATION
# ==============================================================================
echo "Checking for inflation files in .HIDE_${case_name}..."

# If inflation files are stored in the .HIDE directory, move them to the working directory
if [ -d .HIDE_${case_name} ] && [ "$(ls -A .HIDE_${case_name})" ]; then
    echo "Found previous inflation files in .HIDE_${case_name}, moving them..."
    mv -v .HIDE_${case_name}/* .
    # Retrieve the latest inflation date for reference
    export inf_prev_date_files=$(ls -rt1 clm_preassim*inf_mean* | tail -1)
    export inf_prev_date_files=$(echo "$inf_prev_date_files" | cut -d'.' -f2)
    echo "Old inflation date in hide = $inf_prev_date_files"
else
    echo "No previous inflation files found in .HIDE_${case_name}, proceeding with new inflation."
fi

# Inflation process (runs only once per cycle)
echo "Running fill_inflation_restart"
./run_inflation.bash
echo "End running fill_inflation_restart"

# Rename and store the inflation files in .HIDE_${case_name} for the next cycle
for FILE in input_priorinf_*.nc; do
    NEWBASE=$(echo $FILE | sed -e "s#input#output#")
    mv -v "$FILE" clm_${NEWBASE}.1601-01-01-00000.nc
done

# Move the inflation files back to the .HIDE directory for the next cycle
mkdir -p .HIDE_${case_name}
mv -v clm_output_priorinf_mean*.nc .HIDE_${case_name}/
mv -v clm_output_priorinf_sd*.nc .HIDE_${case_name}/

echo "Inflation files moved to .HIDE_${case_name} for the next cycle."

# Prepare inflation pointers
echo "Updating inflation pointer files."
domaincount=0
for FILE in clm_output_priorinf_mean*.nc; do
    domaincount=$((domaincount + 1))
    POINTERFILE=$(printf "priorinf_pointer_d%02d.txt" $domaincount)
    SDFILE=$(echo $FILE | sed -e "s#mean#sd#")
    echo "$FILE" > "$POINTERFILE"
    echo "$SDFILE" >> "$POINTERFILE"
done

# ==============================================================================
# Block 5: REQUIRED DART namelist settings
# ==============================================================================
rm -f restart_files.txt history_files.txt vector_files.txt

for FILE in ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc; do
   OUTPUT=$(echo $FILE | sed -e "s/${CASE}.//")
   cp -v $FILE clm.nc
   ./run_clm_to_dart.bash
   mv -v clm.nc $OUTPUT
done

ls -1 clm2_*.r.${LND_DATE_EXT}.nc > restart_files.txt
ls -1 ${CASE}.clm2_*.h0.${LND_DATE_EXT}.nc > history_files.txt
ls -1 ${CASE}.clm2_*.h2.${LND_DATE_EXT}.nc > vector_files.txt

# ==============================================================================
# Block 6: Actually run the assimilation
# ==============================================================================
echo "`date` -- BEGIN FILTER"
bsub < run_filter.bash
echo "`date` -- END FILTER"

# ==============================================================================
# Block 7: Put the DART posterior into the CLM restart file. The CLM restart
# file is also the prior for the next forecast.
# ==============================================================================
unlink clm_restart.nc
unlink dart_posterior.nc

REPARTITION=$(grep repartition_swe input.nml | sed -e "s/repartition_swe//g" | sed -e "s/=//g")

if [ "$REPARTITION" -ne 0 ]; then
   unlink clm_vector_history
   enscount=1

   for RESTART in ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc; do
      POSTERIOR_RESTART=$(echo $RESTART | sed -e "s/${CASE}.//")
      POSTERIOR_VECTOR=$(printf "analysis_member_00%02d_d03.nc" $enscount)
      CLM_VECTOR=$(printf "${CASE}.clm2_00%02d.h2.${LND_DATE_EXT}.nc" $enscount)

      if [ ! -e "$POSTERIOR_VECTOR" ] || [ ! -e "$CLM_VECTOR" ]; then
         echo "ERROR: Could not find $POSTERIOR_VECTOR or $CLM_VECTOR"
         exit 7
      fi

      cp input.nml tmp/$NDIR/.
      cp run_dart_to_clmB.bash tmp/$NDIR/.
      cd tmp/$NDIR || exit 1
      ln -s ../../$POSTERIOR_RESTART dart_posterior.nc
      ln -s ../../$POSTERIOR_VECTOR dart_posterior_vector.nc
      ln -s ../../$RESTART clm_restart.nc
      ln -s ../../$CLM_VECTOR clm_vector_history.nc

      ./run_dart_to_clm.bash
      if [ $? -ne 0 ]; then
         echo "ERROR: dart_to_clm failed for $RESTART"
         exit 7
      fi

      unlink clm_restart.nc
      unlink clm_vector_history.nc
      unlink dart_posterior.nc
      unlink dart_posterior_vector.nc

      enscount=$((enscount + 1))
   done
else
   for RESTART in ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc; do
      POSTERIOR=$(echo $RESTART | sed -e "s/${CASE}.//")
      ln -s $POSTERIOR dart_posterior.nc
      ln -s $RESTART clm_restart.nc

      ./run_dart_to_clm.bash
      if [ $? -ne 0 ]; then
         echo "ERROR: dart_to_clm failed for $RESTART"
         exit 8
      fi

      unlink dart_posterior.nc
      unlink clm_restart.nc
   done
fi

rm -f clm2_*.r.${LND_DATE_EXT}.nc
rm -f clm2_*.h0.${LND_DATE_EXT}.nc
rm -f clm2_*.h2.${LND_DATE_EXT}.nc

# ==============================================================================
# Block 8: Archive the results and prepare pointer inflation files for next cycle
# Tag the output with the valid time of the model state.
# ==============================================================================
for FILE in input*mean*nc input*sd*nc input_member*nc \
            forecast*mean*nc forecast*sd*nc forecast_member*nc \
            preassim*mean*nc preassim*sd*nc preassim_member*nc \
            postassim*mean*nc postassim*sd*nc postassim_member*nc \
            analysis*mean*nc analysis*sd*nc analysis_member*nc \
            output*mean*nc output*sd*nc; do
   if [ -e "$FILE" ]; then
      FEXT=${FILE##*.}
      FBASE=${FILE%.*}
      mv -v $FILE clm_${FBASE}.${LND_DATE_EXT}.${FEXT}
   fi
done

mv -v obs_seq.final clm_obs_seq.${LND_DATE_EXT}.final
mv -v dart_log.out clm_dart_log.${LND_DATE_EXT}.out

echo "Updating inflation pointer files."

domaincount=0
for FILE in clm_output_priorinf_mean*.${LND_DATE_EXT}.nc; do
   domaincount=$((domaincount + 1))
   POINTERFILE=$(printf "priorinf_pointer_d%02d.txt" $domaincount)
   SDFILE=$(echo $FILE | sed -e "s#mean#sd#")
   echo $FILE > $POINTERFILE
   echo $SDFILE >> $POINTERFILE
done

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
mv -v ${RUNDIR}/*.db ${RUNDIR}/tmp/.

echo "`date` -- END CLM_ASSIMILATE"

exit 0
