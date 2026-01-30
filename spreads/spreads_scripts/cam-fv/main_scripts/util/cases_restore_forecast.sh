#!/bin/bash
#BSUB -n 1
#BSUB -R "span[ptile=18]"
#BSUB -q s_medium
#BSUB -W 4:00
#BSUB -P R000
#BSUB -J cases_create
##BSUB -sla SC_dev_dart
#BSUB -I


#===========================================================
#  Restore last forecast in cam_XXXX.i
#===========================================================


# Set some env variables
SCRIPTDIR=`pwd`
echo " SCRIPTDIR= $SCRIPTDIR"

CLONESROOT=`grep "clonesroot=" $SCRIPTDIR/cases_create.sh | \
            sed -e "s/\\\${USER}/$USER/g;  \
                    s/\\\${CESMEXP}/$CESMEXP/g; \
                    s/[\",=]/ /g"`
CLONESROOT=`echo $CLONESROOT | cut -d' ' -f3`
echo " CLONESROOT=  $CLONESROOT"


TMPDIR=`grep "tmpdir=" $SCRIPTDIR/cases_create.sh | \
            sed -e "s/\\\${USER}/$USER/g;  \
                    s/[\",=]/ /g"`
TMPDIR=`echo $TMPDIR | cut -d' ' -f2`
echo " TMPDIR=  $TMPDIR"

ARCDIR=`grep "archdir=" $SCRIPTDIR/cases_create.sh | \
            sed -e "s/\\\${USER}/$USER/g;  \
                    s/[\",=]/ /g"`
ARCDIR=`echo $ARCDIR | cut -d' ' -f2`
echo " ARCDIR=  $ARCDIR"


case_name=`grep "case_name=" $SCRIPTDIR/cases_create.sh | sed -e "s/=/ /g; s/\"//g"`
case_name=`echo $case_name | cut -d' ' -f2 `
echo " case_name= $case_name"

nens=`grep "nens=" $SCRIPTDIR/cases_create.sh | sed -e "s/=/ /"`
nens=`echo $nens | cut -d' ' -f2 `
echo " nens= $nens"


# ==============================================================================
# Prepare the environment
# ==============================================================================

# Load the environmental variable (CESMEXP)
. $HOME/.bashrc


# Module load
module load intel19.5/19.5.281
module load intel19.5/netcdf/C_4.7.2-F_4.5.2_CXX_4.3.1
module load intel19.5/ncview/2.1.8

module load intel19.5/cdo/1.9.8
module load intel19.5/magics/3.3.1
module load intel19.5/proj/6.2.1
module load intel19.5/udunits/2.2.26
module load intel19.5/szip/2.1.1
module load intel19.5/eccodes/2.12.5

module load intel19.5/nco/4.8.1
module load ncl/6.6.2

echo " "
module list
echo " "

# ==============================================================================
# standard commands:
#
# Make sure that this script is using standard system commands
# instead of aliases defined by the user.
# If the standard commands are not in the location listed below,
# change the 'set' commands to use them.
# The verbose (-v) argument has been separated from these command definitions
# because these commands may not accept it on some systems.  On those systems
# set VERBOSE = ''
# ==============================================================================

VERBOSE='-v'
MOVE='/usr/bin/mv'
COPY='/usr/bin/cp --preserve=timestamps'
LINK='/usr/bin/ln -s'
LIST='/usr/bin/ls'
REMOVE='/usr/bin/rm'

maindir=`pwd`



#===========================================================
#
#===========================================================
# Clone the case nens time

echo -e "Phase 1 (start): restore forecast in cam_XXXX.i ...\n"

laste=`${LIST} ${ARCDIR}/${case_name}/ | tail -1`
echo "last forecast: ${laste}"


inst=1
while (($inst<= $nens))
do
   echo -e "member $inst\n"

   # Following the CESM strategy for 'inst_string'
   inst_string=`printf _%04d $inst`
   
   new_case="$clonesroot/$case_name$inst_string"

   echo "Staging initial files for instance $inst of $nens"

   cd /work/cmcc/${USER}/CESM2/${new_case}/run


   ${COPY} ${ARCDIR}/${case_name}/${laste}/${case_name}.cam${inst_string}.e.forecast.*.nc  ${case_name}${inst_string}.cam.i*.nc

   ((inst++))
done

echo -e "Phase 2 (end): \n"


echo -e "\n END EXPERIMENT RESTORATION \n"

