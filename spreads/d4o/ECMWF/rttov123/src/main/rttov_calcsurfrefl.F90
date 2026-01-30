! Description:
!> @file
!!   Calculate surface BRDF values for solar-affected channels.
!
!> @brief
!!   Calculate surface BRDF values for solar-affected channels.
!!
!! @details
!!   Two BRDF values are required in the RTE integration:
!!   1) the BRDF for the direct surface-reflected solar beam
!!   2) the BRDF for downward-scattered surface-reflected radiation
!!
!!   The first of these is input/output in the RTTOV reflectance
!!   structure. For sea surfaces where calcrefl is true it is
!!   calculated from the sunglint model (see rttov_refsun) and the
!!   fresnel coefficients (see rttov_fresnel). For land and sea-ice
!!   surfaces fixed albedos are used in the absence of anything better.
!!
!!   For visible/near-IR channels the sunglint model gives extremely
!!   small BRDFs away from the sunglint region which results in an
!!   underestimation of the TOA reflectance. Therefore the BRDF derived
!!   from the USGS water reflectance spectrum (see below) is added to
!!   the calculated sunglint BRDF. This does not apply to short-wave IR
!!   channels.
!!
!!   This BRDF affects only the direct surface-reflected solar term.
!!   It is normalised by refl_norm which is usually COS(sunzenangle),
!!   except where the sunglint model is used since this explicitly
!!   treats the wind-roughened surface: in this case the BRDF is
!!   divided by refl_norm to give a BRDF-like value to be used in the
!!   RTE integration.
!!
!!   The second "diffuse" BRDF is calculated as follows:
!!   - for pure solar channels over sea with calcrefl true the values
!!     are taken from the USGS water spectra (these are interpolated onto
!!     channel wavenumbers in rttov_init_coef when the coef file is read)
!!   - for pure solar channels over land/sea-ice the value is the same
!!     as the direct solar BRDF (applies whether calcrefl is true or false)
!!   - for mixed thermal+solar channels the BRDF is (1-emissivity)/pi
!!     which is consistent with the treatment of downwelling atmospheric
!!     emitted radiation (this value has already been calculated by the
!!     surface emissivity calculations so is not modified here)
!!
!!   The diffuse BRDF affects only the Rayleigh single-scattered radiation
!!   and cloud/aerosol-scattered radiation. Currently this value cannot be
!!   specified separately from the direct solar BRDF by users and the value
!!   used is not an output (note that it only differs from the direct solar
!!   BRDF when using the sunglint model and in this case the values used
!!   are available in the optical depth coef structure).
!!
!!   The diffuse BRDF shares an array with the albedo used for surface-
!!   reflected atmospheric emission. The values for pure solar channels
!!   specified here are multiplied by pi for consistency and this factor is
!!   divided out where they are used in rttov_integrate and rttov_dom.
!!
!! @param[in]     coef           optical depth coefficient structure
!! @param[in]     profiles       input atmospheric profiles and surface variables
!! @param[in]     sunglint       internal structure for sea surface BRDF model variables
!! @param[in]     fresnrefl      fresnel coefficients
!! @param[in]     solar          flags to indicate channels with solar radiation
!! @param[in]     chanprof       specifies channels and profiles to simulate
!! @param[out]    refl_norm      normalisation factor for direct solar BRDF
!! @param[in]     calcrefl       flags to indicate if BRDF should be provided by RTTOV
!! @param[in]     emissivity     emissivity input/output structure
!! @param[in,out] reflectance    BRDF input/output structure
!! @param[in,out] diffuse_refl   diffuse reflectance array
!
! Copyright:
!    This software was developed within the context of
!    the EUMETSAT Satellite Application Facility on
!    Numerical Weather Prediction (NWP SAF), under the
!    Cooperation Agreement dated 25 November 1998, between
!    EUMETSAT and the Met Office, UK, by one or more partners
!    within the NWP SAF. The partners in the NWP SAF are
!    the Met Office, ECMWF, KNMI and MeteoFrance.
!
!    Copyright 2016, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_calcsurfrefl( &
              coef,            &
              profiles,        &
              sunglint,        &
              fresnrefl,       &
              solar,           &
              chanprof,        &
              refl_norm,       &
              calcrefl,        &
              emissivity,      &
              reflectance,     &
              diffuse_refl)

  USE rttov_types, ONLY :  &
         rttov_chanprof,   &
         rttov_coef,       &
         rttov_emissivity, &
         rttov_profile,    &
         rttov_sunglint
  USE parkind1, ONLY : jprb, jplm
!INTF_OFF
  USE rttov_const, ONLY :     &
         min_windsp,          &
         pi, pi_r,            &
         deg2rad,             &
         surftype_sea,        &
         surftype_seaice,     &
         watertype_fresh_water
  USE parkind1, ONLY : jpim
  USE yomhook, ONLY : LHOOK, DR_HOOK
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_chanprof),   INTENT(IN)             :: chanprof(:)
  TYPE(rttov_profile),    INTENT(IN)             :: profiles(:)
  TYPE(rttov_coef),       INTENT(IN)             :: coef
  TYPE(rttov_sunglint),   INTENT(IN)             :: sunglint
  REAL(KIND=jprb),        INTENT(IN)             :: fresnrefl(SIZE(chanprof))
  LOGICAL(KIND=jplm),     INTENT(IN)             :: solar(SIZE(chanprof))
  REAL(KIND=jprb),        INTENT(OUT)            :: refl_norm(SIZE(chanprof))
  LOGICAL(KIND=jplm),     INTENT(IN)             :: calcrefl(SIZE(chanprof))
  TYPE(rttov_emissivity), INTENT(IN),   OPTIONAL :: emissivity(SIZE(chanprof))
  REAL(KIND=jprb),        INTENT(INOUT)          :: reflectance(SIZE(chanprof))
  REAL(KIND=jprb),        INTENT(INOUT)          :: diffuse_refl(SIZE(chanprof))
!INTF_END

  INTEGER(KIND=jpim) :: j, prof, chan
  INTEGER(KIND=jpim) :: nchanprof
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_CALCSURFREFL', 0_jpim, ZHOOK_HANDLE)

  nchanprof = SIZE(chanprof)
  DO j = 1, nchanprof

    IF (.NOT. solar(j)) CYCLE

    prof = chanprof(j)%prof
    chan = chanprof(j)%chan

    refl_norm(j) = COS(profiles(prof)%sunzenangle * deg2rad)

    IF (.NOT. calcrefl(j)) THEN
      ! Normalisation by 1/pi occurs at point of use in integrate
      IF (coef%ss_val_chn(chan) == 2) diffuse_refl(j) = reflectance(j) * pi
      CYCLE
    ENDIF

    IF (profiles(prof)%skin%surftype == surftype_sea) THEN

      reflectance(j) = sunglint%s(prof)%glint * fresnrefl(j)

      ! Scale the reflectance by cos(sunzenangle) because the sea surface model
      ! takes the solar zenith angle in account. This ensures the output reflectance
      ! is BRDF-like.
      IF (profiles(prof)%s2m%u**2 + profiles(prof)%s2m%v**2 > min_windsp**2) THEN
        reflectance(j) = reflectance(j) / refl_norm(j)
      ENDIF

      IF (coef%ss_val_chn(chan) == 2) THEN
        ! For pure solar channels this is the only case where the diffuse and direct solar reflectances differ
        IF (profiles(prof)%skin%watertype == watertype_fresh_water) THEN
          diffuse_refl(j) = coef%refl_visnir_fw(chan)
        ELSE
          diffuse_refl(j) = coef%refl_visnir_ow(chan)
        ENDIF
        reflectance(j) = reflectance(j) + diffuse_refl(j) * pi_r
      ENDIF

    ELSE

      ! For land and sea-ice, the reflectance values represent directional-hemispherical
      ! albedos. The reflectance(:) value is a BRDF, hence the normalisation by 1/pi.

      IF (coef%ss_val_chn(chan) == 1) THEN
        reflectance(j) = (1._jprb - emissivity(j)%emis_out) * pi_r
      ELSE
        IF (profiles(prof)%skin%surftype == surftype_seaice) THEN
          reflectance(j) = 0.8_jprb * pi_r  ! Rough value for sea-ice
        ELSE
          reflectance(j) = 0.3_jprb * pi_r  ! Rough value for land
        ENDIF
      ENDIF

      ! Normalisation by 1/pi occurs at point of use in integrate
      IF (coef%ss_val_chn(chan) == 2) diffuse_refl(j) = reflectance(j) * pi

    ENDIF

  ENDDO
  IF (LHOOK) CALL DR_HOOK('RTTOV_CALCSURFREFL', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_calcsurfrefl
