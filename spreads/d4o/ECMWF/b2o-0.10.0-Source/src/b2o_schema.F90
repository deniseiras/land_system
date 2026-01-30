module b2o_schema

use b2o_common
use b2o_table, only : b2o_table_t, b2o_new_table, push

implicit none

#include "b2o_debug.h"
#include "b2o_schema_varno.h"
#include "b2o_schema_vertco_type.h"

type col_t
    character(64) :: name = ""
    integer, pointer :: index => null()
end type

interface col
    module procedure col_scalar, col_array
end interface

interface

subroutine b2o_get_column_attrs_proc(table_name, column_names, column_types, column_indices)
    implicit none
    character(*), intent(in) :: table_name
    character(*), dimension(:), intent(inout), allocatable :: column_names
    integer, dimension(:), intent(out), allocatable :: column_types
    integer, dimension(:), intent(out) :: column_indices
end subroutine

end interface

private :: get_column_attrs

#ifdef _CRAYFTN

! [1] This is a workaround for a Cray compiler bug affecting procedure pointers
! (see CHPC-2133). The problem is twofold: first, initializing procedure pointers
! at the same time they are declared throws a compilation error; and second, even
! if they are initialized after the declaration, the intrinsic function associated
! would always return .false. (which we work around by using our own function pointer
! wrapper).
! Apparently this has been fixed in cdt 19.06.

type b2o_get_column_attrs_wrapper_t
    procedure(b2o_get_column_attrs_proc), pointer, nopass :: ptr => null()
    logical :: associated = .false.
end type

type(b2o_get_column_attrs_wrapper_t) :: b2o_get_column_attrs_wrapper

procedure(b2o_get_column_attrs_proc), pointer :: b2o_get_column_attrs => null()
#else
procedure(b2o_get_column_attrs_proc), pointer :: b2o_get_column_attrs => get_column_attrs
#endif

! hdr

integer :: hdr_subtype
integer :: hdr_bufrtype
integer :: hdr_date
integer :: hdr_time
integer :: hdr_statid
integer :: hdr_rdbdate, hdr_rdbtime
integer :: hdr_report_rdbflag
integer :: hdr_lat
integer :: hdr_lon
integer :: hdr_numlev
integer :: hdr_seqno
integer :: hdr_subsetno
integer :: hdr_retrtype
integer :: hdr_source
integer :: hdr_distribtype
integer :: hdr_groupid
integer :: hdr_reportype
integer :: hdr_obstype
integer :: hdr_codetype
integer :: hdr_sensor
integer :: hdr_stalt
integer :: hdr_instrument_type
integer :: hdr_report_event1
integer :: hdr_reportno
integer :: hdr_report_status
integer :: hdr_wigosid(4)
integer :: hdr_restricted

! body

integer :: body_varno
integer :: body_vertco_type
integer :: body_datum_rdbflag
integer :: body_entryno
integer :: body_vertco_reference_1
integer :: body_vertco_reference_2
integer :: body_obsvalue
integer :: body_nlayer
integer :: body_biascorr
integer :: body_tbcorr
integer :: body_wdeff_bcorr
integer :: body_an_depar
integer :: body_fg_depar
integer :: body_datum_status
integer :: body_datum_event1

! errstat

integer :: errstat_final_obs_error
integer :: errstat_obs_error
integer :: errstat_repres_error
integer :: errstat_pers_error
integer :: errstat_fg_error
integer :: errstat_obs_ak_error

! sat

integer :: sat_satellite_identifier
integer :: sat_zenith
integer :: sat_azimuth
integer :: sat_solar_zenith
integer :: sat_solar_azimuth
integer :: sat_lsm_fov
integer :: sat_gen_centre
integer :: sat_gen_subcentre
integer :: sat_datastream
integer :: sat_satellite_instrument
integer :: sat_range
integer :: sat_arg_lat

! conv

integer :: conv_flight_phase
integer :: conv_anemoht
integer :: conv_station_type
integer :: conv_sonde_type
integer :: conv_baroht
integer :: conv_flight_dp_o_dt
integer :: conv_heading
integer :: conv_aircraft_type

! conv_body

integer :: conv_body_ppcode
integer :: conv_body_level
integer :: conv_body_datum_qcflag

! radiance

integer :: radiance_scanline
integer :: radiance_scanpos
integer :: radiance_typesurf
integer :: radiance_orbit
integer :: radiance_corr_version
integer :: radiance_cldcover
integer :: radiance_asr_pclear
integer :: radiance_asr_pcloudy
integer :: radiance_asr_pcloudy_low
integer :: radiance_asr_pcloudy_middle
integer :: radiance_asr_pcloudy_high

! radiance_body

integer :: radiance_body_csr_pclear
integer :: radiance_body_cold_nedt
integer :: radiance_body_warm_nedt
integer :: radiance_body_channel_qc
integer :: radiance_body_zenith_by_channel

! collocated_imager_information

integer, parameter :: MAX_AVHRR = 7

integer :: collocated_imager_information_provider_qc
integer :: collocated_imager_information_avhrr_max_cluster
integer :: collocated_imager_information_avhrr_mean_ir
integer :: collocated_imager_information_avhrr_stddev_ir
integer :: collocated_imager_information_avhrr_mean_vis
integer :: collocated_imager_information_avhrr_stddev_vis
integer :: collocated_imager_information_avhrr_coldest_cluster_ir
integer :: collocated_imager_information_avhrr_warmest_cluster_ir
integer :: collocated_imager_information_avhrr_largest_cluster_ir
integer :: collocated_imager_information_avhrr_num_clusters
integer :: collocated_imager_information_avhrr_stddev_ir2
integer :: collocated_imager_information_avhrr_frac_cl(MAX_AVHRR)
integer :: collocated_imager_information_avhrr_m_ir1_cl(MAX_AVHRR)
integer :: collocated_imager_information_avhrr_m_ir2_cl(MAX_AVHRR)
integer :: collocated_imager_information_avhrr_fg_ir1
integer :: collocated_imager_information_avhrr_fg_ir2
integer :: collocated_imager_information_avhrr_cloud_flag

! satob

integer :: satob_comp_method
integer :: satob_instdata, satob_dataproc
integer :: satob_qi_fc
integer :: satob_rff
integer :: satob_qi_nofc
integer :: satob_ee
integer :: satob_segment_size_x
integer :: satob_segment_size_y
integer :: satob_tb
integer :: satob_chan_freq
integer :: satob_height_assignment_method
integer :: satob_tracer_correlation_method
integer :: satob_land_sea
integer :: satob_ct_p
integer :: satob_cb_p
integer :: satob_umod_old
integer :: satob_vmod_old

! scatt

integer :: scatt_cellno
integer :: scatt_nretr_amb
integer :: scatt_prodflag
integer :: scatt_wvc_qf

! scatt_body

integer :: scatt_body_azimuth
integer :: scatt_body_incidence
integer :: scatt_body_kp
integer :: scatt_body_invresid
integer :: scatt_body_mpc
integer :: scatt_body_kp_qf
integer :: scatt_body_sigma0_qf
integer :: scatt_body_sigma0_sm
integer :: scatt_body_soilmoist_sd
integer :: scatt_body_soilmoist_cf
integer :: scatt_body_soilmoist_pf
integer :: scatt_body_land_fraction
integer :: scatt_body_wetland_fraction
integer :: scatt_body_topo_complex

! smos

integer :: smos_snapshot_id
integer :: smos_grid_point_id
integer :: smos_electron_count
integer :: smos_sun_bt
integer :: smos_snapshot_acc
integer :: smos_rad_acc_pure
integer :: smos_rad_acc_cross
integer :: smos_footprint_axis_1
integer :: smos_footprint_axis_2
integer :: smos_polarisation
integer :: smos_water_fraction
integer :: smos_incidence_angle
integer :: smos_faradey_rot_angle
integer :: smos_pixel_rot_angle
integer :: smos_info
integer :: smos_snapshot_quality

! resat

integer :: resat_instrument_type
integer :: resat_product_type
integer :: resat_lat_fovcorner(4)
integer :: resat_lon_fovcorner(4)
integer :: resat_solar_elevation
integer :: resat_scanpos
integer :: resat_cloud_cover
integer :: resat_cloud_top_press
integer :: resat_quality_retrieval
integer :: resat_number_layers
integer :: resat_snow_ice_indicator
integer :: resat_surface_type_indicator
integer :: resat_methane_correction
integer :: resat_surface_height
integer :: resat_retrsource

! resat_averaging_kernel

integer, parameter :: MX_AK = 50

integer :: resat_averaging_kernel_nak
integer :: resat_averaging_kernel_wak(MX_AK)
integer :: resat_averaging_kernel_pak(MX_AK)
integer :: resat_averaging_kernel_apak(MX_AK)

! gnssro

integer :: gnssro_radcurv
integer :: gnssro_undulation

! aeolus_hdr

integer :: aeolus_hdr_aeolus_hdrflag

! aeolus_l2c

integer :: aeolus_l2c_hlos_ob_err
integer :: aeolus_l2c_hlos_fg
integer :: aeolus_l2c_u_fg
integer :: aeolus_l2c_u_fg_err
integer :: aeolus_l2c_v_fg
integer :: aeolus_l2c_v_fg_err
integer :: aeolus_l2c_hlos_fg_err
integer :: aeolus_l2c_hlos_an
integer :: aeolus_l2c_hlos_an_err
integer :: aeolus_l2c_u_an
integer :: aeolus_l2c_v_an

! aeolus_l2b

integer :: aeolus_l2b_t_ref
integer :: aeolus_l2b_p_ref
integer :: aeolus_l2b_beta
integer :: aeolus_l2b_dhlos_dt
integer :: aeolus_l2b_dhlos_dp
integer :: aeolus_l2b_dhlos_dbeta
integer :: aeolus_l2b_horiz_length
integer :: aeolus_l2b_vert_length
integer :: aeolus_l2b_conf_flag

contains

! [2] This is a workaround for a Cray compiler bug affecting array constructors
! (see CHPC-2140). The problem seems to appear when array constructors, used to
! initialize allocatable arrays, contain calls to array-valued functions (i.e.
! functions returning arrays). This results in memory corruption, and eventually
! causes the program to segfault.
!
! The workaround is to allocate arrays explicitly (although this shouldn't be
! necessary) before they are initialized. Note that this only needs to be done
! for tables containing array columns (e.g. wigosid[4]@hdr).

#ifdef _CRAYFTN
#define REALLOCATE(x) if (allocated(cols)) deallocate(cols); allocate(x)
#else
#define REALLOCATE(x)
#endif

function create_all_tables() result(tables)

    type(b2o_table_t), pointer :: tables
    type(col_t), allocatable :: cols(:)

    tables => null()

    ! hdr

    REALLOCATE(cols(27+4)) ! see note [2] above

    cols = [ &
      & col("subtype", hdr_subtype), &
      & col("bufrtype", hdr_bufrtype), &
      & col("date", hdr_date), &
      & col("time", hdr_time), &
      & col("rdbdate", hdr_rdbdate), &
      & col("rdbtime", hdr_rdbtime), &
      & col("statid", hdr_statid), &
      & col("report_rdbflag", hdr_report_rdbflag), &
      & col("lat", hdr_lat), &
      & col("lon", hdr_lon), &
      & col("numlev", hdr_numlev), &
      & col("seqno", hdr_seqno), &
      & col("subsetno", hdr_subsetno), &
      & col("retrtype", hdr_retrtype), &
      & col("source", hdr_source), &
      & col("distribtype", hdr_distribtype), &
      & col("groupid", hdr_groupid), &
      & col("reportype", hdr_reportype), &
      & col("obstype", hdr_obstype), &
      & col("codetype", hdr_codetype), &
      & col("sensor", hdr_sensor), &
      & col("stalt", hdr_stalt), &
      & col("instrument_type", hdr_instrument_type), &
      & col("report_event1", hdr_report_event1), &
      & col("reportno", hdr_reportno), &
      & col("report_status", hdr_report_status), &
      & col("wigosid", hdr_wigosid), &
      & col("restricted", hdr_restricted) &
      & ]

    call create_table('hdr', cols)

    ! body

    cols = [ &
      & col('varno', body_varno), &
      & col('vertco_type', body_vertco_type), &
      & col('datum_rdbflag', body_datum_rdbflag), &
      & col('entryno', body_entryno), &
      & col('vertco_reference_1', body_vertco_reference_1), &
      & col('vertco_reference_2', body_vertco_reference_2), &
      & col('obsvalue', body_obsvalue), &
      & col('nlayer', body_nlayer), &
      & col('biascorr', body_biascorr), &
      & col('tbcorr', body_tbcorr), &
      & col('wdeff_bcorr', body_wdeff_bcorr), &
      & col('an_depar', body_an_depar), &
      & col('fg_depar', body_fg_depar), &
      & col('datum_status', body_datum_status), &
      & col('datum_event1', body_datum_event1) &
      & ]

    call create_table('body', cols)

    ! errstat

    cols = [ &
      & col('final_obs_error', errstat_final_obs_error), &
      & col('obs_error', errstat_obs_error), &
      & col('repres_error', errstat_repres_error), &
      & col('pers_error', errstat_pers_error), &
      & col('fg_error', errstat_fg_error), &
      & col('obs_ak_error', errstat_obs_ak_error) &
      & ]

    call create_table('errstat', cols)

    ! sat

    cols = [ &
      & col('satellite_identifier', sat_satellite_identifier), &
      & col('gen_centre', sat_gen_centre), &
      & col('gen_subcentre', sat_gen_subcentre), &
      & col('datastream', sat_datastream), &
      & col('solar_zenith', sat_solar_zenith), &
      & col('solar_azimuth', sat_solar_azimuth), &
      & col('zenith', sat_zenith), &
      & col('azimuth', sat_azimuth), &
      & col('satellite_instrument', sat_satellite_instrument), &
      & col('range', sat_range), &
      & col('arg_lat', sat_arg_lat), &
      & col('lsm_fov', sat_lsm_fov) &
      & ]

    call create_table('sat', cols)

    ! conv

    cols = [ &
      & col('flight_phase', conv_flight_phase), &
      & col('anemoht', conv_anemoht), &
      & col('station_type', conv_station_type), &
      & col('sonde_type', conv_sonde_type), &
      & col('baroht', conv_baroht), &
      & col('flight_dp_o_dt', conv_flight_dp_o_dt), &
      & col('heading', conv_heading), &
      & col('aircraft_type', conv_aircraft_type) &
      & ]

    call create_table('conv', cols)

    ! conv_body

    cols = [ &
      & col('ppcode', conv_body_ppcode), &
      & col('level', conv_body_level), &
      & col('datum_qcflag', conv_body_datum_qcflag) &
      & ]

    call create_table('conv_body', cols)

    ! radiance

    cols = [ &
      & col('orbit', radiance_orbit), &
      & col('scanline', radiance_scanline), &
      & col('scanpos', radiance_scanpos), &
      & col('typesurf', radiance_typesurf), &
      & col('cldcover', radiance_cldcover), &
      & col('corr_version', radiance_corr_version), &
      & col('asr_pclear', radiance_asr_pclear), &
      & col('asr_pcloudy', radiance_asr_pcloudy), &
      & col('asr_pcloudy_low', radiance_asr_pcloudy_low), &
      & col('asr_pcloudy_middle', radiance_asr_pcloudy_middle), &
      & col('asr_pcloudy_high', radiance_asr_pcloudy_high) &
      & ]

    call create_table('radiance', cols)

    ! radiance_body

    cols = [ &
      & col('csr_pclear', radiance_body_csr_pclear), &
      & col('cold_nedt', radiance_body_cold_nedt), &
      & col('warm_nedt', radiance_body_warm_nedt), &
      & col('channel_qc', radiance_body_channel_qc), &
      & col('zenith_by_channel', radiance_body_zenith_by_channel) &
      & ]

    call create_table('radiance_body', cols)

    ! collocated_imager_information

    REALLOCATE(cols(14+3*MAX_AVHRR)) ! see note [2] above

    cols = [ &
      & col('provider_qc', collocated_imager_information_provider_qc), &
      & col('avhrr_max_cluster', collocated_imager_information_avhrr_max_cluster), &
      & col('avhrr_mean_ir', collocated_imager_information_avhrr_mean_ir), &
      & col('avhrr_stddev_ir', collocated_imager_information_avhrr_stddev_ir), &
      & col('avhrr_mean_vis', collocated_imager_information_avhrr_mean_vis), &
      & col('avhrr_stddev_vis', collocated_imager_information_avhrr_stddev_vis), &
      & col('avhrr_coldest_cluster_ir', collocated_imager_information_avhrr_coldest_cluster_ir), &
      & col('avhrr_warmest_cluster_ir', collocated_imager_information_avhrr_warmest_cluster_ir), &
      & col('avhrr_largest_cluster_ir', collocated_imager_information_avhrr_largest_cluster_ir), &
      & col('avhrr_num_clusters', collocated_imager_information_avhrr_num_clusters), &
      & col('avhrr_stddev_ir2', collocated_imager_information_avhrr_stddev_ir2), &
      & col('avhrr_frac_cl', collocated_imager_information_avhrr_frac_cl, separator=""), &
      & col('avhrr_m_ir1_cl', collocated_imager_information_avhrr_m_ir1_cl, separator=""), &
      & col('avhrr_m_ir2_cl', collocated_imager_information_avhrr_m_ir2_cl, separator=""), &
      & col('avhrr_fg_ir1', collocated_imager_information_avhrr_fg_ir1), &
      & col('avhrr_fg_ir2', collocated_imager_information_avhrr_fg_ir2), &
      & col('avhrr_cloud_flag', collocated_imager_information_avhrr_cloud_flag) &
      & ]

    call create_table('collocated_imager_information', cols)

    ! satob

    cols = [ &
      & col('comp_method', satob_comp_method), &
      & col('instdata', satob_instdata), &
      & col('dataproc', satob_dataproc), &
      & col('qi_fc', satob_qi_fc), &
      & col('rff', satob_rff), &
      & col('qi_nofc', satob_qi_nofc), &
      & col('segment_size_x', satob_segment_size_x), &
      & col('segment_size_y', satob_segment_size_y), &
      & col('tb', satob_tb), &
      & col('chan_freq', satob_chan_freq), &
      & col('height_assignment_method', satob_height_assignment_method), &
      & col('tracer_correlation_method', satob_tracer_correlation_method), &
      & col('land_sea', satob_land_sea), &
      & col('ee', satob_ee), &
      & col('ct_p', satob_ct_p), &
      & col('cb_p', satob_cb_p), &
      & col('umod_old', satob_umod_old), &
      & col('vmod_old', satob_vmod_old) &
      & ]

    call create_table('satob', cols)

    ! scatt

    cols = [ &
      & col('cellno', scatt_cellno), &
      & col('nretr_amb', scatt_nretr_amb), &
      & col('prodflag', scatt_prodflag), &
      & col('wvc_qf', scatt_wvc_qf) &
      & ]

    call create_table('scatt', cols)

    ! scatt_body

    cols = [ &
      & col('azimuth', scatt_body_azimuth), &
      & col('incidence', scatt_body_incidence), &
      & col('kp', scatt_body_kp), &
      & col('invresid', scatt_body_invresid), &
      & col('mpc', scatt_body_mpc), &
      & col('kp_qf', scatt_body_kp_qf), &
      & col('sigma0_qf', scatt_body_sigma0_qf), &
      & col('sigma0_sm', scatt_body_sigma0_sm), &
      & col('soilmoist_sd', scatt_body_soilmoist_sd), &
      & col('soilmoist_cf', scatt_body_soilmoist_cf), &
      & col('soilmoist_pf', scatt_body_soilmoist_pf), &
      & col('land_fraction', scatt_body_land_fraction), &
      & col('wetland_fraction', scatt_body_wetland_fraction), &
      & col('topo_complex', scatt_body_topo_complex) &
      & ]

    call create_table('scatt_body', cols)

    ! resat

    REALLOCATE(cols(13+2*4)) ! see note [2] above

    cols = [ &
      & col('instrument_type', resat_instrument_type), &
      & col('product_type', resat_product_type), &
      & col('lat_fovcorner', resat_lat_fovcorner), &
      & col('lon_fovcorner', resat_lon_fovcorner), &
      & col('solar_elevation', resat_solar_elevation), &
      & col('scanpos', resat_scanpos), &
      & col('cloud_cover', resat_cloud_cover), &
      & col('cloud_top_press', resat_cloud_top_press), &
      & col('quality_retrieval', resat_quality_retrieval), &
      & col('number_layers', resat_number_layers), &
      & col('snow_ice_indicator', resat_snow_ice_indicator), &
      & col('surface_type_indicator', resat_surface_type_indicator), &
      & col('methane_correction', resat_methane_correction), &
      & col('surface_height', resat_surface_height), &
      & col('retrsource', resat_retrsource) &
      & ]

    call create_table('resat', cols)

    ! resat_ak

    REALLOCATE(cols(1+3*MX_AK)) ! see note [2] above

    cols = [ &
      & col('nak', resat_averaging_kernel_nak), &
      & col('wak', resat_averaging_kernel_wak), &
      & col('pak', resat_averaging_kernel_pak), &
      & col('apak', resat_averaging_kernel_apak) &
      & ]

    call create_table('resat_averaging_kernel', cols)

    ! gnssro

    cols = [ &
      & col('radcurv', gnssro_radcurv), &
      & col('undulation', gnssro_undulation) &
      & ]

    call create_table('gnssro', cols)

    ! smos

    cols = [ &
      & col('snapshot_id', smos_snapshot_id), &
      & col('grid_point_id', smos_grid_point_id), &
      & col('electron_count', smos_electron_count), &
      & col('sun_bt', smos_sun_bt), &
      & col('snapshot_acc', smos_snapshot_acc), &
      & col('rad_acc_pure', smos_rad_acc_pure), &
      & col('rad_acc_cross', smos_rad_acc_cross), &
      & col('footprint_axis_1', smos_footprint_axis_1), &
      & col('footprint_axis_2', smos_footprint_axis_2), &
      & col('polarisation', smos_polarisation), &
      & col('water_fraction', smos_water_fraction), &
      & col('incidence_angle', smos_incidence_angle), &
      & col('faradey_rot_angle', smos_faradey_rot_angle), &
      & col('pixel_rot_angle', smos_pixel_rot_angle), &
      & col('info', smos_info), &
      & col('snapshot_quality', smos_snapshot_quality) &
      & ]

    call create_table('smos', cols)

    ! aeolus_hdr

    cols = [ &
      & col('aeolus_hdrflag', aeolus_hdr_aeolus_hdrflag) &
      & ]

    call create_table('aeolus_hdr', cols)

    ! aeolus_l2c

    cols = [ &
      & col('hlos_ob_err', aeolus_l2c_hlos_ob_err), &
      & col('hlos_fg', aeolus_l2c_hlos_fg), &
      & col('u_fg', aeolus_l2c_u_fg), &
      & col('u_fg_err', aeolus_l2c_u_fg_err), &
      & col('v_fg', aeolus_l2c_v_fg), &
      & col('v_fg_err', aeolus_l2c_v_fg_err), &
      & col('hlos_fg_err', aeolus_l2c_hlos_fg_err), &
      & col('hlos_an', aeolus_l2c_hlos_an), &
      & col('hlos_an_err', aeolus_l2c_hlos_an_err), &
      & col('u_an', aeolus_l2c_u_an), &
      & col('v_an', aeolus_l2c_v_an) &
      & ]

    call create_table('aeolus_l2c', cols)

    ! aeolus_l2b

    cols = [ &
      & col('t_ref', aeolus_l2b_t_ref), &
      & col('p_ref', aeolus_l2b_p_ref), &
      & col('beta', aeolus_l2b_beta), &
      & col('dhlos_dt', aeolus_l2b_dhlos_dt), &
      & col('dhlos_dp', aeolus_l2b_dhlos_dp), &
      & col('dhlos_dbeta', aeolus_l2b_dhlos_dbeta), &
      & col('horiz_length', aeolus_l2b_horiz_length), &
      & col('vert_length', aeolus_l2b_vert_length), &
      & col('conf_flag', aeolus_l2b_conf_flag) &
      & ]

    call create_table('aeolus_l2b', cols)

contains

subroutine create_table(table_name, columns)

    character(*), intent(in) :: table_name
    type(col_t), intent(inout) :: columns(:)
    character(64), allocatable :: column_names(:)
    integer, allocatable :: column_types(:), column_indices(:)
    type(b2o_table_t), pointer :: table
    integer :: i, n

    n = size(columns)

    column_names = [(columns(i)%name, i = 1, n)]

    allocate (column_indices(n))

#ifdef _CRAYFTN
    if (.not.b2o_get_column_attrs_wrapper%associated) then
        b2o_get_column_attrs_wrapper = b2o_get_column_attrs_wrapper_t(get_column_attrs, .true.)
    end if
    b2o_get_column_attrs => b2o_get_column_attrs_wrapper%ptr ! see note [1] above
#endif

    call b2o_get_column_attrs(table_name, column_names, column_types, column_indices)

    forall (i = 1:n) columns(i)%index = column_indices(i)

    table => b2o_new_table(table_name, column_names, column_types)

    table%default_values(0) = 0 ! required by ODB1 (control column)

    if (table%name == "hdr") then
        table%default_values(hdr_distribtype) = 0 ! required by IFS
    end if

    call push(table, tables)

end subroutine

end function

function col_scalar(name, index) result(col)

    character(*), intent(in) :: name
    integer, intent(in), target :: index
    type(col_t) :: col

    col%name = name
    col%index => index

end function

function col_array(name, index, separator) result(col)

    character(*), intent(in) :: name
    integer, intent(in), target :: index(:)
    character(*), intent(in), optional :: separator
    type(col_t) :: col(size(index))
    integer :: i

    do i = 1, size(index)
        if (present(separator)) then
            write (col(i)%name, "(a,a,i0)") trim(name), trim(separator), i
        else
            write (col(i)%name, "(a,'_',i0)") trim(name), i
        end if
        col(i)%index => index(i)
    end do

end function

subroutine get_column_attrs(table_name, column_names, column_types, column_indices)

    character(*), intent(in) :: table_name
    character(*), dimension(:), intent(inout), allocatable :: column_names
    integer(b2o_int), dimension(:), intent(out), allocatable :: column_types
    integer(b2o_int), dimension(:), intent(out) :: column_indices
    integer(b2o_int) :: i, n

    call b2o_assert(size(column_names) == size(column_indices))

    n = size(column_names)

    column_indices = [(i, i = 1, n)]
    column_types   = [(get_column_type(table_name, column_names(i)), i = 1, n)]

end subroutine

function get_column_type(table_name, column_name) result(column_type)

    use, intrinsic :: iso_c_binding
    use b2o_string, only : foo_car_string

    interface
        function b2o_get_column_type(c_name) result(c_type) bind(c)
            import :: c_char, c_int
            character(kind=c_char), dimension(*) :: c_name
            integer(c_int) :: c_type
        end function
    end interface

    character(*), intent(in) :: table_name, column_name
    integer(b2o_int) :: column_type
    character(kind=c_char), dimension(64) :: c_name

    call foo_car_string(trim(column_name) // "@" // trim(table_name), c_name, size(c_name))

    column_type = b2o_get_column_type(c_name)

end function

end module
