#!/bin/bash

#BSUB -n 4
#BSUB -R "span[ptile=4]"
#BSUB -q s_long
#BSUB -W 8:00
#BSUB -P R000
#BSUB -x 
#BSUB -J fsoi 
#BSUB -o fsoi.out
#BSUB -e fsoi.err
##BSUB -I

#python3 fsoijo_en.py > >(tee output.log >/dev/tty) 2> >(tee error.log >/dev/tty) &


echo " "
echo " Removing old log"
echo " "
rm fsoi.out fsoi.err fsoi.log

echo " Execute the python program for the fsoijo computation"
python3 fsoijo_en.py > fsoi.log 


