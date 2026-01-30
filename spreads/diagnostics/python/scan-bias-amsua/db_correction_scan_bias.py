#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jan 30 11:25:38 2024

@author: giovanniconti
"""

# Scan bias db correction program.  
#
#
# @author: Giovanni Conti 
# @date: 30 Jan 2024



# Import session.
#------------------------------------------
#------------------------------------------
import numpy as np
#import math
import os
import shutil
import sys
import datetime
import sqlite3
import pandas as pd

#import matplotlib.pyplot as plt


# Parameters definition.
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Virgin db path
path_virgin = '/Users/giovanniconti/Documents/data/CMCC-CM/archive/scanb_v2/obsdir'

# Analysis date ("YYYYMMDDHH")
date = "2017110106"

# Corrected db path for saving.
path_corrected = '/Users/giovanniconti/Documents/data/CMCC-CM/archive/scanb_v2/obsdir_fixed'

# Path to the numpy correction
path_scan = '/Users/giovanniconti/Documents/data/CMCC-CM/archive/scanb_v2/scan_bias'


# Time slots
nts = 13


# # Where to save data and img.
# path2sv = patharc + '/' + ename + '/scan_bias'

# # Plot info
# dpi = 100
# fs=16




#******************************************
#    DO NOT MODIFY BELOW 
#******************************************



# Computation.
#------------------------------------------
#------------------------------------------
print("\n ------------- Start Computation ------------\n", flush=True)
# Get the current date and time
start_t = datetime.datetime.now()
print('\n ',start_t)

   # Print the parameters used.
print('\n Computation parameters:')
print(' Date: ', date)
print(' Path virgin dbs: ', path_virgin)
print(' Path corrected dbs: ', path_corrected)
print(' Path scan bias data: ', path_scan)
print(' Time slots: ', nts)

# Load scan bias data
print('\n Load: ', path_scan+'/scan_bias.npz')
data = np.load(path_scan+'/scan_bias.npz', allow_pickle=True) 
scan_bias = data['scan_bias'].item()
latb = data['latb']
lev = data['lev']
chs = data['chs']
platforms = data['platforms']

print(' Latitude bands: ', latb)
print(' Channels: ', chs)
print(' Levs: ', lev)
print(' Platforms: ', platforms)


# Define scan-angle bands.
latc = (latb[:-1] + latb[1:]) / 2
lat_labels = [f'{abs(latb[id])}\u00b0{"N" if latb[id] > 0 else "S" if latb[id] < 0 else ""} - {abs(latb[id+1])}\u00b0{"N" if latb[id+1] > 0 else "S" if latb[id+1] < 0 else ""}' for id in range(len(latc))]


# Copy virgin db in the new location before correction
yyyy=date[0:4]
mm=date[4:6]

# Source directory
source_dir = path_virgin + '/' + yyyy + '/' + mm + '/' + date

# Destination directory
destination_dir = path_corrected + '/' + yyyy + '/' + mm + '/' + date

# Copy the source directory and its contents to the destination
# Check if destination directory exists
if os.path.exists(destination_dir):
    print(f"\n The destination directory '{destination_dir}' already exists.")
else:
    # Copy the source directory and its contents to the destination
    try:
        shutil.copytree(source_dir, destination_dir)
        print(f"\n Successfully copied '{source_dir}' to '{destination_dir}'.")
    except OSError as e:
        print(f"\n Copying '{source_dir}' to '{destination_dir}' failed: {e}")




# Now we can loop through the time slots
print("\n Loop TS:")
for ts in range(1,nts+1):
    tsdir = destination_dir + "/" + f"TS{ts}"
    print(f"\n TS{ts}: ", tsdir)

    # Iterate over all files in the directory
    db_amsu_files = []
    for filename in os.listdir(tsdir):
        # Check if the filename contains 'AMSU'
        if 'AMSU.' in filename:
           db_amsu_files.append(filename)


    print(" file to correct: ", db_amsu_files)

    # If the list is not empty
    if db_amsu_files:
        for fdb in db_amsu_files:
            dbname = tsdir + "/" + fdb
            print("\n\n correcting: ", dbname)
        
            # Connect to your SQL database
            try:
                conn = sqlite3.connect(dbname)
                print(" Db connection created ...")
                cursor = conn.cursor()
                print(" Cursor created ...")

                
                # Write a query according to the platform, levelht, latitude_band
                for idp, sat in enumerate(platforms):
                    print("\n platform: ", sat)
                    for idch, ch in enumerate(chs):
                        print(" channel: ", ch)
                        for idlc, lc in enumerate(latc):
                             print(" latitude band: ", lat_labels[idlc])
                             
                             # Use the tuple in the SQL query
                             select_query = f"SELECT id,reportype,entryno,kind,(select distinct description from toc where kind=body.kind) as description,\
                                         obsvalue, scanpos, dart_qc, deglat, levelht from hdr join body on id=body.hdr_id \
                                         join sat on id=sat.hdr_id WHERE description = '{sat}' and levelht = {lev[idch]} and deglat <= {latb[idlc]} and deglat > {latb[idlc+1]} "
                              
                             #dbg  
                             #df = pd.read_sql(select_query, conn)   
                             #print(df)
                             
                             cursor.execute(select_query)
                             
                             rows = cursor.fetchall()
                             if rows:
                                print("Rows are not empty. Found results.")
                             else:
                                print("Rows are empty. No results found.")
                                continue
                             
                             # Loop through the results and execute the UPDATE query for each row
                             for row in rows:
                                 # Extract relevant data from the row (hdr_id, entryno are unique combination inside body)
                                 hdr_id   = row[0]
                                 entryno  = row[2]
                                 idscanpos = int(row[6]) - 1 #scanpos start from 1
                                 sb = scan_bias[sat][ch][lat_labels[idlc]][idscanpos]
                                 obsvalue = row[5] - sb
                                 
                                 #dbg
                                 print(f"hdr_id: {hdr_id}, entryno: {entryno}, obsvalue: {obsvalue}")
    
                                 # Execute the UPDATE query
                                 update_query = "UPDATE body SET obsvalue = ? WHERE hdr_id = ? and entryno = ?"
                                 cursor.execute(update_query, (obsvalue, hdr_id, entryno))
                                    
            
                # Commit changes to the database
                conn.commit()
            
        
            except sqlite3.Error as e:
                  print("Error during db operation:", e)
                  # Log the error or handle it appropriately
            finally:
                  # Close the database connection
                  if conn:
                    conn.close()
                    print("Db connection closed.")
        
        
        
        


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n ',final_t)
print('  Execution Time: ',final_t-start_t)

print('\n\n -------------------- END ------------------- \n')








