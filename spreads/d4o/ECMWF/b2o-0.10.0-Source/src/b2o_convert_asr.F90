subroutine b2o_convert_asr(handle, status)

use b2o_internal

implicit none

#include "calc_azim.h"

type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: rad(:,:)
real(kind=b2o_double), pointer :: rad_body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

real(kind=b2o_double) :: lat, lon
real(kind=b2o_double) :: sat_lon, sat_lat, sat_alt, zenith, azim
integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: date
integer(kind=b2o_int) :: iobs, jobs, k, r
integer(kind=b2o_int), parameter :: n_variables = 3
integer(kind=b2o_int), parameter :: n_channels = 8
logical :: found_wrong_zenith
character(len=16) :: statid
character(len=128) :: message

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_asr',0,zhook_handle)

call b2o_reserve(handle, n_variables * n_channels)

hdr      => b2o_use_table(handle, "hdr")
sat      => b2o_use_table(handle, "sat")
rad      => b2o_use_table(handle, "radiance")
rad_body => b2o_use_table(handle, "radiance_body")
body     => b2o_use_table(handle, "body")
errstat  => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

found_wrong_zenith = .false.

subset_loop: do while (b2o_next_subset(handle))

  satid = b2o_get_int(handle, "satelliteIdentifier")
  statid = ' '
  write (statid,'(i3.3)') satid

  date = b2o_get_date(handle)

  if (satid == 56) then
    sat_lat = 0
    sat_lon = 0
  else if (satid == 57 .and. date < 20130124) then
    sat_lat = 0
    sat_lon = -3.4
  else if (satid == 57) then
    sat_lat = 0
    sat_lon = 0
  else if (satid == 70 .and. date < 20151201) then
    sat_lat = 0
    sat_lon = -3.4
  else if (satid == 70) then
    sat_lat = 0
    sat_lon = 0.0
  else if (satid == 55 .and. date > 20161020) then
    sat_lat = 0
    sat_lon = 41.5
  else
    call b2o_log(handle, B2O_ERROR, "Unexpected satellite identifier: " // trim(statid))
    call b2o_exit(2)
  end if

  zenith = b2o_get_real_if_defined(handle, "satelliteZenithAngle")

  if (zenith == ODB_MISSING_REAL .or. zenith < 0_B2O_DOUBLE .or. zenith > 90_B2O_DOUBLE) then
    sat_alt = 6610839 * 1.E-6_B2O_DOUBLE * 6378.170_B2O_DOUBLE - 6378.170_B2O_DOUBLE
    call geosangl(b2o_get_real(handle, "latitude"), b2o_get_real(handle, "longitude"), sat_lon, sat_lat, sat_alt, zenith)
  end if

  if (zenith > 75._B2O_DOUBLE) then
    found_wrong_zenith = .true.
    cycle subset_loop
  end if

  iobs = iobs + 1

  ! Calculate azimuth
   azim = -999.0
   if ((sat_lat>-90.0_B2O_DOUBLE .and. sat_lat<90.0_B2O_DOUBLE) .and. (sat_lon>=-180.0_B2O_DOUBLE .and. sat_lon<=360.0_B2O_DOUBLE)) then
      if (b2o_is_defined(handle, 'latitude') .and. b2o_is_defined(handle, 'longitude')) then
         azim=calc_azim(b2o_get_real(handle, 'latitude'), &
                         & b2o_get_real(handle, 'longitude'), sat_lat, sat_lon)
      end if
      if (azim < 0._B2O_DOUBLE .or. azim > 360._B2O_DOUBLE) then
         write(message, "(a,f0.3)") "Found wrong azimuth angle - don't do slant: ", azim
         call b2o_log(handle, B2O_WARNING, message)
         status = B2O_SKIP_MESSAGE
      else
         sat(iobs,sat_azimuth)=azim
      end if
   end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "nonCoordinateHeight")
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = 21

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = 207
  sat(iobs,sat_zenith) = zenith

  call b2o_solar_zenith(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
       & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_zenith))
  call b2o_solar_azimuth(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
       & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_azimuth))

  rad(iobs,radiance_asr_pclear) = b2o_get_int(handle, "amountSegmentCloudFree")
  rad(iobs,radiance_asr_pcloudy) = b2o_get_int(handle, "cloudAmountInSegment", rank=1)
  rad(iobs,radiance_asr_pcloudy_low) = b2o_get_int(handle, "cloudAmountInSegment", rank=2)
  rad(iobs,radiance_asr_pcloudy_middle) = b2o_get_int(handle, "cloudAmountInSegment", rank=3)
  rad(iobs,radiance_asr_pcloudy_high) = b2o_get_int(handle, "cloudAmountInSegment", rank=4)

  channel_loop: do k = 1, n_channels

    r = 18 + 6 * (k-1)

    ! Brightness temperature

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "amountSegmentCloudFree")
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=r+1)
       
    errstat(jobs, errstat_repres_error) = b2o_get_real(handle, "brightnessTemperature->firstOrderStatisticalValue", rank=r+1)

    ! Brightness temperature clear sky

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt_clear
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=r+2)

    ! Brightness temperature cloudy sky

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt_cloudy
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=r+3)

  end do channel_loop

end do subset_loop

if (found_wrong_zenith) then
  call b2o_log(handle, B2O_WARNING, "Found wrong satellite zenith angle")
  call b2o_handle_shrink(handle, iobs)
end if

if (lhook) call dr_hook('b2o_convert_asr',1,zhook_handle)

end subroutine b2o_convert_asr
