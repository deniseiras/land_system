subroutine b2o_convert_smos(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: smos(:,:)

integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: iobs, jobs
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_smos',0,zhook_handle)

n_variables = 1
n_levels = 1

call b2o_reserve(handle, n_variables * n_levels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
smos => b2o_use_table(handle, "smos")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_distribtype) = 1 ! distribute on model grid
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_levels
  hdr(iobs,hdr_sensor) = 18

  ! Brightness temperature (real part)

  jobs = jobs + 1

  body(jobs,body_varno) = g_bt_real
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "gridPointAltitude")
  body(jobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperatureRealPart")
       
  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "azimuthAngle")

  smos(iobs,smos_snapshot_id)      = b2o_get_real(handle, "snapshotIdentifier")
  smos(iobs,smos_grid_point_id)    = b2o_get_real(handle, "gridPointIdentifier")
  smos(iobs,smos_electron_count)   = b2o_get_real(handle, "totalElectronCountPerSquareMetre")
  smos(iobs,smos_sun_bt)           = b2o_get_real(handle, "directSunBrightnessTemperature")
  smos(iobs,smos_snapshot_acc)     = b2o_get_real(handle, "snapshotAccuracy")
  smos(iobs,smos_rad_acc_pure)     = b2o_get_real(handle, "radiometricAccuracyPurePolarization")
  smos(iobs,smos_rad_acc_cross)    = b2o_get_real(handle, "radiometricAccuracyCrossPolarization")
  smos(iobs,smos_footprint_axis_1) = b2o_get_real(handle, "footprintAxis1")
  smos(iobs,smos_footprint_axis_2) = b2o_get_real(handle, "footprintAxis2")
  smos(iobs,smos_polarisation)     = b2o_get_real(handle, "polarization")
  smos(iobs,smos_water_fraction)   = b2o_get_real(handle, "waterFraction")
  smos(iobs,smos_incidence_angle)  = b2o_get_real(handle, "incidenceAngle")
  smos(iobs,smos_faradey_rot_angle)= b2o_get_real(handle, "faradayRotationalAngle")
  smos(iobs,smos_pixel_rot_angle)  = b2o_get_real(handle, "geometricRotationalAngle")
  smos(iobs,smos_info)             = b2o_get_real(handle, "smosInformationFlag")
  smos(iobs,smos_snapshot_quality) = b2o_get_real(handle, "snapshotOverallQuality")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_smos',1,zhook_handle)

end subroutine b2o_convert_smos
