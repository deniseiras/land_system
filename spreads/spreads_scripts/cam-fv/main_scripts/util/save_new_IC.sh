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
# Save new IC from the last run
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


echo -e "\n START EXPERIMENT RESTORATION \n"


#===========================================================
#
#===========================================================
# Clone the case nens time

echo -e "Phase 1 (start): creation of the clones ...\n"



DIRIC=/work/cmcc/${USER}/newIC
inst=1
while (($inst<= $nens))
do
   echo -e "member $inst\n"

   # Following the CESM strategy for 'inst_string'
   inst_string=`printf _%04d $inst`
   
   new_case="${CLONESROOT}/$case_name$inst_string"

   # Modify the I.C. for each clone, then  build
   # Remember that each job contain ONLY one member
   cd $new_case
   
   RUNDIR=`./xmlquery RUNDIR       --value`
   refcase=`./xmlquery RUN_REFCASE --value`
   stagedir=`./xmlquery RUN_REFDIR --value`
   refdate=`./xmlquery RUN_REFDATE --value`
   reftod=`./xmlquery RUN_REFTOD   --value`
   COMP_ROF=`./xmlquery COMP_ROF   --value`   
   init_time="${refdate}-$reftod"
   

   echo "Staging initial files for instance $inst of $nens"

   cd $RUNDIR
   echo " Save new IC"

   ATM_DATE=`head -n 1 rpointer.atm | sed -e "s#\.# #g" | awk '{ print $4}'`
   echo "$ATM_DATE"  
   cp ${case_name}${inst_string}.cam.i.${ATM_DATE}.nc      ${DIRIC}/      
   cp ${case_name}${inst_string}.clm2.r.${ATM_DATE}.nc  ${DIRIC}/ 
   cp ${case_name}${inst_string}.mosart.r.${ATM_DATE}.nc  ${DIRIC}/ 
   cp ${case_name}${inst_string}.cice.r.${ATM_DATE}.nc  ${DIRIC}/ 
   cp ${case_name}${inst_string}.cpl.r.${ATM_DATE}.nc  ${DIRIC}/ 
   cp ${case_name}${inst_string}.docn.rs1.${ATM_DATE}.bin  ${DIRIC}/ 
   cp rpointer.atm  ${DIRIC}/ 
   cp rpointer.lnd  ${DIRIC}/ 
   cp rpointer.rof  ${DIRIC}/ 
   cp rpointer.ice  ${DIRIC}/ 
   cp rpointer.ocn  ${DIRIC}/ 
   cp rpointer.drv  ${DIRIC}/ 

 

   ((inst++))
done

echo -e "Phase 1 (end): \n"


echo -e "\n END EXPERIMENT RESTORATION \n"

