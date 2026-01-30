subroutine b2o_convert_airep(handle, status)

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
integer(kind=b2o_int) :: report_rdbflag, datum_rdbflag
integer(kind=b2o_int) :: iobs, jobs
real(kind=b2o_double) :: height

character(len=8) :: flight_number, tail_number

real(kind=b2o_double) :: zhook_handle
!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_airep',0,zhook_handle)

n_variables = 5

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

  call b2o_get_string(handle, "aircraftFlightNumber", flight_number)
  call b2o_get_string_if_defined(handle, "aircraftTailNumber", tail_number)

  report_rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(flight_number, to_double)
  hdr(iobs,hdr_wigosid(1)) = transfer(tail_number, to_double)
  hdr(iobs,hdr_numlev) = 1

  conv(iobs,conv_flight_phase) = b2o_get_int(handle, "phaseOfAircraftFlight")

  if (len_trim(tail_number) > 0) then
    ! In the lookup table, tail numbers are prefixed with underscore
    tail_number(1:8) = "_" // tail_number(1:7)
  end if

  conv(iobs,conv_aircraft_type) = b2o_get_aircraft_type(handle, transfer(tail_number, to_double))

  height = b2o_get_real(handle, "height")
  datum_rdbflag = b2o_get_rdbflag(handle, "height", 27, 0)

  ! AIREP/AMDAR

  call append("airTemperature", g_t)
  call append("windDirection", g_dd)
  call append("windSpeed", g_ff)

  call append("", g_u)
  call append("", g_v)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_airep',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = height
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag)
    body(jobs,body_obsvalue) = b2o_get_real(handle, key)

end subroutine

end subroutine b2o_convert_airep
