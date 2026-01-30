#!/bin/bash
#BSUB -n 10
#BSUB -R "span[ptile=10]" 
#BSUB -q p_short
#BSUB -W 1:00
#BSUB -P R000
#BSUB -x 
#BSUB -J spread-bs
#BSUB -o bs.out.%J
#BSUB -e bs.err.%J
#BSUB -I
#BSUB -app spreads_filter


echo "run post screening bs"

source /data/cmcc/$USER/d4o/install/INTEL/source.me

set -xeu

export I_MPI_EXTRA_FILESYSTEM=1
export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
export I_MPI_DEBUG=5 # should be enough; use 60 only if debugging seriously
export I_MPI_PLATFORM=icx
export I_MPI_SHM=icx
export I_MPI_HYDRA_BOOTSTRAP=lsf # probably ok when using LSF batch queuing system

export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_MCPU_HOSTS | perl -pe 's/\s+/\n/g' | grep -Pv '^\d+$' | sort -u | wc -l) # Juno has no LSB_HOSTS but uses instead LSB_MCPU_HOSTS

export I_MPI_JOB_ABORT_SIGNAL=6
export I_MPI_JOB_TIMEOUT_SIGNAL=6

npes=$LSB_MAX_NUM_PROCESSORS
echo "Number of processes to be used: $npes"
export LAUNCHCMD="mpirun -np $npes -bind-to core -prepend-rank " 
export I_MPI_PIN=1

# Some more env var for hanging problem
export I_MPI_OFI_PROVIDER=mlx
export I_MPI_FABRICS=shm:ofi
#export I_MPI_FABRICS=ofi

export d4o_ens_size=$(perl -ne '{printf("%d",$1), exit if (m{^\s*ens_size\s*=\s*(\d+)})}' input.nml)

# GPSRO BS
export d4o_hdr="codetype = 250"
 set +e
 gpsro_list=$(ls GPSRO*)
 set -e
 if [ $? -eq 0 ]; then
     /usr/bin/time -v ${LAUNCHCMD} ./postscreening.x ${gpsro_list}
 fi

# SYNP BS
export d4o_hdr="obstype = 1"
# set +e
synp_list=$(ls SYNP*)
if [ $? -eq 0 ]; then
    /usr/bin/time -v ${LAUNCHCMD} ./postscreening.x ${synp_list}
fi




