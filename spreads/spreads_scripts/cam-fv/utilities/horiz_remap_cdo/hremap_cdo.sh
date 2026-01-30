#!/bin/bash

VAR_E5='t'  # t, z, ...
VAR_AS='T'

LEVEL=850  # 850 500
FNAME_E5='ERA5-15-25.nc'
FSAVE_E5="e5_${VAR_E5}_${LEVEL}_remap.nc"

FNAME_AS='cam_phis.nc'
FSAVE_AS_TMP='as_tmp.nc'



echo ""
echo "============ H o r i z o n t a l   I n t e r p o l a t i o n ============"
echo ""

echo "Extract VAR_E5 from ERA5"
cdo selname,${VAR_E5} ${FNAME_E5} tmp1.nc

echo "Extract VAR_E5 at particular level"
cdo sellevel,${LEVEL} tmp1.nc tmp2.nc

echo ""
echo "Extract VAR_AS from analysis"
cdo selname,${VAR_AS} ${FNAME_AS} ${FSAVE_AS_TMP}

echo ""
echo "Extract VAR_AS grid informations from analysis"
cdo griddes ${FSAVE_AS_TMP} > grid.txt

echo ""
echo "Interp ERA5 on the correct grid (Horizontally)"
cdo remapbil,grid.txt tmp2.nc ${FSAVE_E5}

rm *tmp*
rm grid.txt

echo ""
echo " Use python to do the vertical interpolation!"
echo "========================================================================="
echo ""



