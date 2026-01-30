#include "b2o_debug.h"

subroutine b2o_convert_gmi(handle, status)

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

integer(kind=b2o_int) :: channel
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: n_channels
integer(kind=b2o_int) :: chan
integer(kind=b2o_int) :: k

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_gmi',0,zhook_handle)

n_channels = 13

call b2o_reserve(handle, n_channels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
rad => b2o_use_table(handle, "radiance")
body => b2o_use_table(handle, "body")
rad_body => b2o_use_table(handle, "radiance_body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_distribtype) = 2 ! call grid_nearest but don't redistribute on model grid
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_real(handle, "latitude", rank=2)  ! First latitude is spacecraft latitude, so we need the second occurence
  hdr(iobs,hdr_lon) = b2o_get_real(handle, "longitude", rank=2) ! Same for longitude
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "height")
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = 71

  chan = b2o_get_int(handle, "channelNumber")
  if (chan <= 9) then ! This subset contains data for channels 1-9

    channel_loop: do channel=1,9

        jobs=jobs+1
        body(jobs,body_varno) = g_rawbt
        body(jobs,body_vertco_type) = g_tovs_cha
        body(jobs,body_vertco_reference_1) = channel
        body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=channel)
        rad_body(jobs,radiance_body_zenith_by_channel) = b2o_get_real(handle, "satelliteZenithAngle", rank=channel)

    end do channel_loop

    ! Fill in rows for high frequency channels with missing data
    empty_channel_loop: do channel=10,13

        jobs = jobs + 1
        body(jobs,body_varno) = g_rawbt
        body(jobs,body_vertco_type) = g_tovs_cha
        body(jobs,body_vertco_reference_1) = channel

    end do empty_channel_loop

  else ! This subset contains data for channels 10-13

    empty_channel_loop2: do channel=1,9

        jobs = jobs + 1
        body(jobs,body_varno) = g_rawbt
        body(jobs,body_vertco_type) = g_tovs_cha
        body(jobs,body_vertco_reference_1) = channel  

    end do empty_channel_loop2
    
    ! Fill in rows for high frequency channels with missing data

    channel_loop2: do k=1,4

        jobs = jobs + 1
        body(jobs,body_varno) = g_rawbt
        body(jobs,body_vertco_type) = g_tovs_cha
        body(jobs,body_vertco_reference_1) = channel
        body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
        rad_body(jobs,radiance_body_zenith_by_channel) = b2o_get_real(handle, "satelliteZenithAngle", rank=k)
        channel = channel + 1

    end do channel_loop2
  endif

  call b2o_assert(channel-1 == n_channels)

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = 519
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "coordinatesSignificance")
  sat(iobs,sat_lsm_fov) = 0.01 * b2o_get_real(handle, "spacecraftRoll") !stored in % in temporary location
  
  if (b2o_is_missing(handle, "satelliteZenithAngle")) then
    call b2o_log(handle, B2O_WARNING, "b2o_convert_gmi: Zenith Angle not found")
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end if

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "coordinatesSignificance", rank=2) ! Need second instance as first stores azimuth

end do subset_loop

if (lhook) call dr_hook('b2o_convert_gmi',1,zhook_handle)

end subroutine b2o_convert_gmi
