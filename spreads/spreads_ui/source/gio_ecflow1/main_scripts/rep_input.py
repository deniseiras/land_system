import numpy as np
from netCDF4 import Dataset
import sys

# main
filename= sys.argv[1] 

data1 = Dataset(filename,'r+')

#data1 = Dataset('datain/testin.nc','r+')

#data2 = Dataset('testin.nc','r+')

data1q = data1.variables['Q'][:]
data1lf = data1.variables['LANDFRAC'][:]
data1of = data1.variables['OCNFRAC'][:]
data1if = data1.variables['ICEFRAC'][:]

#print(np.shape(data1q))

#threshold = 280 # or whatever your constant c is

# np.where(condition, value if true, value if false)
#new_data = np.where(data < threshold, threshold, data)

new_data = data1lf
new_data = np.where(data1lf > data1of, 0, 1)
new_data = np.where(data1if > 0.5, 2, data1lf)
data1.variables['LANDFRAC'][:] = new_data[:]

#adding QVMR
lst1 = data1.variables.keys()

varname = 'QVMR'
if varname in lst1:
    print("variable ", varname, " already exists")
else:
    lat_nc = data1.dimensions['lat'].name
    lon_nc = data1.dimensions['lon'].name
    tim_nc = data1.dimensions['time'].name
    lev_nc = data1.dimensions['lev'].name

    newQVMR = data1.createVariable('QVMR','float64',(tim_nc,lev_nc,lat_nc,lon_nc))
    newQVMR.mdims = 1
    newQVMR.units = 'kg/kg'
    newQVMR.mixing_ratio = 'wet'
    newQVMR.long_name = 'Specific humidity mixing ratio'

    new_data = data1.variables['QVMR'][:]
    new_data = data1q/(1-data1q)
    data1.variables['QVMR'][:] = new_data

data1.close()


