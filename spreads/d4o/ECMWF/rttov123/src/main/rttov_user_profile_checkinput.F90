! Description:
!> @file
!!   Check input profile variables are physically realistic.
!
!> @brief
!!   Check input profile variables are physically realistic and compare
!!   profile values against the regression limits used in coef training.
!!
!! @details
!!   This subroutine carries out the same tests performed by the
!!   rttov_check_profiles and rttov_checkinput subroutines and also some
!!   relevant tests performed by rttov_check_options.
!!
!!   Unphysical values return a fatal error status.
!!   If opts\%rt_config\%verbose is true then warnings are printed when
!!   regression limits are exceeded. If reg_limits_exceeded is passed in
!!   this is set to true if the limits are exceeded.
!!
!!   Comparisons for gas inputs are all carried out in units of ppmv
!!   over dry air as these are the units used in the coefficient
!!   generation. Where limits are exceeded values are reported in
!!   ppmv over dry air.
!!
!!   Comparisons for ice cloud water content are carried out in units of
!!   g/m3 as these are the units used internally by RTTOV. Where limits are
!!   exceeded values are reported in g/m3.
!!
!!   This subroutine tests a single profile on any pressure levels:
!!   profile levels are tested against regression limits for the nearest
!!   higher pressure coefficient level.
!!
!!   This can be used to check profiles before calling RTTOV instead of
!!   using the internal RTTOV profile checking which is controlled by
!!   opts\%config\%do_checkinput.
!!
!!   The subroutine also optionally checks aer/cld_opt_param structures:
!!   these are checked for unphysical values across *all* channels/profiles.
!!
!! @param[out]    err                  status on exit
!! @param[in]     opts                 options to configure the simulations
!! @param[in]     coefs                coefficients structure for instrument to simulate
!! @param[in]     prof                 input profile to check
!! @param[in]     aer_opt_param        input aerosol optical parameter profile to check, optional
!! @param[in]     cld_opt_param        input cloud optical parameter profile to check, optional
!! @param[in,out] reg_limits_exceeded  output flag indicating whether regression limits were exceeded, optional
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
!    Copyright 2015, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_user_profile_checkinput( &
         err,                &
         opts,               &
         coefs,              &
         prof,               &
         aer_opt_param,      &
         cld_opt_param,      &
         reg_limits_exceeded )

!INTF_OFF
#include "throw.h"
!INTF_ON

  USE rttov_types, ONLY :  &
      rttov_coefs,    &
      rttov_options,  &
      rttov_profile,  &
      rttov_opt_param

  USE parkind1, ONLY : jpim, jplm

!INTF_OFF
  USE rttov_const, ONLY :     &
      inst_id_pmr,            &
      ngases_unit,            &
      nsurftype,              &
      surftype_sea,           &
      vis_scatt_mfasis,       &
      nwatertype,             &
      wcl_id_stco,            &
      wcl_id_cucc,            &
      wcl_id_cucp,            &
      naer_opac,              &
      gas_id_watervapour,     &
      gas_id_ozone,           &
      gas_id_co2,             &
      gas_id_co,              &
      gas_id_ch4,             &
      gas_id_so2,             &
      gas_id_n2o,             &
      tmax, tmin,             &
      qmax, qmin,             &
      o3max, o3min,           &
      co2max, co2min,         &
      comax, comin,           &
      n2omax, n2omin,         &
      ch4max, ch4min,         &
      so2max, so2min,         &
      clwmax, clwmin,         &
      pmax, pmin,             &
      wmax, elevmax,          &
      zenmax, zenmaxv9,       &
      ctpmax, ctpmin,         &
      bemax, bemin,           &
      nclw_scheme,            &
      clw_scheme_deff,        &
      dgmin_clw, dgmax_clw,   &
      nice_scheme, nidg,      &
      ice_scheme_ssec,        &
      ice_scheme_baran,       &
      ice_scheme_baran2018,   &
      dgmin_ssec, dgmax_ssec, &
      iwcmax_ssec
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jprb
  USE mod_rttov_baran2018_icldata, ONLY : &
      baran2018_iwc_max,  &
      baran2018_temp_min, &
      baran2018_temp_max
!INTF_ON

  IMPLICIT NONE

  INTEGER(KIND=jpim),              INTENT(OUT) :: err                  ! status on exit
  TYPE(rttov_options),             INTENT(IN)  :: opts                 ! options to configure the simulations
  TYPE(rttov_coefs),               INTENT(IN)  :: coefs                ! coefficients structure for instrument to simulate
  TYPE(rttov_profile),             INTENT(IN)  :: prof                 ! input profile to check
  TYPE(rttov_opt_param), OPTIONAL, INTENT(IN)  :: aer_opt_param        ! input aerosol optical parameter profile to check
  TYPE(rttov_opt_param), OPTIONAL, INTENT(IN)  :: cld_opt_param        ! input cloud optical parameter profile to check
  LOGICAL(KIND=jplm),    OPTIONAL, INTENT(OUT) :: reg_limits_exceeded  ! output flag indicating whether reg. limits were exceeded

!INTF_END
#include "rttov_alloc_prof_internal.interface"
#include "rttov_convert_profile_units.interface"
#include "rttov_errorreport.interface"
  TYPE(rttov_profile)          :: prof_int(1)
  REAL(KIND=jprb)              :: wind, zmax
  REAL(KIND=jprb)              :: iwcmax
  REAL(KIND=jprb), ALLOCATABLE :: aer_min(:,:), aer_max(:,:)
  INTEGER(KIND=jpim)           :: firstlevel, firstcoeflevel, ilev, jlev, ilay, ig, t
  INTEGER(KIND=jpim)           :: lay_user, lev_user_upper, lev_user_lower
  INTEGER(KIND=jpim)           :: lev_coef_upper, lev_coef_lower
  LOGICAL(KIND=jplm)           :: OK, reg_limits_warn, ltest(SIZE(prof%p))
  CHARACTER(256)               :: msg
  REAL(KIND=jprb)              :: ZHOOK_HANDLE

!- End of header --------------------------------------------------------

TRY

  !-------------
  ! Initialize
  !-------------

  IF (LHOOK) CALL DR_HOOK('RTTOV_USER_PROFILE_CHECKINPUT',0_jpim,ZHOOK_HANDLE)

  reg_limits_warn = .FALSE._jplm

  ! We should check all levels which can contribute to output radiances.
  ! Exactly which user levels contribute depends on the user and coef
  ! levels, the surface pressure, and the interpolation mode used.
  ! In a future version we would like to ensure no input levels below
  ! the level immediately below the surface pressure contribute, but
  ! this is not necessarily the case currently.
  ! In general we should check down at least as far as the *coef*
  ! pressure level which lies on or below the surface pressure.

  ! Find first coef level at or below surface
  DO firstcoeflevel = coefs%coef%nlevels, 2, -1
    IF (coefs%coef%ref_prfl_p(firstcoeflevel-1) < prof%s2m%p) EXIT
  ENDDO

  ! Find first user level at or below firstcoeflevel
  DO firstlevel = prof%nlevels, 2, -1
    IF (prof%p(firstlevel-1) < coefs%coef%ref_prfl_p(firstcoeflevel)) EXIT
  ENDDO

  ! Create profile in internal RTTOV units
  IF (prof%gas_units > ngases_unit) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid gas units")
  ENDIF

  CALL rttov_alloc_prof_internal(err, prof_int, prof%nlevels, opts, coefs, 1_jpim)
  THROWM(err .NE. 0, "error allocating data")
  CALL rttov_convert_profile_units(opts, coefs, (/ prof /), prof_int)


  !------------------------------
  ! Check for unphysical values
  !------------------------------

  ! zenith angle
  IF (coefs%coef%fmv_model_ver == 9) THEN
    zmax = zenmaxv9
  ELSE
    zmax = zenmax
  ENDIF
  IF (prof%zenangle > zmax .OR. &
      prof%zenangle < 0._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid zenith angle")
  ENDIF

  ! PMR zenith angle
  IF (coefs%coef%id_inst == inst_id_pmr) THEN
    IF (prof%zenangle > 1E-3_jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "For PMR zenith angle must be zero: the angle is part of the channel definition")
    ENDIF
  ENDIF

  ! Solar zenith angle
  IF (opts%rt_ir%addsolar) THEN
    IF (prof%sunzenangle < 0._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid solar zenith angle")
    ENDIF
  ENDIF

  ! Cloud fraction
  IF (prof%cfraction > 1._jprb .OR. &
      prof%cfraction < 0._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid cloud fraction (cfraction)")
  ENDIF

  ! Cloud Top Pressure
  IF (prof%cfraction > 0._jprb) THEN
    IF (prof%ctp > ctpmax .OR. &
        prof%ctp < ctpmin) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid cloud top pressure (ctp)")
    ENDIF
  ENDIF

  ! Zeeman variables
  IF (coefs%coef%inczeeman) THEN
    ! Magnetic field strength
    IF (prof%be > bemax .OR. &
        prof%be < bemin) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid magnetic field strength")
    ENDIF

    ! Cosine of angle between path and mag. field
    IF (prof%cosbk > 1._jprb  .OR. &
        prof%cosbk < -1._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid cosbk")
    ENDIF
  ENDIF

  !---------------------
  ! Surface variables
  !---------------------

  ! Pressure
  IF (prof%s2m%p > pmax .OR. &
      prof%s2m%p < pmin) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid surface pressure")
  ENDIF

  ! 2m air temperature
  IF (prof%s2m%t > tmax .OR. &
      prof%s2m%t < tmin) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid 2m air temperature")
  ENDIF

  ! 2m water vapour - only used if opts%rt_all%use_q2m is true
  IF (opts%rt_all%use_q2m) THEN
    IF (prof_int(1)%s2m%q > qmax .OR. &
        prof_int(1)%s2m%q < qmin) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid 2m water vapour")
    ENDIF
  ENDIF

  ! surface wind speed
  wind = SQRT(prof%s2m%u * prof%s2m%u + &
              prof%s2m%v * prof%s2m%v)
  IF (wind > wmax) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid 10m wind speed")
  ENDIF

  IF (opts%rt_ir%addsolar) THEN
    IF (prof%s2m%wfetc <= 0._jprb .AND. &
        prof%skin%surftype == surftype_sea) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid wfetc (wind fetch)")
    ENDIF
  ENDIF

  ! surface skin temperature
  IF (prof%skin%t > tmax .OR. &
      prof%skin%t < tmin) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid skin surface temperature")
  ENDIF

  ! surface type
  IF (prof%skin%surftype < 0 .OR. &
      prof%skin%surftype > nsurftype) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid surface type")
  ENDIF

  ! water type
  IF (prof%skin%watertype < 0 .OR. &
      prof%skin%watertype > nwatertype) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid water type")
  ENDIF

  ! foam fraction
  IF (opts%rt_mw%supply_foam_fraction) THEN
    IF (prof%skin%foam_fraction < 0._jprb .OR. &
        prof%skin%foam_fraction > 1._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid foam fraction")
    ENDIF
  ENDIF

  ! salinity
  IF (prof%skin%salinity < 0._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid salinity")
  ENDIF

  ! snow fraction
  IF (prof%skin%snow_fraction < 0._jprb .OR. &
      prof%skin%snow_fraction > 1._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid snow fraction")
  ENDIF

  ! specularity
  IF (opts%rt_all%do_lambertian) THEN
    IF (prof%skin%specularity < 0._jprb .OR. &
        prof%skin%specularity > 1._jprb) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "invalid specularity")
    ENDIF
  ENDIF

  ! elevation
  IF (prof%elevation > elevmax) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid elevation (units are km)")
  ENDIF

  ! latitude
  IF (prof%latitude < -90._jprb .OR. &
      prof%latitude > 90._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid latitude")
  ENDIF


  !-------------------------
  ! Atmospheric variables
  !-------------------------

  ! Max pressure - catches input profiles passed in Pa instead of hPa
  IF (MAXVAL(prof%p) > 2000._jprb) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "invalid pressure profile (units are hPa)")
  ENDIF

  ! Monotonically increasing pressure
  IF (ANY(prof%p(2:prof%nlevels) - prof%p(1:prof%nlevels-1) <= 0._jprb)) THEN
    err = errorstatus_fatal
    THROWM(err .NE. 0, "pressure levels must be monotonically increasing from TOA down to surface")
  ENDIF

  ! Predictors are calculated on *all* levels so check
  ! the hard limits on every level to avoid errors.

  ! temperature
  ltest = (prof%t(:) > tmax)
  IF (ANY(ltest)) THEN
    err = errorstatus_fatal
    CALL print_info("Input temperature profile exceeds allowed maximum:", &
      (/tmax/), PACK(prof%p(:), mask=ltest), PACK(prof%t(:), mask=ltest))
  ENDIF

  ltest = (prof%t(:) < tmin)
  IF (ANY(ltest)) THEN
    err = errorstatus_fatal
    CALL print_info("Input temperature profile exceeds allowed minimum:", &
      (/tmin/), PACK(prof%p(:), mask=ltest), PACK(prof%t(:), mask=ltest))
  ENDIF
  THROWM(err .NE. 0, "some invalid atmospheric temperature")

  ! water vapour
  ltest = (prof_int(1)%q(:) > qmax)
  IF (ANY(ltest)) THEN
    err = errorstatus_fatal
    CALL print_info("Input water vapour profile exceeds allowed maximum:", &
      (/qmax/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%q(:), mask=ltest))
  ENDIF

  ltest = (prof_int(1)%q(:) < qmin)
  IF (ANY(ltest)) THEN
    err = errorstatus_fatal
    CALL print_info("Input water vapour profile exceeds allowed minimum:", &
      (/qmin/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%q(:), mask=ltest))
  ENDIF
  THROWM(err .NE. 0, "some invalid atmospheric water vapour")

  ! ozone
  IF (opts%rt_ir%ozone_data .AND. coefs%coef%nozone > 0) THEN
    ltest = (prof_int(1)%o3(:) > o3max)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input ozone profile exceeds allowed maximum:", &
        (/o3max/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%o3(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%o3(:) < o3min)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input ozone profile exceeds allowed minimum:", &
        (/o3min/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%o3(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric ozone")
  ENDIF

  ! CO2
  IF (opts%rt_ir%co2_data .AND. coefs%coef%nco2 > 0) THEN
    ltest = (prof_int(1)%co2(:) > co2max)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CO2 profile exceeds allowed maximum:", &
        (/co2max/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%co2(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%co2(:) < co2min)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CO2 profile exceeds allowed minimum:", &
        (/co2min/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%co2(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric CO2")
  ENDIF

  ! CO
  IF (opts%rt_ir%co_data .AND. coefs%coef%nco > 0) THEN
    ltest = (prof_int(1)%co(:) > comax)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CO profile exceeds allowed maximum:", &
        (/comax/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%co(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%co(:) < comin)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CO profile exceeds allowed minimum:", &
        (/comin/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%co(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric CO")
  ENDIF

  ! N2O
  IF (opts%rt_ir%n2o_data .AND. coefs%coef%nn2o > 0) THEN
    ltest = (prof_int(1)%n2o(:) > n2omax)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input N2O profile exceeds allowed maximum:", &
        (/n2omax/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%n2o(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%n2o(:) < n2omin)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input N2O profile exceeds allowed minimum:", &
        (/n2omin/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%n2o(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric N2O")
  ENDIF

  ! CH4
  IF (opts%rt_ir%ch4_data .AND. coefs%coef%nch4 > 0) THEN
    ltest = (prof_int(1)%ch4(:) > ch4max)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CH4 profile exceeds allowed maximum:", &
        (/ch4max/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%ch4(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%ch4(:) < ch4min)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input CH4 profile exceeds allowed minimum:", &
        (/ch4min/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%ch4(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric CH4")
  ENDIF

  ! SO2
  IF (opts%rt_ir%so2_data .AND. coefs%coef%nso2 > 0) THEN
    ltest = (prof_int(1)%so2(:) > so2max)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input SO2 profile exceeds allowed maximum:", &
        (/so2max/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%so2(:), mask=ltest))
    ENDIF

    ltest = (prof_int(1)%so2(:) < so2min)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input so2 profile exceeds allowed minimum:", &
        (/so2min/), PACK(prof%p(:), mask=ltest), PACK(prof_int(1)%so2(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric so2")
  ENDIF

  ! MW cloud liquid water
  IF (opts%rt_mw%clw_data) THEN
    ltest = (prof%clw(:) > clwmax)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input cloud liquid water profile exceeds allowed maximum:", &
        (/clwmax/), PACK(prof%p(:), mask=ltest), PACK(prof%clw(:), mask=ltest))
    ENDIF

    ltest = (prof%clw(:) < clwmin)
    IF (ANY(ltest)) THEN
      err = errorstatus_fatal
      CALL print_info("Input cloud liquid water profile exceeds allowed minimum:", &
        (/clwmin/), PACK(prof%p(:), mask=ltest), PACK(prof%clw(:), mask=ltest))
    ENDIF
    THROWM(err .NE. 0, "some invalid atmospheric cloud liquid water")
  ENDIF

  ! Cloud input profile
  IF (opts%rt_ir%addclouds) THEN
    IF (.NOT. ASSOCIATED(prof%cfrac)) THEN
      err = errorstatus_fatal
      msg = "profiles structure not allocated for clouds; "// &
            "opts%rt_ir%addclouds must be true when calling rttov_alloc_prof"
      THROWM(err .NE. 0, msg)
    ENDIF

    IF (ANY( prof%cfrac(:) > 1._jprb ) .OR. &
        ANY( prof%cfrac(:) < 0._jprb )) THEN
      err = errorstatus_fatal
      THROWM(err .NE. 0, "some invalid cloud profile fraction (cfrac) (must be in [0,1])")
    ENDIF

    IF (.NOT. opts%rt_ir%user_cld_opt_param) THEN

      IF (prof%clw_scheme < 1_jpim .OR. prof%clw_scheme > nclw_scheme) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid clw_scheme")
      ENDIF

      IF (prof%clw_scheme == clw_scheme_deff) THEN
        IF (ANY( prof%clwde(:) < 0._jprb )) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "some invalid cloud liquid water effective diameter (must be >=0)")
        ENDIF
      ENDIF

      IF (prof%ice_scheme < 1_jpim .OR. prof%ice_scheme > nice_scheme) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "invalid ice_scheme")
      ENDIF

      IF (prof%ice_scheme == ice_scheme_ssec) THEN
        IF (prof%idg < 1_jpim .OR. prof%idg > nidg) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "invalid ice effective diameter parameterisation (idg)")
        ENDIF

        IF (ANY( prof%icede(:) < 0._jprb )) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "some invalid ice effective diameter (must be >=0)")
        ENDIF
      ENDIF

      IF (ANY( prof%cloud(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid cloud concentration (must be >=0)")
      ENDIF

      ! Check scattering coefficient files support selected optical properties
      IF (prof%clw_scheme == clw_scheme_deff .AND. &
          coefs%coef_scatt_ir%fmv_wcldeff_chn == 0) THEN
        err = errorstatus_fatal
        msg = 'Deff clw_scheme optical properties are not present in sccld file'
        THROWM(err.NE.0, msg)
      ENDIF
      IF (opts%rt_ir%addsolar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_mfasis) THEN
        ! Check consistency of cloud liquid and ice water schemes in LUT and profiles
        IF (prof%clw_scheme /= coefs%coef_mfasis_cld%clw_scheme) THEN
          err = errorstatus_fatal
          THROWM(err.NE.0, 'Different clw_scheme in MFASIS LUT and profiles')
        ENDIF
        IF (prof%ice_scheme /= coefs%coef_mfasis_cld%ice_scheme) THEN
          err = errorstatus_fatal
          THROWM(err.NE.0, 'Different ice_scheme in MFASIS LUT and profiles')
        ENDIF
      ENDIF

      IF (opts%rt_ir%pc%addpc .AND. coefs%coef_pccomp%fmv_pc_cld /= 0) THEN
        IF (ANY( prof%cloud(wcl_id_stco,:) > 0._jprb ) .OR. &
            ANY( prof%cloud(wcl_id_cucc,:) > 0._jprb ) .OR. &
            ANY( prof%cloud(wcl_id_cucp,:) > 0._jprb )) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "only maritime water cloud types are allowed for cloudy PC-RTTOV")
        ENDIF
      ENDIF

    ELSE IF (PRESENT(cld_opt_param)) THEN

      IF (ANY( cld_opt_param%abs(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid cloud absorption coefficient (must be >=0)")
      ENDIF

      IF (ANY( cld_opt_param%sca(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid cloud scattering coefficient (must be >=0)")
      ENDIF

      IF (ANY( cld_opt_param%bpr(:,:) < 0._jprb ) .OR. &
          ANY( cld_opt_param%bpr(:,:) > 1._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid cloud bpr coefficient (must be in [0,1])")
      ENDIF

    ENDIF

  ENDIF

  ! Aerosol input profile
  IF (opts%rt_ir%addaerosl) THEN

    IF (.NOT. opts%rt_ir%user_aer_opt_param) THEN

      IF (.NOT. ASSOCIATED(prof%aerosols)) THEN
        err = errorstatus_fatal
        msg = "profiles structure not allocated for aerosols; " // &
              "opts%rt_ir%addaerosl must be true when calling rttov_alloc_prof"
        THROWM(err .NE. 0, msg)
      ENDIF

      IF (ANY( prof%aerosols(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid aerosol concentration (must be >=0)")
      ENDIF

      IF (opts%rt_ir%pc%addpc .AND. coefs%coef_pccomp%fmv_pc_aer /= 0) THEN
        IF (coefs%coef_scatt_ir%fmv_aer_comp /= naer_opac) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "PC-RTTOV must be used with an RTTOV OPAC aerosol optical property file")
        ENDIF
        IF (ANY(prof%aerosols(coefs%coef_pccomp%fmv_pc_naer_types+1:,:) > 0._jprb)) THEN
          err = errorstatus_fatal
          THROWM(err .NE. 0, "only OPAC aerosol components are allowed for PC-RTTOV aerosol simulations")
        ENDIF
      ENDIF

    ELSE IF (PRESENT(aer_opt_param)) THEN

      IF (ANY( aer_opt_param%abs(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid aerosol absorption coefficient (must be >=0)")
      ENDIF

      IF (ANY( aer_opt_param%sca(:,:) < 0._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid aerosol scattering coefficient (must be >=0)")
      ENDIF

      IF (ANY( aer_opt_param%bpr(:,:) < 0._jprb ) .OR. &
          ANY( aer_opt_param%bpr(:,:) > 1._jprb )) THEN
        err = errorstatus_fatal
        THROWM(err .NE. 0, "some invalid aerosol bpr coefficient (must be in [0,1])")
      ENDIF

    ENDIF

  ENDIF


  !---------------------------------
  ! Check against regression limits
  !---------------------------------

  ! Check cloud values for both PC and non-PC simulations

  IF (opts%config%verbose .OR. PRESENT(reg_limits_exceeded)) THEN

    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN
      DO ilay = 1, firstlevel-1

        IF (prof%clw_scheme == clw_scheme_deff) THEN
          IF (ANY(prof%cloud(1:5,ilay) > 0._jprb)) THEN
            IF (prof%clwde(ilay) > 0._jprb) THEN
              IF (prof%clwde(ilay) < dgmin_clw) THEN
                reg_limits_warn = .TRUE.
                IF (opts%config%verbose) THEN
                  CALL print_info_lev("CLW effective diameter profile exceeds lower coef limit", ilay, &
                       dgmin_clw, prof%p(ilay), prof%clwde(ilay), .FALSE._jplm, .FALSE._jplm)
                ENDIF
              ENDIF
              IF (prof%clwde(ilay) > dgmax_clw) THEN
                reg_limits_warn = .TRUE.
                IF (opts%config%verbose) THEN
                  CALL print_info_lev("CLW effective diameter profile exceeds upper coef limit", ilay, &
                       dgmax_clw, prof%p(ilay), prof%clwde(ilay), .FALSE._jplm, .FALSE._jplm)
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        ENDIF

        IF (prof%cloud(6_jpim,ilay) > 0._jprb) THEN

          IF (prof%ice_scheme == ice_scheme_ssec) THEN
            iwcmax = iwcmax_ssec
          ELSE IF (prof%ice_scheme == ice_scheme_baran .OR. prof%ice_scheme == ice_scheme_baran2018) THEN
            iwcmax = baran2018_iwc_max
          ELSE
            CYCLE
          ENDIF

          IF (prof_int(1)%cloud(6_jpim,ilay) > iwcmax) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Ice water content profile exceeds upper coef limit", ilay, &
                  iwcmax, prof%p(ilay), prof_int(1)%cloud(6_jpim,ilay), .FALSE._jplm, .TRUE._jplm)
            ENDIF
          ENDIF

          IF (prof%ice_scheme == ice_scheme_baran .OR. prof%ice_scheme == ice_scheme_baran2018) THEN
            IF (prof%t(ilay) < baran2018_temp_min) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("Temperature profile exceeds lower coef limit for Baran parameterization", ilay, &
                     baran2018_temp_min, prof%p(ilay), prof%t(ilay), .FALSE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
            IF (prof%t(ilay) > baran2018_temp_max) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("Temperature profile exceeds upper coef limit for Baran parameterization", ilay, &
                     baran2018_temp_max, prof%p(ilay), prof%t(ilay), .FALSE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
          ELSEIF (prof%ice_scheme == ice_scheme_ssec) THEN
            IF (prof%icede(ilay) > 0._jprb) THEN
              IF (prof%icede(ilay) < dgmin_ssec) THEN
                reg_limits_warn = .TRUE.
                IF (opts%config%verbose) THEN
                  CALL print_info_lev("Ice effective diameter profile exceeds lower coef limit", ilay, &
                       dgmin_ssec, prof%p(ilay), prof%icede(ilay), .FALSE._jplm, .FALSE._jplm)
                ENDIF
              ENDIF
              IF (prof%icede(ilay) > dgmax_ssec) THEN
                reg_limits_warn = .TRUE.
                IF (opts%config%verbose) THEN
                  CALL print_info_lev("Ice effective diameter profile exceeds upper coef limit", ilay, &
                       dgmax_ssec, prof%p(ilay), prof%icede(ilay), .FALSE._jplm, .FALSE._jplm)
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        ENDIF

      ENDDO
    ENDIF ! clouds

  ENDIF ! verbose or warn reg limits

  ! Check profiles against non-PC or PC limits

  IF (.NOT. opts%rt_ir%pc%addpc) THEN

    IF (opts%config%verbose .OR. PRESENT(reg_limits_exceeded)) THEN

      jlev = 1
      DO ilev = 1, firstlevel
        ! Check for user levels above the top coefficient level
        OK = NINT(prof%p(ilev)*1000) < NINT(coefs%coef%lim_prfl_p(1)*1000)

        ! recherche des niveaux RTTOV qui encadrent le niveau user, les pressions sont
        ! arondies à 0.1Pa
        IF (.NOT. OK .AND. jlev < coefs%coef%nlevels) THEN
          OK =  NINT(prof%p(ilev)*1000) >= NINT(coefs%coef%lim_prfl_p(jlev)*1000)   .AND. &
                NINT(prof%p(ilev)*1000) <  NINT(coefs%coef%lim_prfl_p(jlev+1)*1000)
        ENDIF

        DO WHILE (.NOT. OK .AND. jlev < coefs%coef%nlevels)
          jlev = jlev+1
          IF (jlev < coefs%coef%nlevels) THEN
            OK =  NINT(prof%p(ilev)*1000) >= NINT(coefs%coef%lim_prfl_p(jlev)*1000)   .AND. &
                  NINT(prof%p(ilev)*1000) <  NINT(coefs%coef%lim_prfl_p(jlev+1)*1000)
          ELSE
            ! on est sur le dernier niveau des fichiers de coefs
            OK =  .TRUE.
          ENDIF
        ENDDO

        IF (prof%t(ilev) > coefs%coef%lim_prfl_tmax(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("Input temperature profile exceeds upper coef limit", ilev, &
              coefs%coef%lim_prfl_tmax(jlev), prof%p(ilev), prof%t(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (prof%t(ilev) < coefs%coef%lim_prfl_tmin(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("Input temperature profile exceeds lower coef limit", ilev, &
              coefs%coef%lim_prfl_tmin(jlev), prof%p(ilev), prof%t(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        ig = coefs%coef%fmv_gas_pos( gas_id_watervapour )
        IF (prof_int(1)%q(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("Input water vapour profile exceeds upper coef limit", ilev, &
              coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%q(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (prof_int(1)%q(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("Input water vapour profile exceeds lower coef limit", ilev, &
              coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%q(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (opts%rt_ir%ozone_data .AND. coefs%coef%nozone > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_ozone )
          IF (prof_int(1)%o3(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input ozone profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%o3(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%o3(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input ozone profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%o3(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (opts%rt_ir%co2_data .AND. coefs%coef%nco2 > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_co2 )
          IF (prof_int(1)%co2(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CO2 profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%co2(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%co2(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CO2 profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%co2(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (opts%rt_ir%co_data .AND. coefs%coef%nco > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_co )
          IF (prof_int(1)%co(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CO profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%co(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%co(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CO profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%co(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (opts%rt_ir%n2o_data .AND. coefs%coef%nn2o > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_n2o )
          IF (prof_int(1)%n2o(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input N2O profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%n2o(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%n2o(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input N2O profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%n2o(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (opts%rt_ir%ch4_data .AND. coefs%coef%nch4 > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_ch4 )
          IF (prof_int(1)%ch4(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CH4 profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%ch4(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%ch4(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input CH4 profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%ch4(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (opts%rt_ir%so2_data .AND. coefs%coef%nso2 > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_so2 )
          IF (prof_int(1)%so2(ilev) > coefs%coef%lim_prfl_gmax(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input SO2 profile exceeds upper coef limit", ilev, &
                coefs%coef%lim_prfl_gmax(jlev, ig), prof%p(ilev), prof_int(1)%so2(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%so2(ilev) < coefs%coef%lim_prfl_gmin(jlev, ig)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("Input SO2 profile exceeds lower coef limit", ilev, &
                coefs%coef%lim_prfl_gmin(jlev, ig), prof%p(ilev), prof_int(1)%so2(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF
      ENDDO
    ENDIF ! verbose or warn reg limits

  ELSE IF (opts%rt_ir%pc%addpc) THEN

    IF (opts%config%verbose .OR. PRESENT(reg_limits_exceeded)) THEN

      IF ((prof%s2m%p < coefs%coef_pccomp%lim_pc_prfl_pmin) .OR. &
          (prof%s2m%p > coefs%coef_pccomp%lim_pc_prfl_pmax)) THEN
        reg_limits_warn = .TRUE.
        IF (opts%config%verbose) THEN
          WARN("PC-RTTOV: surface pressure outside limits")
        ENDIF
      ENDIF

      IF ((prof%s2m%t < coefs%coef_pccomp%lim_pc_prfl_tsmin) .OR. &
          (prof%s2m%t > coefs%coef_pccomp%lim_pc_prfl_tsmax)) THEN
        reg_limits_warn = .TRUE.
        IF (opts%config%verbose) THEN
          WARN("PC-RTTOV: surface temperature outside limits")
        ENDIF
      ENDIF

      IF ((prof%skin%t < coefs%coef_pccomp%lim_pc_prfl_skmin) .OR. &
          (prof%skin%t > coefs%coef_pccomp%lim_pc_prfl_skmax)) THEN
        reg_limits_warn = .TRUE.
        IF (opts%config%verbose) THEN
          WARN("PC-RTTOV: skin temperature outside limits")
        ENDIF
      ENDIF

      wind = SQRT(&
           prof%s2m%u * prof%s2m%u + &
           prof%s2m%v * prof%s2m%v   )

      IF ((wind < coefs%coef_pccomp%lim_pc_prfl_wsmin) .OR. &
          (wind > coefs%coef_pccomp%lim_pc_prfl_wsmax)) THEN
        reg_limits_warn = .TRUE.
        IF (opts%config%verbose) THEN
          WARN("PC-RTTOV: 10m wind speed outside limits")
        ENDIF
      ENDIF


      jlev = 1
      DO ilev = 1, firstlevel
        ! Check for user levels above the top coefficient level
        OK = NINT(prof%p(ilev)*1000) < NINT(coefs%coef%lim_prfl_p(1)*1000)

        ! recherche des niveaux RTTOV qui encadrent le niveau user, les pressions sont
        ! arondies à 0.1Pa
        IF (.NOT. OK .AND. jlev < coefs%coef%nlevels) THEN
          OK =  NINT(prof%p(ilev)*1000) >= NINT(coefs%coef%lim_prfl_p(jlev)*1000)   .AND. &
                NINT(prof%p(ilev)*1000) <  NINT(coefs%coef%lim_prfl_p(jlev+1)*1000)
        ENDIF

        DO WHILE (.NOT. OK .AND. jlev < coefs%coef%nlevels)
          jlev = jlev+1
          IF (jlev < coefs%coef%nlevels) THEN
            OK =  NINT(prof%p(ilev)*1000) >= NINT(coefs%coef%lim_prfl_p(jlev)*1000)   .AND. &
                  NINT(prof%p(ilev)*1000) <  NINT(coefs%coef%lim_prfl_p(jlev+1)*1000)
          ELSE
            ! on est sur le dernier niveau des fichiers de coefs
            OK =  .TRUE.
          ENDIF
        ENDDO

        IF (prof%t(ilev) > coefs%coef_pccomp%lim_pc_prfl_tmax(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("PC-RTTOV: Input temperature profile exceeds upper coef limit", ilev, &
              coefs%coef_pccomp%lim_pc_prfl_tmax(jlev), prof%p(ilev), prof%t(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (prof%t(ilev) < coefs%coef_pccomp%lim_pc_prfl_tmin(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("PC-RTTOV: Input temperature profile exceeds lower coef limit", ilev, &
              coefs%coef_pccomp%lim_pc_prfl_tmin(jlev), prof%p(ilev), prof%t(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        ig = coefs%coef%fmv_gas_pos( gas_id_watervapour )
        IF (prof_int(1)%q(ilev) > coefs%coef_pccomp%lim_pc_prfl_qmax(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("PC-RTTOV: Input water vapour profile exceeds upper coef limit", ilev, &
              coefs%coef_pccomp%lim_pc_prfl_qmax(jlev), prof%p(ilev), prof_int(1)%q(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (prof_int(1)%q(ilev) < coefs%coef_pccomp%lim_pc_prfl_qmin(jlev)) THEN
          reg_limits_warn = .TRUE.
          IF (opts%config%verbose) THEN
            CALL print_info_lev("PC-RTTOV: Input water vapour profile exceeds lower coef limit", ilev, &
              coefs%coef_pccomp%lim_pc_prfl_qmin(jlev), prof%p(ilev), prof_int(1)%q(ilev), .TRUE._jplm, .FALSE._jplm)
          ENDIF
        ENDIF

        IF (opts%rt_ir%ozone_data .AND. coefs%coef%nozone > 0) THEN
          ig = coefs%coef%fmv_gas_pos( gas_id_ozone )
          IF (prof_int(1)%o3(ilev) > coefs%coef_pccomp%lim_pc_prfl_ozmax(jlev)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("PC-RTTOV: Input ozone profile exceeds upper coef limit", ilev, &
                coefs%coef_pccomp%lim_pc_prfl_ozmax(jlev), prof%p(ilev), prof_int(1)%o3(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF

          IF (prof_int(1)%o3(ilev) < coefs%coef_pccomp%lim_pc_prfl_ozmin(jlev)) THEN
            reg_limits_warn = .TRUE.
            IF (opts%config%verbose) THEN
              CALL print_info_lev("PC-RTTOV: Input ozone profile exceeds lower coef limit", ilev, &
                coefs%coef_pccomp%lim_pc_prfl_ozmin(jlev), prof%p(ilev), prof_int(1)%o3(ilev), .TRUE._jplm, .FALSE._jplm)
            ENDIF
          ENDIF
        ENDIF

        IF (coefs%coef_pccomp%fmv_pc_comp_pc >= 5) THEN

          IF (opts%rt_ir%co2_data .AND. coefs%coef%nco2 > 0) THEN
            IF (prof_int(1)%co2(ilev) > coefs%coef_pccomp%co2_pc_max(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CO2 profile exceeds upper coef limit", ilev, &
                  coefs%coef_pccomp%co2_pc_max(jlev), prof%p(ilev), prof_int(1)%co2(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF

            IF (prof_int(1)%co2(ilev) < coefs%coef_pccomp%co2_pc_min(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CO2 profile exceeds lower coef limit", ilev, &
                  coefs%coef_pccomp%co2_pc_min(jlev), prof%p(ilev), prof_int(1)%co2(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
          ENDIF

          IF (opts%rt_ir%n2o_data .AND. coefs%coef%nn2o > 0) THEN
            IF (prof_int(1)%n2o(ilev) > coefs%coef_pccomp%n2o_pc_max(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input N2O profile exceeds upper coef limit", ilev, &
                  coefs%coef_pccomp%n2o_pc_max(jlev), prof%p(ilev), prof_int(1)%n2o(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF

            IF (prof_int(1)%n2o(ilev) < coefs%coef_pccomp%n2o_pc_min(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input N2O profile exceeds lower coef limit", ilev, &
                  coefs%coef_pccomp%n2o_pc_min(jlev), prof%p(ilev), prof_int(1)%n2o(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
          ENDIF

          IF (opts%rt_ir%co_data .AND. coefs%coef%nco > 0) THEN
            IF (prof_int(1)%co(ilev) > coefs%coef_pccomp%co_pc_max(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CO profile exceeds upper coef limit", ilev, &
                  coefs%coef_pccomp%co_pc_max(jlev), prof%p(ilev), prof_int(1)%co(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF

            IF (prof_int(1)%co(ilev) < coefs%coef_pccomp%co_pc_min(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CO profile exceeds lower coef limit", ilev, &
                  coefs%coef_pccomp%co_pc_min(jlev), prof%p(ilev), prof_int(1)%co(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
          ENDIF

          IF (opts%rt_ir%ch4_data .AND. coefs%coef%nch4 > 0) THEN
            IF (prof_int(1)%ch4(ilev) > coefs%coef_pccomp%ch4_pc_max(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CH4 profile exceeds upper coef limit", ilev, &
                  coefs%coef_pccomp%ch4_pc_max(jlev), prof%p(ilev), prof_int(1)%ch4(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF

            IF (prof_int(1)%ch4(ilev) < coefs%coef_pccomp%ch4_pc_min(jlev)) THEN
              reg_limits_warn = .TRUE.
              IF (opts%config%verbose) THEN
                CALL print_info_lev("PC-RTTOV: Input CH4 profile exceeds lower coef limit", ilev, &
                  coefs%coef_pccomp%ch4_pc_min(jlev), prof%p(ilev), prof_int(1)%ch4(ilev), .TRUE._jplm, .FALSE._jplm)
              ENDIF
            ENDIF
          ENDIF

        ENDIF

      ENDDO

      ! Check aerosols against PC reg limits
      IF (opts%rt_ir%addaerosl .AND. coefs%coef_pccomp%fmv_pc_aer /= 0) THEN

        ALLOCATE(aer_min(coefs%coef_pccomp%fmv_pc_naer_types,prof%nlevels), &
                 aer_max(coefs%coef_pccomp%fmv_pc_naer_types,prof%nlevels), STAT=err)
        THROWM(err .NE. 0, "error allocating data")

        aer_min = 0._jprb
        aer_max = 0._jprb

        ! See also rttov_apply_pc_aer_reg_limits.F90
        IF (opts%interpolation%addinterp) THEN
          ! Interpolate aerosol regression limits

          DO lay_user = 1, prof%nlayers
            lev_user_upper = lay_user
            lev_user_lower = lay_user + 1

            ! Ignore user layers which are entirely above the top coef level
            IF (prof%p(lev_user_lower) < coefs%coef_pccomp%ref_pc_prfl_p(1)) CYCLE

            ! Find coef layers which overlap user layer (bounded by lev_coef_upper and lev_coef_lower)
            DO lev_coef_upper = coefs%coef_pccomp%fmv_pc_nlev-1, 2, -1
              ! Starting at the bottom of the profile, the upper coef level is the first one
              ! above (or equal to) the upper user pressure level (or failing that it's just the
              ! top level)
              IF (coefs%coef_pccomp%ref_pc_prfl_p(lev_coef_upper) <= prof%p(lev_user_upper)) EXIT
            ENDDO

            DO lev_coef_lower = lev_coef_upper+1, coefs%coef_pccomp%fmv_pc_nlev-1
              ! Starting at the top of the profile, the lower coef level is the first one
              ! below (or equal to) the lower user pressure level (or failing that it's just the
              ! bottom level)
              IF (coefs%coef_pccomp%ref_pc_prfl_p(lev_coef_lower) >= prof%p(lev_user_lower)) EXIT
            ENDDO

            ! Set user-layer limits based on limits from overlapping coef layers
            DO t = 1, coefs%coef_pccomp%fmv_pc_naer_types
              ! Most generous limit from overlapping layers (smallest min, largest max)
              aer_min(t,lay_user) = MINVAL(coefs%coef_pccomp%lim_pc_prfl_aermin(t,lev_coef_upper:lev_coef_lower-1))
              aer_max(t,lay_user) = MAXVAL(coefs%coef_pccomp%lim_pc_prfl_aermax(t,lev_coef_upper:lev_coef_lower-1))
            ENDDO

          ENDDO ! user layers

        ELSE
          aer_min(:,:) = coefs%coef_pccomp%lim_pc_prfl_aermin
          aer_max(:,:) = coefs%coef_pccomp%lim_pc_prfl_aermax
        ENDIF

        DO ilay = 1, prof%nlayers
          ! If the level bounding the top of the layer is not above the surface then
          ! this layer does not contribute to TOA radiance so we ignore it
          IF (prof%p(ilay) >= prof%s2m%p) CYCLE

          ! Only check components included in PC training
          DO t = 1, coefs%coef_pccomp%fmv_pc_naer_types

            IF (aer_min(t,ilay) == aer_max(t,ilay)) THEN

              ! Don't flag if there was no variability in the training data
              CYCLE

            ELSE IF (prof_int(1)%aerosols(t,ilay) < aer_min(t,ilay)) THEN

              IF (opts%config%verbose) THEN
                WRITE(msg,'(A,I2,A)') "PC-RTTOV: Input aerosol ", t, " profile exceeds lower coef limit"
                CALL print_info_lev(TRIM(msg), ilay, &
                  aer_min(t,ilay), prof%p(ilay), prof_int(1)%aerosols(t,ilay), .FALSE._jplm, .FALSE._jplm)
              ENDIF
              reg_limits_warn = .TRUE.

            ELSE IF (prof_int(1)%aerosols(t,ilay) > aer_max(t,ilay)) THEN

              IF (opts%config%verbose) THEN
                WRITE(msg,'(A,I2,A)') "PC-RTTOV: Input aerosol ", t, " profile exceeds upper coef limit"
                CALL print_info_lev(TRIM(msg), ilay, &
                  aer_max(t,ilay), prof%p(ilay), prof_int(1)%aerosols(t,ilay), .FALSE._jplm, .FALSE._jplm)
              ENDIF
              reg_limits_warn = .TRUE.

            ENDIF

          ENDDO ! aerosol types
        ENDDO ! layers

        DEALLOCATE(aer_min, aer_max, STAT=err)
        THROWM(err .NE. 0, "error deallocating data")
      ENDIF

    ENDIF ! verbose or warn reg limits

  ENDIF

  CALL rttov_alloc_prof_internal(err, prof_int, prof%nlevels, opts, coefs, 0_jpim)

  IF (PRESENT(reg_limits_exceeded)) reg_limits_exceeded = reg_limits_warn

IF (LHOOK) CALL DR_HOOK('RTTOV_USER_PROFILE_CHECKINPUT',1_jpim,ZHOOK_HANDLE)
CATCH
IF (LHOOK) CALL DR_HOOK('RTTOV_USER_PROFILE_CHECKINPUT',1_jpim,ZHOOK_HANDLE)

CONTAINS

  SUBROUTINE print_info(msg1, limits, levels, values)
    CHARACTER(LEN=*), INTENT(IN) :: msg1
    REAL(KIND=jprb),  INTENT(IN) :: limits(:)
    REAL(KIND=jprb),  INTENT(IN) :: levels(:)
    REAL(KIND=jprb),  INTENT(IN) :: values(:)

    CHARACTER(LEN=256) :: msg2
    INTEGER(KIND=jpim) :: imax, lmax

    ! Print a maximum of 10 elements of the input arrays. Note limits(:) may be a
    ! single element array for hard limits so check size of this separately
    imax = MIN(10, SIZE(levels))
    lmax = MIN(imax, SIZE(limits))
    WARN(msg1)
    WRITE(msg2, '(a,10g11.4)') 'Limit   = ',limits(1:lmax)
    INFO(TRIM(msg2))
    WRITE(msg2, '(a,10f11.4)') 'p (hPa) = ',levels(1:imax)
    INFO(TRIM(msg2))
    WRITE(msg2, '(a,10g11.4)') 'Value   = ',values(1:imax)
    INFO(TRIM(msg2))
  END SUBROUTINE print_info

  SUBROUTINE print_info_lev(msg1, ilevel, limit, p, value, llevel, small)
    CHARACTER(LEN=*),   INTENT(IN) :: msg1    ! General warning message to print out
    INTEGER(KIND=jpim), INTENT(IN) :: ilevel  ! Level or layer index
    REAL(KIND=jprb),    INTENT(IN) :: limit   ! Limit value
    REAL(KIND=jprb),    INTENT(IN) :: p       ! Pressure of level
    REAL(KIND=jprb),    INTENT(IN) :: value   ! Input profile value
    LOGICAL(KIND=jplm), INTENT(IN) :: llevel  ! True/false for level/layer quantities resp.
    LOGICAL(KIND=jplm), INTENT(IN) :: small   ! True if profile values are small numbers

    CHARACTER(LEN=32)  :: s
    CHARACTER(LEN=256) :: msg2

    ! Append level/layer number to input message
    IF (llevel) THEN
      WRITE(s, '(" (level number = ",I4,")")') ilevel
    ELSE
      WRITE(s, '(" (layer number = ",I4,")")') ilevel
    ENDIF
    WARN(msg1//TRIM(s))

    ! Format the limit/pressure/value according to input logical small
    IF (small) THEN
      WRITE(msg2, '((a,e12.5,", "),(a,f10.4,", "),(a,e12.5,", "))') &
        'Limit   = ', limit, 'p (hPa) = ', p, 'Value   = ',value
    ELSE
      WRITE(msg2, '(3(a,f10.4,", "))') &
        'Limit   = ', limit, 'p (hPa) = ', p, 'Value   = ',value
    ENDIF
    INFO(TRIM(msg2))
  END SUBROUTINE print_info_lev

END SUBROUTINE rttov_user_profile_checkinput
