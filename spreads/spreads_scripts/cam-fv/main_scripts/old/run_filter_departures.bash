#!/bin/bash
#
 
#BSUB -n 1080
##BSUB -n 576
#BSUB -R "span[ptile=72]"
##BSUB -n 540
##BSUB -R "span[ptile=36]"
#BSUB -q p_medium
#BSUB -W 4:00
#BSUB -P R000
#BSUB -x 
##BSUB -u giovanni.conti83@gmail.com
#BSUB -J assim_bnoso2 
#BSUB -o assimilate.out
#BSUB -e assimilate.err

 
echo "start"
 
## D4O
echo $CIME_MACH
if [[ ${CIME_MACH} = "zeus" ]]; then
    echo "run filter on Zeus"

    source /usr/share/Modules/init/bash

    export  XIOS_PATH=/work/cmcc/cmip01/csm/xios
    # check if 0
    export I_MPI_EXTRA_FILESYSTEM=1
    # check for comment
    export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
    export MPI_COMM_MAX=16383
    export I_MPI_DEBUG=5
    #export GPFSMPIO_TUNEBLOCKING=0
    # check for comment
    export I_MPI_PLATFORM=skx
    # check for comment
    export I_MPI_SHM=skx_avx512
    export I_MPI_HYDRA_BOOTSTRAP=lsf
    #export I_MPI_LSF_USE_COLLECTIVE_LAUNCH 0
    export I_MPI_HYDRA_COLLECTIVE_LAUNCH=0
    export I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_HOSTS | perl -pe 's/\s+/\n/g' | sort -u | wc -l) # the number of nodes allocated for this run


    module purge
    module load cmake/3.17.3
    module load intel20.1/20.1.217
    module load intel20.1/szip/2.1.1
    module load curl/7.70.0
    module load impi20.1/19.7.217
    module load anaconda/3.9 # gives access to python 3
    module load dbi/1.643
    module load sqlite/3.38.0
    module load dbd-sqlite/1.70
else
    echo "run filter on Juno"

    export I_MPI_EXTRA_FILESYSTEM=1
    export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
    export MPI_COMM_MAX=16383 # I have NEVER used/seen this before Dart/SPREADS, but its default is 256 -- watching this out
    export I_MPI_DEBUG=5 # should be enough; use 60 only if debugging seriously
    export I_MPI_PLATFORM=icx
    export I_MPI_SHM=icx
    export I_MPI_HYDRA_BOOTSTRAP=lsf # probably ok when using LSF batch queuing system
    export I_MPI_HYDRA_COLLECTIVE_LAUNCH=0  # I do not find this variable in Intel MPI at all
    export I_MPI_HYDRA_BRANCH_COUNT=15 #$(echo $LSB_HOSTS | perl -pe 's/\s+/\n/g' | sort -u | wc -l) # the number of nodes allocated for this run

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
    module -t list
fi

source /data/cmcc/${USER}/d4o/install/INTEL/source.me

echo "after module load"
module list

echo $LD_LIBRARY_PATH

#npes=$(echo "$I_MPI_HYDRA_BRANCH_COUNT * 72" | bc)  # 72 was 36 on Zeus
npes=$LSB_MAX_NUM_PROCESSORS
echo "Number of processed to be used: $npes"
#export LAUNCHCMD="mpirun -np $npes -bind-to none" # *never* use bind to none !
export LAUNCHCMD="mpirun -np $npes -bind-to core -prepend-rank" # binding to cores, plus prepending rank# for stdout/stderr outputs
export OMP_NUM_THREADS=1 # No OpenMP seen (yet) for SPREADS
export KMP_AFFINITY="verbose,granularity=core,respect,scatter"
export I_MPI_PIN=1
export I_MPI_JOB_ABORT_SIGNAL=6
export I_MPI_JOB_TIMEOUT_SIGNAL=6


#rc=0
#/usr/bin/time -v ${LAUNCHCMD} ./filter > output.log 2>&1 || rc=$?


# Some more env var for hanging problem
export I_MPI_OFI_PROVIDER=mlx
#export I_MPI_FABRICS=shm:ofi
export I_MPI_FABRICS=ofi




## When run the assimilation use all the processors in all nodes
#nproc_used=`echo "$I_MPI_HYDRA_BRANCH_COUNT * 36" | bc`
#echo -e "\n Num. processor used: $nproc_used \n"
##export LAUNCHCMD="mpirun -np $nproc_used -bind-to core"
#export LAUNCHCMD="mpiexec.hydra -n 540 -ppn 36"

export d4o_debug=1:0
export d4o_catalog=catalog.db # since this env is activated we will use d4o, not obs_seq
#export d4o_hdr="id in (7908)"
export d4o_departures='yes'
export d4o_final=obs_seq.final
export d4o_inflation='yes'
#to check the state of the filter for the next step, if 2 is ok 
export d4o_ens_size=$(perl -ne '{printf("%d",$1), exit if (m{^\s*ens_size\s*=\s*(\d+)})}' input.nml)

# for better parallelization test one of the two parameter below!
#export d4o_bcast=1
export d4o_shmem=1

export d4o_hdr='deglat >= -90 and deglat <= 90'

 #remember that we are in TMP dir
echo "0" > filter.flag

#echo "`date` -- BEGIN FILTER"
${LAUNCHCMD} ./filter || exit 140
#echo "`date` -- END FILTER"

echo "2" > filter.flag

exit
