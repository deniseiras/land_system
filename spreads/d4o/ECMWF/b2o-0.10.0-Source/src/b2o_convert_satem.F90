subroutine b2o_convert_satem(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

integer(kind=b2o_int) :: iobs, jobs, k, m
integer(kind=b2o_int), parameter :: pwc_levels = 3
integer(kind=b2o_int), parameter :: t_levels = 15
integer(kind=b2o_int) :: report_rdbflag, datum_rdbflag

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_satem',0,zhook_handle)

call b2o_reserve(handle, 2 * t_levels + pwc_levels)

hdr => b2o_use_table(handle, "hdr")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  report_rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = t_levels + pwc_levels

  t_loop: do k = 1, t_levels

    ! Mean layer temperature

    jobs = jobs + 1

    m = 1 + 2 * (k-1) + 1

    body(jobs,body_varno) = g_t
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=m+1)
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=m)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "airTemperature", rank=k)

    datum_rdbflag = b2o_get_rdbflag(handle, "pressure", 27, 0, rank=m)
    datum_rdbflag = b2o_get_rdbflag(handle, "airTemperature", 12, datum_rdbflag, rank=k)
    body(jobs,body_datum_rdbflag) = datum_rdbflag

    ! Thickness

    jobs = jobs + 1

    body(jobs,body_varno) = g_dz
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=m+1)
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=m)
    body(jobs,body_datum_rdbflag) = 0

  end do t_loop

  pwc_loop: do k = 1, pwc_levels

    ! Precipitable water

    jobs = jobs + 1

    m = 1 + 2 * t_levels + 2 * (k-1) + 1

    body(jobs,body_varno) = g_pwc
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=m+1)
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=m)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "precipitableWater", rank=k)

    datum_rdbflag = b2o_get_rdbflag(handle, "pressure", 27, 0, rank=m+1)
    datum_rdbflag = b2o_get_rdbflag(handle, "precipitableWater", 12, datum_rdbflag, rank=k)
    body(jobs,body_datum_rdbflag) = datum_rdbflag

  end do pwc_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_satem',1,zhook_handle)

end subroutine b2o_convert_satem
