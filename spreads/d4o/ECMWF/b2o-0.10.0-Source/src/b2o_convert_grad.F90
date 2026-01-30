subroutine b2o_convert_grad(handle, status)

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
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int), parameter :: n_channels = 6

character(len=128) :: message
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_grad',0,zhook_handle)

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
  write (statid,'(i3.3)') b2o_get_int(handle, "satelliteIdentifier")
  satid=b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "nonCoordinateHeight")
  hdr(iobs,hdr_numlev) = n_channels

  date = b2o_get_date(handle)

  ! Hard-coded longitudes are used for slant-path. If this is not specified here 
  ! for a particular satellite/date range, slant-path processing will not be 
  ! performed (azimuth will be invalid).
  sat_lat=-999.0
  sat_lon=-999.0
  
  if (satid == 257) then
    sat_lat=0
    sat_lon=-75
  else if (satid == 259 .and. date < 20181023) then
    sat_lat=0
    sat_lon=-135
  else if (satid == 259) then
    sat_lat=0
    sat_lon=-128
  else if (satid == 54) then
    sat_lat=0
    sat_lon=57.3
  else
    call b2o_log(handle, B2O_WARNING, "Don't do slant path for this satellite - no lon val: " // trim(statid))
  end if

  select case (b2o_get_int(handle, "satelliteIdentifier"))
  case (250:259)
    hdr(iobs,hdr_sensor) = 22
    sat(iobs,sat_satellite_instrument) = 615
  case (50:54,59)
    hdr(iobs,hdr_sensor) = 20
    sat(iobs,sat_satellite_instrument) = 205
  case (510)
    call b2o_log(handle, B2O_WARNING, "BUFR values not yet known for FY-2!: " // trim(statid))
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  case default
    call b2o_log(handle, B2O_ERROR, "Unexpected satellite identifier: " // trim(statid))
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end select

  channel_loop: do k = 1, n_channels

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
    rad_body(jobs,radiance_body_csr_pclear) = b2o_get_real(handle, "amountOfSegmentCloudFree", rank=k)
    errstat(jobs, errstat_repres_error) = b2o_get_real_if_defined(handle,  &
        & "brightnessTemperature->firstOrderStatisticalValue", rank=k)

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

if (lhook) call dr_hook('b2o_convert_grad',1,zhook_handle)

end subroutine b2o_convert_grad
