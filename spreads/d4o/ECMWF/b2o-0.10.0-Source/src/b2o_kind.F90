module b2o_kind

#include "b2o_config.h"

#ifdef B2O_HAVE_IFSAUX

use parkind1, only : JPIM, JPRD

private :: JPIM, JPRD
integer, parameter :: B2O_INT = JPIM
integer, parameter :: B2O_DOUBLE = JPRD

#else

integer, parameter :: B2O_INT = selected_int_kind(9)
integer, parameter :: B2O_DOUBLE = selected_real_kind(13, 300)

#endif

end module
