# Land System
Repository for running the Land spreads d4o system in Cassandra Supercomputer (initially) . 

Includes and manages all repos necessary for running: spreads, CMCC-CM and DART, that was not being managed in repositories in JUNO (Check the Repository Structure Section)

The idea is to maintain all this repositories in this one. If some change, applied in here, needed to be applied in the original repositories, the change must be applied mannually.


## System instalation (Spreads - d4o)

Download the code **preferably** in the the folder /work/cmcc/$USER , to avoid changing some configuration parameters.
```
/work/cmcc/$USER
git clone https://github.com/deniseiras/land_system.git
```
This will download the system in the land_system folder.

Enter in the d4o root folder
```
cd land_system/spreads/d4o
````

OPTIONAL: Update the `branch` variable if needed (i.e., a second installation) in the `build.cassandra` file, because this variable is used in the installation directory definition.

Then, compile all the d4o, including libraries:
```
make cassandra
```
**Note the installed libraries in the installation directories have static linkin to the current directory (spreads/d4o). It means you cannot move the land_system root directory or others inside spreads folder, otherwise will you find problems when recompiling or running the system**

In case of sucess, you will see a message like :

```txt
===> To initialize your d4o-environment under INTEL : source /data/cmcc/<USER>/<BRANCH>/install/INTEL/source.me
+ exit 0
>>> Build log now in the <YOUR_ROOT>/land_system/spreads/d4o/.build-log.INTEL.1234567890.txt
```

Then, source the file as shown in the message to proceed with the running.

Compile flattened/clm/fill_inflation_restart.dir:
```
cd <YOUR_ROOT>/land_system/spreads/d4o/flattened/clm/fill_inflation_restart.dir
make clean
make -j 8
```
Compile flattened/clm/filter.dir:
```
cd <YOUR_ROOT>/land_system/spreads/d4o/flattened/clm/filter.dir
make clean
make -j 8
```
Compile flattened/clm/clm_to_dart.dir:
```
cd <YOUR_ROOT>/land_system/spreads/d4o/flattened/clm/clm_to_dart.dir
make clean
make -j 8
```
Compile flattened/clm/dart_to_clm.dir:
```
cd <YOUR_ROOT>/land_system/spreads/d4o/flattened/clm/dart_to_clm.dir
make clean
make -j 8 
```

## Repository structure:

```
Source files
.
├── CMCC-CM
│   ├── ccs_config
│   ├── cime_config
│   └── ...
├── land
│   └── datain
├── spreads
│   ├── d4o
│   ├── spreads_ui
│   └── ...
├── work_d4o
└── work_dart
    └── DART

Install files
/data
└──cmcc
    └──<USER>
        └──<BRANCH>
            └──install
```

Details of the origin source files and files updated during the migration:

- land/datain
  - Input data folder. Empty in here. You must copy your datain inside this     structure or remove the datain dir and create a link to your datain.

- spreads/d4o
   - original git source: branch d4o-land - https://github.com/lgggoncalves/SPREADS.git
   - modified files for Cassandra porting:
     - ECMWF/eckit-1.19.0-Source/src/eckit/utils/Optional.h
     - Makefile 
     - build.cassandra
     - build.cassandra.INTEL.source.me
     - load-modules-d4o.cassandra*
- spreads/spreads_ui: 
   - ecflow structure (TODO in future if needed)

- CMCC-CM
  - original git source: branch cmcc-cm - https://github.com/CMCC-Foundation/CMCC-CM.git
- CMCC-CM/cime_config
    - cime_config/testlist_allactive.xml
    - cime_config/config_pes.xml
- CMCC-CM/ccs_config 
    - sub repository: branch cmcc-cm_cp1 - https://github.com/CMCC-Foundation/ccs_config_cmcc
    - machines/config_batch.xml
    - machines/config_machines.xml
    - machines/config_workflow.xml
    - machines/cmake_macros/intel_cassandra.cmake
     
- work_d4o
  - experiments output folder

- work_dart/DART
    - original git source: branch main - https://github.com/NCAR/DART.git

## System execution using EC Flow (TODO)

## System execution using scripts

### Building and running the CLM model

#### 1. Experiment definition

After the d4o installation (above), source the file as shown in the message in the installation section.

Then ...
```
cd <LAND_SYSTEM_ROOT>/work_dart/DART/models/clm/shell_scripts/cesm2_3 
```


Copy the templates using a new name for your experiment, i.e **TEST_GSWP** (can be different than the experiment name defined after in the variable `CASE`) :
```
cp ./spreads/d4o/DART_params_d4o_template_GSWP.csh ./DART_params_d4o_TEST_GSWP.csh 
cp ./spreads/d4o/CLM5_CMCC_d4o_template_GSWP ./CLM5_CMCC_d4o_TEST_GSWP
```

Now, configure the experiment.  

First, in `./DART_params_d4o_TEST_GSWP.csh`, set the variables:
- num_instances = the number of members (integer)
- CASE = name of the experiment, in example: `TEST_GSWP`
- ref* = refers to variables that compose the IC (i.e. refcase = d4o_all60_as, refyear = 2002 etc). 
- stagedir = check the stage dir path, which uses the refcase variable.
- start_* = refers to the date of start of execution. 
- stop_n = days in a cycle
- any other optional parameters 

Now change in the file `CLM5_CMCC_d4o_TEST_GSWP`	:
- change line `source DART_params_d4o_template_GSWP.csh` to point the file  `DART_params_d4o_TEST_GSWP.csh`
- Change the `<SOURCE>` file from the line:
 `${COPY} <SOURCE> ${caseroot}/DART_params.csh ` for your file, i.e. `DART_params_d4o_TEST_GSWP.csh`
- number of tasks (Optional, already tunned for Cassandra): refers to the number of processes per member. (min = 1 ; max = number of cores per node).  I.e. , Cassandra has 112 cores per node. Could use 56, i.e. More tasks may have more performance. Example.
  - ./xmlchange NTASKS=56 
  - ./xmlchange NTASKS_LND=56 

Check the forcings pointed by the `SOURCEDIR` variable: check the files in that directory. Check the files named `user_nl*` related to the members you’re using.
It must exist a file named `user_nml_datm_streams_<member_num>`,  in the directory referred to in the variable *SOURCEDIR* inside file `CLM5_CMCC_d4o_TEST_GSWP`, that points to the forcing netcdf files, which must have data from the day before the start date.

#### 2. Experiment construction

Run the script to build the experiment 
```
./CLM5_CMCC_d4o_TEST_GSWP
```

If the experiment build was successful, proceed to the next step.

#### 3. Model run

Start by:
```
cd <LAND_SYSTEM_ROOT>/work_d4o/TEST_GSWP
./case.submit 	
```

Check cesm.stdout.<JOBID> for errors and  cesm.stderr.<JOBID> for errors. The error below is not an error actually, ignore it. (TODO fix) 

  ERROR: Model did not complete - see ./work_d4o/TEST_GSWP/run/drv.log.528704.250306-110110 


Also, check in the run dir:
- ESMF_Profile.summary was created
- rpointer files points to the date after the run date 
- History netcdf files were created: I.e. TEST_GSWP.clm2_<MEMBER>.h<HISTORY>.2000-01-02-00000.nc
- Restart file netcdf files were created: I.e. TEST_GSWP.clm2_<MEMBER>.r.2000-01-03-00000.nc
- Files (?)  were created: I.e. TEST_GSWP.clm2_<MEMBER>.rh<HISTORY>.2000-01-03-00000.nc
- Files (?)  were created: I.e. TEST_GSWP.cpl_<MEMBER>.r.2000-01-03-00000.nc
- Files (?)  were created: I.e. TEST_GSWP.datm_<MEMBER>.r.2000-01-03-00000.nc

### Assimilation configuration

With everything ok, copy the d4o_config: 
```
cd <LAND_SYSTEM_ROOT>/work_d4o/TEST_GSWP
cp <LAND_SYSTEM_ROOT>/work_dart/DART/models/clm/shell_scripts/cesm2_3/spreads/d4o/d4o_config_template.sh ./d4o_config.sh
````

Edit d4o_config.sh and change the variable `firstda` according with the date of the beginning of the run and `ens_dir`="ens_NN" , where NN is the number of members. 

Also check the dobs, in experiments after +-2003 the databases are at ./land/datain/d4o

Then, execute:
```
./d4o_config.sh 
```

Certify if all files copied made in d4o_cofig.sh were fine.

Adjust the input_nml necessary for the inflation with the desired values, e.g.
- inf_damping = 0.9, 0.9 
- inf_sd_max_change = 1.05, 1.05 
- ens_size = <ENSEMBLE SIZE>
- num_output_state_members = <ENSEMBLE SIZE>
- num_output_obs_members   = <ENSEMBLE SIZE>

Where <ENSEMBLE SIZE> is the number of members you had chosen.

### Assimilation run

Run the assimilation, step “0”:

```
./assimilate.csh $PWD 0 
```

where the `$PWD` refers to an environment variable that gets the current directory.

Verify if the assimilation is complete in  `${experiment path}/run/tmp`. For that, go to that directory. Should have the db files, i.e.:

  2000-01-02-00000_LAI.db  2000-01-02-00000_SM.db   2000-01-03-00000_SC.db  catalog.db
  2000-01-02-00000_SC.db   2000-01-03-00000_LAI.db  2000-01-03-00000_SM.db

Confirm if the assimilation files are ok: 
```
module load intel-2021.6.0/sqlite/3.40.0-v3tky 
alias sqlite="sqlite3 -readonly -batch -init /dev/null -nullvalue NULL -box" 

sqlite 2000-01-02-00000_SM.db \
"select id,reportype,entryno,kind,\
  (select distinct description from toc \
    where kind=body.kind) as description, 
obsvalue, prior_mean, posterior_mean, qc, dart_qc, member, prior, posterior \
  from hdr \
  join body on id=body.hdr_id \
  join ens on id=ens.hdr_id and entryno=body_entryno \
 where description in ('LPRM_SOIL_MOISTURE') \
 limit 50" 
```

This select will return only if there were at least 8 cycles. 

Done, the first assimilation cycle is ready. 
