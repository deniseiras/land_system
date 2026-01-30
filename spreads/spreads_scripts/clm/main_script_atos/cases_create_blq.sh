#!/bin/bash

#===========================================================
# Generate an ensemble of clones of a particular template.
# This is useful if you plan to run an ensemble of CAM si-
# mulation on a small cluster.
#
# Here I'm considering a template that is an hybrid case!
#
#===========================================================


# ==============================================================================
# Prepare your .bashrc with  this environment
# ==============================================================================
#export CIME_MACH='zeus'
#export CESMDATAROOT='/data/inputs/CESM'
#export CESMEXP='cesm-exp'
#export MODEL_PATH="/ec/res4/scratch/${USER}"
#export CESMDIR='spreads-cmcc-cm'

# SET IN YOUR BASHRC THIS ENV!
#module load anaconda/3.8
#conda activate /users_home/cmcc/dp16116/.conda/envs/py38CS2

#export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_TYPE=en_US.UTF-8

export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so


# ==============================================================================
# Prepare the experiment CHANGE HERE!
# ==============================================================================

# Experiment name
case_name="spreads_h5_exp"
case_name_upper=$(echo $case_name | tr '[:lower:]' '[:upper:]')

# Where to copy the clones (Use a clear name for the experiment. The dir name must 
# not appears in the case.template.original)
export clonesroot="/home/${USER}/${CESMEXP}/${case_name}"

# Number of clones
nens=5

# DART directory
export dartroot="/home/${USER}/spreads"


# DA working dir
tmpdir="${SCRATCH}/CMCC-CM/TMP${case_name_upper}"

# Archive (to remove previous files)
archdir="${SCRATCH}/CMCC-CM/archive"

# Set the obs dir
baseobsdir="/ec/res4/scratch/ita0829/obs/b2d4o_AMSUA_V2"

# Time slots used for the FGAT implementation (note: for every time timeslot you need to have an output from the model!)
nts=13

# Choose your exp template
script_name_original="case.template-atos.original-SP"

# Chose the input namelist for DART
dartnamelist="input.nml.original.rad"

# Ref date (YYYY-MM-DD-SSSSS)
RDATE=2017-10-02-00000

# Start date
SDATE=2017-10-02-00000

# IC dir
# ICDIR="${SCRATCH}/../ita5542/ic_spread_ugento"
ICDIR="/ec/res4/scratch/ita0829/ic/ic_spread_ugento"

# IC refcase
ICREFCASE="ic_phase1"

# SST dataset period
SST_YEAR_START=2017
SST_YEAR_END=2017


# ==============================================================================
# standard commands:
#
# Make sure that this script is using standard system commands
# instead of aliases defined by the user.
# If the standard commands are not in the location listed below,
# change the 'set' commands to use them.
# The verbose (-v) argument has been separated from these command definitions
# because these commands may not accept it on some systems.  On those systems
# set VERBOSE = ''
# ==============================================================================

VERBOSE='-v'
MOVE='/usr/bin/mv'
COPY='/usr/bin/cp --preserve=timestamps'
LINK='/usr/bin/ln -s'
LIST='/usr/bin/ls'
REMOVE='/usr/bin/rm -f'

maindir=`pwd`


echo -e "\n START EXPERIMENT CREATION \n"

# Parameters check
if [ ${nts} -eq 13 ]
  then
     tcentral=7
  else
     echo " Time slots division not supported yet "
     exit 222
fi

script_name="case.template"
${COPY} ${dartnamelist} input.nml
sed -i "s/NUM_INSTANCE_TEMPLATE/${nens}/g" input.nml

echo -e "\n Remove dir of a previus experiment with the same name if it exists!\n"
if [ -d ${archdir}/${case_name} ]; then
   ${REMOVE} -r ${archdir}/${case_name}
fi 
if [ -d ${tmpdir} ]; then
   ${REMOVE} -r ${tmpdir}
fi 
if [ -d ${clonesroot} ]; then
   ${REMOVE} -r ${clonesroot}
   ${REMOVE} -r /ec/res4/scratch/${USER}/CMCC-CM/${case_name}_*
fi

# if forecast active in the previous experiment
dirff=/ec/res4/scratch/${USER}/cesm-exp/${case_name}-forecast
if [ -d ${dirff} ]; then
   ${REMOVE} -r ${dirff}
   ${REMOVE} -r /ec/res4/scratch/${USER}/CMCC-CM/${case_name}_f_*
fi



# set the obs dir
#${COPY} cases_assimilate_template.csh cases_assimilate.csh
#sed -i "s@TEMPLATE_OBS_EXP@${baseobsdir}@g" cases_assimilate.csh
${COPY} cases_assimilate_template.bash cases_assimilate.bash
sed -i "s@TEMPLATE_OBS_EXP@${baseobsdir}@g" cases_assimilate.bash




containerdir=`echo ${clonesroot} | cut -d'/' -f6`
${COPY} -f ../case_archive/${script_name_original} ../case_archive/${script_name}
sed -i "s/TEMPLATE_DIR_EXP/${containerdir}/g" ../case_archive/${script_name}

sed -i "s/ICCASE_TEMPLATE/${ICREFCASE}/g" ../case_archive/${script_name}
sed -i "s/RY_TEMPLATE/${RDATE:0:4}/g" ../case_archive/${script_name}
sed -i "s/RM_TEMPLATE/${RDATE:5:2}/g" ../case_archive/${script_name}
sed -i "s/RD_TEMPLATE/${RDATE:8:2}/g" ../case_archive/${script_name}
sed -i "s/RS_TEMPLATE/${RDATE:11:5}/g" ../case_archive/${script_name}
sed -i "s@ICDIR_TEMPLATE@${ICDIR}@g" ../case_archive/${script_name}
sed -i "s/SY_TEMPLATE/${SDATE:0:4}/g" ../case_archive/${script_name}
sed -i "s/SM_TEMPLATE/${SDATE:5:2}/g" ../case_archive/${script_name}
sed -i "s/SD_TEMPLATE/${SDATE:8:2}/g" ../case_archive/${script_name}
sed -i "s/SS_TEMPLATE/${SDATE:11:5}/g" ../case_archive/${script_name}
sed -i "s/SST_Y_START_TEMPLATE/${SST_YEAR_START}/g" ../case_archive/${script_name}
sed -i "s/SST_Y_END_TEMPLATE/${SST_YEAR_END}/g" ../case_archive/${script_name}

#===========================================================
#
#===========================================================
# Create the first case

echo -e "Phase 1 (start): creation of a new case from template ...\n"

csh ../case_archive/${script_name} 


case=`awk '/setenv case /{print $NF}' ../case_archive/$script_name`
cesmroot=`awk '/setenv cesmroot/{print $NF}' ../case_archive/$script_name | \
          sed "s@\\\${MODEL_PATH}@$MODEL_PATH@g;\
               s@\\\${CESMDIR}@$CESMDIR@g"`
caseroot=`awk '/setenv caseroot/{print $NF}' ../case_archive/$script_name| \
          sed "s@\\\${USER}@$USER@g;\
               s@\\\${CESMEXP}@$CESMEXP@g;\
               s@\\\${case}@$case@g"`


echo "caseroot is: ${caseroot}"
echo "cesmroot is: ${cesmroot}"

echo -e "Template case created"
echo -e "Phase 1 (end)\n"

#===========================================================
#
#===========================================================
# Clone the case nens time

echo -e "Phase 2 (start): creation of the clones ...\n"

inst=1
while (($inst<= $nens))
do
   echo -e "member $inst\n"

   # Following the CESM strategy for 'inst_string'
   inst_string=`printf _%04d $inst`
   
   new_case="$clonesroot/$case_name$inst_string"
   # Create the clone 
   ${cesmroot}/cime/scripts/create_clone \
      --case     $new_case          \
      --clone    $caseroot          \





   # Modify the I.C. for each clone, then  build
   # Remember that each job contain ONLY one member
   cd $new_case
   
  # sed -i "s/_0001/$inst_string/g" user_nl_cam_0001  
  # ${MOVE} user_nl_cam_0001 user_nl_cam
  # sed -i "s/_0001/$inst_string/g" user_nl_cice_0001  
  # ${MOVE} user_nl_cice_0001 user_nl_cice
  # ${MOVE} user_nl_clm_0001 user_nl_clm
   
   RUNDIR=`./xmlquery RUNDIR       --value`
   refcase=`./xmlquery RUN_REFCASE --value`
   stagedir=`./xmlquery RUN_REFDIR --value`
   refdate=`./xmlquery RUN_REFDATE --value`
   reftod=`./xmlquery RUN_REFTOD   --value`
   COMP_ROF=`./xmlquery COMP_ROF   --value`   
   init_time="${refdate}-$reftod"
   
   
   echo "finidat='${refcase}${inst_string}.clm2.r.${init_time}.nc'">> user_nl_clm
   echo "finidat_hydros='${refcase}${inst_string}.hydros.r.${init_time}.nc'">> user_nl_hydros
   sed -i "s/ICE_IC_TEMPLATE/${refcase}${inst_string}.cice.r.${init_time}.nc/g" user_nl_cice
   sed -i "s/NCDATA_TEMPLATE/cam_initial${inst_string}.nc/g" user_nl_cam

   # # temporary solution for juno for BGC!
   # if [ "${script_name_original}" != "case.template-juno.original-SP" ] && [ "${script_name_original}" != "case.template-juno.original-SP-foretest" ] && [ "${script_name_original}" != "case.template-juno.original-SP-1deg" ]; then
	#  echo "SP activated for CLM"    
   #       echo "stream_meshfile_ch4finundated ='/ec/res4/scratch/gc02720/inputdata/lnd/clm2/paramdata/finundated_inversiondata_0.9x1_ESMFmesh_cdf5_130621.nc'" >> user_nl_clm
   #       echo "stream_meshfile_popdens ='/ec/res4/scratch/gc02720/inputdata/lnd/clm2/firedata/clmforc.Li_2017_HYDEv3.2_CMIP6_hdm_0.5x0_ESMFmesh_cdf5_100621.nc'" >> user_nl_clm
   #       echo "stream_fldfilename_lightng ='/ec/res4/scratch/gc02720/inputdata/atm/datm7/NASA_LIS/clmforc.Li_2016_climo1995-2013.360x720.lnfm_Total_c160825.nc'" >> user_nl_clm
   #       echo "stream_meshfile_lightng = '/ec/res4/scratch/gc02720/inputdata/atm/datm7/NASA_LIS/clmforc.Li_2016_climo1995-2013.360x720_ESMFmesh_cdf5_150621.nc'" >> user_nl_clm
   # fi


#   ./preview_namelists || exit 75

   echo "Staging initial files for instance $inst of $nens"

   cd $RUNDIR
   #${LINK} -f ${stagedir}/${refcase}.clm2${inst_string}.r.${init_time}.nc  .
   #${LINK} -f ${stagedir}/${refcase}.cice${inst_string}.r.${init_time}.nc  .
   #${LINK} -f ${stagedir}/${refcase}.cam${inst_string}.i.${init_time}.nc   cam_initial${inst_string}.nc
   #${LINK} -f ${stagedir}/${refcase}.mosart${inst_string}.r.${init_time}.nc .

   ${LINK} -f ${stagedir}/${refcase}${inst_string}.clm2.r.${init_time}.nc  .
   ${LINK} -f ${stagedir}/${refcase}${inst_string}.cice.r.${init_time}.nc  .
   ${LINK} -f ${stagedir}/${refcase}${inst_string}.cam.i.${init_time}.nc   cam_initial${inst_string}.nc
   ${LINK} -f ${stagedir}/${refcase}${inst_string}.hydros.r.${init_time}.nc .
   
   # Build the case

   cd $new_case
   echo ''
   echo 'Copy executable'
   echo ''

   ./xmlchange --file env_build.xml --id BUILD_COMPLETE --val TRUE
   ./xmlchange --file env_build.xml --id BUILD_STATUS --val 0
   cp /ec/res4/scratch/${USER}/CMCC-CM/case_template/bld/cesm.exe  ${RUNDIR}/../bld/cesm.exe


   ((inst++))
done

echo -e "Phase 2 (end): \n"

echo -e "Copy DART necessary files  in the tmp working dir"
mkdir $tmpdir
${MOVE} ${maindir}/input.nml ${tmpdir}/.
#${MOVE} ${maindir}/Blacklist.txt ${tmpdir}/.   # copied in cases_assimilate.csh
${COPY} ${tmpdir}/input.nml ${tmpdir}/input.nml.original
${COPY} ${dartroot}/d4o/flattened/cam-fv/filter.dir/filter ${tmpdir}/.
${COPY} ${dartroot}/d4o/flattened/cam-fv/fill_inflation_restart.dir/fill_inflation_restart  ${tmpdir}/.
${COPY} ${dartroot}/d4o/flattened/screening/*screening.x ${tmpdir}/.

${COPY} ${dartroot}/d4o/flattened/utility/sampling_error_correction_table.nc ${tmpdir}/.
${COPY} ${dartroot}/d4o/scripts/d4ojoin* ${tmpdir}/.
${COPY} ${dartroot}/d4o/scripts/d4ocatalog ${tmpdir}/.
${COPY} ${dartroot}/d4o/scripts/d4ofixtoc ${tmpdir}/.

echo " Copy RTTOV db file"
${COPY} ${dartroot}/d4o/flattened/utility/rttov_sensor_db.csv ${tmpdir}/.
${COPY} ${dartroot}/d4o/ECMWF/rttov123/rtcoef_rttov12/rttov7pred54L/*  ${tmpdir}/.
${COPY} ${dartroot}/d4o/ECMWF/rttov123/rtcoef_rttov12/rttov7pred101L/*  ${tmpdir}/.

# Inside the TMP dir we need to create time-slots dir that will contain copy of the filter and links to the other needed files
ts=1
while (($ts<= $nts))
do
   echo -e "time slot creation: TS= $ts"
   tsname="TS$ts"
   mkdir $tmpdir/$tsname

   # Copy and link all the necessary files
   ${COPY} $tmpdir/input.nml $tmpdir/${tsname}/input.nml 

   # Let cases_cycles decide how to change the namelist parameters compute_posterior, stages_to_write

#   # Check if central ts and prepare the input.nml accordingly
#   if [ ${ts} -eq ${tcentral} ] 
#     then
#      echo "central time slot\n"
#      # for the central we can ask or not not for the forecast, we decide it at the beginning before running cases_create when we prepare the input namelist
#   else
#      echo "non central time slot, remove forecast from input.nml output\n" 
#     # for non central timeslot we do not want forecast
#     infield=`grep stages_to_write $tmpdir/${tsname}/input.nml | grep =`
#     sed -i "s/${infield}/stages_to_write = 'output'/g" $tmpdir/${tsname}/input.nml
#   fi 

   # Copy filter and fill_inflation_restart
   ${COPY} $dartroot/d4o/flattened/cam-fv/filter.dir/filter $tmpdir/$tsname/.
   # fill_inflation_restart is not needed because teh computation is done inside the TMPROOT
   #${COPY} $dartroot/d4o/flattened/cam-fv/fill_inflation_restart.dir/fill_inflation_restart $tmpdir/$tsname/.
   
   # Link support files and tables for filter
   #${LINK} -f $dartroot/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc    $tmpdir/$tsname/.    
   #${LINK} -f $dartroot/observations/forward_operators/rttov_sensor_db.csv    $tmpdir/$tsname/.    
   #${LINK} -f ${rttovdir}/rtcoef_rttov12/rttov7pred54L/rtcoef_eos_2_amsua.dat    $tmpdir/$tsname/.    
   # Copy is better maybe, so we avoid possible concurrent reading
   ${COPY}  ${dartroot}/d4o/flattened/utility/sampling_error_correction_table.nc    $tmpdir/$tsname/.    
   ${COPY}  ${dartroot}/d4o/flattened/utility/rttov_sensor_db.csv    $tmpdir/$tsname/.    
   ${COPY}  ${dartroot}/d4o/ECMWF/rttov123/rtcoef_rttov12/rttov7pred54L/*    $tmpdir/$tsname/.    
   ${COPY}  ${dartroot}/d4o/ECMWF/rttov123/rtcoef_rttov12/rttov7pred101L/*    $tmpdir/$tsname/.    

   ((ts++))
done



echo -e "\n Modify case_assimilate.sh using the right number of nodes! TO DO!!!!\n"


echo -e "\n END EXPERIMENT CREATION \n"
exit 0
