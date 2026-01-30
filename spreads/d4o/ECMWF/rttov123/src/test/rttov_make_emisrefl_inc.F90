! Description:
!> @file
!!   Compute emissivity and reflectance increments suitable for use in TL
!
!> @brief
!!   Compute emissivity and reflectance increments suitable for use in TL
!!
!! @param[in]     opts             options to configure the simulations
!! @param[in]     coefs            coefficients structure
!! @param[in]     profiles         atmospheric profiles and surface variables
!! @param[in]     chanprof         specifies channels and profiles to simulate
!! @param[in]     calcemis         flags indicating whether RTTOV or user should supply emissivities
!! @param[in,out] emissivity_inc   computed emissivity increments
!! @param[in,out] reflectance_inc  computed BRDF increments
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
!    Copyright 2017, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_make_emisrefl_inc(opts,            &
                                   coefs,           &
                                   profiles,        &
                                   chanprof,        &
                                   calcemis,        &
                                   emissivity_inc,  &
                                   reflectance_inc)
  USE parkind1, ONLY : jplm, jprb

  USE rttov_types, ONLY : &
      rttov_options,      &
      rttov_coefs,        &
      rttov_chanprof,     &
      rttov_profile
!INTF_OFF
  USE parkind1, ONLY : jpim

  USE rttov_const, ONLY : sensor_id_mw, sensor_id_po, surftype_sea
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options),    INTENT(IN)    :: opts
  TYPE(rttov_coefs),      INTENT(IN)    :: coefs
  TYPE(rttov_profile),    INTENT(IN)    :: profiles(:)
  TYPE(rttov_chanprof),   INTENT(IN)    :: chanprof(:)
  LOGICAL(jplm),          INTENT(IN)    :: calcemis(SIZE(chanprof))
  REAL(jprb),             INTENT(INOUT) :: emissivity_inc(SIZE(chanprof))
  REAL(jprb),             INTENT(INOUT) :: reflectance_inc(SIZE(chanprof))
!INTF_END
  INTEGER(jpim) :: nchanprof, i, prof

  nchanprof = SIZE(chanprof)

  emissivity_inc(:) = 0._jprb
  reflectance_inc(:) = 0._jprb

  DO i = 1, nchanprof
    prof = chanprof(i)%prof

    ! We can supply surface emissivity and reflectance increments for all channels.
    ! Where RTTOV is calculating the emissivity or reflectance the corresponding TL
    ! values will be calculated internally and will overwrite any input value.

    IF (coefs%coef%id_sensor == sensor_id_mw .OR. &
        coefs%coef%id_sensor == sensor_id_po) THEN

      emissivity_inc(i) = -0.01_jprb * (MODULO(prof, 3_jpim) + 1_jpim)

    ELSE

      ! Set the emissivity TL to zero when ISEM and the do_lambertian option
      ! are both used, otherwise the Taylor test fails (see rttov_taylor_test)
      IF (profiles(prof)%skin%surftype == surftype_sea .AND. calcemis(i) .AND. &
          opts%rt_all%do_lambertian .AND. opts%rt_ir%ir_sea_emis_model == 1) THEN
        emissivity_inc(i) = 0._jprb
      ELSE
        emissivity_inc(i) = -0.01_jprb * (MODULO(prof, 3_jpim) + 1_jpim)
      ENDIF

      reflectance_inc(i) = 0.01_jprb * (MODULO(prof, 3_jpim) + 1_jpim)

    ENDIF
  ENDDO

END SUBROUTINE rttov_make_emisrefl_inc
