subroutine b2o_convert_radio_lat_long(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: gnssro(:,:)

integer(kind=b2o_int) :: i, k
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: n_batches, n_in_batch
integer(kind=b2o_int) :: next_batch_mid_point
integer(kind=b2o_int) :: entry_number
character(len=16) :: statid
integer(kind=b2o_int), allocatable :: entries(:)

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_radio_lat_long',0,zhook_handle)

n_in_batch = 11
n_levels = b2o_get_int(handle, "extendedDelayedDescriptorReplicationFactor")

n_batches = (n_levels + n_in_batch - 1) / n_in_batch
allocate(entries(n_batches))
entries(1:n_batches-1) = n_in_batch
entries(n_batches) = n_levels - ((n_batches - 1) * n_in_batch)

call b2o_reserve(handle, entries)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
gnssro => b2o_use_table(handle, "gnssro")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

i = 0
iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  i = i + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  entry_number = 0

  ! Calculate first batch mid-point
  next_batch_mid_point = (1 + n_in_batch) / 2

  level_loop: do k = 1, n_levels

    if (k == next_batch_mid_point) then

      iobs = iobs + 1
      
      hdr(iobs,hdr_bufrtype) = b2o_get_int(handle, "dataCategory")
      hdr(iobs,hdr_subtype) = b2o_get_int(handle, "dataSubCategory")
      hdr(iobs,hdr_date) = b2o_get_date(handle)
      hdr(iobs,hdr_time) = b2o_get_time(handle)
      hdr(iobs,hdr_lat) = b2o_get_lat(handle)
      hdr(iobs,hdr_lon) = b2o_get_lon(handle)
      hdr(iobs,hdr_statid) = transfer(statid,to_double)
      hdr(iobs,hdr_numlev) = n_in_batch
      hdr(iobs,hdr_seqno) = i
      hdr(iobs,hdr_reportno) = handle%context%message_number
      hdr(iobs,hdr_retrtype) = b2o_get_int(handle, "radioOccultationDataQualityFlags")
      hdr(iobs,hdr_subsetno) = 0

    end if 

    ! Use only bending angles which mean frequency is == 0

! caused operational failure because varno not set
!!!    if (b2o_get_int(handle, "meanFrequency", rank=k) /= 0) cycle level_loop

    if (k == next_batch_mid_point) then
      hdr(iobs,hdr_lat) = b2o_get_real(handle, "latitude",  rank=k+1, default=hdr(iobs,hdr_lat))
      hdr(iobs,hdr_lon) = b2o_get_real(handle, "longitude", rank=k+1, default=hdr(iobs,hdr_lon))
    end if  

    ! Bending angle

    jobs = jobs + 1
    entry_number = entry_number + 1

    body(jobs,body_varno) = g_bend_angle
    body(jobs,body_vertco_type) = g_imp_param
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "impactParameter", rank=k)
    
    if (b2o_get_int(handle, "meanFrequency", rank=k) == 0)&
   &body(jobs,body_obsvalue) = b2o_get_real(handle, "bendingAngle", rank=k)
    
    body(jobs,body_entryno) = entry_number

    if (k == next_batch_mid_point) then

      sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
      sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
      sat(iobs,sat_azimuth) = nint(b2o_get_real(handle, "bearingOrAzimuth", rank=1))
      gnssro(iobs,gnssro_radcurv) = nint(b2o_get_real(handle, "earthLocalRadiusOfCurvature", rank=1))
      gnssro(iobs,gnssro_undulation) = nint(b2o_get_real(handle, "geoidUndulation", rank=1))

    endif

    ! Calculate next batch mid-point (MIN required for final batch in cases where final batch is smaller than half batch size)
    if (mod(k,n_in_batch) == 0) then
      next_batch_mid_point = min(next_batch_mid_point + n_in_batch, n_levels)
    end if

  end do level_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_radio_lat_long',1,zhook_handle)

end subroutine b2o_convert_radio_lat_long
