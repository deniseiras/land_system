#!/bin/bash
#
 
#BSUB -n 540
#BSUB -R "span[ptile=36]"
#BSUB -q p_short
#BSUB -W 0:30
#BSUB -P R000
#BSUB -x 
##BSUB -u giovanni.conti83@gmail.com
#BSUB -J run_filter 
#BSUB -o assimilate.out
#BSUB -e assimilate.err
##BSUB -sla SC_dev_dart
##BSUB -I
 
echo "start"
 
source /usr/share/Modules/init/bash
#module purge
#module load intel20.1/20.1.217 intel20.1/szip/2.1.1 cmake/3.17.3 curl/7.70.0 impi20.1/19.7.217 impi20.1/hdf5/1.12.0 #impi20.1/netcdf/C_4.7.4-F_4.5.3_CXX_4.3.1 impi20.1/parallel-netcdf/1.12.1 impi20.1/esmf/8.0.1-intelmpi-64-g



export  XIOS_PATH=/work/cmcc/cmip01/csm/xios
# check if 0
export I_MPI_EXTRA_FILESYSTEM=1
# check for comment
export I_MPI_EXTRA_FILESYSTEM_FORCE=gpfs
export MPI_COMM_MAX=16383
export I_MPI_DEBUG=60
#export GPFSMPIO_TUNEBLOCKING=0
# check for comment
export I_MPI_PLATFORM=skx
# check for comment
export I_MPI_SHM=skx_avx512
export I_MPI_HYDRA_BOOTSTRAP=lsf
#export I_MPI_LSF_USE_COLLECTIVE_LAUNCH 0
export I_MPI_HYDRA_COLLECTIVE_LAUNCH=1
export I_MPI_HYDRA_BRANCH_COUNT=15 # it must be equal to the number of nodes!!!!!!!!! 
#module load intel20.1/nco/4.9.3
#module load intel20.1/magics/3.3.1
#module load intel20.1/eccodes/2.17.0
#module load ncl/6.6.2


## D4O
module purge
module load cmake/3.17.3
module load intel20.1/20.1.217
module load intel20.1/szip/2.1.1
module load curl/7.70.0
module load impi20.1/19.7.217
#module load anaconda/3.9 # gives access to python 3
module load dbi/1.643
module load sqlite/3.38.0
module load dbd-sqlite/1.70

source /data/cmcc/${USER}/d4o/install/INTEL/source.me

echo "after module load"
module list
 
# When run the assimilation use all the processors in all nodes
nproc_used=`echo "$I_MPI_HYDRA_BRANCH_COUNT * 36" | bc`
echo -e "\n Num. processor used: $nproc_used \n"
export LAUNCHCMD="mpiexec.hydra -np $nproc_used -bind-to core -prepend-rank"

export d4o_debug=1:0
export d4o_catalog=catalog.db # since this env is activated we will use d4o, not obs_seq
export d4o_departures="no"
 
# to check the state of the filter for the next step, if 2 is ok 
# re,ember that we are in TMP dir
echo "0" > filter.flag

#echo "`date` -- BEGIN FILTER"
${LAUNCHCMD} ./filter || exit 140
#echo "`date` -- END FILTER"

echo "2" > filter.flag

exit
