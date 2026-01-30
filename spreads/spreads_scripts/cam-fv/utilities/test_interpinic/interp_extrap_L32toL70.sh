#!/bin/bash

#----------------------------------------------------
# Compute the extrapolation for the already equilibrated
# ensemble. From 32 Lev -> 70 Lev
#----------------------------------------------------


SCRIPT_NAME=vert_extr.ncl
SRC_DIR=./Kevin_L70
OUT_DIR=./Kevin_L70_EXTR

CASE=f.e21.FHIST_BGC.f09_025.CAM6assim.004.cam
DATE=2017-01-15-00000

NENS=30


string_id=""
count=1
while (( $count<= $NENS ))
do 
  inst_string=`printf _%04d $count`
  
  fcas=$CASE$inst_string.i.${DATE} 
  forg=${SRC_DIR}/${fcas}.nc 
  fout=${OUT_DIR}/${fcas}.nc
  echo "Before interpolation of $forg" 
  
  #cp ${SCRIPT_NAME} tmp.ncl
  #sed -i "s@TEMPLATE_FILE_IN@${forg}@g" ${SCRIPT_NAME}
  #ncl ${SCRIPT_NAME}
  #cp tmp.ncl ${SCRIPT_NAME}
  #rm tmp.ncl


  ./interpic -t templateL70IC.nc ${forg} ${fout}
  echo "After interpolation of $forg" 

 ((count++))
done
