#!/bin/sh
#################################################################
#  GPSRO DATA (https://www.romsaf.org/pub/icdr/v1-series/profs/metop/bfr)
#  Author Dr. Swapan Mallick
#  Date 15 FEBRUARY 2023 at CMCC
#################################################################
#
 set WRKDIR = /data/cmcc/sm09722/DATA_ALL/GPSRO_DWD
 set DATADIR = /data/cmcc/sm09722/DATA_ALL/GPSRO_DWD
 ##mkdir -p ${DATADIR}
 cd $DATADIR
 set YYYY = 2017
 set MM = 10
 #
wget -rN -np -A'*201710*' --user="Swapan Mallick" --ask-password https://www.romsaf.org/pub/icdr/v1-series/profs/metop/bfr/2017

