subroutine b2o_convert_viirs_aot(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: resat(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)


integer(kind=b2o_int) :: k
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int), parameter :: n_channels = 11

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_viirs_aot',0,zhook_handle)

call b2o_reserve(handle, n_channels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
resat => b2o_use_table(handle, "resat")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_retrtype) = 0 ! no averaging kernels
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = b2o_get_int(handle, "satelliteInstruments")

  channel_loop: do k = 1, n_channels

    jobs = jobs + 1

    body(jobs,body_varno) = g_od
    body(jobs,body_vertco_type) = g_cha_wavelength
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "satelliteChannelWavelength", rank=k)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "aerosolOpticalThickness", rank=k)
    errstat(jobs,errstat_obs_error) = b2o_get_real_if_defined(handle, "aerosolOpticalThickness->firstOrderStatisticalValue", rank=k)

  end do channel_loop

  resat(iobs,resat_instrument_type) = b2o_get_int(handle, "satelliteInstruments")
  resat(iobs,resat_surface_type_indicator) = b2o_get_real(handle, "surfaceType")

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_real(handle, "satelliteInstruments")
  sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_viirs_aot',1,zhook_handle)

end subroutine b2o_convert_viirs_aot
