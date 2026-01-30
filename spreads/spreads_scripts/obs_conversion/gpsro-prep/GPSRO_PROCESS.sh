#!/bin/sh
#################################################################
#  Date 13 FEB 2023
#################################################################
#
EXP_DATA=GPSRO
EVENT=201710
SCRDIR=/data/cmcc/${USER}/GPSRO_DWD
INPUT=/data/cmcc/${USER}/GPSRO_DWD/RAW_DATA
WORKDIR=/data/cmcc/${USER}/GPSRO_DWD/tmp
mkdir -p ${WORKDIR}
OUTPUT=/data/cmcc/${USER}/OBS_ECMAR
#
YYYY=`echo $EVENT | cut -c1-4`
MM=`echo $EVENT | cut -c5-6`
#
cd ${YYYY}/
#--------------------------------------
for DD in 09; do
##for DD in {10..28}; do
#
if [ ${DD} -ge 11 ]; then
  DD1=$((DD-1))
else
  DD1=08
  ##DD1='0'$((DD-1))
fi
# 
#DD1=04 # Previous day
DATE=${YYYY}${MM}${DD}
DATEP=${YYYY}${MM}${DD1}
#
cd ${WORKDIR}
rm -rf ${WORKDIR}/bfr_*
echo ${INPUT}/${YYYY}/${YYYY}-${MM}-${DD}
ln -sf ${INPUT}/${YYYY}/${YYYY}-${MM}-${DD}/bfr_*.bin ./
echo ${INPUT}/${YYYY}/${YYYY}-${MM}-${DD1}
ln -sf ${INPUT}/${YYYY}/${YYYY}-${MM}-${DD1}/bfr_*.bin ./
#
for UTC in 00 06 12 18 ; do
   if [ ${UTC} = 00 ];then
      echo ${UTC}
      cat bfr_${DATEP}_21* bfr_${DATEP}_22* bfr_${DATEP}_23* bfr_${DATE}_00* bfr_${DATE}_01* bfr_${DATE}_02* > GPSRO_${UTC}
      rm -rf  ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      cp -f  GPSRO_${UTC} ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      mv GPSRO_${UTC} GPSRO_${UTC}_${DD}_${MM}_${YYYY}
   elif [ ${UTC} = 06 ];then
      echo ${UTC}
      cat bfr_${DATE}_03* bfr_${DATE}_04* bfr_${DATE}_05* bfr_${DATE}_06* bfr_${DATE}_07* bfr_${DATE}_08* > GPSRO_${UTC}
      rm -rf  ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      cp -f  GPSRO_${UTC} ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      mv GPSRO_${UTC} GPSRO_${UTC}_${DD}_${MM}_${YYYY}
   elif [ ${UTC} = 12 ];then
      echo ${UTC}
      cat bfr_${DATE}_09* bfr_${DATE}_10* bfr_${DATE}_11* bfr_${DATE}_12* bfr_${DATE}_13* bfr_${DATE}_14* > GPSRO_${UTC}
      rm -rf  ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      cp -f  GPSRO_${UTC} ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      mv GPSRO_${UTC} GPSRO_${UTC}_${DD}_${MM}_${YYYY}
   elif [ ${UTC} = 18 ];then
      echo ${UTC}
      cat bfr_${DATE}_15* bfr_${DATE}_16* bfr_${DATE}_17* bfr_${DATE}_18* bfr_${DATE}_19* bfr_${DATE}_20* > GPSRO_${UTC}
      rm -rf  ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      cp -f  GPSRO_${UTC} ${OUTPUT}/${YYYY}/${MM}/${DD}/GPSRO_${UTC}00
      mv GPSRO_${UTC} GPSRO_${UTC}_${DD}_${MM}_${YYYY}
   fi
##
done
rm -rf ${WORKDIR}/bfr_*
##
done
exit
