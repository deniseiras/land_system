! Description:
!> @file
!!   AD of calculation of variables related to the input profiles.
!
!> @brief
!!   AD of calculation of variables related to the input profiles.
!!
!> @details
!!   AD of calculation of variables related to the input profiles.
!!
!! @param[in]     opts                 options to configure the simulations
!! @param[in]     prof                 input profiles
!! @param[in,out] prof_ad              input profile increments
!! @param[in]     prof_int             profiles in internal units
!! @param[in]     prof_int_ad          profile increments in internal units
!! @param[in]     coef                 optical depth coefficient structure
!! @param[in]     aux                  auxiliary profile data structure
!! @param[in,out] aux_ad               auxiliary profile data increments
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
!    Copyright 2016, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_profaux_ad( &
              opts,        &
              prof,        &
              prof_ad,     &
              prof_int,    &
              prof_int_ad, &
              coef,        &
              aux,         &
              aux_ad)

  USE rttov_types, ONLY :  &
        rttov_options,     &
        rttov_coef,        &
        rttov_profile,     &
        rttov_profile_aux
!INTF_OFF
  USE rttov_const, ONLY : sensor_id_mw, sensor_id_po, &
                          dgmin_ssec, dgmax_ssec, nwcl_max, &
                          clw_scheme_deff, ice_scheme_ssec
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb, jplm
  USE rttov_math_mod, ONLY: reciprocal, invsqrt_ad, reciprocal_ad, sqrt_ad
  USE rttov_scattering_mod, ONLY: calc_rel_hum_ad
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options),     INTENT(IN)    :: opts
  TYPE(rttov_profile),     INTENT(IN)    :: prof(:)
  TYPE(rttov_profile),     INTENT(INOUT) :: prof_ad(:)
  TYPE(rttov_profile),     INTENT(IN)    :: prof_int(SIZE(prof))
  TYPE(rttov_profile),     INTENT(INOUT) :: prof_int_ad(SIZE(prof))
  TYPE(rttov_coef),        INTENT(IN)    :: coef
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux
  TYPE(rttov_profile_aux), INTENT(INOUT) :: aux_ad
!INTF_END

  INTEGER(jpim) :: nprofiles, nlayers, nlevels
  INTEGER(jpim) :: iprof, lev, lay
  REAL(jprb) :: dp, dp_ad
  REAL(jprb) :: amcfarq, bmcfarq, cmcfarq, zmcfarq, zmcfarq_ad
  REAL(jprb) :: ztempc, ztempc_ad
  REAL(jprb) :: zradipou_upp, zradipou_low
  REAL(jprb) :: bwyser, bwyser_ad, nft
  REAL(jprb), PARAMETER :: rtt      = 273.15_jprb
  REAL(jprb), PARAMETER :: rtou_upp =  - 20._jprb
  REAL(jprb), PARAMETER :: rtou_low =  - 60._jprb
  REAL(jprb) :: ZHOOK_HANDLE

  REAL(jprb) :: tstar_r(prof(1)%nlayers), ostar_r(prof(1)%nlayers)
  REAL(jprb) :: wstar_r(prof(1)%nlayers), co2star_r(prof(1)%nlayers)
  REAL(jprb) :: sum1
  INTEGER(jpim) :: iv2lay, iv2lev!, iv3lev

!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_AD', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers
  nlevels = prof(1)%nlevels

!-----------------------------------------------------------------------------------------
! AD of relative humidity calculation
!-----------------------------------------------------------------------------------------
  IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
    CALL calc_rel_hum_ad(opts, prof, prof_ad, prof_int_ad, aux, aux_ad)
  ENDIF


  DO iprof = 1, nprofiles

    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN

!-----------------------------------------------------------------------------------------
! Deff CLW scheme
!-----------------------------------------------------------------------------------------
      IF (prof(iprof)%clw_scheme == clw_scheme_deff) THEN
        DO lay = 1, nlayers
          IF (ANY(prof_int(iprof)%cloud(1:nwcl_max,lay) > 0._jprb)) THEN
            IF (prof(iprof)%clwde(lay) > 0._jprb) THEN
              prof_ad(iprof)%clwde(lay) = prof_ad(iprof)%clwde(lay) + aux_ad%clw_dg(lay,iprof)
            ENDIF
          ENDIF
          aux_ad%clw_dg(lay,iprof) = 0._jprb
        ENDDO
      ENDIF

!-----------------------------------------------------------------------------------------
! AD for ice water content into effective generalized diameter
!-----------------------------------------------------------------------------------------
      IF (prof(iprof)%ice_scheme == ice_scheme_ssec) THEN
        zmcfarq_ad = 0._jprb
        ztempc_ad  = 0._jprb
        bwyser_ad  = 0._jprb
        ! Calculate upper and lower limits for Ou-Liou effective size
        !
        zradipou_upp = 326.3_jprb + rtou_upp * (12.42_jprb + rtou_upp * (0.197_jprb + rtou_upp * 0.0012_jprb))
        zradipou_low = 326.3_jprb + rtou_low * (12.42_jprb + rtou_low * (0.197_jprb + rtou_low * 0.0012_jprb))
        !
        ! and convert these to the "generalized" effective size used here (using McFarquhar et al 2003 equation),
        ! not forgetting the factor of 2 to convert from McFarquhar's radius to a diameter
        !
        zradipou_upp =  - 1.56_jprb + zradipou_upp * (0.388_jprb + zradipou_upp * 0.00051_jprb)
        zradipou_upp = 2.0_jprb * zradipou_upp
        zradipou_low =  - 1.56_jprb + zradipou_low * (0.388_jprb + zradipou_low * 0.00051_jprb)
        zradipou_low = 2.0_jprb * zradipou_low
        DO lay = nlayers, 1,  - 1
          lev = lay + 1
          IF (prof_int(iprof)%cloud(6, lay) > 0._jprb) THEN
            IF (ABS(aux%ice_dg(lay, iprof)) > 0._jprb) THEN
              IF (aux%ice_dg(lay, iprof) < dgmin_ssec) aux_ad%ice_dg(lay, iprof) = 0._jprb
              IF (aux%ice_dg(lay, iprof) > dgmax_ssec) aux_ad%ice_dg(lay, iprof) = 0._jprb
            ENDIF
            ! Use effective diameter from input profile if specified
            IF (prof(iprof)%icede(lay) > 0._jprb) THEN
              prof_ad(iprof)%icede(lay) = prof_ad(iprof)%icede(lay) + aux_ad%ice_dg(lay, iprof)
            ELSE
              IF (prof(iprof)%idg == 1) THEN
                !Scheme by Ou and Liou, 1995, Atmos. Res., 35, 127-138.
                ztempc = prof(iprof)%t(lev) - rtt
                !
                ! Take Ou-Liou scheme as being valid only between 20C and 60C
                !
                IF (aux%fac3_ice_dg(lay, iprof) < zradipou_low .OR. aux%fac3_ice_dg(lay, iprof) > zradipou_upp) THEN
                  aux_ad%ice_dg(lay, iprof) = 0._jprb
                ELSE
                  aux_ad%fac3_ice_dg(lay, iprof) = aux_ad%fac3_ice_dg(lay, iprof) + aux_ad%ice_dg(lay, iprof)
                ENDIF
                aux_ad%fac2_ice_dg(lay, iprof) = aux_ad%fac2_ice_dg(lay, iprof) + 2.0_jprb * aux_ad%fac3_ice_dg(lay, iprof)
                aux_ad%fac1_ice_dg(lay, iprof) = aux_ad%fac1_ice_dg(lay, iprof) + 0.388_jprb * aux_ad%fac2_ice_dg(lay, iprof)
                aux_ad%fac1_ice_dg(lay, iprof) =      &
                    aux_ad%fac1_ice_dg(lay, iprof) + aux_ad%fac2_ice_dg(lay, iprof) * 0.00051_jprb * 2 * aux%fac1_ice_dg(lay, iprof)
                ztempc_ad                  = ztempc_ad + aux_ad%fac1_ice_dg(lay, iprof) * &
                    (12.42_jprb + 2._jprb * 0.197_jprb * ztempc + 3._jprb * 0.0012_jprb * ztempc * ztempc)
                prof_ad(iprof)%t(lev)      = prof_ad(iprof)%t(lev) + ztempc_ad
                ztempc_ad                  = 0._jprb
              ELSE IF (prof(iprof)%idg == 2) THEN
                !Scheme by Wyser et al. (see McFarquhar et al. (2003))
                bwyser =  - 2.0_jprb
                IF (prof(iprof)%t(lev) < 273._jprb) THEN
                  bwyser = bwyser + (0.001_jprb * &
                    ((273._jprb - prof(iprof)%t(lev)) ** 1.5_jprb) * LOG10(prof_int(iprof)%cloud(6, lay) / 50._jprb))
                ENDIF
                nft = (SQRT(3._jprb) + 4._jprb) / (3._jprb * SQRT(3._jprb))
                aux_ad%fac2_ice_dg(lay, iprof) =      &
                    aux_ad%fac2_ice_dg(lay, iprof) + aux_ad%ice_dg(lay, iprof) * 2._jprb * 4._jprb * SQRT(3._jprb) / 9._jprb
                aux_ad%fac1_ice_dg(lay, iprof) = aux_ad%fac1_ice_dg(lay, iprof) + aux_ad%fac2_ice_dg(lay, iprof) / nft
                bwyser_ad                  = bwyser_ad +      &
                    aux_ad%fac1_ice_dg(lay, iprof) * (203.3_jprb + 2 * bwyser * 37.91_jprb + 3 * bwyser * bwyser * 2.3696_jprb)
                IF (prof(iprof)%t(lev) < 273._jprb) THEN
                  prof_ad(iprof)%t(lev)        = prof_ad(iprof)%t(lev) - &
                      bwyser_ad * 0.001_jprb * 1.5_jprb * ((273._jprb - prof(iprof)%t(lev)) ** 0.5_jprb) * &
                      LOG10(prof_int(iprof)%cloud(6, lay) / 50._jprb)
                  prof_int_ad(iprof)%cloud(6, lay) = prof_int_ad(iprof)%cloud(6, lay) + &
                    bwyser_ad * 0.001_jprb * ((273._jprb - prof(iprof)%t(lev)) ** 1.5_jprb) / &
                    prof_int(iprof)%cloud(6, lay) / LOG(10._jprb)
                ENDIF
                bwyser_ad = 0._jprb
              ELSE IF (prof(iprof)%idg == 3) THEN
                !Scheme by Boudala et al., 2002, Int. J. Climatol., 22, 1267-1284.
                ztempc = prof(iprof)%t(lev) - rtt
                prof_int_ad(iprof)%cloud(6, lay) = prof_int_ad(iprof)%cloud(6, lay) + &
                    aux_ad%ice_dg(lay, iprof) * 53.005_jprb * (prof_int(iprof)%cloud(6, lay) ** (0.06_jprb - 1)) * &
                    EXP(0.013_jprb * ztempc) * 0.06_jprb
                ztempc_ad                    = ztempc_ad + &
                    aux_ad%ice_dg(lay, iprof) * 53.005_jprb * ((prof_int(iprof)%cloud(6, lay)) ** 0.06_jprb) * 0.013_jprb * &
                    EXP(0.013_jprb * ztempc)
                prof_ad(iprof)%t(lev)        = prof_ad(iprof)%t(lev) + ztempc_ad
                ztempc_ad                    = 0._jprb
              ELSE IF (prof(iprof)%idg == 4) THEN
                ! Scheme by McFarquhar et al. (2003)
                amcfarq                      = 1.78449_jprb
                bmcfarq                      = 0.281301_jprb
                cmcfarq                      = 0.0177166_jprb
                zmcfarq                      = prof_int(iprof)%cloud(6, lay)
                aux_ad%fac1_ice_dg(lay, iprof)   = aux_ad%fac1_ice_dg(lay, iprof) + aux_ad%ice_dg(lay, iprof) * 2.0_jprb
                zmcfarq_ad                   = zmcfarq_ad + aux_ad%fac1_ice_dg(lay, iprof) * &
                    10.0_jprb ** (amcfarq + bmcfarq * LOG10(zmcfarq) + cmcfarq * LOG10(zmcfarq) * LOG10(zmcfarq)) * &
                    (bmcfarq + 2._jprb * cmcfarq * LOG10(zmcfarq)) / zmcfarq
                prof_int_ad(iprof)%cloud(6, lay) = prof_int_ad(iprof)%cloud(6, lay) + zmcfarq_ad
                zmcfarq_ad                   = 0._jprb
              ENDIF
            ENDIF
          ENDIF
          aux_ad%ice_dg(lay, iprof) = 0._jprb
        ENDDO
      ENDIF
    ENDIF


!-----------------------------------------
! AD for cloud top and surface levels
!-----------------------------------------
    IF (coef%id_sensor /= sensor_id_mw .AND. coef%id_sensor /= sensor_id_po) THEN
!nearest level above cloud top
      dp = prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1)
      dp_ad = 0._jprb
      prof_ad(iprof)%cfraction = prof_ad(iprof)%cfraction + aux_ad%s(iprof)%cfraction
      prof_ad(iprof)%ctp       = prof_ad(iprof)%ctp - aux_ad%s(iprof)%pfraction_ctp / dp
      IF (opts%interpolation%lgradp) THEN
        prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp) + &
            aux_ad%s(iprof)%pfraction_ctp / dp
        dp_ad = dp_ad - (prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%ctp) / dp ** 2 * &
            aux_ad%s(iprof)%pfraction_ctp
        prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp) + dp_ad
        prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1) - dp_ad
      ENDIF
!Else
! for micro waves do not consider clouds in the RTTOV basis routines
    ENDIF
!nearest level above surface
    dp = prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%p(aux%s(iprof)%nearestlev_surf - 1)
    dp_ad = 0._jprb
    prof_ad(iprof)%s2m%p = prof_ad(iprof)%s2m%p - aux_ad%s(iprof)%pfraction_surf / dp
    IF (opts%interpolation%lgradp) THEN
      prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf) + &
          aux_ad%s(iprof)%pfraction_surf / dp
      dp_ad = dp_ad - (prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%s2m%p) / dp ** 2 * &
          aux_ad%s(iprof)%pfraction_surf
      prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf) + dp_ad
      prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf - 1) = prof_ad(iprof)%p(aux%s(iprof)%nearestlev_surf - 1) - dp_ad
    ENDIF
  ENDDO


!-----------------------------------------------------------------------------------------
! AD of predictor data
!-----------------------------------------------------------------------------------------
  IF (aux%on_coef_levels) THEN
!FWD

    CALL reciprocal(coef%tstar, tstar_r)
    CALL reciprocal(coef%wstar, wstar_r)
    IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) CALL reciprocal(coef%ostar, ostar_r)
    IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) CALL reciprocal(coef%co2star, co2star_r)

!AD
    IF (coef%fmv_model_ver == 7) THEN
      CALL reciprocal_ad(aux%ww_r, aux_ad%ww, aux_ad%ww_r, acc = .TRUE._jplm)
    ENDIF

    aux_ad%wr = aux_ad%wr + aux%wr_rsqrt * aux_ad%wr_sqrt

    aux_ad%wr_rsqrt = &!aux_ad%wr_rsqrt + 
      aux%wr * aux_ad%wr_sqrt

    CALL INVSQRT_AD(aux%wr_rsqrt, aux_ad%wr, aux_ad%wr_rsqrt, acc = .TRUE._jplm)

    CALL sqrt_ad(aux%tw_4rt, aux_ad%tw_sqrt, aux_ad%tw_4rt, acc = .FALSE._jplm)  
    CALL sqrt_ad(aux%tw_sqrt, aux_ad%tw, aux_ad%tw_sqrt, acc = .TRUE._jplm)  

    IF (coef%fmv_model_ver == 8) THEN
      IF (coef%nco2 > 0) THEN
        CALL sqrt_ad(aux%tr_sqrt, aux_ad%tr, aux_ad%tr_sqrt, acc = .TRUE._jplm)
      ENDIF
    ENDIF

    CALL reciprocal_ad(aux%tr_r, aux_ad%tr, aux_ad%tr_r, acc = .TRUE._jplm)
    
    IF (coef%nozone > 0 .and. opts%rt_ir%ozone_Data) THEN
      CALL sqrt_ad(aux%or_sqrt, aux_ad%or, aux_ad%or_sqrt, acc = .TRUE._jplm)  
      aux_ad%ow_rsqrt = &!aux_ad%ow_rsqrt + 
        aux%ow * aux_ad%ow_sqrt

      aux_ad%ow = aux_ad%ow + aux_ad%ow_sqrt * aux%ow_rsqrt
      aux_ad%ow_rsqrt = aux_ad%ow_rsqrt + 2._jprb * aux%ow_rsqrt * aux_ad%ow_r
      CALL INVSQRT_AD(aux%ow_rsqrt, aux_ad%ow, aux_ad%ow_rsqrt, acc = .TRUE._jplm)
    ENDIF

! 4. calculate profile / reference profile sums: tw ww ow

    DO iprof = 1, nprofiles
      DO lay = nlayers, 2, -1
        ! cumulate overlying layers: weighting tr relates to same layer as dpp
        ! do not need dpp(0) to start
        aux_ad%tw(lay - 1, iprof) = aux_ad%tw(lay - 1, iprof) + aux_ad%tw(lay, iprof)
        aux_ad%tr(lay - 1, iprof) = aux_ad%tr(lay - 1, iprof) + coef%dpp(lay - 1) * aux_ad%tw(lay, iprof) 
      ENDDO
    ENDDO

    DO iprof = 1, nprofiles
      sum1 = 0._jprb
      ! cumulating column overlying layer and layer itself
      DO lay = nlayers, 1, -1
        ! cumulate overlying layers: weighting w or wstar relates to layer below dpp
        ! need dpp(0) to start
        sum1 = sum1 + aux_ad%ww(lay, iprof) * aux%sum(lay,1)
        aux_ad%w_layer(lay, iprof) = &!aux_ad%w_layer(lay, iprof) + 
          sum1 * coef%dpp(lay - 1)
      ENDDO
    ENDDO
 
    IF(coef%fmv_model_ver == 8) THEN
      CALL reciprocal_ad(aux%wwr_r, aux_ad%wwr, aux_ad%wwr_r, acc=.FALSE._jplm)
      DO iprof = 1, nprofiles
        sum1 = 0._jprb
        DO lay = nlayers, 1, -1
          sum1 = sum1 + aux_ad%wwr(lay, iprof) * aux%sum(lay,5)

          aux_ad%w_layer(lay, iprof) = aux_ad%w_layer(lay, iprof) + &
            coef%dpp(lay - 1) * sum1 * aux%t_layer(lay, iprof)

          aux_ad%t_layer(lay, iprof) = aux_ad%t_layer(lay, iprof) + &
            coef%dpp(lay - 1) * sum1 * aux%w_layer(lay, iprof)
        ENDDO
      ENDDO
    ENDIF

    IF (coef%nozone > 0) THEN
      IF (opts%rt_ir%ozone_Data) THEN     ! if no input O3 profile, set to reference value (ow =1)
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = nlayers, 1, -1
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + aux_ad%ow(lay, iprof) * aux%sum(lay,2)
            aux_ad%o3_layer(lay, iprof) = &!aux_ad%o3_layer(lay, iprof) + 
              sum1 * coef%dpp(lay - 1) ! OK, dpp(0) defined 
          ENDDO
        ENDDO
      ELSE
        aux_ad%o3_layer(:, :) = 0._jprb
      ENDIF
    ENDIF

! if no input co2 profile, set to reference value (co2w_tl=0) 
! but twr calculation still uses the input temperature profile

    IF (coef%nco2 > 0) THEN
      IF (opts%rt_ir%co2_Data) THEN
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = nlayers, 1, -1
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + aux%sum(lay,3) * aux_ad%co2w(lay, iprof)

            aux_ad%co2_layer(lay, iprof) = &!aux_ad%co2_layer(lay, iprof) + &
              sum1 * coef%dpp(lay - 1) 
          ENDDO
        ENDDO
      ELSE
        aux_ad%co2_layer(:, :) = 0._jprb
      ENDIF
      
      ! twr only used in CO2 predictors
      DO iprof = 1, nprofiles
        sum1   = 0._jprb
        
        DO lay = nlayers, 2, -1
! cumulate overlying layers (t, tstar relate to same layer as dpp)
! do not need dpp(0) to start
          sum1 = sum1 + aux_ad%twr(lay, iprof) * aux%sum(lay,4)
          aux_ad%t_layer(lay - 1, iprof) = aux_ad%t_layer(lay - 1, iprof) + &
                                           coef%dpp(lay - 1) * sum1

        ENDDO
        aux_ad%twr(1, iprof) = 0._jprb
      ENDDO
    ENDIF

! 3. calculate (profile / reference profile) ratios; tr wr or
    DO iprof = 1, nprofiles
      aux_ad%t_layer(:, iprof) = aux_ad%t_layer(:, iprof) + aux_ad%tr(:, iprof) * tstar_r(:)

      aux_ad%w_layer(:, iprof) = aux_ad%w_layer(:, iprof) + aux_ad%wr(:, iprof) * wstar_r(:)

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        aux_ad%o3_layer(:, iprof) = aux_ad%o3_layer(:, iprof) + aux_ad%or(:, iprof) * ostar_r(:)
      ENDIF

      IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) THEN
        aux_ad%co2_layer(:, iprof) = aux_ad%co2_layer(:, iprof) + aux_ad%co2r(:, iprof) * co2star_r(:)
      ENDIF

! 2. calculate, for layers, deviations from reference profile
      aux_ad%t_layer(:, iprof) = aux_ad%t_layer(:, iprof) + aux_ad%dt(:, iprof) 

      ! if no input O3 profile we still use the input temperature profile for dto
      IF (coef%nozone > 0) &
        aux_ad%t_layer(:, iprof) = aux_ad%t_layer(:, iprof) + aux_ad%dto(:, iprof) 

! 1 profile layer quantities
!   the layer number agrees with the level number of its upper boundary
! layer N-1 lies between levels N-1 and N
    !DAR add from set_predictors_7
      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        prof_ad(iprof)%o3(1) = prof_ad(iprof)%o3(1) + &
          0.5_jprb * aux_ad%o3_layer(1, iprof)
        prof_ad(iprof)%o3(2:nlevels-1) = prof_ad(iprof)%o3(2:nlevels-1) + &
          0.5_jprb * (aux_ad%o3_layer(1:nlevels-2, iprof) + aux_ad%o3_layer(2:nlevels-1, iprof))
        prof_ad(iprof)%o3(nlevels) = prof_ad(iprof)%o3(nlevels) + &
          0.5_jprb * aux_ad%o3_layer(nlevels-1, iprof)
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        prof_ad(iprof)%co2(1) = prof_ad(iprof)%co2(1) + &
          0.5_jprb * aux_ad%co2_layer(1, iprof)
        prof_ad(iprof)%co2(2:nlevels-1) = prof_ad(iprof)%co2(2:nlevels-1) + &
          0.5_jprb * (aux_ad%co2_layer(1:nlevels-2, iprof) + aux_ad%co2_layer(2:nlevels-1, iprof))
        prof_ad(iprof)%co2(nlevels) = prof_ad(iprof)%co2(nlevels) + &
          0.5_jprb * aux_ad%co2_layer(nlevels-1, iprof)
      ENDIF


      IF (opts%rt_all%use_q2m) THEN
!         iv3lev = aux%s(iprof)%nearestlev_surf - 1! nearest level above surface
        iv2lev = aux%s(iprof)%nearestlev_surf    ! nearest level above surface

        IF (iv2lev <= coef%nlevels) THEN
          iv2lay       = iv2lev - 1
          prof_ad(iprof)%s2m%q =  prof_ad(iprof)%s2m%q + &
            aux_ad%w_layer(iv2lay, iprof) * 0.5_jprb

          ! This line subtracts the quantity that is added to prof_ad(iprof)%q(iv2lev) below
          ! so that it cancels out: in the case where use_q2m is true prof(iprof)%q(iv2lev) is
          ! replaced by prof(iprof)%s2m%q in the calculation of aux%w_layer(iv2lay, iprof)
          prof_ad(iprof)%q(iv2lev) = prof_ad(iprof)%q(iv2lev) - &
            aux_ad%w_layer(iv2lay, iprof) * 0.5_jprb
        ENDIF
      ENDIF

      prof_ad(iprof)%q(1) = prof_ad(iprof)%q(1) + &
        0.5_jprb * aux_ad%w_layer(1, iprof)
      prof_ad(iprof)%q(2:nlevels-1) = prof_ad(iprof)%q(2:nlevels-1) + &
        0.5_jprb * (aux_ad%w_layer(1:nlevels-2, iprof) + aux_ad%w_layer(2:nlevels-1, iprof))
      prof_ad(iprof)%q(nlevels) = prof_ad(iprof)%q(nlevels) + &
        0.5_jprb * aux_ad%w_layer(nlevels-1, iprof)

      prof_ad(iprof)%t(1) = prof_ad(iprof)%t(1) + &
        0.5_jprb * aux_ad%t_layer(1, iprof)
      prof_ad(iprof)%t(2:nlevels-1) = prof_ad(iprof)%t(2:nlevels-1) + &
        0.5_jprb * (aux_ad%t_layer(1:nlevels-2, iprof) + aux_ad%t_layer(2:nlevels-1, iprof))
      prof_ad(iprof)%t(nlevels) = prof_ad(iprof)%t(nlevels) + &
        0.5_jprb * aux_ad%t_layer(nlevels-1, iprof)

    ENDDO
ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_AD', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_profaux_ad
