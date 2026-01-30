The subdirectory CMCC-DART/d4o/external/ should contain
external contributions e.g. Screening and GlobalThinning programs.

To run Screening development version on Zeus, do

(1) export SCRATCH=/work/cmcc/$USER/screen-develop
    mkdir -pv $SCRATCH

(2) cd /users_home/cmcc/ss35621/git/CMCC-DART/d4o/external
    tar zcvhf $SCRATCH/screen.tgz *

(3) cd $SCRATCH
    tar zxvf screen.tgz

(4) ./doscreening "TS5/bufr.*.db"

Please see the file "sample-output-screening.txt" for an example output of (4)

Anytime outside the "doscreening", you need to initialize env via:

source /users_home/cmcc/ss35621/load-modules-d4o.zeus
source /data/cmcc/ss35621/d4o/install/INTEL/source.me
alias sqlite='sqlite3 -readonly -batch -init /dev/null -nullvalue NULL -box'

