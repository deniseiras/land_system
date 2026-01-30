```
ecperf : Profiling ECMWF MPI+OpenMP applications with perf-tools

( See also https://confluence.ecmwf.int/x/Fhb2DQ )

About perf

perf is a set of performance analysis tools for Linux

Performance counters for Linux are a new kernel-based subsystem that provide a framework for all things performance analysis.

It covers hardware level (CPU/PMU, Performance Monitoring Unit) features and software features  (software counters, tracepoints) as well

There is usually no need to recompile or relink you application (or Linux command) – perf just works as-is on the application
The are various perf tools, for example

* perf stat

Run a command and gather its performance counter statistics
Very light-weight as starts counters at the beginning and produces summary at the end
Usually the default events are sufficient
See more: man perf-stat

* perf record

Run a command and record its profile into perf.data
Performance recording is based on sampling
You can choose which events to monitor, or whether you want to perform system-wide recording
See more: man perf-record

* perf report

Read perf.data (created by perf record) and display the profile
Various reporting options available
What can be displayed also depends on what options were used upon perf record invocation
See more: man perf-report

* perf script

Read perf.data (created by perf record) and display trace output
This gives you every single trace recorded with an optional call trace, when available
Output is usually very readable text format
Allows to build user interfaces and produce customized profiling reports in case perf report was not sufficient
See more: man perf-script

* perf list

List all symbolic event types
Rather than asking very low level (and system dependent) events, you can use more generic names, like "cycles"
Please note that not all system have all the same events
See more: man perf-list

* perf top

System profiling tool
This command generates and displays a performance counter profile in real time
Particularly useful to get system-wide status with perf top -a
See more: man perf-top

* ECMWF wrappers on top of perf tools

Why do we need these ?

perf provided by the RedHat release (8.x) comes with very old Linux kernel (4.18)
ecperf on the other hand is based on newer kernel – yet it still runs correctly on top of older kernels that are not ancient
ecperf brings more features, in particular superfast call trace generation, that it is very much preferred over standard perf
ecperf is currently available on Bologna system and build from Linux kernel sources based on kernel version 5.17

There are 3 notable wrapper commands developed on top of ecperf :

= ecperf-stat
= ecperf-record
= ecperf-digest

* The ecperf wrappers

ecperf-stat

This wrapper invokes "ecperf" with stat option

An example:

srun -l -v -K1 --cpus-per-task=8 --ntasks-per-node=16 --threads-per-core=1 \
     --hint=nomultithread --cpu-bind=none -N9 -n 144 \
     ecbind -V0 --ppn 16 -h 1 --depth 8 --bind=2.8 --places --cps 64 \
            --tool ecperf-stat /a/disk/bin/ifsMASTER.SP


ecperf-record

This wrapper invokes "ecperf" with record -option followed by script -option to produce a datafile (per MPI-task) for further examination with ecperf-digest

Change in the previous ecperf-stat into ecperf-record and you collect sampling based trace records:

srun -l -v -K1 --cpus-per-task=8 --ntasks-per-node=16 --threads-per-core=1 \
     --hint=nomultithread --cpu-bind=none -N9 -n 144 \
     ecbind -V0 --ppn 16 -h 1 --depth 8 --bind=2.8 --places --cps 64 \
            --tool ecperf-record /a/disk/bin/ifsMASTER.SP


ecperf-digest

This is a Perl-script that operates with the outcome of ecperf-record output
Translates the trace record output into a custom SQLite database (using Perl DBI and DBD::SQLite modules)
Subsequent accesses are substantially faster than when reading first time the ecperf-record output
Provides access to hot spots in

Function level
Source code line level
Calling trees with or without line numbers
Selection of subset of collected event events
Filtering per thread id
Inclusion or exclusion of symbols or scopes (e.g. USER versus KERNEL versus MPI)
Selection based on SQL-query from the SQLite database (e.g. generate input for time-line plots of particular events on certain thread id)
Some function level output is similar(-ish) to the DrHook output with exception of ecperf-digest also seeing line numbers and library (e.g. BLAS, MPI, OpenMP) routines

NB: the is no ecperf-report wrapper at all

An example:

ecperf-digest perf-record.dir/aa2-4036/exe-ifsMASTER.SP.mpi-0.omp-8.jobid-1364623.freq-17Hz.gz

ecperf-digest ecperf-exe-ifsMASTER.SP.mpi-0.omp-8.jobid-1364623.freq-17Hz.db --linenos --nocalltree --top 5 -e cycles 


```
