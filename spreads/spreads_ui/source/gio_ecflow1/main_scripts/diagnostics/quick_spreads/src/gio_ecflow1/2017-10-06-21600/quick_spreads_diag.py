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

print("STARTING")
# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Exp name.
ename = 'gio_ecflow1'

# Analysis date ("YYYY-MM-DD-SSSSS").
start_date = '2017-10-06-21600'

# Forecast date ("YYYY-MM-DD-SSSSS").
end_date = '2017-10-06-21600'

# Path to the exp archive
patharc   = '/work/cmcc/gc02720/CMCC-CM/archive'

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


#obs2proc  = ['ACARS_U_WIND_COMPONENT','GPSRO_REFRACTIVITY']


# Number of ensemble members.
nens = 3


# Where to save the output, plot and data.
#path2sv = path2db + '/basic_diag'
path2sv = f'/work/cmcc/gc02720/CMCC-CM/basic_diag/{ename}/{start_date}'

# In hPa
reflevs=(1013,950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,90,50,25,10,5,2.5,1)

# Regions to be investigated.
regions=('Global', 'NH', 'SH', 'TR')


# Diag type. (total_spread and rms MUST BE defined before the index if needed.)
diag_type=('bias', 'spread', 'total_spread', 'oi', 'rmse', 'rmse_tspread_idx', 'num_assi', 'num_rej')


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
print(' Reference levels: ', reflevs, flush=True)

#---------------------------------------------
# Create the save dir if needed
if not os.path.exists(path2sv):
    try:
        os.makedirs(path2sv)
    except OSError:
        print ("\n Creation of the directory %s failed" % path2sv, flush=True)
    else:
        print ("\n Successfully created the directory %s " % path2sv, flush=True)


center_layers = []
for i in range(len(reflevs) - 1):
    center = (reflevs[i] + reflevs[i + 1]) / 2
    center_layers.append(center)
print(' Center layers: ', center_layers, flush=True)



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



# Define the arrays that will contain the diagnostics.
#evol_diag    = np.zeros([len(obs2proc),len(regions),len(diag_type),len(filtered_directories)])
#profile_diag = np.zeros([len(obs2proc),len(regions),len(diag_type),len(center_layers),len(filtered_directories)])
evol_diag = np.full([len(obs2proc), len(regions), len(diag_type), len(filtered_directories)], np.nan)
profile_diag = np.full([len(obs2proc), len(regions), len(diag_type), len(center_layers), len(filtered_directories)], np.nan)




# Loop through the filtered directories
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
        #IF USE MOER MEMBERS THEN YOU NEED TO CHANGE ALSO THE OTHER QUARIES
        #df = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
        #                  obsvalue, obs_error, prior_mean, prior_spread, levelht, deglat, deglon,  dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
        #                  where  member=1 ", con)
        # WITH PRIORS
        df = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
                          obsvalue, obs_error, prior_mean, prior_spread, prior, levelht, deglat, deglon,  dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno", con)
        con.close()
        
        dfos = pd.concat([dfos, df], ignore_index=True)
                  

    
    # Loop within different obs types
    cnt_obt = 0
    for obt in obs2proc:
        print('\n processing obs: ', obt)
        # Loop within different regions.
        cnt_rg = 0
        for rg in regions:
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

            #dbg
            #print(dforg)


            # Vertical loop.
            for kk in range(len(center_layers)):
                llayer         = reflevs[kk]
                ulayer         = reflevs[kk+1]
                
                if obt=='GPSRO_REFRACTIVITY':
                   # Convert in meters approximately. 
                   P0 = 1013
                   llev = 1000*(1-(llayer/P0)**0.190284)*44307.69396/1000
                   ulev = 1000*(1-(ulayer/P0)**0.190284)*44307.69396/1000
                   dforg_v        = dforg.query('levelht >= @llev and levelht <= @ulev')
                   
                   #dbg
                   #print(' ulev: ',ulev, flush=True) 
                   #print(' llev: ',llev, flush=True)
           

                else:
                   llayer = llayer*100 # convert in Pa
                   ulayer = ulayer*100
                   dforg_v        = dforg.query('levelht >= @ulayer and levelht <= @llayer')

                
                if len(dforg_v['obsvalue'].tolist())<=0:
                   #print(' No obs in this layer: '+str(reflevs[kk])+' - '+str(reflevs[kk+1]))
                   kk=kk+1
                   continue

                #dbg
                #print(dforg_v)


                # Retrieve prior by entryno, id and member!!!!!!!!
                m1             = dforg_v.query('dart_qc==0 and member==1')
                prior_mean   = np.zeros([len(m1)])
                prior_spread = np.zeros([len(m1)])
                sigma_o      = np.zeros([len(m1)])
                obs          = np.zeros([len(m1)])
                #num_ass      = np.zeros([len(m1)])
                #num_rej      = np.zeros([len(m1)])

                prior_mean     = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_mean']
                prior_spread   = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_spread']
                sigma_o        = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obs_error']
                obs            = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obsvalue']
                num_ass        = dforg_v.query("dart_qc == 0").shape[0]
                num_rej        = dforg_v.query("dart_qc > 0").shape[0]

                prior        = np.zeros([len(m1),nens])
                prior[:,0]   = m1['prior']
                for iee in range(nens-1):
                   mm=iee+2
                   prior[:,iee+1] = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member=="+str(mm) )['prior']

                #dbg
                #print(' prior shape: ', prior.shape)
                #print(' obs shape: ', obs.shape)
                #print(' prior_mean: ', prior_mean[:])
                #print(' obs: ', obs[:])

                cnt_dt = 0
                for dtype in diag_type:
                    if dtype == 'bias':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(obs-prior_mean)
                    elif dtype == 'spread':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(prior_spread)
                    elif dtype == 'total_spread':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean( np.sqrt(prior_spread**2 + sigma_o**2) )
                    elif dtype == 'oi':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(prior_spread**2 / (prior_spread**2 + sigma_o**2))
                    elif dtype == 'rmse':
                       rrs=0
                       for ne in range(nens):
                          rrs = rrs + (obs - prior[:,ne])**2
                       rrs = np.sqrt( rrs/(nens-1) )   
                       rrs = np.mean(rrs) 
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = rrs
                    elif dtype == 'rmse_tspread_idx':
                       index_total_spread = diag_type.index('total_spread')
                       index_rms = diag_type.index('rmse')  
                       rms_tmp = profile_diag[cnt_obt, cnt_rg, index_rms , kk, cnt_dir]
                       tspread_tmp = profile_diag[cnt_obt, cnt_rg, index_total_spread , kk, cnt_dir]
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = rms_tmp/tspread_tmp
                    elif dtype == 'num_assi':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = num_ass
                    elif dtype == 'num_rej':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = num_rej
                    else:
                       print('\n ERROR diag defined with this label!', flush=True)
                       exit()

                    cnt_dt = cnt_dt + 1
                  
            # Now compute the vertical average.
            for dd in range(len(diag_type)):
                slicep = profile_diag[cnt_obt, cnt_rg, dd, :, cnt_dir]
                #print(' slicep: ',slicep, flush=True)
                num_nan = np.isnan(slicep).sum()
                if num_nan == len(slicep):
                    evol_diag[cnt_obt, cnt_rg, dd, cnt_dir] = np.nan
                else:
                    evol_diag[cnt_obt, cnt_rg, dd, cnt_dir] = np.nanmean(slicep)

                
            cnt_rg = cnt_rg +1

        cnt_obt = cnt_obt+1

    partial_t = datetime.datetime.now()
    print('\n',partial_t)
    print(' Partial Time: ', partial_t-start_t, flush=True)

    cnt_dir = cnt_dir+1



# Saving variables.
np.savez(path2sv+'/utest_all.npz', evol_diag=evol_diag, profile_diag=profile_diag, center_layers=center_layers, regions=regions, obs2proc=obs2proc, diag_type=diag_type, start_date=start_date, end_date=end_date)


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t, flush=True)

print('\n -------------------- END ------------------- \n', flush=True)
