#!/bin/bash
set -x

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

cd "$CASEROOT0001"
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
cd "$SCRIPTDIR"
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

cd "${RUNDIR}"
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

# Move previous inflation restart if necessary
cd ${TMPROOT}
export INFVAL=$(grep inf_flavor input.nml)
export INFVAL=$(echo $INFVAL | cut -d '=' -f 2 | cut -d ',' -f 1)
echo "INFVAL = $INFVAL"

if [ $INFVAL -eq 0 ]; then
  echo  " No inflation used."
else
  echo  " Inflation used. Restage previous inflation files."
  if [ -d .HIDE_${case_name} ]; then
    echo " Found HIDE dir ..."
    export c=$(ls -a .HIDE_${case_name} | wc | awk '{print $1}')
    if [ "${c}" -eq 2 ]; then
       echo " Empty directory, no old inflation files found."
    else
       ${MOVE} .HIDE_${case_name}/* .
       export inf_prev_date_files=$(ls -rt1 clm_preassim*inf_mean* | tail -1)
       export inf_prev_date_files=$(echo $inf_prev_date_files | cut -d'.' -f2)
       echo " Old inflation date in hide = $inf_prev_date_files "
    fi
  else
    echo " No HIDE dir found."
  fi
fi

# ==============================================================================
# Block 2: Populate run-time directory with the input needed to run DART
# ==============================================================================
echo "`date` -- BEGIN COPY BLOCK"
cd ${TMPROOT}
if [  -e   input.nml.original ]; then
   sed -e "/#/d;/^\!/d;/^[ ]*\!/d" input.nml.original > input.nml  || exit 10
else
   echo "ERROR ... DART required file ${TMPROOT}/input.nml not found ... ERROR"
   exit 11
fi
echo "`date` -- END COPY BLOCK"

# ==============================================================================
# Block 3: Identify requested output stages
# ==============================================================================
cd ${TMPROOT}
export MYSTRING=$(grep stages_to_write input.nml | tail -1)
export MYSTRING=$(echo $MYSTRING | sed -e "s#[=,'\.]# #g" | sed 's/stages_to_write//g')

export STAGE_input=FALSE
export STAGE_forecast=FALSE
export STAGE_preassim=TRUE
export STAGE_postassim=FALSE
export STAGE_analysis=TRUE
export STAGE_output=TRUE

export stages_except_output="{"
stage=3
for var in ${MYSTRING}; do
   if [ $var == 'input' ]; then
      export STAGE_input=TRUE
      if [ $stage -gt 2 ]; then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}input"
   fi
   if [ $var == 'forecast' ]; then
      export STAGE_forecast=TRUE
      if [ $stage -gt 2 ]; then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}forecast"
   fi
   if [ $var == 'preassim' ]; then
      export STAGE_preassim=TRUE
      if [ $stage -lt 2 ]; then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}preassim"
   fi
   if [ $var == 'postassim' ]; then
      export STAGE_postassim=TRUE
      if [ $stage -lt 2 ]; then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}postassim"
   fi
   if [ $var == 'analysis' ]; then
      export STAGE_analysis=TRUE
      if [ $stage -gt 2 ]; then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}analysis"
   fi
   stage=$(echo "${stage}+1" | bc)
done

# Add the closing }
export stages_all="${stages_all}}"
export stages_except_output="${stages_except_output}}"

# Checking
echo "stages_except_output = $stages_except_output"
echo "stages_all = $stages_all"
if [ $STAGE_output != TRUE ]; then
   echo "ERROR: stages_to_write must include 'output'"
   exit 40
fi

# ==============================================================================
# Block 5: Get observation sequence file ... or die right away
# ==============================================================================
export its=1
while [ $its -le $NTSLOTS ]; do
   cd "${TMPROOT}"
   export DIROBS=$(printf "%04d-%02d-%02d" "$ATM_YEAR" "$ATM_MONTH" "$ATM_DAY")
   export OBS_FILE="${BASEOBSDIR}/ens_${DENS}/${DIROBS}"
   cp ${OBS_FILE}/*.db ${TMPROOT}/
   its=$((its+1))
done

# ==============================================================================
# Block 6: Run DART Inflation (skipping inflation stages if not needed)
# ==============================================================================
echo "`date` -- BEGIN PREPROCESSING"
cd ${TMPROOT}

if [ "${ffgat}" == "FALSE" ]; then
    echo "ONE SHOT ASSIMILATION"

    # Link new backgrounds
    rm -f restart_files.txt history_files.txt vector_files.txt

    inst=1
    while [ "$inst" -le "$nens" ]; do
        inst_string=$(printf "_%04d" "$inst")
        dates=${ATM_DATE_EXT}
        ftoass="$CASESRUNROOT/${case_name}${inst_string}/run/${case_name}${inst_string}.clm2.r.${dates}.nc"
        OUTPUT=${TMPROOT}/${case_name}${inst_string}.clm2.r.${dates}.nc
        
        #OUTPUT=$(echo "$ftoass" | sed -e "s/${case_name}${inst_string}.//")

        ${COPY} "$ftoass" clm.nc
        ./run_clm_to_dart.bash
        ${MOVE} clm.nc "$OUTPUT"

        echo "Member ${inst}: insert ${ftoass} in ${input_file_list_name}"
        echo "${ftoass}" >> "${TMPROOT}/${input_file_list_name}"

        ls -1 $OUTPUT >> restart_files.txt
        ls -1 "$CASESRUNROOT/${case_name}${inst_string}/run/${case_name}${inst_string}.clm2.h0.${ATM_DATE_EXT}.nc" >> history_files.txt
        ls -1 "$CASESRUNROOT/${case_name}${inst_string}/run/${case_name}${inst_string}.clm2.h2.${ATM_DATE_EXT}.nc" >> vector_files.txt

        inst=$(echo "${inst}+1" | bc)
    done

    # Run the assimilation in one shot
    echo 'CALLING take_f.sh'
    bsub < "${TMPROOT}/run_filter.bash"
    echo 'END take_f.sh'

    # ==============================================================================
    # Block 7: Rename Output Files
    # ==============================================================================
    echo "`date` -- BEGIN FILE RENAMING"

    for FILE in forecast_member_????.nc; do
        OUTPUT=$(echo "$FILE" | sed -e "s/forecast/output/")
        ${MOVE} $FILE $OUTPUT
    done

    # ==============================================================================
    # Block 8: Archive Output
    # ==============================================================================
    echo "`date` -- START ARCHIVING"
    adir="${archive}/${case_name}/${case_name}-${ATM_DATE_EXT}"
    mkdir -p "$adir"
    ${MOVE} ./allTS/*.{e,i}*"${ATM_DATE_EXT}"*  "$adir"
    ${MOVE} ./allTS/*"${ATM_DATE_EXT}".db  "$adir"
    ${MOVE} ./allTS/dart_log.*.out  "$adir"
    ${MOVE} ./allTS/dart_log.nml.*  "$adir"

    # Archive restart files if needed
    inst=1
    while [ "$inst" -le "$nens" ]; do
        inst_string=$(printf "_%04d" "$inst")
        cd "$CASESRUNROOT/${case_name}${inst_string}/run"
        if [ "${ATM_DAY}-${ATM_SECONDS}" == "01-00000" ]; then
            ${COPY} *.{h0,r,rs,rs1}*"${ATM_DATE_EXT}"* "${adir}/"
            ${COPY} rpointer* "${adir}"
        fi
        inst=$(echo "${inst}+1" | bc)
    done

    echo "`date` -- END ARCHIVING"
fi

echo "`date` -- END CLM_ASSIMILATE"
exit 0
