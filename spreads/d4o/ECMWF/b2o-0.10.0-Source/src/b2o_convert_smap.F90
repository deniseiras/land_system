subroutine b2o_convert_smap(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: smos(:,:)

integer(kind=b2o_int) :: n_variables
integer(kind=b2o_int) :: n_levels
integer(kind=b2o_int) :: n_beams,n_pols,n_pols_real,n_pols_imag,n_subsets
integer(kind=b2o_int) :: k,l
integer(kind=b2o_int) :: iobs
character(len=16) :: statid

integer(kind=b2o_int), allocatable :: entries(:)

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_smap',0,zhook_handle)

call codes_get(handle%bufr_id,"numberOfSubsets",n_subsets)

n_variables = 1
n_levels = 1
n_beams = 2
n_pols = 2 ! We only want X and Y polarisations, not cross polarisations
n_pols_real = 2
n_pols_imag = 2

allocate(entries(n_subsets * n_beams * n_pols))

entries = spread(n_variables, 1, n_subsets * n_beams * n_pols)

call b2o_reserve(handle, entries)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
smos => b2o_use_table(handle, "smos")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0

subset_loop: do while (b2o_next_subset(handle))

  beam_loop: do k = 1, n_beams

    pol_loop: do l = 1, n_pols

      iobs = iobs + 1

      statid = ' '
      write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

      hdr(iobs,hdr_distribtype) = 1 ! distribute on model grid
      hdr(iobs,hdr_date) = b2o_get_date(handle, rank=k)
      hdr(iobs,hdr_time) = b2o_get_time(handle, rank=k)
      hdr(iobs,hdr_lat) = b2o_get_lat(handle, rank=k)
      hdr(iobs,hdr_lon) = b2o_get_lon(handle, rank=k)
      hdr(iobs,hdr_statid) = transfer(statid,to_double)
      hdr(iobs,hdr_numlev) = n_levels
      hdr(iobs,hdr_sensor) = 432

      if (l <= 2) then ! Brightness temperature (real part)
        body(iobs,body_varno) = g_bt_real
        body(iobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperatureRealPart", rank=n_pols_real*(k-1)+l)
        smos(iobs,smos_rad_acc_pure)     = b2o_get_real(handle, "radiometricAccuracyPurePolarization", rank=n_pols_real*(k-1)+l)
      else           ! Brightness temperature (imaginary part) (for cross pol)
        body(iobs,body_varno) = g_bt_imaginary
        body(iobs,body_obsvalue) = b2o_get_real(handle, "brightnessTemperatureImaginaryPart", rank=n_pols_imag*(k-1)+l)
        smos(iobs,smos_rad_acc_cross)    = b2o_get_real(handle, "radiometricAccuracyCrossPolarization", rank=n_pols_imag*(k-1)+l)
      endif
       
      sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
      sat(iobs,sat_satellite_instrument) = b2o_get_int(handle, "satelliteInstruments")
      sat(iobs,sat_azimuth) = b2o_get_real(handle, "azimuthAngle", rank=k)
      sat(iobs,sat_solar_zenith) = b2o_get_real(handle, "solarZenithAngle", rank=k)

      smos(iobs,smos_polarisation)     = 1 - b2o_get_real(handle, "polarization", rank=(n_pols_real+n_pols_imag)*(k-1)+l)
      smos(iobs,smos_incidence_angle)  = b2o_get_real(handle, "incidenceAngle", rank=k)

    end do pol_loop

  end do beam_loop

end do subset_loop

if (allocated(entries)) deallocate(entries)

if (lhook) call dr_hook('b2o_convert_smap',1,zhook_handle)

end subroutine b2o_convert_smap
