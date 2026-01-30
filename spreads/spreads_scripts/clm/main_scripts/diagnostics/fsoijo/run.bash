#!/bin/bash 

# 2017-10-05-00000 done
# 2017-10-05-43200 RUN ?
# 2017-10-06-00000 done
# 2017-10-06-43200 RUN ?
# 2017-10-07-00000
# 2017-10-07-43200
# 2017-10-08-00000
# 2017-10-08-43000
# 2017-10-09-00000
# 2017-10-09-43200
# 2017-10-10-00000
# 2017-10-10-43200
# 2017-10-11-00000

START_DATE=2017-10-07-00000
# START_DATE=2017-10-05-43200
NENS=80
END_DATE=2017-10-08-00000
# END_DATE=2017-10-06-43200
ARCHD=/work/cmcc/mg20022/CMCC-CM/archive
EXPNAME=spreads_v5
OBSDIR=/work/cmcc/mg20022/databases/b2d4o_d4o_db
SPREADSDIR=/work/cmcc/mg20022/github/spreads
mkdir -p src/${EXPNAME}/${START_DATE}

cp -f mpi_fsoijo_en.py mpi_fsoijo_exec.bash prep_fsoijo.bash fsoijo_plot.py src/${EXPNAME}/${START_DATE}/

cd src/${EXPNAME}/${START_DATE}/

sed -i "s@=NENS@=${NENS}@g" prep_fsoijo.bash
sed -i "s@=ARCHD@=${ARCHD}@g" prep_fsoijo.bash
sed -i "s@=EXPNAME@=${EXPNAME}@g" prep_fsoijo.bash
sed -i "s@=OBSDIR@=${OBSDIR}@g" prep_fsoijo.bash
sed -i "s@=START_DATE@=${START_DATE}@g" prep_fsoijo.bash
sed -i "s@=END_DATE@=${END_DATE}@g" prep_fsoijo.bash
sed -i "s@=SPREADSDIR@=${SPREADSDIR}@g" prep_fsoijo.bash


sed -i "s@NENS@${NENS}@g" mpi_fsoijo_en.py
sed -i "s@START_DATE@\"${START_DATE}\"@g" mpi_fsoijo_en.py
sed -i "s@END_DATE@\"${END_DATE}\"@g" mpi_fsoijo_en.py
sed -i "s@ARCHD@\"${ARCHD}\"@g" mpi_fsoijo_en.py
sed -i "s@EXPNAME@\"${EXPNAME}\"@g" mpi_fsoijo_en.py

./prep_fsoijo.bash

bsub < mpi_fsoijo_exec.bash