#!/bin/csh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# Resource file for use when running CESM (CLM specifically) and DART.
# This file has all the configuration items needed and will be copied
# into the CASEROOT directory to be used during an experiment.

# ==============================================================================
# Options defining the experiment:
#
# CASE          The value of "CASE" will be used many ways; directory and file
#               names both locally and (possibly) on the HPSS, and script names;
#               so consider its length and information content.
# compset       Defines the vertical resolution and physics packages to be used.
#               Must be a standard CESM compset; see the CESM documentation.
# resolution    Defines the horizontal resolution and dynamics; see CESM docs.
# cesmtag       The version of the CESM source code to use when building the code.
# num_instances The number of ensemble members.
#
# For list of the pre-defined component sets: ./query_config --compsets
# To create a variant compset, see the CESM documentation and carefully
# incorporate any needed changes into this script.
# ==============================================================================
setenv DIN_LOC_ROOT /data/inputs/CESM/inputdata
setenv CESMDATAROOT /data/inputs/CESM
#setenv cesmtag        cesm2.1.4-rc.08
#setenv cesmtag        /work/cmcc/lg07622/land/cesm2.1.4
setenv cesmtag        cesm_dart
#setenv resolution     f05_f05_mg17
setenv resolution     f05_f05_mn0253
#setenv compset        2000_DATM%GSWP3v1_CLM50%BGC-CROP_SICE_SOCN_HYDROS_SGLC_SWAV
setenv compset        HIST_DATM%GSWP3v1_CLM51%BGC-CROP_SICE_SOCN_SROF_SGLC_SWAV_SESP
#setenv compset        2000_DATM%CPLHIST_CLM50%BGC-CROP_SICE_SOCN_MOSART_SGLC_SWAV
# setenv num_instances  30
setenv num_instances  60

# Since this example was tested while assimilating solar induced fluorescence,
# we are using 'SIF' in the CASE. Assimilating SIF requires the use_SourceMods
# to be TRUE.

if (${num_instances} == 1) then
   setenv CASE clm5_f09_pmo_SIF
else
   #setenv CASE d4o_all31
   #setenv CASE control
   setenv CASE d4o_all60_aspar
endif

setenv off_inst 0

# ==============================================================================
# SourceMods for different versions of CESM are available at
# http://www.image.ucar.edu/pub/DART/CESM. Download the tar file that matches
# your CESM version and install the sourcefiles.
#
# SourceMods may be handled in one of two ways. If you have your own GIT clone of
# the repository, you may simply commit your changes to your GIT repo and 
# set use_SourceMods = FALSE . If you prefer to keep your changes separate 
# please put your SourceMods in a directory with 
# the following structure (which is intended to be similar to the structure 
# in the CLM distribution):
#
# ${SourceModDir}/src.clm
#                    |-- biogeochem
#                    |   `-- CNBalanceCheckMod.F90
#                    !-- biogeophys
#                    !   !-- CanopyFluxesMod.F90
#                    !   `-- PhotosynthesisMod.F90
#                    !   `-- SurfaceRadiationMod.F90
#                    `-- cpl/mct/
#                        `-- lnd_import_export.F90
#
# Description of the intent for each file:
#
# biogeochem/CNBalanceCheckMod.F90   Suppress balance checks for first restart step
#
# cpl/mct/lnd_import_export.F90      (deprecated) DS199.1 originally had some slightly
#                                    negative downward radiations that needed to be 
#                                    corrected.
#
# biogeophys/SurfaceRadiationMod.F90 Allows the use of 'PARVEG' in a history file.
#                                    Normally, only 'PARVEGLN' is output.
#
# biogeophys/CanopyFluxesMod.F90,PhotosynthesisMod.F90 calculate SIF

setenv use_SourceMods TRUE
#setenv SourceModDir   /work/cmcc/lg07622/land/work/clm5/externals/SourceMods_release-cesm2.2.01/SourceMods
#setenv SourceModDir   /work/cmcc/lg07622/land/SourceMods/SourceMods_release-cesm2.3_lgg/SourceMods
setenv SourceModDir  /work/cmcc/spreads-lnd/land/datain/SourceMods_release-cesm2.3_lgg/SourceMods

# ==============================================================================
# Directories:
# cesmdata     Location of some supporting CESM data files.
# cesmroot     Location of the CESM code base.
# caseroot     Defines the CESM case directory - where the CESM+DART
#              configuration files will be stored.  This should probably not
#              be on a fileystem that is scrubbed.
#              This script WILL DELETE any existing caseroot, so this script,
#              and other useful things should be kept elsewhere.
# rundir       Defines the location of the CESM run directory.  Will need large
#              amounts of disk space, generally on a scratch partition.
# exeroot      Defines the location of the CESM executable directory , where the
#              CESM executables will be built.  Medium amount of space
#              needed, generally on a scratch partition.
# archdir      Defines the location of the CESM short-term archive directories.
#              Files remain here until the long-term archiver moves them to 
#              permanent storage.  Requires large amounts of disk space. Should
#              not be on a scratch partition unless the long-term archiver is 
#              invoked to move these files to permanent storage.

setenv cesmdata         /glade/p/cesmdata/cseg/inputdata
#setenv cesmroot         /work/cmcc/lg07622/land/cesm2.1.4-rc.08
#setenv cesmroot         /users_home/cmcc/lg07622/cesm2_1_intel20_1
#setenv cesmroot         /work/cmcc/lg07622/land/work/clm5/externals/cesm_dart
setenv cesmroot         /users_home/cmcc/dp16116/CMCC-CM_v9
#setenv cesmroot         /work/cmcc/lg07622/land/cesm_dart
#setenv cesmroot         /work/cmcc/gc02720/mod-dev/cesm2.3_beta06
#setenv cesmroot         /work/cmcc/lg07622/land/${cesmtag}
#setenv caseroot         /glade/work/${USER}/cases/${cesmtag}/${CASE}
setenv caseroot         /work/cmcc/spreads-lnd/work_d4o/${CASE}
setenv cime_output_root /work/cmcc/spreads-lnd/work_d4o/${CASE}
setenv rundir           ${cime_output_root}/run
setenv exeroot          ${cime_output_root}/bld
setenv archdir          ${cime_output_root}/archive

# ==============================================================================
# Set the variables needed for the DART configuration.
# dartroot     Location of the root of _your_ DART installation
# baseobsdir   Part of the directory name containing the observation sequence 
#              files to be used in the assimilation. The observations are presumed
#              to be stored in sub-directories with names built from the year and
#              month. 'baseobsdir' will be inserted into the appropriate scripts.
# ==============================================================================

setenv dartroot               /work/cmcc/spreads-lnd/work_dart/DART
setenv baseobsdir             /work/cmcc/lg07622/land/datain/observations/ESA_CCI_SM/obs/all
setenv pmo_input_baseobsdir   /glade/p/cisl/dares/Observations/land/pmo/input
setenv pmo_output_baseobsdir  /glade/p/cisl/dares/Observations/land/pmo/output

# ==============================================================================
# configure settings:
#
# refcase    Name of the existing reference case that this run will start from.
# refyear    The specific date/time-of-day in the reference case that this
# refmon     run will start from.  (Also see 'runtime settings' below for
# refday     start_year, start_mon, start_day and start_tod.)
# reftod
#
# stagedir   The directory location of the reference case files.
#
# startdate  The date used as the starting date for the hybrid run.
# ==============================================================================

#setenv refcase     cm3_lndHIST_bgc_NoSnAg_eda1_hist
setenv refcase     control60
#setenv refcase     lnd_secn
#the refcase below is a result from a firt init run using the refcase above
#setenv refcase     finidat_interp_dest
setenv refyear      2006
setenv refmon       01
setenv refday       01
setenv reftod       00000
setenv refdate      ${refyear}-${refmon}-${refday}
setenv reftimestamp ${refyear}-${refmon}-${refday}-${reftod}

#setenv stagedir /work/cmcc/lg07622/land/datain/refcase/cmcc/seasonal/2000
# the stagedir below was generated after a initial run using the stagedir above
#setenv stagedir /work/cmcc/lg07622/land/datain/refcase/cmcc/2000
#setenv stagedir /work/cmcc/lg07622/land/work/clm5_23/lnd_secn/run
setenv stagedir /work/cmcc/lg07622/land/work/d4o/control60/run
# In a hybrid configuration, you can set the startdate to whatever you want.
# It does not have to match the reference (although changing the month/day seems bad).
# runtime settings:

setenv start_year    2000
setenv start_month   01
setenv start_day     01
setenv start_tod     00000
setenv startdate     ${start_year}-${start_month}-${start_day}

# ==============================================================================
# OSSE/Perfect Model experiments only.
# If there is an ensemble of CLM states to choose from, which one do you want as
# the truth? There is an argument for picking an instance that will not be part
# of the ensemble used for the assimilation experiment. 

setenv SingleInstanceRefcase FALSE
setenv TRUTHinstance 80

# ==============================================================================
# The forward operators for the flux tower obs REQUIRE that we predict the name of
# of the history file. The history file names of interest are time-tagged with the
# START of the forecast - not the restart time. The obs_def_tower_mod.f90 requires
# the stop_option to be 'nhours', and the stop_n to be accurate.
#
# stop_option   Units for determining the forecast length between assimilations
# stop_n        Number of time units in each forecast
# resubmit      How many job steps to run on continue runs (should be 0 initially)

setenv stop_option  nhours
setenv stop_n       24
setenv resubmit     0

# clm_dtime     CLM dynamical timestep (in seconds). 1800 is the default
# h1nsteps      is the number of time steps to put in a single CLM .h1. file
#               DART needs to know this and the only time it is known is during
#               this configuration step. Changing the value later has no effect.

@ clm_dtime = 1800
@ h1nsteps = $stop_n * 3600 / $clm_dtime

# ==============================================================================
# Settings for the data atmosphere

setenv stream_year_align 2000
setenv stream_year_first 2000
setenv stream_year_last  2000

# ==============================================================================
# machine-specific commands:

#setenv project      P86850054
#setenv machine      cheyenne
setenv project      R000
setenv mach      juno

# The CESM compile step takes enough resource that Cheyenne requires a wrapper
# If your platform does not have this restriction, set BUILD_WRAPPER to '' 
# setenv BUILD_WRAPPER ''
#setenv BUILD_WRAPPER "qcmd -q share -l select=1 -A $project --"
setenv BUILD_WRAPPER ""
setenv nodes_per_instance 2
setenv number_of_threads 1

# ==============================================================================
# The FORCE  options are not optional. You may need to specify full paths
# to alternate locations that support the '-f' option.
# The VERBOSE options are useful for debugging though
# some systems don't like the -v option to any of the following
# ==============================================================================
set nonomatch       # suppress "rm" warnings if wildcard does not match anything

set   MOVE = 'mv -v'
set   COPY = 'cp -v --preserve=timestamps'
set   LINK = 'ln -vs'
set REMOVE = 'rm -rf' 

exit 0

