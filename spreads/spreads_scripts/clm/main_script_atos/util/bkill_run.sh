#/bin/bash

list=`bjobs -u gc02720 | grep RUN | awk '{print $1}'`
bkill $list

