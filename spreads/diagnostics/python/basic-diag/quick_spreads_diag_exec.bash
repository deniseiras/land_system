#!/bin/bash

#BSUB -n 36
#BSUB -R "span[ptile=36]"
#BSUB -q s_long
#BSUB -W 8:00
#BSUB -P R000
#BSUB -x 
#BSUB -J spreads_diag 
#BSUB -o diag.out
#BSUB -e diag.err
##BSUB -I

#python3 fsoijo_en.py > >(tee output.log >/dev/tty) 2> >(tee error.log >/dev/tty) &


echo " "
echo " Removing old log"
echo " "
rm diag.out diag.err 

echo " Execute the python program for the fsoijo computation"
rc=0
/usr/bin/time -v ${LAUNCHCMD} python3 ./quick_spreads_diag.py   > diag.log.$LSB_JOBID 2>&1 || rc=$?


