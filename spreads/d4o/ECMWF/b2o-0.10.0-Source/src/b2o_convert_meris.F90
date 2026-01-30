subroutine b2o_convert_meris(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)


integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int), parameter :: n_variables = 2

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_meris',0,zhook_handle)

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_sensor) = b2o_get_int(handle, "satelliteInstruments")

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = 174
  sat(iobs,sat_zenith) = b2o_get_real(handle, "viewingZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "viewingAzimuthAngle")
  sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")

  ! Cloud optical thickness

  jobs = jobs + 1

  body(jobs,body_varno) = g_cod
  body(jobs,body_vertco_type) = g_pressure
  body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure")
  body(jobs,body_obsvalue) = b2o_get_real(handle, "cloudOpticalThickness")
     
  ! Total column water vapour

  jobs = jobs + 1

  body(jobs,body_varno) = g_pwc
  body(jobs,body_vertco_type) = g_pressure
  body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=2)
  body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=3)
  body(jobs,body_obsvalue) = b2o_get_real(handle, "totalColumnWaterVapour")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_meris',1,zhook_handle)

end subroutine b2o_convert_meris


