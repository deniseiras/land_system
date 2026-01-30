#!/bin/bash

#BSUB -n 3
#BSUB -R "span[ptile=3]"
#BSUB -q s_long
#BSUB -W 8:00
#BSUB -P R000
#BSUB -x 
#BSUB -J scatt 
#BSUB -o scatt.out
#BSUB -e scatt.err
##BSUB -I

#python3 fsoijo_en.py > >(tee output.log >/dev/tty) 2> >(tee error.log >/dev/tty) &


echo " "
echo " Removing old log"
echo " "
rm -f scatt.out scatt.err scatt.log.*

echo " Execute the python program for the fsoijo computation"
#python3 scatter_test.py > scatt.logarc 
rc=0
/usr/bin/time -v  python3 scatter_test.py > scatt.log.$LSB_JOBID 2>&1 || rc=$?

