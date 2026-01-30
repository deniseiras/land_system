# Skeleton for simple diagnostic.
# @author: Giovanni Conti 
# @date: 5 July 2023





# Import session.
#------------------------------------------
#------------------------------------------
import os
import sqlite3
import pandas as pd
import numpy as np
import math
import datetime


# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Exp name.
ename = "spreads"

# Analysis date ("YYYY-MM-DD-SSSSS").
start_date = "2017-10-02-21600"

# Forecast date ("YYYY-MM-DD-SSSSS").
end_date = "2017-10-02-43200"

# Path to the exp archive
patharc   = '/work/cmcc/mg20022/CMCC-CM/archive'

path2db   = patharc + "/" + ename 


obs2proc  = ['RADIOSONDE_U_WIND_COMPONENT', \
             'RADIOSONDE_V_WIND_COMPONENT',  \
             'RADIOSONDE_TEMPERATURE', \
             'AIRCRAFT_U_WIND_COMPONENT', \
             'AIRCRAFT_V_WIND_COMPONENT', \
             'AIRCRAFT_TEMPERATURE', \
             'ACARS_U_WIND_COMPONENT', \
             'ACARS_V_WIND_COMPONENT', \
             'ACARS_TEMPERATURE', \
             'SAT_U_WIND_COMPONENT', \
             'SAT_V_WIND_COMPONENT', \
             'GPSRO_REFRACTIVITY', \
             'EOS_2_AMSUA_TB', \
             'NOAA_15_AMSUA_TB', \
             'NOAA_16_AMSUA_TB', \
             'NOAA_17_AMSUA_TB', \
             'NOAA_18_AMSUA_TB', \
             'NOAA_19_AMSUA_TB', \
             'METOP_1_AMSUA_TB', \
             'METOP_2_AMSUA_TB' \
#             'VADWND_U_WIND_COMPONENT',\
#             'VADWND_V_WIND_COMPONENT'\
            ]




# Number of ensemble members.
nens = 80


# Where to save the output, plot and data.
#path2sv = path2db + '/basic_diag'
path2sv = '/work/cmcc/gc02720/' + 'basic_diag'

# Substitute with layers?????
reflevs=(950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,90,50,25,10,5,2.5)

# Regions to be investigated.
regions=('Global', 'NH', 'SH', 'TR')


# Diag type.
diag_type=('bias','spread','total_spread','oi','rms','rms_tspread_idx')


#******************************************
#    DO NOT MODIFY BELOW
#******************************************


# Get the current date and time
start_t = datetime.datetime.now()
print('\n',start_t)

#------------------------------------------
# Print the parameters used.
print('\n Computation parameters:')
print(' Experiment name: ', ename)
print(' Start date: ', start_date)
print(' End date: ', end_date)
print(' Path archive: ', patharc)
print(' Path experiment: ', path2db)
print(' Path save: ', path2sv)
print(' Observation to process: ', obs2proc)
print(' Reference levels: ', reflevs)

#---------------------------------------------
# Create the save dir if needed
if not os.path.exists(path2sv):
    try:
        os.mkdir(path2sv)
    except OSError:
        print ("\n Creation of the directory %s failed" % path2sv, flush=True)
    else:
        print ("\n Successfully created the directory %s " % path2sv, flush=True)






# Computation.
#------------------------------------------
#------------------------------------------

print('\n Start the computation...')


# Load dbs data.
# Iterate through each date in the range

# Get the list of directory names in the given path
directory_path = path2db  # Update with the actual directory path
directories = os.listdir(directory_path)
#print(directories)

# Filter the directories based on the date and seconds information
lene=len(ename)
filtered_directories = [
    directory for directory in directories
    if directory.startswith(ename) and directory[lene+1:] >= start_date and directory[lene+1:] <= end_date 
]

filtered_directories.sort()
print("\n dir to process: ", filtered_directories)



# Define the arrays that will contain the diagnostics.
evol_diag    = np.zeros([len(obs2proc),len(regions),len(diag_type),len(filtered_directories)])
profile_diag = np.zeros([len(obs2proc),len(regions),len(diag_type),len(reflevs),len(filtered_directories)])




# Loop through the filtered directories
cnt_dir=0
Ndir = len(filtered_directories)
for directory in filtered_directories:
    dir_path = os.path.join(directory_path, directory)
    # Perform the desired actions with the directory path
    print("\n dir: ", dir_path)
    print(" dir number ", cnt_dir+1, " out of ", Ndir)

    # Load the dbs.
    listdb=[]
    maskdb=[]

    for file in os.listdir(dir_path):
       if file.endswith(".db") and "catalog" not in file:
             listdb.append(os.path.join(dir_path, file))
    listdb.sort()

    for db in listdb:
          if any('AMSUA' in obs for obs in obs2proc) and 'AMSU' in db:
             maskdb.append(1)
          elif any('SAT' in obs for obs in obs2proc) and 'AMV' in db:
             maskdb.append(1)
          elif any('AIRCRAFT' in obs or 'ACARS' in obs for obs in obs2proc) and 'ARC' in db:
             maskdb.append(1)
          elif any('RADIOSONDE' in obs for obs in obs2proc) and 'SND' in db:
             maskdb.append(1)
          elif any('GPSRO' in obs for obs in obs2proc) and 'GPSRO'in db:
             maskdb.append(1)
          elif any('VADWND' in obs for obs in obs2proc) and 'WDP' in db:
             maskdb.append(1)
          else:
             maskdb.append(0)
    
    
    print(' listdb= ', listdb, flush=True)
    print(' listdb len= ', len(listdb), flush=True)
    print(' maskdb= ', maskdb, flush=True)
    print(' maskdb len= ', len(maskdb), flush=True)

    if np.sum(maskdb)==0:
        print(' ERROR, no observations to study in the dbs', flush=True)
        exit()


    dfos = pd.DataFrame()

    # Loop within dbs.
    for db, maskcc in zip(listdb, maskdb):
        # print('db:', db)
        # print('maskdb:', maskcc)
        if maskcc == 0:
            continue

        # Read the database.
        
        print(' loading info from: ', db)
        con = sqlite3.connect(db)
        #df = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
        #                  obsvalue, obs_error, prior_mean, prior_spread, dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
        #                  where dart_qc=0 and member=1", con)
        df = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
                          obsvalue, obs_error, prior_mean, prior_spread, prior, dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
                          where dart_qc=0 ", con)
        con.close()
        
        dfos = pd.concat([dfos, df], ignore_index=True)
                  

    
    # Loop within different obs types
    cnt_obt = 0
    for obt in obs2proc:
        print(' processing obs: ', obt)
        # Query the obs type.
        # ...
        # Loop within different regions.
        cnt_rg = 0
        for rg in regions:
            # Loop diag type: bias, spread ....
            evol_diag[cnt_obt, cnt_rg, cnt_dt, cnt_dir]    = np.zeros([len(obs2proc),len(regions),len(diag_type),len(filtered_directories)])
            cnt_rg = cnt_rg +1

        cnt_obt = cnt_obt+1


   

    cnt_dir = cnt_dir+1


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')
