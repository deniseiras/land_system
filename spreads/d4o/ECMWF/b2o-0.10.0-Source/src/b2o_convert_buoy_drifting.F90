subroutine b2o_convert_buoy_drifting(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)
real(kind=b2o_double), pointer :: body(:,:)


integer(kind=b2o_int) :: ios
integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: iobs, jobs
character(len=8) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_buoy_drifting',0,zhook_handle)

n_variables = 11

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  if (b2o_is_missing(handle, "marineObservingPlatformIdentifier")) then
     call b2o_log(handle, B2O_WARNING, "Buoy identifier not found")
     status = B2O_SKIP_MESSAGE
     exit subset_loop
  end if

  statid = ''
  write (statid, '(i7.7)', iostat=ios) b2o_get_int(handle, "marineObservingPlatformIdentifier")

  if (ios /= 0) then
    call b2o_log(handle, B2O_WARNING, "Failed writing buoy identifier")
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle, rank=2)
  hdr(iobs,hdr_time) = b2o_get_time(handle, rank=2)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = b2o_get_ident_if_defined(handle, default=statid)
  hdr(iobs,hdr_wigosid) = b2o_get_wigosid_if_defined(handle)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = 0

  conv(iobs,conv_anemoht) = b2o_get_real_if_defined(handle, "heightOfSensorAboveWaterSurface")

  call append("directionOfMotionOfMovingObservingPlatform", g_ds)
  call append("platformDriftSpeed", g_vs)
  call append("oceanographicWaterTemperature", g_tsts)
  call append("nonCoordinatePressure", g_ps, ppcode=1) ! station-level pressure
  call append("pressureReducedToMeanSeaLevel", g_ps, ppcode=0) ! MSL pressure
  call append("", g_z)
  if (b2o_is_defined(handle, "airTemperature")) then
    call append("airTemperature", g_t2m)
  else
    call append("", g_t2m)
  end if
  if (b2o_is_defined(handle, "windDirection")) then
    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)
  else
    call append("", g_dd)
    call append("", g_ff)
  end if
  call append("", g_u10m)
  call append("", g_v10m)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_buoy_drifting',1,zhook_handle)

contains

subroutine append(key, varno, ppcode)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    integer(b2o_int), intent(in), optional :: ppcode

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = 0.d0
    body(jobs,body_obsvalue) = b2o_get_real(handle, key)
    conv_body(jobs,conv_body_ppcode) = b2o_optional(0, ppcode)

    if (varno == g_ps) then
        body(jobs,body_biascorr) = b2o_get_real_if_defined(handle, trim(key) // "->differenceStatisticalValue", nesting=-1)
    end if

end subroutine

end subroutine b2o_convert_buoy_drifting
