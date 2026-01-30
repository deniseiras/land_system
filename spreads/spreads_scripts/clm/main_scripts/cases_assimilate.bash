#!/bin/bash

# ==============================================================================
# Block 0: Set command environment
# ==============================================================================
# This block is an attempt to localize all the machine-specific
# changes to this script such that the same script can be used
# on multiple platforms. This will help us maintain the script.

echo "`date` -- BEGIN CAM_ASSIMILATE"

shopt -s nullglob # suppress "rm" warnings if wildcard does not match anything

# Read the option
ffgat=$1
echo "FGAT is ${ffgat}"




source /data/cmcc/"$USER"/d4o/install/INTEL/source.me




# Set some env variables
export SCRIPTDIR=$(pwd)
echo " SCRIPTDIR= $SCRIPTDIR"

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
export CAM_DYCORE=$(./xmlquery CAM_DYCORE --value)
export EXEROOT=$(./xmlquery EXEROOT --value)
export RUNDIR=$(./xmlquery RUNDIR --value)
export archive=$(./xmlquery DOUT_S_ROOT --value)
export TOTALPES=$(./xmlquery TOTALPES --value)

export CONT_RUN=$(./xmlquery CONTINUE_RUN --value)
# when you make a long forecast run without assimilation and then you want to assimilate obs but you do not have
# inflation files then force one cycle CONT_RUN FALSE
#CONT_RUN=FALSE

export CHECK_TIMING=$(./xmlquery CHECK_TIMING --value)
export DATA_ASSIMILATION_CYCLES=$(./xmlquery DATA_ASSIMILATION_CYCLES --value)

echo " scomp = ${scomp}"
echo " CASE = ${CASE}"
echo " CAM_DYCORE = ${CAM_DYCORE}"
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
sh cases_check.sh # now also in merge

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
cd "${RUNDIR}"
echo "rundir"
pwd


# A switch to save all the inflation files
export save_all_in="TRUE"


# If they exist, mean and sd will always be saved.
# A switch to signal how often to save the stages' ensemble members.
#     valid values are:  NONE, RESTART_TIMES, ALL
export save_stages_freq="RESTART_TIMES"

# This next line ultimately specifies the location of the observation files.
export BASEOBSDIR="/work/cmcc/lg07622/land/datain/observations/ESA_CCI_SM/obs/all"


# Make sure that this script is using standard system commands
# instead of aliases defined by the user.
# If the standard commands are not in the location listed below,
# change the variable assignments to point to their correct paths.
# The VERBOSE options are useful for debugging, but are optional because
# some systems don't like the -v option to any of the following.

export MOVE='/usr/bin/mv -v'
export COPY='/usr/bin/cp -v --preserve=timestamps'
export LINK='/usr/bin/ln -s'
export LIST='/usr/bin/ls '
export REMOVE='/usr/bin/rm -r'



# ==============================================================================
# Block 1: Determine time of current model state from file name of member 1
# These are of the form "${CASE}.cam_${ensemble_member}.i.2000-01-06-00000.nc"
# ==============================================================================

# Piping stuff through 'bc' strips off any preceding zeros.

export FILE=$(head -n 1 rpointer.atm)
export ATM_DATE_EXT=$(echo "${FILE}" | cut -d "." -f 4)
export ATM_DATE=$(echo "${FILE}" | cut -d "." -f 4)
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

echo " valid time of model is $ATM_YEAR $ATM_MONTH $ATM_DAY $ATM_SECONDS (seconds)"
echo " valid time of model is $ATM_YEAR $ATM_MONTH $ATM_DAY $ATM_HOUR (hours)"

if [ ${ATM_DAY} == "08" ];then
   ATM_DAY="8"
fi

if [ ${ATM_MONTH} == "08" ];then
   ATM_MONTH="8"
fi

if [ ${ATM_DAY} == "09" ];then
   ATM_DAY="9"
fi

if [ ${ATM_MONTH} == "09" ];then
   ATM_MONTH="9"
fi

# Move the previous inflation restart in the TMPDIR (both mean and sd)
cd ${TMPROOT}
export  INFVAL=$(grep inf_flavor input.nml)
export  INFVAL=$(echo $INFVAL | cut -d '=' -f 2 | cut -d ',' -f 1)
echo "INFVAL = $INFVAL"

if [ $INFVAL -eq 0 ]; then
  echo  " No inflation used. Inflations files not restaged from previous run if any exist."
else
  echo  " Inflation used. Restage  previous inflation files if any exist."
  if [ -d .HIDE_${case_name} ]; then
    echo " Found HIDE dir ..."
    export c=$(ls -a .HIDE_${case_name} | wc | awk '{print $1}')
    if [ "${c}" -eq 2 ]; then
       echo " Empty directory"
       echo " No old inflation files found."
    else
       ${MOVE} .HIDE_${case_name}/* .
       # Get the date of this inflation restart file so you can remove it at the end
       export inf_prev_date_files=`ls -rt1 *dart.rh.cam_*inf_mean* | tail -1`
       export inf_prev_date_files=`echo $inf_prev_date_files | cut -d'.' -f5`
       echo " Old inflation date in hide = $inf_prev_date_files "
    fi
  else
    echo " No HIDE dir found."
    export c=2
  fi
fi


# ==============================================================================
# Block 2: Populate a run-time directory with the input needed to run DART.
# ==============================================================================

echo "`date` -- BEGIN COPY BLOCK"

# Put a pared down copy (no comments) of input.nml in this assimilate_cam directory.
# The contents may change from one cycle to the next, so always start from
# the known configuration in the CASEROOT directory.

cd ${TMPROOT}
if [  -e   input.nml.original ]; then
   sed -e "/#/d;/^\!/d;/^[ ]*\!/d" \
       -e '1,1i\WARNING: Changes to this file will be ignored. \n Edit input.nml.original instead.\n\n\n' \
       input.nml.original >! input.nml  || exit 10
else
   echo "ERROR ... DART required file ${TMPROOT}/input.nml not found ... ERROR"
   echo "ERROR ... DART required file ${TMPROOT}/input.nml not found ... ERROR"
   exit 11
fi

echo "`date` -- END COPY BLOCK"

# ==============================================================================
# Block 3: Identify requested output stages, warn about redundant output.
# ==============================================================================

cd ${TMPROOT}
export MYSTRING=$(grep stages_to_write input.nml | tail -1)
export MYSTRING=$(echo $MYSTRING | sed -e "s#[=,'\.]# #g" | sed 's/stages_to_write//g')
export STAGE_input=FALSE
export STAGE_forecast=FALSE
export STAGE_preassim=FALSE
export STAGE_postassim=FALSE
export STAGE_analysis=FALSE
export STAGE_output=FALSE

# Assemble lists of stages to write out, which are not the 'output' stage.

export stages_except_output="{"
stage=2
for var in ${MYSTRING};do
   if [ $var == 'input' ]; then
      export STAGE_input=TRUE
      if [ $stage -gt 2 ];then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}input"
   fi
   if [ $var == 'forecast' ];then
      export STAGE_forecast=TRUE
      if [ $stage -gt 2 ];then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}forecast"
   fi
   if [ $var == 'preassim' ];then
      export STAGE_preassim=TRUE
      if [ $stage -lt 2 ];then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}preassim"
   fi
   if [ $var == 'postassim' ];then
      export STAGE_postassim=TRUE
      if [ $stage -lt 2 ];then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}postassim"
   fi
   if [ $var == 'analysis' ];then
      export STAGE_analysis=TRUE
      if [ $stage -gt 2 ];then
         export stages_except_output="${stages_except_output},"
      fi
      export stages_except_output="${stages_except_output}analysis"
   fi
   # if [ $stage -eq 4 ];then
   if [ $stage -eq 3 ];then
      export stages_all="${stages_except_output}"
      if [ $var == 'output' ];then
         export STAGE_output=TRUE
         export stages_all="${stages_all},output"
      fi
   fi

   stage=$(echo "${stage}+1" | bc)
done

# Add the closing }
export stages_all="${stages_all}}"
export stages_except_output="${stages_except_output}}"

# Checking
echo "stages_except_output = $stages_except_output"
echo "stages_all = $stages_all"
if [ $STAGE_output != TRUE ];then
   echo "ERROR: assimilate.csh requires that input.nml:filter_nml:stages_to_write includes stage 'output'"
   exit 40
fi



# ==============================================================================
# Block 5: Get observation sequence file ... or die right away.
# The observation file names have a time that matches the stopping time of CAM.
#
# Make sure the file name structure matches the obs you will be using.
# PERFECT model obs output appends .perfect to the filenames
# ==============================================================================


export its=1
while [ $its -le $NTSLOTS ]; do
   cd "${TMPROOT}/TS$its"
   export DIROBS=$(printf "%04d/%02d/%04d%02d%02d%02d" "$ATM_YEAR" "$ATM_MONTH" "$ATM_YEAR" "$ATM_MONTH" "$ATM_DAY" "$ATM_HOUR")
   export ldbo=$(ls *.db 2>/dev/null | wc -l)
   if [ $ldbo -gt 0 ]; then
      echo "Remove old databases from TS${its}"
      rm -f "${TMPROOT}/TS${its}"/*.db
   fi
   export OBS_FILE="${BASEOBSDIR}/${DIROBS}/TS${its}"
   echo "Copy the new databases in TS${its}"
   find "${OBS_FILE}" -maxdepth 1 -type f -name "*.db" -exec cp -f {} . \;
   its=$((its+1))
done


# ==============================================================================
# Block 6: DART INFLATION
# This block is only relevant if 'inflation' is turned on AND
# inflation values change through time:
# filter_nml
#    inf_flavor(:)  = 2  (or 3 (or 4 for posterior))
#    inf_initial_from_restart    = .TRUE.
#    inf_sd_initial_from_restart = .TRUE.
#
# This block stages the files that contain the inflation values.
# The inflation files are essentially duplicates of the DART model state,
# which have names in the CESM style, something like
#    ${case}.dart.rh.${scomp}_output_priorinf_{mean,sd}.YYYY-MM-DD-SSSSS.nc
# The strategy is to use the latest such files in ${RUNDIR}.
# If those don't exist at the start of an assimilation,
# this block creates them with 'fill_inflation_restart'.
# If they don't exist AFTER the first cycle, the script will exit
# because they should have been available from a previous cycle.
# The script does NOT check the model date of the files for consistency
# with the current forecast time, so check that the inflation mean
# files are evolving as expected.
#
# CESM's st_archive should archive the inflation restart files
# like any other "restart history" (.rh.) files; copying the latest files
# to the archive directory, and moving all of the older ones.
# ==============================================================================

# If we need to run fill_inflation_restart, CAM:static_init_model()
# always needs a caminput.nc and a cam_phis.nc for geometry information, etc.

echo "`date` -- BEGIN PREPROCESSING"


cd ${TMPROOT}

date
echo "BEGIN PYTHON PROCESS "

#===================================================
#
# Define shell functions
#
#===================================================
# Take the id of the case.submit processes
take_id()
{

  output=$($*)
  echo $output | awk '{print $2}' | cut -d"<" -f2 | cut -d">" -f1
}
#===================================================

set +e
export inst=1
while [ $inst -le $nens ];do
   export inst_string=`printf _%04d $inst`
   export its=1
   
   while [ $its -le $NTSLOTS ];do
      export cits=`echo "${NTSLOTS}+1-${its}" | bc`
	   export datets=`ls -l $CASESRUNROOT/${case_name}$inst_string/run/*cam.i* | tail -n ${cits} | head -n 1 | cut -d '.' -f4`
	   export ftoass="$CASESRUNROOT/${case_name}$inst_string/run/${case_name}$inst_string.cam.i.${datets}.nc"

      ncdump -h ${ftoass} | grep -q "QVMR" >/dev/null 2>&1
#      if [ $? -eq 0 ]; then
#         echo "Variable exists QVMR: ${ftoass}"
#      else
         echo "Member: ${inst}, TS${its}: python preproc. ${ftoass}"
         #nohup /work/cmcc/mg20022/.conda/envs/netcdf4-env/bin/python ${TMPROOT}/rep_input.py ${ftoass} >/dev/null 2>&1 &
         nohup /work/cmcc/spreads-atm/.conda/envs/netcdf4/bin/python ${TMPROOT}/rep_input.py ${ftoass} >/dev/null 2>&1 &
#      fi

      its=$(echo "${its}+1" | bc) 
   done

   wait 
   inst=$(echo "${inst}+1" | bc)
done
set -e
wait

#rm -rf list.txt
#touch list.txt

#export inst=1
#while [ $inst -le $nens ];do
#   export inst_string=`printf _%04d $inst`
#   export its=1
#   
#   while [ $its -le $NTSLOTS ];do
#           export cits=`echo "${NTSLOTS}+1-${its}" | bc`
#	   export datets=`ls -l $CASESRUNROOT/${case_name}$inst_string/run/*cam.i* | tail -n ${cits} | head -n 1 | cut -d '.' -f4`
#	   export ftoass="$CASESRUNROOT/${case_name}$inst_string/run/${case_name}$inst_string.cam.i.${datets}.nc"
#	   echo "Member: ${inst}, TS${its}: python preproc. ${ftoass}"
#	   # python ${TMPROOT}/rep_input.py ${ftoass}
#
#           cp run_prepy_template.bash run_prepy.bash
#	   sed -i "s@TEMPLATE_PYTHON_FILE@${ftoass}@g"  run_prepy.bash 
#
#           jobid=$(take_id bsub < run_prepy.bash) 
#           if [ $its -eq 1 ] && [ $inst -eq 1  ]
#               then
#               p_string_id=$p_string_id" done($jobid)"
#             else
#               p_string_id=$p_string_id" && done($jobid)"
#           fi	   
#	   rm -f run_prepy.bash
#
#	   # nohup python ${TMPROOT}/rep_input.py ${ftoass} >/dev/null 2>&1 &
#           #echo ${ftoass} >> list.txt
#
#
#           its=$(echo "${its}+1" | bc) 
#   done
#
#   inst=$(echo "${inst}+1" | bc)
#done
#
#echo "wait for ${p_string_id}"
#bsub -w "$p_string_id" < cases_bogus_prepy.bash

##/work/cmcc/mg20022/.conda/envs/guatura/bin/python ${TMPROOT}/rep_input.py list.txt 50
date

echo "END PYTHON PROCESS "



export MYSTRING=$(grep cam_template_filename input.nml)
export MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g" | awk '{print $2}')
export CAMINPUT=$MYSTRING
${REMOVE} -f ${CAMINPUT}
#${LINK} ${CASE}.cam_0001.i.${ATM_DATE_EXT}.nc ${CAMINPUT} || exit 90
${LINK} $CASESRUNROOT/${case_name}_0001/run/${case_name}_0001.cam.i.${ATM_DATE_EXT}.nc ${CAMINPUT} || exit 90

export its=1
while [ $its -le $NTSLOTS ];do
   ${REMOVE} -f ./TS${its}/${CAMINPUT}
   ${LINK} $CASESRUNROOT/${case_name}_0001/run/${case_name}_0001.cam.i.${ATM_DATE_EXT}.nc ./TS${its}/${CAMINPUT} || exit 90
   its=$(echo "${its}+1" | bc)
done


# All of the .h0. files contain the same PHIS field, so we can link to any of them.

#export hists = `${LIST} ${CASE}.cam_0001.h0.*.nc`
export hists=$(${LIST} $CASESRUNROOT/${case_name}_0001/run/${case_name}_0001.cam.h0.* | head -1)
export MYSTRING=$(grep cam_phis_filename input.nml)
export MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g" | awk '{print $2}')
export CAM_PHIS=$MYSTRING
${REMOVE} -f ${CAM_PHIS}
${LINK} $hists ${CAM_PHIS} || exit 100
echo " Extract information phis from $hists"


export its=1
while [ $its -le $NTSLOTS ];do

   ${REMOVE} -f ./TS${its}/${CAM_PHIS}
   #${COPY} $hists[1] ./TS${its}/${CAM_PHIS} || exit 90
   ${LINK} $hists ./TS${its}/${CAM_PHIS} || exit 90

   its=$(echo "${its}+1" | bc)
done

# Now, actually check the inflation settings

export  MYSTRING=$(grep inf_flavor input.nml)
export  MYSTRING=$(echo $MYSTRING | sed -e "s#[=,'\.]# #g")
export  PRIOR_INF=$(echo $MYSTRING | awk '{print $2}')
export  POSTE_INF=$(echo $MYSTRING | awk '{print $3}')

export  MYSTRING=$(grep inf_initial_from_restart input.nml)
export  MYSTRING=$(echo $MYSTRING | sed -e "s#[=,'\.]# #g")
echo " MYSTRING = ${MYSTRING}"

# If no inflation is requested, the inflation restart source is ignored
echo " PRIOR_INF= $PRIOR_INF"
echo " POSTE_INF= $POSTE_INF"

if [ $PRIOR_INF -eq 0 ];then
   export  PRIOR_INFLATION_FROM_RESTART="ignored"
   export  USING_PRIOR_INFLATION="false"
else
   export  PRIOR_INFLATION_FROM_RESTART=`echo $MYSTRING | awk '{print $2}' | tr '[:upper:]' '[:lower:]'`
   export  USING_PRIOR_INFLATION="true"
fi
echo " PRIOR_INFLATION_FROM_RESTART = ${PRIOR_INFLATION_FROM_RESTART}"
echo " USING_PRIOR_INFLATION = ${USING_PRIOR_INFLATION}"

if [ $POSTE_INF -eq 0 ];then
   export  POSTE_INFLATION_FROM_RESTART="ignored"
   export  USING_POSTE_INFLATION="false"
else
   export  POSTE_INFLATION_FROM_RESTART=`echo $MYSTRING | awk '{print $3}' | tr '[:upper:]' '[:lower:]'`
   export  USING_POSTE_INFLATION="true"
fi
echo " POSTE_INFLATION_FROM_RESTART = ${POSTE_INFLATION_FROM_RESTART}"
echo " USING_POSTE_INFLATION = ${USING_POSTE_INFLATION}"

if [ $USING_PRIOR_INFLATION == "false" ];then
   export stages_requested=0
   if [ $STAGE_input    == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $STAGE_forecast == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $STAGE_preassim == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $stages_requested -gt 1 ];then
      echo " "
      echo "WARNING ! ! Redundant output is requested at multiple stages before assimilation."
      echo "            Stages 'input' and 'forecast' are always redundant."
      echo "            Prior inflation is OFF, so stage 'preassim' is also redundant. "
      echo "            We recommend requesting just 'preassim'."
      echo " "
   fi
fi

if [ $USING_POSTE_INFLATION == "false" ]; then
   export stages_requested=0
   if [ $STAGE_postassim == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $STAGE_analysis  == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $STAGE_output    == "TRUE" ];then
      stages_requested=$(echo "${stages_requested}+1" | bc)
   fi
   if [ $stages_requested -gt 1 ]; then
      echo " "
      echo "WARNING ! ! Redundant output is requested at multiple stages after assimilation."
      echo "            Stages 'output' and 'analysis' are always redundant."
      echo "            Posterior inflation is OFF, so stage 'postassim' is also redundant. "
      echo "            We recommend requesting just 'output'."
      echo " "
   fi
fi

# IFF we want PRIOR inflation:
echo " CONTINUE_RUN = ${CONT_RUN}"

if [ $USING_PRIOR_INFLATION == "true" ]; then
   if [ $PRIOR_INFLATION_FROM_RESTART == "false" ]; then

      echo "inf_flavor(1) = $PRIOR_INF, using namelist values."

   else
      # Look for the output from the previous assimilation (or fill_inflation_restart)
      # If inflation files exists, use them as input for this assimilation
      
      set +e
      rm -f latestfile 
      rm -f input_priorinf_mean.nc  
      rm -f input_priorinf_sd.nc  
      if [ $CONT_RUN == "FALSE" ]; then
          (${LIST} -rt1 "*.dart.rh.${scomp}_output_priorinf_mean*" | tail -n 1 >> latestfile) 2>  /dev/null
          (${LIST} -rt1 "*.dart.rh.${scomp}_output_priorinf_sd*"   | tail -n 1 >> latestfile) 2>  /dev/null
      else
	   ${LIST} -rt1 *.dart.rh.${scomp}_output_priorinf_mean* | tail -n 1 >> latestfile
           ${LIST} -rt1 *.dart.rh.${scomp}_output_priorinf_sd*   | tail -n 1 >> latestfile
      fi
      set -e
      export nfiles=`cat latestfile | wc -l`

      # Print the content of latestfile
      cat latestfile

      echo " nfiles = $nfiles"
      

      if [ $nfiles -gt 0 ]; then

         export latest_mean=`head -n 1 latestfile`
         export latest_sd=`tail -n 1 latestfile`

         echo " latest_mean = $latest_mean"
         echo " latest_sd = $latest_sd"
         # Need to COPY instead of link because of short-term archiver and disk management.
         ${COPY} $latest_mean input_priorinf_mean.nc
         ${COPY} $latest_sd   input_priorinf_sd.nc

         echo " add TS TREFHT LANDFRAC QVMR to the inflation files"
         python ./rep_inflation.py


      elif [ $CONT_RUN == "FALSE" -o $nfiles -eq 0 ]; then

         # It's the first assimilation; try to find some inflation restart files
         # or make them using fill_inflation_restart.
         # Fill_inflation_restart needs caminput.nc and cam_phis.nc for static_model_init,
         # so this staging is done in assimilate.csh (after a forecast) instead of stage_cesm_files.

         if [ -x fill_inflation_restart ]; then

            echo " CALLING  FILL INFLATION RESTART"
            #./fill_inflation_restart
            ${TMPROOT}/take_f.sh ${TMPROOT} "inflation"
            echo " END  FILL INFLATION RESTART"

            echo "add TS TREFHT LANDFRAC QVMR to the inflation files"
            python ./rep_inflation.py

         else
            echo "ERROR: Requested PRIOR inflation restart for the first cycle."
            echo "       There are no existing inflation files available "
            echo "       and ${EXEROOT}/fill_inflation_restart is missing."
            echo "EXITING"
            exit 112
         fi
      else
         echo "ERROR: Requested PRIOR inflation restart, "
         echo '       but files *.dart.rh.${scomp}_output_priorinf_* do not exist in the ${RUNDIR}.'
         echo '       If you are changing from cam_no_assimilate.csh to assimilate.csh,'
         echo '       you might be able to continue by changing CONTINUE_RUN = FALSE for this cycle,'
         echo '       and restaging the initial ensemble.'
         ${LIST} -l *inf*
         echo "EXITING"
         exit 115
      fi
   fi
else
   echo "Prior Inflation not requested for this assimilation."
fi

# POSTERIOR: We look for the 'newest' and use it - IFF we need it.


if [ $USING_POSTE_INFLATION == "true" ]; then
   if [ $POSTE_INFLATION_FROM_RESTART == "false" ]; then

      # we are not using an existing inflation file.
      echo "inf_flavor(2) = $POSTE_INF, using namelist values."

   else
      # Look for the output from the previous assimilation (or fill_inflation_restart).
      # (The only stage after posterior inflation.)
      set +e
      rm -rf latestfile
      (${LIST} -rt1 "*.dart.rh.${scomp}_output_postinf_mean*" | tail -n 1 >> latestfile) 2>  /dev/null
      (${LIST} -rt1 "*.dart.rh.${scomp}_output_postinf_sd*"   | tail -n 1 >> latestfile) 2>  /dev/null
      set -e
      export nfiles=`cat latestfile | wc -l`

      echo "nfiles =  $nfiles"

      # If one exists, use it as input for this assimilation
      if [ $nfiles -gt 0 ]; then

         export latest_mean=`head -n 1 latestfile`
         export latest_sd=`tail -n 1 latestfile`

         echo "latest_mean = $latest_mean"
         echo "latest_sd = $latest_sd"

         ${LINK} $latest_mean input_postinf_mean.nc || exit 120
         ${LINK} $latest_sd   input_postinf_sd.nc   || exit 121

      elif [ $CONT_RUN == "FALSE" ]; then
         # It's the first assimilation; try to find some inflation restart files
         # or make them using fill_inflation_restart.
         # Fill_inflation_restart needs caminput.nc and cam_phis.nc for static_model_init,
         # so this staging is done in assimilate.csh (after a forecast) instead of stage_cesm_files.

         if [ -x fill_inflation_restart ];then
            ./fill_inflation_restart
            ${MOVE} input_priorinf_mean.nc input_postinf_mean.nc || exit 125
            ${MOVE} input_priorinf_sd.nc   input_postinf_sd.nc   || exit 126

         else
            echo "ERROR: Requested POSTERIOR inflation restart for the first cycle."
            echo "       There are no existing inflation files available "
            echo "       and ${EXEROOT}/fill_inflation_restart is missing."
            echo "EXITING"
            exit 127
         fi

      else
         echo "ERROR: Requested POSTERIOR inflation restart, "
         echo '       but files *.dart.rh.${scomp}_output_postinf_* do not exist in the ${RUNDIR}.'
         ${LIST} -l *inf*
         echo "EXITING"
         exit 128
      fi
   fi
else
   echo "Posterior Inflation not requested for this assimilation."
fi

cd ${TMPROOT}
if [ $USING_PRIOR_INFLATION == true ]; then
   export its=1
   while [ $its -le $NTSLOTS ];do
      ${COPY} ${TMPROOT}/input_priorinf_mean.nc ${TMPROOT}/TS$its/
      ${COPY} ${TMPROOT}/input_priorinf_sd.nc ${TMPROOT}/TS$its/

      its=$(echo "${its}+1" | bc)
   done
fi

echo "`date` -- END PREPROCESSING"
echo "`date` -- BEGIN FILTER"



# ==============================================================================
# Block 7: Actually run the assimilation.
#
# DART namelist settings required:
# &filter_nml
#    adv_ens_command         = "no_CESM_advance_script",
#    obs_sequence_in_name    = 'obs_seq.out'
#    obs_sequence_out_name   = 'obs_seq.final'
#    single_file_in          = .false.,
#    single_file_out         = .false.,
#    stages_to_write         = stages you want + ,'output'
#    input_state_file_list   = 'cam_init_files'
#    output_state_file_list  = 'cam_init_files',
#
# WARNING: the default mode of this script assumes that
#          input_state_file_list = output_state_file_list, so that
#          the CAM initial files used as input to filter will be overwritten.
#          The input model states can be preserved by requesting that stage
#          'forecast' be output.
#
# ==============================================================================

# In the default mode of CAM assimilations, filter gets the model state(s)
# from CAM initial files.  This section puts the names of those files into a text file.
# The name of the text file is provided to filter in filter_nml:input_state_file_list.

# NOTE:
# If the files in input_state_file_list are CESM initial files (all vars and
# all meta data), then they will end up with a different structure than
# the non-'output', stage output written by filter ('preassim', 'postassim', etc.).
# This can be prevented (at the cost of more disk space) by copying
# the CESM format initial files into the names filter will use for preassim, etc.:
#    > cp $case.cam_0001.i.$date.nc  preassim_member_0001.nc.
#    > ... for all members
# Filter will replace the state variables in preassim_member* with updated versions,
# but leave the other variables and all metadata unchanged.

# If filter will create an ensemble from a single state,
#    filter_nml: perturb_from_single_instance = .true.
# it's fine (and convenient) to put the whole list of files in input_state_file_list.
# Filter will just use the first as the base to perturb.



cd ${TMPROOT}
export line=$(grep input_state_file_list input.nml | sed -e "s#[=,'\.]# #g" | awk '{print $2}' )
export input_file_list_name=$line
# If the file names in $output_state_file_list = names in $input_state_file_list,
# then the restart file contents will be overwritten with the states updated by DART.
export line=$(grep output_state_file_list input.nml | sed -e "s#[=,'\.]# #g" | awk '{print $2}')
export output_file_list_name=$line

echo " input_file_list_name = ${input_file_list_name}"
echo " output_file_list_name = ${output_file_list_name}"


#!/bin/bash

if [ "$input_file_list_name" != "$output_file_list_name" ]; then
    echo "ERROR: assimilate.csh requires that input_file_list = output_file_list"
    echo "       You can probably find the data you want in stage 'forecast'."
    echo "       If you truly require separate copies of CAM's initial files"
    echo "       before and after the assimilation, see revision 12603, and note that"
    echo "       it requires changing the linking to cam_initial_####.nc, below."
    exit 130
fi

echo "input/output_file_lis_name = ${input_file_list_name}"


#!/bin/bash

# FGAT procedure or one shot?
if [ "${ffgat}" == "FALSE" ]; then
    echo "ONE SHOT ASSIMILATION, d4o_departure=all"

    # Merge the dbs to create the allTS dir
    echo "DB MERGING, CREATION OF allTS dir"
    if [ -d "${TMPROOT}/allTS" ]; then
        rm -rf "${TMPROOT}/allTS"
    fi
    
    rm -rf files_db.txt
    ls TS*/*.?.db | sed 's@TS.*/@@g' > files_db.txt
    for f in $(sort files_db.txt | uniq);do
       ./d4ojoin $(find TS*/ -name $f | head -1)
    done
    #${TMPROOT}/d4ojoinall
    cp ${TMPROOT}/d4ocatalog ${TMPROOT}/allTS/
    ${TMPROOT}/allTS/d4ocatalog catalog.db *.db
    cd "${TMPROOT}"

    cp ${TMPROOT}/*.dat ${TMPROOT}/allTS
    cp ${TMPROOT}/*.H5 ${TMPROOT}/allTS
    cp ${TMPROOT}/fil* ${TMPROOT}/allTS
    cp ${TMPROOT}/*.csv ${TMPROOT}/allTS
    cp ${TMPROOT}/*.nc ${TMPROOT}/allTS
    cp ${TMPROOT}/*.nml ${TMPROOT}/allTS

    # stage_to_write must be 'forecast', output' it should be already specified!

    # Link the new backgrounds
    inst=1
    while [ "$inst" -le "$nens" ]; do
        inst_string=$(printf "_%04d" "$inst")
        datets=`ls -l "$CASESRUNROOT/${case_name}${inst_string}/run/*cam.i* | tail -n 7 | head -n 1 | cut -d '.' -f4` #BASED ON 13 TSLOTS
        ftoass="$CASESRUNROOT/${case_name}${inst_string}/run/${case_name}${inst_string}.cam.i.${datets}.nc"
        echo "allTS member ${inst}: insert ${ftoass} in ${input_file_list_name}"
        echo "${ftoass}" >> "${TMPROOT}/allTS/${input_file_list_name}"
        inst=$(echo "${inst}+1" | bc)
    done


    # Do the assimilation in one shot

    echo 'CALLING take_f.sh'
    "${TMPROOT}/take_f.sh" "${TMPROOT}" "filter" "all"
    echo 'END take_f.sh'
else
    echo "FGAT ON, TWO STEP ASSIMILATION, d4o_departure=yes/no"

# PHASE 1 departures computation
#-----------------------------------------------------------------------
    echo "ENTER PHASE 1, PRIOR DEPARTURES COMPUTATION"

    its=1
    while [ "$its" -le "$NTSLOTS" ]; do
       ${REMOVE} -f "./TS${its}/$input_file_list_name"
       ${REMOVE} -f "./TS${its}/$output_file_list_name"
       ${REMOVE} -f "./TS${its}"/*output*.nc
       #${REMOVE} -f "./TS${its}"/*input*.nc
       #${COPY} *input*.nc "./TS${its}/"
       its=$(echo "${its}+1" | bc)
    done

    inst=1
    while [ "$inst" -le "$nens" ]; do
       inst_string=$(printf "_%04d" "$inst")
       echo "inst_string: ${inst_string}"
       its=1
       while [ "$its" -le "$NTSLOTS" ]; do
           cits=$(echo "${NTSLOTS}+1-${its}" | bc)
           datets=`ls -l $CASESRUNROOT/${case_name}${inst_string}/run/*cam.i* | tail -n $cits | head -n 1 | cut -d '.' -f4`
           ftoass="$CASESRUNROOT/${case_name}${inst_string}/run/${case_name}${inst_string}.cam.i.${datets}.nc"
           echo "TS${its}: insert ${ftoass} in ${input_file_list_name}"
           echo "${ftoass}" >> "./TS${its}/${input_file_list_name}"
	   cat ./TS${its}/${input_file_list_name}
           its=$(echo "${its}+1" | bc)
       done
       inst=$(echo "${inst}+1" | bc)
    done


    # do not save forecast during phase 1
    its=1
    while [ "$its" -le "$NTSLOTS" ]; do
       echo "change the stages to write (no forecast) in TS${its}"
       sed -i "s@.*stages_to_write.*=.*@stages_to_write='output'@g" "./TS${its}/input.nml"
       its=$(echo "${its}+1" | bc)
    done

    echo 'CALLING take_f.sh'
    "${TMPROOT}/take_f.sh" "${TMPROOT}" "filter" "yes" "$NTSLOTS"
    echo 'END take_f.sh'

    # check if the assimilation ended correctly otherwise you need to skip all the instructions below
    its=1
    ic=0
    while [ "$its" -le "$NTSLOTS" ]; do
      if grep -q "2" "${TMPROOT}/TS${its}/filter.flag"; then
          echo " phase 1 ended successfully, in TS${its}"
          ic=$(echo "${ic}+1" | bc)
      fi
      its=$(echo "${its}+1" | bc)
    done

    if [ "$ic" -eq "$NTSLOTS" ]; then
       echo "PHASE 1 ended successfully"
    else
       echo "ERROR in PHASE1"
       exit
    fi

    # Database merging
    #-----------------------------------------------------------------------
    echo "DB MERGING, PREPARATION FOR PHASE 2"
    if [ -d "${TMPROOT}/allTS" ]; then
       rm -Rf "${TMPROOT}/allTS"
    fi

    rm -rf files_db.txt
    ls TS*/*.?.db | sed 's@TS.*/@@g' > files_db.txt
    for f in $(sort files_db.txt | uniq);do
       ./d4ojoin $(find TS*/ -name $f | head -1)
    done
    #"${TMPROOT}/d4ojoinall"
    cp "${TMPROOT}/d4ocatalog" "${TMPROOT}/allTS/"
    cp "${TMPROOT}/d4ofixtoc" "${TMPROOT}/allTS/"
    cp "${TMPROOT}/d4ocatalog" "${TMPROOT}/allTS/"
    cd ${TMPROOT}/allTS
    ./d4ocatalog catalog.db  *.db
    cd ${TMPROOT}

    # Automatic blacklisting for gpsro
    #-----------------------------------------------------------------------
    echo "AUTO BLACKLISTING FOR GPSRO BEFORE PHASE 2"
    cp "${TMPROOT}/postscreening.x" "${TMPROOT}/allTS/"
    cp "${TMPROOT}/run_post_bs.bash" "${TMPROOT}/allTS/"

    # Here you are using BSUB -I option if you remove it you need to use some bsub -w option with a bogus program to wait 
    cd "${TMPROOT}/allTS"
    #bsub < run_post_bs.bash
    cd "${TMPROOT}"


    # PHASE 2 one shot assimilation
    #-----------------------------------------------------------------------
    # copy files from the central time slot to allTS
    echo "ENTER PHASE 2, REGRESSION"
    echo "COPY WHAT WE NEED FOR ASSIMILATION FROM CENTRAL TS=7, IMPLEMENTATION FOR 13 TIME SLOTS"
    cp ${TMPROOT}/TS7/*.dat ${TMPROOT}/allTS
    cp ${TMPROOT}/TS7/*.H5 ${TMPROOT}/allTS
    cp ${TMPROOT}/TS7/fil*  ${TMPROOT}/allTS
    rm -f ${TMPROOT}/allTS/filter.flag
    cp ${TMPROOT}/TS7/*.csv ${TMPROOT}/allTS
    cp ${TMPROOT}/TS7/*.nc  ${TMPROOT}/allTS
    cp ${TMPROOT}/*.nml  ${TMPROOT}/allTS
    cp ${TMPROOT}/TS7/${input_file_list_name}  ${TMPROOT}/allTS
    cp ${TMPROOT}/TS7/${output_file_list_name} ${TMPROOT}/allTS

    echo 'CALLING take_f.sh'
    ${TMPROOT}/take_f.sh "${TMPROOT}" "filter" "no"
    echo 'END take_f.sh'

fi # End FGAT procedure choice




if grep -q "2" "${TMPROOT}/allTS/filter.flag"; then # CLOSE THE IF AT THE END
    echo "phase 2 ended successfully, move files into archive, set check_assi.flag to 1"

    echo "$(date) -- END FILTER"

    cd "${TMPROOT}/allTS"


# ==============================================================================
# Block 8: Rename the output using the CESM file-naming convention.
# ==============================================================================

# If output_state_file_list is filled with custom (CESM) filenames,
# then 'output' ensemble members will not appear with filter's default,
# hard-wired names.  But file types output_{mean,sd} will appear and be
# renamed here.
#
# We don't know the exact set of files which will be written,
# so loop over all possibilities: use LIST in the foreach.
# LIST will expand the variables and wildcards, only existing files will be
# in the foreach loop. (If the input.nml has num_output_state_members = 0,
# there will be no output_member_xxxx.nc even though the 'output' stage
# may be requested - for the mean and sd)
#
# Handle files with instance numbers first.
#    split off the .nc
#    separate the pieces of the remainder
#    grab all but the trailing 'member' and #### parts.
#    and join them back together

   echo "`date` -- BEGIN FILE RENAMING"

   set +e

# The short-term archiver archives files depending on pieces of their names.
# '_####.i.' files are CESM initial files.
# '.dart.i.' files are ensemble statistics (mean, sd) of just the state variables
#            in the initial files.
# '.e.'      designates a file as something from the 'external system processing ESP', e.g. DART.
# for stage in $( echo ${stages_all} );do
    for FILE in  forecast_member_????.nc;do # {forecast,,output}

        parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
        dart_file=$(echo $parts | sed "s/.nc//g")

        # DART 'output_member_****.nc' files are actually linked to cam input files

        if [[ "out" == "${FILE:0:3}" ]];then
            export type="i"
        else
            export type="e"
        fi

        echo "Moving $FILE in ${case_name}.${scomp}.${type}.${dart_file}.${ATM_DATE_EXT}.nc "
        mv $FILE  ${case_name}.${scomp}.${type}.${dart_file}.${ATM_DATE_EXT}.nc || exit 150

    done
# done

# Files without instance numbers need to have the scomp part of their names = "dart".
# This is because in st_archive, all files with  scomp = "cam"
# (= compname in env_archive.xml) will be st_archived using a pattern
# which has the instance number added onto it.  {mean,sd} files don't have
# instance numbers, so they need to be archived by the "dart" section of env_archive.xml.
# But they still need to be different for each component, so include $scomp in the
# ".dart_file" part of the file name.  Somewhat awkward and inconsistent, but effective.

# Accommodate any possible inflation files.
# The .${scomp}_ part is needed by DART to distinguish
# between inflation files from separate components in coupled assims.
    for tp in $(echo "mean sd");do
        #for tp in $(echo "prior post");do
        #for tp in $(echo "prior");do
            for FILE in $(ls input_priorinf_${tp}*.nc);do
                parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
                echo "$FILE renaming"
                mv -f $FILE  ${case_name}.dart.rh.${scomp}_${parts}.${ATM_DATE_EXT}.nc || exit 180
            done
	    for FILE in $(ls output_priorinf_${tp}*.nc);do
                parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
                echo "$FILE renaming"
                mv -f $FILE  ${case_name}.dart.rh.${scomp}_${parts}.${ATM_DATE_EXT}.nc || exit 180
            done
        #done
    done


# Means and standard deviation files (except for inflation).
# for stage in $(echo "mean sd");do
#     for FILE in $(ls ${stage}_*.nc);do
# for stage in $(echo $stages_all)/work/cmcc/gc02720/CMCC-CM/archive/gpswdpsnd3/gpswdpsnd3-2017-10-02-21600/;do
    for tp in $(echo "mean sd");do
	echo "tp: $tp"    
        #for stg in $(echo ${stages_all});do
        for stg in $(echo "forecast output");do
            echo "stg: $stg" 		
            for FILE in $( ls ${stg}_${tp}*.nc );do
                echo "$FILE renaming"
                parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
                if [[ "out" == "${FILE:0:3}" ]];then
                    export type="i"
                else
                    export type="e"
                fi

                mv $FILE ${case_name}.dart.${type}.${scomp}_${parts}.${ATM_DATE_EXT}.nc || exit 160
            done
        done
    done

# Rename the observation file and run-time output
    if [ -f obs_seq.final.$(ls -l dart_log.out* | tail -1 | awk '{print $9}' | cut -d "." -f 3) ]; then
        mv -f obs_seq.final.$(ls -l dart_log.out* | tail -1 | awk '{print $9}' | cut -d "." -f 3) ${case_name}.dart.e.${scomp}_obs_seq_final.${ATM_DATE_EXT} || exit 170
    fi

#    mv -f $(ls -l dart_log.out* | tail -1 | awk '{print $9}') ${scomp}_dart_log.${ATM_DATE_EXT}.out || exit 171
    mv -f dart_log.out*  dart_log.${ATM_DATE_EXT}.out || exit 171

    for fdb in $(ls *.db);do
        fdb_no_ext=$(echo ${fdb} | cut -d'.' -f1)
        fdb_num=$(echo ${fdb} | cut -d'.' -f2)
        echo "move ${fdb_no_ext}.${fdb_num}"
        mv -f ${fdb} ${case_name}.spreads.${fdb_no_ext}.${fdb_num}.${ATM_DATE_EXT}.db || exit 170
    done
# Rename the inflation files and designate them as 'rh' files - which get
# reinstated in the run directory by the short-term archiver and are then
# available for the next assimilation cycle.
#
# Accommodate any possible inflation files.
# The .${scomp}_ part is needed by DART to distinguish
# between inflation files from separate components in coupled assims.
#    #for stage in $(echo $stages_all);do
#    for stage in $(echo "forecast output");do
#        #for tp in $(echo "prior post");do
#        for tp in $(echo "prior");do
#            for FILE in $(ls ${stage}_${tp}*.nc);do
#                parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
#		echo "$parts renaming"
#                mv -f $parts  ${case_name}.dart.rh.${scomp}_${parts}.${ATM_DATE_EXT}.nc || exit 180
#            done
#        done
#    done

# Handle localization_diagnostics_files
#    MYSTRING=$(grep 'localization_diagnostics_file' input.nml)
#    MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g")
#    MYSTRING=$(echo $MYSTRING | sed -e 's#"# #g')
#    loc_diag=$(echo "$MYSTRING" | awk '{print $2}')
#
#    if [ -f $loc_diag ];then
#        mv -f $loc_diag  ${scomp}_${loc_diag}.dart.e.${ATM_DATE_EXT} || exit 190
#    fi

# Handle regression diagnostics
#    MYSTRING=$(grep 'reg_diagnostics_file' input.nml)
#    MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g")
#    MYSTRING=$(echo $MYSTRING | sed -e 's#"# #g')
#    export reg_diag=$(echo "$MYSTRING" | awk '{print $2}')
#    if [ -f $reg_diag ];then
#        mv -f $reg_diag  ${scomp}_${reg_diag}.dart.e.${ATM_DATE_EXT} || exit 200
#    fi


    member=1
    while [ ${member} -le ${nens} ];do

        inst_string=$(printf _%04d $member)
        cd $CASESRUNROOT/${case_name}$inst_string/run
        echo " In `pwd` for i.c. renaming"
        ATM_INITIAL_FILENAME="${case_name}${inst_string}.cam.i.${ATM_DATE_EXT}.nc"
        rm -f ${scomp}_initial${inst_string}.nc
        echo " Link $ATM_INITIAL_FILENAME in ${scomp}_initial${inst_string}.nc "
        ln -sf $ATM_INITIAL_FILENAME ${scomp}_initial${inst_string}.nc || exit 210

        member=$(echo "${member}+1" | bc)

    done


    echo "$(date) -- END   FILE RENAMING"


    echo ""

    
    echo ""
    echo "$(date) -- START   ANALYSIS ARCHIVING"

    cd "${TMPROOT}"
    adir="${archive}/${case_name}/${case_name}-${ATM_DATE_EXT}"
    mkdir -p "$adir"
    ${MOVE} ./allTS/*.{e,i}*"${ATM_DATE_EXT}"*  "$adir"
    ${MOVE} ./allTS/*"${ATM_DATE_EXT}".db  "$adir"
    ${MOVE} ./allTS/dart_log.*.out  "$adir"
    ${MOVE} ./allTS/dart_log.nml.*  "$adir"

    # inflation archive, remove the oldest files
    if [ "$INFVAL" -eq 0 ]; then
      echo -e "\n No inflation used. Inflations files not hidden.\n"
    else
      echo -e "\n Inflation used. Hide inflation files and delete the old ones.\n"
      mkdir -p ".HIDE_${case_name}"
      ${COPY} ./allTS/*.rh.cam_*inf*"${ATM_DATE_EXT}"*  "$adir"
      ${MOVE} ./allTS/*.rh.cam_*inf*"${ATM_DATE_EXT}"*  ".HIDE_${case_name}"
      rm -f  ${TMPROOT}/*.rh.cam_*inf*"${ATM_DATE_EXT}"*

      #old_inf_files=$(ls -rt1 ./allTS/*.rh.cam_*inf*.nc | wc -l)
      #if [ "$old_inf_files" -eq 0 ]; then
      #  echo "Nothing to remove"
      #else
      #  echo "Remove old inflation files"
      #  ${REMOVE} ./allTS/*.dart.rh.cam_*inf*.nc
      #fi
    fi

# Restart management
    member=1
    while [ "$member" -le "$nens" ]; do

        inst_string=$(printf "_%04d" "$member")
        cd "$CASESRUNROOT/${case_name}${inst_string}/run"

        #echo -e "\n Restart processes date ${ATM_DATE[2]}-${ATM_DATE[3]}-${ATM_DATE[4]} \n"
        echo -e "\n Restart processes date ${ATM_MONTH}-${ATM_DAY}-${ATM_SECONDS} \n"
      	## Save the restarts at the beginning of the year
        #if [ "${ATM_DATE[2]}-${ATM_DATE[3]}-${ATM_DATE[4]}" == "01-01-00000" ]; then
        # Save the restarts at the beginning of the month
        #if [ "${ATM_DATE[3]}-${ATM_DATE[4]}" == "01-00000" ]; then
        if [ "${ATM_DAY}-${ATM_SECONDS}" == "01-00000" ]; then
            echo -e "\n Copy the restart files ... \n"
            ${COPY} *.{h0,r,rs,rs1}*"${ATM_DATE_EXT}"* "${adir}/"
            ${COPY} rpointer* "${adir}"
        fi

	member=$(echo "${member}+1" | bc)
    done

    echo "$(date) -- END   ANALYSIS ARCHIVING"

    cd "$SCRIPTDIR"
    cat check_assi.flag
    sed -i 's/0/1/g' check_assi.flag
    echo " wrote 1 in check_assi.flag"
    cat check_assi.flag

    #echo "FINISHED: compressing coupler history files and DART files at `date`"
    echo "$(date) -- END CAM_ASSIMILATE"

    # Ensure the removal of unneeded restart sets and copy of obs_seq.final are finished.
    wait


fi


exit 0
