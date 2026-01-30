module b2o_string

use b2o_common

use, intrinsic :: iso_c_binding, only : c_char, c_null_char
use, intrinsic :: iso_fortran_env, only : error_unit

implicit none

contains

function parse_int(string, iostat) result(value)

    character(*), intent(in) :: string
    integer, intent(out), optional :: iostat
    integer(b2o_int) :: value
    integer :: iostat_

    read (string, fmt=*, iostat=iostat_) value

    if (iostat_ /= 0) then
        if (is_null(string)) then
            value = ODB_MISSING_INT
            iostat_ = 0
        else if (.not.present(iostat)) then
            write (error_unit, fmt=*) "Cannot parse '" // trim(string) // "' as int"
            call b2o_exit(1)
        end if
    end if

    if (present(iostat)) iostat = iostat_

end function

function parse_double(string, iostat) result(value)

    character(*), intent(in) :: string
    integer, intent(out), optional :: iostat
    real(b2o_double) :: value
    integer :: iostat_

    read (string, fmt=*, iostat=iostat_) value

    if (iostat_ /= 0) then
        if (is_null(string)) then
            value = ODB_MISSING_REAL
            iostat_ = 0
        else if (.not.present(iostat)) then
            write (error_unit, fmt=*) "Cannot parse '" // trim(string) // "' as double"
            call b2o_exit(1)
        end if
    end if

    if (present(iostat)) iostat = iostat_

end function

function parse_bool(string, iostat) result(value)

    character(*), intent(in) :: string
    integer, intent(out), optional :: iostat
    logical :: value
    integer :: iostat_

    read (string, fmt=*, iostat=iostat_) value

    if (iostat_ /= 0) then
        select case (lower_case(trim(adjustl(string))))
        case ("true" ,"1","on" ,"yes")
           value = .true.
           iostat_ = 0
        case ("false","0","off","no" )
           value = .false.
           iostat_ = 0
        case default
            if (.not.present(iostat)) then
                write (error_unit, fmt=*) "Cannot parse '" // trim(string) // "' as bool"
                call b2o_exit(1)
            end if
        end select
    end if

    if (present(iostat)) iostat = iostat_

end function

elemental subroutine asciify(string)

    ! Coerces characters in a string to printable (7-bit) ASCII symbols by
    ! replacing non-printable characters with spaces.

    character(*), intent(inout) :: string
    integer :: i, code

    do i = 1, len(string)
        code = iachar(string(i:i))
        if (code < 32 .or. code >= 127) string(i:i) = ' '
    end do

end subroutine

logical pure function is_null(string)

    character(*), intent(in) :: string ; is_null = (lower_case(trim(adjustl(string))) == "null")

end function

pure function lower_case(string)

    character(*), intent(in) :: string
    character(len(string)) :: lower_case
    integer, parameter :: offset = (ichar("a") - ichar("A"))
    character(1) :: c
    integer :: i

    do i = 1, len_trim(string)
        c = string(i:i)
        lower_case(i:i) = merge(achar(ichar(c)+offset), c, (c >= "A").and.(c <= "Z"))
    end do

end function

subroutine c_f_string(c_string, f_string)

    character(kind=c_char), dimension(*), intent(in) :: c_string
    character(*), intent(out) :: f_string
    integer :: i

    f_string = ""

    do i = 1, len(f_string)
        if (c_string(i) == c_null_char) exit
        f_string(i:i) = c_string(i)
    end do

end subroutine

subroutine f_c_string(f_string, c_string, c_length)

    character(*), intent(in) :: f_string
    character(kind=c_char), dimension(*), intent(out) :: c_string
    integer(b2o_int), intent(in) :: c_length
    integer :: i, n

    n = min(len_trim(f_string), c_length-1)

    forall (i = 1:n) c_string(i) = f_string(i:i)

    c_string(n+1) = c_null_char

end subroutine

subroutine foo_car_string(f_string, c_string, c_length)

    character(*), intent(in) :: f_string
    character(kind=c_char), dimension(*), intent(out) :: c_string
    integer(b2o_int), intent(in) :: c_length
    integer :: i, n

    n = min(len_trim(f_string), c_length-1)

    forall (i = 1:n) c_string(i) = f_string(i:i)

    c_string(n+1) = c_null_char

end subroutine

end module
