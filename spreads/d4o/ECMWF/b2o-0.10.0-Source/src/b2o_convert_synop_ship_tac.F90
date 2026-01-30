subroutine b2o_convert_synop_ship_tac(handle, status)

use b2o_internal
use b2o_option, only : B2O_EXTRACT_RH2M

implicit none

type(b2o_handle_t), intent(inout) :: handle
integer(b2o_int), intent(inout) :: status

real(b2o_double) :: to_double

real(b2o_double), pointer :: hdr(:,:)
real(b2o_double), pointer :: errstat(:,:)
real(b2o_double), pointer :: conv(:,:)
real(b2o_double), pointer :: conv_body(:,:)
real(b2o_double), pointer :: body(:,:)

integer(b2o_int) :: ios
integer(b2o_int) :: n_variables
integer(b2o_int) :: rdbflag
integer(b2o_int) :: iobs, jobs

character(8) :: statid

real(b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_synop_ship_tac',0,zhook_handle)

n_variables = 26

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

  statid = ' '
  if (b2o_is_defined(handle, "shipOrMobileLandStationIdentifier")) then
    call b2o_get_string(handle, "shipOrMobileLandStationIdentifier", statid)
  else if (b2o_is_defined(handle, "buoyOrPlatformIdentifier")) then
    if (b2o_is_missing(handle, "buoyOrPlatformIdentifier")) then
       call b2o_log(handle, B2O_WARNING, "Buoy identifier not found")
       status = B2O_SKIP_MESSAGE
       exit subset_loop
    end if
    write (statid, '(i5.5)', iostat=ios) b2o_get_int(handle, "buoyOrPlatformIdentifier")
    if (ios /= 0) then
      call b2o_log(handle, B2O_WARNING, "Failed writing buoy identifier")
      status = B2O_SKIP_MESSAGE
      exit subset_loop
    end if
  else
    call b2o_log(handle, B2O_WARNING, "Station identifier not found")
    status = B2O_SKIP_MESSAGE
    exit subset_loop
  end if

  rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, rdbflag)
  hdr(iobs,hdr_report_rdbflag) = rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = 0

  conv(iobs,conv_anemoht) = b2o_get_real_if_defined(handle, "anemometerHeight") ! not defined for BATHY
  conv(iobs,conv_baroht) = b2o_get_real_if_defined(handle, "heightOfBarometerAboveMeanSeaLevel") ! not defined in BATHY and DRIBU
  conv(iobs,conv_station_type) = b2o_get_int(handle, "stationType")

  call append("directionOfMotionOfMovingObservingPlatform", g_ds)
  call append("movingObservingPlatformSpeed", g_vs)
  call append("nonCoordinatePressure", g_ps, ppcode=1)
  call append("pressureReducedToMeanSeaLevel", g_ps, ppcode=0)
  call append("", g_z)
  call append("3HourPressureChange", g_ptend)
  call append("airTemperatureAt2M", g_t2m)
  call append("dewpointTemperatureAt2M", g_td2m)
  call append(merge("relativeHumidity", repeat(" ", 16), B2O_EXTRACT_RH2M), g_rh2m)
  call append("", g_q2m)
  call append("windDirectionAt10M", g_dd)
  call append("windSpeedAt10M", g_ff)
  call append("", g_u10m)
  call append("", g_v10m)
  call append("characteristicOfPressureTendency", g_cpt)
  call append("horizontalVisibility", g_vv)
  call append("presentWeather", g_ww)
  call append("pastWeather1", g_w)
  call append("oceanographicWaterTemperature", g_tsts)
  call append("pastWeather2", g_w2)
  call append("cloudCoverTotal", g_n)
  call append("cloudAmount", g_nn)
  call append("cloudType", g_cl, rank=1)
  call append("cloudType", g_cm, rank=2)
  call append("cloudType", g_ch, rank=3)
  call append("heightOfBaseOfCloud", g_nh)

end do subset_loop

if (lhook) call dr_hook('b2o_convert_synop_ship_tac',1,zhook_handle)

contains

subroutine append(key, varno, ppcode, rank)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    integer(b2o_int), intent(in), optional :: ppcode, rank

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = 0.d0
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, 0, rank)
    body(jobs,body_obsvalue) = b2o_get_real(handle, key, rank)
    conv_body(jobs,conv_body_ppcode) = b2o_optional(0, ppcode)

    if (varno == g_ps) then
        body(jobs,body_biascorr) = b2o_get_real_if_defined(handle, trim(key) // "->differenceStatisticalValue", nesting=-1)
    end if

end subroutine

end subroutine b2o_convert_synop_ship_tac
