! Description:
!> @file
!!   AD of v7/8 predictor calculation.
!!
!> @brief
!!   AD of v7/8 predictor calculation.
!!
!! @param[in]     opts            RTTOV options
!! @param[in]     prof            profiles on coefficient levels
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in,out] aux_ad          increments in RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_ad   predictor increments
!! @param[in]     raytracing      RTTOV raytracing structure
!! @param[in,out] raytracing_ad   raytracing structure increments
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
SUBROUTINE rttov_setpredictors_78_ad( &
             opts,          &
             prof,          &
             coef,          &
             aux,           &
             aux_ad,        &
             predictors,    &
             predictors_ad, &
             raytracing,    &
             raytracing_ad)

  USE rttov_types, ONLY :  &
        rttov_coef,        &
        rttov_options,     &
        rttov_path_pred,   &
        rttov_profile,     &
        rttov_profile_aux, &
        rttov_raytracing
!INTF_OFF
  USE rttov_const, ONLY :  &
        inst_id_ssmis,     &
        inst_id_amsua
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
!INTF_ON
  IMPLICIT NONE
  TYPE(rttov_options)     , INTENT(IN)    :: opts
  TYPE(rttov_profile)     , INTENT(IN)    :: prof(:)
  TYPE(rttov_coef)        , INTENT(IN)    :: coef
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_profile_aux) , INTENT(INOUT) :: aux_ad
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_ad(:)
  TYPE(rttov_raytracing)  , INTENT(IN)    :: raytracing
  TYPE(rttov_raytracing)  , INTENT(INOUT) :: raytracing_ad
!INTF_END

  INTEGER(KIND=jpim) :: lay, i
  INTEGER(KIND=jpim) :: nprofiles, nlayers

  REAL   (KIND=jprb) :: sec_wr   (prof(1)%nlayers), sec_wr_sqrt(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_ww(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_or   (prof(1)%nlayers), sec_or_sqrt(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_wr_rsqrt(prof(1)%nlayers), wr_wwr_r(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrtr_r(prof(1)%nlayers), sec_wrwrtr_r(prof(1)%nlayers)
  
  REAL   (KIND=jprb) :: sec_or_ad(prof(1)%nlayers), sec_or_sqrt_ad(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_wr_ad(prof(1)%nlayers), sec_wr_sqrt_ad(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_ww_ad(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: wr_wwr_r_ad(prof(1)%nlayers), sec_wrtr_r_ad(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrwrtr_r_ad(prof(1)%nlayers)

! pressure-moodulated cell (pmc) variables
  REAL   (KIND=jprb) :: Lcel_cm
!   REAL   (KIND=jprb) :: Tcel
  REAL   (KIND=jprb) :: betaplus1
  REAL   (KIND=jprb) :: acm
  REAL   (KIND=jprb) :: Pcel_Lev
  REAL   (KIND=jprb) :: Pnom_LevM1
  REAL   (KIND=jprb) :: Pcel_LevM1
  REAL   (KIND=jprb) :: Pnom_Lev
  REAL   (KIND=jprb) :: Pnom(coef%fmv_chn)
  REAL   (KIND=jprb) :: Pcel(coef%fmv_chn)
  INTEGER(KIND=jpim) :: ichan, lev, iprof
  INTEGER(KIND=jpim) :: nlay
  REAL   (KIND=jprb) :: acm_AD
  REAL   (KIND=jprb) :: Pcel_Lev_AD
  REAL   (KIND=jprb) :: Pnom_LevM1_AD
  REAL   (KIND=jprb) :: Pcel_LevM1_AD
  REAL   (KIND=jprb) :: Pnom_Lev_AD


  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_AD', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers


  aux_ad%t_layer = 0.0_jprb
! mixed gases
!---
  DO i = 1, nprofiles
    DO lay = 1, nlayers
      ! only effective for non-Zeeman chans 1-18,23-24 - coefficient file will have zeros for chan 19-22
      raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
                                               predictors_ad(i)%mixedgas(1, lay) + &
        2._jprb * raytracing%pathsat(lay, i) * predictors_ad(i)%mixedgas(2, lay) + &
        aux%tr(lay, i) *                       predictors_ad(i)%mixedgas(3, lay) + &
        aux%tr(lay, i) * aux%tr(lay, i) *      predictors_ad(i)%mixedgas(4, lay) + &
        aux%tw(lay, i) *                       predictors_ad(i)%mixedgas(7, lay) + &
        aux%tw(lay, i) * aux%tr_r(lay, i) *    predictors_ad(i)%mixedgas(8, lay)

      aux_ad%tr(lay, i) = &!aux_ad%tr(lay, i) + &
        raytracing%pathsat(lay, i) *                            predictors_ad(i)%mixedgas(3, lay) + &
        2._jprb * aux%tr(lay, i) * raytracing%pathsat(lay, i) * predictors_ad(i)%mixedgas(4, lay) + &
                                                                predictors_ad(i)%mixedgas(5, lay) + &
        2._jprb * aux%tr(lay, i) *                              predictors_ad(i)%mixedgas(6, lay)

      aux_ad%tw(lay, i) = &!aux_ad%tw(lay, i) +
        raytracing%pathsat(lay, i) *                    predictors_ad(i)%mixedgas(7, lay) + &
        raytracing%pathsat(lay, i) * aux%tr_r(lay, i) * predictors_ad(i)%mixedgas(8, lay)

      aux_ad%tr_r(lay, i) = &!aux_ad%tr_r(lay, i) + &
        raytracing%pathsat(lay, i) * aux%tw(lay, i) * predictors_ad(i)%mixedgas(8, lay)

      raytracing_ad%pathsat_sqrt(lay, i) = &!raytracing_ad%pathsat_sqrt(lay, i) +
                             predictors_ad(i)%mixedgas(9, lay) + &
        aux%tw_4rt(lay, i) * predictors_ad(i)%mixedgas(10, lay)

      aux_ad%tw_4rt(lay, i) = &!aux_ad%tw_4rt(lay, i) + &
        raytracing%pathsat_sqrt(lay, i) * predictors_ad(i)%mixedgas(10, lay)
    ENDDO
  ENDDO

  IF (coef%id_inst == inst_id_ssmis .AND. coef%inczeeman) THEN
    DO i = 1, nprofiles
      DO lay = 1, nlayers
        ! SSMIS with Zeeman coefficient file
        ! geomagnetic field variables (Be, cosbk) are part of the user input

        ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        ! NB require prof(i) % Be >0. (divisor)
        
        ! X11 -> X21
        ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        predictors_ad(i)%mixedgas(20, lay) = predictors_ad(i)%mixedgas(20, lay) + &
             predictors_ad(i)%mixedgas(21, lay) * prof(i)%Be
        predictors_ad(i)%mixedgas(13, lay) = predictors_ad(i)%mixedgas(13, lay) + &
             predictors_ad(i)%mixedgas(20, lay) * prof(i)%Be

        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
             prof(i)%Be ** 3_jpim * predictors_ad(i)%mixedgas(19, lay)
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
             prof(i)%Be * predictors_ad(i)%mixedgas(18, lay)
        predictors_ad(i)%mixedgas(16, lay) = predictors_ad(i)%mixedgas(16, lay) + &
             predictors_ad(i)%mixedgas(17, lay) / prof(i)%Be
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
             predictors_ad(i)%mixedgas(16, lay) / prof(i)%Be
        predictors_ad(i)%mixedgas(12, lay) = predictors_ad(i)%mixedgas(12, lay) + &
             predictors_ad(i)%mixedgas(15, lay) * prof(i)%cosbk ** 2_jpim
        predictors_ad(i)%mixedgas(12, lay) = predictors_ad(i)%mixedgas(12, lay) + &
             predictors_ad(i)%mixedgas(14, lay) / prof(i)%Be

        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
             prof(i)%cosbk ** 2_jpim * predictors_ad(i)%mixedgas(13, lay)

        aux_ad%t_layer(lay, i) = aux_ad%t_layer(lay, i) - &
            (predictors(i)%mixedgas(12, lay) / &
             aux%t_layer(lay, i)) * predictors_ad(i)%mixedgas(12, lay)

        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
             (300.0_jprb / aux%t_layer(lay, i)) * predictors_ad(i)%mixedgas(12, lay)
        raytracing_ad%pathsat(lay, i) =  raytracing_ad%pathsat(lay, i) + predictors_ad(i)%mixedgas(11, lay)
      ENDDO
    ENDDO
  ELSEIF (coef%id_inst == inst_id_amsua .AND. coef%inczeeman) THEN
    ! AMSU-A with Zeeman coefficient file
    ! only effective for Zeeman chan 14 - coefficient file will have zeros for chan 1-13
    ! NB some of YH's original predictors omitted - effectively duplicated by predictors 1-4 above
    DO i = 1, nprofiles
      DO lay = 1, nlayers
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
          prof(i)%cosbk ** 2_jpim * predictors_ad(i)%mixedgas(11, lay)
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) +     &
          2.0_jprb * prof(i)%Be * raytracing%pathsat(lay, i) * predictors_ad(i)%mixedgas(12, lay)
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
          prof(i)%Be ** 3_jpim * predictors_ad(i)%mixedgas(13, lay)
        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
          2.0_jprb * (prof(i)%cosbk * prof(i)%Be) ** 2_jpim * &
          raytracing%pathsat(lay, i) * predictors_ad(i)%mixedgas(14, lay)
      ENDDO
    ENDDO
  ENDIF
  
! water vapour - numbers in right hand are predictor numbers
! in the reference document for RTTOV7 (science and validation report)
!----------------
  IF (coef%fmv_model_ver == 7) THEN
    DO i = 1, nprofiles
      sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i)
      sec_wr_rsqrt(:) = raytracing%pathsat_rsqrt(:, i) * aux%wr_rsqrt(:, i)
      sec_wr(:) = sec_wr_sqrt(:)**2_jpim

      DO lay = 1, nlayers

        aux_ad%wr(lay, i) = &!aux_ad%wr(lay, i) + &
          sec_wr(lay) * aux%ww_r(lay, i) *         predictors_ad(i)%watervapour(3, lay)  + &  !12
          sec_wr_sqrt(lay) * aux%ww_r(lay, i) *    predictors_ad(i)%watervapour(8, lay) + & !13
          sec_wr(lay) * aux%tr_r(lay, i) *         predictors_ad(i)%watervapour(14, lay) + &
          sec_wr(lay) * aux%tr_r(lay, i)**4_jpim * predictors_ad(i)%watervapour(15, lay)

        aux_ad%tr_r(lay, i) = aux_ad%tr_r(lay, i) + &
          sec_wr(lay) * aux%wr(lay, i) *           predictors_ad(i)%watervapour(14, lay) + & 
          4._jprb * aux%tr_r(lay, i)**2_jpim * predictors(i)%watervapour(14, lay) * &
                                                   predictors_ad(i)%watervapour(15, lay)

        raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
          2._jprb * raytracing%pathsat(lay, i) * aux%ww(lay, i)**2_jpim * ( &
          2._jprb * predictors(i)%watervapour(13, lay) * predictors_ad(i)%watervapour(12, lay) + &
                                                          predictors_ad(i)%watervapour(13, lay))

        aux_ad%ww(lay, i) = &!aux_ad%ww(lay, i) + &
          (2._jprb * raytracing%pathsat(lay, i)**2_jpim * aux%ww(lay, i)) * &
          (2._jprb * predictors(i)%watervapour(13, lay) * predictors_ad(i)%watervapour(12, lay) + &
                                                           predictors_ad(i)%watervapour(13, lay))

        aux_ad%dt(lay, i) = &!aux_ad%dt(lay, i) + &
          sec_wr(lay) *                                 predictors_ad(i)%watervapour(4, lay)  + & !4
          sec_wr_sqrt(lay) *                            predictors_ad(i)%watervapour(6, lay) + &!11
          2._jprb * ABS(aux%dt(lay, i)) * sec_wr(lay) * predictors_ad(i)%watervapour(11, lay)
      ENDDO

      DO lay = 1, nlayers

        sec_wr_ad(lay) = &!sec_wr_ad(lay) + &
                                                      predictors_ad(i)%watervapour(1, lay) + &  !  7
          aux%wr(lay, i) * aux%ww_r(lay, i) *         predictors_ad(i)%watervapour(3, lay) + &  ! 12
          aux%dt(lay, i) *                            predictors_ad(i)%watervapour(4, lay) + &  !  4
          2._jprb * sec_wr(lay) *                     predictors_ad(i)%watervapour(5, lay) + &  !  1
          3._jprb * sec_wr(lay)**2_jpim *             predictors_ad(i)%watervapour(9, lay) + &
          4._jprb * sec_wr(lay)**3_jpim *             predictors_ad(i)%watervapour(10, lay) + &
          ABS(aux%dt(lay, i)) * aux%dt(lay, i) *      predictors_ad(i)%watervapour(11, lay)+ &  ! 10
          aux%wr(lay, i) * aux%tr_r(lay, i) *         predictors_ad(i)%watervapour(14, lay)+ &  ! 14
          aux%wr(lay, i) * aux%tr_r(lay, i)**4_jpim * predictors_ad(i)%watervapour(15, lay)

        sec_wr_sqrt_ad(lay) = &!sec_wr_sqrt_ad(lay) + &
                                               predictors_ad(i)%watervapour(2, lay) + &                  !  5
          aux%dt(lay, i) *                     predictors_ad(i)%watervapour(6, lay) + &!11
          0.5_jprb * SQRT(sec_wr_rsqrt(lay)) * predictors_ad(i)%watervapour(7, lay) + &! 6
          aux%wr(lay, i) * aux%ww_r(lay, i) *  predictors_ad(i)%watervapour(8, lay) !13

        aux_ad%ww_r(lay, i) = &!aux_ad%ww_r(lay, i) + &
           sec_wr(lay) * aux%wr(lay, i) *      predictors_ad(i)%watervapour(3, lay) + &!12
           sec_wr_sqrt(lay) * aux%wr(lay, i) * predictors_ad(i)%watervapour(8, lay) ! 13
      ENDDO

      sec_wr_sqrt_ad(:) = sec_wr_sqrt_ad(:) + &
        2._jprb * sec_wr_sqrt(:) * sec_wr_ad(:)

      raytracing_ad%pathsat_sqrt(:, i) = raytracing_ad%pathsat_sqrt(:, i) + &
        aux%wr_sqrt(:, i) * sec_wr_sqrt_ad(:)

      aux_ad%wr_sqrt(:, i) = &!aux_ad%wr_sqrt(:, i) + &
        raytracing%pathsat_sqrt(:, i) * sec_wr_sqrt_ad(:)
    ENDDO
  ELSEIF(coef%fmv_model_ver == 8) THEN ! version 8
    DO i = 1, nprofiles 
      sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i)
      sec_wr_rsqrt(:) = raytracing%pathsat_rsqrt(:, i) * aux%wr_rsqrt(:, i)
      sec_wr(:) = sec_wr_sqrt(:)**2_jpim

      sec_ww(:) = raytracing%pathsat(:, i) * aux%ww(:,i)
      wr_wwr_r(:) = aux%wr(:, i) * aux%wwr_r(:, i)

      IF (coef%nwvcont > 0) THEN
        sec_wrtr_r(:) = sec_wr(:) * aux%tr_r(:, i)
        sec_wrwrtr_r(:) = sec_wrtr_r(:) * aux%wr(:, i)

        DO lay = 1, nlayers

          sec_wrtr_r_ad(lay) = &! sec_tr_r_ad(lay) + &
                                                        predictors_ad(i)%wvcont(3, lay) + &
                             aux%tr_r(lay, i) *         predictors_ad(i)%wvcont(4, lay)
                                                       
          aux_ad%tr_r(lay, i) = aux_ad%tr_r(lay, i) + &
            3._jprb * sec_wrwrtr_r(lay) * aux%tr_r(lay, i)**2_jpim * predictors_ad(i)%wvcont(2, lay) + &
                      sec_wrtr_r(lay) *                              predictors_ad(i)%wvcont(4, lay)

          sec_wrwrtr_r_ad(lay) = &!sec_wrwrtr_r_ad(lay) + &
            aux%tr_r(lay, i)**3_jpim *                               predictors_ad(i)%wvcont(2, lay) + &
                                                                     predictors_ad(i)%wvcont(1, lay)
        ENDDO

        aux_ad%wr(:,i) = &!aux_ad%wr(:,i) + &
                         sec_wrtr_r(:) * sec_wrwrtr_r_ad(:)
        sec_wrtr_r_ad(:) = sec_wrtr_r_ad(:) + aux%wr(:,i) * sec_wrwrtr_r_ad(:)

        aux_ad%tr_r(:,i) = aux_ad%tr_r(:,i) + sec_wr(:) * sec_wrtr_r_ad(:)
        sec_wr_ad(:) = &!sec_wr_ad(:) + 
                       aux%tr_r(:,i) * sec_wrtr_r_ad(:)
      ELSE
        sec_wr_ad(:) = 0._jprb ! need sec_wr_ad to be initialised
        aux_ad%wr(:,i) = 0._jprb
      ENDIF

      DO lay = 1, nlayers
        sec_wr_ad(lay) = sec_wr_ad(lay) + & 
          2._jprb * sec_wr(lay) *                predictors_ad(i)%watervapour(1, lay) + &
          aux%dt(lay, i)        *                predictors_ad(i)%watervapour(4, lay) + &
                                                 predictors_ad(i)%watervapour(7, lay) + &
          3._jprb * sec_wr(lay)**2_jpim *        predictors_ad(i)%watervapour(8, lay) + &
          ABS(aux%dt(lay, i)) * aux%dt(lay, i) * predictors_ad(i)%watervapour(9, lay) + &
          wr_wwr_r(lay) *                        predictors_ad(i)%watervapour(11, lay)

        sec_ww_ad(lay) = &!sec_ww_ad(lay) + &
                                                 predictors_ad(i)%watervapour(2, lay) + &
          2._jprb * sec_ww(lay) *                predictors_ad(i)%watervapour(3, lay)

        aux_ad%dt(lay, i) = &!aux_ad%dt(lay, i) + &
          sec_wr(lay) * (                        predictors_ad(i)%watervapour(4, lay) + &
                 2._jprb * ABS(aux%dt(lay, i)) * predictors_ad(i)%watervapour(9, lay) &
                        ) + &
          sec_wr_sqrt(lay) *                     predictors_ad(i)%watervapour(10, lay)

        sec_wr_sqrt_ad(lay) = &!sec_wr_sqrt_ad(lay) + &
                                                 predictors_ad(i)%watervapour(5, lay) + &
          0.5_jprb * SQRT(sec_wr_rsqrt(lay)) *   predictors_ad(i)%watervapour(6, lay) + &
          aux%dt(lay, i) *                       predictors_ad(i)%watervapour(10, lay) + &
          wr_wwr_r(lay) *                        predictors_ad(i)%watervapour(12, lay)

        wr_wwr_r_ad(lay) = &!wr_wwr_r_ad(lay) + &
          sec_wr(lay) *                          predictors_ad(i)%watervapour(11, lay) + &
          sec_wr_sqrt(lay) *                     predictors_ad(i)%watervapour(12, lay)
      ENDDO

      aux_ad%wr(:, i) = aux_ad%wr(:, i) + &
                        aux%wwr_r(:, i) * wr_wwr_r_ad(:)
      aux_ad%wwr_r(:, i) = &!aux_ad%wwr_r(:, i) + 
                           aux%wr(:, i) * wr_wwr_r_ad(:)

      raytracing_ad%pathsat(:, i) = raytracing_ad%pathsat(:, i) + &
                                            aux%ww(:, i) * sec_ww_ad(:)
      aux_ad%ww(:, i) = &!aux_ad%ww(:, i) + 
                           raytracing%pathsat(:, i) * sec_ww_ad(:)

      sec_wr_sqrt_ad(:) = sec_wr_sqrt_ad(:) + 2._jprb * sec_wr_sqrt(:) * sec_wr_ad(:)

      raytracing_ad%pathsat_sqrt(:, i) = raytracing_ad%pathsat_sqrt(:, i) + &
        aux%wr_sqrt(:, i) * sec_wr_sqrt_ad(:)

      aux_ad%wr_sqrt(:, i) = &!aux_ad%wr_sqrt(:, i) + &
        raytracing%pathsat_sqrt(:, i) * sec_wr_sqrt_ad(:)
    ENDDO

  ENDIF

! ozone
!---------
  IF (coef%nozone > 0) THEN
    IF(opts%rt_ir%ozone_Data) THEN
      DO i = 1, nprofiles
        sec_or_sqrt(:)             = raytracing%pathsat_sqrt(:, i) * aux%or_sqrt(:, i)
        sec_or(:)                  = sec_or_sqrt(:)**2_jpim

        DO lay = 1, nlayers
          raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
            aux%ow(lay, i) *                        (predictors_ad(i)%ozone(10, lay) + &
            2._jprb * predictors(i)%ozone(10, lay) * predictors_ad(i)%ozone(11, lay))

          raytracing_ad%pathsat_sqrt(lay, i) = raytracing_ad%pathsat_sqrt(lay, i) + &
            sec_or(lay) * aux%ow_sqrt(lay, i) * predictors_ad(i)%ozone(9, lay)

          aux_ad%ow(lay, i) = &!aux_ad%ow(lay, i) + &
             sec_or(lay) * aux%or(lay, i) * predictors_ad(i)%ozone(6, lay) + &
             sec_or(lay) *                  predictors_ad(i)%ozone(8, lay) + &
             raytracing%pathsat(lay, i) *  (predictors_ad(i)%ozone(10, lay) + &
             2._jprb * predictors(i)%ozone(10, lay) * &
                                            predictors_ad(i)%ozone(11, lay))

          sec_or_ad(lay) = &!sec_or_ad(lay) + &
                                                                    predictors_ad(i)%ozone(1, lay) + &
            aux%dto(lay, i) *                                       predictors_ad(i)%ozone(3, lay) + &
            2._jprb * sec_or(lay) *                                 predictors_ad(i)%ozone(4, lay) + &
            aux%or(lay, i) * aux%ow(lay, i) *                       predictors_ad(i)%ozone(6, lay) + &
            aux%ow(lay, i) *                                        predictors_ad(i)%ozone(8, lay) + &
            raytracing%pathsat_sqrt(lay, i) * aux%ow_sqrt(lay, i) * predictors_ad(i)%ozone(9, lay)

          sec_or_sqrt_ad(lay) = &!sec_or_sqrt_ad(lay) + &
                                                predictors_ad(i)%ozone(2, lay) + &
            aux%dto(lay, i) *                   predictors_ad(i)%ozone(5, lay) + &
            aux%or(lay, i) * aux%ow_r(lay, i) * predictors_ad(i)%ozone(7, lay)

          aux_ad%dto(lay, i) = &!aux_ad%dto(lay, i) + &
            sec_or(lay) *      predictors_ad(i)%ozone(3, lay) + &
            sec_or_sqrt(lay) * predictors_ad(i)%ozone(5, lay)

          aux_ad%or(lay, i) = &!aux_ad%or(lay, i) + &
            sec_or(lay) * aux%ow(lay, i) *        predictors_ad(i)%ozone(6, lay) + &
            sec_or_sqrt(lay) * aux%ow_r(lay, i) * predictors_ad(i)%ozone(7, lay)

          aux_ad%ow_r(lay, i) = &!aux_ad%ow_r(lay, i) +
            sec_or_sqrt(lay) * aux%or(lay, i) * predictors_ad(i)%ozone(7, lay)

          aux_ad%ow_sqrt(lay, i) = &!aux_ad%ow_sqrt(lay, i) + &
             sec_or(lay) * raytracing%pathsat_sqrt(lay, i) * predictors_ad(i)%ozone(9, lay)
        ENDDO

        sec_or_sqrt_ad(:) = sec_or_sqrt_ad(:) + &
          2._jprb * sec_or_sqrt(:) * sec_or_ad(:)

        raytracing_ad%pathsat_sqrt(:, i) = raytracing_ad%pathsat_sqrt(:, i) + &
          aux%or_sqrt(:, i) * sec_or_sqrt_ad(:)
        aux_ad%or_sqrt(:, i) = &!aux_ad%or_sqrt(:, i) + &
          raytracing%pathsat_sqrt(:, i) * sec_or_sqrt_ad(:)
      ENDDO
    ELSE
      DO i = 1, nprofiles
        DO lay = 1, nlayers

          raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
                                                          predictors_ad(i)%ozone(1, lay) + &
             aux%dto(lay, i) *                            predictors_ad(i)%ozone(3, lay) + &
             2._jprb * raytracing%pathsat(lay, i) *       predictors_ad(i)%ozone(4, lay) + &
                                                          predictors_ad(i)%ozone(6, lay) + &
                                                          predictors_ad(i)%ozone(8, lay) + &
             1.5_jprb * raytracing%pathsat_sqrt(lay, i) * predictors_ad(i)%ozone(9, lay) + &
                                                          predictors_ad(i)%ozone(10, lay) + &
             2._jprb * raytracing%pathsat(lay, i) *       predictors_ad(i)%ozone(11, lay)

          raytracing_ad%pathsat_sqrt(lay, i) = raytracing_ad%pathsat_sqrt(lay, i) + &
                                                          predictors_ad(i)%ozone(2, lay) + &
             aux%dto(lay, i) *                            predictors_ad(i)%ozone(5, lay) + &                                      
                                                          predictors_ad(i)%ozone(7, lay)

          aux_ad%dto(lay, i) = &!aux_ad%dto(lay, i) + &
            raytracing%pathsat(lay, i) *      predictors_ad(i)%ozone(3, lay) + &
            raytracing%pathsat_sqrt(lay, i) * predictors_ad(i)%ozone(5, lay)

        ENDDO
      ENDDO
    ENDIF
  ENDIF

  !5.6 carbon dioxide transmittance based on RTIASI
!-------------------------------------------------
!

!v8 specific predictors
    IF (coef%fmv_model_ver == 8) THEN

      IF (coef%nco2 > 0) THEN
         
        DO i = 1, nprofiles
          DO lay = 1, nlayers

            raytracing_ad%pathsat(lay, i) = raytracing_ad%pathsat(lay, i) + &
              aux%tr(lay, i) *                                                   predictors_ad(i)%co2(3, lay) + &
              aux%tr(lay, i)**2_jpim *                                           predictors_ad(i)%co2(4, lay) + &
                                                                                 predictors_ad(i)%co2(6, lay) + &
              aux%twr(lay, i) *                                                  predictors_ad(i)%co2(7, lay) + &                    
              aux%tr_sqrt(lay, i) * aux%twr(lay, i) *                            predictors_ad(i)%co2(10, lay)
                            
            aux_ad%tr(lay, i) = aux_ad%tr(lay, i) + &
              2._jprb * aux%tr(lay, i) *                                         predictors_ad(i)%co2(2, lay) + &
              raytracing%pathsat(lay, i) *                                       predictors_ad(i)%co2(3, lay) + &
              2._jprb * raytracing%pathsat(lay, i) * aux%tr(lay, i) *            predictors_ad(i)%co2(4, lay) + &
                                                                                 predictors_ad(i)%co2(5, lay)
            aux_ad%twr(lay, i) = &!aux_ad%twr(lay, i) + &
              raytracing%pathsat(lay, i) *                                       predictors_ad(i)%co2(7, lay) + &
              3._jprb * aux%twr(lay, i) ** 2_jpim *                              predictors_ad(i)%co2(9, lay) + &
              aux%tr_sqrt(lay, i) * raytracing%pathsat(lay, i) *                 predictors_ad(i)%co2(10, lay)
            
            aux_ad%tr_sqrt(lay, i) = &!aux_ad%tr_sqrt(lay, i) + &
              raytracing%pathsat(lay, i) * aux%twr(lay, i) *                     predictors_ad(i)%co2(10, lay)
          ENDDO

          IF(opts%rt_ir%co2_data) THEN !no user-supplied co2_data so no co2r co2w (preds 1&8 differ)
            raytracing_ad%pathsat(:, i) = raytracing_ad%pathsat(:, i) + &
              aux%co2r(:, i) *                                                     predictors_ad(i)%co2(1, :) + &          
              2._jprb * raytracing%pathsat(:, i) * aux%co2w(:, i)**2_jpim *        predictors_ad(i)%co2(8, :)

            aux_ad%co2r(:, i) = &!aux_ad%co2r(:, i) + &
              raytracing%pathsat(:, i) *                                           predictors_ad(i)%co2(1, :)

            aux_ad%co2w(:, i) = &!aux_ad%co2w(:, i) + &
              2._jprb * (raytracing%pathsat(:, i)**2_jpim * aux%co2w(:, i)) *      predictors_ad(i)%co2(8, :)
          ELSE
            raytracing_ad%pathsat(:, i) = raytracing_ad%pathsat(:, i) + &
                                                                                   predictors_ad(i)%co2(1, :) + &          
               2._jprb * raytracing%pathsat(:, i) *                                predictors_ad(i)%co2(8, :)
          ENDIF
        ENDDO
      ENDIF
    ENDIF


!5.7  pressure-modulated cell (pmc) changes
!-------------------------------------------

    IF (coef%pmc_shift) THEN

! FWD
! Constants
      Lcel_cm=coef%pmc_lengthcell
!         Tcel=coef%pmc_tempcell
      betaplus1=coef%pmc_betaplus1
      DO ichan = 1, coef%fmv_chn
        Pnom(ichan)=coef%pmc_pnominal(ichan)
        Pcel(ichan)=coef%pmc_ppmc(ichan)
      ENDDO
      nlay=coef%pmc_nlay

! This is on coef levels so pressure is not an active variable in the AD

      DO iprof = 1, nprofiles
        DO lay = 1, nlay
          lev = lay + 1

          acm = raytracing%co2_cm(iprof)/(2._jprb*betaplus1*Lcel_cm)
          DO ichan=1, coef%fmv_chn
            Pcel_Lev= acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pcel(ichan)**2_jpim
            Pnom_LevM1=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pnom(ichan)**2_jpim
            Pcel_LevM1= acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pcel(ichan)**2_jpim
            Pnom_Lev=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pnom(ichan)**2_jpim
! AD
            Pcel_Lev_AD =  0._jprb
            Pnom_LevM1_AD = 0._jprb
            Pcel_LevM1_AD =  0._jprb
            Pnom_Lev_AD = 0._jprb
            acm_AD = 0._jprb
! for PMC predictor 2
            predictors_AD(iprof)%pmc(2,lay,ichan)=0._jprb
! for PMC predictor 1
            Pcel_Lev_AD = Pcel_Lev_AD                                                    &
            + predictors_AD(iprof)%pmc(1,lay,ichan) * Pnom_LevM1/(Pcel_Lev*Pnom_LevM1)
            Pnom_LevM1_AD = Pnom_LevM1_AD                                                  &
            + predictors_AD(iprof)%pmc(1,lay,ichan) * Pcel_Lev/(Pcel_Lev*Pnom_LevM1)
            Pcel_LevM1_AD = Pcel_LevM1_AD                                                    &
            - predictors_AD(iprof)%pmc(1,lay,ichan) * Pnom_Lev/(Pcel_LevM1*Pnom_Lev)
            Pnom_Lev_AD = Pnom_Lev_AD                                                  &
            - predictors_AD(iprof)%pmc(1,lay,ichan) * Pcel_LevM1/(Pcel_LevM1*Pnom_Lev)
            predictors_AD(iprof)%pmc(1,lay,ichan) = 0._jprb

            acm_AD = acm_AD                                                              &
            + Pnom_Lev_AD * raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim
            raytracing_AD%pathsat(lay,iprof) = raytracing_AD%pathsat(lay,iprof)      &
            + Pnom_Lev_AD * acm * prof(iprof)%p(lev  )**2_jpim
            Pnom_Lev_AD = 0._jprb

            acm_AD = acm_AD                                                              &
            + Pcel_LevM1_AD * raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim
            raytracing_AD%pathsat(lay,iprof) = raytracing_AD%pathsat(lay,iprof)      &
            + Pcel_LevM1_AD * acm * prof(iprof)%p(lev-1)**2_jpim
            Pcel_LevM1_AD = 0._jprb

            acm_AD = acm_AD                                                              &
            + Pnom_LevM1_AD * raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim
            raytracing_AD%pathsat(lay,iprof) = raytracing_AD%pathsat(lay,iprof)      &
            + Pnom_LevM1_AD * acm * prof(iprof)%p(lev-1)**2_jpim
            Pnom_LevM1_AD = 0._jprb

            acm_AD = acm_AD                                                              &
            + Pcel_Lev_AD * raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim
            raytracing_AD%pathsat(lay,iprof) = raytracing_AD%pathsat(lay,iprof)      &
            + Pcel_Lev_AD * acm * prof(iprof)%p(lev  )**2_jpim
            Pcel_Lev_AD = 0._jprb

            raytracing_AD%co2_cm(iprof) = raytracing_AD%co2_cm(iprof)                    &
            + acm_AD/(2._jprb*betaplus1*Lcel_cm)
            acm_AD = 0._jprb

          ENDDO
        ENDDO
      ENDDO
    ENDIF
    
    IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_AD', 1_jpim, ZHOOK_HANDLE)
  END SUBROUTINE rttov_setpredictors_78_ad
