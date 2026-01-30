#!/bin/bash

#BSUB -n 4
#BSUB -R "span[ptile=4]"
#BSUB -q s_long
#BSUB -W 8:00
#BSUB -P R000
#BSUB -x 
#BSUB -J oi 
#BSUB -o oi.out
#BSUB -e oi.err
##BSUB -I

#python3 fsoijo_en.py > >(tee output.log >/dev/tty) 2> >(tee error.log >/dev/tty) &


echo " "
echo " Removing old log"
echo " "
rm oi.out oi.err oi.log

echo " Execute the python program for the fsoijo computation"
python3 oi_en.py > oi.log 


