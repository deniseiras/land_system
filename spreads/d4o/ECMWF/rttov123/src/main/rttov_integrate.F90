! Description:
!> @file
!!   Integrate the radiative transfer equation
!
!> @brief
!!   Integrate the radiative transfer equation
!!
!! @details
!!   The layer emission terms are calculated using the linear-in-tau
!!   approximation.
!!
!!   Rayleigh scattering in visible channels is accounted for as a single-
!!   scattering contribution. The extinction due to Rayleigh scattering is
!!   included in the LBLRTM simulations used to train RTTOV (i.e. it is
!!   effectively included in the mixed gases). The Rayleigh scattering is
!!   calculated even when the DOM solver is used.
!!
!!   Eyre J.R. 1991 A fast radiative transfer model for satellite sounding
!!   systems.  ECMWF Research Dept. Tech. Memo. 176
!!
!!   Saunders R.W., M. Matricardi and P. Brunel 1999 An Improved Fast Radiative
!!   Transfer Model for Assimilation of Satellite Radiance Observations.
!!   QJRMS, 125, 1407-1425.
!!
!!   Matricardi, M. 2003 RTIASI-4, a new version of the ECMWF fast radiative
!!   transfer model for the infrared atmospheric sounding interferometer.
!!   ECMWF Research Dept. Tech. Memo. 425
!!
!!   Matricardi, M. 2005 The inclusion of aerosols and clouds in RTIASI,the
!!   ECMWF radiative transfer model for the infrared atmospheric sounding
!!   interferometer. ECMWF Research Dept. Tech. Memo. 474
!!
!!
!! @param[in]     addcosmic                   flag for inclusion of CMBR term in MW simulations
!! @param[in]     opts                        RTTOV options structure
!! @param[in]     maxnstreams                 largest number of cloud streams (columns) across all profiles
!! @param[in]     chanprof                    specifies channels and profiles to simulate
!! @param[in]     emissivity                  input/output surface emissivities
!! @param[in]     reflectance                 input/output surface reflectances for direct solar beam
!! @param[in]     refl_norm                   surface relfectance normalisation factors
!! @param[in]     diffuse_refl                surface reflectance for downwelling radiation
!! @param[in]     do_lambertian               flag indicating whether Lambertian surface is active for each channel
!! @param[in]     thermal                     per-channel flag to indicate if emissive simulations are being performed
!! @param[in]     dothermal                   flag to indicate if any emissive simulations are being performed
!! @param[in]     solar                       per-channel flag to indicate if solar simulations are being performed
!! @param[in]     dosolar                     flag to indicate if any solar simulations are being performed
!! @param[in]     solar_spectrum              TOA solar irradiance for each channel
!! @param[in]     transmission_aux            top-level auxiliary transmission structure
!! @param[in]     transmission_scatt_ir       visible/IR cloud/aerosol scattering parameters
!! @param[in]     profiles                    input atmospheric profiles and surface variables
!! @param[in]     profiles_dry                profiles in internal units
!! @param[in]     aux_prof                    auxiliary profile variables
!! @param[in]     coef                        optical depth coefficients structure
!! @param[in]     raytracing                  raytracing structure
!! @param[in]     ircld                       computed cloud column data
!! @param[in,out] rad                         primary output radiance structure
!! @param[in,out] rad2                        secondary output radiance structure
!! @param[in,out] auxrad                      Planck radiances
!! @param[in,out] auxrad_stream               internal radiance structure
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
SUBROUTINE rttov_integrate(addcosmic, opts, maxnstreams, chanprof, &
                           emissivity, reflectance, refl_norm, diffuse_refl, do_lambertian, &
                           thermal, dothermal, solar, dosolar, solar_spectrum, &
                           transmission_aux, transmission_scatt_ir, &
                           profiles, profiles_dry, aux_prof, coef, raytracing, ircld, &
                           rad, rad2, auxrad, auxrad_stream)

  USE parkind1, ONLY : jpim, jprb, jplm

  USE rttov_types, ONLY : rttov_chanprof, rttov_coef, rttov_options, rttov_profile, rttov_profile_aux, &
                          rttov_transmission_aux, rttov_transmission_scatt_ir, rttov_radiance, rttov_radiance2, &
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
  TYPE(rttov_reflectance),            INTENT(IN),    OPTIONAL :: reflectance(:)
  REAL(jprb),                         INTENT(IN)              :: refl_norm(:)
  REAL(jprb),                         INTENT(IN)              :: diffuse_refl(:)
  LOGICAL(jplm),                      INTENT(IN)              :: do_lambertian(:)
  LOGICAL(jplm),                      INTENT(IN)              :: thermal(:)
  LOGICAL(jplm),                      INTENT(IN)              :: dothermal
  LOGICAL(jplm),                      INTENT(IN)              :: solar(:)
  LOGICAL(jplm),                      INTENT(IN)              :: dosolar
  REAL(jprb),                         INTENT(IN)              :: solar_spectrum(:)
  TYPE(rttov_transmission_aux),       INTENT(IN)              :: transmission_aux
  TYPE(rttov_transmission_scatt_ir),  INTENT(IN)              :: transmission_scatt_ir
  TYPE(rttov_profile),                INTENT(IN)              :: profiles(:)
  TYPE(rttov_profile),                INTENT(IN)              :: profiles_dry(:)
  TYPE(rttov_profile_aux),            INTENT(IN)              :: aux_prof
  TYPE(rttov_coef),                   INTENT(IN)              :: coef
  TYPE(rttov_raytracing),             INTENT(IN)              :: raytracing
  TYPE(rttov_ircld),                  INTENT(IN)              :: ircld
  TYPE(rttov_radiance),               INTENT(INOUT)           :: rad
  TYPE(rttov_radiance2),              INTENT(INOUT), OPTIONAL :: rad2
  TYPE(rttov_radiance_aux),           INTENT(INOUT)           :: auxrad
  TYPE(rttov_radiance_aux),           INTENT(INOUT)           :: auxrad_stream
!INTF_END

#include "rttov_calcrad.interface"

  INTEGER(jpim) :: i, lev, ist, lay, nchanprof, nlayers, nlevels
  REAL(jprb)    :: refl, refl_norm_scat
  LOGICAL(jplm) :: keyradonly, do_scatt, dom_ir, dom_vis, do_single_scatt

  INTEGER(jpim) :: iv2lev(SIZE(chanprof)), iv2lay(SIZE(chanprof))
  INTEGER(jpim) :: iv3lev(SIZE(chanprof)), iv3lay(SIZE(chanprof))
  INTEGER(jpim) :: pol_id(SIZE(chanprof))

  REAL(jprb)    :: cfraction(SIZE(chanprof)), pfraction(SIZE(chanprof))
  LOGICAL(jplm) :: sateqsun(profiles(1)%nlayers,SIZE(profiles(:)))

  REAL(jprb) :: ZHOOK_HANDLE
!- End of header ------------------------------------------------------

  IF (LHOOK) CALL DR_HOOK('RTTOV_INTEGRATE',0_jpim,ZHOOK_HANDLE)

! Define macros for commonly used variables
#define prof chanprof(i)%Prof
#define chan chanprof(i)%Chan

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
#define fac1 transmission_aux%Fac1(lay,ist,i)
#define fac2_thermal_path1 transmission_aux%thermal_path1%fac2(lay+1,ist,i)
#define fac2_solar_path1 transmission_aux%solar_path1%fac2(lay+1,ist,i)
#define surf_fac transmission_aux%Surf_fac(ist,i)

  !-------------------------------------------------------------------------------
  ! Initialise useful variables
  !-------------------------------------------------------------------------------

  nchanprof = SIZE(chanprof)
  nlayers = profiles(1)%nlayers
  nlevels = nlayers + 1

  do_scatt = opts%rt_ir%addclouds .OR. opts%rt_ir%addaerosl
  dom_ir = do_scatt .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom
  dom_vis = do_scatt .AND. opts%rt_ir%addsolar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom ! DOM vis *selected*
  do_single_scatt = do_scatt .AND. dosolar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single  ! Single-scatt *actually used*
  keyradonly = opts%rt_ir%addaerosl .OR. opts%rt_ir%pc%addpc .OR. dom_ir .OR. dom_vis

  IF (dosolar) sateqsun(:,:) = (ABS(raytracing%pathsat(:,:) - raytracing%pathsun(:,:)) < realtol)

  DO i = 1, nchanprof
    cfraction(i) = aux_prof%s(prof)%cfraction
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

  auxrad_stream%cloudy = 0._jprb
  IF (dosolar) THEN
    auxrad_stream%up_solar = 0._jprb
    auxrad_stream%meanrad_up_solar = 0._jprb
    auxrad_stream%down_solar = 0._jprb
    auxrad_stream%meanrad_down_solar = 0._jprb
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate layer radiances
  !-------------------------------------------------------------------------------
  IF (dothermal) CALL rttov_calcrad(addcosmic, opts, chanprof, profiles, coef, thermal, auxrad)

  !-------------------------------------------------------------------------------
  ! Calculate atmospheric contribution from layers
  !-------------------------------------------------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) &
    CALL calc_atmospheric_radiance(transmission_aux, auxrad, auxrad_stream)

  ! Scattering of the solar beam
  IF (do_single_scatt) &
    CALL  solar_scattering_air(transmission_aux, diffuse_refl, raytracing, &
                               transmission_scatt_ir, auxrad_stream)

  !-------------------------------------------------------------------------------
  ! Calculate near-surface layer contribution
  !-------------------------------------------------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) &
    CALL calc_near_surf_contribution(transmission_aux, auxrad, auxrad_stream)

  ! Scattering of the solar beam
  IF (do_single_scatt) &
    CALL solar_scattering_near_surf(transmission_aux, diffuse_refl, auxrad_stream)

  !-------------------------------------------------------------------------------
  ! Calculate clear-sky Rayleigh scattering contribution
  !-------------------------------------------------------------------------------
  IF (dosolar .AND. opts%rt_ir%rayleigh_single_scatt) &
    CALL solar_rayleigh(raytracing, profiles, profiles_dry, transmission_aux, auxrad_stream)

  !-------------------------------------------------------------------------------
  ! Add thermal and solar atmospheric contributions to the clear and cloudy streams
  !-------------------------------------------------------------------------------
  DO i = 1, nchanprof
    IF (thermal(i) .AND. .NOT. dom_ir) THEN
      DO ist = 0, ircld%nstream(prof)
        IF (do_lambertian(i)) THEN
          auxrad_stream%cloudy(ist,i) = &
              auxrad_stream%cloudy(ist,i) + auxrad_stream%meanrad_up(ist,i) + &
              (profiles(prof)%skin%specularity * &
               auxrad_stream%meanrad_down(ist,i) * tau_surf + &
               (1._jprb - profiles(prof)%skin%specularity) * &
               auxrad_stream%meanrad_down_p(ist,i) * tau_surf_p) * &
              diffuse_refl(i) * tau_surf
        ELSE
          auxrad_stream%cloudy(ist,i) = &
              auxrad_stream%cloudy(ist,i) + auxrad_stream%meanrad_up(ist,i) + &
              auxrad_stream%meanrad_down(ist,i) * diffuse_refl(i) * &
              tau_surf**2_jpim
        ENDIF
      ENDDO

      ! Replace the upward radiances from the level at the bottom of the layer
      ! containing the surface with the calculated surface->ToA radiance (only for stream 0)
      ! (for overcast and secondary radiances)
      auxrad_stream%up(iv2lay(i),0,i) = auxrad_stream%meanrad_up(0,i)
    ENDIF

    IF (solar(i)) THEN
      ! Downward-scattered component: this radiation is travelling along the
      ! satellite line-of-sight. diffuse_refl must be divided by pi to give
      ! a BRDF and multiplied by cos(sat_zen_angle)
      refl_norm_scat = COS(profiles(prof)%zenangle * deg2rad) * pi_r

      DO ist = 0, ircld%nstream(prof)
        auxrad_stream%cloudy(ist,i) = auxrad_stream%cloudy(ist,i) + &
                                      auxrad_stream%meanrad_up_solar(ist,i) + &
                                      auxrad_stream%meanrad_down_solar(ist,i) * &
                                      diffuse_refl(i) * refl_norm_scat * &
                                      transmission_aux%solar_path1%Tau_surf(ist,i)**2_jpim
      ENDDO

      ! Replace the upward radiances from the level at the bottom of the layer
      ! containing the surface with the calculated surface->ToA radiance (only for stream 0)
      ! (for overcast and secondary radiances)
      auxrad_stream%up_solar(iv2lay(i),0,i) = auxrad_stream%meanrad_up_solar(0,i)
    ENDIF
  ENDDO

  !-------------------------------------------------------------------------------
  ! Calculate surface emission contribution
  !-------------------------------------------------------------------------------
  IF (dothermal .AND. .NOT. dom_ir) THEN
  !cdir nodep
    DO i = 1, nchanprof
      IF (thermal(i)) THEN
  !cdir nodep
        DO ist = 0, ircld%nstream(prof)
          auxrad_stream%cloudy(ist,i) = auxrad_stream%cloudy(ist,i) + &
                                        auxrad%skin(i) * emissivity(i)%emis_out * tau_surf
        ENDDO
      ENDIF
    ENDDO
  ENDIF

  !-------------------------------------------------------------------------------
  ! Solar surface contribution
  !-------------------------------------------------------------------------------
  IF (dosolar .AND. .NOT. dom_vis) &
    CALL solar_surface_contribution(transmission_aux, reflectance%refl_out, auxrad_stream)

  !-------------------------------------------------------------------------------
  ! Cosmic temperature correction
  !-------------------------------------------------------------------------------
  ! calculate planck function corresponding to tcosmic = 2.7k
  ! deblonde tcosmic for microwave sensors only
  IF (addcosmic) THEN
    ist = 0
    DO i = 1, nchanprof
      IF (do_lambertian(i)) THEN
        auxrad_stream%cloudy(ist,i) = auxrad_stream%cloudy(ist,i) + diffuse_refl(i) * &
                        (profiles(prof)%skin%specularity * tau_surf + &
                         (1._jprb - profiles(prof)%skin%specularity) * tau_surf_p) * &
                        tau_surf * auxrad%cosmic(i)
      ELSE
        auxrad_stream%cloudy(ist,i) = auxrad_stream%cloudy(ist,i) + diffuse_refl(i) * &
                        transmission_aux%thermal_path1%Tau_surf(ist,i)**2_jpim * &
                        auxrad%cosmic(i)
      ENDIF
    ENDDO
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate secondary radiances
  !-------------------------------------------------------------------------------
  ! These direct-model-only outputs include thermal contributions (no solar) and are calculated
  ! only for non-aerosol, non-DOM and non-PC simulations if the rad2 parameter is present

  IF (PRESENT(rad2) .AND. dothermal .AND. .NOT. keyradonly) then
    !cdir nodep
    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        ist = 0_jpim

        ! Clear-sky upwelling atmospheric emission at TOA
        ! Note the surface layer value in auxrad_stream%up has been modified above
        rad2%up(:,i) = auxrad_stream%up(:,ist,i)

        ! Clear-sky upwelling radiance at TOA (without surface reflected term)
        rad2%upclear(i) = auxrad_stream%meanrad_up(ist,i) + &
                          auxrad%skin(i) * emissivity(i)%emis_out * tau_surf

        ! Clear-sky downwelling radiance at surface (before reflection)
        IF (do_lambertian(i)) THEN  ! Lambertian/specular mixed
          rad2%dnclear(i) = profiles(prof)%skin%specularity * &
                            auxrad_stream%meanrad_down(ist,i) * tau_surf + &
                            (1._jprb - profiles(prof)%skin%specularity) * &
                            auxrad_stream%meanrad_down_p(ist,i) * tau_surf_p
        ELSE                        ! Specular
          rad2%dnclear(i) = auxrad_stream%meanrad_down(ist,i) * tau_surf
        ENDIF

        ! Reflected clear-sky downwelling radiance at TOA
        rad2%refldnclear(i) = rad2%dnclear(i) * diffuse_refl(i) * tau_surf

        ! Planck emission
        rad2%surf(2:nlayers,i) = auxrad%air(3:nlevels,i)
        rad2%surf(iv2lay(i),i) = auxrad%skin(i)

        ! Clear-sky downwelling radiance from TOA down to bottom of each layer
        ! at the level bounding the bottom of the layer
        DO lay = 2, nlayers
          IF (tau_level > min_tau) THEN
            IF (do_lambertian(i)) THEN
              rad2%down(lay,i) = profiles(prof)%skin%specularity * &
                                 auxrad_stream%down(lay,ist,i) * tau_level + &
                                 (1._jprb - profiles(prof)%skin%specularity) * &
                                 auxrad_stream%down_p(lay,ist,i) * tau_level_p
            ELSE
              rad2%down(lay,i) = auxrad_stream%down(lay,ist,i) * tau_level
            ENDIF
          ELSE
            rad2%down(lay,i) = rad2%down(lay-1,i)
          ENDIF
        ENDDO
        IF (tau_surf > min_tau) THEN
          rad2%down(iv2lay(i),i) = rad2%dnclear(i)
        ELSE
          rad2%down(iv2lay(i),i) = rad2%down(iv3lay(i),i)
        ENDIF

      ENDIF
    ENDDO
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate overcast radiances
  !-------------------------------------------------------------------------------
  ! Overcast radiances only calculated for non-aerosol, non-DOM, non-PC simulations

  IF (.NOT. keyradonly) THEN
    ! rad%overcast includes solar contribution ONLY for pure-solar channels because assumed
    !   cloud emissivity is 1.0 (i.e. no reflection) for all thermal channels
    ist = 0_jpim
    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        DO lay = 1, nlayers
          lev = lay + 1
          ! Overcast radiances at given cloud top
          rad%overcast(lay,i) = auxrad_stream%up(lay,ist,i) + auxrad%air(lev,i) * tau_level
        ENDDO
      ELSEIF (solar(i)) THEN
        ! Very crude model: assumes clouds are Lambertian reflectors with fixed albedo
        ! Use input cloud top BRDF if user has supplied it, otherwise use default BRDF
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
          ! Overcast radiances at given cloud top
          rad%overcast(lay,i) = solar_spectrum(i) * refl / raytracing%pathsun(lay,prof) * &
                                transmission_aux%solar_path2%Tau_level(lev,ist,i) + &
                                auxrad_stream%up_solar(lay,ist,i) + &
                                auxrad_stream%down_solar(lay,ist,i) * refl / raytracing%pathsat(lay,prof) * &
                                transmission_aux%solar_path1%Tau_level(lev,ist,i) ** 2_jpim
        ENDDO
      ENDIF
    ENDDO

    IF (dothermal) THEN
      ! Add surface component to thermal overcast radiances in near-surface layer
      DO i = 1, nchanprof
        IF (thermal(i)) THEN
          lay = iv2lay(i)
          rad%overcast(lay,i) = auxrad_stream%up(lay,ist,i) + tau_surf * auxrad%surfair(i)
        ENDIF
      ENDDO
    ENDIF
  ENDIF

  !-------------------------------------------------------------------------------
  ! Calculate total radiance
  !-------------------------------------------------------------------------------
  rad%clear(1:nchanprof) = auxrad_stream%cloudy(0,1:nchanprof)

  ! The simple cloudy scheme is not applied to aerosol-affected radiances
  IF (do_scatt) THEN
    !---------------------------------------------------
    ! Calculate complex cloudy radiances
    !---------------------------------------------------
    DO i = 1, nchanprof
      ! For thermal channels with DOM the whole radiance is calculated in rttov_dom.
      ! For solar-affected channels the Rayleigh contribution and/or the solar
      ! single-scattering are calculated here and need to be accumulated.
      IF (thermal(i) .AND. dom_ir .AND. .NOT. solar(i)) CYCLE
      DO ist = 1, ircld%nstream(prof)
        rad%cloudy(i) = rad%cloudy(i) + &
                        auxrad_stream%cloudy(ist,i) * &
                        (ircld%xstr(ist+1,prof) - ircld%xstr(ist,prof))
      ENDDO

      rad%cloudy(i) = rad%cloudy(i) + auxrad_stream%cloudy(0,i) * ircld%xstrclr(prof)
    ENDDO

    rad%total(1:nchanprof) = rad%cloudy(1:nchanprof)
  ELSE
    !---------------------------------------------------
    ! Calculate total radiance (clear case/simple cloud)
    !---------------------------------------------------
    IF (opts%rt_ir%pc%addpc) THEN
      rad%total(1:nchanprof) = rad%clear(1:nchanprof)
    ELSE
      ! Interpolate to given cloud-top pressures
      DO i = 1, nchanprof
        lay = aux_prof%s(prof)%nearestlev_ctp - 1
        rad%cloudy(i) = rad%overcast(lay,i) * &
                        (1._jprb - aux_prof%s(prof)%pfraction_ctp) + &
                        rad%overcast(lay-1,i) * aux_prof%s(prof)%pfraction_ctp
      ENDDO

      rad%total(1:nchanprof) = rad%clear(1:nchanprof) + &
                               cfraction(1:nchanprof) * &
                              (rad%cloudy(1:nchanprof) - rad%clear(1:nchanprof))
    ENDIF
  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_INTEGRATE',1_jpim,ZHOOK_HANDLE)

CONTAINS

! DAR: This subroutine calculates the individual layer clear-sky radiances and then does a cumulative sum to determine the
!      radiance observed from the top of atmosphere to a particular layer.
! DAR: As expected, this routine consumes most of the time (loops over channels, streams and levels)
!      and has been most heavily optimised (for IBM only so far, Intel shows neutral impact - will look into this)
!      I have taken out the code that switches the order of the loops on the NEC and will let MF test this impact
!      See subroutine comments for more details of individual changes.

  SUBROUTINE calc_atmospheric_radiance(transmission_aux, auxrad, auxrad_stream)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux
    TYPE(rttov_radiance_aux),     INTENT(IN)    :: auxrad
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream

    INTEGER(jpim) :: i, ist, isti, lay
    REAL(jprb)    :: up_laym1, down_laym1, down_p_laym1
    REAL(jprb)    :: rad_air_avg(nlayers), rad_air_diff(nlayers)
    REAL(jprb)    :: dtau(nlayers)

! DAR: fac and fac2 contain real 1 or 0 depending on whether a calculation should be performed or not.
!      IBM performance was suffering as a result of doing lots of branching (mispredicts?) so these arrays are populated in advance
!      and the calculation is performed regardless.

! DAR: I've removed a lot of the 'temporary' variables that were eventually summed together because they were taking up a
!      signficant amount of time on the IBM. Now the big sum is done with all the variables in full because the 16 prefetch streams
!      can handle this (POWER6) - maybe will have to split this up for POWER7 (only 12). Will do more testing on Intel with vtune
!      to check performance impact.

! DAR: I've also removed od_singlelayer_r and added it to transmission_aux so it can be reused the TL/AD/K code when ready
!      and doesn't have to be recalculated - This should be faster...

! DAR: cumulative sum is done at same time as it's significantly quicker than doing it later.
!      This code is still very hard to read though.
    DO i = 1, nchanprof
      IF (thermal(i)) THEN

        IF (do_lambertian(i) .OR. .NOT. opts%rt_all%rad_down_lin_tau) THEN
          rad_air_avg = 0.5_jprb * (auxrad%air(1:nlayers,i) + auxrad%air(2:nlevels,i))
        ENDIF
        rad_air_diff = auxrad%air(2:nlevels,i) - auxrad%air(1:nlayers,i)

        DO ist = 0, ircld%nstream(prof)
          up_laym1 = 0._jprb
          down_laym1 = 0._jprb
          down_p_laym1 = 0._jprb

          dtau = transmission_aux%thermal_path1%Tau_level(1:nlayers,ist,i) - &
                 transmission_aux%thermal_path1%Tau_level(2:nlevels,ist,i)

          DO lay = 1, nlayers
            isti = ircld%icldarr(ist,lay,prof)
            auxrad_stream%up(lay,ist,i) = up_laym1 + &
              fac1 * &
              (dtau(lay) * &
              (auxrad%air(lay,i) + &
              rad_air_diff(lay) * &
              od_singlelayer_r) - &
              rad_air_diff(lay) * &
              tau_level)
            IF (do_lambertian(i)) THEN
              ! Lambertian reflected downwelling layer-average
              auxrad_stream%down_p(lay,ist,i) = down_p_laym1 + &
                fac1 * &
                fac2_thermal_path1 * rad_air_avg(lay) * &
                ((tau_level_p_r) - (tau_layer_p_r))
            ENDIF
            IF (opts%rt_all%rad_down_lin_tau) THEN
              ! Specular reflected downwelling linear-in-tau
              auxrad_stream%down(lay,ist,i) = down_laym1 + &
                fac1 * &
                fac2_thermal_path1 * &
              ((dtau(lay) * &
                (auxrad%air(lay,i) - &
                rad_air_diff(lay) * &
                od_singlelayer_r) * &
                (tau_level_r * &
                tau_layer_r)) + &
                rad_air_diff(lay) * &
                tau_level_r)
            ELSE
              ! Specular reflected downwelling layer-average
              auxrad_stream%down(lay,ist,i) = down_laym1 + &
                fac1 * &
                fac2_thermal_path1 * rad_air_avg(lay) * &
                ((tau_level_r) - (tau_layer_r))
            ENDIF

            up_laym1   = auxrad_stream%up(lay,ist,i)
            down_laym1 = auxrad_stream%down(lay,ist,i)
            IF (do_lambertian(i)) down_p_laym1 = auxrad_stream%down_p(lay,ist,i)
          ENDDO
        ENDDO
      ENDIF
    ENDDO

    DO i = 1, nchanprof
      IF (thermal(i)) THEN
        DO ist = 0, ircld%nstream(prof)
          auxrad_stream%down_ref(:,ist,i) = auxrad_stream%down(:,ist,i)
          auxrad_stream%down(:,ist,i) = MAX(auxrad_stream%down_ref(:,ist,i), 0._jprb)
        ENDDO
        IF (do_lambertian(i)) THEN
          DO ist = 0, ircld%nstream(prof)
            auxrad_stream%down_p_ref(:,ist,i) = auxrad_stream%down_p(:,ist,i)
            auxrad_stream%down_p(:,ist,i) = MAX(auxrad_stream%down_p_ref(:,ist,i), 0._jprb)
          ENDDO
        ENDIF
      ENDIF
    ENDDO
  END SUBROUTINE calc_atmospheric_radiance

  ! DAR: This is the next biggest consumer of CPU time and should be looked at next. The trouble seems to be that you have to change a
  !      lot of non-consecutive data.

  SUBROUTINE calc_near_surf_contribution(transmission_aux, auxrad, auxrad_stream)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux
    TYPE(rttov_radiance_aux),     INTENT(IN)    :: auxrad
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream

    INTEGER(jpim) :: i, ist, lay, lev
    REAL(jprb)    :: rad_air_avg, rad_air_diff

#define B1_3 auxrad%air(lev,i) * (tau_level  - tau_surf)
#define B2_3 rad_air_diff * tau_surf
#define B3_3 rad_air_diff * (tau_level - tau_surf) * (transmission_aux%thermal_path1%od_sfrac_r(ist,i))

    DO i = 1, nchanprof
      IF (.NOT. thermal(i)) CYCLE
      lay = iv3lay(i)
      lev = iv3lev(i)

      rad_air_avg = 0.5_jprb * (auxrad%surfair(i) + auxrad%air(lev,i))
      rad_air_diff = auxrad%surfair(i) - auxrad%air(lev,i)

      DO ist = 0, ircld%nstream(prof)

        IF (transmission_aux%thermal_path1%od_sfrac(ist,i) < min_od .OR. &
            (opts%rt_all%dtau_test .AND. &
             (tau_level - tau_surf) < min_od)) THEN
          ! small optical depth or optical depth change set radiance to zero
          auxrad_stream%meanrad_up(ist,i) = 0._jprb
          auxrad_stream%meanrad_down(ist,i) = 0._jprb
          IF (do_lambertian(i)) auxrad_stream%meanrad_down_p(ist,i) = 0._jprb
        ELSE
          ! Upwelling linear-in-tau
          auxrad_stream%meanrad_up(ist,i) = &
            B1_3 - &
            B2_3 + &
            B3_3
          IF (do_lambertian(i)) THEN 
            ! Lambertian reflected downwelling layer-average
            auxrad_stream%meanrad_down_p(ist,i) = &
              surf_fac * rad_air_avg * &
              ((tau_surf_p_r) - (tau_level_p_r))
          ENDIF
          IF (opts%rt_all%rad_down_lin_tau) THEN
            ! Specular reflected downwelling linear-in-tau
             auxrad_stream%meanrad_down(ist,i) = &
                surf_fac * &
                (B1_3 - &
                B3_3) * &
                tau_level_r * tau_surf_r + &
                B2_3 * tau_surf_r**2
          ELSE
            ! Specular reflected downwelling layer-average
            auxrad_stream%meanrad_down(ist,i) = &
              surf_fac * rad_air_avg * &
              ((tau_surf_r) - (tau_level_r))
          ENDIF
        ENDIF

        IF (pol_id(i) >= 6_jpim) THEN
          auxrad_stream%meanrad_up(ist,i) = 0._jprb
        ELSE
          auxrad_stream%meanrad_up(ist,i) = auxrad_stream%meanrad_up(ist,i) + auxrad_stream%up(lay,ist,i)
        ENDIF

        auxrad_stream%meanrad_down(ist,i) = auxrad_stream%meanrad_down(ist,i) + auxrad_stream%down(lay,ist,i)
        auxrad_stream%meanrad_down(ist,i) = MAX(auxrad_stream%meanrad_down(ist,i), 0._jprb)
        IF (do_lambertian(i)) THEN
          auxrad_stream%meanrad_down_p(ist,i) = auxrad_stream%meanrad_down_p(ist,i) + auxrad_stream%down_p(lay,ist,i)
          auxrad_stream%meanrad_down_p(ist,i) = MAX(auxrad_stream%meanrad_down_p(ist,i), 0._jprb)
        ENDIF
      ENDDO
    ENDDO
  END SUBROUTINE calc_near_surf_contribution

  SUBROUTINE solar_scattering_air(transmission_aux, refl, raytracing, transmission_scatt_ir, auxrad_stream)

    TYPE(rttov_transmission_aux),      INTENT(IN)    :: transmission_aux
    REAL(jprb),                        INTENT(IN)    :: refl(:)
    TYPE(rttov_raytracing),            INTENT(IN)    :: raytracing
    TYPE(rttov_transmission_scatt_ir), INTENT(IN)    :: transmission_scatt_ir
    TYPE(rttov_radiance_aux),          INTENT(INOUT) :: auxrad_stream

    REAL(jprb)    :: temp(nlayers,0:maxnstreams)
    INTEGER(jpim) :: i, ist, isti, lay, su

    ! The solar_path1 and solar_path2 quantities are completely consistent (i.e.
    ! they are based on the same optical depth regression, namely the solar one).
    ! Note that solar_path2%tau_level is on the sun-surface-satellite path
    ! but solar_path2%od_single_layer is on the sun-surface path.

#define fac1_2 auxrad_stream%Fac1_2(isti,lay,i)
#define fac3_2 auxrad_stream%Fac3_2(lay,i)
#define fac4_2 auxrad_stream%Fac4_2(isti,lay,i)
#define fac5_2 auxrad_stream%Fac5_2(isti,lay,i)
#define fac6_2 auxrad_stream%Fac6_2(isti,lay,i)
#define fac7_2 auxrad_stream%Fac7_2(lay,i)
#define dfac54_2 (fac5_2 - fac4_2)
#define tausun_layer transmission_aux%solar_path2%Tau_level(lay,ist,i)

    su = 0
    IF (opts%rt_ir%addclouds) su = 1

    DO i = 1, nchanprof
      IF (.NOT. solar(i)) CYCLE

      auxrad_stream%Fac6_2(0:su,:,i) = solar_spectrum(i) * z4pi_r * transmission_scatt_ir%phdo(0:su,:,i)
      auxrad_stream%Fac1_2(0:su,:,i) = solar_spectrum(i) * z4pi_r * transmission_scatt_ir%phup(0:su,:,i)

      auxrad_stream%Fac3_2(:,i) = raytracing%pathsat(:,prof) / raytracing%patheff(:,prof)

      auxrad_stream%Fac4_2(0:su,:,i) = EXP(-transmission_aux%solar_path2%Od_singlelayer(0:su,:,i))
      auxrad_stream%Fac5_2(0:su,:,i) = EXP(-transmission_aux%solar_path1%Od_singlelayer(0:su,:,i))

      DO lay = 1, nlayers
        IF (.NOT. sateqsun(lay,prof)) THEN
          auxrad_stream%Fac7_2(lay,i) = raytracing%pathsat(lay,prof) / &
                                        (raytracing%pathsun(lay,prof) - raytracing%pathsat(lay,prof))
        ENDIF
      ENDDO

      !----------------Upward single scattering of the solar beam-----------------------

      DO ist = 0, ircld%nstream(prof)
        DO lay = 1, nlayers
          isti = ircld%icldarr(ist,lay,prof)
          auxrad_stream%up_solar(lay,ist,i) = &
                        (auxrad_stream%Fac1_2(isti,lay,i) * &
                        transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                        auxrad_stream%Fac3_2(lay,i) * &
                        (transmission_aux%solar_path2%Tau_level(lay,ist,i) - &
                        transmission_aux%solar_path2%Tau_level(lay+1,ist,i)))
        ENDDO
      ENDDO

      DO ist = 0, ircld%nstream(prof)
        DO lay = 2, nlayers
          auxrad_stream%up_solar(lay,ist,i) = auxrad_stream%up_solar(lay,ist,i) + auxrad_stream%up_solar(lay-1,ist,i)
        ENDDO
      ENDDO

      !-------------------Downward single scattering of the solar beam------------------

      IF (refl(i) > 0._jprb) THEN
        DO ist = 0, ircld%nstream(prof)
          DO lay = 1, nlayers
            isti = ircld%icldarr(ist,lay,prof)

            temp(lay,ist) = fac2_solar_path1 * &
                            fac6_2 * &
                            transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                            tausun_layer * &
                            transmission_aux%solar_path1%Tau_level_r(lay,ist,i) * &
                            transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i)

            IF (.NOT. sateqsun(lay,prof)) THEN
              temp(lay,ist) = temp(lay,ist) * &
                              fac7_2 * &
                              dfac54_2
            ELSE
              temp(lay,ist) = temp(lay,ist) * &
                              fac4_2 * &
                              transmission_aux%solar_path2%Od_singlelayer(isti,lay,i)
            ENDIF
          ENDDO
        ENDDO

        DO ist = 0, ircld%nstream(prof)
          lay = 1_jpim
          auxrad_stream%down_ref_solar(lay,ist,i) = temp(lay,ist)
          auxrad_stream%down_solar(lay,ist,i) = MAX(auxrad_stream%down_ref_solar(lay,ist,i), 0._jprb)
          DO lay = 2, nlayers
            temp(lay,ist) = temp(lay-1,ist) + temp(lay,ist)
            auxrad_stream%down_ref_solar(lay,ist,i) = temp(lay,ist)
            auxrad_stream%down_solar(lay,ist,i) = MAX(auxrad_stream%down_ref_solar(lay,ist,i), 0._jprb)
          ENDDO
        ENDDO
      ENDIF ! refl(i) > 0.
    ENDDO
  END SUBROUTINE solar_scattering_air

  SUBROUTINE solar_scattering_near_surf(transmission_aux, refl, auxrad_stream)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux
    REAL(jprb),                   INTENT(IN)    :: refl(:)
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream

    INTEGER(jpim) :: i, ist, isti, lay, lev, lay1, nstreams
    REAL(jprb) :: temp(0:maxnstreams)

#define fac4_3 auxrad_stream%Fac4_3(ist,i)
#define fac5_3 auxrad_stream%Fac5_3(ist,i)
#define dfac54_3 (fac5_3 - fac4_3)
#define dtausun_surf (transmission_aux%solar_path2%Tau_level(lev,ist,i) - transmission_aux%solar_path2%Tau_surf(ist,i))
#define tausun_level transmission_aux%solar_path2%Tau_level(lev,ist,i)

    DO i = 1, nchanprof
      IF (.NOT. solar(i)) CYCLE

      ! lay is the layer above the one containing the surface
      ! lev is the nearest layer above the surface
      lay = iv3lay(i)
      lev = iv3lev(i)
      nstreams = ircld%nstream(prof)

      ! lay1 is the layer containing the surface or the bottom layer
      !   if the surface lies below the bottom of the profile
      IF (pfraction(i) < 0._jprb) THEN
        lay1 = lay
      ELSE
        lay1 = lay + 1
      ENDIF

      auxrad_stream%Fac4_3(0:nstreams,i) = EXP(-transmission_aux%solar_path2%od_sfrac(0:nstreams,i))
      auxrad_stream%Fac5_3(0:nstreams,i) = EXP(-transmission_aux%solar_path1%od_sfrac(0:nstreams,i))

      !--------------Upward single scattering of the solar beam-------------------------

      DO ist = 0, ircld%nstream(prof)
        isti = ircld%icldarr(ist,lay,prof)

        auxrad_stream%meanrad_up_solar(ist,i) = &
          fac1_2 * &
          transmission_scatt_ir%ssa_solar(isti,lay,i) * &
          fac3_2 * &
          dtausun_surf
      ENDDO

      DO ist = 0, ircld%nstream(prof)
        auxrad_stream%meanrad_up_solar(ist,i) = auxrad_stream%meanrad_up_solar(ist,i) + &
                                                auxrad_stream%up_solar(lay,ist,i)
      ENDDO

      !--------------Downward single scattering of the solar beam-----------------------

      IF (refl(i) > 0._jprb) THEN
        DO ist = 0, ircld%nstream(prof)
          temp(ist) = fac2_solar_path1 * &
                      fac6_2 * &
                      transmission_scatt_ir%ssa_solar(isti,lay,i) * &
                      tausun_level * &
                      (transmission_aux%solar_path1%Tau_level_r(lay+1,ist,i) * &
                      transmission_aux%solar_path1%Tau_surf_r(ist,i))
        ENDDO

        IF (.NOT. sateqsun(lay1,prof)) THEN
          DO ist = 0, ircld%nstream(prof)
            auxrad_stream%meanrad_down_solar(ist,i) = &
                    temp(ist) * &
                    auxrad_stream%Fac7_2(lay1,i) * &
                    dfac54_3
          ENDDO
        ELSE
          DO ist = 0, ircld%nstream(prof)
            auxrad_stream%meanrad_down_solar(ist,i) = &
                                temp(ist) * fac4_3 * &
                                transmission_aux%solar_path2%od_sfrac(ist,i)
          ENDDO
        ENDIF

        DO ist = 0, ircld%nstream(prof)
          auxrad_stream%meanrad_down_solar(ist,i) = auxrad_stream%meanrad_down_solar(ist,i) + &
                                                    auxrad_stream%down_solar(lay,ist,i)

          auxrad_stream%meanrad_down_solar(ist,i) = MAX(auxrad_stream%meanrad_down_solar(ist,i), 0._jprb)
        ENDDO
      ENDIF ! refl(i) > 0.
    ENDDO
  END SUBROUTINE solar_scattering_near_surf

  SUBROUTINE solar_rayleigh(raytracing, profiles, profiles_dry, transmission_aux, auxrad_stream)

    TYPE(rttov_raytracing),       INTENT(IN)    :: raytracing
    TYPE(rttov_profile),          INTENT(IN)    :: profiles(:)
    TYPE(rttov_profile),          INTENT(IN)    :: profiles_dry(:)
    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream

    INTEGER(jpim) :: i, ist, lay, lev
    REAL(jprb) :: wlm, ss_param, v_h2o, Mwet, cosscata_term1, cosscata_term2, cosscata
    REAL(jprb) :: ray_phase, solar_src, solar_src_updn
    REAL(jprb) :: rayrad_up(0:nlayers,0:maxnstreams), rayrad_dn(0:nlayers,0:maxnstreams)

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

      rayrad_up(0,:) = 0._jprb
      rayrad_dn(0,:) = 0._jprb

      ! Sum contributions from atmospheric layers
      DO lev = 2, nlevels
        lay = lev - 1

        ! Layer H2O by volume as fraction:
        v_h2o = 0.5_jprb * (profiles_dry(prof)%q(lev-1) + profiles_dry(prof)%q(lev)) * 1.E-6_jprb
        ! Convert ppmv dry to ppmv wet
        v_h2o = v_h2o / (1._jprb + v_h2o)

        ! Average molar weight of wet air for the layer (kg)
        Mwet = ((1._jprb - v_h2o) * Mair + v_h2o * Mh2o) * 1.E-3_jprb

        ! cosine of scattering angle - raytracing%zasat/zasun contain the sine of the angles
        cosscata_term1 = SQRT((1._jprb - raytracing%zasat(lay, prof) * raytracing%zasat(lay, prof)) * &
                         (1._jprb - raytracing%zasun(lay, prof) * raytracing%zasun(lay, prof)))
        cosscata_term2 = raytracing%zasat(lay, prof) * raytracing%zasun(lay, prof) * &
                         COS((profiles(prof)%azangle - profiles(prof)%sunazangle)*deg2rad)

        solar_src = solar_spectrum(i) * & ! mW m^-2 (cm^-1)^-1
              (profiles(prof)%p(lev) - profiles(prof)%p(lev-1)) * 100._jprb * & ! convert hPa to Pa
              raytracing%pathsat(lay, prof) * ss_param / Mwet

        cosscata = - cosscata_term1 - cosscata_term2
        ray_phase = 0.75_jprb * (1._jprb + cosscata * cosscata)
        solar_src_updn = solar_src * ray_phase

        ! Phase function symmetry means upwelling and downwelling radiances are the same
        DO ist = 0, ircld%nstream(prof)
          rayrad_up(lay,ist) = rayrad_up(lay-1,ist) + solar_src_updn * &
                               transmission_aux%solar_path2%Tau_level(lev-1,ist,i)
        ENDDO

        DO ist = 0, ircld%nstream(prof)
          IF (transmission_aux%solar_path1%Tau_level(lev-1,ist,i) > min_tau) THEN
            rayrad_dn(lay,ist) = rayrad_dn(lay-1,ist) + solar_src_updn * &
                                 transmission_aux%solar_path2%Tau_level(lev-1,ist,i) / &
                                 transmission_aux%solar_path1%Tau_level(lev-1,ist,i) ** 3_jpim
          ELSE
            rayrad_dn(lay,ist) = rayrad_dn(lay-1,ist)
          ENDIF
        ENDDO
      ENDDO

      ! Add Rayleigh contributions to radiance totals
      DO ist = 0, ircld%nstream(prof)
        auxrad_stream%up_solar(:,ist,i) = auxrad_stream%up_solar(:,ist,i) + &
                                          rayrad_up(1:nlayers,ist)

        auxrad_stream%meanrad_up_solar(ist,i) = auxrad_stream%meanrad_up_solar(ist,i) + &
                                                rayrad_up(iv3lay(i),ist)

        auxrad_stream%down_solar(:,ist,i) = auxrad_stream%down_solar(:,ist,i) + &
                                            rayrad_dn(1:nlayers,ist)

        auxrad_stream%meanrad_down_solar(ist,i) = auxrad_stream%meanrad_down_solar(ist,i) + &
                                                  rayrad_dn(iv3lay(i),ist)
      ENDDO

      ! Calculate the contribution from the part-layer above the surface

      ! Layer H2O by volume as fraction:
      IF (opts%rt_all%use_q2m) THEN
        v_h2o = 0.5_jprb * (profiles_dry(prof)%q(iv3lev(i)) + profiles_dry(prof)%s2m%q) * 1.E-6_jprb
      ELSE
        v_h2o = profiles_dry(prof)%q(iv3lev(i)) * 1.E-6_jprb
      ENDIF
      ! Convert ppmv dry to ppmv wet
      v_h2o = v_h2o / (1._jprb + v_h2o)

      ! Average molar weight of wet air for the layer (kg):
      Mwet = ((1._jprb - v_h2o) * Mair + v_h2o * Mh2o) * 1.E-3_jprb

      ! cosine of scattering angle
      cosscata_term1 = SQRT((1._jprb - raytracing%zasat(iv2lay(i), prof) * raytracing%zasat(iv2lay(i), prof)) * &
                        (1._jprb - raytracing%zasun(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof)))
      cosscata_term2 = raytracing%zasat(iv2lay(i), prof) * raytracing%zasun(iv2lay(i), prof) * &
                        COS((profiles(prof)%azangle - profiles(prof)%sunazangle)*deg2rad)
      solar_src = solar_spectrum(i) * & ! mW m^-2 (cm^-1)^-1
            ABS(profiles(prof)%s2m%p - profiles(prof)%p(iv3lev(i))) * 100._jprb * &  ! convert hPa to Pa
            raytracing%pathsat(iv2lay(i), prof) * ss_param / Mwet

      cosscata = - cosscata_term1 - cosscata_term2
      ray_phase = 0.75_jprb * (1._jprb + cosscata * cosscata)
      solar_src_updn = solar_src * ray_phase

      ! Add near-surface contributions to the total radiances
      DO ist = 0, ircld%nstream(prof)
        auxrad_stream%meanrad_up_solar(ist,i) = auxrad_stream%meanrad_up_solar(ist,i) + solar_src_updn * &
                                                transmission_aux%solar_path2%Tau_level(iv3lev(i),ist,i)
      ENDDO

      DO ist = 0, ircld%nstream(prof)
        IF (transmission_aux%solar_path1%Tau_level(iv3lev(i),ist,i) > min_tau) THEN
          auxrad_stream%meanrad_down_solar(ist,i) = auxrad_stream%meanrad_down_solar(ist,i) + solar_src_updn * &
                                                    transmission_aux%solar_path2%Tau_level(iv3lev(i),ist,i) / &
                                                    transmission_aux%solar_path1%Tau_level(iv3lev(i),ist,i) ** 3_jpim
        ENDIF
      ENDDO
    ENDDO
  END SUBROUTINE solar_rayleigh

  SUBROUTINE solar_surface_contribution(transmission_aux, reflectance, auxrad_stream)

    TYPE(rttov_transmission_aux), INTENT(IN)    :: transmission_aux
    REAL(jprb),                   INTENT(IN)    :: reflectance(:)
    TYPE(rttov_radiance_aux),     INTENT(INOUT) :: auxrad_stream

    INTEGER(jpim) :: i, nstreams

    DO i = 1, nchanprof
      IF (solar(i)) THEN
        nstreams = ircld%nstream(prof)
        auxrad_stream%cloudy(0:nstreams,i) = auxrad_stream%cloudy(0:nstreams,i) + &
               solar_spectrum(i) * reflectance(i) * refl_norm(i) * &
               transmission_aux%solar_path2%Tau_surf(0:nstreams,i)
      ENDIF
    ENDDO
  END SUBROUTINE solar_surface_contribution

END SUBROUTINE rttov_integrate
