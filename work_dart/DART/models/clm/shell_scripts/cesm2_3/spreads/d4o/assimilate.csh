#!/bin/csh

#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# This script performs an assimilation by directly reading and writing to
# the CLM restart file.
#
# NOTE: 'dart_to_clm' does not currently support updating the 
# prognostic snow variables based on posterior SWE values.
# Consequently, snow DA is not currently supported.
# Implementing snow DA is high on our list of priorities. 


# HISTORY
#
# author            version     comments
# Luis Gustavo      none        Original version
# Denis Eiras       1.0.0       One submission version - Paralelized modules - firtst github version


echo "`date` -- BEGIN CLM_ASSIMILATE benchmark"
setenv now_yyyymmddss `date +%Y%m%d%H%M%S`

# As of CESM2.0, the assimilate.csh is called by CESM - and has
# two arguments: the CASEROOT and the DATA_ASSIMILATION_CYCLE
if ($# == 0) then
    echo "Error: CASEROOT (parameter 1) is missing."
    exit 1
endif

if ($# < 2) then
    echo "Error: ASSIMILATION_CYCLE (parameter 2) is missing."
    exit 1
endif

# Script arguments (values provided on the command line)
#
setenv CASEROOT $1
setenv ASSIMILATION_CYCLE $2


# xmlquery must be executed in $CASEROOT.
cd ${CASEROOT}
setenv CASE           `./xmlquery CASE        --value`
setenv ENSEMBLE_SIZE  `./xmlquery NINST_LND   --value`
setenv TOTALPES       `./xmlquery TOTALPES    --value`
setenv TASKS_PER_NODE `./xmlquery MAX_TASKS_PER_NODE --value`
setenv LOGFILE "assimilate___${CASE}_${ENSEMBLE_SIZE}_${TOTALPES}_${TASKS_PER_NODE}_${now_yyyymmddss}.log"

# Call and wait the child script
# Execute the command and capture the return code
# Execute the command and capture the output

setenv machine `./xmlquery MACH --value`

if ( "$machine" == "juno" ) then
    bsub -K \
        -P 0575 \
        -J "${CASE}" \
        -W 00:20 \
        -o "${LOGFILE}" \
        -e "${LOGFILE}" \
        -x \
        -n "${TOTALPES}" \
        -R "span[ptile=${TASKS_PER_NODE}]" \
        -q p_short \
        -app spreads_filter \
        < ./assimilate_executor.csh
else  
    echo "Submitting to cassandra" 
    bsub < /work/cmcc/de34824/lsf_tests/arch_parallel.lsf
endif


# Capture the exit status of the command
set ret_exec_ass = $status

# Use the exit status in an if statement
if ($ret_exec_ass == 0) then
    echo "***** Assimilation succeeded ! *****"
else
    echo "***** Assimilation FAILED ! *****"
endif
echo "=====> Exit status: $ret_exec_ass"
echo "LOG FILE: ${LOGFILE}"

echo "`date` -- END CLM_ASSIMILATE benchmark"

exit $ret_exec_ass