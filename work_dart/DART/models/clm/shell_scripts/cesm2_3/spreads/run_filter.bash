#!/bin/bash
#
 
#BSUB -n 360
##BSUB -n 720
#BSUB -R "span[ptile=72]"
#BSUB -q p_short
#BSUB -W 00:30
#BSUB -P R000
#BSUB -x 
##BSUB -u giovanni.conti83@gmail.com
#BSUB -J assim_bnoso2 
##BSUB -o assimilate.out
##BSUB -e assimilate.err
##BSUB -sla SC_dev_dart
#BSUB -I
 
echo "start"
 
source /usr/share/Modules/init/bash
module purge
#module load intel20.1/20.1.217 intel20.1/szip/2.1.1 cmake/3.17.3 curl/7.70.0 impi20.1/19.7.217 impi20.1/hdf5/1.12.0 impi20.1/netcdf/C_4.7.4-F_4.5.3_CXX_4.3.1 impi20.1/parallel-netcdf/1.12.1 impi20.1/esmf/8.0.1-intelmpi-64-g
source /users_home/cmcc/lg07622/modules_juno.me



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
export I_MPI_HYDRA_BRANCH_COUNT=5 # it must be equal to the number of nodes!!!!!!!!! 
#module load intel20.1/nco/4.9.3
#module load intel20.1/magics/3.3.1
#module load intel20.1/eccodes/2.17.0
#module load ncl/6.6.2

echo "after module load"
module list

echo $LD_LIBRARY_PATH
 
# When run the assimilation use all the processors in all nodes
nproc_used=`echo "$I_MPI_HYDRA_BRANCH_COUNT * 72" | bc`
echo -e "\n Num. processor used: $nproc_used \n"
#export LAUNCHCMD="mpirun -np $nproc_used -bind-to core"
export LAUNCHCMD="mpiexec -n 360 -ppn 72"

export EXEROOT=/work/cmcc/lg07622/land/work/clm5/clm5_lai8

#echo "`date` -- BEGIN FILTER"
${LAUNCHCMD} ../bld/filter || exit 140
#echo "`date` -- END FILTER"
