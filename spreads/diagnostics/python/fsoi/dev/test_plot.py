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
    #fsoi_map, lon = add_cyclic_point(fsoi_map, coord=lon)
    fsoi_map, lon = cutil.add_cyclic_point(fsoi_map, coord=lon)
    lon, fsoi_map = cutil.shiftgrid(180, fsoi_map, lon, start=False)

    # Make a filled contour plot
    cs = ax.pcolormesh(lon, lat, fsoi_map, transform=ccrs.PlateCarree(), cmap=cmap, vmin=vmin, vmax=vmax, shading='auto')

    # Add coastlines
    ax.coastlines()

    # Set xticks and yticks
    ax.set_xticks(np.arange(-180, 181, 60), crs=ccrs.PlateCarree())
    ax.set_yticks(np.arange(-90, 91, 30), crs=ccrs.PlateCarree())

    # Add gridlines
    gl = ax.gridlines(color='black', linestyle='--', linewidth=0.5)
    gl.top_labels = False
    gl.right_labels = False

    # Add colorbar
    cbar = plt.colorbar(cs, shrink=0.7, orientation='horizontal', label=clabel)

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







file2open='utest.npz'

print("\nLoad data")
loaded_data = np.load(file2open, allow_pickle=True)


scatt_anT_amsua=loaded_data['scatt_anT_amsua']










