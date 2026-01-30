#!/bin/bash

#BSUB -n 1
#BSUB -R "span[ptile=1]"
#BSUB -x
#BSUB -q p_short
#BSUB -W 0:30
#BSUB -P R000
#BSUB -J cases_no_assimilate
#BSUB -I

#============================================================
#
#============================================================

echo -e "\n `date` -- NO ASSIMILATION --\n"

sh cases_check.sh


# Need to link the new cam_initial_XXXX IC in case we move 
# from ASSIMILATION FALSE to TRUE
echo "Set the new cam_initial_XXXX links in case you want to start the assimilation!"

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



inst=1
while (( ${inst} <= $nens ))
do

    inst_string=`printf _%04d $inst`
    echo "Linking the new cam_initial${inst_string} for possible DA run."

    cd ${CLONESROOT}/${case_name}${inst_string}
    rdir=`./xmlquery RUNDIR | awk '{print $NF}'`
    cd ${rdir}
    rdate=`head -n 1 rpointer.atm | cut -d'.' -f4`
    rm -f cam_initial${inst_string}.nc
    ln -s  ${case_name}${inst_string}.cam.i.${rdate}.nc cam_initial${inst_string}.nc  

    
    ((inst++)) 

done


echo -e "\n Starting the next evolution cycles\n"


# Restart management




