# FSOI_Jo diagnostic computation for ensemble systems.
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
adate = "2017-10-02-43200"

# Forecast date ("YYYY-MM-DD-SSSSS").
fdate = "2017-10-03-43200"

# Path to the exp archive
patharc   = '/work/cmcc/gc02720/CESM2/archive'

path2an   = patharc + '/' + ename + '-forecast/' + ename + '_forecast-' + adate 
path2db   = path2an + '/fsoi_jo-db'

# Number of grid points. We will have a map of NGLAT*NGLON cells.
NGLAT =  40
NGLON =  100

#obs2proc  = ['RADIOSONDE_U_WIND_COMPONENT', \
#             'RADIOSONDE_V_WIND_COMPONENT', \
#             'RADIOSONDE_TEMPERATURE', \
#             'AIRCRAFT_U_WIND_COMPONENT', \
#             'AIRCRAFT_V_WIND_COMPONENT', \
#             'AIRCRAFT_TEMPERATURE', \
#             'ACARS_U_WIND_COMPONENT', \
#             'ACARS_V_WIND_COMPONENT', \
#             'ACARS_TEMPERATURE', \
#             'SAT_U_WIND_COMPONENT', \
#             'SAT_V_WIND_COMPONENT', \
#             'GPSRO_REFRACTIVITY', \
#             'EOS_2_AMSUA_TB', \
#             'NOAA_15_AMSUA_TB', \
#             'NOAA_16_AMSUA_TB', \
#             'NOAA_17_AMSUA_TB', \
#             'NOAA_18_AMSUA_TB', \
#             'NOAA_19_AMSUA_TB', \
#             'METOP_1_AMSUA_TB', \
#             'METOP_2_AMSUA_TB' \
##             'VADWND_U_WIND_COMPONENT',\
##             'VADWND_V_WIND_COMPONENT'\
#            ]


obs2proc  = [ 'EOS_2_AMSUA_TB', \
             'NOAA_15_AMSUA_TB', \
             'NOAA_16_AMSUA_TB', \
             'NOAA_17_AMSUA_TB', \
             'NOAA_18_AMSUA_TB', \
             'NOAA_19_AMSUA_TB', \
             'METOP_1_AMSUA_TB', \
             'METOP_2_AMSUA_TB' \
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

# FSOI-Jo with OI approximation?
use_oi = 'FALSE'

# Plot samples img?
plot_img = 'TRUE'

# Chose level of output. 
# DEBUG = 1 only cells indication, DEBUG = 2 add vertical information, DEBUG = 3 also obs retrieve info
# DEBUG = 4 print also the pandas query dataframe
DEBUG = 1 


# The computation is really hard and we need to speed it up choosing only same particular layer of interest
# level 83 is too much. 
#reflevs=(850,500,400,200,150,90)
reflevs=(150,)


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
print('Forecast date: ', fdate)
print('Path archive: ', patharc)
print('Path analysis: ', path2an)
print('Path forecast: ', path2db)
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

aname = path2an + '/' + ename + '_f_0001-' + adate + '.cam.h0.' + adate + '.nc'
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





# FSOI 
fsoi = np.zeros([len(obs2proc), len(lev), NGLAT, NGLON]) 
if use_oi=="TRUE":
   fsoi_oi = np.zeros([len(obs2proc), len(lev), NGLAT, NGLON]) 

# FSOI mask to see where we really have corrections. If nan we did not corrected that location and it must be discarded by the mean
fsoi_mask = np.full_like(fsoi, np.nan)

# obs used counter, per type
ocount = np.zeros(len(obs2proc))

# Analysis and Forecast on the same coarser grid.
an_mean = np.zeros([NGLAT,NGLON])
fo_mean = np.zeros([NGLAT,NGLON])
# Index mapping.
idlat = np.zeros([NGLAT,NGLON], dtype=int)
idlon = np.zeros([NGLAT,NGLON], dtype=int)
# Coarse grid points.
co_lat = np.zeros(NGLAT)
co_lon = np.zeros(NGLON)


if use_oi=="TRUE":
   # Load OI data.
   print(' BE SURE OI CONTAINS THE SAME LIST OF OBS YOU WANT TO USE FOR FSOI_Jo!') 
   oiname  = path2sv + '/data_oi.nc'
   print(' path to oi data: ', oiname)
   dset    = Dataset(oiname, mode='r')
   oi      = dset.variables['oi'][:]
   oi_sigma_o      = dset.variables['oi_sigma_o'][:]
   oi_lat  = dset.variables['c_lat'][:]
   oi_lon  = dset.variables['c_lon'][:]
   dset.close()
   if oi.shape[0]!=len(obs2proc):
      print(' ERROR the number of obs type in oi are different than the one you want to use here!')
      quit()




# Main computation.
#------------------------------------------
# Loop through the cells
ncel=1
for jj in range( NGLON ):
       
    # Define the closest lon index of the model grid to the center of the cell.
    ilon = find_closest_index(lon, clon[jj]) 
    idlon[:,jj] = int(ilon)       
                          
    if use_oi=="TRUE":
       i_oi_lon = find_closest_index(oi_lon, clon[jj]) 
 
    for ii in range( NGLAT ):
      
        if DEBUG>=1: 
            print("\n\n Process cell ",ncel," out of ",NGLON*NGLAT)
        
        ncel=ncel+1
          
        # Define the closest lat index of the model grid to the center of the cell.
        ilat = find_closest_index(lat, clat[ii])
        idlat[ii,:] = int(ilat)       
    
        if use_oi=="TRUE":
           i_oi_lat = find_closest_index(oi_lat, clat[ii]) 

 
        # Retrieve the central cell analysis columns for the whole ensemble.
        print('load ensemble columns  . . .')
        ens_T_an = np.zeros([len(lev),nens]);
        ens_Q_an = np.zeros([len(lev),nens]);
        ens_U_an = np.zeros([len(lev),nens]);
        ens_V_an = np.zeros([len(lev),nens]);
        for ee in range( nens ):
              print('member: ',ee+1)
              # Define the correct name of the member.
              width = 4                  
              instr = str(ee+1).zfill(width)
              # Load the state vector variables from all the members.
              aname = path2an + '/' + ename + '_f_' + instr  +'-' + adate + '.cam.h0.' + adate + '.nc'
              dset  = Dataset(aname, mode='r')
              if len(reflevs) > 0:
                  ens_T_an[:,ee]  = dset.variables['T'][0,closest_indices,idlat[ii,jj],idlon[ii,jj]]
                  ens_Q_an[:,ee]  = dset.variables['Q'][0,closest_indices,idlat[ii,jj],idlon[ii,jj]]
                  ens_U_an[:,ee]  = dset.variables['U'][0,closest_indices,idlat[ii,jj],idlon[ii,jj]]
                  ens_V_an[:,ee]  = dset.variables['V'][0,closest_indices,idlat[ii,jj],idlon[ii,jj]]
              else:
                  ens_T_an[:,ee]  = dset.variables['T'][0,:,idlat[ii,jj],idlon[ii,jj]]
                  ens_Q_an[:,ee]  = dset.variables['Q'][0,:,idlat[ii,jj],idlon[ii,jj]]
                  ens_U_an[:,ee]  = dset.variables['U'][0,:,idlat[ii,jj],idlon[ii,jj]]
                  ens_V_an[:,ee]  = dset.variables['V'][0,:,idlat[ii,jj],idlon[ii,jj]]
              dset.close() # END ee cycle (ensemble member analysis cycle).


        # Compute the horizontal localization interval for the obs retrieval.
        # Given a location in degree (clat, clon), we need to consider approximately all the observations
        # in a rectangle of sides [clat+dlato, clat-dlato] and [clon-dlono, clon+dlono]. 
        lat_deg2km = 110.574 # Km/degree
        dlato = 2 * loch/lat_deg2km  
        latu = lat[idlat[ii,jj]] + dlato
        latd = lat[idlat[ii,jj]] - dlato
        if latu > 90:
           latu = 90
        if latd < -90:
           latd = -90
 
        deg2rad = math.pi/180
        lon_deg2km = 111.320*np.cos(deg2rad*lat[idlat[ii,jj]]) # Km/degree
        dlono = 2 * loch/lon_deg2km
        lonl = lon[idlon[ii,jj]] - dlono
        lonr = lon[idlon[ii,jj]] + dlono
        if lonl < 0:
           lonl = 0
        if lonr > 360:
           lonr = 360
         
        if DEBUG>=1: 
            # Retrieve observation in these intervals.
            print(' Retrieve obs in these intervals (deg):')
            print('lat in [',latu,'    ',latd,']') 
            print('lon in [',lonl,'    ',lonr,']') 

        # Check all the possible dbs containing the observations needed.
        maskcnt=0
        for db in listdb[:]:
            #print('db:',db)
            #print('maskdb:',maskdb[maskcnt])
            if maskdb[maskcnt]==0:
               maskcnt=maskcnt+1
               continue
            maskcnt=maskcnt+1

            print('\nworking with db: ',db)

            # Retrieve a column of observations. 
            con=sqlite3.connect(db)
            #dfo = pd.read_sql("select obsvalue, obs_error, kind, prior, posterior, dart_qc, member, deglat, deglon,\
            #                  levelht, vertco_type, (select distinct description from toc where kind=body.kind) \
            #                  as description from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and \
            #                  entryno=body_entryno where deglat>"+ str(latd) + " and deglat<" + str(latu) + " and deglon>"\
            #                  + str(lonl) + " and deglon<" + str(lonr) +" and dart_qc=0", con)
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
            for kk in range( len(lev) ):
                 # If level is above 0.1 hPa skip the computation. 
                 clev = lev[kk]
                 if clev < vthreshold: 
                    continue
                 # Conversion in Km for the computation of the vertical localization.
                 #dclev = (1-(clev/P0)**0.190284)*44307.69396/1000 
                  


                 if DEBUG>=2:
                    print('\n Processing lev: ',clev,' level ',kk,'out of ', len(lev))
                 
                 # Compute vertical localization box for the obs retrieval
                 ulev = clev * np.exp(-vloch)
                 dlev = clev * np.exp(vloch)
                 if ulev < vthreshold:
                    ulev = vthreshold
                 if dlev > P0:
                    dlev = P0 
    
 
                 # Get all the obs, prior, obs var, inside the vertical localization interval
                 # CHECK THAT HEIGHT IS IN Pa otherwise you need a conversion!
                 qstr="levelht>"+ f'{ulev:.2f}' +" and levelht<"+ f'{dlev:.2f}'
                 
                 #dbg
                 #import difflib
                 #d = difflib.Differ()
                 #diff = d.compare([qstr], [ss])
                 #print('\n'.join(diff))

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
 
                 # If there are obs then retrieve all the analysis ensemble members component at this level.
                 Tan_ens = ens_T_an[kk,:]
                 Qan_ens = ens_Q_an[kk,:]
                 Uan_ens = ens_U_an[kk,:]
                 Van_ens = ens_V_an[kk,:]
                     
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
                     prior        = np.zeros([len(m1),nens])
                     prior_mean   = np.zeros([len(m1)])
                     prior_spread = np.zeros([len(m1)])
                     sigma_o      = np.zeros([len(m1)])
                     obs          = np.zeros([len(m1)])
                     levelht      = np.zeros([len(m1)])
                     deglat       = np.zeros([len(m1)])
                     deglon       = np.zeros([len(m1)])
                     prior[:,0]   = m1['prior']
                     for iee in range(nens-1):
                         mm=iee+2
                         prior[:,iee+1] = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member=="+str(mm) )['prior']

                     # Retrieve the other related quantity needed for the final computation.
                     prior_mean[:]     = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_mean']
                     prior_spread[:]   = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['prior_spread']
                     sigma_o[:]        = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obs_error']
                     obs[:]            = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['obsvalue']
                     levelht[:]        = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['levelht']
                     deglat[:]         = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['deglat']
                     deglon[:]         = do_ens_type.query("entryno=="+str(m1['entryno'].tolist()) + " and id=="+str(m1['id'].tolist())+" and member==1" )['deglon']


                     if use_oi=="TRUE":
                        oi_val         = oi[idx_o2p, kk, i_oi_lat, i_oi_lon]
                        oi_sigma_o_val = oi_sigma_o[idx_o2p, kk, i_oi_lat, i_oi_lon]
                        if oi_val==0:
                           omega_fac=0
                        else:
                           omega_fac      = np.sqrt( oi_val**2/(oi_val**2 + oi_sigma_o_val**2) )

         
                     if loc_type=='GC':
                         # Vertical distance in Km. Remember that levelht has been already converted in hPa.
                         #do  = (1-(levelht[iss]/P0)**0.190284)*44307.69396/1000 
                         #dv  = dclev-do
                         dv  = np.log(clev) - np.log(levelht)
                         gcv = gaspari_cohn(dv/vloch)
                         # Horizontal distance in Km by exploiting the Haversine Formul by exploiting the Haversine formula.
                         # https://en.wikipedia.org/wiki/Great-circle_distance  CHECK
                         phi1    =  lat[idlat[ii,jj]]*np.pi/180
                         phi2    =  deglat[:]*np.pi/180
                         lambda1 =  lon[idlon[ii,jj]]*np.pi/180
                         lambda2 =  deglon[:]*np.pi/180
                         dsigma  = 2 * np. arcsin( np.sqrt( np.sin( 0.5*(phi1-phi2) )**2 + (1 - np.sin( 0.5*(phi1-phi2) )**2 - np.sin( 0.5*(phi1+phi2) )**2 )*np.sin( 0.5*(lambda1-lambda2) )**2 )  )
                         dh      = REarth*dsigma
                         gch     = gaspari_cohn(dh/loch) 
                         gcloc = gch * gcv
                  

                     loc=1 
                     for iss in range( len(m1) ):
                          # Compute the correlation.
                          #print('before')
                          crT=np.corrcoef(Tan_ens,prior[iss,:])[0,1]
                          crQ=np.corrcoef(Qan_ens,prior[iss,:])[0,1]
                          crU=np.corrcoef(Uan_ens,prior[iss,:])[0,1]
                          crV=np.corrcoef(Van_ens,prior[iss,:])[0,1]
                
                          #print(Tan_ens) 
                          #print(Qan_ens) 
                          #print(Uan_ens) 
                          #print(Van_ens) 
                          #print(prior[iss,:]) 
                          #print('after')

                          # Compute the 3D distance to apply the Gaspary and Cohn correction.
                          if loc_type=='GC':   
                             loc = gcloc[iss]


                          # compute the fsoi
                          if use_oi=="TRUE":
                             fsoi_oi[idx_o2p, kk, ii, jj] = fsoi_oi[idx_o2p, kk, ii, jj] - (obs[iss]-prior_mean[iss]) * (crT + crQ + crU + crV) * loc * omega_fac/sigma_o[iss]
                          else: 
                             fsoi[idx_o2p, kk, ii, jj] = fsoi[idx_o2p, kk, ii, jj] - (obs[iss]-prior_mean[iss])*(crT + crQ + crU + crV)*loc*prior_spread[iss]/(sigma_o[iss]**2)
                          
                          fsoi_mask[idx_o2p, kk, ii, jj] = 1 

                          ocount[idx_o2p]=ocount[idx_o2p]+1
                          # SERVE MASCHERA PER VEDERE SE CI SONO OBS IN UNA DETERMINATA POSIZIONE
                          #print('idx_o2p= ',idx_o2p)



                     idx_o2p=idx_o2p+1 # END o2p cycle



    





# Coordinate of the new coarser grid.
tmp=idlat[:,0];
co_lat = lat[tmp] 
tmp=idlon[0,:]
co_lon = lon[tmp]  

#print(idlat)
#print(idlon)





## Count the total number of observations used per type. This counting makes sense only if I consider a sub grid that, with the localization area,
## can cover the whole domain.
#ocount = np.zeros(len(obs2proc))
#maskcnt = 0
#print('\n counting the used observation per obs type ...')
#for db in listdb:
#    if maskdb[maskcnt] == 0:
#        continue
#    maskcnt += 1
#    print('\nworking with db: ', db)
#    con = sqlite3.connect(db)
#    
#    for io in range(len(obs2proc)):
#        dfo = pd.read_sql("select count(*), id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) \
#                           as description, dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
#                           where description in ('" + obs2proc[io] + "') and dart_qc=0 and member=1", con)
#        if len(dfo) > 0:
#            ocount[io] += dfo['count(*)'].values[0]
#
#    con.close()
        

print('\ncount obs used: ', ocount)




mask = np.isnan(fsoi_mask)
masked_fsoi = np.ma.masked_array(fsoi, mask)
fsoim= np.zeros(len(obs2proc))
fsoisd= np.zeros(len(obs2proc))
for io in range(len(obs2proc)):
    flattened  = masked_fsoi[io,:,:,:].flatten()
    mean = np.ma.mean(flattened)
    sd = np.ma.std(flattened)
    #print('flattened ', flattened )
    #print('mean ', mean )
    #print('sd ', sd )
    #print(type(mean))
    if isinstance(mean, np.ma.core.MaskedConstant):
       mean = mean.filled(0.0)
    if isinstance(sd, np.ma.core.MaskedConstant):
       sd = sd.filled(0.0)
    fsoim[io]  = mean
    fsoisd[io] = sd


print("\nmean per type:")
print(fsoim)
print("\nsd per type:")
print(fsoisd)



# Plotting
#------------------------------------------
#------------------------------------------
if plot_img=='TRUE':
   # Consider four different regions: Global
   # NH, SH, TR for the bar plot. 
   print('\nbar plot') 

   NH_fsoim= np.zeros(len(obs2proc))
   NH_fsoisd= np.zeros(len(obs2proc))
   SH_fsoim= np.zeros(len(obs2proc))
   SH_fsoisd= np.zeros(len(obs2proc))
   TR_fsoim= np.zeros(len(obs2proc))
   TR_fsoisd= np.zeros(len(obs2proc))

   tmp_idlat = np.where(clat>30)
   NH_fsoi = fsoi[:,:,tmp_idlat, :] 
   for io in range(len(obs2proc)):
       mean = np.ma.mean(NH_fsoi[io,:,:,:].flatten())
       sd = np.ma.std(NH_fsoi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       NH_fsoim[io]  = mean
       NH_fsoisd[io] = sd
   tmp_idlat = np.where(clat<-30) 
   SH_fsoi = fsoi[:,:,tmp_idlat, :] 
   for io in range(len(obs2proc)):
       mean = np.ma.mean(SH_fsoi[io,:,:,:].flatten())
       sd = np.ma.std(SH_fsoi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       SH_fsoim[io]  = mean
       SH_fsoisd[io] = sd
   tmp_idlat = np.where( (clat>=-30) & (clat<=30) ) 
   TR_fsoi = fsoi[:,:,tmp_idlat,:]
   for io in range(len(obs2proc)):
       mean = np.ma.mean(TR_fsoi[io,:,:,:].flatten())
       sd = np.ma.std(TR_fsoi[io,:,:,:].flatten())
       if isinstance(mean, np.ma.core.MaskedConstant):
          mean = mean.filled(0.0)
       if isinstance(sd, np.ma.core.MaskedConstant):
          sd = sd.filled(0.0)
       TR_fsoim[io]  = mean
       TR_fsoisd[io] = sd

 #  fsoi_plot_bar(fsoim,fsoisd, obs2proc, ocount, title='Global'+'\n Date: '+fdate , xlabel='$FSOI-J_o$ %', ylabel='', save_path=path2sv+'/bar_global.png', fs=16, dpi=100)
#   fsoi_plot_bar(NH_fsoim, NH_fsoisd, obs2proc, ocount, title='Northern Hemisphere'+'\n Date: '+fdate, xlabel='$FSOI-J_o$ %', ylabel='', save_path=path2sv+'/bar_nh.png', fs=16, dpi=100)
#   fsoi_plot_bar(SH_fsoim, SH_fsoisd, obs2proc, ocount, title='Southern Hemisphere'+'\n Date: '+fdate, xlabel='$FSOI-J_o$ %', ylabel='', save_path=path2sv+'/bar_sh.png', fs=16, dpi=100)
#   fsoi_plot_bar(TR_fsoim, TR_fsoisd, obs2proc, ocount,title='Tropics'+'\n Date: '+fdate, xlabel='', ylabel='$FSOI-J_o$ %', save_path=path2sv+'/bar_tr.png', fs=16, dpi=100)



   # Pie summary
   # Generates groups set from obs type in obs2proc
   print('\npie plot') 
   groups = set([obs.split('_')[0] for obs in obs2proc])
   labels = []
   if 'AIRCRAFT' in groups or 'ACARS' in groups:
     labels.append('ARC')
   if 'RADIOSONDE' in groups:
     labels.append('SND')
   if 'SAT' in groups:
     labels.append('AMV')
   if 'GPSRO' in groups:
     labels.append('GPSRO')
   if 'EOS' in groups or 'NOAA' in groups or 'METOP' in groups :
     labels.append('AMSU-A')
 
   sizes = [0] * len(labels)
   fsoigr = [0] * len(labels)

   for obs in obs2proc:
       index = obs2proc.index(obs)
       if 'AIRCRAFT' in obs or 'ACARS' in obs:
           il=labels.index('ARC')
       elif 'RADIOSONDE' in obs:
           il=labels.index('SND')
       elif 'SAT' in obs:
           il=labels.index('AMV')
       elif 'GPSRO' in obs:
           il=labels.index('GPSRO')
       elif 'EOS' in obs or 'NOAA' in obs or 'METOP' in obs:
           il=labels.index('AMSU-A')
           
       #print('il=',il)
       sizes[il]=sizes[il]+ocount[index]
       fsoigr[il]=fsoigr[il]+np.abs(fsoim[index])


   #print('sizes=',sizes)
   total = sum(sizes)
   sizes = [size * 100 / total if size != 0 else 0 for size in sizes] 
   totalf = sum(fsoigr)
   fsoigr = [fgr * 100 / totalf if fgr != 0 else 0 for fgr in fsoigr] 
    
   
   print('labels=',labels)
   print('sizes=',sizes)
   print('fsoigr=',fsoigr)
#   create_pie_chart(labels, sizes,  title='SPREADS: Obs used for the FSOI-Jo'+'\n Date: '+fdate, dpi=100, save_path=path2sv+'/pie_global_nobs.png')
#   create_pie_chart(labels, fsoigr,  title='SPREADS: Global FSOI-Jo Summary'+'\n Date: '+fdate, dpi=100, save_path=path2sv+'/pie_global_fsoi.png')




   print('\nmaps ') 
   # For the maps consider three reference levels
   # 850 hPa, 500h Pa, 200 hPa and the vertical average. 

#   fsoi_map = fsoi.mean(axis=(0,1))
#   fsoi_plot_map(fsoi_map, co_lon, co_lat, title='FSOI-Jo, All Obs., Vertical Integration.'+'\n Date: '+fdate, clabel='$FSOI-J_{o}$', xlabel='', ylabel='', fs=16, dpi=100, save_path=path2sv+'/all_obs_vint_map.png')
   idlev = find_closest_index(lev, 150)
   fsoi_map = fsoi[:,idlev,:,:].mean(axis=0)
   
   #DBG
   np.savez('utest.npz',fsoi=fsoi,fsoi_map=fsoi_map, lat=co_lat, lon=co_lon, labels=labels, fsoigr=fsoigr, sizes=sizes, fsoim=fsoim, fsoisd=fsoisd, obs2proc=obs2proc, ocount=ocount)
   
#   fsoi_plot_map(fsoi_map, co_lon, co_lat, title='FSOI-Jo, All Obs., Model Level: '+ str( round(lev[idlev],2) )  +'\n Date: '+fdate, clabel='$FSOI-J_{o}$', xlabel='', ylabel='', fs=16, dpi=100, save_path=path2sv+'/all_obs_150_map.png') 


# Profiles?? 



# Data saving session.
#------------------------------------------
#------------------------------------------
print('\n Save data . . .')

with Dataset(path2sv+'/data.nc', 'w', format='NETCDF4_CLASSIC') as ds:
 
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
    
    ds.createDimension('c_lat',len(co_lat))
    co_lat_var = ds.createVariable('c_lat', 'f8', ('c_lat',))
    co_lat_var.units = 'degree' 
    co_lat_var.long_name = 'latitude coordinate of the coarser diag grid' 
    co_lat_var[:] = co_lat   

    ds.createDimension('c_lon',len(co_lon))
    co_lon_var = ds.createVariable('c_lon', 'f8', ('c_lon',))
    co_lon_var.units = 'degree' 
    co_lon_var.long_name = 'longitude coordinate of the coarser diag grid' 
    co_lon_var[:] = co_lon   
    


    # Add 2D variables  
    #------------------------------------------
    idlat_var = ds.createVariable('idlat', 'f8', ('c_lat', 'c_lon'))
    idlat_var.units = ''
    idlat_var.long_name = 'Matrix indices for the mapping between the model and the coarse grid. It contains the lat indices correspondednt to positions in model grid.'
    idlat_var[:] = idlat

    idlon_var = ds.createVariable('idlon', 'f8', ('c_lat', 'c_lon'))
    idlon_var.units = ''
    idlon_var.long_name = 'Matrix indices for the mapping between the model and the coarse grid. It contains the lat indices correspondednt to positions in model grid.'
    idlon_var[:] = idlon

    # Add 4D variables  
    #------------------------------------------
    ds.createDimension('num_obs_types', len(obs2proc))
    fsoi_var = ds.createVariable('fsoi', 'f8', ('num_obs_types', 'model_lev', 'c_lat', 'c_lon'))
    fsoi_var.units = ''
    fsoi_var.long_name = 'FSOI-Jo. First dimension is the list of obs type: ' + str(obs2proc)
    fsoi_var[:] = fsoi

    if use_oi=='TRUE':
       oi_var = ds.createVariable('fsoi_oi', 'f8', ('num_obs_types', 'model_lev', 'c_lat', 'c_lon'))
       oi_var.units = ''
       oi_var.long_name = 'FSOI-Jo_OI approximation. First dimension is the list of obs type: ' + str(obs2proc)
       oi_var[:] = fsoi_oi
    
       oi_var = ds.createVariable('oi', 'f8', ('num_obs_types', 'model_lev', 'c_lat', 'c_lon'))
       oi_var.units = ''
       oi_var.long_name = 'OI First dimension is the list of obs type: ' + str(obs2proc)
       oi_var[:] = oi
    
    ds.setncattr('title', 'Simplified FSOI for ensemble filtering: forecast date: ' + fdate)
    ds.setncattr('author', 'G. C.')


# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')
