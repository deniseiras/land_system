# FSOI_Jo diagnostic computation for ensemble systems adaptation to 
# check the functional relation between simulated obs and analysis.
#
#
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
NGLAT = 40
NGLON = 40

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
##             'VADWND_U_WIND_COMPONENT',\
##             'VADWND_V_WIND_COMPONENT',\
#             'EOS_2_AMSUA_TB', \
#             'NOAA_15_AMSUA_TB', \
#             'NOAA_16_AMSUA_TB', \
#             'NOAA_17_AMSUA_TB', \
#             'NOAA_18_AMSUA_TB', \
#             'NOAA_19_AMSUA_TB', \
#             'METOP_1_AMSUA_TB', \
#             'METOP_2_AMSUA_TB' \
#            ]

#AMSUA
obs2proc  = ['EOS_2_AMSUA_TB', \
             'NOAA_15_AMSUA_TB', \
             'NOAA_16_AMSUA_TB', \
             'NOAA_17_AMSUA_TB', \
             'NOAA_18_AMSUA_TB', \
             'NOAA_19_AMSUA_TB', \
             'METOP_1_AMSUA_TB', \
             'METOP_2_AMSUA_TB' \
            ]


#ARC
#obs2proc  = ['AIRCRAFT_U_WIND_COMPONENT', \
#             'AIRCRAFT_V_WIND_COMPONENT', \
#             'AIRCRAFT_TEMPERATURE', \
#             'ACARS_U_WIND_COMPONENT', \
#             'ACARS_V_WIND_COMPONENT', \
#             'ACARS_TEMPERATURE' \
#             ]

name_gr_scatter='scatter_amsua'

# Number of ensemble members.
nens = 2

# Type of localization: 'GC' for Gaspari-Cohn, 'Box' for Box.
loc_type = 'Box'

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


# sub sample obs around a lat lon lev
NSAMPLE=5

# Plot samples img?
plot_img = 'TRUE'

# Chose level of output. 
# DEBUG = 1 only cells indication, DEBUG = 2 add vertical information, DEBUG = 3 also obs retrieve info
# DEBUG = 4 print also the pandas query dataframe
DEBUG = 1


# The computation is really hard and we need to speed it up choosing only same particular layer of interest
# level 83 is too much. 
#AMSUA
reflevs=(150,90,50,25,10,5,2.5)
#reflevs=(500,)
#reflevs=(850,)

#AMV
#reflevs=(500,200)

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


print(' tmp coarse grid ')
print(' clon: ',clon)
print(' clat: ',clat)
print(' clon: ',clon)

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





# Index mapping.
idlat = np.zeros([NGLAT,NGLON], dtype=int)
idlon = np.zeros([NGLAT,NGLON], dtype=int)
# Coarse grid points.
co_lat = np.zeros(NGLAT)
co_lon = np.zeros(NGLON)


scatt_anT_amsua=np.array([])
scatt_anQ_amsua=np.array([])
scatt_anU_amsua=np.array([])
scatt_anV_amsua=np.array([])
scatt_pr_amsua=np.array([])

scatt_anT_amsua_ch8=np.array([])
scatt_anQ_amsua_ch8=np.array([])
scatt_anU_amsua_ch8=np.array([])
scatt_anV_amsua_ch8=np.array([])
scatt_anT_amsua_ch9=np.array([])
scatt_anQ_amsua_ch9=np.array([])
scatt_anU_amsua_ch9=np.array([])
scatt_anV_amsua_ch9=np.array([])
scatt_anT_amsua_ch10=np.array([])
scatt_anQ_amsua_ch10=np.array([])
scatt_anU_amsua_ch10=np.array([])
scatt_anV_amsua_ch10=np.array([])
scatt_anT_amsua_ch11=np.array([])
scatt_anQ_amsua_ch11=np.array([])
scatt_anU_amsua_ch11=np.array([])
scatt_anV_amsua_ch11=np.array([])
scatt_anT_amsua_ch12=np.array([])
scatt_anQ_amsua_ch12=np.array([])
scatt_anU_amsua_ch12=np.array([])
scatt_anV_amsua_ch12=np.array([])
scatt_anT_amsua_ch13=np.array([])
scatt_anQ_amsua_ch13=np.array([])
scatt_anU_amsua_ch13=np.array([])
scatt_anV_amsua_ch13=np.array([])
scatt_anT_amsua_ch14=np.array([])
scatt_anQ_amsua_ch14=np.array([])
scatt_anU_amsua_ch14=np.array([])
scatt_anV_amsua_ch14=np.array([])
scatt_pr_amsua_ch8=np.array([])
scatt_pr_amsua_ch9=np.array([])
scatt_pr_amsua_ch10=np.array([])
scatt_pr_amsua_ch11=np.array([])
scatt_pr_amsua_ch12=np.array([])
scatt_pr_amsua_ch13=np.array([])
scatt_pr_amsua_ch14=np.array([])

scatt_anT_sndw=np.array([])
scatt_anQ_sndw=np.array([])
scatt_anU_sndw=np.array([]) 
scatt_anV_sndw=np.array([])
scatt_pr_sndw=np.array([])

scatt_anT_sndt=np.array([]) 
scatt_anQ_sndt=np.array([])
scatt_anU_sndt=np.array([])
scatt_anV_sndt=np.array([])
scatt_pr_sndt=np.array([])

scatt_anT_satw=np.array([])  
scatt_anQ_satw=np.array([])   
scatt_anU_satw=np.array([])   
scatt_anV_satw=np.array([])   
scatt_pr_satw=np.array([])

scatt_anT_arcw=np.array([])   
scatt_anQ_arcw=np.array([])   
scatt_anU_arcw=np.array([])   
scatt_anV_arcw=np.array([])   
scatt_pr_arcw=np.array([])

scatt_anT_arct=np.array([])   
scatt_anQ_arct=np.array([])  
scatt_anU_arct=np.array([])   
scatt_anV_arct=np.array([])   
scatt_pr_arct=np.array([])

scatt_anT_gpsro=np.array([])
scatt_anQ_gpsro=np.array([]) 
scatt_anU_gpsro=np.array([]) 
scatt_anV_gpsro=np.array([]) 
scatt_pr_gpsro=np.array([])

scatt_anT_wdp=np.array([])     
scatt_anQ_wdp=np.array([])     
scatt_anU_wdp=np.array([])     
scatt_anV_wdp=np.array([])     
scatt_pr_wdp=np.array([])




# Main computation.
#------------------------------------------
# Load all the possible obs will be used in one task in order to open dbs only once.
# We can refine later in a parcisular sub-cell.
lat_deg2km = 110.574 # Km/degree
dlato = 2 * loch/lat_deg2km
ilat_u = find_closest_index(lat, clat[0])
ilat_d = find_closest_index(lat, clat[-1])
latu = lat[ilat_u] + dlato
latd = lat[ilat_d] - dlato
if latu > 90:
    latu = 90
if latd < -90:
    latd = -90

deg2rad = math.pi/180
lon_deg2km = np.min( [111.320*np.cos(deg2rad*lat[ilat_u]), 111.320*np.cos(deg2rad*lat[ilat_d])] ) # Km/degree
dlono = 2 * loch/lon_deg2km
ilon_l = find_closest_index(lon, clon[0])
ilon_r = find_closest_index(lon, clon[-1])
lonl = lon[ilon_l] - dlono
lonr = lon[ilon_r] + dlono
if lonl < 0:
    lonl = 0
if lonr > 360:
    lonr = 360

if DEBUG >= 1:
    print(' obs.  domain: lat in [',latu,'    ',latd,'] and lon in [',lonl,'    ',lonr,']',  flush=True)

# Check all the possible dbs containing the observations needed.
dfos = pd.DataFrame()
for db, maskcc in zip(listdb, maskdb):
    # print('db:', db)
    # print('maskdb:', mask)
    if maskcc == 0:
        continue

    if DEBUG >= 1:
        print(" working with db: ", db, flush=True)

    # Retrieve the vertical column of observations for the subdomain considered. 
    con=sqlite3.connect(db)
    df_temp = pd.read_sql("select entryno,id,obsvalue, obs_error, prior_mean, prior_spread, kind, prior, dart_qc, member, deglat, deglon,\
                       levelht, (select distinct description from toc where kind=body.kind) \
                       as description from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and \
                       entryno=body_entryno where deglat>"+ str(latd) + " and deglat<" + str(latu) + " and deglon>"\
                      + str(lonl) + " and deglon<" + str(lonr) +" and dart_qc=0", con)
    con.close()

    # If there are not observation skip.
    if len(df_temp['obsvalue'].tolist())<=0:
       print(" No obs in this cell from this db", flush=True)
       continue

    # Inside d4o we have Pa not hPa. 
    if DEBUG >= 22:
        print(" Convert levelht in hPa. ", flush=True)
    df_temp['levelht'] = df_temp['levelht']/100
    dfos = pd.concat([dfos, df_temp], ignore_index=True)

    if DEBUG >= 4:
        print(" Pandas Obs: \n", dfos, flush=True)
                                                                          




# Main computation.
#------------------------------------------
# Loop through the cells
ncel=1
for jj in range( NGLON ):
       
    # Define the closest lon index of the model grid to the center of the cell.
    ilon = find_closest_index(lon, clon[jj]) 
    idlon[:,jj] = int(ilon)       
                          
 
    for ii in range( NGLAT ):
      
        if DEBUG>=1: 
            print("\n\n Process cell ",ncel," out of ",NGLON*NGLAT, flush=True)
        
        ncel=ncel+1
          
        # Define the closest lat index of the model grid to the center of the cell.
        ilat = find_closest_index(lat, clat[ii])
        idlat[ii,:] = int(ilat)       
    

 
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
        #dlato = 2 * loch/lat_deg2km  
        dlato =  loch/lat_deg2km  
        latu = lat[idlat[ii,jj]] + dlato
        latd = lat[idlat[ii,jj]] - dlato
        if latu > 90:
           latu = 90
        if latd < -90:
           latd = -90
 
        deg2rad = math.pi/180
        lon_deg2km = 111.320*np.cos(deg2rad*lat[idlat[ii,jj]]) # Km/degree
        #dlono = 2 * loch/lon_deg2km
        dlono =  loch/lon_deg2km
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


        dfo = dfos.query("deglat > @latd and deglat < @latu and deglon > @lonl and deglon < @lonr ")
        if len(dfo['obsvalue'].tolist())<=0:
           if DEBUG>=2:
              print(' No obs in this cell.')
              print(qstr)
           continue
        
        # Loop through the column but skip above a certain threshold.
        for kk in range( len(lev) ):
            # If level is above 0.1 hPa skip the computation. 
            clev = lev[kk]
            if clev < vthreshold: 
               continue

            if DEBUG>=2:
               print('\n Processing lev: ',clev,' level ',kk,'out of ', len(lev))
                 
            # Compute vertical localization box for the obs retrieval
            ulev = clev * np.exp(-vloch)
            dlev = clev * np.exp(vloch)
            if ulev < vthreshold:
               ulev = vthreshold
            if dlev > P0:
               dlev = P0 
    
            #do_ens_total = dfos.query("deglat > @latd and deglat < @latu and deglon > @lonl and deglon < @lonr and dart_qc == 0 and levelht > @ulev and levelht < @dlev")
            do_ens_total = dfo.query("levelht > @ulev and levelht < @dlev")
          

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
                if DEBUG>=3: 
                   print('Processing observation: ',o2p)
                # Find different obs of this type.
                qstr = "description=="+"'"+o2p +"'"
                #print(qstr)
                do_ens_type = do_ens_total.query(qstr)
                if len(do_ens_type['obsvalue'].tolist())<=0:
                    if DEBUG>=3:
                        print(' No obs of this type '+ o2p +' in this interval.') 
                
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

                #print('levelht=',levelht[:])

         
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
                #for iss in range( len(m1) ):
                if NSAMPLE<len(m1):
                   indices = np.random.choice(len(m1), size=NSAMPLE, replace=False)
                else:
                   indices = np.arange(len(m1))

                for iss in indices:
              #       # Compute the correlation.
              #       #print('before')
              #       crT=np.corrcoef(Tan_ens,prior[iss,:])[0,1]
              #       crQ=np.corrcoef(Qan_ens,prior[iss,:])[0,1]
              #       crU=np.corrcoef(Uan_ens,prior[iss,:])[0,1]
              #       crV=np.corrcoef(Van_ens,prior[iss,:])[0,1]
             
              #       #print(Tan_ens) 
              #       #print(Qan_ens) 
              #       #print(Uan_ens) 
              #       #print(Van_ens) 
              #       #print(prior[iss,:]) 
              #       #print('after')

              #       # Compute the 3D distance to apply the Gaspary and Cohn correction.
              #       if loc_type=='GC':   
              #          loc = gcloc[iss]
                       
#                       check=0 
#                       for element in prior[iss,:]:
#                           if np.any(element == 0):
#                              check=1
                      
                       print(prior[iss,:])
                      
#                       if check==1:
#                           continue


                       if o2p in ['EOS_2_AMSUA_TB', 'NOAA_15_AMSUA_TB', 'NOAA_16_AMSUA_TB', 'NOAA_17_AMSUA_TB', 'NOAA_18_AMSUA_TB', 'NOAA_19_AMSUA_TB', 'METOP_1_AMSUA_TB', 'METOP_2_AMSUA_TB']:
                           scatt_anT_amsua = np.append(scatt_anT_amsua, Tan_ens)  
                           scatt_anQ_amsua = np.append(scatt_anQ_amsua, Qan_ens)  
                           scatt_anU_amsua = np.append(scatt_anU_amsua, Uan_ens)  
                           scatt_anV_amsua = np.append(scatt_anV_amsua, Van_ens)  
                           scatt_pr_amsua = np.append(scatt_pr_amsua, prior[iss,:])
                           if levelht[iss]==150:
                               scatt_pr_amsua_ch8 = np.append(scatt_pr_amsua_ch8, prior[iss,:])
                               scatt_anT_amsua_ch8 = np.append(scatt_anT_amsua_ch8, Tan_ens)  
                               scatt_anQ_amsua_ch8 = np.append(scatt_anQ_amsua_ch8, Qan_ens)  
                               scatt_anU_amsua_ch8 = np.append(scatt_anU_amsua_ch8, Uan_ens)  
                               scatt_anV_amsua_ch8 = np.append(scatt_anV_amsua_ch8, Van_ens)  
                           elif levelht[iss]==90:
                               scatt_pr_amsua_ch9 = np.append(scatt_pr_amsua_ch9, prior[iss,:])
                               scatt_anT_amsua_ch9 = np.append(scatt_anT_amsua_ch9, Tan_ens)  
                               scatt_anQ_amsua_ch9 = np.append(scatt_anQ_amsua_ch9, Qan_ens)  
                               scatt_anU_amsua_ch9 = np.append(scatt_anU_amsua_ch9, Uan_ens)  
                               scatt_anV_amsua_ch9 = np.append(scatt_anV_amsua_ch9, Van_ens)  
                           elif levelht[iss]==50:
                               scatt_pr_amsua_ch10 = np.append(scatt_pr_amsua_ch10, prior[iss,:])
                               scatt_anT_amsua_ch10 = np.append(scatt_anT_amsua_ch10, Tan_ens)  
                               scatt_anQ_amsua_ch10 = np.append(scatt_anQ_amsua_ch10, Qan_ens)  
                               scatt_anU_amsua_ch10 = np.append(scatt_anU_amsua_ch10, Uan_ens)  
                               scatt_anV_amsua_ch10 = np.append(scatt_anV_amsua_ch10, Van_ens)  
                           elif levelht[iss]==25:
                               scatt_pr_amsua_ch11 = np.append(scatt_pr_amsua_ch11, prior[iss,:])
                               scatt_anT_amsua_ch11 = np.append(scatt_anT_amsua_ch11, Tan_ens)  
                               scatt_anQ_amsua_ch11 = np.append(scatt_anQ_amsua_ch11, Qan_ens)  
                               scatt_anU_amsua_ch11 = np.append(scatt_anU_amsua_ch11, Uan_ens)  
                               scatt_anV_amsua_ch11 = np.append(scatt_anV_amsua_ch11, Van_ens)  
                           elif levelht[iss]==10:
                               scatt_pr_amsua_ch12 = np.append(scatt_pr_amsua_ch12, prior[iss,:])
                               scatt_anT_amsua_ch12 = np.append(scatt_anT_amsua_ch12, Tan_ens)  
                               scatt_anQ_amsua_ch12 = np.append(scatt_anQ_amsua_ch12, Qan_ens)  
                               scatt_anU_amsua_ch12 = np.append(scatt_anU_amsua_ch12, Uan_ens)  
                               scatt_anV_amsua_ch12 = np.append(scatt_anV_amsua_ch12, Van_ens)  
                           elif levelht[iss]==5:
                               scatt_pr_amsua_ch13 = np.append(scatt_pr_amsua_ch13, prior[iss,:])
                               scatt_anT_amsua_ch13 = np.append(scatt_anT_amsua_ch13, Tan_ens)  
                               scatt_anQ_amsua_ch13 = np.append(scatt_anQ_amsua_ch13, Qan_ens)  
                               scatt_anU_amsua_ch13 = np.append(scatt_anU_amsua_ch13, Uan_ens)  
                               scatt_anV_amsua_ch13 = np.append(scatt_anV_amsua_ch13, Van_ens)  
                           elif levelht[iss]==2.5:
                               scatt_pr_amsua_ch14 = np.append(scatt_pr_amsua_ch14, prior[iss,:])
                               scatt_anT_amsua_ch14 = np.append(scatt_anT_amsua_ch14, Tan_ens)  
                               scatt_anQ_amsua_ch14 = np.append(scatt_anQ_amsua_ch14, Qan_ens)  
                               scatt_anU_amsua_ch14 = np.append(scatt_anU_amsua_ch14, Uan_ens)  
                               scatt_anV_amsua_ch14 = np.append(scatt_anV_amsua_ch14, Van_ens)  
                       elif o2p in ['RADIOSONDE_U_WIND_COMPONENT','RADIOSONDE_V_WIND_COMPONENT']:
                           #print('appending sndw prior:', prior[iss,:])
                           #print('appending sndw prior:', Tan_ens)
                           scatt_anT_sndw = np.append(scatt_anT_sndw, Tan_ens)  
                           scatt_anQ_sndw = np.append(scatt_anQ_sndw, Qan_ens)  
                           scatt_anU_sndw = np.append(scatt_anU_sndw, Uan_ens)  
                           scatt_anV_sndw = np.append(scatt_anV_sndw, Van_ens)  
                           scatt_pr_sndw = np.append(scatt_pr_sndw, prior[iss,:])
                       elif o2p in ['RADIOSONDE_TEMPERATURE']:
                           #print('appending sndt prior:', prior[iss,:])
                           #print('appending Tan_ens prior:', Tan_ens)
                           scatt_anT_sndt = np.append(scatt_anT_sndt, Tan_ens)  
                           scatt_anQ_sndt = np.append(scatt_anQ_sndt, Qan_ens)  
                           scatt_anU_sndt = np.append(scatt_anU_sndt, Uan_ens)  
                           scatt_anV_sndt = np.append(scatt_anV_sndt, Van_ens)  
                           scatt_pr_sndt = np.append(scatt_pr_sndt, prior[iss,:])
                       elif o2p in ['SAT_U_WIND_COMPONENT', 'SAT_V_WIND_COMPONENT']:
                           #print('appending satw prior:', prior[iss,:])
                           scatt_anT_satw = np.append(scatt_anT_satw, Tan_ens)  
                           scatt_anQ_satw = np.append(scatt_anQ_satw, Qan_ens)  
                           scatt_anU_satw = np.append(scatt_anU_satw, Uan_ens)  
                           scatt_anV_satw = np.append(scatt_anV_satw, Van_ens)  
                           scatt_pr_satw = np.append(scatt_pr_satw, prior[iss,:])
                       elif o2p in ['AIRCRAFT_U_WIND_COMPONENT','AIRCRAFT_V_WIND_COMPONENT','ACARS_U_WIND_COMPONENT','ACARS_V_WIND_COMPONENT']:
                           #print('appending arcw prior:', prior[iss,:])
                           scatt_anT_arcw = np.append(scatt_anT_arcw, Tan_ens)  
                           scatt_anQ_arcw = np.append(scatt_anQ_arcw, Qan_ens)  
                           scatt_anU_arcw = np.append(scatt_anU_arcw, Uan_ens)  
                           scatt_anV_arcw = np.append(scatt_anV_arcw, Van_ens)  
                           scatt_pr_arcw = np.append(scatt_pr_arcw, prior[iss,:])
                       elif o2p in ['AIRCRAFT_TEMPERATURE','ACARS_TEMPERATURE']:
                           #print('appending arct prior:', prior[iss,:])
                           scatt_anT_arct = np.append(scatt_anT_arct, Tan_ens)  
                           scatt_anQ_arct = np.append(scatt_anQ_arct, Qan_ens)  
                           scatt_anU_arct = np.append(scatt_anU_arct, Uan_ens)  
                           scatt_anV_arct = np.append(scatt_anV_arct, Van_ens)  
                           scatt_pr_arct = np.append(scatt_pr_arct, prior[iss,:])
                       elif o2p in ['GPSRO_REFRACTIVITY']:
                           #print('appending gpsro prior:', prior[iss,:])
                           scatt_anT_gpsro = np.append(scatt_anT_gpsro, Tan_ens)  
                           scatt_anQ_gpsro = np.append(scatt_anQ_gpsro, Qan_ens)  
                           scatt_anU_gpsro = np.append(scatt_anU_gpsro, Uan_ens)  
                           scatt_anV_gpsro = np.append(scatt_anV_gpsro, Van_ens)  
                           scatt_pr_gpsro = np.append(scatt_pr_gpsro, prior[iss,:])
                       elif o2p in ['VADWND_U_WIND_COMPONENT','VADWND_V_WIND_COMPONENT']:
                           #print('appending wdp prior:', prior[iss,:])
                           scatt_anT_wdp = np.append(scatt_anT_wdp, Tan_ens)  
                           scatt_anQ_wdp = np.append(scatt_anQ_wdp, Qan_ens)  
                           scatt_anU_wdp = np.append(scatt_anU_wdp, Uan_ens)  
                           scatt_anV_wdp = np.append(scatt_anV_wdp, Van_ens)  
                           scatt_pr_wdp = np.append(scatt_pr_wdp, prior[iss,:])
                       else:
                           print("No type in the list:", o2p)
             



                idx_o2p=idx_o2p+1 # END o2p cycle



# Coordinate of the new coarser grid.
tmp=idlat[:,0];
co_lat = lat[tmp] 
tmp=idlon[0,:]
co_lon = lon[tmp]  

print(' coarse grid ')
print(' co_lon: ',co_lon)
print(' co_lat: ',co_lat)


print('\n Save data . . .')

    
np.savez(path2sv+"/"+name_gr_scatter+'.npz', scatt_anT_amsua=scatt_anT_amsua, scatt_anQ_amsua=scatt_anQ_amsua, scatt_anU_amsua=scatt_anU_amsua, scatt_anV_amsua=scatt_anV_amsua, scatt_pr_amsua=scatt_pr_amsua,
                                 scatt_anT_amsua_ch8=scatt_anT_amsua_ch8, scatt_anQ_amsua_ch8=scatt_anQ_amsua_ch8, scatt_anU_amsua_ch8=scatt_anU_amsua_ch8, 
                                 scatt_anV_amsua_ch8=scatt_anV_amsua_ch8, scatt_pr_amsua_ch8=scatt_pr_amsua_ch8,
                                 scatt_anT_amsua_ch9=scatt_anT_amsua_ch9, scatt_anQ_amsua_ch9=scatt_anQ_amsua_ch9, scatt_anU_amsua_ch9=scatt_anU_amsua_ch9, 
                                 scatt_anV_amsua_ch9=scatt_anV_amsua_ch9, scatt_pr_amsua_ch9=scatt_pr_amsua_ch9,
                                 scatt_anT_amsua_ch10=scatt_anT_amsua_ch10, scatt_anQ_amsua_ch10=scatt_anQ_amsua_ch10, scatt_anU_amsua_ch10=scatt_anU_amsua_ch10, 
                                 scatt_anV_amsua_ch10=scatt_anV_amsua_ch10, scatt_pr_amsua_ch10=scatt_pr_amsua_ch10,
                                 scatt_anT_amsua_ch11=scatt_anT_amsua_ch11, scatt_anQ_amsua_ch11=scatt_anQ_amsua_ch11, scatt_anU_amsua_ch11=scatt_anU_amsua_ch11, 
                                 scatt_anV_amsua_ch11=scatt_anV_amsua_ch11, scatt_pr_amsua_ch11=scatt_pr_amsua_ch11,
                                 scatt_anT_amsua_ch12=scatt_anT_amsua_ch12, scatt_anQ_amsua_ch12=scatt_anQ_amsua_ch12, scatt_anU_amsua_ch12=scatt_anU_amsua_ch12, 
                                 scatt_anV_amsua_ch12=scatt_anV_amsua_ch12, scatt_pr_amsua_ch12=scatt_pr_amsua_ch12,
                                 scatt_anT_amsua_ch13=scatt_anT_amsua_ch13, scatt_anQ_amsua_ch13=scatt_anQ_amsua_ch13, scatt_anU_amsua_ch13=scatt_anU_amsua_ch13, 
                                 scatt_anV_amsua_ch13=scatt_anV_amsua_ch13, scatt_pr_amsua_ch13=scatt_pr_amsua_ch13,
                                 scatt_anT_amsua_ch14=scatt_anT_amsua_ch14, scatt_anQ_amsua_ch14=scatt_anQ_amsua_ch14, scatt_anU_amsua_ch14=scatt_anU_amsua_ch14, 
                                 scatt_anV_amsua_ch14=scatt_anV_amsua_ch14, scatt_pr_amsua_ch14=scatt_pr_amsua_ch14,
                                 scatt_anT_sndw=scatt_anT_sndw,   scatt_anQ_sndw=scatt_anQ_sndw,   scatt_anU_sndw=scatt_anU_sndw,   scatt_anV_sndw=scatt_anV_sndw,   scatt_pr_sndw=scatt_pr_sndw,
                                 scatt_anT_sndt=scatt_anT_sndt,   scatt_anQ_sndt=scatt_anQ_sndt,   scatt_anU_sndt=scatt_anU_sndt,   scatt_anV_sndt=scatt_anV_sndt,   scatt_pr_sndt=scatt_pr_sndt,
                                 scatt_anT_satw=scatt_anT_satw,   scatt_anQ_satw=scatt_anQ_satw,   scatt_anU_satw=scatt_anU_satw,   scatt_anV_satw=scatt_anV_satw,   scatt_pr_satw=scatt_pr_satw,
                                 scatt_anT_arcw=scatt_anT_arcw,   scatt_anQ_arcw=scatt_anQ_arcw,   scatt_anU_arcw=scatt_anU_arcw,   scatt_anV_arcw=scatt_anV_arcw,   scatt_pr_arcw=scatt_pr_arcw,
                                 scatt_anT_arct=scatt_anT_arct,   scatt_anQ_arct=scatt_anQ_arct,   scatt_anU_arct=scatt_anU_arct,   scatt_anV_arct=scatt_anV_arct,   scatt_pr_arct=scatt_pr_arct,
                                 scatt_anT_gpsro=scatt_anT_gpsro, scatt_anQ_gpsro=scatt_anQ_gpsro, scatt_anU_gpsro=scatt_anU_gpsro, scatt_anV_gpsro=scatt_anV_gpsro, scatt_pr_gpsro=scatt_pr_gpsro,
                                 scatt_anT_wdp=scatt_anT_wdp,     scatt_anQ_wdp=scatt_anQ_wdp,     scatt_anU_wdp=scatt_anU_wdp,     scatt_anV_wdp=scatt_anV_wdp,     scatt_pr_wdp=scatt_pr_wdp, lev=lev, obs2proc=obs2proc)










# Plotting
#------------------------------------------
#------------------------------------------
#if plot_img=='TRUE':

# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')
