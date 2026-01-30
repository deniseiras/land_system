subroutine b2o_convert_acars(handle, status)

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
real(kind=b2o_double) :: pressure

character(len=8) :: statid
character(len=64) :: message

real(kind=b2o_double) :: zhook_handle
!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_acars',0,zhook_handle)

select case (handle%subtype)
case (145) ; n_variables = 5 ! ACARS
case (149) ; n_variables = 9 ! ACARS+MR
end select

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

  report_rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(statid, to_double)
  hdr(iobs,hdr_numlev) = 1

  conv(iobs,conv_flight_phase) = b2o_get_int(handle, "phaseOfAircraftFlight")

  pressure = b2o_get_real(handle, "pressure")
  datum_rdbflag = b2o_get_rdbflag(handle, "pressure", 27, 0)

  select case (handle%subtype)
  case (145) ! ACARS
    call append("airTemperature", g_t)
    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)
    call append("", g_u)
    call append("", g_v)
  case (149) ! ACARS+MR
    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)
    call append("", g_u)
    call append("", g_v)
    call append("airTemperature", g_t)
    call append("mixingRatio", g_humidity_mixing_ratio)
    call append("relativeHumidity", g_rh)
    call append("", g_q)
    call append("airframeIcing", g_airframe_icing)
  end select

end do subset_loop

if (lhook) call dr_hook('b2o_convert_acars',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    real(b2o_double) :: obsvalue

    jobs = jobs + 1

    obsvalue = b2o_get_real(handle, key)

    ! Dismiss unreasonable relative humidity values
    if (varno == g_rh .and. obsvalue /= ODB_MISSING_REAL) then
        if (0.d0 > obsvalue .or. obsvalue > 100.d0) then
            obsvalue = ODB_MISSING_REAL
        else
            obsvalue = obsvalue / 100.d0
        end if
    end if

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = pressure
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag)
    body(jobs,body_obsvalue) = obsvalue

end subroutine

end subroutine b2o_convert_acars
