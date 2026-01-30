#include "b2o_debug.h"

subroutine b2o_convert_amsr2_1d(handle, status)

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
integer(kind=b2o_int), parameter :: n_channels = 14
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_amsr2_1d',0,zhook_handle)

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
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_distribtype) = 2 ! call grid_nearest but don't redistribute on model grid
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = 63

  channel_loop: do k = 1, n_channels

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
    body(jobs,body_vertco_type) = g_tovs_cha
    ! body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "channelNumber", rank=k)
    body(jobs,body_vertco_reference_1) = k

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")
  sat(iobs,sat_lsm_fov) = 0.01 * b2o_get_real(handle, "instrumentTemperature", rank=1)  ! in % in temporary location
  ! sat(iobs,k_sunglint_angle) = b2o_get_real(handle, "solarAzimuth") ! obtain from temporal location
  ! sat(iobs,k_ad_orbit) = b2o_get_int(handle, "solarZenithAngle") ! obtain from temporal location

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")
  rad(iobs,radiance_orbit) = b2o_get_int(handle, "orbitNumber")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_amsr2_1d',1,zhook_handle)

end subroutine b2o_convert_amsr2_1d
