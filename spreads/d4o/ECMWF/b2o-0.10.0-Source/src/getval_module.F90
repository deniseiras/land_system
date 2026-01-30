
MODULE getval_module
USE PARKIND1  ,ONLY : JPIM     ,JPRD

#ifndef B2O_STANDALONE
USE odb_module
#endif

 implicit none


 INTEGER(KIND=JPIM)   :: g_gpheight
 INTEGER(KIND=JPIM)   :: g_pressure
 INTEGER(KIND=JPIM)   :: g_tovs_cha
 INTEGER(KIND=JPIM)   :: g_scat_cha
 INTEGER(KIND=JPIM)   :: g_imp_param
 INTEGER(KIND=JPIM)   :: g_cha_number
 INTEGER(KIND=JPIM)   :: g_cha_wavelength
 INTEGER(KIND=JPIM)   :: g_cha_frequency
 INTEGER(KIND=JPIM)   :: g_dd
 INTEGER(KIND=JPIM)   :: g_ff
 INTEGER(KIND=JPIM)   :: g_u
 INTEGER(KIND=JPIM)   :: g_v
 INTEGER(KIND=JPIM)   :: g_los
 INTEGER(KIND=JPIM)   :: g_t
 INTEGER(KIND=JPIM)   :: g_ps
 INTEGER(KIND=JPIM)   :: g_z
 INTEGER(KIND=JPIM)   :: g_vt
 INTEGER(KIND=JPIM)   :: g_td
 INTEGER(KIND=JPIM)   :: g_rh
 INTEGER(KIND=JPIM)   :: g_q
 INTEGER(KIND=JPIM)   :: g_vs
 INTEGER(KIND=JPIM)   :: g_ds
 INTEGER(KIND=JPIM)   :: g_u10m
 INTEGER(KIND=JPIM)   :: g_v10m
 INTEGER(KIND=JPIM)   :: g_t2m
 INTEGER(KIND=JPIM)   :: g_td2m
 INTEGER(KIND=JPIM)   :: g_rh2m
 INTEGER(KIND=JPIM)   :: g_rr
 INTEGER(KIND=JPIM)   :: g_trtr
 INTEGER(KIND=JPIM)   :: g_sdepth
 INTEGER(KIND=JPIM)   :: g_sfall
 INTEGER(KIND=JPIM)   :: g_ptend
 INTEGER(KIND=JPIM)   :: g_dz
 INTEGER(KIND=JPIM)   :: g_pwc
 INTEGER(KIND=JPIM)   :: g_rawbt
 INTEGER(KIND=JPIM)   :: g_rawbt_clear
 INTEGER(KIND=JPIM)   :: g_rawbt_cloudy
 INTEGER(KIND=JPIM)   :: g_rawra
 INTEGER(KIND=JPIM)   :: g_cllqw
 INTEGER(KIND=JPIM)   :: g_scatss
 INTEGER(KIND=JPIM)   :: g_scatu
 INTEGER(KIND=JPIM)   :: g_scatv
 INTEGER(KIND=JPIM)   :: g_o3lay
 INTEGER(KIND=JPIM)   :: g_height
 INTEGER(KIND=JPIM)   :: g_apdss
 INTEGER(KIND=JPIM)   :: g_vv
 INTEGER(KIND=JPIM)   :: g_ww
 INTEGER(KIND=JPIM)   :: g_w
 INTEGER(KIND=JPIM)   :: g_w2
 INTEGER(KIND=JPIM)   :: g_n
 INTEGER(KIND=JPIM)   :: g_nn
 INTEGER(KIND=JPIM)   :: g_nh
 INTEGER(KIND=JPIM)   :: g_cl
 INTEGER(KIND=JPIM)   :: g_cm
 INTEGER(KIND=JPIM)   :: g_ch
 INTEGER(KIND=JPIM)   :: g_cpt
 INTEGER(KIND=JPIM)   :: g_tsts
 INTEGER(KIND=JPIM)   :: g_bend_angle
 INTEGER(KIND=JPIM)   :: g_aerod
 INTEGER(KIND=JPIM)   :: g_chem1
 INTEGER(KIND=JPIM)   :: g_chem2
 INTEGER(KIND=JPIM)   :: g_chem3
 INTEGER(KIND=JPIM)   :: g_chem4
 INTEGER(KIND=JPIM)   :: g_chem5
 INTEGER(KIND=JPIM)   :: g_ghg1
 INTEGER(KIND=JPIM)   :: g_ghg2
 INTEGER(KIND=JPIM)   :: g_ghg3
 INTEGER(KIND=JPIM)   :: g_rao
 INTEGER(KIND=JPIM)   :: g_od
 INTEGER(KIND=JPIM)   :: g_rfltnc
 INTEGER(KIND=JPIM)   :: g_nsoilm
 INTEGER(KIND=JPIM)   :: g_soilm
 INTEGER(KIND=JPIM)   :: g_prc
 INTEGER(KIND=JPIM)   :: g_lnprc
#ifdef BOM
 INTEGER(KIND=JPIM)   :: g_flgt_phase
#endif
 INTEGER(KIND=JPIM)   :: g_cod
 INTEGER(KIND=JPIM)   :: g_bt_real
 INTEGER(KIND=JPIM)   :: g_bt_imaginary
 INTEGER(KIND=JPIM)   :: g_libksc
 INTEGER(KIND=JPIM)   :: g_ralt_swh
 INTEGER(KIND=JPIM)   :: g_ralt_sws
 INTEGER(KIND=JPIM)   :: g_binary_snow_cover
 INTEGER(KIND=JPIM)   :: g_humidity_mixing_ratio
 INTEGER(KIND=JPIM)   :: g_airframe_icing
 INTEGER(KIND=JPIM)   :: g_turbulence_index
 INTEGER(KIND=JPIM)   :: g_q2m

contains 

subroutine getval(h)
USE PARKIND1  ,ONLY : JPIM     ,JPRD
 

 implicit none

INTEGER(KIND=JPIM), intent(in) :: h

#ifndef B2O_STANDALONE
g_gpheight=ODB_getval(h,'$gpheight')
g_pressure=ODB_getval(h,'$pressure')
g_tovs_cha=ODB_getval(h,'$tovs_cha')
g_scat_cha=ODB_getval(h,'$scat_cha')
g_imp_param=ODB_getval(h,'$imp_param')
g_cha_number=ODB_getval(h,'$cha_number')
g_cha_wavelength=ODB_getval(h,'$cha_wavelength')
g_cha_frequency=ODB_getval(h,'$cha_frequency')
g_dd=ODB_getval(h,'$dd')
g_ff=ODB_getval(h,'$ff')
g_u=ODB_getval(h,'$u')
g_v=ODB_getval(h,'$v')
g_los=ODB_getval(h,'$los')
g_t=ODB_getval(h,'$t')
g_ps=ODB_getval(h,'$ps')
g_z=ODB_getval(h,'$z')
g_vt=ODB_getval(h,'$vt')
g_td=ODB_getval(h,'$td')
g_rh=ODB_getval(h,'$rh')
g_q=ODB_getval(h,'$q')
g_vs=ODB_getval(h,'$vs')
g_ds=ODB_getval(h,'$ds')
g_u10m=ODB_getval(h,'$u10m')
g_v10m=ODB_getval(h,'$v10m')
g_t2m=ODB_getval(h,'$t2m')
g_td2m=ODB_getval(h,'$td2m')
g_rh2m=ODB_getval(h,'$rh2m')
g_rr=ODB_getval(h,'$rr')
g_trtr=ODB_getval(h,'$trtr')
g_sdepth=ODB_getval(h,'$sdepth')
g_sfall=ODB_getval(h,'$sfall')
g_ptend=ODB_getval(h,'$ptend')
g_dz=ODB_getval(h,'$dz')
g_pwc=ODB_getval(h,'$pwc')
g_rawbt=ODB_getval(h,'$rawbt')
g_rawra=ODB_getval(h,'$rawra')
g_cllqw=ODB_getval(h,'$cllqw')
g_scatss=ODB_getval(h,'$scatss')
g_scatu=ODB_getval(h,'$scatu')
g_scatv=ODB_getval(h,'$scatv')
g_o3lay=ODB_getval(h,'$o3lay')
g_height=ODB_getval(h,'$height')
g_ww=ODB_getval(h,'$ww')
g_w=ODB_getval(h,'$w')
g_w2=ODB_getval(h,'$w2')
g_n=ODB_getval(h,'$n')
g_nn=ODB_getval(h,'$nn')
g_nh=ODB_getval(h,'$nh')
g_cl=ODB_getval(h,'$cl')
g_cm=ODB_getval(h,'$cm')
g_ch=ODB_getval(h,'$ch')
g_cpt=ODB_getval(h,'$cpt')
g_tsts=ODB_getval(h,'$tsts')
g_vv=ODB_getval(h,'$vv')
g_apdss=ODB_getval(h,'$apdss')
g_bend_angle=ODB_getval(h,'$bend_angle')
g_aerod=ODB_getval(h,'$aerod')
g_chem1=ODB_getval(h,'$chem1')
g_chem2=ODB_getval(h,'$chem2')
g_chem3=ODB_getval(h,'$chem3')
g_chem4=ODB_getval(h,'$chem4')
g_chem5=ODB_getval(h,'$chem5')
g_ghg1=ODB_getval(h,'$ghg1')
g_ghg2=ODB_getval(h,'$ghg2')
g_ghg3=ODB_getval(h,'$ghg3')
g_rao=ODB_getval(h,'$rao')
g_od=ODB_getval(h,'$od')
g_rfltnc=ODB_getval(h,'$rfltnc')
g_nsoilm=ODB_getval(h,'$nsoilm')
g_soilm=ODB_getval(h,'$soilm')
g_prc=ODB_getval(h,'$prc')
g_lnprc=ODB_getval(h,'$lnprc')
#ifdef BOM
g_flgt_phase = ODB_getval(h,'$flgt_phase')
#endif
g_cod=ODB_getval(h,'$cod')
g_bt_real=ODB_getval(h,'$bt_real')
g_bt_imaginary=ODB_getval(h,'$bt_imaginary')
g_libksc=ODB_getval(h,'$libksc')
g_ralt_swh=ODB_getval(h,'$ralt_swh')
g_ralt_sws=ODB_getval(h,'$ralt_sws')
g_rawbt_clear=ODB_getval(h,'$rawbt_clear')
g_rawbt_cloudy=ODB_getval(h,'$rawbt_cloudy') 
g_binary_snow_cover=ODB_getval(h,'$binary_snow_cover') 
g_humidity_mixing_ratio=ODB_getval(h, '$humidity_mixing_ratio')
g_airframe_icing=ODB_getval(h, '$airframe_icing')
g_turbulence_index=ODB_getval(h, '$turbulence_index')
g_q2m=ODB_getval(h, "$q2m")

#else

g_pressure = 1
g_gpheight = 2
g_tovs_cha = 3
g_scat_cha = 4
g_imp_param = 6
g_cha_number = 7
g_cha_wavelength = 8
g_cha_frequency = 9

g_u  =  3
g_v  =  4
g_z  =  1
g_dz  =  57
g_rh  =  29
g_pwc  =  9
g_rh2m  =  58
g_t  =  2
g_td  =  59
g_t2m  =  39
g_td2m  =  40
g_ptend  =  30
g_w  =  60
g_ww  =  61
g_vv  =  62
g_ch  =  63
g_cm  =  64
g_cl  =  65
g_nh  =  66
g_nn  =  67
g_sdepth  =  71
g_trtr  =  79
g_rr  =  80
g_vs  =  82
g_ds  =  83
g_n  =  91
g_sfall  =  92
g_ps  =  110
g_dd  =  111
g_ff  =  112
g_rawbt  =  119
g_rawra  =  120
g_scatss  =  122
g_u10m  =  41
g_v10m  =  42
g_cllqw  =  123
g_scatv  =  124
g_scatu  =  125
g_q  =  7
g_vt  =  56
g_o3lay  =  206
g_height  =  156
g_w2  =  160
g_cpt  =  130
g_tsts  =  12
g_apdss  =  128
g_bend_angle  =  162
g_los  =  187
g_aerod  =  174
g_chem1  =  181
g_chem2  =  182
g_chem3  =  183
g_chem4  =  184
g_chem5  =  185
g_cod  =  175
g_rao  =  176
g_od  =  177
g_rfltnc  =  178
g_nsoilm  =  179
g_soilm  =  180
#ifdef BOM
g_flgt_phase  =  201
#endif
g_ghg1  =  186
g_ghg2  =  188
g_ghg3  =  189
g_bt_real  =  190
g_bt_imaginary  =  191
g_prc  =  202
g_lnprc  =  203
g_libksc  =  222
g_ralt_swh  =  220
g_ralt_sws  =  221
g_rawbt_clear  =  193
g_rawbt_cloudy  =  194
g_binary_snow_cover = 223
g_humidity_mixing_ratio = 226
g_airframe_icing = 227
g_turbulence_index = 228
g_q2m = 281

#endif

end subroutine getval
END MODULE getval_module
