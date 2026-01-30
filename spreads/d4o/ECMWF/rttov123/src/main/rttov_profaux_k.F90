! Description:
!> @file
!!   K of calculation of variables related to the input profiles.
!
!> @brief
!!   K of calculation of variables related to the input profiles.
!!
!> @details
!!   K of calculation of variables related to the input profiles.
!!
!! @param[in]     opts                 options to configure the simulations
!! @param[in]     chanprof             channels and profiles to simulate
!! @param[in]     profiles             input profiles
!! @param[in,out] profiles_k           input profile increments
!! @param[in]     profiles_int         profiles in internal units
!! @param[in]     profiles_int_k       profile increments in internal units
!! @param[in]     coef                 optical depth coefficient structure
!! @param[in]     aux                  auxiliary profile data structure
!! @param[in,out] aux_k                auxiliary profile data increments
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
SUBROUTINE rttov_profaux_k( &
              opts,           &
              chanprof,       &
              profiles,       &
              profiles_k,     &
              profiles_int,   &
              profiles_int_k, &
              coef,           &
              aux,            &
              aux_k)

  USE rttov_types, ONLY :  &
        rttov_chanprof,    &
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
  USE rttov_math_mod, ONLY: reciprocal, invsqrt_k, reciprocal_k, sqrt_k
  USE rttov_scattering_mod, ONLY: calc_rel_hum_k
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options),     INTENT(IN)    :: opts
  TYPE(rttov_chanprof),    INTENT(IN)    :: chanprof(:)
  TYPE(rttov_profile),     INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),     INTENT(INOUT) :: profiles_k(SIZE(chanprof))
  TYPE(rttov_profile),     INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_profile),     INTENT(INOUT) :: profiles_int_k(SIZE(chanprof))
  TYPE(rttov_coef),        INTENT(IN)    :: coef
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux
  TYPE(rttov_profile_aux), INTENT(INOUT) :: aux_k
!INTF_END

  REAL(jprb), PARAMETER :: rtt      = 273.15_jprb
  REAL(jprb), PARAMETER :: rtou_upp =  - 20._jprb
  REAL(jprb), PARAMETER :: rtou_low =  - 60._jprb

  INTEGER(jpim) :: nchannels, nlayers, nlevels
  INTEGER(jpim) :: i, prof, lev, lay
  REAL(jprb)    :: dp, dp_k
  REAL(jprb)    :: amcfarq, bmcfarq, cmcfarq, zmcfarq, zmcfarq_k
  REAL(jprb)    :: ztempc, ztempc_k
  REAL(jprb)    :: zradipou_upp, zradipou_low
  REAL(jprb)    :: bwyser, bwyser_k, nft
  REAL(jprb)    :: ZHOOK_HANDLE
  REAL(jprb)    :: tstar_r(profiles(1)%nlayers)
  REAL(jprb)    :: wstar_r(profiles(1)%nlayers)
  REAL(jprb)    :: ostar_r(profiles(1)%nlayers)
  REAL(jprb)    :: co2star_r(profiles(1)%nlayers)
  REAL(jprb)    :: sum1
  INTEGER(jpim) :: iv2lay, iv2lev!, iv3lev
  INTEGER(jpim) :: map(SIZE(chanprof),2), prof_stat

!- End of header --------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_K', 0_jpim, ZHOOK_HANDLE)
  nchannels = SIZE(chanprof)
  nlayers = profiles(1)%nlayers
  nlevels = profiles(1)%nlevels

  map(1,1) = chanprof(1)%prof
  map(1,2) = chanprof(1)%chan

  prof_stat = 1 ! assume profs are contiguous and monotonic
  DO i = 2, nchannels
    map(i,1) = chanprof(i)%prof
    map(i,2) = chanprof(i)%chan

    IF (map(i,1) < map(i-1,1)) THEN ! they are not.
      prof_stat = -1
    ENDIF
  ENDDO

!-----------------------------------------------------------------------------------------
! K of relative humidity calculation
!-----------------------------------------------------------------------------------------
  IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
    CALL calc_rel_hum_k(opts, chanprof, profiles, profiles_k, profiles_int_k, aux, aux_k)
  ENDIF


  IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN

!-----------------------------------------------------------------------------------------
! Deff CLW scheme
!-----------------------------------------------------------------------------------------
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      IF (profiles(prof)%clw_scheme == clw_scheme_deff) THEN
        DO lay = 1, nlayers
          IF (ANY(profiles_int(prof)%cloud(1:nwcl_max,lay) > 0._jprb)) THEN
            IF (profiles(prof)%clwde(lay) > 0._jprb) THEN
              profiles_k(i)%clwde(lay) = profiles_k(i)%clwde(lay) + aux_k%clw_dg(lay,i)
            ENDIF
          ENDIF
          aux_k%clw_dg(lay,i) = 0._jprb
        ENDDO
      ENDIF
    ENDDO

!------------------------------------------------------------
! K for ice water content into effective generalized diameter
!------------------------------------------------------------
    zmcfarq_k = 0._jprb
    ztempc_k  = 0._jprb
    bwyser_k  = 0._jprb
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
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      IF (.NOT. profiles(prof)%ice_scheme == ice_scheme_ssec) CYCLE
      DO lay = nlayers, 1, -1
        lev = lay + 1
        IF (profiles_int(prof)%cloud(6, lay) > 0._jprb) THEN
          IF (ABS(aux%ice_dg(lay, prof)) > 0._jprb) THEN
            IF (aux%ice_dg(lay, prof) < dgmin_ssec) aux_k%ice_dg(lay, i) = 0._jprb
            IF (aux%ice_dg(lay, prof) > dgmax_ssec) aux_k%ice_dg(lay, i) = 0._jprb
          ENDIF
          ! Use effective diameter from input profile if specified
          IF (profiles(prof)%icede(lay) > 0._jprb) THEN
            profiles_k(i)%icede(lay) = profiles_k(i)%icede(lay) + aux_k%ice_dg(lay, i)
          ELSE
            IF (profiles(prof)%idg == 1) THEN
              ! Scheme by Ou and Liou, 1995, Atmos. Res., 35, 127-138.
              ztempc = profiles(prof)%t(lev) - rtt
              !
              ! Take Ou-Liou scheme as being valid only between 20C and 60C
              !
              IF (aux%fac3_ice_dg(lay, prof) < zradipou_low .OR. aux%fac3_ice_dg(lay, prof) > zradipou_upp) THEN
                aux_k%ice_dg(lay, i) = 0._jprb
              ELSE
                aux_k%fac3_ice_dg(lay, i) = aux_k%fac3_ice_dg(lay, i) + aux_k%ice_dg(lay, i)
              ENDIF
              aux_k%fac2_ice_dg(lay, i) = aux_k%fac2_ice_dg(lay, i) + 2.0_jprb * aux_k%fac3_ice_dg(lay, i)
              aux_k%fac1_ice_dg(lay, i) = aux_k%fac1_ice_dg(lay, i) + 0.388_jprb * aux_k%fac2_ice_dg(lay, i)
              aux_k%fac1_ice_dg(lay, i) =      &
                  aux_k%fac1_ice_dg(lay, i) + aux_k%fac2_ice_dg(lay, i) * 0.00051_jprb * 2 * aux%fac1_ice_dg(lay, prof)
              ztempc_k                   = ztempc_k + aux_k%fac1_ice_dg(lay, i) *      &
                  (12.42_jprb + 2._jprb * 0.197_jprb * ztempc + 3._jprb * 0.0012_jprb * ztempc * ztempc)
              profiles_k(i)%t(lev)       = profiles_k(i)%t(lev) + ztempc_k
              ztempc_k                   = 0._jprb
            ELSE IF (profiles(prof)%idg == 2) THEN
              ! Scheme by Wyser et al. (see McFarquhar et al. (2003))
              bwyser =  - 2.0_jprb
              IF (profiles(prof)%t(lev) < 273._jprb) THEN
                bwyser = bwyser + (0.001_jprb * &
                  ((273._jprb - profiles(prof)%t(lev)) ** 1.5_jprb) * LOG10(profiles_int(prof)%cloud(6, lay) / 50._jprb))
              ENDIF
              nft = (SQRT(3._jprb) + 4._jprb) / (3._jprb * SQRT(3._jprb))
              aux_k%fac2_ice_dg(lay, i) =      &
                  aux_k%fac2_ice_dg(lay, i) + aux_k%ice_dg(lay, i) * 2._jprb * 4._jprb * SQRT(3._jprb) / 9._jprb
              aux_k%fac1_ice_dg(lay, i) = aux_k%fac1_ice_dg(lay, i) + aux_k%fac2_ice_dg(lay, i) / nft
              bwyser_k                   = bwyser_k + &
                  aux_k%fac1_ice_dg(lay, i) * (203.3_jprb + 2 * bwyser * 37.91_jprb + 3 * bwyser * bwyser * 2.3696_jprb)
              IF (profiles(prof)%t(lev) < 273._jprb) THEN
                profiles_k(i)%t(lev)        = profiles_k(i)%t(lev) - &
                    bwyser_k * 0.001_jprb * 1.5_jprb * ((273._jprb - profiles(prof)%t(lev)) ** 0.5_jprb) *  &
                    LOG10(profiles_int(prof)%cloud(6, lay) / 50._jprb)
                profiles_int_k(i)%cloud(6, lay) = profiles_int_k(i)%cloud(6, lay) + &
                    bwyser_k * 0.001_jprb * ((273._jprb - profiles(prof)%t(lev)) ** 1.5_jprb) / &
                    profiles_int(prof)%cloud(6, lay) / LOG(10._jprb)
              ENDIF
              bwyser_k = 0._jprb
            ELSE IF (profiles(prof)%idg == 3) THEN
              ! Scheme by Boudala et al., 2002, Int. J. Climatol., 22, 1267-1284.
              ztempc = profiles(prof)%t(lev) - rtt
              profiles_int_k(i)%cloud(6, lay) = profiles_int_k(i)%cloud(6, lay) + &
                  aux_k%ice_dg(lay, i) * 53.005_jprb * (profiles_int(prof)%cloud(6, lay) ** (0.06_jprb - 1)) *  &
                  EXP(0.013_jprb * ztempc) * 0.06_jprb
              ztempc_k                    = ztempc_k + &
                  aux_k%ice_dg(lay, i) * 53.005_jprb * ((profiles_int(prof)%cloud(6, lay)) ** 0.06_jprb) * 0.013_jprb *  &
                  EXP(0.013_jprb * ztempc)
              profiles_k(i)%t(lev)        = profiles_k(i)%t(lev) + ztempc_k
              ztempc_k                    = 0._jprb
            ELSE IF (profiles(prof)%idg == 4) THEN
              ! Scheme by McFarquhar et al. (2003)
              amcfarq                     = 1.78449_jprb
              bmcfarq                     = 0.281301_jprb
              cmcfarq                     = 0.0177166_jprb
              zmcfarq                     = profiles_int(prof)%cloud(6, lay)
              aux_k%fac1_ice_dg(lay, i)  = aux_k%fac1_ice_dg(lay, i) + aux_k%ice_dg(lay, i) * 2.0_jprb
              zmcfarq_k                   = zmcfarq_k + aux_k%fac1_ice_dg(lay, i) * &
                  10.0_jprb ** (amcfarq + bmcfarq * LOG10(zmcfarq) + cmcfarq * LOG10(zmcfarq) * LOG10(zmcfarq)) *  &
                  (bmcfarq + 2._jprb * cmcfarq * LOG10(zmcfarq)) / zmcfarq
              profiles_int_k(i)%cloud(6, lay) = profiles_int_k(i)%cloud(6, lay) + zmcfarq_k
              zmcfarq_k                   = 0._jprb
            ENDIF
          ENDIF
        ENDIF
        aux_k%ice_dg(lay, i) = 0._jprb
      ENDDO
    ENDDO
  ENDIF

!-----------------------------------
! K for cloud top and surface levels
!-----------------------------------
  DO i = 1, nchannels
    prof = chanprof(i)%prof
    IF (coef%id_sensor /= sensor_id_mw .AND. coef%id_sensor /= sensor_id_po) THEN
!nearest level above cloud top
      dp = profiles(prof)%p(aux%s(prof)%nearestlev_ctp) - profiles(prof)%p(aux%s(prof)%nearestlev_ctp - 1)
      dp_k = 0._jprb
      profiles_k(i)%cfraction = profiles_k(i)%cfraction + aux_k%s(i)%cfraction
      profiles_k(i)%ctp       = profiles_k(i)%ctp - aux_k%s(i)%pfraction_ctp / dp
      IF (opts%interpolation%lgradp) THEN
        profiles_k(i)%p(aux%s(prof)%nearestlev_ctp) = profiles_k(i)%p(aux%s(prof)%nearestlev_ctp) + &
            aux_k%s(i)%pfraction_ctp / dp
        dp_k = dp_k - (profiles(prof)%p(aux%s(prof)%nearestlev_ctp) - profiles(prof)%ctp) / dp ** 2 * &
            aux_k%s(i)%pfraction_ctp
        profiles_k(i)%p(aux%s(prof)%nearestlev_ctp) = profiles_k(i)%p(aux%s(prof)%nearestlev_ctp) + dp_k
        profiles_k(i)%p(aux%s(prof)%nearestlev_ctp - 1) = profiles_k(i)%p(aux%s(prof)%nearestlev_ctp - 1) - dp_k
      ENDIF
!Else
! for micro waves do not consider clouds in the RTTOV basis routines
    ENDIF
!nearest level above surface
    dp = profiles(prof)%p(aux%s(prof)%nearestlev_surf) - profiles(prof)%p(aux%s(prof)%nearestlev_surf - 1)
    dp_k = 0._jprb
    profiles_k(i)%s2m%p = profiles_k(i)%s2m%p - aux_k%s(i)%pfraction_surf / dp
    IF (opts%interpolation%lgradp) THEN
      profiles_k(i)%p(aux%s(prof)%nearestlev_surf) = profiles_k(i)%p(aux%s(prof)%nearestlev_surf) + &
          aux_k%s(i)%pfraction_surf / dp
      dp_k = dp_k - (profiles(prof)%p(aux%s(prof)%nearestlev_surf) - profiles(prof)%s2m%p) / dp ** 2 * &
          aux_k%s(i)%pfraction_surf
      profiles_k(i)%p(aux%s(prof)%nearestlev_surf) = profiles_k(i)%p(aux%s(prof)%nearestlev_surf) + dp_k
      profiles_k(i)%p(aux%s(prof)%nearestlev_surf - 1) = profiles_k(i)%p(aux%s(prof)%nearestlev_surf - 1) - dp_k
    ENDIF
  ENDDO ! channels



!-----------------------------------------------------------------------------------------
! K of predictor data
!-----------------------------------------------------------------------------------------
  IF (aux%on_coef_levels) THEN

!FWD
    CALL reciprocal(coef%tstar, tstar_r)
    CALL reciprocal(coef%wstar, wstar_r)
    IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) CALL reciprocal(coef%ostar, ostar_r)
    IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) CALL reciprocal(coef%co2star, co2star_r)

!K
    IF (coef%fmv_model_ver == 7) THEN
      CALL reciprocal_k(aux%ww_r, aux_k%ww, aux_k%ww_r, &
        acc = .TRUE._jplm, map = map, prof_stat = prof_stat)
    ENDIF

    DO i = 1, nchannels
      prof = chanprof(i)%prof
      
      aux_k%wr(:,i) = aux_k%wr(:,i) + aux%wr_rsqrt(:,prof) * aux_k%wr_sqrt(:,i)

      aux_k%wr_rsqrt(:,i) = &!aux_k%wr_rsqrt +
        aux%wr(:,prof) * aux_k%wr_sqrt(:,i)
    ENDDO
    CALL INVSQRT_K(aux%wr_rsqrt, aux_k%wr, aux_k%wr_rsqrt, &
      acc = .TRUE._jplm, map = map, prof_stat = prof_stat)

    CALL sqrt_k(aux%tw_4rt, aux_k%tw_sqrt, aux_k%tw_4rt, &
      acc = .FALSE._jplm, map = map, prof_stat = prof_stat)  
    CALL sqrt_k(aux%tw_sqrt, aux_k%tw, aux_k%tw_sqrt, &
      acc = .TRUE._jplm, map = map, prof_stat = prof_stat)  

    IF (coef%fmv_model_ver == 8) THEN
      IF (coef%nco2 > 0) THEN
        CALL sqrt_k(aux%tr_sqrt, aux_k%tr, aux_k%tr_sqrt, &
          acc = .TRUE._jplm, map = map, prof_stat = prof_stat)
      ENDIF
    ENDIF

    CALL reciprocal_k(aux%tr_r, aux_k%tr, aux_k%tr_r, &
      acc = .TRUE._jplm, map = map, prof_stat = prof_stat) ! used by mg and wv
    
    IF (coef%nozone > 0 .and. opts%rt_ir%ozone_Data) THEN
      CALL sqrt_k(aux%or_sqrt, aux_k%or, aux_k%or_sqrt, &
        acc = .TRUE._jplm, map = map, prof_stat = prof_stat)
      DO i = 1, nchannels
        prof = chanprof(i)%prof

        aux_k%ow_rsqrt(:,i) = &!aux_k%ow_rsqrt + 
          aux%ow(:,prof) * aux_k%ow_sqrt(:,i)

        aux_k%ow(:,i) = aux_k%ow(:,i) + aux_k%ow_sqrt(:,i) * aux%ow_rsqrt(:,prof)
        aux_k%ow_rsqrt(:,i) = aux_k%ow_rsqrt(:,i) + &
          2._jprb * aux%ow_rsqrt(:,prof) * aux_k%ow_r(:,i)
      ENDDO
      CALL INVSQRT_K(aux%ow_rsqrt, aux_k%ow, aux_k%ow_rsqrt, &
        acc = .TRUE._jplm, map = map, prof_stat = prof_stat)
    ENDIF

! 4. calculate profile / reference profile sums: tw ww ow

    DO i = 1, nchannels
      DO lay = nlayers, 2, -1
        ! cumulate overlying layers: weighting tr relates to same layer as dpp
        ! do not need dpp(0) to start
        aux_k%tw(lay - 1, i) = aux_k%tw(lay - 1, i) + aux_k%tw(lay, i)
        aux_k%tr(lay - 1, i) = aux_k%tr(lay - 1, i) + coef%dpp(lay - 1) * aux_k%tw(lay, i)
      ENDDO
    ENDDO

    DO i = 1, nchannels
      sum1 = 0._jprb
      ! cumulating column overlying layer and layer itself
      DO lay = nlayers, 1, -1
        ! cumulate overlying layers: weighting w or wstar relates to layer below dpp
        ! need dpp(0) to start
        sum1 = sum1 + aux_k%ww(lay, i) * aux%sum(lay,1)
        aux_k%w_layer(lay, i) = &!aux_k%w_layer(lay, i) +
          sum1 * coef%dpp(lay - 1)
      ENDDO
    ENDDO

    IF(coef%fmv_model_ver == 8) THEN
      CALL reciprocal_k(aux%wwr_r, aux_k%wwr, aux_k%wwr_r, &
        acc=.FALSE._jplm, map = map, prof_stat = prof_stat)
      DO i = 1, nchannels
        prof = chanprof(i)%prof
        sum1 = 0._jprb
        DO lay = nlayers, 1, -1
          sum1 = sum1 + aux_k%wwr(lay, i) * aux%sum(lay,5)

          aux_k%w_layer(lay, i) = aux_k%w_layer(lay, i) + &
            coef%dpp(lay - 1) * sum1 * aux%t_layer(lay, prof)

          aux_k%t_layer(lay, i) = aux_k%t_layer(lay, i) + &
            coef%dpp(lay - 1) * sum1 * aux%w_layer(lay, prof)
        ENDDO
      ENDDO
    ENDIF

    IF (coef%nozone > 0) THEN
      IF (opts%rt_ir%ozone_Data) THEN     ! if no input O3 profile, set to reference value (ow =1)
        DO i = 1, nchannels
          sum1 = 0._jprb
          DO lay = nlayers, 1, -1
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + aux_k%ow(lay, i) * aux%sum(lay,2)
            aux_k%o3_layer(lay, i) = &!aux_k%o3_layer(lay, i) +
              sum1 * coef%dpp(lay - 1) ! OK, dpp(0) defined
          ENDDO
        ENDDO
      ELSE
        aux_k%o3_layer(:, :) = 0._jprb
      ENDIF
    ENDIF

! if no input co2 profile, set to reference value (co2w_tl=0) 
! but twr calculation still uses the input temperature profile

    IF (coef%nco2 > 0) THEN
      IF (opts%rt_ir%co2_Data) THEN
        DO i = 1, nchannels
          sum1 = 0._jprb
          DO lay = nlayers, 1, -1
            ! cumulate overlying layers: weighting o or ostar relates to layer below dpp
            ! need dpp(0) to start
            sum1 = sum1 + aux%sum(lay,3) * aux_k%co2w(lay, i)

            aux_k%co2_layer(lay, i) = &!aux_k%co2_layer(lay, i) + &
              sum1 * coef%dpp(lay - 1) 
          ENDDO
        ENDDO
      ELSE
        aux_k%co2_layer(:, :) = 0._jprb
      ENDIF
      
      ! twr only used in CO2 predictors
      DO i = 1, nchannels
        sum1   = 0._jprb
        
        DO lay = nlayers, 2, -1
! cumulate overlying layers (t, tstar relate to same layer as dpp)
! do not need dpp(0) to start
          sum1 = sum1 + aux_k%twr(lay, i) * aux%sum(lay,4)
          aux_k%t_layer(lay - 1, i) = aux_k%t_layer(lay - 1, i) + &
                                           coef%dpp(lay - 1) * sum1
        ENDDO
        aux_k%twr(1, i) = 0._jprb

      ENDDO
    ENDIF

! 3. calculate (profile / reference profile) ratios; tr wr or
    DO i = 1, nchannels
      prof = chanprof(i)%prof
      aux_k%t_layer(:, i) = aux_k%t_layer(:, i) + aux_k%tr(:, i) * tstar_r(:)

      aux_k%w_layer(:, i) = aux_k%w_layer(:, i) + aux_k%wr(:, i) * wstar_r(:)

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        aux_k%o3_layer(:, i) = aux_k%o3_layer(:, i) + aux_k%or(:, i)  * ostar_r(:)
      ENDIF

      IF (opts%rt_ir%co2_Data .AND. coef%nco2 > 0) THEN
        aux_k%co2_layer(:, i) = aux_k%co2_layer(:, i) + aux_k%co2r(:, i) * co2star_r(:)
      ENDIF

! 2. calculate, for layers, deviations from reference profile
      aux_k%t_layer(:, i) = aux_k%t_layer(:, i) + aux_k%dt(:, i)

      ! if no input O3 profile we still use the input temperature profile for dto
      IF (coef%nozone > 0) &
        aux_k%t_layer(:, i) = aux_k%t_layer(:, i) + aux_k%dto(:, i)

! 1 profile layer quantities
!   the layer number agrees with the level number of its upper boundary
! layer N-1 lies between levels N-1 and N
    !DAR add from set_predictors_7

      IF (opts%rt_ir%ozone_Data .AND. coef%nozone > 0) THEN
        profiles_k(i)%o3(1) = profiles_k(i)%o3(1) + &
          0.5_jprb * aux_k%o3_layer(1, i)
        profiles_k(i)%o3(2:nlevels-1) = profiles_k(i)%o3(2:nlevels-1) + &
          0.5_jprb * (aux_k%o3_layer(1:nlevels-2, i) + aux_k%o3_layer(2:nlevels-1, i))
        profiles_k(i)%o3(nlevels) = profiles_k(i)%o3(nlevels) + &
          0.5_jprb * aux_k%o3_layer(nlevels-1, i)
      ENDIF

      IF (opts%rt_ir%co2_data .AND. coef%nco2 > 0) THEN
        profiles_k(i)%co2(1) = profiles_k(i)%co2(1) + &
          0.5_jprb * aux_k%co2_layer(1, i)
        profiles_k(i)%co2(2:nlevels-1) = profiles_k(i)%co2(2:nlevels-1) + &
          0.5_jprb * (aux_k%co2_layer(1:nlevels-2, i) + aux_k%co2_layer(2:nlevels-1, i))
        profiles_k(i)%co2(nlevels) = profiles_k(i)%co2(nlevels) + &
          0.5_jprb * aux_k%co2_layer(nlevels-1, i)
      ENDIF

      IF (opts%rt_all%use_q2m) THEN
!         iv3lev = aux%s(prof)%nearestlev_surf - 1! nearest level above surface
        iv2lev = aux%s(prof)%nearestlev_surf    ! nearest level above surface

        IF (iv2lev <= coef%nlevels) THEN
          iv2lay       = iv2lev - 1
          profiles_k(i)%s2m%q =  profiles_k(i)%s2m%q + &
            aux_k%w_layer(iv2lay, i) * 0.5_jprb

          ! This line subtracts the quantity that is added to prof_k(i)%q(iv2lev) below
          ! so that it cancels out: in the case where use_q2m is true prof(prof)%q(iv2lev) is
          ! replaced by prof(prof)%s2m%q in the calculation of aux%w_layer(iv2lay, prof)
          profiles_k(i)%q(iv2lev) = profiles_k(i)%q(iv2lev) - &
            aux_k%w_layer(iv2lay, i) * 0.5_jprb
        ENDIF
      ENDIF

      profiles_k(i)%q(1) = profiles_k(i)%q(1) + &
        0.5_jprb * aux_k%w_layer(1, i)
      profiles_k(i)%q(2:nlevels-1) = profiles_k(i)%q(2:nlevels-1) + &
        0.5_jprb * (aux_k%w_layer(1:nlevels-2, i) + aux_k%w_layer(2:nlevels-1, i))
      profiles_k(i)%q(nlevels) = profiles_k(i)%q(nlevels) + &
        0.5_jprb * aux_k%w_layer(nlevels-1, i)

      profiles_k(i)%t(1) = profiles_k(i)%t(1) + &
        0.5_jprb * aux_k%t_layer(1, i)
      profiles_k(i)%t(2:nlevels-1) = profiles_k(i)%t(2:nlevels-1) + &
        0.5_jprb * (aux_k%t_layer(1:nlevels-2, i) + aux_k%t_layer(2:nlevels-1, i))
      profiles_k(i)%t(nlevels) = profiles_k(i)%t(nlevels) + &
        0.5_jprb * aux_k%t_layer(nlevels-1, i)
    ENDDO

  ENDIF
  IF (LHOOK) CALL DR_HOOK('RTTOV_PROFAUX_K', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_profaux_k
