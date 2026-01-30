#include "b2o_debug.h"

subroutine b2o_convert_windprofiler(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)
real(kind=b2o_double), pointer :: body(:,:)


integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_levels
character(len=64) :: k_levels
real(kind=b2o_double) :: height

real(kind=b2o_double) :: zhook_handle

#if defined(__PGI)
character(len=8) :: hdr_statid_temp ! local for PGI workaround
#endif

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_windprofiler',0,zhook_handle)

select case (handle%subtype)
case (95)
    n_variables = 2
    n_levels = 43
case (96)
    n_variables = 4
    if (.not.b2o_which_defined(handle, (/"delayedDescriptorReplicationFactor        ", &
          & "extendedDelayedDescriptorReplicationFactor"/), k_levels)) then
        call b2o_log(handle, B2O_WARNING, "Number of n_levels descriptor not found")
        status = B2O_SKIP_MESSAGE
        if (lhook) call dr_hook('b2o_convert_windprofiler',1,zhook_handle)
        return
    end if
    n_levels = b2o_get_int(handle, k_levels)
end select

if (n_levels <= 0 .or. n_levels == ODB_MISSING_INT) then
    call b2o_log(handle, B2O_WARNING, "Invalid number of levels")
    status = B2O_SKIP_MESSAGE
    if (lhook) call dr_hook('b2o_convert_windprofiler',1,zhook_handle)
    return
end if

call b2o_reserve(handle, n_variables * n_levels)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
#if defined(__PGI)
  hdr_statid_temp=b2o_get_station_id(handle, status)
  hdr(iobs,hdr_statid) = transfer( hdr_statid_temp, to_double)
#else
  hdr(iobs,hdr_statid) = transfer(b2o_get_station_id(handle, status), to_double)
#endif
  if (status /= B2O_SUCCESS) exit subset_loop
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = n_levels

  select case (handle%subtype)
  case (95)

  level_loop1: do k = 1, n_levels

    height = b2o_get_real(handle, "heightAboveStation", rank=k)

    call append("u", g_u)
    call append("v", g_v)

  end do level_loop1

  case (96)

  level_loop2: do k = 1, n_levels

    if (b2o_is_defined(handle, "height")) then
      height = b2o_get_real(handle, "height", rank=k)
    else if (b2o_is_defined(handle, "nonCoordinateHeight")) then
      height = b2o_get_real(handle, "nonCoordinateHeight", rank=k)
    else if (b2o_is_defined(handle, "heightAboveStation")) then
      height = b2o_get_real(handle, "heightAboveStation", rank=k)
    else
      call b2o_log(handle, B2O_WARNING, "Could not find the expected height key/descriptor")
      status = B2O_SKIP_MESSAGE
      exit subset_loop
    end if

    call append("windDirection", g_dd)
    call append("windSpeed", g_ff)

    call reserve(g_u)
    call reserve(g_v)

  end do level_loop2

  case default
    call b2o_assert(.false.)
  end select

end do subset_loop

if (lhook) call dr_hook('b2o_convert_windprofiler',1,zhook_handle)

contains

subroutine append(key, varno)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = height
    body(jobs,body_obsvalue) = b2o_get_real(handle, key, rank=k)
    conv_body(jobs,conv_body_datum_qcflag) = b2o_get_int_if_defined(handle, "windDirection->associatedField", rank=k, default=0)

end subroutine

subroutine reserve(varno)

    integer(b2o_int), intent(in) :: varno

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_gpheight
    body(jobs,body_vertco_reference_1) = height
    conv_body(jobs,conv_body_datum_qcflag) = 0

end subroutine

end subroutine b2o_convert_windprofiler
