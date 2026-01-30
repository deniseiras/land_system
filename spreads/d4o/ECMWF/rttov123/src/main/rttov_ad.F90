! Description:
!> @file
!!   Runs RTTOV adjoint (AD) model
!
!> @brief
!!   Runs RTTOV adjoint (AD) model
!!
!! @details
!!   Given the gradient of a scalar function with respect to
!!   channel radiances, computes the gradient of the same scalar
!!   function with respect to the profile variables.
!!   This is the transpose of the tangent linear model.
!!
!!   All AD variables should be initialised to zero before calling.
!!   The input gradients should then be written to the radiance_ad
!!   structure. If opts\%rt_all\%switchrad is false the gradient should
!!   be wrt to radiance in radiance_ad%total, otherwise it is wrt
!!   to BT in radiance_ad\%bt. For visible/near-IR channels (at
!!   wavelengths less than 3 microns) the input gradients are always
!!   in radiance_ad\%total.
!!
!!   For PC-RTTOV the input gradients are specified in pccomp_ad instead.
!!   If opts\%rt_ir\%addpc\%addradrec is false the gradient should be wrt
!!   PC score in pccomp_ad\%pcscores. Otherwise it should be in
!!   pccomp_ad\%total_pccomp or pccomp_ad\%bt_pccomp according to the
!!   setting of opts\%rt_all\%switchrad (false/true respectively).
!!
!! @param[out]    errorstatus       status on exit
!! @param[in]     chanprof          specifies channels and profiles to simulate
!! @param[in]     opts              options to configure the simulations
!! @param[in]     profiles          input atmospheric profiles and surface variables
!! @param[in,out] profiles_ad       output gradient wrt atmospheric profile and surface variables
!! @param[in]     coefs             coefficients structure for instrument to simulate
!! @param[in,out] transmission      output transmittances
!! @param[in,out] transmission_ad   input gradient wrt transmittances (usually zero)
!! @param[in,out] radiance          output radiances and corresponding BTs and BRFs
!! @param[in,out] radiance_ad       input gradient wrt radiances or BTs
!! @param[in]     calcemis          flags for internal RTTOV surface emissivity calculation, optional
!! @param[in,out] emissivity        input/output surface emissivities, optional
!! @param[in,out] emissivity_ad     output gradient wrt surface emissivities, optional
!! @param[in]     calcrefl          flags for internal RTTOV surface BRDF calculation, optional
!! @param[in,out] reflectance       input/output surface BRDFs, input cloud top BRDF for simple cloud, optional
!! @param[in,out] reflectance_ad    output gradient wrt surface BRDFs, optional
!! @param[in]     aer_opt_param     input aerosol optical parameters, optional
!! @param[in,out] aer_opt_param_ad  output gradient wrt aerosol optical parameters, optional
!! @param[in]     cld_opt_param     input cloud optical parameters, optional
!! @param[in,out] cld_opt_param_ad  output gradient wrt cloud optical parameters, optional
!! @param[in,out] traj              RTTOV direct internal state, can be initialised outside RTTOV, optional
!! @param[in,out] traj_ad           RTTOV AD internal state, can be initialised outside RTTOV, optional
!! @param[in,out] pccomp            output PC scores and radiances from PC-RTTOV, optional
!! @param[in,out] pccomp_ad         input gradient wrt PC scores, radiances or BTs for PC-RTTOV, optional
!! @param[in]     channels_rec      list of channels for which to calculate reconstructed radiances, optional
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
SUBROUTINE rttov_ad( &
              errorstatus,       &
              chanprof,          &
              opts,              &
              profiles,          &
              profiles_ad,       &
              coefs,             &
              transmission,      &
              transmission_ad,   &
              radiance,          &
              radiance_ad,       &
              calcemis,          &
              emissivity,        &
              emissivity_ad,     &
              calcrefl,          &
              reflectance,       &
              reflectance_ad,    &
              aer_opt_param,     &
              aer_opt_param_ad,  &
              cld_opt_param,     &
              cld_opt_param_ad,  &
              traj,              &
              traj_ad,           &
              pccomp,            &
              pccomp_ad,         &
              channels_rec)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY :  &
         rttov_coefs,        &
         rttov_pccomp,       &
         rttov_profile,      &
         rttov_transmission, &
         rttov_radiance,     &
         rttov_options,      &
         rttov_chanprof,     &
         rttov_emissivity,   &
         rttov_reflectance,  &
         rttov_opt_param,    &
         rttov_traj
  USE parkind1, ONLY : jpim, jplm
!INTF_OFF
  USE parkind1, ONLY : jprb
  USE rttov_const, ONLY :  &
         sensor_id_mw,     &
         sensor_id_hi,     &
         sensor_id_po,     &
         vis_scatt_dom,    &
         ir_scatt_dom
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE rttov_types, ONLY :  &
         rttov_traj_sta,   &
         rttov_traj_dyn
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),       INTENT(OUT)                     :: errorstatus
  TYPE(rttov_profile),      INTENT(IN)                      :: profiles(:)
  TYPE(rttov_chanprof),     INTENT(IN)                      :: chanprof(:)
  TYPE(rttov_options),      INTENT(IN)                      :: opts
  TYPE(rttov_profile),      INTENT(INOUT)                   :: profiles_ad(SIZE(profiles))
  TYPE(rttov_coefs),        INTENT(IN)   , TARGET           :: coefs
  TYPE(rttov_transmission), INTENT(INOUT)                   :: transmission
  TYPE(rttov_transmission), INTENT(INOUT)                   :: transmission_ad
  TYPE(rttov_radiance),     INTENT(INOUT)                   :: radiance
  TYPE(rttov_radiance),     INTENT(INOUT)                   :: radiance_ad
  LOGICAL(KIND=jplm),       INTENT(IN)   , OPTIONAL         :: calcemis(SIZE(chanprof))
  TYPE(rttov_emissivity),   INTENT(INOUT), OPTIONAL         :: emissivity(SIZE(chanprof))
  TYPE(rttov_emissivity),   INTENT(INOUT), OPTIONAL         :: emissivity_ad(SIZE(chanprof))
  LOGICAL(KIND=jplm),       INTENT(IN)   , OPTIONAL         :: calcrefl(SIZE(chanprof))
  TYPE(rttov_reflectance),  INTENT(INOUT), OPTIONAL         :: reflectance(SIZE(chanprof))
  TYPE(rttov_reflectance),  INTENT(INOUT), OPTIONAL         :: reflectance_ad(SIZE(chanprof))
  TYPE(rttov_opt_param),    INTENT(IN)   , OPTIONAL         :: aer_opt_param
  TYPE(rttov_opt_param),    INTENT(INOUT), OPTIONAL         :: aer_opt_param_ad
  TYPE(rttov_opt_param),    INTENT(IN)   , OPTIONAL         :: cld_opt_param
  TYPE(rttov_opt_param),    INTENT(INOUT), OPTIONAL         :: cld_opt_param_ad
  TYPE(rttov_traj),         INTENT(INOUT), OPTIONAL, TARGET :: traj, traj_ad       ! target is needed here
  TYPE(rttov_pccomp),       INTENT(INOUT), OPTIONAL         :: pccomp
  TYPE(rttov_pccomp),       INTENT(INOUT), OPTIONAL         :: pccomp_ad
  INTEGER(KIND=jpim),       INTENT(IN)   , OPTIONAL         :: channels_rec(:)
!INTF_END
#include "rttov_add_aux_prof.interface"
#include "rttov_add_opdp_path.interface"
#include "rttov_add_prof.interface"
#include "rttov_add_raytracing.interface"
#include "rttov_alloc_traj_dyn.interface"
#include "rttov_alloc_traj_sta.interface"
#include "rttov_apply_reg_limits_ad.interface"
#include "rttov_apply_pc_aer_reg_lims_ad.interface"
#include "rttov_calcbt_ad.interface"
#include "rttov_calcbt_pc_ad.interface"
#include "rttov_calcemis_ir_ad.interface"
#include "rttov_calcemis_mw_ad.interface"
!#include "rttov_calcsatrefl_ad.interface"
#include "rttov_calcsurfrefl_ad.interface"
#include "rttov_check_traj.interface"
#include "rttov_cldstr_ad.interface"
#include "rttov_convert_profile_units_ad.interface"
#include "rttov_direct.interface"
#include "rttov_dom_ad.interface"
#include "rttov_dom_setup_profile_ad.interface"
#include "rttov_errorreport.interface"
#include "rttov_fresnel_ad.interface"
#include "rttov_init_aux_prof.interface"
#include "rttov_init_auxrad_stream.interface"
!#include "rttov_init_ircld.interface"
#include "rttov_init_opdp_path.interface"
#include "rttov_init_predictor.interface"
#include "rttov_init_prof.interface"
#include "rttov_init_prof_internal.interface"
#include "rttov_init_raytracing.interface"
#include "rttov_init_sunglint.interface"
#include "rttov_init_trans_scatt_ir.interface"
#include "rttov_init_transmission_aux.interface"
#include "rttov_intavg_chan_ad.interface"
#include "rttov_intavg_prof_ad.interface"
#include "rttov_integrate_ad.interface"
#include "rttov_mfasis_ad.interface"
#include "rttov_mw_clw_absorption_ad.interface"
#include "rttov_nlte_bias_correction_ad.interface"
#include "rttov_opdep_9_ad.interface"
#include "rttov_opdep_ad.interface"
#include "rttov_opdpscattir_ad.interface"
#include "rttov_pcscores_ad.interface"
#include "rttov_profaux_ad.interface"
#include "rttov_reconstruct_ad.interface"
#include "rttov_refsun_ad.interface"
#include "rttov_setgeometry_ad.interface"
#include "rttov_setpredictors_78_ad.interface"
#include "rttov_setpredictors_9_ad.interface"
#include "rttov_transmit_9_solar_ad.interface"
#include "rttov_transmit_ad.interface"

  INTEGER(KIND=jpim) :: err
  INTEGER(KIND=jpim) :: nlevels, nprofiles, nchanprof, npcscores
  LOGICAL(KIND=jplm) :: sensor_mw

  TYPE(rttov_options) :: opts_coef

  TYPE(rttov_traj), TARGET  :: traj1
  TYPE(rttov_traj), POINTER :: traj0
  TYPE(rttov_traj), TARGET  :: traj1_ad
  TYPE(rttov_traj), POINTER :: traj0_ad
  TYPE(rttov_traj_dyn) :: traj0_dyn
  TYPE(rttov_traj_sta) :: traj0_sta
  TYPE(rttov_traj_dyn) :: traj0_ad_dyn
  LOGICAL(KIND=jplm)   :: ltraj_ad_dyn_dealloc

  REAL(KIND=jprb) :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------
  TRY
  IF (LHOOK) CALL DR_HOOK('RTTOV_AD', 0_jpim, ZHOOK_HANDLE)

!-------------
! Initialize
!-------------
  IF (opts%htfrtc_opts%htfrtc) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0, "HT-FRTC: AD model not available")
  ENDIF

  nprofiles                 = SIZE(profiles)
  nchanprof                 = SIZE(chanprof)
  opts_coef                 = opts
  opts_coef%rt_ir%addaerosl = .FALSE.
  opts_coef%rt_ir%addclouds = .FALSE.
  nlevels                   = profiles(1)%nlevels
  errorstatus               = errorstatus_success
  sensor_mw                 = coefs%coef%id_sensor == sensor_id_mw .OR. &
                              coefs%coef%id_sensor == sensor_id_po

  ltraj_ad_dyn_dealloc = .FALSE.
  traj0_dyn%from_tladk = .TRUE.

  IF (opts%rt_ir%pc%addpc) npcscores = opts%rt_ir%pc%npcscores * nprofiles

  NULLIFY (traj0, traj0_ad)
  CALL rttov_check_traj( &
          err,                 &
          nprofiles,           &
          nchanprof,           &
          opts,                &
          nlevels,             &
          coefs,               &
          1_jpim,              &
          traj0 = traj0,       &
          traj0_ad = traj0_ad, &
          traj1 = traj1,       &
          traj1_ad = traj1_ad, &
          traj2 = traj,        &
          traj2_ad = traj_ad)
  THROWM(err.NE.0, "rttov_check_traj fatal error")

!-----------------------------------------------------------------------
! Call direct model
!-----------------------------------------------------------------------
  CALL rttov_direct( &
              err,                           &
              chanprof,                      &
              opts,                          &
              profiles,                      &
              coefs,                         &
              transmission,                  &
              radiance,                      &
              calcemis      = calcemis,      &
              emissivity    = emissivity,    &
              calcrefl      = calcrefl,      &
              reflectance   = reflectance,   &
              aer_opt_param = aer_opt_param, &
              cld_opt_param = cld_opt_param, &
              traj          = traj0,         &
              traj_dyn      = traj0_dyn,     &
              traj_sta      = traj0_sta,     &
              pccomp        = pccomp,        &
              channels_rec  = channels_rec)
  THROW(err.NE.0)

  ! If no channels are active (thermal and solar flags false for all channels) then
  ! skip to the end. In particular this can happen when using the parallel interface.
  IF (.NOT. (traj0_sta%dothermal .OR. traj0_sta%dosolar)) GOTO 998

  IF (traj0_sta%dothermal .AND. .NOT. PRESENT(emissivity_ad)) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0, "emissivity_ad parameter required")
  END IF
  IF (traj0_sta%dosolar .AND. .NOT. PRESENT(reflectance_ad)) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0, "reflectance_ad parameter required")
  END IF

  radiance_ad%plane_parallel = traj0_sta%plane_parallel
  radiance_ad%quality        = radiance%quality

  CALL rttov_alloc_traj_dyn(err, traj0_ad_dyn, opts, coefs, nchanprof, profiles(1)%nlayers, &
                            traj0_dyn%nstreams, traj0_sta%dom_nstreams, &
                            traj0_sta%thermal, traj0_sta%solar, traj0_sta%do_mfasis, 1_jpim, traj0_dyn)
  THROW(err.NE.0)
  ltraj_ad_dyn_dealloc = .TRUE.


!----------------
! Adjoint
!----------------

!---------------------------------------------
! Initialize AD variables
!---------------------------------------------
  ! xstrclr and xstr are the only ircld variables used outside rttov_cldstr:
  ! if traj_ad is not passed in by the user some time can be saved
  ! by avoiding unnecessary initialisations in traj0_ad%ircld
!   CALL rttov_init_ircld(traj0_ad%ircld)
  traj0_ad%ircld%xstrclr = 0._jprb
  IF (opts%rt_ir%addclouds) THEN
    traj0_ad%ircld%xstr = 0._jprb
  ENDIF
  IF (opts%rt_ir%addaerosl .OR. opts%rt_ir%addclouds) THEN
    CALL rttov_init_trans_scatt_ir(traj0_ad%transmission_scatt_ir)
    CALL rttov_init_trans_scatt_ir(traj0_ad_dyn%transmission_scatt_ir_dyn)
  ENDIF

  IF (traj0_sta%do_opdep_calc) THEN
    CALL rttov_init_opdp_path(opts, traj0_ad%opdp_path)
    CALL rttov_init_opdp_path(opts, traj0_ad%opdp_path_coef)
    CALL rttov_init_predictor(opts%rt_ir%addsolar, traj0_ad%predictors)

    CALL rttov_init_raytracing(traj0_sta%dosolar, traj0_ad%raytracing_coef)
    CALL rttov_init_prof(traj0_ad%profiles_coef)
    CALL rttov_init_aux_prof(traj0_ad%aux_prof_coef)
  ENDIF

  CALL rttov_init_raytracing(traj0_sta%dosolar, traj0_ad%raytracing)
  CALL rttov_init_prof_internal(traj0_ad%profiles_int)
  CALL rttov_init_aux_prof(traj0_ad%aux_prof)

  IF (.NOT. traj0_sta%do_mfasis) THEN
    CALL rttov_init_transmission_aux(opts, traj0_ad_dyn%transmission_aux)
    CALL rttov_init_auxrad_stream(traj0_ad_dyn%auxrad_stream)
  ENDIF

  traj0_ad%diffuse_refl(:) = 0._jprb
  IF (traj0_sta%dosolar) THEN
    traj0_ad%fresnrefl(:) = 0._jprb
    CALL rttov_init_sunglint(traj0_ad%sunglint)
  ENDIF

  traj0_ad%auxrad%surfair(:) = 0._jprb
  traj0_ad%auxrad%skin(:)    = 0._jprb
  traj0_ad%auxrad%air(:,:)   = 0._jprb

  ! Copy units from direct model profile (not strictly essential for AD code)
  profiles_ad(:)%gas_units = profiles(1)%gas_units
  profiles_ad(:)%mmr_cldaer = profiles(1)%mmr_cldaer

!--------------------------------------------------
! Set up radiance/BT inputs
!--------------------------------------------------
  IF (opts%rt_ir%pc%addpc) THEN

    IF (opts%rt_ir%pc%addradrec) THEN

      IF (opts%rt_all%switchrad) THEN
        CALL rttov_calcbt_pc_ad(         &
                traj0_sta%chanprof_in,   &
                coefs%coef_pccomp,       &
                pccomp,                  &
                pccomp_ad)
      ENDIF

      CALL rttov_reconstruct_ad( &
              opts                 ,   &
              traj0_sta%chanprof_in,   &
              traj0_sta%chanprof_pc,   &
              pccomp_ad,               &
              coefs%coef_pccomp)

    ENDIF

    CALL rttov_pcscores_ad( &
            opts,                   &
            chanprof,               &
            traj0_sta%chanprof_pc,  &
            pccomp_ad,              &
            coefs%coef_pccomp,      &
            radiance_ad)

  ELSEIF (.NOT. traj0_sta%do_mfasis) THEN

    ! Classical RTTOV
    IF (opts%rt_all%switchrad) THEN
      IF (traj0_sta%dothermal) &
        CALL rttov_calcbt_ad(opts, chanprof, coefs%coef, traj0_sta%thermal, radiance, radiance_ad)
!       Input AD perturbation is always in radiance for pure-solar channels, never in reflectance
!       IF (traj0_sta%dosolar) &
!         CALL rttov_calcsatrefl_ad(chanprof, profiles, traj0_sta%solar_spec_esd, &
!                                   traj0_sta%thermal, traj0_sta%solar, radiance_ad)
    ELSE
! AJGDB this prevents RTTOV-SCATT using the clear radiance as adjoint input
!      radiance_ad%clear(:) = 0._jprb
    ENDIF

  ENDIF

!---------------------------------------------------------
! Do NLTE bias correction for hyperspectral instruments
!---------------------------------------------------------
  IF (coefs%coef%nltecoef) THEN
    IF (opts%rt_ir%do_nlte_correction .AND. coefs%coef%id_sensor == sensor_id_hi) THEN
      CALL rttov_nlte_bias_correction_ad(coefs%coef, profiles, profiles_ad, chanprof, radiance_ad)
    ENDIF
  ENDIF

!---------------------------------------------------------
! Solve the radiative transfer equation - user levs
!---------------------------------------------------------
  IF (traj0_sta%do_mfasis) THEN

    CALL rttov_mfasis_ad( &
            err,                            &
            chanprof,                       &
            traj0_sta%solar,                &
            opts,                           &
            profiles,                       &
            profiles_ad,                    &
            traj0%profiles_int,             &
            traj0_ad%profiles_int,          &
            coefs,                          &
            traj0%ircld,                    &
            traj0_ad%ircld,                 &
            traj0%aux_prof,                 &
            traj0_ad%aux_prof,              &
            reflectance,                    &
            reflectance_ad,                 &
            traj0_sta%solar_spec_esd,       &
            traj0%transmission_scatt_ir,    &
            traj0_ad%transmission_scatt_ir, &
            traj0_dyn%mfasis_refl,          &
            radiance_ad)
    THROW(err.NE.0)

  ELSE
    IF (traj0_sta%dothermal .AND. (opts%rt_ir%addclouds .OR. opts%rt_ir%addaerosl) .AND. &
        opts%rt_ir%ir_scatt_model == ir_scatt_dom) THEN
      CALL rttov_dom_ad(                                    &
            err,                                            &
            chanprof,                                       &
            .FALSE._jplm,                                   &  ! FALSE => thermal source term
            traj0_sta%thermal,                              &
            traj0_sta%dom_nstreams,                         &
            profiles,                                       &
            traj0_dyn%profiles_dom_thermal,                 &
            traj0_ad_dyn%profiles_dom_thermal,              &
            MAXVAL(traj0_dyn%profiles_dom_thermal%nlayers), &
            traj0%auxrad,                                   &
            traj0_ad%auxrad,                                &
            traj0%transmission_scatt_ir,                    &
            traj0_ad%transmission_scatt_ir,                 &
            traj0_dyn%transmission_scatt_ir_dyn,            &
            traj0_ad_dyn%transmission_scatt_ir_dyn,         &
            emissivity,                                     &
            emissivity_ad,                                  &
            reflectance,                                    &
            reflectance_ad,                                 &
            traj0%diffuse_refl,                             &
            traj0_ad%diffuse_refl,                          &
            traj0_sta%solar_spec_esd,                       &
            traj0%raytracing,                               &
            traj0%ircld,                                    &
            traj0_ad%ircld,                                 &
            radiance_ad,                                    &
            traj0_dyn%dom_state_thermal)
      THROW(err.NE.0)

      CALL rttov_dom_setup_profile_ad(              &
            err,                                    &
            opts,                                   &
            coefs%coef,                             &
            chanprof,                               &
            .FALSE._jplm,                           &  ! FALSE => thermal source term
            traj0_sta%thermal,                      &
            profiles(1)%nlayers,                    &
            traj0%aux_prof,                         &
            traj0_ad%aux_prof,                      &
            traj0%opdp_path%atm_level,              &
            traj0_ad%opdp_path%atm_level,           &
            traj0_sta%angles,                       &
            traj0%ircld,                            &
            traj0%transmission_scatt_ir,            &
            traj0_ad%transmission_scatt_ir,         &
            traj0_dyn%profiles_dom_thermal,         &
            traj0_ad_dyn%profiles_dom_thermal)
      THROW(err.NE.0)
    ENDIF

    IF (traj0_sta%dosolar .AND. (opts%rt_ir%addclouds .OR. opts%rt_ir%addaerosl) .AND. &
        opts%rt_ir%vis_scatt_model == vis_scatt_dom) THEN
      CALL rttov_dom_ad(                                  &
            err,                                          &
            chanprof,                                     &
            .TRUE._jplm,                                  &  ! TRUE => solar source term
            traj0_sta%solar,                              &
            traj0_sta%dom_nstreams,                       &
            profiles,                                     &
            traj0_dyn%profiles_dom_solar,                 &
            traj0_ad_dyn%profiles_dom_solar,              &
            MAXVAL(traj0_dyn%profiles_dom_solar%nlayers), &
            traj0%auxrad,                                 &
            traj0_ad%auxrad,                              &
            traj0%transmission_scatt_ir,                  &
            traj0_ad%transmission_scatt_ir,               &
            traj0_dyn%transmission_scatt_ir_dyn,          &
            traj0_ad_dyn%transmission_scatt_ir_dyn,       &
            emissivity,                                   &
            emissivity_ad,                                &
            reflectance,                                  &
            reflectance_ad,                               &
            traj0%diffuse_refl,                           &
            traj0_ad%diffuse_refl,                        &
            traj0_sta%solar_spec_esd,                     &
            traj0%raytracing,                             &
            traj0%ircld,                                  &
            traj0_ad%ircld,                               &
            radiance_ad,                                  &
            traj0_dyn%dom_state_solar)
      THROW(err.NE.0)

      CALL rttov_dom_setup_profile_ad(              &
            err,                                    &
            opts,                                   &
            coefs%coef,                             &
            chanprof,                               &
            .TRUE._jplm,                            &  ! TRUE => solar source term
            traj0_sta%solar,                        &
            profiles(1)%nlayers,                    &
            traj0%aux_prof,                         &
            traj0_ad%aux_prof,                      &
            traj0%opdp_path%sun_level_path2,        &
            traj0_ad%opdp_path%sun_level_path2,     &
            traj0_sta%angles,                       &
            traj0%ircld,                            &
            traj0%transmission_scatt_ir,            &
            traj0_ad%transmission_scatt_ir,         &
            traj0_dyn%profiles_dom_solar,           &
            traj0_ad_dyn%profiles_dom_solar)
      THROW(err.NE.0)
    ENDIF

    CALL rttov_integrate_ad( &
            sensor_mw,                                 &
            opts,                                      &
            traj0_dyn%nstreams,                        &
            chanprof,                                  &
            emissivity,                                &
            emissivity_ad,                             &
            reflectance,                               &
            reflectance_ad,                            &
            traj0_sta%refl_norm,                       &
            traj0%diffuse_refl,                        &
            traj0_ad%diffuse_refl,                     &
            traj0_sta%do_lambertian,                   &
            traj0_sta%thermal,                         &
            traj0_sta%dothermal,                       &
            traj0_sta%solar,                           &
            traj0_sta%dosolar,                         &
            traj0_sta%solar_spec_esd,                  &
            traj0_dyn%transmission_aux,                &
            traj0_ad_dyn%transmission_aux,             &
            traj0%transmission_scatt_ir,               &
            traj0_ad%transmission_scatt_ir,            &
            profiles,                                  &
            profiles_ad,                               &
            traj0%profiles_int,                        &
            traj0_ad%profiles_int,                     &
            traj0%aux_prof,                            &
            traj0_ad%aux_prof,                         &
            coefs%coef,                                &
            traj0%raytracing,                          &
            traj0_ad%raytracing,                       &
            traj0%ircld,                               &
            traj0_ad%ircld,                            &
            radiance,                                  &
            traj0%auxrad,                              &
            traj0_ad%auxrad,                           &
            traj0_dyn%auxrad_stream,                   &
            traj0_ad_dyn%auxrad_stream,                &
            radiance_ad)! inout  (output if conversion Bt -> rad)
  ENDIF ! .NOT. do_mfasis

!-------------------------------------------------------
! Calculate surface reflectance
!-------------------------------------------------------
  IF (traj0_sta%dosolar) THEN

    CALL rttov_calcsurfrefl_ad( &
            coefs%coef,              &
            profiles,                &
            traj0%sunglint,          &
            traj0_ad%sunglint,       &
            traj0%fresnrefl,         &
            traj0_ad%fresnrefl,      &
            traj0_sta%solar,         &
            chanprof,                &
            traj0_sta%refl_norm,     &
            calcrefl,                &
            emissivity_ad,           &
            reflectance_ad%refl_out, &
            traj0_ad%diffuse_refl)

    IF (ANY(calcrefl)) THEN
      CALL rttov_fresnel_ad( &
              chanprof,           &
              calcrefl,           &
              profiles,           &
              traj0_sta%solar,    &
              coefs%coef,         &
              traj0%sunglint,     &
              traj0_ad%sunglint,  &
              traj0_ad%fresnrefl)

      CALL rttov_refsun_ad( &
              opts,                &
              profiles,            &
              profiles_ad,         &
              coefs%coef,          &
              traj0%aux_prof,      &
              traj0%sunglint,      &
              traj0_ad%sunglint,   &
              traj0%raytracing,    &
              traj0_ad%raytracing)
    ENDIF

    reflectance_ad%refl_in = reflectance_ad%refl_in + reflectance_ad%refl_out

  ENDIF

!-------------------------------------------------
! Calculate surface emissivity
!-------------------------------------------------
  IF (traj0_sta%dothermal) THEN

    IF (ANY(calcemis)) THEN
      ! Calculate surface emissivity and traj0%diffuse_refl for selected channels

      IF (sensor_mw) THEN
        CALL rttov_calcemis_mw_ad( &
                opts,                               &
                profiles,                           &
                profiles_ad,                        &
                traj0_sta%angles,                   &
                coefs%coef,                         &
                chanprof,                           &
                traj0_dyn%transmission_aux,         &
                traj0_ad_dyn%transmission_aux,      &
                calcemis,                           &
                emissivity_ad%emis_out,             &
                traj0_ad%diffuse_refl)
      ELSE
        WHERE (calcemis)
          emissivity_ad(:)%emis_out = emissivity_ad(:)%emis_out - traj0_ad%diffuse_refl(:)
        ENDWHERE

        CALL rttov_calcemis_ir_ad( &
                err,               &
                opts,              &
                chanprof,          &
                profiles,          &
                profiles_ad,       &
                coefs,             &
                traj0_sta%thermal, &
                calcemis,          &
                emissivity_ad%emis_out)
        THROWM(err.NE.0, "calcemis_ir_ad")
      ENDIF

    ENDIF

    WHERE (.NOT. calcemis)
      emissivity_ad%emis_out = emissivity_ad%emis_out - traj0_ad%diffuse_refl
    ENDWHERE

    emissivity_ad%emis_in = emissivity_ad%emis_in + emissivity_ad%emis_out

  ENDIF

!-------------------------------------------------
! Calculate transmittances - user levs
!-------------------------------------------------
  IF (.NOT. traj0_sta%do_mfasis) THEN
    IF (traj0_sta%dosolar) THEN
      CALL rttov_transmit_9_solar_ad( &
              opts,                                      &
              profiles(1)%nlayers,                       &
              nprofiles,                                 &
              chanprof,                                  &
              traj0_sta%solar,                           &
              traj0%aux_prof,                            &
              traj0_ad%aux_prof,                         &
              coefs%coef,                                &
              traj0%raytracing,                          &
              traj0_ad%raytracing,                       &
              traj0%ircld,                               &
              traj0_ad%opdp_path,                        &
              traj0_sta%solar_path2,                     &
              traj0_sta%solar_path1,                     &
              transmission_ad,                           &
              traj0_dyn%transmission_aux,                &
              traj0_ad_dyn%transmission_aux,             &
              traj0%transmission_scatt_ir,               &
              traj0_ad%transmission_scatt_ir,            &
              traj0_dyn%transmission_scatt_ir_dyn,       &
              traj0_ad_dyn%transmission_scatt_ir_dyn)
    ENDIF

    IF (traj0_sta%dothermal) THEN
      CALL rttov_transmit_ad( &
              opts,                                        &
              traj0_sta%do_lambertian,                     &
              profiles(1)%nlayers,                         &
              chanprof,                                    &
              traj0_sta%thermal,                           &
              traj0%aux_prof,                              &
              traj0_ad%aux_prof,                           &
              coefs%coef,                                  &
              traj0%ircld,                                 &
              traj0_sta%angles,                            &
              traj0_ad%opdp_path%atm_level,                &
              traj0_sta%thermal_path1%od_level,            &
              transmission_ad%tau_levels,                  &
              transmission_ad%tau_total,                   &
              traj0_dyn%transmission_aux%thermal_path1,    &
              traj0_ad_dyn%transmission_aux%thermal_path1, &
              traj0_ad%transmission_scatt_ir,              &
              traj0_dyn%transmission_scatt_ir_dyn,         &
              traj0_ad_dyn%transmission_scatt_ir_dyn,      &
              traj0_sta%thermal_path1%tau_ref,             &
              traj0_sta%thermal_path1%tau_ref_surf,        &
              traj0_sta%thermal_path1%tau_surf,            &
              traj0_sta%thermal_path1%tau_level)
    ENDIF
  ENDIF ! .NOT. do_mfasis

!----------------------------------------------------------------------------
! Calculate optical depths of aerosols and/or clouds - user levs
!----------------------------------------------------------------------------
  IF (opts%rt_ir%addaerosl .OR. opts%rt_ir%addclouds) THEN
    CALL rttov_opdpscattir_ad( &
            profiles(1)%nlayers,                     &
            chanprof,                                &
            opts,                                    &
            traj0_sta%dom_nstreams,                  &
            traj0%aux_prof,                          &
            traj0_ad%aux_prof,                       &
            traj0%ircld,                             &
            profiles,                                &
            profiles_ad,                             &
            traj0%profiles_int,                      &
            traj0_ad%profiles_int,                   &
            aer_opt_param,                           &
            aer_opt_param_ad,                        &
            cld_opt_param,                           &
            cld_opt_param_ad,                        &
            traj0_sta%dothermal,                     &
            traj0_sta%thermal,                       &
            traj0_sta%dosolar,                       &
            traj0_sta%solar,                         &
            coefs%coef,                              &
            coefs%coef_scatt_ir,                     &
            coefs%optp,                              &
            coefs%coef_mfasis_cld,                   &
            traj0%raytracing,                        &
            traj0_ad%raytracing,                     &
            traj0%transmission_scatt_ir,             &
            traj0_ad%transmission_scatt_ir,          &
            traj0_dyn%transmission_scatt_ir_dyn,     &
            traj0_ad_dyn%transmission_scatt_ir_dyn)
  ENDIF

!--------------------------------------------------------------------
! If clouds are present calculate the number of streams and
! the cloud distribution in each stream - user levs
!--------------------------------------------------------------------
  IF (opts%rt_ir%addclouds) THEN
    CALL rttov_cldstr_ad( &
            opts%rt_ir,         &
            profiles,           &
            profiles_ad,        &
            traj0%profiles_int, &
            traj0%ircld,        &
            traj0_ad%ircld)
  ENDIF

!--------------------------------------------------------------------------
! MW CLW absorption optical depths on user levels
!--------------------------------------------------------------------------
  IF (sensor_mw .AND. opts%rt_mw%clw_data .AND. .NOT. opts%rt_mw%clw_calc_on_coef_lev) THEN
    CALL rttov_mw_clw_absorption_ad( &
            opts,                &
            coefs%coef,          &
            chanprof,            &
            traj0_sta%angles,    &
            traj0%raytracing,    &
            traj0_ad%raytracing, &
            profiles,            &
            profiles_ad,         &
            traj0%aux_prof,      &
            traj0_ad%aux_prof,   &
            traj0_ad%opdp_path)
  ENDIF

!------------------------------------------------------------------------
! Set up common geometric variables for the RT integration - user levels
!------------------------------------------------------------------------
  IF (opts%interpolation%addinterp .OR. .NOT. traj0_sta%do_opdep_calc) THEN
    CALL rttov_setgeometry_ad( &
        opts,                     &
        traj0_sta%dosolar,        &
        traj0_sta%plane_parallel, &
        profiles,                 &
        profiles_ad,              &
        traj0%aux_prof,           &
        coefs%coef,               &
        traj0_sta%angles,         &
        traj0%raytracing,         &
        traj0_ad%raytracing,      &
        traj0%profiles_int,       &
        traj0_ad%profiles_int)
  ELSE
    CALL rttov_add_raytracing(traj0_sta%dosolar, traj0_ad%raytracing_coef, &
                              traj0_ad%raytracing_coef, traj0_ad%raytracing)
  ENDIF

!------------------------------------------------------------------------
! Determine cloud top, surface levels, rel. hum. calcs for aerosol, liquid/ice Deff - user levels
!------------------------------------------------------------------------
  IF (opts%rt_ir%addclouds .OR. opts%rt_ir%addaerosl .OR. &
      opts%interpolation%addinterp .OR. .NOT. traj0_sta%do_opdep_calc) THEN
    CALL rttov_profaux_ad( &
        opts,                  &
        profiles,              &
        profiles_ad,           &
        traj0%profiles_int,    &
        traj0_ad%profiles_int, &
        coefs%coef,            &
        traj0%aux_prof,        &
        traj0_ad%aux_prof)
  ELSE
    CALL rttov_add_aux_prof(traj0_ad%aux_prof_coef, traj0_ad%aux_prof_coef, traj0_ad%aux_prof)
  ENDIF

!-----------------------------------------------------------------------
! RTTOV optical depth calculation: on coef levels
!-----------------------------------------------------------------------

  IF (traj0_sta%do_opdep_calc) THEN
!--------------------------------------------------------------------------
! Move top level to space boundary (opdep=0) if spacetop flag is set
!--------------------------------------------------------------------------
    IF (opts%interpolation%spacetop) THEN
      traj0_ad%opdp_path%atm_level(1,:) = 0._jprb
      IF (opts%rt_ir%addsolar) THEN
        traj0_ad%opdp_path%sun_level_path2(1,:) = 0._jprb
      ENDIF
    ENDIF

!--------------------------------------------------------------------------
! Interpolator second  call - optical depths from coef levs to user levs
!--------------------------------------------------------------------------
    IF (opts%interpolation%addinterp) THEN
      CALL rttov_intavg_chan_ad( &
              opts,                           &
              traj0_sta%thermal,              &
              traj0_sta%solar,                &
              coefs%coef%nlevels,             &
              nlevels,                        &
              chanprof,                       &
              traj0%profiles_coef,            &
              profiles,                       &
              profiles_ad,                    &
              traj0%opdp_path_coef,           &
              traj0_ad%opdp_path_coef,        &
              traj0_ad%opdp_path)
    ELSE
      CALL rttov_add_opdp_path(opts, traj0_ad%opdp_path_coef, traj0_ad%opdp_path_coef, traj0_ad%opdp_path)
    ENDIF

!--------------------------------------------------------------------------
! MW CLW absorption optical depths on coef levels
!--------------------------------------------------------------------------
    IF (sensor_mw .AND. opts%rt_mw%clw_data .AND. opts%rt_mw%clw_calc_on_coef_lev) THEN
      CALL rttov_mw_clw_absorption_ad( &
              opts,                     &
              coefs%coef,               &
              chanprof,                 &
              traj0_sta%angles_coef,    &
              traj0%raytracing_coef,    &
              traj0_ad%raytracing_coef, &
              traj0%profiles_coef,      &
              traj0_ad%profiles_coef,   &
              traj0%aux_prof_coef,      &
              traj0_ad%aux_prof_coef,   &
              traj0_ad%opdp_path_coef)
    ENDIF

!--------------------------------------------------------------------
! Predict atmospheric (emissive) and solar optical depths - coef levs
!--------------------------------------------------------------------
    IF (coefs%coef%fmv_model_ver == 9) THEN
      IF (traj0_sta%dosolar) THEN
        ! Calculate solar path2 optical depths for solar channels
        CALL rttov_opdep_9_ad( &
                coefs%coef%nlayers,                      &
                chanprof,                                &
                traj0_sta%solar,                         &
                traj0%predictors%path2,                  &
                traj0_ad%predictors%path2,               &
                coefs%coef,                              &
                coefs%coef%solar,                        &
                traj0_ad%opdp_path_coef%sun_level_path2, &
                traj0_sta%solar_path2%opdp_ref_coef,     &
                thermal = .FALSE._jplm)
      ENDIF
      IF (traj0_sta%dothermal) THEN
        ! Calculate thermal path1 optical depths for thermal channels
        CALL rttov_opdep_9_ad( &
                coefs%coef%nlayers,                    &
                chanprof,                              &
                traj0_sta%thermal,                     &
                traj0%predictors%path1,                &
                traj0_ad%predictors%path1,             &
                coefs%coef,                            &
                coefs%coef%thermal,                    &
                traj0_ad%opdp_path_coef%atm_level,     &
                traj0_sta%thermal_path1%opdp_ref_coef, &
                thermal = .TRUE._jplm)
      ENDIF
    ELSE
      CALL rttov_opdep_ad( &
              coefs%coef%nlayers,           &
              chanprof,                     &
              traj0_ad%predictors%path1,    &
              coefs%coef,                   &
              coefs%coef%thermal,           &
              traj0_ad%opdp_path_coef,      &
              traj0_sta%thermal_path1%opdp_ref_coef)
    ENDIF

!---------------------------------------------------
! Calculate predictors - coef levs
!---------------------------------------------------
    IF (coefs%coef%fmv_model_ver < 9) THEN
      CALL rttov_setpredictors_78_ad( &
              opts,                      &
              traj0%profiles_coef,       &
              coefs%coef,                &
              traj0%aux_prof_coef,       &
              traj0_ad%aux_prof_coef,    &
              traj0%predictors%path1,    &
              traj0_ad%predictors%path1, &
              traj0%raytracing_coef,     &
              traj0_ad%raytracing_coef)
    ELSE ! IF (coefs%coef%fmv_model_ver == 9) THEN
      IF (traj0_sta%dosolar) THEN
        CALL rttov_setpredictors_9_ad(            &
                opts,                             &
                traj0%profiles_coef,              &
                traj0_ad%profiles_coef,           &
                traj0%raytracing_coef%patheff,    &
                traj0_ad%raytracing_coef%patheff, &
                coefs%coef_pccomp,                &
                coefs%coef,                       &
                traj0%aux_prof_coef,              &
                traj0%predictors%path2,           &
                traj0_ad%predictors%path2)
      ENDIF
      IF (traj0_sta%dothermal) THEN
        CALL rttov_setpredictors_9_ad(            &
                opts,                             &
                traj0%profiles_coef,              &
                traj0_ad%profiles_coef,           &
                traj0%raytracing_coef%pathsat,    &
                traj0_ad%raytracing_coef%pathsat, &
                coefs%coef_pccomp,                &
                coefs%coef,                       &
                traj0%aux_prof_coef,              &
                traj0%predictors%path1,           &
                traj0_ad%predictors%path1)
      ENDIF
    ENDIF

!------------------------------------------------------------------------
! Set up common geometric variables for the RT integration - coef levels
!------------------------------------------------------------------------
    CALL rttov_setgeometry_ad( &
        opts,                     &
        traj0_sta%dosolar,        &
        traj0_sta%plane_parallel, &
        traj0%profiles_coef,      &
        traj0_ad%profiles_coef,   &
        traj0%aux_prof_coef,      &
        coefs%coef,               &
        traj0_sta%angles_coef,    &
        traj0%raytracing_coef,    &
        traj0_ad%raytracing_coef, &
        traj0%profiles_coef,      &
        traj0_ad%profiles_coef,   &
        .TRUE._jplm)  ! do_pmc_calc on coef levels

!------------------------------------------------------------------------
! Determine cloud top, surface levels, predictor pre-calculations - coef levels
!------------------------------------------------------------------------
    CALL rttov_profaux_ad( &
            opts_coef,              &
            traj0%profiles_coef,    &
            traj0_ad%profiles_coef, &
            traj0%profiles_coef,    &
            traj0_ad%profiles_coef, &
            coefs%coef,             &
            traj0%aux_prof_coef,    &
            traj0_ad%aux_prof_coef)

!------------------------------------------------------------------
! Check input data is within suitable physical limits - coef levs
!------------------------------------------------------------------
    IF (opts%config%apply_reg_limits .OR. opts%interpolation%addinterp) THEN
      CALL rttov_apply_reg_limits_ad( &
              opts,                        &
              profiles,                    &
              traj0_sta%profiles_coef_ref, &
              traj0_ad%profiles_coef,      &
              coefs%coef,                  &
              coefs%coef_pccomp)
    ENDIF

!-----------------------------------------------------------------------
! Interpolator first call - input profiles from user levs to coef levs
!-----------------------------------------------------------------------
    IF (opts%interpolation%addinterp) THEN
      CALL rttov_intavg_prof_ad( &
              opts,                           &
              nlevels,                        &
              coefs%coef%nlevels,             &
              profiles,                       &
              profiles_ad,                    &
              traj0%profiles_int,             &
              traj0_ad%profiles_int,          &
              traj0%profiles_coef,            &
              traj0_ad%profiles_coef,         &
              coefs%coef,                     &
              coefs%coef_pccomp)
    ELSE
      ! If interpolator is off copy profile variables
      CALL rttov_add_prof( &
              profiles_ad,            &
              profiles_ad,            &
              traj0_ad%profiles_coef, &
              larray = .TRUE._jplm,   &
              lscalar = .FALSE._jplm, &
              profiles_gas = traj0_ad%profiles_int)
    ENDIF

    ! Copy non-interpolated variables (e.g. surface parameters)
    CALL rttov_add_prof( &
            profiles_ad,            &
            profiles_ad,            &
            traj0_ad%profiles_coef, &
            larray = .FALSE._jplm,  &
            lscalar = .TRUE._jplm,  &
            profiles_gas = traj0_ad%profiles_int)

  ENDIF ! do_opdep_calc

!-----------------------------------------------------------------------
! Apply PC-RTTOV aerosol regression limits
!-----------------------------------------------------------------------
  IF (opts%rt_ir%pc%addpc .AND. opts%rt_ir%addaerosl) THEN
    CALL rttov_apply_pc_aer_reg_lims_ad( &
          opts,                  &
          coefs%coef_pccomp,     &
          profiles,              &
          traj0_ad%profiles_int, &
          traj0_sta%pc_aer_ref,  &
          traj0_sta%pc_aer_min,  &
          traj0_sta%pc_aer_max)
  ENDIF

!-----------------------------------------------------------------------
! Convert input profiles to units used internally
!-----------------------------------------------------------------------
  CALL rttov_convert_profile_units_ad( &
      opts,                            &
      coefs,                           &
      profiles,                        &
      profiles_ad,                     &
      traj0%profiles_int,              &
      traj0_ad%profiles_int)

!---------------------
! Deallocate memory
!---------------------
998 CONTINUE ! no channels are active
  CALL cleanup()

  IF (LHOOK) CALL DR_HOOK('RTTOV_AD', 1_jpim, ZHOOK_HANDLE)
  CATCH_C
  errorstatus = err
  IF (LHOOK) CALL DR_HOOK('RTTOV_AD', 1_jpim, ZHOOK_HANDLE)

CONTAINS

  SUBROUTINE cleanup()
    INTEGER(KIND=jpim) :: error

    IF (opts%htfrtc_opts%htfrtc) RETURN

    IF (ltraj_ad_dyn_dealloc) THEN
      CALL rttov_alloc_traj_dyn(error, traj0_ad_dyn, opts, coefs, nchanprof, profiles(1)%nlayers, &
                                traj0_dyn%nstreams, traj0_sta%dom_nstreams, &
                                traj0_sta%thermal, traj0_sta%solar, traj0_sta%do_mfasis, 0_jpim, traj0_dyn)
    ENDIF

    IF (traj0_dyn%nstreams >= 0) THEN
      CALL rttov_alloc_traj_dyn(error, traj0_dyn, opts, coefs, nchanprof, profiles(1)%nlayers, &
                                traj0_dyn%nstreams, traj0_sta%dom_nstreams, &
                                traj0_sta%thermal, traj0_sta%solar, traj0_sta%do_mfasis, 0_jpim)
    ENDIF

    IF (ASSOCIATED(traj0_sta%thermal)) THEN
      CALL rttov_alloc_traj_sta(error, traj0_sta, opts, coefs, chanprof, profiles, &
                                0_jpim, npcscores, channels_rec)
    ENDIF

    IF (ASSOCIATED(traj0)) THEN
      CALL rttov_check_traj( &
              error,               &
              nprofiles,           &
              nchanprof,           &
              opts,                &
              nlevels,             &
              coefs,               &
              0_jpim,              &
              traj0 = traj0,       &
              traj0_ad = traj0_ad, &
              traj1 = traj1,       &
              traj1_ad = traj1_ad, &
              traj2 = traj,        &
              traj2_ad = traj_ad)
    ENDIF
  END SUBROUTINE cleanup

END SUBROUTINE rttov_ad
