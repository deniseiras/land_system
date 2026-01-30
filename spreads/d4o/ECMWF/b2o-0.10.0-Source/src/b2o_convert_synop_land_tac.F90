subroutine b2o_convert_synop_land_tac(handle, status)

use b2o_internal
use b2o_option, only : B2O_EXTRACT_RH2M

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(b2o_int), intent(inout) :: status

real(b2o_double) :: to_double

real(b2o_double), pointer :: hdr(:,:)
real(b2o_double), pointer :: errstat(:,:)
real(b2o_double), pointer :: conv(:,:)
real(b2o_double), pointer :: conv_body(:,:)
real(b2o_double), pointer :: body(:,:)

real(b2o_double) :: stalt
real(b2o_double) :: z, p
real(b2o_double) :: time_period

integer(b2o_int) :: varno
integer(b2o_int) :: n_variables
integer(b2o_int) :: report_rdbflag, datum_rdbflag
integer(b2o_int) :: iobs, jobs

character(32) :: k_rr
character(24) :: units

real(b2o_double) :: zhook_handle

#if defined(__PGI)
character(len=8) :: hdr_statid_temp ! local for PGI workaround
#endif

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_synop_land_tac',0,zhook_handle)

n_variables = 27

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  stalt = b2o_get_real(handle, "heightOfStation")
  report_rdbflag = b2o_get_rdbflag(handle, "heightOfStation", 3, 0)
  datum_rdbflag  = b2o_get_rdbflag(handle, "heightOfStation", 27, 0)

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
#if defined(__PGI)
  hdr_statid_temp=b2o_get_station_id(handle, status)
  hdr(iobs,hdr_statid) = transfer( hdr_statid_temp, to_double)
#else
  hdr(iobs,hdr_statid) = transfer(b2o_get_station_id(handle, status), to_double)
#endif
  if (status /= B2O_SUCCESS) exit subset_loop
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = stalt

  conv(iobs,conv_station_type) = b2o_get_int(handle, "stationType")

  call append("nonCoordinatePressure", g_ps, ppcode=1) ! station level pressure

  if (b2o_is_defined(handle, "pressure")) then

    p = b2o_get_real(handle, "pressure")
    z = b2o_get_real(handle, "nonCoordinateGeopotential")
    call b2o_get_string(handle, trim("nonCoordinateGeopotential") // "->units", units)
    if (trim(units) == "gpm" .and. z /= ODB_MISSING_REAL) z = z * B2O_GRAVITY

    call append("pressure", g_ps, press=z)
    call append("nonCoordinateGeopotential", g_z, vertco=g_pressure, press=p)

  else ! use pressure reduced to MSL
    call append("pressureReducedToMeanSeaLevel", g_ps, press=0.d0, ppcode=0)
    call append("", g_z)
  end if

  call append("3HourPressureChange", g_ptend)
  call append("airTemperatureAt2M", g_t2m)
  call append("dewpointTemperatureAt2M", g_td2m)
  call append(merge("relativeHumidity", repeat(" ", 16), B2O_EXTRACT_RH2M), g_rh2m)
  call append("", g_q2m)
  call append("windDirectionAt10M", g_dd)
  call append("windSpeedAt10M", g_ff)
  call append("", g_u10m)
  call append("", g_v10m)

  ! Rain amount and time period

  k_rr = ""
  time_period = ODB_MISSING_REAL

  if (b2o_is_defined(handle, "totalPrecipitationPast1Hour")) then
    k_rr = "totalPrecipitationPast1Hour"
    time_period = 1
  else if (b2o_is_defined(handle, "totalPrecipitationPast3Hours")) then
    k_rr = "totalPrecipitationPast3Hours"
    time_period = 3
  else if (b2o_is_defined(handle, "totalPrecipitationPast6Hours")) then
    k_rr = "totalPrecipitationPast6Hours"
    time_period = 6
  else if (b2o_is_defined(handle, "totalPrecipitationPast12Hours")) then
    k_rr = "totalPrecipitationPast12Hours"
    time_period = 12
  else if (b2o_is_defined(handle, "totalPrecipitationPast24Hours")) then
    k_rr = "totalPrecipitationPast24Hours"
    time_period = 24
  end if

  call append(k_rr, g_rr)
  call append("", g_trtr, obsvalue=time_period)
  call append("totalSnowDepth", g_sdepth)
  call append("", g_sfall)
  call append("characteristicOfPressureTendency", g_cpt)
  call append("horizontalVisibility", g_vv)
  call append("presentWeather", g_ww)
  call append("pastWeather1", g_w)
  call append("pastWeather2", g_w2)
  call append("cloudCoverTotal", g_n)
  call append("cloudAmount", g_nn)
  call append("cloudType", g_cl, rank=1)
  call append("cloudType", g_cm, rank=2)
  call append("cloudType", g_ch, rank=3)
  call append("heightOfBaseOfCloud", g_nh)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_synop_land_tac',1,zhook_handle)

contains

subroutine append(key, varno, obsvalue, vertco, press, ppcode, rank)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    real(b2o_double), intent(in), optional :: obsvalue, press
    integer(b2o_int), intent(in), optional :: vertco, ppcode, rank
    integer(b2o_int) :: vertco_type
    real(b2o_double) :: vertco_reference_1

    jobs = jobs + 1

    vertco_type = b2o_optional(g_gpheight, vertco)
    vertco_reference_1 = b2o_optional(stalt, press)

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = vertco_type
    body(jobs,body_vertco_reference_1) = vertco_reference_1
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag, rank)
    body(jobs,body_obsvalue) = b2o_optional(b2o_get_real_if_defined(handle, key, rank), obsvalue)
    conv_body(jobs,conv_body_ppcode) = b2o_optional(b2o_synop_ppcode(varno, vertco_type, vertco_reference_1), ppcode)

    if (varno == g_ps) then
        body(jobs,body_biascorr) = b2o_get_real_if_defined(handle, trim(key) // "->differenceStatisticalValue", nesting=-1)
    end if

end subroutine

end subroutine b2o_convert_synop_land_tac
