#!/bin/csh
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


# HISTORY
#
# author            version     comments
# Luis Gustavo      none        Original version
# Denis Eiras       1.0.0       Paralelized version - firtst github version

# set verbose
# set echo

echo "`date` -- BEGIN CLM_ASSIMILATE_EXECUTOR benchmark"

echo "Running assimilation executor with params:"
echo "CASE: ${CASE}, ENSEMBLE_SIZE: ${ENSEMBLE_SIZE}, TOTALPES: ${TOTALPES}, TASKS_PER_NODE: ${TASKS_PER_NODE}"
echo "CASEROOT: ${CASEROOT}"
echo "ASSIMILATION_CYCLE: ${ASSIMILATION_CYCLE}"

source ${CASEROOT}/DART_params.csh || exit 1

module purge
unset LIBRARY_PATH

if ( "$machine" == "juno" ) then
   module load --auto intel-2021.6.0/2021.6.0
   module load --auto intel-2021.6.0/libszip/2.1.1-tvhyi
   module load --auto impi-2021.6.0/2021.6.0
   module load --auto anaconda/3-2022.10
   module load --auto intel-2021.6.0/sqlite/3.40.0-v3tky
   module load --auto intel-2021.6.0/perl-dbi/1.643-3satl
   module load --auto intel-2021.6.0/perl-dbd-sqlite/1.72-3f7xn
   module load --auto intel-2021.6.0/jasper/2.0.32-rofnd
   module load --auto intel-2021.6.0/libjpeg-turbo/2.1.4-tk73d
   setenv LIBRARY_PATH ":$LD_LIBRARY_PATH" # without this line the build.juno does not find -ljpeg f.ex.
else  # cassandra
   # TODO - parametrize this
   source /work/cmcc/de34824/spreads/d4o/load-modules-d4o.cassandra
endif
module -t list
   


# Python uses C indexing on loops; cycle = [0,....,$DATA_ASSIMILATION_CYCLES - 1]
# "Fix" that here, so the rest of the script isn't confusing.
@ cycle = $ASSIMILATION_CYCLE + 1

# xmlquery must be executed in $CASEROOT.
cd ${CASEROOT}
setenv CASE           `./xmlquery CASE        --value`
setenv ENSEMBLE_SIZE  `./xmlquery NINST_LND   --value`
setenv EXEROOT        `./xmlquery EXEROOT     --value`
setenv RUNDIR         `./xmlquery RUNDIR      --value`
setenv ARCHIVE        `./xmlquery DOUT_S_ROOT --value`
setenv TOTALPES       `./xmlquery TOTALPES    --value`
setenv STOP_N         `./xmlquery STOP_N      --value`
setenv DATA_ASSIMILATION_CYCLES `./xmlquery DATA_ASSIMILATION_CYCLES --value`
setenv TASKS_PER_NODE `./xmlquery MAX_TASKS_PER_NODE --value`

# Most of this syntax can be determined from CASEROOT  ./preview_run
setenv MPI_RUN_COMMAND "mpiexec_mpt -np $TOTALPES omplace -tm open64"

cd ${RUNDIR}

#=========================================================================
# Block 1: Determine time of model state ... from file name of first member
# of the form "./${CASE}.clm2_${ensemble_member}.r.2000-01-06-00000.nc"
#
# Piping stuff through 'bc' strips off any preceeding zeros.
#=========================================================================

set FILE = `head -n 1 rpointer.lnd_0001`
set FILE = $FILE:r
set LND_DATE_EXT = `echo $FILE:e`
set LND_DATE     = `echo $FILE:e | sed -e "s#-# #g"`
set LND_YEAR     = `echo $LND_DATE[1] | bc`
set LND_MONTH    = `echo $LND_DATE[2] | bc`
set LND_DAY      = `echo $LND_DATE[3] | bc`
set LND_SECONDS  = `echo $LND_DATE[4] | bc`
set LND_HOUR     = `echo $LND_DATE[4] / 3600 | bc`

echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_SECONDS (seconds)"
echo "valid time of model is $LND_YEAR $LND_MONTH $LND_DAY $LND_HOUR (hours)"

#=========================================================================
# Block 2: Get observation sequence file ... or die right away.
#=========================================================================

# The observation file names have a time that matches the stopping time of CLM.
#
# The CLM observations are stored in two sets of directories.
# If you are stopping every 24 hours or more, the obs are in directories like YYYYMM.
# In all other situations the observations come from directories like YYYYMM_6H.
# The only ugly part here is if the first advance and subsequent advances are
# not the same length. The observations _may_ come from different directories.
#
# The contents of the file must match the history file contents if one is using
# the obs_def_tower_mod or could be the 'traditional' +/- 12Z ... or both.
# Since the history file contains the previous days' history ... so must the obs file.

if ($STOP_N >= 24) then
   set OBSDIR = `printf %04d%02d    ${LND_YEAR} ${LND_MONTH}`
else
   set OBSDIR = `printf %04d%02d_6H ${LND_YEAR} ${LND_MONTH}`
endif

set OBS_FILE = ${baseobsdir}/obs_seq.${LND_DATE_EXT}

${REMOVE} obs_seq.out

if (  -e   ${OBS_FILE} ) then
   ${LINK} ${OBS_FILE} obs_seq.out || exit 2
else
   echo "ERROR ... no observation file $OBS_FILE"
   echo "ERROR ... no observation file $OBS_FILE"
   #LGG exit 2
endif

set dens = `printf %02d    ${ENSEMBLE_SIZE}`
set dpart = `printf %04d"-"%02d"-"%02d    ${LND_YEAR} ${LND_MONTH} ${LND_DAY}`

# TODO check / improve ddir
# JUNO - EXPS > 2003 must use the spreads-lnd dir -- confirm that cassandra uses lg07622 data below - not copied yet frim spreads-lnd
# set ddir = /work/cmcc/lg07622/land/datain/d4o/datastore/ens_${dens}/${dpart}
if ( $machine | grep juno > /dev/null ) then
   set ddir = /work/cmcc/spreads-lnd/land/datain/d4o/datastore/ens_${dens}/${dpart}
else
   set ddir = /work/cmcc/de34824/land/datain/d4o/datastore/ens_${dens}/${dpart}
endif


echo ${ddir}
ls ${ddir}/*.db

${COPY} ${ddir}/*.db .


#=========================================================================
# Block 3: Populate a run-time directory with the input needed to run DART.
#=========================================================================

echo "`date` -- BEGIN COPY BLOCK"

if (  -e   ${CASEROOT}/input.nml ) then
   ${COPY} ${CASEROOT}/input.nml .
else
   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
   echo "ERROR ... DART required file ${CASEROOT}/input.nml not found ... ERROR"
   exit 3
endif

echo "`date` -- END COPY BLOCK"

# If possible, use the round-robin approach to deal out the tasks.

if ($?TASKS_PER_NODE) then
   if ($#TASKS_PER_NODE > 0) then
      ${COPY} input.nml input.nml.$$
      sed -e "s#layout.*#layout = 2#" \
          -e "s#tasks_per_node.*#tasks_per_node = $TASKS_PER_NODE#" input.nml.$$ >! input.nml
      ${REMOVE} input.nml.$$
   endif
endif

echo "`date` -- BEGIN INFLATION benchmark"

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
#==========================================================================

set     LND_RESTART_FILENAME = ${CASE}.clm2_0001.r.${LND_DATE_EXT}.nc
set     LND_HISTORY_FILENAME = ${CASE}.clm2_0001.h0.${LND_DATE_EXT}.nc
set LND_VEC_HISTORY_FILENAME = ${CASE}.clm2_0001.h2.${LND_DATE_EXT}.nc

# remove any potentially pre-existing links
unlink clm_restart.nc
unlink clm_history.nc
unlink clm_vector_history.nc

${LINK} ${LND_RESTART_FILENAME} clm_restart.nc || exit 4
${LINK} ${LND_HISTORY_FILENAME} clm_history.nc || exit 4
if (  -s   ${LND_VEC_HISTORY_FILENAME} ) then
   ${LINK} ${LND_VEC_HISTORY_FILENAME} clm_vector_history.nc || exit 4
endif

# fill_inflation_restart creates files for all the domains in play,
# with names like input_priorinf_[mean,sd]_d0?.nc These should be renamed
# to be similar to what is created during the cycling. fill_inflation_restart
# only takes a second and only runs once.

if ( -e clm_inflation_cookie ) then

echo "Runninng  fill_inflation_restart"
   #${EXEROOT}/fill_inflation_restart || exit  4
./run_inflation.bash
if ($status != 0) then
    echo "ERROR: fill_inflation_restart failed"
    exit 1
endif
   
echo "End running  fill_inflation_restart"

   foreach FILE ( input_priorinf_*.nc )
      set NEWBASE = `echo $FILE:r | sed -e "s#input#output#"`
      ${MOVE} ${FILE} clm_${NEWBASE}.1601-01-01-00000.nc
   end

   # Make sure this only happens once. Eat the cookie.
   ${REMOVE} clm_inflation_cookie

   # To help keep track of the most recent inflation file,
   # create a 'pointer file' to hold the name of the most recent.

   @ domaincount = 0
   foreach FILE ( clm_output_priorinf_mean*.nc )

      @ domaincount ++

      set POINTERFILE = `printf priorinf_pointer_d%02d.txt $domaincount`

      set SDFILE = `echo $FILE | sed -e "s#mean#sd#"`

      echo $FILE   >! $POINTERFILE
      echo $SDFILE >> $POINTERFILE

   end

   # Not supporting posterior inflation at this time.
   ${REMOVE} input_postinf*nc

endif

# We have to potentially deal with files like:
# clm_output_priorinf_mean_d01.${LND_DATE_EXT}.nc
# clm_output_priorinf_mean_d02.${LND_DATE_EXT}.nc
# clm_output_priorinf_mean_d03.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d01.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d02.${LND_DATE_EXT}.nc
# clm_output_priorinf_sd_d03.${LND_DATE_EXT}.nc


# Check to see if inflation is being used.

set  MYSTRING = `grep inf_flavor input.nml`
set  MYSTRING = `echo $MYSTRING | sed -e "s#[=,'\.]# #g"`
set  PRIOR_INF = $MYSTRING[2]
set  POSTE_INF = $MYSTRING[3]

if ( $PRIOR_INF != 0 ) then

   # CLM always has at least two domains, but may sometimes have three.
   # Link to the new expected name, if the file does not exist, filter will
   # die and issue a very explicit death message.

   ${REMOVE} input_priorinf_mean*.nc input_priorinf_sd*.nc

   @ domaincount = 1

   foreach POINTERFILE ( priorinf_pointer*.txt )

      set DOMAIN = `printf _d%02d $domaincount`
      set INPUT  =  input_priorinf_mean_${DOMAIN}
      set OUTPUT = output_priorinf_mean_${DOMAIN}

      set latest_mean = `head -n 1 $POINTERFILE`
      set latest_sd   = `tail -n 1 $POINTERFILE`

      # Create the expected output inflation file.
      # The NO_COPY_BACK variables that are part of the DART vector
      # need to have inflation values. 
      ${COPY} ${latest_mean} output_priorinf_mean${DOMAIN}.nc
      ${COPY} ${latest_sd}   output_priorinf_sd${DOMAIN}.nc

      ${LINK} ${latest_mean} input_priorinf_mean${DOMAIN}.nc
      ${LINK} ${latest_sd}   input_priorinf_sd${DOMAIN}.nc

      @ domaincount ++

   end

endif

if ( $POSTE_INF != 0 ) then
   echo "ERROR: assimilate.csh not configured to cycle with posterior inflation."
   exit 4
endif

echo "`date` -- END INFLATION benchmark"

echo "`date` -- BEGIN CLM_TO_DART benchmark"
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

./run_clm_to_dart_par.bash $CASE $LND_DATE_EXT $ENSEMBLE_SIZE $RUNDIR
if ($status != 0) then
    echo "ERROR: clm_to_dart failed"
    exit 1
endif

echo "`date` -- END CLM_TO_DART benchmark"

#=========================================================================
# Block 6: Actually run the assimilation.
#=========================================================================

echo "`date` -- BEGIN FILTER benchmark"
#${MPI_RUN_COMMAND} ${EXEROOT}/filter || exit 6
./run_filter.bash
if ($status != 0) then
    echo "ERROR: filter failed"
    exit 1
endif
echo "`date` -- END FILTER benchmark"


#=========================================================================
# Block 7: Put the DART posterior into the CLM restart file. The CLM
# restart file is also the prior for the next forecast.
#=========================================================================
# Unlink any potentially pre-existing links
unlink clm_restart.nc
unlink dart_posterior.nc

# Identify if SWE re-partitioning is necessary
set  REPARTITION = `grep repartition_swe input.nml`
set  REPARTITION = `echo $REPARTITION | sed -e "s/repartition_swe//g"`
set  REPARTITION = `echo $REPARTITION | sed -e "s/=//g"`

echo "`date` -- BEGIN DART_TO_CLM benchmark"

if ($REPARTITION != 0) then
unlink clm_vector_history   

     #${EXEROOT}/dart_to_clm >& /dev/null
     ./run_dart_to_clm_snow.bash ${CASE} ${LND_DATE_EXT}

     if ($status != 0) then
        echo "ERROR: dart_to_clm failed for ..."
        exit 7
     endif
     
     foreach LIST (clm_restart.nc clm_vector_history.nc dart_posterior.nc \
              dart_posterior_vector.nc )

             unlink $LIST
     end

else

   foreach RESTART ( ${CASE}.clm2_*.r.${LND_DATE_EXT}.nc )

      set POSTERIOR = `echo $RESTART | sed -e "s/${CASE}.//"`

      ${LINK} $POSTERIOR dart_posterior.nc
      ${LINK} $RESTART   clm_restart.nc

      #${EXEROOT}/dart_to_clm >& /dev/null
      ./run_dart_to_clm.bash
      if ($status != 0) then
         echo "ERROR: dart_to_clm failed for $RESTART"
         exit 8
      endif

      unlink dart_posterior.nc
      unlink clm_restart.nc
   end

endif

# Remove the copies that we no longer need. The posterior values are
# in the DART diagnostic files for the appropriate 'stage'.
\rm -f clm2_*.r.${LND_DATE_EXT}.nc
\rm -f clm2_*.h0.${LND_DATE_EXT}.nc
\rm -f clm2_*.h2.${LND_DATE_EXT}.nc

echo "`date` -- END DART_TO_CLM benchmark"

#=========================================================================
# Block 8: Archive the results and prepare pointer inflation files for
# next cycle. Tag the output with the valid time of the model state.
#=========================================================================

# TODO could move each ensemble-member file to the respective member dir.

foreach FILE ( input*mean*nc      input*sd*nc     input_member*nc \
            forecast*mean*nc   forecast*sd*nc  forecast_member*nc \
            preassim*mean*nc   preassim*sd*nc  preassim_member*nc \
           postassim*mean*nc  postassim*sd*nc postassim_member*nc \
            analysis*mean*nc   analysis*sd*nc  analysis_member*nc \
              output*mean*nc     output*sd*nc )

   if (  -e $FILE ) then
      set FEXT  = $FILE:e
      set FBASE = $FILE:r
      ${MOVE} $FILE clm_${FBASE}.${LND_DATE_EXT}.${FEXT}
   endif
end

# Tag the DART observation file with the valid time of the model state.

${MOVE} obs_seq.final    clm_obs_seq.${LND_DATE_EXT}.final
${MOVE} dart_log.out     clm_dart_log.${LND_DATE_EXT}.out

echo "Updating inflation pointer files."

@ domaincount = 0
foreach FILE ( clm_output_priorinf_mean*.${LND_DATE_EXT}.nc )
   @ domaincount ++
   set POINTERFILE = `printf priorinf_pointer_d%02d.txt $domaincount`
   set SDFILE = `echo $FILE | sed -e "s#mean#sd#"`
   echo $FILE   >! $POINTERFILE
   echo $SDFILE >> $POINTERFILE
end

#-------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------

${MOVE} ${RUNDIR}/*.db ${RUNDIR}/tmp/.

echo "`date` -- END CLM_ASSIMILATE_EXECUTOR benchmark"

exit 0



