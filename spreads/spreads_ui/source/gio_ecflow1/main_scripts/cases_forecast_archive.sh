#!/bin/bash
# Archive the forecast.

# Take the name of the experiment
EXPNAME=$1


echo -e "\n START FORECAST ARCHIVING PROCEDURE \n"

CASESCONTAINERF=/work/cmcc/${USER}/${CESMEXP}
#CASESCONTAINER=/work/cmcc/${USER}/CESM2
CASESCONTAINER=/work/cmcc/${USER}/CMCC-CM
ARCHIVE=${CASESCONTAINER}/archive


echo " Forecast cases container dir = $CASESCONTAINERF"
echo " Run dir container = $CASESCONTAINER"
echo " Archive dir = $ARCHIVE"
echo " Experiment name = $EXPNAME"
echo " Numeber of instances = $NENS"
echo " Forecast N = $NFORE"
echo " "


for ff in ${CASESCONTAINERF}/${EXPNAME}-forecast/*
 do
  echo "Check: ${ff}"
  echo " check if the forecast has finished"
  grep "resubmit_num 0" ${ff}/cesm.stderr*
  status=$?
  if [ $status -eq 0 ]
    then
      echo " job finished! archive the forecast"
      #take the date
      date=$(echo ${ff} | rev | cut -d'-' -f1-4 | rev)
      echo " date:  ${date}"
      string2remove="${EXPNAME}_f_"
      member=$(echo ${ff} | rev |  cut -d'/' -f1 | rev | sed "s/$string2remove//" | cut -d'-' -f1)
      echo " member:  ${member}"
      tmpf=${ARCHIVE}/${EXPNAME}-forecast/${EXPNAME}_forecast-${date}
      echo " move forecast in ${tmpf}"
      mkdir -p ${tmpf}
      echo " move ${CASESCONTAINER}/${EXPNAME}_f_${member}-${date}/run/*cam.h0&i*${date}.nc"
      mv -f ${CASESCONTAINER}/${EXPNAME}_f_${member}-${date}/run/*cam.h0*${date}* ${tmpf}/.
      mv -f ${CASESCONTAINER}/${EXPNAME}_f_${member}-${date}/run/*cam.i* ${tmpf}/.
      # delete dir forecast member
      echo " remove ${CASESCONTAINER}/${EXPNAME}_f_${member}-${date}/"
        rm -rf  ${CASESCONTAINER}/${EXPNAME}_f_${member}-${dt}/
      echo " remove ${ff}"
        rm -rf  ${ff}
 else
   echo " forecast not finished!"
 fi

done	




