subroutine b2o_convert_ims(handle, status)

use b2o_internal
use b2o_option, only : B2O_THINNING_INTERVAL

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)

integer(kind=b2o_int) :: i
integer(kind=b2o_int), save :: j_total_nesdis = 0
integer(kind=b2o_int), save :: j_remaining_subset = 0
integer(kind=b2o_int) :: i_subset

integer(kind=b2o_int), parameter :: n_variables = 2 ! snow_depth + binary snow cover
integer(kind=b2o_int) :: rdbflag
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: n_input_subsets, n_output_subsets
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_ims',0,zhook_handle)

n_input_subsets = b2o_get_int(handle, "numberOfSubsets")
n_output_subsets = 0

do i = 1, n_input_subsets
  if (mod(j_total_nesdis+i-1,B2O_THINNING_INTERVAL) /= 0) cycle
  n_output_subsets = n_output_subsets + 1
enddo

if (n_output_subsets == 0) then
  j_total_nesdis = j_total_nesdis + n_input_subsets
  j_remaining_subset = j_remaining_subset + n_input_subsets
  status = B2O_SKIP_MESSAGE
  if (lhook) call dr_hook('b2o_convert_ims',1,zhook_handle)
  return
end if

call b2o_reserve(handle, n_variables, n_output_subsets)

hdr     => b2o_use_table(handle, "hdr")
body    => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0
i_subset=0

subset_loop: do while (b2o_next_subset(handle))

  i_subset = i_subset + 1

  if (mod(j_total_nesdis+i_subset-1,B2O_THINNING_INTERVAL) /= 0) cycle

  iobs = iobs + 1

  statid='IMS'

  rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, rdbflag)
  hdr(iobs,hdr_report_rdbflag) = rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "height")
  hdr(iobs,hdr_numlev) = 1

  if (n_input_subsets > 1) then
    hdr(iobs,hdr_subsetno) = i_subset
  else
    hdr(iobs,hdr_subsetno) = 0
  end if

  hdr(iobs,hdr_obstype) = 18
  hdr(iobs,hdr_codetype) = 18
  hdr(iobs,hdr_reportype) = 40001
  hdr(iobs,hdr_groupid) = 41

  ! Binary snow cover

  jobs = jobs + 1

  body(jobs,body_varno) = g_binary_snow_cover
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_vertco_reference_1) = 0.0_b2o_double ! sea surface
  body(jobs,body_obsvalue) = b2o_get_real(handle, "snowCover") / 100.0_b2o_double

  ! Snow depth (to be used in the surface analysis when binary snow cover is 0)

  jobs = jobs + 1

  body(jobs,body_varno) = g_sdepth 
  body(jobs,body_vertco_type) = g_gpheight
  body(jobs,body_datum_rdbflag) = 0
  body(jobs,body_vertco_reference_1) = 0.0_b2o_double ! sea surface

  ! If no snow cover then snow depth is 0.0, else we do not know (set to missing)
  if (b2o_get_real(handle, "snowCover") == 0.0_b2o_double) then
    body(jobs,body_obsvalue) = 0.0_b2o_double
  else
    body(jobs,body_obsvalue) = 0.05_b2o_double ! 100 % binary snow cover corresponds to a minimum of 0.05m of snow depth 
  end if

end do subset_loop

j_remaining_subset = n_input_subsets - i_subset
j_total_nesdis = j_total_nesdis + n_input_subsets

if (lhook) call dr_hook('b2o_convert_ims',1,zhook_handle)

end subroutine b2o_convert_ims
