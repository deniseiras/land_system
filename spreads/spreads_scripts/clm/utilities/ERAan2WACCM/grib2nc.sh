#!/bin/bash

#========================================
#    conversion from grib to netcdf
#========================================


# remember that for info you can use
#  wgrib -V (-v o -s) filein.grb 

echo ""
echo "============ M o d u l e   L o a d ============"
echo ""

#module purge
#module load wgrib/1.8.1.0b
#module load impi19.5/19.5.281
#module load intel19.5/19.5.281
#module load intel19.5/eccodes/2.12.5
#module load impi19.5/netcdf/C_4.7.2-F_4.5.2_CXX_4.3.1
#module load impi19.5/hdf5/1.10.5
#module load intel19.5/szip/2.1.1
#module load intel19.5/udunits/2.2.26
#module load intel19.5/magics/3.3.1
#module load intel19.5/cdo/1.9.8
#module load intel19.5/nco/4.8.1
#module load anaconda/3.7


# load module wgrib (cdo is already running on my env)
#module load intel20.1/wgrib2/3.0.0


echo ""
echo "============ S e t   P a r a m e t e r s ============"
echo ""

# set the path of dir containing .grib
dgrib=.

# grib extention
grbext="grib"


echo ""
echo "============ C o n v e r s i o n ============"
echo ""


# cycle over the grib files
for file in ${dgrib}/*.${grbext}; do
#for fin in `ls ${dgrib}/*.${grbext}`; do

  fname=`echo ${file} | awk -F '.' '{print $2}' | cut -d'/' -f2`
  echo -e "\nconverion of: ${fname} \n"

  cdo -r -f nc -t ecmwf copy ${dgrib}/${fname}.${grbext} ${dgrib}/${fname}.nc
  
done










