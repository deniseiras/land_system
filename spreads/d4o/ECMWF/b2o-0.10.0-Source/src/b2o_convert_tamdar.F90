subroutine b2o_convert_tamdar(handle, status)

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
real(kind=b2o_double) :: level
character(len=8) :: statid
character(len=64) :: message, flightLevel, gnssAltitude

real(kind=b2o_double) :: zhook_handle
!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_tamdar',0,zhook_handle)

if (b2o_is_defined(handle, "globalNavigationSatelliteSystemAltitude")) then
    ! FLYHT template
    flightLevel  = "flightLevel"
    gnssAltitude = "globalNavigationSatelliteSystemAltitude"
    n_variables  = 8
else if (b2o_is_defined(handle, "height")) then
    ! Panasonic template (with mixed up flightLevel and GNSS height)
    flightLevel  = "height"
    gnssAltitude = "flightLevel"
    n_variables  = 10
else
    call b2o_log(handle, B2O_ERROR, "Unsupported TAMDAR template")
    call b2o_exit(1)
end if

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

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid, to_double)
  hdr(iobs,hdr_numlev) = 1

  conv(iobs,conv_flight_phase) = b2o_get_int(handle, "phaseOfAircraftFlight")

  level = b2o_get_real(handle, flightLevel)

  call append("", g_z)

  call append("windDirection", g_dd)
  call append("windSpeed", g_ff)

  call append("", g_u)
  call append("", g_v)

  call append("airTemperature", g_t)
  call append("relativeHumidity", g_rh)

  call append("", g_q)

  if (n_variables == 10) then
    call append("airframeIcing", g_airframe_icing)
    call append("turbulenceIndex", g_turbulence_index)
  end if

end do subset_loop

if (lhook) call dr_hook('b2o_convert_tamdar',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    integer(b2o_int) :: quality, rdbflag
    real(b2o_double) :: obsvalue, uncertainty
    real(b2o_double) :: altitude

    jobs = jobs + 1

    rdbflag  = 0
    obsvalue = b2o_get_real(handle, key)

    if (len_trim(key) /= 0) then
        quality = b2o_get_int(handle, trim(key) // "->associatedField")
        if (quality < 0 .or. quality > 3) quality = 3
        rdbflag = b2o_set_bits(quality, 12, 2)
    end if

    if (varno == g_rh .and. obsvalue /= ODB_MISSING_REAL) then
        if (0.d0 > obsvalue .or. obsvalue > 200.d0) then
            obsvalue = ODB_MISSING_REAL
        else
            obsvalue = obsvalue / 100.d0
        end if
    end if

    if (any(varno==(/g_rh, g_q/))) then

        uncertainty = b2o_get_real(handle, "relativeHumidity->associatedField")

             if (uncertainty >= 0 .and. uncertainty <=  15) then; quality = 0
        else if (uncertainty > 15 .and. uncertainty <=  20) then; quality = 1
        else if (uncertainty > 20 .and. uncertainty <=  80) then; quality = 2
        else if (uncertainty > 80 .and. uncertainty <= 100) then; quality = 3
        else
            write (message,*) "Invalid uncertainty value: ", uncertainty
            call b2o_log(handle, B2O_WARNING, message)
            quality = 3
        end if

        rdbflag = b2o_set_bits(quality, 12, 2)

    else if (varno == g_z) then
        altitude = b2o_get_real(handle, gnssAltitude)
        obsvalue = b2o_height_to_geopotential(altitude, hdr(iobs,hdr_lat))
    end if

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) =  g_gpheight
    body(jobs,body_vertco_reference_1) = level
    body(jobs,body_datum_rdbflag) = rdbflag
    body(jobs,body_obsvalue) = obsvalue

end subroutine

end subroutine b2o_convert_tamdar
