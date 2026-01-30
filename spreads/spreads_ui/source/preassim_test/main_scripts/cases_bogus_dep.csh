#!/bin/csh 
#BSUB -n 1
#BSUB -R "span[ptile=1]"
#BSUB -q p_short
#BSUB -W 0:01
#BSUB -P R000
#BSUB -x 
##BSUB -u giovanni.conti83@gmail.com
#BSUB -J assim_bogus_assim 
##BSUB -o assimilate.out
##BSUB -e assimilate.err
##BSUB -sla SC_dev_dart
#BSUB -I


echo "start -- BOGUS DEP"

echo "`date` -- END BOGUS DEP"

exit 0

# <next few lines under version control, do not edit>
# $URL$
# $Revision$
# $Date$

