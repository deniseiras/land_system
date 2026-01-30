subroutine b2o_convert_iasi(handle, status)

use b2o_internal
use b2o_option, only : B2O_IASI_CHANNELS

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: rad(:,:)
real(kind=b2o_double), pointer :: rad_body(:,:)
real(kind=b2o_double), pointer :: collocated_imager_info(:,:)

integer(kind=b2o_int), parameter:: Max_size_of_csf = 10
integer(kind=b2o_int) :: size_of_csf 
integer(kind=b2o_int) :: start_channel(Max_size_of_csf)
integer(kind=b2o_int) :: end_channel(Max_size_of_csf)
integer(kind=b2o_int) :: channel_scale_factor(Max_size_of_csf)

integer(kind=b2o_int), parameter :: MaxChans = 8461
real(kind=b2o_double), parameter :: eps = 1.0E-6_B2O_DOUBLE

integer(kind=b2o_int) :: k,m,n,iy
integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: total_channels
real(kind=b2o_double) :: Radiance
real(kind=b2o_double) :: scaled_radiance

integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: channel

integer(kind=b2o_int), allocatable, save :: channels(:)
real(kind=b2o_double), allocatable, save :: planck_coeffs(:,:)

character(len=8) :: s_channel
character(len=16) :: statid

logical :: has_imager

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_iasi',0,zhook_handle)

! Read in namelist of channels to load

if (.not.allocated(channels)) then
  channels = load(B2O_IASI_CHANNELS)
end if

! Calculate constants required for radiance to BT conversion.

if (.not.allocated(planck_coeffs)) then
  planck_coeffs = b2o_planck_coeffs(avhrr_wavenumber(channels))
end if

call b2o_reserve(handle, size(channels))

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
rad => b2o_use_table(handle, "radiance")
rad_body => b2o_use_table(handle, "radiance_body")
collocated_imager_info => b2o_use_table(handle, "collocated_imager_information")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  satid = b2o_get_int(handle, "satelliteIdentifier")
  write (statid,'(i8)') satid

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  hdr(iobs,hdr_numlev) = size(channels)
  hdr(iobs,hdr_sensor) = 16

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")
  sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")

  size_of_csf = 0

  channel_scaling_loop: do iy = 1, Max_size_of_csf
     if (b2o_is_missing(handle, "startChannel")) exit channel_scaling_loop
     start_channel(iy) = b2o_get_int(handle, "startChannel", rank=iy)
     end_channel(iy) = b2o_get_int(handle, "endChannel", rank=iy)
     channel_scale_factor(iy) = b2o_get_int(handle, "channelScaleFactor", rank=iy)
     if (start_channel(iy) > MaxChans) exit channel_scaling_loop
     size_of_csf = size_of_csf + 1
  end do channel_scaling_loop

  total_channels = 0

  n = 0
  channel_loop: do k = 1, MaxChans

    if (.not.b2o_is_defined(handle, "scaledIasiRadiance", rank=k)) exit channel_loop

    total_channels = total_channels + 1

    channel = b2o_get_int(handle, "channelNumber", rank=k)

    ! Check if channel number was requested

    if (search(channel, channels) < 0) then
        write (s_channel, "(i4.4)") channel
        call b2o_log(handle, B2O_DEBUG, "Channel number not requested: " // trim(s_channel))
        cycle channel_loop
    end if

    ! Scaled IASI radiance

    n = n + 1
    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt ! Changed to BT as we are converting
    body(jobs,body_vertco_type) = g_cha_number
    body(jobs,body_vertco_reference_1) = channel

    do iy = 1, size_of_csf
       if (channel /= ODB_MISSING_INT) then
       if (channel >= start_channel(iy) .and. channel <= end_channel(iy)) then
          scaled_radiance = b2o_get_real(handle, "scaledIasiRadiance", rank=k)
          if (scaled_radiance /= ODB_MISSING_REAL .and. scaled_radiance > 0_B2O_DOUBLE) then
             radiance = scaled_radiance / 10_B2O_DOUBLE**(channel_scale_factor(iy))
             body(jobs,body_obsvalue) = b2o_radiance_to_brightnes_temperature(planck_coeffs(:,n), radiance)
          end if
          exit
       end if
       end if
    end do

  end do channel_loop

  has_imager = (b2o_get_int(handle, "satelliteInstruments", rank=2) == 591)

  if (has_imager) then
    call convert_imager(hirs_wavenumbers(satid))
  end if

end do subset_loop

if (lhook) call dr_hook('b2o_convert_iasi',1,zhook_handle)

contains

pure elemental function avhrr_wavenumber(channel)

    integer(b2o_int), intent(in) :: channel
    real(b2o_double) :: avhrr_wavenumber

    avhrr_wavenumber = 645._b2o_double + 0.25_b2o_double * (channel-1)

end function

pure function hirs_wavenumbers(satid) result(ks)

    integer(b2o_int), intent(in) :: satid
    real(b2o_double) :: ks(6)

    ks(:) = 0.0

    select case (satid)
    case (3) ! Metop-B
        ks(4) = 2661.5_b2o_double
        ks(5) =  931.3_b2o_double
        ks(6) =  837.9_b2o_double
    case (4) ! Metop-A
        ks(4) = 2687.0_b2o_double
        ks(5) =  927.2_b2o_double
        ks(6) =  837.7_b2o_double
     case (5) ! Metop-C
        ks(4) = 2661.5_b2o_double
        ks(5) =  931.3_b2o_double
        ks(6) =  837.9_b2o_double
    end select

end function

subroutine convert_imager(wavenumber)

    real(b2o_double), intent(in) :: wavenumber(:)

    integer(b2o_int), parameter :: n_channels = 6, n_clusters = 7

    real(b2o_double) :: cluster_fraction(n_clusters)
    integer(b2o_int) :: cluster_ordinal(n_clusters)
    real(b2o_double) :: R(2,n_channels,n_clusters)
    real(b2o_double) :: BT(2,n_channels,n_clusters)
    real(b2o_double) :: total_R(2,n_channels)
    real(b2o_double) :: total_BT(2,n_channels)
    real(b2o_double) :: scaled_R(2), scale_factor
    real(b2o_double) :: cluster_ir
    integer(b2o_int) :: max_cluster, num_clusters
    integer(b2o_int) :: ichan, k

    do k = 1, n_clusters
        cluster_fraction(k) = b2o_get_real(handle, "fractionOfClearPixelsInHirsFov", rank=k)
    end do

   cluster_loop: do k = 1, n_clusters

      do ichan = 1, n_channels

         m = (k-1) * n_channels + ichan
         
         channel = b2o_get_int(handle, "channelNumber", rank=total_channels+m)
         if (channel /= ichan) then
            write (s_channel, "(i4.4)") channel
            call b2o_log(handle, B2O_WARNING, 'Unexpected imager channel number: ' // trim(s_channel))
            cluster_fraction(:) = 0 ! Causes all R ODB variables to be RMDI
            exit cluster_loop
         end if
         
         ! The value 5 below is a unit conversion:

         scaled_R(1) = b2o_get_real(handle, "scaledMeanAvhrrRadiance", rank=m)
         if (scaled_R(1) == ODB_MISSING_REAL) scaled_R(1) = BUFR_MISSING_REAL
         scale_factor = b2o_get_real(handle, "channelScaleFactor", rank=Max_size_of_csf+2*(m-1)+1)
         R(1,ichan,k) = scaled_R(1) * (10_B2O_DOUBLE ** (5_B2O_DOUBLE - scale_factor))

         scaled_R(2) = b2o_get_real(handle, "scaledStandardDeviationAvhrrRadiance", rank=m)
         scale_factor = b2o_get_real(handle, "channelScaleFactor", rank=Max_size_of_csf+2*m)
         R(2,ichan,k) = scaled_R(2) * (10_B2O_DOUBLE ** (5_B2O_DOUBLE - scale_factor))

      end do

   end do cluster_loop
   
   if (sum(cluster_fraction(:)) > eps) then

      total_R(:,:)  = ODB_MISSING_REAL
      total_BT(:,:) = ODB_MISSING_REAL

      cluster_fraction(:) = cluster_fraction(:) / sum(cluster_fraction(:))

      do k = 1, n_channels
         if (all(abs(R(1,k,:)) <= 1.d10) .and. all(abs(R(2,k,:)) <= 1.d10)) then
            total_R(1,k) = sum(cluster_fraction(:) * R(1,k,:))
            total_R(2,k) = sum(cluster_fraction(:) * (R(2,k,:)**2 + R(1,k,:)**2)) - total_R(1,k)**2
            total_R(2,k) = sqrt(max(total_R(2,k), 0.0))
         end if
      end do

      ! Conversion from radiances to brightness temperatures

      call rad2bt(wavenumber(4:), total_R(1,4:), total_R(2,4:), total_BT(1,4:), total_BT(2,4:))

      do k = 1, n_clusters
        call rad2bt(wavenumber(4:), R(1,4:,k), R(2,4:,k), BT(1,4:,k), BT(2,4:,k))
      end do

      ! Count only non-zero sized clusters. Those with zero size are outside the FOV.
      collocated_imager_info(iobs,collocated_imager_information_avhrr_num_clusters) = count(cluster_fraction(:) > eps)
      collocated_imager_info(iobs,collocated_imager_information_avhrr_max_cluster) = maxval(cluster_fraction(:))
      collocated_imager_info(iobs,collocated_imager_information_avhrr_mean_vis) = total_R(1,1)
      collocated_imager_info(iobs,collocated_imager_information_avhrr_stddev_vis) = total_R(2,1)
      collocated_imager_info(iobs,collocated_imager_information_avhrr_mean_ir) = total_BT(1,5)
      collocated_imager_info(iobs,collocated_imager_information_avhrr_stddev_ir) = total_BT(2,5)
      collocated_imager_info(iobs,collocated_imager_information_avhrr_stddev_ir2) = total_BT(2,6)

      cluster_ir = maxval(BT(1,5,:), mask=(R(1,5,:) < 1.d10))
      if (cluster_ir > -huge(BT)) then
        collocated_imager_info(iobs,collocated_imager_information_avhrr_warmest_cluster_ir) = cluster_ir
      end if

      cluster_ir = minval(BT(1,5,:), mask=((R(1,5,:) < 1.d10) .and. (R(1,5,:) > 0)))
      if (cluster_ir < huge(BT)) then
        collocated_imager_info(iobs,collocated_imager_information_avhrr_coldest_cluster_ir) = cluster_ir
      end if

      max_cluster = maxloc(cluster_fraction(:), dim=1)
      if (R(1,5,max_cluster) <= 1.d10) then
         collocated_imager_info(iobs,collocated_imager_information_avhrr_largest_cluster_ir) = BT(1,5,max_cluster)
      end if

      ! Sort clusters according to descending fractional coverage
      call sort(cluster_fraction(:), cluster_ordinal(:))

      do k = 1, n_clusters
        collocated_imager_info(iobs,collocated_imager_information_avhrr_frac_cl(k))  = cluster_fraction(k)
        collocated_imager_info(iobs,collocated_imager_information_avhrr_m_ir1_cl(k)) = BT(1,5,cluster_ordinal(k))
        collocated_imager_info(iobs,collocated_imager_information_avhrr_m_ir2_cl(k)) = BT(1,6,cluster_ordinal(k))
      end do

      collocated_imager_info(iobs,collocated_imager_information_provider_qc) = b2o_get_int(handle, "gqisFlagQual")

      where (abs(collocated_imager_info(iobs,:) - rvind) / rvind < 1.d-03)
        collocated_imager_info(iobs,:) = ODB_MISSING_REAL
      end where

    end if ! sum(cluster_fraction(:)) > eps

end subroutine

pure elemental subroutine rad2bt(k, R_mean, R_stddev, BT_mean, BT_stddev)

    real(b2o_double), intent(in) :: k, R_mean, R_stddev
    real(b2o_double), intent(out) :: BT_mean, BT_stddev

    real(b2o_double), parameter :: c1 = 1.1910659d-10 ! W/(m^2.ster.m^-2)
    real(b2o_double), parameter :: c2 = 1.438833d0    ! K/cm^-1

    if (R_mean > eps .and. R_mean < 1.0d10) then
        BT_mean = c2 * k / log(1.0d0 + (1.0d5 * c1 * k ** 3 / R_mean))
        BT_stddev = R_stddev * (1.0d5 * c1 * c2 * k ** 4 / &
         & (R_mean * (R_mean + 1.0d5 * c1 * k**3) * (log(1.0d0 + 1.0d5 * c1 * k**3 / R_mean))**2))
    else
        BT_mean = rvind
        BT_stddev = rvind
    end if

end subroutine

subroutine sort(values, ordinals)

    real(b2o_double), intent(inout) :: values(:)
    integer(b2o_int), intent(out) :: ordinals(size(values))
    integer :: i, j, o
    real(b2o_double) :: v

    do i = 1, size(values)
        ordinals(i) = i
    end do

    do i = 1, size(values) - 1
        do j = i + 1, size(values)
            if (values(j) > values(i)) then
                v = values(j)
                values(j) = values(i)
                values(i) = v
                o = ordinals(j)
                ordinals(j) = ordinals(i)
                ordinals(i) = o
            end if
        end do
    end do

end subroutine

pure function search(x, array) result(loc)

    integer(b2o_int), intent(in) :: x, array(:)
    integer(b2o_int) :: loc, k

    loc = -1
    do k = 1, size(array)
       if (array(k) == x) then
          loc = k
          exit
       end if
    end do

end function

function load(file) result(channels)

    character(len=*), intent(in) :: file
    integer(b2o_int), allocatable :: channels(:)

    integer(b2o_int) :: i__number_of_channels
    integer(b2o_int) :: i__channels(MaxChans)
    integer(b2o_int) :: k, iostat

    namelist /channels2load/ i__number_of_channels, i__channels

    ! Default values
    i__number_of_channels = MaxChans
    do k = 1, MaxChans
        i__channels(k) = k
    end do

    open(unit=88, file=file, status='old')
    read(88, nml=channels2load, iostat=iostat)
    if (iostat /= 0) then
        call b2o_log(handle%context, B2O_ERROR, "Cannot read 'iasichannels' namelist file")
        call b2o_exit(2)
    end if
    close(88)

    allocate(channels(i__number_of_channels))
    channels(:) = i__channels(1:size(channels))

end function

end subroutine b2o_convert_iasi
