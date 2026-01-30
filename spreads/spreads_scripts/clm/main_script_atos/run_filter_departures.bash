#!/bin/bash --login
#SBATCH -q np
#SBATCH -A itcmcc
#SBATCH -J d4o-phase1
#SBATCH -o d4o-phase1-%j.out
#SBATCH -N 2
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00

pwd
printenv | fgrep SLURM | sort
cd $SLURM_SUBMIT_DIR
pwd
rm -fv failed || :

branch=d4o-bs
jobid=$SLURM_JOB_ID # job id
jobname=$SLURM_JOB_NAME # job name

source $HPCPERM/d4o-bs/install/INTEL/source.me # d4o-bs
# source $HPCPERM/d4o/install/INTEL/source.me # d4o-bs

set -eux

nodes=$SLURM_JOB_NUM_NODES # number of nodes -- here 3
ppn=$SLURM_NTASKS_PER_NODE # processes or tasks per node -- here 128
cps=64 # cores per socket -- in this machine = 64
mpi=$SLURM_NPROCS # total number of MPI tasks -- here 3 x 128 
omp=${SLURM_CPUS_PER_TASK} # Number of OpenMP threads/task -- here 1
export OMP_NUM_THREADS=$omp
depth=${depth:-$omp} # about the same as OpenMP
#ht=${ht:-$(htset.pl $SLURM_NTASKS_PER_NODE $SLURM_CPUS_PER_TASK)} # hyperthreads -- here 1 (could be 2 per core, but strongly not recommended) : ht=1 implies --hint=nomultithread below
ht=1
# Running filter.x with help of ecbind :
export timecmd="/usr/bin/time -v"
export ecbind=$(which ecbind 2>/dev/null || echo ecbind)
export cmd="$timecmd srun -v -K1 -l --cpus-per-task=$omp --ntasks-per-node=$ppn --hint=nomultithread -N $nodes -n $mpi $ecbind -V0 --ppn $ppn -h $ht --depth $depth --bind=2 --places --cps $cps ${d4o_tool:-} ./filter"
#export cmd="$timecmd srun -v -K1 -l --hint=nomultithread -n $mpi $ecbind -V0 --ppn $ppn -h $ht --depth $depth --bind=2 --places --cps $cps ${d4o_tool:-} ./filter.x"
#export cmd="$timecmd srun -v -K1 -l --hint=nomultithread -n $mpi ${d4o_tool:-} ./filter.x"
export jobout=log.txt
export running=running.txt
cat /dev/null > $running
export envs=envs.txt

export jobout=log.txt

export maxdeglat=${maxdeglat:-90}

set -o pipefail
{
    set -xeu

    export d4o_shmem=1
    export d4o_bcast=1 # kind of redundant if d4o_shmem=1
    
    export backup=0
    export d4o_update_threads=$(ls -C1 *.[0-20]*.db|wc -l)
    export non_blocking_comms=T
    
    export d4o_maxdb=$(ls -C1 *.[0-20]*.db|wc -l)
    export d4o_debug=1:0
    export d4o_catalog=catalog.db
    #export d4o_final=obs_seq.final
    unset d4o_final
    export d4o_ens_size=$(perl -ne '{printf("%d",$1), exit if (m{^\s*ens_size\s*=\s*(\d+)})}' input.nml)
    export d4o_hdr="abs(deglat) <= $maxdeglat" 

    printenv | perl -ne 'BEGIN{$p=1} $p=0 if(m%^BASH_FUNC%); print if($p); $p=1 if (!$p&&m%^}\s*$%);' | sort > $envs

    ldd ./filter
    
    #*** Phase-1 ***
	
	export d4o_departures=yes # phase-1

	# rm -rfv failed dart_log.* ayt*nc forecast_*.nc output_*.nc obs_seq.final* || :
	rm -rfv failed || :
	pwd; ls -ltra
	
	rc=0
	$cmd || rc=$?

    mv dart_log.nml dart_log.nml.$jobid || :
    mv dart_log.out dart_log.out.$jobid || :

	if [[ $rc -ne 0 ]] ; then
	    echo "$rc" > failed
	fi
} 2>&1 | tee $jobout

retcode=$?

if [[ -s failed ]] ; then
    echo "Error in filter"
    echo "2" > filter.flag
else
    echo "0" > filter.flag
fi

set -x
exit $retcode