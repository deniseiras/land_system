#include "b2o_debug.h"

subroutine b2o_convert_mwri_1d(handle, status)

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

integer(kind=b2o_int) :: satinst, sensor
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_channels
character(len=16) :: statid
character(len=64) :: message

integer(kind=b2o_int), parameter :: MWTS = 934
integer(kind=b2o_int), parameter :: MWHS = 936
integer(kind=b2o_int), parameter :: MWRI = 938

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_mwri_1d',0,zhook_handle)

satinst = b2o_get_int(handle, "satelliteInstruments")

select case (satinst)
case (MWTS) ; n_channels = 4
case (MWHS) ; n_channels = 5
case (MWRI) ; n_channels = 10
case default
  write (message, "(a,i0)") "Unsupported satellite instrument: ", satinst
  call b2o_log(handle, B2O_ERROR, message)
  call b2o_exit(2)
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
  write (statid,'(i5.5)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_distribtype) = 2 ! call grid_nearest but don't redistribute on model grid
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_channels

  select case (satinst)
  case (MWTS) ; sensor = 40
  case (MWHS) ; sensor = 41
  case (MWRI) ; sensor = 43
  end select
  hdr(iobs,hdr_sensor) = sensor

  channel_loop: do k = 1, n_channels

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "channelNumber", rank=k)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")
  rad(iobs,radiance_orbit) = 10 ! b2o_get_int(handle, "orbitNumber")
  rad(iobs,radiance_typesurf) = b2o_get_int_if_defined(handle, "heightOfStation")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_mwri_1d',1,zhook_handle)

end subroutine b2o_convert_mwri_1d
