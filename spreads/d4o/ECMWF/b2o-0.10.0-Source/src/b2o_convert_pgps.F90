subroutine b2o_convert_pgps(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

integer(kind=b2o_int), parameter :: n_variables = 1
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: ppcode
integer(kind=b2o_int) :: hyphen
character(len=20) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_pgps',0,zhook_handle)

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while(b2o_next_subset(handle))

  iobs = iobs + 1

  call b2o_get_string(handle, "stationOrSiteName", statid)

  ! Remove hyphen from station ID

  hyphen = index(statid, '-')
  if (hyphen /= 0) then
    statid(1:8) = statid(1:hyphen-1) // statid(hyphen+1:9)
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1

  if (b2o_is_defined(handle, "heightOfStation")) then
    hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  else
    hdr(iobs,hdr_stalt) = 0.0_B2O_DOUBLE
  end if

  ! Atmospheric path delay in satellite signal

  jobs = jobs + 1

  if (b2o_is_defined(handle, "heightOfStation")) then
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "heightOfStation")
    ppcode = 1
  else
    body(jobs,body_vertco_reference_1) = 0.0_B2O_DOUBLE
    ppcode = 0
  end if

  body(jobs,body_varno) = g_apdss
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_obsvalue) = b2o_get_real(handle, "atmosphericPathDelayInSatelliteSignal")
  conv_body(jobs,conv_body_ppcode) = ppcode

end do subset_loop

if (lhook) call dr_hook('b2o_convert_pgps',1,zhook_handle)

end subroutine b2o_convert_pgps
