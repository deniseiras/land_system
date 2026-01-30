# FSOI_Jo and FSOI_Jo_OI diagnostic plot support function.
# @author: Giovanni Conti 
# @date: 10 April 2023



# Import session.
#------------------------------------------
#------------------------------------------
import numpy as np
from netCDF4 import Dataset
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
#from cartopy.util import add_cyclic_point
import cartopy.util as cutil

# Functions definition.
#------------------------------------------
#------------------------------------------


# Bar plot, percentage indicator.
def fsoi_plot_bar(fsoimean, fsoisd, obs2proc, ocount, title='' , xlabel='', ylabel='', fs=16, dpi=100, save_path=None):
    fig      = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
    ax = fig.add_subplot(111)

    # Find the relative contribution.
    NOBS  = len(obs2proc) #fsoi.shape[0]
    omean = np.zeros(NOBS)
    ostd  = np.zeros(NOBS)
    #mask = np.isnan(fsoi_mask)
    #masked_fsoi = np.ma.masked_array(fsoi, mask)
    #filled_fsoi = masked_fsoi.filled(np.nan)
    for io in range(NOBS):
        #valid_values = filled_fsoi[io, :, :, :].flatten()
        #valid_values = valid_values[~np.isnan(valid_values)]
        #omean[io] = np.mean(valid_values)
        #ostd[io] = np.std(valid_values)
        #    omean[io] = np.nanmean( filled_fsoi[io,:,:,:].flatten() )
        #    ostd[io] = np.nanstd( filled_fsoi[io,:,:,:].flatten() )
        omean[io] = fsoimean[io]
        ostd[io] = fsoisd[io]
        if ocount[io] > 0:
           ostd[io] = 2.58 * ostd[io] / np.sqrt(ocount[io])

            #print('omean= ', omean[io])

    # Normalize.
    omean_norm = np.abs(omean)
    norm       = np.sum(omean_norm)
    omean_norm = omean_norm*100/norm
    ostd_norm  = ostd*100/norm

    y_pos = np.arange(len(obs2proc))
    ax.barh(y_pos, omean_norm, xerr=ostd_norm, align='center', alpha=0.5, ecolor='black', capsize=10)
    ax.invert_yaxis()  # labels read top-to-bottom
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_yticks(y_pos)
    ax.set_yticklabels(obs2proc)
    ax.set_title(title)
    ax.xaxis.grid(True)

    # Save the figure and show.   
    if save_path is not None:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()


def create_pie_chart(labels, sizes, title='', colormap='tab20', dpi=100, save_path=None):
    fig = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
    colors = plt.cm.get_cmap(colormap)(np.linspace(0, 1, len(labels)))
    explode_index = np.argmax(sizes)
    explode = [0.1 if i == explode_index else 0 for i in range(len(labels))]

    plt.pie(sizes, explode=explode, labels=labels, colors=colors, autopct='%1.1f%%', shadow=True, startangle=90)
    plt.axis('equal')
    plt.title(title)

    if save_path is not None:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()

#def create_pie_chart(labels, sizes,  title='', dpi=100, save_path=None):
#    fig      = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
#    colors = plt.cm.tab20(np.linspace(0, 1, len(labels)))
#    explode_index = np.argmax(sizes)
#    explode = [0.1 if i == explode_index else 0 for i in range(len(labels))]
#    
#    plt.pie(sizes, explode=explode, labels=labels, colors=colors, autopct='%1.1f%%', shadow=True, startangle=90)
#    plt.axis('equal')
#    plt.title(title)
#    
#    if save_path is not None:
#        plt.savefig(save_path)
#        plt.close()
#    else:
#        plt.show()



def fsoi_plot_bar_gr(fsoimean, fsoisd, obs2proc, ocount, title='' , xlabel='', ylabel='', fs=16, dpi=100, save_path='bar.png'):
    fig      = plt.figure(figsize=(1000/dpi, 1000/dpi), dpi=dpi)
    ax = fig.add_subplot(111)

    # Find the relative contribution.
    NOBS  = len(obs2proc) #fsoi.shape[0]
    labels = ['$Aircraft$','$Radiosondes$','$AMV$','$GPS-RO$','$AMSU-A$']
    NL=len(labels)
    omean = np.zeros(NL)
    ostd  = np.zeros(NL)
    oc  = np.zeros(NL)
    
    idx=0
    for obs in obs2proc:
        
        #if idx==2 or idx==4 or idx==12 or idx==13:
        if fsoimean[idx]==0:
            idx=idx+1
            continue
        
        #index = obs2proc.index(obs)
        if 'AIRCRAFT' in obs or 'ACARS' in obs:
            #il=labels.index('$Aircraft$')
            il=0
        elif 'RADIOSONDE' in obs:
            #il=labels.index('$Radiosondes$')
            il=1
        elif 'SAT' in obs:
            #il=labels.index('$AMV$')
            il=2
        elif 'GPSRO' in obs:
            #il=labels.index('$GPS-RO$')
            il=3
        elif 'EOS' in obs or 'NOAA' in obs or 'METOP' in obs:
            #il=labels.index('$AMSU-A$')
            il=4
  
        #omean[il]=omean[il]+fsoimean[index]
        #ostd[il]=ostd[il]+fsoisd[index]
        #oc[il]=oc[il]+ocount[index]
        omean[il]=omean[il]+np.abs(fsoimean[idx])
        ostd[il]=ostd[il]+fsoisd[idx]
        oc[il]=oc[il]+ocount[idx]
        idx=idx+1
 

    for io in range(NL):
        if oc[io] > 0:
           ostd[io] = 2.58 * ostd[io] / np.sqrt(oc[io])

    # Normalize.
    omean_norm = np.abs(omean)
    norm       = np.sum(omean_norm)
    omean_norm = omean_norm*100/norm
    ostd_norm  = ostd*100/norm
    
    print(omean_norm)
    print(ostd_norm)

    #y_pos = np.arange(len(obs2proc))
    y_pos = np.arange(len(labels))
    print(y_pos)
    ax.barh(y_pos, omean_norm, xerr=ostd_norm, align='center', alpha=0.5, ecolor='black', capsize=10)
    ax.invert_yaxis()  # labels read top-to-bottom
    ax.set_xlabel(xlabel,fontsize=20)
    ax.set_ylabel(ylabel,fontsize=20)
    ax.set_yticks(y_pos)
    #ax.set_yticklabels(obs2proc)
    ax.set_yticklabels(labels,fontsize=20)    
    #ax.set_yticklabels(('ARC','SND','AMV','GPSRO','AMSU-A'))
    ax.set_title(title,fontsize=20)
    ax.xaxis.grid(True)

    # Save the figure and show.    
    if save_path is not None:
        plt.savefig(save_path, dpi=dpi)
        plt.close()
    else:
        plt.show()



def fsoi_plot_map(fsoi_map, lon, lat, title='', clabel='', xlabel='', ylabel='', cmap='bwr', fs=16, dpi=100, save_path=None):
    # Calculate symmetric vmin and vmax
    fsoi_max = np.abs(fsoi_map).max()
    vmin = -fsoi_max
    vmax = fsoi_max

    # Make the figure
    fig = plt.figure(figsize=(11, 8.5))

    # Set the axes using PlateCarree projection
    ax = plt.axes(projection=ccrs.PlateCarree())

    # Add cyclic point to data
    lon = np.linspace(lon.min(), lon.max(), len(lon))
    fsoi_map, lon = cutil.add_cyclic_point(fsoi_map, coord=lon)
    #lon, fsoi_map = cutil.shiftgrid(180, fsoi_map, lon, start=False)

    # Make a filled contour plot
    cs = ax.pcolormesh(lon, lat, fsoi_map, transform=ccrs.PlateCarree(), cmap=cmap, vmin=vmin, vmax=vmax, shading='auto')

    # Add coastlines
    ax.coastlines()

    # Set xticks and yticks
    ax.set_xticks(np.arange(-180, 181, 60), crs=ccrs.PlateCarree())
    ax.set_yticks(np.arange(-90, 91, 30), crs=ccrs.PlateCarree())
    ax.tick_params(axis='both', which='major', labelsize=12) 

    # Add gridlines
    gl = ax.gridlines(color='black', linestyle='--', linewidth=0.5)
    gl.top_labels = False
    gl.right_labels = False

    # Add colorbar
    cbar = plt.colorbar(cs, shrink=0.7, orientation='horizontal', label=clabel)
    cbar.ax.tick_params(labelsize=12) 

    # Add title
    plt.title(title, fontsize=fs)

    # Set axis labels
    ax.set_xlabel(xlabel, fontsize=fs)
    ax.set_ylabel(ylabel, fontsize=fs)

    if save_path is not None:
        plt.savefig(save_path, dpi=dpi)
        plt.close()
    else:
        plt.show()        
