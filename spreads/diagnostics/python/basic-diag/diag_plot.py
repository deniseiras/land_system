# Create a diag report./users_home/cmcc/gc02720/spreads/diagnostics/python/basic-diag
# @author: Giovanni Conti
# @date: 10 July 2023


# Import session.
#------------------------------------------
#------------------------------------------
import os
import numpy as np
import math
import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

import glob
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

from PIL import Image

# Functions definition.
#------------------------------------------
#------------------------------------------

# Evol plot.
def diag_evol(evol_diag, id_region, id_obs, diag_type, title='', fs=16, dpi=100, save_path=None):
    # Create the figure and subplots
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(800/dpi, 1000/dpi))

    ncycles = np.arange(1,evol_diag.shape[-1]+1)
   
    # Plot on the first subplot (BIAS and # of obs)
    id_dt = np.where(diag_type == 'bias')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax1.plot(ncycles, tmp, 'ko-', label='Bias: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    ax1.set_title('Bias')
    # Add a horizontal line at y=0
    ax1.axhline(y=0, color='red', linestyle='--')
    # Create the second y-axis and plot the second variable
    ax1_2 = ax1.twinx()
    id_dt = np.where(diag_type == 'num_assi')[0]
    tmpa=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    id_dt = np.where(diag_type == 'num_rej')[0]
    tmpr=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmpr_m = np.nanmean(tmpr)
    tmpa_m = np.nanmean(tmpa)
    pr=np.round( 100*tmpr_m/(tmpr_m+tmpa_m), 2 )
    pa=np.round( 100*tmpa_m/(tmpr_m+tmpa_m), 2 )
    ax1_2.plot(ncycles, tmpa, 'bo-', label='# assimilated obs: '+ str(pa)+'%')
    ax1_2.plot(ncycles, tmpr, 'bv-.', label='# rejected obs: '+str(pr)+'%')
    ax1_2.set_ylabel('# obs', color='blue')
    ax1_2.tick_params(axis='y', labelcolor='blue')
    ax1_2.spines['right'].set_color('blue')
    # Add legend to the subplot
    lines, labels = ax1.get_legend_handles_labels()
    lines2, labels2 = ax1_2.get_legend_handles_labels()
    leg = ax1_2.legend(lines + lines2, labels + labels2, loc='upper right')

    #dbg
    #print('id_obs: ', id_obs)
    #print('id_region', id_region)
    #print('id_dt', id_dt)
    #print(evol_diag[id_obs, id_region, id_dt, :])

    # Plot on the second subplot (SPREAD, TOTAL_SPREAD, RMSE)
    id_dt = np.where(diag_type == 'spread')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax2.plot(ncycles, tmp, 'kv-', label='Spread: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    id_dt = np.where(diag_type == 'total_spread')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax2.plot(ncycles, tmp, 'ko-', label='Total Spread: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    id_dt = np.where(diag_type == 'rmse')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax2.plot(ncycles, tmp, 'ro-', label='RMSE: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    ax2.set_title('Spread, Total Spread, RMSE')
    lines, labels = ax2.get_legend_handles_labels()
    leg = ax2.legend(lines, labels, loc='upper right')

    # Plot on the third subplot
    id_dt = np.where(diag_type == 'oi')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax3.plot(ncycles, tmp, 'ko-', label='OI: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    ax3.axhline(y=1, color='red', linestyle='--')
    id_dt = np.where(diag_type == 'rmse_tspread_idx')[0]
    tmp=np.squeeze(evol_diag[id_obs, id_region, id_dt, :])
    tmp_m=np.round( np.nanmean(tmp), 2)
    tmp_s=np.round( np.nanstd(tmp), 2)
    ax3.plot(ncycles, tmp, 'bo-', label='RMSE/Total_Spread: '+str(tmp_m)+' $\pm$ '+str(tmp_s), linewidth=2)
    lines, labels = ax3.get_legend_handles_labels()
    leg = ax3.legend(lines, labels, loc='upper right')
    
    ax3.set_xlabel('# cycles')
    ax3.set_title('OI  -  RMSE/Total_Spread')

    # Add a title for the entire figure
    fig.suptitle(title, fontsize=14, fontweight='bold')
    
    # Adjust the layout and spacing between subplots
    plt.tight_layout()

    if save_path is not None:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()


# Profile plot.
def diag_profile(profile_diag, id_region, id_obs, diag_type, clayers, title='', fs=16, dpi=100, save_path=None):
    # Create the figure and subplots
    fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(1000/dpi, 600/dpi))

    # Plot on the first subplot (BIAS)
    id_dt = np.where(diag_type == 'bias')[0]
    
    #print(profile_diag[id_obs, id_region, id_dt, :,:])
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0

    tmp=np.nanmean( tmp,  axis=1)
    ax1.plot( tmp, clayers,'ko-', label='Bias', linewidth=2)
    #ax1.set_title('Bias')
    # Add a horizontal line at y=0
    ax1.axvline(x=0, color='red', linestyle='--')
    lines, labels = ax1.get_legend_handles_labels()
    leg = ax1.legend(lines, labels, loc='upper right')
    ax1.set_xlabel('Bias')
    ax1.set_ylabel('hPa')
    ax1.invert_yaxis()

    # Plot on the second subplot (SPREAD, TOTAL_SPREAD, RMSE)
    id_dt = np.where(diag_type == 'spread')[0]
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0
    tmp=np.nanmean( tmp, axis=1)
    ax2.plot(tmp, clayers, 'kv-', label='Spread', linewidth=2)
    id_dt = np.where(diag_type == 'total_spread')[0]
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0
    tmp=np.nanmean(tmp, axis=1)
    ax2.plot(tmp, clayers, 'ko-', label='Total Spread', linewidth=2)
    id_dt = np.where(diag_type == 'rmse')[0]
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0
    tmp=np.nanmean(tmp, axis=1)
    ax2.plot(tmp, clayers, 'ro-', label='RMSE', linewidth=2)
    #ax2.set_title('Spread, Total Spread, RMSE')
    lines, labels = ax2.get_legend_handles_labels()
    leg = ax2.legend(lines, labels, loc='upper right')
    ax2.invert_yaxis()
    ax2.set_xlabel('Spread, Total Spread, RMSE')

    # Plot on the third subplot
    id_dt = np.where(diag_type == 'oi')[0]
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0
    tmp=np.nanmean( tmp, axis=1)
    ax3.plot(tmp, clayers, 'ko-', label='OI', linewidth=2)
    ax3.axvline(x=1, color='red', linestyle='--')
    ax3.axvline(x=0, color='red', linestyle='--')
    id_dt = np.where(diag_type == 'rmse_tspread_idx')[0]
    tmp=np.squeeze(profile_diag[id_obs, id_region, id_dt, :,:])
    nan_rows = np.isnan(tmp).all(axis=1)
    # Set rows with all NaN values to zero
    tmp[nan_rows] = 0
    tmp=np.nanmean(tmp, axis=1)
    ax3.plot(tmp, clayers, 'bo-', label='RMSE/Total_Spread', linewidth=2)
    lines, labels = ax3.get_legend_handles_labels()
    leg = ax3.legend(lines, labels, loc='upper right')
    ax3.invert_yaxis()
    ax3.set_xlabel('OI,  RMSE/Total_Spread')



    # Add a title for the entire figure
    fig.suptitle(title, fontsize=14, fontweight='bold')

    if save_path is not None:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()




# Parameters definition. 
#------------------------------------------
#------------------------------------------
#******************************************
#    MODIFY THE PARAMETERS HERE!
#******************************************

# File to load.
path2sv   = '/work/cmcc/gc02720/basic_diag'
file_path = path2sv + '/utest_all.npz'


#******************************************
#    DO NOT MODIFY BELOW
#******************************************
#------------------------------------------
# Create the save dir if needed
path2img=path2sv+'/img'
if not os.path.exists(path2img):
     try:
         os.mkdir(path2img)
     except OSError:
         print ("\nCreation of the directory %s failed" % path2img)
     else:
         print ("\nSuccessfully created the directory %s " % path2img)




# Plot session.
#------------------------------------------
#------------------------------------------

# Get the current date and time
start_t = datetime.datetime.now()
print('\n',start_t, flush=True)

# Load the data from the file
data = np.load(file_path)

# Access the variables saved in the file
evol_diag     = data['evol_diag']
profile_diag  = data['profile_diag']
center_layers = data['center_layers']
regions       = data['regions']
obs2proc      = data['obs2proc']
diag_type     = data['diag_type']
start_date    = data['start_date']
end_date      = data['end_date']

# Print the shapes of the loaded variables
print(" Shape of evol_diag:", evol_diag.shape, flush=True)
print(" Shape of profile_diag:", profile_diag.shape, flush=True)
print(" Shape of center_layers:", center_layers.shape, flush=True)
print(" Shape of regions:", regions.shape, flush=True)
print(" Shape of obs2proc:", obs2proc.shape, flush=True)
print(" Shape of diag_type:", diag_type.shape, flush=True)
print("\n Obs to process:", obs2proc, flush=True)
print(" Regions:", regions, flush=True)
print(" Start Date:", start_date, flush=True)
print(" End Date:", end_date, flush=True)


#dbg
#start_date="2017-10-02-21600"
#end_date="2017-10-03-00000"



for obs in obs2proc:
    print('\n processing obs: ', obs, flush=True)
    id_obs = np.where(obs2proc == obs)[0]

    for rg in regions:
        print(' region: ', rg, flush=True)
        id_rg = np.where(regions == rg)[0]
  
        # check that we have something to be plotted
        id_dt=0
        slicep=np.squeeze(evol_diag[id_obs,id_rg,id_dt,:])
        #print(slicep)
        num_nan = np.isnan(slicep).sum()
        if num_nan == len(slicep):
           print(' no obs for plotting evolution...')
        else:
           # plot evol
           fsave = obs+'_'+rg+'.png'
           diag_evol(evol_diag, id_rg, id_obs, diag_type, title=obs+'  '+rg+'\n Period: '+str(start_date)+' - '+str(end_date), fs=16, dpi=100, save_path=path2img+'/'+fsave)

        id_dt=0
        slicep  = np.squeeze(profile_diag[id_obs, id_rg, id_dt, :,:])
        slicep1 = np.reshape(slicep, -1)
        #print(slicep1)
        if np.all(np.isnan(slicep1)):
           print(" no obs in these profiles (all nan)...")
        else:
           # plot profile
           fsave = obs+'_'+rg+'_profile.png'
           diag_profile(profile_diag, id_rg, id_obs, diag_type, center_layers,  title=obs+'  '+rg+'\n Period: '+str(start_date)+' - '+str(end_date), fs=16, dpi=100, save_path=path2img+'/'+fsave)


            
           

# Collect all the images in a pdf report.
# Set the path to the directory containing the .png images
directory = path2img

# Retrieve the filenames of .png images in the directory
png_files = glob.glob(directory + "/*.png")
png_files.sort()

# Create a PDF file
pdf_file = path2img+"/report.pdf"
c = canvas.Canvas(pdf_file, pagesize=letter)

# Loop through the .png files and add them to the PDF
for png_file in png_files:

    c.drawImage(png_file, 0, 0, width=letter[0], height=letter[1])
    c.showPage()

# Save and close the PDF file
c.save()





# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t, flush=True)

print('\n -------------------- END ------------------- \n', flush=True)
                                                                               
