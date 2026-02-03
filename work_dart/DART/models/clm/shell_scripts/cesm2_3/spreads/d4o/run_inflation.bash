#!/bin/bash
#

# TODO check / improve dir
# source /users_home/cmcc/lg07622/modules_juno.me
if ( "$machine" == "juno" ) then
    # sources the same modules at assimilate_executor, plus /data/cmcc/de34824/d4o/install/INTEL/source.me
    # which exports a lot of env vars - e.g. below - confirm if needed in cassandra and ... 
    source /users_home/cmcc/lg07622/modules_juno.me
    # ... includes the below
    # source /data/cmcc/${USER}/d4o/install/INTEL/source.me
    # module load intel-2021.6.0/cdo-threadsafe/2.1.1-lyjsw
    # module load intel-2021.6.0/ncview/2.1.8-sds5t
else # cassandra
    # TODO - check the vars exported in juno above
    source /work/cmcc/de34824/spreads/d4o/load-modules-d4o.cassandra
endif


./fill_inflation_restart || exit 4

