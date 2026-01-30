#!/bin/bash

TMPROOT=$1
execfile=$2
d4odep=$3
nits=$4


#===================================================
#
# Define shell functions
#
#===================================================
# Take the id of the case.submit processes
take_id()
{

  output=$($*)
  echo $output | awk '{print $NF}'
}
#===================================================


date
echo "BEGIN FILTER PROCESSES "$TMPROOT" "$execfile" "$nits" "$d4odep
source /ec/res4/hpcperm/${USER}/d4o-bs/install/INTEL/source.me
# source /ec/res4/hpcperm/${USER}/d4o/install/INTEL/source.me
if [ $execfile == "filter" ]
  then
 
     # chose the working mode for filter
     if [ $d4odep == "yes" ]
      then
         string_id=""
         for i in $(seq $nits)
           do 
             cd ${TMPROOT}/TS${i}
             if [ ! -f run_filter_departures.bash ]; then cp ${TMPROOT}/run_filter_departures.bash . ;fi
             rm -f assimilate.err
             rm -f assimilate.out
             echo "TS$i: change the name of the process in order to better follow what is happening with bjobs"
            #  sed -i "s@.*#sbatch-J.*@#sbatch-J dep_TS${i}@g" run_filter_departures.bash
             jobid=$(take_id sbatch < run_filter_departures.bash) 
            #  if [ $i -eq 1 ]
            #    then
            #    string_id=$string_id" done($jobid)"
            #  else
            #    string_id=$string_id" && done($jobid)"
            #  fi
            string_id=$string_id" $jobid"
          done
          
          cd ${TMPROOT}
          for jb in ${string_id};do

            echo "wait for jobid: ${jb}"

            while true; do

                state=$(squeue -j $jb | awk '{print $5}' | tail -1)
                if [ $state != "STATE" ];then
                    sleep 3
                else
                    break
                fi
            done
          
          done
          
          # sbatch -w "$string_id" < cases_bogus_dep.csh         
     elif [ ${d4odep} == "no" ]
       then   
          #d4odep=no
          cd ${TMPROOT}/allTS
          if [ ! -f run_filter.bash ]; then cp ${TMPROOT}/run_filter.bash . ;fi
          rm -f log_filter.txt
          echo "change the name of the process, for filter, in order to better follow what is happening with bjobs"
          # sed -i "s@.*#sbatch-J.*@#sbatch-J filter_allTS@g" run_filter.bash
          jb=$(take_id sbatch < run_filter.bash)
          
          echo "wait for jobid PHASE 2: ${jb}"

          while true; do

              state=$(squeue -j $jb | awk '{print $5}' | tail -1)
              if [ $state != "STATE" ];then
                  sleep 3
              else
                  break
              fi
          done
     elif [ ${d4odep} == "all" ]
      then
          cd ${TMPROOT}/allTS
          if [ ! -f run_filter_all.bash ]; then cp ${TMPROOT}/run_filter_all.bash . ;fi
          rm -f log_filter_all.txt
          echo "change the name of the process, for filter, in order to better follow what is happening with bjobs"
          # sed -i "s@.*#sbatch-J.*@#sbatch-J filter_all_allTS@g" run_filter_all.bash
          sbatch < run_filter_all.bash > log_filter_all.txt
     else
          echo "ERROR: filter option not available! use: all, yes, no"
          exit
     fi
     cd ${TMPROOT}
else
    rm -f inflog.txt
    ./fill_inflation_restart >> inflog.txt
fi

exit
