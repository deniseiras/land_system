#!/bin/ksh -x

case_name=$1
nens=$2
datahome=$(pwd)
cd /work/cmcc/${USER}/CMCC-CM/archive/${case_name}
for dir in $(ls -d  ${case_name}-*);do

    cd $datahome

    dt=$(echo $dir | sed "s/${case_name}\-//g")

    # if [ ! -f /work/cmcc/${USER}/CMCC-CM/basic_diag/${case_name}/${dt}/metrics.pickle ];
    # if [ ! -f /work/cmcc/${USER}/CMCC-CM/basic_diag/${case_name}/${dt}/utest_all.npz ];
    if [ ! -f /work/cmcc/${USER}/CMCC-CM/basic_diag/${case_name}/${dt}/assimilated_global.feather_ ];
    then
        mkdir -p src/${case_name}/$dt
        cp -f quick_spreads_diag_exec.bash quick_spreads_diag.py src/${case_name}/$dt/
        cd src/${case_name}/$dt
        sed -i "s/assim_date/'$dt'/g" quick_spreads_diag.py
        sed -i "s@mg20022@${USER}@g" quick_spreads_diag.py
        sed -i "s@NENS@${nens}@g" quick_spreads_diag.py

        sed -i "s/case_name/${case_name}_${dt}/g" quick_spreads_diag_exec.bash
        sed -i "s@NOME@'${case_name}'@g" quick_spreads_diag.py
        bsub < quick_spreads_diag_exec.bash
        # ./quick_spreads_diag_exec.bash
        # sleep 1
        # python quick_spreads_diag.py
        # exit
    else
        echo "SKIP ${case_name} ${dt}"
        # sleep 1
    fi
    # exit

done


echo "FINISH $(date)"


# spreads-2017-10-02-64800 spreads-2017-10-03-00000 spreads-2017-10-03-21600 spreads-2017-10-03-43200 spreads-2017-10-03-64800 spreads-2017-10-04-00000 spreads-2017-10-04-21600 spreads-2017-10-04-43200 spreads-2017-10-04-64800 spreads-2017-10-05-00000 spreads-2017-10-05-21600 spreads-2017-10-05-43200 spreads-2017-10-05-64800 spreads-2017-10-06-00000 spreads-2017-10-06-21600 spreads-2017-10-06-43200 spreads-2017-10-06-64800 spreads-2017-10-07-00000 spreads-2017-10-07-21600 spreads-2017-10-07-43200 spreads-2017-10-07-64800 spreads-2017-10-08-00000 spreads-2017-10-08-21600 spreads-2017-10-08-43200 spreads-2017-10-08-64800 spreads-2017-10-09-00000 spreads-2017-10-09-21600 spreads-2017-10-09-43200 spreads-2017-10-09-64800 spreads-2017-10-10-00000 spreads-2017-10-10-21600 spreads-2017-10-10-43200 spreads-2017-10-10-64800 spreads-2017-10-11-00000 spreads-2017-10-11-21600 spreads-2017-10-11-43200 spreads-2017-10-11-64800 spreads-2017-10-12-00000 spreads-2017-10-12-21600 spreads-2017-10-12-43200 spreads-2017-10-12-64800 spreads-2017-10-13-00000 spreads-2017-10-13-21600 spreads-2017-10-13-43200 spreads-2017-10-13-64800 spreads-2017-10-14-00000 spreads-2017-10-14-21600 spreads-2017-10-14-43200 spreads-2017-10-14-64800 spreads-2017-10-15-00000 spreads-2017-10-15-21600 spreads-2017-10-15-43200 spreads-2017-10-15-64800 spreads-2017-10-16-00000 spreads-2017-10-16-21600 spreads-2017-10-16-43200 spreads-2017-10-16-64800 spreads-2017-10-17-00000 spreads-2017-10-17-21600 spreads-2017-10-17-43200 spreads-2017-10-17-64800 spreads-2017-10-18-00000 spreads-2017-10-18-21600 spreads-2017-10-18-43200 spreads-2017-10-18-64800 spreads-2017-10-19-00000 spreads-2017-10-19-21600 spreads-2017-10-19-43200 spreads-2017-10-19-64800 spreads-2017-10-20-00000 spreads-2017-10-20-21600 spreads-2017-10-20-43200 spreads-2017-10-20-64800 spreads-2017-10-21-00000 spreads-2017-10-21-21600 spreads-2017-10-21-43200 spreads-2017-10-21-64800 spreads-2017-10-22-00000
