module b2o_accessor_compressed

use b2o_accessor_abstract
use b2o_common
use eccodes

implicit none

#include "b2o_config.h"

type, extends(b2o_accessor_t) :: b2o_accessor_compressed_t
    contains
    procedure :: get_int
    procedure :: get_real
    procedure :: get_string
    procedure :: is_defined
end type

contains

function get_int(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_compressed_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    integer(b2o_int) :: value

    real(b2o_double) :: d_value

    d_value = this%get_real(message, subset, key, rank, status)

    if (d_value == CODES_MISSING_DOUBLE .or. status /= CODES_SUCCESS) then
        value = CODES_MISSING_LONG
    else
        ! This test is just to work around a Cray Fortran 8.6.2 bug
        if (abs(d_value) > huge(value)) then
          call b2o_exit(B2O_VALUE_ERROR)
        end if
        value = int(d_value)
    end if

end function

function get_real(this, message, subset, key, rank, status) result(value)

    class(b2o_accessor_compressed_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset, rank
    character(len=*), intent(in) :: key
    integer(b2o_int), intent(out) :: status
    real(b2o_double) :: value
    integer(b2o_int) :: index, size

    index = max(1, subset) ! invoked before subset-loop (i.e. subset == 0)
    index = index - 1      ! zero-based indexing

    call codes_get_element(message, path(rank, key), index, value, status)

    if (status /= CODES_SUCCESS .and. rank == 1) then
        call codes_get_size(message, key, size, status)
        if (status == CODES_SUCCESS) then
            if (size == 1) then
                call codes_get_real8(message, key, value, status)
            else
                call codes_get_element(message, key, index, value, status)
            end if
        end if
    end if

end function

subroutine get_string(this, message, subset, key, value, status)

    class(b2o_accessor_compressed_t), intent(in) :: this
    integer(b2o_int), intent(in) :: message, subset
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value
    integer(b2o_int), intent(out) :: status
    integer(b2o_int) :: size, index
    character(len(value)+1), allocatable :: array(:) ! reserving space for '\0' character

    call codes_get_size(message, key, size, status)

    if (status == CODES_SUCCESS) then
        allocate(array(size))
        call codes_get_string_array(message, key, array, status)
        value = array(subset)(1:len(value))
        deallocate(array)
    end if

end subroutine

function is_defined(this, message, subset, key, rank)

    class(b2o_accessor_compressed_t), intent(in) :: this
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
