#!/bin/bash
#
dorigin=/work/cmcc/spreads-lnd/work_dart/DART/models/clm/shell_scripts/cesm2_3/spreads/d4o
dd4o=/work/cmcc/spreads-lnd/spreads/d4o/flattened/clm
dobs=/work/cmcc/lg07622/land/datain/d4o
firstda="2000-01-02"
nens=30
droot=`pwd`
adopt="all" # sm scg lai all
echo $droot

./CESM_DART_config
./xmlchange CONTINUE_RUN=TRUE
cp -f ${dorigin}/assimilate.csh ${droot}/.
cp -f ${dorigin}/assimilate_bogus.csh ${droot}/.
cp -f ${dorigin}/input.nml_${adopt} ${droot}/input.nml

cp -f ${dorigin}/run_clm_to_dart_par.bash ${droot}/run/.
cp -f ${dorigin}/run_dart_to_clm.bash ${droot}/run/.
cp -f ${dorigin}/run_filter.bash ${droot}/run/.
cp -f ${dorigin}/run_inflation.bash ${droot}/run/.

cp -f ${dd4o}/clm_to_dart.dir/clm_to_dart ${droot}/run/.
cp -f ${dd4o}/dart_to_clm.dir/dart_to_clm ${droot}/run/.
cp -f ${dd4o}/fill_inflation_restart.dir/fill_inflation_restart ${droot}/run/.
cp -f ${dd4o}/filter.dir/filter ${droot}/run/.

if [ $adopt == "scg" -o $adopt == "all" ]; then
  echo "Assimilating snow cover fraction"
  cp -f ${dorigin}/run_dart_to_clm_snow.bash ${droot}/run/.
  cp -f ${dorigin}/assimilate_par.csh ${droot}/assimilate.csh
  #if [ ! -d ${droot}/run/tmp ]; then mkdir ${droot}/run/tmp; fi
fi

#create first obs dataset

if [ -d ${dobs}/datastore/${firstda} ]; then

cp -f ${dobs}/datastore/${firstda}/*.db ${droot}/run/.

fi

if [ ! -d ${droot}/run/tmp ]; then mkdir ${droot}/run/tmp; fi

cd ${droot}

./xmlchange DATA_ASSIMILATION_LND=TRUE
./xmlchange DATA_ASSIMILATION_CYCLES=1
./xmlchange DATA_ASSIMILATION_SCRIPT=${droot}/assimilate.csh

touch ${droot}/run/clm_inflation_cookie


