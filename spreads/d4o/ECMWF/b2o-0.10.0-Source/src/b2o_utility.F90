module b2o_utility

use b2o_common

implicit none

interface

    subroutine b2o_solar_azimuth(date, time, lat, lon, azimuth) &
        & bind(c, name="codb_solar_azimuth_")
        use, intrinsic :: iso_c_binding
        real(c_double), intent(in)  :: date, time, lat, lon
        real(c_double), intent(out) :: azimuth
    end subroutine

    subroutine b2o_solar_zenith(date, time, lat, lon, zenith) &
        & bind(c, name="codb_solar_zenith_")
        use, intrinsic :: iso_c_binding
        real(c_double), intent(in)  :: date, time, lat, lon
        real(c_double), intent(out) :: zenith
    end subroutine

    subroutine secdiff(year1, month1, day1, hour1, min1, sec1, &
        & year2, month2, day2, hour2, min2, sec2, seconds, iret) &
        & bind(c, name="secdiff") ! from eclib.h
        use, intrinsic :: iso_c_binding
        integer(c_int), intent(in) :: year1, month1, day1, hour1, min1, sec1
        integer(c_int), intent(in) :: year2, month2, day2, hour2, min2, sec2
        integer(c_int), intent(out) :: seconds, iret
    end subroutine

    subroutine secincr(year, month, day, hour, min, sec, seconds, &
        & new_year, new_month, new_day, new_hour, new_min, new_sec, iret) &
        & bind(c, name="secincr") ! from eclib.h
        use, intrinsic :: iso_c_binding
        integer(c_int), intent(in) :: year, month, day, hour, min, sec, seconds
        integer(c_int), intent(out) :: new_year, new_month, new_day, new_hour, new_min, new_sec, iret
    end subroutine

end interface

interface b2o_resize
    module procedure b2o_resize_int
    module procedure b2o_resize_real
end interface

interface b2o_find_free_unit ! for backwards compatibility
    module procedure b2o_get_free_unit
end interface

contains

subroutine b2o_time_inc(date, time, seconds, new_date, new_time)

    ! Increments date/time by the given number of seconds.

    integer(b2o_int), value :: date, time, seconds
    integer(b2o_int), intent(out) :: new_date, new_time
    integer(b2o_int) :: year, month, day, hour, minute, second, iret

    call secincr(date / 10000, mod(date, 10000) / 100, mod(date, 100), &
               & time / 10000, mod(time / 100, 100),   mod(time, 100), seconds, &
               & year, month, day, hour, minute, second, iret)

    new_date = year * 10000 + month * 100 + day
    new_time = hour * 10000 + minute * 100 + second

end subroutine

function b2o_time_diff(date1, time1, date2, time2) result (seconds)

    ! Returns time difference (in seconds) between two date/times.

    integer(b2o_int), intent(in) :: date1, time1, date2, time2
    integer(b2o_int) :: seconds, iret

    call secdiff(date1 / 10000, mod(date1, 10000) / 100, mod(date1, 100), &
               & time1 / 10000, mod(time1 / 100, 100),   mod(time1, 100), &
               & date2 / 10000, mod(date2, 10000) / 100, mod(date2, 100), &
               & time2 / 10000, mod(time2 / 100, 100),   mod(time2, 100), &
               & seconds, iret)
end function

pure elemental function b2o_wind_u_component(s, d) result(u)

    real(b2o_double), intent(in) :: s, d
    real(b2o_double) :: u
    real(b2o_double), parameter :: pi = 2.d0 * asin(1.d0)
    real(b2o_double), parameter :: in_radians = pi / 180.d0

    if (any([s, d] == ODB_MISSING_REAL)) then
        u = ODB_MISSING_REAL
    else
        u = -s * sin(d * in_radians)
    end if

end function

pure elemental function b2o_wind_v_component(s, d) result(v)

    real(b2o_double), intent(in) :: s, d
    real(b2o_double) :: v
    real(b2o_double), parameter :: pi = 2.d0 * asin(1.d0)
    real(b2o_double), parameter :: in_radians = pi / 180.d0

    if (any([s, d] == ODB_MISSING_REAL)) then
        v = ODB_MISSING_REAL
    else
        v = -s * cos(d * in_radians)
    end if

end function

pure elemental function b2o_wind_speed(u, v) result(s)

    real(b2o_double), intent(in) :: u, v
    real(b2o_double) :: s

    if (any([u, v] == ODB_MISSING_REAL)) then
        s = ODB_MISSING_REAL
    else
        s = norm2([u, v])
    end if

end function

pure elemental function b2o_wind_direction(u, v) result(d)

    real(b2o_double), intent(in) :: u, v
    real(b2o_double) :: d
    real(b2o_double), parameter :: pi = 2.d0 * asin(1.d0)
    real(b2o_double), parameter :: in_degrees = 180.d0 / pi

    if (any([u, v] == ODB_MISSING_REAL)) then
        d = ODB_MISSING_REAL
    else
        d = mod(270.d0 - atan2(v, u) * in_degrees, 360.d0)
    end if

end function

elemental function b2o_round(x)

    real(b2o_double), intent(in) :: x
    real(b2o_double) :: b2o_round
    real(b2o_double), parameter :: xround = 100000

    b2o_round = x

    if (x /= ODB_MISSING_REAL) then
        if (abs(x) < 10000000) then
            b2o_round = (anint(xround * x)) / xround
        end if
    end if

end function

pure function b2o_distance(coords1, coords2) result(delta)

    ! Returns distance (in meters) between two points, measured along the great circle.

    real(b2o_double), intent(in) :: coords1(2), coords2(2)
    real(b2o_double) :: delta, lat1, lon1, lat2, lon2
    real(b2o_double), parameter :: pi = 2.d0 * asin(1.d0)
    real(b2o_double), parameter :: radians = pi / 180.d0
    real(b2o_double), parameter :: r_earth = 180.d0 * 60.d0 / pi * 1.852d0 * 1000.d0 ! meters

    if (any([coords1, coords2] == ODB_MISSING_REAL)) then
        delta = ODB_MISSING_REAL
        return
    end if

    lat1 = coords1(1) * radians
    lon1 = coords1(2) * radians
    lat2 = coords2(1) * radians
    lon2 = coords2(2) * radians

    delta = r_earth * acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon1 - lon2))

end function

elemental subroutine coerce_to_ascii(string)

    ! Coerces characters in a string to printable (7-bit) ASCII symbols by
    ! replacing non-printable characters with spaces.

    character(len=*), intent(inout) :: string
    integer :: i, code

    do i = 1, len(string)
        code = iachar(string(i:i))
        if (code < 32 .or. code >= 127) string(i:i) = ' '
    end do

end subroutine

subroutine b2o_locf(array, default)

    ! Fills missing values in an array with last occurrences carried forward.

    real(b2o_double), intent(inout) :: array(:)
    real(b2o_double), intent(in) :: default
    real(b2o_double) :: last
    integer(b2o_int) :: i

    last = default

    ! Find the first non-missing value
    do i = 1, size(array)
        if (array(i) /= ODB_MISSING_REAL) then
            last = array(i)
            exit
        end if
    end do

    ! Pad missing values with the last seen non-missing value
    do i = 1, size(array)
        if (array(i) /= ODB_MISSING_REAL) then
            last = array(i)
        else
            array(i) = last
        end if
    end do

end subroutine

pure function b2o_find_if_not(f, array, not_found) result(value)

    ! Returns first element of an array that satisfies the predicate f,
    ! otherwise returns not_found.

    interface
        logical pure function f(x)
            import b2o_double
            real(b2o_double), intent(in) :: x
        end function
    end interface

    real(b2o_double), intent(in) :: array(:), not_found
    real(b2o_double) :: value
    integer(b2o_int) :: i

    value = not_found

    do i = 1, size(array)
        if (.not.f(array(i))) then
            value = array(i)
            exit
        end if
    end do

end function

pure function b2o_is_missing_real(x) result(is_missing)

    real(b2o_double), intent(in) :: x
    logical :: is_missing

    is_missing = (x == ODB_MISSING_REAL)

end function

pure function b2o_get_bit(bits, skip) result(bit)

    integer(b2o_int), intent(in) :: bits, skip
    integer(b2o_int) :: bit

    bit = b2o_get_bits(bits, skip, 1)

end function

pure function b2o_get_bits(source, skip, width)

    integer(b2o_int), intent(in) :: source
    integer(b2o_int), intent(in) :: skip
    integer(b2o_int), intent(in) :: width
    integer(b2o_int) :: b2o_get_bits
    integer(b2o_int) :: offset, select_mask

    offset = 32 - (skip + width)
    select_mask = ishft(ishft(not(0), width-32), offset)
    b2o_get_bits = ishft(iand(source, select_mask), -offset)

end function

pure function b2o_set_bit(skip) result(bits)

    integer(b2o_int), intent(in) :: skip
    integer(b2o_int) :: bits

    bits = b2o_set_bits(1, skip, 1)

end function

pure function b2o_set_bits(source, skip, width, target)

    integer(b2o_int), intent(in) :: source
    integer(b2o_int), intent(in) :: skip
    integer(b2o_int), intent(in) :: width
    integer(b2o_int), intent(in), optional :: target
    integer(b2o_int) :: b2o_set_bits
    integer(b2o_int) :: dest, offset, erase_mask

    dest = 0
    if (present(target)) then
        dest = target
    end if

    offset = 32 - (skip + width)
    erase_mask = not(ishft(ishft(not(0), width-32), offset))
    b2o_set_bits = ior(iand(dest, erase_mask), ishft(source, offset))

end function

pure function b2o_any_bits(bitfield, skip, width)

    integer(b2o_int), intent(in) :: bitfield
    integer(b2o_int), intent(in) :: skip
    integer(b2o_int), intent(in) :: width
    integer(b2o_int) :: offset, select_mask
    logical :: b2o_any_bits

    offset = 32 - (skip + width)
    select_mask = ishft(ishft(not(0), width-32), offset)
    b2o_any_bits = iand(bitfield, select_mask) /= 0

end function

elemental function b2o_height_to_pressure(h) result(p)

    ! Converts gepotential height (m) to pressure (hPa) using ICAO standard atmosphere.

    real(b2o_double), intent(in) :: h
    real(b2o_double) :: p, y
    real(b2o_double), parameter :: a = 5.252368255329d0
    real(b2o_double), parameter :: b = 44330.769230769d0
    real(b2o_double), parameter :: c = 0.000157583169442d0
    real(b2o_double), parameter :: ptro = 226.547172d0
    real(b2o_double), parameter :: po = 1013.25d0

    if (h == ODB_MISSING_REAL) then
        p =  ODB_MISSING_REAL
    else if (h > 11000.d0) then
        y = -c * (h - 11000.d0)
        p = ptro * exp(y)
    else
        y = 1.d0 - h / b
        p = po * (y**a)
    endif

end function

function b2o_height_to_geopotential(h, lat) result(z)

    ! Converts geometric height (m) to geopotential (m^2/s^2).

    real(b2o_double), intent(in) :: h
    real(b2o_double), value :: lat
    real(b2o_double) :: z, r, phi2
    real(b2o_double), parameter :: pi = acos(-1.d0)
    real(b2o_double), parameter :: radians = pi / 180.d0
    real(b2o_double), parameter :: phi45 = sin(45.d0 * radians)

    if (any((/h, lat/) .eq. ODB_MISSING_REAL)) then
        z = ODB_MISSING_REAL
        return
    end if

    lat = lat * radians
    phi2 = sin(lat) * sin(lat)
    r = 6378.137d3 / (1.006803d0 - 0.006706d0 * phi2)
    z = gamma(phi2) / gamma(phi45**2) * (r * h) / (r + h) * B2O_GRAVITY

contains

    elemental function gamma(phi2)
        real(b2o_double), intent(in) :: phi2
        real(b2o_double) :: gamma
        gamma = 9.780325d0 * (1 + 0.00193185d0 * phi2) / sqrt(1 - 0.00669435d0 * phi2)
    end function

end function

pure function b2o_planck_coeffs(wavenumbers) result(coeffs)

    real(b2o_double), intent(in) :: wavenumbers(:)
    real(b2o_double) :: coeffs(2,size(wavenumbers))
    integer(b2o_int) :: n

    real(b2o_double), parameter :: c1 = 1.1910659e-10_b2o_double ! W/(m^2.ster.m^-2)
    real(b2o_double), parameter :: c2 = 1.438833_b2o_double      ! K/cm^-1

    do n = 1, size(wavenumbers)
        coeffs(1,n) = c1 * wavenumbers(n) ** 3
        coeffs(2,n) = c2 * wavenumbers(n)
    end do

end function

pure function b2o_radiance_to_brightnes_temperature(planck_coeffs, r) result(bt)

    real(b2o_double), intent(in) :: planck_coeffs(2), r
    real(b2o_double) :: bt

    bt = planck_coeffs(2) / log(planck_coeffs(1) / r + 1.d0)

end function

elemental function b2o_sounding_significance_flags(table, bufr_flags, pressure) result(odb_flags)

    ! Maps sounding significance flags from BUFR to ODB convention.

    integer(b2o_int), intent(in) :: table, bufr_flags
    real(b2o_double), intent(in) :: pressure
    integer(b2o_int) :: odb_flags
    integer(b2o_int) :: i, j, bit

    integer(b2o_int), parameter :: bufr_table(0:5,2) = reshape([26, 25, 27, 28, 29, 30, 15, 14, 16, 17, 18, 19], [6,2])
    integer(b2o_int), parameter :: odb_table(0:5) = [-1, 25, 30, 31, 23, 24]

    odb_flags = 0

    if (bufr_flags == ODB_MISSING_INT .or. pressure == ODB_MISSING_REAL) then
        return
    end if

    j = merge(1, 2, table == 8001)

    do i = 1, ubound(bufr_table, 1)
        bit = b2o_get_bit(bufr_flags, bufr_table(i,j))
        odb_flags = ior(odb_flags, b2o_set_bits(bit, odb_table(i), 1))
    end do

    bit = b2o_get_bit(bufr_flags, bufr_table(0,j)) ! standard pressure level
    odb_flags = ior(odb_flags, b2o_set_bit(merge(27, 29, pressure >= 10000.d0) - bit))

end function

pure function b2o_synop_ppcode(varno, vertco_type, vertco_reference_1) result(ppcode)

    use b2o_schema, only : g_gpheight, g_pressure, g_ps, g_z

    integer(b2o_int), intent(in) :: varno, vertco_type
    real(b2o_double), intent(in) :: vertco_reference_1
    integer(b2o_int) :: ppcode

    ppcode = ODB_MISSING_INT

    if (varno == g_ps) then
        if (vertco_type == g_gpheight) then
            select case (nint(vertco_reference_1 / B2O_GRAVITY))
            case (0)     ; ppcode = 0
            case (500)   ; ppcode = 4
            case (1000)  ; ppcode = 5
            case (2000)  ; ppcode = 6
            case (3000)  ; ppcode = 7
            case (4000)  ; ppcode = 8
            end select
        end if
    else if (varno == g_z) then
        if (vertco_type == g_pressure) then
            select case (nint(vertco_reference_1))
            case (100000) ; ppcode = 10
            case (92500)  ; ppcode = 12
            case (85000)  ; ppcode = 2
            case (70000)  ; ppcode = 3
            case (50000)  ; ppcode = 11
            case (90000)  ; ppcode = 9
            end select
        else if (vertco_type == g_gpheight) then
            ppcode = 1
        end if
    else
        ppcode = 1
    end if

end function

subroutine b2o_resize_int(array, n)

    integer(b2o_int), intent(inout), allocatable :: array(:)
    integer(b2o_int), intent(in) :: n
    integer(b2o_int), allocatable :: temporary(:)

    if (.not.allocated(array)) then
        allocate(array(n))
    else if (size(array) /= n) then
        allocate(temporary(size(array)))
        temporary(:) = array(:)
        deallocate(array)
        allocate(array(n))
        if (size(temporary) > n) then
            array(:) = temporary(:n)
        else
            array(:size(temporary)) = temporary(:)
        end if
    end if

end subroutine

subroutine b2o_resize_real(array, n)

    real(b2o_double), intent(inout), allocatable :: array(:)
    integer(b2o_int), intent(in) :: n
    real(b2o_double), allocatable :: temporary(:)

    if (.not.allocated(array)) then
        allocate(array(n))
    else if (size(array) /= n) then
        allocate(temporary(size(array)))
        temporary(:) = array(:)
        deallocate(array)
        allocate(array(n))
        if (size(temporary) > n) then
            array(:) = temporary(:n)
        else
            array(:size(temporary)) = temporary(:)
        end if
    end if

end subroutine

subroutine b2o_read_csv(file, table, skip_rows)

    ! Reads CSV file and returns 2D string array.

    character(len=*), intent(in) :: file
    character(len=*), allocatable, intent(out) :: table(:,:)
    integer(b2o_int), intent(in), optional :: skip_rows(:)
    integer(b2o_int), allocatable :: skip_rows_(:)
    character(len=1), parameter :: delimiter = ","
    character(len=1024) :: line
    integer(b2o_int) :: unit, iostat
    integer(b2o_int) :: n_rows, n_records, n_fields
    integer(b2o_int) :: i, row, record, field, from, to

    allocate(skip_rows_(0)); if (present(skip_rows)) skip_rows_ = skip_rows
    if (allocated(table)) deallocate(table)

    ! Open the file

    unit = b2o_get_free_unit()
    open (unit=unit, file=file, status="old", action="read", iostat=iostat)

    if (iostat /= 0) then
        allocate(table(0,0))
        return
    end if

    ! Count the total number of rows and the number actual records

    n_rows = 0
    n_records = 0

    do while (.true.)
        read (unit, fmt=*, iostat=iostat)
        if (iostat /= 0) exit
        n_rows = n_rows + 1
        if (any(n_rows == skip_rows_)) cycle
        n_records = n_records + 1
    end do

    rewind (unit)

    ! Find the first record and count the number of fields

    do row = 1, n_rows
        read (unit, fmt="(a)") line
        if (any(row == skip_rows_)) cycle
        exit
    end do

    n_fields = 1
    do i = 1, len_trim(line)
        if (line(i:i) == delimiter) n_fields = n_fields + 1
    end do

    rewind (unit)

    ! Read the records

    allocate(table(n_records,n_fields))

    row = 0
    record = 0

    do while (.true.)
        read (unit, fmt="(a)", iostat=iostat) line
        if (iostat /= 0) exit
        row = row + 1
        if (any(row == skip_rows_)) cycle
        record = record + 1
        to = 0 ! points to the delimiter
        do field = 1, n_fields
            from = to + 1
            to = to + index(line(from:), delimiter)
            if (to < from) to = len_trim(line) + 1 ! the last field
            write (table(record,field), fmt="(a)") adjustl(line(from:to-1))
        end do
    end do

    close (unit)

    call coerce_to_ascii(table)

end subroutine

function b2o_get_free_unit() result(unit)

    integer(b2o_int) :: unit
    logical :: exist, opened

    do unit = 99, 7, -1
        inquire(unit=unit, exist=exist, opened=opened)
        if (exist.and..not.opened) return
    end do

    unit = -1

end function

subroutine b2o_get_executable_path(path)

    ! Returns absolute, real path to the currently running executable.

    use, intrinsic :: iso_c_binding

    character(len=*), intent(out) :: path
    character(c_char) :: c_path(len(path)+1)
    integer(c_size_t) :: c_path_size

    interface
        subroutine c_b2o_get_executable_path(c_path, c_path_size) bind(c, name="b2o_get_executable_path")
            use, intrinsic :: iso_c_binding
            character(kind=c_char), dimension(*) :: c_path
            integer(c_size_t), value :: c_path_size
        end subroutine
    end interface

    c_path_size = size(c_path)
    call c_b2o_get_executable_path(c_path, c_path_size)
    call c_f_string(c_path, path)

end subroutine

subroutine b2o_setenv(name, value)

    use, intrinsic :: iso_c_binding
    use b2o_string, only : foo_car_string

    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: value
    character(kind=c_char) :: c_name(128)
    character(kind=c_char) :: c_value(1024)
    integer(c_int) :: c_overwrite = 1

    interface ! for setenv function from stdlib.h
        subroutine c_setenv(c_name, c_value, c_overwrite) bind(c, name="setenv")
            use, intrinsic :: iso_c_binding
            character(kind=c_char), dimension(*) :: c_name
            character(kind=c_char), dimension(*) :: c_value
            integer(c_int), value :: c_overwrite
        end subroutine
    end interface

    call foo_car_string(name, c_name, size(c_name))
    call foo_car_string(value, c_value, size(c_value))
    call c_setenv(c_name, c_value, c_overwrite)

end subroutine

subroutine c_f_string(c_string, f_string)

    use, intrinsic :: iso_c_binding

    character(kind=c_char), dimension(*), intent(in) :: c_string
    character(len=*), intent(out) :: f_string
    integer :: i

    f_string = ""
    do i = 1, len(f_string)
        if (c_string(i) == c_null_char) exit
        f_string(i:i) = c_string(i)
    end do
    
end subroutine

subroutine f_c_string(f_string, c_string, c_length)

    use, intrinsic :: iso_c_binding

    character(len=*), intent(in) :: f_string
    character(kind=c_char), dimension(*), intent(out) :: c_string
    integer(b2o_int), intent(in) :: c_length
    integer :: i, last

    last = min(len_trim(f_string), c_length-1)
    do i = 1, last
        c_string(i) = f_string(i:i)
    end do
    c_string(last+1) = c_null_char
    
end subroutine

end module b2o_utility
