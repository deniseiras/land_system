module b2o_log_mod

    use b2o_common
    implicit none

interface b2o_log
    module procedure b2o_log_via_context
end interface

contains

subroutine b2o_log_via_context(context, level, message)

    use, intrinsic :: iso_c_binding
    use b2o_utility, only : f_c_string

    type(b2o_context_t), intent(in) :: context
    integer(b2o_int), intent(in) :: level
    character(len=*), intent(in) :: message
    character(kind=c_char), dimension(256) :: c_message

    if (level < context%log_level) return

    if (associated(context%log_proc)) then
        call context%log_proc(level, message, context%mpi_rank)
    else if (associated(context%c_log_proc)) then
        call f_c_string(message, c_message, size(c_message))
        call context%c_log_proc(level, c_message)
    end if

end subroutine

subroutine b2o_default_log_proc(level, message, mpi_rank)

    use, intrinsic :: iso_fortran_env, only : error_unit

    integer(b2o_int), intent(in) :: level
    character(len=*), intent(in) :: message
    integer(b2o_int), intent(in) :: mpi_rank
    character(len=4) :: s_level

    select case (level)
    case (B2O_DEBUG)   ; s_level = "(D)"
    case (B2O_INFO)    ; s_level = "(I)"
    case (B2O_WARNING) ; s_level = "(W)"
    case (B2O_ERROR)   ; s_level = "(E)"
    end select

    if (mpi_rank > 0) then
        write(error_unit, "(i0,': b2o ',a,' ',a)") mpi_rank, trim(s_level), trim(message)
    else
        write(error_unit, "('b2o ',a,' ',a)") trim(s_level), trim(message)
    end if
    
end subroutine

subroutine b2o_check(status)

    use yomhook

    integer(b2o_int), intent(in) :: status
    character(len=124) :: handle
    real(b2o_double) :: hook_handle
    character(len=128), parameter :: hook_label = &
        & "b2o_internal:b2o_check"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    select case (status)
    case (B2O_SUCCESS)
        if (lhook) then
            call dr_hook(hook_label, 1, hook_handle)
        end if
        return
    case (B2O_END_OF_FILE)
        handle = "Reached end of BUFR file"
    case default
        handle = "Unknown error"
    end select

    write (*,*) "b2o: error: ", handle
    call b2o_exit(status)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

end module b2o_log_mod
