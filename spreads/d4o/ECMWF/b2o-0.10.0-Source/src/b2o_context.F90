module b2o_context

use b2o_common

implicit none

#include "b2o_debug.h"

type b2o_context_t
    character(256) :: message_source = ""
    integer(b2o_int) :: message_number = 0
    integer(b2o_int) :: message_subtype = 0
    integer(b2o_int) :: seqno = 1
    integer(b2o_int) :: log_level
    integer(b2o_int) :: mpi_rank = 0
    logical :: is_inited = .false.
    type(b2o_context_t), pointer :: self => null()
end type

type(b2o_context_t), target, save, private :: the_default_context

interface b2o_log
    module procedure b2o_log_via_context
end interface

contains

subroutine b2o_new_context(c_new, c_parent) bind(c)

    use, intrinsic :: iso_c_binding

    type(c_ptr) :: c_new
    type(c_ptr), value :: c_parent
    type(b2o_context_t), pointer :: new, parent

    parent => b2o_get_default_context()
    if (c_associated(c_parent)) then
        call c_f_pointer(c_parent, parent)
    end if

    allocate(new)
    new = parent
    new%self => new

    c_new = c_loc(new)

end subroutine

subroutine b2o_delete_context(c_context) bind(c)

    use, intrinsic :: iso_c_binding

    type(c_ptr), value :: c_context
    type(b2o_context_t), pointer :: context, self

    call b2o_assert(c_associated(c_context))
    call c_f_pointer(c_context, context)

    call b2o_assert(associated(context%self))
    self => context%self
    deallocate(self)

end subroutine

subroutine b2o_context_set_message_source(c_context, c_source) bind(c)

    use, intrinsic :: iso_c_binding
    use b2o_string, only : c_f_string

    type(c_ptr), value :: c_context
    character(kind=c_char), dimension(*), intent(in) :: c_source
    type(b2o_context_t), pointer :: context

    call c_f_pointer(c_context, context)
    call c_f_string(c_source, context%message_source)

end subroutine

function b2o_get_default_context() result(context)

    type(b2o_context_t), pointer :: context

    context => the_default_context

    if (.not.context%is_inited) then
        context%is_inited = .true.
    end if

end function

subroutine b2o_log_via_context(context, level, message)

    use b2o_option, only : B2O_LOG_LEVEL

    type(b2o_context_t), intent(in) :: context
    integer(b2o_int), intent(in) :: level
    character(*), intent(in) :: message

    if (level >= B2O_LOG_LEVEL) then
        call b2o_default_log_proc(level, message, context%mpi_rank)
    end if

end subroutine

end module
