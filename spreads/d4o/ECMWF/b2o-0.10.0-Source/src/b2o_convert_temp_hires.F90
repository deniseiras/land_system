#include <b2o_debug.h>
subroutine b2o_convert_temp_hires(handle, status)

use b2o_internal
use b2o_functional
use b2o_option

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)
real(kind=b2o_double), pointer :: body(:,:)

real(kind=b2o_double) :: coords(2)
real(kind=b2o_double) :: lat, lon
real(kind=b2o_double) :: stalt
real(kind=b2o_double) :: ident, wigosid(1:4)

integer(kind=b2o_int) :: ios
integer(kind=b2o_int) :: date, time, new_date, new_time
integer(kind=b2o_int), parameter :: n_variables = 9
integer(kind=b2o_int) :: i, j, k
integer(kind=b2o_int) :: jobs
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: report_event1
integer(kind=b2o_int) :: max_levels
integer(kind=b2o_int) :: n_seconds_from_full_hour
integer(kind=b2o_int) :: batch_interval

character(len=8) :: statid, s_levels

logical, allocatable :: select_mask(:), batch_mask(:)
logical :: batch_averaging

integer(kind=b2o_int), allocatable :: significancies(:), levels(:), flags(:)
real(kind=b2o_double), allocatable :: windDirections(:)
real(kind=b2o_double), allocatable :: windSpeeds(:)
real(kind=b2o_double), allocatable :: us(:), vs(:)
real(kind=b2o_double), allocatable :: geopotentialHeights(:)
real(kind=b2o_double), allocatable :: airTemperatures(:)
real(kind=b2o_double), allocatable :: dewpointTemperatures(:)
real(kind=b2o_double), allocatable :: pressures(:)
real(kind=b2o_double), allocatable :: priorities(:)
real(kind=b2o_double), allocatable :: timePeriods(:)
real(kind=b2o_double), allocatable :: latitudeDisplacements(:), longitudeDisplacements(:)
real(kind=b2o_double), allocatable :: seconds(:), lats(:), lons(:)

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_temp_hires',0,zhook_handle)

max_levels = B2O_TEMP_MAX_LEVELS

select case (handle%subtype)
case (230)
    batch_interval  = B2O_TEMP_DROP_BATCH_INTERVAL
    batch_averaging = B2O_TEMP_DROP_BATCH_AVERAGING
case (231)
    batch_interval  = B2O_TEMP_DESCENT_BATCH_INTERVAL
    batch_averaging = B2O_TEMP_DESCENT_BATCH_AVERAGING
case default
    batch_interval  = B2O_TEMP_ASCENT_BATCH_INTERVAL
    batch_averaging = B2O_TEMP_ASCENT_BATCH_AVERAGING
end select

n_levels = b2o_get_int(handle, "extendedDelayedDescriptorReplicationFactor")

if (n_levels <= 0 .or. n_levels == ODB_MISSING_INT) then
  call b2o_log(handle, B2O_WARNING, "Invalid number of levels")
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook("b2o_convert_temp_hires", 1, zhook_handle)
  return
end if

call b2o_get_array(handle, "windDirection", windDirections, n_levels)
call b2o_get_array(handle, "windSpeed", windSpeeds, n_levels)
call b2o_get_array(handle, "nonCoordinateGeopotentialHeight", geopotentialHeights, n_levels)
call b2o_get_array(handle, "airTemperature", airTemperatures, n_levels)
call b2o_get_array(handle, "dewpointTemperature", dewpointTemperatures, n_levels)
call b2o_get_array(handle, "pressure", pressures, n_levels)
call b2o_get_array(handle, "extendedVerticalSoundingSignificance", significancies, n_levels)
call b2o_get_array(handle, "timePeriod", timePeriods, n_levels)
call b2o_get_array(handle, "latitudeDisplacement", latitudeDisplacements, n_levels)
call b2o_get_array(handle, "longitudeDisplacement", longitudeDisplacements, n_levels)

report_event1 = 0

statid = ' '
if (handle%subtype == 111) then
  call b2o_get_string(handle, "shipOrMobileLandStationIdentifier", statid)
else if (handle%subtype == 230) then
  call b2o_get_string(handle, "aircraftFlightNumber", statid)
else
  statid = b2o_get_station_id(handle, status)
  if (status /= B2O_SUCCESS) then
    call b2o_get_string(handle, "shipOrMobileLandStationIdentifier", statid)
    status = B2O_SUCCESS
  end if
end if

ident = b2o_get_ident_if_defined(handle, default=statid)
wigosid(1:4) = b2o_get_wigosid_if_defined(handle)

call b2o_log(handle, B2O_WARNING, "Converting radiosonde '" // trim(statid) // "'")

stalt = b2o_get_oscar_stalt(handle, "height", report_event1)
flags = b2o_sounding_significance_flags(8042, significancies, pressures)
priorities = priority(flags)

select_mask = b2o_compose(thin, distinct, sanitize, pressures)

windDirections         = pack(windDirections, select_mask)
windSpeeds             = pack(windSpeeds, select_mask)
geopotentialHeights    = pack(geopotentialHeights, select_mask)
airTemperatures        = pack(airTemperatures, select_mask)
dewpointTemperatures   = pack(dewpointTemperatures, select_mask)
pressures              = pack(pressures, select_mask)
significancies         = pack(significancies, select_mask)
flags                  = pack(flags, select_mask)
timePeriods            = pack(timePeriods, select_mask)
latitudeDisplacements  = pack(latitudeDisplacements, select_mask)
longitudeDisplacements = pack(longitudeDisplacements, select_mask)

! Fill potential gaps in the displacement arrays (default to 0.d0 if all missing).

call b2o_locf(timePeriods, 0.d0)
call b2o_locf(latitudeDisplacements, 0.d0)
call b2o_locf(longitudeDisplacements, 0.d0)

! Compute time offset with respect to the nearest full hour. This is needed so that
! batch intervals are aligned with full hours.

date = b2o_get_date(handle)
time = b2o_get_time(handle)

n_seconds_from_full_hour = b2o_time_diff(date, time, date, time / 10000 * 10000)
timePeriods = timePeriods + n_seconds_from_full_hour

if (batch_interval == 0) then
    batch_mask = spread(.true., 1, size(timePeriods))
else
#if defined(__PGI) && (__PGIC__ < 18 || (__PGIC__ == 18 && __PGIC_MINOR__ < 7))
  call b2o_log(handle, B2O_ERROR, "Your PGI compiler version is not supported -- minimum required version is 18.7")
  call b2o_exit(1)
#else
   batch_mask = b2o_partition_by(batch_number, timePeriods)
#endif
end if

coords = b2o_get_oscar_lat_lon(handle, report_event1)
lat = coords(1)
lon = coords(2)

#if defined(__PGI) && (__PGIC__ < 18 || (__PGIC__ == 18 && __PGIC_MINOR__ < 7))
  call b2o_log(handle, B2O_ERROR, "Your PGI compiler version is not supported -- minimum required version is 18.7")
  call b2o_exit(1)
#else
if (timePeriods(1) <= timePeriods(size(timePeriods))) then
  seconds  = b2o_map(b2o_first, timePeriods, batch_mask) - n_seconds_from_full_hour
  lats     = b2o_map(b2o_first, latitudeDisplacements,  batch_mask) + lat
  lons     = b2o_map(b2o_first, longitudeDisplacements, batch_mask) + lon
else
  seconds  = b2o_map(b2o_last, timePeriods, batch_mask) - n_seconds_from_full_hour
  lats     = b2o_map(b2o_last, latitudeDisplacements,  batch_mask) + lat
  lons     = b2o_map(b2o_last, longitudeDisplacements, batch_mask) + lon
end if

levels = b2o_map(b2o_count, spread(.true., 1, size(batch_mask)), batch_mask)
#endif

if (batch_averaging) then

  us = b2o_map(b2o_mean, b2o_wind_u_component(windSpeeds, windDirections), batch_mask)
  vs = b2o_map(b2o_mean, b2o_wind_v_component(windSpeeds, windDirections), batch_mask)

  windSpeeds = b2o_wind_speed(us, vs)
  windDirections = b2o_wind_direction(us, vs)

  geopotentialHeights  = b2o_map(b2o_mean, geopotentialHeights, batch_mask)
  airTemperatures      = b2o_map(b2o_mean, airTemperatures, batch_mask)
  dewpointTemperatures = b2o_map(b2o_mean, dewpointTemperatures, batch_mask)
  pressures            = b2o_map(b2o_mean, pressures, batch_mask)

  flags  = b2o_sounding_significance_flags(8042, 0, pressures)
  levels = spread(1, 1, size(pressures)) ! one level per report

end if

if (.not.size(levels) > 0) then
  call b2o_log(handle, B2O_WARNING, "Invalid number of levels")
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook("b2o_convert_temp_hires", 1, zhook_handle)
  return
end if

call b2o_reserve(handle, levels(:) * n_variables)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

jobs = 0
k = 0

report_loop: do i = 1, size(levels)

  call b2o_time_inc(date, time, int(seconds(i)), new_date, new_time)

  hdr(i,hdr_date) = new_date
  hdr(i,hdr_time) = new_time
  hdr(i,hdr_wigosid(1:4)) = wigosid(1:4)
  hdr(i,hdr_statid) = ident
  hdr(i,hdr_lat) = lats(i)
  hdr(i,hdr_lon) = lons(i)
  hdr(i,hdr_stalt) = stalt
  hdr(i,hdr_numlev) = levels(i)
  hdr(i,hdr_report_event1) = report_event1
  hdr(i,hdr_reportno) = handle%context%message_number

  conv(i,conv_sonde_type) = b2o_get_real(handle, "radiosondeType")

  level_loop: do j = 1, levels(i)

    k = k + 1

    ! Wind direction, speed and (reserved) u/v components

    call append(g_dd, windDirections(k))
    call append(g_ff, windSpeeds(k))
    call append(g_u,  ODB_MISSING_REAL)
    call append(g_v,  ODB_MISSING_REAL)

    ! Geopotential

    call append(g_z, geopotentialHeights(k))

    ! Temperatures, dew point and (reserved) relative and specific humidity

    call append(g_t,  airTemperatures(k))
    call append(g_td, dewPointTemperatures(k))
    call append(g_rh, ODB_MISSING_REAL)
    call append(g_q,  ODB_MISSING_REAL)

  end do level_loop

end do report_loop

if (lhook) call dr_hook('b2o_convert_temp_hires',1,zhook_handle)

contains

subroutine append(varno, obsvalue)

    integer(b2o_int), intent(in) :: varno
    real(b2o_double), value :: obsvalue

    jobs = jobs + 1

    ! Convert geopotential height to geopotential

    if (varno == g_z) then
        if (obsvalue /= ODB_MISSING_REAL) then
            obsvalue = B2O_GRAVITY * obsvalue
        end if
    end if

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = pressures(k)
    body(jobs,body_obsvalue) = obsvalue
    conv_body(jobs,conv_body_level) = flags(k)

end subroutine

elemental function priority(significance)

    ! Returns relative priority of the level given its significancies flags

    integer(b2o_int), intent(in) :: significance
    real(b2o_double) :: priority
    integer(b2o_int) :: i

    integer(b2o_int), parameter :: max_w = 31, trop = 30, std_c = 28, std_a = 26
    integer(b2o_int), parameter :: surf = 25, sign_w = 24, sign_t = 23
    integer(b2o_int), parameter :: table(2,7) = reshape( &
      & (/sign_t, 1, sign_w, 1, trop, 2, max_w, 2, surf, 3, std_a, 3, std_c, 3/), (/2,7/))

    priority = 0

    do i = 1, size(table, 2)
        if (b2o_any_bits(significance, table(1,i), 1)) priority = table(2,i)
    end do

end function

function sanitize(array, global_mask) result(mask)

    ! Returns a mask with sanity checked levels.

    real(b2o_double), intent(in) :: array(:)
    logical, intent(in) :: global_mask(:)
    logical, dimension(size(array)) :: mask

    mask = (array > 0) .and. (array /= ODB_MISSING_REAL)

end function

function distinct(array, global_mask) result(mask)

    real(b2o_double), intent(in) :: array(:)
    logical, intent(in) :: global_mask(:)
    logical, dimension(size(array)) :: mask
    character(len=16) :: s_levels, s_distinct_levels

    interface

    function distinct_helper(array, priorities) result(mask)
        use b2o_common
        real(b2o_double), intent(in) :: array(:)
        real(b2o_double), intent(in), dimension(size(array)) :: priorities
        logical, dimension(size(array)) :: mask
    end function

    end interface

    mask = distinct_helper(array, pack(priorities, global_mask))

    write (s_levels, "(i0)") n_levels
    write (s_distinct_levels, "(i0)") count(mask)
    call b2o_log(handle, B2O_WARNING, "Found " // trim(s_distinct_levels) // &
        & " distinct levels out of the total " // trim(s_levels) // " levels")

end function

function thin(array, global_mask) result(mask)

    use b2o_thinning

    real(b2o_double), intent(in) :: array(:)
    logical, intent(in) :: global_mask(:)
    logical, dimension(size(array)) :: mask

    if (count(global_mask) <= max_levels) then
        mask = .true.
        return
    end if

    call b2o_log(handle, B2O_WARNING, "Number of levels exceeded the maximum allowed limit")

    mask = b2o_non_adaptive_thinning(log(array), max_levels, pack(priorities, global_mask))

end function

pure function batch_number(time_offset)

    ! Returns batch number given the offset (in seconds) from the full hour.
    ! Note: -1 is used to get right-inclusive, half-closed intervals.

    real(b2o_double), intent(in) :: time_offset
    real(b2o_double) :: batch_number
    batch_number = (int(time_offset) - 1) / batch_interval

end function

end subroutine b2o_convert_temp_hires

function distinct_helper(array, priorities) result(mask)

    use b2o_common
    use b2o_functional

    real(b2o_double), intent(in) :: array(:)
    real(b2o_double), intent(in), dimension(size(array)) :: priorities
    logical, dimension(size(array)) :: mask

#if defined(__PGI) && (__PGIC__ < 18 || (__PGIC__ == 18 && __PGIC_MINOR__ < 7))
  call b2o_log(handle, B2O_ERROR, "Your PGI compiler version is not supported -- minimum required version is 18.7")
  call b2o_exit(1)
#else
    mask = b2o_compose(b2o_mapcat(select_midpoint), b2o_partition_by(identity), array)
#endif

contains

pure function select_midpoint(array, a, b) result(mask)

    integer(b2o_int), intent(in) :: a, b
    real(b2o_double), intent(in), dimension(b-a+1) :: array
    logical, dimension(size(array)) :: mask
    integer(b2o_int) :: p

    mask = .false.

    if (any(priorities(a:b) > 0)) then
        p = maxloc(priorities(a:b), dim=1) ! highest priority point
    else
        p = 1 + (b - a) / 2 ! mid-point
    end if

    mask(p) = .true.

end function

pure function identity(x)

    real(b2o_double), intent(in) :: x
    real(b2o_double) :: identity

    identity = x

end function

end function distinct_helper
