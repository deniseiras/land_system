#!/bin/bash

####################################################
#    Interpolate the staggered variable on the 
#    regular grid for the FSOI_Jo estimate
#
#    Quick and dirty solution, please find a better 
#    one for the interpolation
#
#    @author Giovanni Conti
#    @date 12 April 2023
#
#    usage:> ./main_fsoijo.sh
####################################################



#***************************************************
#           Set the parameters here
#***************************************************


NENS=3

START_DATE="2017-10-03-43200"

END_DATE="2017-10-03-43200"

ARCHD="/work/cmcc/${USER}/CESM2/archive"

EXPNAME="spreads_bgc"



#***************************************************
#           Main computation
#***************************************************
echo " "
echo "****************** Prep FSOI_Jo ********************"
echo "****************** for ensemble ********************\n"

cd ${ARCHD}/${EXPNAME}

# list all the dirs, not their content
alldir=`ls -d ${EXPNAME}*`

# define the starting and ending dir
sfname="${EXPNAME}-${START_DATE}"
ffname="${EXPNAME}-${END_DATE}"

echo "Starting date to process: ${sfname}"
echo "Ending date to process: ${ffname}\n"
echo " "

for ff in ${alldir}
do
     if [[ ${ff} == ${sfname} ]] || [[ ${ff} > ${sfname} ]]; then
       if    [[ ${ff} == ${ffname} ]] || [[ ${ff} < ${ffname} ]]; then
           echo "processing: ${ff} ..."

           # enter in the dir to process        
           cd ${ff}
  
           # actual date
           ACTUAL_DATE=${ff#"${EXPNAME}-"}
           echo "   date: ${ACTUAL_DATE}" 

           echo "   extract reference variable T" 
           cdo selname,T ${EXPNAME}.cam_0001.e.analysis.${ACTUAL_DATE}.nc ref.nc
           echo "   extract grid info "            
           cdo griddes ref.nc > grid.txt
           
           echo ""
           # cycle, all members
           inst=1
           while ((${inst}<=${NENS}))
              do
                 echo -e "   member: $inst\n"

                 # Following the CESM strategy for 'inst_string'
                 inst_string=`printf _%04d $inst`

                 echo "   extract staggered US "            
                 cdo selname,US ${EXPNAME}.cam${inst_string}.e.analysis.${ACTUAL_DATE}.nc us.nc
                 echo "   remap US "            
                 cdo remapbil,grid.txt us.nc u.nc
                 echo "   rename US->U "            
                 ncrename -h -O -v US,U u.nc
                 echo "   save US in the main file "
                 ncks -A -v U u.nc ${EXPNAME}.cam${inst_string}.e.analysis.${ACTUAL_DATE}.nc  
 
                 echo "   extract staggered VS "            
                 cdo selname,VS ${EXPNAME}.cam${inst_string}.e.analysis.${ACTUAL_DATE}.nc vs.nc
                 echo "   remap VS "            
                 cdo remapbil,grid.txt vs.nc v.nc
                 echo "   rename VS->V "            
                 ncrename -h -O -v VS,V v.nc
                 echo "   save US in the main file "
                 ncks -A -v V v.nc ${EXPNAME}.cam${inst_string}.e.analysis.${ACTUAL_DATE}.nc  
           
                 echo "   remove tmp files"
                 rm -f u.nc v.nc us.nc vs.nc 
                 echo ""
          
              ((inst++))
           done
 
           # back to the main dir
           cd ..
       fi
     fi
done



#***************************************************
#           END
#***************************************************
echo "****************** END ********************"
echo " "


