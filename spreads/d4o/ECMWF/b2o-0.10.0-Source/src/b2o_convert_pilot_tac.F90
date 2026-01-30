subroutine b2o_convert_pilot_tac(handle, status)

use b2o_internal

#include "b2o_debug.h"

implicit none

type(b2o_handle_t), intent(inout) :: handle
integer(b2o_int),   intent(inout) :: status

real(b2o_double) :: to_double

real(b2o_double), pointer :: hdr(:,:)
real(b2o_double), pointer :: errstat(:,:)
real(b2o_double), pointer :: conv(:,:)
real(b2o_double), pointer :: conv_body(:,:)
real(b2o_double), pointer :: body(:,:)

real(b2o_double) :: pressure, geopotential, vertco

integer(b2o_int), parameter :: n_variables = 5
integer(b2o_int) :: report_rdbflag, datum_rdbflag
integer(b2o_int) :: iobs, jobs, k
integer(b2o_int) :: n_levels
integer(b2o_int) :: level_flags
integer(b2o_int) :: significance

character(len=8) :: statid

real(b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_pilot',0,zhook_handle)

n_levels = b2o_get_int(handle, "delayedDescriptorReplicationFactor")

if (n_levels <= 0 .or. n_levels == ODB_MISSING_INT) then
  call b2o_log(handle, B2O_WARNING, "Invalid number of levels")
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook("b2o_convert_pilot", 1, zhook_handle)
  return
end if

call b2o_reserve(handle, n_variables * n_levels)

hdr       => b2o_use_table(handle, "hdr")
conv      => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body      => b2o_use_table(handle, "body")
errstat   => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  report_rdbflag = 0

  hdr(iobs,hdr_lat) = b2o_get_lat(handle, report_rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, report_rdbflag)
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_report_rdbflag) = report_rdbflag

  select case (handle%subtype)
  case (92)
    call b2o_get_string(handle, "shipOrMobileLandStationIdentifier", statid)
  case (91)
    statid = b2o_get_station_id(handle, status)
    if (status /= B2O_SUCCESS) exit subset_loop
  end select

  hdr(iobs,hdr_statid) = transfer(statid, to_double)
  hdr(iobs,hdr_numlev) = n_levels
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")

  conv(iobs,conv_sonde_type) = b2o_get_real(handle, "radiosondeType")

  level_loop: do k = 1, n_levels

    pressure = b2o_get_real(handle, "pressure", rank=k)
    datum_rdbflag = b2o_get_rdbflag(handle, "pressure", 27, 0, rank=k)

    vertco = pressure
    if (pressure == ODB_MISSING_REAL) then
      geopotential = b2o_get_real_if_defined(handle, "nonCoordinateGeopotential", rank=k)
      if (geopotential /= ODB_MISSING_REAL) then
        pressure = b2o_height_to_pressure(geopotential / B2O_GRAVITY) * 100.d0
      end if
    end if

    ! Sounding level flags

    significance = b2o_get_int(handle, "verticalSoundingSignificance", rank=k)
    level_flags = b2o_sounding_significance_flags(8001, significance, pressure)

    ! Geopotential (or missing value if not present)

    if (b2o_is_defined(handle, "nonCoordinateGeopotential", rank=k)) then
        call append("nonCoordinateGeopotential", g_z)
    else if (b2o_is_defined(handle, "geopotentialHeight", rank=k)) then
        call append("geopotentialHeight", g_z, scale_factor=B2O_GRAVITY)
    else
        call append("", g_z)
    end if

    ! Wind direction, speed and (reserved) u/v components

    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)
    call append("", g_u)
    call append("", g_v)

  end do level_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_pilot',1,zhook_handle)

contains

subroutine append(key, varno, scale_factor)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    real(b2o_double), intent(in), optional :: scale_factor
    real(b2o_double) :: obsvalue

    jobs = jobs + 1

    obsvalue = b2o_get_real(handle, key, rank=k)

    if (present(scale_factor).and.(obsvalue /= ODB_MISSING_REAL)) then
        obsvalue = obsvalue * scale_factor
    end if

    body(jobs,body_varno) = varno
    body(jobs,body_datum_rdbflag) = b2o_get_rdbflag(handle, key, 12, datum_rdbflag, rank=k)
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = vertco
    body(jobs,body_obsvalue) = obsvalue
    conv_body(jobs,conv_body_level) = level_flags

end subroutine

end subroutine b2o_convert_pilot_tac
