#!/bin/csh
#
# Simply loop over each input AMSUA netCDF file and create an observation
# sequence file from it. No other processing.
# 
# The output observation sequence file will be renamed with the YYYY.MM.DD.XXX
# values (the Date-Time-Group : DTG) from the input filename.
#
# This input.nml is the minimal namelist needed for this purpose.
# I envision the &obs_sequence_tool_nml will be modified in a
# subsequent script that will read a collection of obs_seq files and output
# a single obs_seq file with just the observations for that assimilation cycle.
# There are some strings in there are intended to be replaced with each execution
# of the obs_sequence_tool.

cp ../work/input.nml.amsua_template input.nml
#set DATADIR=/work/cmcc/gc02720/observations/AMSUL1B_20170114-25
set DATADIR=/work/cmcc/gc02720/observations/amsua-test/allswaths21600
#set DATADIR=/work/cmcc/gc02720/observations/amsua-test/high


foreach FILE ( ${DATADIR}/*nc )

   # Grab the time information from the input filename
   set DTG = `echo $FILE:t | cut -b6-19`
   set OUT = ${DATADIR}/obs_seq.amsua.$DTG

   echo ''
   echo "Converting $FILE into $OUT"

   # The input.nml is configured to always read from "input_file_list"
   echo $FILE >! input_file_list
      
   ../work/convert_amsu_L1 || exit 1

   # rename the output to something unique
   mv -v obs_seq.amsua $OUT

end

#unlink L1_amsua.nc

