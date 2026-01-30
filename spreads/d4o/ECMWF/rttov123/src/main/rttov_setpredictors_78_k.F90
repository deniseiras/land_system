! Description:
!> @file
!!   K of v7/8 predictor calculation.
!!
!> @brief
!!   K of v7/8 predictor calculation.
!!
!! @param[in]     chanprof        specifies channels and profiles to simulate
!! @param[in]     profiles        profiles on coefficient levels
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in,out] aux_k           increments in RTTOV profile_aux structure
!! @param[in]     predictors      predictors
!! @param[in,out] predictors_k    predictor increments
!! @param[in]     raytracing      RTTOV raytracing structure
!! @param[in,out] raytracing_k    raytracing structure increments
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
SUBROUTINE rttov_setpredictors_78_k( &
             opts,         &
             chanprof,      &
             profiles,      &
             coef,          &
             aux,           &
             aux_k,         &
             predictors,    &
             predictors_k,  &
             raytracing,    &
             raytracing_k)

  USE rttov_types, ONLY :  &
        rttov_chanprof,    &
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
  TYPE(rttov_chanprof)    , INTENT(IN)    :: chanprof(:)
  TYPE(rttov_profile)     , INTENT(IN)    :: profiles(:)
  TYPE(rttov_coef)        , INTENT(IN)    :: coef
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_profile_aux) , INTENT(INOUT) :: aux_k
  TYPE(rttov_path_pred)   , INTENT(IN)    :: predictors(:)
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors_k(:)
  TYPE(rttov_raytracing)  , INTENT(IN)    :: raytracing
  TYPE(rttov_raytracing)  , INTENT(INOUT) :: raytracing_k
!INTF_END

  INTEGER(KIND=jpim) :: lay, prof, i

  REAL   (KIND=jprb) :: sec_wr   (profiles(1)%nlayers), sec_wr_sqrt(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_ww(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_or_sqrt(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: wr_wwr_r(profiles(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrtr_r(profiles(1)%nlayers), sec_wrwrtr_r(profiles(1)%nlayers)

  REAL   (KIND=jprb) :: sec_or_k(profiles(1)%nlayers), sec_or_sqrt_k(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: sec_wr_k(profiles(1)%nlayers), sec_wr_sqrt_k(profiles(1)%nlayers)
  REAL   (KIND=jprb) :: sec_ww_k(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: wr_wwr_r_k(profiles(1)%nlayers), sec_wrtr_r_k(profiles(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrwrtr_r_k(profiles(1)%nlayers)

  REAL   (KIND=jprb) :: mgtemp(4,profiles(1)%nlayers), wtemp(19,profiles(1)%nlayers)
  REAL   (KIND=jprb) :: o3temp(11,profiles(1)%nlayers), co2temp(7,profiles(1)%nlayers)
  REAL   (KIND=jprb) :: co2temp_t(profiles(1)%nlayers,2)

  INTEGER(KIND=jpim) :: nlayers, nchannels
  INTEGER(KIND=jpim) :: last_prof
  REAL   (KIND=jprb) :: ZHOOK_HANDLE

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
  INTEGER(KIND=jpim) :: ichan, lev, j ,k
  INTEGER(KIND=jpim) :: nlay
  REAL   (KIND=jprb) :: acm_K
  REAL   (KIND=jprb) :: Pcel_Lev_K
  REAL   (KIND=jprb) :: Pnom_LevM1_K
  REAL   (KIND=jprb) :: Pcel_LevM1_K
  REAL   (KIND=jprb) :: Pnom_Lev_K

!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_K', 0_jpim, ZHOOK_HANDLE)

  nchannels = SIZE(chanprof)
  nlayers = profiles(1)%nlayers

  aux_k%t_layer = 0.0_jprb

! mixed gases
!---

  last_prof = -1
  DO i = 1, nchannels
    prof = chanprof(i)%prof
    IF (prof .NE. last_prof) THEN
      DO lay=1, nlayers
        mgtemp(1,lay) = 2._jprb * raytracing%pathsat(lay, prof)
        mgtemp(2,lay) = mgtemp(1,lay) * aux%tr(lay, prof)
        mgtemp(3,lay) = aux%tw(lay, prof) * aux%tr_r(lay, prof)
        mgtemp(4,lay) = raytracing%pathsat(lay, prof) * aux%tw(lay, prof)
      ENDDO
      last_prof = prof
    ENDIF

    DO lay = 1, nlayers
      ! only effective for non-Zeeman chans 1-18,23-24 - coefficient file will have zeros for chan 19-22
      raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
                                     predictors_k(i)%mixedgas(1, lay) + &
        mgtemp(1,lay)   *            predictors_k(i)%mixedgas(2, lay) + &
        aux%tr(lay, prof) *          predictors_k(i)%mixedgas(3, lay) + &
        aux%tr(lay, prof) **2_jpim * predictors_k(i)%mixedgas(4, lay) + &
        aux%tw(lay, prof) *          predictors_k(i)%mixedgas(7, lay) + &
        mgtemp(3,lay)   *            predictors_k(i)%mixedgas(8, lay)

      aux_k%tr(lay, i) = &!aux_k%tr(lay, i) + &
        raytracing%pathsat(lay, prof) * predictors_k(i)%mixedgas(3, lay) + &
        mgtemp(2,lay) *                 predictors_k(i)%mixedgas(4, lay) + &
                                        predictors_k(i)%mixedgas(5, lay) + &
        2._jprb * aux%tr(lay, prof) *   predictors_k(i)%mixedgas(6, lay)

      aux_k%tw(lay, i) = &!aux_k%tw(lay, i) +
        raytracing%pathsat(lay, prof) * ( predictors_k(i)%mixedgas(7, lay) + &
                    aux%tr_r(lay, prof) * predictors_k(i)%mixedgas(8, lay))

      aux_k%tr_r(lay, i) = &!aux_k%tr_r(lay, i) + &
        mgtemp(4,lay) * predictors_k(i)%mixedgas(8, lay)

      raytracing_k%pathsat_sqrt(lay, i) = &!raytracing_k%pathsat_sqrt(lay, i) + &
                                predictors_k(i)%mixedgas(9, lay) + &
        aux%tw_4rt(lay, prof) * predictors_k(i)%mixedgas(10, lay)

      aux_k%tw_4rt(lay, i) = &!aux_k%tw_4rt(lay, i) + &
        raytracing%pathsat_sqrt(lay, prof) * predictors_k(i)%mixedgas(10, lay)

    ENDDO
  ENDDO

  IF (coef%id_inst == inst_id_ssmis .AND. coef%inczeeman) THEN
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      DO lay = 1, nlayers
        ! SSMIS with Zeeman coefficient file
        ! geomagnetic field variables (Be, cosbk) are part of the user input

        ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        ! NB require prof(i) % Be >0. (divisor)

        ! X11 -> X21
        ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        predictors_k(i)%mixedgas(20, lay) = predictors_k(i)%mixedgas(20, lay) + &
           predictors_k(i)%mixedgas(21, lay) * profiles(prof)%Be
        predictors_k(i)%mixedgas(13, lay) = predictors_k(i)%mixedgas(13, lay) + &
           predictors_k(i)%mixedgas(20, lay) * profiles(prof)%Be

        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
           profiles(prof)%Be ** 3_jpim * predictors_k(i)%mixedgas(19, lay)
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          profiles(prof)%Be * predictors_k(i)%mixedgas(18, lay)

        predictors_k(i)%mixedgas(16, lay) = predictors_k(i)%mixedgas(16, lay) + &
          predictors_k(i)%mixedgas(17, lay) / profiles(prof)%Be
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          predictors_k(i)%mixedgas(16, lay) / profiles(prof)%Be
        predictors_k(i)%mixedgas(12, lay) = predictors_k(i)%mixedgas(12, lay) + &
          predictors_k(i)%mixedgas(15, lay) * profiles(prof)%cosbk ** 2_jpim
        predictors_k(i)%mixedgas(12, lay) = predictors_k(i)%mixedgas(12, lay) + &
          predictors_k(i)%mixedgas(14, lay) / profiles(prof)%Be

        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          profiles(prof)%cosbk ** 2_jpim * predictors_k(i)%mixedgas(13, lay)
        
        aux_k%t_layer(lay, i) = aux_k%t_layer(lay, i) - &
          (predictors(prof)%mixedgas(12, lay) / &
          aux%t_layer(lay, prof)) * predictors_k(i)%mixedgas(12, lay)

        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          (300.0_jprb / aux%t_layer(lay, prof)) * predictors_k(i)%mixedgas(12, lay)
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + predictors_k(i)%mixedgas(11, lay)
      ENDDO
    ENDDO
  ELSEIF (coef%id_inst == inst_id_amsua .AND. coef%inczeeman) THEN
    ! AMSU-A with Zeeman coefficient file
    ! only effective for Zeeman chan 14 - coefficient file will have zeros for chan 1-13
    ! NB some of YH's original predictors omitted - effectively duplicated by predictors 1-4 above
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      DO lay = 1, nlayers
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          profiles(prof)%cosbk ** 2_jpim * predictors_k(i)%mixedgas(11, lay)
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) +     &
          2.0_jprb * profiles(prof)%Be * raytracing%pathsat(lay, prof) * predictors_k(i)%mixedgas(12, lay)
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          profiles(prof)%Be ** 3_jpim * predictors_k(i)%mixedgas(13, lay)
        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
          2.0_jprb * (profiles(prof)%cosbk * profiles(prof)%Be) ** 2_jpim * &
          raytracing%pathsat(lay, prof) * predictors_k(i)%mixedgas(14, lay)
      ENDDO
    ENDDO
  ENDIF

! water vapour - numbers in right hand are predictor numbers
! in the reference document for RTTOV7 (science and validation report)
!----------------
  last_prof = -1
  IF (coef%fmv_model_ver == 7) THEN
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      IF (prof .NE. last_prof) THEN
        sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, prof) * aux%wr_sqrt(:, prof)
        sec_wr(:) = sec_wr_sqrt(:)**2_jpim

        DO lay=1, nlayers
          wtemp(1,lay) = sec_wr(lay) * aux%ww_r(lay, prof)
          wtemp(2,lay) = sec_wr_sqrt(lay) * aux%ww_r(lay, prof)
          wtemp(3,lay) = sec_wr(lay) * aux%tr_r(lay, prof)
          wtemp(4,lay) = wtemp(3,lay) * aux%tr_r(lay, prof)**3_jpim
          wtemp(5,lay) = sec_wr(lay) * aux%wr(lay, prof)
          wtemp(6,lay) = 4._jprb * aux%tr_r(lay, prof)**2_jpim * predictors(prof)%watervapour(14, lay)
          wtemp(7,lay) = 2._jprb * raytracing%pathsat(lay, prof) * aux%ww(lay, prof)**2_jpim
          wtemp(8,lay) = 2._jprb * raytracing%pathsat(lay, prof)**2_jpim * aux%ww(lay, prof)
          wtemp(9,lay) = 2._jprb * predictors(prof)%watervapour(13, lay)
          wtemp(10,lay) = 2._jprb * ABS(aux%dt(lay, prof)) * sec_wr(lay)
          wtemp(11,lay) = aux%wr(lay, prof) * aux%ww_r(lay, prof)
          wtemp(12,lay) = 2._jprb * sec_wr(lay)
          wtemp(13,lay) = 3._jprb * sec_wr(lay)**2_jpim
          wtemp(14,lay) = 4._jprb * sec_wr(lay)**3_jpim
          wtemp(15,lay) = ABS(aux%dt(lay, prof)) * aux%dt(lay, prof)
          wtemp(16,lay) = aux%wr(lay, prof) * aux%tr_r(lay, prof)
          wtemp(17,lay) = aux%wr(lay, prof) * aux%tr_r(lay, prof)**4_jpim
          wtemp(18,lay) = sec_wr_sqrt(lay) * aux%wr(lay, prof)
        ENDDO
        wtemp(19,:) = 0.5_jprb * SQRT(raytracing%pathsat_rsqrt(:, prof) * aux%wr_rsqrt(:, prof))
        last_prof = prof
      ENDIF

      DO lay = 1, nlayers

        aux_k%wr(lay, i) = &!aux_k%wr(lay, i) + &
          wtemp(1,lay) * predictors_k(i)%watervapour(3, lay)  + &  !12
          wtemp(2,lay) * predictors_k(i)%watervapour(8, lay) + &   !13
          wtemp(3,lay) * predictors_k(i)%watervapour(14, lay) + &
          wtemp(4,lay) * predictors_k(i)%watervapour(15, lay)

        aux_k%tr_r(lay, i) = aux_k%tr_r(lay, i) + &
          wtemp(5,lay) * predictors_k(i)%watervapour(14, lay) + &
          wtemp(6,lay) * predictors_k(i)%watervapour(15, lay)

        raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
           wtemp(7,lay) * ( &
                            wtemp(9,lay) * predictors_k(i)%watervapour(12, lay) + &
                                           predictors_k(i)%watervapour(13, lay))

        aux_k%ww(lay, i) = &!aux_k%ww(lay, i) + &
           wtemp(8,lay) * ( &
                            wtemp(9,lay) * predictors_k(i)%watervapour(12, lay) + &
                                           predictors_k(i)%watervapour(13, lay))

        aux_k%dt(lay, i) = &!aux_k%dt(lay, i) + &
          sec_wr(lay) *       predictors_k(i)%watervapour(4, lay) + & !4
          sec_wr_sqrt(lay) *  predictors_k(i)%watervapour(6, lay) + & !11
          wtemp(10,lay) *     predictors_k(i)%watervapour(11, lay)    ! 10
      ENDDO

      DO lay = 1, nlayers
        sec_wr_k(lay) = &!sec_wr_k(lay) + &
                                          predictors_k(i)%watervapour(1, lay) + &  !  7
          wtemp(11,lay) *                 predictors_k(i)%watervapour(3, lay) + &  ! 12
          aux%dt(lay, prof) *             predictors_k(i)%watervapour(4, lay) + &  !  4
          wtemp(12,lay)         *         predictors_k(i)%watervapour(5, lay) + &  !  1
          wtemp(13,lay) *                 predictors_k(i)%watervapour(9, lay) + &
          wtemp(14,lay) *                 predictors_k(i)%watervapour(10, lay) + &
          wtemp(15,lay) *                 predictors_k(i)%watervapour(11, lay)+ &  ! 10
          wtemp(16,lay) *                 predictors_k(i)%watervapour(14, lay)+ &     ! 14
          wtemp(17,lay) *                 predictors_k(i)%watervapour(15, lay)          

        sec_wr_sqrt_k(lay) = &!sec_wr_sqrt_k(lay) + &
                              predictors_k(i)%watervapour(2, lay) + &                  !  5
          aux%dt(lay, prof) * predictors_k(i)%watervapour(6, lay) + &!11
          wtemp(19,lay) *     predictors_k(i)%watervapour(7, lay) + &! 6
          wtemp(11,lay) *     predictors_k(i)%watervapour(8, lay) !13

        aux_k%ww_r(lay, i) = &!aux_k%ww_r(lay, i) + &
          wtemp(5,lay) *  predictors_k(i)%watervapour(3, lay) + &!12
          wtemp(18,lay) * predictors_k(i)%watervapour(8, lay) ! 13
      ENDDO

      sec_wr_sqrt_k(:) = sec_wr_sqrt_k(:) + &
        2._jprb * sec_wr_sqrt(:) * sec_wr_k(:)

      raytracing_k%pathsat_sqrt(:, i) = raytracing_k%pathsat_sqrt(:, i) + &
        aux%wr_sqrt(:, prof) * sec_wr_sqrt_k(:) 
      aux_k%wr_sqrt(:, i) = &!aux_k%wr_sqrt(:, i) + &
        raytracing%pathsat_sqrt(:, prof) * sec_wr_sqrt_k(:)
    ENDDO
  ELSEIF(coef%fmv_model_ver == 8) THEN ! version 8
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      IF (prof .NE. last_prof) THEN
        sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, prof) * aux%wr_sqrt(:, prof)
        sec_wr(:) = sec_wr_sqrt(:)**2_jpim    
        sec_ww(:) = raytracing%pathsat(:, prof) * aux%ww(:,prof)
        wr_wwr_r(:) = aux%wr(:, prof) * aux%wwr_r(:, prof)
        sec_wrtr_r(:) = sec_wr(:) * aux%tr_r(:, prof)
        sec_wrwrtr_r(:) = sec_wrtr_r(:) * aux%wr(:, prof)

        wtemp(1,:) = 3._jprb * sec_wrwrtr_r(:) * aux%tr_r(:, prof)**2_jpim
        wtemp(2,:) = aux%tr_r(:, prof)**3_jpim
        wtemp(3,:) = 3._jprb * sec_wr(:) ** 2_jpim
        wtemp(4,:) = ABS(aux%dt(:, prof)) * aux%dt(:, prof)
        wtemp(5,:) = 2._jprb * ABS(aux%dt(:, prof)) * sec_wr(:)
        wtemp(6,:) = 0.5_jprb * SQRT(raytracing%pathsat_rsqrt(:, prof) * aux%wr_rsqrt(:, prof))
      ENDIF
      last_prof = prof

      IF (coef%nwvcont > 0) THEN
        DO lay = 1, nlayers

          sec_wrtr_r_k(lay) = &! sec_tr_r_k(lay) + &
                                                        predictors_k(i)%wvcont(3, lay) + &
                             aux%tr_r(lay, prof) *      predictors_k(i)%wvcont(4, lay)
                                                       
          aux_k%tr_r(lay, i) = aux_k%tr_r(lay, i) + &
            wtemp(1,lay) *    predictors_k(i)%wvcont(2, lay) + &
            sec_wrtr_r(lay) * predictors_k(i)%wvcont(4, lay)

          sec_wrwrtr_r_k(lay) = &!sec_wrwrtr_r_k(lay) + &
            wtemp(2,lay) * predictors_k(i)%wvcont(2, lay) + &
                           predictors_k(i)%wvcont(1, lay)
        ENDDO

        aux_k%wr(:,i) = &!aux_k%wr(:,i) + &
                         sec_wrtr_r(:) * sec_wrwrtr_r_k(:)

        sec_wrtr_r_k(:) = sec_wrtr_r_k(:) + aux%wr(:,prof) * sec_wrwrtr_r_k(:)

        aux_k%tr_r(:,i) = aux_k%tr_r(:,i) + sec_wr(:) * sec_wrtr_r_k(:)
        sec_wr_k(:) = &!sec_wr_k(:) + 
                       aux%tr_r(:,prof) * sec_wrtr_r_k(:)
      ELSE
        sec_wr_k(:) = 0._jprb ! need sec_wr_k to be initialised
        aux_k%wr(:,i) = 0._jprb
      ENDIF

      DO lay = 1, nlayers
        sec_wr_k(lay) = sec_wr_k(lay) + & 
          2._jprb * sec_wr(lay) *                predictors_k(i)%watervapour(1, lay) + &
          aux%dt(lay, prof)     *                predictors_k(i)%watervapour(4, lay) + &
                                                 predictors_k(i)%watervapour(7, lay) + &
          wtemp(3,lay) *                         predictors_k(i)%watervapour(8, lay) + &
          wtemp(4,lay) *                         predictors_k(i)%watervapour(9, lay) + &
          wr_wwr_r(lay) *                        predictors_k(i)%watervapour(11, lay)

        sec_ww_k(lay) = &!sec_ww_k(lay) + &
                                                 predictors_k(i)%watervapour(2, lay) + &
          2._jprb * sec_ww(lay) *                predictors_k(i)%watervapour(3, lay)

        aux_k%dt(lay, i) = &!aux_k%dt(lay, i) + &
          sec_wr(lay) *                          predictors_k(i)%watervapour(4, lay) + &
          wtemp(5,lay) *                         predictors_k(i)%watervapour(9, lay) + &
          sec_wr_sqrt(lay) *                     predictors_k(i)%watervapour(10, lay)

        sec_wr_sqrt_k(lay) = &!sec_wr_sqrt_k(lay) + &
                                                 predictors_k(i)%watervapour(5, lay) + &
          wtemp(6,lay) *                         predictors_k(i)%watervapour(6, lay) + &
          aux%dt(lay, prof) *                    predictors_k(i)%watervapour(10, lay) + &
          wr_wwr_r(lay) *                        predictors_k(i)%watervapour(12, lay)

        wr_wwr_r_k(lay) = &!wr_wwr_r_k(lay) + &
          sec_wr(lay) *                          predictors_k(i)%watervapour(11, lay) + &
          sec_wr_sqrt(lay) *                     predictors_k(i)%watervapour(12, lay)
      ENDDO

      aux_k%wr(:, i) = aux_k%wr(:, i) + &
                        aux%wwr_r(:, prof) * wr_wwr_r_k(:)
      aux_k%wwr_r(:, i) = &!aux_k%wwr_r(:, i) + 
                           aux%wr(:, prof) * wr_wwr_r_k(:)

      raytracing_k%pathsat(:, i) = raytracing_k%pathsat(:, i) + &
                                            aux%ww(:, prof) * sec_ww_k(:)
      aux_k%ww(:, i) = &!aux_k%ww(:, i) + 
                           raytracing%pathsat(:, prof) * sec_ww_k(:)

      sec_wr_sqrt_k(:) = sec_wr_sqrt_k(:) + 2._jprb * sec_wr_sqrt(:) * sec_wr_k(:)

      raytracing_k%pathsat_sqrt(:, i) = raytracing_k%pathsat_sqrt(:, i) + &
        aux%wr_sqrt(:, prof) * sec_wr_sqrt_k(:)

      aux_k%wr_sqrt(:, i) = &!aux_k%wr_sqrt(:, i) + &
        raytracing%pathsat_sqrt(:, prof) * sec_wr_sqrt_k(:)

    ENDDO

  ENDIF
    
! ozone
!---------
  last_prof = -1
  IF (coef%nozone > 0) THEN
    IF(opts%rt_ir%ozone_Data) THEN
      DO i = 1, nchannels
        prof = chanprof(i)%prof

        IF (prof .NE. last_prof) THEN
          sec_or_sqrt(:) = raytracing%pathsat_sqrt(:, prof) * aux%or_sqrt(:, prof)
          o3temp(1,:) = 2._jprb * predictors(prof)%ozone(10, :)
          o3temp(2,:) = sec_or_sqrt(:)**2_jpim

          o3temp(3, :)  = o3temp(2,:) * aux%ow_sqrt(:, prof)
          o3temp(4, :)  = o3temp(2,:) * aux%or(:, prof)
          o3temp(5, :)  = aux%ow(:, prof) * aux%or(:, prof)
          o3temp(6, :)  = raytracing%pathsat_sqrt(:, prof) * aux%ow_sqrt(:, prof)
          o3temp(7, :)  = aux%or(:, prof) * aux%ow_r(:, prof)
          o3temp(8, :)  = o3temp(2,:) * aux%ow(:, prof)
          o3temp(9, :)  = sec_or_sqrt(:) * aux%ow_r(:, prof)
          o3temp(10, :) = sec_or_sqrt(:) * aux%or(:, prof)
          o3temp(11, :) = o3temp(2,:) * raytracing%pathsat_sqrt(:, prof)

          last_prof = prof
        ENDIF

        DO lay = 1, nlayers
          raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
            aux%ow(lay, prof) *                     (predictors_k(i)%ozone(10, lay) + &
            o3temp(1,lay) *                          predictors_k(i)%ozone(11, lay))

          raytracing_k%pathsat_sqrt(lay, i) = raytracing_k%pathsat_sqrt(lay, i) + &
            o3temp(3,lay) * predictors_k(i)%ozone(9, lay)

          aux_k%ow(lay, i) = &!aux_k%ow(lay, i) + &
            o3temp(4,lay) *                  predictors_k(i)%ozone(6, lay) + &
            o3temp(2,lay) *                  predictors_k(i)%ozone(8, lay) + & ! * sec_or(lay)
            raytracing%pathsat(lay, prof) * (predictors_k(i)%ozone(10, lay) + &
            o3temp(1,lay) *                  predictors_k(i)%ozone(11, lay))

          sec_or_k(lay) = &!sec_or_k(lay) + &
                                      predictors_k(i)%ozone(1, lay) + &
            aux%dto(lay, prof) *      predictors_k(i)%ozone(3, lay) + &
            2._jprb * o3temp(2,lay) * predictors_k(i)%ozone(4, lay) + &
            o3temp(5,lay) *           predictors_k(i)%ozone(6, lay) + &
            aux%ow(lay, prof) *       predictors_k(i)%ozone(8, lay)+ &
            o3temp(6,lay) *           predictors_k(i)%ozone(9, lay)

          sec_or_sqrt_k(lay) = &!sec_or_sqrt_k(lay) + &
                                 predictors_k(i)%ozone(2, lay) + &
            aux%dto(lay, prof) * predictors_k(i)%ozone(5, lay) + &
            o3temp(7,lay)    *   predictors_k(i)%ozone(7, lay)

          aux_k%dto(lay, i) = &!aux_k%dto(lay, i) + &
            o3temp(2,lay) * predictors_k(i)%ozone(3, lay) + &
            sec_or_sqrt(lay) * predictors_k(i)%ozone(5, lay)

          aux_k%or(lay, i) = &!aux_k%or(lay, i) + &
            o3temp(8,lay) * predictors_k(i)%ozone(6, lay) + &
            o3temp(9,lay) * predictors_k(i)%ozone(7, lay)

          aux_k%ow_r(lay, i) = &!aux_k%ow_r(lay, i) +
            o3temp(10,lay) * predictors_k(i)%ozone(7, lay)

          aux_k%ow_sqrt(lay, i) = &!aux_k%ow_sqrt(lay, i) + &
            o3temp(11,lay) * predictors_k(i)%ozone(9, lay)
        ENDDO

        sec_or_sqrt_k(:) = sec_or_sqrt_k(:) + &
          2._jprb * sec_or_sqrt(:) * sec_or_k(:)

        raytracing_k%pathsat_sqrt(:, i) = raytracing_k%pathsat_sqrt(:, i) + &
          aux%or_sqrt(:, prof) * sec_or_sqrt_k(:)

        aux_k%or_sqrt(:, i) = &!aux_k%or_sqrt(:, i) + &
          raytracing%pathsat_sqrt(:, prof) * sec_or_sqrt_k(:)
      ENDDO
    ELSE ! no ozone data
      DO i = 1, nchannels
        prof = chanprof(i)%prof

        IF (prof .NE. last_prof) THEN
          o3temp(1,:) = 2._jprb * raytracing%pathsat(:, prof) 
          o3temp(2,:) = 1.5_jprb * raytracing%pathsat_sqrt(:, prof) 
          last_prof = prof
        ENDIF

        DO lay = 1, nlayers
          raytracing_k%pathsat(lay, i) = raytracing_k%pathsat(lay, i) + &
                                                          predictors_k(i)%ozone(1, lay) + &
             aux%dto(lay, prof) *                            predictors_k(i)%ozone(3, lay) + &
                                          o3temp(1,lay) * predictors_k(i)%ozone(4, lay) + &
                                                          predictors_k(i)%ozone(6, lay) + &
                                                          predictors_k(i)%ozone(8, lay) + &
                                          o3temp(2,lay) * predictors_k(i)%ozone(9, lay) + &
                                                          predictors_k(i)%ozone(10, lay) + &
                                          o3temp(1,lay) * predictors_k(i)%ozone(11, lay)

          raytracing_k%pathsat_sqrt(lay, i) = raytracing_k%pathsat_sqrt(lay, i) + &
                                                          predictors_k(i)%ozone(2, lay) + &
             aux%dto(lay, prof) *                            predictors_k(i)%ozone(5, lay) + &                                      
                                                          predictors_k(i)%ozone(7, lay)

          aux_k%dto(lay, i) = &!aux_k%dto(lay, i) + &
            raytracing%pathsat(lay, prof) *      predictors_k(i)%ozone(3, lay) + &
            raytracing%pathsat_sqrt(lay, prof) * predictors_k(i)%ozone(5, lay)

        ENDDO
      ENDDO
    ENDIF
  ENDIF

!5.6 carbon dioxide transmittance based on RTIASI
!-------------------------------------------------
!

!v8 specific predictors
  last_prof = -1
  IF (coef%fmv_model_ver == 8) THEN
    IF (coef%nco2 > 0) THEN      
      DO i = 1, nchannels
        prof = chanprof(i)%prof
        IF (prof .NE. last_prof) THEN
          co2temp(1,:) = aux%tr(:, prof)**2_jpim
          co2temp(2,:) = aux%tr_sqrt(:, prof) * aux%twr(:, prof)
          co2temp(3,:) = 2._jprb * aux%tr(:, prof)
          co2temp(4,:) = 2._jprb * raytracing%pathsat(:, prof) * aux%tr(:, prof)
          co2temp(5,:) = 3._jprb * aux%twr(:, prof) ** 2_jpim
          co2temp(6,:) = aux%tr_sqrt(:, prof) * raytracing%pathsat(:, prof)
          co2temp(7,:) = raytracing%pathsat(:, prof) * aux%twr(:, prof)
        ENDIF

        DO lay = 1, nlayers
          
          raytracing_k%pathsat(lay, i)= raytracing_k%pathsat(lay, i) + &
            aux%tr(lay, prof) *            predictors_k(i)%co2(3, lay) + &
            co2temp(1,lay) *               predictors_k(i)%co2(4, lay) + &
                                           predictors_k(i)%co2(6, lay) + &
            aux%twr(lay, prof) *           predictors_k(i)%co2(7, lay) + &                    
            co2temp(2,lay) *               predictors_k(i)%co2(10, lay)

          aux_k%tr(lay, i) = aux_k%tr(lay, i) + &
            co2temp(3,lay) *                predictors_k(i)%co2(2, lay) + &
            raytracing%pathsat(lay, prof) * predictors_k(i)%co2(3, lay) + &
            co2temp(4,lay) *                predictors_k(i)%co2(4, lay) + &
                                            predictors_k(i)%co2(5, lay)
          aux_k%twr(lay, i) = &!aux_k%twr(lay, i) + &
            raytracing%pathsat(lay, prof) * predictors_k(i)%co2(7, lay) + &
            co2temp(5,lay) *                predictors_k(i)%co2(9, lay) + &
            co2temp(6,lay) *                predictors_k(i)%co2(10, lay)

          aux_k%tr_sqrt(lay, i) = &!aux_k%tr_sqrt(lay, i) + &
            co2temp(7,lay) *             predictors_k(i)%co2(10, lay)
        ENDDO

        IF(opts%rt_ir%co2_data) THEN !no user-supplied co2_data so no co2r co2w ( preds 1&8 differ)
          IF (prof .NE. last_prof) THEN
            co2temp_t(:,1) = 2._jprb * raytracing%pathsat(:, prof) * aux%co2w(:, prof)**2_jpim
            co2temp_t(:,2) = 2._jprb * raytracing%pathsat(:, prof)**2_jpim * aux%co2w(:, prof)
          ENDIF

          raytracing_k%pathsat(:, i) = raytracing_k%pathsat(:, i) + &
            aux%co2r(:, prof) *           predictors_k(i)%co2(1, :) + &
            co2temp_t(:,1) *              predictors_k(i)%co2(8, :)
 
          aux_k%co2r(:, i) = &!aux_k%co2r(:, i) + &
            raytracing%pathsat(:, prof) * predictors_k(i)%co2(1, :)

          aux_k%co2w(:, i) = &!aux_k%co2w(:, i) + &
            co2temp_t(:,2) *              predictors_k(i)%co2(8, :)
        ELSE
          raytracing_k%pathsat(:, i) = raytracing_k%pathsat(:, i) + &
                                                     predictors_k(i)%co2(1, :) + &          
             2._jprb * raytracing%pathsat(:, prof) * predictors_k(i)%co2(8, :)
        ENDIF

        ! defer until end of loop in case we need to update co2_data aswell
        last_prof = prof
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

! This is on coef levels so pressure is not an active variable in the K

    DO i = 1, nchannels
       j = chanprof(i)%prof
       k = chanprof(i)%chan

      DO lay = 1, nlay
        lev = lay + 1

        acm = raytracing%co2_cm(j) / (2._jprb*betaplus1*Lcel_cm)

        Pcel_Lev = acm*raytracing%pathsat(lay,j)*profiles(j)%p(lev  )**2_jpim + Pcel(k)**2_jpim
        Pnom_LevM1 = acm*raytracing%pathsat(lay,j)*profiles(j)%p(lev-1)**2_jpim + Pnom(k)**2_jpim
        Pcel_LevM1 = acm*raytracing%pathsat(lay,j)*profiles(j)%p(lev-1)**2_jpim + Pcel(k)**2_jpim
        Pnom_Lev = acm*raytracing%pathsat(lay,j)*profiles(j)%p(lev  )**2_jpim + Pnom(k)**2_jpim
! AD
        Pcel_Lev_K =  0._jprb
        Pnom_LevM1_K = 0._jprb
        Pcel_LevM1_K =  0._jprb
        Pnom_Lev_K = 0._jprb
        acm_K = 0._jprb
        ! for PMC predictor 2
        predictors_K(i)%pmc(2,lay,k)=0._jprb
! for PMC predictor 1
        Pcel_Lev_K = Pcel_Lev_K                                                    &
          + predictors_K(i)%pmc(1,lay,k) * Pnom_LevM1/(Pcel_Lev*Pnom_LevM1)
        Pnom_LevM1_K = Pnom_LevM1_K                                                  &
          + predictors_K(i)%pmc(1,lay,k) * Pcel_Lev/(Pcel_Lev*Pnom_LevM1)
        Pcel_LevM1_K = Pcel_LevM1_K                                                    &
          - predictors_K(i)%pmc(1,lay,k) * Pnom_Lev/(Pcel_LevM1*Pnom_Lev)
        Pnom_Lev_K = Pnom_Lev_K                                                  &
          - predictors_K(i)%pmc(1,lay,k) * Pcel_LevM1/(Pcel_LevM1*Pnom_Lev)
        predictors_K(i)%pmc(1,lay,k) = 0._jprb
        
        acm_K = acm_K                                                              &
          + Pnom_Lev_K * raytracing%pathsat(lay,j)*profiles(j)%p(lev  )**2_jpim
        raytracing_K%pathsat(lay,i) = raytracing_K%pathsat(lay,i)      &
          + Pnom_Lev_K * acm * profiles(j)%p(lev  )**2_jpim
        Pnom_Lev_K = 0._jprb
        
        acm_K = acm_K                                                              &
          + Pcel_LevM1_K * raytracing%pathsat(lay,j)*profiles(j)%p(lev-1)**2_jpim
        raytracing_K%pathsat(lay,i) = raytracing_K%pathsat(lay,i)      &
          + Pcel_LevM1_K * acm * profiles(j)%p(lev-1)**2_jpim
        Pcel_LevM1_K = 0._jprb
        
        acm_K = acm_K                                                              &
          + Pnom_LevM1_K * raytracing%pathsat(lay,j)*profiles(j)%p(lev-1)**2_jpim
        raytracing_K%pathsat(lay,i) = raytracing_K%pathsat(lay,i)      &
          + Pnom_LevM1_K * acm * profiles(j)%p(lev-1)**2_jpim
        Pnom_LevM1_K = 0._jprb
        
        acm_K = acm_K                                                              &
          + Pcel_Lev_K * raytracing%pathsat(lay,j)*profiles(j)%p(lev  )**2_jpim
        raytracing_K%pathsat(lay,i) = raytracing_K%pathsat(lay,i)      &
          + Pcel_Lev_K * acm * profiles(j)%p(lev  )**2_jpim
        Pcel_Lev_K = 0._jprb
        
        raytracing_K%co2_cm(i) = raytracing_K%co2_cm(i)                    &
          + acm_K/(2._jprb*betaplus1*Lcel_cm)
        acm_K = 0._jprb
        
      ENDDO
    ENDDO
  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78_K', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_78_k
