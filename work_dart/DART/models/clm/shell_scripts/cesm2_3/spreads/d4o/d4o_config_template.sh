#!/bin/bash

# The land_system_work was created to work with the structure below:
# 
# Source files
# .
# ├── CMCC-CM
# │   ├── ccs_config
# │   ├── cime_config
# │   └── ...
# ├── land
# │   └── datain
# ├── spreads
# │   ├── d4o
# │   ├── spreads_ui
# │   └── ...
# ├── work_d4o
# └── work_dart
#     └── DART

# Install files
# /data
# └──cmcc
#     └──<USER>
#         └──<BRANCH>
#             └──install


# Change the 4 parameters below accordingly your necessities
# ==========================================================
firstda="2000-01-02"
nens="04" #number of members
droot=`pwd`
adopt="all" # sm scg lai all
set -x
# ==========================================================

land_system_root_dir=/work/cmcc/$USER/land_system
dobs=${land_system_root_dir}/land/datain/d4o
dd4o=${land_system_root_dir}/spreads/d4o/flattened/clm
dorigin=${land_system_root_dir}/work_dart/DART/models/clm/shell_scripts/cesm2_3/spreads/d4o


echo $droot

./CESM_DART_config
./xmlchange CONTINUE_RUN=TRUE

# The files below were updated for Cassandra. In Juno, the files comes from 
# the repository PROFESSIONAL_land_assimilate_opt.git.
# In the future, maybe the PROFESSIONAL_land_assimilate_opt.git must be ignored and
# this repository (land_system) must be used as the main repository for the assimilation 
# scripts for JUNO and Cassandra.

cp -f ${dorigin}/assimilate.csh ${droot}/.
cp -f ${dorigin}/assimilate_executor.csh ${droot}/.
cp -f ${dorigin}/run_clm_to_dart_par.bash ${droot}/run/.
cp -f ${dorigin}/run_dart_to_clm.bash ${droot}/run/.
cp -f ${dorigin}/run_filter.bash ${droot}/run/.
cp -f ${dorigin}/run_inflation.bash ${droot}/run/.

cp -f ${dorigin}/assimilate_bogus.csh ${droot}/.
cp -f ${dorigin}/input.nml_${adopt} ${droot}/input.nml


cp -f ${dd4o}/clm_to_dart.dir/clm_to_dart ${droot}/run/.
cp -f ${dd4o}/dart_to_clm.dir/dart_to_clm ${droot}/run/.
cp -f ${dd4o}/fill_inflation_restart.dir/fill_inflation_restart ${droot}/run/.
cp -f ${dd4o}/filter.dir/filter ${droot}/run/.

if [ $adopt == "scg" -o $adopt == "all" ]; then
  echo "Assimilating snow cover fraction"
  cp -f ${dorigin}/run_dart_to_clm_snow.bash ${droot}/run/.
  # cp -f ${dorigin}/assimilate_par.csh ${droot}/assimilate.csh
  #if [ ! -d ${droot}/run/tmp ]; then mkdir ${droot}/run/tmp; fi
fi

#create first obs dataset

if [ -d ${dobs}/datastore/ens_${nens}/${firstda} ]; then

cp -f ${dobs}/datastore/ens_${nens}/${firstda}/*.db ${droot}/run/.

fi

if [ ! -d ${droot}/run/tmp ]; then mkdir ${droot}/run/tmp; fi

cd ${droot}

./xmlchange DATA_ASSIMILATION_LND=TRUE
./xmlchange DATA_ASSIMILATION_CYCLES=1
./xmlchange DATA_ASSIMILATION_SCRIPT=${droot}/assimilate.csh

touch ${droot}/run/clm_inflation_cookie