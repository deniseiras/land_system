subroutine b2o_convert_oscat(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: scatt(:,:)
real(kind=b2o_double), pointer :: scatt_body(:,:)

integer(kind=b2o_int) :: sensor
integer(kind=b2o_int) :: iobs, jobs, k

integer(kind=b2o_int), parameter :: n_variables = 4
integer(kind=b2o_int), parameter :: n_solutions = 4

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_oscat',0,zhook_handle)

call b2o_reserve(handle, n_variables * n_solutions)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
scatt => b2o_use_table(handle, "scatt")
scatt_body => b2o_use_table(handle, "scatt_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i5.5)') b2o_get_int(handle, "satelliteIdentifier")

  select case (b2o_get_int(handle, "satelliteIdentifier"))
  case (421) ; sensor = 288
  case (801) ; sensor = 314
  case (502) ; sensor = 686
  case (422) ; sensor = 288
  case (423) ; sensor = 288
  case (503) ; sensor = 686


  end select

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_solutions
  hdr(iobs,hdr_sensor) = sensor

  solution_loop: do k = 1, n_solutions

    call append("windDirectionAt10M", g_dd, k)
    call append("windSpeedAt10M", g_ff, k)
    call append("", g_scatu, k)
    call append("", g_scatv, k)

  end do solution_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = sensor

  scatt(iobs,scatt_cellno) = b2o_get_int(handle, "crossTrackCellNumber")
  scatt(iobs,scatt_nretr_amb) = b2o_get_int(handle, "numberOfVectorAmbiguities")
  scatt(iobs,scatt_prodflag) = b2o_get_int(handle, "seawindsWindVectorCellQuality")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_oscat',1,zhook_handle)

contains

subroutine append(key, varno, k)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    integer(b2o_int), intent(in) :: k

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_scat_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, key, rank=k)
    scatt_body(jobs,scatt_body_invresid) = b2o_get_real(handle, "likelihoodComputedForSolution", rank=k)

end subroutine

end subroutine b2o_convert_oscat
