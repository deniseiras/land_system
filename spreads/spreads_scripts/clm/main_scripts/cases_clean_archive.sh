#!/bin/bash

# This script is used after cases_assimilate, this means that all the members have finished correctly
# and DART filter did not crashed!

# Take the name of the experiment the ensemble size and the forecast flag
EXPNAME=$1
NENS=$2
FORE=$3
NFORE=$4



echo -e "\n START CLEANING ARCHIVING PROCEDURE \n"

CASESCONTAINERF=/work/cmcc/${USER}/cesm-exp
#CASESCONTAINER=/work/cmcc/${USER}/CESM2
CASESCONTAINER=/work/cmcc/${USER}/CMCC-CM
ARCHIVE=${CASESCONTAINER}/archive

# save only 2 days that means 8 cycles!
NSAVE=8

TMPDATE="savelist.txt"

echo " Forecast cases container dir = $CASESCONTAINERF"
echo " Container dir = $CASESCONTAINER"
echo " Archive dir = $ARCHIVE"
echo " Experiment name = $EXPNAME"
echo " Numeber of instances = $NENS"
echo " Forecast = $FORE"
echo " Forecast N = $NFORE"
echo " "


# If the cleaning is active we remove all the output not needed for a
# restart. Everithing that is not computed at 6H cycle: 21600, 43200,
# 64800, 00000 is removed. After that we check how many cycles we did.
echo "Removing intermediate output needed for the model interpolator:"
cdir=`pwd`
echo "CDIR= ${cdir}"
inst=1
while (($inst<= $NENS))
   do
     inst_string=`printf _%04d $inst`
     cd  ${CASESCONTAINER}/${EXPNAME}${inst_string}/run
     for i in ${EXPNAME}${inst_string}*; do
       # take the date
       dt=`echo $i | cut -d'.' -f4`
       # take the seconds
       ds=`echo $dt | cut -d'-' -f4`
       echo " processing: ${i}"
       #echo " dt=${dt}"
       echo " ds=${ds}" 
      # if (( 10#${ds}==21600 )) || (( 10#${ds}==64800 )) || (( 10#${ds}==43200 )) || ((10#${ds}==00000 )) # if 06Z 18Z
       if [ ${ds} -eq 21600 -o ${ds} -eq 64800 -o ${ds} -eq 43200 -o ${ds} -eq 00000 ]
        then
         # skip
         echo "skip: ${ds}"
       else
         echo " removing: $i"
         rm $i
       fi
     done
   ((inst++))
done
cd ${cdir}






# some operation must be done independently by the forecast
# check the number of evolution cycles
ncyc=`ls ${CASESCONTAINER}/${EXPNAME}_0001/run/*cam.i* | wc -l`
nmod=`echo "(${ncyc}%${NSAVE})" | bc`

echo " number of saved initial files in DA exp: ${ncyc}"
echo " number of saved initial files mod ${NSAVE}: ${nmod}"
echo " "


# cleaning condition
if (( ${nmod}==1 )) && (( ${ncyc}>${NSAVE} ))
#if true
  then
     echo " need to clean"
     # list of dates to keep
     if [ -f "${TMPDATE}" ]; then  rm ${TMPDATE};  fi
     ls ${CASESCONTAINER}/${EXPNAME}_0001/run/*cam.i* | tail -${NSAVE} | cut -d'.' -f4 >> ${TMPDATE}
     echo "  keeping:"
     cat ${TMPDATE}
     echo " "


     inst=1
     while (($inst<= $NENS))
       do
         echo -e " cleaning member $inst\n"
         # Following the CESM strategy for 'inst_string'
         inst_string=`printf _%04d $inst`


         for i in ${CASESCONTAINER}/${EXPNAME}${inst_string}/run/${EXPNAME}*; do
           # take the date
           dt=`echo $i | cut -d'.' -f4`
           # take the seconds
           ds=`echo $dt | cut -d'-' -f4`
           echo " processing: ${i}"
           echo " dt=${dt}"
           echo " ds=${ds}"
           if ! grep -qxFe ${dt} ${TMPDATE}
              then
                if [ $FORE = "TRUE" ] # if forecast active
                   then
                     # we need to understand if the forecast started and all the members finished the simulation otherwise we can not remove
                     # potential i.c. for the forecast!
                     # we need to ask: is this file an I.C. for some forecast
                     if (( ${ds}==21600)) || (( ${ds}==64800)) # if 06Z 18Z
                       then
                         # we have forecast only at 00Z and 12Z
                         echo " Deleting: $i"
                         rm "$i"
                     else
                         if ((${inst}<=${NFORE})) # if do not exceed the forecast members
                           then
                             # has the forecast finished?
                             echo " check if the forecast dir still exist and if it exist if the forecast has finished"
			     if [[ -d ${CASESCONTAINERF}/${EXPNAME}-forecast/${EXPNAME}_f${inst_string}-${dt} ]]; then
                                grep "resubmit_num 0" ${CASESCONTAINERF}/${EXPNAME}-forecast/${EXPNAME}_f${inst_string}-${dt}/cesm.stderr*
                                status=$?
                                if [ $status -eq 0 ]
                                  then
                                    echo " job finished! delete forecast i.c."
                                    echo " Deleting: $i"
                                    rm "$i"
#                                echo " archive forecast: "
#                                tmpf=${ARCHIVE}/${EXPNAME}-forecast/${EXPNAME}_f-${dt}
#                                mkdir -p ${tmpf}
#                                mv  ${CASESCONTAINER}/${EXPNAME}_f${inst_string}-${dt}/run/*cam.h0*${dt}* ${tmpf}/.           
#                                mv  ${CASESCONTAINER}/${EXPNAME}_f${inst_string}-${dt}/run/*cam.i*${dt}* ${tmpf}/.           
#                                # delete dir forecast member
#                                echo " remove ${CASESCONTAINER}/${EXPNAME}_f${inst_string}-${dt}/"
#                                rm -r  ${CASESCONTAINER}/${EXPNAME}_f${inst_string}-${dt}/          
#                                echo " remove ${CASESCONTAINERF}/${EXPNAME}-forecast/${EXPNAME}_f${inst_string}-${dt}"
#                                rm -r  ${CASESCONTAINERF}/${EXPNAME}-forecast/${EXPNAME}_f${inst_string}-${dt}          
                                else
                                   echo " forecast unfinished, do not delete i.c."
                                fi
			     else
                                   echo " forecast dir does not exist"
                                   echo " Deleting: $i"
                                   rm "$i"
			     fi
                         else
                             # we do not have forecast for this member so clean with no mercy
                             echo " No forecast required for member ${inst} "    
                             echo " Deleting: $i"
                             rm "$i"
                         fi # end if do not exceed the forecast members
                     fi # end fi 06Z 18Z
                else
                     echo " Deleting: $i"
                     rm "$i"
                fi # end forecast active
           fi
         done

         #clean the logs
         echo " clean logs"
         rm ${CASESCONTAINER}/${EXPNAME}${inst_string}/run/*log*.gz

       ((inst++))
     done

     rm  ${TMPDATE}
   
else
     echo " no need to clean"
fi




echo -e "\n END CLEANING ARCHIVING PROCEDURE \n"
