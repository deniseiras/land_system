subroutine b2o_convert_atms(handle, status)

use b2o_internal
use b2o_option, only : B2O_ALL_SKY

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: rad(:,:)
real(kind=b2o_double), pointer :: rad_body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

real(kind=b2o_double) :: bufrtype, subtype
integer(kind=b2o_int) :: iobs, jobs, k, satid
integer(kind=b2o_int) :: n_channels
integer(kind=b2o_int) :: n_body_entries
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

#include "datastream.h"

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('bufr2odb_atms',0,zhook_handle)

n_channels = b2o_get_int(handle, "extendedDelayedDescriptorReplicationFactor")

if (B2O_ALL_SKY) then
  n_body_entries = 7 ! all-sky performance saving - only all but 7 ATMS channels
else
  n_body_entries = n_channels
end if

call b2o_reserve(handle, n_body_entries)

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
  satid = b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "height")
  hdr(iobs,hdr_numlev) = n_body_entries
  hdr(iobs,hdr_sensor) = 19
  hdr(iobs,hdr_distribtype) = merge(2, 0, B2O_ALL_SKY)

  channel_loop: do k = 1, n_channels

    ! Brightness temperature

    if (B2O_ALL_SKY .and. k < 16) then
      cycle channel_loop ! all-sky performance saving - ignore all but 7 ATMS channels
    end if

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "channelNumber", rank=k)
    if (satid == 225 .and. hdr(iobs,hdr_date) < 20180726) then
      body(jobs,body_obsvalue) = b2o_get_real(handle, "antennaTemperature", rank=k)
    else
      body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
    endif

    rad_body(jobs,radiance_body_cold_nedt) = b2o_get_real(handle, "noiseEquivalentDeltaTemperatureWhileViewingColdTarget", rank=k)
    rad_body(jobs,radiance_body_warm_nedt) = b2o_get_real(handle, "noiseEquivalentDeltaTemperatureWhileViewingWarmTarget", rank=k)
    rad_body(jobs,radiance_body_channel_qc) = b2o_get_int(handle, "channelDataQualityFlags", rank=k)

  end do channel_loop

  ! Exclude cases for which brightness temperatures are unbelievable

  where (body((jobs-n_channels+1):jobs,body_obsvalue) > 330.0_B2O_DOUBLE .or. &
   &     body((jobs-n_channels+1):jobs,body_obsvalue) < 85.0_B2O_DOUBLE)
    body((jobs-n_channels+1):jobs,body_obsvalue) = ODB_MISSING_REAL
  end where

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_gen_centre) = b2o_get_int(handle, "centre")
  sat(iobs,sat_gen_subcentre) = b2o_get_int(handle, "subCentre")

  bufrtype = b2o_get_int(handle, "dataCategory")
  subtype = b2o_get_int(handle, "dataSubCategory")
  sat(iobs,sat_datastream) = datastream(bufrtype, subtype, &
   &   sat(iobs,sat_gen_centre),sat(iobs,sat_gen_subcentre),&
   &   sat(iobs,sat_satellite_identifier))

  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
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
  rad(iobs,radiance_orbit) = b2o_get_int(handle, "orbitNumber")

end do subset_loop

if (lhook) call dr_hook('bufr2odb_atms',1,zhook_handle)

end subroutine b2o_convert_atms
