#/bin/bash

list=`bjobs -u ${USER} | grep PEND | awk '{print $1}'`
bkill $list

