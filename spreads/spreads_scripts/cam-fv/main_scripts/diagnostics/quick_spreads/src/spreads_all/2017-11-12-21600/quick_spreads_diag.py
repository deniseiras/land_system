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
import pickle

print("STARTING")
# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Exp name.
ename = 'spreads_all'
# ename = 'onedeg'

# Analysis date ("YYYY-MM-DD-SSSSS").
start_date = '2017-11-12-21600'
# start_date = "2017-10-05-43200"

# Forecast date ("YYYY-MM-DD-SSSSS").
# end_date = "2017-10-05-43200"
end_date = '2017-11-12-21600'

# Path to the exp archive
patharc   = '/work/cmcc/mg20022/CMCC-CM/archive'

path2db   = patharc + "/" + ename 


# obs2proc  = ['RADIOSONDE_U_WIND_COMPONENT', \
#              'RADIOSONDE_V_WIND_COMPONENT',  \
#              'RADIOSONDE_TEMPERATURE', \
#              'AIRCRAFT_U_WIND_COMPONENT', \
#              'AIRCRAFT_V_WIND_COMPONENT', \
#              'AIRCRAFT_TEMPERATURE', \
#              'ACARS_U_WIND_COMPONENT', \
#              'ACARS_V_WIND_COMPONENT', \
#              'ACARS_TEMPERATURE', \
#              'SAT_U_WIND_COMPONENT', \
#              'SAT_V_WIND_COMPONENT', \
#              'GPSRO_REFRACTIVITY', \
#              'EOS_2_AMSUA_TB', \
#              'NOAA_15_AMSUA_TB', \
#              'NOAA_16_AMSUA_TB', \
#              'NOAA_17_AMSUA_TB', \
#              'NOAA_18_AMSUA_TB', \
#              'NOAA_19_AMSUA_TB', \
#              'METOP_1_AMSUA_TB', \
#              'METOP_2_AMSUA_TB',\
#              'VADWND_U_WIND_COMPONENT',\
#              'VADWND_V_WIND_COMPONENT',\
#              'LAND_SFC_PRESSURE',\
#              'MARINE_SFC_PRESSURE'
#             ]

obs2proc  = ['RADIOSONDE_U_WIND_COMPONENT',\
            'RADIOSONDE_V_WIND_COMPONENT',\
            'RADIOSONDE_TEMPERATURE',\
            'AIRCRAFT_U_WIND_COMPONENT',\
            'AIRCRAFT_V_WIND_COMPONENT',\
            'AIRCRAFT_TEMPERATURE',\
            'ACARS_U_WIND_COMPONENT',\
            'ACARS_V_WIND_COMPONENT',\
            'ACARS_TEMPERATURE',\
            'SAT_U_WIND_COMPONENT',\
            'SAT_V_WIND_COMPONENT',\
            'GPSRO_REFRACTIVITY',\
            'EOS_2_AMSUA_TB',\
            'NOAA_15_AMSUA_TB',\
            'NOAA_16_AMSUA_TB',\
            'NOAA_17_AMSUA_TB',\
            'NOAA_18_AMSUA_TB',\
            'NOAA_19_AMSUA_TB',\
            'METOP_1_AMSUA_TB',\
            'METOP_2_AMSUA_TB',\
            'VADWND_U_WIND_COMPONENT',\
            'VADWND_V_WIND_COMPONENT',\
            'LAND_SFC_PRESSURE',\
            'MARINE_SFC_PRESSURE']
#obs2proc  = ['ACARS_U_WIND_COMPONENT','GPSRO_REFRACTIVITY']


# Number of ensemble members.
nens = 80
# nens = 80


# Where to save the output, plot and data.
#path2sv = path2db + '/basic_diag'
path2sv = f'/work/cmcc/mg20022/CMCC-CM/basic_diag/{ename}/{start_date}'
# path2sv = f'/work/cmcc/mg20022/github/spreads/spreads_scripts/cam-fv/main_scripts/diagnostics/quick_spreads'

# In hPa
reflevs=(1014,950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,90,50,25,10,5,2.5,1)
# reflevs=(1013,950,900,850)

# Regions to be investigated.
regions=('Global', 'NH', 'SH', 'TR')


# Diag type. (total_spread and rms MUST BE defined before the index if needed.)
diag_type=('bias_prior', 'bias_posterior', 'spread', 'total_spread', 'obs_influence', 'rms', 'rmse', 'rms_tspread_idx', 'num_assi', 'num_rej')


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
   #  listdb = listdb[0:3]
   #  listdb = ["/work/cmcc/mg20022/CMCC-CM/archive/spreads_v5/spreads_v5-2017-10-05-43200/spreads_v5.spreads.AMSU.10.2017-10-05-43200.db"]
   #  print(listdb)
   #  quit()
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
          elif any('MARINE_SFC_PRESSURE' in obs or 'LAND_SFC_PRESSURE' in obs for obs in obs2proc) and 'SYNP' in db:
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
                          obsvalue, obs_error, prior_mean, prior_spread, bias_prior, bias_posterior, obs_influence, rms, rmse, posterior_mean, levelht, deglat, deglon,  dart_qc, body.status as bstatus, ens.status as ensstatus, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno where member=1", con)
        con.close()
        
        dfos = pd.concat([dfos, df], ignore_index=True)
                  
    # Loop within different obs types
    cnt_obt = 0
    ass = {} # filed by region and type of observation
    rej = {} # filed by region and type of observation
    
    assimilated = pd.DataFrame()
    rejected = pd.DataFrame()
      
    for obt in obs2proc:
        print('\n processing obs: ', obt)
        ass[obt] = {}
        rej[obt] = {}
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
            
            # ass[][] = dforg.query("dart_qc == 0 and member==1").shape[0]
            # rej = dforg.query("dart_qc > 0 and member==1").shape[0]
            
            ass[obt][rg] = {}
            rej[obt][rg] = {}
            
            print(' region: ', rg, flush=True)
            if len(dforg['obsvalue'].tolist())<=0:
                print(' No obs: ', obt,' in region: ',rg, ' at this time.')
                cnt_rg=cnt_rg+1
                continue

            #dbg
            #print(dforg)
            temporary_ass = pd.DataFrame()
            tmp = dforg.query("dart_qc == 0 and bstatus  == 1 and ensstatus  == 1")
            temporary_ass['obs-prior']       = tmp['obsvalue'].values - tmp['prior_mean'].values
            temporary_ass['obs-poste']       = tmp['obsvalue'].values - tmp['posterior_mean'].values
            # temporary_ass['obs-prior']       = tmp['bias_prior'].values
            # temporary_ass['obs-poste']       = tmp['bias_posterior'].values
            temporary_ass['rms']             = tmp['rms'].values
            temporary_ass['rmse']            = tmp['rmse'].values
            temporary_ass['obs_influence']   = tmp['obs_influence'].values
            temporary_ass['prior_mean']      = tmp['prior_mean'].values
            temporary_ass['posterior_mean']  = tmp['posterior_mean'].values
            temporary_ass['obsvalue']        = tmp['obsvalue'].values
            temporary_ass['levelht']         = tmp['levelht'].values
            temporary_ass['prior_spread']    = tmp['prior_spread'].values
            temporary_ass['obs_error']       = tmp['obs_error'].values
            temporary_ass['observation']     = obt 
            temporary_ass['region']          = rg
            temporary_ass['date']            = start_date[0:10]
            temporary_ass['hour']            = start_date[11:]
            
            assimilated = pd.concat([assimilated, temporary_ass], ignore_index=True)
            
            temporary_rej = pd.DataFrame()

            tmp = dforg.query("( dart_qc > 0 ) | ( bstatus != 1 ) | ( ensstatus != 1)")
            # tmp = dforg.query("(dart_qc > 0) | ((bstatus ) != true) | ((ensstatus ) != true)")
            
            # temporary_rej['obs-prior']       = tmp['bias_prior'].values
            temporary_rej['obs-prior']       = tmp['obsvalue'].values - tmp['prior_mean'].values
            # temporary_rej['obs-prior']       = tmp['obsvalue'].values - tmp['prior_mean'].values
            temporary_rej['prior_mean']      = tmp['prior_mean'].values
            temporary_rej['obsvalue']        = tmp['obsvalue'].values
            # rej[obt]['posterior_mean']  = tmp['obsvalue'].values - tmp['posterior_mean'].values
            temporary_rej['levelht']         = tmp['levelht'].values
            temporary_rej['observation']     = obt 
            temporary_rej['region']          = rg
            temporary_rej['date']            = start_date[0:10]
            temporary_rej['hour']            = start_date[11:]
            # with open('filename.pickle', 'wb') as handle:
            #    pickle.dump(ass, handle, protocol=pickle.HIGHEST_PROTOCOL)
            # quit()
            rejected = pd.concat([rejected, temporary_rej], ignore_index=True)
            # rejected.dropna(inplace=True)

            ##### FROM HERE
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
               #  m1             = dforg_v.query('dart_qc==0 and member==1')
               #  prior_mean   = np.zeros([len(m1)])
               #  prior_spread = np.zeros([len(m1)])
               #  sigma_o      = np.zeros([len(m1)])
               #  obs          = np.zeros([len(m1)])
               #  #num_ass      = np.zeros([len(m1)])
               #  #num_rej      = np.zeros([len(m1)])

               #  prior_mean     = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_mean']
               #  prior_spread   = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_spread']
               #  sigma_o        = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obs_error']
               #  obs            = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obsvalue']
                num_ass        = dforg_v.query("dart_qc == 0 and bstatus  == 1 and ensstatus  == 1").shape[0]
                num_rej        = dforg_v.query("dart_qc > 0 or bstatus  != 1 or ensstatus  != 1").shape[0]

               #  prior        = np.zeros([len(m1),nens])
               #  prior[:,0]   = m1['prior']
               #  for iee in range(nens-1):
               #     mm=iee+2
               #     prior[:,iee+1] = dforg_v.query("dart_qc==0 and entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member=="+str(mm) )['prior']

                #dbg
                #print(' prior shape: ', prior.shape)
                #print(' obs shape: ', obs.shape)
                #print(' prior_mean: ', prior_mean[:])
                #print(' obs: ', obs[:])
                print(temporary_ass['obs-prior'])
                cnt_dt = 0
                for dtype in diag_type:
                    if dtype == 'bias_prior':
                     #   profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(obs-prior_mean)
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['obs-prior'])
                    elif dtype == 'bias_posterior':
                     #   profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(obs-prior_mean)
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['obs-poste'])
                    elif dtype == 'spread':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['prior_spread'])
                    elif dtype == 'total_spread':
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean( np.sqrt(temporary_ass['prior_spread']**2 + temporary_ass['obs_error']**2) )
                    elif dtype == 'obs_influence':
                     #   profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(prior_spread**2 / (prior_spread**2 + sigma_o**2))
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['obs_influence'])
                    elif dtype == 'rms':
                     #   rrs=0
                     #   for ne in range(nens):
                     #      rrs = rrs + (obs - prior[:,ne])**2
                     #   rrs = np.sqrt( rrs/(nens-1) )   
                     #   rrs = np.mean(rrs) 
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['rms'])
                    elif dtype == 'rmse': 
                       profile_diag[cnt_obt, cnt_rg, cnt_dt, kk, cnt_dir] = np.mean(temporary_ass['rmse'])
                    elif dtype == 'rms_tspread_idx':
                       index_total_spread = diag_type.index('total_spread')
                       index_rms = diag_type.index('rms')  
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



# # Saving variables.
np.savez(path2sv+'/utest_all.npz', evol_diag=evol_diag, profile_diag=profile_diag, center_layers=center_layers, regions=regions, obs2proc=obs2proc, diag_type=diag_type, start_date=start_date, end_date=end_date)

total_ass = assimilated.copy()
total_ass['dt'] = total_ass['date'].astype(str) + '-' +  total_ass['hour'].astype(str)
total_ass.sort_values(by='dt', inplace=True)

total_rej = rejected.copy()
total_rej['dt'] = total_rej['date'].astype(str) + '-' +  total_rej['hour'].astype(str)
total_rej.sort_values(by='dt', inplace=True)

ass = total_ass[['dt', 'prior_mean', 'observation', 'region']].groupby(['dt', 'observation', 'region']).count().reset_index()
rej = total_rej[['dt', 'prior_mean', 'observation', 'region']].groupby(['dt', 'observation', 'region']).count().reset_index()

ass['status'] = 'Assimilated'
rej['status'] = 'Rejected'

total = pd.concat([ass, rej], ignore_index=True)

total.to_feather(f"{path2sv}/assimilation_metrics.feather")

for rg in ['Global', 'SH', 'NH', 'TR']:
   
   print(f'Save assimilated: {rg}')
   
   assim = assimilated.query(f"region == '{rg}'").copy()
   assim.reset_index(inplace=True, drop=True)
   assim.to_feather(f'{path2sv}/assimilated_{rg}.feather')
   
   reje = rejected.query(f"region == '{rg}'").copy()
   reje.reset_index(inplace=True, drop=True)
   reje.to_feather(f'{path2sv}/rejected_{rg}.feather')

# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t, flush=True)

print('\n -------------------- END ------------------- \n', flush=True)
