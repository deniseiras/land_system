subroutine b2o_convert_metar(handle, status)

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

real(kind=b2o_double) :: station_height

integer(kind=b2o_int), parameter :: n_variables = 9
integer(kind=b2o_int) :: report_rdbflag, datum_rdbflag
integer(kind=b2o_int) :: iobs, jobs

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_metar',0,zhook_handle)

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

  call b2o_get_string(handle, "icaoLocationIndicator", statid)

  station_height = b2o_get_real(handle, "heightOfStation")
  report_rdbflag = b2o_get_rdbflag(handle, "heightOfStation", 3, 0)
  datum_rdbflag  = b2o_get_rdbflag(handle, "heightOfStation", 27, 0)

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = station_height

  conv(iobs,conv_station_type) = b2o_get_real(handle, "stationType")

  call append("nonCoordinatePressure", g_ps)
  call append("airTemperature", g_t2m)
  call append("dewpointTemperature", g_td2m)
  call append("", g_rh2m)
  call append("", g_q2m)
  call append("windDirection", g_dd)
  call append("windSpeed", g_ff)
  call append("", g_u10m)
  call append("", g_v10m)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_metar',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = station_height
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag)
    body(jobs,body_obsvalue) = b2o_get_real(handle, key)
    conv_body(jobs,conv_body_ppcode) = 1

    if (varno == g_ps) then
        body(jobs,body_biascorr) = b2o_get_real_if_defined(handle, trim(key) // "->differenceStatisticalValue", nesting=-1)
    end if

end subroutine

end subroutine b2o_convert_metar
