#!/bin/bash 
#BSUB -n 1
#BSUB -R "span[ptile=1]"
#BSUB -q s_short
#BSUB -W 0:10
#BSUB -P R000
#BUSB -M 1GB 
#BSUB -R "rusage[mem=1GB]"
##BSUB -x 
##BSUB -u giovanni.conti83@gmail.com
#BSUB -J prepy
##BSUB -o assimilate.out
##BSUB -e assimilate.err
##BSUB -sla SC_dev_dart
##BSUB -I


python rep_input.py TEMPLATE_PYTHON_FILE





