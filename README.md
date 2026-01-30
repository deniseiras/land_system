# land_system
Repository for running the Land spreads d4o system in Cassandra Supercomputer. 
Includes and manages all repos necessary for running, as d4o, CMCC-CM and DART, that was not managed anymore in JUNO.

## Repository structure:

- land
  - datain: Input data folder. Empty in here.

- spreads
  - d4o
    - original git source: branch d4o-land - https://github.com/lgggoncalves/SPREADS.git
    - modified files for Cassandra porting:
      - ECMWF/eckit-1.19.0-Source/src/eckit/utils/Optional.h
      - Makefile 
      - build.cassandra
      - build.cassandra.INTEL.source.me
      - load-modules-d4o.cassandra
  - spreads_ui: ecflow structure


- users_home_cmcc_cp1
  - CMCC-CM
    - original git source: branch cmcc-cm - git@github.com:CMCC-Foundation/CMCC-CM.git 
    - cime_config
      - cime_config/testlist_allactive.xml
      - cime_config/config_pes.xml
  - CMCC-CM
    - ccs_config 
      - original git source: branch cmcc-cm_cp1 - https://github.com/CMCC-Foundation/ccs_config_cmcc
      - machines/config_batch.xml
      - machines/config_machines.xml
      - machines/config_workflow.xml
      - machines/cmake_macros/intel_cassandra.cmake
     
- work_d4o
  - experiments output folder

- work_dart
  - DART
    - original git source: branch main - https://github.com/NCAR/DART.git

