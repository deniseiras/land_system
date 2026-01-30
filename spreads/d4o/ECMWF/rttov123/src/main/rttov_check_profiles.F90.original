! Description:
!> @file
!!   Check input profile variables on user levels for unphysical values.
!
!> @brief
!!   Check input profile variables on user levels for unphysical values.
!!
!! @details
!!   This subroutine is called internally within RTTOV on the input profiles
!!   structure. It checks for physically unrealistic inputs in all variables.
!!
!!   If rttov_user_profile_checkinput is used to check profiles before calling
!!   RTTOV then users may set the do_checkinput option to false in which case
!!   this subroutine is not called. It is important that the same tests on
!!   profile variables are performed in this subroutine and in
!!   rttov_user_profile_checkinput, but note that the latter subroutine does
!!   additional tests, for example, against the regression limits.
!!
!!   In particular the test to ensure gas_units are identical among all
!!   profiles is done in rttov_check_options (which is always called). This
!!   cannot be tested in rttov_user_profile_checkinput so it should not be
!!   tested in this subroutine either.
!!
!!   Since the hard limits for gases are specified in ppmv over dry air, these
!!   are checked using the profiles converted to internal RTTOV units. As such
!!   any out-of-bounds errors for gases are reported in ppmv over dry air
!!   rather than the input gas_units.
!!
!! @param[out]    err            status on exit
!! @param[in]     opts           options to configure the simulations
!! @param[in]     coefs          RTTOV coefficient structure
!! @param[in]     profiles       input profiles structure
!! @param[in]     profiles_int   profiles converted to internal units
!! @param[in]     aer_opt_param  input aerosol optical parameters, optional
!! @param[in]     cld_opt_param  input cloud optical parameters, optional
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
!    Copyright 2018, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_check_profiles( &
         err,           &
         opts,          &
         coefs,         &
         profiles,      &
         profiles_int,  &
         aer_opt_param, &
         cld_opt_param)
!INTF_OFF
#include "throw.h"
!INTF_ON

  USE rttov_types, ONLY : &
      rttov_options,     &
      rttov_coefs,       &
      rttov_profile,     &
      rttov_opt_param

  USE parkind1, ONLY : jpim

!INTF_OFF
  USE rttov_const, ONLY : &
      inst_id_pmr,        &
      nsurftype,          &
      nwatertype,         &
      surftype_sea,       &
      tmax, tmin,         &
      qmax, qmin,         &
      o3max, o3min,       &
      co2max, co2min,     &
      comax, comin,       &
      n2omax, n2omin,     &
      ch4max, ch4min,     &
      so2max, so2min,     &
      clwmax, clwmin,     &
      pmax, pmin,         &
      wmax, elevmax,      &
      zenmax, zenmaxv9,   &
      ctpmax, ctpmin,     &
      bemax, bemin,       &
      nclw_scheme,        &
      clw_scheme_deff,    &
      nice_scheme, nidg,  &
      ice_scheme_ssec,    &
      wcl_id_stco,        &
      wcl_id_cucc,        &
      wcl_id_cucp,        &
      vis_scatt_mfasis
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jprb, jplm
!INTF_ON

  IMPLICIT NONE

  INTEGER(KIND=jpim),      INTENT(OUT)          :: err
  TYPE(rttov_options),     INTENT(IN)           :: opts
  TYPE(rttov_coefs),       INTENT(IN)           :: coefs
  TYPE(rttov_profile),     INTENT(IN)           :: profiles(:)
  TYPE(rttov_profile),     INTENT(IN)           :: profiles_int(:)
  TYPE(rttov_opt_param),   INTENT(IN), OPTIONAL :: aer_opt_param
  TYPE(rttov_opt_param),   INTENT(IN), OPTIONAL :: cld_opt_param
!INTF_END

#include "rttov_errorreport.interface"

  REAL(KIND=jprb)    :: wind, zmax
  INTEGER(KIND=jpim) :: nprofiles, iprof, nlevels
  CHARACTER(32)      :: sprof
  LOGICAL(KIND=jplm) :: ltest(SIZE(profiles(1)%p)), do_mfasis
  REAL(KIND=jprb)    :: ZHOOK_HANDLE

  !- End of header --------------------------------------------------------
  TRY

  !-------------
  ! Initialize
  !-------------

  IF (LHOOK) CALL DR_HOOK('RTTOV_CHECK_PROFILES',0_jpim,ZHOOK_HANDLE)

  do_mfasis = (opts%rt_ir%addaerosl .OR. opts%rt_ir%addclouds) .AND. &
              opts%rt_ir%vis_scatt_model == vis_scatt_mfasis   .AND. &
              opts%rt_ir%addsolar

  nprofiles = SIZE(profiles)

  DO iprof = 1, nprofiles
    ! For OpenMP only: Fortran I/O is not thread-safe
!$OMP CRITICAL
    WRITE(sprof,'(" (profile number = ",I8,")")') iprof
!$OMP END CRITICAL

    !------------------------------
    ! Check scalar variables
    !------------------------------

    ! Zenith angle
    IF (coefs%coef%fmv_model_ver == 9) THEN
      zmax = zenmaxv9
    Else
      zmax = zenmax
    ENDIF
    IF (profiles(iprof)%zenangle > zmax .OR. &
        profiles(iprof)%zenangle < 0._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid zenith angle"//sprof)
    ENDIF

    ! PMR zenith angle
    IF (coefs%coef%id_inst == inst_id_pmr) THEN
      IF (profiles(iprof)%zenangle > 1E-3_jprb) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "For PMR zenith angle must be zero: the angle is part of the channel definition"//sprof)
      ENDIF
    ENDIF

    ! Solar zenith angle
    IF (opts%rt_ir%addsolar) THEN
      IF (profiles(iprof)%sunzenangle < 0._jprb) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid solar zenith angle"//sprof)
      ENDIF
    ENDIF

    ! Cloud fraction
    IF (profiles(iprof)%cfraction > 1._jprb .OR. &
        profiles(iprof)%cfraction < 0._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid cloud fraction (cfraction)"//sprof)
    ENDIF

    ! Cloud Top Pressure
    IF (profiles(iprof)%cfraction > 0._jprb) THEN
      IF (profiles(iprof)%ctp > ctpmax .OR. &
          profiles(iprof)%ctp < ctpmin) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid cloud top pressure (ctp)"//sprof)
      ENDIF
    ENDIF

    ! Zeeman variables
    IF (coefs%coef%inczeeman) THEN
      ! Magnetic field strength
      IF (profiles(iprof)%be > bemax .OR. &
          profiles(iprof)%be < bemin) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid magnetic field strength"//sprof)
      ENDIF

      ! Cosine of angle between path and mag. field
      IF (profiles(iprof)%cosbk > 1._jprb  .OR. &
          profiles(iprof)%cosbk < -1._jprb) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid cosbk"//sprof)
      ENDIF
    ENDIF


    ! Surface variables

    ! Pressure
    IF (profiles(iprof)%s2m%p > pmax .OR. &
        profiles(iprof)%s2m%p < pmin) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid surface pressure"//sprof)
    ENDIF

    IF (.NOT. do_mfasis) THEN
      ! 2m air temperature
      IF (profiles(iprof)%s2m%t > tmax .OR. &
          profiles(iprof)%s2m%t < tmin) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid 2m air temperature"//sprof)
      ENDIF

      ! 2m water vapour - only used if opts%rt_all%use_q2m is TRUE
      IF (opts%rt_all%use_q2m) THEN
        IF (profiles_int(iprof)%s2m%q > qmax .OR. &
            profiles_int(iprof)%s2m%q < qmin) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "invalid 2m water vapour"//sprof)
        ENDIF
      ENDIF
    ENDIF

    !  surface wind speed
    wind = SQRT(profiles(iprof)%s2m%u * profiles(iprof)%s2m%u + &
                profiles(iprof)%s2m%v * profiles(iprof)%s2m%v)
    IF (wind > wmax) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid 10m wind speed"//sprof)
    ENDIF

    IF (opts%rt_ir%addsolar) THEN
      ! wind fetch
      IF (profiles(iprof)%s2m%wfetc <= 0._jprb .AND. &
          profiles(iprof)%skin%surftype == surftype_sea) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid wfetc (wind fetch)"//sprof)
      ENDIF
    ENDIF

    IF (.NOT. do_mfasis) THEN
      ! surface skin temperature
      IF (profiles(iprof)%skin%t > tmax .OR. &
          profiles(iprof)%skin%t < tmin) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid skin surface temperature"//sprof)
      ENDIF
    ENDIF

    ! surface type
    IF (profiles(iprof)%skin%surftype < 0 .OR. &
        profiles(iprof)%skin%surftype > nsurftype) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid surface type"//sprof)
    ENDIF

    ! water type
    IF (profiles(iprof)%skin%watertype < 0 .OR. &
        profiles(iprof)%skin%watertype > nwatertype) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid water type"//sprof)
    ENDIF

    ! foam fraction
    IF (opts%rt_mw%supply_foam_fraction) THEN
      IF (profiles(iprof)%skin%foam_fraction < 0._jprb .OR. &
          profiles(iprof)%skin%foam_fraction > 1._jprb) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid foam fraction"//sprof)
      ENDIF
    ENDIF

    ! salinity
    IF (profiles(iprof)%skin%salinity < 0._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid salinity"//sprof)
    ENDIF

    ! snow fraction
    IF (profiles(iprof)%skin%snow_fraction < 0._jprb .OR. &
        profiles(iprof)%skin%snow_fraction > 1._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid snow fraction"//sprof)
    ENDIF

    ! specularity
    IF (opts%rt_all%do_lambertian) THEN
      IF (profiles(iprof)%skin%specularity < 0._jprb .OR. &
          profiles(iprof)%skin%specularity > 1._jprb) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid specularity"//sprof)
      ENDIF
    ENDIF

    ! elevation
    IF (profiles(iprof)%elevation > elevmax) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid elevation (units are km)"//sprof)
    ENDIF

    ! latitude
    IF (profiles(iprof)%latitude < -90._jprb .OR. &
        profiles(iprof)%latitude > 90._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid latitude"//sprof)
    ENDIF


    ! Atmospheric variables

    ! Max pressure - catches input profiles passed in Pa instead of hPa
    IF (MAXVAL(profiles(iprof)%p) > 2000._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid pressure profile (units are hPa)"//sprof)
    ENDIF

    ! Monotonically increasing pressure
    nlevels = profiles(iprof)%nlevels
    IF (ANY(profiles(iprof)%p(2:nlevels) - profiles(iprof)%p(1:nlevels-1) <= 0._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "pressure levels must be monotonically increasing from TOA down to surface"//sprof)
    ENDIF

    ltest = .FALSE.

    ! temperature
    ltest(:) = (profiles(iprof)%t(:) > tmax)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input temperature profile exceeds allowed maximum:", &
        (/tmax/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                  PACK(profiles(iprof)%t(:), mask=ltest(:)))
    ENDIF

    ltest(:) = (profiles(iprof)%t(:) < tmin)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input temperature profile exceeds allowed minimum:", &
        (/tmin/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                  PACK(profiles(iprof)%t(:), mask=ltest(:)))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric temperature"//sprof)

    ! water vapour
    ltest(:) = (profiles_int(iprof)%q(:) > qmax)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input water vapour profile exceeds allowed maximum:", &
        (/qmax/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                  PACK(profiles_int(iprof)%q(:), mask=ltest(:)))
    ENDIF

    ltest(:) = (profiles_int(iprof)%q(:) < qmin)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input water vapour profile exceeds allowed minimum:", &
        (/qmin/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                  PACK(profiles_int(iprof)%q(:), mask=ltest(:)))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric water vapour"//sprof)

    ! ozone
    IF (opts%rt_ir%ozone_data .AND. coefs%coef%nozone > 0) THEN
      ltest(:) = (profiles_int(iprof)%o3(:) > o3max)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input ozone profile exceeds allowed maximum:", &
          (/o3max/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                     PACK(profiles_int(iprof)%o3(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%o3(:) < o3min)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input ozone profile exceeds allowed minimum:", &
          (/o3min/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                     PACK(profiles_int(iprof)%o3(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric ozone"//sprof)
    ENDIF

    ! CO2
    IF (opts%rt_ir%co2_data .AND. coefs%coef%nco2 > 0) THEN
      ltest(:) = (profiles_int(iprof)%co2(:) > co2max)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CO2 profile exceeds allowed maximum:", &
          (/co2max/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%co2(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%co2(:) < co2min)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CO2 profile exceeds allowed minimum:", &
          (/co2min/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%co2(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric CO2"//sprof)
    ENDIF

    ! CO
    IF (opts%rt_ir%co_data .AND. coefs%coef%nco > 0) THEN
      ltest(:) = (profiles_int(iprof)%co(:) > comax)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CO profile exceeds allowed maximum:", &
          (/comax/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                     PACK(profiles_int(iprof)%co(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%co(:) < comin)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CO profile exceeds allowed minimum:", &
          (/comin/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                     PACK(profiles_int(iprof)%co(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric CO"//sprof)
    ENDIF

    ! N2O
    IF (opts%rt_ir%n2o_data .AND. coefs%coef%nn2o > 0) THEN
      ltest(:) = (profiles_int(iprof)%n2o(:) > n2omax)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input N2O profile exceeds allowed maximum:", &
          (/n2omax/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%n2o(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%n2o(:) < n2omin)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input N2O profile exceeds allowed minimum:", &
          (/n2omin/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%n2o(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric N2O"//sprof)
    ENDIF

    ! CH4
    IF (opts%rt_ir%ch4_data .AND. coefs%coef%nch4 > 0) THEN
      ltest(:) = (profiles_int(iprof)%ch4(:) > ch4max)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CH4 profile exceeds allowed maximum:", &
          (/ch4max/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%ch4(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%ch4(:) < ch4min)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input CH4 profile exceeds allowed minimum:", &
          (/ch4min/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%ch4(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric CH4"//sprof)
    ENDIF

    ! SO2
    IF (opts%rt_ir%so2_data .AND. coefs%coef%nso2 > 0) THEN
      ltest(:) = (profiles_int(iprof)%so2(:) > so2max)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input SO2 profile exceeds allowed maximum:", &
          (/so2max/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%so2(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles_int(iprof)%so2(:) < so2min)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input SO2 profile exceeds allowed minimum:", &
          (/so2min/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles_int(iprof)%so2(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric SO2"//sprof)
    ENDIF

    ! cloud liquid water
    IF (opts%rt_mw%clw_data) THEN
      ltest(:) = (profiles(iprof)%clw(:) > clwmax)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input cloud liquid water profile exceeds allowed maximum:", &
          (/clwmax/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles(iprof)%clw(:), mask=ltest(:)))
      ENDIF

      ltest(:) = (profiles(iprof)%clw(:) < clwmin)
      IF (ANY(ltest)) THEN
        err = errorstatus_fatal
        CALL print_info("Input cloud liquid water profile exceeds allowed minimum:", &
          (/clwmin/), PACK(profiles(iprof)%p(:), mask=ltest(:)), &
                      PACK(profiles(iprof)%clw(:), mask=ltest(:)))
      ENDIF
      THROWM(err .NE. 0, "some invalid atmospheric cloud liquid water"//sprof)
    ENDIF


    ! Cloud variables

    IF (opts%rt_ir%addclouds) THEN
      IF (ANY(profiles(iprof)%cfrac(:) > 1._jprb) .OR. &
          ANY(profiles(iprof)%cfrac(:) < 0._jprb)) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid cloud profile fraction (cfrac) (must be in [0,1])"//sprof)
      ENDIF

      IF (.NOT. opts%rt_ir%user_cld_opt_param) THEN

        IF (profiles(iprof)%clw_scheme < 1_jpim .OR. profiles(iprof)%clw_scheme > nclw_scheme) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "invalid clw_scheme"//sprof)
        ENDIF

        IF (profiles(iprof)%clw_scheme == clw_scheme_deff) THEN
          IF (ANY(profiles(iprof)%clwde(:) < 0._jprb)) THEN
            err = errorstatus_fatal
            THROWM(err .NE. 0, "some invalid cloud liquid water effective diameter (must be >=0)"//sprof)
          ENDIF
        ENDIF

        IF (profiles(iprof)%ice_scheme < 1_jpim .OR. profiles(iprof)%ice_scheme > nice_scheme) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "invalid ice_scheme"//sprof)
        ENDIF

        IF (profiles(iprof)%ice_scheme == ice_scheme_ssec) THEN
          IF (profiles(iprof)%idg < 1_jpim .OR. profiles(iprof)%idg > nidg) THEN
            err = errorstatus_fatal
            THROWM(err .NE. 0, "invalid ice effective diameter parameterisation (idg)"//sprof)
          ENDIF

          IF (ANY(profiles(iprof)%icede(:) < 0._jprb)) THEN
            err = errorstatus_fatal
            THROWM(err .NE. 0, "some invalid ice effective diameter (must be >=0)"//sprof)
          ENDIF
        ENDIF

        IF (ANY(profiles(iprof)%cloud(:,:) < 0._jprb)) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "some invalid cloud concentration (must be >=0)"//sprof)
        ENDIF

        ! Check scattering coefficient files support selected optical properties
        IF (opts%rt_ir%pc%addpc .AND. coefs%coef_pccomp%fmv_pc_cld /= 0) THEN
          IF (ANY(profiles(iprof)%cloud(wcl_id_stco,:) > 0._jprb) .OR. &
              ANY(profiles(iprof)%cloud(wcl_id_cucc,:) > 0._jprb) .OR. &
              ANY(profiles(iprof)%cloud(wcl_id_cucp,:) > 0._jprb)) THEN
            err = errorstatus_fatal
            THROWM(err .NE. 0, "only maritime water cloud types are allowed for cloudy PC-RTTOV"//sprof)
          ENDIF
        ENDIF

      ENDIF
    ENDIF


    ! Aerosol variables

    IF (opts%rt_ir%addaerosl) THEN
      IF (.NOT. opts%rt_ir%user_aer_opt_param) THEN

        IF (ANY(profiles(iprof)%aerosols(:,:) < 0._jprb)) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "some invalid aerosol concentration (must be >=0)"//sprof)
        ENDIF

        IF (opts%rt_ir%pc%addpc .AND. coefs%coef_pccomp%fmv_pc_aer /= 0) THEN
          IF (ANY(profiles(iprof)%aerosols(coefs%coef_pccomp%fmv_pc_naer_types+1:,:) > 0._jprb)) THEN
            err = errorstatus_fatal
            THROWM(err .NE. 0, "only OPAC aerosol components are allowed for PC-RTTOV aerosol simulations"//sprof)
          ENDIF
        ENDIF

      ENDIF
    ENDIF

  ENDDO ! profiles


  ! Cloud and aerosol optical properties

  IF (opts%rt_ir%addclouds .AND. opts%rt_ir%user_cld_opt_param) THEN
    IF (ANY(cld_opt_param%abs(:,:) < 0._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid cloud absorption coefficient (must be >=0)")
    ENDIF

    IF (ANY(cld_opt_param%sca(:,:) < 0._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid cloud scattering coefficient (must be >=0)")
    ENDIF

    IF (ANY(cld_opt_param%bpr(:,:) < 0._jprb) .OR. &
        ANY(cld_opt_param%bpr(:,:) > 1._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid cloud bpr coefficient (must be in [0,1])")
    ENDIF
  ENDIF

  IF (opts%rt_ir%addaerosl .AND. opts%rt_ir%user_aer_opt_param) THEN
    IF (ANY(aer_opt_param%abs(:,:) < 0._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid aerosol absorption coefficient (must be >=0)")
    ENDIF

    IF (ANY(aer_opt_param%sca(:,:) < 0._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid aerosol scattering coefficient (must be >=0)")
    ENDIF

    IF (ANY(aer_opt_param%bpr(:,:) < 0._jprb) .OR. &
        ANY(aer_opt_param%bpr(:,:) > 1._jprb)) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid aerosol bpr coefficient (must be in [0,1])")
    ENDIF
  ENDIF


  IF (LHOOK) CALL DR_HOOK('RTTOV_CHECK_PROFILES',1_jpim,ZHOOK_HANDLE)

  CATCH

  IF (LHOOK) CALL DR_HOOK('RTTOV_CHECK_PROFILES',1_jpim,ZHOOK_HANDLE)

CONTAINS

  SUBROUTINE print_info(msg1, limits, levels, values)
    CHARACTER(LEN=*), INTENT(IN) :: msg1
    REAL(KIND=jprb),  INTENT(IN) :: limits(:)
    REAL(KIND=jprb),  INTENT(IN) :: levels(:)
    REAL(KIND=jprb),  INTENT(IN) :: values(:)

    CHARACTER(LEN=256) :: msg2
    INTEGER(KIND=jpim) :: imax, lmax

    imax = MIN(10, SIZE(levels))
    lmax = MIN(imax, SIZE(limits))

! Replace warn/info macros from throw.h with in-line code because
! NAG v5.3 complains otherwise.

! For OpenMP only: Fortran I/O is not thread-safe
!$OMP CRITICAL
!     WARN(msg1)
    CALL rttov_errorreport(errorstatus_success, TRIM(msg1), 'rttov_check_profiles.F90')
    WRITE(msg2, '(a,10g11.4)') 'Limit   = ',limits(1:lmax)
!     INFO(TRIM(msg2))
    CALL rttov_errorreport(errorstatus_success, TRIM(msg2))
    WRITE(msg2, '(a,10f11.4)') 'p (hPa) = ',levels(1:imax)
!     INFO(TRIM(msg2))
    CALL rttov_errorreport(errorstatus_success, TRIM(msg2))
    WRITE(msg2, '(a,10g11.4)') 'Value   = ',values(1:imax)
!     INFO(TRIM(msg2))
    CALL rttov_errorreport(errorstatus_success, TRIM(msg2))
!$OMP END CRITICAL

  END SUBROUTINE print_info

END SUBROUTINE rttov_check_profiles
