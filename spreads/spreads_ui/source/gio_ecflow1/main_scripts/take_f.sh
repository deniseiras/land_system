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
  echo $output | awk '{print $2}' | cut -d"<" -f2 | cut -d">" -f1
}
#===================================================


date
echo "BEGIN FILTER PROCESSES "$TMPROOT" "$execfile" "$nits" "$d4odep
source /data/cmcc/${USER}/d4o/install/INTEL/source.me
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
             sed -i "s@.*#BSUB -J.*@#BSUB -J dep_TS${i}@g" run_filter_departures.bash
             jobid=$(take_id bsub < run_filter_departures.bash) 
             if [ $i -eq 1 ]
               then
               string_id=$string_id" done($jobid)"
             else
               string_id=$string_id" && done($jobid)"
             fi
          done
          cd ${TMPROOT}
          echo "wait for ${string_id}"
          bsub -w "$string_id" < cases_bogus_dep.csh         
     elif [ ${d4odep} == "no" ]
       then   
          #d4odep=no
          cd ${TMPROOT}/allTS
          if [ ! -f run_filter.bash ]; then cp ${TMPROOT}/run_filter.bash . ;fi
          rm -f log_filter.txt
          echo "change the name of the process, for filter, in order to better follow what is happening with bjobs"
          sed -i "s@.*#BSUB -J.*@#BSUB -J filter_allTS@g" run_filter.bash
          bsub < run_filter.bash > log_filter.txt
     elif [ ${d4odep} == "all" ]
      then
          cd ${TMPROOT}/allTS
          if [ ! -f run_filter_all.bash ]; then cp ${TMPROOT}/run_filter_all.bash . ;fi
          rm -f log_filter_all.txt
          echo "change the name of the process, for filter, in order to better follow what is happening with bjobs"
          sed -i "s@.*#BSUB -J.*@#BSUB -J filter_all_allTS@g" run_filter_all.bash
          bsub < run_filter_all.bash > log_filter_all.txt
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
