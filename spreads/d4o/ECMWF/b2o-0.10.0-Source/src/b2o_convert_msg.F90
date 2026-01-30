subroutine b2o_convert_msg(handle, status)

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

real(kind=b2o_double) :: sat_lon, sat_lat, lat, lon, azim

integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: date
integer(kind=b2o_int) :: iobs, jobs, k, counter
integer(kind=b2o_int) :: channel_start = 1
integer(kind=b2o_int) :: channel_end = 10
integer(kind=b2o_int), parameter :: n_channels = 10

character(len=128) :: message
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_msg',0,zhook_handle)

call b2o_reserve(handle, n_channels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
rad => b2o_use_table(handle, "radiance")
rad_body => b2o_use_table(handle, "radiance_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while(b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i3.3)') b2o_get_int(handle, "satelliteIdentifier")
  satid=b2o_get_int(handle, "satelliteIdentifier")

  date = b2o_get_date(handle)

  ! Hard-coded longitudes are used for slant-path. If this is not specified here 
  ! for a particular satellite/date range, slant-path processing will not be 
  ! performed (azimuth will be invalid).
  sat_lat=-999.0
  sat_lon=-999.0

  if (satid == 173) then
    sat_lat=0
    sat_lon=140.7
  else if (satid == 270) then
    sat_lat=0
    sat_lon=-75.2
  else if (satid == 271) then
    sat_lat=0
    sat_lon=-137.2
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "nonCoordinateHeight")
  hdr(iobs,hdr_numlev) = n_channels

  channel_start = 1
  channel_end = 10

  select case (b2o_get_int(handle, "satelliteIdentifier"))
  case (71:74) ! SEVIRI Eumetsat (pre-operational)
    hdr(iobs,hdr_sensor) = 21
    sat(iobs,sat_satellite_instrument) = 207
  case (55:58) ! SEVIRI Eumetsat (operational)
    hdr(iobs,hdr_sensor) = 21
    sat(iobs,sat_satellite_instrument) = 207
  case (171,172) ! MTSAT-1R Imager (Japanese)
    hdr(iobs,hdr_sensor) = 24
    sat(iobs,sat_satellite_instrument) = 294
  case (173,174) ! AHI (Japanese)
    hdr(iobs,hdr_sensor) = 56
    sat(iobs,sat_satellite_instrument) = 297
  case (270) ! GOES-16 ABI (NOAA) V2 processing
    hdr(iobs,hdr_sensor) = 44
    sat(iobs,sat_satellite_instrument)=617
    ! V1 processing
    if (date < 20210413) then ! Switch to the V2 stream in operations
      channel_start = 3
      channel_end = 12
    end if
  case (271) ! GOES-17 ABI (NOAA) V2 processing (removes 2 NIR channels wrt V1)
    hdr(iobs,hdr_sensor) = 44
    sat(iobs,sat_satellite_instrument)=617
  case default
    call b2o_log(handle, B2O_ERROR, "Unexpected satellite identifier" // trim(statid))
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end select

  counter=0
  channel_loop: do k = channel_start, channel_end
    counter = counter + 1

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = counter
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
    errstat(jobs, errstat_repres_error) = b2o_get_real_if_defined(handle, &
      & "brightnessTemperature->firstOrderStatisticalValue", rank=k)
    rad_body(jobs,radiance_body_csr_pclear) = b2o_get_real(handle, "amountSegmentCloudFree", rank=k)

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")

  call b2o_solar_zenith(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
       & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_zenith))
  call b2o_solar_azimuth(hdr(iobs,hdr_date), hdr(iobs,hdr_time), &
       & hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_azimuth))

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

end do subset_loop

if (lhook) call dr_hook('b2o_convert_msg',1,zhook_handle)

end subroutine b2o_convert_msg
