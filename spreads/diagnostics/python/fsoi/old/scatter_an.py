# FSOI_Jo diagnostic computation for ensemble systems adaptation to 
# check the functional relation between simulated obs and analysis.
# It processes one dir.
#
# Skeleton for single cycle! Need to be extended.
# @author: Giovanni Conti 
# @date: 19 July 2023


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
import random
from scipy.stats import t

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
#             'VADWND_U_WIND_COMPONENT',\
#             'VADWND_V_WIND_COMPONENT',\
             'EOS_2_AMSUA_TB', \
             'NOAA_15_AMSUA_TB', \
             'NOAA_16_AMSUA_TB', \
             'NOAA_17_AMSUA_TB', \
             'NOAA_18_AMSUA_TB', \
             'NOAA_19_AMSUA_TB', \
             'METOP_1_AMSUA_TB', \
             'METOP_2_AMSUA_TB' \
            ]

name_gr_scatter='scatt_an'

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
P0 = 1013.25

# Where to save the output, plot and data.
path2sv = path2db + '/diag-' + fdate

# sample numerosity 
nsample = 5

# t stundent confidence
confidence_level = 0.95


# Plot samples img?
plot_img = 'TRUE'

# Chose level of output. 
# DEBUG = 1 only cells indication, DEBUG = 2 add vertical information, DEBUG = 3 also obs retrieve info
# DEBUG = 4 print also the pandas query dataframe
DEBUG = 1


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
print(' Analysis date: ', adate)
print(' Forecast date: ', fdate)
print(' Path archive: ', patharc)
print(' Path analysis: ', path2an)
print(' Path forecast: ', path2db)
print(' Path to save: ', path2sv)
print(' Ensemble size: ', nens)
print(' Sample size: ', nsample)
print(' Observation to process: ', obs2proc)




#---------------------------------------------
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

print('\n Start the computation...', flush=True)

# Calculate the critical t-value for the given confidence level and degrees of freedom
dof = nens - 2
critical_t_value = t.ppf(confidence_level, dof)

# Read model grid informations.
aname = path2an + '/' + ename + '_f_0001-' + adate + '.cam.h0.' + adate + '.nc'
dset  = Dataset(aname, mode='r')
lon   = dset.variables['lon'][:]
lat   = dset.variables['lat'][:]
lev   = dset.variables['lev'][:]
dset.close()

print('\n Original full res  grid ', flush=True)
print(' lat: ', lat, flush=True)
print(' lon: ', lon, flush=True)
print(' lev: ', lev, flush=True)

lon_size = lon.size
lat_size = lat.size
lev_size = lev.size

print('\n lon_size: ', lon_size)
print(' lat_size: ', lat_size)
print(' lev_size: ', lev_size)

lower_threshold = 1
upper_threshold = 160
valid_indices = np.where((lev > lower_threshold) & (lev < upper_threshold))[0]

# List the dbs.
listdb=[]

for file in os.listdir(path2db):
    if file.endswith(".db") and "catalog" not in file:
       listdb.append(os.path.join(path2db, file))
listdb.sort()
print('\n dbs list in dir: ', listdb)


print('\n')
# For each obs type:
cnt_obs=0
for obs in obs2proc:
    print('\n processing obs type: ', obs)
   
    # For a particular type of obs we can have more than one db. Chose one randomly.
    # Choose one particular db"
    if 'AMSUA' in obs:
        selected_string = [file for file in listdb if "AMSU." in file]
    elif 'SAT' in obs:
        selected_string = [file for file in listdb if "AMV." in file]
    elif 'AIRCRAFT' in obs or 'ACARS' in obs:
        selected_string = [file for file in listdb if "ARC." in file]
    elif 'RADIOSONDE' in obs:
        selected_string = [file for file in listdb if "SND." in file]
    elif 'GPSRO' in obs:
        selected_string = [file for file in listdb if "GPSRO." in file]
    elif 'VADWND' in obs:
        selected_string = [file for file in listdb if "WDP." in file]
    else:
       print(' no obs of this kind in dbs')
       cnt_obs = cnt_obs+1
       continue


    random_selected_db = random.choice(selected_string)
    if DEBUG>=2:
        print(" Selected db:", random_selected_db)



    # Extract nsample data from the db.
    # Sqlite query.
    con = sqlite3.connect(random_selected_db)
    df_temp = pd.read_sql("select entryno,id,obsvalue, obs_error, prior_mean, prior_spread, kind, GROUP_CONCAT(prior), dart_qc, GROUP_CONCAT(member), deglat, deglon,\
                                levelht, (select distinct description from toc where kind=body.kind) \
                                as description from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and \
                                entryno=body_entryno where dart_qc=0  and description in ('"+str(obs)+"') GROUP BY entryno, id, kind, description  ORDER BY RANDOM()  limit "+str(nsample), con)
    con.close()
   
    # Conta il numero di righe non vuote in df_temp
    num_rows = df_temp.shape[0]

    # Verifica se il numero di righe è inferiore a nsample
    if num_rows < nsample:
        print(" WARNING:  not enough data from this db. There are only ",num_rows, " out of ", nsample)
        # If you do not exit you need to manage the possible empty values. 

    if DEBUG>=3:
       print(" df", df_temp)

    # Read the nsample location for the state vector according to the obs and localization.
    for ns in range(num_rows):
       lat_obs = df_temp.loc[ns,'deglat']
       lon_obs = df_temp.loc[ns,'deglon']
       lev_obs = df_temp.loc[ns,'levelht']
       if obs=='GPSRO_REFRACTIVITY':
          # Convert meters in hPa (From NOAA)
          lev_obs = P0*(1-lev_obs/44307.69396)**(1/0.190284)

          # From Pa to meters
          #lev_obs = 44307.69396*( 1 - (lev_obs*100/P0)**0.190284 )
       else:
          # Convert Pa in hPa
          lev_obs = lev_obs/100


       # Now find the model closest indeces to a point randmly chosen between the obs location and the obs location+-loc_radius      
       lat_index = find_closest_index(lat, lat_obs) 
       lon_index = find_closest_index(lon, lon_obs)
       lev_index = find_closest_index(lev, lev_obs)
       
       model_lat = lat[lat_index] 
       model_lon = lon[lon_index]
       model_lev = lev[lev_index]

       lat_deg2km = 110.574 # Km/degree
       dlato = 2 * loch/lat_deg2km
       latu = model_lat + dlato
       latd = model_lat - dlato
       if latu > 90:
          latu = 90
       if latd < -90:
          latd = -90

       deg2rad = math.pi/180
       lon_deg2km = 111.320*np.cos(deg2rad*model_lat) # Km/degree
       dlono = 2 * loch/lon_deg2km
       lonl = model_lon - dlono
       lonr = model_lon + dlono
       if lonl < 0:
          lonl1 = 0
          lonl2 = 360 + lonl
       if lonr > 360:
          lonr1 = 360
          lonr2 = lonr - 360 


       # Compute vertical localization box for the obs retrieval.
       ulev = lev[lev_index] * np.exp(-vloch)
       dlev = lev[lev_index] * np.exp(vloch)
       if ulev < vthreshold:
          ulev = vthreshold
       if dlev > P0:
          dlev = P0


       # Now we can find a random position of the sate vector within the loc radius.
       random_lat = random.uniform(latd, latu)
       if lonl<0:
          random_lon1 = random.uniform(lonl2, lonl1)
          random_lon2 = random.uniform(0, lonr)
          random_lon = random.choice([random_lon1, random_lon2])
       elif lonr>360:
          random_lon1 = random.uniform(lonl, 360)
          random_lon2 = random.uniform(lonr2, lonr1)
          random_lon = random.choice([random_lon1, random_lon2])
       else:
          random_lon = random.uniform(lonl, lonr)
       random_lev = random.uniform(dlev, ulev)


       # Now find the model location closer to this point.
       rmlat_index = find_closest_index(lat, random_lat)
       rmlon_index = find_closest_index(lon, random_lon)
       rmlev_index = find_closest_index(lev, random_lev)
       
       rmlat = lat[rmlat_index] 
       rmlon = lon[rmlon_index]
       rmlev = lev[rmlev_index]
      
     
       # We can now load the state vectors ensemble.
       # Extract the analysis values.
       ens_T_an  = np.zeros(nens);
       ens_Q_an  = np.zeros(nens);
       ens_U_an  = np.zeros(nens);
       ens_V_an  = np.zeros(nens);
       ens_PS_an = np.zeros(nens);
       for ne in range(nens):
             # Define the correct name of the member.
             width = 4
             instr = str(ne+1).zfill(width)
             # Load the state vector variables from all the members.
             aname = path2an + '/' + ename + '_f_' + instr  +'-' + adate + '.cam.h0.' + adate + '.nc'
             #print('analysis name: ', aname)
             dset  = Dataset(aname, mode='r')
             ens_T_an[ne]  = dset.variables['T'][0,lev_index,lat_index,lon_index]
             ens_Q_an[ne]  = dset.variables['Q'][0,lev_index,lat_index,lon_index]
             ens_U_an[ne]  = dset.variables['U'][0,lev_index,lat_index,lon_index]
             ens_V_an[ne]  = dset.variables['V'][0,lev_index,lat_index,lon_index]
             ens_PS_an[ne] = dset.variables['PS'][0,lat_index,lon_index]
             dset.close() # END ne cycle (ensemble member analysis cycle).


       # Assuming df is your DataFrame containing the 'GROUP_CONCAT(prior)' column
       prior_values_str = df_temp.loc[ns,'GROUP_CONCAT(prior)']
       # Split the comma-separated values and convert to a NumPy array
       prior_val = np.array(prior_values_str.split(','), dtype=float)
       
       if DEBUG>=4:
           print(' row number: ',ns)
           print(prior_values_str)
           print(prior_val)

       

       # Now the correlation coefficients can be computed.
       crT  = np.corrcoef(ens_T_an,prior_val)[0,1]
       crQ  = np.corrcoef(ens_Q_an,prior_val)[0,1]
       crU  = np.corrcoef(ens_U_an,prior_val)[0,1]
       crV  = np.corrcoef(ens_V_an,prior_val)[0,1]
       crPS = np.corrcoef(ens_PS_an,prior_val)[0,1]
       
       if DEBUG>=4:
           print(' crT = ',crT)
           print(' crQ = ',crQ)
           print(' crU = ',crU)
           print(' crV = ',crV)
           print(' crPS = ',crPS)


       # Now we can compute the t student test.
       tT  = crT *np.sqrt( (nens-2)/(1-crT**2) )
       tQ  = crQ *np.sqrt( (nens-2)/(1-crQ**2) )
       tU  = crU *np.sqrt( (nens-2)/(1-crU**2) )
       tV  = crV *np.sqrt( (nens-2)/(1-crV**2) )
       tPS = crPS *np.sqrt( (nens-2)/(1-crPS**2) )

       if abs(tT) > critical_t_value:
          print("The t-statistic is statistically significant.")
       else:
          print("The t-statistic is not statistically significant.")       


 #      if np.isnan(crT):
 #                          crT=0.0
 #                      if np.isnan(crQ):
 #                          crQ=0.0
 #                      if np.isnan(crU):
 #                          crU=0.0
 #                      if np.isnan(crV):
 #                          crV=0.0
 #                      if np.isnan(crPS):
 #                          crPS=0.0
 #
 








    cnt_obs = cnt_obs+1











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
print(' Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')
                                                                   




