#!/bin/bash
#BSUB -n 360
#BSUB -R "span[ptile=72]" 
#BSUB -R "affinity[core(1):cpubind=core]" 
#BSUB -q p_short
#BSUB -P R000
#BSUB -J d4o-opt
#BSUB -o d4o-opt.%J.out
#BSUB -e d4o-opt.%J.out
#BSUB -x 
#BSUB -rn
#BSUB -W 1:00
#BSUB -app spreads_filter

#
# A useful table:
#
# Nodes   -n    ptile  core aka OpenMP
#
#     8   576     72    1
#     8   288     36    2
#     8   144     18    4
#
#    16  1152     72    1
#    16   576     36    2
#    16   288     18    4
#
#    25  1800     72    1
#    25   900     36    2
#    25   450     18    4
#

set +x
set -a

shopt -s extglob # enables extglob i.e. @(x|y|z) regular expressions in bash

branch=d4o-opt
jobid=$LSB_JOBID # job id
#jobname=$LSB_JOBNAME # job name
jobname=$(echo "$LSB_JOBNAME" | cut -d. -f1)
NENS=${NENS:-$(echo "$LSB_JOBNAME" | cut -d. -f2 -s)}
[[ "$NENS" != "" ]] || NENS=0

available="5 15 30 50 60 80"
#NENS=${NENS:-0} # number of ensemble members : MUST BE PROVIDED -- currently dbdata available as in $available
base="base${NENS}"

if [[ ! -d ../$base ]] ; then
    set +x
    echo "Error: Unable to locate base dbdata dir for ${NENS}-ensembles in $(pwd)/../$base" >&2
    echo " Hint: use either env NENS=<value> bsub ... < this_job_script with <value> one of $available" >&2
    echo "   or  provide NENS as part of the jobname e.g. bsub -J foobar.5 < this_job_script would automatically set NENS to 5" >&2
    exit 1
fi

#scr=$LS_SUBCWD/${jobname}.lsf
scr=$LS_SUBCWD/${branch}.lsf

#bashsrc=$(basename ${BASH_SOURCE})
bashsrc=$(basename $scr)

if [[ $BASH_VERSINFO -lt 4 ]] ; then
    PS4='+ [${bashsrc}:${LINENO}]: '
else # only v4 onwards supports the below one w/o silent deaths
    _tref=$(date +%s)
    PS4='+ [${bashsrc}:$(($(date +%s)-_tref))s:$(date +%H%M%S):${LINENO}]: '
fi

pwd
printenv | egrep ^LS | sort
cd $LS_SUBCWD
pwd

source /data/cmcc/$USER/${branch}/install/INTEL/source.me # d4o-opt

set -eux
set -o pipefail
set -a # auto-export

ulimit -c 0
ulimit -a

if [[ -n "${LSB_HOSTS:-}" ]] ; then 
    I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_HOSTS | perl -pe 's/\s+/\n/g' | sort -u | wc -l) # the number of nodes allocated for this run
elif [[ -n "${LSB_MCPU_HOSTS:-}" ]] ; then
    I_MPI_HYDRA_BRANCH_COUNT=$(echo $LSB_MCPU_HOSTS | perl -pe 's/\s+/\n/g' | grep -Pv '^\d+$' | sort -u | wc -l) # in absence of LSB_HOSTS !!!
else
    set +x
    echo "Error: Both LSB_HOSTS and LSB_MCPU_HOSTS were not defined -- cannot figure out the number of nodes for I_MPI_HYDRA_BRANCH_COUNT" >&2
    set -x
    printenv | egrep '^LS' | sort 
    exit 1
fi

KMP_BLOCKTIME=${KMP_BLOCKTIME:-10} # default = 200 (ms) -- watch also for OMP_WAIT_POLICY=passive (def) vs active (in which case KMP_BLOCKTIME=infinite
OMP_STACKSIZE=${OMP_STACKSIZE:-300M}
d4o_numa=2 # $(lscpu 2>/dev/null | grep -Pi '^\s*NUMA\s+node\(s\):' | awk '{print $3}') # number of NUMA nodes
nodes=$I_MPI_HYDRA_BRANCH_COUNT # number of nodes
ppn=$(echo $LSB_SUB_RES_REQ | perl -pe 's/.*\[ptile=(\d+)\].*/$1/') # processes or tasks per node
#d4o_max_iopes=${d4o_max_iopes:-$ppn}
d4o_max_iopes=${d4o_max_iopes:-$nodes}
#d4o_max_iopes=${d4o_max_iopes:-$((nodes-1))} # one less than #nodes since there is probably biggest memory pressure on the glbtask#0
#d4o_max_iopes=${d4o_max_iopes:-1} # trying something very simplistic now
#d4o_max_iopes=${d4o_max_iopes:-0} # 'as many as we need' i.e. roughly npools in each case
cps=36 # cores per socket -- in this machine = 36
cpn=$((cps * 2)) # cores per node
mpi=$LSB_MAX_NUM_PROCESSORS # total number of MPI tasks
omp_given=0
[[ "${omp:-}" = "" ]] || omp_given=1
omp=${omp:-$((cpn/ppn))} # Number of OpenMP threads/task (use env omp=<newvalue> bsub < this_job_script to override)
depth=${depth:-$((cpn/ppn))} # usually the same as OpenMP
[[ $omp -le $depth ]] || omp=$depth # a must -- means : if omp > depth then set omp=depth i.e. omp cannot be larger than depth, ever
OMP_NUM_THREADS=$omp
ht=1

# Running filter.$branch.x with help of ecbind :
filterx=$(readlink -f filter.$branch.x)
if [[ ! -x $filterx ]] ; then
    echo "Error: Unable to locate executable $filterx for branch $branch" >&2
    exit 2
fi
timecmd="/usr/bin/time -v"
ecbind=$(which ecbind 2>/dev/null || echo ecbind)
#cmd="$timecmd mpirun -np $mpi -prepend-rank $ecbind -V0 --ppn $ppn -h $ht --depth $depth --omp=$omp --bind=2 --places --cps $cps ${d4o_tool:-} $filterx"
cmd="$timecmd mpirun -ppn $ppn -prepend-rank -bind-to core -print-rank-map $filterx"

# phase-2 -- so called "flat out" -mode
#phase2=${phase2:-"36x2"} # could be 72x1
phase2=${phase2:-"${ppn}x${depth}"} # for now ...
ppn2=$(echo "$phase2" | cut -f1 -dx)
mpi2=$((nodes * ppn2))
if [[ $omp_given -eq 1 ]] ; then
    omp2=$omp
else
    omp2=$(echo "$phase2" | cut -f2 -dx)
fi
depth2=$(echo "$phase2" | cut -f2 -dx)
[[ $omp2 -le $depth2 ]] || omp2=$depth2 # a must -- means : if omp2 > depth2 then set omp2=depth2 i.e. omp cannot be larger than depth, ever
#cmd2="$timecmd mpirun -np $mpi2 -prepend-rank $ecbind -V0 --ppn $ppn2 -h $ht --depth $depth2 --omp=$omp2 --bind=2 --places --cps $cps ${d4o_tool:-} $filterx"
cmd2="$timecmd mpirun -ppn $ppn2 -prepend-rank -bind-to core -print-rank-map $filterx"

# Post-Screening executable (if available)
screenx=$(readlink -f postscreening.$branch.x)

if [[ $omp -eq $depth ]] ; then
    outdir=$(pwd)/${branch}-m${NENS}/${jobname}-${jobid}-N${nodes}-T${mpi}xt${omp}.dir
else
    outdir=$(pwd)/${branch}-m${NENS}/${jobname}-${jobid}-N${nodes}-T${mpi}xt${omp}.${depth}.dir
fi
mkdir -pv $outdir

cp -pv $scr $outdir/ || :
cp -pv $LSB_AFFINITY_HOSTFILE $outdir/ || :
cp -pv $LSB_DJOB_HOSTFILE $outdir/ || :

jobout=$outdir/log.txt
running=$outdir/running.txt
cat /dev/null > $running
envs=$outdir/envs.txt
failed=$outdir/failed.txt
rm -fv $failed
timing=$outdir/timing.txt
cat /dev/null > $timing

cd $outdir
pwd

d4o_respect=${d4o_respect:-} # a comma (or '%' or '/', or ' ' between tokens) separated list of tokens to be "grepped" against the list of databases (their "basename $dbname .db" to be exact)
d4o_respect=$(echo "$d4o_respect" | perl -pe 's/^\s+//; s/\s+$//; s{[%\s+/]}{,}g; s/[,]+/,/g; s/^,//; s/,$//') # make it a true comma separated value

maxdeglat=${maxdeglat:-90}
#maxdeglat=${maxdeglat:-25}

# Production
mints=${mints:-1}
maxts=${maxts:-13}
incts=${incts:-1}

#mints=${mints:-12} # we have first IASI here
#maxts=${maxts:-7}  # we have a few GPSROs here
#incts=${incts:--5} # we start from 12, go backwards to 7 by using inc -5

#bailout=${bailout:-1} # whether to bailout (1) of errors when any of the individual TS* (phase-1) runs fail and keep going to allTS with successful timeslots only 
bailout=${bailout:-0} # no more bailing out by default

NTH=${NTH:-10000} # in phase-2 SEQUENCE_OBS_LOOP, print "Processing X of N observations" -line every NTH obs

#d4o_ens_size=$(perl -ne '{printf("%d",$1), exit if (m{^\s*ens_size\s*=\s*(\d+)})}' ../input.nml) # old
d4o_ens_size=${NENS}

#d4o_matchup=${d4o_matchup:-1} # set to 0 if match-up ("mup") needs NOT to be run as well
d4o_matchup=${d4o_matchup:-0}

d4o_scc=${d4o_scc:-0} # (stands for "simple_calc_comm" -- whether to MPI_comm_split (aka simple aka =1) or more complicated calc%comm creation (=0 and more performant for output I/O)
[[ $d4o_max_iopes -ne 1 ]] || d4o_scc=1 # .. to simplify things

d4o_dbwr_openclose=${d4o_dbwr_openclose:-0} # if =1 then closedb after each epoch of PUTDB in the run_obs_ioserv

d4o_spintime=20 # harakiri_timeout will be set to this number plus 30 secs in signals.c -- this number *can* be a flp number, if that matters

d4o_backup=0
d4o_debug=1:0
d4o_catalog=catalog.db
d4o_hdr="abs(deglat) <= $maxdeglat" 

perfstat=${perfstat:-1}
perfstat_tblsize=${perfstat_tblsize:-300}
#perfstat_callgraph=${perfstat_callgraph:-1} # now on automatically if perfstat is on
perfstat_top=${perfstat_top:-30}
perfstat_profile="prof.csv" # creates automatically files under perfstat/<taskid>/prof.csv & prof.txt

if [[ "$d4o_respect" != "" ]] ; then
    retries=0 # when operating with respected databases, we do often fail in Phase-1 due to lack of input files -- thus do NOT rerun ; of course we may fail also for other reasons -- so check out
else
    #retries=${retries:-3} # in case of failures in phase-1, how many times to try to rerun before abandoning the TS ; in particular if retries=0 do not re-try to run at all
    retries=${retries:-0} # no more retries by default
    [[ $retries -ge 0 ]] || retries=0
fi

#TBB_MALLOC_SET_HUGE_SIZE_THRESHOLD=${TBB_MALLOC_SET_HUGE_SIZE_THRESHOLD:-8388608}
d4o_numreqs=${d4o_numreqs:-50}

d4o_local=${d4o_local:-1} # localize timeset & obsk2ts -- total memory usage goes up a bit (with LOTS of obs, 10.000.000 or so set to 0)

d4o_parallel=${d4o_parallel:-10} # parallelism for d4ojoinall (set to 0 to disable parallelism, and to 1 to allow max parallelism [not recommended; may blow up])

non_blocking_comms=${non_blocking_comms:-T} 

#d4o_dump_diags=${d4o_dump_diags:-1} # option to enable dump diagnostics from calc-PEs in obs_space_diagnostics()
d4o_dump_diags=${d4o_dump_diags:-0} # option to enable dump diagnostics from calc-PEs in obs_space_diagnostics()

#d4o_poo=${d4o_poo:-1} # create print_ordered_obs.csv from the master task
d4o_poo=${d4o_poo:-0} # create print_ordered_obs.csv from the master task

cutoff=${cutoff:-0.15} # phase-2 obs (half-)cutoff distance

d4o_csvprint=${d4o_csvprint:-1} # diagnostics data rows
d4o_debug_limit=${d4o_debug_limit:-0} # set > 0 to see this many first & last lines of diagnostics data (csv or other format)

d4o_journal=${d4o_journal:-off} # turn journal mode on (default by SQLite) or off (as here) for files to be updated

# For location_mod namelist
nlon=${nlon:-553}
nlat=${nlat:-340}
# However, the resolution is
#	lon = 576 ;
#	lat = 384 ;
#	slon = 576 ;
#	slat = 383 ;

postscreen=${postscreen:-1} # perform post screening with blacklisting just before phase-2 filter commences
screencmd="$timecmd mpirun -ppn ZZTOP -prepend-rank -bind-to core -print-rank-map $filterx"

inf_flavor=${inf_flavor:-5}

function PostProc()
{
    # Must wait outside and do NOT call with "PostProc &" -- just use the plain "PostProc"
    if [[ -d perfstat ]] ; then
	# if csv, then turn it into a single global csv
	(create_profdb > create_profdb.txt 2>&1) &
	(tar zcf perfstat.tgz perfstat) &
    fi
    if [[ -d dump ]] ; then
	# turn prior/posterior.*.txt into respective databases
	(create_dumpdb > create_dumpdb.txt 2>&1) &
	(tar zcf dump.tgz dump) &
    fi
}

function RunPostScreening()
{
    if [[ $# -gt 0 ]] && [[ $postscreen -eq 1 ]] && [[ -x $screenx ]] ; then
	dbs=$(set +xeu; eval echo "${@:-}")
	numdbs=$(set +xeu; set +o pipefail; ls -C1 $dbs 2>/dev/null | wc -l)
	if [[ $numdbs -gt 0 ]] ; then
	    if [[ $numdbs -gt $ppn ]] ; then
		tpn=$ppn
	    else
		tpn=$numdbs
	    fi
	    kmd=$(echo "$screencmd" | perl -pe "s/ZZTOP/$tpn/g")
	    env perfstat=0 $kmd $dbs
	    unset tpn kmd
	fi
	unset dbs numdbs
    fi
}

{
    set -xeu
    set -o pipefail
    set -a # auto-export

    cd $outdir
    pwd
    
    du -sh $TMPDIR || :
    df -h $TMPDIR || :
    
    #d4o_is_obs=1 # see ensemble_manager_mod.F90 & assim_tools_mod.F90 -- obsolete now
    #d4o_shmem=1
    #d4o_bcast=1 # kind of redundant if d4o_shmem=1
    #d4o_update_threads=10
    #d4o_final=obs_seq.final
    
    unset d4o_final

    printenv | perl -ne 'BEGIN{$p=1} $p=0 if(m%^BASH_FUNC%); print if($p); $p=1 if (!$p&&m%^}\s*$%);' | sort > $envs

    ldd $filterx || :

    # create input.nml from input.nml.in
    #ln -sv ../../input.nml.in .
    cp -v ../../input.nml.in.$branch input.nml.in
    chmod u+w input.nml.in

    # these __\w+__ params/vars we have
    cat > /dev/null <<'EOF'
    grep -P '\b__\w+__\b' input.nml.in 
    input_state_file_list        = __cam_init_files__
    output_state_file_list       = __cam_init_files_ayt__
    num_output_state_members     = __NENS__
    ens_size                     = __NENS__
    num_output_obs_members   = __NENS__
    tasks_per_node = __PPN__ ! irrelevant
    print_every_nth_obs               = __NTH__
    stages_to_write              = __stages_to_write__
    cutoff = __cutoff__
    nlon                            = __nlon__
    nlat                            = __nlat__
    inf_flavor                  = __inf_flavor__,          0
EOF

    # Now create cam_init_files.$NENS & cam_init_files_ayt.$NENS by replicating the contents from the base5 (=truth)
    #LGG
    #if [[ $NENS -eq 5 ]] ; then
	#cat ../../cam_init_files > cam_init_files.$NENS
	#cat ../../cam_init_files.ayt > cam_init_files.ayt.$NENS
    #else
	#nrepl=$((NENS/5)) # fortunately all our $available cases are multiples of 5
	#cat /dev/null > cam_init_files.$NENS
	#for n in $(seq 1 $nrepl)
	#do
	#    cat ../../cam_init_files >> cam_init_files.$NENS # sharing some input files
	#done
	## however, output files must be different
	#cat /dev/null > cam_init_files.ayt.$NENS
	#fmt=$(head -n1 ../../cam_init_files.ayt | perl -pe 's/_\d{4}\.nc$/_%4.4d.nc/')
	#for n in $(seq 1 $NENS)
	#do
	#    printf "$fmt\n" $n >> cam_init_files.ayt.$NENS
	#done
    #fi

    #cat cam_init_files.$NENS
    #cat cam_init_files.ayt.$NENS
    #LGG END

    ok_timeslots="" # timeslots that were ok for allTS (phase-2) -- if empty, then allTS will fail / will not be run

    # for use by tryno > 0 -- changes execution layout somewhat, but usually yield to slower elapsed times as well
    safe_scc=1
    #safe_max_iopes=1
    safe_dbwr_openclose=1
    safe_numreqs=1
    # save these
    saved_scc=$d4o_scc
    saved_max_iopes=$d4o_max_iopes
    saved_dbwr_openclose=$d4o_dbwr_openclose
    saved_numreqs=$d4o_numreqs
    
    #*** Phase-1 ***
    d4o_departures=no # phase-1 #LGG
    ts=1
    TS=`pwd`
    d4o_scc=$saved_scc
	d4o_max_iopes=$saved_max_iopes
	d4o_dbwr_openclose=$saved_dbwr_openclose
	d4o_numreqs=$saved_numreqs

	d4o_maxdb=$(ls -C1 *.db 2>/dev/null | wc -l)
	((d4o_maxdb+1)) # +1 to account $ODB_SCHEMA_DIR/rttov_sensor_db.db
	d4o_timeslot=1

    pwd; ls -ltra || :
    
    dateu=$(date -u)
        perfstat_title="${dateu}: Phase-1@$TS : exe=$(basename $filterx) : job=$jobname.$jobid ens#$NENS : {nodes,ppn,mpi,omp,depth,iopes,scc,dbwroc}={$nodes,$ppn,$mpi,$omp,$depth,$d4o_max_iopes,$d4o_scc,$d4o_dbwr_openclose}"
    perfstat_subtitle="${dateu}: Phase-1@$TS : respect=$d4o_respect maxdeglat=$maxdeglat : pwd=$(pwd)"
    
    printenv | perl -ne 'BEGIN{$p=1} $p=0 if(m%^BASH_FUNC%); print if($p); $p=1 if (!$p&&m%^}\s*$%);' | sort > env_$TS.txt

    echo "$(date -u): TS=$TS tryno=$tryno" >> $running
    mkdir -pv perfstat dump
    rc=0
    $cmd 2>&1 | tee log_$TS.txt || rc=$?
    echo "$(date -u): TS=$TS tryno=$tryno done with rc=$rc" >> $running
    # Remove empty dirs if any
    rmdir perfstat/* 2>/dev/null || :
    rmdir perfstat dump || :

    nodata=0
    if [[ $rc -ne 0 ]] ; then
    if [[ -s nodata.txt ]] ; then
        nodata=1
        cat nodata.txt || :
    else
        [[ $bailout -eq 1 ]] || echo "$rc" > $failed
    fi
    echo "$rc" > failed_${TS}_$tryno.txt
    fi

    pwd; ls -ltra || :
	    if [[ -s failed_${TS}_$tryno.txt ]] ; then
		# Discard this TS from going to the allTS -- for now -- TBD -- see the connection to the $bailout
        echo "failed LGG"
		    break;
	    else
		ok_timeslots+=",$ts"
		(d4ocatalog $d4o_catalog "*.*.db" > catalog.txt 2>&1) &
		break
	    fi

#echo "`date` -- END FILTER"

mv dart_log.nml dart_log.nml.$LSB_JOBID || :
mv dart_log.out dart_log.out.$LSB_JOBID || :
if [ "$rc" -eq 0 ]; then
    echo "2" > filter.flag
else
    echo "Error in filter"
    exit 1
fi


pwd
ls -ltr

exit $rc
