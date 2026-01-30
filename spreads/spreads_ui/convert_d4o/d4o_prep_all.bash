#!/bin/bash
#BSUB -L /bin/bash
#BSUB -n 288
#BSUB -R "span[ptile=72]"
#BSUB -q p_long
#BSUB -W 08:00
#BSUB -P R000
#BSUB -x
#BSUB -J d4o_prep
#BSUB -o prep.out
#BSUB -e prep.err
##BSUB -I
#set -x


set -eu
set -a


#-----------------------------------------------------------------------
# Set the env
#-----------------------------------------------------------------------

# Some more env var for hanging problem
export I_MPI_OFI_PROVIDER=mlx
export I_MPI_FABRICS=shm:ofi
export I_MPI_EXTRA_FILESYSTEM=1
export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
export MPI_COMM_MAX=16383
export I_MPI_DEBUG=5
export I_MPI_HYDRA_BOOTSTRAP=lsf
#export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_HOSTS | perl -pe 's/\s+/\n/g' | sort -u | wc -l) # the number of nodes allocated for this run 
export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_MCPU_HOSTS | perl -pe 's/\s+/\n/g' | grep -Pv '^\d+$' | sort -u | wc -l)

## D4O
if [[ ${CIME_MACH} = "zeus" ]]; then
    echo "run filter on Zeus"

    source /usr/share/Modules/init/bash

    export  XIOS_PATH=/work/cmcc/cmip01/csm/xios
    # check for comment
    export I_MPI_PLATFORM=skx
    # check for comment
    export I_MPI_SHM=skx_avx512
    export I_MPI_HYDRA_COLLECTIVE_LAUNCH=1

    source ../../d4o/load-modules-d4o.zeus

else
    echo "run filter on Juno"

    export I_MPI_PLATFORM=icx
    export I_MPI_SHM=icx

    module purge
    unset LIBRARY_PATH
    module load --auto intel-2021.6.0/2021.6.0
    module load --auto intel-2021.6.0/libszip/2.1.1-tvhyi
    module load --auto impi-2021.6.0/2021.6.0
    module load --auto anaconda/3-2022.10
    module load --auto intel-2021.6.0/sqlite/3.40.0-v3tky
    module load --auto intel-2021.6.0/perl-dbi/1.643-3satl
    module load --auto intel-2021.6.0/perl-dbd-sqlite/1.72-3f7xn
    module load --auto intel-2021.6.0/jasper/2.0.32-rofnd
    module load --auto intel-2021.6.0/libjpeg-turbo/2.1.4-tk73d
    export LIBRARY_PATH+=":$LD_LIBRARY_PATH" # without this line the build.juno does not find -ljpeg f.ex.
fi

module -t list

source /data/cmcc/${USER}/d4o/install/INTEL/source.me

# Utility functions:
#-----------------------------------------------------------------------
get_last_day_and_previous_month() {
    current_year=$1
    current_month=$2

    # Subtract 1 from the current month to get the previous month
    previous_month=$((current_month - 1))

    # Handle the case when the current month is January (previous month is December of the previous year)
    if [ $previous_month -eq 0 ]; then
        previous_month=12
        current_year=$((current_year - 1))
    fi

    # Get the last day of the previous month
    last_day=$(date -d "$current_year-$previous_month-01 +1 month -1 day" +'%d')

    # Assign the values to an array
    echo "$last_day $previous_month"
}

echo ""
echo "-------- START THE CONVERSION bufr->d4o --------"
echo ""


#-----------------------------------------------------------------------
# Script BUFR to D4O OBS PRORCESS
#-----------------------------------------------------------------------
#
EVENT=$1
#
YYYY=`echo $EVENT | cut -c1-4`
MM=`echo $EVENT | cut -c5-6`
echo "YEAR "$YYYY
echo "MONTH" $MM
#
# USER INPUT

EXP=$2

#TMPSLASH=/dev/shm
TMPSLASH=$3

INPUTDIR=$4

#Change here
WORKDIR=$5
WORKDIR=${WORKDIR}/b2d4o_${EXP}
mkdir -p  ${WORKDIR}
# How many ensemble members
NENS=$6

# Start conversion at DSTART and finish at DEND
DSTART=$7
DEND=$8



# remove old intermediate data
rm -rf ${TMPSLASH}
mkdir -p ${TMPSLASH}



#for DD in {08..09}; do
for ((IDD=${DSTART}; IDD<=${DSTART}; IDD++)); do
    printf -v DD "%02d" $IDD	
    echo "Day: ${DD}"	
    for UTC in "00" "06" "12" "18"; do
        #
        echo "Time (hr): ${UTC}"	
        rm -rf ${WORKDIR}/${YYYY}/${MM}/${YYYY}${MM}${DD}${UTC}/*
	mkdir -p ${WORKDIR}/${YYYY}/${MM}/${YYYY}${MM}${DD}${UTC}
	cd  ${WORKDIR}/${YYYY}/${MM}/${YYYY}${MM}${DD}${UTC}
	#
	#for bufrin in  SYNP; do
	#for bufrin in ARC AMV SND AMSU GPSRO WDP; do
	for bufrin in BUFR_LIST; do
        #
        #----6HR DATA ARRANGE  (+/- 3HR) ----
        #
        echo "Obs Type: ${bufrin}"	
        if [ ${UTC} = "00" ]; then
	   
	   if [ "${DD#0}" -gt 10 ]; then
              DDP=$((10#${DD}-1))
	      MMP=${MM}
           elif [ "${DD#0}" == "1" ]; then
              result_array=($(get_last_day_and_previous_month ${YYYY} ${MM})) 
	      DDP="${result_array[0]}"
	      MMP="${result_array[1]}" 
           else
              DDP=$(printf "%02d" $((10#${DD}-1)))
	      MMP=${MM}
           fi
           #
           file1=${INPUTDIR}/${YYYY}/${MMP}/${DDP}/${bufrin}_2100.bufr
           file2=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_0000.bufr
           if [ ${bufrin} = GPSRO ]; then
       	      cat ${file2}  > ${bufrin}
           else
       	      cat ${file1} ${file2}  > ${bufrin}
           fi   
        elif [ ${UTC} = "06" ]; then
           file1=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_0300.bufr
           file2=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_0600.bufr
           if [ ${bufrin} = GPSRO ]; then
       	      cat ${file2}  > ${bufrin}
           else
       	      cat ${file1} ${file2}  > ${bufrin}
           fi   
        elif [ ${UTC} = "12" ]; then
           file1=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_0900.bufr
           file2=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_1200.bufr
           if [ ${bufrin} = GPSRO ]; then
       	      cat ${file2}  > ${bufrin}
           else
       	      cat ${file1} ${file2}  > ${bufrin}
           fi   
        elif [ ${UTC} = "18" ]; then
           file1=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_1500.bufr
           file2=${INPUTDIR}/${YYYY}/${MM}/${DD}/${bufrin}_1800.bufr
           if [ ${bufrin} = GPSRO ]; then
       	      cat ${file2}  > ${bufrin}
           else
       	      cat ${file1} ${file2}  > ${bufrin}
           fi   
        fi
        echo ${file1}
        echo ${file2}
#-----------------------------------
	BASETIME=${YYYY}${MM}${DD}${UTC}
	rc=0
	tslots="1-13"
	npes=$LSB_MAX_NUM_PROCESSORS
	bjobs -l $LSB_JOBID | perl -pe 's/^\s+//; s/\n//'
	parallel=1  # 0
	errfile=$(pwd)/errfile.$$
	cat /dev/null > $errfile
        #
#-----------------------------------
            if [ ${bufrin} = ARC ]; then
		THINSM=4
		npools=4 # a guess
		kinds="--target_kinds=16-23" # please see kindmap.camfv.txt
            elif [ ${bufrin} = WDP ]; then
		THINSM=0
		npools=4 # a guess
		kinds="--target_kinds=40-41" # please see kindmap.camfv.txt
            elif [ ${bufrin} = AMV ]; then
		THINSM=10
		npools=20 # a guess
		parallel=20
		kinds="--target_kinds=34-35"
            elif [ ${bufrin} = SND ]; then
		THINSM=0
		npools=2 # a guess
		kinds="--target_kinds=5-6"
            elif [ ${bufrin} = SYNP ]; then
		THINSM=0
		npools=6 
		kinds="--target_kinds=1,24-33"
            elif [ ${bufrin} = WDP ]; then
		THINSM=0
		npools=2 
		kinds="--target_kinds=11-12,14-15"
            elif [ ${bufrin} = GPSRO ]; then
		THINSM=0
		npools=8
		kinds="--target_kinds=4"
            elif [ ${bufrin} = AMSU ]; then
                THINSM=6
                npools=20 # a guess
                parallel=20  # parallel less than npools if on /dev/shm
                ##kinds=""
                kinds="--target_kinds=129,130,133,134,137,138,141,145,214,220,224"
            fi
	    echo $THINSM   
#-----------------------------------
	    (set -x; \
	     (time bufr2d4o $bufrin $npools $parallel \
		   --camfv --basetime=$BASETIME --ens=${NENS} --thinning=$THINSM $kinds --psplit=$tslots --deferens) \
		 > output.$(basename $bufrin).log 2>&1 \
		 || echo "$burfin failed" >> $errfile) &
	    echo "$bufrin : launched with THINSM=$THINSM npools=$npools kinds=$kinds"
	done   # BURFINPUT FILE TYPE
	
	wait # for subprocesses to finish

	if [[ -s $errfile ]] ; then
	    echo "Something went wrong"
	    cat $errfile
	    exit 1
	fi

        echo "catalog.db creation ..."

	(set -x; time catalogd4o catalog.db "*.db") >> output.log 2>&1 || rc=$?
	#
	if [[ 0 -eq 1 ]] ; then # NOT executed since 0 != 1
            tslots="1-13"
            (set -x; time d4osplit parallel=1 ens=${NENS} $tslots "*.db") >> output.log 2>&1 || rc=$?
	fi

	# Create catalog databases under each timeslot dir

	for ts in {1..13}
	do 
            d=TS$ts
            if [[ -d $d ]] ; then
		cd $d
                echo "TS${d} catalog.db creation"
		(set -x; time catalogd4o catalog.db "*.db") >> output.log 2>&1 || rc=$?
		cd -
            fi
	done

	cd - # back to previous dir
	##
	echo "END UTC" $UTC
    done
    #    
done
#
echo ""
echo "-------- END THE CONVERSION bufr->d4o --------"
echo ""
