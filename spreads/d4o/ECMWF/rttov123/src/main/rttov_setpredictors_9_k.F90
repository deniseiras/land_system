! Description:
!> @file
!!   Jacobian of v9 predictor calculation.
!!
!> @brief
!!   Jacobian of v9 predictor calculation.
!!
!! @param[in]     opts            RTTOV options
!! @param[in]     chanprof        specifies channels and profiles to simulate
!! @param[in]     nlayers         number of coefficient layers
!! @param[in]     prof            profiles on coefficient levels
!! @param[in,out] prof_k          profile increments on coefficient levels
!! @param[in]     ray_path        raytracing path array
!! @param[in,out] ray_path_k      raytracing path array increments
!! @param[in]     coef_pccomp     PC coefficients structure
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_k    predictor increments
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
SUBROUTINE rttov_setpredictors_9_k( &
              opts,         &
              chanprof,     &
              nlayers,      &
              prof,         &
              prof_k,       &
              ray_path,     &
              ray_path_k,   &
              coef_pccomp,  &
              coef,         &
              aux,          &
              predictors,   &
              predictors_k)

  USE rttov_types, ONLY : &
       rttov_chanprof,    &
       rttov_coef,        &
       rttov_options,     &
       rttov_coef_pccomp, &
       rttov_profile,     &
       rttov_profile_aux, &
       rttov_path_pred
  USE parkind1, ONLY : jpim, jprb
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE rttov_const, ONLY : gas_id_so2
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options)     , INTENT(IN)    :: opts
  TYPE(rttov_chanprof)    , INTENT(IN)    :: chanprof(:)
  INTEGER(KIND=jpim)      , INTENT(IN)    :: nlayers
  TYPE(rttov_profile)     , INTENT(IN)    :: prof(:)
  TYPE(rttov_profile)     , INTENT(INOUT) :: prof_k(SIZE(chanprof))
  REAL(jprb)              , INTENT(IN)    :: ray_path(prof(1)%nlayers,SIZE(prof))
  REAL(jprb)              , INTENT(INOUT) :: ray_path_k(prof(1)%nlayers,SIZE(chanprof))
  TYPE(rttov_coef_pccomp) , INTENT(IN)    :: coef_pccomp
  TYPE(rttov_coef)        , INTENT(IN)    :: coef
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_k(:)
!INTF_END

  INTEGER(KIND=jpim) :: level, layer, n, i, j, iv2lev, iv3lev, iv2lay
! user profile
  REAL   (KIND=jprb) :: t(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: w(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: o(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: co2  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: co   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: n2o  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ch4  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: so2  (nlayers, SIZE(prof))
! reference profile
  REAL   (KIND=jprb) :: tr   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: tro  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: wr   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: or   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: co2r (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: n2or (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: cor  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ch4r (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: so2r (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: wwr  (nlayers, SIZE(prof))
! user - reference
  REAL   (KIND=jprb) :: dt   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: dto  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: dtabs(nlayers, SIZE(prof))
! pressure weighted
  REAL   (KIND=jprb) :: tw   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: twr  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: tuw  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: tuwr (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ww   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ow   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: co2w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: n2ow (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: cow  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ch4w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: so2w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: n2owr(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: cowr (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: ch4wr(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: so2wr(nlayers, SIZE(prof))
! intermediate variables
  REAL   (KIND=jprb) :: sum1, sum2
  REAL   (KIND=jprb) :: sum2_ww   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_wwr  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_ow   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_twr  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_tuw  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_co2w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_ch4w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_ch4wr(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_so2w (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_so2wr(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_n2ow (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_n2owr(nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_cow  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sum2_cowr (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: tr_sq     (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: tr_4      (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sec_wrwr  (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sec_wr    (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sec_so2   (nlayers, SIZE(prof))
  REAL   (KIND=jprb) :: sec_so2so2(nlayers, SIZE(prof))

! K variables
  REAL   (KIND=jprb) :: t_k       (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: w_k       (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: o_k       (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: co2_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: n2o_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: co_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ch4_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: so2_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: tr_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: tro_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: wr_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: or_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: wwr_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: co2r_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: n2or_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: cor_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ch4r_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: so2r_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: twr_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: tuw_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: tuwr_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: dt_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: dto_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: tw_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ww_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ow_k      (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: co2w_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: n2ow_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: cow_k     (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ch4w_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: so2w_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: n2owr_k   (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: cowr_k    (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: ch4wr_k   (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: so2wr_k   (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: sec_or_k  (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: sec_wr_k  (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: sec_wrwr_k(nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: sec_so2_k   (nlayers, SIZE(chanprof))
  REAL   (KIND=jprb) :: sec_so2so2_k(nlayers, SIZE(chanprof))

! John.Hague@ecmwf.int optimisation start
  Real(Kind=jprb) :: tmp1(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp2(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp3(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp4(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp5(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp6(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp7(nlayers,SIZE(prof))
  Real(Kind=jprb) :: tmp8(nlayers,SIZE(prof))
! optimisation end

  INTEGER(KIND=jpim) :: nprofiles, nchanprof

  REAL   (KIND=jprb) :: ZHOOK_HANDLE

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_K', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nchanprof = SIZE(chanprof)

!  ind = 1
!  IF (.NOT. thermal) ind = 2

!-------------------------------------------------------------------------------
! Recompute Direct variables
!-------------------------------------------------------------------------------
! layer N-1 lies between levels N-1 and N

  DO j = 1, nprofiles
!-------------------------------------------------------------------------------
!1) Profile layer quantities
!-------------------------------------------------------------------------------

    DO layer = 1, prof(j)%nlayers
      level       = layer + 1
!-Temperature--------------------------------------------------------------------
      t(layer, j) = (prof(j)%t(level - 1) + prof(j)%t(level)) / 2._jprb
!-H2O----------------------------------------------------------------------------
      w(layer, j) = (prof(j)%q(level - 1) + prof(j)%q(level)) / 2._jprb
!-O3-----------------------------------------------------------------------------
      IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) &
          o(layer, j) = (prof(j)%o3(level - 1) + prof(j)%o3(level)) / 2._jprb
!-CO2----------------------------------------------------------------------------

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          co2(layer, j) = (coef_pccomp%co2_pc_ref(level - 1) + coef_pccomp%co2_pc_ref(level)) * 0.5_jprb
        ELSE
          co2(layer, j) = (prof(j)%co2(level - 1) + prof(j)%co2(level)) * 0.5_jprb
        ENDIF

      ENDIF

!-N2O----------------------------------------------------------------------------

      IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          n2o(layer, j) = (coef_pccomp%n2o_pc_ref(level - 1) + coef_pccomp%n2o_pc_ref(level)) * 0.5_jprb
        ELSE
          n2o(layer, j) = (prof(j)%n2o(level - 1) + prof(j)%n2o(level)) * 0.5_jprb
        ENDIF

      ENDIF

!-CO-----------------------------------------------------------------------------

      IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          co(layer, j) = (coef_pccomp%co_pc_ref(level - 1) + coef_pccomp%co_pc_ref(level)) * 0.5_jprb
        ELSE
          co(layer, j) = (prof(j)%co(level - 1) + prof(j)%co(level)) * 0.5_jprb
        ENDIF

      ENDIF

!-CH4----------------------------------------------------------------------------

      IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          ch4(layer, j) = (coef_pccomp%ch4_pc_ref(level - 1) + coef_pccomp%ch4_pc_ref(level)) * 0.5_jprb
        ELSE
          ch4(layer, j) = (prof(j)%ch4(level - 1) + prof(j)%ch4(level)) * 0.5_jprb
        ENDIF

      ENDIF

!-SO2----------------------------------------------------------------------------

      IF (coef%nso2 > 0) THEN
        IF (opts%rt_ir%pc%addpc) THEN
!             so2(layer, j) = (coef_pccomp%so2_pc_ref(level - 1) + coef_pccomp%so2_pc_ref(level)) * 0.5_jprb
        ELSE
          IF (opts%rt_ir%so2_data) THEN
            so2(layer, j) = (prof(j)%so2(level - 1) + prof(j)%so2(level)) * 0.5_jprb
          ELSE
            n = coef%fmv_gas_pos(gas_id_so2)
            so2(layer, j) = (coef%bkg_prfl_mr(level - 1,n) + coef%bkg_prfl_mr(level,n)) * 0.5_jprb
          ENDIF
        ENDIF
      ENDIF

    ENDDO

    IF (opts%rt_all%use_q2m) THEN
! include surface humidity
      iv3lev = aux%s(j)%nearestlev_surf - 1
      iv2lev = aux%s(j)%nearestlev_surf

      IF (iv2lev <= coef%nlevels) THEN
        iv2lay = iv2lev - 1
        w(iv2lay, j) = (prof(j)%s2m%q + prof(j)%q(iv3lev)) * 0.5_JPRB
      ENDIF

    ENDIF

!------------------------------------------------------------------------------
!2) calculate deviations from reference profile (layers)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    dt(:, j)      = t(:, j) - coef%tstar(:)
    dtabs(:, j)   = ABS(dt(:, j))
!------------------------------------------------------------------------------
!3) calculate (profile / reference profile) ratios; tr wr or
! if no input O3 profile, set to reference value (or =1)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    tr(:, j)      = t(:, j) / coef%tstar(:)
    tr_sq(:, j)   = tr(:, j) * tr(:, j)
    tr_4(:, j)    = tr_sq(:, j) * tr_sq(:, j)
    wr(:, j)      = w(:, j) / coef%wstar(:)

    IF (coef%nozone > 0) THEN
      dto(:, j) = t(:, j) - coef%to3star(:)
      tro(:, j) = t(:, j) / coef%to3star(:)
      IF (opts%rt_ir%ozone_data) THEN
        or(:, j)  = o(:, j) / coef%ostar(:)
      ELSE
        or(:, j)  = 1._jprb
      ENDIF
    ENDIF

!-CO2----------------------------------------------------------------------------

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      co2r(:, j) = co2(:, j) / coef%co2star(:)
    ELSE
      co2r(:, j) = 1._jprb
    ENDIF

!-N2O----------------------------------------------------------------------------

    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
      n2or(:, j) = n2o(:, j) / coef%n2ostar(:)
    ELSE
      n2or(:, j) = 1._jprb
    ENDIF

!-CO----------------------------------------------------------------------------

    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
      cor(:, j) = co(:, j) / coef%costar(:)
    ELSE
      cor(:, j) = 1._jprb
    ENDIF

!-CH4---------------------------------------------------------------------------

    IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
      ch4r(:, j) = ch4(:, j) / coef%ch4star(:)
    ELSE
      ch4r(:, j) = 1._jprb
    ENDIF

!-SO2--------------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      so2r(:, j) = so2(:, j) / coef%so2star(:)
    ENDIF

!-------------------------------------------------------------------
! 4. calculate profile / reference profile sums: tw wwr
!--------------------------------------------------------------------
    tw(1, j) = 0._jprb

    DO layer = 2, prof(j)%nlayers
      tw(layer, j) = tw(layer - 1, j) + coef%dpp(layer - 1) * tr(layer - 1, j)
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(j)%nlayers
      sum1 = sum1 + t(layer, j)
      sum2 = sum2 + coef%tstar(layer)
      sum2_tuw(layer, j) = sum2
      tuw(layer, j)      = sum1 / sum2
    ENDDO

    tuwr(1, j)                 = coef%dpp(0) * t(1, j) / (coef%dpp(0) * coef%tstar(1))
    tuwr(2:prof(j)%nlayers, j) = tuw(2:prof(j)%nlayers, j)

    IF (coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(j)%nlayers
        sum1 = sum1 + coef%dpp(layer - 1) * t(layer, j)
        sum2 = sum2 + coef%dpp(layer - 1) * coef%tstar(layer)
        sum2_twr(layer, j) = sum2
        twr(layer, j)      = sum1 / sum2
      ENDDO
    ENDIF

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(j)%nlayers
      sum1 = sum1 + coef%dpp(layer - 1) * w(layer, j) * t(layer, j)
      sum2 = sum2 + coef%dpp(layer - 1) * coef%wstar(layer) * coef%tstar(layer)
      sum2_wwr(layer, j) = sum2
      wwr(layer, j)      = sum1 / sum2
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(j)%nlayers
      sum1 = sum1 + coef%dpp(layer - 1) * w(layer, j)
      sum2 = sum2 + coef%dpp(layer - 1) * coef%wstar(layer)
      sum2_ww(layer, j) = sum2
      ww(layer, j)      = sum1 / sum2
    ENDDO


    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(j)%nlayers
        sum1 = sum1 + coef%dpp(layer - 1) * o(layer, j)
        sum2 = sum2 + coef%dpp(layer - 1) * coef%ostar(layer)
        sum2_ow(layer, j) = sum2
        ow(layer, j)      = sum1 / sum2
      ENDDO

    ELSE
      sum2_ow(:, j) = 0._jprb
      ow(:, j)      = 1._jprb
    ENDIF


    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(j)%nlayers
        sum1 = sum1 + coef%dpp(layer - 1) * co2(layer, j)
        sum2 = sum2 + coef%dpp(layer - 1) * coef%co2star(layer)
        sum2_co2w(layer, j) = sum2
        co2w(layer, j)      = sum1 / sum2
      ENDDO

    ELSE
      sum2_co2w(:, j) = 0._jprb
      co2w(:, j)      = 1._jprb
    ENDIF

!-N2O---------------------------------------------------------------------------

    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * n2o(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer)
          sum2_n2ow(layer, j) = sum2
          n2ow(layer, j)      = sum1 / sum2
        ENDDO
  
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * n2o(layer, j) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          sum2_n2owr(layer, j) = sum2
          n2owr(layer, j)      = sum1 / sum2
        ENDDO
  
      ELSE
        sum2_n2ow(:, j)  = 0._jprb
        n2ow(:, j)       = 1._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * coef%n2ostar(layer) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          sum2_n2owr(layer, j) = sum2
          n2owr(layer, j)      = sum1 / sum2
        ENDDO

      ENDIF
    ENDIF

!-CO---------------------------------------------------------------------------

    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * co(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%costar(layer)
          sum2_cow(layer, j) = sum2
          cow(layer, j)      = sum1 / sum2
        ENDDO
  
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * co(layer, j) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          sum2_cowr(layer, j) = sum2
          cowr(layer, j)      = sum1 / sum2
        ENDDO
  
      ELSE
        sum2_cow(:, j)  = 0._jprb
        cow(:, j)       = 1._jprb
        
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * coef%costar(layer) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          sum2_cowr(layer, j) = sum2
          cowr(layer, j)      = sum1 / sum2
        ENDDO        
      ENDIF
    ENDIF
    
!-CH4---------------------------------------------------------------------------

    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * ch4(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer)
          sum2_ch4w(layer, j) = sum2
          ch4w(layer, j)      = sum1 / sum2
        ENDDO
  
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * ch4(layer, j) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          sum2_ch4wr(layer, j) = sum2
          ch4wr(layer, j)      = sum1 / sum2
        ENDDO
  
      ELSE
        sum2_ch4w(:, j)  = 0._jprb
        ch4w(:, j)       = 1._jprb
        
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(j)%nlayers
          sum1 = sum1 + coef%dpp(layer - 1) * coef%ch4star(layer) * t(layer, j)
          sum2 = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          sum2_ch4wr(layer, j) = sum2
          ch4wr(layer, j)      = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF

!-SO2---------------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(j)%nlayers
        sum1 = sum1 + coef%dpp(layer - 1) * so2(layer, j)
        sum2 = sum2 + coef%dpp(layer - 1) * coef%so2star(layer)
        sum2_so2w(layer, j) = sum2
        so2w(layer, j)      = sum1 / sum2
      ENDDO

      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(j)%nlayers
        sum1 = sum1 + coef%dpp(layer - 1) * so2(layer, j) * t(layer, j)
        sum2 = sum2 + coef%dpp(layer - 1) * coef%so2star(layer) * coef%tstar(layer)
        sum2_so2wr(layer, j) = sum2
        so2wr(layer, j)      = sum1 / sum2
      ENDDO
    ENDIF

  ENDDO
! Loop on profiles
!-------------------------------------------------------------------------
! K code
!-------------------------------------------------------------------------
  w_k(:,:)        = 0._jprb
  wr_k(:,:)       = 0._jprb
  ww_k(:,:)       = 0._jprb
  wwr_k(:,:)      = 0._jprb
  sec_wr_k(:,:)   = 0._jprb
  sec_wrwr_k(:,:) = 0._jprb
  dt_k(:,:)       = 0._jprb
  dto_k(:,:)      = 0._jprb
  t_k(:,:)        = 0._jprb
  tr_k(:,:)       = 0._jprb
  tro_k(:,:)      = 0._jprb
  tw_k(:,:)       = 0._jprb
  twr_k(:,:)      = 0._jprb
  o_k(:,:)        = 0._jprb
  or_k(:,:)       = 0._jprb
  ow_k(:,:)       = 0._jprb
  sec_or_k(:,:)   = 0._jprb
  tuw_k(:,:)      = 0._jprb
  tuwr_k(:,:)     = 0._jprb
  ch4_k(:,:)      = 0._jprb
  ch4r_k(:,:)     = 0._jprb
  ch4w_k(:,:)     = 0._jprb
  ch4wr_k(:,:)    = 0._jprb
  so2_k(:,:)      = 0._jprb
  so2r_k(:,:)     = 0._jprb
  so2w_k(:,:)     = 0._jprb
  so2wr_k(:,:)    = 0._jprb
  sec_so2_k(:,:)  = 0._jprb
  sec_so2so2_k(:,:) = 0._jprb
  co_k(:,:)       = 0._jprb
  cor_k(:,:)      = 0._jprb
  cow_k(:,:)      = 0._jprb
  cowr_k(:,:)     = 0._jprb
  n2o_k(:,:)      = 0._jprb
  n2or_k(:,:)     = 0._jprb
  n2ow_k(:,:)     = 0._jprb
  n2owr_k(:,:)    = 0._jprb
  co2_k(:,:)      = 0._jprb
  co2r_k(:,:)     = 0._jprb
  co2w_k(:,:)     = 0._jprb

!-------------------------------------------------
!    so2
!-------------------------------------------------
!

  IF (coef%nso2 == 19) THEN
!---------------------------------
! John.Hague@ecmwf.int optimisation start
    DO j = 1, nprofiles
      DO layer = 1,prof_k(1) % nlayers
        tmp1(layer,j)=predictors(j)%so2(7,layer)**1.5_jprb
        tmp2(layer,j)=0.5_jprb*so2r(layer,j)**1.5_jprb/ray_path(layer,j)**0.5_jprb
        tmp3(layer,j)=1.25_jprb*so2w(layer,j)* (predictors(j)%so2(2,layer))**0.25_jprb
        tmp4(layer,j)=0.5_jprb/SQRT(ray_path(layer,j))*(so2r(layer,j)**1.5_jprb / so2wr(layer,j))
        tmp5(layer,j)=SQRT(ray_path(layer,j))*1.5_jprb*so2r(layer,j)**0.5_jprb/ so2wr(layer,j)
        tmp6(layer,j)=SQRT(ray_path(layer,j))*so2r(layer,j)**1.5_jprb / so2wr(layer,j)**2_jpim
      ENDDO
    ENDDO
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, prof_k(i)%nlayers
        level = layer + 1
        sec_so2(layer, j)               = ray_path(layer, j) * so2r(layer, j)
        sec_so2so2(layer, j)             = sec_so2(layer, j) * so2r(layer, j)
        so2r_k(layer, i)                 =      &
            so2r_k(layer, i) + predictors_k(i)%so2(19, layer) * 2._jprb * predictors(j)%so2(7, layer) / so2w(layer, j)
        so2w_k(layer, i)                 = so2w_k(layer, i) -                                   &
            predictors_k(i)%so2(19, layer) * predictors(j)%so2(1, layer) /  &
            (ray_path(layer, j) * so2w(layer, j) ** 2_jpim)
        ray_path_k(layer, i) =      &
            ray_path_k(layer, i) + predictors_k(i)%so2(19, layer) * so2r(layer, j) ** 2_jpim / so2w(layer, j)
        dt_k(layer, i)                 =      &
            dt_k(layer, i) + predictors_k(i)%so2(18, layer) * tmp1(layer,j)
        so2r_k(layer, i)                 = so2r_k(layer, i) +                                                                     &
            predictors_k(i)%so2(18, layer) * 1.5_jprb * predictors(j)%so2(5, layer) * ray_path(layer, j) &
             * dt(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(18, layer) * 1.5_jprb * predictors(j)%so2(5, layer) * so2r(layer, j) * dt(layer, j)
        so2r_k(layer, i)                 =      &
            so2r_k(layer, i) + predictors_k(i)%so2(17, layer) * 1.5_jprb * predictors(j)%so2(5, layer)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(17, layer) * tmp2(layer,j)
        so2w_k(layer, i)                 = so2w_k(layer, i) +                                   &
            predictors_k(i)%so2(16, layer) * 1.25_jprb * ray_path(layer, j) *  &
            (predictors(j)%so2(2, layer)) ** 0.25_jprb
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(16, layer) * tmp3(layer,j)
        so2r_k(layer, i)                 = so2r_k(layer, i) +                                  &
            predictors_k(i)%so2(15, layer) * 1.5_jprb * ray_path(layer, j) *  &
            SQRT(predictors(j)%so2(7, layer))
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(15, layer) * 1.5_jprb * so2r(layer, j) * SQRT(predictors(j)%so2(7, layer))
        so2w_k(layer, i)                 = so2w_k(layer, i) +                                  &
            predictors_k(i)%so2(14, layer) * 1.5_jprb * ray_path(layer, j) *  &
            SQRT(predictors(j)%so2(2, layer))
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(14, layer) * 1.5_jprb * so2w(layer, j) * SQRT(predictors(j)%so2(2, layer))
        ray_path_k(layer, i) = ray_path_k(layer, i) +                        &
            predictors_k(i)%so2(13, layer) * tmp4(layer,j)
        so2r_k(layer, i)                 = so2r_k(layer, i) +                                                              &
            predictors_k(i)%so2(13, layer) * tmp5(layer,j)
        so2wr_k(layer, i)                = so2wr_k(layer, i) -                                                            &
            predictors_k(i)%so2(13, layer) * tmp6(layer,j)
        sec_so2so2_k(layer, i)           = sec_so2so2_k(layer, i) + predictors_k(i)%so2(12, layer) / so2wr(layer, j)
        so2wr_k(layer, i)                =      &
            so2wr_k(layer, i) - predictors_k(i)%so2(12, layer) * sec_so2so2(layer, j) / so2wr(layer, j) ** 2_jpim
        dt_k(layer, i)                 =      &
            dt_k(layer, i) + predictors_k(i)%so2(11, layer) * predictors(j)%so2(5, layer)
        sec_so2_k(layer, i)             = sec_so2_k(layer, i) +      &
            0.5_jprb * predictors_k(i)%so2(11, layer) * dt(layer, j) / predictors(j)%so2(5, layer)
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + predictors_k(i)%so2(10, layer) * dtabs(layer, j) * dt(layer, j)
        dt_k(layer, i)                 = dt_k(layer, i) +      &
            2 * predictors_k(i)%so2(10, layer) * predictors(j)%so2(7, layer) * dtabs(layer, j)
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + predictors_k(i)%so2(9, layer) * 4._jprb * predictors(j)%so2(8, layer)
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + 3._jprb * predictors_k(i)%so2(8, layer) * predictors(j)%so2(1, layer)
        sec_so2_k(layer, i)             = sec_so2_k(layer, i) + predictors_k(i)%so2(7, layer)
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + 0.25_jprb * predictors_k(i)%so2(6, layer) / predictors(j)%so2(6, layer) ** 3
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + 0.5_jprb * predictors_k(i)%so2(5, layer) / predictors(j)%so2(5, layer)
        dt_k(layer, i)                 =      &
            dt_k(layer, i) + predictors_k(i)%so2(4, layer) * predictors(j)%so2(7, layer)
        sec_so2_k(layer, i)             = sec_so2_k(layer, i) + predictors_k(i)%so2(4, layer) * dt(layer, j)
        so2w_k(layer, i)                 = so2w_k(layer, i) +      &
            predictors_k(i)%so2(3, layer) * 2._jprb * predictors(j)%so2(2, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
            predictors_k(i)%so2(3, layer) * 2._jprb * predictors(j)%so2(2, layer) * so2w(layer, j)
        so2w_k(layer, i)                 =      &
            so2w_k(layer, i) + predictors_k(i)%so2(2, layer) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
            ray_path_k(layer, i) + predictors_k(i)%so2(2, layer) * so2w(layer, j)
        sec_so2_k(layer, i)             =      &
            sec_so2_k(layer, i) + 2._jprb * predictors_k(i)%so2(1, layer) * predictors(j)%so2(7, layer)
        sec_so2_k(layer, i)             = sec_so2_k(layer, i) + sec_so2so2_k(layer, i) * so2r(layer, j)
        so2r_k(layer, i)                 = so2r_k(layer, i) + sec_so2so2_k(layer, i) * predictors(j)%so2(7, layer)
        so2r_k(layer, i)                 = so2r_k(layer, i) + sec_so2_k(layer, i) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + sec_so2_k(layer, i) * so2r(layer, j)
      ENDDO
    ENDDO
  ENDIF

!-------------------------------------------------
!5.9 ch4            transmittance based on RTIASI
!-------------------------------------------------
!

  IF (coef%nch4 > 0) THEN
! John.Hague@ecmwf.int optimisation start
    Do j = 1, nprofiles
      Do layer = 1,prof_k(1) % nlayers
        tmp1(layer,j) = 1.5_jprb*predictors(j)%ch4(2,layer)/ch4w(layer,j)
        tmp2(layer,j) = predictors(j)%ch4(2,layer)**3_jpim/(ray_path(layer, j)*ch4w(layer,j)**2_jpim)
        tmp3(layer,j) = 0.5_jprb*ch4r(layer,j)**1.5_jprb/(ray_path(layer, j)**0.5_jprb*ch4w(layer,j))
        tmp4(layer,j) = 0.25_jprb / predictors(j)%ch4(6,layer)**3_jpim
        tmp5(layer,j) = 1._jprb / predictors(j)%ch4(2,layer)
      Enddo
    Enddo
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level = layer + 1
        ch4r_k(layer, i)               = ch4r_k(layer, i) + predictors_k(i)%ch4(11, layer) * tmp1(layer,j)
        ch4w_k(layer, i)               = ch4w_k(layer, i) - predictors_k(i)%ch4(11, layer) * tmp2(layer,j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%ch4(11, layer) * tmp3(layer,j)
        ch4w_k(layer, i)               =      &
           ch4w_k(layer, i) + ray_path(layer, j) * predictors_k(i)%ch4(10, layer)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ch4(10, layer) * ch4w(layer, j)
        ch4w_k(layer, i)               = ch4w_k(layer, i) +      &
           predictors_k(i)%ch4(9, layer) * predictors(j)%ch4(10, layer) * 2._jprb * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ch4(9, layer) * 2._jprb * predictors(j)%ch4(10, layer) * ch4w(layer, j)
        ch4wr_k(layer, i)              = ch4wr_k(layer, i) + predictors_k(i)%ch4(8, layer)
        ch4wr_k(layer, i)              =      &
           ch4wr_k(layer, i) + predictors_k(i)%ch4(7, layer) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ch4(7, layer) * ch4wr(layer, j)
        ch4r_k(layer, i)               = ch4r_k(layer, i) + &
           predictors_k(i)%ch4(6, layer) * ray_path(layer, j) * tmp4(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ch4(6, layer) * ch4r(layer, j) * tmp4(layer,j)
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%ch4(5, layer) * ch4r(layer, j)
        ch4r_k(layer, i)               = ch4r_k(layer, i) + predictors_k(i)%ch4(5, layer) * dt(layer, j)
        ch4r_k(layer, i)               = ch4r_k(layer, i) +      &
           predictors_k(i)%ch4(4, layer) * predictors(j)%ch4(1, layer) * ray_path(layer, j) * 2._jprb
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ch4(4, layer) * 2 * predictors(j)%ch4(1, layer) * ch4r(layer, j)
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%ch4(3, layer) * predictors(j)%ch4(1, layer)
        ch4r_k(layer, i)               =      &
           ch4r_k(layer, i) + predictors_k(i)%ch4(3, layer) * ray_path(layer, j) * dt(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ch4(3, layer) * ch4r(layer, j) * dt(layer, j)
        ch4r_k(layer, i)               = ch4r_k(layer, i) +      &
           predictors_k(i)%ch4(2, layer) * 0.5_jprb * ray_path(layer, j) * tmp5(layer,j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ch4(2, layer) * 0.5_jprb * ch4r(layer, j) * tmp5(layer,j)
        ch4r_k(layer, i)               = ch4r_k(layer, i) + predictors_k(i)%ch4(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%ch4(1, layer) * ch4r(layer, j)
      ENDDO

    ENDDO

  ENDIF

!-------------------------------------------------
!5.8 CO             transmittance based on RTIASI
!-------------------------------------------------
!

  IF (coef%nco > 0) THEN
! John.Hague@ecmwf.int optimisation start
    Do j = 1, nprofiles
      Do layer = 1,prof_k(1) % nlayers
        tmp1(layer,j) = 0.25_jprb*ray_path(layer, j)*(ray_path(layer, j)*cowr(layer,j))**(-0.75_jprb)
        tmp2(layer,j) = 0.25_jprb*cowr(layer,j)*(ray_path(layer, j)*cowr(layer,j))**(-0.75_jprb)
        tmp3(layer,j) = ray_path(layer, j)*0.4_jprb*(ray_path(layer, j)*cowr(layer,j))**(-0.6_jprb)
        tmp4(layer,j) = cowr(layer,j)*0.4_jprb* (ray_path(layer, j)*cowr(layer,j))**(-0.6_jprb)
        tmp5(layer,j) = 2._jprb*predictors(j)%co(1,layer)/cow(layer,j)**0.25_jprb
        tmp6(layer,j) = cor(layer,j)**2_jpim  /cow(layer,j)**0.25_jprb
        tmp7(layer,j) = 2._jprb*predictors(j)%co(1,layer)/cow(layer,j)**0.5_jprb
        tmp8(layer,j) = 0.5_jprb*cor(layer,j)**1.5_jprb/(ray_path(layer, j)**0.5_jprb*cow(layer,j))
      Enddo
    Enddo
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level = layer + 1
        cow_k(layer, i) = cow_k(layer, i) + ray_path(layer,j) * predictors_k(i)%co(14, layer)
        ray_path_k(layer,i) = ray_path_k(layer,i) + cow(layer, j) * predictors_k(i)%co(14, layer)

        cowr_k(layer, i)               = cowr_k(layer, i) + predictors_k(i)%co(13, layer) * tmp1(layer,j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +  predictors_k(i)%co(13, layer) * tmp2(layer,j)
        cowr_k(layer, i)               = cowr_k(layer, i) +                       &
           predictors_k(i)%co(12, layer) * tmp3(layer,j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co(12, layer) * tmp4(layer,j)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(11, layer) * tmp5(layer,j)
        cow_k(layer, i)                =      &
           cow_k(layer, i) - predictors_k(i)%co(11, layer) * 0.25_jprb * predictors(j)%co(11, layer) / cow(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(11, layer) * tmp6(layer,j)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(10, layer) * tmp7(layer,j)
        cow_k(layer, i)                =      &
           cow_k(layer, i) - predictors_k(i)%co(10, layer) * 0.5_jprb * predictors(j)%co(10, layer) / cow(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(10, layer) * cor(layer, j) ** 2_jpim / SQRT(cow(layer, j))
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(9, layer) * 1.5_jprb * predictors(j)%co(2, layer) / cow(layer, j)
        cow_k(layer, i)                = cow_k(layer, i) -                    &
           predictors_k(i)%co(9, layer) * predictors(j)%co(2, layer) ** 3_jpim /  &
           (ray_path(layer, j) * cow(layer, j) ** 2_jpim)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co(9, layer) * tmp8(layer,j)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(8, layer) * 2._jprb * predictors(j)%co(1, layer) / cow(layer, j)
        cow_k(layer, i)                =      &
           cow_k(layer, i) - predictors_k(i)%co(8, layer) * predictors(j)%co(8, layer) / cow(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(8, layer) * cor(layer, j) ** 2_jpim / cow(layer, j)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(7, layer) * dtabs(layer, j) * ray_path(layer, j) * dt(layer, j)
        dt_k(layer, i)                 =      &
           dt_k(layer, i) + predictors_k(i)%co(7, layer) * dtabs(layer, j) * predictors(j)%co(1, layer) * 2._jprb
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(7, layer) * dtabs(layer, j) * cor(layer, j) * dt(layer, j)
        cor_k(layer, i)                = cor_k(layer, i) +      &
           predictors_k(i)%co(6, layer) * ray_path(layer, j) * 0.25_jprb / predictors(j)%co(6, layer) ** 3_jpim
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co(6, layer) * cor(layer, j) * 0.25_jprb / predictors(j)%co(6, layer) ** 3_jpim
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%co(5, layer) * predictors(j)%co(2, layer)
        cor_k(layer, i)                = cor_k(layer, i) +      &
           predictors_k(i)%co(5, layer) * 0.5_jprb * dt(layer, j) * ray_path(layer, j) / predictors(j)%co(2, layer)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co(5, layer) * 0.5_jprb * dt(layer, j) * cor(layer, j) / predictors(j)%co(2, layer)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(4, layer) * 2._jprb * predictors(j)%co(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(4, layer) * 2._jprb * predictors(j)%co(1, layer) * cor(layer, j)
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%co(3, layer) * predictors(j)%co(1, layer)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(3, layer) * dt(layer, j) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(3, layer) * cor(layer, j) * dt(layer, j)
        cor_k(layer, i)                =      &
           cor_k(layer, i) + predictors_k(i)%co(2, layer) * 0.5_jprb * ray_path(layer, j) / predictors(j)%co(2, layer)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co(2, layer) * 0.5_jprb * cor(layer, j) / predictors(j)%co(2, layer)
        cor_k(layer, i)                = cor_k(layer, i) + predictors_k(i)%co(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%co(1, layer) * cor(layer, j)
      ENDDO

    ENDDO

  ENDIF

!-------------------------------------------------
!5.7 N2O            transmittance based on RTIASI
!-------------------------------------------------
!

  IF (coef%nn2o > 0) THEN
! John.Hague@ecmwf.int optimisation start
    Do j = 1, nprofiles
      Do layer = 1,prof_k(1) % nlayers
        tmp1(layer,j)=0.5_jprb*n2or(layer,j)**1.5_jprb/(ray_path(layer, j)**0.5_jprb*n2ow(layer,j))
      Enddo
    Enddo
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level = layer + 1
        dt_k(layer, i)                 =      &
           dt_k(layer, i) + predictors_k(i)%n2o(13, layer) * ray_path(layer, j) ** 2_jpim * n2owr(layer, j)
        n2owr_k(layer, i)              =      &
           n2owr_k(layer, i) + predictors_k(i)%n2o(13, layer) * ray_path(layer, j) ** 2_jpim * dt(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(13, layer) * 2._jprb * ray_path(layer, j) * n2owr(layer, j) * dt(layer, j)
        n2owr_k(layer, i)              = n2owr_k(layer, i) +      &
           predictors_k(i)%n2o(12, layer) * 3._jprb * predictors(j)%n2o(8, layer) ** 2_jpim * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(12, layer) * 3._jprb * predictors(j)%n2o(8, layer) ** 2_jpim * n2owr(layer, j)
        n2owr_k(layer, i)              = n2owr_k(layer, i) +      &
           predictors_k(i)%n2o(11, layer) * 2._jprb * predictors(j)%n2o(8, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(11, layer) * predictors(j)%n2o(8, layer) * 2._jprb * n2owr(layer, j)
        n2or_k(layer, i)               =      &
           n2or_k(layer, i) + predictors_k(i)%n2o(10, layer) * 1.5_jprb * predictors(j)%n2o(2, layer) / n2ow(layer, j)
        n2ow_k(layer, i)               = n2ow_k(layer, i) -                      &
           predictors_k(i)%n2o(10, layer) * predictors(j)%n2o(2, layer) ** 3_jpim /  &
           (ray_path(layer, j) * n2ow(layer, j) ** 2_jpim)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(10, layer) * tmp1(layer,j)
        n2owr_k(layer, i)              = n2owr_k(layer, i) + predictors_k(i)%n2o(9, layer)
        n2owr_k(layer, i)              =      &
           n2owr_k(layer, i) + predictors_k(i)%n2o(8, layer) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%n2o(8, layer) * n2owr(layer, j)
        n2ow_k(layer, i)               = n2ow_k(layer, i) + predictors_k(i)%n2o(7, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%n2o(7, layer) * n2ow(layer, j)
        n2or_k(layer, i)               = n2or_k(layer, i) +      &
           predictors_k(i)%n2o(6, layer) * ray_path(layer, j) * 0.25_jprb / predictors(j)%n2o(6, layer) ** 3_jpim
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(6, layer) * n2or(layer, j) * 0.25_jprb / predictors(j)%n2o(6, layer) ** 3_jpim
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%n2o(5, layer) * n2or(layer, j)
        n2or_k(layer, i)               = n2or_k(layer, i) + predictors_k(i)%n2o(5, layer) * dt(layer, j)
        n2or_k(layer, i)               = n2or_k(layer, i) +      &
           predictors_k(i)%n2o(4, layer) * 2._jprb * predictors(j)%n2o(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(4, layer) * 2._jprb * predictors(j)%n2o(1, layer) * n2or(layer, j)
        dt_k(layer, i)                 = dt_k(layer, i) + predictors_k(i)%n2o(3, layer) * predictors(j)%n2o(1, layer)
        n2or_k(layer, i)               =      &
           n2or_k(layer, i) + predictors_k(i)%n2o(3, layer) * ray_path(layer, j) * dt(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%n2o(3, layer) * n2or(layer, j) * dt(layer, j)
        n2or_k(layer, i)               = n2or_k(layer, i) +      &
           predictors_k(i)%n2o(2, layer) * 0.5_jprb * ray_path(layer, j) / predictors(j)%n2o(2, layer)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%n2o(2, layer) * 0.5_jprb * n2or(layer, j) / predictors(j)%n2o(2, layer)
        n2or_k(layer, i)               = n2or_k(layer, i) + predictors_k(i)%n2o(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%n2o(1, layer) * n2or(layer, j)
      ENDDO

    ENDDO

  ENDIF

!-----------------------------------------------------------------------------------------------
!5.6 CO2 transmittance
!-----------------------------------------------------------------------------------------------

  IF (coef%nco2 > 0) THEN
! John.Hague@ecmwf.int optimisation start
    Do j = 1, nprofiles
      Do layer = 1,prof_k(1) % nlayers
        tmp1(layer,j)=twr(layer,j)**2_jpim*tr(layer,j)**2_jpim*ray_path(layer, j)**0.5_jprb
        tmp2(layer,j)=twr(layer,j)*tr(layer,j)**0.5_jprb
      Enddo
    Enddo
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level = layer + 1
        tr_k(layer, i)                 =      &
           tr_k(layer, i) + predictors_k(i)%co2(15, layer) * 2._jprb * SQRT(predictors(j)%co2(15, layer)) * twr(layer, j)
        twr_k(layer, i)                =      &
           twr_k(layer, i) + predictors_k(i)%co2(15, layer) * 2._jprb * SQRT(predictors(j)%co2(15, layer)) * tr(layer, j)
        twr_k(layer, i)                = twr_k(layer, i) +                                 &
           predictors_k(i)%co2(14, layer) * 3._jprb * tmp1(layer,j)
        tr_k(layer, i)                 = tr_k(layer, i) +      &
           predictors_k(i)%co2(14, layer) * 2._jprb * tr(layer, j) * twr(layer, j) ** 3_jpim * SQRT(ray_path(layer, j))
        ray_path_k(layer, i) = ray_path_k(layer, i) +                    &
           predictors_k(i)%co2(14, layer) * tr(layer, j) ** 2_jpim * twr(layer, j) ** 3_jpim * 0.5_jprb /  &
           SQRT(ray_path(layer, j))
        tr_k(layer, i)                 =      &
           tr_k(layer, i) + predictors_k(i)%co2(13, layer) * 3._jprb * tr(layer, j) ** 2_jpim * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co2(13, layer) * tr(layer, j) ** 3_jpim
        tr_k(layer, i)                 = tr_k(layer, i) + predictors_k(i)%co2(12, layer) * 3 * tr(layer, j) ** 2_jpim
        co2r_k(layer, i)               = co2r_k(layer, i) +      &
           predictors_k(i)%co2(11, layer) * 0.5_jprb * ray_path(layer, j) / SQRT(predictors(j)%co2(1, layer))
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co2(11, layer) * 0.5_jprb * co2r(layer, j) / SQRT(predictors(j)%co2(1, layer))
        twr_k(layer, i)                = twr_k(layer, i) +      &
           predictors_k(i)%co2(10, layer) * ray_path(layer, j) * SQRT(predictors(j)%co2(5, layer))
        tr_k(layer, i)                 = tr_k(layer, i) +      &
           predictors_k(i)%co2(10, layer) * 0.5_jprb * predictors(j)%co2(7, layer) / SQRT(predictors(j)%co2(5, layer))
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co2(10, layer) * tmp2(layer,j)
        twr_k(layer, i)                = twr_k(layer, i) + predictors_k(i)%co2(9, layer) * 3._jprb * twr(layer, j) ** 2_jpim
        co2w_k(layer, i)               = co2w_k(layer, i) +      &
           predictors_k(i)%co2(8, layer) * 2._jprb * ray_path(layer, j) * SQRT(predictors(j)%co2(8, layer))
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%co2(8, layer) * 2._jprb * co2w(layer, j) * SQRT(predictors(j)%co2(8, layer))
        twr_k(layer, i)                = twr_k(layer, i) + predictors_k(i)%co2(7, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%co2(7, layer) * twr(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%co2(6, layer)
        tr_k(layer, i)                 = tr_k(layer, i) + predictors_k(i)%co2(5, layer)
        tr_k(layer, i)                 =      &
           tr_k(layer, i) + predictors_k(i)%co2(4, layer) * 2._jprb * predictors(j)%co2(3, layer)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%co2(4, layer) * tr(layer, j) ** 2_jpim
        tr_k(layer, i)                 = tr_k(layer, i) + predictors_k(i)%co2(3, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%co2(3, layer) * tr(layer, j)
        tr_k(layer, i)                 =      &
           tr_k(layer, i) + predictors_k(i)%co2(2, layer) * 2._jprb * predictors(j)%co2(5, layer)
        co2r_k(layer, i)               = co2r_k(layer, i) + predictors_k(i)%co2(1, layer) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%co2(1, layer) * co2r(layer, j)
      ENDDO

    ENDDO

  ENDIF

!------------------------------------------------------------------------------------
!5.4 ozone
!------------------------------------------------------------------------------------

  IF (coef%nozone > 0) THEN
! John.Hague@ecmwf.int optimisation start
    Do j = 1, nprofiles
      Do layer = 1,prof_k(1) % nlayers
        tmp1(layer,j)=0.5_jprb*ray_path(layer, j)**(-0.5_jprb)* ow(layer,j)**2_jpim*dto(layer,j)
        tmp2(layer,j)=2._jprb*ow(layer,j)*ray_path(layer, j)**0.5_jprb *dto(layer,j)
        tmp3(layer,j)=ray_path(layer, j)**0.5_jprb *ow(layer,j)**2_jpim
        tmp4(layer,j)=1.75_jprb*ray_path(layer, j)*(ray_path(layer, j)*ow(layer,j))**0.75_jprb
        tmp5(layer,j)=1.75_jprb*ow(layer,j)*(ray_path(layer, j)*ow(layer,j))**0.75_jprb
        tmp6(layer,j)=0.5_jprb*or(layer,j)**1.5_jprb / (ray_path(layer, j)**0.5_jprb*ow(layer,j))
      Enddo
    Enddo
! optimisation end

    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level = layer + 1
! One can pack all ow_k lines in one longer statement
! same for sec_or_k and dto_k
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ozone(15, layer) * tro(layer, j) ** 3_jpim
        tro_k(layer, i)                =      &
           tro_k(layer, i) + predictors_k(i)%ozone(15, layer) * 3._jprb * tro(layer, j) ** 2_jpim * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +                                            &
           predictors_k(i)%ozone(14, layer) * tmp1(layer,j)
        ow_k(layer, i)                 = ow_k(layer, i) +      &
           predictors_k(i)%ozone(14, layer) * tmp2(layer,j)
        dto_k(layer, i)                =      &
           dto_k(layer, i) + predictors_k(i)%ozone(14, layer) * tmp3(layer,j)
        ow_k(layer, i)                 = ow_k(layer, i) +                             &
           predictors_k(i)%ozone(13, layer) * tmp4(layer,j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ozone(13, layer) * tmp5(layer,j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ozone(12, layer) * or(layer, j) / ow(layer, j)
        or_k(layer, i)                 =      &
           or_k(layer, i) + predictors_k(i)%ozone(12, layer) * ray_path(layer, j) / ow(layer, j)
        ow_k(layer, i)                 = ow_k(layer, i) -      &
           predictors_k(i)%ozone(12, layer) * or(layer, j) * ray_path(layer, j) / ow(layer, j) ** 2_jpim
        ow_k(layer, i)                 = ow_k(layer, i) +      &
           predictors_k(i)%ozone(11, layer) * 2._jprb * ray_path(layer, j) * predictors(j)%ozone(10, layer)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ozone(11, layer) * 2._jprb * ow(layer, j) * predictors(j)%ozone(10, layer)
        ow_k(layer, i)                 =      &
           ow_k(layer, i) + predictors_k(i)%ozone(10, layer) * ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ozone(10, layer) * ow(layer, j)
        or_k(layer, i)                 = or_k(layer, i) +                                          &
           predictors_k(i)%ozone(9, layer) * SQRT(ray_path(layer, j) * ow(layer, j)) *  &
           ray_path(layer, j)
        ow_k(layer, i)                 = ow_k(layer, i) +                                                           &
           predictors_k(i)%ozone(9, layer) * predictors(j)%ozone(1, layer) * 0.5_jprb * ray_path(layer, j) /  &
           SQRT(ray_path(layer, j) * ow(layer, j))
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ozone(9, layer) * 1.5_jprb * or(layer, j) * SQRT(predictors(j)%ozone(10, layer))
        or_k(layer, i)                 =      &
           or_k(layer, i) + predictors_k(i)%ozone(8, layer) * predictors(j)%ozone(10, layer)
        ow_k(layer, i)                 =      &
           ow_k(layer, i) + predictors_k(i)%ozone(8, layer) * ray_path(layer, j) * or(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ozone(8, layer) * or(layer, j) * ow(layer, j)
        or_k(layer, i)                 =      &
           or_k(layer, i) + predictors_k(i)%ozone(7, layer) * 1.5_jprb * predictors(j)%ozone(2, layer) / ow(layer, j)
        ow_k(layer, i)                 =      &
           ow_k(layer, i) - predictors_k(i)%ozone(7, layer) * predictors(j)%ozone(7, layer) / ow(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) +      &
           predictors_k(i)%ozone(7, layer) * tmp6(layer,j)
        or_k(layer, i)                 =      &
           or_k(layer, i) + predictors_k(i)%ozone(6, layer) * 2._jprb * predictors(j)%ozone(1, layer) * ow(layer, j)
        ow_k(layer, i)                 =      &
           ow_k(layer, i) + predictors_k(i)%ozone(6, layer) * predictors(j)%ozone(4, layer) / ray_path(layer, j)
        ray_path_k(layer, i) =      &
           ray_path_k(layer, i) + predictors_k(i)%ozone(6, layer) * or(layer, j) ** 2_jpim * ow(layer, j)
        sec_or_k(layer, i)             = sec_or_k(layer, i) +                             &
           predictors_k(i)%ozone(5, layer) * 0.5_jprb * predictors(j)%ozone(3, layer) /  &
           (predictors(j)%ozone(1, layer) * predictors(j)%ozone(2, layer))
        dto_k(layer, i)                =      &
           dto_k(layer, i) + predictors_k(i)%ozone(5, layer) * predictors(j)%ozone(2, layer)
        sec_or_k(layer, i)             =      &
           sec_or_k(layer, i) + predictors_k(i)%ozone(4, layer) * 2._jprb * predictors(j)%ozone(1, layer)
        sec_or_k(layer, i)             = sec_or_k(layer, i) +      &
           predictors_k(i)%ozone(3, layer) * predictors(j)%ozone(3, layer) / predictors(j)%ozone(1, layer)
        dto_k(layer, i)                =      &
           dto_k(layer, i) + predictors_k(i)%ozone(3, layer) * predictors(j)%ozone(1, layer)
        sec_or_k(layer, i)             =      &
           sec_or_k(layer, i) + predictors_k(i)%ozone(2, layer) * 0.5_jprb / predictors(j)%ozone(2, layer)
        sec_or_k(layer, i)             = sec_or_k(layer, i) + predictors_k(i)%ozone(1, layer)
        or_k(layer, i)                 = or_k(layer, i) + sec_or_k(layer, i) * ray_path(layer, j)
        ray_path_k(layer, i) = ray_path_k(layer, i) + sec_or_k(layer, i) * or(layer, j)
      ENDDO

    ENDDO

  ENDIF

!--------------------------------------------
!5.3 Water Vapour Continuum based on RTIASI
!--------------------------------------------

  IF (coef%nwvcont > 0) THEN
    DO i = 1, nchanprof
      j = chanprof(i)%prof

      DO layer = 1, nlayers
        level                = layer + 1
        sec_wr_k(layer, i)   = sec_wr_k(layer, i) + predictors_k(i)%wvcont(4, layer) / tr_sq(layer, j)
        tr_k(layer, i)       = tr_k(layer, i) -      &
           2 * predictors_k(i)%wvcont(4, layer) * predictors(j)%watervapour(7, layer) / (tr_sq(layer, j) * tr(layer, j))
        sec_wr_k(layer, i)   = sec_wr_k(layer, i) + predictors_k(i)%wvcont(3, layer) / tr(layer, j)
        tr_k(layer, i)       =      &
           tr_k(layer, i) - predictors_k(i)%wvcont(3, layer) * predictors(j)%watervapour(7, layer) / tr_sq(layer, j)
        sec_wrwr_k(layer, i) = sec_wrwr_k(layer, i) + predictors_k(i)%wvcont(2, layer) / tr_4(layer, j)
        tr_k(layer, i)       =      &
           tr_k(layer, i) - 4._jprb * predictors_k(i)%wvcont(2, layer) * predictors(j)%wvcont(1, layer) / tr_4(layer, j)
        sec_wrwr_k(layer, i) = sec_wrwr_k(layer, i) + predictors_k(i)%wvcont(1, layer) / tr(layer, j)
        tr_k(layer, i)       =      &
           tr_k(layer, i) - predictors_k(i)%wvcont(1, layer) * predictors(j)%wvcont(1, layer) / tr(layer, j)
      ENDDO

    ENDDO

  ENDIF

!---------------------------------
!5.2 water vapour based on RTIASI
!---------------------------------
  ! John.Hague@ecmwf.int optimisation start
  Do j = 1, nprofiles
    Do layer = 1,prof_k(1) % nlayers
      tmp1(layer,j)=predictors(j)%watervapour(7,layer)**1.5_jprb
      tmp2(layer,j)=0.5_jprb*wr(layer,j)**1.5_jprb/ray_path(layer, j)**0.5_jprb
      tmp3(layer,j)=1.25_jprb*ww(layer,j)* (predictors(j)%watervapour(2,layer))**0.25_jprb
      tmp4(layer,j)=0.5_jprb/SQRT(ray_path(layer, j))*(wr(layer,j)**1.5_jprb / wwr(layer,j))
      tmp5(layer,j)=SQRT(ray_path(layer, j))*1.5_jprb*wr(layer,j)**0.5_jprb/ wwr(layer,j)
      tmp6(layer,j)=SQRT(ray_path(layer, j))*wr(layer,j)**1.5_jprb / wwr(layer,j)**2_jpim
    Enddo
  Enddo
! optimisation end

  DO i = 1, nchanprof
    j = chanprof(i)%prof

    DO layer = 1, nlayers
      level = layer + 1
      sec_wr(layer, j)               = ray_path(layer, j) * wr(layer, j)
      sec_wrwr(layer, j)             = sec_wr(layer, j) * wr(layer, j)
      wr_k(layer, i)                 =      &
         wr_k(layer, i) + predictors_k(i)%watervapour(19, layer) * 2._jprb * predictors(j)%watervapour(7, layer) / ww(layer, j)
      ww_k(layer, i)                 = ww_k(layer, i) -                                   &
         predictors_k(i)%watervapour(19, layer) * predictors(j)%watervapour(1, layer) /  &
         (ray_path(layer, j) * ww(layer, j) ** 2_jpim)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%watervapour(19, layer) * wr(layer, j) ** 2_jpim / ww(layer, j)
      dt_k(layer, i)                 =      &
         dt_k(layer, i) + predictors_k(i)%watervapour(18, layer) * tmp1(layer,j)
      wr_k(layer, i)                 = wr_k(layer, i) +                                                                     &
         predictors_k(i)%watervapour(18, layer) * 1.5_jprb * predictors(j)%watervapour(5, layer) * ray_path(layer, j) &
          * dt(layer, j)
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(18, layer) * 1.5_jprb * predictors(j)%watervapour(5, layer) * wr(layer, j) * dt(layer, j)
      wr_k(layer, i)                 =      &
         wr_k(layer, i) + predictors_k(i)%watervapour(17, layer) * 1.5_jprb * predictors(j)%watervapour(5, layer)
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(17, layer) * tmp2(layer,j)
      ww_k(layer, i)                 = ww_k(layer, i) +                                   &
         predictors_k(i)%watervapour(16, layer) * 1.25_jprb * ray_path(layer, j) *  &
         (predictors(j)%watervapour(2, layer)) ** 0.25_jprb
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(16, layer) * tmp3(layer,j)
      wr_k(layer, i)                 = wr_k(layer, i) +                                  &
         predictors_k(i)%watervapour(15, layer) * 1.5_jprb * ray_path(layer, j) *  &
         SQRT(predictors(j)%watervapour(7, layer))
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(15, layer) * 1.5_jprb * wr(layer, j) * SQRT(predictors(j)%watervapour(7, layer))
      ww_k(layer, i)                 = ww_k(layer, i) +                                  &
         predictors_k(i)%watervapour(14, layer) * 1.5_jprb * ray_path(layer, j) *  &
         SQRT(predictors(j)%watervapour(2, layer))
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(14, layer) * 1.5_jprb * ww(layer, j) * SQRT(predictors(j)%watervapour(2, layer))
      ray_path_k(layer, i) = ray_path_k(layer, i) +                        &
         predictors_k(i)%watervapour(13, layer) * tmp4(layer,j)
      wr_k(layer, i)                 = wr_k(layer, i) +                                                              &
         predictors_k(i)%watervapour(13, layer) * tmp5(layer,j)
      wwr_k(layer, i)                = wwr_k(layer, i) -                                                            &
         predictors_k(i)%watervapour(13, layer) * tmp6(layer,j)
      sec_wrwr_k(layer, i)           = sec_wrwr_k(layer, i) + predictors_k(i)%watervapour(12, layer) / wwr(layer, j)
      wwr_k(layer, i)                =      &
         wwr_k(layer, i) - predictors_k(i)%watervapour(12, layer) * sec_wrwr(layer, j) / wwr(layer, j) ** 2_jpim
      dt_k(layer, i)                 =      &
         dt_k(layer, i) + predictors_k(i)%watervapour(11, layer) * predictors(j)%watervapour(5, layer)
      sec_wr_k(layer, i)             = sec_wr_k(layer, i) +      &
         0.5_jprb * predictors_k(i)%watervapour(11, layer) * dt(layer, j) / predictors(j)%watervapour(5, layer)
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + predictors_k(i)%watervapour(10, layer) * dtabs(layer, j) * dt(layer, j)
      dt_k(layer, i)                 = dt_k(layer, i) +      &
         2 * predictors_k(i)%watervapour(10, layer) * predictors(j)%watervapour(7, layer) * dtabs(layer, j)
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + predictors_k(i)%watervapour(9, layer) * 4._jprb * predictors(j)%watervapour(8, layer)
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + 3._jprb * predictors_k(i)%watervapour(8, layer) * predictors(j)%watervapour(1, layer)
      sec_wr_k(layer, i)             = sec_wr_k(layer, i) + predictors_k(i)%watervapour(7, layer)
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + 0.25_jprb * predictors_k(i)%watervapour(6, layer) / predictors(j)%watervapour(6, layer) ** 3
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + 0.5_jprb * predictors_k(i)%watervapour(5, layer) / predictors(j)%watervapour(5, layer)
      dt_k(layer, i)                 =      &
         dt_k(layer, i) + predictors_k(i)%watervapour(4, layer) * predictors(j)%watervapour(7, layer)
      sec_wr_k(layer, i)             = sec_wr_k(layer, i) + predictors_k(i)%watervapour(4, layer) * dt(layer, j)
      ww_k(layer, i)                 = ww_k(layer, i) +      &
         predictors_k(i)%watervapour(3, layer) * 2._jprb * predictors(j)%watervapour(2, layer) * ray_path(layer, j)
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%watervapour(3, layer) * 2._jprb * predictors(j)%watervapour(2, layer) * ww(layer, j)
      ww_k(layer, i)                 =      &
         ww_k(layer, i) + predictors_k(i)%watervapour(2, layer) * ray_path(layer, j)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%watervapour(2, layer) * ww(layer, j)
      sec_wr_k(layer, i)             =      &
         sec_wr_k(layer, i) + 2._jprb * predictors_k(i)%watervapour(1, layer) * predictors(j)%watervapour(7, layer)
      sec_wr_k(layer, i)             = sec_wr_k(layer, i) + sec_wrwr_k(layer, i) * wr(layer, j)
      wr_k(layer, i)                 = wr_k(layer, i) + sec_wrwr_k(layer, i) * predictors(j)%watervapour(7, layer)
      wr_k(layer, i)                 = wr_k(layer, i) + sec_wr_k(layer, i) * ray_path(layer, j)
      ray_path_k(layer, i) = ray_path_k(layer, i) + sec_wr_k(layer, i) * wr(layer, j)
    ENDDO

  ENDDO

!-----------------------------------------------------------------------------------------------------
!5.1 mixed gases
!-----------------------------------------------------------------------------------------------------
! John.Hague@ecmwf.int optimisation start
  Do j = 1, nprofiles
    Do layer = 1,prof_k(1) % nlayers
      tmp1(layer,j)=ray_path(layer, j)**1.5_jprb/SQRT(tr(layer,j))
    Enddo
  Enddo
! optimisation end

  DO i = 1, nchanprof
    j = chanprof(i)%prof

    DO layer = 1, nlayers
      level = layer + 1
! X10
      tr_k(layer, i)                 = tr_k(layer, i) +      &
         predictors_k(i)%mixedgas(10, layer) * 0.5_jprb * tmp1(layer,j)
      ray_path_k(layer, i) = ray_path_k(layer, i) +      &
         predictors_k(i)%mixedgas(10, layer) * 1.5_jprb * SQRT(predictors(j)%mixedgas(3, layer))
! X9
      tr_k(layer, i)                 =      &
         tr_k(layer, i) + predictors_k(i)%mixedgas(9, layer) * 3._jprb * ray_path(layer, j) * tr(layer, j) ** 2_jpim
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(9, layer) * tr(layer, j) ** 3_jpim
! X8
      tuwr_k(layer, i)               =      &
         tuwr_k(layer, i) + predictors_k(i)%mixedgas(8, layer) * ray_path(layer, j)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(8, layer) * tuwr(layer, j)
! X7
      tuw_k(layer, i)                =      &
         tuw_k(layer, i) + predictors_k(i)%mixedgas(7, layer) * ray_path(layer, j)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(7, layer) * tuw(layer, j)
! X6
      tr_k(layer, i)                 =      &
         tr_k(layer, i) + predictors_k(i)%mixedgas(6, layer) * 2._jprb * predictors(j)%mixedgas(5, layer)
! X5
      tr_k(layer, i)                 = tr_k(layer, i) + predictors_k(i)%mixedgas(5, layer)
! X4
      tr_k(layer, i)                 =      &
         tr_k(layer, i) + predictors_k(i)%mixedgas(4, layer) * 2._jprb * predictors(j)%mixedgas(3, layer)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(4, layer) * predictors(j)%mixedgas(5, layer) ** 2_jpim
! X3
      tr_k(layer, i)                 =      &
         tr_k(layer, i) + predictors_k(i)%mixedgas(3, layer) * ray_path(layer, j)
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(3, layer) * tr(layer, j)
! X2
      ray_path_k(layer, i) =      &
         ray_path_k(layer, i) + predictors_k(i)%mixedgas(2, layer) * 2._jprb * ray_path(layer, j)
! X1
      ray_path_k(layer, i) = ray_path_k(layer, i) + predictors_k(i)%mixedgas(1, layer)
    ENDDO

  ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile/reference sums
!-------------------------------------------------------------------

  DO i = 1, nchanprof
    j = chanprof(i)%prof

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb

      DO layer = prof_k(i)%nlayers, 1,  - 1
        sum1            = sum1 + so2w_k(layer, i) / sum2_so2w(layer, j)
        so2_k(layer, i) = so2_k(layer, i) + sum1 * coef%dpp(layer - 1)
      ENDDO

      sum1 = 0._jprb

      DO layer = prof_k(i)%nlayers, 1,  - 1
        sum1            = sum1 + so2wr_k(layer, i) / sum2_so2wr(layer, j)
        so2_k(layer, i) = so2_k(layer, i) + sum1 * coef%dpp(layer - 1) * t(layer, j)
        t_k(layer, i)   = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * so2(layer, j)
      ENDDO
    ENDIF

    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + ch4w_k(layer, i) / sum2_ch4w(layer, j)
          ch4_k(layer, i) = ch4_k(layer, i) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + ch4wr_k(layer, i) / sum2_ch4wr(layer, j)
          ch4_k(layer, i) = ch4_k(layer, i) + sum1 * coef%dpp(layer - 1) * t(layer, j)
          t_k(layer, i)   = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * ch4(layer, j)
        ENDDO

      ELSE
        ch4_k(:, i) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + ch4wr_k(layer, i) / sum2_ch4wr(layer, j)
          t_k(layer, i)   = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * coef%ch4star(layer)
        ENDDO

      ENDIF
    ENDIF

    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1           = sum1 + cow_k(layer, i) / sum2_cow(layer, j)
          co_k(layer, i) = co_k(layer, i) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1           = sum1 + cowr_k(layer, i) / sum2_cowr(layer, j)
          co_k(layer, i) = co_k(layer, i) + sum1 * coef%dpp(layer - 1) * t(layer, j)
          t_k(layer, i)  = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * co(layer, j)
        ENDDO

      ELSE
        co_k(:, i) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1           = sum1 + cowr_k(layer, i) / sum2_cowr(layer, j)
          t_k(layer, i)  = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * coef%costar(layer)
        ENDDO

      ENDIF
    ENDIF

    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + n2ow_k(layer, i) / sum2_n2ow(layer, j)
          n2o_k(layer, i) = n2o_k(layer, i) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + n2owr_k(layer, i) / sum2_n2owr(layer, j)
          n2o_k(layer, i) = n2o_k(layer, i) + sum1 * coef%dpp(layer - 1) * t(layer, j)
          t_k(layer, i)   = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * n2o(layer, j)
        ENDDO

      ELSE
        n2o_k(:, i) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof_k(i)%nlayers, 1,  - 1
          sum1            = sum1 + n2owr_k(layer, i) / sum2_n2owr(layer, j)
          t_k(layer, i)   = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * coef%n2ostar(layer)
        ENDDO

      ENDIF
    ENDIF

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb

      DO layer = prof_k(i)%nlayers, 1,  - 1
        sum1            = sum1 + co2w_k(layer, i) / sum2_co2w(layer, j)
        co2_k(layer, i) = co2_k(layer, i) + sum1 * coef%dpp(layer - 1)
      ENDDO

    ELSE
      co2_k(:, i) = 0._jprb
    ENDIF

    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN
      sum1 = 0._jprb

      DO layer = prof_k(i)%nlayers, 1,  - 1
        sum1          = sum1 + ow_k(layer, i) / sum2_ow(layer, j)
        o_k(layer, i) = o_k(layer, i) + sum1 * coef%dpp(layer - 1)
      ENDDO

    ELSE
      o_k(:, i) = 0._jprb
    ENDIF

!
    sum1 = 0._jprb

    DO layer = prof_k(i)%nlayers, 1,  - 1
      sum1          = sum1 + wwr_k(layer, i) / sum2_wwr(layer, j)
      w_k(layer, i) = w_k(layer, i) + sum1 * coef%dpp(layer - 1) * t(layer, j)
      t_k(layer, i) = t_k(layer, i) + sum1 * coef%dpp(layer - 1) * w(layer, j)
    ENDDO

!
    sum1 = 0._jprb

    DO layer = prof_k(i)%nlayers, 1,  - 1
      sum1          = sum1 + ww_k(layer, i) / sum2_ww(layer, j)
      w_k(layer, i) = w_k(layer, i) + sum1 * coef%dpp(layer - 1)
    ENDDO

    sum1 = 0._jprb

    IF (coef%nco2 > 0) THEN
      DO layer = prof_k(i)%nlayers, 1,  - 1
        sum1          = sum1 + twr_k(layer, i) / sum2_twr(layer, j)
        t_k(layer, i) = t_k(layer, i) + sum1 * coef%dpp(layer - 1)
      ENDDO
    ENDIF

    tuw_k(2:prof(j)%nlayers, i) = tuw_k(2:prof(j)%nlayers, i) + tuwr_k(2:prof(j)%nlayers, i)
    t_k(1, i)                   = t_k(1, i) + tuwr_k(1, i) * coef%dpp(0) / (coef%dpp(0) * coef%tstar(1))
    sum1 = 0._jprb

    DO layer = prof_k(i)%nlayers, 1,  - 1
      sum1          = sum1 + tuw_k(layer, i) / sum2_tuw(layer, j)
      t_k(layer, i) = t_k(layer, i) + sum1
    ENDDO

    DO layer = prof_k(i)%nlayers, 2,  - 1
      tw_k(layer - 1, i) = tw_k(layer - 1, i) + tw_k(layer, i)
      tr_k(layer - 1, i) = tr_k(layer - 1, i) + tw_k(layer, i) * coef%dpp(layer - 1)
    ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile deviations
!-------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers

    DO layer = 1, prof_k(i)%nlayers

      IF (coef%nso2 > 0) THEN
        so2_k(layer, i) = so2_k(layer, i) + so2r_k(layer, i) / coef%so2star(layer)
      ENDIF

      IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
        ch4_k(layer, i) = ch4_k(layer, i) + ch4r_k(layer, i) / coef%ch4star(layer)
      ELSE
        ch4_k(layer, i) = 0._jprb
      ENDIF

      IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
        co_k(layer, i) = co_k(layer, i) + cor_k(layer, i) / coef%costar(layer)
      ELSE
        co_k(layer, i) = 0._jprb
      ENDIF

      IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
        n2o_k(layer, i) = n2o_k(layer, i) + n2or_k(layer, i) / coef%n2ostar(layer)
      ELSE
        n2o_k(layer, i) = 0._jprb
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        co2_k(layer, i) = co2_k(layer, i) + co2r_k(layer, i) / coef%co2star(layer)
      ELSE
        co2_k(layer, i) = 0._jprb
      ENDIF

      IF (coef%nozone > 0) THEN
        t_k(layer, i) = t_k(layer, i) + tro_k(layer, i) / coef%to3star(layer)
        IF (opts%rt_ir%ozone_data) THEN
          o_k(layer, i) = o_k(layer, i) + or_k(layer, i) / coef%ostar(layer)
        ELSE
          o_k(layer, i) = 0._jprb
        ENDIF
      ENDIF

      w_k(layer, i) = w_k(layer, i) + wr_k(layer, i) / coef%wstar(layer)
      t_k(layer, i) = t_k(layer, i) + tr_k(layer, i) / coef%tstar(layer)

      IF (coef%nozone > 0) t_k(layer, i) = t_k(layer, i) + dto_k(layer, i)

      t_k(layer, i) = t_k(layer, i) + dt_k(layer, i)
    ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile layer means
!-------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN

      DO level = 2, prof_k(i)%nlevels

        IF (opts%rt_ir%pc%addpc .OR. .NOT. opts%rt_ir%so2_data) THEN
          layer           = level - 1
          so2_k(layer, i) = 0._jprb
        ELSE
          layer = level - 1
          prof_k(i)%so2(level - 1) = prof_k(i)%so2(level - 1) + 0.5_jprb * so2_k(layer, i)
          prof_k(i)%so2(level)     = prof_k(i)%so2(level) + 0.5_jprb * so2_k(layer, i)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN

      DO level = 2, prof_k(i)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer           = level - 1
          ch4_k(layer, i) = 0._jprb
        ELSE
          layer = level - 1
          prof_k(i)%ch4(level - 1) = prof_k(i)%ch4(level - 1) + 0.5_jprb * ch4_k(layer, i)
          prof_k(i)%ch4(level)     = prof_k(i)%ch4(level) + 0.5_jprb * ch4_k(layer, i)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN

      DO level = 2, prof_k(i)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer           = level - 1
          n2o_k(layer, i) = 0._jprb
        ELSE
          layer = level - 1
          prof_k(i)%n2o(level - 1) = prof_k(i)%n2o(level - 1) + 0.5_jprb * n2o_k(layer, i)
          prof_k(i)%n2o(level)     = prof_k(i)%n2o(level) + 0.5_jprb * n2o_k(layer, i)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN

      DO level = 2, prof_k(i)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer          = level - 1
          co_k(layer, i) = 0._jprb
        ELSE
          layer = level - 1
          prof_k(i)%co(level - 1) = prof_k(i)%co(level - 1) + 0.5_jprb * co_k(layer, i)
          prof_k(i)%co(level)     = prof_k(i)%co(level) + 0.5_jprb * co_k(layer, i)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN

      DO level = 2, prof_k(i)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer           = level - 1
          co2_k(layer, i) = 0._jprb
        ELSE
          layer = level - 1
          prof_k(i)%co2(level - 1) = prof_k(i)%co2(level - 1) + 0.5_jprb * co2_k(layer, i)
          prof_k(i)%co2(level)     = prof_k(i)%co2(level) + 0.5_jprb * co2_k(layer, i)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN

      DO level = 2, prof_k(i)%nlevels
        layer = level - 1
        prof_k(i)%o3(level - 1) = prof_k(i)%o3(level - 1) + 0.5_jprb * o_k(layer, i)
        prof_k(i)%o3(level)     = prof_k(i)%o3(level) + 0.5_jprb * o_k(layer, i)
      ENDDO

    ENDIF

! include K surface humidity

    IF (opts%rt_all%use_q2m) THEN
      iv2lev = aux%s(j)%nearestlev_surf

      ! It is not immediately obvious that this is correct, but after careful comparison with
      ! the TL one can see that it is.
      DO level = 2, prof(1)%nlevels
        layer = level - 1
        prof_k(i)%q(level - 1) = prof_k(i)%q(level - 1) + 0.5_JPRB * w_k(layer, i)

        IF (level == iv2lev) THEN
          iv2lay = iv2lev - 1
          prof_k(i)%s2m%q = prof_k(i)%s2m%q + 0.5_JPRB * w_k(iv2lay, i)
        ELSE
          prof_k(i)%q(level) = prof_k(i)%q(level) + 0.5_JPRB * w_k(layer, i)
        ENDIF
      ENDDO

    ELSE

      DO level = 2, prof(1)%nlevels
        layer = level - 1
        prof_k(i)%q(level - 1) = prof_k(i)%q(level - 1) + 0.5_JPRB * w_k(layer, i)
        prof_k(i)%q(level)     = prof_k(i)%q(level) + 0.5_JPRB * w_k(layer, i)
      ENDDO

    ENDIF

    DO level = 2, prof_k(i)%nlevels
      layer = level - 1
      prof_k(i)%t(level - 1) = prof_k(i)%t(level - 1) + 0.5_jprb * t_k(layer, i)
      prof_k(i)%t(level)     = prof_k(i)%t(level) + 0.5_jprb * t_k(layer, i)
    ENDDO

  ENDDO
  
! End of channel loop
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_K', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_9_k
