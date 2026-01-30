import pandas as pd
import numpy as np
import sys
import concurrent.futures
import time
import xarray as xr
import glob
import shutil

def copy_and_overwrite(src, dst):
    shutil.copyfile(src, dst)
    
START = time.time()

files = np.loadtxt(sys.argv[1], dtype='str')

print(f"NUMBER OF FILES TO TRANSFORM: {len(files)}")    

def process_file(filename):
    
    print(f"START FILE: {filename}")
    START2 = time.time()

    with xr.open_dataset(filename, mode='a', decode_times=False, decode_coords=False) as data1:
        
        # Load specific variables into memory
        data1q  = data1['Q']#.load()  # Load variable1 into memory
        data1lf = data1['LANDFRAC']#.load()  # Load variable2 into memory        
        # data1of = data1['OCNFRAC']#.load()  # Load variable1 into memory
        data1if = data1['ICEFRAC']#.load()  # Load variable2 into memory
               
        # data1q = data1['Q'].values
        # data1lf = data1['LANDFRAC'].values
        # data1of = data1['OCNFRAC'].values
        # data1if = data1['ICEFRAC'].values

        # #threshold = 280 # or whatever your constant c is

        # np.where(condition, value if true, value if false)
        #new_data = np.where(data < threshold, threshold, data)

        # new_data = data1lf
        # new_data = np.where(data1lf > data1of, 0, 1)
        data1lf = np.where(data1if > 0.5, 2, data1lf)
        
        lat_nc = data1.coords['lat'].name
        lon_nc = data1.coords['lon'].name
        tim_nc = data1.coords['time'].name
        lev_nc = data1.coords['lev'].name
    
        data1['QVMR'] = ((tim_nc,lev_nc,lat_nc,lon_nc), data1q.values/(1-data1q.values))
        data1['QVMR'].attrs['mdims'] = 1
        data1['QVMR'].attrs['units'] = 'kg/kg'
        data1['QVMR'].attrs['mixing_ratio'] = 'wet'
        data1['QVMR'].attrs['long_name'] = 'Specific humidity mixing ratio'
        
        data1['LANDFRAC'][:] = data1lf
        
        #data1.to_netcdf(f"{filename.replace('.nc', '.nc_converted')}", format='netCDF4', mode='w')  # Write mode ('w') will overwrite the file
        data1.to_netcdf(f"{filename.replace('.nc', '.nc_converted')}", mode='w')  # Write mode ('w') will overwrite the file
        data1.close()
        shutil.move(f"{filename.replace('.nc', '.nc_converted')}", filename, copy_function=copy_and_overwrite)
            
        print(f"END FILE: {filename}: {time.time()-START2}")        
    

max_workers = int(sys.argv[2])

def load_parallel(filename, max_workers):
    # ThreadPoolExecutor by the maximum number of process to run simultaneously 
    with concurrent.futures.ProcessPoolExecutor(max_workers=max_workers) as executor:
        list(executor.map(process_file, filename))

load_parallel(files, max_workers)

print(f"TOOK: {time.time()-START}")
