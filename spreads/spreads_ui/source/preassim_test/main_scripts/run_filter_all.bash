#!/bin/bash
# BSUB -n 1080
# BSUB -R "span[ptile=72]" 
# BSUB -q p_short
# BSUB -W 2:00
# BSUB -P R000
# BSUB -x 
#BSUB -J phase2_25N
#BSUB -o assimilate.out.%J
#BSUB -e assimilate.err.%J
## BSUB -m spreads_nodes
## BSUB -app spreads_filter

echo "run filter on Juno"

source /data/cmcc/$USER/d4o/install/INTEL/source.me

set -xeu

pwd
hostname

export I_MPI_EXTRA_FILESYSTEM=1
export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
#--export MPI_COMM_MAX=16383 # I have NEVER used/seen this before Dart/SPREADS, but its default is 256 -- watching this out
export I_MPI_DEBUG=5 # should be enough; use 60 only if debugging seriously
export I_MPI_PLATFORM=icx
export I_MPI_SHM=icx
export I_MPI_HYDRA_BOOTSTRAP=lsf # probably ok when using LSF batch queuing system
# export I_MPI_HYDRA_COLLECTIVE_LAUNCH=1  # I do not find this variable in Intel MPI at all

#--export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_HOSTS | perl -pe 's/\s+/\n/g' | sort -u | wc -l) # the number of nodes allocated for this run
export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_MCPU_HOSTS | perl -pe 's/\s+/\n/g' | grep -Pv '^\d+$' | sort -u | wc -l) # Juno has no LSB_HOSTS but uses instead LSB_MCPU_HOSTS

export I_MPI_JOB_ABORT_SIGNAL=6
export I_MPI_JOB_TIMEOUT_SIGNAL=6

npes=$LSB_MAX_NUM_PROCESSORS
echo "Number of processes to be used: $npes"
export LAUNCHCMD="mpirun -np $npes -bind-to core -prepend-rank" # binding to cores, plus prepending rank# for stdout/stderr outputs
export OMP_NUM_THREADS=1 # No OpenMP seen (yet) for SPREADS
#export KMP_AFFINITY="verbose,granularity=core,respect,scatter"
export KMP_AFFINITY=disabled
export I_MPI_PIN=1

# Some more env var for hanging problem
export I_MPI_OFI_PROVIDER=mlx
export I_MPI_FABRICS=shm:ofi
#export I_MPI_FABRICS=ofi

export d4o_debug=1:0
export d4o_catalog=catalog.db # since this env is activated we will use d4o, not obs_seq
export d4o_departures='all'

export d4o_final=obs_seq.final.$LSB_JOBID # we may not want this -- can be a resource hog at the end when all done
unset d4o_final

export d4o_inflation='yes'
#to check the state of the filter for the next step, if 2 is ok 
export d4o_ens_size=$(perl -ne '{printf("%d",$1), exit if (m{^\s*ens_size\s*=\s*(\d+)})}' input.nml)

# for better parallelization test one of the two parameter below!
#export d4o_bcast=1

#export d4o_shmem=0
export d4o_shmem=1

# Use non-blocking Isend+Irecv (and Ibcast when it works)
export non_blocking_comms=T # or t or 1
#export non_blocking_comms=F # or f or 0

#export d4o_hdr='obstype <> 7 and deglat >= -90 and deglat <= 90'
#export d4o_hdr='obstype <> 7 and deglat >= -30 and deglat <= 30'
#export d4o_hdr='deglat >= -30 and deglat <= 30'
#export d4o_hdr='deglat >= -30 and deglat <= 30'
#export d4o_hdr='deglat >= -10 and deglat <= 10'
#export d4o_hdr='deglat >= -1 and deglat <= 1'
#export d4o_hdr='deglat >= -2 and deglat <= 2'

export d4o_hdr='deglat >= -90 and deglat <= 90'
export d4o_body='dart_qc = 0'

# Considerable speed-up for database updates
#export d4o_update_threads=$(ls -C1 backups/*.[0-9]*.db|wc -l)
export d4o_update_threads=$(ls -C1 *.[0-9]*.db|wc -l)

rm -fv dart_log.nml dart_log.out

# Reproducible runs : get virgin fields & databases
#for f in backups/*.db backups/forecast_*nc backups/output_*.nc
#do
#    /usr/bin/cp -fv $f . &
#done
#wait 

#remember that we are in TMP dir
echo "0" > filter.flag

#echo "`date` -- BEGIN FILTER"

# Activate mpiP ? Remove comment from previous line
#export MPIP="-c -k 7 -l -n"

printenv > env.out.$LSB_JOBID
pwd
ls -ltra
ldd ./filter || :
rc=0

if [[ "${MPIP:-}" = "" ]] ; then
   /usr/bin/time -v ${LAUNCHCMD} ./filter > output.log.$LSB_JOBID 2>&1 || rc=$?
else
    /usr/bin/time -v ${LAUNCHCMD} env LD_PRELOAD=/users_home/cmcc/ss35621/mpiP/INTEL/lib/libmpiP.so ./filter > output.log.$LSB_JOBID 2>&1 || rc=$?
fi

#echo "`date` -- END FILTER"

mv dart_log.nml dart_log.nml.$LSB_JOBID || :
mv dart_log.out dart_log.out.$LSB_JOBID || :
if [ "$rc" -eq 0 ]; then
    echo "2" > filter.flag
else
    echo "Error in filter"
    exit 1
fi


pwd
ls -ltr

exit $rc
