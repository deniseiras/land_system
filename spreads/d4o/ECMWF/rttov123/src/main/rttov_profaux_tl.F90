! Description:
!> @file
!!   TL of calculation of variables related to the input profiles.
!
!> @brief
!!   TL of calculation of variables related to the input profiles.
!!
!> @details
!!   TL of calculation of variables related to the input profiles.
!!
!! @param[in]     opts                 options to configure the simulations
!! @param[in]     prof                 input profiles
!! @param[in]     prof_tl              input profile perturbations
!! @param[in]     prof_int             profiles in internal units
!! @param[in]     prof_int_tl          profile perturbations in internal units
!! @param[in]     coef                 optical depth coefficient structure
!! @param[in]     aux                  auxiliary profile data structure
!! @param[in,out] aux_tl               auxiliary profile data perturbations
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
SUBROUTINE rttov_profaux_tl( &
              opts,        &
              prof,        &
              prof_tl,     &
              prof_int,    &
              prof_int_tl, &
              coef,        &
              aux,         &
              aux_tl)

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
  USE parkind1, ONLY : jpim, jprb
  USE rttov_math_mod, ONLY: reciprocal, invsqrt_tl, reciprocal_tl, sqrt_tl
  USE rttov_scattering_mod, ONLY: calc_rel_hum_tl
!INTF_ON

  IMPLICIT NONE

  TYPE(rttov_options),     INTENT(IN)    :: opts
  TYPE(rttov_profile),     INTENT(IN)    :: prof(:)
  TYPE(rttov_profile),     INTENT(IN)    :: prof_tl(:)
  TYPE(rttov_profile),     INTENT(IN)    :: prof_int(SIZE(prof))
  TYPE(rttov_profile),     INTENT(IN)    :: prof_int_tl(SIZE(prof))
  TYPE(rttov_coef),        INTENT(IN)    :: coef
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux
  TYPE(rttov_profile_aux), INTENT(INOUT) :: aux_tl
!INTF_END

  INTEGER(jpim) :: nprofiles, nlayers, nlevels
  INTEGER(jpim) :: iprof, lev, lay
  REAL(jprb) :: dp, dp_tl
  REAL(jprb) :: amcfarq, bmcfarq, cmcfarq, zmcfarq, zmcfarq_tl
  REAL(jprb) :: ztempc, ztempc_tl
  REAL(jprb) :: zradipou_upp, zradipou_low
  REAL(jprb) :: bwyser, bwyser_tl, nft
  REAL(jprb), PARAMETER :: rtt      = 273.15_jprb
  REAL(jprb), PARAMETER :: rtou_upp =  - 20._jprb
  REAL(jprb), PARAMETER :: rtou_low =  - 60._jprb
  REAL(jprb) :: ZHOOK_HANDLE

  REAL(jprb) :: tstar_r(prof(1)%nlayers), ostar_r(prof(1)%nlayers)
  REAL(jprb) :: wstar_r(prof(1)%nlayers), co2star_r(prof(1)%nlayers)
  REAL(jprb) :: sum1
  INTEGER(jpim) :: iv2lay, iv2lev, iv3lev

!- End of header --------------------------------------------------------
!-----------------------------------------
! TL for cloud top and surface levels
!-----------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_TL', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers
  nlevels = prof(1)%nlevels

  DO iprof = 1, nprofiles
!nearest level above surface
    dp = prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%p(aux%s(iprof)%nearestlev_surf - 1)
    IF (opts%interpolation%lgradp) THEN
      dp_tl = prof_tl(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof_tl(iprof)%p(aux%s(iprof)%nearestlev_surf - 1)
      aux_tl%s(iprof)%pfraction_surf = &
          (prof_tl(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof_tl(iprof)%s2m%p) / dp -  &
          (prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%s2m%p) * dp_tl / (dp ** 2)
    ELSE
      aux_tl%s(iprof)%pfraction_surf =  - prof_tl(iprof)%s2m%p / dp
    ENDIF
    IF (coef%id_sensor /= sensor_id_mw .AND. coef%id_sensor /= sensor_id_po) THEN
!nearest level above cloud top
      dp = prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1)
      IF (opts%interpolation%lgradp) THEN
        dp_tl = prof_tl(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof_tl(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1)
        aux_tl%s(iprof)%pfraction_ctp = &
            (prof_tl(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof_tl(iprof)%ctp) / dp -  &
            (prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%ctp) * dp_tl / (dp ** 2)
      ELSE
        aux_tl%s(iprof)%pfraction_ctp =  - prof_tl(iprof)%ctp / dp
      ENDIF
      aux_tl%s(iprof)%cfraction = prof_tl(iprof)%cfraction
    ELSE
! for micro waves do not consider clouds in the RTTOV basis routines
      aux_tl%s(iprof)%pfraction_ctp = 0._jprb
      aux_tl%s(iprof)%cfraction     = 0._jprb
    ENDIF



    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN

!-----------------------------------------------------------------------------------------
! Deff CLW scheme
!-----------------------------------------------------------------------------------------
      IF (prof(iprof)%clw_scheme == clw_scheme_deff) THEN
        DO lay = 1, nlayers
          aux_tl%clw_dg(lay,iprof) = 0._jprb
          IF (ANY(prof_int(iprof)%cloud(1:nwcl_max,lay) > 0._jprb)) THEN
            IF (prof(iprof)%clwde(lay) > 0._jprb) THEN
              aux_tl%clw_dg(lay,iprof) = prof_tl(iprof)%clwde(lay)
            ENDIF
          ENDIF
        ENDDO
      ENDIF

!--------------------------------------------------------------
! TL for ice water content into effective generalized diameter
!--------------------------------------------------------------
      IF (prof(iprof)%ice_scheme == ice_scheme_ssec) THEN
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
        DO lay = 1, nlayers
          lev = lay + 1
          aux_tl%ice_dg(lay,iprof) = 0._jprb
          IF (prof_int(iprof)%cloud(6, lay) > 0._jprb) THEN
            ! Use effective diameter from input profile if specified
            IF (prof(iprof)%icede(lay) > 0._jprb) THEN
              aux_tl%ice_dg(lay, iprof) = prof_tl(iprof)%icede(lay)
            ELSE
              IF (prof(iprof)%idg == 1) THEN
                !Scheme by Ou and Liou, 1995, Atmos. Res., 35, 127-138.
                ztempc = prof(iprof)%t(lev) - rtt
                ztempc_tl                  = prof_tl(iprof)%t(lev)
                aux_tl%fac1_ice_dg(lay, iprof) = &
                    ztempc_tl * (12.42_jprb + 2._jprb * 0.197_jprb * ztempc + 3._jprb * 0.0012_jprb * ztempc * ztempc)
                aux_tl%fac2_ice_dg(lay, iprof) = 0.388_jprb * aux_tl%fac1_ice_dg(lay, iprof) +      &
                    0.00051_jprb * 2 * aux%fac1_ice_dg(lay, iprof) * aux_tl%fac1_ice_dg(lay, iprof)
                aux_tl%fac3_ice_dg(lay, iprof) = 2.0_jprb * aux_tl%fac2_ice_dg(lay, iprof)
                !
                ! Take Ou-Liou scheme as being valid only between 20C and 60C
                !
                IF (aux%fac3_ice_dg(lay, iprof) < zradipou_low .OR. aux%fac3_ice_dg(lay, iprof) > zradipou_upp) THEN
                  aux_tl%ice_dg(lay, iprof) = 0._jprb
                ELSE
                  aux_tl%ice_dg(lay, iprof) = aux_tl%fac3_ice_dg(lay, iprof)
                ENDIF
              ELSE IF (prof(iprof)%idg == 2) THEN
                !Scheme by Wyser et al. (see McFarquhar et al. (2003))
                bwyser    =  - 2.0_jprb
                bwyser_tl = 0._jprb
                IF (prof(iprof)%t(lev) < 273._jprb) THEN
                  bwyser    = bwyser + (0.001_jprb * &
                    ((273._jprb - prof(iprof)%t(lev)) ** 1.5_jprb) * LOG10(prof_int(iprof)%cloud(6, lay) / 50._jprb))
                  bwyser_tl = &
                      -0.001_jprb * 1.5_jprb * ((273._jprb - prof(iprof)%t(lev)) ** 0.5_jprb) * prof_tl(iprof)%t(lev) * &
                      LOG10(prof_int(iprof)%cloud(6, lay) / 50._jprb) + &
                      0.001_jprb * ((273._jprb - prof(iprof)%t(lev)) ** 1.5_jprb) * prof_int_tl(iprof)%cloud(6, lay) / &
                      prof_int(iprof)%cloud(6, lay) / LOG(10._jprb)
                ENDIF
                aux_tl%fac1_ice_dg(lay, iprof) = &
                    (203.3_jprb + 2 * bwyser * 37.91_jprb + 3 * bwyser * bwyser * 2.3696_jprb) * bwyser_tl
                nft = (SQRT(3._jprb) + 4._jprb) / (3._jprb * SQRT(3._jprb))
                aux_tl%fac2_ice_dg(lay, iprof) = aux_tl%fac1_ice_dg(lay, iprof) / nft
                aux_tl%ice_dg(lay, iprof)      = 2._jprb * 4._jprb * aux_tl%fac2_ice_dg(lay, iprof) * SQRT(3._jprb) / 9._jprb
              ELSE IF (prof(iprof)%idg == 3) THEN
                !Scheme by Boudala et al., 2002, Int. J. Climatol., 22, 1267-1284.
                ztempc                = prof(iprof)%t(lev) - rtt
                ztempc_tl             = prof_tl(iprof)%t(lev)
                aux_tl%ice_dg(lay, iprof) = 53.005_jprb * 0.06_jprb * &
                  (prof_int(iprof)%cloud(6, lay) ** (0.06_jprb - 1)) * prof_int_tl(iprof)%cloud(6, lay) * &
                  EXP(0.013_jprb * ztempc) + 53.005_jprb * &
                  ((prof_int(iprof)%cloud(6, lay)) ** 0.06_jprb) * 0.013_jprb * ztempc_tl * EXP(0.013_jprb * ztempc)
              ELSE IF (prof(iprof)%idg == 4) THEN
                ! Scheme by McFarquhar et al. (2003)
                amcfarq                    = 1.78449_jprb
                bmcfarq                    = 0.281301_jprb
                cmcfarq                    = 0.0177166_jprb
                zmcfarq                    = prof_int(iprof)%cloud(6, lay)
                zmcfarq_tl                 = prof_int_tl(iprof)%cloud(6, lay)
                aux_tl%fac1_ice_dg(lay, iprof) = &
                    10.0_jprb ** (amcfarq + bmcfarq * LOG10(zmcfarq) + cmcfarq * LOG10(zmcfarq) * LOG10(zmcfarq)) * &
                    (bmcfarq + 2._jprb * cmcfarq * LOG10(zmcfarq)) / zmcfarq * zmcfarq_tl
                aux_tl%ice_dg(lay, iprof)      = 2.0_jprb * aux_tl%fac1_ice_dg(lay, iprof)
              ENDIF
            ENDIF

            IF (ABS(aux%ice_dg(lay, iprof)) > 0._jprb) THEN
              IF (aux%ice_dg(lay, iprof) < dgmin_ssec) aux_tl%ice_dg(lay, iprof) = 0._jprb
              IF (aux%ice_dg(lay, iprof) > dgmax_ssec) aux_tl%ice_dg(lay, iprof) = 0._jprb
            ENDIF
          ENDIF
        ENDDO
      ENDIF
    ENDIF
  ENDDO

!-----------------------------------------------------------------------------------------
! TL of relative humidity calculation
!-----------------------------------------------------------------------------------------
  IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
    CALL calc_rel_hum_tl(opts, prof, prof_tl, prof_int_tl, aux, aux_tl)
  ENDIF

!-----------------------------------------------------------------------------------------
! TL of predictor data
!-----------------------------------------------------------------------------------------
  IF (aux%on_coef_levels) THEN
    ! 1 profile layer quantities
!   the layer number agrees with the level number of its upper boundary
! layer N-1 lies between levels N-1 and N
    CALL reciprocal(coef%tstar, tstar_r)
    CALL reciprocal(coef%wstar, wstar_r)
    IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) CALL reciprocal(coef%ostar, ostar_r)
    IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) CALL reciprocal(coef%co2star, co2star_r)

    DO iprof = 1, nprofiles
      aux_tl%t_layer(1:nlayers, iprof) = &
        (prof_tl(iprof)%t(1:nlevels-1) + prof_tl(iprof)%t(2:nlevels)) * 0.5_jprb
      aux_tl%w_layer(1:nlayers, iprof) = &
        (prof_tl(iprof)%q(1:nlevels-1) + prof_tl(iprof)%q(2:nlevels)) * 0.5_jprb

      IF (opts%rt_all%use_q2m) THEN
        iv3lev = aux%s(iprof)%nearestlev_surf - 1! nearest level above surface
        iv2lev = aux%s(iprof)%nearestlev_surf    ! nearest level above surface

        IF (iv2lev <= coef%nlevels) THEN
          iv2lay       = iv2lev - 1
          aux_tl%w_layer(iv2lay, iprof) = &
            (prof_tl(iprof)%s2m%q + prof_tl(iprof)%q(iv3lev)) * 0.5_jprb
        ENDIF
      ENDIF

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
!        aux_tl%o3_layer(layer, iprof) = (prof(iprof)%o3(level - 1) + prof(iprof)%o3(level)) * 0.5_jprb
        aux_tl%o3_layer(1:nlayers, iprof) = &
          (prof_tl(iprof)%o3(1:nlevels-1) + prof_tl(iprof)%o3(2:nlevels)) * 0.5_jprb
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        aux_tl%co2_layer(1:nlayers, iprof) = &
          (prof_tl(iprof)%co2(1:nlevels-1) + prof_tl(iprof)%co2(2:nlevels)) * 0.5_jprb
      ENDIF

! 2. calculate, for layers, deviations from reference profile
      aux_tl%dt(:, iprof) = aux_tl%t_layer(:, iprof)

      ! if no input O3 profile we still use the input temperature profile for dto
      IF (coef%nozone > 0) &
        aux_tl%dto(:, iprof) = aux_tl%t_layer(:, iprof)

! 3. calculate (profile / reference profile) ratios; tr wr or
      aux_tl%tr(:, iprof) = aux_tl%t_layer(:, iprof) * tstar_r(:)
      aux_tl%wr(:, iprof) = aux_tl%w_layer(:, iprof) * wstar_r(:)
      
! if no input O3 profile, set to reference value (or = 1)

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        aux_tl%or(:, iprof) = aux_tl%o3_layer(:, iprof) * ostar_r(:)
      ELSE
        aux_tl%or(:, iprof) = 0._jprb
      ENDIF

      IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) THEN
        aux_tl%co2r(:, iprof) = aux_tl%co2_layer(:, iprof) * co2star_r(:)
!      ELSE
!        aux%co2r(:, iprof) = 1._jprb
      ENDIF
    ENDDO

! 4. calculate profile / reference profile sums: tw ww ow

    DO iprof = 1, nprofiles
      aux_tl%tw(1, iprof) = 0._jprb
      DO lay = 2, nlayers
        ! cumulate overlying layers: weighting tr relates to same layer as dpp
        ! do not need dpp(0) to start
        aux_tl%tw(lay, iprof) = aux_tl%tw(lay - 1, iprof) + &
          coef%dpp(lay - 1) * aux_tl%tr(lay - 1, iprof)
      ENDDO
    ENDDO

    DO iprof = 1, nprofiles
      sum1 = 0._jprb
      ! cumulating column overlying layer and layer itself
      DO lay = 1, nlayers
        ! cumulate overlying layers: weighting w or wstar relates to layer below dpp
        ! need dpp(0) to start
        sum1 = sum1 + coef%dpp(lay - 1) * aux_tl%w_layer(lay, iprof)
        aux_tl%ww(lay, iprof) = sum1 * aux%sum(lay,1)
      ENDDO
    ENDDO
    
    IF(coef%fmv_model_ver == 8) THEN
      DO iprof = 1, nprofiles
        sum1 = 0._jprb
        DO lay = 1, nlayers
          sum1 = sum1 + coef%dpp(lay - 1) * (aux_tl%w_layer(lay, iprof) * aux%t_layer(lay, iprof) + &
                                             aux%w_layer(lay, iprof) * aux_tl%t_layer(lay, iprof))
          aux_tl%wwr(lay, iprof) = sum1 * aux%sum(lay,5)
        ENDDO
      ENDDO
      CALL reciprocal_tl(aux%wwr_r, aux_tl%wwr, aux_tl%wwr_r)
    ENDIF

    ! if no input O3 profile, set to reference value (ow =1)
    IF (coef%nozone > 0) THEN
      IF (opts%rt_ir%ozone_Data) THEN
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = 1, nlayers
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + coef%dpp(lay - 1) * aux_tl%o3_layer(lay, iprof) ! OK, dpp(0) defined 
            aux_tl%ow(lay, iprof) = sum1 * aux%sum(lay,2)
          ENDDO
        ENDDO
      ELSE
        aux_tl%ow(:, :) = 0._jprb
      ENDIF
    ENDIF

! if no input co2 profile, set to reference value (co2w_tl=0) 
! but twr calculation still uses the input temperature profile

    IF (coef%nco2 > 0) THEN
      IF (opts%rt_ir%co2_Data) THEN
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = 1, nlayers
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + coef%dpp(lay - 1) * aux_tl%co2_layer(lay, iprof) ! OK, dpp(0) defined 
            aux_tl%co2w(lay, iprof) = sum1 * aux%sum(lay,3)
          ENDDO
        ENDDO
      ELSE
        aux_tl%co2w(:, :) = 0._jprb
      ENDIF
      
      ! twr only used in CO2 predictors
      DO iprof = 1, nprofiles
        sum1   = 0._jprb
        aux_tl%twr(1, iprof) = 0._jprb
        
        DO lay = 2, nlayers
! cumulate overlying layers (t, tstar relate to same layer as dpp)
! do not need dpp(0) to start
          sum1       = sum1 + coef%dpp(lay - 1) * aux_tl%t_layer(lay - 1, iprof)
          aux_tl%twr(lay, iprof) = sum1 * aux%sum(lay,4)
        ENDDO
      ENDDO
    ENDIF

    CALL reciprocal_tl(aux%tr_r, aux_tl%tr, aux_tl%tr_r)
 
    IF (coef%fmv_model_ver == 8) THEN
      CALL sqrt_tl(aux%tr_sqrt, aux_tl%tr, aux_tl%tr_sqrt)  
    ENDIF
  
    CALL sqrt_tl(aux%tw_sqrt, aux_tl%tw, aux_tl%tw_sqrt)  
    CALL sqrt_tl(aux%tw_4rt, aux_tl%tw_sqrt, aux_tl%tw_4rt)  

    CALL INVSQRT_TL(aux%wr_rsqrt, aux_tl%wr, aux_tl%wr_rsqrt)
    aux_tl%wr_sqrt = aux_tl%wr * aux%wr_rsqrt + &
                     aux%wr * aux_tl%wr_rsqrt

    IF (coef%fmv_model_ver == 7) THEN
      CALL reciprocal_tl(aux%ww_r, aux_tl%ww, aux_tl%ww_r)
    ENDIF

    IF (coef%nozone > 0 .and. opts%rt_ir%ozone_Data) THEN
      CALL INVSQRT_TL(aux%ow_rsqrt, aux_tl%ow, aux_tl%ow_rsqrt)
      aux_tl%ow_sqrt = aux_tl%ow * aux%ow_rsqrt + &
                       aux%ow * aux_tl%ow_rsqrt
      aux_tl%ow_r = 2._jprb * aux%ow_rsqrt * aux_tl%ow_rsqrt

      CALL sqrt_tl(aux%or_sqrt, aux_tl%or, aux_tl%or_sqrt)  
    ENDIF   
  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_TL', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_profaux_tl
