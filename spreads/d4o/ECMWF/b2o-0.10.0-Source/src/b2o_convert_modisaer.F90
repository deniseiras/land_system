subroutine b2o_convert_modisaer(handle, status)

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


integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: iobs, jobs, isatid, k, jobs_sav
integer(kind=b2o_int) :: n_channels

character(len=16) :: statid
real(kind=b2o_double) :: wavelength

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! ANTJE: FUDGE PMAP & S3 OBS ERROR.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
if (lhook) call dr_hook('b2o_convert_modisaer',0,zhook_handle)

n_variables = 2  ! optical depth + reflectance

n_channels = b2o_get_int(handle, "totalNumberOfWaveBands")

call b2o_reserve(handle, n_variables * n_channels + 2)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
resat => b2o_use_table(handle, "resat")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  isatid = b2o_get_int(handle, "satelliteIdentifier")
  statid = ' '
  write (statid,'(i8)') isatid

  hdr(iobs,hdr_retrtype) = 0
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_channels
  hdr(iobs,hdr_sensor) = b2o_get_int(handle, "satelliteInstruments")

  wavelength = b2o_get_real(handle, "spectrographicWavelength", rank=1)

  ! Optical depth which is coupled with fine mode aerosol optical depth

  call append("opticalDepth", g_aerod, 1)
  !fudge PMAP observation errors
  if(isatid==4 .or. isatid==3 .or. isatid==61) then
    jobs_sav=jobs
  endif

  ! Fine mode aerosol optical depth

  call append("opticalDepth", g_rao, 2)

  ! Optical depth and reflectance

  channel_loop: do k = 1, n_channels

    wavelength = b2o_get_real(handle, "spectrographicWavelength", rank=k+1)

    call append("opticalDepth", g_od, k+2)
    if(isatid==4 .or. isatid==3 .or. isatid==61) then
      errstat(jobs_sav,errstat_obs_error)=errstat(jobs,errstat_obs_error)
    endif
    call append("reflectance", g_rfltnc, k)

  end do channel_loop

  resat(iobs,resat_instrument_type) = b2o_get_int(handle, "satelliteInstruments")
  resat(iobs,resat_product_type) = b2o_get_int(handle, "productTypeForRetrievedAtmosphericGases")
  resat(iobs,resat_cloud_cover) = b2o_get_real(handle, "cloudCoverTotal")
  resat(iobs,resat_snow_ice_indicator) = b2o_get_int(handle, "snowOrIceCrystalsIndicator")
  resat(iobs,resat_surface_type_indicator) = b2o_get_int(handle, "surfaceFlag")

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_real(handle, "satelliteInstruments")
  sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "viewingAzimuthAngle")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_modisaer',1,zhook_handle)

contains

subroutine append(key, varno, k)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    integer(b2o_int), intent(in) :: k

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_cha_wavelength
    body(jobs,body_vertco_reference_1) = wavelength
    body(jobs,body_obsvalue) = b2o_get_real(handle, key, rank=k)
    errstat(jobs,errstat_obs_error) = b2o_get_real_if_defined(handle, trim(key) // "->firstOrderStatisticalValue", rank=k)

end subroutine

end subroutine b2o_convert_modisaer
