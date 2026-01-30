#!/bin/bash

#BSUB -n 18
#BSUB -R "span[ptile=18]"
#BSUB -q p_short
#BSUB -W 00:30
#BSUB -P R000
##BSUB -x 
#BSUB M 10GB
#BSUB -R rusage[mem=10GB]
#BSUB -J arc2_2017-10-05-21600 
#BSUB -o diag.out
#BSUB -e diag.err
#BSUB -app spreads_filter
##BSUB -I

#python3 fsoijo_en.py > >(tee output.log >/dev/tty) 2> >(tee error.log >/dev/tty) &


echo " "
echo " Removing old log"
echo " "
# rm -f diag.out diag.err 

echo " Execute the python program for the fsoijo computation"
rc=0
/usr/bin/time -v ${LAUNCHCMD} /work/cmcc/mg20022/.conda/envs/guatura/bin/python ./quick_spreads_diag.py   > diag.log.$LSB_JOBID 2>&1 || rc=$?


