#!/bin/csh

module purge
unsetenv LIBRARY_PATH

module load --auto anaconda/3-2024.10-1
module load --auto oneapi-2025.0.4/2025.0.4-bwtfc
module load --auto oneapi-2025.0.4/impi-2021.14.2/2021.14.2-e7cvt
module load --auto oneapi-2025.0.4/intel-oneapi-runtime/2025.0.4-dflrt
module load --auto oneapi-2025.0.4/autoconf/2.72-vnerg
module load --auto oneapi-2025.0.4/libszip/2.1.1-jawpw
module load --auto oneapi-2025.0.4/sqlite/3.46.0-cuoh5
module load --auto oneapi-2025.0.4/jasper/4.2.4-us3na
module load --auto oneapi-2025.0.4/libjpeg-turbo/3.0.3-h24zj
module load --auto oneapi-2025.0.4/libunwind/1.8.1-qgmuc
module load --auto gcc-11.4.1/gcc-runtime/11.4.1-pewvn

# Perl (new stack ships base perl, DBI/DBD::SQLite are bundled)
module load --auto gcc-11.4.1/perl/5.32.1-xel5x
module load --auto oneapi-2025.0.4/intel-oneapi-tbb/2022.0.0-uw267

# Sync LIBRARY_PATH with LD_LIBRARY_PATH
if ( $?LD_LIBRARY_PATH ) then
    setenv LIBRARY_PATH ":${LD_LIBRARY_PATH}"
else
    setenv LIBRARY_PATH ":"
endif

# TBB malloc setup
setenv TBBMALLOC_DIR "$TBBROOT/lib/intel64/gcc4.8"
if ( -d "$TBBMALLOC_DIR" ) then
    if ( $?LD_LIBRARY_PATH ) then
        setenv LD_LIBRARY_PATH "${TBBMALLOC_DIR}:${LD_LIBRARY_PATH}"
    else
        setenv LD_LIBRARY_PATH "${TBBMALLOC_DIR}"
    endif
    setenv TBB_MALLOC_USE_HUGE_PAGES 1
    if ( ! $?TBB_MALLOC_SET_HUGE_SIZE_THRESHOLD ) then
        setenv TBB_MALLOC_SET_HUGE_SIZE_THRESHOLD 8388608
    endif
else
    unsetenv TBBMALLOC_DIR
endif
# Hugepages
setenv HUGETLB_DEFAULT_PAGE_SIZE 2M
setenv HUGETLB_MORECORE yes

# Intel MPI tuning (Xeon Max + NDR)
setenv I_MPI_EXTRA_FILESYSTEM 1
setenv I_MPI_EXTRA_FILESYSTEM_FORCE gpfs
setenv I_MPI_DEBUG 5
setenv I_MPI_PLATFORM icx
setenv I_MPI_SHM icx
setenv I_MPI_HYDRA_BOOTSTRAP lsf
setenv I_MPI_JOB_ABORT_SIGNAL 6
setenv I_MPI_JOB_TIMEOUT_SIGNAL 6
setenv I_MPI_JOB_SIGNAL_PROPAGATION 1
setenv I_MPI_PIN 1
setenv I_MPI_PIN_DOMAIN "omp:compact"
setenv I_MPI_PIN_ORDER "compact"
setenv I_MPI_OFI_PROVIDER mlx
setenv I_MPI_FABRICS shm:ofi

# Xeon Max: 112 cores per node → scatter across cores
setenv KMP_AFFINITY "granularity=core,respect,scatter"

echo "+ module -t list"
module -t list

