#!/bin/bash
#

#source /users_home/cmcc/lg07622/modules_juno.me

#CASE='clm5_sc_frac'
CASE=$1

#LND_DATE_EXT='2011-01-02-00000'
LND_DATE_EXT=$2

string_id=""


#==============================================
#     Function def
#==============================================
# Take the id of the case.submit processes
take_id()
{

  output=$("$@")
  #echo $output | awk '{print $NF}'
  echo 'OUTPUT '$output
  echo $output
}
#
# Function to process data for a specific year and month
process_data() {
#    nmen=$1
#    if [ -d tmp/$nmen ]; then rm -Rf tmp/$nmen; mkdir -p tmp/$nmen; fi
#    if [ ! -d tmp/$nmen ]; then mkdir -p tmp/$nmen; fi
#    cd $nmen
    

   #jobid=$(take_id ../../../bld/dart_to_clm)
   #d4o change of executables in directories
   jobid=$(take_id ../../dart_to_clm)

   #take_id ../../../bld/dart_to_clm
   #string_id=$string_id" done($jobid)"
   echo 'JOB_ID '$jobid
   #echo $string_id

}

export -f process_data
export -f take_id

unlink clm_vector_history   

# Initialize ensemble count
enscount=1

# Iterate over RESTART files matching the pattern
for RESTART in "${CASE}.clm2_"*.r."${LND_DATE_EXT}".nc; do

    NDIR='dd_'$enscount
    
    if [ -d tmp/$NDIR ]; then
      rm -Rf tmp/$NDIR
      mkdir -p tmp/$NDIR
    else
      mkdir -p tmp/$NDIR
    fi
    
    # Extract POSTERIOR_RESTART
    #change from 2.2 to 2.3??
    #POSTERIOR_RESTART="${RESTART/${CASE}.}"
    POSTERIOR_RESTART="${RESTART}"

    # Create POSTERIOR_VECTOR and CLM_VECTOR
    #change from 2.2 to 2.3??

    #POSTERIOR_VECTOR="analysis_member_00$(printf "%02d" $enscount)_d03.nc"
    #CLM_VECTOR="${CASE}.clm2_00$(printf "%02d" $enscount).h2.${LND_DATE_EXT}.nc"

    POSTERIOR_VECTORA="clm_analysis_member_00$(printf "%02d" $enscount)_d03.${LND_DATE_EXT}.nc"
    POSTERIOR_VECTORB="analysis_member_00$(printf "%02d" $enscount)_d03.nc"
    CLM_VECTOR="${CASE}.clm2_00$(printf "%02d" $enscount).h2.${LND_DATE_EXT}.nc"

    if [ -e $POSTERIOR_VECTORA ]; then
        #echo "EXISTS: $POSTERIOR_VECTORA"
        POSTERIOR_VECTOR=$POSTERIOR_VECTORA
    fi
    if [ -e $POSTERIOR_VECTORB ]; then
        #echo "EXISTS: $POSTERIOR_VECTORB"
        POSTERIOR_VECTOR=$POSTERIOR_VECTORB
    fi


    # Confirm the existence of H2OSNO prior/posterior files
    if [[ ! -e $POSTERIOR_VECTOR || ! -e $CLM_VECTOR ]]; then
        echo "ERROR: assimilate.sh could not find $POSTERIOR_VECTOR or $CLM_VECTOR"
        echo "When SWE re-partitioning is enabled H2OSNO must be"
        echo "within vector history file (h2). Also, the analysis"
        echo "stage must be output in 'stages_to_write' within filter_nml"
        exit 7
    fi

    # Copy necessary files
    cp input.nml "tmp/$NDIR/"

    # Change directory
    cd "tmp/$NDIR"

    # Create symbolic links
    ln -sf "../../$POSTERIOR_RESTART" "dart_posterior.nc"
    ln -sf "../../$POSTERIOR_VECTOR" "dart_posterior_vector.nc"
    ln -sf "../../$RESTART" "clm_restart.nc"
    ln -sf "../../$CLM_VECTOR" "clm_vector_history.nc"
    ln -sf "../../clm_history.nc" "clm_history.nc"

       kk=`bsub -J "process_${NDIR}" -oo "process_${NDIR}.log" << EOF
#!/bin/bash
#BSUB -P R000
#BSUB -W 00:20
#BSUB -n 2
#BSUB -q p_short
#BSUB -R "rusage[mem=2000]"
#BSUB -R "span[ptile=8]"
#BSUB -app spreads_filter
##BSUB -o %J.stdout
##BSUB -eo %J.stderr

# Load any necessary modules
source /users_home/cmcc/lg07622/modules_juno.me

# Change to the working directory
#cd "${dirwrk}"

# Call the function to process data for the current member
process_data
EOF`

jobid=`echo "${kk//<}" | awk '{print $2}'`
if [ $enscount -eq 1 ]; then 
  string_id=$string_id"post_done(${jobid//>})"
else
  string_id=$string_id" && post_done(${jobid//>})"
fi

cd ../../

((enscount++))
done

   echo " string_id = $string_id"
   bw=0
   bwait -w "$string_id" || bw=$?
   bjobs
   echo "ALL DART_TO_CLM JOBS FINISHED" 

exit

