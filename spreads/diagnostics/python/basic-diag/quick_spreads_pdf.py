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
ename = "spreads_all"

# Analysis date ("YYYY-MM-DD-SSSSS").
start_date = "2017-11-12-21600"

# Forecast date ("YYYY-MM-DD-SSSSS").
end_date = "2017-11-12-21600"

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
             'METOP_2_AMSUA_TB', \
             'VADWND_U_WIND_COMPONENT',\
             'VADWND_V_WIND_COMPONENT',\
             'LAND_SFC_PRESSURE',\
             'MARINE_SFC_PRESSURE'\
            ]


#obs2proc  = ['VADWND_U_WIND_COMPONENT','VADWND_V_WIND_COMPONENT','LAND_SFC_PRESSURE','MARINE_SFC_PRESSURE']


# Number of ensemble members.
nens = 80


# Where to save the output, plot and data.
#path2sv = path2db + '/basic_diag'
path2sv = '/work/cmcc/gc02720/' + 'basic_diag'


# Regions to be investigated.
regions=('Global', 'NH', 'SH', 'TR')


# Diag type. (total_spread and rms MUST BE defined before the index if needed.)
diag_type=('bias_prior_pdf', 'bias_posterior_pdf')


#******************************************
#    DO NOT MODIFY BELOW
#******************************************


# Get the current date and time
start_t = datetime.datetime.now()
print('\n',start_t, flush=True)

#------------------------------------------
# Print the parameters used.
print('\n Computation parameters:', flush=True)
print(' Experiment name: ', ename, flush=True)
print(' Start date: ', start_date, flush=True)
print(' End date: ', end_date, flush=True)
print(' Path archive: ', patharc, flush=True)
print(' Path experiment: ', path2db, flush=True)
print(' Path save: ', path2sv, flush=True)
print(' Observation to process: ', obs2proc, flush=True)

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

print('\n Start the computation...', flush=True)


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
print("\n dir to process: ", filtered_directories, flush=True)


# Loop through the filtered directories
pdf_diag = {}
cnt_dir=0
Ndir = len(filtered_directories)
for directory in filtered_directories:
    dir_path = os.path.join(directory_path, directory)
    # Perform the desired actions with the directory path
    print("\n dir: ", dir_path, flush=True)
    print(" dir number ", cnt_dir+1, " out of ", Ndir, flush=True)

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
          elif any('MARINE_SFC' in obs or 'LAND_SFC' in obs for obs in obs2proc) and 'SYNP' in db:
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
        
        print(' loading info from: ', db, flush=True)
        con = sqlite3.connect(db)
        df = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
                          obsvalue, obs_error, prior_mean, prior_spread, posterior_mean, levelht, deglat, deglon,  dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno where member=1 and dart_qc=0", con)
        con.close()
        
        dfos = pd.concat([dfos, df], ignore_index=True)
                  

    
    # Loop within different obs types
    cnt_obt = 0
    for obt in obs2proc:
        obs_pdf_diag = {}
        print('\n processing obs: ', obt)
        # Loop within different regions.
        cnt_rg = 0
        for rg in regions:
            obs_rg_pdf_diag = {}
            if rg =='Global':
               dforg = dfos.query( "description == @obt") 
            elif rg == 'NH':
               dforg = dfos.query( "description == @obt and deglat >= 30" ) 
            elif rg == 'SH':
               dforg = dfos.query( "description == @obt and  deglat <= -30" ) 
            elif rg == 'TR': 
               dforg = dfos.query( "description == @obt and deglat >= -30 and deglat<=30" ) 
            else:
               print('\n ERROR no region defined with this label!', flush=True)
               exit()
                    
            print(' region: ', rg, flush=True)
            if len(dforg['obsvalue'].tolist())<=0:
                print(' No obs: ', obt,' in region: ',rg, ' at this time.')
                cnt_rg=cnt_rg+1
                continue


            prior_mean     = dforg['prior_mean']
            posterior_mean = dforg['posterior_mean']
            obs            = dforg['obsvalue']

            cnt_dt = 0
            for dtype in diag_type:
                if dtype == 'bias_prior_pdf':
                    tmp_arr = np.array(dforg['obsvalue']-dforg['prior_mean'])
                elif dtype == 'bias_posterior_pdf':
                    tmp_arr = np.array(dforg['obsvalue']-dforg['posterior_mean'])
                else:
                    print('\n ERROR diag defined with this label!', flush=True)
                    exit()
               
                obs_rg_pdf_diag[dtype] = tmp_arr

                cnt_dt = cnt_dt + 1
                  
            

            obs_pdf_diag[rg] = obs_rg_pdf_diag    
            cnt_rg = cnt_rg +1

        pdf_diag[obt] = obs_pdf_diag
        cnt_obt = cnt_obt+1

    partial_t = datetime.datetime.now()
    print('\n',partial_t)
    print(' Partial Time: ', partial_t-start_t, flush=True)

    cnt_dir = cnt_dir+1



# Saving variables.
np.savez(path2sv+'/pdf_all.npz',  pdf_diag=pdf_diag, regions=regions, obs2proc=obs2proc, diag_type=diag_type, start_date=start_date, end_date=end_date)


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t, flush=True)

print('\n -------------------- END ------------------- \n', flush=True)
