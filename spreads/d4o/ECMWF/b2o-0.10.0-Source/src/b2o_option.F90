module b2o_option

use b2o_common
use b2o_string, only : parse_bool, parse_double, parse_int

implicit none

#include "b2o_config.h"

integer, parameter, private :: MAX_LEN = 256

logical :: B2O_ALL_SKY
logical :: B2O_CAMS_AND_IFS_OZONE
logical :: B2O_CAMS_OZONE
logical :: B2O_EXTRACT_RH2M
logical :: B2O_HELP
logical :: B2O_TEMP_ASCENT_BATCH_AVERAGING
logical :: B2O_TEMP_DESCENT_BATCH_AVERAGING
logical :: B2O_TEMP_DROP_BATCH_AVERAGING
logical :: B2O_UNIQUE_SEQNO
logical :: B2O_VERBOSE

integer(b2o_int) :: B2O_LOG_LEVEL
integer(b2o_int) :: B2O_MODES_THINNING_INTERVAL
integer(b2o_int) :: B2O_TEMP_ASCENT_BATCH_INTERVAL
integer(b2o_int) :: B2O_TEMP_DESCENT_BATCH_INTERVAL
integer(b2o_int) :: B2O_TEMP_DROP_BATCH_INTERVAL
integer(b2o_int) :: B2O_TEMP_MAX_LEVELS
integer(b2o_int) :: B2O_THINNING_INTERVAL

real(b2o_double) :: B2O_DEFAULT_BUOY_HEIGHT
real(b2o_double) :: B2O_STATION_POSITION_TOLERANCE
real(b2o_double) :: B2O_STATION_HEIGHT_TOLERANCE

character(len=MAX_LEN) :: B2O_AEOLUS_MIE_SETTINGS
character(len=MAX_LEN) :: B2O_AEOLUS_RAY_SETTINGS
character(len=MAX_LEN) :: B2O_AIRCRAFT_TYPE_MAPPINGS
character(len=MAX_LEN) :: B2O_AIRCRAFT_TYPES
character(len=MAX_LEN) :: B2O_BUOY_HEIGHTS
character(len=MAX_LEN) :: B2O_CRIS_CHANNELS
character(len=MAX_LEN) :: B2O_HIRAS_CHANNELS
character(len=MAX_LEN) :: B2O_IASI_CHANNELS
character(len=MAX_LEN) :: B2O_IKFS2_CHANNELS
character(len=MAX_LEN) :: ODB_CODE_MAPPINGS
character(len=MAX_LEN) :: ODB_SCHEMA_FILE

contains

subroutine set_options(args)

    use b2o_common, only : B2O_ERROR, B2O_WARNING

    character(len=*), intent(inout) :: args(:)

    interface set
        procedure set_bool
        procedure set_int
        procedure set_double
        procedure set_string
    end interface

    call set(B2O_AEOLUS_MIE_SETTINGS, path_to("aeolus_mie_settings"), env="B2O_AEOLUS_MIE_SETTINGS", flag="--aeolos-mie-settings")
    call set(B2O_AEOLUS_RAY_SETTINGS, path_to("aeolus_ray_settings"), env="B2O_AEOLUS_RAY_SETTINGS", flag="--aeolos-ray-settings")
    call set(B2O_AIRCRAFT_TYPE_MAPPINGS, "", env="B2O_AIRCRAFT_TYPE_MAPPINGS", flag="--aircraft-type-mappings")
    call set(B2O_AIRCRAFT_TYPES, path_to("aircraft_types.csv"), env="B2O_AIRCRAFT_TYPES", flag="--aircraft-types")
    call set(B2O_ALL_SKY, .false., env="B2O_ALL_SKY", flag="--all-sky")
    call set(B2O_BUOY_HEIGHTS, path_to("buoy_heights.csv"), env="B2O_BUOY_HEIGHTS", flag="--buoy-heights")
    call set(B2O_CAMS_AND_IFS_OZONE, .false., flag="--cams-and-ifs-ozone")
    call set(B2O_CAMS_OZONE, .false., flag="--cams-ozone")
    call set(B2O_CRIS_CHANNELS, path_to("crischannels"), env="B2O_CRIS_CHANNELS", flag="--cris-channels")
    call set(B2O_DEFAULT_BUOY_HEIGHT, 0.d0, env="B2O_DEFAULT_BUOY_HEIGHT", flag="--default-buoy-height")
    call set(B2O_EXTRACT_RH2M, .true., env="B2O_EXTRACT_RH2M")
    call set(B2O_HELP, .false., flag="--help")
    call set(B2O_HIRAS_CHANNELS, path_to("hiraschannels"), env="B2O_HIRAS_CHANNELS", flag="--hiras-channels")
    call set(B2O_IASI_CHANNELS, path_to("iasichannels"), env="B2O_IASI_CHANNELS", flag="--iasi-channels")
    call set(B2O_IKFS2_CHANNELS, path_to("ikfs2channels"), env="B2O_IKFS2_CHANNELS", flag="--ikfs2-channels")
    !call set(B2O_LOG_LEVEL, B2O_ERROR, env="B2O_LOG_LEVEL", flag="--log-level")
    call set(B2O_LOG_LEVEL, B2O_WARNING, env="B2O_LOG_LEVEL", flag="--log-level")
    call set(B2O_MODES_THINNING_INTERVAL, 15, env="B2O_MODES_THINNING_INTERVAL")
    call set(B2O_STATION_HEIGHT_TOLERANCE, 5.0d0, env="B2O_STATION_HEIGHT_TOLERANCE")
    call set(B2O_STATION_POSITION_TOLERANCE, 0.1d0, env="B2O_STATION_POSITION_TOLERANCE")
    call set(B2O_TEMP_ASCENT_BATCH_AVERAGING, .false., env="B2O_TEMP_ASCENT_BATCH_AVERAGING")
    call set(B2O_TEMP_ASCENT_BATCH_INTERVAL, 15*60, env="B2O_TEMP_ASCENT_BATCH_INTERVAL")
    call set(B2O_TEMP_DESCENT_BATCH_AVERAGING, .false., env="B2O_TEMP_DESCENT_BATCH_AVERAGING")
    call set(B2O_TEMP_DESCENT_BATCH_INTERVAL, 5*60, env="B2O_TEMP_DESCENT_BATCH_INTERVAL")
    call set(B2O_TEMP_DROP_BATCH_AVERAGING, .false., env="B2O_TEMP_DROP_BATCH_AVERAGING")
    call set(B2O_TEMP_DROP_BATCH_INTERVAL, 1*60, env="B2O_TEMP_DROP_BATCH_INTERVAL")
    call set(B2O_TEMP_MAX_LEVELS, 5000, env="B2O_TEMP_MAX_LEVELS")
    call set(B2O_THINNING_INTERVAL, 1, flag="--thinning-interval")
    call set(B2O_UNIQUE_SEQNO, .false., env="B2O_UNIQUE_SEQNO", flag="--unique-seqno")
    call set(B2O_VERBOSE, .false., env="B2O_VERBOSE", flag="--verbose")
    call set(ODB_CODE_MAPPINGS, path_to("odb_code_mappings.csv"), env="ODB_CODE_MAPPINGS", flag="--code-mappings")
    call set(ODB_SCHEMA_FILE, path_to("cma.ddl"), env="ODB_SCHEMA_FILE", flag="--schema-file")
    
contains

subroutine set_string(option, default, env, flag)

    character(len=*), intent(inout) :: option
    character(len=*), intent(in) :: default
    character(len=*), intent(in), optional :: env, flag
    character(len=len(option)) :: value

    option = default

    if (present(env)) then
        call get_environment_variable(env, value)
        if (len_trim(value) > 0) then
            read (value, fmt="(a)") option
        end if
    end if

    if (present(flag)) then 
        value = parse_flag(args, flag)
        if (len_trim(value) > 0) then
            read(value, fmt="(a)") option
        end if
    end if

end subroutine

subroutine set_double(option, default, env, flag)

    real(b2o_double), intent(inout) :: option
    real(b2o_double), intent(in) :: default
    character(len=*), intent(in), optional :: env, flag
    character(len=16) :: value
    integer :: iostat

    option = default

    if (present(env)) then
        call get_environment_variable(env, value)
        if (len_trim(value) > 0) then
            option = parse_double(value, iostat)
            call check(iostat, env, value, "double")
        end if
    end if

    if (present(flag)) then 
        value = parse_flag(args, flag)
        if (len_trim(value) > 0) then
            option = parse_double(value, iostat)
            call check(iostat, flag, value, "double")
        end if
    end if

end subroutine

subroutine set_int(option, default, env, flag)

    integer(b2o_int), intent(inout) :: option
    integer(b2o_int), intent(in) :: default
    character(len=*), intent(in), optional :: env, flag
    character(len=16) :: value
    integer :: iostat

    option = default

    if (present(env)) then
        call get_environment_variable(env, value)
        if (len_trim(value) > 0) then
            option = parse_int(value, iostat)
            call check(iostat, env, value, "int")
        end if
    end if

    if (present(flag)) then 
        value = parse_flag(args, flag)
        if (len_trim(value) > 0) then
            option = parse_int(value, iostat)
            call check(iostat, env, value, "int")
        end if
    end if

end subroutine

subroutine set_bool(option, default, env, flag)

    logical, intent(inout) :: option
    logical, intent(in) :: default
    character(len=*), intent(in), optional :: env, flag
    character(len=:), allocatable :: value
    integer :: i, n, iostat

    option = default

    if (present(env)) then

        call get_environment_variable(env, length=n)
        allocate(character(len=n+1) :: value)
        call get_environment_variable(env, value)

        if (len_trim(value) == 0) then
            option = default
        else
            option = parse_bool(value, iostat)
            call check(iostat, env, value, "bool")
        end if

    end if

    if (present(flag)) then
        do i = 1, size(args)    
            if (index(args(i), trim(flag)) > 0) then
                option = (.not. default)
                args(i) = ""
                exit
            end if
        end do
    end if

end subroutine

function parse_flag(args, flag) result(value)

    character(*), intent(inout) :: args(:)
    character(*), intent(in) :: flag
    character(len(args(1))) :: value
    integer :: i, j

    do i = 1, size(args)
        if (index(args(i), trim(flag)) > 0) then
            j = index(args(i), "=")
            if (j > 0) then
                value = args(i)(j+1:)
            else
                value = args(i+1)
                args(i+1) = ""
            end if
            args(i) = ""
            return
        end if
    end do

    value = ""

end function

subroutine check(iostat, name, value, type)

    use, intrinsic :: iso_fortran_env, only : error_unit

    integer, intent(in) :: iostat
    character(*), intent(in) :: name, value, type

    if (iostat /= 0) then
        write (error_unit, fmt=*) "Invalid value of " // trim(name) // ": '" &
            // trim(value) // "' (expected " // trim(type) // ")"
        call b2o_exit(1)
    end if

end subroutine

function path_to(filename) result(path)

    use b2o_utility, only : b2o_get_executable_path

    character(len=*), intent(in) :: filename
    character(len=MAX_LEN) :: path

    call get_environment_variable("B2O_HOME", path)

    if (len_trim(path) == 0) then
        call b2o_get_executable_path(path)
        path = path(:index(path, "/", back=.true.)-1)
        path = path(:index(path, "/", back=.true.)-1)
    end if

    !path = trim(path) // "/etc/bufr2odb/" // trim(filename)
    path = trim(path) // "/share/b2o/" // trim(filename)

end function

end subroutine set_options

subroutine b2o_init()

    use eccodes

    character(len=:), allocatable :: args(:)
    integer :: count, i, len, max_len

    count = command_argument_count()

    max_len = 0

    do i = 1, count
        call get_command_argument(i, length=len)
        max_len = max(len, max_len)
    end do

    allocate(character(max_len) :: args(count))

    do i = 1, count
        call get_command_argument(i, args(i))
    end do

    call set_options(args)

    call codes_bufr_multi_element_constant_arrays_on()

end subroutine

subroutine c_b2o_init(c_argc, c_argv) bind(c, name="b2o_init")

    use, intrinsic :: iso_c_binding
    use b2o_string, only : c_f_string
    use eccodes

    integer(c_int), value :: c_argc
    type(c_ptr), intent(in) :: c_argv(*)
    character(kind=c_char), pointer :: c_arg
    character(len=MAX_LEN), allocatable :: f_args(:)
    integer :: i

    allocate(f_args(c_argc-1))

    do i = 1, c_argc-1
        call c_f_pointer(c_argv(i+1), c_arg)
        call c_f_string(c_arg, f_args(i))
    end do

    call set_options(f_args)

    call codes_bufr_multi_element_constant_arrays_on()

end subroutine

end module
