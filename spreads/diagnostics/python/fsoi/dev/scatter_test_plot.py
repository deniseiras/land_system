# FSOI_Jo diagnostic check for the linear functional relation. 
#
# Skeleton for single cycle! Need to be extended.
# @author: Giovanni Conti 
# @date: 30 March 2023

# Import session.
#------------------------------------------
#------------------------------------------
import os
import numpy as np
import matplotlib.pyplot as plt
import math




# Functions definition.
#------------------------------------------
#------------------------------------------
def scatter_plot(x, y, title='', xlabel='', ylabel='', marker_size=10, tick_size=10, dpi=100, save_path=None):
    #plt.rcParams['text.usetex'] = True
    plt.figure(dpi=dpi)
    color='black'
    plt.scatter(x, y, s=marker_size, color=color)
    coeffs = np.polyfit(x, y, 1)
    regression_line = np.polyval(coeffs, x)
    color='red'
    plt.plot(x, regression_line, color=color)
    plt.title(title, fontsize=tick_size)
    plt.xlabel(xlabel, fontsize=tick_size)
    plt.ylabel(ylabel, fontsize=tick_size)
    plt.tick_params(axis='both', which='major', labelsize=tick_size)
    
    if save_path is not None:
        plt.savefig(save_path)
        plt.close()
    else:
        plt.show()




def scatter_plot_list(x_list, y_list, labels=None, title='', xlabel='', ylabel='', marker_size=10, tick_size=10, dpi=100, save_path=None):
    plt.figure(dpi=dpi)

    colors = plt.cm.viridis(np.linspace(0, 1, len(x_list)))  # Generate a list of colours with 'viridis'

    for i in range(len(x_list)):
        plt.scatter(x_list[i], y_list[i], s=marker_size, label=labels[i] if labels else None, color=colors[i])

    plt.title(title, fontsize=tick_size)
    plt.xlabel(xlabel, fontsize=tick_size)
    plt.ylabel(ylabel, fontsize=tick_size)
    plt.tick_params(axis='both', which='major', labelsize=tick_size)
    plt.legend()

    if save_path is not None:
        plt.savefig(save_path)
    else:
        plt.show()



def scatter_plot_list_reg(x_list, y_list, colorslist, labels=None, title='', xlabel='', ylabel='', marker_size=10, marker_alpha=1.0, tick_size=10, dpi=100, save_path=None, loc='upper right', x_log_scale=False):
    plt.figure(dpi=dpi)
    
    colors = colorslist 
    
    for i in range(len(x_list)):
        color = colors[i % len(colors)]
        plt.scatter(x_list[i], y_list[i], s=marker_size, alpha=marker_alpha, color=color, label=labels[i] if labels else None)

        # Regression computation
        x = np.array(x_list[i])
        y = np.array(y_list[i])
        if len(x) > 0:
           coeffs = np.polyfit(x, y, 1)
           regression_line = np.polyval(coeffs, x)
           # Plot regression line with the same colour of the group
           plt.plot(x, regression_line, color=color)


    if x_log_scale:
       plt.xscale('log')
    plt.title(title, fontsize=tick_size)
    plt.xlabel(xlabel, fontsize=tick_size)
    plt.ylabel(ylabel, fontsize=tick_size)
    plt.tick_params(axis='both', which='major', labelsize=tick_size)
    plt.legend(loc=loc)

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

dir2open='/work/cmcc/gc02720/CESM2/archive/junov4-forecast/junov4_forecast-2017-10-02-43200/fsoi_jo-db/diag-2017-10-03-43200' #'amsua.npz'
file2open='scatter_all.npz' #'amsua.npz'
path2sv = dir2open+'/img_scatter'


#******************************************
#    DO NOT MODIFY BELOW 
#******************************************
#---------------------------------------------
# Create the save dir if needed
if not os.path.exists(path2sv):
     try:
         os.mkdir(path2sv)
     except OSError:
         print ("\nCreation of the directory %s failed" % path2sv)
     else:
         print ("\nSuccessfully created the directory %s " % path2sv)




print("\nLoad data")
loaded_data = np.load(dir2open+'/'+file2open, allow_pickle=True)


scatt_anT_amsua=loaded_data['scatt_anT_amsua']
scatt_anQ_amsua=loaded_data['scatt_anQ_amsua']
scatt_anU_amsua=loaded_data['scatt_anU_amsua']
scatt_anV_amsua=loaded_data['scatt_anV_amsua']
scatt_pr_amsua=loaded_data['scatt_pr_amsua']

scatt_anT_amsua_ch8=loaded_data['scatt_anT_amsua_ch8']
scatt_anQ_amsua_ch8=loaded_data['scatt_anQ_amsua_ch8']
scatt_anU_amsua_ch8=loaded_data['scatt_anU_amsua_ch8']
scatt_anV_amsua_ch8=loaded_data['scatt_anV_amsua_ch8']
scatt_anT_amsua_ch9=loaded_data['scatt_anT_amsua_ch9']
scatt_anQ_amsua_ch9=loaded_data['scatt_anQ_amsua_ch9']
scatt_anU_amsua_ch9=loaded_data['scatt_anU_amsua_ch9']
scatt_anV_amsua_ch9=loaded_data['scatt_anV_amsua_ch9']
scatt_anT_amsua_ch10=loaded_data['scatt_anT_amsua_ch10']
scatt_anQ_amsua_ch10=loaded_data['scatt_anQ_amsua_ch10']
scatt_anU_amsua_ch10=loaded_data['scatt_anU_amsua_ch10']
scatt_anV_amsua_ch10=loaded_data['scatt_anV_amsua_ch10']
scatt_anT_amsua_ch11=loaded_data['scatt_anT_amsua_ch11']
scatt_anQ_amsua_ch11=loaded_data['scatt_anQ_amsua_ch11']
scatt_anU_amsua_ch11=loaded_data['scatt_anU_amsua_ch11']
scatt_anV_amsua_ch11=loaded_data['scatt_anV_amsua_ch11']
scatt_anT_amsua_ch12=loaded_data['scatt_anT_amsua_ch12']
scatt_anQ_amsua_ch12=loaded_data['scatt_anQ_amsua_ch12']
scatt_anU_amsua_ch12=loaded_data['scatt_anU_amsua_ch12']
scatt_anV_amsua_ch12=loaded_data['scatt_anV_amsua_ch12']
scatt_anT_amsua_ch13=loaded_data['scatt_anT_amsua_ch13']
scatt_anQ_amsua_ch13=loaded_data['scatt_anQ_amsua_ch13']
scatt_anU_amsua_ch13=loaded_data['scatt_anU_amsua_ch13']
scatt_anV_amsua_ch13=loaded_data['scatt_anV_amsua_ch13']
scatt_anT_amsua_ch14=loaded_data['scatt_anT_amsua_ch14']
scatt_anQ_amsua_ch14=loaded_data['scatt_anQ_amsua_ch14']
scatt_anU_amsua_ch14=loaded_data['scatt_anU_amsua_ch14']
scatt_anV_amsua_ch14=loaded_data['scatt_anV_amsua_ch14']
scatt_pr_amsua_ch8=loaded_data['scatt_pr_amsua_ch8']
scatt_pr_amsua_ch9=loaded_data['scatt_pr_amsua_ch9']
scatt_pr_amsua_ch10=loaded_data['scatt_pr_amsua_ch10']
scatt_pr_amsua_ch11=loaded_data['scatt_pr_amsua_ch11']
scatt_pr_amsua_ch12=loaded_data['scatt_pr_amsua_ch12']
scatt_pr_amsua_ch13=loaded_data['scatt_pr_amsua_ch13']
scatt_pr_amsua_ch14=loaded_data['scatt_pr_amsua_ch14']

scatt_anT_sndw=loaded_data['scatt_anT_sndw']
scatt_anQ_sndw=loaded_data['scatt_anQ_sndw']
scatt_anU_sndw=loaded_data['scatt_anU_sndw']
scatt_anV_sndw=loaded_data['scatt_anV_sndw']
scatt_pr_sndw=loaded_data['scatt_pr_sndw']

scatt_anT_sndt=loaded_data['scatt_anT_sndt']
scatt_anQ_sndt=loaded_data['scatt_anQ_sndt']
scatt_anU_sndt=loaded_data['scatt_anU_sndt']
scatt_anV_sndt=loaded_data['scatt_anV_sndt']
scatt_pr_sndt=loaded_data['scatt_pr_sndt']

scatt_anT_satw=loaded_data['scatt_anT_satw']
scatt_anQ_satw=loaded_data['scatt_anQ_satw']
scatt_anU_satw=loaded_data['scatt_anU_satw']
scatt_anV_satw=loaded_data['scatt_anV_satw']
scatt_pr_satw=loaded_data['scatt_pr_satw']

scatt_anT_arcw=loaded_data['scatt_anT_arcw']
scatt_anQ_arcw=loaded_data['scatt_anQ_arcw']
scatt_anU_arcw=loaded_data['scatt_anU_arcw']
scatt_anV_arcw=loaded_data['scatt_anV_arcw']
scatt_pr_arcw=loaded_data['scatt_pr_arcw']

scatt_anT_arct=loaded_data['scatt_anT_arct']
scatt_anQ_arct=loaded_data['scatt_anQ_arct']
scatt_anU_arct=loaded_data['scatt_anU_arct']
scatt_anV_arct=loaded_data['scatt_anV_arct']
scatt_pr_arct=loaded_data['scatt_pr_arct']

scatt_anT_gpsro=loaded_data['scatt_anT_gpsro']
scatt_anQ_gpsro=loaded_data['scatt_anQ_gpsro']
scatt_anU_gpsro=loaded_data['scatt_anU_gpsro']
scatt_anV_gpsro=loaded_data['scatt_anV_gpsro']
scatt_pr_gpsro=loaded_data['scatt_pr_gpsro']

scatt_anT_wdp=loaded_data['scatt_anT_wdp']
scatt_anQ_wdp=loaded_data['scatt_anQ_wdp']
scatt_anU_wdp=loaded_data['scatt_anU_wdp']
scatt_anV_wdp=loaded_data['scatt_anV_wdp']
scatt_pr_wdp=loaded_data['scatt_pr_wdp']

print("Data loaded")


print("\nGenerate Images")
print("AMSU-A")
# AMSU-A
yl='$\mathcal{H}[x]=Tb$'
#title='all channels, lev='+str(lev)
#scatter_plot(scatt_anT_amsua, scatt_pr_amsua, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatT.png')
#scatter_plot(scatt_anQ_amsua, scatt_pr_amsua, title='', xlabel='$Q$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatQ.png')
#scatter_plot(scatt_anU_amsua, scatt_pr_amsua, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatU.png')
#scatter_plot(scatt_anV_amsua, scatt_pr_amsua, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatV.png')

x8=scatt_anT_amsua_ch8
x9=scatt_anT_amsua_ch9
x10=scatt_anT_amsua_ch10
x11=scatt_anT_amsua_ch11
x12=scatt_anT_amsua_ch12
x13=scatt_anT_amsua_ch13
x14=scatt_anT_amsua_ch14

y8=scatt_pr_amsua_ch8
y9=scatt_pr_amsua_ch9
y10=scatt_pr_amsua_ch10
y11=scatt_pr_amsua_ch11
y12=scatt_pr_amsua_ch12
y13=scatt_pr_amsua_ch13
y14=scatt_pr_amsua_ch14

x_list=[x8,x9,x10,x11,x12,x13,x14]
y_list=[y8,y9,y10,y11,y12,y13,y14]
lege=['$ch8$','$ch9$','$ch10$','$ch11$','$ch12$','$ch13$','$ch14$']
colorslist=['black','blue', 'red', 'green', 'purple','orange','yellow']
if len(x_list) > 0 and len(y_list) > 0:
    scatter_plot_list_reg(x_list, y_list, colorslist, labels=lege, title='', xlabel='$T$', ylabel=yl, marker_size=10, marker_alpha=0.8, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatT_chall.png', loc='upper right', x_log_scale=False)
else:
   print('amsu-a list for T analisys is empty')

x8=scatt_anQ_amsua_ch8
x9=scatt_anQ_amsua_ch9
x10=scatt_anQ_amsua_ch10
x11=scatt_anQ_amsua_ch11
x12=scatt_anQ_amsua_ch12
x13=scatt_anQ_amsua_ch13
x14=scatt_anQ_amsua_ch14
x_list=[x8,x9,x10,x11,x12,x13,x14]
#scatter_plot_list_reg(x_list, y_list, colorslist, labels=lege, title='', xlabel='$Q$', ylabel=yl,  marker_size=10, marker_alpha=0.8, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatQ_chall.png', loc='upper right', x_log_scale=True)
x_list=[x * 1000 for x in x_list]
if len(x_list) > 0 and len(y_list) > 0:
   scatter_plot_list_reg(x_list, y_list, colorslist, labels=lege, title='', xlabel='$Q\\times 10^3$', ylabel=yl,  marker_size=10, marker_alpha=0.8, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatQ_chall.png', loc='upper right', x_log_scale=False)
else:
   print('amsu-a list for Q analisys is empty')


x8=scatt_anU_amsua_ch8
x9=scatt_anU_amsua_ch9
x10=scatt_anU_amsua_ch10
x11=scatt_anU_amsua_ch11
x12=scatt_anU_amsua_ch12
x13=scatt_anU_amsua_ch13
x14=scatt_anU_amsua_ch14
x_list=[x8,x9,x10,x11,x12,x13,x14]
if len(x_list) > 0 and len(y_list) > 0:
    scatter_plot_list_reg(x_list, y_list, colorslist, labels=lege, title='', xlabel='$U$', ylabel=yl, marker_size=10, marker_alpha=0.8, tick_size=10, dpi=100, save_path=path2sv+'/amsua-scatU_chall.png', loc='upper right', x_log_scale=False)
else:
   print('amsu-a list for U analisys is empty')


print("SND")
#SND
yl='$\mathcal{H}[x]={U,V}$'
if len(scatt_anT_sndw) > 0 and len(scatt_anQ_sndw) > 0 and len(scatt_anU_sndw) > 0 and len(scatt_anV_sndw) > 0 and len(scatt_pr_sndw) > 0:
   scatter_plot(scatt_anT_sndw, scatt_pr_sndw, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndw-scatT.png')
   scatter_plot(scatt_anQ_sndw*1000, scatt_pr_sndw, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndw-scatQ.png')
   scatter_plot(scatt_anU_sndw, scatt_pr_sndw, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndw-scatU.png')
   scatter_plot(scatt_anV_sndw, scatt_pr_sndw, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndw-scatV.png')
else:
   print('sndw lists are empty')

if  len(scatt_pr_sndt) > 0:
   yl='$\mathcal{H}[x]=T$'
   scatter_plot(scatt_anT_sndt, scatt_pr_sndt, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndt-scatT.png')
   scatter_plot(scatt_anQ_sndt*1000, scatt_pr_sndt, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndt-scatQ.png')
   scatter_plot(scatt_anU_sndt, scatt_pr_sndt, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndt-scatU.png')
   scatter_plot(scatt_anV_sndt, scatt_pr_sndt, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/sndt-scatV.png')
else:
   print('sndt lists are empty')


print("ARC")
#ARC
#print(scatt_anT_arcw)
#print(scatt_pr_arcw)
#print(scatt_anT_arct)
#print(scatt_pr_arct)
if  len(scatt_pr_arcw) > 0:
    yl='$\mathcal{H}[x]={U,V}$'
    scatter_plot(scatt_anT_arcw, scatt_pr_arcw, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arcw-scatT.png')
    scatter_plot(scatt_anQ_arcw*1000, scatt_pr_arcw, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arcw-scatQ.png')
    scatter_plot(scatt_anU_arcw, scatt_pr_arcw, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arcw-scatU.png')
    scatter_plot(scatt_anV_arcw, scatt_pr_arcw, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arcw-scatV.png')
else:
   print('arcw lists are empty')


if  len(scatt_pr_arcw) > 0:
    yl='$\mathcal{H}[x]=T$'
    scatter_plot(scatt_anT_arct, scatt_pr_arct, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arct-scatT.png')
    scatter_plot(scatt_anQ_arct*1000, scatt_pr_arct, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arct-scatQ.png')
    scatter_plot(scatt_anU_arct, scatt_pr_arct, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arct-scatU.png')
    scatter_plot(scatt_anV_arct, scatt_pr_arct, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/arct-scatV.png')
else:
   print('arct lists are empty')


print("AMV")
#AMV
if  len(scatt_pr_satw) > 0:
    yl='$\mathcal{H}[x]={U,V}$'
    scatter_plot(scatt_anT_satw, scatt_pr_satw, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/satw-scatT.png')
    scatter_plot(scatt_anQ_satw*1000, scatt_pr_satw, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/satw-scatQ.png')
    scatter_plot(scatt_anU_satw, scatt_pr_satw, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/satw-scatU.png')
    scatter_plot(scatt_anV_satw, scatt_pr_satw, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/satw-scatV.png')
else:
   print('satw lists are empty')


print("GPSRO")
#GPSRO
if  len(scatt_pr_gpsro) > 0:
    yl='$\mathcal{H}[x]=Refractivity$'
    scatter_plot(scatt_anT_gpsro, scatt_pr_gpsro, title='', xlabel='$T$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/gpsro-scatT.png')
    scatter_plot(scatt_anQ_gpsro*1000, scatt_pr_gpsro, title='', xlabel='$Q\\times 10^3$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/gpsro-scatQ.png')
    scatter_plot(scatt_anU_gpsro, scatt_pr_gpsro, title='', xlabel='$U$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/gpsro-scatU.png')
    scatter_plot(scatt_anV_gpsro, scatt_pr_gpsro, title='', xlabel='$V$', ylabel=yl, marker_size=10, tick_size=10, dpi=100, save_path=path2sv+'/gpsro-scatV.png')
else:
   print('gpsro lists are empty')




