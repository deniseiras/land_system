#!/bin/bash


# Take the name of the experiment to check the time of the last assimilation cycle
EXPNAME=$1
NENS=$2
FENS=$3
FSOI_Jo=$4
FDAYS=$5


# CESMDIR is defined in .bashrc


# DO NOT CHANGE THESE VARS! If you want have a more flexible code set them in bashrc or 
# read them from cases_create since it needs to know some of them for the initial cleaning
MAINCONTAINER=/users_home/cmcc/${USER}/${CESMEXP}
CASESCONTAINERF=/work/cmcc/${USER}/${CESMEXP}
#CASESCONTAINER=/work/cmcc/${USER}/CESM2
CASESCONTAINER=/work/cmcc/${USER}/CMCC-CM
ARCHIVE=${CASESCONTAINER}/archive

# 4 cycles per days the i.c. must be included!
FSAVE=`echo "${FDAYS}*4 + 1" | bc -l`

LINK='/usr/bin/ln -s'




echo -e "\n START FORECAST PROCEDURE \n"


echo " Forecast cases container dir = $CASESCONTAINERF"
echo " Container dir = $CASESCONTAINER"
echo " Archive dir = $ARCHIVE"
echo " Experiment name = $EXPNAME"
echo " Numeber of instances = $NENS"
echo " Number of forecast members = $FENS"
echo " Number of forecast days = $FDAYS"
echo " Output for FSOI_Jo = $FSOI_Jo"


# Check that FENS<=NENS
if ((${FENS}>${NENS}))
 then
    echo " ERROR: the number of forecast members can not be bigger than the EnKF ensemble, "
    echo "        set FENS to $NENS "
    FENS=${NENS}
    echo " FENS = ${FENS}"
fi

# Check that FDAYS is not less than 1
if ((${FDAYS}<1))
  then
    echo " ERROR: the number of forecast days is wrong, it can not be less than 1 day, "
    echo "        set FDAYS to 1 "
    FDAYS=1
fi

echo " "
echo " Check time of the last assimilation cycle"
# If 00Z or 12Z do the forecast, otherwise skip at the end doing nothing
lcycle=`ls -ltr ${ARCHIVE}/${EXPNAME} | tail -1 | awk '{print $(NF)}'`
yy=`echo $lcycle | cut -d'-' -f2`
mm=`echo $lcycle | cut -d'-' -f3`
dd=`echo $lcycle | cut -d'-' -f4`
ss=`echo $lcycle | cut -d'-' -f5`
date="${yy}-${mm}-${dd}-${ss}"
echo " Last assimilation cycle time (s): ${ss}"
#if (( ${ss}==00000 )) || (( ${ss}==43200))
if (( ${ss}==00000 )) || (( ${ss}==21600 )) || (( ${ss}==43200 )) || (( ${ss}==64800 ))  
 then
    echo " Time correct, create the forecast experiment"

    # Create the forecast experiment in the work dir.
    # Home dir has not enough space. 

    # If not already present create a directory containing the forecast cases
    echo " Create the forecast container if not present"
    mkdir -p ${CASESCONTAINERF}/${EXPNAME}-forecast 

    # Then clone the main experiment
    inst=1
    while (($inst<= $FENS))
      do
       echo -e " "
       echo -e " forecast member $inst\n"

       # Following the CESM strategy for 'inst_string'
       inst_string=`printf _%04d $inst`
       new_case="${CASESCONTAINERF}/${EXPNAME}-forecast/${EXPNAME}_f${inst_string}-${date}"
       new_case_run=${CASESCONTAINER}/${EXPNAME}_f${inst_string}-${date}
       casemain="${MAINCONTAINER}/${EXPNAME}/${EXPNAME}${inst_string}"  

       # Remove old dir if necessary
       if [ -d "${new_case}" ]; then rm -Rf ${new_case}; fi
       if [ -d "${new_case_run}" ]; then rm -Rf ${new_case_run}; fi

       # Create the clone 
       ${MODEL_PATH}/${CESMDIR}/cime/scripts/create_clone  \
               --case     $new_case          \
               --clone    $casemain          \

       # Change the simulation parameters: i.c., output frequency, simulation lenght   
       cd $new_case
       
       RUNDIR=`./xmlquery RUNDIR       --value`
       stagedir=${CASESCONTAINER}/${EXPNAME}${inst_string}/run

       # Remove the wrong i.c. for land
       sed -i '/finidat/d' ./user_nl_clm
       # Write the correct i.c. for land
       echo "finidat='${EXPNAME}${inst_string}.clm2.r.${date}.nc'">> user_nl_clm
       # Remove the wrong i.c. for rivers
       sed -i '/finidat_hydros/d' ./user_nl_hydros
       # Write the correct i.c. for rivers
       echo "finidat_hydros='${EXPNAME}${inst_string}.hydros.r.${date}.nc'">> user_nl_hydros
       # Remove the wrong i.c. for cice
       sed -i '/ice_ic/d' ./user_nl_cice
       # Write the correct i.c. for cice
       echo "ice_ic='${EXPNAME}${inst_string}.cice.r.${date}.nc'">> user_nl_cice
       # We consider the experiment as an hybrid since we cloned an hybrid
       # the initial condition can be considered cam_initial_XXXX we just need to link the correct one


       # Add timing in cice namelist
       echo "sec_init=${ss}">> user_nl_cice
       echo "day_init=${dd}">> user_nl_cice
       echo "month_init=${mm}">> user_nl_cice
       echo "year_init=${yy}">> user_nl_cice

       ./preview_namelists || exit 75
       
       # Link the correct i.c.
       echo " Staging initial files for instance $inst"
     
       cd $RUNDIR

       ${LINK} -f ${stagedir}/${EXPNAME}${inst_string}.clm2.r.${date}.nc  .
       ${LINK} -f ${stagedir}/${EXPNAME}${inst_string}.cice.r.${date}.nc  .
       # cam_initial_XXXX is now our analysis field for the atmosphere
       ${LINK} -f ${stagedir}/${EXPNAME}${inst_string}.cam.i.${date}.nc   cam_initial${inst_string}.nc
       ${LINK} -f ${stagedir}/${EXPNAME}${inst_string}.hydros.r.${date}.nc . 
       
       cd $new_case
       # Change other xml and namelist settings
       # assimilation is off we do not read every time from ncdata
       ./xmlchange DATA_ASSIMILATION_ATM=FALSE
       ./xmlchange CONTINUE_RUN=FALSE


       # if FSOI_Jo is not required we do not need of cam.i 
       if [[ ${FSOI_Jo} == "FALSE" ]]; then
          echo "FSOI_Jo is FALSE we do not need *cam.i* output"
          sed -i '/inithist/d' ./user_nl_cam 
          echo "inithist='NONE'" >> ./user_nl_cam
       else
          echo "FSOI_Jo is TRUE we do need *cam.i* output"
          sed -i '/inithist/d' ./user_nl_cam 
          echo "inithist='ENDOFRUN'" >> ./user_nl_cam
          sed -i '/inithist_all/d' ./user_nl_cam 
          echo "inithist_all      = .true." >> ./user_nl_cam
       fi    
     
       # only variables in  .h0 file in output
       sed -i '/fincl2/d' ./user_nl_cam 
       sed -i '/fincl1/d' ./user_nl_cam 
       sed -i '/nhtfrq/d' ./user_nl_cam 
       sed -i '/mfilt/d' ./user_nl_cam 
       echo "fincl1='PHIS:I','T:I','U:I','V:I','Q:I','PS:I','PSL:I','Z500:I','T850:I'">> ./user_nl_cam
       echo "nhtfrq=-6">> ./user_nl_cam
       echo "mfilt=${FSAVE}">> ./user_nl_cam

       # rest options, no restart file in output
       ./xmlchange RUN_REFDIR=${stagedir}
       ./xmlchange RUN_REFCASE=${EXPNAME}
       ./xmlchange RUN_REFDATE=${yy}-${mm}-${dd}
       ./xmlchange RUN_REFTOD=${ss}
       ./xmlchange RUN_STARTDATE=${yy}-${mm}-${dd}
       ./xmlchange START_TOD=${ss}
       
       ./xmlchange STOP_OPTION=ndays
       ./xmlchange STOP_N=${FDAYS}
       ./xmlchange REST_OPTION=none
       #./xmlchange REST_N=6

    
       # modify clm output
       sed -i '/hist_nhtfrq/d' ./user_nl_clm 
       sed -i '/hist_mfilt/d' ./user_nl_clm
       echo "hist_nhtfrq=-6">> ./user_nl_clm
       echo "hist_mfilt=${FSAVE}">> ./user_nl_clm
      

       # change the queue
       ./xmlchange JOB_QUEUE=p_medium
       ./xmlchange JOB_WALLCLOCK_TIME="4:00" 


       # Change the executable 
       echo ''
       echo 'Copy executable'
       echo ''

       ./xmlchange --file env_build.xml --id BUILD_COMPLETE --val TRUE
       ./xmlchange --file env_build.xml --id BUILD_STATUS --val 0
       cp ${CASESCONTAINER}/${EXPNAME}${inst_string}/bld/cesm.exe  ${RUNDIR}/../bld/cesm.exe

       grep -rl "/work/data" . | xargs sed -i 's@\/work\/data@\/data@g'

       # Run the forecast
       echo " Run forecast${inst_string}"
       ./case.submit

     ((inst++))
    done 

fi





echo -e "\n END FORECAST PROCEDURE \n"

