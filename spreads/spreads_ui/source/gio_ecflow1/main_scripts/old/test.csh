#!/bin/csh


if ( -f test.sh ) then
  echo "CIAO"
endif

set list=`ls *.sh` 
#echo ${list}
foreach fdb ("$list") 
    echo ${fdb}
end 
