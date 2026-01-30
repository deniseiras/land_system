# Scan bias computation program.  
#
#
# @author: Giovanni Conti 
# @date: 19 June 2023



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


# Parameters definition.
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************
# Exp name.
ename = "scanb_v2"

# Analysis date ("YYYY-MM-DD-SSSSS"), from ... to ....
start_date = "2017-11-01-21600"
end_date   = "2017-11-01-21600"

# Archiving dir path.
patharc   = '/work/cmcc/gc02720/CMCC-CM/archive'

# Define latitude bands boundary.
latb = np.array([ 90, 80, 70, 60, 50, 40, 30, 20, 10, 0, -10, -20, -30, -40, -50, -60, -70, -80, -90  ])

# Define channels.
chs = np.array([ 8, 9, 10, 11, 12, 13, 14])
lev = np.array([ 150, 90, 50, 25, 10, 5, 2.5])*100  # Pa
#chs = np.array([ 8,])
#lev = np.array([ 150, ])*100  # Pa


# Platforms
platforms = ['EOS_2_AMSUA_TB',
              'NOAA_15_AMSUA_TB',
              'NOAA_16_AMSUA_TB',
              'NOAA_17_AMSUA_TB',
              'NOAA_18_AMSUA_TB',
              'NOAA_19_AMSUA_TB',
              'METOP_1_AMSUA_TB',
              'METOP_2_AMSUA_TB']

#platforms = ['NOAA_16_AMSUA_TB']


# Where to save data and img.
path2sv = patharc + '/' + ename + '/scan_bias'

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
print(' Latitude bands: ', latb)
print(' Channels: ', chs)
print(' Levs: ', lev)
print(' Platforms: ', platforms)


# Define scan-angle bands.
latc = (latb[:-1] + latb[1:]) / 2
lat_labels = [f'{abs(latb[id])}\u00b0{"N" if latb[id] > 0 else "S" if latb[id] < 0 else ""} - {abs(latb[id+1])}\u00b0{"N" if latb[id+1] > 0 else "S" if latb[id+1] < 0 else ""}' for id in range(len(latc))]


# Initialize the dictionary containing the final results.
scan_bias = {}
for platform in platforms:
    scanbias_per_platform = {}
    for channel in chs:
        # Initialize scanbias dictionary for the current channel
        scanbias_per_channel = {lat_label: np.full(30, np.nan) for lat_label in lat_labels}
        
        # Assign the scanbias dictionary to the current channel
        scanbias_per_platform[channel] = scanbias_per_channel
    
    # Assign the channel data to the current platform
    scan_bias[platform] = scanbias_per_platform

# Example of calling
#scan_bias['EOS_2_AMSUA_TB'][10]['60°S - 70°S']
#Out[43]: 
#array([nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan,
#       nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan, nan,
#       nan, nan, nan, nan])




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


# Loop through the filtered directories
for directory in filtered_directories:
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

           con=sqlite3.connect(dir_path + '/'+ file)
           
           platname = tuple(platforms)
           # Use the tuple in the SQL query
           query = f"select id,reportype,entryno,kind,(select distinct description from toc where kind=body.kind) as description,\
                   obsvalue,prior_mean, posterior_mean, scanpos, qc,dart_qc,member, deglat, levelht from hdr join body on id=body.hdr_id \
                   join ens on id=ens.hdr_id and entryno=body_entryno join sat on id=sat.hdr_id where description in {platname}\
                   and dart_qc=0 and member=1"
           # Read data from the database using the query
           df = pd.read_sql(query, con)
           
                             
           # df = pd.read_sql("select id,reportype,entryno,kind,(select distinct description from toc where kind=body.kind) as description,\
           #                   obsvalue,prior_mean, posterior_mean, scanpos, qc,dart_qc,member, deglat, levelht from hdr join body on id=body.hdr_id \
           #                   join ens on id=ens.hdr_id and entryno=body_entryno join sat on id=sat.hdr_id where description in \
           #                   ('EOS_2_AMSUA_TB','NOAA_15_AMSUA_TB','NOAA_16_AMSUA_TB','NOAA_17_AMSUA_TB','NOAA_18_AMSUA_TB','NOAA_19_AMSUA_TB','METOP_1_AMSUA_TB','METOP_2_AMSUA_TB')\
           #                   and dart_qc=0 and member=1" , con)
                             
           con.close()
           dfos = pd.concat([dfos, df], ignore_index=True)


          

    print(" data extracted from: ", listdb)
    
    if dfos.empty:
       print(' EMPTY DBS')
       sys.exit()

#dbg
#print(dfos)

# Now that we have our pool of data we can compute the bias. To make the computation
# more efficient we should move the following cycles inside the previous loop, to avoid
# giant pandas dataframe.

smask = np.full((len(platforms), len(chs)), 1)
for idp, platform in enumerate(platforms):
    print(f'\n compute bias for platform: {platform}')
    dplat = dfos[dfos['description'] == platform].copy()
    if dplat.empty:
        print(f'   NO VALUES FOR PLATFORM: {platform}')
        smask[idp,:]=0
        continue
    
    for idc, channel in enumerate(chs):
        print(f'   channel: {channel}')
        dchan = dplat[dplat['levelht']==lev[idc]].copy()
        if dchan.empty:
            print(f'   NO VALUES FOR CH: {channel}')
            smask[idp,idc]=0
            continue
        
        for idlat, lat_band in enumerate(lat_labels):
            print(f'      latitudinal band: {lat_band}')
            
            scanbias = np.zeros(30)
            
            dfband  = 0
            lat_max = latb[idlat]
            lat_min = latb[idlat+1]
            # Extract rows where deglat is between lat_max and lat_min
            dfband = dchan[(dchan['deglat'] >= lat_min) & (dchan['deglat'] <= lat_max)].copy()
            
            if dfband.empty:
                print(f'   NO VALUES FOR BAND: {lat_band}')
                continue
            
            # Filter rows with scanpos equal to 15 or 16
            filtered_df = dfband[dfband['scanpos'].isin([15, 16])].copy()
            #f Calculate the difference mb = obsvalues - prior_mean
            filtered_df['mb'] = filtered_df['obsvalue'] - filtered_df['prior_mean']
            # Compute the average of the 'mb' column
            nadir_mb = filtered_df['mb'].mean()
           
            dfband['scan_bias'] = dfband['obsvalue'] - dfband['prior_mean'] - nadir_mb
            for idscan in range(1,31):
                scanbias[idscan-1] = dfband[dfband['scanpos']==idscan]['scan_bias'].mean()
                
                    
            scan_bias[platform][channel][lat_band]=scanbias.copy()







# Saving session.
#------------------------------------------
#------------------------------------------
print("\n Saving...")
np.savez( path2sv + '/scan_bias.npz', scan_bias=scan_bias, smask=smask, exp_name=ename, start_date=start_date,
                                      end_date=end_date, latb=latb, chs=chs, lev=lev, platforms=platforms)







# Plotting.
#------------------------------------------
#------------------------------------------

print("\n Plotting...")
# Scan bias plot. For different platforms and channel plot all the bands
for idp, platform in enumerate(platforms):
    if np.all(smask[idp, :] == 0):
        continue
    for idc, channel in enumerate(chs):
        if smask[idp, idc] == 0:
             continue
        fig = plt.figure(f'{platform} ch:{channel}', figsize=(1000/dpi,1000/dpi), dpi=dpi)    
        sname=f'{platform}_{channel}.png'
        ax  = fig.add_subplot(111)
        
        color_cycle = plt.cm.tab20.colors
        plt.gca().set_prop_cycle('color', color_cycle)
    
        x=np.arange(1,31)
        for idl, label in enumerate(lat_labels):
            plt.plot(x, scan_bias[platform][channel][label] , 'o-', label=label, linewidth=2)
      
        plt.xlim([0,30])
        plt.ylabel('Bias $K$',fontsize=fs)
        plt.xlabel('scan position',fontsize=fs)
        plt.title(f'{platform} ch:{channel}',fontsize=(fs))
        plt.xticks(fontsize=(fs-2))
        plt.yticks(fontsize=(fs-2))
        plt.grid()
        plt.legend(fontsize=fs-3, loc='upper center', bbox_to_anchor=(0.5, 0.3), ncol=3)
        plt.savefig(path2sv+'/'+sname, format='png')
        plt.close(fig) 
    




# Scan bias plot. For different platforms average on bands
for idp, platform in enumerate(platforms):
    if np.all(smask[idp, :] == 0):
        continue
    fig = plt.figure(f'{platform}_global', figsize=(1000/dpi,1000/dpi), dpi=dpi)    
    sname=f'{platform}_global.png'
    ax  = fig.add_subplot(111)
    
    color_cycle = plt.cm.tab20.colors
    plt.gca().set_prop_cycle('color', color_cycle)

    x=np.arange(1,31)
    
           
    for idc, channel in enumerate(chs):
        if smask[idp, idc] == 0:
             continue

        tmp=scan_bias[platform][channel]
        tmp_arr = np.stack(list(tmp.values()), axis=0)
        average_array = np.nanmean(tmp_arr, axis=0)

        plt.plot(x, average_array , 'o-', label=f'ch: {channel}', linewidth=2)
  
    plt.xlim([0,30])
    plt.ylabel('Bias $K$',fontsize=fs)
    plt.xlabel('scan position',fontsize=fs)
    plt.title(f'{platform} global behaviour',fontsize=(fs))
    plt.xticks(fontsize=(fs-2))
    plt.yticks(fontsize=(fs-2))
    plt.grid()
    plt.legend(fontsize=fs-3, loc='upper center', bbox_to_anchor=(0.5, 0.3), ncol=3)
    plt.savefig(path2sv+'/'+sname, format='png')
    plt.close(fig)






# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n ',final_t)
print('  Execution Time: ',final_t-start_t)

print('\n\n -------------------- END ------------------- \n')




