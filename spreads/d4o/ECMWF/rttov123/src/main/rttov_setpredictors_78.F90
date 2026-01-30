! Description:
!> @file
!!   Calculates v7 and v8 predictors.
!!
!> @brief
!!   Calculates v7 and v8 predictors.
!!
!! @details
!!   The v7 predictors allow for optional variable O3. 
!!
!!   The v8 predictors include separate water vapour continuum and
!!   allow for optional variable O3, and CO2. Predictors are also
!!   calculated the pressure modulated cell (PMC) sensor capability.
!!
!!   Various quantities used in the calculations were precalculated
!!   in rttov_profaux.
!!
!!   This subroutine operates on coefficient layers/levels.
!!
!!
!! @param[in]     opts            RTTOV options
!! @param[in]     prof            profiles on coefficient levels
!! @param[in]     coef            rttov_coef structure
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in,out] predictors      calculated predictors
!! @param[in]     raytracing      RTTOV raytracing structure
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

SUBROUTINE rttov_setpredictors_78( &
             opts,       &
             prof,       &
             coef,       &
             aux,        &
             predictors, &
             raytracing)

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
  TYPE(rttov_path_pred)   , INTENT(INOUT) :: predictors(:)
  TYPE(rttov_profile_aux) , INTENT(IN)    :: aux
  TYPE(rttov_raytracing)  , INTENT(IN)    :: raytracing
!INTF_END

  INTEGER(KIND=jpim) :: lev, lay, i, iprof, ichan
  REAL   (KIND=jprb) :: sec_or(prof(1)%nlayers), sec_or_sqrt(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wr(prof(1)%nlayers), sec_wr_sqrt(prof(1)%nlayers)
  REAL   (KIND=jprb) :: wr_wwr_r(prof(1)%nlayers), sec_wrtr_r(prof(1)%nlayers)
  REAL   (KIND=jprb) :: sec_wrwrtr_r(prof(1)%nlayers)

  INTEGER(KIND=jpim) :: nprofiles, nlayers
  REAL   (KIND=jprb) :: ZHOOK_HANDLE

! pressure-moodulated cell (pmc) variables
  REAL   (KIND=jprb) :: Lcel_cm, betaplus1
  REAL   (KIND=jprb) :: acm
  REAL   (KIND=jprb) :: Pcel_Lev, Pnom_LevM1, Pcel_LevM1, Pnom_Lev
  REAL   (KIND=jprb) :: Pnom(coef%fmv_chn), Pcel(coef%fmv_chn)
  REAL   (KIND=jprb) :: Pupper, Plower

!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers

! aux% variables are calculated in rttov_profaux

! mixed gases
!---
  DO i = 1, nprofiles
    DO lay = 1, nlayers
      ! only effective for non-Zeeman chans 1-18,23-24 - coefficient file will have zeros for chan 19-22
      predictors(i)%mixedgas(1, lay)  = raytracing%pathsat(lay, i)
      predictors(i)%mixedgas(2, lay)  = raytracing%pathsat(lay, i) ** 2_jpim
      predictors(i)%mixedgas(3, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i)
      predictors(i)%mixedgas(4, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i) ** 2_jpim
      predictors(i)%mixedgas(5, lay)  = aux%tr(lay, i)
      predictors(i)%mixedgas(6, lay)  = aux%tr(lay, i) ** 2_jpim
      predictors(i)%mixedgas(7, lay)  = raytracing%pathsat(lay, i) * aux%tw(lay, i)
      predictors(i)%mixedgas(8, lay)  = raytracing%pathsat(lay, i) * aux%tw(lay, i) * aux%tr_r(lay, i)
      predictors(i)%mixedgas(9, lay)  = raytracing%pathsat_sqrt(lay, i)
      predictors(i)%mixedgas(10, lay) = raytracing%pathsat_sqrt(lay, i) * aux%tw_4rt(lay, i)
    ENDDO
  ENDDO

  IF (coef%id_inst == inst_id_ssmis .AND. coef%inczeeman) THEN
    DO i = 1, nprofiles
      DO lay = 1, nlayers
        ! SSMIS with Zeeman coefficient file
        ! geomagnetic field variables (Be, cosbk) are part of the user input
        
        ! only effective for Zeeman chans 19-22 - coefficient file will have zeros for chan 1-18,23-24
        ! NB require prof(i) % Be > 0. (divisor)
        predictors(i)%mixedgas(11, lay) = raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(12, lay) = (300.0_jprb/aux%t_layer(lay, i)) * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(13, lay) = prof(i)%cosbk**2_jpim * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(14, lay) = predictors(i)%mixedgas(12, lay) / prof(i)%Be
        predictors(i)%mixedgas(15, lay) = predictors(i)%mixedgas(12, lay) * prof(i)%cosbk**2_jpim
        predictors(i)%mixedgas(16, lay) = raytracing%pathsat(lay, i) / prof(i)%Be
        predictors(i)%mixedgas(17, lay) = predictors(i)%mixedgas(16, lay) / prof(i)%Be
        predictors(i)%mixedgas(18, lay) = prof(i)%Be * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(19, lay) = prof(i)%Be**3_jpim * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(20, lay) = predictors(i)%mixedgas(13, lay) * prof(i)%Be
        predictors(i)%mixedgas(21, lay) = predictors(i)%mixedgas(20, lay) * prof(i)%Be
      ENDDO
    ENDDO
  ELSEIF (coef%id_inst == inst_id_amsua .AND. coef%inczeeman) THEN
    ! AMSU-A with Zeeman coefficient file
    ! only effective for Zeeman chan 14 - coefficient file will have zeros for chan 1-13
    ! NB some of YH's original predictors omitted - effectively duplicated by predictors 1-4 above
    DO i = 1, nprofiles
      DO lay = 1, nlayers
        predictors(i)%mixedgas(11, lay) = prof(i)%cosbk ** 2_jpim * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(12, lay) = prof(i)%Be * raytracing%pathsat(lay, i) ** 2_jpim
        predictors(i)%mixedgas(13, lay) = prof(i)%Be ** 3_jpim * raytracing%pathsat(lay, i)
        predictors(i)%mixedgas(14, lay) = (prof(i)%cosbk * prof(i)%Be * raytracing%pathsat(lay, i)) ** 2_jpim
      ENDDO
    ENDDO
  ENDIF

! water vapour - numbers in right hand are predictor numbers
! in the reference document for RTTOV7 (science and validation report)
!----------------

  IF (coef%fmv_model_ver == 7) THEN
    DO i = 1, nprofiles
      sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i)
      sec_wr(:) = sec_wr_sqrt(:)**2_jpim

      DO lay = 1, nlayers
        predictors(i)%watervapour(1, lay)  = sec_wr(lay)                                                           !  7
        predictors(i)%watervapour(2, lay)  = sec_wr_sqrt(lay)                                                      !  5
        predictors(i)%watervapour(3, lay)  = sec_wr(lay) * aux%wr(lay, i) * aux%ww_r(lay, i)                       ! 12
        predictors(i)%watervapour(4, lay)  = sec_wr(lay) * aux%dt(lay, i)                                          !  4
        predictors(i)%watervapour(5, lay)  = sec_wr(lay) * sec_wr(lay)                                             !  1
        predictors(i)%watervapour(6, lay)  = sec_wr_sqrt(lay) * aux%dt(lay, i)                                     ! 11
        predictors(i)%watervapour(7, lay)  = SQRT(sec_wr_sqrt(lay))                                                ! 6
        predictors(i)%watervapour(8, lay)  = sec_wr_sqrt(lay) * aux%wr(lay, i) * aux%ww_r(lay, i)                  ! 13
      ENDDO
      predictors(i)%watervapour(9, :) = predictors(i)%watervapour(5, :) * sec_wr(:) ! sec_wr^3                               ! 8
      predictors(i)%watervapour(10,:) = predictors(i)%watervapour(5, :) ** 2_jpim ! sec_wr^4                               ! 9

      DO lay = 1, nlayers
        predictors(i)%watervapour(11, lay) = sec_wr(lay) * aux%dt(lay, i) * ABS(aux%dt(lay, i))                    ! 10
        predictors(i)%watervapour(13, lay) = (raytracing%pathsat(lay, i) * aux%ww(lay, i)) ** 2_jpim               ! 2
        predictors(i)%watervapour(14, lay) = sec_wr(lay) * aux%wr(lay, i) * aux%tr_r(lay, i)                       ! 14
      ENDDO
      predictors(i)%watervapour(12, :) = predictors(i)%watervapour(13, :) ** 2_jpim                          ! 3
      predictors(i)%watervapour(15, :) = predictors(i)%watervapour(14, :) * aux%tr_r(:, i) ** 3_jpim
    ENDDO

  ELSEIF(coef%fmv_model_ver == 8) THEN
    DO i = 1, nprofiles
      sec_wr_sqrt(:) = raytracing%pathsat_sqrt(:, i) * aux%wr_sqrt(:, i)
      sec_wr(:) = sec_wr_sqrt(:)**2_jpim
      wr_wwr_r(:) = aux%wr(:, i) * aux%wwr_r(:, i)

      DO lay = 1, nlayers
        predictors(i)%watervapour(1, lay)  = sec_wr(lay) * sec_wr(lay)
        predictors(i)%watervapour(2, lay)  = raytracing%pathsat(lay, i) * aux%ww(lay, i)
        predictors(i)%watervapour(3, lay)  = (raytracing%pathsat(lay, i) * aux%ww(lay, i)) ** 2_jpim
        predictors(i)%watervapour(4, lay)  = sec_wr(lay) * aux%dt(lay, i)
        predictors(i)%watervapour(5, lay)  = sec_wr_sqrt(lay)
        predictors(i)%watervapour(6, lay)  = SQRT(sec_wr_sqrt(lay))
        predictors(i)%watervapour(7, lay)  = sec_wr(lay)
        predictors(i)%watervapour(8, lay)  = sec_wr(lay) ** 3_jpim
        predictors(i)%watervapour(9, lay)  = sec_wr(lay) * aux%dt(lay, i) * ABS(aux%dt(lay, i))
        predictors(i)%watervapour(10, lay) = sec_wr_sqrt(lay) * aux%dt(lay, i)
        predictors(i)%watervapour(11, lay) = sec_wr(lay) * wr_wwr_r(lay)
        predictors(i)%watervapour(12, lay) = sec_wr_sqrt(lay) * wr_wwr_r(lay)
      ENDDO

      IF (coef%nwvcont > 0) THEN
        sec_wrtr_r(:) = sec_wr(:) * aux%tr_r(:, i)
        sec_wrwrtr_r(:) = sec_wrtr_r(:) * aux%wr(:,i) 

        DO lay = 1, nlayers
          predictors(i)%wvcont(1, lay) = sec_wrwrtr_r(lay)
          predictors(i)%wvcont(2, lay) = sec_wrwrtr_r(lay) * aux%tr_r(lay, i) ** 3_jpim
          predictors(i)%wvcont(3, lay) = sec_wrtr_r(lay)
          predictors(i)%wvcont(4, lay) = sec_wrtr_r(lay) * aux%tr_r(lay, i)
        ENDDO
      ENDIF
    ENDDO
  ENDIF

! ozone
!---------
! if no input O3 profile, variables or, ow have been set
! to the reference profile values (1, 1)

  IF (coef%nozone > 0) THEN
    IF(opts%rt_ir%ozone_Data) THEN
      DO i = 1, nprofiles
        sec_or_sqrt(:)             = raytracing%pathsat_sqrt(:, i) * aux%or_sqrt(:, i)
        sec_or(:)                  = sec_or_sqrt(:)**2_jpim

        DO lay = 1, nlayers
          predictors(i)%ozone(1, lay)  = sec_or(lay)
          predictors(i)%ozone(2, lay)  = sec_or_sqrt(lay)
          predictors(i)%ozone(3, lay)  = sec_or(lay) * aux%dto(lay, i)
          predictors(i)%ozone(4, lay)  = sec_or(lay) ** 2_jpim
          predictors(i)%ozone(5, lay)  = sec_or_sqrt(lay) * aux%dto(lay, i)
          predictors(i)%ozone(6, lay)  = sec_or(lay) * aux%or(lay, i) * aux%ow(lay, i)
          predictors(i)%ozone(7, lay)  = sec_or_sqrt(lay) * aux%or(lay, i) * aux%ow_r(lay, i)
          predictors(i)%ozone(8, lay)  = sec_or(lay) * aux%ow(lay, i)
          predictors(i)%ozone(9, lay)  = sec_or(lay) * raytracing%pathsat_sqrt(lay, i) * aux%ow_sqrt(lay, i)
          predictors(i)%ozone(10, lay) = raytracing%pathsat(lay, i) * aux%ow(lay, i)
          predictors(i)%ozone(11, lay) = (raytracing%pathsat(lay, i) * aux%ow(lay, i)) ** 2_jpim
        ENDDO
      ENDDO
    ELSE
      DO i = 1, nprofiles   
        DO lay = 1, nlayers
          predictors(i)%ozone(1, lay)  = raytracing%pathsat(lay, i)
          predictors(i)%ozone(2, lay)  = raytracing%pathsat_sqrt(lay, i)
          predictors(i)%ozone(3, lay)  = raytracing%pathsat(lay, i) * aux%dto(lay, i)
          predictors(i)%ozone(4, lay)  = raytracing%pathsat(lay, i)**2_jpim
          predictors(i)%ozone(5, lay)  = raytracing%pathsat_sqrt(lay, i) * aux%dto(lay, i)
          predictors(i)%ozone(6, lay)  = raytracing%pathsat(lay, i)
          predictors(i)%ozone(7, lay)  = raytracing%pathsat_sqrt(lay, i)
          predictors(i)%ozone(8, lay)  = raytracing%pathsat(lay, i)
          predictors(i)%ozone(9, lay)  = raytracing%pathsat(lay, i) * raytracing%pathsat_sqrt(lay, i)
          predictors(i)%ozone(10, lay) = raytracing%pathsat(lay, i)
          predictors(i)%ozone(11, lay) = raytracing%pathsat(lay, i)**2_jpim
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
            predictors(i)%co2(1, lay)  = raytracing%pathsat(lay, i) * aux%co2r(lay, i)
            predictors(i)%co2(2, lay)  = aux%tr(lay, i) ** 2_jpim !6
            predictors(i)%co2(3, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i) !3
            predictors(i)%co2(4, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i) ** 2_jpim !4
            predictors(i)%co2(5, lay)  = aux%tr(lay, i) !5
            predictors(i)%co2(6, lay)  = raytracing%pathsat(lay, i) ! 1
            predictors(i)%co2(7, lay)  = raytracing%pathsat(lay, i) * aux%twr(lay, i)
            predictors(i)%co2(8, lay)  = (raytracing%pathsat(lay, i) * aux%co2w(lay, i)) ** 2_jpim
            predictors(i)%co2(9, lay)  = aux%twr(lay, i) ** 3_jpim
            predictors(i)%co2(10, lay) = raytracing%pathsat(lay, i) * aux%twr(lay, i) * aux%tr_sqrt(lay, i)
          ENDDO
        ENDDO
      ELSE !no co2r co2w
        DO i = 1, nprofiles
          DO lay = 1, nlayers
            predictors(i)%co2(1, lay)  = raytracing%pathsat(lay, i)
            predictors(i)%co2(2, lay)  = aux%tr(lay, i) ** 2_jpim !6
            predictors(i)%co2(3, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i) !3
            predictors(i)%co2(4, lay)  = raytracing%pathsat(lay, i) * aux%tr(lay, i) ** 2_jpim !4
            predictors(i)%co2(5, lay)  = aux%tr(lay, i) !5
            predictors(i)%co2(6, lay)  = raytracing%pathsat(lay, i) ! 1
            predictors(i)%co2(7, lay)  = raytracing%pathsat(lay, i) * aux%twr(lay, i)
            predictors(i)%co2(8, lay)  = raytracing%pathsat(lay, i) ** 2_jpim
            predictors(i)%co2(9, lay)  = aux%twr(lay, i) ** 3_jpim
            predictors(i)%co2(10, lay) = raytracing%pathsat(lay, i) * aux%twr(lay, i) * aux%tr_sqrt(lay, i)
          ENDDO
        ENDDO
      ENDIF
    ENDIF
  ENDIF

!5.7  pressure-modulated cell (pmc) changes
!-------------------------------------------
  IF (coef%pmc_shift) THEN

! FROM COEF FILE
! cell length, temperature and air- to self -broadening conversion
    Lcel_cm = coef%pmc_lengthcell
!       Tcel=coef%pmc_tempcell
    betaplus1 = coef%pmc_betaplus1

! nominal cell pressure (coef file) and actual cell pressure (user input)
    DO ichan = 1, coef%fmv_chn
      Pnom(ichan) = coef%pmc_pnominal(ichan)
      Pcel(ichan) = coef%pmc_ppmc(ichan)
    ENDDO

! Number of layers (may be less than prof(1)%nlayers) and predictors used 
    nlayers = coef%pmc_nlay  

    DO iprof = 1, nprofiles
      acm = raytracing%co2_cm(iprof)/(2._jprb*betaplus1*Lcel_cm)

      DO ichan=1, coef%fmv_chn
        DO lay = 1, nlayers
          lev = lay + 1
! PMC Predictor-1
          Pcel_Lev=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pcel(ichan)**2_jpim
          Pnom_LevM1=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pnom(ichan)**2_jpim
          Pcel_LevM1=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev-1)**2_jpim + Pcel(ichan)**2_jpim
          Pnom_Lev=acm*raytracing%pathsat(lay,iprof)*prof(iprof)%p(lev  )**2_jpim + Pnom(ichan)**2_jpim

          predictors(iprof)%pmc(1,lay,ichan)=log( (Pcel_Lev*Pnom_LevM1)/(Pcel_LevM1*Pnom_Lev) )

! PMC Predictor-2 - use lay depth as lower bound for denominator
          Pupper=prof(iprof)%p(lev-1)
          IF (lay < prof(1)%nlayers) THEN
            Plower=prof(iprof)%p(lev+1)
          ELSE
            Plower=prof(iprof)%p(lev)
          ENDIF
          IF ( (Pcel(ichan) <= Pupper) .or. (Pcel(ichan) >= Plower) ) THEN
! Denominator goes from bottom of present layer to Pcel
                 predictors(iprof)%pmc(2,lay,ichan) &
                  =(Pcel(ichan)-Pnom(ichan))/(Pcel(ichan)-prof(iprof)%p(lev))
          ELSE
! Denominator is the depth of the present layer
                 predictors(iprof)%pmc(2,lay,ichan) &
                  =(Pcel(ichan)-Pnom(ichan))/(prof(iprof)%p(lev-1)-prof(iprof)%p(lev))
          ENDIF

        ENDDO
      ENDDO
    ENDDO
  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETPREDICTORS_78', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setpredictors_78
