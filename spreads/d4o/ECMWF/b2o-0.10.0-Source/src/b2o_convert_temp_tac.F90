subroutine b2o_convert_temp_tac(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)
real(kind=b2o_double), pointer :: body(:,:)

integer(kind=b2o_int), parameter :: n_variables = 9
integer(kind=b2o_int) :: report_rdbflag, datum_rdbflag
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: level_flags
integer(kind=b2o_int) :: significance
character(len=16) :: statid
real(kind=b2o_double) :: pressure

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_temp_tac',0,zhook_handle)

n_levels = b2o_get_int(handle, "delayedDescriptorReplicationFactor")

if (n_levels <= 0 .or. n_levels == ODB_MISSING_INT) then
  call b2o_log(handle, B2O_WARNING, "Invalid number of levels")
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook("b2o_convert_temp", 1, zhook_handle)
  return
end if

call b2o_reserve(handle, n_variables * n_levels)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  if (b2o_is_defined(handle, "blockNumber")) then
    statid = b2o_get_station_id(handle, status)
    if (status /= B2O_SUCCESS) exit subset_loop
  else if (b2o_is_defined(handle, "shipOrMobileLandStationIdentifier")) then ! ship temp
    call b2o_get_string(handle, "shipOrMobileLandStationIdentifier", statid)
  else if (b2o_is_defined(handle, "carrierBalloonOrAircraftIdentifier")) then ! drop sonde
    call b2o_get_string(handle, "carrierBalloonOrAircraftIdentifier", statid)
  end if

  call b2o_log(handle, B2O_WARNING, "Converting radiosonde '" // trim(statid) // "'")

  report_rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = n_levels

  conv(iobs,conv_sonde_type) = b2o_get_real(handle, "radiosondeType")

  level_loop: do k = 1, n_levels

    pressure = b2o_get_real(handle, "pressure", rank=k)
    datum_rdbflag  = b2o_get_rdbflag(handle, "pressure", 27, 0, rank=k)

    if (pressure <= 0._B2O_DOUBLE) then
        call b2o_log(handle, B2O_WARNING, "Found zero or negative pressure -- resetting to missing value")
        pressure = ODB_MISSING_REAL
    end if

    significance = b2o_get_int(handle, "verticalSoundingSignificance", rank=k)
    level_flags = b2o_sounding_significance_flags(8001, significance, pressure)

    call append("nonCoordinateGeopotential", g_z)
    call append("airTemperature", g_t)
    call append("dewpointTemperature", g_td)
    call append("", g_rh)
    call append("", g_q)
    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)
    call append("", g_u)
    call append("", g_v)

  end do level_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_temp_tac',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    real(b2o_double) :: obsvalue

    jobs = jobs + 1

    obsvalue = b2o_get_real(handle, key, rank=k)

    body(jobs,body_varno) = varno
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag, rank=k)
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = pressure
    body(jobs,body_obsvalue) = obsvalue
    conv_body(jobs,conv_body_level) = level_flags

    if (varno == g_z) then
        body(jobs,body_obsvalue) = b2o_get_real_if_defined(handle, trim(key) // "->substitutedValue", rank=k, default=obsvalue)
    end if

end subroutine

end subroutine b2o_convert_temp_tac
