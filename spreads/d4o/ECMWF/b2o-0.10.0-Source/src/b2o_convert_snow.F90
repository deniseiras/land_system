subroutine b2o_convert_snow(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: conv(:,:)
real(kind=b2o_double), pointer :: conv_body(:,:)

integer(kind=b2o_int) :: istationTypeID, istationID
integer(kind=b2o_int), parameter :: n_variables = 1
integer(kind=b2o_int) :: iobs, jobs
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_snow',0,zhook_handle)

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
conv => b2o_use_table(handle, "conv")
conv_body => b2o_use_table(handle, "conv_body")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  if (b2o_is_defined(handle, "nationalStationNumber")) then
    istationTypeID = b2o_get_int(handle, "nationalStationNumber") / 10**6
    istationID = b2o_get_int(handle, "nationalStationNumber") - istationTypeID * 10**6
    write (statid(1:3),'(i3.3)') b2o_get_int(handle, "stateIdentifier")
    write (statid(4:9),'(i6.6)') istationid ! country and national station id
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStationGroundAboveMeanSeaLevel")

  ! Total snow depth

  jobs = jobs + 1

  body(jobs,body_varno) = g_sdepth
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "heightOfStationGroundAboveMeanSeaLevel")
  body(jobs,body_obsvalue) = b2o_get_real(handle, "totalSnowDepth")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_snow',1,zhook_handle)

end subroutine b2o_convert_snow
