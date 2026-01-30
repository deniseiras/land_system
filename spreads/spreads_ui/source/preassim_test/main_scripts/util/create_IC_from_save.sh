#/bin/bash


INDIR=/work/cmcc/gc02720/CESM2/archive/testfinal/testfinal-2017-08-01-00000
OUTDIR=/work/cmcc/gc02720/ic/wforeIC
EXP_NAME=testfinal
DATE=2017-08-01-00000
NENS=30


echo "copy saved file in the new directory ..."
mkdir -p $OUTDIR
# note  that the dart files are name_experiment.cam_XXXX while the restart are
# name_experiment_XXXX
#cp ${INDIR}/${EXP_NAME}_* ${OUTDIR}
cp ${INDIR}/${EXP_NAME}*.e.forecast.* ${OUTDIR}
#chmod 777 ${OUTDIR}

inst=1
while (( $inst<=30))
do
   inst_string=`printf _%04d $inst` 
   echo "create rpointer for member:  $inst"
   
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.mosart.r.${DATE}.nc   ${OUTDIR}/${EXP_NAME}.mosart${inst_string}.r.${DATE}.nc
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.clm2.r.${DATE}.nc     ${OUTDIR}/${EXP_NAME}.clm2${inst_string}.r.${DATE}.nc
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.cam.r.${DATE}.nc      ${OUTDIR}/${EXP_NAME}.cam${inst_string}.r.${DATE}.nc
   mv ${OUTDIR}/${EXP_NAME}.cam${inst_string}.e.forecast.${DATE}.nc      ${OUTDIR}/${EXP_NAME}.cam${inst_string}.i.${DATE}.nc
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.cice.r.${DATE}.nc     ${OUTDIR}/${EXP_NAME}.cice${inst_string}.r.${DATE}.nc
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.docn.rs1.${DATE}.bin  ${OUTDIR}/${EXP_NAME}.docn${inst_string}.rs1.${DATE}.bin
   mv ${OUTDIR}/${EXP_NAME}${inst_string}.cpl.r.${DATE}.nc      ${OUTDIR}/${EXP_NAME}.cpl${inst_string}.r.${DATE}.nc 
   
   echo "${OUTDIR}/${EXP_NAME}.mosart${inst_string}.r.${DATE}.nc" > ${OUTDIR}/rpointer_rof${inst_string}    
   echo "${OUTDIR}/${EXP_NAME}.clm2${inst_string}.r.${DATE}.nc" > ${OUTDIR}/rpointer_lnd${inst_string}    
   echo "${OUTDIR}/${EXP_NAME}.cam${inst_string}.r.${DATE}.nc" > ${OUTDIR}/rpointer_atm${inst_string}    
   echo "${OUTDIR}/${EXP_NAME}.cice${inst_string}.r.${DATE}.nc"> ${OUTDIR}/rpointer_ice${inst_string}    
   echo "${OUTDIR}/${EXP_NAME}.docn${inst_string}.rs1.${DATE}.bin" > ${OUTDIR}/rpointer_ocn${inst_string}    
   echo "${OUTDIR}/${EXP_NAME}.cpl${inst_string}.r.${DATE}.nc" > ${OUTDIR}/rpointer_drv${inst_string}    
  

  ((inst++))
done



