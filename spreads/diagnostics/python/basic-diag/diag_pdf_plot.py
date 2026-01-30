# Create a diag report
# @author: Giovanni Conti
# @date: 25 March 2024


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
def diag_pdf(data, region, obs,  title='', fs=16, dpi=100, save_path=None):

    if obs not in data or region not in data[obs]:
        print(f"Error: Data not found for observation '{obs}' and region '{region}'")
        return
    
    # Create the figure and subplots
    fig, ax = plt.subplots(figsize=(800/dpi, 1000/dpi))

    bias_prior     = data[obs][region]['bias_prior_pdf']
    bias_posterior = np.array(data[obs][region]['bias_posterior_pdf'])

    NB=int(np.sqrt(len(bias_prior)))
    plt.hist(bias_prior, bins=NB, alpha=0.5, label='Bias Prior', color='blue')
    plt.hist(bias_posterior, bins=NB, alpha=0.5, label='Bias Posterior', color='red')
    #plt.hist(bias_prior, bins=40, alpha=0.5, label='Bias Prior', color='blue')
    #plt.hist(bias_posterior, bins=40, alpha=0.5, label='Bias Posterior', color='red')


    plt.xlabel('Bias',fontsize=fs)
    plt.ylabel('Frequency',fontsize=fs)
    plt.title(title,fontsize=fs)
    
    # Extract the handles and labels for the legend
    handles, labels = ax.get_legend_handles_labels()
    plt.legend(handles, labels, fontsize=fs)

    plt.xticks(fontsize=fs)
    plt.yticks(fontsize=fs)

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
file_path = path2sv + '/pdf_all.npz'


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
data = np.load(file_path, allow_pickle=True)

# Access the variables saved in the file
pdf_diag      = data['pdf_diag'].item()
regions       = data['regions']
obs2proc      = data['obs2proc']
diag_type     = data['diag_type']
start_date    = data['start_date']
end_date      = data['end_date']

#dbg
print(pdf_diag)

# Print the shapes of the loaded variables
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

    for id_rg, rg in enumerate(regions):
        print(' region: ', rg, flush=True)
        # plot profile
        fsave = obs+'_'+rg+'_pdf.png'
        diag_pdf(pdf_diag, rg, obs,  title=obs+'  '+rg+'\n Period: '+str(start_date)+' - '+str(end_date), fs=16, dpi=100, save_path=path2img+'/'+fsave)




# END
#------------------------------------------
#------------------------------------------
# Get the current date and time
final_t = datetime.datetime.now()
print('\n',final_t)
print('Execution Time: ',final_t-start_t, flush=True)

print('\n -------------------- END ------------------- \n', flush=True)
                                                                               
