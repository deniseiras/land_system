module b2o_accessor_uncompressed_multi

use b2o_accessor_abstract
use b2o_common
use eccodes

implicit none

type, extends(b2o_accessor_t) :: b2o_accessor_uncompressed_multi_t
    contains
    procedure :: get_int
    procedure :: get_real
    procedure :: get_string
    procedure :: is_defined
end type

contains

function get_int(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_uncompressed_multi_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    integer(b2o_int) :: value
    integer(b2o_int), allocatable :: array(:)

    call codes_get_int_array(message, path(subset, key), array, status)

    if (status /= CODES_SUCCESS .and. rank == 1) then
        call codes_get_int_array(message, key, array, status)
    end if

    if (status == CODES_SUCCESS) then
        value = array(rank)
    else
        value = CODES_MISSING_LONG
    end if

end function

function get_real(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_uncompressed_multi_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    real(b2o_double) :: value
    real(b2o_double), allocatable :: array(:)

    call codes_get_real8_array(message, path(subset, key), array, status)

    if (status /= CODES_SUCCESS .and. rank == 1) then
        call codes_get_real8_array(message, key, array, status)
    end if

    if (status == CODES_SUCCESS) then
        value = array(rank)
    else
        value = CODES_MISSING_DOUBLE
    end if

end function

subroutine get_string(this, message, subset, key, value, status)

    class(b2o_accessor_uncompressed_multi_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value
    integer(b2o_int), intent(out) :: status
    character(len=len(value)+1) :: value1 ! +1 to reserve space for '\0' character

    call codes_get_string(message, path(subset, key), value1, status)
    value = value1(1:len(value))

end subroutine

function is_defined(this, message, subset, key, rank)

    class(b2o_accessor_uncompressed_multi_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    logical :: is_defined
    integer(b2o_int) :: size, status

    call codes_get_size(message, path(subset, key), size, status)
    is_defined = (status .eq. CODES_SUCCESS) .and. (rank .le. size)

end function

pure character(len=B2O_MAX_KEY_LEN) function path(subset, key)

    integer(b2o_int), intent(in) :: subset
    character(len=*), intent(in) :: key

    write (path, "('/subsetNumber=',i0,'/',a)") max(1, subset), trim(key)

end function

end module
