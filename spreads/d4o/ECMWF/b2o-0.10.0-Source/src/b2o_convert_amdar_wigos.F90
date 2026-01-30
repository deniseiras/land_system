subroutine b2o_convert_amdar_wigos(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)

integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: iobs, jobs
real(kind=b2o_double) :: flight_level

character(len=8) :: statid
character(len=64) :: message

real(kind=b2o_double) :: zhook_handle
!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_amdar_wigos',0,zhook_handle)

n_variables = 9

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

  call b2o_get_string(handle, "aircraftRegistrationNumberOrOtherIdentification", statid)
  if (len_trim(statid) == 0) then
    call b2o_get_string(handle, "aircraftFlightNumber", statid)
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid, to_double)
  hdr(iobs,hdr_numlev) = 1

  if (b2o_get_int(handle, "aircraftRollAngleQuality", default=0) == 1) then
    hdr(iobs,hdr_report_rdbflag) = b2o_set_bit(1)
  end if

  conv(iobs,conv_flight_phase) = b2o_get_int(handle, "detailedPhaseOfFlight")
  conv(iobs,conv_aircraft_type) = b2o_get_aircraft_type(handle, hdr(iobs,hdr_statid))

  flight_level = b2o_get_real(handle, "flightLevel")

  call append("windDirection", g_dd)
  call append("windSpeed", g_ff)

  call reserve(g_u)
  call reserve(g_v)

  call append("airTemperature", g_t)
  call append("mixingRatio", g_humidity_mixing_ratio)
  call append("relativeHumidity", g_rh)

  call reserve(g_q)

  call append_if_defined("turbulenceIndex", g_turbulence_index)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_amdar_wigos',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    call reserve(varno)
    body(jobs,body_obsvalue) = b2o_get_real(handle, key)

end subroutine

subroutine append_if_defined(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    call reserve(varno)
    body(jobs,body_obsvalue) = b2o_get_real_if_defined(handle, key)

end subroutine

subroutine reserve(varno)

    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = flight_level

end subroutine

end subroutine b2o_convert_amdar_wigos
