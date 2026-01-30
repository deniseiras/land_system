#!/bin/bash


echo " "
echo " Removing old log"
echo " "
# rm -f diag.out diag.err 

echo " Execute the python program for the fsoijo computation"
rc=0
/usr/bin/time -v /ec/res4/hpcperm/ita0829/conda/envs/metrics/bin/python ./quick_spreads_diag.py   > diag.log 2>&1 || rc=$?
exit $rc


