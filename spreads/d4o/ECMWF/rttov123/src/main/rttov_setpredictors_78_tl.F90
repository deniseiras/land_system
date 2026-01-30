! Description:
!> @file
!!   TL of v78 predictor calculation.
!!
!> @brief
!!   TL of v78 predictor calculation.
!!
!! @param[in]     prof            profiles on coefficient levels
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in]     aux_tl          perturbations in RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_tl   calculated predictor perturbations
!! @param[in]     raytracing      RTTOV raytracing structure
!! @param[in]     raytracing_tl   raytracing structure perturbations
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
SUBROUTINE rttov_setpredictors_78_tl( &
             opts,          &
             prof,          &
             coef,          &
             aux,           &
             aux_tl,        &
             predictors,    &
             predictors_tl, &
             raytracing,    &
             raytracing_tl)

  USE rttov_types, ONLY :  &
        rttov_coef,        &
        rttov_options,     &
        rttov_profile,     &
        rttov_profile_aux, &
        rttov_path_pred,   &
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
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux_tl
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_tl(:)
  TYPE(rttov_raytracing)  , INTENT(IN)    :: raytracing
  TYPE(rttov_raytracing)  , INTENT(IN)    :: raytracing_tl
!INTF_END

  INTEGER(KIND=jpim) :: lay, i
  INTEGER(KIND=jpim) :: nlayers, nprofiles

  REAL   (KIND=jprb) :: sec_wr   (prof(1)%nlayers), sec_wr_sqrt(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_ww(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_or   (prof(1)%nlayers), sec_or_sqrt(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_wr_rsqrt(prof(1)%nlayers), wr_wwr_r(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrtr_r(prof(1)%nlayers), sec_wrwrtr_r(prof(1)%nlayers)
  
  REAL   (KIND=jprb) :: sec_or_tl(prof(1)%nlayers), sec_or_sqrt_tl(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_wr_tl(prof(1)%nlayers), sec_wr_sqrt_tl(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_ww_tl(prof(1)%nlayers) 
  REAL   (KIND=jprb) :: wr_wwr_r_tl(prof(1)%nlayers), sec_wrtr_r_tl(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrwrtr_r_tl(prof(1)%nlayers)

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
  REAL   (KIND=jprb) :: acm_TL
  REAL   (KIND=jprb) :: Pcel_Lev_TL
  REAL   (KIND=jprb) :: Pnom_LevM1_TL
  REAL   (KIND=jprb) :: Pcel_LevM1_TL
  REAL   (KIND=jprb) :: Pnom_Lev_TL

  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_TL', 0_jpim, ZHOOK_HANDLE)

  nlayers = prof(1)%nlayers
  nprofiles = SIZE(prof)

! mixed gases
!---
  DO i = 1, nprofiles
    DO lay = 1, nlayers
      ! only effective for non-Zeeman chans 1-18,23-24 - coefficient file will have zeros for chan 19-22
      predictors_tl(i)%mixedgas(1, lay)  = raytracing_tl%pathsat(lay, i)
      predictors_tl(i)%mixedgas(2, lay)  = 2._jprb * raytracing_tl%pathsat(lay, i) * raytracing%pathsat(lay, i)
      predictors_tl(i)%mixedgas(3, lay)  = raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + &
                                           raytracing%pathsat(lay, i) * aux_tl%tr(lay, i)
      predictors_tl(i)%mixedgas(4, lay)  = aux%tr(lay, i) * (raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + &
                                                             2._jprb * raytracing%pathsat(lay, i) * aux_tl%tr(lay, i))
      predictors_tl(i)%mixedgas(5, lay)  = aux_tl%tr(lay, i)
      predictors_tl(i)%mixedgas(6, lay)  = 2._jprb * aux%tr(lay, i) * aux_tl%tr(lay, i) !tr*tr
      predictors_tl(i)%mixedgas(7, lay)  = raytracing_tl%pathsat(lay, i) * aux%tw(lay, i) + &
                                           raytracing%pathsat(lay, i) * aux_tl%tw(lay, i)
      predictors_tl(i)%mixedgas(8, lay)  = raytracing_tl%pathsat(lay, i) * aux%tw(lay, i) * aux%tr_r(lay, i) + &
                                           raytracing%pathsat(lay, i) * (aux_tl%tw(lay, i) * aux%tr_r(lay, i) + &
                                                                         aux%tw(lay, i) * aux_tl%tr_r(lay, i))
      predictors_tl(i)%mixedgas(9, lay)  = raytracing_tl%pathsat_sqrt(lay, i)
      predictors_tl(i)%mixedgas(10, lay) = raytracing_tl%pathsat_sqrt(lay, i) * aux%tw_4rt(lay, i) + &
                                           raytracing%pathsat_sqrt(lay, i) * aux_tl%tw_4rt(lay, i)
    ENDDO
  ENDDO

  IF(coef%id_inst == inst_id_ssmis .AND. coef%inczeeman) THEN
    DO i = 1, nprofiles
      DO lay = 1, nlayers
           ! SSMIS with Zeeman coefficient file
           ! geomagnetic field variables (Be, cosbk) are part of the user input

           ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
           ! NB require prof(i) % Be > 0. (divisor)

           ! X11 -> X21
           ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        predictors_tl(i)%mixedgas(11, lay)  = raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(12, lay)  =  - (predictors(i)%mixedgas(12, lay) / &
          aux%t_layer(lay, i)) * aux_tl%t_layer(lay, i) +      &
          (300.0_jprb / aux%t_layer(lay, i)) * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(13, lay)  = prof(i)%cosbk ** 2_jpim * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(14, lay)  = predictors_tl(i)%mixedgas(12, lay) / prof(i)%Be
        predictors_tl(i)%mixedgas(15, lay)  = predictors_tl(i)%mixedgas(12, lay) * prof(i)%cosbk ** 2_jpim
        predictors_tl(i)%mixedgas(16, lay)  = raytracing_tl%pathsat(lay, i) / prof(i)%Be
        predictors_tl(i)%mixedgas(17, lay)  = predictors_tl(i)%mixedgas(16, lay) / prof(i)%Be
        predictors_tl(i)%mixedgas(18, lay)  = prof(i)%Be * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(19, lay)  = prof(i)%Be ** 3_jpim * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(20, lay) = predictors_tl(i)%mixedgas(13, lay) * prof(i)%Be
        predictors_tl(i)%mixedgas(21, lay) = predictors_tl(i)%mixedgas(20, lay) * prof(i)%Be
      ENDDO
    ENDDO
  ELSEIF (coef%id_inst == inst_id_amsua .AND. coef%inczeeman) THEN
    ! AMSU-A with Zeeman coefficient file
    ! only effective for Zeeman chan 14 - coefficient file will have zeros for chan 1-13
    ! NB some of YH's original predictors omitted - effectively duplicated by predictors 1-4 above
    DO i = 1, nprofiles
      DO lay = 1, nlayers
        predictors_tl(i)%mixedgas(11, lay) = prof(i)%cosbk ** 2_jpim * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(12, lay) =      &
          2.0_jprb * prof(i)%Be * raytracing%pathsat(lay, i) * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(13, lay) = prof(i)%Be ** 3_jpim * raytracing_tl%pathsat(lay, i)
        predictors_tl(i)%mixedgas(14, lay) =      &
          2.0_jprb * (prof(i)%cosbk * prof(i)%Be) ** 2_jpim * raytracing%pathsat(lay, i) * raytracing_tl%pathsat(lay, i)
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

      sec_wr_sqrt_tl(:) = raytracing_tl%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i) + &
                          raytracing%pathsat_sqrt(:, i) * aux_tl%wr_sqrt(:, i)

      sec_wr_tl(:) = 2._jprb * sec_wr_sqrt(:) * sec_wr_sqrt_tl(:)

      DO lay = 1, nlayers
        predictors_tl(i)%watervapour(1, lay)  = sec_wr_tl(lay)                                             !  7
        predictors_tl(i)%watervapour(2, lay)  = sec_wr_sqrt_tl(lay)                                      !  5
        predictors_tl(i)%watervapour(3, lay)  = sec_wr_tl(lay) * aux%wr(lay, i) * aux%ww_r(lay, i) + &
                                                sec_wr(lay) * (aux_tl%wr(lay, i) * aux%ww_r(lay, i) + &
                                                               aux%wr(lay, i) * aux_tl%ww_r(lay, i)) ! 12

        predictors_tl(i)%watervapour(4, lay)  = sec_wr_tl(lay) * aux%dt(lay, i) + sec_wr(lay) * aux_tl%dt(lay, i)   !4
        predictors_tl(i)%watervapour(5, lay)  = 2._jprb * sec_wr_tl(lay) * sec_wr(lay)                             !  1
        predictors_tl(i)%watervapour(6, lay)  = sec_wr_sqrt_tl(lay) * aux%dt(lay, i) + &
                                                sec_wr_sqrt(lay) * aux_tl%dt(lay, i) !11

        predictors_tl(i)%watervapour(7, lay)  = 0.5_jprb * SQRT(sec_wr_rsqrt(lay)) * sec_wr_sqrt_tl(lay)              ! 6

        predictors_tl(i)%watervapour(8, lay)  = sec_wr_sqrt_tl(lay) * aux%wr(lay, i) * aux%ww_r(lay, i) + &
                                                sec_wr_sqrt(lay) * (aux_tl%wr(lay, i) * aux%ww_r(lay, i) + &
                                                                    aux%wr(lay, i) * aux_tl%ww_r(lay, i)) ! 13
      ENDDO
      predictors_tl(i)%watervapour(9, :)  = 3._jprb * sec_wr(:) ** 2_jpim * sec_wr_tl(:)
      predictors_tl(i)%watervapour(10, :) = 4._jprb * sec_wr(:) ** 3_jpim * sec_wr_tl(:)

      DO lay = 1, nlayers
        predictors_tl(i)%watervapour(11, lay) = ABS(aux%dt(lay, i)) * (&
                                                                       sec_wr_tl(lay) * aux%dt(lay, i) + &
                                                                       sec_wr(lay) * 2._jprb * aux_tl%dt(lay, i))     ! 10
        predictors_tl(i)%watervapour(13, lay) = 2._jprb * (raytracing%pathsat(lay, i) * aux%ww(lay, i)) * &  ! 2
                                                (raytracing_tl%pathsat(lay, i) * aux%ww(lay, i) + &
                                                 raytracing%pathsat(lay, i) * aux_tl%ww(lay, i))
        predictors_tl(i)%watervapour(14, lay) = sec_wr_tl(lay) * aux%wr(lay, i) * aux%tr_r(lay, i) + &      ! 14
                                                sec_wr(lay) * (aux_tl%wr(lay, i) * aux%tr_r(lay, i) + &
                                                               aux%wr(lay, i) * aux_tl%tr_r(lay, i))
      ENDDO
      predictors_tl(i)%watervapour(12, :) = 2._jprb * predictors(i)%watervapour(13, :) * &
                                                      predictors_tl(i)%watervapour(13, :) ! 3

!     predictors_tl(i)%watervapour(12, :) = 2._jprb * (raytracing%pathsat(lay, i) * aux%ww(lay, i)) ** 2_jpim *
!                                          (2._jprb * (raytracing%pathsat(lay, i) * aux%ww(lay, i)) * &  ! 2
!                                           (raytracing_tl%pathsat(lay, i) * aux%ww(lay, i) + &
!                                            raytracing%pathsat(lay, i) * aux_tl%ww(lay, i)))

      predictors_tl(i)%watervapour(15, :) = aux%tr_r(:, i)**2_jpim * ( &
                                                   3._jprb * predictors(i)%watervapour(14, :) * aux_tl%tr_r(:, i) + &
                                                   predictors_tl(i)%watervapour(14, :) * aux%tr_r(:, i))

!     predictors_tl(i)%watervapour(15, :) = aux%tr_r(:, i)**2_jpim * ( &
!                          3._jprb * sec_wr(lay) * aux%wr(lay, i) * aux%tr_r(lay, i) * aux_tl%tr_r(:, i) + &
!                          aux%tr_r(:, i) * (sec_wr_tl(lay) * aux%wr(lay, i) * aux%tr_r(lay, i) + &      ! 14
!                         sec_wr(lay) * (aux_tl%wr(lay, i) * aux%tr_r(lay, i) + &
!                         aux%wr(lay, i) * aux_tl%tr_r(lay, i))))

    ENDDO
  ELSEIF(coef%fmv_model_ver == 8) THEN
    DO i = 1, nprofiles
      sec_wr_rsqrt(:) = raytracing%pathsat_rsqrt(:, i) * aux%wr_rsqrt(:, i)

      sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i)
      sec_wr(:) = sec_wr_sqrt(:)**2_jpim
      sec_ww(:) = raytracing%pathsat(:, i) * aux%ww(:,i)
      wr_wwr_r(:) = aux%wr(:, i) * aux%wwr_r(:, i)

      sec_wr_sqrt_tl(:) = raytracing_tl%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i) + &
                          raytracing%pathsat_sqrt(:, i) * aux_tl%wr_sqrt(:, i)
      sec_wr_tl(:) = 2._jprb * sec_wr_sqrt(:) * sec_wr_sqrt_tl(:)
      sec_ww_tl(:) = raytracing_tl%pathsat(:, i) * aux%ww(:, i) + &
                     raytracing%pathsat(:, i)    * aux_tl%ww(:, i)
      wr_wwr_r_tl(:) = aux_tl%wr(:, i) * aux%wwr_r(:, i) + & 
                       aux%wr(:, i) * aux_tl%wwr_r(:, i)

      DO lay = 1, nlayers
        predictors_tl(i)%watervapour(1, lay)  = 2._jprb * sec_wr_tl(lay) * sec_wr(lay)
        predictors_tl(i)%watervapour(2, lay)  = sec_ww_tl(lay)
        predictors_tl(i)%watervapour(3, lay)  = 2._jprb * sec_ww(lay) * sec_ww_tl(lay)
        predictors_tl(i)%watervapour(4, lay)  = sec_wr_tl(lay) * aux%dt(lay, i) + &
                                                sec_wr(lay) * aux_tl%dt(lay, i)   !4
        predictors_tl(i)%watervapour(5, lay)  = sec_wr_sqrt_tl(lay)
        predictors_tl(i)%watervapour(6, lay)  = 0.5_jprb * SQRT(sec_wr_rsqrt(lay)) * sec_wr_sqrt_tl(lay) ! 6
        predictors_tl(i)%watervapour(7, lay)  = sec_wr_tl(lay)
        predictors_tl(i)%watervapour(8, lay)  = 3._jprb * sec_wr(lay)**2_jpim * sec_wr_tl(lay)
        predictors_tl(i)%watervapour(9, lay)  = ABS(aux%dt(lay, i)) * (&
                                                                       sec_wr_tl(lay) * aux%dt(lay, i) + &
                                                                       sec_wr(lay) * 2._jprb * aux_tl%dt(lay, i))     ! 10
        predictors_tl(i)%watervapour(10, lay) = sec_wr_sqrt_tl(lay) * aux%dt(lay, i) + &
                                                sec_wr_sqrt(lay) * aux_tl%dt(lay, i) !11
        predictors_tl(i)%watervapour(11, lay) = sec_wr_tl(lay) * wr_wwr_r(lay) + &
                                                sec_wr(lay) * wr_wwr_r_tl(lay)
        predictors_tl(i)%watervapour(12, lay) = sec_wr_sqrt_tl(lay) * wr_wwr_r(lay) + &
                                                sec_wr_sqrt(lay) * wr_wwr_r_tl(lay)
      ENDDO

      IF (coef%nwvcont > 0) THEN
        sec_wrtr_r(:) = sec_wr(:) * aux%tr_r(:, i)
        sec_wrwrtr_r(:) = sec_wrtr_r(:) * aux%wr(:, i)

        sec_wrtr_r_tl(:) = sec_wr_tl(:) * aux%tr_r(:,i) + &
                           sec_wr(:) * aux_tl%tr_r(:,i)
        sec_wrwrtr_r_tl(:) = sec_wrtr_r(:) * aux_tl%wr(:,i) + &
                             sec_wrtr_r_tl(:) * aux%wr(:,i)
        
        DO lay = 1, nlayers
          predictors_tl(i)%wvcont(1, lay) = sec_wrwrtr_r_tl(lay)
          predictors_tl(i)%wvcont(2, lay) = aux%tr_r(lay, i)**2_jpim * &
                                           (sec_wrwrtr_r(lay) * 3._jprb * aux_tl%tr_r(lay, i) + &
                                            sec_wrwrtr_r_tl(lay) * aux%tr_r(lay, i))
          predictors_tl(i)%wvcont(3, lay) = sec_wrtr_r_tl(lay)
          predictors_tl(i)%wvcont(4, lay) = sec_wrtr_r_tl(lay) * aux%tr_r(lay, i) + &
                                            sec_wrtr_r(lay) * aux_tl%tr_r(lay, i)
        ENDDO
      ENDIF

    ENDDO
  ENDIF

! ozone
!---------
  IF (coef%nozone > 0) THEN
    IF(opts%rt_ir%ozone_Data) THEN
      DO i = 1, nprofiles
        sec_or_sqrt(:)             = raytracing%pathsat_sqrt(:, i) * aux%or_sqrt(:, i)
        sec_or(:)                  = sec_or_sqrt(:)**2_jpim
        sec_or_sqrt_tl(:)          = raytracing_tl%pathsat_sqrt(:, i) * aux%or_sqrt(:, i) + &
                                     raytracing%pathsat_sqrt(:, i) * aux_tl%or_sqrt(:, i)
        sec_or_tl(:)               = 2._jprb * sec_or_sqrt(:) * sec_or_sqrt_tl(:)

        DO lay = 1, prof(1)%nlayers
          predictors_tl(i)%ozone(1, lay)  = sec_or_tl(lay)
          predictors_tl(i)%ozone(2, lay)  = sec_or_sqrt_tl(lay)
          predictors_tl(i)%ozone(3, lay)  = sec_or_tl(lay) * aux%dto(lay, i) + sec_or(lay) * aux_tl%dto(lay, i)
          predictors_tl(i)%ozone(4, lay)  = 2._jprb * sec_or(lay) * sec_or_tl(lay)
          predictors_tl(i)%ozone(5, lay)  = sec_or_sqrt_tl(lay) * aux%dto(lay, i) + sec_or_sqrt(lay) * aux_tl%dto(lay, i)
          predictors_tl(i)%ozone(6, lay)  = sec_or_tl(lay) * aux%or(lay, i) * aux%ow(lay, i) + &
                                            sec_or(lay) * (aux_tl%or(lay, i) * aux%ow(lay, i) + &
                                                           aux%or(lay, i) * aux_tl%ow(lay, i))
          predictors_tl(i)%ozone(7, lay)  = sec_or_sqrt_tl(lay) * aux%or(lay, i) * aux%ow_r(lay, i) + &
                                            sec_or_sqrt(lay) * (aux_tl%or(lay, i) * aux%ow_r(lay, i) + &
                                                                aux%or(lay, i) * aux_tl%ow_r(lay, i))
          predictors_tl(i)%ozone(8, lay)  = sec_or_tl(lay) * aux%ow(lay, i) + sec_or(lay) * aux_tl%ow(lay, i)
          predictors_tl(i)%ozone(9, lay)  = sec_or_tl(lay) * raytracing%pathsat_sqrt(lay, i) * aux%ow_sqrt(lay, i) + &
                                            sec_or(lay) * (raytracing_tl%pathsat_sqrt(lay, i) * aux%ow_sqrt(lay, i) + &
                                                           raytracing%pathsat_sqrt(lay, i) * aux_tl%ow_sqrt(lay, i))
          predictors_tl(i)%ozone(10, lay) = raytracing_tl%pathsat(lay, i) * aux%ow(lay, i) + &
                                            raytracing%pathsat(lay, i) * aux_tl%ow(lay, i)
          predictors_tl(i)%ozone(11, lay) = 2._jprb * predictors(i)%ozone(10, lay) * predictors_tl(i)%ozone(10, lay)

        ENDDO
      ENDDO
    ELSE ! no user-supplied ozone data
      DO i = 1, nprofiles   
        DO lay = 1, nlayers
          predictors_tl(i)%ozone(1, lay)  = raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(2, lay)  = raytracing_tl%pathsat_sqrt(lay, i)
          predictors_tl(i)%ozone(3, lay)  = raytracing_tl%pathsat(lay, i) * aux%dto(lay, i) + &
                                            raytracing%pathsat(lay, i) * aux_tl%dto(lay, i)  
          predictors_tl(i)%ozone(4, lay)  = 2._jprb * raytracing%pathsat(lay, i) * raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(5, lay)  = raytracing_tl%pathsat_sqrt(lay, i) * aux%dto(lay, i) + &
                                            raytracing%pathsat_sqrt(lay, i) * aux_tl%dto(lay, i)   
          predictors_tl(i)%ozone(6, lay)  = raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(7, lay)  = raytracing_tl%pathsat_sqrt(lay, i)
          predictors_tl(i)%ozone(8, lay)  = raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(9, lay)  = 1.5_jprb * raytracing%pathsat_sqrt(lay, i) * raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(10, lay) = raytracing_tl%pathsat(lay, i)
          predictors_tl(i)%ozone(11, lay) = 2._jprb * raytracing%pathsat(lay, i) * raytracing_tl%pathsat(lay, i)
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
        IF(opts%rt_ir%co2_data) THEN
          DO i = 1, nprofiles
            DO lay = 1, nlayers
              predictors_tl(i)%co2(1, lay)  = raytracing_tl%pathsat(lay, i) * aux%co2r(lay, i) + &
                                              raytracing%pathsat(lay, i) * aux_tl%co2r(lay, i)
              predictors_tl(i)%co2(2, lay)  = 2._jprb * aux%tr(lay, i) * aux_tl%tr(lay, i) !6
              predictors_tl(i)%co2(3, lay)  = raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + & !3
                                              raytracing%pathsat(lay, i) * aux_tl%tr(lay, i)
              predictors_tl(i)%co2(4, lay)  = aux%tr(lay, i) * ( raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + &!4
                                                                 2._jprb * raytracing%pathsat(lay, i) * aux_tl%tr(lay, i))
              predictors_tl(i)%co2(5, lay)  = aux_tl%tr(lay, i) !5
              predictors_tl(i)%co2(6, lay)  = raytracing_tl%pathsat(lay, i) ! 1
              predictors_tl(i)%co2(7, lay)  = raytracing_tl%pathsat(lay, i) * aux%twr(lay, i) + &
                                              raytracing%pathsat(lay, i) * aux_tl%twr(lay, i)
              predictors_tl(i)%co2(8, lay)  = 2._jprb * (raytracing%pathsat(lay, i) * aux%co2w(lay, i)) * &
                                                        (raytracing_tl%pathsat(lay, i) * aux%co2w(lay, i) + &
                                                         raytracing%pathsat(lay, i) * aux_tl%co2w(lay, i))
              predictors_tl(i)%co2(9, lay)  = 3._jprb * aux%twr(lay, i) ** 2_jpim * aux_tl%twr(lay, i)
              predictors_tl(i)%co2(10, lay) = aux%tr_sqrt(lay, i) * &
                                               (raytracing_tl%pathsat(lay, i) * aux%twr(lay, i) + & 
                                                raytracing%pathsat(lay, i) * aux_tl%twr(lay, i)) + & 
                                                raytracing%pathsat(lay, i) * aux%twr(lay, i) * aux_tl%tr_sqrt(lay, i)
            ENDDO
          ENDDO
        ELSE !no user-supplied co2_data so no co2r co2w (preds 1&8 differ)
          DO i = 1, nprofiles
            DO lay = 1, nlayers
              predictors_tl(i)%co2(1, lay)  = raytracing_tl%pathsat(lay, i)
              predictors_tl(i)%co2(2, lay)  = 2._jprb * aux%tr(lay, i) * aux_tl%tr(lay, i) !6
              predictors_tl(i)%co2(3, lay)  = raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + & !3
                                              raytracing%pathsat(lay, i) * aux_tl%tr(lay, i)
              predictors_tl(i)%co2(4, lay)  = aux%tr(lay, i) * ( raytracing_tl%pathsat(lay, i) * aux%tr(lay, i) + &!4
                                                                 2._jprb * raytracing%pathsat(lay, i) * aux_tl%tr(lay, i))
              predictors_tl(i)%co2(5, lay)  = aux_tl%tr(lay, i) !5
              predictors_tl(i)%co2(6, lay)  = raytracing_tl%pathsat(lay, i) ! 1
              predictors_tl(i)%co2(7, lay)  = raytracing_tl%pathsat(lay, i) * aux%twr(lay, i) + &
                                              raytracing%pathsat(lay, i) * aux_tl%twr(lay, i)
              predictors_tl(i)%co2(8, lay)  = 2._jprb * raytracing%pathsat(lay, i) * raytracing_tl%pathsat(lay, i)
              predictors_tl(i)%co2(9, lay)  = 3._jprb * aux%twr(lay, i) ** 2_jpim * aux_tl%twr(lay, i)
              predictors_tl(i)%co2(10, lay) = aux%tr_sqrt(lay, i) * &
                                               (raytracing_tl%pathsat(lay, i) * aux%twr(lay, i) + & 
                                                raytracing%pathsat(lay, i) * aux_tl%twr(lay, i)) + & 
                                                raytracing%pathsat(lay, i) * aux%twr(lay, i) * aux_tl%tr_sqrt(lay, i)
            ENDDO
          ENDDO
        ENDIF
      ENDIF
    ENDIF

!5.7  pressure-modulated cell (pmc) changes
!-------------------------------------------

    IF (coef%pmc_shift) THEN
! FWD
! Constants
      Lcel_cm=coef%pmc_lengthcell

      betaplus1=coef%pmc_betaplus1
      DO ichan = 1, coef%fmv_chn
        Pnom(ichan)=coef%pmc_pnominal(ichan)
        Pcel(ichan)=coef%pmc_ppmc(ichan)
      ENDDO
      nlay=coef%pmc_nlay

! This is on coef levels so pressure is not an active variable in the TL
      DO iprof = 1, nprofiles
        DO lay = 1, nlay
          lev = lay + 1
! nlayers (for pmc) may be less than prof(1)%nlayerss
! FWD
          acm = raytracing%co2_cm(iprof)/(2._jprb*betaplus1*Lcel_cm)
! TL
          acm_TL = raytracing_TL%co2_cm(iprof)/(2._jprb*betaplus1*Lcel_cm)

          DO ichan=1, coef%fmv_chn
! FWD
            Pcel_Lev= acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pcel(ichan)**2_jpim
            Pnom_LevM1=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pnom(ichan)**2_jpim
            Pcel_LevM1= acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pcel(ichan)**2_jpim
            Pnom_Lev=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pnom(ichan)**2_jpim
! TL
! PMC Predictor-1
            Pcel_Lev_TL  = acm_TL*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim                    &
                           +acm*raytracing_TL%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim
            Pnom_LevM1_TL = acm_TL*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim                   &
                           +acm*raytracing_TL%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim
            Pcel_LevM1_TL  = acm_TL*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim                  &
                            +acm*raytracing_TL%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim
            Pnom_Lev_TL = acm_TL*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim                     &
                         +acm*raytracing_TL%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim
            predictors_TL(iprof)%pmc(1,lay,ichan)=                                                                 &
              Pcel_Lev_TL  * Pnom_LevM1/(Pcel_Lev*Pnom_LevM1)                                                      &
            + Pnom_LevM1_TL * Pcel_Lev/(Pcel_Lev*Pnom_LevM1)                                                       &
            - Pcel_LevM1_TL  * Pnom_Lev/(Pcel_LevM1*Pnom_Lev)                                                      &
            - Pnom_Lev_TL * Pcel_LevM1/(Pcel_LevM1*Pnom_Lev)

! PMC Predictor-2 - use lay depth as lower bound for denominator
            predictors_TL(iprof)%pmc(2,lay,ichan)=0._jprb

          ENDDO
        ENDDO
      ENDDO

      ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_TL', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_78_tl
