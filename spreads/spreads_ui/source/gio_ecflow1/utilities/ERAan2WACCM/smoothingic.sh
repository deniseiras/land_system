#!/bin/bash


# Make use of a waccm file to make the interpolated ic smoother
f1="f.e21.FHIST_BGC.f09_025.CAM6assim.004.cam_0003.i.2017-01-15-00000.nc"
fcc="FWT2000_f09_spinup01.cam.i.0001-01-02-00000_c160315.nc"


echo "Extract clim T"
ncrename -h -v T,TCC $fcc tmpcT.nc
echo "Extract clim Q"
ncrename -h -v Q,QCC $fcc tmpcQ.nc
echo "Extract clim US"
ncrename -h -v US,USCC $fcc tmpcUS.nc
echo "Extract clim VS"
ncrename -h -v VS,VSCC $fcc tmpcVS.nc

echo "Create new clim file"
ncks -v TCC  tmpcT.nc  tmpc.nc
ncks -A -v QCC  tmpcQ.nc  tmpc.nc
ncks -A -v USCC  tmpcUS.nc  tmpc.nc
ncks -A -v VSCC  tmpcVS.nc  tmpc.nc

echo "Remove tmp files"
mv tmpc.nc clim.nc
rm tmp*.nc


echo "Insert new variables"
cp $f1 da.nc
ncks -A -v TCC,QCC,USCC,VSCC clim.nc da.nc




echo "Make the computation"
ii=0
ie=18
ncap2 -s "T(:,$ii:$ie,:,:)=TCC(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "Q(:,$ii:$ie,:,:)=QCC(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "US(:,$ii:$ie,:,:)=USCC(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "VS(:,$ii:$ie,:,:)=VSCC(:,$ii:$ie,:,:)" da.nc o.nc
ii=19
ie=23
ncap2 -A -s "T(:,$ii:$ie,:,:)=0.4*T(:,$ii:$ie,:,:)+TCC(:,$ii:$ie,:,:)*0.6" da.nc o.nc
ncap2 -A -s "Q(:,$ii:$ie,:,:)=0.4*Q(:,$ii:$ie,:,:)+QCC(:,$ii:$ie,:,:)*0.6" da.nc o.nc
ncap2 -A -s "US(:,$ii:$ie,:,:)=0.4*US(:,$ii:$ie,:,:)+USCC(:,$ii:$ie,:,:)*0.6" da.nc o.nc
ncap2 -A -s "VS(:,$ii:$ie,:,:)=0.4*VS(:,$ii:$ie,:,:)+VSCC(:,$ii:$ie,:,:)*0.6" da.nc o.nc
ii=24
ie=28
ncap2 -A -s "T(:,$ii:$ie,:,:)=0.8*T(:,$ii:$ie,:,:)+TCC(:,$ii:$ie,:,:)*0.2" da.nc o.nc
ncap2 -A -s "Q(:,$ii:$ie,:,:)=0.8*Q(:,$ii:$ie,:,:)+QCC(:,$ii:$ie,:,:)*0.2" da.nc o.nc
ncap2 -A -s "US(:,$ii:$ie,:,:)=0.8*US(:,$ii:$ie,:,:)+USCC(:,$ii:$ie,:,:)*0.2" da.nc o.nc
ncap2 -A -s "VS(:,$ii:$ie,:,:)=0.8*VS(:,$ii:$ie,:,:)+VSCC(:,$ii:$ie,:,:)*0.2" da.nc o.nc
ii=29
ie=69
ncap2 -A -s "T(:,$ii:$ie,:,:)=T(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "Q(:,$ii:$ie,:,:)=Q(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "US(:,$ii:$ie,:,:)=US(:,$ii:$ie,:,:)" da.nc o.nc
ncap2 -A -s "VS(:,$ii:$ie,:,:)=VS(:,$ii:$ie,:,:)" da.nc o.nc

