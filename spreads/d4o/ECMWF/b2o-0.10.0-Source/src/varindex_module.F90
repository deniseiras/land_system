MODULE varindex_module
USE PARKIND1  ,ONLY : JPIM

  implicit none

!   hdr table
!   ---------
    INTEGER(KIND=JPIM), parameter :: hdrlen=30

    character(len=64) , dimension(hdrlen)  :: hdrname
    INTEGER(KIND=JPIM)           , dimension(hdrlen)      :: hdridx
    INTEGER(KIND=JPIM)                                    :: hdr_subtype, hdr_bufrtype
    INTEGER(KIND=JPIM)                                    :: hdr_date, hdr_time, hdr_statid
    INTEGER(KIND=JPIM)                                    :: hdr_rdbdate, hdr_rdbtime
    INTEGER(KIND=JPIM)                                    :: hdr_report_rdbflag, hdr_lat, hdr_lon, hdr_numlev
    INTEGER(KIND=JPIM)                                    :: hdr_seqno, hdr_subsetno
    INTEGER(KIND=JPIM)                                    :: hdr_retrtype, hdr_source
    INTEGER(KIND=JPIM)                                    :: hdr_distribtype
    INTEGER(KIND=JPIM)                                    :: hdr_groupid, hdr_reportype, hdr_obstype, hdr_codetype, hdr_sensor
    INTEGER(KIND=JPIM)                                    :: hdr_stalt
    INTEGER(KIND=JPIM)                                    :: hdr_instrument_type
    INTEGER(KIND=JPIM)                                    :: hdr_report_event1
    INTEGER(KIND=JPIM)                                    :: hdr_reportno
    INTEGER(KIND=JPIM)                                    :: hdr_report_status
    INTEGER(KIND=JPIM)                                    :: hdr_wigosid(4)

!   body table
!   ----------

    INTEGER(KIND=JPIM), parameter :: bodylen=15

    character(len=64) , dimension(bodylen) :: bodyname
    INTEGER(KIND=JPIM)           , dimension(bodylen) :: bodyidx
    INTEGER(KIND=JPIM)                                :: body_varno, body_vertco_type
    INTEGER(KIND=JPIM)                                :: body_datum_rdbflag, body_entryno
    INTEGER(KIND=JPIM)                                :: body_vertco_reference_1,body_vertco_reference_2, body_obsvalue
    INTEGER(KIND=JPIM)                                :: body_nlayer, body_biascorr, body_tbcorr
    INTEGER(KIND=JPIM)                                :: body_wdeff_bcorr
    INTEGER(KIND=JPIM)                                :: body_an_depar, body_fg_depar
    INTEGER(KIND=JPIM)                                :: body_datum_status, body_datum_event1


!   errstat table
!   -------------

    INTEGER(KIND=JPIM), parameter                       :: errstatlen=6

    character(len=64) , dimension(errstatlen):: errstatname
    INTEGER(KIND=JPIM)           , dimension(errstatlen):: errstatidx

    INTEGER(KIND=JPIM)                                     :: errstat_final_obs_error, errstat_obs_error, errstat_repres_error
    INTEGER(KIND=JPIM)                                     :: errstat_pers_error, errstat_fg_error, errstat_obs_ak_error

!   Sat table
!   ---------

    INTEGER(KIND=JPIM), parameter                     :: satlen=12 

    character(len=64) , dimension(satlen)             :: satname
    INTEGER(KIND=JPIM), dimension(satlen)             :: satidx
    INTEGER(KIND=JPIM)                                :: sat_satellite_identifier
    INTEGER(KIND=JPIM)                                :: sat_zenith, sat_azimuth, sat_solar_zenith, sat_solar_azimuth, sat_lsm_fov
    INTEGER(KIND=JPIM)                                :: sat_gen_centre, sat_gen_subcentre, sat_datastream
    INTEGER(KIND=JPIM)                                :: sat_satellite_instrument
    INTEGER(KIND=JPIM)                                :: sat_range, sat_arg_lat


!   conv table
!   -----------

    INTEGER(KIND=JPIM), parameter                     :: convlen=8

    character(len=64) , dimension(convlen)            :: convname
    INTEGER(KIND=JPIM), dimension(convlen)            :: convidx

    INTEGER(KIND=JPIM)                                :: conv_flight_phase
    INTEGER(KIND=JPIM)                                :: conv_anemoht, conv_station_type
    INTEGER(KIND=JPIM)                                :: conv_sonde_type, conv_baroht
    INTEGER(KIND=JPIM)                                :: conv_flight_dp_o_dt
    INTEGER(KIND=JPIM)                                :: conv_heading
    INTEGER(KIND=JPIM)                                :: conv_aircraft_type

!   conv_body table
!   -----------

    INTEGER(KIND=JPIM), parameter                     :: conv_bodylen=3

    character(len=64) , dimension(conv_bodylen)       :: conv_bodyname
    INTEGER(KIND=JPIM), dimension(conv_bodylen)       :: conv_bodyidx

    INTEGER(KIND=JPIM)                                :: conv_body_ppcode
    INTEGER(KIND=JPIM)                                :: conv_body_level
    INTEGER(KIND=JPIM)                                :: conv_body_datum_qcflag

!   Radiance table
!   -----------

    INTEGER(KIND=JPIM), parameter                     :: radlen=11

    character(len=64) , dimension(radlen)             :: radname
    INTEGER(KIND=JPIM), dimension(radlen)             :: radidx

    INTEGER(KIND=JPIM)                                :: radiance_scanline, radiance_scanpos, radiance_typesurf, radiance_orbit, radiance_corr_version
    INTEGER(KIND=JPIM)                                :: radiance_cldcover
    INTEGER(KIND=JPIM)                                :: radiance_asr_pclear, radiance_asr_pcloudy, radiance_asr_pcloudy_low
    INTEGER(KIND=JPIM)                                :: radiance_asr_pcloudy_middle, radiance_asr_pcloudy_high

!   Radiance_body table
!   ---------------

    INTEGER(KIND=JPIM), parameter                     :: radbodylen=5

    character(len=64) , dimension(radbodylen)         :: radbodyname
    INTEGER(KIND=JPIM), dimension(radbodylen)         :: radbodyidx

    INTEGER(KIND=JPIM)                                :: radiance_body_csr_pclear
    INTEGER(KIND=JPIM)                                :: radiance_body_cold_nedt
    INTEGER(KIND=JPIM)                                :: radiance_body_warm_nedt
    INTEGER(KIND=JPIM)                                :: radiance_body_channel_qc
    INTEGER(KIND=JPIM)                                :: radiance_body_zenith_by_channel

!   Iasi table
!   -----------

    INTEGER(KIND=JPIM), parameter                     :: max_avhrr=7
    INTEGER(KIND=JPIM), parameter                     :: collocated_imager_info_len=14+3*max_avhrr

    character(len=64) , dimension(collocated_imager_info_len)             :: collocated_imager_infoname
    INTEGER(KIND=JPIM), dimension(collocated_imager_info_len)             :: collocated_imager_infoidx

    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_provider_qc
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_max_cluster
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_mean_ir
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_stddev_ir
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_mean_vis
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_stddev_vis
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_coldest_cluster_ir
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_warmest_cluster_ir
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_largest_cluster_ir
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_num_clusters
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_stddev_ir2
    INTEGER(KIND=JPIM), dimension(max_avhrr)            :: collocated_imager_information_avhrr_frac_cl
    INTEGER(KIND=JPIM), dimension(max_avhrr)            :: collocated_imager_information_avhrr_m_ir1_cl
    INTEGER(KIND=JPIM), dimension(max_avhrr)            :: collocated_imager_information_avhrr_m_ir2_cl
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_fg_ir1
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_fg_ir2
    INTEGER(KIND=JPIM)                                  :: collocated_imager_information_avhrr_cloud_flag

!   satob table
!   -----------

    INTEGER(KIND=JPIM), parameter :: satoblen=14

    character(len=64) , dimension(satoblen):: satobname
    INTEGER(KIND=JPIM)           , dimension(satoblen):: satobidx

    INTEGER(KIND=JPIM)                                :: satob_comp_method, satob_instdata, satob_dataproc
    INTEGER(KIND=JPIM)                                :: satob_qi_fc, satob_rff, satob_qi_nofc, satob_ee
    INTEGER(KIND=JPIM)                                :: satob_segment_size_x, satob_segment_size_y, satob_tb, satob_chan_freq
    INTEGER(KIND=JPIM)                                :: satob_height_assignment_method
    INTEGER(KIND=JPIM)                                :: satob_tracer_correlation_method, satob_land_sea

!   SCATT table

    INTEGER(KIND=JPIM), parameter                       :: scattlen=4

    character(len=64) , dimension(scattlen)  :: scattname
    INTEGER(KIND=JPIM)           , dimension(scattlen)  :: scattidx

    INTEGER(KIND=JPIM)                                  :: scatt_cellno, scatt_nretr_amb, scatt_prodflag, scatt_wvc_qf

!   SCATT_BODY table

    INTEGER(KIND=JPIM), parameter                       :: scatt_bodylen=14

    character(len=64) , dimension(scatt_bodylen)        :: scatt_bodyname
    INTEGER(KIND=JPIM)      , dimension(scatt_bodylen)  :: scatt_bodyidx

    INTEGER(KIND=JPIM)                                  :: scatt_body_azimuth, scatt_body_incidence, scatt_body_kp, scatt_body_invresid
    INTEGER(KIND=JPIM)                                  :: scatt_body_mpc
    INTEGER(KIND=JPIM)                                  :: scatt_body_kp_qf, scatt_body_sigma0_qf, scatt_body_sigma0_sm, scatt_body_soilmoist_sd
    INTEGER(KIND=JPIM)                                  :: scatt_body_soilmoist_cf, scatt_body_soilmoist_pf, scatt_body_land_fraction
    INTEGER(KIND=JPIM)                                  :: scatt_body_wetland_fraction, scatt_body_topo_complex

!   SMOS table

    INTEGER(KIND=JPIM), parameter                       :: smoslen=16

    character(len=64) , dimension(smoslen)              :: smosname
    INTEGER(KIND=JPIM), dimension(smoslen)              :: smosidx

    INTEGER(KIND=JPIM)                                  :: smos_snapshot_id, smos_grid_point_id, smos_electron_count
    INTEGER(KIND=JPIM)                                  :: smos_sun_bt, smos_snapshot_acc, smos_rad_acc_pure
    INTEGER(KIND=JPIM)                                  :: smos_rad_acc_cross, smos_footprint_axis_1, smos_footprint_axis_2
    INTEGER(KIND=JPIM)                                  :: smos_polarisation, smos_water_fraction, smos_incidence_angle
    INTEGER(KIND=JPIM)                                  :: smos_faradey_rot_angle, smos_pixel_rot_angle
    INTEGER(KIND=JPIM)                                  :: smos_info, smos_snapshot_quality

!   resat table

    INTEGER(KIND=JPIM), parameter                       :: n_fov_corners=4
    INTEGER(KIND=JPIM), parameter                       :: resatlen=13+2*n_fov_corners

    character(len=64) , dimension(resatlen)             :: resatname
    INTEGER(KIND=JPIM), dimension(resatlen)             :: resatidx

    INTEGER(KIND=JPIM)                                  :: resat_instrument_type, resat_product_type
    INTEGER(KIND=JPIM), dimension(n_fov_corners)        :: resat_lat_fovcorner
    INTEGER(KIND=JPIM), dimension(n_fov_corners)        :: resat_lon_fovcorner
    INTEGER(KIND=JPIM)                                  :: resat_solar_elevation, resat_scanpos
    INTEGER(KIND=JPIM)                                  :: resat_cloud_cover    , resat_cloud_top_press
    INTEGER(KIND=JPIM)                                  :: resat_quality_retrieval, resat_number_layers
    INTEGER(KIND=JPIM)                                  :: resat_snow_ice_indicator, resat_surface_type_indicator
    INTEGER(KIND=JPIM)                                  :: resat_methane_correction, resat_surface_height
    INTEGER(KIND=JPIM)                                  :: resat_retrsource

!   resat_averaging_kernel table

    INTEGER(KIND=JPIM), parameter                       :: resat_max_nak=50
    INTEGER(KIND=JPIM), parameter                       :: resat_aklen = 3*resat_max_nak + 1

    character(len=64) , dimension(resat_aklen)  :: resat_akname
    INTEGER(KIND=JPIM), dimension(resat_aklen)  :: resat_akidx

    INTEGER(KIND=JPIM)                                  :: resat_averaging_kernel_nak
    INTEGER(KIND=JPIM), dimension(resat_max_nak)        :: resat_averaging_kernel_wak
    INTEGER(KIND=JPIM), dimension(resat_max_nak)        :: resat_averaging_kernelm_pak
    INTEGER(KIND=JPIM), dimension(resat_max_nak)        :: resat_averaging_kernelm_apak
 
!   gnssro table
!   ------------------
    INTEGER(KIND=JPIM), parameter                       :: gnssro_len=2
    character(len=64) , dimension(gnssro_len    )       :: gnssro_name
    INTEGER(KIND=JPIM), dimension(gnssro_len    )       :: gnssro_idx

    INTEGER(KIND=JPIM)                                  :: gnssro_radcurv, gnssro_undulation

!   aeolus_hdr table

    INTEGER(KIND=JPIM), parameter                       :: aeolus_hdrlen=1

    character(len=64) , dimension(aeolus_hdrlen)        :: aeolus_hdrname
    INTEGER(KIND=JPIM), dimension(aeolus_hdrlen)        :: aeolus_hdridx

    INTEGER(KIND=JPIM)                                  :: aeolus_hdr_aeolus_hdrflag

!   aeolus_l2c table

    INTEGER(KIND=JPIM), parameter                       :: aeolus_l2clen=11

    character(len=64) , dimension(aeolus_l2clen)        :: aeolus_l2cname
    INTEGER(KIND=JPIM), dimension(aeolus_l2clen)        :: aeolus_l2cidx

    INTEGER(KIND=JPIM)                                  :: aeolus_l2c_hlos_ob_err, aeolus_l2c_hlos_fg, aeolus_l2c_u_fg
    INTEGER(KIND=JPIM)                                  :: aeolus_l2c_u_fg_err, aeolus_l2c_v_fg, aeolus_l2c_v_fg_err
    INTEGER(KIND=JPIM)                                  :: aeolus_l2c_hlos_fg_err, aeolus_l2c_hlos_an, aeolus_l2c_hlos_an_err
    INTEGER(KIND=JPIM)                                  :: aeolus_l2c_u_an, aeolus_l2c_v_an

!   aeolus_l2b table

    INTEGER(KIND=JPIM), parameter                       :: aeolus_l2blen=9

    character(len=64) , dimension(aeolus_l2blen)        :: aeolus_l2bname
    INTEGER(KIND=JPIM), dimension(aeolus_l2blen)        :: aeolus_l2bidx

    INTEGER(KIND=JPIM)                                  :: aeolus_l2b_t_ref, aeolus_l2b_p_ref, aeolus_l2b_beta
    INTEGER(KIND=JPIM)                                  :: aeolus_l2b_dhlos_dt, aeolus_l2b_dhlos_dp, aeolus_l2b_dhlos_dbeta
    INTEGER(KIND=JPIM)                                  :: aeolus_l2b_horiz_length, aeolus_l2b_vert_length, aeolus_l2b_conf_flag

END MODULE varindex_module
