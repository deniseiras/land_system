subroutine b2o_convert_paob(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)


integer(kind=b2o_int), parameter :: n_variables = 3
integer(kind=b2o_int) :: report_rdbflag
integer(kind=b2o_int) :: iobs, jobs

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_paob',0,zhook_handle)

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

  statid = 'PAOB'

  report_rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1

  ! MSL pressure

  jobs = jobs + 1

  body(jobs,body_varno) = g_ps
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = 0.0_b2o_double ! sea surface
  body(jobs,body_obsvalue) = b2o_get_real(handle, "pressureReducedToMeanSeaLevel")

  ! Geopotential (reserved)

  jobs = jobs + 1

  body(jobs,body_varno) = g_z
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = 0.0_b2o_double ! sea surface

  ! Virtual temperature

  jobs = jobs + 1

  body(jobs,body_varno) = g_vt
  if (b2o_is_defined(handle, "pressure")) then
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=1)
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=2)
  else
    call b2o_log(handle, B2O_WARNING, "Pressure layer not found")
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end if

  body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, "virtualTemperature", 27, 0)
  body(jobs,body_obsvalue) = b2o_get_real(handle, "virtualTemperature")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_paob',1,zhook_handle)

end subroutine b2o_convert_paob
