module b2o_common

#include "b2o_config.h"

use b2o_kind, only : b2o_int, b2o_double
use yomhook, only : lhook, dr_hook

implicit none

integer(b2o_int), parameter :: ODB_IGNORE = 0
integer(b2o_int), parameter :: ODB_INTEGER = 1
integer(b2o_int), parameter :: ODB_REAL = 2
integer(b2o_int), parameter :: ODB_STRING = 3
integer(b2o_int), parameter :: ODB_BITFIELD = 4
integer(b2o_int), parameter :: ODB_DOUBLE = 5

real(b2o_double), parameter :: BUFR_MISSING_REAL = 1.7e38_B2O_DOUBLE
real(b2o_double), parameter :: B2O_GRAVITY = 9.80665_B2O_DOUBLE
real(b2o_double), parameter :: ODB_MISSING_REAL = -2147483647
integer(b2o_int), parameter :: ODB_MISSING_INT = 2147483647

real(b2o_double), parameter :: RVIND = BUFR_MISSING_REAL

integer(b2o_int), parameter :: B2O_DEBUG = 0
integer(b2o_int), parameter :: B2O_INFO = 1
integer(b2o_int), parameter :: B2O_WARNING = 2
integer(b2o_int), parameter :: B2O_ERROR = 3

integer(b2o_int), parameter :: B2O_SUCCESS = 0
integer(b2o_int), parameter :: B2O_END_OF_FILE = -1
integer(b2o_int), parameter :: B2O_IO_ERROR = -2
integer(b2o_int), parameter :: B2O_SKIP_MESSAGE = -3
integer(b2o_int), parameter :: B2O_UNSUPPORTED_SUBTYPE = -4
integer(b2o_int), parameter :: B2O_ASSERTION_ERROR = -5
integer(b2o_int), parameter :: B2O_DECODING_ERROR = -6
integer(b2o_int), parameter :: B2O_UNRECOGNIZED_TABLE = -7
integer(b2o_int), parameter :: B2O_INTERNAL_ERROR = -8
integer(b2o_int), parameter :: B2O_VALUE_ERROR = -9

integer(b2o_int), parameter :: B2O_KIND_UNKNOWN = 0
integer(b2o_int), parameter :: B2O_KIND_HEADER = 1
integer(b2o_int), parameter :: B2O_KIND_BODY = 2

integer(b2o_int), parameter :: B2O_NO_SKIP_EXTRA_KEY_ATTRIBUTES(8) = [0, 1, 2, 3, 170, 172, 176, 178]

integer(b2o_int), parameter :: B2O_MAX_KEY_LEN = 256

interface b2o_optional
    module procedure b2o_optional_int
    module procedure b2o_optional_real
end interface

character(len=32), dimension(12), parameter :: ODB_HEADER_TABLES = (/ &
    "collocated_imager_information", &
    "conv                         ", &
    "gnssro                       ", &
    "hdr                          ", &
    "radiance                     ", &
    "resat                        ", &
    "sat                          ", &
    "satob                        ", &
    "scatt                        ", &
    "smos                         ", &
    "aeolus_hdr                   ", &
    "aeolus_l2b                   "  &
/)

character(len=32), dimension(6), parameter :: ODB_BODY_TABLES = (/ &
    "body                  ", &
    "conv_body             ", &
    "errstat               ", &
    "radiance_body         ", &
    "resat_averaging_kernel", &
    "scatt_body            "  &
/)

contains

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
        write(error_unit, "(i3.3,': b2o ',a,' ',a)") mpi_rank, trim(s_level), trim(message)
    else
        write(error_unit, "('b2o ',a,' ',a)") trim(s_level), trim(message)
    end if

end subroutine

pure function b2o_optional_int(default, optional) result(value)

    integer(b2o_int), intent(in) :: default
    integer(b2o_int), intent(in), optional :: optional
    integer(b2o_int) :: value

    if (present(optional)) then
        value = optional
    else
        value = default
    end if

end function

pure function b2o_optional_real(default, optional) result(value)

    real(b2o_double), intent(in) :: default
    real(b2o_double), intent(in), optional :: optional
    real(b2o_double) :: value

    if (present(optional)) then
        value = optional
    else
        value = default
    end if

end function

subroutine b2o_do_nothing
end subroutine b2o_do_nothing

subroutine b2o_exit(code)
#if defined(__INTEL_COMPILER)
  use ifcore
#endif
  integer, intent(in) :: code
    
  interface ! stdlib.h
     subroutine c_exit(code) bind (c, name="exit")
       use, intrinsic :: iso_c_binding
       integer(c_int), value :: code
     end subroutine c_exit
     subroutine c_putenv(s) bind (c, name="putenv")
       use, intrinsic :: iso_c_binding
       character(kind=c_char), dimension(*) :: s
     end subroutine c_putenv
  end interface

#if defined(__INTEL_COMPILER)
  call tracebackqq("b2o_exit",-1)
#endif
#if defined(__GFORTRAN__)
  call backtrace
#endif 
#if defined(__PGI)
  call c_putenv('PGI_TERM=trace'//char(0))
#endif
#ifdef B2O_STANDALONE
  call c_exit(code)
#else
  call abor1("b2o_exit")
#endif

end subroutine b2o_exit

end module b2o_common
