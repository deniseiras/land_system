#!/bin/bash

####################################################
#    Computation of the FSOI-Jo 
#
#    @author Giovanni Conti
#    @date 05 May 2023
#
#    usage:> ./prep_fsoijo.sh
####################################################

set -ea


#***************************************************
#           Set the parameters here
#***************************************************

# number of ensemble members
NENS=80

# compute the FSOI-Jo between the start and the end date
# they must be considered as the first and last i.c. for the forecast run
START_DATE="2017-10-03-43200"

END_DATE="2017-10-04-43200"

# path to archdir
ARCHD="/work/cmcc/${USER}/CMCC-CM/archive"

# experiment name
EXPNAME="spreads_paper"

# Set the obs dir
OBSDIR="/work/cmcc/mg20022/databases/b2d4o_d4o_db"

# SPREADS directory
SPREADSDIR="/users_home/cmcc/${USER}/spreads"

# number of timeslot now fixed to 13
NTS=13


#***************************************************
#           Main computation
#***************************************************
echo " "
echo "****************** Prep FSOI_Jo ********************"
echo "****************** for ensemble ********************"
echo " "


echo " Starting date to process: ${START_DATE}"
echo " Ending date to process: ${END_DATE}"
echo " "

echo " preparation..."
##source ${SPREADSDIR}/d4o/load-modules-d4o.juno
source /data/cmcc/${USER}/d4o/install/INTEL/source.me
#source /data/cmcc/mg20022/d4o/install/INTEL/source.me    #CHANGE!!!!
echo " "



# loop between the start and the end date (read -r mean "raw mode" to avoid problems with escape and special characters )
find ${ARCHD}/${EXPNAME}-forecast -maxdepth 1 -type d -name "*-????-??-??-?????" | while read -r dirf; do
    ss=$(echo "$dirf" | rev | cut -d'-' -f1 | rev)
    dd=$(echo "$dirf" | rev | cut -d'-' -f2 | rev)
    mm=$(echo "$dirf" | rev | cut -d'-' -f3 | rev)
    yy=$(echo "$dirf" | rev | cut -d'-' -f4 | rev)
    date="${yy}-${mm}-${dd}-${ss}"
    echo " yy = ${yy}"
    echo " mm = ${mm}"
    echo " dd = ${dd}"
    echo " ss = ${ss}"
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


    # Verifica se la data è compresa tra le date specificate
    if [[ "$date" > "${START_DATE}" && "$date" < "${END_DATE}" || "$date" == "${START_DATE}" || "$date" == "${END_DATE}" ]]; then
    #if [[ $date -ge ${START_DATE} && $date -le ${END_DATE} ]]; then


        echo " Elaborate directory: ${dirf}"
        # create a tmp directory inside the archived forecast dir
        if [ ! -d "${dirf}/tmp" ]; then
             mkdir -p "${dirf}/tmp"
             echo " Directory created: ${dirf}/tmp"
        else
             echo " Directory existing: ${dirf}/tmp"
	     rm -rf ${dirf}/tmp/*
        fi

        # store all the necessary files to run the filter inside tmp
        # inside the TMP dir we need to create time-slots dir that will contain the obs
	# find the forecast date, we need to store the obs corresponding to the cam.i date

        filename=$(ls ${dirf}/*cam.i*.nc | head -n 1)
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


	if [ ${ddf} == "08" ];then
                ddf="8"
        fi

        if [ ${mmf} == "08" ];then
                mmf="8"
        fi

        if [ ${ddf} == "09" ];then
                ddf="9"
        fi

        if [ ${mmf} == "09" ];then
                mmf="9"
        fi



        tmpdir="${dirf}/tmp"
	its=1
        while (( $its<=${NTS} ))
           do
               echo -e " time slot creation: TS= $its"
               tsname="TS$its"
               mkdir -p $tmpdir/$tsname

	       # copy the observations
               DIROBS=`printf %04d/%02d/%04d%02d%02d%02d ${yyf} ${mmf} ${yyf} ${mmf} ${ddf} ${hhf}`
               OBS_FILE=${OBSDIR}/${DIROBS}/TS$its
               echo " Copy the new databases in TS${its}"
               for FILE in ${OBS_FILE}/*.db; do
                  echo " Copy ${FILE}"
                  cp -f "${FILE}" ${tmpdir}/${tsname}/.
               done
          ((its++))
        done

        #*************************************************************
        # the following procedure is for FGAT=FALSE, that is one shot.
        #*************************************************************

        # merge the dbs to create the allTS dir
        echo " dbs merging, creation of allTS dir"
	if [ -d "${tmpdir}/allTS" ]; then
            rm -Rf "${tmpdir}/allTS"
        fi
        cd ${tmpdir}
        d4ojoinall
        cd ${tmpdir}/allTS
        d4ocatalog catalog.db "*.db"

        # prepare the directory allTS for the filter
        # change the ouput of the filter, we do not want the forecast, we do not want inflation 
        cp  ${SPREADSDIR}/spreads_scripts/cam-fv/main_scripts/input.nml.original.rad $tmpdir/allTS/input.nml
        sed -i "s@.*stages_to_write.*=.*@stages_to_write='output'@g" $tmpdir/allTS/input.nml
	sed -i "s@.*inf_flavor.*=.*@inf_flavor                  = 0,                       0@g" $tmpdir/allTS/input.nml
	sed -i "s/NUM_INSTANCE_TEMPLATE/${NENS}/g" ${tmpdir}/allTS/input.nml
        #cp  ${SPREADSDIR}/spreads_scripts/cam-fv/main_scripts/run_filter_departures.bash $tmpdir/allTS/.
        cp  ${SPREADSDIR}/spreads_scripts/cam-fv/main_scripts/run_filter_departures_mg.bash $tmpdir/allTS/.          #CHANGE!!!!
        cp  ${SPREADSDIR}/spreads_scripts/cam-fv/main_scripts/rep_input.py ${dirf}/.

        cp  ${SPREADSDIR}/d4o/flattened/cam-fv/filter.dir/filter $tmpdir/allTS/.
        cp  ${SPREADSDIR}/d4o/flattened/utility/sampling_error_correction_table.nc    $tmpdir/allTS/.
        cp  ${SPREADSDIR}/d4o/flattened/utility/rttov_sensor_db.csv    $tmpdir/allTS/.
        cp  ${SPREADSDIR}/d4o/ECMWF/rttov123/rtcoef_rttov12/rttov7pred54L/*    $tmpdir/allTS/.


	cd ${dirf}
        # set the cam_init_files
        filename="input.nml"
	line=$(grep "output_state_file_list" ${tmpdir}/allTS/"$filename")
	name=$(echo "$line" | awk -F"'" '{print $2}')
	if [ -e "${name}" ]; then
            rm -f "${name}"
            echo " ${name} deleted"
        else
            echo " ${name} does not exist"
        fi
	echo " create a new ${name}"
        for file in *cam.i*; do
            echo " insert ${file} in ${name}"
	    echo "${dirf}/${file}" >> ${name}
        done    
	mv ${name} ${tmpdir}/allTS/.
        
	# preprocess the cam.i files for RTTOV forward operator
        echo ""
        echo " python preprocess ..."
	for file in *cam.i*; do
            echo " process file:  ${file}"
	    python ${dirf}/rep_input.py ${file}
        done    

	# caminput cam_phis
        cp *0001*.cam.h0.${date}.nc ${tmpdir}/allTS/cam_phis.nc
        cp *0001*.cam.i.*.nc ${tmpdir}/allTS/caminput.nc

	# compute the departures
	cd ${tmpdir}/allTS
	##sed -i 's/##BSUB -I/#BSUB -I/g' run_filter_departures.bash
        
	#sed -i '/#BSUB -e assimilate.err/a #BSUB -I' run_filter_departures.bash
	#sed -i 's/export d4o_final=obs_seq\.final//g' run_filter_departures.bash
        sed -i '/#BSUB -e assimilate.err/a #BSUB -I' run_filter_departures_mg.bash      #CHANGE!!!!
	#sed -i 's/export d4o_final=obs_seq\.final//g' run_filter_departures_mg.bash     #CHANGE!!!!
	#bsub < run_filter_departures.bash
	bsub < run_filter_departures_mg.bash          #CHANGE!!!!

        # save the databases outside tmp and remove tmp
        if [ ! -d "${dirf}/fsoi_jo-db" ]; then
             mkdir -p "${dirf}/fsoi_jo-db"
             echo " Directory created: ${dirf}/fsoi_jo-db"
        else
             echo " Directory existing: ${dirf}/fsoi_jo-db"
	     rm -rf ${dirf}/fsoi_jo-db/*
        fi
        cp ${dirf}/tmp/allTS/*.db ${dirf}/fsoi_jo-db/  


        # post screening in particular for GPSRO

	#rm -rf ${dirf}/tmp

        # compute the FSOI-Jo with the python script
        # set parameter inside the python script correctly from here
        # FOR THE MOMENT TEST SEPARATELY THE PYTHON SCRIPT, ADD IN A FUTURE AFTER TESTING    
        # PASSING ARGUMENTS CASE NAME, ARCHDIR, START DATE FORECAST DATE VIA PARAMETERS TO PYTHON SCRIPT

    fi

done






#***************************************************
#           END
#***************************************************
echo " "
echo "****************** END ********************"
echo " "


