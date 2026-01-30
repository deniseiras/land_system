subroutine b2o_convert_fy3(handle, status)

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
real(kind=b2o_double) :: z_non_dt, Tb
integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: nonlin_corr_version ! used for FY-3 non-linearity correction
integer(kind=b2o_int) :: instr_index 
integer(kind=b2o_int) :: channel
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_channels
integer(kind=b2o_int) :: satinst, sensor
character(len=8) :: s_satinst
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

#include "datastream.h"

!--------------------------------------------------------------------------------------                                                                                         
if (lhook) call dr_hook('b2o_convert_fy3',0,zhook_handle)

satinst = b2o_get_int(handle, "satelliteInstruments")

! Two entries defined for MWTS-2 - make sure only one is used.
if (satinst == 935) then
  satinst = 954
end if

select case (satinst)
case (933) ; n_channels = 20 ! IRAS
case (934) ; n_channels = 4  ! MWTS or MWAS
case (936) ; n_channels = 5  ! MWHS
case (938) ; n_channels = 10 ! MWRI
case (953) ; n_channels = 15 ! MWHS2
case (954) ; n_channels = 13 ! MWTS2
case default
  write (s_satinst, "(i4)") satinst
  call b2o_log(handle, B2O_ERROR, "Unexpected satellite instrument: " // trim(s_satinst))
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

  satid = b2o_get_int(handle, "satelliteIdentifier")
  statid = ' '
  write (statid,'(i8)') satid

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  if (b2o_is_defined(handle, "height")) then
    hdr(iobs,hdr_stalt) = b2o_get_real(handle, "height")
  elseif (b2o_is_defined(handle, "heightOfStation")) then
    hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  endif  
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_distribtype) = merge(2, 0, B2O_ALL_SKY) ! MWHS2 all-sky

  select case (satinst)
  case (933) ; sensor = 42 ! IRAS
  case (934) ; sensor = 40 ! MWTS or MWAS
  case (936) ; sensor = 41 ! MWHS
  case (938) ; sensor = 43 ! MWRI
  case (953) ; sensor = 73 ! MWHS2
  case (954) ; sensor = 72 ! MWTS2
  case default ; sensor = ODB_MISSING_INT
  end select

  hdr(iobs,hdr_sensor) = sensor

  channel_loop: do k = 1, n_channels

    channel = b2o_get_int(handle, "channelNumber", rank=k)

    if (channel == ODB_MISSING_INT .or. k > n_channels) then
      exit channel_loop
    end if

    ! Brightness temperature

    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt
    body(jobs,body_vertco_type) = g_tovs_cha
    body(jobs,body_vertco_reference_1) = channel

    nonlin_corr_version = 0   ! no correction
    z_non_dt = 0.0_B2O_DOUBLE ! non-linearity correction
    Tb = b2o_get_real(handle, "brightnessTemperature", rank=k)

    if (satinst == 934) then  ! If (instr = MWTS) compute non-lin correction

      select case (satid)
          case(520) ! FY-3A
           instr_index = 1
          case(521) ! FY-3B
           instr_index = 2
           nonlin_corr_version = 1
          case default ! FY-3A
           instr_index = 1
      end select

      call fy3_corrections(instr_index, channel, nonlin_corr_version, Tb, z_non_dt)

    end if

    if (Tb /= ODB_MISSING_REAL .and. abs(z_non_dt) < 100._b2o_double) then
      body(jobs,body_obsvalue) = Tb - z_non_dt
    end if

    body(jobs,body_tbcorr) = z_non_dt

  end do channel_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = satinst
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")

  sat(iobs,sat_gen_centre) = b2o_get_int(handle, "centre")
  sat(iobs,sat_gen_subcentre) = b2o_get_int(handle, "subCentre")

  bufrtype = b2o_get_int(handle, "dataCategory")
  subtype = b2o_get_int(handle, "dataSubCategory")
  sat(iobs,sat_datastream) = datastream(bufrtype, subtype, &
   &   sat(iobs,sat_gen_centre),sat(iobs,sat_gen_subcentre),&
   &   sat(iobs,sat_satellite_identifier))

  if (b2o_is_missing(handle, "solarZenithAngle")) then
    call b2o_solar_zenith(hdr(iobs,hdr_date), hdr(iobs,hdr_time), hdr(iobs,hdr_lat), hdr(iobs,hdr_lon),  &
      & sat(iobs,sat_solar_zenith))
  else
    sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  end if

  if (b2o_is_missing(handle, "solarAzimuth")) then
    call b2o_solar_azimuth(hdr(iobs,hdr_date), hdr(iobs,hdr_time), hdr(iobs,hdr_lat), hdr(iobs,hdr_lon),  &
      & sat(iobs,sat_solar_azimuth))
  else
    sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  end if

  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")
  rad(iobs,radiance_corr_version) = nonlin_corr_version

end do subset_loop

if (lhook) call dr_hook('b2o_convert_fy3',1,zhook_handle)

end subroutine b2o_convert_FY3
