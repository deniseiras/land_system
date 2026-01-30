! Description:
!> @file
!!   Calculate some variables related to the input profiles.
!
!> @brief
!!   Calculate some variables related to the input profiles.
!!
!> @details
!!   Calculates the following information:
!!   - first level below the surface (or the bottom level)
!!   - first level below input cloud top pressure (for simple cloud)
!!   - layer fractions for position of cloud and surface within layer
!!   - store clw cloud Deff for VIS/IR scattering
!!   - ice cloud Deff parameterisations for VIS/IR scattering
!!   - for coefficient levels it calculates quantities used in the
!!     predictor calculations
!!
!!   This subroutine is called on both user levels and coefficient levels
!!   when the interpolator is being used.
!!
!! @param[in]     opts                 options to configure the simulations
!! @param[in]     prof                 input profiles
!! @param[in]     prof_int             profiles in internal units
!! @param[in]     coef                 optical depth coefficient structure
!! @param[in,out] aux                  auxiliary profile data structure
!! @param[in]     on_coef_levels       flag to indicate calculations are on coefficient levels
!!                                     (if so predictor calculations are done), optional
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
SUBROUTINE rttov_profaux( &
              opts,     &
              prof,     &
              prof_int, &
              coef,     &
              aux,      &
              on_coef_levels)

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
  USE rttov_math_mod, ONLY: INVSQRT, reciprocal
  USE rttov_scattering_mod, ONLY: calc_rel_hum
!INTF_ON
  USE parkind1, ONLY : jplm
  IMPLICIT NONE
  TYPE(rttov_options),     INTENT(IN)           :: opts
  TYPE(rttov_profile),     INTENT(IN)           :: prof(:)
  TYPE(rttov_profile),     INTENT(IN)           :: prof_int(SIZE(prof))
  TYPE(rttov_coef),        INTENT(IN)           :: coef
  TYPE(rttov_profile_aux), INTENT(INOUT)        :: aux
  LOGICAL(jplm),           INTENT(IN), OPTIONAL :: on_coef_levels
!INTF_END

  INTEGER(jpim) :: nprofiles, nlayers, nlevels
  INTEGER(jpim) :: iprof, lev, lay
  REAL(jprb) :: dp
  REAL(jprb) :: amcfarq, bmcfarq, cmcfarq, zmcfarq
  REAL(jprb) :: ztempc
  REAL(jprb) :: zradipou_upp, zradipou_low
  REAL(jprb) :: bwyser, nft
  REAL(jprb), PARAMETER :: rtt      = 273.15_jprb
  REAL(jprb), PARAMETER :: rtou_upp =  - 20._jprb
  REAL(jprb), PARAMETER :: rtou_low =  - 60._jprb
  REAL(jprb) :: ZHOOK_HANDLE

  REAL(jprb) :: tstar_r(prof(1)%nlayers), ostar_r(prof(1)%nlayers)
  REAL(jprb) :: wstar_r(prof(1)%nlayers), co2star_r(prof(1)%nlayers)
  REAL(jprb) :: sum1
  INTEGER(jpim) :: iv2lay, iv2lev, iv3lev
  LOGICAL(jplm) :: on_coef_levels1

!- End of header --------------------------------------------------------
!-----------------------------------------
! determine cloud top and surface levels
!-----------------------------------------
! in line with coef % dp in rttov_initcoeffs
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX', 0_jpim, ZHOOK_HANDLE)
  on_coef_levels1 = .FALSE.
  IF(PRESENT(on_coef_levels)) on_coef_levels1 = on_coef_levels
  nprofiles = SIZE(prof)
  nlayers = prof(1)%nlayers
  nlevels = prof(1)%nlevels

  DO iprof = 1, nprofiles

!-----------------------------------------
! Find cloud top and surface levels
!-----------------------------------------
! nearest level above surface
    DO lev = nlevels - 1, 1, -1
      IF (prof(iprof)%s2m%p > prof(iprof)%p(lev)) EXIT
    ENDDO
! case-1: surf lies above lev=nlevels
!         at exit, lev is first level above surface
! case-2: surf lies below lev=nlevels
!         at exit, lev+1=nlevels, there is no level below surface
! case-1: first level below surface
! case-2: first level above surface
    aux%s(iprof)%nearestlev_surf = lev + 1
    dp = prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%p(aux%s(iprof)%nearestlev_surf - 1)
    aux%s(iprof)%pfraction_surf  = &
        (prof(iprof)%p(aux%s(iprof)%nearestlev_surf) - prof(iprof)%s2m%p) / dp
! NB for case-2, aux % s(iprof) % pfraction_surf -ve
!nearest level above cloud top
    IF (coef%id_sensor /= sensor_id_mw .AND. coef%id_sensor /= sensor_id_po) THEN
      DO lev = nlevels - 1, 1, -1
        IF (prof(iprof)%ctp > prof(iprof)%p(lev)) EXIT
      ENDDO
      IF (lev > 1) THEN
        aux%s(iprof)%nearestlev_ctp = lev + 1
        dp = prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%p(aux%s(iprof)%nearestlev_ctp - 1)
        aux%s(iprof)%pfraction_ctp  = &
            (prof(iprof)%p(aux%s(iprof)%nearestlev_ctp) - prof(iprof)%ctp) / dp
        aux%s(iprof)%cfraction      = prof(iprof)%cfraction
      ELSE
        aux%s(iprof)%nearestlev_ctp = nlevels - 1
        aux%s(iprof)%pfraction_ctp  = 0._jprb
        aux%s(iprof)%cfraction      = 0._jprb
      ENDIF
    ELSE
! for micro waves do not consider clouds in the RTTOV basis routines
      aux%s(iprof)%nearestlev_ctp = nlevels - 1
      aux%s(iprof)%pfraction_ctp  = 0._jprb
      aux%s(iprof)%cfraction      = 0._jprb
    ENDIF



    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN

!-----------------------------------------------------------------------------------------
! For Deff CLW scheme store effective generalized diameter
!-----------------------------------------------------------------------------------------
      IF (prof(iprof)%clw_scheme == clw_scheme_deff) THEN
        DO lay = 1, nlayers
          aux%clw_dg(lay,iprof) = 0._jprb
          IF (ANY(prof_int(iprof)%cloud(1:nwcl_max,lay) > 0._jprb)) THEN
            ! Use effective diameter from input profile if specified
            IF (prof(iprof)%clwde(lay) > 0._jprb) THEN
              aux%clw_dg(lay,iprof) = prof(iprof)%clwde(lay)
            ENDIF
          ENDIF
        ENDDO
      ENDIF

!-----------------------------------------------------------------------------------------
! For ice clouds convert ice water content into effective generalized diameter
!-----------------------------------------------------------------------------------------
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
          aux%ice_dg(lay, iprof) = 0._jprb
          IF (prof_int(iprof)%cloud(6, lay) > 0._jprb) THEN
            ! Use effective diameter from input profile if specified
            IF (prof(iprof)%icede(lay) > 0._jprb) THEN
              aux%ice_dg(lay, iprof) = prof(iprof)%icede(lay)
            ELSE
              IF (prof(iprof)%idg == 1) THEN
                ! Scheme by Ou and Liou, 1995, Atmos. Res., 35, 127-138.
                ztempc                  = prof(iprof)%t(lev) - rtt
                ! intermediate factors in calculating the generalized effective diameter
                aux%fac1_ice_dg(lay, iprof) = 326.3_jprb + ztempc * (12.42_jprb + ztempc * (0.197_jprb + ztempc * 0.0012_jprb))
                aux%fac2_ice_dg(lay, iprof) =      &
                  &  - 1.56_jprb + aux%fac1_ice_dg(lay, iprof) * (0.388_jprb + aux%fac1_ice_dg(lay, iprof) * 0.00051_jprb)
                aux%fac3_ice_dg(lay, iprof) = 2.0_jprb * aux%fac2_ice_dg(lay, iprof)
                !
                ! Take Ou-Liou scheme as being valid only between -20C and -60C
                !
                aux%ice_dg(lay, iprof)      = MAX(aux%fac3_ice_dg(lay, iprof), zradipou_low)
                aux%ice_dg(lay, iprof)      = MIN(aux%ice_dg(lay, iprof), zradipou_upp)
              ELSE IF (prof(iprof)%idg == 2) THEN
                ! Scheme by Wyser et al. (see McFarquhar et al. (2003))
                bwyser =  - 2.0_jprb
                IF (prof(iprof)%t(lev) < 273._jprb) THEN
                  bwyser = bwyser + (0.001_jprb * ((273._jprb - prof(iprof)%t(lev)) ** 1.5_jprb) * &
                    LOG10(prof_int(iprof)%cloud(6, lay) / 50._jprb))
                ENDIF
                aux%fac1_ice_dg(lay, iprof) = 377.4_jprb + bwyser * (203.3_jprb + bwyser * (37.91_jprb + bwyser * 2.3696_jprb))
                nft = (SQRT(3._jprb) + 4._jprb) / (3._jprb * SQRT(3._jprb))
                aux%fac2_ice_dg(lay, iprof) = aux%fac1_ice_dg(lay, iprof) / nft
                aux%ice_dg(lay, iprof)      = 2._jprb * 4._jprb * aux%fac2_ice_dg(lay, iprof) * SQRT(3._jprb) / 9._jprb
              ELSE IF (prof(iprof)%idg == 3) THEN
                ! Scheme by Boudala et al., 2002, Int. J. Climatol., 22, 1267-1284.
                ztempc             = prof(iprof)%t(lev) - rtt
                aux%ice_dg(lay, iprof) = 53.005_jprb * ((prof_int(iprof)%cloud(6, lay)) ** 0.06_jprb) * EXP(0.013_jprb * ztempc)
              ELSE IF (prof(iprof)%idg == 4) THEN
                ! Scheme by McFarquhar et al. (2003)
                amcfarq                 = 1.78449_jprb
                bmcfarq                 = 0.281301_jprb
                cmcfarq                 = 0.0177166_jprb
                zmcfarq                 = prof_int(iprof)%cloud(6, lay)
                aux%fac1_ice_dg(lay, iprof) =      &
                  & 10.0_jprb ** (amcfarq + (bmcfarq * LOG10(zmcfarq)) + (cmcfarq * LOG10(zmcfarq) * LOG10(zmcfarq)))
                aux%ice_dg(lay, iprof)      = 2.0_jprb * aux%fac1_ice_dg(lay, iprof)
              ENDIF
            ENDIF

            IF (ABS(aux%ice_dg(lay, iprof)) > 0._jprb) THEN
              IF (aux%ice_dg(lay, iprof) < dgmin_ssec) aux%ice_dg(lay, iprof) = dgmin_ssec
              IF (aux%ice_dg(lay, iprof) > dgmax_ssec) aux%ice_dg(lay, iprof) = dgmax_ssec
            ENDIF
          ENDIF
        ENDDO
      ENDIF ! SSEC/Baum

    ENDIF ! addclouds
  ENDDO ! iprof

!-----------------------------------------------------------------------------------------
! If using pre-defined aerosol types, do relative humidity calculation
!-----------------------------------------------------------------------------------------
  IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
    CALL calc_rel_hum(prof, prof_int, aux)
  ENDIF


!-----------------------------------------------------------------------------------------
! Calculate predictor data
!-----------------------------------------------------------------------------------------
  IF (on_coef_levels1) THEN
!FWD ONLY
    aux%on_coef_levels = .TRUE.
! 1 profile layer quantities
!   the layer number agrees with the level number of its upper boundary
! layer N-1 lies between levels N-1 and N
    CALL reciprocal(coef%tstar, tstar_r)
    CALL reciprocal(coef%wstar, wstar_r)
    IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) CALL reciprocal(coef%ostar, ostar_r)
    IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) CALL reciprocal(coef%co2star, co2star_r)

    !DAR add from set_predictors_7
    DO iprof = 1, nprofiles
      aux%t_layer(1:nlayers, iprof) = &
        (prof(iprof)%t(1:nlevels-1) + prof(iprof)%t(2:nlevels)) * 0.5_jprb
      aux%w_layer(1:nlayers, iprof) = &
        (prof(iprof)%q(1:nlevels-1) + prof(iprof)%q(2:nlevels)) * 0.5_jprb

      IF (opts%rt_all%use_q2m) THEN
        iv3lev = aux%s(iprof)%nearestlev_surf - 1! nearest level above surface
        iv2lev = aux%s(iprof)%nearestlev_surf    ! nearest level above surface

        IF (iv2lev <= coef%nlevels) THEN
          iv2lay       = iv2lev - 1
          aux%w_layer(iv2lay, iprof) = &
            (prof(iprof)%s2m%q + prof(iprof)%q(iv3lev)) * 0.5_jprb
        ENDIF
      ENDIF

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        aux%o3_layer(1:nlayers, iprof) = &
          (prof(iprof)%o3(1:nlevels-1) + prof(iprof)%o3(2:nlevels)) * 0.5_jprb
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        aux%co2_layer(1:nlayers, iprof) = &
          (prof(iprof)%co2(1:nlevels-1) + prof(iprof)%co2(2:nlevels)) * 0.5_jprb
      ENDIF

! 2. calculate, for layers, deviations from reference profile
      aux%dt(:, iprof) = aux%t_layer(:, iprof)- coef%tstar(:)

      ! if no input O3 profile we still use the input temperature profile for dto
      IF (coef%nozone > 0) &
        aux%dto(:, iprof) = aux%t_layer(:, iprof) - coef%to3star(:)

! 3. calculate (profile / reference profile) ratios; tr wr or co2r
      
      aux%tr(:, iprof) = aux%t_layer(:, iprof) * tstar_r(:)
      aux%wr(:, iprof) = aux%w_layer(:, iprof) * wstar_r(:)
      
! if no input O3 profile, set to reference value (or = 1)

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        aux%or(:, iprof) = aux%o3_layer(:, iprof) * ostar_r(:)
      ELSE
        aux%or(:, iprof) = 1._jprb
      ENDIF

      IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) THEN
        aux%co2r(:, iprof) = aux%co2_layer(:, iprof) * co2star_r(:)
!      ELSE
!        aux%co2r(:, iprof) = 1._jprb
      ENDIF

    ENDDO

! 4. calculate profile / reference profile sums: tw ww ow co2w twr

    DO iprof = 1, nprofiles
      aux%tw(1, iprof) = 0._jprb
      DO lay = 2, nlayers
        ! cumulate overlying layers: weighting tr relates to same layer as dpp
        ! do not need dpp(0) to start
        aux%tw(lay, iprof) = aux%tw(lay - 1, iprof) + &
          coef%dpp(lay - 1) * aux%tr(lay - 1, iprof)
      ENDDO
    ENDDO

    aux%sum = 1._jprb ! Reciprocal below requires non-zero initialisation

!calc profile invariant normalisation coefficient (sum2) - FWD ONLY
    aux%sum(1,1) = coef%dpp(0) * coef%wstar(1)

    DO lay=2, nlayers
      aux%sum(lay,1) = aux%sum(lay-1,1) + coef%dpp(lay - 1) * coef%wstar(lay)
    ENDDO

    IF (coef%nozone > 0 .AND. opts%rt_ir%ozone_Data) THEN
      aux%sum(1,2) = coef%dpp(0) * coef%ostar(1)
      DO lay = 2, nlayers
        aux%sum(lay,2) = aux%sum(lay-1,2) + coef%dpp(lay - 1) * coef%ostar(lay)
      ENDDO
    ENDIF

    IF (coef%nco2 > 0) THEN
      aux%sum(1,4) = 0._jprb ! calc starts at layer 2
      DO lay = 2, nlayers
        aux%sum(lay,4) = aux%sum(lay-1,4) + coef%dpp(lay - 1) * coef%tstar(lay - 1)
      ENDDO
      aux%sum(1,4) = 1e-20_jprb ! calc starts at layer 2

      IF(opts%rt_ir%co2_Data) THEN
        aux%sum(1,3) = coef%dpp(0) * coef%co2star(1)
        DO lay = 2, nlayers
          aux%sum(lay,3) = aux%sum(lay-1,3) + coef%dpp(lay - 1) * coef%co2star(lay)
        ENDDO
      ENDIF
    ENDIF

    IF(coef%fmv_model_ver == 8) THEN
      aux%sum(1,5) = coef%dpp(0) * coef%wstar(1) * coef%tstar(1)
      DO lay = 2, nlayers
        aux%sum(lay,5) = aux%sum(lay-1,5) + coef%dpp(lay - 1) * coef%wstar(lay) * coef%tstar(lay)
      ENDDO
    ENDIF

    CALL reciprocal(aux%sum, aux%sum)

    DO iprof = 1, nprofiles
      ! cumulating column overlying layer and layer itself
      sum1 = 0._jprb
      DO lay = 1, nlayers
        ! cumulate overlying layers: weighting w or wstar relates to layer below dpp
        ! need dpp(0) to start
        sum1 = sum1 + coef%dpp(lay - 1) * aux%w_layer(lay, iprof)
        aux%ww(lay, iprof) = sum1 * aux%sum(lay,1)
      ENDDO
    ENDDO
 
    IF(coef%fmv_model_ver == 8) THEN
      DO iprof = 1, nprofiles
        sum1 = 0._jprb
        DO lay = 1, nlayers
          sum1 = sum1 + coef%dpp(lay - 1) * aux%w_layer(lay, iprof) * aux%t_layer(lay, iprof)
          aux%wwr(lay, iprof) = sum1 * aux%sum(lay,5)
        ENDDO
      ENDDO

      CALL reciprocal(aux%wwr, aux%wwr_r)
    ENDIF
   
    ! if no input O3 profile, set to reference value (ow =1)
    IF (coef%nozone > 0) THEN
      IF (opts%rt_ir%ozone_Data) THEN
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = 1, nlayers
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + coef%dpp(lay - 1) * aux%o3_layer(lay, iprof) ! OK, dpp(0) defined 
            aux%ow(lay, iprof) = sum1 * aux%sum(lay,2)
          ENDDO
        ENDDO
      ELSE
        aux%ow(:, :) = 1._jprb
      ENDIF
    ENDIF

! if no input co2 profile, set to reference value (co2w=1) 
! but twr calculation still uses the input temperature profile

    IF (coef%nco2 > 0) THEN
      IF (opts%rt_ir%co2_Data) THEN
        DO iprof = 1, nprofiles
          sum1 = 0._jprb
          DO lay = 1, nlayers
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + coef%dpp(lay - 1) * aux%co2_layer(lay, iprof) ! OK, dpp(0) defined 
            aux%co2w(lay, iprof) = sum1 * aux%sum(lay,3)
          ENDDO
        ENDDO
      ELSE
        aux%co2w(:, :) = 1._jprb
      ENDIF
 
      ! twr only used in CO2 predictors
      DO iprof = 1, nprofiles
        sum1   = 0._jprb
        aux%twr(1, iprof) = 1._jprb
        
        DO lay = 2, nlayers
! cumulate overlying layers (t, tstar relate to same layer as dpp)
! do not need dpp(0) to start
          sum1       = sum1 + coef%dpp(lay - 1) * aux%t_layer(lay - 1, iprof)
          aux%twr(lay, iprof) = sum1 * aux%sum(lay,4)
        ENDDO
      ENDDO
    ENDIF

!Calculate and store useful intermediate variables

    CALL reciprocal(aux%tr, aux%tr_r)

    IF (coef%fmv_model_ver == 8) THEN
      aux%tr_sqrt = SQRT(aux%tr)
    ENDIF

    aux%tw_sqrt = SQRT(aux%tw)
    aux%tw_sqrt(1,:) = 1e-100_jprb ! DARFIX used for division later...
    aux%tw_4rt = SQRT(aux%tw_sqrt)

    CALL INVSQRT(aux%wr, aux%wr_rsqrt)
    aux%wr_sqrt = aux%wr * aux%wr_rsqrt

    IF (coef%fmv_model_ver == 7) THEN
      CALL reciprocal(aux%ww, aux%ww_r)
    ENDIF

    IF (coef%nozone > 0 .and. opts%rt_ir%ozone_Data) THEN
      CALL INVSQRT(aux%ow, aux%ow_rsqrt)
      aux%ow_r = aux%ow_rsqrt**2_jpim
      aux%or_sqrt = SQRT(aux%or)
      aux%ow_sqrt = aux%ow * aux%ow_rsqrt
    ENDIF
    
  ELSE
!FWD ONLY
    aux%on_coef_levels = .FALSE.
  ENDIF
  
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_profaux
