module b2o_get

use b2o_accessor
use b2o_common
use b2o_handle
use b2o_utility

use eccodes

implicit none

interface b2o_get_array
    module procedure b2o_get_int_array
    module procedure b2o_get_real_array
    module procedure b2o_get_string_array
end interface

interface get
    module procedure b2o_get_int_array
    module procedure b2o_get_real_array
    module procedure b2o_get_string_array
end interface

contains

function b2o_is_missing(handle, key, rank) result(missing)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank
    logical :: missing

    missing = (b2o_get_real(handle, key, rank) == ODB_MISSING_REAL)

end function

function b2o_is_defined(handle, key, rank) result(defined)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank
    logical :: defined

    defined = handle%accessor%is_defined(handle%bufr_id, handle%subset_number, key, b2o_optional(1, rank))

end function

function b2o_which_defined(handle, keys, which, rank) result(found)

    type(b2o_handle_t), intent(in):: handle
    character(len=*), intent(in) :: keys(:)
    character(len=*), intent(inout) :: which
    integer(b2o_int), intent(in), optional :: rank
    logical :: found
    integer(b2o_int) :: i, r
    character(len=128) :: message

    r = 1
    if (present(rank)) then
        r = rank
    end if

    found = .false.

    do i = 1, size(keys)
        if (b2o_is_defined(handle, keys(i), rank=r)) then
            if (.not.found) then
                found = .true.
                which = keys(i)
            else
                write (message, "(a,a,' vs ',a)") "Found conflicting keys: ", &
                  & trim(which), trim(keys(i))
                call b2o_log(handle, B2O_ERROR, message)
                found = .false.
                exit
            end if
        end if
    end do

end function

function b2o_get_int(handle, key, rank, default) result(value)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank
    integer(b2o_int), intent(in), optional :: default
    integer(b2o_int) :: value, status

    if (len_trim(key) == 0) then
        value = b2o_optional(ODB_MISSING_INT, default)
        return
    end if

    value = handle%accessor%get_int(handle%bufr_id, handle%subset_number, key, b2o_optional(1, rank), status)

    call check_status(handle, key, status)

    if (value == CODES_MISSING_LONG) then
        value = b2o_optional(ODB_MISSING_INT, default)
    end if

end function

function b2o_get_int_if_defined(handle, key, rank, default) result(value)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank
    integer(b2o_int), intent(in), optional :: default
    integer(b2o_int) :: value

    if (b2o_is_defined(handle, key, rank)) then
        value = b2o_get_int(handle, key, rank, default)
    else
        value = b2o_optional(ODB_MISSING_INT, default)
    end if

end function

recursive function b2o_get_real(handle, key, rank, default, nesting) result(value)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank
    real(b2o_double), intent(in), optional :: default
    integer(b2o_int), intent(in), optional :: nesting
    real(b2o_double) :: value
    integer(b2o_int) :: a, i
    integer(b2o_int) :: status
    character(len=B2O_MAX_KEY_LEN) :: path, attribute

    if (len_trim(key) == 0) then
        value = b2o_optional(ODB_MISSING_REAL, default)
        return
    end if

    if (present(nesting)) then
        a = index(key, "->") ! find attribute position within the key
        if (a == 0) then
            call b2o_log(handle, B2O_ERROR, "Key '" // trim(key) // "' has no attribute")
            call b2o_exit(B2O_VALUE_ERROR)
        end if
        attribute = key(a+2:)
        if (nesting >= 0) then
            path = key
            do i = 1, nesting
                path = trim(path) // "->" // attribute
            end do
            value = b2o_get_real(handle, path, rank)
            return
        else if (nesting == -1) then ! find the last nested attribute
            path = key
            do while (b2o_is_defined(handle, trim(path) // "->" // attribute, rank))
                path = trim(path) // "->" // attribute
            end do
            value = b2o_get_real(handle, path, rank)
            return
        else
            call b2o_log(handle, B2O_ERROR, "Invalid nesting level")
            call b2o_exit(B2O_VALUE_ERROR)
        end if
    end if

    value = handle%accessor%get_real(handle%bufr_id, handle%subset_number, key, b2o_optional(1, rank), status)

    call check_status(handle, key, status)

    if (value == CODES_MISSING_DOUBLE) then
        value = b2o_optional(ODB_MISSING_REAL, default)
    end if

end function

function b2o_get_real_if_defined(handle, key, rank, default, nesting) result(value)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in), optional :: rank, nesting
    real(b2o_double), intent(in), optional :: default
    real(b2o_double) :: value

    if (b2o_is_defined(handle, key, rank)) then
        value = b2o_get_real(handle, key, rank, default, nesting)
    else
        value = b2o_optional(ODB_MISSING_REAL, default)
    end if

end function

subroutine b2o_get_string(handle, key, value)

    use b2o_utility, only : coerce_to_ascii

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value
    integer(b2o_int) :: status

    call handle%accessor%get_string(handle%bufr_id, handle%subset_number, key, value, status)
    call check_status(handle, key, status)
    call coerce_to_ascii(value)

end subroutine

subroutine b2o_get_string_if_defined(handle, key, value, default)

    type(b2o_handle_t), intent(in) :: handle
    character(*), intent(in) :: key
    character(*), intent(inout) :: value
    character(*), intent(in), optional :: default

    if (b2o_is_defined(handle, key)) then
        call b2o_get_string(handle, key, value)
    else if (present(default)) then
        value = default
    else
        value = repeat(achar(0), len(value))
    end if

end subroutine

subroutine check_status(handle, key, status)

    type(b2o_handle_t), intent(in) :: handle
    character(*), intent(in) :: key
    integer(b2o_int), intent(in) :: status
    character(256) :: message

    if (status /= CODES_SUCCESS) then
        message = ""
        call codes_get_error_string(status, message)
        call b2o_log(handle, B2O_ERROR, trim(message) // ": " // trim(key))
        call b2o_exit(status)
    end if

end subroutine

function b2o_get_date(handle, rank) result(date)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(in), optional :: rank
    integer(b2o_int) :: date, year, month, day

    date  = ODB_MISSING_INT
    year  = b2o_get_int(handle, "year",  rank)
    month = b2o_get_int(handle, "month", rank)
    day   = b2o_get_int(handle, "day",   rank)

    if (any([year, month, day] == ODB_MISSING_INT)) then
        call b2o_log(handle, B2O_WARNING, "Found missing year/month/day value")
        return
    end if

    date = year * 10000 + month * 100 + day

end function

subroutine get_date(handle, date)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), allocatable, intent(out) :: date(:)
    integer(b2o_int), allocatable :: year(:), month(:), day(:)

    call get(handle, "year", year)
    call get(handle, "month", month)
    call get(handle, "day", day)

    allocate(date(size(year)))

    where (year /= ODB_MISSING_INT .and. month /= ODB_MISSING_INT .and. day /= ODB_MISSING_INT)
        date = year * 10000 + month * 100 + day
    elsewhere
        date = ODB_MISSING_INT
    end where

end subroutine

function b2o_get_time(handle, rank) result(time)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(in), optional :: rank
    integer(b2o_int) :: time
    integer(b2o_int) :: hour, minute, second
    real(b2o_double) :: d_second

    time   = ODB_MISSING_INT
    hour   = b2o_get_int(handle, "hour",   rank)
    minute = b2o_get_int(handle, "minute", rank)

    d_second = b2o_get_real_if_defined(handle, "second", rank, default=0.d0)
    second = nint(min(59.d0, d_second))

    if (any([hour, minute] == ODB_MISSING_INT)) then
        call b2o_log(handle, B2O_WARNING, "Found missing hour/minute value")
        return
    end if

    time = hour * 10000 + minute * 100 + second

end function

subroutine get_time(handle, time)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), allocatable, intent(out) :: time(:)
    integer(b2o_int), allocatable :: hour(:), minute(:)
    real(b2o_double), allocatable :: second(:)

    call get(handle, "hour", hour)
    call get(handle, "minute", minute)
    call get(handle, "second", second)

    allocate(time(size(hour)))

    where (hour /= ODB_MISSING_INT .and. minute /= ODB_MISSING_INT .and. second /= ODB_MISSING_REAL)
        time = hour * 10000 + minute * 100 + nint(min(59.0, second))
    else where
        time = ODB_MISSING_INT
    end where

end subroutine

function b2o_get_lat(handle, rdbflag, rank) result(lat)

    use b2o_utility, only : b2o_round

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(inout), optional :: rdbflag
    integer(b2o_int), intent(in), optional :: rank
    real(b2o_double) :: lat

    lat = b2o_get_real_if_defined(handle, "latitude", rank)
    lat = b2o_round(lat)

    if (present(rdbflag)) then
        rdbflag = b2o_get_rdbflag(handle, "latitude", 27, rdbflag)
    end if

end function

function b2o_get_lon(handle, rdbflag, rank) result(lon)

    use b2o_utility, only : b2o_round

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(inout), optional :: rdbflag
    integer(b2o_int), intent(in), optional :: rank
    real(b2o_double) :: lon

    lon = b2o_get_real_if_defined(handle, "longitude", rank)
    lon = b2o_round(lon)

    if (present(rdbflag)) then
        rdbflag = b2o_get_rdbflag(handle, "longitude", 21, rdbflag)
    end if

end function

function b2o_get_lat_lon(handle, rank, default) result(coords)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(in), optional :: rank
    real(b2o_double), intent(in), optional :: default(2)
    real(b2o_double) :: coords(2)

    coords(1) = b2o_get_lat(handle, rank=rank)
    coords(2) = b2o_get_lon(handle, rank=rank)

    if (present(default)) then
        coords = merge(default, coords, any(coords == ODB_MISSING_REAL))
    end if

end function

function b2o_get_oscar_lat_lon(handle, report_event1) result(coords)

    use b2o_utility, only : b2o_set_bits
    use b2o_option, only : tolerance => B2O_STATION_POSITION_TOLERANCE

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(inout) :: report_event1
    real(b2o_double) :: coords(2), coords1(2), coords2(2), delta

    coords1 = b2o_get_lat_lon(handle, rank=1)
    coords2 = b2o_get_lat_lon(handle, rank=2, default=coords1)

    coords = merge(coords2, coords1, any(coords1 == ODB_MISSING_REAL))

    if (tolerance < 1.d0) then
        delta = maxval(abs(coords - coords2)) ! in degreese
    else
        delta = b2o_distance(coords, coords2) ! in meters
    end if

    coords = merge(coords2, coords, delta > tolerance)

    if (any(coords /= coords1)) then
        report_event1 = b2o_set_bits(1, 22, 1, report_event1)
    end if

end function

function b2o_get_oscar_stalt(handle, key, report_event1) result(stalt)

    use b2o_utility, only : b2o_set_bits
    use b2o_option,  only : tolerance => B2O_STATION_HEIGHT_TOLERANCE

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(inout) :: report_event1
    real(b2o_double) :: stalt, stalt1, stalt2

    stalt1 = b2o_get_real(handle, key)
    stalt2 = b2o_get_real_if_defined(handle, "heightOfStation", default=stalt1)

    stalt = merge(stalt2, stalt1, stalt1 == ODB_MISSING_REAL)
    stalt = merge(stalt2, stalt, abs(stalt2-stalt) > tolerance)

    if (stalt /= stalt1) then
        report_event1 = b2o_set_bits(1, 21, 1, report_event1)
    end if

end function

function b2o_get_rdbflag(handle, key, skip, rdbflag, rank)

    use b2o_utility, only : b2o_set_bits

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: skip
    integer(b2o_int), intent(in) :: rdbflag
    integer(b2o_int), intent(in), optional :: rank
    real(b2o_double) :: b2o_get_rdbflag
    real(b2o_double) :: confidence
    integer(b2o_int) :: quality
    real(b2o_double) :: hook_handle
    character(len=64) :: message

    if (len_trim(key) == 0) then
        b2o_get_rdbflag = rdbflag
        return
    end if

    quality = 0
    confidence = ODB_MISSING_REAL

    if (b2o_is_defined(handle, trim(key) // "->percentConfidence", rank)) then
        confidence = b2o_get_real(handle, trim(key) // "->percentConfidence", rank)
    end if

         if (confidence > 69 .and. confidence <= 100) then ; quality = 0
    else if (confidence > 46 .and. confidence <=  69) then ; quality = 1
    else if (confidence > 23 .and. confidence <=  46) then ; quality = 2
    else if (confidence >= 0 .and. confidence <=  23) then ; quality = 3
    else if (confidence /= ODB_MISSING_REAL) then
        write(message, "(a,f0.0)") "Unexpected confidence value: ", confidence
        call b2o_log(handle, B2O_WARNING, message)
    end  if

    b2o_get_rdbflag = b2o_set_bits(quality, skip, 2, rdbflag)

end function

function b2o_get_station_id(handle, status) result (station_id)

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(out) :: status
    character(len=8) :: station_id
    integer(b2o_int) :: blockNumber, stationNumber

    station_id = "        "
    status = B2O_SUCCESS

    blockNumber = b2o_get_int(handle, "blockNumber")
    stationNumber = b2o_get_int(handle, "stationNumber")

    if (any((/blockNumber, stationNumber/) == ODB_MISSING_INT)) then
        call b2o_log(handle, B2O_WARNING, "Missing block number or station number")
        status = B2O_SKIP_MESSAGE
        return
    end if

    if (blockNumber < 0 .or. blockNumber > 99) then
        call b2o_log(handle, B2O_WARNING, "Invalid block number")
        status = B2O_SKIP_MESSAGE
        return
    end if

    if (stationNumber < 0 .or. stationNumber > 999) then
        call b2o_log(handle, B2O_WARNING, "Invalid station number")
        status = B2O_SKIP_MESSAGE
        return
    end if

    write (station_id, "(i5.5)") blockNumber * 1000 + stationNumber

end function

function b2o_get_ident_if_defined(handle, default) result(ident)

    ! Gets 'ident', defined in (ECMWF) section 2, for templates with WIGOS indentifiers.

    type(b2o_handle_t), intent(in) :: handle
    character(8), intent(in), optional :: default
    real(b2o_double) :: ident
    character(8) :: s_ident
    integer :: status
    logical :: is_defined_ident

    call codes_is_defined(handle%bufr_id, "ident", status)
    is_defined_ident = (status .eq. 1)

    if (b2o_is_defined(handle, "wigosIdentifierSeries").and.is_defined_ident) then
        call b2o_get_string(handle, "ident", s_ident)
        ident = transfer(s_ident, ident)
    else if (present(default)) then
        ident = transfer(default, ident)
    else
        ident = transfer(repeat(achar(0), 8), ident)
    end if

end function

function b2o_get_wigosid_if_defined(handle) result(wigosid)

    type(b2o_handle_t), intent(in) :: handle
    real(b2o_double) :: wigosid(4)
    character(32) :: string
    character(16+1) :: part4 ! +1 to account for the terminating '\0' character
    integer :: part(3), iostat

    if (.not.b2o_is_defined(handle, "wigosIdentifierSeries")) then
        go to 1
    end if

    part(1) = b2o_get_int(handle, "wigosIdentifierSeries")
    part(2) = b2o_get_int(handle, "wigosIssuerOfIdentifier")
    part(3) = b2o_get_int(handle, "wigosIssueNumber")

    call b2o_get_string(handle, "wigosLocalIdentifierCharacter", part4)

    part4 = trim(adjustl(part4)) // achar(0)

    if (any(part(1:3) == ODB_MISSING_INT) .or. len_trim(part4) == 0) then
        call b2o_log(handle, B2O_WARNING, "Missing WIGOS station identifier")
        go to 1
    end if

    if (part(1) /= 0 .or. any(.not.between(part(2:3), 0, 65534))) then
        call b2o_log(handle, B2O_WARNING, "Invalid WIGOS station identifier")
        go to 1
    end if

    write (string, "(i0,'-',i0,'-',i0,'-',a)", iostat=iostat) part(1:3), part4

    if (iostat /= 0) then
        call b2o_log(handle, B2O_WARNING, "Malformed WIGOS station identifier")
        go to 1
    end if

    wigosid = transfer(string, wigosid)

    return

1   wigosid = transfer(repeat(achar(0), 32), wigosid)

contains

logical elemental pure function between(x, lo, hi)

    integer, intent(in) :: x, lo, hi ; between = (x >= lo) .and. (x <= hi)

end function

end function

function b2o_get_aircraft_type(handle, statid) result(aircraft_type)

    use b2o_algorithm, only : binary_search, string_less_than
    use b2o_option, only : file => B2O_AIRCRAFT_TYPES, old_file => B2O_AIRCRAFT_TYPE_MAPPINGS

    type(b2o_handle_t), intent(inout) :: handle
    real(b2o_double), intent(in) :: statid
    real(b2o_double) :: aircraft_type
    real(b2o_double), allocatable, save :: csv_table(:,:)
    integer, parameter :: csv_statid = 1
    integer, parameter :: csv_aircraft_type = 2
    integer :: p

    if (.not.allocated(csv_table)) then
        csv_table = load(merge(old_file, file, len_trim(old_file) > 0))
    end if

    p = binary_search(csv_table(:,csv_statid), statid, string_less_than)

    if (p > 0) then
        aircraft_type = csv_table(p,csv_aircraft_type)
    else
        aircraft_type = 0
    end if

contains

function load(file) result(csv_table)

    use b2o_algorithm, only : order_by
    use b2o_utility, only : b2o_read_csv

    character(len=*), intent(in)  :: file
    real(b2o_double), allocatable :: csv_table(:,:)
    character(len=8), allocatable :: table(:,:)

    call b2o_log(handle%context, B2O_INFO, "Loading aircraft types from " // trim(file))

    call b2o_read_csv(file, table)

    if (size(table) == 0) then
        call b2o_log(handle%context, B2O_WARNING, "Could not load aircraft types from " // trim(file))
    end if

    csv_table = reshape(transfer(table, csv_table), shape(table))

    call order_by(csv_table, [csv_statid], string_less_than)

end function

end function

function b2o_get_buoy_height(handle, statid) result(height)

    use b2o_algorithm, only : select, string_less_than
    use b2o_option,    only : file => B2O_BUOY_HEIGHTS, default => B2O_DEFAULT_BUOY_HEIGHT

    type(b2o_handle_t), intent(inout) :: handle
    real(b2o_double), intent(in) :: statid
    real(b2o_double) :: height
    real(b2o_double), allocatable, save :: buoy(:,:)
    integer, parameter :: buoy_statid = 1
    integer, parameter :: buoy_height = 2
    real(b2o_double), allocatable :: result(:,:)

    if (.not.allocated(buoy)) then
        buoy = load(file)
    end if

    result = select([buoy_height], &
           & from=buoy, &
           & match=[buoy_statid], &
           & against=[statid], &
           & compare=string_less_than, &
           & limit=1)

    if (size(result, 1) > 0) then
        height = result(1,1)
    else
        height = default
    end if

contains

function load(file) result(buoy)

    use b2o_algorithm, only : order_by
    use b2o_utility,   only : b2o_read_csv
    use b2o_string,    only : parse_double

    character(*), intent(in)  :: file
    real(b2o_double), allocatable :: buoy(:,:)
    character(8), allocatable :: table(:,:)
    integer :: i

    call b2o_log(handle%context, B2O_INFO, "Loading buoy heights from " // trim(file))

    call b2o_read_csv(file, table)

    allocate(buoy(size(table, 1), 2))

    if (size(table) == 0) then
        call b2o_log(handle%context, B2O_WARNING, "Could not load buoy heights from " // trim(file))
        return
    end if

    do i = 1, size(table, 1)
        buoy(i,buoy_statid) = transfer(table(i,buoy_statid), buoy(i,buoy_statid))
        buoy(i,buoy_height) = parse_double(table(i,buoy_height))
    end do

    call order_by(buoy, [buoy_statid], string_less_than)

end function

end function

subroutine b2o_get_int_array(handle, key, values, n)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out), allocatable :: values(:)
    integer(b2o_int), intent(in), optional :: n

    call codes_get_int_array(handle%bufr_id, key, values)
    where (values(:) == CODES_MISSING_LONG) values(:) = ODB_MISSING_INT

    if (present(n)) then
        if (size(values) > n) then
            call b2o_resize(values, n)
        else if (size(values) < n) then
            call b2o_log(handle, B2O_ERROR, "Unexpected number of " // trim(key) // " values")
            call b2o_exit(1)
        end if
    end if

end subroutine

subroutine b2o_get_real_array(handle, key, values, n)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: key
    real(b2o_double), intent(out), allocatable :: values(:)
    integer(b2o_int), intent(in), optional :: n

    call codes_get_real8_array(handle%bufr_id, key, values)
    where (values(:) == CODES_MISSING_DOUBLE) values(:) = ODB_MISSING_REAL

    ! Allow to get an exact number of values - sometimes there can be more
    ! values for the given key than desired (e.g. pressure level of TEMP wind shear).

    if (present(n)) then
        if (size(values) > n) then
            call b2o_resize(values, n)
        else if (size(values) < n) then
            call b2o_log(handle, B2O_ERROR, "Unexpected number of " // trim(key) // " values")
            call b2o_exit(1)
        end if
    end if

end subroutine

subroutine b2o_get_string_array(handle, key, values)

    type(b2o_handle_t), intent(in) :: handle
    character(*), intent(in) :: key
    character(*), intent(out), allocatable :: values(:)
    integer :: size

    call codes_get_size(handle%bufr_id, key, size)
    allocate(values(size)) ! ecCodes doesn't allocate string arrays automatically
    call codes_get_string_array(handle%bufr_id, key, values)

end subroutine


end module b2o_get
