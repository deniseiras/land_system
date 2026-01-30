subroutine b2o_convert_modes(handle, status)

! A converter for Mode-S (EHS/MRAR) reports.

use b2o_internal
use b2o_algorithm, only : sort, string_less_than
use b2o_option,    only : B2O_MODES_THINNING_INTERVAL

implicit none

#include <b2o_debug.h>

type(b2o_handle_t), intent(inout), target :: handle
integer(b2o_int),   intent(inout) :: status
type(b2o_handle_t), pointer :: bufr, odb

logical :: new_identifier, new_time_window
logical, allocatable :: mask(:)

integer(b2o_int) :: i, n, bad_quality
integer(b2o_int), parameter   :: varno(5) = [g_dd, g_ff, g_u, g_v, g_t]
integer(b2o_int), allocatable :: detailedPhaseOfFlight(:), aircraftRollAngleQuality(:)
integer(b2o_int), allocatable :: date(:), time(:), time_offset(:), time_window(:), index(:), priority(:)
integer(b2o_int), allocatable :: windDirectionFlag(:), windSpeedFlag(:), airTemperatureFlag(:), qualityInformation(:)

real(b2o_double) :: zhook_handle
real(b2o_double), pointer     :: hdr(:,:), conv(:,:), conv_body(:,:), body(:,:), errstat(:,:)
real(b2o_double), allocatable :: latitude(:), longitude(:), flightLevel(:)
real(b2o_double), allocatable :: windDirection(:), windSpeed(:), airTemperature(:)
real(b2o_double), allocatable :: array(:)

character(8), allocatable :: identifier(:)

if (lhook) call dr_hook('b2o_convert_modes', 0, zhook_handle)

bufr => handle
odb  => handle

n = b2o_get_int(bufr, "numberOfSubsets")

if (n == 0) then
    status = B2O_SKIP_MESSAGE
    if (lhook) call dr_hook('b2o_convert_modes', 1, zhook_handle)
    return
end if

call get(bufr, "aircraftRegistrationNumberOrOtherIdentification", identifier)
call get(bufr, "detailedPhaseOfFlight", detailedPhaseOfFlight)
call get(bufr, "aircraftRollAngleQuality", aircraftRollAngleQuality)
call get(bufr, "latitude", latitude)
call get(bufr, "longitude", longitude)
call get(bufr, "flightLevel", flightLevel)
call get(bufr, "windDirection", windDirection)
call get(bufr, "windDirection->associatedField", windDirectionFlag)
call get(bufr, "windSpeed", windSpeed)
call get(bufr, "windSpeed->associatedField", windSpeedFlag)
call get(bufr, "airTemperature", airTemperature)
call get(bufr, "airTemperature->associatedField", airTemperatureFlag)

if (b2o_is_defined(bufr, "qualityInformation")) then
    call get(bufr, "qualityInformation", qualityInformation) ! new Mode-S template
else
    qualityInformation = spread(0, 1, n) ! old AMDAR-WIGOS template
end if

! Compute time windows based on the thinning interval.

call get_date(bufr, date)
call get_time(bufr, time)
time_offset = [(b2o_time_diff(date(i), time(i), date(1), time(1)), i = 1, n)]
time_window = time_offset / B2O_MODES_THINNING_INTERVAL

! When doing the thinning, we want to give higher priority to reports where both
! wind and temperature are whitelisted.

priority = spread(0, 1, n)
where (windDirection /= ODB_MISSING_REAL .and. windSpeed /= ODB_MISSING_REAL .and. &
    &  windDirectionFlag == 0 .and. windSpeedFlag == 0) priority = priority + 1
where (airTemperature /= ODB_MISSING_REAL .and. airTemperatureFlag == 0) priority = priority + 1
where (qualityInformation > 0) priority = 0

! Prepare arrays for thinning: order by indentifier, time window, and (descending) priority.

index = [(i, i = 1, n)]
array = -priority
call sort(array, index)
array = time_window(index)
call sort(array, index)
array = transfer(identifier(index), array)
call sort(array, index, string_less_than)

! Do the thinning.

new_identifier = .true.
new_time_window = .true.
mask = spread(.false., 1, n)

i = 1
do while (.true.)
    if (new_identifier .or. new_time_window) then
        mask(index(i)) = (priority(index(i)) > 0)
    end if
    if (i == n) exit
    i = i + 1
    new_identifier = (identifier(index(i)) /= identifier(index(i-1)))
    new_time_window = (time_window(index(i)) /= time_window(index(i-1)))
end do

n = count(mask) ! number of reports after thinning

if (n == 0) then
    status = B2O_SKIP_MESSAGE
    if (lhook) call dr_hook('b2o_convert_modes', 1, zhook_handle)
    return
end if

! Do the conversion.

call b2o_reserve(odb, size(varno), n)

hdr       => b2o_use_table(odb, "hdr")
conv      => b2o_use_table(odb, "conv")
conv_body => b2o_use_table(odb, "conv_body")
body      => b2o_use_table(odb, "body")
errstat   => b2o_use_table(odb, "errstat")

call assert(size(hdr,  1) == n)
call assert(size(body, 1) == n * size(varno))

hdr(:,hdr_date) = pack(date, mask)
hdr(:,hdr_time) = pack(time, mask)
hdr(:,hdr_lat)  = pack(latitude, mask)
hdr(:,hdr_lon)  = pack(longitude, mask)
hdr(:,hdr_statid) = transfer(pack(identifier, mask), hdr(:,hdr_statid))
where (pack(aircraftRollAngleQuality, mask) == 1) hdr(:,hdr_report_rdbflag) = b2o_set_bit(1)
hdr(:,hdr_numlev) = 1

conv(:,conv_flight_phase)  = pack(detailedPhaseOfFlight, mask)
conv(:,conv_aircraft_type) = [(b2o_get_aircraft_type(handle, hdr(i,hdr_statid)), i = 1, n)]

body(:,body_vertco_type) = g_gpheight
body(:,body_vertco_reference_1) = reshape(spread(pack(flightLevel, mask), 1, size(varno)), [n * size(varno)])
body(:,body_varno) = reshape(spread(varno, 2, n), [n * size(varno)])

body(1::size(varno),body_obsvalue) = pack(windDirection, mask)
body(2::size(varno),body_obsvalue) = pack(windSpeed, mask)
body(5::size(varno),body_obsvalue) = pack(airTemperature, mask)

bad_quality = b2o_set_bits(3, 12, 2)
where (pack(windDirectionFlag, mask) == 1)  body(1::size(varno),body_datum_rdbflag) = bad_quality
where (pack(windSpeedFlag, mask) == 1)      body(2::size(varno),body_datum_rdbflag) = bad_quality
where (pack(airTemperatureFlag, mask) == 1) body(5::size(varno),body_datum_rdbflag) = bad_quality

if (lhook) call dr_hook('b2o_convert_modes', 1, zhook_handle)

end subroutine b2o_convert_modes
