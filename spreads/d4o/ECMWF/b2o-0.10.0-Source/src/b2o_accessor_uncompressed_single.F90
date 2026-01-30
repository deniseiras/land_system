module b2o_accessor_uncompressed_single

use b2o_accessor_abstract
use b2o_common
use eccodes

implicit none

type, extends(b2o_accessor_t) :: b2o_accessor_uncompressed_single_t
    contains
    procedure :: get_int
    procedure :: get_real
    procedure :: get_string
    procedure :: is_defined
end type

contains

function get_int(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_uncompressed_single_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    integer(b2o_int) :: value

    call codes_get_int(message, path(rank, key), value, status)

    if (status /= CODES_SUCCESS .and. rank == 1) then
        call codes_get_int(message, key, value, status)
    end if

end function

function get_real(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_uncompressed_single_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    real(b2o_double) :: value

    call codes_get_real8(message, path(rank, key), value, status)

    if (status /= CODES_SUCCESS .and. rank == 1) then
        call codes_get_real8(message, key, value, status)
    end if

end function

subroutine get_string(this, message, subset, key, value, status)

    class(b2o_accessor_uncompressed_single_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value
    integer(b2o_int), intent(out) :: status
    character(len=len(value)+1) :: value1 ! reserving space for '\0' character

    call codes_get_string(message, key, value1, status)
    value = value1(1:len(value))

end subroutine

function is_defined(this, message, subset, key, rank)

    class(b2o_accessor_uncompressed_single_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    logical :: is_defined
    integer(b2o_int) :: value

    call codes_is_defined(message, path(rank, key), value)
    is_defined = value .eq. 1

end function

pure character(len=B2O_MAX_KEY_LEN) function path(rank, key)

    integer(b2o_int), intent(in) :: rank
    character(len=*), intent(in) :: key

    write (path, "('#',i0,'#',a)") rank, trim(key)

end function

end module
