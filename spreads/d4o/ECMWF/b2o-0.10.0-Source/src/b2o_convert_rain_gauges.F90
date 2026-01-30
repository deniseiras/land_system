subroutine b2o_convert_rain_gauges(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)

integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: iobs, jobs

character(len=20) :: statid, source

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_rain_gauges',0,zhook_handle)

n_variables = 2

call b2o_reserve(handle, n_variables)

hdr     => b2o_use_table(handle, "hdr")
body    => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  call b2o_get_string(handle, "stationOrSiteName", statid)
  call b2o_get_string(handle, "radarCompositeName", source)

  hdr(iobs,hdr_distribtype) = 1 ! distribute on model grid
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_source) = transfer(source,to_double) ! rain gauge network name
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")

  ! Radar rain rates in m/s

  jobs = jobs + 1

  body(jobs,body_varno) = g_prc
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = hdr(iobs,hdr_stalt)
  body(jobs,body_obsvalue) = b2o_get_real(handle, "radarRainfallIntensity")

  ! Add ln (RR(mm/h) + repslog) ; repslog = 1.0

  jobs = jobs + 1

  body(jobs,body_varno) = g_lnprc
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = hdr(iobs,hdr_stalt)

  if (.not.b2o_is_missing(handle, "radarRainfallIntensity")) then
     body(jobs,body_obsvalue) = log(b2o_get_real(handle, "radarRainfallIntensity") * 3.6_B2O_DOUBLE * 1.0e6_B2O_DOUBLE &
       & + 1.0_B2O_DOUBLE)
  end if
     
  ! Rain gauge wind-induced bias correction (in RR space).
  ! Lopez: Unit is mm/h to avoid current encoding precision issue on Mars ODB.

  body(jobs,body_wdeff_bcorr) = &
    & b2o_get_real(handle, "totalPrecipitableWaterIndependentEstimateOfError") * 3.6_B2O_DOUBLE * 1.0_B2O_DOUBLE
  errstat(jobs,errstat_repres_error) = b2o_get_real(handle, "qualityInformation")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_rain_gauges',1,zhook_handle)

end subroutine b2o_convert_rain_gauges
