#!/bin/bash




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


echo ""


inst=1
while (( $inst <= $nens ))
 do
    inst_string=`printf _%04d $inst`

    sed -i "11 i #BSUB -sla SC_dev_dart" ${CLONESROOT}/${case_name}${inst_string}/.case.run    

    ((inst++))
done
