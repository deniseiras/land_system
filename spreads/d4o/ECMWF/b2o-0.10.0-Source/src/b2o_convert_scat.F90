subroutine b2o_convert_scat(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: scatt(:,:)
real(kind=b2o_double), pointer :: scatt_body(:,:)

integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int), parameter :: n_variables = 11
integer(kind=b2o_int), parameter :: n_beams = 3
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_scat',0,zhook_handle)

call b2o_reserve(handle, n_variables)

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

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_beams
  hdr(iobs,hdr_sensor) = 150

  beam_loop: do k = 1, n_beams

    jobs = jobs + 1

    body(jobs,body_varno) = g_scatss
    body(jobs,body_vertco_type) = g_scat_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "radarBackScatter", rank=k)

    scatt_body(jobs,scatt_body_azimuth) = b2o_get_real(handle, "radarLookAngle", rank=k)
    scatt_body(jobs,scatt_body_incidence) = b2o_get_real(handle, "radarIncidenceAngle", rank=k)
    scatt_body(jobs,scatt_body_kp) = b2o_get_real(handle, "noiseFigure", rank=k)
    scatt_body(jobs,scatt_body_mpc) = b2o_get_real(handle, "missingPacketCounter", rank=k)

  end do beam_loop

  call append("windDirectionAt10M", g_dd)
  call append("windSpeedAt10M", g_ff)

  call append("", g_u10m)
  call append("", g_v10m)
  call append("", g_scatu)
  call append("", g_scatv)
  call append("", g_scatu)
  call append("", g_scatv)

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = 142  ! AMI/Scatterometer ESA ERS 2 satellite

  scatt(iobs,scatt_wvc_qf) = b2o_get_int(handle, "uwiProductConfidence")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_scat',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_scat_cha
    body(jobs,body_obsvalue) = b2o_get_real(handle, key)

end subroutine

end subroutine b2o_convert_scat
