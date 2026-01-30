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

#=========================================================================
# This block is an attempt to localize all the machine-specific
# changes to this script such that the same script can be used
# on multiple platforms. This will help us maintain the script.
#=========================================================================

echo "`date` -- BEGIN BOGUS CLM_ASSIMILATE"


echo "`date` -- END BOGUS CLM_ASSIMILATE"

exit 0

