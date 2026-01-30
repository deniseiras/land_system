subroutine b2o_convert_radio(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double
real(kind=b2o_double) :: zprofile_confidence  ! used in HARMONIE

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: gnssro(:,:)

integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: report_event1
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_radio',0,zhook_handle)

n_levels = b2o_get_int(handle, "extendedDelayedDescriptorReplicationFactor")

call b2o_reserve(handle, n_levels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
gnssro => b2o_use_table(handle, "gnssro")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  if (b2o_is_defined(handle, "FIXME(Bjarne): 033007")) then
    zprofile_confidence = b2o_get_real(handle, "FIXME(Bjarne): 033007")
    if (zprofile_confidence <= 99.9) then
!      status = B2O_SKIP_MESSAGE
!      exit subset_loop
      hdr(iobs,hdr_report_event1) = b2o_set_bits(1, 7, 1)
    endif
  end if

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_levels
  hdr(iobs,hdr_retrtype) = b2o_get_int(handle, "radioOccultationDataQualityFlags")

  level_loop: do k = 1, n_levels

    ! Use only bending angles which mean frequency is == 0

    if (b2o_get_int(handle, "meanFrequency", rank=k) /= 0) cycle level_loop

    ! Bending angle

    jobs = jobs + 1
    
    body(jobs,body_varno) = g_bend_angle
    body(jobs,body_vertco_type) = g_imp_param
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "impactParameter", rank=k)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "bendingAngle", rank=k)

  end do level_loop

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_azimuth) = b2o_get_int(handle, "bearingOrAzimuth")
  gnssro(iobs,gnssro_radcurv) = b2o_get_int(handle, "earthLocalRadiusOfCurvature")
  gnssro(iobs,gnssro_undulation) = b2o_get_int(handle, "geoidUndulation")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_radio',1,zhook_handle)

end subroutine b2o_convert_radio
