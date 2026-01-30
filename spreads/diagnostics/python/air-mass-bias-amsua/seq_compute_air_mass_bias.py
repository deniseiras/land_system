# Air mass bias computation program.  
#
#
# @author: Giovanni Conti 
# @date: 06 Feb. 2024



# Import session.
#------------------------------------------
#------------------------------------------
import numpy as np
#import math
import os
import sys
import datetime
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from tqdm import tqdm
from scipy.stats import linregress

# Parameters definition.
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************
# Exp name.
ename = "testam"

# Analysis date ("YYYY-MM-DD-SSSSS"), from ... to ....
start_date = "2017-11-01-21600"
end_date   = "2017-11-01-21600"

# Archiving dir path.
patharc   = '/work/cmcc/gc02720/CMCC-CM/archive'

# Define channels.
#chs = np.array([ 8, 9, 10, 11, 12, 13, 14])
#lev = np.array([ 150, 90, 50, 25, 10, 5, 2.5])*100  # Pa
chs = np.array([ 8,])
lev = np.array([ 150, ])*100  # Pa


# Platforms
#platforms = ['EOS_2_AMSUA_TB',
#              'NOAA_15_AMSUA_TB',
#              'NOAA_16_AMSUA_TB',
#              'NOAA_17_AMSUA_TB',
#              'NOAA_18_AMSUA_TB',
#              'NOAA_19_AMSUA_TB',
#              'METOP_1_AMSUA_TB',
#              'METOP_2_AMSUA_TB']

platforms = ['EOS_2_AMSUA_TB']



# Where to save data and img.
path2sv = patharc + '/' + ename + '/airmass_bias'

# Plot info
dpi = 100
fs=16




#******************************************
#    DO NOT MODIFY BELOW 
#******************************************

# Create the save dir if needed
if not os.path.exists(path2sv):
     try:
         os.mkdir(path2sv)
     except OSError:
         print ("\n Creation of the directory %s failed" % path2sv)
     else:
         print ("\n Successfully created the directory %s " % path2sv)



# Computation.
#------------------------------------------
#------------------------------------------
print("\n ------------- Start Computation ------------\n", flush=True)
# Get the current date and time
start_t = datetime.datetime.now()
print('\n ',start_t)


# Print the parameters used.
print('\n Computation parameters:')
print(' Experiment name: ', ename)
print(' Start date: ', start_date)
print(' End date: ', end_date)
print(' Path archive: ', patharc)
print(' Channels: ', chs)
print(' Levs: ', lev)
print(' Platforms: ', platforms)





# Load dbs data.
# Iterate through each date in the range
# Extract the date and seconds portions from the input strings
start_date_str, start_seconds_str = start_date[:10], start_date[-5:]
end_date_str, end_seconds_str = end_date[:10], end_date[-5:]

# Get the list of directory names in the given path
directory_path = patharc + "/" + ename  # Update with the actual directory path
directories = os.listdir(directory_path)

# Filter the directories based on the date and seconds information
filtered_directories = [
    directory for directory in directories
    if directory.startswith(ename) and directory[-16:-6] == start_date_str and directory[-5:] >= start_seconds_str and directory[-5:] <= end_seconds_str
]

filtered_directories.sort()


if not filtered_directories:
    print("ERROR: filtered_directories is empty. Exiting program.")
    sys.exit()  # or sys.exit() if you've imported sys module


num_dirs = len(filtered_directories)

# Initialize the dictionary containing the final results.
am_bias = {}
for platform in platforms:
    ambias_per_platform = {}
    for channel in chs:
        # Assign the scanbias dictionary to the current channel
        b0_array = np.full(num_dirs, np.nan)
        b1_array = np.full(num_dirs, np.nan)
        ambias_per_platform[channel] = {"b0": b0_array, "b1": b1_array}

    # Assign the channel data to the current platform
    am_bias[platform] = ambias_per_platform

# Example of calling
#print(am_bias['EOS_2_AMSUA_TB'][10]['b0'])



# For each dir
for idir, directory in enumerate(filtered_directories):
    dir_path = os.path.join(directory_path, directory)
    # Perform the desired actions with the directory path
    print("\n dir: ", dir_path)


    # Load the dbs.
    listdb=[]
    dfos = pd.DataFrame()
    for file in os.listdir(dir_path):
        if file.endswith(".db") and "AMSU" in file:
           listdb.append(file)
           print(" added: ", file)

           try:
              con=sqlite3.connect(dir_path + '/'+ file)

              platname = tuple(platforms)
              if len(platname) == 1:
                 platname += ('None',)

              # Use the tuple in the SQL query
              query = f"select id,reportype,entryno,kind,(select distinct description from toc where kind=body.kind) as description,\
                      obsvalue,prior_mean, qc,dart_qc, member, deglat, deglon, levelht from hdr join body on id=body.hdr_id \
                      join ens on id=ens.hdr_id and entryno=body_entryno where description in {platname}\
                      and dart_qc=0 and member=1"
              # Read data from the database using the query
              df = pd.read_sql(query, con)

              dfos = pd.concat([dfos, df], ignore_index=True)

           except sqlite3.Error as e:
               print("SQLite error:", e)
           finally:
               # Close the database connection in the finally block
               try:
                 con.close()
               except NameError:
                 pass  # Handle the case where the connection object wasn't created successfully

    if dfos.empty:
       print(' EMPTY DBS')
       sys.exit()


    # Load ZXXX in order to create predictors
    try:
       cur_date = dir_path[-16:]
       nc_file = dir_path + '/' + ename + '.h0.forecast.' + cur_date + '.nc'
       print(f" Opening netcdf: {nc_file}\n")
    
       # Attempt to open the netCDF file
       with Dataset(nc_file, 'r') as nc_data: #finally block is not necessary  'with' statement is context managers and automatically handle resource cleanup
           Z002 = nc_data.variables['Z002'][:]
           Z200 = nc_data.variables['Z200'][:]
           #Z300 = nc_data.variables['Z300'][:]
           grid_lat = nc_data.variables['lat'][:]
           grid_lon = nc_data.variables['lon'][:] 
           
           # Compute predictors 
           #predictor_z_002_300 = Z002 - Z300
           predictor_z_002_200 = Z002 - Z200

           # Create meshgrid of latitude and longitude values
           mesh_lat, mesh_lon = np.meshgrid(grid_lat, grid_lon)

           # Flatten the meshgrid arrays
           flat_mesh_lat = mesh_lat.flatten()
           flat_mesh_lon = mesh_lon.flatten()

    except FileNotFoundError:
       print("Error: The specified netCDF file does not exist.")
    except Exception as e:
       print(f"An error occurred: {e}")



    # For each platform
    for idp, platform in enumerate(platforms):
        print(f'\n compute bias for platform: {platform}')
        dplat = dfos[dfos['description'] == platform].copy()
        if dplat.empty:
           print(f'   NO VALUES FOR PLATFORM: {platform}')
           continue
       
        # For each channel
        for idc, channel in enumerate(chs):
            print(f'   channel: {channel}')
            dchan = dplat[dplat['levelht']==lev[idc]].copy()
            if dchan.empty:
               print(f'   NO VALUES FOR CH: {channel}')
               continue


            pairs = []
            total_rows = len(dchan)
            batch_size = 1000

            obs_latitudes = dchan['deglat'].values
            obs_longitudes = dchan['deglon'].values
            obs_values = dchan['obsvalue'].values
            prior_m_values = dchan['prior_mean'].values
            fg_dep = obs_values - prior_m_values

            # Create progress bar
            with tqdm(total=total_rows) as pbar:
              for idx in range(0, total_rows, batch_size):
              #dbg
              #for idx in range(0, 500, batch_size):
                  # Get batch of data
                  batch_obs_lat = obs_latitudes[idx:idx + batch_size]
                  batch_obs_lon = obs_longitudes[idx:idx + batch_size]
                  batch_fg_dep_val = fg_dep[idx:idx + batch_size]
        
                  # Calculate distances for the batch
                  distances = np.sqrt((flat_mesh_lat[:, None] - batch_obs_lat)**2 + (flat_mesh_lon[:, None] - batch_obs_lon)**2)
        
                  # Find the index of the grid point with the minimum distance for each observation
                  closest_idx = np.argmin(distances, axis=0)
        
                  # Retrieve the corresponding z values for each observation
                  #closest_z = predictor_z_002_300.flatten()[closest_idx]
                  closest_z = predictor_z_002_200.flatten()[closest_idx]
        
                  # Add pairs to the list
                  for fg_dep_val, p_val in zip(batch_fg_dep_val, closest_z):
                      pairs.append({'fg_dep': fg_dep_val, 'pvalue': p_val})
        
                  # Update progress bar
                  pbar.update(batch_size)

            # Convert the list of pairs to a DataFrame if necessary
            pairs_df = pd.DataFrame(pairs)
            fg_dep_values = pairs_df['fg_dep']
            p_values = pairs_df['pvalue']

            # Perform linear regression
            slope, intercept, r_value, p_value, std_err = linregress(p_values, fg_dep_values)
            am_bias[platform][channel]['b0'][idir] = intercept
            am_bias[platform][channel]['b1'][idir] = slope

            
            
            # Plotting
            #--------------------------------------
            #--------------------------------------
            # Create scatter plot
            sname = f"{platform}_{channel}_{cur_date}"
            plt.figure(sname, figsize=(8, 6))

            np_fg_dep_values = np.array(fg_dep_values)
            np_p_values = np.array(p_values)

            plt.scatter(np_p_values, np_fg_dep_values, color='blue', alpha=0.5, label='Data')

            # Perform linear regression
            regression_line = slope * np_p_values + intercept


            # Plot regression line
            plt.plot(np_p_values, regression_line, color='red', label='Linear Regression')

            # Add labels and legend
            plt.ylabel('Firsr Guess Dep.')
            plt.xlabel('Predictor')
            plt.title('Scatter Plot with Linear Regression Fit')
            plt.legend(fontsize=fs-3)
            #plt.legend(fontsize=fs-3, loc='upper center', bbox_to_anchor=(0.5, 0.3), ncol=3)

            # Show plot
            plt.grid(True)
            plt.savefig(path2sv+'/'+sname+'.png', format='png')
            plt.close()

            # Print regression parameters
            print(f" Slope: {slope}")
            print(f" Intercept: {intercept}")
            print(f" R-value: {r_value}")
            print(f" P-value: {p_value}")
            print(f" Standard Error: {std_err}")










# Saving session.
#------------------------------------------
#------------------------------------------
print("\n Saving...")
np.savez( path2sv + '/am_bias.npz', am_bias=am_bias, exp_name=ename, start_date=start_date,
                                      end_date=end_date, chs=chs, lev=lev, platforms=platforms)





# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n ',final_t)
print('  Execution Time: ',final_t-start_t)

print('\n\n -------------------- END ------------------- \n')











