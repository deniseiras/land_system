subroutine b2o_convert_gch5(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: resat(:,:)
real(kind=b2o_double), pointer :: resat_ak(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

real(kind=b2o_double) :: ap_ak_value
real(kind=b2o_double) :: ak_value, ak_pressure
real(kind=b2o_double) :: value, scale

integer(kind=b2o_int) :: k, n
integer(kind=b2o_int) :: ap_ak_scale

! This should be consistent with mx_ak in odb/ddl/cma.status
integer(kind=b2o_int), parameter :: MAX_AK_LEVELS = 50

integer(kind=b2o_int) :: varno
integer(kind=b2o_int) :: iobs, jobs
integer(kind=b2o_int) :: n_layers
integer(kind=b2o_int) :: n_ak_levels
integer(kind=b2o_int) :: n_ap_ak_levels
integer(kind=b2o_int) :: n_fixed_ak_levels
integer(kind=b2o_int) :: ak, ak_rank
integer(kind=b2o_int) :: species

character(len=8) :: s_ak_levels
character(len=8) :: s_max_ak_levels
character(len=8) :: s_species
character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_gch5',0,zhook_handle)

n_layers = b2o_get_int(handle, "numberOfRetrievedLayers")

call b2o_reserve(handle, n_layers)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
resat => b2o_use_table(handle, "resat")
resat_ak => b2o_use_table(handle, "resat_averaging_kernel")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_retrtype) = 1 ! averaging kernels
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_layers
  hdr(iobs,hdr_sensor) = b2o_get_int(handle, "satelliteInstruments")

  n_ap_ak_levels = b2o_get_int(handle, "delayedDescriptorReplicationFactor", rank=1)
  n_ak_levels = b2o_get_int(handle, "numberOfAveragingKernelLayers")
  n_fixed_ak_levels = b2o_get_int(handle, "delayedDescriptorReplicationFactor", rank=3)

  if (n_ak_levels .gt. MAX_AK_LEVELS) then
     write (s_ak_levels, "(i2.2)") n_ak_levels
     write (s_max_ak_levels, "(i2.2)") MAX_AK_LEVELS
     call b2o_log(handle, B2O_ERROR, &
         & "Number of averaging kernel levels (" // trim(s_ak_levels) // &
         & ") is greater than allowed maximum of " // trim(s_max_ak_levels))
     status = B2O_SKIP_MESSAGE
     exit subset_loop
  end if

  ! Set varno depending on chemical species
  species = b2o_get_int(handle, "atmosphericChemical")
  select case (species)
  case(5) ; varno = g_chem1 ! Nitrogen dioxide
  case(8) ; varno = g_chem2 ! Sulphur dioxide
  case(4) ; varno = g_chem3 ! Carbon monoxide
  case(7) ; varno = g_chem4 ! Formaldehyde
  case(0) ; varno = g_chem5 ! Ozone
  case default
     write (s_species, "(i4.4)") species
     call b2o_log(handle, B2O_ERROR, "Unknown chemical species: " // s_species)
     status = B2O_SKIP_MESSAGE
  end select
 
  layer_loop: do k = 1, n_layers

    ! Scaled integrated mass density

    jobs = jobs + 1

    n = 2 * n_ap_ak_levels + 2 * (k - 1) + 1

    body(jobs,body_nlayer) = k
    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, "pressure", rank=2*(k-1)+1)
    body(jobs,body_vertco_reference_2) = b2o_get_real(handle, "pressure", rank=2*(k-1)+2)
    body(jobs,body_obsvalue) = b2o_get_real(handle, "integratedMassDensity", rank=k) &
          & * (10.0_B2O_DOUBLE ** b2o_get_real(handle, "decimalScaleOfFollowingSignificands", rank=n))

    scale = b2o_get_real(handle, "decimalScaleOfFollowingSignificands->firstOrderStatisticalValue", rank=n)
    value  = b2o_get_real(handle, "integratedMassDensity->firstOrderStatisticalValue", rank=k)
    errstat(jobs, errstat_obs_error) = value * (10_B2O_DOUBLE ** scale)

    scale = b2o_get_real(handle, "decimalScaleOfFollowingSignificands->firstOrderStatisticalValue", rank=n, nesting=1)
    value  = b2o_get_real(handle, "integratedMassDensity->firstOrderStatisticalValue", rank=k, nesting=1)
    errstat(jobs, errstat_obs_ak_error) = value * (10_B2O_DOUBLE ** scale)

    if (n_ak_levels /= b2o_get_int(handle, "numberOfAveragingKernelLayers")) then
       call b2o_log(handle, B2O_WARNING, &
           & "Number of averaging kernel levels differs between atmospheric layers")
       status = B2O_SKIP_MESSAGE
    end if

    resat_ak(jobs,resat_averaging_kernel_nak) = n_ak_levels

    ! Loop over averaging kernel levels
    do ak = 1, n_ak_levels
      ak_rank = ((k-1) * n_fixed_ak_levels) + ak
      ak_value = b2o_get_real(handle, "averagingKernelValue", rank=ak_rank)
      ak_pressure = b2o_get_real(handle, "nonCoordinatePressure", rank=n_ap_ak_levels+ak_rank)

      ap_ak_value = b2o_get_real(handle, "significandOfVolumetricMixingRatio", rank=ak)
      ap_ak_scale = b2o_get_int(handle, "decimalScaleOfFollowingSignificands", rank=2*(ak-1)+1)

      resat_ak(jobs,resat_averaging_kernel_pak(ak)) = ak_pressure
      resat_ak(jobs,resat_averaging_kernel_wak(ak)) = ak_value
      resat_ak(jobs,resat_averaging_kernel_apak(ak)) = ap_ak_value * (10.0_B2O_DOUBLE ** ap_ak_scale)
    end do

  end do layer_loop

  resat(iobs,resat_retrsource) = b2o_get_int(handle, "originatorOfRetrievedAtmosphericConstituent")
  resat(iobs,resat_instrument_type) = b2o_get_int(handle, "satelliteInstruments")
  resat(iobs,resat_product_type) = b2o_get_int(handle, "productTypeForRetrievedAtmosphericGases")
  resat(iobs,resat_solar_elevation) = b2o_get_real(handle, "solarElevation")
  resat(iobs,resat_scanpos) = b2o_get_real(handle, "fieldOfViewNumber")
  resat(iobs,resat_cloud_cover) = b2o_get_real(handle, "cloudCoverTotal")
  resat(iobs,resat_cloud_top_press) = b2o_get_real(handle, "pressureAtTopOfCloud")
  resat(iobs,resat_quality_retrieval) = b2o_get_int(handle, "overallQualityOfRetrievedAtmosphericProfile")
  resat(iobs,resat_number_layers) = b2o_get_int(handle, "numberOfRetrievedLayers")
  resat(iobs,resat_surface_type_indicator) = b2o_get_int(handle, "surfaceFlag")
  resat(iobs,resat_surface_height) = b2o_get_real(handle, "heightOfLandSurface")

  do k = 1, 4
    resat(iobs,resat_lat_fovcorner(k)) = b2o_get_real(handle, "nonCoordinateLatitude", rank=k)
    resat(iobs,resat_lon_fovcorner(k)) = b2o_get_real(handle, "nonCoordinateLongitude", rank=k)
  end do

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_real(handle, "satelliteInstruments")

end do subset_loop

if (lhook) call dr_hook('b2o_convert_gch5',1,zhook_handle)

end subroutine b2o_convert_gch5
