#!/bin/bash

#BSUB -n 1080
#BSUB -R "span[ptile=72]"
#BSUB -q p_long
#BSUB -W 8:00
#BSUB -P R000
#BSUB -x 
#BSUB -J spreads_paper_02_mpi_fsoi 
#BSUB -o spreads_paper_02_mpi_fsoi.out
#BSUB -e spreads_paper_02_mpi_fsoi.err
##BSUB -I

module load impi-2021.6.0/2021.6.0

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
export LAUNCHCMD="mpirun -np $npes -bind-to core -prepend-rank" # binding to cores, plus prepending rank# for stdout/stderr outputs
export OMP_NUM_THREADS=1 # No OpenMP seen (yet) for SPREADS
export KMP_AFFINITY=disabled
export I_MPI_PIN=1

# Some more env var for hanging problem
export I_MPI_OFI_PROVIDER=mlx
export I_MPI_FABRICS=shm:ofi
#export I_MPI_FABRICS=ofi


export LAUNCHCMD="mpirun -np $npes -bind-to core -prepend-rank"


echo " "
echo " Removing old log"
echo " "
rm -f spreads_paper_02_mpi_fsoi.out spreads_paper_02_mpi_fsoi.err spreads_paper_02_mpi_fsoi.log*

echo " Execute the python program for the fsoijo computation"
rc=0
#/usr/bin/time -v ${LAUNCHCMD} python3 ./mpi_fsoijo_en.py  > mpi_fsoi.log.$LSB_JOBID 2>&1 || rc=$?
/usr/bin/time -v ${LAUNCHCMD} python3 ./spreads_paper_02_mpi_fsoijo_en.py  > spreads_paper_02_mpi_fsoi.log.$LSB_JOBID 2>&1 || rc=$?


