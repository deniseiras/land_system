#!/bin/sh
#################################################################
#  Date 13 FEB 2023
#################################################################
#
EXP_DATA=GPSRO
EVENT=201710
SCRDIR=/data/cmcc/${USER}/GPSRO_DWD
#
YYYY=`echo $EVENT | cut -c1-4`
MM=`echo $EVENT | cut -c5-6`
#
#-------- EXTRACT TAR FILE -------------
cd ${SCRDIR}/RAW_DATA/${YYYY}/
for DD in {01..31}; do
   DATE=${YYYY}${MM}${DD}
   realpath bfr_${DATE}_metop_I_2320_0010.tgz
   tar -zxvf bfr_${DATE}_metop_I_2320_0010.tgz
   wait
done
exit
