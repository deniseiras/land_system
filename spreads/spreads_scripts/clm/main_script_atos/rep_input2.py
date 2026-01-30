#!/ec/res4/hpcperm/ita0829/conda/envs/cesm/bin/python
import numpy as np
from netCDF4 import Dataset
import sys
import time
import concurrent.futures


def load_file(file):
    with Dataset(file, 'r+', format='NETCDF4') as data1:

        if 'QVMR' not in data1.variables:
            data1q = data1.variables['Q'][:]
            data1lf = data1.variables['LANDFRAC'][:]
            data1of = data1.variables['OCNFRAC'][:]
            data1if = data1.variables['ICEFRAC'][:]

            new_data = data1lf
            new_data = np.where(data1lf > data1of, 0, 1)
            new_data = np.where(data1if > 0.5, 2, data1lf)
            data1.variables['LANDFRAC'][:] = new_data[:]

            #adding QVMR
            # lst1 = data1.variables.keys()

            varname = 'QVMR'

            lat_nc = data1.dimensions['lat'].name
            lon_nc = data1.dimensions['lon'].name
            tim_nc = data1.dimensions['time'].name
            lev_nc = data1.dimensions['lev'].name

            newQVMR = data1.createVariable('QVMR','float64',(tim_nc,lev_nc,lat_nc,lon_nc))
            # newQVMR.mdims = 1
            # newQVMR.units = 'kg/kg'
            # newQVMR.mixing_ratio = 'wet'
            # newQVMR.long_name = 'Specific humidity mixing ratio'

            # Set attributes in a batch if possible
            newQVMR.setncatts({
                'mdims': 1,
                'units': 'kg/kg',
                'mixing_ratio': 'wet',
                'long_name': 'Specific humidity mixing ratio'
            })

            new_data = data1.variables['QVMR'][:]
            new_data = data1q/(1-data1q)
            data1.variables['QVMR'][:] = new_data

def load_parallel(df, max_workers):
    # ThreadPoolExecutor / ProcessPoolExecutor by the maximum number of process to run simultaneously 
    with concurrent.futures.ProcessPoolExecutor(max_workers=max_workers) as executor:
        return list(executor.map(load_file, df))


if __name__ == "__main__":

    start = time.time()
    print(f'STARTING {len(sys.argv[1:-1])}, {sys.argv[-1]} by time')
    load_parallel(sys.argv[1:-1], int(sys.argv[-1]))
    finish = time.time()-start
    print(f'FINISH TOOK: {finish}')
