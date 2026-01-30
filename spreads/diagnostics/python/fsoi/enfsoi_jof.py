# EnFSOI_Jf diagnostic computation for ensemble systems.
# Skeleton for single cycle! Need to be extended.
# @author: Giovanni Conti 
# @date: 04 March 2024




# Import session.
#------------------------------------------
#------------------------------------------
import os
import sqlite3
import pandas as pd
import numpy as np
from netCDF4 import Dataset
import datetime
import matplotlib.pyplot as plt
#from fsoijo_plot import *




# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# Exp name.
ename = "testfsoi"

# Analysis date ("YYYY-MM-DD-SSSSS").
adate = "2017-10-02-43200"

# Forecast date ("YYYY-MM-DD-SSSSS").
fdate = "2017-10-03-43200"

# Path to the exp archive
patharc   = '/work/cmcc/gc02720/CMCC-CM/archive'

path2an  = patharc + '/' + ename + '/' + ename + '-' + adate
path2f   = patharc + '/' + ename + '-forecast/' + ename + '_forecast-' + fdate + '/fsoi_jf-db'

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
             'METOP_2_AMSUA_TB' \
            ]


#obs4ver  = ['RADIOSONDE_U_WIND_COMPONENT', \
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


obs4ver  = [ 'EOS_2_AMSUA_TB']



# Number of ensemble members.
nens = 3

# Where to save the output, plot and data.
path2sv = path2f + '/diag-' + fdate

# Plot samples img?
plot_img = 'TRUE'

# Chose level of output. 
# DEBUG = 1 only cells indication, DEBUG = 2 add vertical information, DEBUG = 3 also obs retrieve info
# DEBUG = 4 print also the pandas query dataframe
DEBUG = 2


# Plot maps only on these levels 
#reflevs=(850,500,400,200,150,90)
reflevs=(150,)



# Plotting options.
fs=16 
dpi=100



#******************************************
#    DO NOT MODIFY BELOW 
#******************************************

# Functions definition. 
#------------------------------------------
#------------------------------------------
def get_obs(listdb, maskdb, obslist, nens, DEBUG):
    dfos_f = pd.DataFrame()
    
    for db, maskcc in zip(listdb, maskdb):
        if maskcc == 0:
            continue

        if DEBUG >= 2:
            print("\n Working with db: ", db, flush=True)

        obslist_str = ', '.join([f"'{obs}'" for obs in obslist])
        con = sqlite3.connect(db)
        df_temp = pd.read_sql(f"select entryno, id, kind, obsvalue, obs_error_variance, prior_mean, prior, dart_qc, member, deglat, deglon,\
                                    levelht, (select distinct description from toc where kind=body.kind) \
                                    as description from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and \
                                    entryno=body_entryno where description IN ({obslist_str}) AND dart_qc=0 AND member<={nens}", con)
        con.close()

        if len(df_temp['obsvalue'].tolist()) <= 0:
            print("\n No obs in this task from this db", flush=True)
            continue

        if DEBUG >= 1:
            print("\n Convert levelht in hPa. ", flush=True)

        if 'GPSRO' in db:
            P0 = 1013
            df_temp['levelht'] = P0*(1-df_temp['levelht']/44307.69396)**(1/0.190284)
        else:
            df_temp['levelht'] = df_temp['levelht'] / 100

        dfos_f = pd.concat([dfos_f, df_temp], ignore_index=True)

        if DEBUG >= 4:
            print("\n Pandas Obs: \n", dfos_f, flush=True)

    return dfos_f

## Usage example:
#listdb_f = [...]  # Your list of databases
#maskdb_f = [...]  # Your list of mask values
#obs4ver = [...]   # Your list of observations
#nens = ...        # Your value of nens
#DEBUG = ...       # Your DEBUG value
#dfos_f = get_obs(listdb_f, maskdb_f, obs4ver, nens, DEBUG)



def check_databases_obs(path2obs, obslist, obs_description_str):
    listdb = []
    rescatalog = False
    catalog_file = ''

    for file in os.listdir(path2obs):
        if file.endswith(".db"):
            if 'catalog' in file:
                rescatalog = True
                catalog_file = file
                print('\n catalog: ' + catalog_file)
            else:
                listdb.append(os.path.join(path2obs, file))
    listdb.sort()
    print("\n databases analysis: ", listdb)

    if rescatalog != True:
        print('\n ERROR: catalog not present!\n')
        exit()

    con = sqlite3.connect(os.path.join(path2obs, catalog_file))
    df = pd.read_sql("select * from catalog", con)
    con.close()
    dartotype = df['description'].unique()
    dartotype = dartotype[dartotype != np.array(None)]
    dartotype = dartotype[dartotype != np.array('')]
    print(f"\n{obs_description_str}:\n{dartotype}\n")

    cnt = 0
    for o2p in obslist:
        if np.where(dartotype == o2p) != []:
            cnt = cnt + 1
    if cnt == 0:
        print(' ERROR, no observations to study in the dbs')
        exit()

    maskdb = []
    for db in listdb:
        if any('AMSUA' in obs for obs in obslist) and 'AMSU' in db:
            maskdb.append(1)
        elif any('SAT' in obs for obs in obslist) and 'AMV' in db:
            maskdb.append(1)
        elif any('AIRCRAFT' in obs or 'ACARS' in obs for obs in obslist) and 'ARC' in db:
            maskdb.append(1)
        elif any('RADIOSONDE' in obs for obs in obslist) and 'SND' in db:
            maskdb.append(1)
        elif any('GPSRO' in obs for obs in obslist) and 'GPSRO' in db:
            maskdb.append(1)
        elif any('VADWND' in obs for obs in obslist) and 'WDP' in db:
            maskdb.append(1)
        else:
            maskdb.append(0)

    
    return listdb, maskdb

## Example usage:
#path2an = "/path/to/your/analysis/folder"
#obs2proc = ['obs1', 'obs2', 'obs3']  # Your list of observations
#obs_description_str = "List of ALL the different SPREADS obs type at analysis time:"
#listdb_a, maskdb_a = check_databases_obs(path2an, obs2proc, obs_description_str)









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
print(' Path forecast: ', path2f)
print(' Path save: ', path2sv)
print(' Observation to process: ', obs2proc)
print(' Observation for verification: ', obs4ver)
print(' Reference levels: ', reflevs)



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


# Determine how many db are present in the analysis and verification dir.
# Analisys check --------------------------------------------------------
print('\n\n Analysis db check ...')
print(' -------------------------------------------------------')

obs_description_str = "List of ALL the different SPREADS obs type at analysis time"
listdb_a, maskdb_a = check_databases_obs(path2an, obs2proc, obs_description_str)
print(' maskdb_a= ', maskdb_a)
print(' maskdb_a len= ', len(maskdb_a))
print(' listdb_a len= ', len(listdb_a))


# Verification check ------------------------------------------------
print('\n\n Verification db check ...')
print(' -------------------------------------------------------')

obs_description_str = "List of ALL the possible SPREADS obs type for verification"
listdb_f, maskdb_f = check_databases_obs(path2f, obs4ver, obs_description_str)
print(' maskdb_f= ', maskdb_f)
print(' maskdb_f len= ', len(maskdb_f))
print(' listdb_f len= ', len(listdb_f))



# Real computation ------------------------------------------------
print('\n\n Check finished, start the real computation')
print(' -------------------------------------------------------')

# For each obs type  chosen at analysis tiem we need to compute
# \delta y_f^{\top} R_f^{-1} Y_f Y_a^{\top} R_a^{-1}
# Remember that each type of obs will have a weight that 
# depends on all the types chosen at verification time.

# Save everything in a dictionary of dictionaries
enfsoi_jof = {}

#------------------------------------------------------------------------------------------
# Load all the obs at verification time 
# collect obs, prior, prior_mean, obs variance deglat, deglon, levelht
print("\n Get verification obs . . .")
dfos_f = get_obs(listdb_f, maskdb_f, obs4ver, nens, DEBUG)


# PAY ATTENTION WE NEED TO IMPOSE SOME ORDER BECASUE NOT NECESSARITLY THE FIRST ROW OF MEMBER 1 CORRESPOND TOTHE OBSERVATION OF 1 ROW FOR MEMBER 2!!!!! 
# Group by observation values, deglat, deglon, and levelht columns and sort within each group by member
print("\n Sort obs")
dfos_f_sorted = dfos_f.sort_values(by=['obsvalue', 'deglat', 'deglon', 'levelht', 'member'])

if DEBUG>=4:
    print("\n Pandas Obs sorted: \n", dfos_f_sorted, flush=True)


#------------------------------------------------------------------------------------------
# Generate the term \delta y_f^{\top} R_f^{-1} (R is diagonal in our system)
# size order 1 x 10^6 
df_member_ne = dfos_f[dfos_f['member'] == 1]
# Number of observation for verification
Nof = len(df_member_ne)
# Calculate the differences between 'obsvalue' and 'prior_mean'
differences = (df_member_ne['obsvalue'] - df_member_ne['prior_mean'])/ df_member_ne['obs_error_variance']
# Convert the result to a numpy array with shape (1, len(df_member_1))
yf_T_IRf = (-1/nens) * np.array(differences).reshape(1, -1)


# For memory release
# dfos_f = pd.DataFrame()

#------------------------------------------------------------------------------------------
# Instead of computing the intermediate term  Y_f
# size order 10^6 x 80
# we can compute the j column of Y_f by time and considering the scalar product with
# \delta y_f^{\top} R_f^{-1} automatically computing the j term of \delta y_f^{\top} R_f^{-1} Y_f
# which total size is of order 1 x 80
yf_T_IRf_Yf = np.zeros([1,nens])
for ne in range(1,nens+1):
    df_member_ne = dfos_f[dfos_f['member'] == ne]
    differences = df_member_ne['prior'] - df_member_ne['prior_mean']
    differences = differences.values.reshape(-1, 1)
    yf_T_IRf_Yf[0,ne-1] =np.dot(yf_T_IRf,differences)


print("\n Finished the computation of \delta y_f^{top} R_f^{-1} Y_f")

#------------------------------------------------------------------------------------------
# Load analysis obs type to process
# Also in this case we avoid the computation of the full matrix Y_a^{\top} of size 80 x 10^6
# we can compute directly  the ith entry of the final array 1 x 10^6 given by 
# \delta y_f^{\top} R_f^{-1} Y_f Y_a^{\top}. With the normalization is like the we perform also 
# the next computation step with teh R_a^{-1} moltiplication.
print("\n Get analysis obs . . . \n")
dfos_a = get_obs(listdb_a, maskdb_a, obs2proc, nens, DEBUG)

# I can already create here the anomalies, I add a new column. We normalize already with the obs variance.
dfos_a['anomalies'] = (dfos_a['prior'] - dfos_a['prior_mean'])/dfos_a['obs_error_variance']


for o2p in obs2proc:

    if DEBUG>=2:
       print('\n Processing analysis observation: ',o2p)
    
    # Exctract only one type of obs by time
    qstr = "description=="+"'"+o2p +"'"
    dfos_a_single_type = dfos_a.query(qstr)
    if len(dfos_a_single_type['obsvalue'].tolist())<=0:
        if DEBUG>=3:
            print(' No obs of this type '+ o2p +' in this interval.')
            continue
    
    Noa_type=len(dfos_a_single_type[dfos_a_single_type['member']==1])
    # Define the weight array that will multiply the analysis innovation.
    wfa = np.zeros([1,Noa_type])
    dya = np.zeros([Noa_type])
    deglata = np.zeros([Noa_type])
    deglona = np.zeros([Noa_type])
    levelhta = np.zeros([Noa_type])
    # Group by different obs 
    dfos_a_single_type_grp = dfos_a_single_type.groupby(['obsvalue', 'deglat', 'deglon', 'levelht','prior_mean'])
    dfos_a_single_type_grp = dfos_a_single_type_grp.apply(lambda x: x['anomalies'].to_numpy())

    if DEBUG>=5:
        print(f"\n dfos_a_single_type_grp: {dfos_a_single_type_grp}")
        print(f" len(dfos_a_single_type_grp) = {len(dfos_a_single_type_grp)}") 


    for no in range(Noa_type):
         tmp_column = dfos_a_single_type_grp.iloc[no]
         # Transform the array in a column shape [nens,1].
         tmp_column = np.array(tmp_column).reshape(-1,1)  
         # Compute the entry.
         wfa[0,no] = np.dot(yf_T_IRf_Yf, tmp_column)
        
         # Now take the information about obs localization and innovation.
         tmp_index    = dfos_a_single_type_grp.index[no]
         #print(f"tmp_index: {tmp_index}")
         dya[no]      = tmp_index[0]-tmp_index[4]
         deglata[no]  = tmp_index[1] 
         deglona[no]  = tmp_index[2]
         levelhta[no] = tmp_index[3]


    dya = np.array(dya).reshape(-1,1)
    impact_tot = np.dot(wfa,dya)
    wfa = wfa.reshape(-1)
    dya = np.squeeze(dya)
    #print(f"wfa: {wfa}")
    #print(f"wfa shape: {wfa.shape}")
    #print(f"dya: {dya}")
    #print(f"dya shape: {dya.shape}")
    impact_sgl = wfa*dya

    print(' Computed first variation for: ',o2p)
    # Complete the computation multiplying by the analysis innovation element by element!

    # Store the results.
    enfsoi_jof[o2p] = {"total_impact": impact_tot, "impact": impact_sgl, "deglat":deglata, "deglon":deglona, "levelht":levelhta} 

   
    #dbg
    if DEBUG>=5:
        print(f"\n enfsoi_jof: {enfsoi_jof}")
        print(f" len(enfsoi_jof) = {len(enfsoi_jof)}") 




#------------------------------------------------------------------------------------------



# Convert the dictionary to a DataFrame
enfsoi_jof_pd = pd.DataFrame.from_dict(enfsoi_jof, orient='index')

# Transpose the DataFrame to have the desired structure
#enfsoi_jof_pd = enfsoi_jof_pd.transpose()

# Compute the relative impact. Number of analysis obs per bin (type).
# For the error bar we need to know how many values we have in a bin and compute the std. err= 1.96*std_bin/sqrt(Nbin).
r_impact = np.zeros(len(enfsoi_jof))
nbin     = np.zeros(len(enfsoi_jof)) 
stdbin   = np.zeros(len(enfsoi_jof)) 
ri_errbin   = np.zeros(len(enfsoi_jof)) 
key_list    = list(enfsoi_jof.keys()) # we can have less observations type than the one required in obs2proc
print(f"\n keys: {key_list}")
for idp, o2p in enumerate(key_list):
      r_impact[idp] = enfsoi_jof[o2p]['total_impact']
      nbin[idp]   = len(enfsoi_jof[o2p]['impact'])
      stdbin[idp] = np.std(enfsoi_jof[o2p]['impact'])
      ri_errbin[idp] = 1.96*stdbin[idp]/np.sqrt(nbin[idp])

# Normalization.
r_impact_norm = 100/sum(r_impact) # To get percentage.
r_impact      = r_impact * r_impact_norm
ri_errbin     = ri_errbin * r_impact_norm
print(f"\n\n Relative impact computed!")


# Check also how much the observations contribute to improve or degrade the forecast.
# Use boolean indexing:
# count the number of values >= 0 and < 0.
num_impact_positive = np.zeros(len(enfsoi_jof))
num_impact_negative = np.zeros(len(enfsoi_jof))
p_errbin = np.zeros(len(enfsoi_jof))
n_errbin = np.zeros(len(enfsoi_jof))
for idp, o2p in enumerate(key_list):
    num_impact_positive[idp] = np.sum(enfsoi_jof[o2p]['impact'] >= 0)
    num_impact_negative[idp] = np.sum(enfsoi_jof[o2p]['impact'] < 0)
    p_errbin[idp] = 1.96* np.std( enfsoi_jof[o2p]['impact'][enfsoi_jof[o2p]['impact'] >= 0]  )/np.sqrt(num_impact_positive[idp]) 
    n_errbin[idp] = 1.96* np.std( enfsoi_jof[o2p]['impact'][enfsoi_jof[o2p]['impact'] < 0]  )/np.sqrt(num_impact_negative[idp]) 

    # Normalization.
    norm_pd_impact = 100/(num_impact_positive[idp]+num_impact_negative[idp]) 
    num_impact_positive[idp] = num_impact_positive[idp] * norm_pd_impact
    num_impact_negative[idp] = num_impact_negative[idp] * norm_pd_impact
    p_errbin[idp] = p_errbin[idp] * norm_pd_impact
    n_errbin[idp] = n_errbin[idp] * norm_pd_impact






print(f"\n Relative impact for degradation or improvement of single type obs computed!")




# Saving session.
#------------------------------------------
#------------------------------------------
np.savez(path2sv+"/enfsoi_jof.npz", enfsoi_jof_pd=enfsoi_jof_pd, r_impact=r_impact, ri_errbin=ri_errbin, 
                                    key_list=key_list, 
                                    num_impact_positive = num_impact_positive,
                                    num_impact_negative = num_impact_negative,
                                    p_errbin = p_errbin,
                                    n_errbin = n_errbin,
                                    listdb_a=listdb_a, listdb_f=listdb_f, adate=adate, fdate=fdate)


# Plots.
#------------------------------------------
#------------------------------------------
print('\n Start plotting . . .')
# Bar plot for relative impact
print(' Relative impact bar plot . . .')

fig = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
ax = fig.add_subplot(111)
y_pos = np.arange(len(key_list))
ax.barh(y_pos, r_impact, xerr=ri_errbin, align='center', alpha=0.5, ecolor='black', capsize=10)
ax.invert_yaxis()  # labels read top-to-bottom
ax.set_xlabel('$EnFSOI-J_o^f$ %')
ax.set_ylabel('')
ax.set_yticks(y_pos)
ax.set_yticklabels(key_list)
ax.set_title('')
ax.xaxis.grid(True)
plt.savefig(path2sv+"/relative_impact.png")
plt.close()




# Bar plot for positive and negative contribution of single type
for idp, o2p in enumerate(key_list):
    fig = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
    ax = fig.add_subplot(111)
    y_pos = np.array([1,2])
    x     = np.array([num_impact_positive[idp], num_impact_negative[idp]])
    xerr  = np.array([p_errbin[idp], n_errbin[idp]])
    ax.barh(y_pos, x, xerr=xerr, align='center', alpha=0.5, ecolor='black', capsize=10)
    ax.invert_yaxis()  # labels read top-to-bottom
    ax.set_xlabel('$% of Positive and Negative contributions')
    ax.set_ylabel('Positive - Pegative Impact Percentage')
    ax.set_yticks(y_pos)
    ax.set_yticklabels(["Degrading (>0)","Improving (<0)"])
    ax.set_title('')
    ax.xaxis.grid(True)
    plt.savefig(path2sv+"/pn_"+o2p+"_relative_impact.png")
    plt.close()

# 2d maps for AMSUA test






# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t)

print('\n -------------------- END ------------------- \n')




