#include "b2o_config.h"

#ifndef B2O_HAVE_IFSAUX

module parkind1

implicit none
integer, parameter :: JPIM = selected_int_kind(9)
integer, parameter :: JPRD = selected_real_kind(13, 300)

end module parkind1

module yomhook

implicit none

logical :: lhook = .false.

interface dr_hook
    module procedure dr_hook_default8
end interface

contains

subroutine dr_hook_default8(name, switch, key)
    use parkind1, only : jpim, jprd
    character(len=*), intent(in) :: name
    integer(kind=jpim), intent(in) :: switch
    real(kind=jprd), intent(inout) :: key
end subroutine

end module yomhook

subroutine abor1(message)
    use, intrinsic :: iso_fortran_env, only : output_unit, error_unit
    implicit none
    character(len=*), intent(in) :: message
    write (error_unit, "(1x,a,1x,a)") "ABORT!", trim(message)
    call flush(output_unit)
    call flush(error_unit)
    call abort()
    stop 1
end subroutine

function get_max_threads()
    use parkind1, only : JPIM
    implicit none
    integer(kind=JPIM) :: get_max_threads
    get_max_threads = 1
    ! TODO: call b2o_exit(B2O_NOT_IMPLEMENTED)
end function


function get_thread_id()
    use parkind1, only : JPIM
    implicit none
    integer(kind=JPIM) :: get_thread_id
    get_thread_id = 1
    ! TODO: call b2o_exit(B2O_NOT_IMPLEMENTED)
end function

#endif
