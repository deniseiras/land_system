# OI diagnostic computation for ensemble systems.
# Skeleton for single cycle! Need to be extended.
# @author: Giovanni Conti 
# @date: 30 March 2023

# Remarks:
# The procedure is based on a subsampling of the entire model space.
# Localization distances are computed in an approximate way.



# Import session.
#------------------------------------------
#------------------------------------------
import os
import sqlite3
import pandas as pd
import numpy as np
import math
from netCDF4 import Dataset
import bisect
import datetime
from fsoijo_plot import *



# Functions definition.
#------------------------------------------
#------------------------------------------
# Find the closest index.
def find_closest_index(x, y):
    i = bisect.bisect_left(x, y)
    if i == 0:
        return 0
    elif i == len(x):
        return len(x) - 1
    else:
        before = x[i-1]
        after = x[i]
        if after - y < y - before:
            return i
        else:
            return i-1



# Gaspari and Cohn localization function.
def gaspari_cohn(r):
    """Gaspari-Cohn function. r=z/cutoff"""
    if type(r) is float:
        ra = np.array([r])
    else:
        ra = r
    ra = np.abs(ra)
    gp = np.zeros_like(ra)
    i=np.where(ra<=1.)[0]
    gp[i]=-0.25*ra[i]**5+0.5*ra[i]**4+0.625*ra[i]**3-5./3.*ra[i]**2+1.
    i=np.where((ra>1.)*(ra<=2.))[0]
    gp[i]=1./12.*ra[i]**5-0.5*ra[i]**4+0.625*ra[i]**3+5./3.*ra[i]**2-5.*ra[i]+4.-2./3./ra[i]
    if type(r) is float:
        gp = gp[0]
    return gp





# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Exp name.
ename = "junov4"

# Analysis date ("YYYY-MM-DD-SSSSS").
adate = "2017-10-02-21600"
fdate=adate

# Path to the exp archive
patharc   = '/work/cmcc/gc02720/CESM2/archive'

#path2an   = patharc + '/' + ename + '-forecast/' + ename + '_forecast-' + fdate
path2an   = patharc + '/' + ename + '/' + ename + '-' + fdate
#path2db   = path2an + '/fsoi_jo-db'
path2db   = path2an

# Number of grid points. We will have a map of NGLAT*NGLON cells.
NGLAT = 2
NGLON = 7


obs2proc  = ['RADIOSONDE_U_WIND_COMPONENT', \
             'RADIOSONDE_V_WIND_COMPONENT', \
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
#             'VADWND_U_WIND_COMPONENT',\
#             'VADWND_V_WIND_COMPONENT'\
            ]



# Number of ensemble members.
nens = 3

# Type of localization: 'GC' for Gaspari-Cohn, 'Box' for Box.
loc_type = 'GC'

# The computation for the localization distances is approximate! It must be improved.
# Horizontal localization, half width Gaspari-Cohn (Km).
cutoff = 0.15 # radian
vert_normalization_scale_height = 1.5 # scale_height/radian
REarth = 6371 # Km

loch  = REarth*cutoff
vloch = vert_normalization_scale_height * cutoff # scale_height units. Used in the barometric equation to get the vertical localization.

# Vertical threshold in hPa.
vthreshold = 1
# Reference pressure in hPa.
P0 = 1013

# Where to save the output, plot and data.
path2sv = path2db + '/diag-' + fdate

# Plot samples img?
plot_img = 'FALSE'

# Chose level of output. 
# DEBUG = 1 only cells indication, DEBUG = 2 add vertical information, DEBUG = 3 also obs retrieve info
# DEBUG = 4 print also the pandas query dataframe
DEBUG = 3

# The computation is really hard and we need to speed it up choosing only same particular layer of interest
# level 83 is too much. 
reflevs=(850,500,400,200,150,90)

#******************************************
#    DO NOT MODIFY BELOW 
#******************************************

# Get the current date and time
start_t = datetime.datetime.now()
print('\n',start_t)

#------------------------------------------
# Print the parameters used.
print('\n Computation parameters:')
print('Experiment name: ', ename)
print('Analysis date: ', adate)
print('Path archive: ', patharc)
print('Path analysis: ', path2an)
print('Path dbs: ', path2db)
print('Path save: ', path2sv)
print('Comp. grid NGLAT: ', NGLAT)
print('Comp. grid NGLON: ', NGLON)
print('Observation to process: ', obs2proc)
print('Reference levels: ', reflevs)


#---------------------------------------------
# Create the save dir if needed
if not os.path.exists(path2sv):
     try:
         os.mkdir(path2sv)
     except OSError:
         print ("\nCreation of the directory %s failed" % path2sv)
     else:
         print ("\nSuccessfully created the directory %s " % path2sv)










# Computation.
#------------------------------------------
#------------------------------------------

print('\n Start the computation...')

# Determine how many db are present in the current dir.
listdb=[]
rescatalog=False
catalog_file=''
for file in os.listdir(path2db):
    if file.endswith(".db"):
       if 'catalog' in file:
          rescatalog=True
          catalog_file=file
          print('\ncatalog: ' + catalog_file)
       else:
         listdb.append(os.path.join(path2db, file))
listdb.sort()
print("\ndatabases: ", listdb)


# From catalog determine all the different kind of observation.
# We always have a catalog.db (the last element of the list), 
# so create a connection.
#rescatalog=any(item in path2db+'/'+'catalog.db' for item in listdb)
if rescatalog!=True:
   print('\nERROR: catalog not present!\n')
   exit()

con=sqlite3.connect(path2db + '/'+ catalog_file)
df = pd.read_sql("select * from catalog", con)
con.close()
dartotype=df['description'].unique()
# Remove 'none' and '' from the list if present.
dartotype=dartotype[dartotype != np.array(None)]
dartotype=dartotype[dartotype != np.array('')]
print("\nList of different SPREADS obs type:\n", dartotype, "\n")


# Check that some of the obs in the list obs2proc is present in 
# the dbs, otherwise exit.
cnt=0
for o2p in obs2proc:
    if np.where(dartotype==o2p) != []:
       cnt=cnt+1
if cnt==0:
   print('ERROR, no observations to study in the dbs')
   exit()


# Mask the dbs that must be excluded in the computation
maskdb = []

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


print('maskdb= ', maskdb)
print('maskdb len= ', len(maskdb))
print('listdb len= ', len(listdb))



# Create the empty FSOI and OI maps for the obs 2 process,
# define the grid of the map.
# The following define a support reference grid that allow to
# create a coarse grid by considering the closest gridpoint of 
# the model grid to the center of the cells of the support grid.
elat = np.linspace(90,-90,NGLAT+1,endpoint=True)   
elon = np.linspace(0,360,NGLON+1,endpoint=True)   
# Centers of the cells.
clon = elon[:-1] + 0.5*(elon[1]-elon[0]) 
clat = elat[:-1] + 0.5*(elat[1]-elat[0]) 

aname = path2an + '/' + ename + '.dart.e.cam_forecast_mean.' + adate + '.nc'
dset  = Dataset(aname, mode='r')
lon   = dset.variables['lon'][:]
lat   = dset.variables['lat'][:]
#slon  = dset.variables['slon'][:]
#slat  = dset.variables['slat'][:]
lev   = dset.variables['lev'][:]
dset.close()


if len(reflevs) == 0:
    print('\nAll the original levels will be used in the computation... go on vacation in the meanwhile')
else:
    print("\nOnly the closest levels to the reference levels will be involved in the computation")
    # Compute the absolute differece between lev and reflevs
    diff = np.abs(lev[:, np.newaxis] - np.array(reflevs))

    # Find the closes index
    closest_indices = np.argmin(diff, axis=0)

    # Seleziona solo i valori di lev più vicini ai valori di riferimento
    lev = lev[closest_indices]

    print('lev: ', lev)
    print('closest_indices: ', closest_indices)  # Array




# OI. 
oi   = np.zeros([len(obs2proc), len(lev), NGLAT, NGLON])
oi_sigma_o   = np.zeros([len(obs2proc), len(lev), NGLAT, NGLON])


# obs used counter, per type
ocount = np.zeros(len(obs2proc))


# Main computation.
#------------------------------------------
# Loop through the cells
ncel=1
for jj in range( NGLON ):
       
    for ii in range( NGLAT ):
      
        if DEBUG>=1: 
            print("\n\n Process cell ",ncel," out of ",NGLON*NGLAT)
        
        ncel=ncel+1
          
        # Given a location in degree (clat, clon), we need to consider
        # obse in that grid cell.
        latu = elat[ii]
        latd = elat[ii+1]
 
        lonl = elon[jj]
        lonr = elon[jj+1]
         
        if DEBUG>=1: 
            # Retrieve observation in these intervals.
            print(' Retrieve obs in these intervals (deg):')
            print('lat in [',latu,'    ',latd,']') 
            print('lon in [',lonl,'    ',lonr,']') 
            print('clat = ', str(clat[ii])) 
            print('clon = ', str(clon[jj])) 

        # Check all the possible dbs containing the observations needed.
        maskcnt=0
        for db in listdb[:]:
            if maskdb[maskcnt]==0:
               maskcnt=maskcnt+1
               continue
            maskcnt=maskcnt+1
            
            print('\nworking with db: ',db)

            # Retrieve a column of observations. 
            con=sqlite3.connect(db)
            dfo = pd.read_sql("select entryno,id,obsvalue, obs_error, prior_mean, prior_spread, kind, prior, posterior, dart_qc, member, deglat, deglon,\
                              levelht, vertco_type, (select distinct description from toc where kind=body.kind) \
                              as description from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and \
                              entryno=body_entryno where deglat>"+ str(latd) + " and deglat<" + str(latu) + " and deglon>"\
                              + str(lonl) + " and deglon<" + str(lonr) +" and dart_qc=0", con)
            con.close()

            # If there are not observation skip.
            if len(dfo['obsvalue'].tolist())<=0:
               print(' No obs in this cell from this db.')
               continue
            
            # Inside d4o we have Pa not hPa. 
            print(' Convert levelht in hPa.')         
            dfo['levelht'] = dfo['levelht']/100

            #dbg
            #dfo.to_pickle("mydata_2.pkl")
            #quit() 
            if DEBUG>=4:
               print('\n')
               print(dfo)
            

            # Loop through the column but skip above a certain threshold.
            for kk in range( len(lev)-1 ):
                 # If level is above 0.1 hPa skip the computation. 
                 clev = lev[kk]
                 if clev < vthreshold: 
                    continue

                 if DEBUG>=2:
                    print('\n Processing lev: ',clev,' level ',kk,'out of ', len(lev))
                 
                 # Compute vertical localization box for the obs retrieval
                 ulev = clev - np.abs(lev[kk+1] -clev)*0.5
                 if ulev < vthreshold:
                    ulev = vthreshold
                 if kk>0: 
                    dlev = clev + np.abs(clev - lev[kk-1])*0.5
                 else:
                    dlev = P0
    
 
                 # Get all the obs, prior, obs var, inside the vertical localization interval
                 # CHECK THAT HEIGHT IS IN Pa otherwise you need a conversion!
                 qstr="levelht>"+ f'{ulev:.2f}' +" and levelht<"+ f'{dlev:.2f}'
                 

                 do_ens_total = dfo.query(str(qstr))
                 
                 if len(do_ens_total['obsvalue'].tolist())<=0:
                    if DEBUG>=2:
                       print(' No obs in this vertical interval at this location.')
                       print(qstr)
                    continue

                 if DEBUG>=4:
                     print('\n')
                     print(qstr)
                     print(do_ens_total)
 
                     
                 # Loop beetween the different obs type
                 idx_o2p=0
                 for o2p in obs2proc:
                     if DEBUG>=2: 
                        print('Processing observation: ',o2p)
                     # Find different obs of this type.
                     qstr = "description=="+"'"+o2p +"'"
                     #print(qstr)
                     do_ens_type = do_ens_total.query(qstr)
                     if len(do_ens_type['obsvalue'].tolist())<=0:
                          if DEBUG>=3:
                              print(' No obs of this type '+ o2p +' in this interval.') 

                          # before jumping the loop we need to increase the obs type counter!
                          idx_o2p = idx_o2p + 1                
                          continue

                     if DEBUG>=4:
                        print(do_ens_type)
                       
                      
                     # Retrieve prior by entryno, id and member!!!!!!!!
                     m1           = do_ens_type.query('member==1')
                     prior_mean   = np.zeros([len(m1)])
                     prior_spread = np.zeros([len(m1)])
                     sigma_o      = np.zeros([len(m1)])
                     obs          = np.zeros([len(m1)])
                     levelht      = np.zeros([len(m1)])
                     deglat       = np.zeros([len(m1)])
                     deglon       = np.zeros([len(m1)])

                     # Retrieve the other related quantity needed for the final computation.
                     prior_mean[:]     = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_mean']
                     prior_spread[:]   = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_spread']
                     sigma_o[:]        = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obs_error']
                     obs[:]            = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obsvalue']
                     levelht[:]        = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['levelht']
                     deglat[:]         = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['deglat']
                     deglon[:]         = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['deglon']


         
                     norm_loc = len(m1)
                     if loc_type=='GC':
                         # Vertical distance in Km. Remember that levelht has been already converted in hPa.
                         #do  = (1-(levelht[iss]/P0)**0.190284)*44307.69396/1000 
                         #dv  = dclev-do
                         dv  = np.log(clev) - np.log(levelht)
                         gcv = gaspari_cohn(dv/vloch)
                         # Horizontal distance in Km by exploiting the Haversine Formula by exploiting the Haversine formula.
                         # https://en.wikipedia.org/wiki/Great-circle_distance  CHECK
                         phi1     =  clat[ii]*np.pi/180
                         phi2     =  deglat[:]*np.pi/180
                         lambda1  =  clon[jj]*np.pi/180
                         lambda2  =  deglon[:]*np.pi/180
                         dsigma   = 2 * np. arcsin( np.sqrt( np.sin( 0.5*(phi1-phi2) )**2 + (1 - np.sin( 0.5*(phi1-phi2) )**2 - np.sin( 0.5*(phi1+phi2) )**2 )*np.sin( 0.5*(lambda1-lambda2) )**2 )  )
                         dh       = REarth*dsigma
                         gch      = gaspari_cohn(dh/loch) 
                         gcloc    = gch * gcv
                         norm_loc = np.sum(gcloc)

                     loc=1 
                     for iss in range( len(m1) ):
                          # Compute the 3D distance to apply the Gaspary and Cohn correction.
                          if loc_type=='GC':   
                             loc = gcloc[iss]
 
                          # compute the oi
                          oi[idx_o2p, kk, ii, jj] = oi[idx_o2p, kk, ii, jj]  + loc * prior_spread[iss]**2 /(prior_spread[iss]**2 + sigma_o[iss]**2)
                          oi_sigma_o[idx_o2p, kk, ii, jj] = oi_sigma_o[idx_o2p, kk, ii, jj]  + loc * sigma_o[iss]
                     
                          ocount[idx_o2p]=ocount[idx_o2p]+1

                     # Normalize. PAY ATTENTION, we load a box of observations and some of that could be outside the elipsoid of the GC loc.
                     if np.sum(gch)==0:
                        norm_loc=1
                     oi[idx_o2p, kk, ii, jj] = oi[idx_o2p, kk, ii, jj] / norm_loc
                     oi_sigma_o[idx_o2p, kk, ii, jj] = oi_sigma_o[idx_o2p, kk, ii, jj] / norm_loc

                     idx_o2p=idx_o2p+1 # END o2p cycle





print('count obs used: ', ocount)



#DBG
np.savez('utestoi.npz', oi=oi, lat=clat, lon=clon, obs2proc=obs2proc, ocount=ocount)






# Plotting
#------------------------------------------
#------------------------------------------
if plot_img=='TRUE':
   # Consider four different regions: Global
   # NH, SH, TR for the bar plot. 
   print('\nbar plot')

   NH_oim= np.zeros(len(obs2proc))
   NH_oisd= np.zeros(len(obs2proc))
   SH_oim= np.zeros(len(obs2proc))
   SH_oisd= np.zeros(len(obs2proc))
   TR_oim= np.zeros(len(obs2proc))
   TR_oisd= np.zeros(len(obs2proc))

   tmp_idlat = np.where(clat>30)
   NH_oi = oi[:,:,tmp_idlat, :]
   for io in range(len(obs2proc)):
       mean = np.ma.mean(NH_oi[io,:,:,:].flatten())
       sd = np.ma.std(NH_oi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       NH_oim[io]  = mean
       NH_oisd[io] = sd
   tmp_idlat = np.where(clat<-30)
   SH_oi = oi[:,:,tmp_idlat, :]
   for io in range(len(obs2proc)):
       mean = np.ma.mean(SH_oi[io,:,:,:].flatten())
       sd = np.ma.std(SH_oi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       SH_oim[io]  = mean
       SH_oisd[io] = sd
   tmp_idlat = np.where( (clat>=-30) & (clat<=30) )
   TR_oi = oi[:,:,tmp_idlat,:]
   for io in range(len(obs2proc)):
       mean = np.ma.mean(TR_oi[io,:,:,:].flatten())
       sd = np.ma.std(TR_oi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       TR_oim[io]  = mean
       TR_oisd[io] = sd


   #fsoi_plot_bar(oi, obs2proc, title='Global'+'\n Date: '+fdate , xlabel='$OI$ %', ylabel='', psave=path2sv+'/oi_bar_global.png', fs=16, dpi=100)
   #fsoi_plot_bar(NH_oi, obs2proc, title='Northern Hemisphere'+'\n Date: '+fdate, xlabel='$OI$ %', ylabel='', psave=path2sv+'/oi_bar_nh.png', fs=16, dpi=100)
   #fsoi_plot_bar(SH_oi, obs2proc, title='Southern Hemisphere'+'\n Date: '+fdate, xlabel='$OI$ %', ylabel='', psave=path2sv+'/oi_bar_sh.png', fs=16, dpi=100)
   #fsoi_plot_bar(TR_oi, obs2proc, title='Tropics'+'\n Date: '+fdate, xlabel='', ylabel='$OI$ %', psave=path2sv+'/oi_bar_tr.png', fs=16, dpi=100)

 #  fsoi_plot_bar(oim,oisd, obs2proc, ocount, title='Global'+'\n Date: '+fdate , xlabel='$OI$ %', ylabel='', psave=path2sv+'/bar_global.png', fs=16, dpi=100)
#   fsoi_plot_bar(NH_oim, NH_oisd, obs2proc, ocount, title='Northern Hemisphere'+'\n Date: '+fdate, xlabel='$OI$ %', ylabel='', psave=path2sv+'/bar_nh.png', fs=16, dpi=100)
#   fsoi_plot_bar(SH_oim, SH_oisd, obs2proc, ocount, title='Southern Hemisphere'+'\n Date: '+fdate, xlabel='$OI$ %', ylabel='', psave=path2sv+'/bar_sh.png', fs=16, dpi=100)
#   fsoi_plot_bar(TR_oim, TR_oisd, obs2proc, ocount,title='Tropics'+'\n Date: '+fdate, xlabel='', ylabel='$OI$ %', psave=path2sv+'/bar_tr.png', fs=16, dpi=100)


# For the maps consider three reference levels
# 850 hPa, 500h Pa, 200 hPa and the vertical average. 

#   oi_map = oi.mean(axis=(0,1))
#   fsoi_plot_map(oi_map, title='OI, All Obs., Vertical Integration.'+'\n Date: '+fdate , xlabel='', ylabel='', psave=path2sv+'/oi_all_obs_vint_map.png', fs=16, dpi=100) 
#   idlev = find_closest_index(lev, 850)
#   oi_map = oi[:,idlev,:,:].mean(axis=0)
#   fsoi_plot_map(oi_map, title='FSOI-Jo, All Obs., Model Level: '+ str(lev[idlev])  +'\n Date: '+fdate , xlabel='', ylabel='', psave=path2sv+'/oi_all_obs_850_map.png', fs=16, dpi=100) 
#   idlev = find_closest_index(lev, 500)
#   oi_map = oi[:,idlev,:,:].mean(axis=0)
#   fsoi_plot_map(oi_map, title='FSOI-Jo, All Obs., Model Level: '+ str(lev[idlev])  +'\n Date: '+fdate , xlabel='', ylabel='', psave=path2sv+'/oi_all_obs_500_map.png', fs=16, dpi=100) 
#   idlev = find_closest_index(lev, 200)
#   oi_map = oi[:,idlev,:,:].mean(axis=0)
#   fsoi_plot_map(oi_map, title='OI, All Obs., Model Level: '+ str(lev[idlev])  +'\n Date: '+fdate , xlabel='', ylabel='', psave=path2sv+'/oi_all_obs_200_map.png', fs=16, dpi=100) 


# Profiles?? 

 #DBG
   np.savez('utestoi.npz', oi=oi, lat=clat, lon=clon, oim=oim, oisd=oisd, obs2proc=obs2proc, ocount=ocount)

# Data saving session.
#------------------------------------------
#------------------------------------------
print('\n Save data . . .')

with Dataset(path2sv+'/data_oi.nc', 'w', format='NETCDF4_CLASSIC') as ds:
 
    # Add 1D variables  
    #------------------------------------------
    ds.createDimension('model_lon',len(lon))
    model_lon_var = ds.createVariable('model_lon', 'f8', ('model_lon',))
    model_lon_var.units='degree' 
    model_lon_var.long_name='longitude coordinate of the original model' 
    #ds.variables['model_lon'][:] = lon   
    model_lon_var[:] = lon

    ds.createDimension('model_lat',len(lat))
    model_lat_var = ds.createVariable('model_lat', 'f8', ('model_lat',))
    model_lat_var.units = 'degree' 
    model_lat_var.long_name = 'latitude coordinate of the original model' 
    model_lat_var[:] = lat   
 
    ds.createDimension('model_lev',len(lev))
    model_lev_var = ds.createVariable('model_lev', 'f8', ('model_lev',))
    model_lev_var.units = 'hPa' 
    model_lev_var.long_name = 'vertical coordinate of the original model' 
    model_lev_var[:] = lev   
    
    ds.createDimension('c_lat',len(clat))
    co_lat_var = ds.createVariable('c_lat', 'f8', ('c_lat',))
    co_lat_var.units = 'degree' 
    co_lat_var.long_name = 'latitude coordinate of the coarser diag grid' 
    co_lat_var[:] = clat   

    ds.createDimension('c_lon',len(clon))
    co_lon_var = ds.createVariable('c_lon', 'f8', ('c_lon',))
    co_lon_var.units = 'degree' 
    co_lon_var.long_name = 'longitude coordinate of the coarser diag grid' 
    co_lon_var[:] = clon   
    


    # Add 2D variables  
    #------------------------------------------

    # Add 4D variables  
    #------------------------------------------
    ds.createDimension('num_obs_types', len(obs2proc))
    oi_var = ds.createVariable('oi', 'f8', ('num_obs_types', 'model_lev', 'c_lat', 'c_lon'))
    oi_var.units = ''
    oi_var.long_name = 'OI. First dimension is the list of obs type: ' + str(obs2proc)
    oi_var[:] = oi

    oi_var = ds.createVariable('oi_sigma_o', 'f8', ('num_obs_types', 'model_lev', 'c_lat', 'c_lon'))
    oi_var.units = ''
    oi_var.long_name = 'sigma_o used in the OI computation. First dimension is the list of obs type: ' + str(obs2proc)
    oi_var[:] = oi_sigma_o
    
    ds.setncattr('title', 'Simplified OI for ensemble filtering: forecast date: ' + adate)
    ds.setncattr('author', 'G. C.')
    


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')
