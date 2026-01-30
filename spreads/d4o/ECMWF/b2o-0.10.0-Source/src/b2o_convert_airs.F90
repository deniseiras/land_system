subroutine b2o_convert_airs(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: rad(:,:)
real(kind=b2o_double), pointer :: rad_body(:,:)

integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_channels
integer(kind=b2o_int) :: satinst
character(len=8) :: s_satinst
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_airs',0,zhook_handle)

satinst = b2o_get_int(handle, "satelliteInstruments")

select case (satinst)
case (420) ! AQUA AIRS
  n_channels = b2o_get_int(handle, "extendedDelayedDescriptorReplicationFactor")
  if (n_channels /= 324) then
    call b2o_log(handle, B2O_ERROR, "The AIRS data does not contain 324 channels")
    status = B2O_SKIP_MESSAGE
    if (lhook) call dr_hook('b2o_convert_airs',1,zhook_handle)
    return
  end if
case (570) ! AQUA AMSU-A
  n_channels = 15
case (574) ! AQUA HSB
  n_channels = 4
case default
  write (s_satinst, "(i8)") satinst
  call b2o_log(handle, B2O_ERROR, "Unexpected satellite instrument: " // trim(s_satinst))
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook('b2o_convert_airs',1,zhook_handle)
  return
end select

call b2o_reserve(handle, n_channels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
rad => b2o_use_table(handle, "radiance")
rad_body => b2o_use_table(handle, "radiance_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = 11

  channel_loop: do k = 1, n_channels

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "channelNumber", rank=k)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)

    ! Set rejected if QC flag non-zero
    if (b2o_get_real(handle, "channelQualityFlagsForAtovs", rank=k) /= 0) then
      body(jobs,body_obsvalue) = ODB_MISSING_REAL
    end if

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = satinst
  sat(iobs,sat_zenith) = b2o_get_real(handle,"satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")

  if (b2o_is_missing(handle, "solarZenithAngle")) then
    call b2o_solar_zenith(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
      & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_zenith))
  else
    sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  end if
  if (b2o_is_missing(handle, "solarAzimuth")) then
    call b2o_solar_azimuth(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
     & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_azimuth))
  else
    sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  end if

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")
  rad(iobs,radiance_cldcover) = b2o_get_int(handle, "cloudCoverTotal")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_airs',1,zhook_handle)

end subroutine b2o_convert_airs
