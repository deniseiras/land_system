! Description:
!> @file
!!   TL of v9 predictor calculation.
!!
!> @brief
!!   TL of v9 predictor calculation.
!!
!! @param[in]     opts            RTTOV options
!! @param[in]     prof            profiles on coefficient levels
!! @param[in]     prof_tl         profile perturbations on coefficient levels
!! @param[in]     ray_path        raytracing path array
!! @param[in]     ray_path_tl     raytracing path array perturbations
!! @param[in]     coef_pccomp     PC coefficients structure
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_tl   calculated predictor perturbations
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
SUBROUTINE rttov_setpredictors_9_tl( &
              opts,          &
              prof,          &
              prof_tl,       &
              ray_path,      &
              ray_path_tl,   &
              coef_pccomp,   &
              coef,          &
              aux,           &
              predictors,    &
              predictors_tl)

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
  TYPE(rttov_profile)     , INTENT(IN)    :: prof_tl(SIZE(prof))
  REAL(jprb)              , INTENT(IN)    :: ray_path(prof(1)%nlayers,SIZE(prof))
  REAL(jprb)              , INTENT(IN)    :: ray_path_tl(prof(1)%nlayers,SIZE(prof))
  TYPE(rttov_coef_pccomp) , INTENT(IN)    :: coef_pccomp
  TYPE(rttov_coef)        , INTENT(IN)    :: coef
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_tl(:)
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
  REAL   (KIND=jprb) :: twr  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuw  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuwr (SIZE(prof(1)%p)-1)
! user - reference
  REAL   (KIND=jprb) :: dt   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dto  (SIZE(prof(1)%p)-1)
! pressure weighted
  REAL   (KIND=jprb) :: tw   (SIZE(prof(1)%p)-1)
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
  REAL   (KIND=jprb) :: sum1, sum2    , sum3 , sum4
  REAL   (KIND=jprb) :: tr_sq   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tr_4    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wr  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wrwr(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_or  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wwr_r, wwr_r_tl
  REAL   (KIND=jprb) :: sec_so2   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2so2(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2wr_r
! TL variables
  REAL   (KIND=jprb) :: t_tl       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: w_tl       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: o_tl       (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2o_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tr_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tro_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wr_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: wwr_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: or_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2r_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2or_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cor_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4r_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2r_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: twr_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuw_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tuwr_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dt_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: dto_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: tw_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ww_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ow_tl      (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: co2w_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2ow_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cow_tl     (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4w_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2w_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: n2owr_tl   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: cowr_tl    (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: ch4wr_tl   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2wr_tl   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_or_tl  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wr_tl  (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_wrwr_tl(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2_tl   (SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: sec_so2so2_tl(SIZE(prof(1)%p)-1)
  REAL   (KIND=jprb) :: so2wr_r_tl
  INTEGER(KIND=jpim) :: nprofiles

  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-------------------------------------------------------------------------------
! Recompute direct variables
!-------------------------------------------------------------------------------
! 1) profile layer mean quantities
!------------------------------------------------------------------------------
! layer N-1 lies between levels N-1 and N
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_TL', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)

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

        IF (.NOT. opts%rt_ir%pc%addpc) THEN
          IF (coef%nso2 > 0) THEN
            IF (opts%rt_ir%so2_data) THEN
              so2(layer) = (prof(iprof)%so2(level - 1) + prof(iprof)%so2(level)) * 0.5_jprb
            ELSE
              n = coef%fmv_gas_pos(gas_id_so2)
              so2(layer) = (coef%bkg_prfl_mr(level - 1,n) + coef%bkg_prfl_mr(level,n)) * 0.5_jprb
            ENDIF
          ENDIF
        ENDIF

      ENDDO
! layers

    ENDIF
! not addpc


! Direct value of o and co2 NOT needed for TL
!------------------------------------------------------------------------------
!2) calculate deviations from reference profile (layers)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    dt(:) = t(:) - coef%tstar(:)
!------------------------------------------------------------------------------
!3) calculate (profile / reference profile) ratios; tr wr or
! if no input O3 profile, set to reference value (or =1)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
!-Temperature
    tr(:) = t(:) / coef%tstar(:)
!-H2O
    wr(:) = w(:) / coef%wstar(:)
!-CO2

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      co2r(:) = co2(:) / coef%co2star(:)
    ELSE
      co2r(:) = 1._jprb
    ENDIF

!-Ozone

    IF (coef%nozone > 0) THEN
      dto(:) = t(:) - coef%to3star(:)
      tro(:) = t(:) / coef%to3star(:)
      IF (opts%rt_ir%ozone_data) THEN
        or(:)  = o(:) / coef%ostar(:)
      ELSE
        or(:)  = 1._jprb
      ENDIF
    ENDIF
    
!-N2O

    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
      n2or(:) = n2o(:) / coef%n2ostar(:)
    ELSE
      n2or(:) = 1._jprb
    ENDIF

!-CO

    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
      cor(:) = co(:) / coef%costar(:)
    ELSE
      cor(:) = 1._jprb
    ENDIF

!-CH4

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
! 4. calculate profile / reference profile sums: tw wwr twr
!--------------------------------------------------------------------
!-Temperature-------------------------------------------------------------------
    tw(1) = 0._jprb

    DO layer = 2, prof(1)%nlayers
      tw(layer) = tw(layer - 1) + coef%dpp(layer - 1) * tr(layer - 1)
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1       = sum1 + t(layer)
      sum2       = sum2 + coef%tstar(layer)
      tuw(layer) = sum1 / sum2
    ENDDO

    tuwr(1)                 = coef%dpp(0) * t(1) / (coef%dpp(0) * coef%tstar(1))
    tuwr(2:prof(1)%nlayers) = tuw(2:prof(1)%nlayers)

    IF (coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1       = sum1 + coef%dpp(layer - 1) * t(layer)
        sum2       = sum2 + coef%dpp(layer - 1) * coef%tstar(layer)
        twr(layer) = sum1 / sum2
      ENDDO
    ENDIF

!-H2O----------------------------------------------------------------------------
    sum1 = 0._jprb
    sum2 = 0._jprb
    sum3 = 0._jprb
    sum4 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1       = sum1 + coef%dpp(layer - 1) * w(layer)
      sum2       = sum2 + coef%dpp(layer - 1) * coef%wstar(layer)
      sum3       = sum3 + coef%dpp(layer - 1) * w(layer) * t(layer)
      sum4       = sum4 + coef%dpp(layer - 1) * coef%wstar(layer) * coef%tstar(layer)
      ww(layer)  = sum1 / sum2
      wwr(layer) = sum3 / sum4
    ENDDO

!-O3-----------------------------------------------------------------------------

    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1      = sum1 + coef%dpp(layer - 1) * o(layer)
        sum2      = sum2 + coef%dpp(layer - 1) * coef%ostar(layer)
        ow(layer) = sum1 / sum2
      ENDDO

    ELSE
      ow(:) = 1._jprb
    ENDIF

!-CO2---------------------------------------------------------------------------

    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1        = sum1 + coef%dpp(layer - 1) * co2(layer)
        sum2        = sum2 + coef%dpp(layer - 1) * coef%co2star(layer)
        co2w(layer) = sum1 / sum2
      ENDDO

    ELSE
      co2w(:) = 1._jprb
    ENDIF

!-N2O---------------------------------------------------------------------------

    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
        sum3 = 0._jprb
        sum4 = 0._jprb
          
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * n2o(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer)
          sum3         = sum3 + coef%dpp(layer - 1) * n2o(layer) * t(layer)
          sum4         = sum4 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          n2ow(layer)  = sum1 / sum2
          n2owr(layer) = sum3 / sum4
        ENDDO
  
      ELSE
        n2ow(:)  = 1._jprb
      
        sum3 = 0._jprb
        sum4 = 0._jprb
    
        DO layer = 1, prof(1)%nlayers
          sum3         = sum3 + coef%dpp(layer - 1) * coef%n2ostar(layer) * t(layer)
          sum4         = sum4 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          n2owr(layer) = sum3 / sum4
        ENDDO
      ENDIF
    ENDIF

!-CO---------------------------------------------------------------------------

    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
        sum3 = 0._jprb
        sum4 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1        = sum1 + coef%dpp(layer - 1) * co(layer)
          sum2        = sum2 + coef%dpp(layer - 1) * coef%costar(layer)
          sum3        = sum3 + coef%dpp(layer - 1) * co(layer) * t(layer)
          sum4        = sum4 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          cow(layer)  = sum1 / sum2
          cowr(layer) = sum3 / sum4
        ENDDO
  
      ELSE
        cow(:)  = 1._jprb
    
        sum3 = 0._jprb
        sum4 = 0._jprb
    
        DO layer = 1, prof(1)%nlayers
          sum3        = sum3 + coef%dpp(layer - 1) * coef%costar(layer) * t(layer)
          sum4        = sum4 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          cowr(layer) = sum3 / sum4
        ENDDO
      ENDIF
    ENDIF

!-CH4---------------------------------------------------------------------------

    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb
        sum3 = 0._jprb
        sum4 = 0._jprb
  
        DO layer = 1, prof(1)%nlayers
          sum1         = sum1 + coef%dpp(layer - 1) * ch4(layer)
          sum2         = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer)
          sum3         = sum3 + coef%dpp(layer - 1) * ch4(layer) * t(layer)
          sum4         = sum4 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          ch4w(layer)  = sum1 / sum2
          ch4wr(layer) = sum3 / sum4
        ENDDO
  
      ELSE
        ch4w(:)  = 1._jprb

        sum3 = 0._jprb
        sum4 = 0._jprb
    
        DO layer = 1, prof(1)%nlayers
          sum3         = sum3 + coef%dpp(layer - 1) * coef%ch4star(layer) * t(layer)
          sum4         = sum4 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          ch4wr(layer) = sum3 / sum4
        ENDDO
      ENDIF
    ENDIF

!-SO2---------------------------------------------------------------------------

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb
      sum3 = 0._jprb
      sum4 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1         = sum1 + coef%dpp(layer - 1) * so2(layer)
        sum2         = sum2 + coef%dpp(layer - 1) * coef%so2star(layer)
        sum3         = sum3 + coef%dpp(layer - 1) * so2(layer) * t(layer)
        sum4         = sum4 + coef%dpp(layer - 1) * coef%so2star(layer) * coef%tstar(layer)
        so2w(layer)  = sum1 / sum2
        so2wr(layer) = sum3 / sum4
      ENDDO
    ENDIF

!-------------------------------------------------------------------------------
! Now compute TL variables
!-------------------------------------------------------------------------------
! 1) profile layer mean quantities
!------------------------------------------------------------------------------

    DO layer = 1, prof(1)%nlayers
      level       = layer + 1
      t_tl(layer) = (prof_tl(iprof)%t(level - 1) + prof_tl(iprof)%t(level)) * 0.5_jprb
      w_tl(layer) = (prof_tl(iprof)%q(level - 1) + prof_tl(iprof)%q(level)) * 0.5_jprb
      IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0)     &
           o_tl(layer) = (prof_tl(iprof)%o3(level - 1) + prof_tl(iprof)%o3(level)) * 0.5_jprb

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          co2_tl(layer) = 0._jprb
        ELSE
          co2_tl(layer) = (prof_tl(iprof)%co2(level - 1) + prof_tl(iprof)%co2(level)) * 0.5_jprb
        ENDIF

      ENDIF


      IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          n2o_tl(layer) = 0._jprb
        ELSE
          n2o_tl(layer) = (prof_tl(iprof)%n2o(level - 1) + prof_tl(iprof)%n2o(level)) * 0.5_jprb
        ENDIF

      ENDIF


      IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          co_tl(layer) = 0._jprb
        ELSE
          co_tl(layer) = (prof_tl(iprof)%co(level - 1) + prof_tl(iprof)%co(level)) * 0.5_jprb
        ENDIF

      ENDIF


      IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN

        IF (opts%rt_ir%pc%addpc .AND. coef_pccomp%fmv_pc_comp_pc < 5) THEN
          ch4_tl(layer) = 0._jprb
        ELSE
          ch4_tl(layer) = (prof_tl(iprof)%ch4(level - 1) + prof_tl(iprof)%ch4(level)) * 0.5_jprb
        ENDIF

      ENDIF

      IF (coef%nso2 > 0) THEN

        IF (opts%rt_ir%pc%addpc .OR. .NOT. opts%rt_ir%so2_data) THEN
          so2_tl(layer) = 0._jprb
        ELSE
          so2_tl(layer) = (prof_tl(iprof)%so2(level - 1) + prof_tl(iprof)%so2(level)) * 0.5_jprb
        ENDIF
      ENDIF

    ENDDO

! include tl surface humidity

    IF (opts%rt_all%use_q2m) THEN

      IF (iv2lev <= coef%nlevels) THEN
        w_tl(iv2lay) = (prof_tl(iprof)%s2m%q + prof_tl(iprof)%q(iv3lev)) / 2._JPRB
      ENDIF

    ENDIF

!------------------------------------------------------------------------------
!2) calculate deviations from reference profile (layers)
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    dt_tl(:) = t_tl(:)

    IF (coef%nozone > 0) dto_tl(:) = t_tl(:)

!------------------------------------------------------------------------------
!3) calculate (profile / reference profile) ratios; tr_tl wr_tl or_tl
!------------------------------------------------------------------------------
! All assignments 1:prof(1) % nlayers
    tr_tl(:) = t_tl(:) / coef%tstar(:)
    wr_tl(:) = w_tl(:) / coef%wstar(:)

    IF (coef%nozone > 0) THEN
      tro_tl(:) = t_tl(:) / coef%to3star(:)
      IF (opts%rt_ir%ozone_data) THEN
        or_tl(:)  = o_tl(:) / coef%ostar(:)
      ELSE
        or_tl(:)  = 0._jprb
      ENDIF
    ENDIF


    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      co2r_tl(:) = co2_tl(:) / coef%co2star(:)
    ELSE
      co2r_tl(:) = 0._jprb
    ENDIF


    IF (opts%rt_ir%n2o_data .AND. coef%nn2o > 0) THEN
      n2or_tl(:) = n2o_tl(:) / coef%n2ostar(:)
    ELSE
      n2or_tl(:) = 0._jprb
    ENDIF


    IF (opts%rt_ir%co_data .AND. coef%nco > 0) THEN
      cor_tl(:) = co_tl(:) / coef%costar(:)
    ELSE
      cor_tl(:) = 0._jprb
    ENDIF


    IF (opts%rt_ir%ch4_data .AND. coef%nch4 > 0) THEN
      ch4r_tl(:) = ch4_tl(:) / coef%ch4star(:)
    ELSE
      ch4r_tl(:) = 0._jprb
    ENDIF

    IF (coef%nso2 > 0) THEN
      so2r_tl(:) = so2_tl(:) / coef%so2star(:)
    ENDIF

!-------------------------------------------------------------------------
! 4. calculate profile / reference profile sums: tw_tl ww_tl ow_tl co2w_tl
!-------------------------------------------------------------------------
    tw_tl(1) = 0._jprb

    DO layer = 2, prof(1)%nlayers
      tw_tl(layer) = tw_tl(layer - 1) + coef%dpp(layer - 1) * tr_tl(layer - 1)
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1          = sum1 + t_tl(layer)
      sum2          = sum2 + coef%tstar(layer)
      tuw_tl(layer) = sum1 / sum2
    ENDDO

    tuwr_tl(1)                 = coef%dpp(0) * t_tl(1) / (coef%dpp(0) * coef%tstar(1))
    tuwr_tl(2:prof(1)%nlayers) = tuw_tl(2:prof(1)%nlayers)

    IF (coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1          = sum1 + coef%dpp(layer - 1) * t_tl(layer)
        sum2          = sum2 + coef%dpp(layer - 1) * coef%tstar(layer)
        twr_tl(layer) = sum1 / sum2
      ENDDO
    ENDIF

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1         = sum1 + coef%dpp(layer - 1) * w_tl(layer)
      sum2         = sum2 + coef%dpp(layer - 1) * coef%wstar(layer)
      ww_tl(layer) = sum1 / sum2
    ENDDO

    sum1 = 0._jprb
    sum2 = 0._jprb

    DO layer = 1, prof(1)%nlayers
      sum1          = sum1 + coef%dpp(layer - 1) * (w_tl(layer) * t(layer) + w(layer) * t_tl(layer))
      sum2          = sum2 + coef%dpp(layer - 1) * coef%wstar(layer) * coef%tstar(layer)
      wwr_tl(layer) = sum1 / sum2
    ENDDO


    IF (opts%rt_ir%ozone_data .AND. coef%nozone > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1         = sum1 + coef%dpp(layer - 1) * o_tl(layer)
        sum2         = sum2 + coef%dpp(layer - 1) * coef%ostar(layer)
        ow_tl(layer) = sum1 / sum2
      ENDDO

    ELSE
      ow_tl(:) = 0._jprb
    ENDIF


    IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1           = sum1 + coef%dpp(layer - 1) * co2_tl(layer)
        sum2           = sum2 + coef%dpp(layer - 1) * coef%co2star(layer)
        co2w_tl(layer) = sum1 / sum2
      ENDDO

    ELSE
      co2w_tl(:) = 0._jprb
    ENDIF


    IF (coef%nn2o > 0) THEN
      IF (opts%rt_ir%n2o_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1           = sum1 + coef%dpp(layer - 1) * n2o_tl(layer)
          sum2           = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer)
          n2ow_tl(layer) = sum1 / sum2
        ENDDO

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1            = sum1 + coef%dpp(layer - 1) * (n2o_tl(layer) * t(layer) + n2o(layer) * t_tl(layer))
          sum2            = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          n2owr_tl(layer) = sum1 / sum2
        ENDDO

      ELSE
        n2ow_tl(:)  = 0._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1            = sum1 + coef%dpp(layer - 1) * coef%n2ostar(layer) * t_tl(layer)
          sum2            = sum2 + coef%dpp(layer - 1) * coef%n2ostar(layer) * coef%tstar(layer)
          n2owr_tl(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF


    IF (coef%nco > 0) THEN
      IF (opts%rt_ir%co_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1          = sum1 + coef%dpp(layer - 1) * co_tl(layer)
          sum2          = sum2 + coef%dpp(layer - 1) * coef%costar(layer)
          cow_tl(layer) = sum1 / sum2
        ENDDO

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1           = sum1 + coef%dpp(layer - 1) * (co_tl(layer) * t(layer) + co(layer) * t_tl(layer))
          sum2           = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          cowr_tl(layer) = sum1 / sum2
        ENDDO

      ELSE
        cow_tl(:)  = 0._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1           = sum1 + coef%dpp(layer - 1) * coef%costar(layer) * t_tl(layer)
          sum2           = sum2 + coef%dpp(layer - 1) * coef%costar(layer) * coef%tstar(layer)
          cowr_tl(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF


    IF (coef%nch4 > 0) THEN
      IF (opts%rt_ir%ch4_data) THEN
        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1           = sum1 + coef%dpp(layer - 1) * ch4_tl(layer)
          sum2           = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer)
          ch4w_tl(layer) = sum1 / sum2
        ENDDO

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1            = sum1 + coef%dpp(layer - 1) * (ch4_tl(layer) * t(layer) + ch4(layer) * t_tl(layer))
          sum2            = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          ch4wr_tl(layer) = sum1 / sum2
        ENDDO

      ELSE
        ch4w_tl(:)  = 0._jprb

        sum1 = 0._jprb
        sum2 = 0._jprb

        DO layer = 1, prof(1)%nlayers
          sum1            = sum1 + coef%dpp(layer - 1) * coef%ch4star(layer) * t_tl(layer)
          sum2            = sum2 + coef%dpp(layer - 1) * coef%ch4star(layer) * coef%tstar(layer)
          ch4wr_tl(layer) = sum1 / sum2
        ENDDO
      ENDIF
    ENDIF

    IF (coef%nso2 > 0) THEN
      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1           = sum1 + coef%dpp(layer - 1) * so2_tl(layer)
        sum2           = sum2 + coef%dpp(layer - 1) * coef%so2star(layer)
        so2w_tl(layer) = sum1 / sum2
      ENDDO

      sum1 = 0._jprb
      sum2 = 0._jprb

      DO layer = 1, prof(1)%nlayers
        sum1            = sum1 + coef%dpp(layer - 1) * (so2_tl(layer) * t(layer) + so2(layer) * t_tl(layer))
        sum2            = sum2 + coef%dpp(layer - 1) * coef%so2star(layer) * coef%tstar(layer)
        so2wr_tl(layer) = sum1 / sum2
      ENDDO
    ENDIF

! End of TL profile calcs
! ATTENTION
!  w_tl(:) = prof_tl(iprof) % q(:)
!5) set predictors for RTTOV-8 options
!--
!5.1 mixed gases
!---

    DO layer = 1, prof(1)%nlayers
      level = layer + 1
      predictors_tl(iprof)%mixedgas(1, layer)     = ray_path_tl(layer, iprof)
      predictors_tl(iprof)%mixedgas(2, layer)     =      &
         ray_path_tl(layer, iprof) * 2._jprb * ray_path(layer, iprof)
      predictors_tl(iprof)%mixedgas(3, layer)     =      &
         tr_tl(layer) * ray_path(layer, iprof) + ray_path_tl(layer, iprof) * tr(layer)
      predictors_tl(iprof)%mixedgas(4, layer)     = 2._jprb * tr_tl(layer) * predictors(iprof)%mixedgas(3, layer) +      &
         ray_path_tl(layer, iprof) * predictors(iprof)%mixedgas(5, layer) ** 2_jpim
      predictors_tl(iprof)%mixedgas(5, layer)     = tr_tl(layer)
      predictors_tl(iprof)%mixedgas(6, layer)     = 2._jprb * tr_tl(layer) * tr(layer)
      predictors_tl(iprof)%mixedgas(7, layer)     =      &
         tuw_tl(layer) * ray_path(layer, iprof) + tuw(layer) * ray_path_tl(layer, iprof)
      predictors_tl(iprof)%mixedgas(8, layer)     =      &
         tuwr_tl(layer) * ray_path(layer, iprof) + tuwr(layer) * ray_path_tl(layer, iprof)
      predictors_tl(iprof)%mixedgas(9, layer)     = ray_path_tl(layer, iprof) * tr(layer) ** 3_jpim +      &
         tr_tl(layer) * 3._jprb * ray_path(layer, iprof) * tr(layer) ** 2_jpim
      predictors_tl(iprof)%mixedgas(10, layer)    =                                                 &
         ray_path_tl(layer, iprof) * 1.5_jprb * SQRT(predictors(iprof)%mixedgas(3, layer)) +  &
         tr_tl(layer) * 0.5_jprb * ray_path(layer, iprof) * SQRT(ray_path(layer, iprof)) / SQRT(tr(layer))
!5.2 water vapour lines based on RTIASI
!--------------------------------------
      sec_wr(layer)                               = ray_path(layer, iprof) * wr(layer)
      sec_wrwr(layer)                             = sec_wr(layer) * wr(layer)
      wwr_r = 1.0_jprb / wwr(layer)
      sec_wr_tl(layer)                            =      &
         ray_path(layer, iprof) * wr_tl(layer) + ray_path_tl(layer, iprof) * wr(layer)
      sec_wrwr_tl(layer)                          = sec_wr_tl(layer) * wr(layer) + sec_wr(layer) * wr_tl(layer)
      wwr_r_tl =  - wwr_tl(layer) * wwr_r ** 2_jpim
      predictors_tl(iprof)%watervapour(1, layer)  = 2._jprb * sec_wr(layer) * sec_wr_tl(layer)
      predictors_tl(iprof)%watervapour(2, layer)  =      &
         ray_path(layer, iprof) * ww_tl(layer) + ray_path_tl(layer, iprof) * ww(layer)
      predictors_tl(iprof)%watervapour(3, layer)  =                                                        &
         2._jprb * predictors(iprof)%watervapour(2, layer) * ray_path(layer, iprof) * ww_tl(layer) +  &
         2._jprb * predictors(iprof)%watervapour(2, layer) * ray_path_tl(layer, iprof) * ww(layer)
      predictors_tl(iprof)%watervapour(4, layer)  = sec_wr(layer) * dt_tl(layer) + sec_wr_tl(layer) * dt(layer)
      predictors_tl(iprof)%watervapour(5, layer)  =      &
         0.5_jprb * sec_wr_tl(layer) / predictors(iprof)%watervapour(5, layer)
      predictors_tl(iprof)%watervapour(6, layer)  =      &
         0.25_jprb * sec_wr_tl(layer) / predictors(iprof)%watervapour(6, layer) ** 3_jpim
      predictors_tl(iprof)%watervapour(7, layer)  = sec_wr_tl(layer)
      predictors_tl(iprof)%watervapour(8, layer)  = 3._jprb * predictors(iprof)%watervapour(1, layer) * sec_wr_tl(layer)
      predictors_tl(iprof)%watervapour(9, layer)  = 4._jprb * predictors(iprof)%watervapour(8, layer) * sec_wr_tl(layer)
! NB can we sort this next one out?
      predictors_tl(iprof)%watervapour(10, layer) =      &
         ABS(dt(layer)) * (sec_wr_tl(layer) * dt(layer) + 2._jprb * sec_wr(layer) * dt_tl(layer))
!  Do layer = 1, prof(1) % nlayers
!     predictors_tl % watervapour(9,layer,iprof)  =  &
!         ABS(dt(layer)) * &
!         (sec_wr_tl(layer) * dt(layer) + 2 * sec_wr(layer)  * dt_tl(layer) )
!!$   If ( dt(layer) >= 0. )Then
!!$     predictors_tl % watervapour(9,layer,iprof)  =  sec_wr_tl(layer) * dt(layer) * dt(layer) + &
!!$              2 * sec_wr(layer) * dt(layer) * dt_tl(layer)
!!$   Else
!!$     predictors_tl % watervapour(9,layer,iprof)  =  sec_wr_tl(layer) * dt(layer) * dtabs(layer) + &
!!$              sec_wr(layer) * dtabs(layer) * dt_tl(layer) - &
!!$              sec_wr(layer) * dt(layer) * dt_tl(layer)
!!$   Endif
!  End Do
      predictors_tl(iprof)%watervapour(11, layer) = predictors(iprof)%watervapour(5, layer) * dt_tl(layer) +      &
         0.5_jprb * dt(layer) * sec_wr_tl(layer) / predictors(iprof)%watervapour(5, layer)
      predictors_tl(iprof)%watervapour(12, layer) = sec_wrwr_tl(layer) * wwr_r + wwr_r_tl * sec_wrwr(layer)
      predictors_tl(iprof)%watervapour(13, layer) =                                                 &
         0.5_jprb * ray_path_tl(layer, iprof) / SQRT(ray_path(layer, iprof)) *      &
         (wr(layer) * sqrt(wr(layer)) * wwr_r) +                                                         &
         SQRT(ray_path(layer, iprof)) * 1.5_jprb * wr_tl(layer) * sqrt(wr(layer)) * wwr_r +  &
         SQRT(ray_path(layer, iprof)) * wr(layer) * SQRT(wr(layer)) * wwr_r_tl
      predictors_tl(iprof)%watervapour(14, layer) =                                                                &
         ray_path_tl(layer, iprof) * 1.5_jprb * SQRT(predictors(iprof)%watervapour(2, layer)) * ww(layer) +  &
         ww_tl(layer) * 1.5_jprb * SQRT(predictors(iprof)%watervapour(2, layer)) * ray_path(layer, iprof)
      predictors_tl(iprof)%watervapour(15, layer) =                                      &
         ray_path_tl(layer, iprof) * 1.5_jprb * SQRT(sec_wr(layer)) * wr(layer) +  &
         wr_tl(layer) * 1.5_jprb * SQRT(sec_wr(layer)) * ray_path(layer, iprof)
      predictors_tl(iprof)%watervapour(16, layer) =                                                                     &
         ray_path_tl(layer, iprof) * 1.25_jprb * sqrt(sqrt(predictors(iprof)%watervapour(2, layer))) * ww(layer) +  &
         ww_tl(layer) * 1.25_jprb * sqrt(sqrt(predictors(iprof)%watervapour(2, layer))) * ray_path(layer, iprof)
      predictors_tl(iprof)%watervapour(17, layer) = 1.5_jprb * predictors(iprof)%watervapour(5, layer) * wr_tl(layer) +      &
         ray_path_tl(layer, iprof) * 0.5_jprb * wr(layer) * sqrt(wr(layer)) / sqrt(ray_path(layer, iprof))
      predictors_tl(iprof)%watervapour(18, layer) = dt_tl(layer) * sec_wr(layer) * SQRT(sec_wr(layer)) +                                &
         ray_path_tl(layer, iprof) * 1.5_jprb * predictors(iprof)%watervapour(5, layer) * wr(layer) * dt(layer) +  &
         wr_tl(layer) * 1.5_jprb * predictors(iprof)%watervapour(5, layer) * ray_path(layer, iprof) * dt(layer)
      predictors_tl(iprof)%watervapour(19, layer) = 2._jprb * sec_wr(layer) * wr_tl(layer) / ww(layer) -                        &
         predictors(iprof)%watervapour(1, layer) * ww_tl(layer) / (ray_path(layer, iprof) * ww(layer) ** 2_jpim) +  &
         ray_path_tl(layer, iprof) * wr(layer) ** 2_jpim / ww(layer)
    ENDDO

!
!5.3 water vapour continuum transmittance based on RTIASI
!--------------------------------------------------------
!

    IF (coef%nwvcont > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        tr_sq(layer)                          = tr(layer) * tr(layer)
        tr_4(layer)                           = tr_sq(layer) * tr_sq(layer)
        predictors_tl(iprof)%wvcont(1, layer) =      &
           sec_wrwr_tl(layer) / tr(layer) - predictors(iprof)%wvcont(1, layer) * tr_tl(layer) / tr(layer)
        predictors_tl(iprof)%wvcont(2, layer) =      &
           sec_wrwr_tl(layer) / tr_4(layer) - 4._jprb * predictors(iprof)%wvcont(1, layer) * tr_tl(layer) / tr_4(layer)
        predictors_tl(iprof)%wvcont(3, layer) =      &
           sec_wr_tl(layer) / tr(layer) - sec_wr(layer) * tr_tl(layer) / tr_sq(layer)
        predictors_tl(iprof)%wvcont(4, layer) =      &
           sec_wr_tl(layer) / tr_sq(layer) - 2._jprb * sec_wr(layer) * tr_tl(layer) / (tr_sq(layer) * tr(layer))
      ENDDO

    ENDIF

!
!5.4 ozone
!---------

    IF (coef%nozone > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        sec_or(layer)                         = ray_path(layer, iprof) * or(layer)
        sec_or_tl(layer)                      =      &
           ray_path_tl(layer, iprof) * or(layer) + or_tl(layer) * ray_path(layer, iprof)
        predictors_tl(iprof)%ozone(1, layer)  = sec_or_tl(layer)
        predictors_tl(iprof)%ozone(2, layer)  = 0.5_jprb * sec_or_tl(layer) / predictors(iprof)%ozone(2, layer)
        predictors_tl(iprof)%ozone(3, layer)  =                                                         &
           sec_or_tl(layer) * predictors(iprof)%ozone(3, layer) / predictors(iprof)%ozone(1, layer) +  &
           predictors(iprof)%ozone(1, layer) * dto_tl(layer)
        predictors_tl(iprof)%ozone(4, layer)  = 2._jprb * sec_or_tl(layer) * predictors(iprof)%ozone(1, layer)
        predictors_tl(iprof)%ozone(5, layer)  = 0.5_jprb * sec_or_tl(layer) * predictors(iprof)%ozone(3, layer) /      &
           (predictors(iprof)%ozone(1, layer) * predictors(iprof)%ozone(2, layer)) +                                  &
           predictors(iprof)%ozone(2, layer) * dto_tl(layer)
        predictors_tl(iprof)%ozone(6, layer)  =                                                    &
           sec_or_tl(layer) * or(layer) * ow(layer) + or_tl(layer) * sec_or(layer) * ow(layer) +  &
           ow_tl(layer) * sec_or(layer) * or(layer)
        predictors_tl(iprof)%ozone(7, layer)  = predictors_tl(iprof)%ozone(2, layer) * or(layer) / ow(layer) +      &
           or_tl(layer) * predictors(iprof)%ozone(2, layer) / ow(layer) -                                          &
           ow_tl(layer) * predictors(iprof)%ozone(2, layer) * or(layer) / ow(layer) ** 2_jpim
        predictors_tl(iprof)%ozone(8, layer)  = sec_or_tl(layer) * ow(layer) + sec_or(layer) * ow_tl(layer)
        predictors_tl(iprof)%ozone(9, layer)  =                                                           &
           ray_path(layer, iprof) * or_tl(layer) * SQRT(predictors(iprof)%ozone(10, layer)) +  &
           predictors(iprof)%ozone(1, layer) * 0.5_jprb * ray_path(layer, iprof) * ow_tl(layer) /   &
           SQRT(predictors(iprof)%ozone(10, layer)) +                                                    &
           1.5_jprb * ray_path_tl(layer, iprof) * or(layer) * SQRT(predictors(iprof)%ozone(10, layer))
        predictors_tl(iprof)%ozone(10, layer) =      &
           ray_path_tl(layer, iprof) * ow(layer) + ray_path(layer, iprof) * ow_tl(layer)
        predictors_tl(iprof)%ozone(11, layer) =                                                         &
           2._jprb * ow_tl(layer) * ray_path(layer, iprof) * predictors(iprof)%ozone(10, layer) +  &
           2._jprb * ray_path_tl(layer, iprof) * ow(layer) * predictors(iprof)%ozone(10, layer)
        predictors_tl(iprof)%ozone(12, layer) = ray_path_tl(layer, iprof) * or(layer) / ow(layer) +      &
           or_tl(layer) * ray_path(layer, iprof) / ow(layer) -                                          &
           or(layer) * ray_path(layer, iprof) * ow_tl(layer) / ow(layer) ** 2_jpim
        predictors_tl(iprof)%ozone(13, layer) = &
           ow_tl(layer) * 1.75_jprb * ray_path(layer, iprof) * &
           SQRT(SQRT(ray_path(layer, iprof) * ow(layer))) ** 3_jpim + &
           ray_path_tl(layer, iprof) * 1.75_jprb * ow(layer) * &
           SQRT(SQRT(ray_path(layer, iprof) * ow(layer))) ** 3_jpim
        predictors_tl(iprof)%ozone(14, layer) = &
           ray_path_tl(layer, iprof) * 0.5_jprb / &
           sqrt(ray_path(layer, iprof)) * ow(layer) ** 2_jpim * dto(layer) + &
           ow_tl(layer) * 2._jprb * ow(layer) * sqrt(ray_path(layer, iprof)) * dto(layer) + &
           dto_tl(layer) * sqrt(ray_path(layer, iprof)) * ow(layer) ** 2_jpim
        predictors_tl(iprof)%ozone(15, layer) = ray_path_tl(layer, iprof) * tro(layer) ** 3_jpim +      &
           tro_tl(layer) * 3._jprb * tro(layer) ** 2_jpim * ray_path(layer, iprof)
      ENDDO

    ENDIF

!
!5.6 carbon dioxide transmittance based on RTIASI
!-------------------------------------------------
!

    IF (coef%nco2 > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        predictors_tl(iprof)%co2(1, layer)  =      &
           ray_path(layer, iprof) * co2r_tl(layer) + ray_path_tl(layer, iprof) * co2r(layer)
        predictors_tl(iprof)%co2(2, layer)  = 2._jprb * tr_tl(layer) * predictors(iprof)%co2(5, layer)
        predictors_tl(iprof)%co2(3, layer)  =      &
           ray_path(layer, iprof) * tr_tl(layer) + ray_path_tl(layer, iprof) * tr(layer)
        predictors_tl(iprof)%co2(4, layer)  =      &
           2._jprb * tr_tl(layer) * predictors(iprof)%co2(3, layer) + ray_path_tl(layer, iprof) * tr(layer) ** 2_jpim
        predictors_tl(iprof)%co2(5, layer)  = tr_tl(layer)
        predictors_tl(iprof)%co2(6, layer)  = ray_path_tl(layer, iprof)
        predictors_tl(iprof)%co2(7, layer)  =      &
           ray_path(layer, iprof) * twr_tl(layer) + ray_path_tl(layer, iprof) * twr(layer)
        predictors_tl(iprof)%co2(8, layer)  =                                                                &
           2._jprb * ray_path(layer, iprof) * SQRT(predictors(iprof)%co2(8, layer)) * co2w_tl(layer) +  &
           2._jprb * co2w(layer) * SQRT(predictors(iprof)%co2(8, layer)) * ray_path_tl(layer, iprof)
        predictors_tl(iprof)%co2(9, layer)  = 3._jprb * twr(layer) ** 2_jpim * twr_tl(layer)
        predictors_tl(iprof)%co2(10, layer) =                                                               &
           ray_path(layer, iprof) * SQRT(predictors(iprof)%co2(5, layer)) * twr_tl(layer) +      &
           0.5_jprb * predictors(iprof)%co2(7, layer) * tr_tl(layer) / SQRT(predictors(iprof)%co2(5, layer)) +  &
           ray_path_tl(layer, iprof) * twr(layer) * sqrt(tr(layer))
        predictors_tl(iprof)%co2(11, layer) =                                                                  &
           ray_path_tl(layer, iprof) * 0.5_jprb * co2r(layer) / SQRT(predictors(iprof)%co2(1, layer)) +  &
           co2r_tl(layer) * 0.5_jprb * ray_path(layer, iprof) / SQRT(predictors(iprof)%co2(1, layer))
        predictors_tl(iprof)%co2(12, layer) = tr_tl(layer) * 3._jprb * tr(layer) ** 2_jpim
        predictors_tl(iprof)%co2(13, layer) = ray_path_tl(layer, iprof) * tr(layer) ** 3_jpim +      &
           tr_tl(layer) * 3._jprb * tr(layer) ** 2_jpim * ray_path(layer, iprof)
        predictors_tl(iprof)%co2(14, layer) =                                                          &
           ray_path_tl(layer, iprof) * tr(layer) ** 2_jpim * twr(layer) ** 3_jpim * 0.5_jprb /             &
           SQRT(ray_path(layer, iprof)) +                                                   &
           tr_tl(layer) * 2._jprb * tr(layer) * twr(layer) ** 3_jpim * SQRT(ray_path(layer, iprof)) +  &
           twr_tl(layer) * 3._jprb * twr(layer) ** 2_jpim * tr(layer) ** 2_jpim * SQRT(ray_path(layer, iprof))
        predictors_tl(iprof)%co2(15, layer) = tr_tl(layer) * 2._jprb * SQRT(predictors(iprof)%co2(15, layer)) * twr(layer) +      &
           twr_tl(layer) * 2._jprb * SQRT(predictors(iprof)%co2(15, layer)) * tr(layer)
      ENDDO

    ENDIF

!5.7 n2o            transmittance based on RTIASI
!-------------------------------------------------
!

    IF (coef%nn2o > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        predictors_tl(iprof)%n2o(1, layer)  =      &
           ray_path(layer, iprof) * n2or_tl(layer) + ray_path_tl(layer, iprof) * n2or(layer)
        predictors_tl(iprof)%n2o(2, layer)  =                                                            &
           0.5_jprb * ray_path(layer, iprof) * n2or_tl(layer) / predictors(iprof)%n2o(2, layer) +  &
           0.5_jprb * ray_path_tl(layer, iprof) * n2or(layer) / predictors(iprof)%n2o(2, layer)
        predictors_tl(iprof)%n2o(3, layer)  =                                                                              &
           predictors(iprof)%n2o(1, layer) * dt_tl(layer) + ray_path(layer, iprof) * n2or_tl(layer) * dt(layer) &
            + ray_path_tl(layer, iprof) * n2or(layer) * dt(layer)
        predictors_tl(iprof)%n2o(4, layer)  =                                                          &
           2._jprb * predictors(iprof)%n2o(1, layer) * n2or_tl(layer) * ray_path(layer, iprof) +  &
           2._jprb * predictors(iprof)%n2o(1, layer) * n2or(layer) * ray_path_tl(layer, iprof)
        predictors_tl(iprof)%n2o(5, layer)  = n2or(layer) * dt_tl(layer) + n2or_tl(layer) * dt(layer)
        predictors_tl(iprof)%n2o(6, layer)  =                                                                  &
           ray_path(layer, iprof) * n2or_tl(layer) * 0.25_jprb / predictors(iprof)%n2o(6, layer) ** 3_jpim +  &
           ray_path_tl(layer, iprof) * n2or(layer) * 0.25_jprb / predictors(iprof)%n2o(6, layer) ** 3_jpim
        predictors_tl(iprof)%n2o(7, layer)  =      &
           ray_path(layer, iprof) * n2ow_tl(layer) + ray_path_tl(layer, iprof) * n2ow(layer)
        predictors_tl(iprof)%n2o(8, layer)  =      &
           ray_path(layer, iprof) * n2owr_tl(layer) + ray_path_tl(layer, iprof) * n2owr(layer)
        predictors_tl(iprof)%n2o(9, layer)  = n2owr_tl(layer)
        predictors_tl(iprof)%n2o(10, layer) = &
           1.5_jprb * predictors(iprof)%n2o(2, layer) * n2or_tl(layer) / n2ow(layer) - &
           predictors(iprof)%n2o(2, layer) ** 3_jpim * &
           n2ow_tl(layer) / (ray_path(layer, iprof) * n2ow(layer) ** 2_jpim) + &
           0.5_jprb * n2or(layer) * SQRT(n2or(layer)) * &
           ray_path_tl(layer, iprof) / (sqrt(ray_path(layer, iprof)) * n2ow(layer))
        predictors_tl(iprof)%n2o(11, layer) =                                                           &
           ray_path_tl(layer, iprof) * 2._jprb * predictors(iprof)%n2o(8, layer) * n2owr(layer) +  &
           n2owr_tl(layer) * 2._jprb * predictors(iprof)%n2o(8, layer) * ray_path(layer, iprof)
        predictors_tl(iprof)%n2o(12, layer) =                                                                &
           ray_path_tl(layer, iprof) * 3._jprb * predictors(iprof)%n2o(8, layer) ** 2_jpim * n2owr(layer) + &
           n2owr_tl(layer) * 3._jprb * predictors(iprof)%n2o(8, layer) ** 2_jpim * ray_path(layer, iprof)
        predictors_tl(iprof)%n2o(13, layer) = &
           ray_path_tl(layer, iprof) * 2._jprb * &
           ray_path(layer, iprof) * n2owr(layer) * dt(layer) +  &
           n2owr_tl(layer) * ray_path(layer, iprof) ** 2_jpim * dt(layer) + &
           dt_tl(layer) * ray_path(layer, iprof) ** 2_jpim * n2owr(layer)
      ENDDO

    ENDIF

!5.8 co             transmittance based on RTIASI
!-------------------------------------------------
!

    IF (coef%nco > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        predictors_tl(iprof)%co(1, layer)  =      &
           ray_path(layer, iprof) * cor_tl(layer) + ray_path_tl(layer, iprof) * cor(layer)
        predictors_tl(iprof)%co(2, layer)  =                                                           &
           0.5_jprb * ray_path(layer, iprof) * cor_tl(layer) / predictors(iprof)%co(2, layer) +  &
           0.5_jprb * ray_path_tl(layer, iprof) * cor(layer) / predictors(iprof)%co(2, layer)
        predictors_tl(iprof)%co(3, layer)  = &
           predictors(iprof)%co(1, layer) * dt_tl(layer) + &
           dt(layer) * ray_path(layer, iprof) * cor_tl(layer) +  &
           ray_path_tl(layer, iprof) * cor(layer) * dt(layer)
        predictors_tl(iprof)%co(4, layer)  =                                                         &
           2._jprb * predictors(iprof)%co(1, layer) * cor_tl(layer) * ray_path(layer, iprof) +  &
           2._jprb * predictors(iprof)%co(1, layer) * cor(layer) * ray_path_tl(layer, iprof)
        predictors_tl(iprof)%co(5, layer)  = &
           predictors(iprof)%co(2, layer) * dt_tl(layer) + &
           0.5_jprb * dt(layer) * ray_path(layer, iprof) * &
           cor_tl(layer) / predictors(iprof)%co(2, layer) +  &
           0.5_jprb * dt(layer) * ray_path_tl(layer, iprof) * cor(layer) / predictors(iprof)%co(2, layer)
        predictors_tl(iprof)%co(6, layer)  =                                                                 &
           ray_path(layer, iprof) * cor_tl(layer) * 0.25_jprb / predictors(iprof)%co(6, layer) ** 3_jpim +  &
           ray_path_tl(layer, iprof) * cor(layer) * 0.25_jprb / predictors(iprof)%co(6, layer) ** 3_jpim
        predictors_tl(iprof)%co(7, layer)  = ABS(dt(layer)) * &
           (ray_path(layer, iprof) * cor_tl(layer) * dt(layer) + &
           predictors(iprof)%co(1, layer) * 2._jprb * dt_tl(layer) + &
           ray_path_tl(layer, iprof) * cor(layer) * dt(layer))
        predictors_tl(iprof)%co(8, layer)  = &
           (2._jprb * predictors(iprof)%co(1, layer) * cor_tl(layer) / cow(layer)) - &
           predictors(iprof)%co(8, layer) * cow_tl(layer) / cow(layer) + &
           ray_path_tl(layer, iprof) * cor(layer) ** 2_jpim / cow(layer)
        predictors_tl(iprof)%co(9, layer)  = &
           1.5_jprb * predictors(iprof)%co(2, layer) * cor_tl(layer) / cow(layer) - &
           predictors(iprof)%co(2, layer) ** 3_jpim * &
           cow_tl(layer) / (ray_path(layer, iprof) * cow(layer) ** 2_jpim) +  &
           0.5_jprb * cor(layer) * sqrt(cor(layer)) * &
           ray_path_tl(layer, iprof) / (sqrt(ray_path(layer, iprof)) * cow(layer))
        predictors_tl(iprof)%co(10, layer) = &
           (2._jprb * predictors(iprof)%co(1, layer) * cor_tl(layer) / sqrt(cow(layer))) - &
           0.5_jprb * predictors(iprof)%co(10, layer) * cow_tl(layer) / cow(layer) + &
           ray_path_tl(layer, iprof) * cor(layer) ** 2_jpim / SQRT(cow(layer))
        predictors_tl(iprof)%co(11, layer) = &
           (2._jprb * predictors(iprof)%co(1, layer) * cor_tl(layer) / sqrt(sqrt(cow(layer)))) - &
           0.25_jprb * predictors(iprof)%co(11, layer) * cow_tl(layer) / cow(layer) + &
           ray_path_tl(layer, iprof) * cor(layer) ** 2_jpim / sqrt(sqrt(cow(layer)))
        predictors_tl(iprof)%co(12, layer) = ray_path(layer, iprof) * 0.4_jprb * cowr_tl(layer) *      &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.6_jprb) +                                  &
           cowr(layer) * 0.4_jprb * ray_path_tl(layer, iprof) *                                       &
           (ray_path(layer, iprof) * cowr(layer)) ** ( - 0.6_jprb)
        predictors_tl(iprof)%co(13, layer) = ray_path(layer, iprof) * 0.25_jprb * cowr_tl(layer) *      &
           SQRT(SQRT((ray_path(layer, iprof) * cowr(layer)))) / (ray_path(layer, iprof) * cowr(layer)) +                                  &
           cowr(layer) * 0.25_jprb * ray_path_tl(layer, iprof) *                                       &
           SQRT(SQRT((ray_path(layer, iprof) * cowr(layer)))) / (ray_path(layer, iprof) * cowr(layer))
        predictors_tl(iprof)%co(14, layer) = ray_path_tl(layer,iprof) * cow(layer) + &
                                             ray_path(layer,iprof) * cow_tl(layer)
      ENDDO

    ENDIF

!5.9 ch4            transmittance based on RTIASI
!-------------------------------------------------
!

    IF (coef%nch4 > 0) THEN

      DO layer = 1, prof(1)%nlayers
        level = layer + 1
        predictors_tl(iprof)%ch4(1, layer)  =      &
           ray_path(layer, iprof) * ch4r_tl(layer) + ray_path_tl(layer, iprof) * ch4r(layer)
        predictors_tl(iprof)%ch4(2, layer)  =                                                            &
           0.5_jprb * ray_path(layer, iprof) * ch4r_tl(layer) / predictors(iprof)%ch4(2, layer) +  &
           0.5_jprb * ray_path_tl(layer, iprof) * ch4r(layer) / predictors(iprof)%ch4(2, layer)
        predictors_tl(iprof)%ch4(3, layer)  =                                                                              &
           predictors(iprof)%ch4(1, layer) * dt_tl(layer) + ray_path(layer, iprof) * ch4r_tl(layer) * dt(layer) &
            + ray_path_tl(layer, iprof) * ch4r(layer) * dt(layer)
        predictors_tl(iprof)%ch4(4, layer)  =                                                          &
           2._jprb * predictors(iprof)%ch4(1, layer) * ch4r_tl(layer) * ray_path(layer, iprof) +  &
           2._jprb * predictors(iprof)%ch4(1, layer) * ch4r(layer) * ray_path_tl(layer, iprof)
        predictors_tl(iprof)%ch4(5, layer)  = ch4r(layer) * dt_tl(layer) + ch4r_tl(layer) * dt(layer)
        predictors_tl(iprof)%ch4(6, layer)  =                                                                  &
           ray_path(layer, iprof) * ch4r_tl(layer) * 0.25_jprb / predictors(iprof)%ch4(6, layer) ** 3_jpim +  &
           ray_path_tl(layer, iprof) * ch4r(layer) * 0.25_jprb / predictors(iprof)%ch4(6, layer) ** 3_jpim
        predictors_tl(iprof)%ch4(7, layer)  =      &
           ray_path(layer, iprof) * ch4wr_tl(layer) + ray_path_tl(layer, iprof) * ch4wr(layer)
        predictors_tl(iprof)%ch4(8, layer)  = ch4wr_tl(layer)
        predictors_tl(iprof)%ch4(9, layer)  =                                                           &
           2._jprb * predictors(iprof)%ch4(10, layer) * ch4w_tl(layer) * ray_path(layer, iprof) +  &
           2._jprb * predictors(iprof)%ch4(10, layer) * ch4w(layer) * ray_path_tl(layer, iprof)
        predictors_tl(iprof)%ch4(10, layer) =      &
           ray_path(layer, iprof) * ch4w_tl(layer) + ray_path_tl(layer, iprof) * ch4w(layer)
        predictors_tl(iprof)%ch4(11, layer) = &
           1.5_jprb * predictors(iprof)%ch4(2, layer) * ch4r_tl(layer) / ch4w(layer) - &
           predictors(iprof)%ch4(2, layer) ** 3_jpim * &
           ch4w_tl(layer) / (ray_path(layer, iprof) * ch4w(layer) ** 2_jpim) +  &
           0.5_jprb * ch4r(layer) * SQRT(ch4r(layer)) * ray_path_tl(layer, iprof) / &
           (SQRT(ray_path(layer, iprof)) * ch4w(layer))
      ENDDO

    ENDIF

!    so2
!-------------------------------------------------
!

    IF (coef%nso2 == 19) THEN
      DO layer = 1, prof(1)%nlayers
        sec_so2(layer)                               = ray_path(layer, iprof) * so2r(layer)
        sec_so2so2(layer)                            = sec_so2(layer) * so2r(layer)
        so2wr_r = 1.0_jprb / so2wr(layer)
        sec_so2_tl(layer)                            =      &
            ray_path(layer, iprof) * so2r_tl(layer) + ray_path_tl(layer, iprof) * so2r(layer)
        sec_so2so2_tl(layer)                         = sec_so2_tl(layer) * so2r(layer) + sec_so2(layer) * so2r_tl(layer)
        so2wr_r_tl =  - so2wr_tl(layer) * so2wr_r ** 2_jpim
        predictors_tl(iprof)%so2(1, layer)  = 2._jprb * sec_so2(layer) * sec_so2_tl(layer)
        predictors_tl(iprof)%so2(2, layer)  =      &
            ray_path(layer, iprof) * so2w_tl(layer) + ray_path_tl(layer, iprof) * so2w(layer)
        predictors_tl(iprof)%so2(3, layer)  =                                                        &
            2._jprb * predictors(iprof)%so2(2, layer) * ray_path(layer, iprof) * so2w_tl(layer) +  &
            2._jprb * predictors(iprof)%so2(2, layer) * ray_path_tl(layer, iprof) * so2w(layer)
        predictors_tl(iprof)%so2(4, layer)  = sec_so2(layer) * dt_tl(layer) + sec_so2_tl(layer) * dt(layer)
        predictors_tl(iprof)%so2(5, layer)  =      &
            0.5_jprb * sec_so2_tl(layer) / predictors(iprof)%so2(5, layer)
        predictors_tl(iprof)%so2(6, layer)  =      &
            0.25_jprb * sec_so2_tl(layer) / predictors(iprof)%so2(6, layer) ** 3_jpim
        predictors_tl(iprof)%so2(7, layer)  = sec_so2_tl(layer)
        predictors_tl(iprof)%so2(8, layer)  = 3._jprb * predictors(iprof)%so2(1, layer) * sec_so2_tl(layer)
        predictors_tl(iprof)%so2(9, layer)  = 4._jprb * predictors(iprof)%so2(8, layer) * sec_so2_tl(layer)
        predictors_tl(iprof)%so2(10, layer) =      &
            ABS(dt(layer)) * (sec_so2_tl(layer) * dt(layer) + 2._jprb * sec_so2(layer) * dt_tl(layer))
        predictors_tl(iprof)%so2(11, layer) = predictors(iprof)%so2(5, layer) * dt_tl(layer) +      &
            0.5_jprb * dt(layer) * sec_so2_tl(layer) / predictors(iprof)%so2(5, layer)
        predictors_tl(iprof)%so2(12, layer) = sec_so2so2_tl(layer) * so2wr_r + so2wr_r_tl * sec_so2so2(layer)
        predictors_tl(iprof)%so2(13, layer) =                                                 &
            0.5_jprb * ray_path_tl(layer, iprof) / SQRT(ray_path(layer, iprof)) *      &
            (so2r(layer) ** 1.5_jprb * so2wr_r) +                                                         &
            SQRT(ray_path(layer, iprof)) * 1.5_jprb * so2r_tl(layer) * so2r(layer) ** 0.5_jprb * so2wr_r +  &
            SQRT(ray_path(layer, iprof)) * so2r(layer) ** 1.5_jprb * so2wr_r_tl
        predictors_tl(iprof)%so2(14, layer) =                                                                &
            ray_path_tl(layer, iprof) * 1.5_jprb * SQRT(predictors(iprof)%so2(2, layer)) * so2w(layer) +  &
            so2w_tl(layer) * 1.5_jprb * SQRT(predictors(iprof)%so2(2, layer)) * ray_path(layer, iprof)
        predictors_tl(iprof)%so2(15, layer) =                                      &
            ray_path_tl(layer, iprof) * 1.5_jprb * SQRT(sec_so2(layer)) * so2r(layer) +  &
            so2r_tl(layer) * 1.5_jprb * SQRT(sec_so2(layer)) * ray_path(layer, iprof)
        predictors_tl(iprof)%so2(16, layer) =                                                                     &
            ray_path_tl(layer, iprof) * 1.25_jprb * (predictors(iprof)%so2(2, layer)) ** 0.25_jprb * so2w(layer) +  &
            so2w_tl(layer) * 1.25_jprb * (predictors(iprof)%so2(2, layer)) ** 0.25_jprb * ray_path(layer, iprof)
        predictors_tl(iprof)%so2(17, layer) = 1.5_jprb * predictors(iprof)%so2(5, layer) * so2r_tl(layer) +      &
            ray_path_tl(layer, iprof) * 0.5_jprb * so2r(layer) ** 1.5_jprb / ray_path(layer, iprof) ** 0.5_jprb
        predictors_tl(iprof)%so2(18, layer) = dt_tl(layer) * sec_so2(layer) ** 1.5_jprb +                                &
            ray_path_tl(layer, iprof) * 1.5_jprb * predictors(iprof)%so2(5, layer) * so2r(layer) * dt(layer) +  &
            so2r_tl(layer) * 1.5_jprb * predictors(iprof)%so2(5, layer) * ray_path(layer, iprof) * dt(layer)
        predictors_tl(iprof)%so2(19, layer) = 2._jprb * sec_so2(layer) * so2r_tl(layer) / so2w(layer) -                        &
            predictors(iprof)%so2(1, layer) * so2w_tl(layer) / (ray_path(layer, iprof) * so2w(layer) ** 2_jpim) +  &
            ray_path_tl(layer, iprof) * so2r(layer) ** 2_jpim / so2w(layer)
      ENDDO
    ENDIF

  ENDDO

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_9_TL', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_9_tl
