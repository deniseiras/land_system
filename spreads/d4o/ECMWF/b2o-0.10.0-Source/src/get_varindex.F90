subroutine get_varindex(handle, h)
USE PARKIND1  ,ONLY : JPIM     ,JPRD
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK


!**** *get_varindex*


!     Purpose.
!     --------




!**   Interface.
!     ----------


!     Method.
!     -------





!     Externals.
!     ----------



!     Reference.
!     ----------



!     Author.
!     -------

!          M. Dragosavac    *ECMWF*       2003


!     Modifications.
!     --------------

!          NONE.
!         2007-09-10 - K. Scipal - introduced ascat soil moisture & flags

!     2007-10-10  D. Tan        Naming consistency for aeolus_2b table
!     2008-09-17  D. Tan        Naming consistency for aeolus_1b table
!     2008-11-06  D. Tan        More aeolus_hdr and aeolus_1b entries
!     2010-10-28  J. Munoz      Naming consistency for smos table
!     2011-11-22  C. Lupu       More Met-9 ASR entries
!     2012-04-13  M. Rennie     Remove Aeolus
!     2017-11-03  M. Rennie     Add aeolus_hdr and aeolus_l2c tables
!     2018-01-10  M. Rennie     Add new sat table entries: range and arg_lat
!                               and aeolus_l2b
!     2018-04-13  K. Lonitz     Add sat_lsm_fov
!---------------------------------------------------------------------------

use b2o_internal
USE varindex_module

implicit none

type(b2o_handle_t), intent(inout) :: handle
INTEGER(KIND=JPIM), intent(in)  :: h

INTEGER(KIND=JPIM)              :: i, j
CHARACTER(LEN=4)                :: c_up_no
REAL(KIND=JPRD) :: ZHOOK_HANDLE

!   !-- Get ODBtable components indices for hdr

IF (LHOOK) CALL DR_HOOK('GET_VARINDEX',0,ZHOOK_HANDLE)

hdrname=' '
hdrname( 1)='subtype'
hdrname( 2)='bufrtype'
hdrname( 3)='date'
hdrname( 4)='time'
hdrname( 5)='rdbdate'
hdrname( 6)='rdbtime'
hdrname( 7)='statid'
hdrname( 8)='report_rdbflag'
hdrname( 9)='lat'
hdrname(10)='lon'
hdrname(11)='numlev'
hdrname(12)='seqno'
hdrname(13)='subsetno'
hdrname(14)='retrtype'
hdrname(15)='source'
hdrname(16)='distribtype'
hdrname(17)='groupid'
hdrname(18)='reportype'
hdrname(19)='obstype'
hdrname(20)='codetype'
hdrname(21)='sensor'
hdrname(22)='stalt'
hdrname(23)='instrument_type'
hdrname(24)='report_event1'
hdrname(25)='reportno'
hdrname(26)='report_status'
hdrname(27)='wigosid_1'
hdrname(28)='wigosid_2'
hdrname(29)='wigosid_3'
hdrname(30)='wigosid_4'

call b2o_varindex(handle, h, '@hdr',hdrname(1:hdrlen), hdridx(1:hdrlen))

hdr_subtype       = hdridx(1)
hdr_bufrtype      = hdridx(2)
hdr_date          = hdridx(3)
hdr_time          = hdridx(4)
hdr_rdbdate       = hdridx(5)
hdr_rdbtime       = hdridx(6)
hdr_statid        = hdridx(7)
hdr_report_rdbflag= hdridx(8)
hdr_lat           = hdridx(9)
hdr_lon           = hdridx(10)
hdr_numlev        = hdridx(11)
hdr_seqno         = hdridx(12)
hdr_subsetno      = hdridx(13)
hdr_retrtype      = hdridx(14)
hdr_source        = hdridx(15)
hdr_distribtype   = hdridx(16)
hdr_groupid       = hdridx(17)
hdr_reportype     = hdridx(18)
hdr_obstype       = hdridx(19)
hdr_codetype      = hdridx(20)
hdr_sensor        = hdridx(21)
hdr_stalt         = hdridx(22)
hdr_instrument_type = hdridx(23)
hdr_report_event1 = hdridx(24)
hdr_reportno      = hdridx(25)
hdr_report_status = hdridx(26)
hdr_wigosid(1)    = hdridx(27)
hdr_wigosid(2)    = hdridx(28)
hdr_wigosid(3)    = hdridx(29)
hdr_wigosid(4)    = hdridx(30)

!-- Get ODBtable components indices for body

bodyname=' '
bodyname( 1)='varno'
bodyname( 2)='vertco_type'
bodyname( 3)='datum_rdbflag'
bodyname( 4)='entryno'
bodyname( 5)='vertco_reference_1'
bodyname( 6)='vertco_reference_2'
bodyname( 7)='obsvalue'
bodyname( 8)='nlayer'
bodyname( 9)='biascorr'
bodyname(10)='tbcorr'
bodyname(11)='wdeff_bcorr'
bodyname(12)='an_depar'
bodyname(13)='fg_depar'
bodyname(14)='datum_status'
bodyname(15)='datum_event1'


call b2o_varindex(handle, h, '@body', bodyname(1:bodylen), bodyidx(1:bodylen))

body_varno           = bodyidx( 1)
body_vertco_type     = bodyidx( 2)
body_datum_rdbflag   = bodyidx( 3)
body_entryno         = bodyidx( 4)
body_vertco_reference_1 = bodyidx( 5)
body_vertco_reference_2 = bodyidx( 6)
body_obsvalue        = bodyidx( 7)
body_nlayer          = bodyidx( 8)
body_biascorr        = bodyidx( 9)
body_tbcorr          = bodyidx(10)
body_wdeff_bcorr     = bodyidx(11)
body_an_depar        = bodyidx(12)
body_fg_depar        = bodyidx(13)
body_datum_status    = bodyidx(14)
body_datum_event1    = bodyidx(15)


!-- Get ODBtable components for errstat

errstatname=' '
errstatname( 1)='final_obs_error'
errstatname( 2)='obs_error'
errstatname( 3)='repres_error'
errstatname( 4)='pers_error'
errstatname( 5)='fg_error'
errstatname( 6)='obs_ak_error'

call b2o_varindex(handle, h, '@errstat', errstatname(1:errstatlen), errstatidx(1:errstatlen))

errstat_final_obs_error = errstatidx( 1)
errstat_obs_error       = errstatidx( 2)
errstat_repres_error    = errstatidx( 3)
errstat_pers_error      = errstatidx( 4)
errstat_fg_error        = errstatidx( 5)
errstat_obs_ak_error    = errstatidx( 6)


!-- Get ODBtable components indices for sat

satname=' '
satname(1)='satellite_identifier'
satname(2)='gen_centre'
satname(3)='gen_subcentre'
satname(4)='datastream'
satname(5)='solar_zenith'
satname(6)='solar_azimuth'
satname(7)='zenith'
satname(8)='azimuth'
satname(9)='satellite_instrument'
satname(10)='range'
satname(11)='arg_lat'
satname(12)='lsm_fov'

call b2o_varindex(handle, h, '@sat', satname(1:satlen), satidx(1:satlen))

sat_satellite_identifier = satidx(1)
sat_gen_centre    = satidx(2)
sat_gen_subcentre = satidx(3)
sat_datastream    = satidx(4)
sat_solar_zenith  = satidx(5)
sat_solar_azimuth = satidx(6)
sat_zenith        = satidx(7)
sat_azimuth       = satidx(8)
sat_satellite_instrument = satidx(9)
sat_range         = satidx(10)
sat_arg_lat       = satidx(11)
sat_lsm_fov       = satidx(12) 


!-- Get ODBtable components for conv

convname=' '
convname( 1)='flight_phase'
convname( 2)='anemoht'
convname( 3)='station_type'
convname( 4)='sonde_type'
convname( 5)='baroht'
convname( 6)='flight_dp_o_dt'
convname( 7)='heading'
convname( 8)='aircraft_type'

call b2o_varindex(handle, h, '@conv', convname(1:convlen), convidx(1:convlen))

conv_flight_phase           = convidx( 1)
conv_anemoht                = convidx( 2)
conv_station_type           = convidx( 3)
conv_sonde_type             = convidx( 4)
conv_baroht                 = convidx( 5)
conv_flight_dp_o_dt         = convidx( 6)
conv_heading                = convidx( 7)
conv_aircraft_type          = convidx( 8)

!-- Get ODBtable components for conv_body

conv_bodyname=' '
conv_bodyname( 1)='ppcode'
conv_bodyname( 2)='level'
conv_bodyname( 3)='datum_qcflag'

call b2o_varindex(handle, h, '@conv_body', conv_bodyname(1:conv_bodylen), conv_bodyidx(1:conv_bodylen))

conv_body_ppcode                  = conv_bodyidx( 1)
conv_body_level                   = conv_bodyidx( 2)
conv_body_datum_qcflag            = conv_bodyidx( 3)

!-- Get ODBtable components for radiance

radname=' '
radname( 1)='orbit'
radname( 2)='scanline'
radname( 3)='scanpos'
radname( 4)='typesurf'
radname( 5)='cldcover'
radname( 6)='corr_version'
radname( 7)='asr_pclear'
radname( 8)='asr_pcloudy'
radname( 9)='asr_pcloudy_low'
radname(10)='asr_pcloudy_middle'
radname(11)='asr_pcloudy_high'

call b2o_varindex(handle, h, '@radiance', radname(1:radlen), radidx(1:radlen))

radiance_orbit                        = radidx( 1)
radiance_scanline                     = radidx( 2)
radiance_scanpos                      = radidx( 3)
radiance_typesurf                     = radidx( 4)
radiance_cldcover                     = radidx( 5)
radiance_corr_version                 = radidx( 6)
radiance_asr_pclear                   = radidx( 7)
radiance_asr_pcloudy                  = radidx( 8)
radiance_asr_pcloudy_low              = radidx( 9)
radiance_asr_pcloudy_middle           = radidx(10)
radiance_asr_pcloudy_high             = radidx(11)

!-- Get ODBtable components for radiance_body
radbodyname=' '
radbodyname(1)='csr_pclear'
radbodyname(2)='cold_nedt'
radbodyname(3)='warm_nedt'
radbodyname(4)='channel_qc'
radbodyname(5)='zenith_by_channel'
call b2o_varindex(handle, h, '@radiance_body', radbodyname(1:radbodylen), radbodyidx(1:radbodylen))

radiance_body_csr_pclear = radbodyidx(1)
radiance_body_cold_nedt  = radbodyidx(2)
radiance_body_warm_nedt  = radbodyidx(3)
radiance_body_channel_qc = radbodyidx(4)
radiance_body_zenith_by_channel = radbodyidx(5)

!   Get ODBtable component indices for collocated imager information

collocated_imager_infoname=' '
collocated_imager_infoname( 1)='provider_qc'
collocated_imager_infoname( 2)='avhrr_max_cluster'
collocated_imager_infoname( 3)='avhrr_mean_ir'
collocated_imager_infoname( 4)='avhrr_stddev_ir'
collocated_imager_infoname( 5)='avhrr_mean_vis'
collocated_imager_infoname( 6)='avhrr_stddev_vis'
collocated_imager_infoname( 7)='avhrr_coldest_cluster_ir'
collocated_imager_infoname( 8)='avhrr_warmest_cluster_ir'
collocated_imager_infoname( 9)='avhrr_largest_cluster_ir'
collocated_imager_infoname(10)='avhrr_num_clusters'
collocated_imager_infoname(11)='avhrr_stddev_ir2'
i = 11
do j = 1, max_avhrr
   i = i + 1
   c_up_no = ' '
   write (c_up_no,'(i0)') j
   collocated_imager_infoname(i)='avhrr_frac_cl'//trim(c_up_no)
end do
do j = 1, max_avhrr
   i = i + 1
   c_up_no = ' '
   write (c_up_no,'(i0)') j
   collocated_imager_infoname(i)='avhrr_m_ir1_cl'//trim(c_up_no)
end do
do j = 1, max_avhrr
   i = i + 1
   c_up_no = ' '
   write (c_up_no,'(i0)') j
   collocated_imager_infoname(i)='avhrr_m_ir2_cl'//trim(c_up_no)
end do
collocated_imager_infoname(i+1)='avhrr_fg_ir1'
collocated_imager_infoname(i+2)='avhrr_fg_ir2'
collocated_imager_infoname(i+3)='avhrr_cloud_flag'

call b2o_varindex(handle, h, '@collocated_imager_information', collocated_imager_infoname(1:collocated_imager_info_len), &
                      collocated_imager_infoidx(1:collocated_imager_info_len))

collocated_imager_information_provider_qc               = collocated_imager_infoidx(1)
collocated_imager_information_avhrr_max_cluster         = collocated_imager_infoidx(2)
collocated_imager_information_avhrr_mean_ir             = collocated_imager_infoidx(3)
collocated_imager_information_avhrr_stddev_ir           = collocated_imager_infoidx(4)
collocated_imager_information_avhrr_mean_vis            = collocated_imager_infoidx(5)
collocated_imager_information_avhrr_stddev_vis          = collocated_imager_infoidx(6)
collocated_imager_information_avhrr_coldest_cluster_ir  = collocated_imager_infoidx(7)
collocated_imager_information_avhrr_warmest_cluster_ir  = collocated_imager_infoidx(8)
collocated_imager_information_avhrr_largest_cluster_ir  = collocated_imager_infoidx(9)
collocated_imager_information_avhrr_num_clusters        = collocated_imager_infoidx(10)
collocated_imager_information_avhrr_stddev_ir2          = collocated_imager_infoidx(11)
i = 11
do j = 1, max_avhrr
  i = i + 1
  collocated_imager_information_avhrr_frac_cl(j)        = collocated_imager_infoidx(i)
end do
do j = 1, max_avhrr
  i = i + 1
  collocated_imager_information_avhrr_m_ir1_cl(j)       = collocated_imager_infoidx(i)
end do
do j = 1, max_avhrr
  i = i + 1
  collocated_imager_information_avhrr_m_ir2_cl(j)       = collocated_imager_infoidx(i)
end do
collocated_imager_information_avhrr_fg_ir1              = collocated_imager_infoidx(i+1)
collocated_imager_information_avhrr_fg_ir2              = collocated_imager_infoidx(i+2)
collocated_imager_information_avhrr_cloud_flag          = collocated_imager_infoidx(i+3)

!   Get ODBtable component indices for satob

satobname=' '
satobname(1)='comp_method'
satobname(2)='instdata'
satobname(3)='dataproc'
satobname(4)='qi_fc'
satobname(5)='rff'
satobname(6)='qi_nofc'
satobname(7)='segment_size_x'
satobname(8)='segment_size_y'
satobname(9)='tb'
satobname(10)='chan_freq'
satobname(11)='height_assignment_method'
satobname(12)='tracer_correlation_method'
satobname(13)='land_sea'
satobname(14)='ee'

call b2o_varindex(handle, h, '@satob', satobname(1:satoblen), satobidx(1:satoblen))

satob_comp_method   = satobidx(1)
satob_instdata      = satobidx(2)
satob_dataproc      = satobidx(3)
satob_qi_fc         = satobidx(4)
satob_rff           = satobidx(5)
satob_qi_nofc       = satobidx(6)
satob_segment_size_x = satobidx(7)
satob_segment_size_y = satobidx(8)
satob_tb            = satobidx(9)
satob_chan_freq     = satobidx(10)
satob_height_assignment_method = satobidx(11)
satob_tracer_correlation_method = satobidx(12)
satob_land_sea      = satobidx(13)
satob_ee            = satobidx(14)

!-- Get ODBtable components for scatt

scattname=' '
scattname( 1)='cellno'
scattname( 2)='nretr_amb'
scattname( 3)='prodflag'
scattname( 4)='wvc_qf'

call b2o_varindex(handle, h, '@scatt', scattname(1:scattlen), scattidx(1:scattlen))

scatt_cellno     = scattidx( 1)
scatt_nretr_amb  = scattidx( 2)
scatt_prodflag   = scattidx( 3)
scatt_wvc_qf     = scattidx( 4)

!-- Get ODBtable components for scatt_body

scatt_bodyname=' '
scatt_bodyname( 1)='azimuth'
scatt_bodyname( 2)='incidence'
scatt_bodyname( 3)='kp'
scatt_bodyname( 4)='invresid'
scatt_bodyname( 5)='mpc'
scatt_bodyname( 6)='kp_qf'
scatt_bodyname( 7)='sigma0_qf'
scatt_bodyname( 8)='sigma0_sm'
scatt_bodyname( 9)='soilmoist_sd'
scatt_bodyname(10)='soilmoist_cf'
scatt_bodyname(11)='soilmoist_pf'
scatt_bodyname(12)='land_fraction'
scatt_bodyname(13)='wetland_fraction'
scatt_bodyname(14)='topo_complex'

call b2o_varindex(handle, h, '@scatt_body', scatt_bodyname(1:scatt_bodylen), scatt_bodyidx(1:scatt_bodylen))

scatt_body_azimuth    = scatt_bodyidx( 1)
scatt_body_incidence  = scatt_bodyidx( 2)
scatt_body_kp         = scatt_bodyidx( 3)
scatt_body_invresid   = scatt_bodyidx( 4)
scatt_body_mpc        = scatt_bodyidx( 5)
scatt_body_kp_qf      = scatt_bodyidx( 6)
scatt_body_sigma0_qf  = scatt_bodyidx( 7)
scatt_body_sigma0_sm  = scatt_bodyidx( 8)
scatt_body_soilmoist_sd = scatt_bodyidx( 9)
scatt_body_soilmoist_cf = scatt_bodyidx(10)
scatt_body_soilmoist_pf = scatt_bodyidx(11)
scatt_body_land_fraction = scatt_bodyidx(12)
scatt_body_wetland_fraction = scatt_bodyidx(13)
scatt_body_topo_complex = scatt_bodyidx(14)

!-- Get ODBtable components for resat

resatname=' '
resatname( 1)='instrument_type'
resatname( 2)='product_type'
i = 2
do j = 1, n_fov_corners
   i = i + 1
   c_up_no = ' '
   write (c_up_no,'(i0)') j
   resatname(i)='lat_fovcorner_'//trim(c_up_no)
end do
do j = 1, n_fov_corners
   i = i + 1
   c_up_no = ' '
   write (c_up_no,'(i0)') j
   resatname(i)='lon_fovcorner_'//trim(c_up_no)
end do
resatname(i+1)='solar_elevation'
resatname(i+2)='scanpos'
resatname(i+3)='cloud_cover'
resatname(i+4)='cloud_top_press'
resatname(i+5)='quality_retrieval'
resatname(i+6)='number_layers'
resatname(i+7)='snow_ice_indicator'
resatname(i+8)='surface_type_indicator'
resatname(i+9)='methane_correction'
resatname(i+10)='surface_height'
resatname(i+11)='retrsource'

call b2o_varindex(handle, h, '@resat', resatname(1:resatlen), resatidx(1:resatlen))

resat_instrument_type        = resatidx(1)
resat_product_type           = resatidx(2)
i = 2
do j = 1, n_fov_corners
   i = i + 1
   resat_lat_fovcorner(j)    = resatidx(i)
end do
do j = 1, n_fov_corners
   i = i + 1
   resat_lon_fovcorner(j)    = resatidx(i)
end do
resat_solar_elevation        = resatidx(i+1)
resat_scanpos                = resatidx(i+2)
resat_cloud_cover            = resatidx(i+3)
resat_cloud_top_press        = resatidx(i+4)
resat_quality_retrieval      = resatidx(i+5)
resat_number_layers          = resatidx(i+6)
resat_snow_ice_indicator     = resatidx(i+7)
resat_surface_type_indicator = resatidx(i+8)
resat_methane_correction     = resatidx(i+9)
resat_surface_height         = resatidx(i+10)
resat_retrsource             = resatidx(i+11)

!-- Get ODBtable components for resat_ak

resat_akname=' '
resat_akname( 1)='nak'
do i = 1, resat_max_nak
   c_up_no=' '
   write(c_up_no,'(i4)') i
   resat_akname(i+1)='wak_'//trim(adjustl(c_up_no))
   resat_akname(i+1+resat_max_nak)='pak_'//trim(adjustl(c_up_no))
   resat_akname(i+1+2*resat_max_nak)='apak_'//trim(adjustl(c_up_no))
end do
call b2o_varindex(handle, h, '@resat_averaging_kernel', resat_akname(1:resat_aklen), resat_akidx(1:resat_aklen))
resat_averaging_kernel_nak    = resat_akidx( 1)
do i = 1, resat_max_nak
   resat_averaging_kernel_wak(i) = resat_akidx(i+1)
   resat_averaging_kernelm_pak(i) = resat_akidx(i+1+resat_max_nak)
   resat_averaging_kernelm_apak(i) = resat_akidx(i+1+2*resat_max_nak)
end do

!-- Get ODBtable components for gnssro

gnssro_name=' '
gnssro_name(1)='radcurv'
gnssro_name(2)='undulation'

call b2o_varindex(handle, h, '@gnssro' , gnssro_name(1:gnssro_len), gnssro_idx(1:gnssro_len))

gnssro_radcurv = gnssro_idx( 1)
gnssro_undulation=gnssro_idx( 2)

!-- Get ODBtable components for smos

smosname=' '
smosname( 1)='snapshot_id'
smosname( 2)='grid_point_id'
smosname( 3)='electron_count'
smosname( 4)='sun_bt'
smosname( 5)='snapshot_acc'
smosname( 6)='rad_acc_pure'
smosname( 7)='rad_acc_cross'
smosname( 8)='footprint_axis_1'
smosname( 9)='footprint_axis_2'
smosname(10)='polarisation'
smosname(11)='water_fraction'
smosname(12)='incidence_angle'
smosname(13)='faradey_rot_angle'
smosname(14)='pixel_rot_angle'
smosname(15)='info'
smosname(16)='snapshot_quality'

call b2o_varindex(handle, h, '@smos' , smosname(1:smoslen), smosidx(1:smoslen))

smos_snapshot_id = smosidx( 1)
smos_grid_point_id = smosidx( 2)
smos_electron_count = smosidx( 3)
smos_sun_bt = smosidx( 4)
smos_snapshot_acc = smosidx( 5)
smos_rad_acc_pure = smosidx( 6)
smos_rad_acc_cross = smosidx( 7)
smos_footprint_axis_1 = smosidx( 8)
smos_footprint_axis_2 = smosidx( 9)
smos_polarisation = smosidx( 10)
smos_water_fraction = smosidx(11)
smos_incidence_angle = smosidx(12)
smos_faradey_rot_angle = smosidx(13)
smos_pixel_rot_angle = smosidx(14)
smos_info = smosidx(15)
smos_snapshot_quality = smosidx(16)

!-- Get ODBtable components for aeolus_hdr

aeolus_hdrname=' '
aeolus_hdrname( 1)='aeolus_hdrflag'

call b2o_varindex(handle, h, '@aeolus_hdr' , aeolus_hdrname(1:aeolus_hdrlen), aeolus_hdridx(1:aeolus_hdrlen))

aeolus_hdr_aeolus_hdrflag = aeolus_hdridx( 1)

!-- Get ODBtable components for aeolus_l2c

aeolus_l2cname=' '
aeolus_l2cname( 1)='hlos_ob_err'
aeolus_l2cname( 2)='hlos_fg'
aeolus_l2cname( 3)='u_fg'
aeolus_l2cname( 4)='u_fg_err'
aeolus_l2cname( 5)='v_fg'
aeolus_l2cname( 6)='v_fg_err'
aeolus_l2cname( 7)='hlos_fg_err'
aeolus_l2cname( 8)='hlos_an'
aeolus_l2cname( 9)='hlos_an_err'
aeolus_l2cname(10)='u_an'
aeolus_l2cname(11)='v_an'

call b2o_varindex(handle, h, '@aeolus_l2c' , aeolus_l2cname(1:aeolus_l2clen), aeolus_l2cidx(1:aeolus_l2clen))

aeolus_l2c_hlos_ob_err = aeolus_l2cidx( 1)
aeolus_l2c_hlos_fg     = aeolus_l2cidx( 2)
aeolus_l2c_u_fg        = aeolus_l2cidx( 3)
aeolus_l2c_u_fg_err    = aeolus_l2cidx( 4)
aeolus_l2c_v_fg        = aeolus_l2cidx( 5)
aeolus_l2c_v_fg_err    = aeolus_l2cidx( 6)
aeolus_l2c_hlos_fg_err = aeolus_l2cidx( 7)
aeolus_l2c_hlos_an     = aeolus_l2cidx( 8)
aeolus_l2c_hlos_an_err = aeolus_l2cidx( 9)
aeolus_l2c_u_an        = aeolus_l2cidx(10)
aeolus_l2c_v_an        = aeolus_l2cidx(11)

!-- Get ODBtable components for aeolus_l2b

aeolus_l2bname=' '
aeolus_l2bname( 1)='t_ref'
aeolus_l2bname( 2)='p_ref'
aeolus_l2bname( 3)='beta'
aeolus_l2bname( 4)='dhlos_dt'
aeolus_l2bname( 5)='dhlos_dp'
aeolus_l2bname( 6)='dhlos_dbeta'
aeolus_l2bname( 7)='horiz_length'
aeolus_l2bname( 8)='vert_length'
aeolus_l2bname( 9)='conf_flag'

call b2o_varindex(handle, h, '@aeolus_l2b' , aeolus_l2bname(1:aeolus_l2blen), aeolus_l2bidx(1:aeolus_l2blen))

aeolus_l2b_t_ref        = aeolus_l2bidx( 1)
aeolus_l2b_p_ref        = aeolus_l2bidx( 2)
aeolus_l2b_beta         = aeolus_l2bidx( 3)
aeolus_l2b_dhlos_dt     = aeolus_l2bidx( 4)
aeolus_l2b_dhlos_dp     = aeolus_l2bidx( 5)
aeolus_l2b_dhlos_dbeta  = aeolus_l2bidx( 6)
aeolus_l2b_horiz_length = aeolus_l2bidx( 7)
aeolus_l2b_vert_length  = aeolus_l2bidx( 8)
aeolus_l2b_conf_flag    = aeolus_l2bidx( 9)

IF (LHOOK) CALL DR_HOOK('GET_VARINDEX',1,ZHOOK_HANDLE)

end subroutine get_varindex
