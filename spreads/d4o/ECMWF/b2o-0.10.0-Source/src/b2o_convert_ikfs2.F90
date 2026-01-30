subroutine b2o_convert_ikfs2(handle, status)

use b2o_internal
use b2o_option, only : B2O_IKFS2_CHANNELS

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

integer(kind=b2o_int), parameter :: MaxChans = 2701

real(b2o_double) :: radiance
integer(b2o_int) :: iobs, jobs
integer(b2o_int) :: k, n
integer(b2o_int) :: channel

character(len=8) :: s_channel
character(len=16) :: statid

integer(b2o_int), allocatable, save :: channels(:)
real(b2o_double), allocatable, save :: planck_coeffs(:,:)

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_ikfs2',0,zhook_handle)

! Read in namelist of channels to load

if (.not.allocated(channels)) then
  channels = load(B2O_IKFS2_CHANNELS)
end if

! Calculate constants required for radiance to BT conversion.

if (.not.allocated(planck_coeffs)) then
  planck_coeffs = b2o_planck_coeffs(wavenumber(channels))
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

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = size(channels)
  hdr(iobs,hdr_sensor) = 94

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
  sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  sat(iobs,sat_azimuth) = b2o_get_real(handle, "bearingOrAzimuth")
  sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle")
  sat(iobs,sat_solar_azimuth) = b2o_get_real(handle, "solarAzimuth")
  rad(iobs,radiance_scanline) = b2o_get_int(handle, "scanLineNumber")
  rad(iobs,radiance_scanpos) = b2o_get_int(handle, "fieldOfViewNumber")


  if (b2o_is_defined(handle, "heightOfStation")) then
    hdr(iobs,hdr_stalt) = b2o_get_real(handle, "heightOfStation")
  else if (b2o_is_defined(handle, "height")) then
    hdr(iobs,hdr_stalt) = b2o_get_real(handle, "height")
  end if


  ! IKFS2 doesn't have scaled radiances

  n = 0
  channel_loop: do k = 1, MaxChans

    if (.not.b2o_is_defined(handle, "channelNumber", rank=k)) exit channel_loop

    channel = b2o_get_int(handle, "channelNumber", rank=k)

    ! Check if channel number was requested

    if (search(channel, channels) < 0) then
        write (s_channel, "(i4.4)") channel
        call b2o_log(handle, B2O_DEBUG, "Channel number not requested: " // trim(s_channel))
        cycle channel_loop
    end if

    ! (not) Scaled IKFS2 radiance

    n = n + 1
    jobs = jobs + 1

    body(jobs,body_varno) = g_rawbt ! changed to BT as we are converting
    body(jobs,body_vertco_type) = g_cha_number
    body(jobs,body_vertco_reference_1) = channel

    radiance = b2o_get_real(handle, "channelRadiance", rank=k)
    if (radiance /= ODB_MISSING_REAL .and. radiance > 0._B2O_DOUBLE) then
        radiance = radiance / 100._B2O_DOUBLE
        body(jobs,body_obsvalue) = b2o_radiance_to_brightnes_temperature(planck_coeffs(:,n), radiance)
    end if

  end do channel_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_ikfs2',1,zhook_handle)

contains

pure elemental function wavenumber(channel)

    integer(b2o_int), intent(in) :: channel
    real(b2o_double) :: wavenumber

    select case (channel)
    case (1:1571)    ; wavenumber =  660._b2o_double + 0.35_b2o_double * (channel-1)
    case (1572:2701) ; wavenumber = 1210.2_b2o_double + 0.7_b2o_double * (channel-1572)
    case default     ; wavenumber = 1000._b2o_double
    end select

end function

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

    namelist /CHANNELS2LOAD/ I__number_of_channels, I__channels

    ! Default values
    i__number_of_channels = MaxChans
    do k = 1, MaxChans
        i__channels(k) = k
    end do

    open(unit=88, file=file, status='old')
    read(88, nml=channels2load, iostat=iostat)
    if (iostat /= 0) then
        call b2o_log(handle%context, B2O_ERROR, "Cannot read 'ikfs2channels' namelist file")
        call b2o_exit(2)
    end if
    close(88)

    allocate(channels(i__number_of_channels))
    channels(:) = i__channels(1:size(channels))

end function

end subroutine b2o_convert_ikfs2
