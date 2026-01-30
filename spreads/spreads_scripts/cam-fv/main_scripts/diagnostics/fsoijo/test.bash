#!/bin/bash

# number of ensemble members
NENS=80

# compute the FSOI-Jo between the start and the end date
# they must be considered as the first and last i.c. for the forecast run
# START_DATE="2017-10-03-43200"
# END_DATE="2017-10-04-43200"
START_DATE="2017-10-05-00000"

END_DATE="2017-10-06-00000"
# path to archdir
# ARCHD="/work/cmcc/${USER}/CMCC-CM/archive"
ARCHD=/work/cmcc/mg20022/CMCC-CM/archive

# experiment name
# EXPNAME="spreads_paper"
EXPNAME=spreads_v5

# Set the obs dir
# OBSDIR="/work/cmcc/mg20022/databases/b2d4o_d4o_db"
OBSDIR=/work/cmcc/mg20022/databases/b2d4o_d4o_db

# SPREADS directory
# SPREADSDIR="/users_home/cmcc/${USER}/spreads"
SPREADSDIR=/work/cmcc/mg20022/github/spreads


find ${ARCHD}/${EXPNAME}-forecast -maxdepth 1 -type d -name "*-????-??-??-?????" | while read -r dirf; do
    ss=$(echo "$dirf" | rev | cut -d'-' -f1 | rev)
    dd=$(echo "$dirf" | rev | cut -d'-' -f2 | rev)
    mm=$(echo "$dirf" | rev | cut -d'-' -f3 | rev)
    yy=$(echo "$dirf" | rev | cut -d'-' -f4 | rev)
    date="${yy}-${mm}-${dd}-${ss}"
    # echo " yy = ${yy}"
    # echo " mm = ${mm}"
    # echo " dd = ${dd}"
    # echo " ss = ${ss}"
    echo " i.c. forecast date: ${date}"
    case "${ss}" in
      "00000")
    	  hh="00"
        ;;
      "21600")
	  hh="06"
        ;;
      "43200")
	  hh="12"
        ;;
      "64800")
	  hh="18"
        ;;
      *)
        echo " ERROR: hh variable not defined!"
       ;;
    esac


    if [[ "$date" > "${START_DATE}" && "$date" < "${END_DATE}" || "$date" == "${START_DATE}" || "$date" == "${END_DATE}" ]]; then

        echo "ENTRE"



        filename=$(ls ${dirf}/*cam.i*.nc | head -n 1)
        echo $filename
        cci=$(echo "$filename" | grep -oP 'cam\.i\.(\d{4}-\d{2}-\d{2}-\d{5})' | cut -d '.' -f 3)
        yyf=$(echo ${cci} | rev | cut -d'.' -f2| rev | cut -d'-' -f1)
        mmf=$(echo ${cci} | rev | cut -d'.' -f2| rev | cut -d'-' -f2)
        ddf=$(echo ${cci} | rev | cut -d'.' -f2| rev | cut -d'-' -f3)
        ssf=$(echo ${cci} | rev | cut -d'.' -f2| rev | cut -d'-' -f4)
            case "${ssf}" in
                "00000")
            hhf="00"
                ;;
                "21600")
            hhf="06"
                ;;
                "43200")
            hhf="12"
                ;;
                "64800")
            hhf="18"
                ;;
                *)
                echo " ERROR: hh variable not defined!"
                ;;
            esac
        echo " yyf = ${yyf}"
        echo " mmf = ${mmf}"
        echo " ddf = ${ddf}"
        echo " ssf = ${ssf}"
        datef=${yyf}-${mmf}-${ddf}-${ssf}
        echo " forecasted date ${datef}"  



    fi
done