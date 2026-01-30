import numpy as np
from netCDF4 import Dataset

#data1 = Dataset('datain/input_priorinf_mean.nc','r+')
#data2 = Dataset('datain/input_priorinf_sd.nc','r+')
data1 = Dataset('input_priorinf_mean.nc','r+')
data2 = Dataset('input_priorinf_sd.nc','r+')

#adding TS, TREFHT, LANDFRAC, QVMR
lat_nc = data1.dimensions['lat'].name
lon_nc = data1.dimensions['lon'].name
tim_nc = data1.dimensions['time'].name
lev_nc = data1.dimensions['lev'].name

lst1 = data1.variables.keys()
lst2 = data2.variables.keys()
print(lst1)

#create TS
varname = 'TS'
if varname in lst1:
    print("variable ", varname, " already exists")
    data1.variables['TS'][:] = 1
else:
    meanTS           = data1.createVariable('TS','float64',(tim_nc,lat_nc,lon_nc))
    meanTS.units     = 'K'
    meanTS.long_name = 'Surface temperature (radiative)'
    data1.variables['TS'][:] = 1
if varname in lst2:
    print("variable ", varname, " already exists")
    data2.variables['TS'][:] = 0    
else:
    sdTS           = data2.createVariable('TS','float64',(tim_nc,lat_nc,lon_nc))
    sdTS.units     = 'K'
    sdTS.long_name = 'Surface temperature (radiative)'
    data2.variables['TS'][:] = 0

#create TREFHT
varname = 'TREFHT'
if varname in lst1:
    print("variable ", varname, " already exists")
    data1.variables['TREFHT'][:] = 1
else:
    meanTREFHT           = data1.createVariable('TREFHT','float64',(tim_nc,lat_nc,lon_nc))
    meanTREFHT.units     = 'K'
    meanTREFHT.long_name = 'Reference height temperature'
    data1.variables['TREFHT'][:] = 1
if varname in lst2:
    print("variable ", varname, " already exists")
    data2.variables['TREFHT'][:] = 0
else:
    sdTREFHT           = data2.createVariable('TREFHT','float64',(tim_nc,lat_nc,lon_nc))
    sdTREFHT.units     = 'K'
    sdTREFHT.long_name = 'Reference height temperature'
    data2.variables['TREFHT'][:] = 0

#create LANDFRAC
varname = 'LANDFRAC'
if varname in lst1:
    print("variable ", varname, " already exists")
    data1.variables['LANDFRAC'][:] = 1
else:
    meanLANDFRAC           = data1.createVariable('LANDFRAC','float64',(tim_nc,lat_nc,lon_nc))
    meanLANDFRAC.units     = 'fraction'
    meanLANDFRAC.long_name = 'Fraction of sfc area covered by land'
    data1.variables['LANDFRAC'][:] = 1
if varname in lst2:
    print("variable ", varname, " already exists")
    data2.variables['LANDFRAC'][:] = 0
else:
    sdLANDFRAC           = data2.createVariable('LANDFRAC','float64',(tim_nc,lat_nc,lon_nc))
    sdLANDFRAC.units     = 'fraction'
    sdLANDFRAC.long_name = 'Fraction of sfc area covered by land'
    data2.variables['LANDFRAC'][:] = 0

#create QVMR
varname = 'QVMR'
if varname in lst1:
    print("variable ", varname, " already exists")
    data1.variables['QVMR'][:] = 1
else:
    meanQVMR           = data1.createVariable('QVMR','float64',(tim_nc,lev_nc,lat_nc,lon_nc))
    meanQVMR.mdims     = 1
    meanQVMR.units     = 'kg/kg'
    meanQVMR.mixing_ratio     = 'wet'
    meanQVMR.long_name = 'Specific humidity mixing ratio'
    data1.variables['QVMR'][:] = 1
if varname in lst2:
    print("variable ", varname, " already exists")
    data2.variables['QVMR'][:] = 0
else:
    sdQVMR           = data2.createVariable('QVMR','float64',(tim_nc,lev_nc,lat_nc,lon_nc))
    sdQVMR.mdims     = 1
    sdQVMR.units     = 'kg/kg'
    sdQVMR.mixing_ratio     = 'wet'
    sdQVMR.long_name = 'Specific humidity mixing ratio'
    data2.variables['QVMR'][:] = 0

data1.close()
data2.close()

