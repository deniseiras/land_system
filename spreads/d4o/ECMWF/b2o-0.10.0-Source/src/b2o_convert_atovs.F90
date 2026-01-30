subroutine b2o_convert_atovs(handle, status)

use b2o_internal
use b2o_option, only : B2O_ALL_SKY

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

real(kind=b2o_double) :: bufrtype, subtype
real(kind=b2o_double) :: nedt
integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: satinst
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_channels
character(len=128) :: message
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

#include "datastream.h"

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_atovs',0,zhook_handle)

if (b2o_is_defined(handle, "satelliteSensorIndicator")) then
  satinst = b2o_get_int(handle, "satelliteSensorIndicator")
elseif (b2o_is_defined(handle, "satelliteInstruments")) then ! SAPHIR
  satinst = b2o_get_int(handle, "satelliteInstruments")
#ifdef DMIATOVS
elseif (b2o_is_defined(handle, "tovsOrAtovsOrAvhrrInstrumentationChannelNumber", rank=1)) then
  k = b2o_get_int(handle, "tovsOrAtovsOrAvhrrInstrumentationChannelNumber", rank=1)
  if (k == 1) then
    satinst = 3
  elseif (k == 43) then
    if (satid > 14 .and. satid < 18) then ! AMSU-B from NOAA15 through NOAA17
      satinst = 4
    else
      satinst = 11
    endif
  endif
#endif
else
  satinst = -1
endif

select case (satinst)
case (0)    ; n_channels = 20 ! HIRS
case (1)    ; n_channels = 4  ! MSU
case (2)    ; n_channels = 3  ! SSU
case (3)    ; n_channels = 15 ! AMSU-A
case (4,11) ; n_channels = 5  ! AMSU-B/MHS
case (5)    ; n_channels = 5  ! AVHRR
case (6)    ; n_channels = 7  ! SSMI/BT
case (7,8)  ; n_channels = 8  ! VTPR
case (941)  ; n_channels = 6  ! SAPHIR
case default
  write (message, "(a,i0)") "Unexpected satellite sensor: ", satinst
  call b2o_log(handle, B2O_ERROR, message)
  call b2o_exit(B2O_VALUE_ERROR)
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
  if (b2o_is_defined(handle, "satelliteIdentifier")) then
    satid = b2o_get_int(handle, "satelliteIdentifier")
    write (statid,'(i8)') satid
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = satinst
  hdr(iobs,hdr_distribtype) = merge(2, 0, B2O_ALL_SKY)

  if (satinst == 11) then
    hdr(iobs,hdr_sensor) = 15 ! MHS RTTOV ID
  elseif (satinst == 941) then
    hdr(iobs,hdr_sensor) = 34 ! SAPHIR RTTOV ID
  end if

  channel_loop: do k = 1, n_channels

    if (b2o_is_missing(handle, "tovsOrAtovsOrAvhrrInstrumentationChannelNumber", rank=k)) then
      exit channel_loop
    end if

    if (b2o_is_defined(handle, "brightnessTemperature", rank=k)) then

      ! Brightness temperature

      jobs = jobs + 1

      body(jobs,body_varno) = g_rawbt
      body(jobs,body_vertco_type) = g_tovs_cha
      body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperature", rank=k)
      if (satinst == 3 .or. (satinst == 11 .and. B2O_ALL_SKY) .or. satinst == 941) then ! AMSU-A, MHS in all-sky, or SAPHIR
        body(jobs,body_vertco_reference_1) = k
      else
        body(jobs,body_vertco_reference_1) = b2o_get_int(handle, "tovsOrAtovsOrAvhrrInstrumentationChannelNumber", rank=k, &
          & default=k)
      end if
      nedt = b2o_get_real_if_defined(handle, "brightnessTemperature->noiseEquivalentDeltaTemperatureNedtQualityIndicatorsForWarmTargetCalibration", rank=k)
      if (nedt /= ODB_MISSING_REAL) then
        rad_body(jobs,radiance_body_warm_nedt) = nedt
      endif

    else if (b2o_is_defined(handle, "channelRadiance")) then ! will account for HIRS radiance

      ! Radiance

      jobs = jobs + 1

      body(jobs,body_varno) = g_rawbt
      body(jobs,body_vertco_type) = g_tovs_cha
      if (b2o_is_defined(handle, "channelRadiance", rank=k)) then
        body(jobs,body_obsvalue) = b2o_get_real(handle, "channelRadiance", rank=k)
      else ! HIRS radiance in channel 20
        body(jobs,body_obsvalue) = b2o_get_real(handle, "channelRadiance")
      end if
      body(jobs,body_vertco_reference_1) = b2o_get_int(handle, "tovsOrAtovsOrAvhrrInstrumentationChannelNumber", rank=k, default=k)

    else
      call b2o_log(handle, B2O_ERROR, "Brightness temperature or radiance not found")
      call b2o_exit(2)
    end if

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_gen_centre) = b2o_get_int(handle, "centre")
  sat(iobs,sat_gen_subcentre) = b2o_get_int(handle, "subCentre")

  bufrtype = b2o_get_int(handle, "dataCategory")
  subtype = b2o_get_int(handle, "dataSubCategory")
  sat(iobs,sat_datastream) = datastream(bufrtype, subtype, &
   &   sat(iobs,sat_gen_centre),sat(iobs,sat_gen_subcentre),&
   &   sat(iobs,sat_satellite_identifier))

  if (.not.b2o_is_missing(handle, "satelliteZenithAngle")) then
    sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  elseif (.not.b2o_is_missing(handle, "incidenceAngle")) then
    sat(iobs,sat_zenith) = b2o_get_real(handle, "incidenceAngle") ! for SAPHIR?
  else
    satinst = -1
  endif

  if (satinst /= 941) then
    sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")
  else
    ! SAPHIR quick workaround for lack of azimuth angle (it doesn't matter
    ! too much because even channel 6 is essentially insensitive to the surface)
    sat(iobs,sat_azimuth) = 0.0
  endif

  if (b2o_is_missing(handle, "solarZenithAngle")) then
    call b2o_solar_zenith(hdr(iobs,hdr_date), hdr(iobs,hdr_time), hdr(iobs,hdr_lat), hdr(iobs,hdr_lon), sat(iobs,sat_solar_zenith))
  else
    sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  end if

  if (b2o_is_missing(handle, "solarAzimuth")) then
    call b2o_solar_azimuth(hdr(iobs,hdr_date), hdr(iobs,hdr_time), hdr(iobs,hdr_lat), hdr(iobs,hdr_lon),  &
        & sat(iobs,sat_solar_azimuth))
  else
    sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  end if

  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")

  ! Handle cases of strange azimuth angles
  ! All global NOAA data before the 2018011512 cycle and, until 2015120113, the non-AAPP EARS/RARS stations provide
  ! "relative azimuth" angle
  if (   (satid > 205 .and. satid < 224 .and. sat(iobs,sat_datastream) == 0 &
   &      .and. ( hdr(iobs,hdr_date) < 20180115 .or. (hdr(iobs,hdr_date) == 20180115 .and. hdr(iobs,hdr_time) < 90000 ))) &
   & .or.(sat(iobs,sat_datastream) > 0 &
   &      .and. (     sat(iobs,sat_gen_subcentre) == 70 & ! Monterey
   &             .or. sat(iobs,sat_gen_subcentre) == 80 & ! Wallops
   &             .or. sat(iobs,sat_gen_subcentre) == 90 & ! Gilmore Creek
   &             .or. sat(iobs,sat_gen_subcentre) == 120& ! Ewa Beach
   &             .or. sat(iobs,sat_gen_subcentre) == 130)& ! Miami
   &      .and. ( hdr(iobs,hdr_date) < 20151201 .or. (hdr(iobs,hdr_date) == 20151201 .and. hdr(iobs,hdr_time) <= 130000 ))))then 
    sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth") + sat(iobs,sat_solar_azimuth)
    if(sat(iobs,sat_azimuth) > 360.0_B2O_DOUBLE) sat(iobs,sat_azimuth) = sat(iobs,sat_azimuth) -  360.0_B2O_DOUBLE
  else
    sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")
  endif

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")
  rad(iobs,radiance_orbit) = b2o_get_int(handle, "orbitNumber")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_atovs',1,zhook_handle)

end subroutine b2o_convert_atovs
