# Welcome to the suite used to run SPREADS and CAM-FV

#==================================================================

 This is a simple suite writen in order to manage SPREAD and
 the CAM component of CESM, [http://www.cesm.ucar.edu/models/cesm2/](http://www.cesm.ucar.edu/models/cesm2/),
 at CMCC, [https://www.cmcc.it](https://www.cmcc.it).

 These scripts are tested on zeus machine. 

 Some disgnostic scripts are tested on local mac machine. 

 

## Source code tree

| Directory            | Purpose  |
| :--------------      | :------- |
| `case_archive/`      | Archive of the experiments templates. |
| `main_scripts/`      | Main scripts, e.g. create, cycle, assimilate and auxiliary txt files. |
| `diagnostics/`       | Routines to diagnose assimilation performance. |
| `docs/`              | Short presentation about the suite workflow and results. |
| **Files**            | **Purpose** |
| `CHANGELOG`          | Brief summary of recent changes. |
| `LICENSE`            | Terms of use and copyright information. |
| `README.md`          | Basic Information about the suite. |


## How to, structrure of the suite:

 ------------------------------------------------------------------
  
    1 - Creation of the clones

            USAGE:>
            nohup bsub < cases_create.sh > log.txt & (NEED FIXING, USE: sh cases_create.sh)


        You need to set some experiment variables in cases_create.sh, 
        in particular:

            case_name  (experiment name)
            clonesroot (where the cases of the single members will be created)
            nens       (number of clones)
            dartroot   (DART dir)
            tmpdir     (external dir where all the DART computation happens)
            archdir    (archive dir)
 

        Dependencies:
            
            cases_creates.sh -->  case.template.original
                             |
                             -->  input.nml.original

        In case.template.original you can set the CESM2 model experiment.
        In input.nml.original you can set the parameters for DART. 

 ------------------------------------------------------------------

    2 - Run the simulation


            USAGE:>
            nohup ./cases_cycles.sh > log.txt &           

        
        Variables to set:

            NCYCLES       (number of  CESM2, and possibly DART, cycles)
            CONT_RUN      (TRUE if start from a previous run, FALSE for the first cycle)
            ACTIVATE_ASSI (if TRUE then use the assimilation)
            MAXTRY        (number of attempts to make the assimilation in case of failure)
     
        Dependencies:
         
            cases_cycles.sh --> cases_assimilate.csh   -  
                            |                          |       
                            |                           -----> cases_check.sh
                            |                          |   
                            --> cases_no_assimilate.sh -   
                            |
                            |
                            |
                            --> cases_restart_management.sh 


        The first run uses NCYCLES=1 and CONT_RUN=FALSE.
        The scripts cases_assimilate.csh arranges the assimilation with DART and moves
        the outputs in the corrected dirs. cases_check.sh control that the CESM2 run
        are finished correctly. cases_restart_management.sh moves the restart files in/from
        a hidden dir to avoid problem with the st_archive. It also remove old restarts.

 ------------------------------------------------------------------

    3 - Diagnostic


            USAGE:>
            nohup ./cases_diag.sh > log_diag.txt &

        Variables to set:

        STARTDATE
        ENDDATE
        EXPNAME
        TMPROOT
        OBSDIAG            (TRUE or FALSE if you want activate or not the obs_diag program)
        OBS_TO_NETCDF      (TRUE or FALSE if you want activate or not the obs_to_netcdf program)
        ARCDIR          

        The ouputs saved could be explored with the python script included in the 
        others_post_proc_tools dir. 

 ------------------------------------------------------------------

#==================================================================


# How to use the main program:
bsub < cases_create.sh  

nohup ./cases_cycles.sh >&log.txt&

