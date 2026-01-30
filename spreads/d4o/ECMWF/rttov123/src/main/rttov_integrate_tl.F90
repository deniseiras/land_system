! Description:
!> @file
!!   TL of integration of the radiative transfer equation
!
!> @brief
!!   TL of integration of the radiative transfer equation
!!
!!
!! @param[in]     addcosmic                   flag for inclusion of CMBR term in MW simulations
!! @param[in]     opts                        RTTOV options structure
!! @param[in]     maxnstreams                 largest number of cloud streams (columns) across all profiles
!! @param[in]     chanprof                    specifies channels and profiles to simulate
!! @param[in]     emissivity                  input/output surface emissivities
!! @param[in,out] emissivity_tl               input/output surface emissivity perturbations
!! @param[in]     reflectance                 input/output surface reflectances for direct solar beam
!! @param[in,out] reflectance_tl              input/output surface reflectance perturbations for direct solar beam
!! @param[in]     refl_norm                   surface relfectance normalisation factors
!! @param[in]     diffuse_refl                surface reflectance for downwelling radiation
!! @param[in]     diffuse_refl_tl             surface reflectance perturbations for downwelling radiation
!! @param[in]     do_lambertian               flag indicating whether Lambertian surface is active for each channel
!! @param[in]     thermal                     per-channel flag to indicate if emissive simulations are being performed
!! @param[in]     dothermal                   flag to indicate if any emissive simulations are being performed
!! @param[in]     solar                       per-channel flag to indicate if solar simulations are being performed
!! @param[in]     dosolar                     flag to indicate if any solar simulations are being performed
!! @param[in]     solar_spectrum              TOA solar irradiance for each channel
!! @param[in]     transmission_aux            top-level auxiliary transmission structure
!! @param[in]     transmission_aux_tl         auxiliary transmission perturbations
!! @param[in]     transmission_scatt_ir       visible/IR cloud/aerosol scattering parameters
!! @param[in]     transmission_scatt_ir_tl    visible/IR cloud/aerosol scattering parameter perturbations
!! @param[in]     profiles                    input atmospheric profiles and surface variables
!! @param[in]     profiles_tl                 input atmospheric profile perturbations
!! @param[in]     profiles_dry                profiles in internal units
!! @param[in]     profiles_dry_tl             profile perturbations in internal units
!! @param[in]     aux_prof                    auxiliary profile variables
!! @param[in]     aux_prof_tl                 auxiliary profile variable perturbations
!! @param[in]     coef                        optical depth coefficients structure
!! @param[in]     raytracing                  raytracing structure
!! @param[in]     raytracing_tl               raytracing perturbations
!! @param[in]     ircld                       computed cloud column data
!! @param[in]     ircld_tl                    cloud column perturbations
!! @param[in]     rad                         primary output radiance structure
!! @param[in]     auxrad                      Planck radiances
!! @param[in,out] auxrad_tl                   Planck radiance perturbations
!! @param[in]     auxrad_stream               internal radiance structure
!! @param[in,out] auxrad_stream_tl            internal radiance perturbations
!! @param[in,out] rad_tl                      output radiance perturbations
!!
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
SUBROUTINE rttov_integrate_tl(addcosmic, opts, maxnstreams, chanprof, emissivity, emissivity_tl, &
                              reflectance, reflectance_tl, refl_norm, diffuse_refl, diffuse_refl_tl, &
                              do_lambertian, thermal, dothermal, solar, dosolar, solar_spectrum, &
                              transmission_aux, transmission_aux_tl, transmission_scatt_ir, &
                              transmission_scatt_ir_tl, profiles, profiles_tl, profiles_dry, &
                              profiles_dry_tl, aux_prof, aux_prof_tl, coef, raytracing, &
                              raytracing_tl, ircld, ircld_tl, rad, auxrad, auxrad_tl, auxrad_stream, &
                              auxrad_stream_tl, rad_tl)

  USE parkind1, ONLY : jpim, jprb, jplm

  USE rttov_types, ONLY : rttov_chanprof, rttov_coef, rttov_options, rttov_profile, rttov_profile_aux, &
                          rttov_transmission_aux, rttov_transmission_scatt_ir, rttov_radiance, &
                          rttov_ircld, rttov_raytracing, rttov_radiance_aux, rttov_emissivity, rttov_reflectance
!INTF_OFF
  USE rttov_const, ONLY : realtol, sensor_id_po, min_od, min_tau, pi_r, z4pi_r, &
                          deg2rad, gravity, na, Mh2o, Mair, &
                          overcast_albedo_wvn, overcast_albedo1, overcast_albedo2, &
                          vis_scatt_dom, vis_scatt_single, ir_scatt_dom, &
                          ray_scs_wlm, ray_scs_a1, ray_scs_b1, ray_scs_c1, &
                          ray_scs_d1, ray_scs_a2, ray_scs_b2, ray_scs_c2, ray_scs_d2, ray_min_wvn

  USE yomhook, ONLY : LHOOK, DR_HOOK
!INTF_ON
  IMPLICIT NONE

  LOGICAL(jplm),                      INTENT(IN)              :: addcosmic
  TYPE(rttov_options),                INTENT(IN)              :: opts
  INTEGER(jpim),                      INTENT(IN)              :: maxnstreams
  TYPE(rttov_chanprof),               INTENT(IN)              :: chanprof(:)
  TYPE(rttov_emissivity),             INTENT(IN),    OPTIONAL :: emissivity(:)
  TYPE(rttov_emissivity),             INTENT(INOUT), OPTIONAL :: emissivity_tl(:)
  TYPE(rttov_reflectance),            INTENT(IN),    OPTIONAL :: reflectance(:)
  TYPE(rttov_reflectance),            INTENT(INOUT), OPTIONAL :: reflectance_tl(:)
  REAL(jprb),                         INTENT(IN)              :: refl_norm(:)
  REAL(jprb),                         INTENT(IN)              :: diffuse_refl(:)
  REAL(jprb),                         INTENT(IN)              :: diffuse_refl_tl(:)
  LOGICAL(jplm),                      INTENT(IN)              :: do_lambertian(:)
  LOGICAL(jplm),                      INTENT(IN)              :: thermal(:)
  LOGICAL(jplm),                      INTENT(IN)              :: dothermal
  LOGICAL(jplm),                      INTENT(IN)              :: solar(:)
  LOGICAL(jplm),                      INTENT(IN)              :: dosolar
  REAL(jprb),                         INTENT(IN)              :: solar_spectrum(:)
  TYPE(rttov_transmission_aux),       INTENT(IN)              :: transmission_aux
  TYPE(rttov_transmission_aux),       INTENT(IN)              :: transmission_aux_tl
  TYPE(rttov_transmission_scatt_ir),  INTENT(IN)              :: transmission_scatt_ir
  TYPE(rttov_transmission_scatt_ir),  INTENT(IN)              :: transmission_scatt_ir_tl
  TYPE(rttov_profile),                INTENT(IN)              :: profiles(:)
  TYPE(rttov_profile),                INTENT(IN)              :: profiles_tl(:)
  TYPE(rttov_profile),                INTENT(IN)              :: profiles_dry(:)
  TYPE(rttov_profile),                INTENT(IN)              :: profiles_dry_tl(:)
  TYPE(rttov_profile_aux),            INTENT(IN)              :: aux_prof
  TYPE(rttov_profile_aux),            INTENT(IN)              :: aux_prof_tl
  TYPE(rttov_coef),                   INTENT(IN)              :: coef
  TYPE(rttov_raytracing),             INTENT(IN)              :: raytracing
  TYPE(rttov_raytracing),             INTENT(IN)              :: raytracing_tl
  TYPE(rttov_ircld),                  INTENT(IN)              :: ircld
  TYPE(rttov_ircld),                  INTENT(IN)              :: ircld_tl
  TYPE(rttov_radiance),               INTENT(IN)              :: rad
  TYPE(rttov_radiance_aux),           INTENT(IN)              :: auxrad
  TYPE(rttov_radiance_aux),           INTENT(INOUT)           :: auxrad_tl
  TYPE(rttov_radiance_aux),           INTENT(IN)              :: auxrad_stream
  TYPE(rttov_radiance_aux),           INTENT(INOUT)           :: auxrad_stream_tl
  TYPE(rttov_radiance),               INTENT(INOUT)           :: rad_tl
!INTF_END

#include "rttov_calcrad_tl.interface"

  INTEGER(jpim) :: i, lev, ist, lay, nchanprof, nlayers, nlevels
  REAL(jprb)    :: refl, refl_norm_scat
  LOGICAL(jplm) :: keyradonly, do_scatt, dom_ir, dom_vis, do_single_scatt

  INTEGER(jpim) :: iv2lay(SIZE(chanprof)), iv2lev(SIZE(chanprof))
  INTEGER(jpim) :: iv3lay(SIZE(chanprof)), iv3lev(SIZE(chanprof))
  INTEGER(jpim) :: pol_id(SIZE(chanprof))

  REAL(jprb)    :: cfraction(SIZE(chanprof)), cfraction_tl(SIZE(chanprof)), pfraction(SIZE(chanprof))
  LOGICAL(jplm) :: sateqsun(profiles(1)%nlayers,SIZE(profiles(:)))

  REAL(jprb)    :: ZHOOK_HANDLE
!- End of header ------------------------------------------------------

  IF (LHOOK) CALL DR_HOOK('RTTOV_INTEGRATE_TL',0_jpim,ZHOOK_HANDLE)

#define prof chanprof(i)%Prof
#define chan chanprof(i)%Chan

#define tau_surf_p_tl transmission_aux_tl%thermal_path1%Tau_surf_p(ist,i)
#define tau_surf_tl transmission_aux_tl%thermal_path1%Tau_surf(ist,i)
#define tau_layer_p_tl transmission_aux_tl%thermal_path1%Tau_level_p(lay,ist,i)
#define tau_layer_tl transmission_aux_tl%thermal_path1%Tau_level(lay,ist,i)
#define tau_level_p_tl transmission_aux_tl%thermal_path1%Tau_level_p(lay+1,ist,i)
#define tau_level_tl transmission_aux_tl%thermal_path1%Tau_level(lay+1,ist,i)

#define od_singlelayer_tl transmission_aux_tl%thermal_path1%Od_singlelayer(isti,lay,i)

#define tau_surf_p_r transmission_aux%thermal_path1%Tau_surf_p_r(ist,i)
#define tau_surf_p transmission_aux%thermal_path1%Tau_surf_p(ist,i)
#define tau_surf_r transmission_aux%thermal_path1%Tau_surf_r(ist,i)
#define tau_surf transmission_aux%thermal_path1%Tau_surf(ist,i)

#define tau_layer_p_r transmission_aux%thermal_path1%Tau_level_p_r(lay,ist,i)
#define tau_layer_p transmission_aux%thermal_path1%Tau_level_p(lay,ist,i)
#define tau_layer_r transmission_aux%thermal_path1%Tau_level_r(lay,ist,i)
#define tau_layer transmission_aux%thermal_path1%Tau_level(lay,ist,i)

#define tau_level_p_r transmission_aux%thermal_path1%Tau_level_p_r(lay+1,ist,i)
#define tau_level_p transmission_aux%thermal_path1%Tau_level_p(lay+1,ist,i)
#define tau_level_r transmission_aux%thermal_path1%Tau_level_r(lay+1,ist,i)
#define tau_level transmission_aux%thermal_path1%Tau_level(lay+1,ist,i)

#define od_singlelayer_r transmission_aux%thermal_path1%Od_singlelayer_r(isti,lay,i)
#define od_singlelayer transmission_aux%thermal_path1%Od_singlelayer(isti,lay,i)

  !-------------------------------------------------------------------------------
  ! Initialise useful variables
  !-------------------------------------------------------------------------------

  nchanprof = SIZE(chanprof)
  nlayers = profiles(1)%nlayers
  nlevels = nlayers + 1

  do_scatt = opts%rt_ir%addclouds .OR. opts%rt_ir%addaerosl
  dom_ir = do_scatt .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom
  dom_vis = do_scatt .AND. opts%rt_ir%addsolar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom
  do_single_scatt = do_scatt .AND. dosolar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single
  keyradonly = opts%rt_ir%addaerosl .OR. opts%rt_ir%pc%addpc .OR. dom_ir .OR. dom_vis

  IF (dosolar) sateqsun(:,:) = (ABS(raytracing%pathsat(:,:) - raytracing%pathsun(:,:)) < realtol)

  DO i = 1, nchanprof
    cfraction(i) = aux_prof%s(prof)%cfraction
    cfraction_tl(i) = aux_prof_tl%s(prof)%cfraction
    pfraction(i) = aux_prof%s(prof)%pfraction_surf
  ENDDO

  DO i = 1, nchanprof
    ! case-1: surf lies above lev=nlevels
    iv3lev(i) = aux_prof%s(prof)%nearestlev_surf - 1   ! lowest lev above surf
    ! case-2: surf lies below lev=nlevels
    IF (pfraction(i) < 0._jprb) iv3lev(i) = iv3lev(i) + 1  ! iv3lev=iv2lev=lowest lev above surf

    iv2lev(i) = aux_prof%s(prof)%nearestlev_surf       ! highest lev below surf
    iv2lay(i) = iv2lev(i) - 1                          ! same layer as that numbered by  iv2 in RTTOV-9
    iv3lay(i) = iv3lev(i) - 1                          ! same layer as that numbered by  iv3 in RTTOV-9
  ENDDO

  IF (coef%id_sensor == sensor_id_po) THEN
    DO i = 1, nchanprof
      pol_id(i) = coef%fastem_polar(chan) + 1_jpim
    ENDDO
  ELSE
    pol_id(:) = 0_jpim
  ENDIF

  auxrad_stream_tl%cloudy = 0._jprb
  IF (dosolar) THEN
    auxrad_stream_tl%up_solar = 0._jprb
    auxrad_stream_tl%meanrad_up_solar = 0._jprb
    auxrad_stream_tl%down_solar = 0._jprb
    auxrad_stream_tl%meanrad_down_solar = 0._jprb
  ENDIF

  !----------------------------
  ! Calculate layer radiances
  !----------------------------
  IF (dothermal) CALL rttov_calcrad_tl(opts, chanprof, profiles, profiles_tl, coef, thermal, auxrad, auxrad_tl)

  !-------------------------------------
  ! Calculate atmospheric contribution
  !-------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) &
    CALL calc_atmospheric_radiance_tl(transmission_aux, transmission_aux_tl, auxrad, auxrad_tl, ircld, &
                                      auxrad_stream_tl)

  ! Scattering of the solar beam
  IF (do_single_scatt) &
    CALL  solar_scattering_air_tl(transmission_aux, transmission_aux_tl, ircld, raytracing, raytracing_tl, &
                                  transmission_scatt_ir_tl, diffuse_refl, auxrad_stream, auxrad_stream_tl)

  !-------------------------------------------------------------------------------
  ! Calculate near-surface layer contribution
  !-------------------------------------------------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) &
    CALL calc_near_surf_contribution_tl(transmission_aux, transmission_aux_tl, auxrad, auxrad_tl, &
                                        ircld, auxrad_stream_tl)

  ! Scattering of the solar beam
  IF (do_single_scatt) &
    CALL solar_scattering_near_surf_tl(transmission_aux, transmission_aux_tl, ircld, raytracing, &
                                       raytracing_tl, transmission_scatt_ir_tl, diffuse_refl, &
                                       auxrad_stream, auxrad_stream_tl)

  !-------------------------------------------------------------------------------
  ! Calculate clear-sky Rayleigh scattering contribution
  !-------------------------------------------------------------------------------
  IF (dosolar .AND. opts%rt_ir%rayleigh_single_scatt) &
    CALL solar_rayleigh_tl(raytracing, raytracing_tl, ircld, profiles, profiles_tl, profiles_dry, &
                           profiles_dry_tl, transmission_aux, transmission_aux_tl, auxrad_stream_tl)

  !-------------------------------------------------------------------------------
  ! Add thermal and solar atmospheric contributions to the clear and cloudy streams
  !-------------------------------------------------------------------------------
  DO i = 1, nchanprof
    IF (thermal(i) .AND. .NOT. dom_ir) THEN
      DO ist = 0, ircld%nstream(prof)
        IF (do_lambertian(i)) THEN
          auxrad_stream_tl%cloudy(ist,i) = &
              auxrad_stream_tl%meanrad_up(ist,i) + &
              (profiles(prof)%skin%specularity * &
               (auxrad_stream_tl%meanrad_down(ist,i) * tau_surf + &
                auxrad_stream%meanrad_down(ist,i) * tau_surf_tl) + &
               (1._jprb - profiles(prof)%skin%specularity) * &
               (auxrad_stream_tl%meanrad_down_p(ist,i) * tau_surf_p + &
                auxrad_stream%meanrad_down_p(ist,i) * tau_surf_p_tl)) * &
              diffuse_refl(i) * tau_surf + &
              (profiles(prof)%skin%specularity * &
               auxrad_stream%meanrad_down(ist,i) * tau_surf + &
               (1._jprb - profiles(prof)%skin%specularity) * &
               auxrad_stream%meanrad_down_p(ist,i) * tau_surf_p) * &
              (diffuse_refl_tl(i) * tau_surf + &
               diffuse_refl(i) * tau_surf_tl)
        ELSE
          auxrad_stream_tl%cloudy(ist,i) = &
              auxrad_stream_tl%meanrad_up(ist,i) + &
              tau_surf * (diffuse_refl(i) * &
              (auxrad_stream_tl%meanrad_down(ist,i) * tau_surf + &
              auxrad_stream%meanrad_down(ist,i) * &
              tau_surf_tl * 2._jprb) + &
              diffuse_refl_tl(i) * auxrad_stream%meanrad_down(ist,i) * &
              tau_surf)
        ENDIF
      ENDDO

      auxrad_stream_tl%up(iv2lay(i),0,i) = auxrad_stream_tl%meanrad_up(0,i)
    ENDIF

    IF (solar(i)) THEN
      refl_norm_scat = COS(profiles(prof)%zenangle * deg2rad) * pi_r

      DO ist = 0, ircld%nstream(prof)
        auxrad_stream_tl%cloudy(ist,i) = auxrad_stream_tl%cloudy(ist,i) + &
                          auxrad_stream_tl%meanrad_up_solar(ist,i) + &
                          transmission_aux%solar_path1%Tau_surf(ist,i) * refl_norm_scat * &
                          (diffuse_refl(i) * &
                            (auxrad_stream_tl%meanrad_down_solar(ist,i) * &
                            transmission_aux%solar_path1%Tau_surf(ist,i) + &
                            2._jprb * auxrad_stream%meanrad_down_solar(ist,i) * &
                            transmission_aux_tl%solar_path1%Tau_surf(ist,i)) + &
                          diffuse_refl_tl(i) * &
                          auxrad_stream%meanrad_down_solar(ist,i) * &
                          transmission_aux%solar_path1%Tau_surf(ist,i))
      ENDDO

      auxrad_stream_tl%up_solar(iv2lay(i),0,i) = auxrad_stream_tl%meanrad_up_solar(0,i)
    ENDIF
  ENDDO

  !-------------------------------------------------------------------------------
  ! Calculate surface emission contribution
  !-------------------------------------------------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) THEN
    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        DO ist = 0, ircld%nstream(prof)
          auxrad_stream_tl%cloudy(ist,i) = &
              auxrad_stream_tl%cloudy(ist,i) + &
              auxrad%skin(i) * (emissivity_tl(i)%emis_out * tau_surf + &
                                emissivity(i)%emis_out * tau_surf_tl) + &
              auxrad_tl%skin(i) * emissivity(i)%emis_out * tau_surf
        ENDDO
      ENDIF
    ENDDO
  ENDIF

  !-------------------------------------------------------------------------------
  ! Solar surface contribution
  !-------------------------------------------------------------------------------
  IF (dosolar .AND. .NOT. dom_vis) &
    CALL solar_surface_contribution_tl(transmission_aux, transmission_aux_tl, ircld, &
                                       reflectance%refl_out, reflectance_tl%refl_out, &
                                       auxrad_stream_tl)

  !-------------------------------------------------------------------------------
  ! Cosmic temperature correction
  !-------------------------------------------------------------------------------
  IF (addcosmic) THEN
    DO i = 1, nchanprof
      ist = 0_jpim
      IF (do_lambertian(i)) THEN
        auxrad_stream_tl%cloudy(ist,i) = auxrad_stream_tl%cloudy(ist,i) + &
                        auxrad%cosmic(i) * &
                        ((diffuse_refl_tl(i) * tau_surf + &
                          diffuse_refl(i) * tau_surf_tl) * &
                         (profiles(prof)%skin%specularity * tau_surf + &
                          (1._jprb - profiles(prof)%skin%specularity) * tau_surf_p) + &
                         diffuse_refl(i) * tau_surf * &
                         (profiles(prof)%skin%specularity * tau_surf_tl + &
                          (1._jprb - profiles(prof)%skin%specularity) * tau_surf_p_tl))
      ELSE
        auxrad_stream_tl%cloudy(ist,i) = auxrad_stream_tl%cloudy(ist,i) + &
                          auxrad%cosmic(i) * tau_surf * &
                         (diffuse_refl_tl(i) * tau_surf + &
                          diffuse_refl(i) * 2._jprb * tau_surf_tl)
      ENDIF
    ENDDO
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate overcast radiances
  !-------------------------------------------------------------------------------
  IF (.NOT. keyradonly) THEN
    ist = 0_jpim
  !cdir nodep
    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        DO lay = 1, nlayers
          lev = lay + 1
          rad_tl%overcast(lay,i) = auxrad_stream_tl%up(lay,ist,i) + &
                                   auxrad_tl%air(lev,i) * tau_level + &
                                   auxrad%air(lev,i) * tau_level_tl
        ENDDO
      ELSEIF (solar(i)) THEN
        IF (reflectance(i)%refl_cloud_top > 0) THEN
          refl = reflectance(i)%refl_cloud_top
        ELSE
          IF (coef%ff_cwn(chan) > overcast_albedo_wvn) THEN
            refl = overcast_albedo1 * pi_r
          ELSE
            refl = overcast_albedo2 * pi_r
          ENDIF
        ENDIF
        DO lay = 1, nlayers
          lev = lay + 1
          rad_tl%overcast(lay,i) = solar_spectrum(i) * refl / raytracing%pathsun(lay,prof) * &
                  (transmission_aux_tl%solar_path2%Tau_level(lev,ist,i) - &
                  transmission_aux%solar_path2%Tau_level(lev,ist,i) * &
                  raytracing_tl%pathsun(lay,prof) / raytracing%pathsun(lay,prof)) + &
                  auxrad_stream_tl%up_solar(lay,ist,i) + &
                  refl / raytracing%pathsat(lay,prof) * &
                  transmission_aux%solar_path1%Tau_level(lev,ist,i) * &
                  (auxrad_stream_tl%down_solar(lay,ist,i) * &
                  transmission_aux%solar_path1%Tau_level(lev,ist,i) - &
                  auxrad_stream%down_solar(lay,ist,i) * &
                  raytracing_tl%pathsat(lay,prof) / raytracing%pathsat(lay,prof) * &
                  transmission_aux%solar_path1%Tau_level(lev,ist,i) + &
                  auxrad_stream%down_solar(lay,ist,i) * &
                  2_jpim * transmission_aux_tl%solar_path1%Tau_level(lev,ist,i))
        ENDDO
      ENDIF
    ENDDO

    IF (dothermal) THEN
      DO i = 1, nchanprof
        IF (thermal(i)) THEN
          lay = iv2lay(i)
          rad_tl%overcast(lay,i) = auxrad_stream_tl%up(lay,ist,i) + &
                                    tau_surf_tl * auxrad%surfair(i) + &
                                    tau_surf    * auxrad_tl%surfair(i)
        ENDIF
      ENDDO
    ENDIF
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate total radiance
  !-------------------------------------------------------------------------------
  rad_tl%clear(1:nchanprof) = auxrad_stream_tl%cloudy(0,1:nchanprof)

  IF (do_scatt) THEN
    !---------------------------------------------------
    ! Calculate complex cloudy radiances
    !---------------------------------------------------
     DO i = 1, nchanprof
       IF (thermal(i) .AND. dom_ir .AND. .NOT. solar(i)) CYCLE

       DO ist = 1, ircld%nstream(prof)
         rad_tl%cloudy(i) = rad_tl%cloudy(i) + &
                  auxrad_stream_tl%cloudy(ist,i) * (ircld%xstr(ist+1,prof) - ircld%xstr(ist,prof)) + &
                  auxrad_stream%cloudy(ist,i) * (ircld_tl%xstr(ist+1,prof) - ircld_tl%xstr(ist,prof))
       ENDDO

       rad_tl%cloudy(i)= rad_tl%cloudy(i) + &
                         auxrad_stream_tl%cloudy(0,i) * ircld%xstrclr(prof) + &
                         auxrad_stream%cloudy(0,i) * ircld_tl%xstrclr(prof)
     ENDDO

     rad_tl%total(1:nchanprof) = rad_tl%cloudy(1:nchanprof)
  ELSE
    !---------------------------------------------------
    ! Calculate total radiance (clear case/simple cloud)
    !---------------------------------------------------
    IF (opts%rt_ir%pc%addpc) THEN
      rad_tl%total(1:nchanprof) = rad_tl%clear(1:nchanprof)
    ELSE

      DO i = 1, nchanprof
        lay = aux_prof%s(prof)%nearestlev_ctp - 1

        rad_tl%cloudy(i) = rad_tl%overcast(lay,i) + &
                     (rad_tl%overcast(lay-1,i) - rad_tl%overcast(lay,i)) * aux_prof%s(prof)%pfraction_ctp + &
                     (rad%overcast(lay-1,i) - rad%overcast(lay,i)) * aux_prof_tl%s(prof)%pfraction_ctp
      ENDDO

      rad_tl%total(1:nchanprof) = rad_tl%clear(1:nchanprof) + &
                                  cfraction(1:nchanprof)    * &
                                  (rad_tl%cloudy(1:nchanprof) - rad_tl%clear(1:nchanprof)) + &
                                  cfraction_tl(1:nchanprof) * (rad%cloudy(1:nchanprof) - rad%clear(1:nchanprof))
    ENDIF
  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_INTEGRATE_TL',1_jpim,ZHOOK_HANDLE)

CONTAINS

  SUBROUTINE calc_atmospheric_radiance_tl(transmission_aux, transmission_aux_tl, auxrad, &
                                          auxrad_tl, ircld, auxrad_stream_tl)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_radiance_aux),     INTENT(IN)    :: auxrad, auxrad_tl
    TYPE(rttov_ircld),            INTENT(IN)    :: ircld
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, ist, isti, lay
    REAL(jprb)    :: up_laym1, down_laym1, down_p_laym1
    REAL(jprb)    :: tau_lev_r_tl, tau_lay_r_tl, od_singlelayer_r_tl
    REAL(jprb)    :: tau_lev_p_r_tl, tau_lay_p_r_tl
    REAL(jprb)    :: b1_2, b2_2, b3_2, b1_tl, b2_tl, b3_tl
    REAL(jprb)    :: rad_air_avg(nlayers), rad_air_avg_tl(nlayers)
    REAL(jprb)    :: rad_air_diff(nlayers), rad_air_diff_tl(nlayers)
    REAL(jprb)    :: dtau(nlayers), dtau_tl(nlayers)

    DO i = 1, nchanprof
      IF (thermal(i)) THEN

        IF (do_lambertian(i) .OR. .NOT. opts%rt_all%rad_down_lin_tau) THEN
          rad_air_avg = 0.5_jprb * (auxrad%air(1:nlayers,i) + auxrad%air(2:nlevels,i))
          rad_air_avg_tl = 0.5_jprb * (auxrad_tl%air(1:nlayers,i) + auxrad_tl%air(2:nlevels,i))
        ENDIF
        rad_air_diff = auxrad%air(2:nlevels,i) - auxrad%air(1:nlayers,i)
        rad_air_diff_tl = auxrad_tl%air(2:nlevels,i) - auxrad_tl%air(1:nlayers,i)

        DO ist = 0, ircld%nstream(prof)
          up_laym1 = 0._jprb
          down_laym1 = 0._jprb
          down_p_laym1 = 0._jprb

          lay = 1
          tau_lay_r_tl = -tau_layer_tl * tau_layer_r**2
          IF (do_lambertian(i)) THEN
            tau_lay_p_r_tl = -tau_layer_p_tl * tau_layer_p_r**2
          ENDIF
          dtau = transmission_aux%thermal_path1%Tau_level(1:nlayers,ist,i) - &
                 transmission_aux%thermal_path1%Tau_level(2:nlevels,ist,i)
          dtau_tl = transmission_aux_tl%thermal_path1%Tau_level(1:nlayers,ist,i) - &
                    transmission_aux_tl%thermal_path1%Tau_level(2:nlevels,ist,i)

          DO lay = 1, nlayers
            isti = ircld%icldarr(ist,lay,prof)

            od_singlelayer_r_tl = -od_singlelayer_tl * od_singlelayer_r**2
            B1_TL = auxrad_tl%air(lay,i) * dtau(lay) + &
                    auxrad%air(lay,i) * dtau_tl(lay)
            B2_TL = rad_air_diff_tl(lay) * tau_level  + &
                    rad_air_diff(lay) * tau_level_tl
            B3_TL = od_singlelayer_r * &
                    (rad_air_diff_tl(lay) * dtau(lay) + &
                    rad_air_diff(lay) * dtau_tl(lay)) + &
                    od_singlelayer_r_tl * (rad_air_diff(lay) * dtau(lay))

            auxrad_stream_tl%up(lay,ist,i) = up_laym1 + transmission_aux%fac1(lay,ist,i) * &
                    (B1_TL - B2_TL + B3_TL)

            IF (do_lambertian(i)) THEN
              tau_lev_p_r_tl = -tau_level_p_tl * tau_level_p_r**2
              auxrad_stream_tl%down_p(lay,ist,i) = down_p_laym1 + transmission_aux%fac1(lay,ist,i) * &
                transmission_aux%thermal_path1%fac2(lay+1,ist,i) * &
                (rad_air_avg_tl(lay) * &
                 ((tau_level_p_r) - (tau_layer_p_r)) + &
                 rad_air_avg(lay) * &
                 (tau_lev_p_r_tl - tau_lay_p_r_tl))
              tau_lay_p_r_tl = tau_lev_p_r_tl
            ENDIF
            tau_lev_r_tl = -tau_level_tl * tau_level_r**2
            IF (opts%rt_all%rad_down_lin_tau) THEN
              B1_2 = auxrad%air(lay,i) * dtau(lay)
              B2_2 = rad_air_diff(lay) * tau_level
              B3_2 = rad_air_diff(lay) * dtau(lay) * od_singlelayer_r
              auxrad_stream_tl%down(lay,ist,i) = down_laym1 + transmission_aux%fac1(lay,ist,i) * &
                      transmission_aux%thermal_path1%fac2(lay+1,ist,i) * &
                      (tau_level_r * ( &
                      (B1_TL - B3_TL) * (tau_layer_r) + &
                      (B2_TL * tau_level_r + &
                      B2_2 * (2._jprb * tau_lev_r_tl))) + &
                      (B1_2 - B3_2)  * (tau_lay_r_tl * tau_level_r + &
                      tau_lev_r_tl * tau_layer_r))
            ELSE
              auxrad_stream_tl%down(lay,ist,i) = down_laym1 + transmission_aux%fac1(lay,ist,i) * &
                transmission_aux%thermal_path1%fac2(lay+1,ist,i) * &
                (rad_air_avg_tl(lay) * &
                 ((tau_level_r) - (tau_layer_r)) + &
                 rad_air_avg(lay) * &
                 (tau_lev_r_tl - tau_lay_r_tl))
            ENDIF
            tau_lay_r_tl = tau_lev_r_tl

            up_laym1   = auxrad_stream_tl%up(lay,ist,i)
            down_laym1 = auxrad_stream_tl%down(lay,ist,i)
            IF (do_lambertian(i)) down_p_laym1 = auxrad_stream_tl%down_p(lay,ist,i)
          ENDDO
        ENDDO
      ENDIF
    ENDDO

    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        DO ist = 0, ircld%nstream(prof)
          WHERE (auxrad_stream%down_ref(:,ist,i) < 0._jprb)
            auxrad_stream_tl%down(:,ist,i) = 0._jprb
          ENDWHERE
        ENDDO
        IF (do_lambertian(i)) THEN
          DO ist = 0, ircld%nstream(prof)
            WHERE (auxrad_stream%down_p_ref(:,ist,i) < 0._jprb)
              auxrad_stream_tl%down_p(:,ist,i) = 0._jprb
            ENDWHERE
          ENDDO
        ENDIF
      ENDIF
    ENDDO
  END SUBROUTINE calc_atmospheric_radiance_tl

  SUBROUTINE calc_near_surf_contribution_tl(transmission_aux, transmission_aux_tl, auxrad, &
                                            auxrad_tl, ircld, auxrad_stream_tl)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_radiance_aux),     INTENT(IN)    :: auxrad, auxrad_tl
    TYPE(rttov_ircld),            INTENT(IN)    :: ircld
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, ist, lay, lev
    REAL(jprb)    :: rad_tmp, rad_tmp_tl, rad_tmp_p_tl
    REAL(jprb)    :: tau_lev_r_tl, tau_surf_r_tl
    REAL(jprb)    :: tau_lev_p_r_tl, tau_surf_p_r_tl
    REAL(jprb)    :: rad_air_avg, rad_air_avg_tl
    REAL(jprb)    :: rad_air_diff, rad_air_diff_tl

#define B1_3 (auxrad%air(lev,i) * (tau_level  - tau_surf))
#define B2_3 (rad_air_diff * tau_surf)
#define B3_3 (rad_air_diff * (tau_level - tau_surf) * (transmission_aux%thermal_path1%od_sfrac_r(ist,i)))
#define B1_TL1 (auxrad_tl%air(lev,i) * (tau_level  - tau_surf))
#define B1_TL2 (auxrad%air(lev,i) * (tau_level_tl - tau_surf_tl))
#define B2_TL1 (tau_surf * rad_air_diff_tl)
#define B2_TL2 (tau_surf_tl * rad_air_diff)
#define B3_TL1 (rad_air_diff * (tau_level_tl - tau_surf_tl))
#define B3_TL2 (rad_air_diff_tl * (tau_level - tau_surf))
#define B3_TL3 (-B3_3 * transmission_aux_tl%thermal_path1%od_sfrac(ist,i))
#define B3_TL4 (transmission_aux%thermal_path1%od_sfrac_r(ist,i))

    DO i = 1, nchanprof
      IF (.NOT. thermal(i)) CYCLE
      lay = iv3lay(i)
      lev = iv3lev(i)

      rad_air_avg = 0.5_jprb * (auxrad%surfair(i) + auxrad%air(lev,i))
      rad_air_avg_tl = 0.5_jprb * (auxrad_tl%surfair(i) + auxrad_tl%air(lev,i))
      rad_air_diff = auxrad%surfair(i) - auxrad%air(lev,i)
      rad_air_diff_tl = auxrad_tl%surfair(i) - auxrad_tl%air(lev,i)

      DO ist = 0, ircld%nstream(prof)

        IF (transmission_aux%thermal_path1%od_sfrac(ist,i) < min_od .OR. &
            (opts%rt_all%dtau_test .AND. &
             (tau_level - tau_surf) < min_od)) THEN

          ! small optical depth or optical depth change set radiance to zero
          auxrad_stream_tl%meanrad_up(ist,i)   = auxrad_stream_tl%up(lay,ist,i)
          auxrad_stream_tl%meanrad_down(ist,i) = auxrad_stream_tl%down(lay,ist,i)
          IF (do_lambertian(i)) THEN
            auxrad_stream_tl%meanrad_down_p(ist,i) = auxrad_stream_tl%down_p(lay,ist,i)
          ENDIF

        ELSE

          ! PGF90 compatibility for b3_tl macros
          auxrad_stream_tl%meanrad_up(ist,i) = &
          B1_TL1 + &
          B1_TL2 - &
          (B2_TL1 + &
          B2_TL2) + &
(B3_TL1 + &
          B3_TL2 + &
B3_TL3) * &
          B3_TL4

          rad_tmp_tl = 0.
          rad_tmp_p_tl = 0.
          IF (tau_surf > min_tau) THEN
            IF (do_lambertian(i)) THEN
              tau_lev_p_r_tl = -tau_level_p_tl * tau_level_p_r**2
              tau_surf_p_r_tl = -tau_surf_p_tl * tau_surf_p_r**2
              rad_tmp_p_tl = &
                transmission_aux%surf_fac(ist,i) * &
                (rad_air_avg_tl * &
                 ((tau_surf_p_r) - (tau_level_p_r)) + &
                 rad_air_avg * &
                 ((tau_surf_p_r_tl) - (tau_lev_p_r_tl)))
            ENDIF
            IF (opts%rt_all%rad_down_lin_tau) THEN
              rad_tmp = transmission_aux%surf_fac(ist,i) * &
              (B1_3 - &
              B3_3) * &
              (tau_level_r * tau_surf_r) + &
              B2_3 * (tau_surf_r)**2_jpim

              rad_tmp_tl = tau_surf_r * ( &
                  (tau_level * ((B1_TL1 + &
                  B1_TL2) - &
(B3_TL1 + &
                  B3_TL2 + &
B3_TL3) * &
                  B3_TL4) - &
                  (B1_3 - &
                  B3_3) * &
                  tau_level_tl) * &
                  tau_level_r**2_jpim + &
                  ((B2_TL1 + &
                  B2_TL2) * &
                  tau_surf - B2_3 * tau_surf_tl) * &
                  tau_surf_r**2_jpim - &
                  rad_tmp * tau_surf_tl)
            ELSE
              tau_lev_r_tl = -tau_level_tl * tau_level_r**2
              tau_surf_r_tl = -tau_surf_tl * tau_surf_r**2
              rad_tmp_tl = &
                transmission_aux%surf_fac(ist,i) * &
                (rad_air_avg_tl * &
                 ((tau_surf_r) - &
                  (tau_level_r)) + &
                 rad_air_avg * &
                 ((tau_surf_r_tl) - (tau_lev_r_tl)))
            ENDIF
          ENDIF

          IF (pol_id(i) >= 6_jpim) auxrad_stream_tl%meanrad_up(ist,i) = 0._jprb

          IF (do_lambertian(i)) THEN
            auxrad_stream_tl%meanrad_down_p(ist,i) = auxrad_stream_tl%down_p(lay,ist,i) + rad_tmp_p_tl
          ENDIF
          auxrad_stream_tl%meanrad_down(ist,i) = auxrad_stream_tl%down(lay,ist,i) + rad_tmp_tl
          auxrad_stream_tl%meanrad_up(ist,i)   = auxrad_stream_tl%up(lay,ist,i) + &
                                                 auxrad_stream_tl%meanrad_up(ist,i)
        ENDIF
        IF (pol_id(i) >= 6_jpim) auxrad_stream_tl%meanrad_up(ist,i) = 0._jprb
      ENDDO
    ENDDO
  END SUBROUTINE calc_near_surf_contribution_tl

  SUBROUTINE solar_scattering_air_tl(transmission_aux, transmission_aux_tl, ircld, raytracing, raytracing_tl, &
                                     transmission_scatt_ir_tl, refl, auxrad_stream, auxrad_stream_tl)

    TYPE(rttov_transmission_aux),      INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_ircld),                 INTENT(IN)    :: ircld
    TYPE(rttov_raytracing),            INTENT(IN)    :: raytracing, raytracing_tl
    TYPE(rttov_transmission_scatt_ir), INTENT(IN)    :: transmission_scatt_ir_tl
    REAL(jprb),                        INTENT(IN)    :: refl(:)
    TYPE(rttov_radiance_aux),          INTENT(IN)    :: auxrad_stream
    TYPE(rttov_radiance_aux),          INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, ist, isti, lay, su
    REAL(jprb)    :: temp_tl(1:nlayers,0:maxnstreams)
    REAL(jprb)    :: fac1_2_tl(0:1,1:nlayers), fac3_2_tl(1:nlayers), fac4_2_tl(0:1,1:nlayers), &
                     fac5_2_tl(0:1,1:nlayers), fac6_2_tl(0:1,1:nlayers), fac7_2_tl(1:nlayers)

#define fac1_2 auxrad_stream%Fac1_2(isti,lay,i)
#define fac3_2 auxrad_stream%Fac3_2(lay,i)
#define fac4_2 auxrad_stream%Fac4_2(isti,lay,i)
#define fac5_2 auxrad_stream%Fac5_2(isti,lay,i)
#define fac6_2 auxrad_stream%Fac6_2(isti,lay,i)
#define fac7_2 auxrad_stream%Fac7_2(lay,i)
#define dfac54_2 (fac5_2 - fac4_2)

#define fac1_2_tl Fac1_2_tl(isti,lay)
#define fac3_2_tl Fac3_2_tl(lay)
#define fac4_2_tl Fac4_2_tl(isti,lay)
#define fac5_2_tl Fac5_2_tl(isti,lay)
#define fac6_2_tl Fac6_2_tl(isti,lay)
#define fac7_2_tl Fac7_2_tl(lay)
#define dfac54_2_tl (fac5_2_tl - fac4_2_tl)

#define tausun2_layer_tl transmission_aux_tl%solar_path2%Tau_level(lay,ist,i)
#define tausun2_level_tl transmission_aux_tl%solar_path2%Tau_level(lay+1,ist,i)
#define tausun2_layer transmission_aux%solar_path2%Tau_level(lay,ist,i)
#define tausun2_level transmission_aux%solar_path2%Tau_level(lay+1,ist,i)

#define tausun1_layer_tl transmission_aux_tl%solar_path1%Tau_level(lay,ist,i)
#define tausun1_level_tl transmission_aux_tl%solar_path1%Tau_level(lay+1,ist,i)
#define tausun1_layer transmission_aux%solar_path1%Tau_level(lay,ist,i)
#define tausun1_level transmission_aux%solar_path1%Tau_level(lay+1,ist,i)
#define tausun1_level_r transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i)
#define tausun1_surf transmission_aux%solar_path1%Tau_surf(ist,i)
#define tausun1_surf_r transmission_aux%solar_path1%Tau_surf_r(ist,i)
#define tausun1_surf_tl transmission_aux_tl%solar_path1%Tau_surf(ist,i)

    su = 0
    IF (opts%rt_ir%addclouds) su = 1

    DO i = 1, nchanprof
      IF (.NOT. solar(i)) CYCLE

      Fac6_2_tl(0:su,:) = solar_spectrum(i) * z4pi_r * transmission_scatt_ir_tl%phdo(0:su,:,i)
      Fac1_2_tl(0:su,:) = solar_spectrum(i) * z4pi_r * transmission_scatt_ir_tl%phup(0:su,:,i)

      Fac4_2_tl(0:su,:) = -transmission_aux_tl%solar_path2%Od_singlelayer(0:su,:,i) * auxrad_stream%Fac4_2(0:su,:,i)
      Fac5_2_tl(0:su,:) = -transmission_aux_tl%solar_path1%Od_singlelayer(0:su,:,i) * auxrad_stream%Fac5_2(0:su,:,i)

      Fac3_2_tl(:) = raytracing_tl%pathsat(:,prof) / raytracing%patheff(:,prof) - &
                     raytracing%pathsat(:,prof) * raytracing_tl%patheff(:,prof) / &
                     raytracing%patheff(:,prof)**2_jpim

    !----------------Upward single scattering of the solar beam-----------------------

      DO ist = 0, ircld%nstream(prof)
        DO lay = 1, nlayers
          isti = ircld%icldarr(ist,lay,prof)
          auxrad_stream_tl%up_solar(lay,ist,i) = (tausun2_layer - tausun2_level) * &
                (fac1_2_tl * transmission_scatt_ir%ssa_solar(isti,lay,i) * fac3_2 + &
                 transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * fac3_2 * fac1_2 + &
                 fac3_2_tl * fac1_2 * transmission_scatt_ir%ssa_solar(isti,lay,i)) + &
                (fac1_2 * transmission_scatt_ir%ssa_solar(isti,lay,i) * fac3_2 * &
                (tausun2_layer_tl - tausun2_level_tl))
        ENDDO
      ENDDO

      DO ist = 0, ircld%nstream(prof)
        DO lay = 2, nlayers
          auxrad_stream_tl%up_solar(lay,ist,i) = auxrad_stream_tl%up_solar(lay,ist,i) + &
                                                 auxrad_stream_tl%up_solar(lay-1,ist,i)
        ENDDO
      ENDDO

      !-------------------Downward single scattering of the solar beam------------------

      IF (refl(i) > 0._jprb) THEN
        DO lay = 1, nlayers
          IF (.NOT. sateqsun(lay,prof)) THEN
            fac7_2_tl = (raytracing%pathsun(lay,prof) * raytracing_tl%pathsat(lay,prof) - &
                         raytracing_tl%pathsun(lay,prof) * raytracing%pathsat(lay,prof)) / &
                        (raytracing%pathsun(lay,prof) - raytracing%pathsat(lay,prof))**2_jpim
          ENDIF
        ENDDO

        DO ist = 0, ircld%nstream(prof)
          DO lay = 1, nlayers
            isti = ircld%icldarr(ist,lay,prof)
            ! nested multiplication of derivative
            IF (.NOT. sateqsun(lay,prof)) THEN
              temp_tl(lay,ist) = &
                transmission_aux%solar_path1%fac2(lay+1,ist,i) * &
                transmission_aux%solar_path1%Tau_level_r(lay,ist,i) * &
                transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i) * &
                 (fac6_2_tl * &
                  transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                  fac7_2 * &
                  dfac54_2 * &
                  tausun2_layer + &
                  fac6_2 * (&
                    transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * &
                    fac7_2 * &
                    dfac54_2 * &
                    tausun2_layer + &
                    transmission_scatt_ir%ssa_solar(isti,lay,i) * (&
                      fac7_2_tl * &
                      dfac54_2 * &
                      tausun2_layer + &
                      fac7_2 * (&
                        dfac54_2_tl * &
                        tausun2_layer + &
                        dfac54_2 * (&
                          (tausun2_layer_tl - &
                          (tausun2_layer * &
                          transmission_aux%solar_path1%Tau_level_r(lay,ist,i) * &
                          transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i)) * &
                          (tausun1_layer_tl * tausun1_level + &
                          tausun1_layer * tausun1_level_tl)))))))
            ELSE
              temp_tl(lay,ist) = &
                transmission_aux%solar_path1%fac2(lay+1,ist,i) * &
                transmission_aux%solar_path1%Tau_level_r(lay,ist,i) * &
                transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i) * &
                 (fac6_2_tl * &
                  transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                  fac4_2 * &
                  transmission_aux%solar_path2%Od_singlelayer(isti,lay,i) * &
                  tausun2_layer + &
                  fac6_2 * (&
                    transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * &
                    fac4_2 * &
                    transmission_aux%solar_path2%Od_singlelayer(isti,lay,i) * &
                    tausun2_layer + &
                    transmission_scatt_ir%ssa_solar(isti,lay,i) * (&
                      fac4_2_tl * &
                      transmission_aux%solar_path2%Od_singlelayer(isti,lay,i) * &
                      tausun2_layer + &
                      fac4_2 * (&
                        transmission_aux_tl%solar_path2%Od_singlelayer(isti,lay,i) * &
                        tausun2_layer + &
                        transmission_aux%solar_path2%Od_singlelayer(isti,lay,i) * (&
                          (tausun2_layer_tl - &
                          (tausun2_layer * &
                          transmission_aux%solar_path1%Tau_level_r(lay,ist,i) * &
                          transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i)) * &
                          (tausun1_layer_tl * tausun1_level + &
                          tausun1_layer * tausun1_level_tl)))))))
            ENDIF
          ENDDO
        ENDDO

        DO ist = 0, ircld%nstream(prof)
          lay = 1_jpim
          IF (auxrad_stream%down_ref_solar(lay,ist,i) < 0._jprb) THEN
            auxrad_stream_tl%down_solar(lay,ist,i) = 0._jprb
          ELSE
            auxrad_stream_tl%down_solar(lay,ist,i) = temp_tl(lay,ist)
          ENDIF

          DO lay = 2, nlayers
            temp_tl(lay,ist) = temp_tl(lay-1,ist) + temp_tl(lay,ist)
            IF (auxrad_stream%down_ref_solar(lay,ist,i) < 0._jprb) THEN
              auxrad_stream_tl%down_solar(lay,ist,i) = 0._jprb
            ELSE
              auxrad_stream_tl%down_solar(lay,ist,i) = temp_tl(lay,ist)
            ENDIF
          ENDDO
        ENDDO
      ENDIF ! refl(i) > 0.
    ENDDO
  END SUBROUTINE solar_scattering_air_tl

  SUBROUTINE solar_scattering_near_surf_tl(transmission_aux, transmission_aux_tl, ircld, raytracing, &
                                           raytracing_tl, transmission_scatt_ir_tl, refl, &
                                           auxrad_stream, auxrad_stream_tl)

    TYPE(rttov_transmission_aux),      INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_ircld),                 INTENT(IN)    :: ircld
    TYPE(rttov_raytracing),            INTENT(IN)    :: raytracing, raytracing_tl
    TYPE(rttov_transmission_scatt_ir), INTENT(IN)    :: transmission_scatt_ir_tl
    REAL(jprb),                        INTENT(IN)    :: refl(:)
    TYPE(rttov_radiance_aux),          INTENT(IN)    :: auxrad_stream
    TYPE(rttov_radiance_aux),          INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, ist, isti, lay, lev, lay1
    REAL(jprb) :: fac1_3_tl, fac3_3_tl, fac4_3_tl(0:maxnstreams), &
                  fac5_3_tl(0:maxnstreams), fac6_3_tl, fac7_3_tl

#define fac4_3 auxrad_stream%Fac4_3(ist,i)
#define fac5_3 auxrad_stream%Fac5_3(ist,i)
#define dfac54_3 (fac5_3 - fac4_3)

#define dfac54_3_tl (fac5_3_tl(ist) - fac4_3_tl(ist))

    DO i = 1, nchanprof
      IF (.NOT. solar(i)) CYCLE

      lay = iv3lay(i)
      lev = iv3lev(i)

      IF (pfraction(i) < 0._jprb) THEN
         lay1 = lay
      ELSE
         lay1 = lay + 1_jpim
      ENDIF

      DO ist = 0, ircld%nstream(prof)
        isti = ircld%icldarr(ist,lay,prof)
        fac4_3_tl(ist) = -transmission_aux_tl%solar_path2%od_sfrac(ist,i) * fac4_3 !(exp(-x))'=-exp(-x)
        fac5_3_tl(ist) = -transmission_aux_tl%solar_path1%od_sfrac(ist,i) * fac5_3
      ENDDO

      fac3_3_tl = raytracing_tl%pathsat(lay,prof) / raytracing%patheff(lay,prof) - &
                  raytracing%pathsat(lay,prof) * raytracing_tl%patheff(lay,prof) / &
                  raytracing%patheff(lay,prof)**2_jpim

      !--------------Upward single scattering of the solar beam-------------------------

      DO ist = 0, ircld%nstream(prof)
        isti = ircld%icldarr(ist,lay,prof)
        fac1_3_tl = solar_spectrum(i) * z4pi_r * transmission_scatt_ir_tl%phup(isti,lay,i)

        auxrad_stream_tl%meanrad_up_solar(ist,i) = &
           fac1_3_tl * transmission_scatt_ir%ssa_solar(isti,lay,i) * fac3_2 * &
           (tausun2_level - transmission_aux%solar_path2%Tau_surf(ist,i)) + &
            fac1_2 * (transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * fac3_2 * &
           (tausun2_level - transmission_aux%solar_path2%Tau_surf(ist,i)) + &
            transmission_scatt_ir%ssa_solar(isti,lay,i) * (fac3_3_tl  * &
           (tausun2_level - transmission_aux%solar_path2%Tau_surf(ist,i)) + &
            fac3_2 * (&
           (tausun2_level_tl - transmission_aux_tl%solar_path2%Tau_surf(ist,i)))))
      ENDDO

      DO ist = 0, ircld%nstream(prof)
        auxrad_stream_tl%meanrad_up_solar(ist,i)   = auxrad_stream_tl%up_solar(lay,ist,i)   + &
                                                     auxrad_stream_tl%meanrad_up_solar(ist,i)
      ENDDO

      !--------------Downward single scattering of the solar beam-----------------------

      IF (refl(i) > 0._jprb) THEN
        IF (.NOT. sateqsun(lay1,prof)) THEN
          fac7_3_tl = (raytracing%pathsun(lay1,prof)    * raytracing_tl%pathsat(lay1,prof)  - &
                       raytracing_tl%pathsun(lay1,prof) * raytracing%pathsat(lay1,prof)) / &
                      (raytracing%pathsun(lay1,prof) - raytracing%pathsat(lay1,prof))**2

          DO ist = 0, ircld%nstream(prof)
            isti = ircld%icldarr(ist,lay,prof)
            fac6_3_tl = solar_spectrum(i) * z4pi_r * transmission_scatt_ir_tl%phdo(isti,lay,i)

            auxrad_stream_tl%meanrad_down_solar(ist,i) = transmission_aux%solar_path1%fac2(lev,ist,i) * &
                        (tausun1_level_r * tausun1_surf_r) * &
                         (fac6_3_tl * transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                         auxrad_stream%Fac7_2(lay1,i) * &
                         dfac54_3 * tausun2_level + &
                         fac6_2 * (&
                                  transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * auxrad_stream%Fac7_2(lay1,i) * &
                                  dfac54_3 * tausun2_level + &
                                          transmission_scatt_ir%ssa_solar(isti,lay,i) * (&
                                           fac7_3_tl * dfac54_3 * tausun2_level + &
                                                   auxrad_stream%Fac7_2(lay1,i) * (&
                                                         dfac54_3_tl * tausun2_level + &
                                                            dfac54_3 * (&
                        (tausun2_level_tl - &
                        (tausun2_level * (tausun1_level_r * tausun1_surf_r))*&
                        (tausun1_level_tl * tausun1_surf + &
                         tausun1_level * tausun1_surf_tl)))))))
          ENDDO
        ELSE
          DO ist = 0, ircld%nstream(prof)
            isti = ircld%icldarr(ist,lay,prof)
            fac6_3_tl = solar_spectrum(i) * z4pi_r * transmission_scatt_ir_tl%phdo(isti,lay,i)

            auxrad_stream_tl%meanrad_down_solar(ist,i) = transmission_aux%solar_path1%fac2(lev,ist,i) * &
                        (tausun1_level_r * tausun1_surf_r) * &
                         (fac6_3_tl * transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                         fac4_3 * transmission_aux%solar_path2%od_sfrac(ist,i) * &
                         tausun2_level + &
                           fac6_2 * (&
                             transmission_scatt_ir_tl%ssa_solar(isti,lay,i) * fac4_3 * &
                             transmission_aux%solar_path2%od_sfrac(ist,i) * &
                             tausun2_level + &
                               transmission_scatt_ir%ssa_solar(isti,lay,i) * (&
                                 fac4_3_tl(ist) * transmission_aux%solar_path2%od_sfrac(ist,i) * &
                                 tausun2_level + &
                                   fac4_3 * (&
                                     transmission_aux_tl%solar_path2%od_sfrac(ist,i) * &
                                     tausun2_level + &
                                     transmission_aux%solar_path2%od_sfrac(ist,i) * (&
                        (tausun2_level_tl - &
                        (tausun2_level * (tausun1_level_r * tausun1_surf_r)) * &
                        (tausun1_level_tl * tausun1_surf + &
                        tausun1_level * tausun1_surf_tl)))))))

          ENDDO
        ENDIF

        DO ist = 0, ircld%nstream(prof)
          auxrad_stream_tl%meanrad_down_solar(ist,i) = auxrad_stream_tl%down_solar(lay,ist,i) + &
                                                       auxrad_stream_tl%meanrad_down_solar(ist,i)

          IF (auxrad_stream%meanrad_down_solar(ist,i) < 0._jprb) THEN
            auxrad_stream_tl%meanrad_down_solar(ist,i) = 0._jprb
          ENDIF
        ENDDO
      ENDIF ! refl(i) > 0.
    ENDDO
  END SUBROUTINE solar_scattering_near_surf_tl

  SUBROUTINE solar_rayleigh_tl(raytracing, raytracing_tl, ircld, profiles, profiles_tl, &
                               profiles_dry, profiles_dry_tl, transmission_aux, &
                               transmission_aux_tl, auxrad_stream_tl)

    TYPE(rttov_raytracing),       INTENT(IN)    :: raytracing, raytracing_tl
    TYPE(rttov_ircld),            INTENT(IN)    :: ircld
    TYPE(rttov_profile),          INTENT(IN)    :: profiles(:), profiles_tl(:)
    TYPE(rttov_profile),          INTENT(IN)    :: profiles_dry(:), profiles_dry_tl(:)
    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, ist, lay, lev
    REAL(jprb) :: wlm, ss_param, v_h2o, v_h2o_dry, Mwet
    REAL(jprb) :: cossat, cossol, cosazi, cosscata_term1, cosscata_term2, cosscata
    REAL(jprb) :: ray_phase, solar_src, solar_src_updn
    REAL(jprb) :: v_h2o_tl, v_h2o_dry_tl, Mwet_tl, plev_tl, plev1_tl, dp_tl
    REAL(jprb) :: cosscata_term1_tl, cosscata_term2_tl, cosscata_tl
    REAL(jprb) :: ray_phase_tl, solar_src_tl, solar_src_updn_tl
    REAL(jprb) :: rayrad_up_tl(0:nlayers,0:maxnstreams), rayrad_dn_tl(0:nlayers,0:maxnstreams)

    ! The scattering cross-section calculation is based on Bucholzt '95.
    ! The phase function could be made to account for depolarisation.
    ! The solar geometry is approximated using the sun-surface path values,
    ! and similarly for the sun-level-satellite transmittances.

    ! Rayleigh scattering currently only included for channels less than 2um (ray_min_wvn).

    DO i = 1, nchanprof
      IF (.NOT. solar(i) .OR. coef%ff_cwn(chan) < ray_min_wvn) CYCLE

      ! Calculate layer-independent scattering parameter
      wlm = 10000._jprb / coef%ff_cwn(chan)    ! Wavelength in microns

      IF (wlm < ray_scs_wlm) THEN
        ss_param = ray_scs_a1 * wlm ** (ray_scs_b1 + ray_scs_c1 * wlm + ray_scs_d1/wlm)
      ELSE
        ss_param = ray_scs_a2 * wlm ** (ray_scs_b2 + ray_scs_c2 * wlm + ray_scs_d2/wlm)
      ENDIF
      ss_param = ss_param * 0.01_jprb ** 2_jpim * na * z4pi_r / gravity

      rayrad_up_tl(0,:) = 0._jprb
      rayrad_dn_tl(0,:) = 0._jprb

      ! Sum contributions from atmospheric layers
      DO lev = 2, nlevels
        lay = lev - 1_jpim

        ! Layer H2O by volume as fraction:
        v_h2o_dry = 0.5_jprb * (profiles_dry(prof)%q(lev-1) + profiles_dry(prof)%q(lev)) * 1.E-6_jprb
        v_h2o_dry_tl = 0.5_jprb * (profiles_dry_tl(prof)%q(lev-1) + profiles_dry_tl(prof)%q(lev)) * 1.E-6_jprb
        v_h2o = v_h2o_dry / (1._jprb + v_h2o_dry)
        v_h2o_tl = v_h2o_dry_tl * v_h2o * (1._jprb - v_h2o / (1._jprb + v_h2o_dry)) / v_h2o_dry

        ! Average molar weight of wet air for the layer (kg)
        Mwet = ((1._jprb - v_h2o) * Mair + v_h2o * Mh2o) * 1.E-3_jprb
        Mwet_tl = v_h2o_tl * (Mh2o - Mair) * 1.E-3_jprb

        ! cosine of scattering angle - raytracing%zasat/zasun contain the sine of the angles
        ! NB there are no perturbations around the profile angles, but the raytracing angles
        !    are dependent on atmospheric parameters.
        cossat = 1._jprb - raytracing%zasat(lay, prof) * raytracing%zasat(lay, prof)
        cossol = 1._jprb - raytracing%zasun(lay, prof) * raytracing%zasun(lay, prof)
        cosscata_term1 = SQRT(cossat * cossol)
        cosazi = COS((profiles(prof)%azangle - profiles(prof)%sunazangle)*deg2rad)
        cosscata_term2 = raytracing%zasat(lay, prof) * raytracing%zasun(lay, prof) * cosazi
        solar_src = solar_spectrum(i) * ss_param * &
              (profiles(prof)%p(lev) - profiles(prof)%p(lev-1)) * 100._jprb * &
              raytracing%pathsat(lay, prof) / Mwet

        cosscata = - cosscata_term1 - cosscata_term2
        ray_phase = 0.75_jprb * (1._jprb + cosscata * cosscata)
        solar_src_updn = solar_src * ray_phase

        cosscata_term1_tl = -1._jprb / cosscata_term1 * &
                            (raytracing_tl%zasat(lay, prof) * raytracing%zasat(lay, prof) * cossol + &
                             raytracing_tl%zasun(lay, prof) * raytracing%zasun(lay, prof) * cossat)
        cosscata_term2_tl = raytracing_tl%zasat(lay, prof) * raytracing%zasun(lay, prof) * cosazi + &
                            raytracing_tl%zasun(lay, prof) * raytracing%zasat(lay, prof) * cosazi

        IF (opts%interpolation%lgradp) THEN
          plev_tl = profiles_tl(prof)%p(lev)
          plev1_tl = profiles_tl(prof)%p(lev-1)
        ELSE
          plev_tl = 0._jprb
          plev1_tl = 0._jprb
        ENDIF

        solar_src_tl = solar_spectrum(i) * ss_param * &
                 ((plev_tl - plev1_tl) * 100._jprb * &
                 raytracing%pathsat(lay, prof) / Mwet + &
                 (profiles(prof)%p(lev) - profiles(prof)%p(lev-1)) * 100._jprb * &
                 raytracing_tl%pathsat(lay, prof) / Mwet + &
                 (profiles(prof)%p(lev) - profiles(prof)%p(lev-1)) * 100._jprb * &
                 raytracing%pathsat(lay, prof) * (-1._jprb) * Mwet_tl / (Mwet * Mwet))

        cosscata_tl = - cosscata_term1_tl - cosscata_term2_tl
        ray_phase_tl = 2._jprb * 0.75_jprb * cosscata_tl * cosscata
        solar_src_updn_tl = solar_src_tl * ray_phase + solar_src * ray_phase_tl

        DO ist = 0, ircld%nstream(prof)
          rayrad_up_tl(lay,ist) = rayrad_up_tl(lay-1,ist) + &
                                  transmission_aux_tl%solar_path2%Tau_level(lev-1,ist,i) * solar_src_updn + &
                                  transmission_aux%solar_path2%Tau_level(lev-1,ist,i) * solar_src_updn_tl

          IF (transmission_aux%solar_path1%Tau_level(lev-1,ist,i) > min_tau) THEN
            rayrad_dn_tl(lay,ist) = rayrad_dn_tl(lay-1,ist) + &
                                    (solar_src_updn_tl * transmission_aux%solar_path2%Tau_level(lev-1,ist,i) + &
                                    solar_src_updn * transmission_aux_tl%solar_path2%Tau_level(lev-1,ist,i) - &
                                    solar_src_updn * transmission_aux%solar_path2%Tau_level(lev-1,ist,i) * &
                                    3_jpim * transmission_aux_tl%solar_path1%Tau_level(lev-1,ist,i) / &
                                    transmission_aux%solar_path1%Tau_level(lev-1,ist,i)) / &
                                    transmission_aux%solar_path1%Tau_level(lev-1,ist,i) ** 3_jpim
          ELSE
            rayrad_dn_tl(lay,ist) = rayrad_dn_tl(lay-1,ist)
          ENDIF
        ENDDO
      ENDDO

      ! Add Rayleigh contributions to radiance totals
      DO ist = 0, ircld%nstream(prof)
        auxrad_stream_tl%up_solar(:,ist,i) = auxrad_stream_tl%up_solar(:,ist,i) + &
                                             rayrad_up_tl(1:nlayers,ist)

        auxrad_stream_tl%meanrad_up_solar(ist,i) = auxrad_stream_tl%meanrad_up_solar(ist,i) + &
                                                   rayrad_up_tl(iv3lay(i),ist)

        auxrad_stream_tl%down_solar(:,ist,i) = auxrad_stream_tl%down_solar(:,ist,i) + &
                                               rayrad_dn_tl(1:nlayers,ist)

        auxrad_stream_tl%meanrad_down_solar(ist,i) = auxrad_stream_tl%meanrad_down_solar(ist,i) + &
                                                     rayrad_dn_tl(iv3lay(i),ist)
      ENDDO

      ! Calculate the contribution from the part-layer above the surface

      ! Layer H2O by volume as fraction:
      IF (opts%rt_all%use_q2m) THEN
        v_h2o_dry = 0.5_jprb * (profiles_dry(prof)%q(iv3lev(i)) + &
                                profiles_dry(prof)%s2m%q) * 1.E-6_jprb
        v_h2o_dry_tl = 0.5_jprb * (profiles_dry_tl(prof)%q(iv3lev(i)) + &
                                   profiles_dry_tl(prof)%s2m%q) * 1.E-6_jprb
      ELSE
        v_h2o_dry = profiles_dry(prof)%q(iv3lev(i)) * 1.E-6_jprb
        v_h2o_dry_tl = profiles_dry_tl(prof)%q(iv3lev(i)) * 1.E-6_jprb
      ENDIF
      v_h2o = v_h2o_dry / (1._jprb + v_h2o_dry)
      v_h2o_tl = v_h2o_dry_tl * v_h2o * (1._jprb - v_h2o / (1._jprb + v_h2o_dry)) / v_h2o_dry

      ! Average molar weight of wet air for the layer (kg):
      Mwet = ((1._jprb - v_h2o) * Mair + v_h2o * Mh2o) * 1.E-3_jprb
      Mwet_tl = v_h2o_tl * (Mh2o - Mair) * 1.E-3_jprb

      ! cosine of scattering angle
      ! NB there are no pertubations around profile angles
      cossat = 1._jprb - raytracing%zasat(iv2lay(i), prof) * raytracing%zasat(iv2lay(i), prof)
      cossol = 1._jprb - raytracing%zasun(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof)
      cosscata_term1 = SQRT(cossat * cossol)
      cosazi = COS((profiles(prof)%azangle - profiles(prof)%sunazangle)*deg2rad)
      cosscata_term2 = raytracing%zasat(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof) * cosazi
      solar_src = solar_spectrum(i) * & ! mW m^-2 (cm^-1)^-1
            ABS(profiles(prof)%s2m%p - profiles(prof)%p(iv3lev(i))) * 100._jprb * &  ! convert hPa to Pa
            raytracing%pathsat(iv2lay(i), prof) * ss_param / Mwet

      cosscata = - cosscata_term1 - cosscata_term2
      ray_phase = 0.75_jprb * (1._jprb + cosscata * cosscata)
      solar_src_updn = solar_src * ray_phase

      cosscata_term1_tl = -1._jprb / cosscata_term1 * &
                      (raytracing_tl%zasat(iv2lay(i), prof) * raytracing%zasat(iv2lay(i), prof) * cossol + &
                      raytracing_tl%zasun(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof) * cossat)

      cosscata_term2_tl = raytracing_tl%zasat(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof) * cosazi + &
                          raytracing_tl%zasun(iv2lay(i), prof) * raytracing%zasat(iv2lay(i), prof) * cosazi

      IF (opts%interpolation%lgradp) THEN
        plev_tl = profiles_tl(prof)%p(iv3lev(i))
      ELSE
        plev_tl = 0._jprb
      ENDIF

      IF (profiles(prof)%s2m%p >= profiles(prof)%p(iv3lev(i))) THEN
        dp_tl = profiles_tl(prof)%s2m%p - plev_tl
      ELSE
        dp_tl = plev_tl - profiles_tl(prof)%s2m%p
      ENDIF

      solar_src_tl = solar_spectrum(i) * ss_param * &
                     (dp_tl * 100._jprb * &
                     raytracing%pathsat(iv2lay(i), prof) / Mwet + &
                     ABS(profiles(prof)%s2m%p - profiles(prof)%p(iv3lev(i))) * 100._jprb * &
                     raytracing_tl%pathsat(iv2lay(i), prof) / Mwet + &
                     ABS(profiles(prof)%s2m%p - profiles(prof)%p(iv3lev(i))) * 100._jprb * &
                     raytracing%pathsat(iv2lay(i), prof) * (-1._jprb) * Mwet_tl / (Mwet * Mwet))

      cosscata_tl = - cosscata_term1_tl - cosscata_term2_tl
      ray_phase_tl = 2._jprb * 0.75_jprb * cosscata_tl * cosscata
      solar_src_updn_tl = solar_src_tl * ray_phase + solar_src * ray_phase_tl

      ! Add near-surface contributions to the total radiances
      DO ist = 0, ircld%nstream(prof)
        auxrad_stream_tl%meanrad_up_solar(ist,i) = auxrad_stream_tl%meanrad_up_solar(ist,i) + &
                                  transmission_aux_tl%solar_path2%Tau_level(iv3lev(i),ist,i) * solar_src_updn + &
                                  transmission_aux%solar_path2%Tau_level(iv3lev(i),ist,i) * solar_src_updn_tl

        IF (transmission_aux%solar_path1%Tau_level(iv3lev(i),ist,i) > min_tau) THEN
          auxrad_stream_tl%meanrad_down_solar(ist,i) = auxrad_stream_tl%meanrad_down_solar(ist,i) + &
                                    (solar_src_updn_tl * transmission_aux%solar_path2%Tau_level(iv3lev(i),ist,i) + &
                                    solar_src_updn * transmission_aux_tl%solar_path2%Tau_level(iv3lev(i),ist,i) - &
                                    solar_src_updn * transmission_aux%solar_path2%Tau_level(iv3lev(i),ist,i) * &
                                    3_jpim * transmission_aux_tl%solar_path1%Tau_level(iv3lev(i),ist,i) / &
                                    transmission_aux%solar_path1%Tau_level(iv3lev(i),ist,i)) / &
                                    transmission_aux%solar_path1%Tau_level(iv3lev(i),ist,i) ** 3_jpim
        ENDIF
      ENDDO
    ENDDO
  END SUBROUTINE solar_rayleigh_tl

  SUBROUTINE solar_surface_contribution_tl(transmission_aux, transmission_aux_tl, ircld, &
                                           reflectance, reflectance_tl, auxrad_stream_tl)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux, transmission_aux_tl
    TYPE(rttov_ircld),            INTENT(IN)    :: ircld
    REAL(jprb),                   INTENT(IN)    :: reflectance(:), reflectance_tl(:)
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream_tl

    INTEGER(jpim) :: i, nstreams

    DO i = 1, nchanprof
      IF (solar(i)) THEN
        nstreams = ircld%nstream(prof)
        auxrad_stream_tl%cloudy(0:nstreams,i) = auxrad_stream_tl%cloudy(0:nstreams,i) + &
              solar_spectrum(i) * refl_norm(i) * &
              (reflectance_tl(i) * transmission_aux%solar_path2%Tau_surf(0:nstreams,i) + &
              reflectance(i) * transmission_aux_tl%solar_path2%Tau_surf(0:nstreams,i))
      ENDIF
    ENDDO
  END SUBROUTINE solar_surface_contribution_tl

END SUBROUTINE rttov_integrate_tl
