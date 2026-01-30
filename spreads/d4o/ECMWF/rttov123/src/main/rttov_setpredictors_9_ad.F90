! Description:
!> @file
!!   AD of v9 predictor calculation.
!!
!> @brief
!!   AD of v9 predictor calculation.
!!
!! @param[in]     opts            RTTOV options
!! @param[in]     prof            profiles on coefficient levels
!! @param[in,out] prof_ad         profile increments on coefficient levels
!! @param[in]     ray_path        raytracing path array
!! @param[in,out] ray_path_ad     raytracing path array increments
!! @param[in]     coef_pccomp     PC coefficients structure
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_ad   predictor increments
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
SUBROUTINE rttov_setpredictors_9_ad( &
              opts,          &
              prof,          &
              prof_ad,       &
              ray_path,      &
              ray_path_ad,   &
              coef_pccomp,   &
              coef,          &
              aux,           &
              predictors,    &
              predictors_ad)

  USE rttov_types, ONLY : &
       rttov_coef,        &
       rttov_options,     &
       rttov_coef_pccomp, &
       rttov_profile,     &
       rttov_profile_aux, &
       rttov_path_pred
  USE parkind1, ONLY : jprb
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim
  USE rttov_const, ONLY : gas_id_so2
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options)     , INTENT(IN)    :: opts
  TYPE(rttov_profile)     , INTENT(IN)    :: prof(:)
  TYPE(rttov_profile)     , INTENT(INOUT) :: prof_ad(SIZE(prof))
  REAL(jprb)              , INTENT(IN)    :: ray_path(prof(1)%nlayers,SIZE(prof))
  REAL(jprb)              , INTENT(INOUT) :: ray_path_ad(prof(1)%nlayers,SIZE(prof))
  TYPE(rttov_coef_pccomp) , INTENT(IN)    :: coef_pccomp
  TYPE(rttov_coef)        , INTENT(IN)    :: coef
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_ad(:)
!INTF_END

  INTEGER(KIND=jpim) :: level, layer, iprof, n, iv2lev, iv3lev, iv2lay
! user profile
  REAL   (KIND=jprb) :: t(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: w(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: o(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2o  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2  (SIZE(prof(1)%p)-1)
! reference profile
  REAL   (KIND=jprb) :: tr   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tro  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wr   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: or   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2r (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2or (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cor  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4r (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2r (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wwr  (SIZE(prof(1)%p)-1)
! user - reference
  REAL   (KIND=jprb) :: dt   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dto  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dtabs(SIZE(prof(1)%p)-1)
! pressure weighted
  REAL   (KIND=jprb) :: tw   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: twr  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuw  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuwr (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ww   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ow   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2w (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2ow (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cow  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4w (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2w (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2owr(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cowr (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4wr(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2wr(SIZE(prof(1)%p)-1)
! intermediate variables
  REAL   (KIND=jprb) :: sum1, sum2
  REAL   (KIND=jprb) :: sum2_ww    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_wwr   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_ow    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_twr   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_tuw   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_co2w  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_ch4w  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_ch4wr (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_so2w  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_so2wr (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_n2ow  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_n2owr (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_cow   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sum2_cowr  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tr_sq      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tr_4       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wrwr   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wr     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2so2 (SIZE(prof(1)%p)-1)

! AD variables
  REAL   (KIND=jprb) :: t_ad       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: w_ad       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: o_ad       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2o_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tr_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tro_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wr_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: or_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wwr_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2r_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2or_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cor_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4r_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2r_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: twr_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuw_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuwr_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dt_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dto_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tw_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ww_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ow_ad      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2w_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2ow_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cow_ad     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4w_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2w_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2owr_ad   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cowr_ad    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4wr_ad   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2wr_ad   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_or_ad  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wr_ad  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wrwr_ad(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2_ad   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2so2_ad(SIZE(prof(1)%p)-1)

  INTEGER(KIND=jpim) :: nprofiles, nlayers
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-------------------------------------------------------------------------------
! Recompute Direct variables
!-------------------------------------------------------------------------------
!1) Profile layer quantities
!-------------------------------------------------------------------------------
!-Temperature--------------------------------------------------------------------
! layer N-1 lies between levels N-1 and N
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_AD', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers

    IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
!-CO2--------------------------------------------------------------------------

      DO layer = 1, prof(1)%nlayers
        level    = layer + 1
        IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
          co2(layer) = (coef_pccomp%co2_pc_ref(level - 1) + coef_pccomp%co2_pc_ref(level)) * 0.5_jprb
        ENDIF
      ENDDO

!-N2O--------------------------------------------------------------------------
      DO layer = 1, prof(1)%nlayers
        level    = layer + 1
        IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
          n2o(layer) = (coef_pccomp%n2o_pc_ref(level - 1) + coef_pccomp%n2o_pc_ref(level)) * 0.5_jprb
        ENDIF
      ENDDO

!-CO---------------------------------------------------------------------------
      DO layer = 1, prof(1)%nlayers
        level    = layer + 1
        IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
          co(layer) = (coef_pccomp%co_pc_ref(level - 1) + coef_pccomp%co_pc_ref(level)) * 0.5_jprb
        ENDIF
      ENDDO

!-CH4--------------------------------------------------------------------------
      DO layer = 1, prof(1)%nlayers
        level    = layer + 1
        IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
          ch4(layer) = (coef_pccomp%ch4_pc_ref(level - 1) + coef_pccomp%ch4_pc_ref(level)) * 0.5_jprb
        ENDIF
      ENDDO

    ENDIF
! addpc


  DO iprof = 1, nprofiles

    DO layer = 1, prof(1)%nlayers
      level    = layer + 1
!-Temperature  ----------------------------------------------------------------
      t(layer) = (prof(iprof)%t(level - 1) + prof(iprof)%t(level)) * 0.5_jprb
!-H2O--------------------------------------------------------------------------
      w(layer) = (prof(iprof)%q(level - 1) + prof(iprof)%q(level)) * 0.5_jprb
!-O3---------------------------------------------------------------------------
      IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0)     &
           o(layer) = (prof(iprof)%o3(level - 1) + prof(iprof)%o3(level)) * 0.5_jprb
    ENDDO

    IF (opts%rt_all%use_q2m) THEN
! include surface humidity
      iv3lev = aux%s(iprof)%nearestlev_surf - 1
      iv2lev = aux%s(iprof)%nearestlev_surf

      IF (iv2lev <= coef%nlevels) THEN
        iv2lay    = iv2lev - 1
        w(iv2lay) = (prof(iprof)%s2m%q + prof(iprof)%q(iv3lev)) / 2._JPRB
      ENDIF

    ENDIF

    IF (.NOT. (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5)) THEN

      DO layer = 1, prof(1)%nlayers
        level    = layer + 1

!-CO2--------------------------------------------------------------------------

        IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
          co2(layer) = (prof(iprof)%co2(level - 1) + prof(iprof)%co2(level)) * 0.5_jprb
        ENDIF

!-N2O--------------------------------------------------------------------------

        IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
          n2o(layer) = (prof(iprof)%n2o(level - 1) + prof(iprof)%n2o(level)) * 0.5_jprb
        ENDIF

!-CO---------------------------------------------------------------------------

        IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
          co(layer) = (prof(iprof)%co(level - 1) + prof(iprof)%co(level)) * 0.5_jprb
        ENDIF

!-CH4--------------------------------------------------------------------------

        IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
          ch4(layer) = (prof(iprof)%ch4(level - 1) + prof(iprof)%ch4(level)) * 0.5_jprb
        ENDIF

!-SO2--------------------------------------------------------------------------

        IF (coef%nso2 > 0) THEN
          IF (opts%rt_ir%so2_data) THEN
            so2(layer) = (prof(iprof)%so2(level - 1) + prof(iprof)%so2(level)) * 0.5_jprb
          ELSE
            n = coef%fmv_gas_pos(gas_id_so2)
            so2(layer) = (coef%bkg_prfl_mr(level - 1,n) + coef%bkg_prfl_mr(level,n)) * 0.5_jprb
          ENDIF
        ENDIF

      ENDDO
! layers

    ENDIF
! not addpc


!------------------------------------------------------------------------------
!2) calculate deviations from reference profile (layers)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    dt(:)      = t(:) - coef%tstar(:)
    dtabs(:)   = ABS(dt(:))
!------------------------------------------------------------------------------
!3) calculate (profile / reference profile) ratios; tr wr or
! if no input O3 profile, set to reference value (or =1)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    tr(:)      = t(:) / coef%tstar(:)
    tr_sq(:)   = tr(:) * tr(:)
    tr_4(:)    = tr_sq(:) * tr_sq(:)
    wr(:)      = w(:) / coef%wstar(:)

    IF (coef%nozone > 0) THEN
      dto(:) = t(:) - coef%to3star(:)
      tro(:) = t(:) / coef%to3star(:)
      IF (opts%rt_ir%ozone_data) THEN
        or(:)  = o(:) / coef%ostar(:)
      ELSE
        or(:)  = 1._jprb
      ENDIF
    ENDIF

!-CO2----------------------------------------------------------------------------

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      co2r(:) = co2(:) / coef%co2star(:)
    ELSE
      co2r(:) = 1._jprb
    ENDIF

!-N2O----------------------------------------------------------------------------

    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
      n2or(:) = n2o(:) / coef%n2ostar(:)
    ELSE
      n2or(:) = 1._jprb
    ENDIF

!-CO----------------------------------------------------------------------------

    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
      cor(:) = co(:) / coef%costar(:)
    ELSE
      cor(:) = 1._jprb
    ENDIF

!-CH4---------------------------------------------------------------------------

    IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
      ch4r(:) = ch4(:) / coef%ch4star(:)
    ELSE
      ch4r(:) = 1._jprb
    ENDIF

!-SO2--------------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      so2r(:) = so2(:) / coef%so2star(:)
    ENDIF

!-------------------------------------------------------------------
! 4. calculate profile / reference profile sums: tw wwr
!--------------------------------------------------------------------
    tw(1) = 0._jprb

    DO layer = 2, prof(1)%nlayers
      tw(layer) = tw(layer - 1) + coef%dpp(layer - 1) * tr(layer - 1)
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1            = sum1 + t(layer)
      sum2            = sum2 + coef%tstar(layer)
      sum2_tuw(layer) = sum2
      tuw(layer)      = sum1 / sum2
    ENDDO

    tuwr(1)                 = coef%dpp(0) * t(1) / (coef%dpp(0) * coef%tstar(1))
    tuwr(2:prof(1)%nlayers) = tuw(2:prof(1)%nlayers)

    IF (coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1            = sum1 + coef%dpp(layer - 1) * t(layer)
        sum2            = sum2 + coef%dpp(layer - 1) * coef%tstar(layer)
        sum2_twr(layer) = sum2
        twr(layer)      = sum1 / sum2
      ENDDO
    ENDIF

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1            = sum1 + coef%dpp(layer - 1) * w(layer) * t(layer)
      sum2            = sum2 + coef%dpp(layer - 1) * coef%wstar(layer) * coef%tstar(layer)
      sum2_wwr(layer) = sum2
      wwr(layer)      = sum1 / sum2
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1           = sum1 + coef%dpp(layer - 1) * w(layer)
      sum2           = sum2 + coef%dpp(layer - 1) * coef%wstar(layer)
      sum2_ww(layer) = sum2
      ww(layer)      = sum1 / sum2
    ENDDO


    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1           = sum1 + coef%dpp(layer - 1) * o(layer)
        sum2           = sum2 + coef%dpp(layer - 1) * coef%ostar(layer)
        sum2_ow(layer) = sum2
        ow(layer)      = sum1 / sum2
      ENDDO

    ELSE
      sum2_ow(:) = 0._jprb
      ow(:)      = 1._jprb
    ENDIF


    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1             = sum1 + coef%dpp(layer - 1) * co2(layer)
        sum2             = sum2 + coef%dpp(layer - 1) * coef%co2star(layer)
        sum2_co2w(layer) = sum2
        co2w(layer)      = sum1 / sum2
      ENDDO

    ELSE
      sum2_co2w(:) = 0._jprb
      co2w(:)      = 1._jprb
    ENDIF

!-N2O---------------------------------------------------------------------------

    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1        = sum1 + coef%dpp(layer - 1) * n2o(layer)
          sum2        = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer)
          sum2_n2ow(layer) = sum2
          n2ow(layer) = sum1 / sum2
        ENDDO
  
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * n2o(layer) * t(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          sum2_n2owr(layer) = sum2
          n2owr(layer) = sum1 / sum2
        ENDDO
  
      ELSE
        sum2_n2ow(:) = 0._jprb
        n2ow(:)  = 1._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb
    
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * coef%n2ostar(layer) * t(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          sum2_n2owr(layer) = sum2
          n2owr(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF

!-CO---------------------------------------------------------------------------

    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1       = sum1 + coef%dpp(layer - 1) * co(layer)
          sum2       = sum2 + coef%dpp(layer - 1) * coef%costar(layer)
          sum2_cow(layer) = sum2
          cow(layer) = sum1 / sum2
        ENDDO

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1        = sum1 + coef%dpp(layer - 1) * co(layer) * t(layer)
          sum2        = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          sum2_cowr(layer) = sum2
          cowr(layer) = sum1 / sum2
        ENDDO

      ELSE
        sum2_cow(:) = 0._jprb
        cow(:)  = 1._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1        = sum1 + coef%dpp(layer - 1) * coef%costar(layer) * t(layer)
          sum2        = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          sum2_cowr(layer) = sum2
          cowr(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF

!-CH4---------------------------------------------------------------------------

    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1        = sum1 + coef%dpp(layer - 1) * ch4(layer)
          sum2        = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer)
          sum2_ch4w(layer) = sum2
          ch4w(layer) = sum1 / sum2
        ENDDO
  
        sum1 = 0._jprb
        sum2 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * ch4(layer) * t(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          sum2_ch4wr(layer) = sum2
          ch4wr(layer) = sum1 / sum2
        ENDDO
  
      ELSE
        sum2_ch4w(:) = 0._jprb
        ch4w(:)  = 1._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb
    
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * coef%ch4star(layer) * t(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          sum2_ch4wr(layer) = sum2
          ch4wr(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF

!-SO2---------------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1        = sum1 + coef%dpp(layer - 1) * so2(layer)
        sum2        = sum2 + coef%dpp(layer - 1) * coef%so2star(layer)
        sum2_so2w(layer) = sum2
        so2w(layer) = sum1 / sum2
      ENDDO

      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1         = sum1 + coef%dpp(layer - 1) * so2(layer) * t(layer)
        sum2         = sum2 + coef%dpp(layer - 1) * coef%so2star(layer) * coef%tstar(layer)
        sum2_so2wr(layer) = sum2
        so2wr(layer) = sum1 / sum2
      ENDDO
    ENDIF

!-------------------------------------------------------------------------
! Adjoint code
!-------------------------------------------------------------------------
! DAR - 1:nlayers is seemingly necessary to stop ifort from optimising these lines out at -O3

    w_ad(1:nlayers)        = 0._jprb
    wr_ad(1:nlayers)       = 0._jprb
    ww_ad(1:nlayers)       = 0._jprb
    wwr_ad(1:nlayers)      = 0._jprb
    sec_wr_ad(1:nlayers)   = 0._jprb
    sec_wrwr_ad(1:nlayers) = 0._jprb
    dt_ad(1:nlayers)       = 0._jprb
    dto_ad(1:nlayers)      = 0._jprb
    t_ad(1:nlayers)        = 0._jprb
    tr_ad(1:nlayers)       = 0._jprb
    tro_ad(1:nlayers)      = 0._jprb
    tw_ad(1:nlayers)       = 0._jprb
    twr_ad(1:nlayers)      = 0._jprb
    tuw_ad(1:nlayers)      = 0._jprb
    tuwr_ad(1:nlayers)     = 0._jprb
    ch4_ad(1:nlayers)      = 0._jprb
    ch4r_ad(1:nlayers)     = 0._jprb
    ch4w_ad(1:nlayers)     = 0._jprb
    ch4wr_ad(1:nlayers)    = 0._jprb
    so2_ad(1:nlayers)      = 0._jprb
    so2r_ad(1:nlayers)     = 0._jprb
    so2w_ad(1:nlayers)     = 0._jprb
    so2wr_ad(1:nlayers)    = 0._jprb
    sec_so2_ad(1:nlayers)  = 0._jprb
    sec_so2so2_ad(1:nlayers) = 0._jprb
    co_ad(1:nlayers)       = 0._jprb
    cor_ad(1:nlayers)      = 0._jprb
    cow_ad(1:nlayers)      = 0._jprb
    cowr_ad(1:nlayers)     = 0._jprb
    n2o_ad(1:nlayers)      = 0._jprb
    n2or_ad(1:nlayers)     = 0._jprb
    n2ow_ad(1:nlayers)     = 0._jprb
    n2owr_ad(1:nlayers)    = 0._jprb
    co2_ad(1:nlayers)      = 0._jprb
    co2r_ad(1:nlayers)     = 0._jprb
    co2w_ad(1:nlayers)     = 0._jprb

!    so2
!-------------------------------------------------
!

    DO layer = 1, prof(1)%nlayers
      level = layer + 1

      IF (coef%nso2 == 19) THEN
        sec_so2 = ray_path(layer,iprof) * so2r(layer)
        sec_so2so2 = sec_so2(layer) * so2r(layer)
        so2r_ad(layer)                        = so2r_ad(layer) +      &
            predictors_ad(iprof)%so2(19, layer) * 2._jprb * predictors(iprof)%so2(7, layer) / so2w(layer)
        so2w_ad(layer)                        = so2w_ad(layer) -                                         &
            predictors_ad(iprof)%so2(19, layer) * predictors(iprof)%so2(1, layer) /  &
            (ray_path(layer,iprof) * so2w(layer) ** 2_jpim)
        ray_path_ad(layer,iprof) =      &
            ray_path_ad(layer,iprof) + predictors_ad(iprof)%so2(19, layer) * so2r(layer) ** 2_jpim / so2w(layer)
        dt_ad(layer)                        =      &
            dt_ad(layer) + predictors_ad(iprof)%so2(18, layer) * predictors(iprof)%so2(7, layer) ** 1.5_jprb
        so2r_ad(layer)                        = so2r_ad(layer) +                                               &
            predictors_ad(iprof)%so2(18, layer) * 1.5_jprb * predictors(iprof)%so2(5, layer) *  &
            ray_path(layer,iprof) * dt(layer)
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +                                    &
            predictors_ad(iprof)%so2(18, layer) * 1.5_jprb * predictors(iprof)%so2(5, layer) * so2r(layer) *  &
            dt(layer)
        so2r_ad(layer)                        =      &
            so2r_ad(layer) + predictors_ad(iprof)%so2(17, layer) * 1.5_jprb * predictors(iprof)%so2(5, layer)
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +      &
            predictors_ad(iprof)%so2(17, layer) * 0.5_jprb * so2r(layer) ** 1.5_jprb / ray_path(layer,iprof) ** 0.5
        so2w_ad(layer)                        = so2w_ad(layer) +                                         &
            predictors_ad(iprof)%so2(16, layer) * 1.25_jprb * ray_path(layer,iprof) *  &
            (predictors(iprof)%so2(2, layer)) ** 0.25_jprb
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +      &
            predictors_ad(iprof)%so2(16, layer) * 1.25_jprb * so2w(layer) * &
            (predictors(iprof)%so2(2, layer)) ** 0.25_jprb
        so2r_ad(layer)                        = so2r_ad(layer) +                                        &
            predictors_ad(iprof)%so2(15, layer) * 1.5_jprb * ray_path(layer,iprof) *  &
            SQRT(predictors(iprof)%so2(7, layer))
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +      &
            predictors_ad(iprof)%so2(15, layer) * 1.5_jprb * so2r(layer) * SQRT(predictors(iprof)%so2(7, layer))
        so2w_ad(layer)                        = so2w_ad(layer) +                                        &
            predictors_ad(iprof)%so2(14, layer) * 1.5_jprb * ray_path(layer,iprof) *  &
            SQRT(predictors(iprof)%so2(2, layer))
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +      &
            predictors_ad(iprof)%so2(14, layer) * 1.5_jprb * so2w(layer) * SQRT(predictors(iprof)%so2(2, layer))
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +                       &
            predictors_ad(iprof)%so2(13, layer) * 0.5_jprb / SQRT(ray_path(layer,iprof)) *  &
            (so2r(layer) ** 1.5_jprb / so2wr(layer))
        so2r_ad(layer)                        = so2r_ad(layer) + &
            predictors_ad(iprof)%so2(13, layer) * SQRT(ray_path(layer,iprof)) * &
            1.5_jprb * so2r(layer) ** 0.5_jprb / so2wr(layer)
        so2wr_ad(layer)                       = so2wr_ad(layer) - &
            predictors_ad(iprof)%so2(13, layer) * SQRT(ray_path(layer,iprof)) * &
            so2r(layer) ** 1.5_jprb / so2wr(layer) ** 2_jpim
        sec_so2so2_ad(layer)                  =      &
            sec_so2so2_ad(layer) + predictors_ad(iprof)%so2(12, layer) / so2wr(layer)
        so2wr_ad(layer)                       =      &
            so2wr_ad(layer) - predictors_ad(iprof)%so2(12, layer) * sec_so2so2(layer) / so2wr(layer) ** 2_jpim
        dt_ad(layer)                        =      &
            dt_ad(layer) + predictors_ad(iprof)%so2(11, layer) * predictors(iprof)%so2(5, layer)
        sec_so2_ad(layer)                    = sec_so2_ad(layer) +      &
            0.5_jprb * predictors_ad(iprof)%so2(11, layer) * dt(layer) / predictors(iprof)%so2(5, layer)
        sec_so2_ad(layer)                    =      &
            sec_so2_ad(layer) + predictors_ad(iprof)%so2(10, layer) * dtabs(layer) * dt(layer)
        dt_ad(layer)                        = dt_ad(layer) +      &
            2._jprb * predictors_ad(iprof)%so2(10, layer) * predictors(iprof)%so2(7, layer) * dtabs(layer)
        sec_so2_ad(layer)                    =      &
            sec_so2_ad(layer) + predictors_ad(iprof)%so2(9, layer) * 4._jprb * predictors(iprof)%so2(8, layer)
        sec_so2_ad(layer)                    =      &
            sec_so2_ad(layer) + 3._jprb * predictors_ad(iprof)%so2(8, layer) * predictors(iprof)%so2(1, layer)
        sec_so2_ad(layer)                    = sec_so2_ad(layer) + predictors_ad(iprof)%so2(7, layer)
        sec_so2_ad(layer)                    = sec_so2_ad(layer) +      &
            0.25_jprb * predictors_ad(iprof)%so2(6, layer) / predictors(iprof)%so2(6, layer) ** 3_jpim
        sec_so2_ad(layer)                    =      &
            sec_so2_ad(layer) + 0.5_jprb * predictors_ad(iprof)%so2(5, layer) / predictors(iprof)%so2(5, layer)
        dt_ad(layer)                        =      &
            dt_ad(layer) + predictors_ad(iprof)%so2(4, layer) * predictors(iprof)%so2(7, layer)
        sec_so2_ad(layer)                    = sec_so2_ad(layer) + predictors_ad(iprof)%so2(4, layer) * dt(layer)
        so2w_ad(layer)                        = so2w_ad(layer) +                                            &
            predictors_ad(iprof)%so2(3, layer) * 2._jprb * predictors(iprof)%so2(2, layer) *  &
            ray_path(layer,iprof)
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) +      &
            predictors_ad(iprof)%so2(3, layer) * 2._jprb * predictors(iprof)%so2(2, layer) * so2w(layer)
        so2w_ad(layer)                        =      &
            so2w_ad(layer) + predictors_ad(iprof)%so2(2, layer) * ray_path(layer,iprof)
        ray_path_ad(layer,iprof) =      &
            ray_path_ad(layer,iprof) + predictors_ad(iprof)%so2(2, layer) * so2w(layer)
        sec_so2_ad(layer)                    =      &
            sec_so2_ad(layer) + 2 * predictors_ad(iprof)%so2(1, layer) * predictors(iprof)%so2(7, layer)
        sec_so2_ad(layer)                    = sec_so2_ad(layer) + sec_so2so2_ad(layer) * so2r(layer)
        so2r_ad(layer)                       = so2r_ad(layer) + sec_so2so2_ad(layer) * predictors(iprof)%so2(7, layer)
        so2r_ad(layer)                       = so2r_ad(layer) + sec_so2_ad(layer) * ray_path(layer,iprof)
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) + sec_so2_ad(layer) * so2r(layer)
      ENDIF


!5.9 ch4            transmittance based on RTIASI
!-------------------------------------------------
!

      IF (coef%nch4 > 0) THEN
        ch4r_ad(layer)                      =      &
           ch4r_ad(layer) + predictors_ad(iprof)%ch4(11, layer) * 1.5_jprb * predictors(iprof)%ch4(2, layer) / ch4w(layer)
        ch4w_ad(layer)                      = ch4w_ad(layer) -                            &
           predictors_ad(iprof)%ch4(11, layer) * predictors(iprof)%ch4(2, layer) ** 3_jpim /  &
           (ray_path(layer, iprof) * ch4w(layer) ** 2_jpim)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ch4(11, layer) * 0.5_jprb * ch4r(layer) ** 1.5_jprb /             &
           (ray_path(layer, iprof) ** 0.5_jprb * ch4w(layer))
        ch4w_ad(layer)                      =      &
           ch4w_ad(layer) + ray_path(layer, iprof) * predictors_ad(iprof)%ch4(10, layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ch4(10, layer) * ch4w(layer)
        ch4w_ad(layer)                      = ch4w_ad(layer) +      &
           predictors_ad(iprof)%ch4(9, layer) * predictors(iprof)%ch4(10, layer) * 2._jprb * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ch4(9, layer) * 2._jprb * predictors(iprof)%ch4(10, layer) * ch4w(layer)
        ch4wr_ad(layer)                     = ch4wr_ad(layer) + predictors_ad(iprof)%ch4(8, layer)
        ch4wr_ad(layer)                     =      &
           ch4wr_ad(layer) + predictors_ad(iprof)%ch4(7, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ch4(7, layer) * ch4wr(layer)
        ch4r_ad(layer)                      = ch4r_ad(layer) +                              &
           predictors_ad(iprof)%ch4(6, layer) * ray_path(layer, iprof) * 0.25_jprb /  &
           predictors(iprof)%ch4(6, layer) ** 3_jpim
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ch4(6, layer) * ch4r(layer) * 0.25_jprb / predictors(iprof)%ch4(6, layer) ** 3_jpim
        dt_ad(layer)                        = dt_ad(layer) + predictors_ad(iprof)%ch4(5, layer) * ch4r(layer)
        ch4r_ad(layer)                      = ch4r_ad(layer) + predictors_ad(iprof)%ch4(5, layer) * dt(layer)
        ch4r_ad(layer)                      = ch4r_ad(layer) +      &
           predictors_ad(iprof)%ch4(4, layer) * predictors(iprof)%ch4(1, layer) * ray_path(layer, iprof) * 2._jprb
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ch4(4, layer) * 2._jprb * predictors(iprof)%ch4(1, layer) * ch4r(layer)
        dt_ad(layer)                        =      &
           dt_ad(layer) + predictors_ad(iprof)%ch4(3, layer) * predictors(iprof)%ch4(1, layer)
        ch4r_ad(layer)                      =      &
           ch4r_ad(layer) + predictors_ad(iprof)%ch4(3, layer) * ray_path(layer, iprof) * dt(layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ch4(3, layer) * ch4r(layer) * dt(layer)
        ch4r_ad(layer)                      = ch4r_ad(layer) +      &
           predictors_ad(iprof)%ch4(2, layer) * 0.5_jprb * ray_path(layer, iprof) / predictors(iprof)%ch4(2, layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ch4(2, layer) * 0.5_jprb * ch4r(layer) / predictors(iprof)%ch4(2, layer)
        ch4r_ad(layer)                      =      &
           ch4r_ad(layer) + predictors_ad(iprof)%ch4(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ch4(1, layer) * ch4r(layer)
      ENDIF

!5.8 co             transmittance based on RTIASI
!-------------------------------------------------
!

      IF (coef%nco > 0) THEN
        cow_ad(layer) = cow_ad(layer) + ray_path(layer,iprof) * predictors_ad(iprof)%co(14, layer)
        ray_path_ad(layer,iprof) = ray_path_ad(layer,iprof) + cow(layer) * predictors_ad(iprof)%co(14, layer)

        cowr_ad(layer)                      = cowr_ad(layer) +                              &
           predictors_ad(iprof)%co(13, layer) * 0.25_jprb * ray_path(layer, iprof) *  &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.75_jprb)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(13, layer) * 0.25_jprb * cowr(layer) *                    &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.75_jprb)
        cowr_ad(layer)                      = cowr_ad(layer) +                             &
           predictors_ad(iprof)%co(12, layer) * ray_path(layer, iprof) * 0.4_jprb *  &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.6_jprb)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(12, layer) * cowr(layer) * 0.4_jprb *                     &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.6_jprb)
        cor_ad(layer)                       = cor_ad(layer) + &
           predictors_ad(iprof)%co(11, layer) * 2._jprb * predictors(iprof)%co(1, layer) / cow(layer) ** 0.25_jprb
        cow_ad(layer)                       = cow_ad(layer) - &
           predictors_ad(iprof)%co(11, layer) * 0.25_jprb * predictors(iprof)%co(11, layer) / cow(layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + &
           predictors_ad(iprof)%co(11, layer) * cor(layer) ** 2_jpim / cow(layer) ** 0.25_jprb
        cor_ad(layer)                       = cor_ad(layer) + &
           predictors_ad(iprof)%co(10, layer) * 2._jprb * predictors(iprof)%co(1, layer) / cow(layer) ** 0.5_jprb
        cow_ad(layer)                       =      &
           cow_ad(layer) - predictors_ad(iprof)%co(10, layer) * 0.5_jprb * predictors(iprof)%co(10, layer) / cow(layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + &
           predictors_ad(iprof)%co(10, layer) * cor(layer) ** 2_jpim / SQRT(cow(layer))
        cor_ad(layer)                       =      &
           cor_ad(layer) + predictors_ad(iprof)%co(9, layer) * 1.5_jprb * predictors(iprof)%co(2, layer) / cow(layer)
        cow_ad(layer)                       = cow_ad(layer) -                          &
           predictors_ad(iprof)%co(9, layer) * predictors(iprof)%co(2, layer) ** 3_jpim /  &
           (ray_path(layer, iprof) * cow(layer) ** 2_jpim)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(9, layer) * 0.5_jprb * cor(layer) ** 1.5_jprb /                &
           (ray_path(layer, iprof) ** 0.5_jprb * cow(layer))
        cor_ad(layer)                       =      &
           cor_ad(layer) + predictors_ad(iprof)%co(8, layer) * 2._jprb * predictors(iprof)%co(1, layer) / cow(layer)
        cow_ad(layer)                       =      &
           cow_ad(layer) - predictors_ad(iprof)%co(8, layer) * predictors(iprof)%co(8, layer) / cow(layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co(8, layer) * cor(layer) ** 2_jpim / cow(layer)
        cor_ad(layer)                       = cor_ad(layer) + &
           predictors_ad(iprof)%co(7, layer) * dtabs(layer) * ray_path(layer, iprof) * dt(layer)
        dt_ad(layer)                        = dt_ad(layer) + &
           predictors_ad(iprof)%co(7, layer) * dtabs(layer) * predictors(iprof)%co(1, layer) * 2._jprb
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + &
           predictors_ad(iprof)%co(7, layer) * dtabs(layer) * cor(layer) * dt(layer)
        cor_ad(layer)                       = cor_ad(layer) +                              &
           predictors_ad(iprof)%co(6, layer) * ray_path(layer, iprof) * 0.25_jprb /  &
           predictors(iprof)%co(6, layer) ** 3_jpim
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(6, layer) * cor(layer) * 0.25_jprb / predictors(iprof)%co(6, layer) ** 3_jpim
        dt_ad(layer)                        =      &
           dt_ad(layer) + predictors_ad(iprof)%co(5, layer) * predictors(iprof)%co(2, layer)
        cor_ad(layer)                       = cor_ad(layer) +                                         &
           predictors_ad(iprof)%co(5, layer) * 0.5_jprb * dt(layer) * ray_path(layer, iprof) /  &
           predictors(iprof)%co(2, layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(5, layer) * 0.5_jprb * dt(layer) * cor(layer) / predictors(iprof)%co(2, layer)
        cor_ad(layer)                       = cor_ad(layer) +      &
           predictors_ad(iprof)%co(4, layer) * 2._jprb * predictors(iprof)%co(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(4, layer) * 2._jprb * predictors(iprof)%co(1, layer) * cor(layer)
        dt_ad(layer)                        =      &
           dt_ad(layer) + predictors_ad(iprof)%co(3, layer) * predictors(iprof)%co(1, layer)
        cor_ad(layer)                       =      &
           cor_ad(layer) + predictors_ad(iprof)%co(3, layer) * dt(layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co(3, layer) * cor(layer) * dt(layer)
        cor_ad(layer)                       = cor_ad(layer) +      &
           predictors_ad(iprof)%co(2, layer) * 0.5_jprb * ray_path(layer, iprof) / predictors(iprof)%co(2, layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co(2, layer) * 0.5_jprb * cor(layer) / predictors(iprof)%co(2, layer)
        cor_ad(layer)                       =      &
           cor_ad(layer) + predictors_ad(iprof)%co(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co(1, layer) * cor(layer)
      ENDIF

!5.7 n2o            transmittance based on RTIASI
!-------------------------------------------------
!

      IF (coef%nn2o > 0) THEN
        dt_ad(layer)                        = dt_ad(layer) + &
           predictors_ad(iprof)%n2o(13, layer) * ray_path(layer, iprof) ** 2_jpim * n2owr(layer)
        n2owr_ad(layer)                     = n2owr_ad(layer) + &
           predictors_ad(iprof)%n2o(13, layer) * ray_path(layer, iprof) ** 2_jpim * dt(layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(13, layer) * 2._jprb * ray_path(layer, iprof) * n2owr(layer) * dt(layer)
        n2owr_ad(layer)                     = n2owr_ad(layer) +                               &
           predictors_ad(iprof)%n2o(12, layer) * 3._jprb * predictors(iprof)%n2o(8, layer) ** 2_jpim *  &
           ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(12, layer) * 3._jprb * predictors(iprof)%n2o(8, layer) ** 2_jpim * n2owr(layer)
        n2owr_ad(layer)                     = n2owr_ad(layer) +      &
           predictors_ad(iprof)%n2o(11, layer) * 2._jprb * predictors(iprof)%n2o(8, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(11, layer) * predictors(iprof)%n2o(8, layer) * 2 * n2owr(layer)
        n2or_ad(layer)                      =      &
           n2or_ad(layer) + predictors_ad(iprof)%n2o(10, layer) * 1.5_jprb * predictors(iprof)%n2o(2, layer) / n2ow(layer)
        n2ow_ad(layer)                      = n2ow_ad(layer) -                            &
           predictors_ad(iprof)%n2o(10, layer) * predictors(iprof)%n2o(2, layer) ** 3_jpim /  &
           (ray_path(layer, iprof) * n2ow(layer) ** 2_jpim)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(10, layer) * 0.5_jprb * n2or(layer) ** 1.5_jprb /             &
           (ray_path(layer, iprof) ** 0.5_jprb * n2ow(layer))
        n2owr_ad(layer)                     = n2owr_ad(layer) + predictors_ad(iprof)%n2o(9, layer)
        n2owr_ad(layer)                     =      &
           n2owr_ad(layer) + predictors_ad(iprof)%n2o(8, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%n2o(8, layer) * n2owr(layer)
        n2ow_ad(layer)                      =      &
           n2ow_ad(layer) + predictors_ad(iprof)%n2o(7, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%n2o(7, layer) * n2ow(layer)
        n2or_ad(layer)                      = n2or_ad(layer) +                              &
           predictors_ad(iprof)%n2o(6, layer) * ray_path(layer, iprof) * 0.25_jprb /  &
           predictors(iprof)%n2o(6, layer) ** 3_jpim
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(6, layer) * n2or(layer) * 0.25_jprb / predictors(iprof)%n2o(6, layer) ** 3_jpim
        dt_ad(layer)                        = dt_ad(layer) + predictors_ad(iprof)%n2o(5, layer) * n2or(layer)
        n2or_ad(layer)                      = n2or_ad(layer) + predictors_ad(iprof)%n2o(5, layer) * dt(layer)
        n2or_ad(layer)                      = n2or_ad(layer) +      &
           predictors_ad(iprof)%n2o(4, layer) * 2._jprb * predictors(iprof)%n2o(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(4, layer) * 2._jprb * predictors(iprof)%n2o(1, layer) * n2or(layer)
        dt_ad(layer)                        =      &
           dt_ad(layer) + predictors_ad(iprof)%n2o(3, layer) * predictors(iprof)%n2o(1, layer)
        n2or_ad(layer)                      =      &
           n2or_ad(layer) + predictors_ad(iprof)%n2o(3, layer) * ray_path(layer, iprof) * dt(layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%n2o(3, layer) * n2or(layer) * dt(layer)
        n2or_ad(layer)                      = n2or_ad(layer) +      &
           predictors_ad(iprof)%n2o(2, layer) * 0.5_jprb * ray_path(layer, iprof) / predictors(iprof)%n2o(2, layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%n2o(2, layer) * 0.5_jprb * n2or(layer) / predictors(iprof)%n2o(2, layer)
        n2or_ad(layer)                      =      &
           n2or_ad(layer) + predictors_ad(iprof)%n2o(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%n2o(1, layer) * n2or(layer)
      ENDIF

!5.6 CO2
!-------

      IF (coef%nco2 > 0) THEN
!    co2r_ad(:)    = 0._jprb
!    co2w_ad(:)    = 0._jprb
!    twr_ad(:)     = 0._jprb
!    co2_ad(:)     = 0._jprb
        tr_ad(layer)                        =      &
           tr_ad(layer) + predictors_ad(iprof)%co2(15, layer) * 2._jprb * SQRT(predictors(iprof)%co2(15, layer)) * twr(layer)
        twr_ad(layer)                       =      &
           twr_ad(layer) + predictors_ad(iprof)%co2(15, layer) * 2._jprb * SQRT(predictors(iprof)%co2(15, layer)) * tr(layer)
        twr_ad(layer)                       = twr_ad(layer) +                             &
           predictors_ad(iprof)%co2(14, layer) * 3._jprb * twr(layer) ** 2_jpim * tr(layer) ** 2_jpim *  &
           ray_path(layer, iprof) ** 0.5_jprb
        tr_ad(layer)                        = tr_ad(layer) +      &
           predictors_ad(iprof)%co2(14, layer) * 2._jprb * tr(layer) * twr(layer) ** 3_jpim * &
           SQRT(ray_path(layer, iprof))
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +         &
           predictors_ad(iprof)%co2(14, layer) * tr(layer) ** 2_jpim * twr(layer) ** 3_jpim * 0.5_jprb /  &
           SQRT(ray_path(layer, iprof))
        tr_ad(layer)                        =      &
           tr_ad(layer) + predictors_ad(iprof)%co2(13, layer) * 3._jprb * tr(layer) ** 2_jpim * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(13, layer) * tr(layer) ** 3_jpim
        tr_ad(layer)                        = tr_ad(layer) + predictors_ad(iprof)%co2(12, layer) * 3._jprb * tr(layer) ** 2_jpim
        co2r_ad(layer)                      = co2r_ad(layer) +                              &
           predictors_ad(iprof)%co2(11, layer) * 0.5_jprb * ray_path(layer, iprof) /  &
           SQRT(predictors(iprof)%co2(1, layer))
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co2(11, layer) * 0.5_jprb * co2r(layer) / SQRT(predictors(iprof)%co2(1, layer))
        twr_ad(layer)                       = twr_ad(layer) +      &
           predictors_ad(iprof)%co2(10, layer) * ray_path(layer, iprof) * SQRT(predictors(iprof)%co2(5, layer))
        tr_ad(layer)                        = tr_ad(layer) +                               &
           predictors_ad(iprof)%co2(10, layer) * 0.5_jprb * predictors(iprof)%co2(7, layer) /  &
           SQRT(predictors(iprof)%co2(5, layer))
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(10, layer) * twr(layer) * tr(layer) ** 0.5_jprb
        twr_ad(layer)                       = twr_ad(layer) + predictors_ad(iprof)%co2(9, layer) * 3._jprb * twr(layer) ** 2_jpim
        co2w_ad(layer)                      = co2w_ad(layer) +                           &
           predictors_ad(iprof)%co2(8, layer) * 2._jprb * ray_path(layer, iprof) *  &
           SQRT(predictors(iprof)%co2(8, layer))
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%co2(8, layer) * 2._jprb * co2w(layer) * SQRT(predictors(iprof)%co2(8, layer))
        twr_ad(layer)                       =      &
           twr_ad(layer) + predictors_ad(iprof)%co2(7, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(7, layer) * twr(layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(6, layer)
        tr_ad(layer)                        = tr_ad(layer) + predictors_ad(iprof)%co2(5, layer)
        tr_ad(layer)                        =      &
           tr_ad(layer) + predictors_ad(iprof)%co2(4, layer) * 2._jprb * predictors(iprof)%co2(3, layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(4, layer) * tr(layer) ** 2_jpim
        tr_ad(layer)                        =      &
           tr_ad(layer) + predictors_ad(iprof)%co2(3, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(3, layer) * tr(layer)
        tr_ad(layer)                        =      &
           tr_ad(layer) + predictors_ad(iprof)%co2(2, layer) * 2._jprb * predictors(iprof)%co2(5, layer)
        co2r_ad(layer)                      =      &
           co2r_ad(layer) + predictors_ad(iprof)%co2(1, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%co2(1, layer) * co2r(layer)
      ENDIF

    ENDDO

!5.4 ozone
!---------

    IF (coef%nozone > 0) THEN
      o_ad(:)      = 0._jprb
      or_ad(:)     = 0._jprb
      wr_ad(:)     = 0._jprb
      ow_ad(:)     = 0._jprb
      dto_ad(:)    = 0._jprb
      sec_or_ad(:) = 0._jprb

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
! One can pack all ow_ad lines in one longer statement
! same for sec_or_ad and dto_ad
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ozone(15, layer) * tro(layer) ** 3_jpim
        tro_ad(layer)                       = tro_ad(layer) + &
           predictors_ad(iprof)%ozone(15, layer) * 3._jprb * tro(layer) ** 2_jpim * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + &
           predictors_ad(iprof)%ozone(14, layer) * 0.5_jprb * &
           ray_path(layer, iprof) ** ( - 0.5_jprb) * ow(layer) ** 2_jpim * dto(layer)
        ow_ad(layer)                        = ow_ad(layer) +      &
           predictors_ad(iprof)%ozone(14, layer) * 2._jprb * ow(layer) * &
           ray_path(layer, iprof) ** 0.5_jprb * dto(layer)
        dto_ad(layer)                       = dto_ad(layer) + &
           predictors_ad(iprof)%ozone(14, layer) * ray_path(layer, iprof) ** 0.5_jprb * ow(layer) ** 2_jpim
        ow_ad(layer)                        = ow_ad(layer) +                                   &
           predictors_ad(iprof)%ozone(13, layer) * 1.75_jprb * ray_path(layer, iprof) *  &
           (ray_path(layer, iprof) * ow(layer)) ** 0.75_jprb
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ozone(13, layer) * 1.75_jprb * ow(layer) *                   &
           (ray_path(layer, iprof) * ow(layer)) ** 0.75_jprb
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ozone(12, layer) * or(layer) / ow(layer)
        or_ad(layer)                        =      &
           or_ad(layer) + predictors_ad(iprof)%ozone(12, layer) * ray_path(layer, iprof) / ow(layer)
        ow_ad(layer)                        = ow_ad(layer) -      &
           predictors_ad(iprof)%ozone(12, layer) * or(layer) * ray_path(layer, iprof) / ow(layer) ** 2_jpim
        ow_ad(layer)                        = ow_ad(layer) +                                &
           predictors_ad(iprof)%ozone(11, layer) * 2._jprb * ray_path(layer, iprof) *  &
           predictors(iprof)%ozone(10, layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ozone(11, layer) * 2._jprb * ow(layer) * predictors(iprof)%ozone(10, layer)
        ow_ad(layer)                        =      &
           ow_ad(layer) + predictors_ad(iprof)%ozone(10, layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ozone(10, layer) * ow(layer)
        or_ad(layer)                        = or_ad(layer) +                                             &
           predictors_ad(iprof)%ozone(9, layer) * SQRT(ray_path(layer, iprof) * ow(layer)) *  &
           ray_path(layer, iprof)
        ow_ad(layer)                        = ow_ad(layer) +                                  &
           predictors_ad(iprof)%ozone(9, layer) * predictors(iprof)%ozone(1, layer) * 0.5_jprb *  &
           ray_path(layer, iprof) / SQRT(ray_path(layer, iprof) * ow(layer))
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ozone(9, layer) * 1.5_jprb * or(layer) * SQRT(predictors(iprof)%ozone(10, layer))
        or_ad(layer)                        =      &
           or_ad(layer) + predictors_ad(iprof)%ozone(8, layer) * predictors(iprof)%ozone(10, layer)
        ow_ad(layer)                        =      &
           ow_ad(layer) + predictors_ad(iprof)%ozone(8, layer) * ray_path(layer, iprof) * or(layer)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ozone(8, layer) * or(layer) * ow(layer)
        or_ad(layer)                        = or_ad(layer) + &
           predictors_ad(iprof)%ozone(7, layer) * 1.5_jprb * predictors(iprof)%ozone(2, layer) / ow(layer)
        ow_ad(layer)                        =      &
           ow_ad(layer) - predictors_ad(iprof)%ozone(7, layer) * predictors(iprof)%ozone(7, layer) / ow(layer)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
           predictors_ad(iprof)%ozone(7, layer) * 0.5_jprb * or(layer) ** 1.5_jprb /              &
           (ray_path(layer, iprof) ** 0.5_jprb * ow(layer))
        or_ad(layer)                        = or_ad(layer) + &
           predictors_ad(iprof)%ozone(6, layer) * 2._jprb * predictors(iprof)%ozone(1, layer) * ow(layer)
        ow_ad(layer)                        = ow_ad(layer) +      &
           predictors_ad(iprof)%ozone(6, layer) * predictors(iprof)%ozone(4, layer) / ray_path(layer, iprof)
        ray_path_ad(layer, iprof) =      &
           ray_path_ad(layer, iprof) + predictors_ad(iprof)%ozone(6, layer) * or(layer) ** 2_jpim * ow(layer)
        sec_or_ad(layer)                    = sec_or_ad(layer) +                                   &
           predictors_ad(iprof)%ozone(5, layer) * 0.5_jprb * predictors(iprof)%ozone(3, layer) /  &
           (predictors(iprof)%ozone(1, layer) * predictors(iprof)%ozone(2, layer))
        dto_ad(layer)                       =      &
           dto_ad(layer) + predictors_ad(iprof)%ozone(5, layer) * predictors(iprof)%ozone(2, layer)
        sec_or_ad(layer)                    =      &
           sec_or_ad(layer) + predictors_ad(iprof)%ozone(4, layer) * 2._jprb * predictors(iprof)%ozone(1, layer)
        sec_or_ad(layer)                    = sec_or_ad(layer) +      &
           predictors_ad(iprof)%ozone(3, layer) * predictors(iprof)%ozone(3, layer) / predictors(iprof)%ozone(1, layer)
        dto_ad(layer)                       =      &
           dto_ad(layer) + predictors_ad(iprof)%ozone(3, layer) * predictors(iprof)%ozone(1, layer)
        sec_or_ad(layer)                    =      &
           sec_or_ad(layer) + predictors_ad(iprof)%ozone(2, layer) * 0.5_jprb / predictors(iprof)%ozone(2, layer)
        sec_or_ad(layer)                    = sec_or_ad(layer) + predictors_ad(iprof)%ozone(1, layer)
        or_ad(layer)                        = or_ad(layer) + sec_or_ad(layer) * ray_path(layer, iprof)
        ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + sec_or_ad(layer) * or(layer)
      ENDDO

    ENDIF

!5.3 Water Vapour Continuum based on RTIASI
!------------------------------------------

    IF (coef%nwvcont > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level              = layer + 1
        sec_wr_ad(layer)   = sec_wr_ad(layer) + predictors_ad(iprof)%wvcont(4, layer) / tr_sq(layer)
        tr_ad(layer)       = tr_ad(layer) -      &
           2._jprb * predictors_ad(iprof)%wvcont(4, layer) * &
           predictors(iprof)%watervapour(7, layer) / (tr_sq(layer) * tr(layer))
        sec_wr_ad(layer)   = sec_wr_ad(layer) + predictors_ad(iprof)%wvcont(3, layer) / tr(layer)
        tr_ad(layer)       =      &
           tr_ad(layer) - predictors_ad(iprof)%wvcont(3, layer) * &
           predictors(iprof)%watervapour(7, layer) / tr_sq(layer)
        sec_wrwr_ad(layer) = sec_wrwr_ad(layer) + predictors_ad(iprof)%wvcont(2, layer) / tr_4(layer)
        tr_ad(layer)       =      &
           tr_ad(layer) - 4._jprb * predictors_ad(iprof)%wvcont(2, layer) * &
           predictors(iprof)%wvcont(1, layer) / tr_4(layer)
        sec_wrwr_ad(layer) = sec_wrwr_ad(layer) + predictors_ad(iprof)%wvcont(1, layer) / tr(layer)
        tr_ad(layer)       =      &
           tr_ad(layer) - predictors_ad(iprof)%wvcont(1, layer) * predictors(iprof)%wvcont(1, layer) / tr(layer)
      ENDDO

    ENDIF

!
!5.2 water vapour based on RTIASI
!--------------------------------

    DO layer = 1, prof(1)%nlayers
      level = layer + 1
      sec_wr = ray_path(layer, iprof) * wr(layer)
      sec_wrwr = sec_wr(layer) * wr(layer)
      wr_ad(layer)                        = wr_ad(layer) +      &
         predictors_ad(iprof)%watervapour(19, layer) * 2._jprb * predictors(iprof)%watervapour(7, layer) / ww(layer)
      ww_ad(layer)                        = ww_ad(layer) -                                         &
         predictors_ad(iprof)%watervapour(19, layer) * predictors(iprof)%watervapour(1, layer) /  &
         (ray_path(layer, iprof) * ww(layer) ** 2_jpim)
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%watervapour(19, layer) * wr(layer) ** 2_jpim / ww(layer)
      dt_ad(layer)                        =      &
         dt_ad(layer) + predictors_ad(iprof)%watervapour(18, layer) * predictors(iprof)%watervapour(7, layer) ** 1.5_jprb
      wr_ad(layer)                        = wr_ad(layer) +                                               &
         predictors_ad(iprof)%watervapour(18, layer) * 1.5_jprb * predictors(iprof)%watervapour(5, layer) *  &
         ray_path(layer, iprof) * dt(layer)
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +                                    &
         predictors_ad(iprof)%watervapour(18, layer) * 1.5_jprb * predictors(iprof)%watervapour(5, layer) * wr(layer) *  &
         dt(layer)
      wr_ad(layer)                        =      &
         wr_ad(layer) + predictors_ad(iprof)%watervapour(17, layer) * 1.5_jprb * predictors(iprof)%watervapour(5, layer)
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%watervapour(17, layer) * 0.5_jprb * wr(layer) ** 1.5_jprb / ray_path(layer, iprof) ** 0.5
      ww_ad(layer)                        = ww_ad(layer) +                                         &
         predictors_ad(iprof)%watervapour(16, layer) * 1.25_jprb * ray_path(layer, iprof) *  &
         (predictors(iprof)%watervapour(2, layer)) ** 0.25_jprb
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%watervapour(16, layer) * 1.25_jprb * ww(layer) * &
         (predictors(iprof)%watervapour(2, layer)) ** 0.25_jprb
      wr_ad(layer)                        = wr_ad(layer) +                                        &
         predictors_ad(iprof)%watervapour(15, layer) * 1.5_jprb * ray_path(layer, iprof) *  &
         SQRT(predictors(iprof)%watervapour(7, layer))
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%watervapour(15, layer) * 1.5_jprb * wr(layer) * SQRT(predictors(iprof)%watervapour(7, layer))
      ww_ad(layer)                        = ww_ad(layer) +                                        &
         predictors_ad(iprof)%watervapour(14, layer) * 1.5_jprb * ray_path(layer, iprof) *  &
         SQRT(predictors(iprof)%watervapour(2, layer))
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%watervapour(14, layer) * 1.5_jprb * ww(layer) * SQRT(predictors(iprof)%watervapour(2, layer))
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +                       &
         predictors_ad(iprof)%watervapour(13, layer) * 0.5_jprb / SQRT(ray_path(layer, iprof)) *  &
         (wr(layer) ** 1.5_jprb / wwr(layer))
      wr_ad(layer)                        = wr_ad(layer) + &
         predictors_ad(iprof)%watervapour(13, layer) * SQRT(ray_path(layer, iprof)) * &
         1.5_jprb * wr(layer) ** 0.5_jprb / wwr(layer)
      wwr_ad(layer)                       = wwr_ad(layer) - &
         predictors_ad(iprof)%watervapour(13, layer) * SQRT(ray_path(layer, iprof)) * &
         wr(layer) ** 1.5_jprb / wwr(layer) ** 2_jpim
      sec_wrwr_ad(layer)                  =      &
         sec_wrwr_ad(layer) + predictors_ad(iprof)%watervapour(12, layer) / wwr(layer)
      wwr_ad(layer)                       =      &
         wwr_ad(layer) - predictors_ad(iprof)%watervapour(12, layer) * sec_wrwr(layer) / wwr(layer) ** 2_jpim
      dt_ad(layer)                        =      &
         dt_ad(layer) + predictors_ad(iprof)%watervapour(11, layer) * predictors(iprof)%watervapour(5, layer)
      sec_wr_ad(layer)                    = sec_wr_ad(layer) +      &
         0.5_jprb * predictors_ad(iprof)%watervapour(11, layer) * dt(layer) / predictors(iprof)%watervapour(5, layer)
      sec_wr_ad(layer)                    =      &
         sec_wr_ad(layer) + predictors_ad(iprof)%watervapour(10, layer) * dtabs(layer) * dt(layer)
      dt_ad(layer)                        = dt_ad(layer) +      &
         2._jprb * predictors_ad(iprof)%watervapour(10, layer) * predictors(iprof)%watervapour(7, layer) * dtabs(layer)
      sec_wr_ad(layer)                    =      &
         sec_wr_ad(layer) + predictors_ad(iprof)%watervapour(9, layer) * 4._jprb * predictors(iprof)%watervapour(8, layer)
      sec_wr_ad(layer)                    =      &
         sec_wr_ad(layer) + 3._jprb * predictors_ad(iprof)%watervapour(8, layer) * predictors(iprof)%watervapour(1, layer)
      sec_wr_ad(layer)                    = sec_wr_ad(layer) + predictors_ad(iprof)%watervapour(7, layer)
      sec_wr_ad(layer)                    = sec_wr_ad(layer) +      &
         0.25_jprb * predictors_ad(iprof)%watervapour(6, layer) / predictors(iprof)%watervapour(6, layer) ** 3_jpim
      sec_wr_ad(layer)                    =      &
         sec_wr_ad(layer) + 0.5_jprb * predictors_ad(iprof)%watervapour(5, layer) / predictors(iprof)%watervapour(5, layer)
      dt_ad(layer)                        =      &
         dt_ad(layer) + predictors_ad(iprof)%watervapour(4, layer) * predictors(iprof)%watervapour(7, layer)
      sec_wr_ad(layer)                    = sec_wr_ad(layer) + predictors_ad(iprof)%watervapour(4, layer) * dt(layer)
      ww_ad(layer)                        = ww_ad(layer) +                                            &
         predictors_ad(iprof)%watervapour(3, layer) * 2._jprb * predictors(iprof)%watervapour(2, layer) *  &
         ray_path(layer, iprof)
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%watervapour(3, layer) * 2._jprb * predictors(iprof)%watervapour(2, layer) * ww(layer)
      ww_ad(layer)                        =      &
         ww_ad(layer) + predictors_ad(iprof)%watervapour(2, layer) * ray_path(layer, iprof)
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%watervapour(2, layer) * ww(layer)
      sec_wr_ad(layer)                    =      &
         sec_wr_ad(layer) + 2 * predictors_ad(iprof)%watervapour(1, layer) * predictors(iprof)%watervapour(7, layer)
      sec_wr_ad(layer)                    = sec_wr_ad(layer) + sec_wrwr_ad(layer) * wr(layer)
      wr_ad(layer)                        = wr_ad(layer) + sec_wrwr_ad(layer) * predictors(iprof)%watervapour(7, layer)
      wr_ad(layer)                        = wr_ad(layer) + sec_wr_ad(layer) * ray_path(layer, iprof)
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) + sec_wr_ad(layer) * wr(layer)
!5.1 mixed gases
!---------------
! X10
      tr_ad(layer)                        = tr_ad(layer) +      &
         predictors_ad(iprof)%mixedgas(10, layer) * 0.5_jprb * ray_path(layer, iprof) ** 1.5_jprb / SQRT(tr(layer))
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%mixedgas(10, layer) * 1.5_jprb * SQRT(predictors(iprof)%mixedgas(3, layer))
! X9
      tr_ad(layer)                        =      &
         tr_ad(layer) + predictors_ad(iprof)%mixedgas(9, layer) * 3._jprb * ray_path(layer, iprof) * tr(layer) ** 2_jpim
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%mixedgas(9, layer) * tr(layer) ** 3_jpim
! X8
      tuwr_ad(layer)                      =      &
         tuwr_ad(layer) + predictors_ad(iprof)%mixedgas(8, layer) * ray_path(layer, iprof)
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%mixedgas(8, layer) * tuwr(layer)
! X7
      tuw_ad(layer)                       =      &
         tuw_ad(layer) + predictors_ad(iprof)%mixedgas(7, layer) * ray_path(layer, iprof)
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%mixedgas(7, layer) * tuw(layer)
! X6
      tr_ad(layer)                        =      &
         tr_ad(layer) + predictors_ad(iprof)%mixedgas(6, layer) * 2._jprb * predictors(iprof)%mixedgas(5, layer)
! X5
      tr_ad(layer)                        = tr_ad(layer) + predictors_ad(iprof)%mixedgas(5, layer)
! X4
      tr_ad(layer)                        =      &
         tr_ad(layer) + predictors_ad(iprof)%mixedgas(4, layer) * 2._jprb * predictors(iprof)%mixedgas(3, layer)
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%mixedgas(4, layer) * predictors(iprof)%mixedgas(5, layer) ** 2_jpim
! X3
      tr_ad(layer)                        =      &
         tr_ad(layer) + predictors_ad(iprof)%mixedgas(3, layer) * ray_path(layer, iprof)
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%mixedgas(3, layer) * tr(layer)
! X2
      ray_path_ad(layer, iprof) = ray_path_ad(layer, iprof) +      &
         predictors_ad(iprof)%mixedgas(2, layer) * 2._jprb * ray_path(layer, iprof)
! X1
      ray_path_ad(layer, iprof) =      &
         ray_path_ad(layer, iprof) + predictors_ad(iprof)%mixedgas(1, layer)
    ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile/reference sums
!-------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb

      DO layer = prof(1)%nlayers, 1,  - 1
        sum1          = sum1 + so2w_ad(layer) / sum2_so2w(layer)
        so2_ad(layer) = so2_ad(layer) + sum1 * coef%dpp(layer - 1)
      ENDDO

      sum1 = 0._jprb

      DO layer = prof(1)%nlayers, 1,  - 1
        sum1          = sum1 + so2wr_ad(layer) / sum2_so2wr(layer)
        so2_ad(layer) = so2_ad(layer) + sum1 * coef%dpp(layer - 1) * t(layer)
        t_ad(layer)   = t_ad(layer) + sum1 * coef%dpp(layer - 1) * so2(layer)
      ENDDO
    ENDIF

    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + ch4w_ad(layer) / sum2_ch4w(layer)
          ch4_ad(layer) = ch4_ad(layer) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + ch4wr_ad(layer) / sum2_ch4wr(layer)
          ch4_ad(layer) = ch4_ad(layer) + sum1 * coef%dpp(layer - 1) * t(layer)
          t_ad(layer)   = t_ad(layer) + sum1 * coef%dpp(layer - 1) * ch4(layer)
        ENDDO

      ELSE
        ch4_ad(:) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + ch4wr_ad(layer) / sum2_ch4wr(layer)
          t_ad(layer)   = t_ad(layer) + sum1 * coef%dpp(layer - 1) * coef%ch4star(layer)
        ENDDO

      ENDIF
    ENDIF


    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1         = sum1 + cow_ad(layer) / sum2_cow(layer)
          co_ad(layer) = co_ad(layer) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1         = sum1 + cowr_ad(layer) / sum2_cowr(layer)
          co_ad(layer) = co_ad(layer) + sum1 * coef%dpp(layer - 1) * t(layer)
          t_ad(layer)  = t_ad(layer) + sum1 * coef%dpp(layer - 1) * co(layer)
        ENDDO

      ELSE
        co_ad(:) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1         = sum1 + cowr_ad(layer) / sum2_cowr(layer)
          t_ad(layer)  = t_ad(layer) + sum1 * coef%dpp(layer - 1) * coef%costar(layer)
        ENDDO

      ENDIF
    ENDIF


    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + n2ow_ad(layer) / sum2_n2ow(layer)
          n2o_ad(layer) = n2o_ad(layer) + sum1 * coef%dpp(layer - 1)
        ENDDO

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + n2owr_ad(layer) / sum2_n2owr(layer)
          n2o_ad(layer) = n2o_ad(layer) + sum1 * coef%dpp(layer - 1) * t(layer)
          t_ad(layer)   = t_ad(layer) + sum1 * coef%dpp(layer - 1) * n2o(layer)
        ENDDO

      ELSE
        n2o_ad(:) = 0._jprb

        sum1 = 0._jprb

        DO layer = prof(1)%nlayers, 1,  - 1
          sum1          = sum1 + n2owr_ad(layer) / sum2_n2owr(layer)
          t_ad(layer)   = t_ad(layer) + sum1 * coef%dpp(layer - 1) * coef%n2ostar(layer)
        ENDDO

      ENDIF
    ENDIF

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb

      DO layer = prof(1)%nlayers, 1,  - 1
        sum1          = sum1 + co2w_ad(layer) / sum2_co2w(layer)
        co2_ad(layer) = co2_ad(layer) + sum1 * coef%dpp(layer - 1)
      ENDDO

    ELSE
      co2_ad(:) = 0._jprb
    ENDIF

!
    sum1 = 0._jprb

    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN

      DO layer = prof(1)%nlayers, 1,  - 1
        sum1        = sum1 + ow_ad(layer) / sum2_ow(layer)
        o_ad(layer) = o_ad(layer) + sum1 * coef%dpp(layer - 1)
      ENDDO

    ELSE
      o_ad(:) = 0._jprb
    ENDIF

!
    sum1 = 0._jprb

    DO layer = prof(1)%nlayers, 1,  - 1
      sum1        = sum1 + wwr_ad(layer) / sum2_wwr(layer)
      w_ad(layer) = w_ad(layer) + sum1 * coef%dpp(layer - 1) * t(layer)
      t_ad(layer) = t_ad(layer) + sum1 * coef%dpp(layer - 1) * w(layer)
    ENDDO

!
    sum1 = 0._jprb

    DO layer = prof(1)%nlayers, 1,  - 1
      sum1        = sum1 + ww_ad(layer) / sum2_ww(layer)
      w_ad(layer) = w_ad(layer) + sum1 * coef%dpp(layer - 1)
    ENDDO

    sum1 = 0._jprb

    IF (coef%nco2 > 0) THEN
      DO layer = prof(1)%nlayers, 1,  - 1
        sum1        = sum1 + twr_ad(layer) / sum2_twr(layer)
        t_ad(layer) = t_ad(layer) + sum1 * coef%dpp(layer - 1)
      ENDDO
    ENDIF

    tuw_ad(2:prof(1)%nlayers) = tuw_ad(2:prof(1)%nlayers) + tuwr_ad(2:prof(1)%nlayers)
    t_ad(1)                   = t_ad(1) + tuwr_ad(1) * coef%dpp(0) / (coef%dpp(0) * coef%tstar(1))
    sum1 = 0._jprb

    DO layer = prof(1)%nlayers, 1,  - 1
      sum1        = sum1 + tuw_ad(layer) / sum2_tuw(layer)
      t_ad(layer) = t_ad(layer) + sum1
    ENDDO


    DO layer = prof(1)%nlayers, 2,  - 1
      tw_ad(layer - 1) = tw_ad(layer - 1) + tw_ad(layer)
      tr_ad(layer - 1) = tr_ad(layer - 1) + tw_ad(layer) * coef%dpp(layer - 1)
    ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile deviations
!-------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers

    DO layer = 1, prof(1)%nlayers

      IF (coef%nso2 > 0) THEN
        so2_ad(layer) = so2_ad(layer) + so2r_ad(layer) / coef%so2star(layer)
      ENDIF

      IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
        ch4_ad(layer) = ch4_ad(layer) + ch4r_ad(layer) / coef%ch4star(layer)
      ELSE
        ch4_ad(layer) = 0
      ENDIF

      IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
        co_ad(layer) = co_ad(layer) + cor_ad(layer) / coef%costar(layer)
      ELSE
        co_ad(layer) = 0
      ENDIF

      IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
        n2o_ad(layer) = n2o_ad(layer) + n2or_ad(layer) / coef%n2ostar(layer)
      ELSE
        n2o_ad(layer) = 0
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        co2_ad(layer) = co2_ad(layer) + co2r_ad(layer) / coef%co2star(layer)
      ELSE
        co2_ad(layer) = 0
      ENDIF

      IF (coef%nozone > 0) THEN
        t_ad(layer) = t_ad(layer) + tro_ad(layer) / coef%to3star(layer)
        IF (opts%rt_ir%ozone_data) THEN
          o_ad(layer) = o_ad(layer) + or_ad(layer) / coef%ostar(layer)
        ELSE
          o_ad(layer) = 0
        ENDIF
      ENDIF

      w_ad(layer) = w_ad(layer) + wr_ad(layer) / coef%wstar(layer)
      t_ad(layer) = t_ad(layer) + tr_ad(layer) / coef%tstar(layer)

      IF (coef%nozone > 0) t_ad(layer) = t_ad(layer) + dto_ad(layer)

      t_ad(layer) = t_ad(layer) + dt_ad(layer)
    ENDDO

!-------------------------------------------------------------------
!   calc adjoint of profile layer means
!-------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN

      DO level = 2, prof(1)%nlevels

        IF (opts%rt_ir%pc%addpc .OR. .NOT. opts%rt_ir%so2_data) THEN
          layer         = level - 1
          so2_ad(layer) = 0._jprb
        ELSE
          layer = level - 1
          prof_ad(iprof)%so2(level - 1) = prof_ad(iprof)%so2(level - 1) + 0.5_jprb * so2_ad(layer)
          prof_ad(iprof)%so2(level)     = prof_ad(iprof)%so2(level) + 0.5_jprb * so2_ad(layer)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN

      DO level = 2, prof(1)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer         = level - 1
          ch4_ad(layer) = 0._jprb
        ELSE
          layer = level - 1
          prof_ad(iprof)%ch4(level - 1) = prof_ad(iprof)%ch4(level - 1) + 0.5_jprb * ch4_ad(layer)
          prof_ad(iprof)%ch4(level)     = prof_ad(iprof)%ch4(level) + 0.5_jprb * ch4_ad(layer)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN

      DO level = 2, prof(1)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer         = level - 1
          n2o_ad(layer) = 0._jprb
        ELSE
          layer = level - 1
          prof_ad(iprof)%n2o(level - 1) = prof_ad(iprof)%n2o(level - 1) + 0.5_jprb * n2o_ad(layer)
          prof_ad(iprof)%n2o(level)     = prof_ad(iprof)%n2o(level) + 0.5_jprb * n2o_ad(layer)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN

      DO level = 2, prof(1)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer        = level - 1
          co_ad(layer) = 0._jprb
        ELSE
          layer = level - 1
          prof_ad(iprof)%co(level - 1) = prof_ad(iprof)%co(level - 1) + 0.5_jprb * co_ad(layer)
          prof_ad(iprof)%co(level)     = prof_ad(iprof)%co(level) + 0.5_jprb * co_ad(layer)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN

      DO level = 2, prof(1)%nlevels

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          layer         = level - 1
          co2_ad(layer) = 0._jprb
        ELSE
          layer = level - 1
          prof_ad(iprof)%co2(level - 1) = prof_ad(iprof)%co2(level - 1) + 0.5_jprb * co2_ad(layer)
          prof_ad(iprof)%co2(level)     = prof_ad(iprof)%co2(level) + 0.5_jprb * co2_ad(layer)
        ENDIF

      ENDDO

    ENDIF

    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN

      DO level = 2, prof(1)%nlevels
        layer = level - 1
        prof_ad(iprof)%o3(level - 1) = prof_ad(iprof)%o3(level - 1) + 0.5_jprb * o_ad(layer)
        prof_ad(iprof)%o3(level)     = prof_ad(iprof)%o3(level) + 0.5_jprb * o_ad(layer)
      ENDDO

    ENDIF

! include adjoint surface humidity

    IF (opts%rt_all%use_q2m) THEN

      ! It is not immediately obvious that this is correct, but after careful comparison with
      ! the TL one can see that it is.
      DO level = 2, prof(1)%nlevels
        layer = level - 1
        prof_ad(iprof)%q(level - 1) = prof_ad(iprof)%q(level - 1) + 0.5_JPRB * w_ad(layer)

        IF (level == iv2lev) THEN
          iv2lay = iv2lev - 1
          prof_ad(iprof)%s2m%q = prof_ad(iprof)%s2m%q + 0.5_JPRB * w_ad(iv2lay)
        ELSE
          prof_ad(iprof)%q(level) = prof_ad(iprof)%q(level) + 0.5_JPRB * w_ad(layer)
        ENDIF
      ENDDO

    ELSE

      DO level = 2, prof(1)%nlevels
        layer = level - 1
        prof_ad(iprof)%q(level - 1) = prof_ad(iprof)%q(level - 1) + 0.5_JPRB * w_ad(layer)
        prof_ad(iprof)%q(level)     = prof_ad(iprof)%q(level) + 0.5_JPRB * w_ad(layer)
      ENDDO

    ENDIF

    DO level = 2, prof(1)%nlevels
      layer = level - 1
      prof_ad(iprof)%t(level - 1) = prof_ad(iprof)%t(level - 1) + 0.5_jprb * t_ad(layer)
      prof_ad(iprof)%t(level)     = prof_ad(iprof)%t(level) + 0.5_jprb * t_ad(layer)
    ENDDO

  ENDDO

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_AD', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_9_ad
