! Description:
!> @file
!!   TL of combined optical properties of aerosols and/or clouds.
!
!> @brief
!!   TL of combined optical properties of aerosols and/or clouds.
!!
!! @details
!!   TL of combined optical properties of aerosols and/or clouds.
!!
!! @param[in]     nlayers                number of layers in input profile
!! @param[in]     chanprof               specifies channels and profiles to simulate
!! @param[in]     opts                   options to configure the simulations
!! @param[in]     dom_nstr               number of DOM streams
!! @param[in]     aux                    additional internal profile variables
!! @param[in,out] aux_tl                 additional internal profile variable perturbations
!! @param[in]     ircld                  computed cloud column data
!! @param[in]     profiles               input atmospheric profiles and surface variables
!! @param[in]     profiles_tl            atmospheric profiles and surface variable perturbations
!! @param[in]     profiles_int           profiles in internal units
!! @param[in]     profiles_int_tl        profile perturbations in internal units
!! @param[in]     aer_opt_param          explicit aerosol optical properties per channel (optional)
!! @param[in]     aer_opt_param_tl       explicit aerosol optical property perturbations (optional)
!! @param[in]     cld_opt_param          explicit cloud optical properties per channel (optional)
!! @param[in]     cld_opt_param_tl       explicit cloud optical property perturbations (optional)
!! @param[in]     do_thermal             flag to indicate if any thermal (emissive) simulations are being performed
!! @param[in]     thermal                per-channel flag to indicate if thermal (emissive) simulations are being performed
!! @param[in]     do_solar               flag to indicate if any solar simulations are being performed
!! @param[in]     solar                  per-channel flag to indicate if any solar simulations are being performed
!! @param[in]     coef                   optical depth coefficients structure
!! @param[in]     coef_scatt_ir          IR scattering coefficients structure
!! @param[in]     optp                   optical properties coefficients structure
!! @param[in]     coef_mfasis_cld        MFASIS cloud coefficients structure
!! @param[in]     raytracing             raytracing structure
!! @param[in]     raytracing_tl          TL of raytracing structure
!! @param[in]     trans_scatt_ir         computed optical depths
!! @param[in,out] trans_scatt_ir_tl      computed optical depth perturbations
!! @param[in]     trans_scatt_ir_dyn     computed optical depths per cloud column and phase functions
!! @param[in,out] trans_scatt_ir_dyn_tl  computed optical depth perturbations per cloud column and phase function perturbations
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
SUBROUTINE rttov_opdpscattir_tl( &
              nlayers,             &
              chanprof,            &
              opts,                &
              dom_nstr,            &
              aux,                 &
              aux_tl,              &
              ircld,               &
              profiles,            &
              profiles_tl,         &
              profiles_int,        &
              profiles_int_tl,     &
              aer_opt_param,       &
              aer_opt_param_tl,    &
              cld_opt_param,       &
              cld_opt_param_tl,    &
              do_thermal,          &
              thermal,             &
              do_solar,            &
              solar,               &
              coef,                &
              coef_scatt_ir,       &
              optp,                &
              coef_mfasis_cld,     &
              raytracing,          &
              raytracing_tl,       &
              trans_scatt_ir,      &
              trans_scatt_ir_tl,   &
              trans_scatt_ir_dyn,  &
              trans_scatt_ir_dyn_tl)

  USE rttov_types, ONLY :  &
       rttov_chanprof,              &
       rttov_options,               &
       rttov_coef,                  &
       rttov_profile,               &
       rttov_opt_param,             &
       rttov_raytracing,            &
       rttov_transmission_scatt_ir, &
       rttov_coef_scatt_ir,         &
       rttov_optpar_ir,             &
       rttov_coef_mfasis,           &
       rttov_profile_aux,           &
       rttov_ircld
  USE parkind1, ONLY : jpim, jplm
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jprb
  USE rttov_const, ONLY :  &
       realtol,            &
       deg2rad,            &
       ncldtyp,            &
       nwcl_max,           &
       vis_scatt_dom,      &
       vis_scatt_single,   &
       vis_scatt_mfasis,   &
       ir_scatt_dom,       &
       ir_scatt_chou,      &
       nphangle_lores,     &
       phangle_lores,      &
       nphangle_hires,     &
       phangle_hires,      &
       baran_ngauss,       &
       clw_scheme_deff,    &
       ice_scheme_ssec,    &
       ice_scheme_baran2018
  USE rttov_types, ONLY : rttov_scatt_ir_aercld
  USE rttov_scattering_mod, ONLY :  &
       spline_interp_tl,            &
       normalise_tl,                &
       calc_legendre_coef_gauss_tl
!INTF_ON
  IMPLICIT NONE
  INTEGER(KIND=jpim),                INTENT(IN)    :: nlayers
  TYPE(rttov_chanprof),              INTENT(IN)    :: chanprof(:)
  TYPE(rttov_options),               INTENT(IN)    :: opts
  INTEGER(KIND=jpim),                INTENT(IN)    :: dom_nstr
  TYPE(rttov_profile_aux),           INTENT(IN)    :: aux
  TYPE(rttov_profile_aux),           INTENT(INOUT) :: aux_tl
  TYPE(rttov_ircld),                 INTENT(IN)    :: ircld
  TYPE(rttov_profile),               INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),               INTENT(IN)    :: profiles_tl(SIZE(profiles))
  TYPE(rttov_profile),               INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_profile),               INTENT(IN)    :: profiles_int_tl(SIZE(profiles))
  TYPE(rttov_opt_param),   OPTIONAL, INTENT(IN)    :: aer_opt_param
  TYPE(rttov_opt_param),   OPTIONAL, INTENT(IN)    :: aer_opt_param_tl
  TYPE(rttov_opt_param),   OPTIONAL, INTENT(IN)    :: cld_opt_param
  TYPE(rttov_opt_param),   OPTIONAL, INTENT(IN)    :: cld_opt_param_tl
  LOGICAL(KIND=jplm),                INTENT(IN)    :: do_thermal
  LOGICAL(KIND=jplm),                INTENT(IN)    :: thermal(SIZE(chanprof))
  LOGICAL(KIND=jplm),                INTENT(IN)    :: do_solar
  LOGICAL(KIND=jplm),                INTENT(IN)    :: solar(SIZE(chanprof))
  TYPE(rttov_coef),                  INTENT(IN)    :: coef
  TYPE(rttov_coef_scatt_ir),         INTENT(IN)    :: coef_scatt_ir
  TYPE(rttov_optpar_ir),             INTENT(IN)    :: optp
  TYPE(rttov_coef_mfasis),           INTENT(IN)    :: coef_mfasis_cld
  TYPE(rttov_raytracing),            INTENT(IN)    :: raytracing
  TYPE(rttov_raytracing),            INTENT(IN)    :: raytracing_tl
  TYPE(rttov_transmission_scatt_ir), INTENT(IN)    :: trans_scatt_ir
  TYPE(rttov_transmission_scatt_ir), INTENT(INOUT) :: trans_scatt_ir_tl
  TYPE(rttov_transmission_scatt_ir), INTENT(IN)    :: trans_scatt_ir_dyn
  TYPE(rttov_transmission_scatt_ir), INTENT(INOUT) :: trans_scatt_ir_dyn_tl
!INTF_END

#include "rttov_baran2014_calc_optpar_tl.interface"
#include "rttov_baran2018_calc_optpar_tl.interface"
#include "rttov_baran_calc_phase_tl.interface"

  LOGICAL(KIND=jplm) :: do_dom, do_chou_scaling, do_single_scatt, do_mfasis
  LOGICAL(KIND=jplm) :: do_dom_chan, do_chou_scaling_chan, do_single_scatt_chan, do_mfasis_chan, do_chan
  INTEGER(KIND=jpim) :: nchanprof
  INTEGER(KIND=jpim) :: j, k, k1, k2
  INTEGER(KIND=jpim) :: prof, chan, phchan
  INTEGER(KIND=jpim) :: clw_scheme, ice_scheme, ist, isti, iaer, icld
  INTEGER(KIND=jpim) :: lev, lay
  REAL(KIND=jprb)    :: opd_tl, opdsun_tl
  REAL(KIND=jprb)    :: dgfrac, dgfrac_tl
  REAL(KIND=jprb)    :: abso, abso_tl
  REAL(KIND=jprb)    :: sca, sca_tl
  REAL(KIND=jprb)    :: sumsca, sumsca_tl
  REAL(KIND=jprb)    :: bpr, bpr_tl
  REAL(KIND=jprb)    :: asym, asym_tl
  REAL(KIND=jprb)    :: clw, clw_tl, tmpval
  REAL(KIND=jprb)    :: afac, sfac, gfac, frach, frach_tl
  REAL(KIND=jprb)    :: pfac1(0:dom_nstr)
  REAL(KIND=jprb)    :: pfac2(coef_scatt_ir%aer_nphangle)

  INTEGER(KIND=jpim) :: nmom
  REAL(KIND=jprb)    :: legcoef(0:dom_nstr), thislegcoef(0:dom_nstr)
  REAL(KIND=jprb)    :: legcoefcld(0:dom_nstr)
  REAL(KIND=jprb)    :: legcoef_tl(0:dom_nstr), thislegcoef_tl(0:dom_nstr)
  REAL(KIND=jprb)    :: aer_phfn(coef_scatt_ir%aer_nphangle)
  REAL(KIND=jprb)    :: aer_phfn_tl(coef_scatt_ir%aer_nphangle)
  REAL(KIND=jprb)    :: wcldeff_phfn(coef_scatt_ir%wcldeff_nphangle)
  REAL(KIND=jprb)    :: wcldeff_phfn_tl(coef_scatt_ir%wcldeff_nphangle)
  REAL(KIND=jprb)    :: icl_phfn(coef_scatt_ir%icl_nphangle)
  REAL(KIND=jprb)    :: icl_phfn_tl(coef_scatt_ir%icl_nphangle)
  REAL(KIND=jprb)    :: zminphadiff
  REAL(KIND=jprb)    :: relazi, musat, musun
  REAL(KIND=jprb)    :: musat_tl, musun_tl, phasint_tl
  INTEGER(KIND=jpim) :: thisnphangle
  REAL(KIND=jprb)    :: thisphangle(nphangle_hires), thiscosphangle(nphangle_hires)
  REAL(KIND=jprb)    :: baran_phfn(1:nphangle_hires), baran_phfn_tl(1:nphangle_hires)
  REAL(KIND=jprb)    :: baran_phfn_interp(baran_ngauss), baran_phfn_interp_tl(baran_ngauss)

  TYPE(rttov_scatt_ir_aercld), POINTER :: aer, aer_tl, cld, cld_tl

  REAL   (KIND=JPRB) :: ZHOOK_HANDLE
!-----End of header-------------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_OPDPSCATTIR_TL', 0_jpim, ZHOOK_HANDLE)
  nchanprof = SIZE(chanprof)

  do_dom = (do_solar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom) .OR. &
           (do_thermal .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom)
  do_chou_scaling = do_thermal .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
  do_single_scatt = do_solar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single
  do_mfasis = do_solar .AND. opts%rt_ir%vis_scatt_model == vis_scatt_mfasis

  IF (do_thermal) trans_scatt_ir_tl%opdpacl = 0._jprb
  IF (do_solar .AND. .NOT. do_mfasis) THEN
    trans_scatt_ir_tl%opdpaclsun = 0._jprb
    trans_scatt_ir_tl%phup = 0._jprb
  ENDIF
  IF (do_single_scatt) trans_scatt_ir_tl%phdo = 0._jprb
  IF (do_dom) THEN
    DO j = 1, nchanprof
      IF (ASSOCIATED(trans_scatt_ir_dyn_tl%phasefn(j)%legcoef)) &
          trans_scatt_ir_dyn_tl%phasefn(j)%legcoef = 0._jprb
    ENDDO
  ENDIF
  IF (do_mfasis) trans_scatt_ir_tl%opdpext = 0._jprb

  !----------------------------------------------------------------------------
  ! CALCULATE OPTICAL DEPTHS OF AEROSOLS
  !----------------------------------------------------------------------------

  IF (opts%rt_ir%addaerosl) THEN

    aer    => trans_scatt_ir%aer
    aer_tl => trans_scatt_ir_tl%aer

    aer_tl%opdpabs = 0._jprb
    aer_tl%opdpsca = 0._jprb
    IF (do_chou_scaling) aer_tl%opdpscabpr = 0._jprb
    IF (do_solar .AND. .NOT. do_mfasis) aer_tl%phtotup = 0._jprb
    IF (do_single_scatt) aer_tl%phtotdo = 0._jprb
    IF (do_dom) aer_tl%sca = 0._jprb

    IF (opts%rt_ir%user_aer_opt_param) THEN

      CALL calc_user_opt_param_tl(aer_opt_param, aer_opt_param_tl, aer, aer_tl, 0_jpim)

    ELSE

      DO j = 1, nchanprof
        chan = chanprof(j)%chan
        prof = chanprof(j)%prof
        relazi = profiles(prof)%azangle - profiles(prof)%sunazangle

        do_dom_chan = (solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom) .OR. &
                      (thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom)
        do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
        do_single_scatt_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single
        do_mfasis_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_mfasis
        do_chan = thermal(j) .OR. solar(j)

        DO lay = 1, nlayers

          !----------------------------------------------------------------------
          ! Calculate combined aerosol parameters for layer
          !----------------------------------------------------------------------
          IF (do_dom_chan) THEN
            sumsca = 0._jprb
            sumsca_tl = 0._jprb
            legcoef(:) = 0._jprb
            legcoef_tl(:) = 0._jprb
          ENDIF

          DO iaer = 1, coef_scatt_ir%fmv_aer_comp
            IF (profiles_int(prof)%aerosols(iaer,lay) <= 0._jprb) CYCLE

            IF (do_dom_chan) THEN
              thislegcoef(:) = 0._jprb
              thislegcoef_tl(:) = 0._jprb
            ENDIF

            k = coef_scatt_ir%fmv_aer_rh(iaer)
            IF (k /= 1 .AND. aux%relhum(lay,prof) <= optp%optpaer(iaer)%fmv_aer_rh_val(k)) THEN
              ! Interpolate scattering parameters to actual value of relative humidity
              DO k = 1, coef_scatt_ir%fmv_aer_rh(iaer) - 1
                IF (aux%relhum(lay,prof) >= optp%optpaer(iaer)%fmv_aer_rh_val(k) .AND. &
                    aux%relhum(lay,prof) <= optp%optpaer(iaer)%fmv_aer_rh_val(k+1)) THEN
                  frach = (aux%relhum(lay,prof) - optp%optpaer(iaer)%fmv_aer_rh_val(k)) / &
                          (optp%optpaer(iaer)%fmv_aer_rh_val(k+1) - &
                           optp%optpaer(iaer)%fmv_aer_rh_val(k))
                  afac  = (optp%optpaer(iaer)%abs(chan,k+1) - optp%optpaer(iaer)%abs(chan,k))
                  abso  = optp%optpaer(iaer)%abs(chan,k) + afac * frach
                  sfac  = (optp%optpaer(iaer)%sca(chan,k+1) - optp%optpaer(iaer)%sca(chan,k))
                  sca   = optp%optpaer(iaer)%sca(chan,k) + sfac * frach

                  frach_tl = aux_tl%relhum(lay,prof) / &
                             (optp%optpaer(iaer)%fmv_aer_rh_val(k+1) - &
                              optp%optpaer(iaer)%fmv_aer_rh_val(k))
                  abso_tl  = afac * frach_tl
                  sca_tl   = sfac * frach_tl

                  IF (do_chou_scaling_chan) THEN
                    gfac  = (optp%optpaer(iaer)%bpr(chan,k+1) - optp%optpaer(iaer)%bpr(chan,k))
                    bpr   = optp%optpaer(iaer)%bpr(chan,k) + gfac * frach
                    bpr_tl = gfac * frach_tl
                  ENDIF

                  IF (do_dom_chan) THEN
                    nmom = MIN(MAX(optp%optpaer(iaer)%nmom(chan,k), optp%optpaer(iaer)%nmom(chan,k+1)), dom_nstr)
                    pfac1(0:nmom) = (optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k+1) - &
                                     optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k))
                    thislegcoef(0:nmom) = optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k) + pfac1(0:nmom) * frach
                    thislegcoef_tl(0:nmom) = pfac1(0:nmom) * frach_tl
                  ENDIF

                  IF (solar(j) .AND. .NOT. do_mfasis_chan) THEN
                    phchan = coef_scatt_ir%aer_pha_index(chan)
                    pfac2(:) = (optp%optpaer(iaer)%pha(:,phchan,k+1) - &
                                optp%optpaer(iaer)%pha(:,phchan,k))
                    aer_phfn(:) = optp%optpaer(iaer)%pha(:,phchan,k) + pfac2(:) * frach
                    aer_phfn_tl(:) = pfac2(:) * frach_tl
                  ENDIF
                  EXIT
                ENDIF
              ENDDO
            ELSE
              ! Particle doesn't change with rel. hum. (k=1) or rel. hum. exceeds max (k=max_rh_index)
              abso = optp%optpaer(iaer)%abs(chan,k)
              sca  = optp%optpaer(iaer)%sca(chan,k)

              abso_tl = 0._jprb
              sca_tl  = 0._jprb

              IF (do_chou_scaling_chan) THEN
                bpr = optp%optpaer(iaer)%bpr(chan,k)
                bpr_tl = 0._jprb
              ENDIF

              IF (do_dom_chan) THEN
                nmom = MIN(optp%optpaer(iaer)%nmom(chan,k), dom_nstr)
                thislegcoef(0:nmom) = optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k)
                thislegcoef_tl(0:nmom) = 0._jprb
              ENDIF

              IF (solar(j) .AND. .NOT. do_mfasis_chan) THEN
                phchan = coef_scatt_ir%aer_pha_index(chan)
                aer_phfn(:) = optp%optpaer(iaer)%pha(:,phchan,k)
                aer_phfn_tl(:) = 0._jprb
              ENDIF
            ENDIF

            IF (do_mfasis_chan) THEN
              trans_scatt_ir_tl%opdpext(iaer,lay,j) = coef%ff_gam(chan) * &
                (profiles_int_tl(prof)%aerosols(iaer,lay) * raytracing%ltick(lay,prof) * (abso + sca) + &
                 profiles_int(prof)%aerosols(iaer,lay) * raytracing_tl%ltick(lay,prof) * (abso + sca) + &
                 profiles_int(prof)%aerosols(iaer,lay) * raytracing%ltick(lay,prof) * (abso_tl + sca_tl))
            ELSEIF (do_chan) THEN
              !------------------------------------------------------------------
              ! Accumulate total aerosol optical parameters (all particles)
              !------------------------------------------------------------------
              ! For pre-defined particle types OD calculated as (aerosol amount in layer) *
              !   (aerosol ext coeff for given layer RH) * (layer thickness)
              ! OD is accumulated for each aerosol type - arrays are zeroed above.
              aer_tl%opdpabs(lay,j) = aer_tl%opdpabs(lay,j) + &
                profiles_int_tl(prof)%aerosols(iaer,lay) * abso * raytracing%ltick(lay,prof) + &
                profiles_int(prof)%aerosols(iaer,lay) * abso_tl * raytracing%ltick(lay,prof) + &
                profiles_int(prof)%aerosols(iaer,lay) * abso * raytracing_tl%ltick(lay,prof)

              aer_tl%opdpsca(lay,j) = aer_tl%opdpsca(lay,j) + &
                profiles_int_tl(prof)%aerosols(iaer,lay) * sca * raytracing%ltick(lay,prof) + &
                profiles_int(prof)%aerosols(iaer,lay) * sca_tl * raytracing%ltick(lay,prof) + &
                profiles_int(prof)%aerosols(iaer,lay) * sca * raytracing_tl%ltick(lay,prof)

              IF (do_chou_scaling_chan) THEN
                aer_tl%opdpscabpr(lay,j) = aer_tl%opdpscabpr(lay,j) + &
                  profiles_int_tl(prof)%aerosols(iaer,lay) * sca * bpr * raytracing%ltick(lay,prof) + &
                  profiles_int(prof)%aerosols(iaer,lay) * sca_tl * bpr * raytracing%ltick(lay,prof) + &
                  profiles_int(prof)%aerosols(iaer,lay) * sca * bpr_tl * raytracing%ltick(lay,prof) + &
                  profiles_int(prof)%aerosols(iaer,lay) * sca * bpr * raytracing_tl%ltick(lay,prof)
              ENDIF

              IF (do_dom_chan) THEN
                sumsca = sumsca + profiles_int(prof)%aerosols(iaer,lay) * sca
                sumsca_tl = sumsca_tl + profiles_int_tl(prof)%aerosols(iaer,lay) * sca + &
                                        profiles_int(prof)%aerosols(iaer,lay) * sca_tl
                legcoef(:) = legcoef(:) + thislegcoef(:) * profiles_int(prof)%aerosols(iaer,lay) * sca
                legcoef_tl(:) = legcoef_tl(:) + &
                  thislegcoef_tl(:) * profiles_int(prof)%aerosols(iaer,lay) * sca + &
                  thislegcoef(:) * profiles_int_tl(prof)%aerosols(iaer,lay) * sca + &
                  thislegcoef(:) * profiles_int(prof)%aerosols(iaer,lay) * sca_tl
              ENDIF

              IF (solar(j)) THEN
                musat =  1._jprb / raytracing%pathsat(lay,prof)
                musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
                musun = -1._jprb / raytracing%pathsun(lay,prof)
                musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
                zminphadiff = coef_scatt_ir%aer_phfn_int%zminphadiff / deg2rad

                CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                     aer_phfn, coef_scatt_ir%aer_phfn_int%cosphangle, &
                                     coef_scatt_ir%aer_phfn_int%iphangle, phasint_tl, aer_phfn_tl)

                aer_tl%phtotup(lay,j) = aer_tl%phtotup(lay,j) + &
                    profiles_int_tl(prof)%aerosols(iaer,lay) * &
                    aer%phintup(iaer,lay,j) * sca * raytracing%ltick(lay,prof) + &
                    profiles_int(prof)%aerosols(iaer,lay) * &
                    phasint_tl * sca * raytracing%ltick(lay,prof) + &
                    profiles_int(prof)%aerosols(iaer,lay) * &
                    aer%phintup(iaer,lay,j) * sca_tl * raytracing%ltick(lay,prof) + &
                    profiles_int(prof)%aerosols(iaer,lay) * &
                    aer%phintup(iaer,lay,j) * sca * raytracing_tl%ltick(lay,prof)

                IF (do_single_scatt_chan) THEN
                  musat = -musat
                  musat_tl = -musat_tl

                  CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                     aer_phfn, coef_scatt_ir%aer_phfn_int%cosphangle, &
                                     coef_scatt_ir%aer_phfn_int%iphangle, phasint_tl, aer_phfn_tl)

                  aer_tl%phtotdo(lay,j) = aer_tl%phtotdo(lay,j) + &
                      profiles_int_tl(prof)%aerosols(iaer,lay) * &
                      aer%phintdo(iaer,lay,j) * sca * raytracing%ltick(lay,prof) + &
                      profiles_int(prof)%aerosols(iaer,lay) * &
                      phasint_tl * sca * raytracing%ltick(lay,prof) + &
                      profiles_int(prof)%aerosols(iaer,lay) * &
                      aer%phintdo(iaer,lay,j) * sca_tl * raytracing%ltick(lay,prof) + &
                      profiles_int(prof)%aerosols(iaer,lay) * &
                      aer%phintdo(iaer,lay,j) * sca * raytracing_tl%ltick(lay,prof)
                ENDIF
              ENDIF
            ENDIF
          ENDDO ! aer types

          !------------------------------------------------------------------
          ! Calculate final phase function Leg. coefs for all aerosol types
          !------------------------------------------------------------------
          IF (do_dom_chan) THEN
            IF (ABS(sumsca) > realtol) THEN
              aer_tl%sca(lay,j) = sumsca_tl
              trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,0,lay) = &
                  legcoef_tl(:) / sumsca - sumsca_tl * legcoef(:) / sumsca ** 2_jpim
            ENDIF
          ENDIF
        ENDDO ! layers
      ENDDO ! chanprof
    ENDIF ! scaer coef file

    DO j = 1, nchanprof
      do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
      do_single_scatt_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single
      do_mfasis_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_mfasis

      !------------------------------------------------------------------------
      ! Calculate total aerosol optical depths
      !------------------------------------------------------------------------
      IF (thermal(j)) THEN
        IF (do_chou_scaling_chan) THEN
          ! Chou-scaled optical depth for thermal channels
          aer_tl%opdp(:,j) = aer_tl%opdpabs(:,j) + aer_tl%opdpscabpr(:,j)
        ELSE
          ! Full optical depth for thermal channels
          aer_tl%opdp(:,j) = aer_tl%opdpabs(:,j) + aer_tl%opdpsca(:,j)
        ENDIF
      ENDIF

      IF (solar(j) .AND. .NOT. do_mfasis_chan) THEN
        WHERE (ABS(aer%opdpsca(:,j)) > realtol)
          trans_scatt_ir_tl%phup(0,:,j) = aer_tl%phtotup(:,j) / aer%opdpsca(:,j) - &
              aer_tl%opdpsca(:,j) * aer%phtotup(:,j) / aer%opdpsca(:,j)**2
        ENDWHERE
        IF (do_single_scatt_chan) THEN
          WHERE (ABS(aer%opdpsca(:,j)) > realtol)
            trans_scatt_ir_tl%phdo(0,:,j) = aer_tl%phtotdo(:,j) / aer%opdpsca(:,j) - &
                aer_tl%opdpsca(:,j) * aer%phtotdo(:,j) / aer%opdpsca(:,j)**2
          ENDWHERE
        ENDIF

        ! Full optical depth for solar channels
        aer_tl%opdpsun(:,j) = aer_tl%opdpabs(:,j) + aer_tl%opdpsca(:,j)
      ENDIF
    ENDDO ! chanprof
  ENDIF ! opts%rt_ir%addaerosl


  !----------------------------------------------------------------------------
  ! CALCULATE OPTICAL DEPTHS OF CLOUDS
  !----------------------------------------------------------------------------
  IF (opts%rt_ir%addclouds) THEN

    cld    => trans_scatt_ir%cld
    cld_tl => trans_scatt_ir_tl%cld

    IF (.NOT. do_mfasis) THEN
      cld_tl%opdpabs = 0._jprb
      cld_tl%opdpsca = 0._jprb
    ENDIF
    IF (do_chou_scaling) cld_tl%opdpscabpr = 0._jprb
    IF (do_solar .AND. .NOT. do_mfasis) cld_tl%phtotup = 0._jprb
    IF (do_single_scatt) cld_tl%phtotdo = 0._jprb
    IF (do_dom) cld_tl%sca = 0._jprb

    IF (opts%rt_ir%user_cld_opt_param) THEN

      CALL calc_user_opt_param_tl(cld_opt_param, cld_opt_param_tl, cld, cld_tl, 1_jpim)

    ELSE

      DO j = 1, nchanprof
        chan = chanprof(j)%chan
        prof = chanprof(j)%prof
        relazi = profiles(prof)%azangle - profiles(prof)%sunazangle

        do_dom_chan = (solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom) .OR. &
                      (thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom)
        do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
        do_single_scatt_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single
        do_mfasis_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_mfasis
        do_chan = thermal(j) .OR. solar(j)

        IF (do_mfasis_chan) THEN
          clw_scheme = coef_mfasis_cld%clw_scheme
          ice_scheme = coef_mfasis_cld%ice_scheme
        ELSE
          clw_scheme = profiles(prof)%clw_scheme
          ice_scheme = profiles(prof)%ice_scheme
        ENDIF

        DO lay = 1, nlayers
          IF (do_dom_chan) THEN
            sumsca = 0._jprb
            sumsca_tl = 0._jprb
            legcoef = 0._jprb
            legcoef_tl = 0._jprb
          ENDIF

          DO icld = 1, ncldtyp

            IF (icld <= nwcl_max) THEN
              !--------------------------------------------------------------
              ! Water clouds
              !--------------------------------------------------------------

              IF (clw_scheme == clw_scheme_deff) THEN
                !--------------------------------------------------------------
                ! Water clouds - Deff scheme
                !--------------------------------------------------------------

                ! Combine all input CLW values
                IF (icld > 1) CYCLE
                clw = SUM(profiles_int(prof)%cloud(1:nwcl_max,lay))

                IF (.NOT. clw > 0._jprb .OR. .NOT. aux%clw_dg(lay,prof) > 0._jprb) CYCLE

                clw_tl = SUM(profiles_int_tl(prof)%cloud(1:nwcl_max,lay))

                ! Interpolate optical parameters based on aux%clw_dg

                IF (aux%clw_dg(lay,prof) >= optp%optpwcldeff%fmv_wcldeff_deff(1) .AND. &
                    aux%clw_dg(lay,prof) < optp%optpwcldeff%fmv_wcldeff_deff(coef_scatt_ir%fmv_wcldeff_ndeff)) THEN
                  ! Find deff index below this channel
                  DO k1 = 1, coef_scatt_ir%fmv_wcldeff_ndeff - 1
                    IF (optp%optpwcldeff%fmv_wcldeff_deff(k1+1) > aux%clw_dg(lay,prof)) EXIT
                  ENDDO
                  k2 = k1 + 1
                  dgfrac = (aux%clw_dg(lay,prof) - optp%optpwcldeff%fmv_wcldeff_deff(k1)) / &
                           (optp%optpwcldeff%fmv_wcldeff_deff(k2) - optp%optpwcldeff%fmv_wcldeff_deff(k1))
                  dgfrac_tl = aux_tl%clw_dg(lay,prof) / &
                              (optp%optpwcldeff%fmv_wcldeff_deff(k2) - optp%optpwcldeff%fmv_wcldeff_deff(k1))
                ELSE
                  ! Take first or last value if deff lies beyond data range
                  IF (aux%clw_dg(lay,prof) < optp%optpwcldeff%fmv_wcldeff_deff(1)) THEN
                    k1 = 1
                    k2 = 1
                  ELSE
                    k1 = coef_scatt_ir%fmv_wcldeff_ndeff
                    k2 = coef_scatt_ir%fmv_wcldeff_ndeff
                  ENDIF
                  dgfrac = 0._jprb
                  dgfrac_tl = 0._jprb
                ENDIF

                IF (do_mfasis_chan) THEN
                  trans_scatt_ir_tl%opdpext(icld,lay,j) = &
                    coef%ff_gam(chan) * &
                    ((clw_tl * raytracing%ltick(lay,prof) + &
                      clw * raytracing_tl%ltick(lay,prof)) * &
                     (optp%optpwcldeff%abs(k1,chan) + dgfrac * &
                      (optp%optpwcldeff%abs(k2,chan) - optp%optpwcldeff%abs(k1,chan)) + &
                      optp%optpwcldeff%sca(k1,chan) + dgfrac * &
                      (optp%optpwcldeff%sca(k2,chan) - optp%optpwcldeff%sca(k1,chan))) + &
                    clw * raytracing%ltick(lay,prof) * &
                    dgfrac_tl * (optp%optpwcldeff%abs(k2,chan) - optp%optpwcldeff%abs(k1,chan) + &
                                 optp%optpwcldeff%sca(k2,chan) - optp%optpwcldeff%sca(k1,chan)))

                ELSEIF (do_chan) THEN
                  cld_tl%opdpabs(lay,j) = cld_tl%opdpabs(lay,j) + &
                    (clw_tl * raytracing%ltick(lay,prof) + &
                     clw * raytracing_tl%ltick(lay,prof)) * &
                    (optp%optpwcldeff%abs(k1,chan) + dgfrac * &
                    (optp%optpwcldeff%abs(k2,chan) - optp%optpwcldeff%abs(k1,chan))) + &
                    clw * raytracing%ltick(lay,prof) * &
                    dgfrac_tl * (optp%optpwcldeff%abs(k2,chan) - optp%optpwcldeff%abs(k1,chan))

                  sca = (optp%optpwcldeff%sca(k1,chan) + dgfrac * &
                    (optp%optpwcldeff%sca(k2,chan) - optp%optpwcldeff%sca(k1,chan))) * clw
                  sca_tl = &
                    dgfrac_tl * (optp%optpwcldeff%sca(k2,chan) - optp%optpwcldeff%sca(k1,chan)) * clw + &
                    (optp%optpwcldeff%sca(k1,chan) + dgfrac * &
                    (optp%optpwcldeff%sca(k2,chan) - optp%optpwcldeff%sca(k1,chan))) * clw_tl
                  cld_tl%partsca(icld,lay,j) = sca_tl * raytracing%ltick(lay,prof) + &
                    sca * raytracing_tl%ltick(lay,prof)
                  cld_tl%opdpsca(lay,j) = cld_tl%opdpsca(lay,j) + cld_tl%partsca(icld,lay,j)

                  IF (do_chou_scaling_chan) THEN
                    cld_tl%partbpr(icld,lay,j) = &
                      dgfrac_tl * (optp%optpwcldeff%bpr(k2,chan) - optp%optpwcldeff%bpr(k1,chan))
                    cld_tl%opdpscabpr(lay,j) = cld_tl%opdpscabpr(lay,j) + &
                      cld_tl%partbpr(icld,lay,j) * cld%partsca(icld,lay,j) + &
                      cld%partbpr(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                  ENDIF

                  IF (do_dom_chan) THEN
                    thislegcoef(:) = 0._jprb
                    sumsca = sumsca + sca
                    sumsca_tl = sumsca_tl + sca_tl
                    nmom = MIN(optp%optpwcldeff%nmom(1,chan), dom_nstr)
                    thislegcoef(0:nmom) = &
                      optp%optpwcldeff%legcoef(1:nmom+1,k1,chan) + dgfrac * &
                      (optp%optpwcldeff%legcoef(1:nmom+1,k2,chan) - optp%optpwcldeff%legcoef(1:nmom+1,k1,chan))
                    thislegcoef_tl(0:nmom) = &
                      dgfrac_tl * (optp%optpwcldeff%legcoef(1:nmom+1,k2,chan) - optp%optpwcldeff%legcoef(1:nmom+1,k1,chan))

                    legcoef(:) = legcoef(:) + thislegcoef(:) * sca
                    legcoef_tl(:) = legcoef_tl(:) + thislegcoef_tl(:) * sca + thislegcoef(:) * sca_tl
                  ENDIF

                  IF (solar(j)) THEN
                    musat =  1._jprb / raytracing%pathsat(lay,prof)
                    musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
                    musun = -1._jprb / raytracing%pathsun(lay,prof)
                    musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
                    zminphadiff = coef_scatt_ir%wcldeff_phfn_int%zminphadiff / deg2rad

                    phchan = coef_scatt_ir%wcldeff_pha_index(chan)
                    wcldeff_phfn(:) = &
                      optp%optpwcldeff%pha(:,k1,phchan) + dgfrac * &
                      (optp%optpwcldeff%pha(:,k2,phchan) - optp%optpwcldeff%pha(:,k1,phchan))
                    wcldeff_phfn_tl(:) = &
                      dgfrac_tl * (optp%optpwcldeff%pha(:,k2,phchan) - optp%optpwcldeff%pha(:,k1,phchan))

                    CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                         wcldeff_phfn, coef_scatt_ir%wcldeff_phfn_int%cosphangle, &
                                         coef_scatt_ir%wcldeff_phfn_int%iphangle, phasint_tl, wcldeff_phfn_tl)

                    cld_tl%phtotup(lay,j) = cld_tl%phtotup(lay,j) + &
                        phasint_tl * cld%partsca(icld,lay,j) + &
                        cld%phintup(icld,lay,j) * cld_tl%partsca(icld,lay,j)

                    IF (do_single_scatt_chan) THEN
                      musat = -musat
                      musat_tl = -musat_tl

                      CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                           wcldeff_phfn, coef_scatt_ir%wcldeff_phfn_int%cosphangle, &
                                           coef_scatt_ir%wcldeff_phfn_int%iphangle, phasint_tl, wcldeff_phfn_tl)

                    cld_tl%phtotdo(lay,j) = cld_tl%phtotdo(lay,j) + &
                        phasint_tl * cld%partsca(icld,lay,j) + &
                        cld%phintdo(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                    ENDIF
                  ENDIF
                ENDIF

              ELSE
                !--------------------------------------------------------------
                ! Water clouds - OPAC optical parameters
                !--------------------------------------------------------------
                IF (.NOT. profiles_int(prof)%cloud(icld,lay) > 0._jprb) CYCLE

                IF (do_mfasis_chan) THEN
                  trans_scatt_ir_tl%opdpext(icld,lay,j) = &
                    coef%ff_gam(chan) * coef_scatt_ir%confac(icld) * &
                    (optp%optpwcl(icld)%abs(chan,1) + optp%optpwcl(icld)%sca(chan,1)) * &
                    (profiles_int_tl(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) + &
                     profiles_int(prof)%cloud(icld,lay) * raytracing_tl%ltick(lay,prof))

                ELSEIF (do_chan) THEN
                  cld_tl%opdpabs(lay,j) = cld_tl%opdpabs(lay,j) + &
                      coef_scatt_ir%confac(icld) * optp%optpwcl(icld)%abs(chan,1) * &
                      (profiles_int_tl(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) + &
                       profiles_int(prof)%cloud(icld,lay) * raytracing_tl%ltick(lay,prof))
                  cld_tl%partsca(icld,lay,j) = &
                      coef_scatt_ir%confac(icld) * optp%optpwcl(icld)%sca(chan,1) * &
                      (profiles_int_tl(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) + &
                       profiles_int(prof)%cloud(icld,lay) * raytracing_tl%ltick(lay,prof))
                  cld_tl%opdpsca(lay,j) = cld_tl%opdpsca(lay,j) + cld_tl%partsca(icld,lay,j)

                  IF (do_chou_scaling_chan) THEN
!                     bpr_tl = 0._jprb !optp%optpwcl(icld)%bpr(chan,1)
                    cld_tl%opdpscabpr(lay,j) = cld_tl%opdpscabpr(lay,j) + &
                        cld%partbpr(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                  ENDIF

                  IF (do_dom_chan) THEN
                    sca = optp%optpwcl(icld)%sca(chan,1) * &
                          profiles_int(prof)%cloud(icld,lay) * coef_scatt_ir%confac(icld)
                    sca_tl = optp%optpwcl(icld)%sca(chan,1) * &
                             profiles_int_tl(prof)%cloud(icld,lay) * coef_scatt_ir%confac(icld)
                    sumsca = sumsca + sca
                    sumsca_tl = sumsca_tl + sca_tl
                    nmom = MIN(optp%optpwcl(icld)%nmom(chan,1), dom_nstr)
                    legcoef(0:nmom) = legcoef(0:nmom) + optp%optpwcl(icld)%legcoef(1:nmom+1,chan,1) * sca
                    legcoef_tl(0:nmom) = legcoef_tl(0:nmom) + optp%optpwcl(icld)%legcoef(1:nmom+1,chan,1) * sca_tl
                  ENDIF

                  IF (solar(j)) THEN
                    musat =  1._jprb / raytracing%pathsat(lay,prof)
                    musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
                    musun = -1._jprb / raytracing%pathsun(lay,prof)
                    musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
                    zminphadiff = coef_scatt_ir%wcl_phfn_int%zminphadiff / deg2rad

                    phchan = coef_scatt_ir%wcl_pha_index(chan)
                    CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                         optp%optpwcl(icld)%pha(:,phchan,1), coef_scatt_ir%wcl_phfn_int%cosphangle, &
                                         coef_scatt_ir%wcl_phfn_int%iphangle, phasint_tl)

                    cld_tl%phtotup(lay,j) = cld_tl%phtotup(lay,j) + &
                        phasint_tl * cld%partsca(icld,lay,j) + &
                        cld%phintup(icld,lay,j) * cld_tl%partsca(icld,lay,j)

                    IF (do_single_scatt_chan) THEN
                      musat = -musat
                      musat_tl = -musat_tl

                      CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                         optp%optpwcl(icld)%pha(:,phchan,1), coef_scatt_ir%wcl_phfn_int%cosphangle, &
                                         coef_scatt_ir%wcl_phfn_int%iphangle, phasint_tl)

                      cld_tl%phtotdo(lay,j) = cld_tl%phtotdo(lay,j) + &
                          phasint_tl * cld%partsca(icld,lay,j) + &
                          cld%phintdo(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                    ENDIF
                  ENDIF
                ENDIF
              ENDIF
            ELSE
              !--------------------------------------------------------------
              ! Ice clouds
              !--------------------------------------------------------------
              IF (.NOT. profiles_int(prof)%cloud(icld,lay) > 0._jprb) CYCLE

              IF (ice_scheme == ice_scheme_ssec) THEN
                !--------------------------------------------------------------
                ! Optical parameters from SSEC database
                !--------------------------------------------------------------

                ! Interpolate optical parameters based on aux%ice_dg

                IF (aux%ice_dg(lay,prof) >= optp%optpicl%fmv_icl_deff(1) .AND. &
                    aux%ice_dg(lay,prof) < optp%optpicl%fmv_icl_deff(coef_scatt_ir%fmv_icl_ndeff)) THEN
                  ! Find deff index below this channel
                  DO k1 = 1, coef_scatt_ir%fmv_icl_ndeff - 1
                    IF (optp%optpicl%fmv_icl_deff(k1+1) > aux%ice_dg(lay,prof)) EXIT
                  ENDDO
                  k2 = k1 + 1
                  dgfrac = (aux%ice_dg(lay,prof) - optp%optpicl%fmv_icl_deff(k1)) / &
                           (optp%optpicl%fmv_icl_deff(k2) - optp%optpicl%fmv_icl_deff(k1))
                  dgfrac_tl = aux_tl%ice_dg(lay,prof) / &
                              (optp%optpicl%fmv_icl_deff(k2) - optp%optpicl%fmv_icl_deff(k1))
                ELSE
                  ! Take first or last value if deff lies beyond data range
                  IF (aux%ice_dg(lay,prof) < optp%optpicl%fmv_icl_deff(1)) THEN
                    k1 = 1
                    k2 = 1
                  ELSE
                    k1 = coef_scatt_ir%fmv_icl_ndeff
                    k2 = coef_scatt_ir%fmv_icl_ndeff
                  ENDIF
                  dgfrac = 0._jprb
                  dgfrac_tl = 0._jprb
                ENDIF

                IF (do_mfasis_chan) THEN
                  trans_scatt_ir_tl%opdpext(icld,lay,j) = &
                    coef%ff_gam(chan) * &
                    ((profiles_int_tl(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) + &
                      profiles_int(prof)%cloud(icld,lay) * raytracing_tl%ltick(lay,prof)) * &
                     (optp%optpicl%abs(k1,chan) + dgfrac * &
                      (optp%optpicl%abs(k2,chan) - optp%optpicl%abs(k1,chan)) + &
                      optp%optpicl%sca(k1,chan) + dgfrac * &
                      (optp%optpicl%sca(k2,chan) - optp%optpicl%sca(k1,chan))) + &
                    profiles_int(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) * &
                    dgfrac_tl * (optp%optpicl%abs(k2,chan) - optp%optpicl%abs(k1,chan) + &
                                 optp%optpicl%sca(k2,chan) - optp%optpicl%sca(k1,chan)))

                ELSEIF (do_chan) THEN
                  cld_tl%opdpabs(lay,j) = cld_tl%opdpabs(lay,j) + &
                      (profiles_int_tl(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) + &
                       profiles_int(prof)%cloud(icld,lay) * raytracing_tl%ltick(lay,prof)) * &
                      (optp%optpicl%abs(k1,chan) + dgfrac * &
                      (optp%optpicl%abs(k2,chan) - optp%optpicl%abs(k1,chan))) + &
                      profiles_int(prof)%cloud(icld,lay) * raytracing%ltick(lay,prof) * &
                      dgfrac_tl * (optp%optpicl%abs(k2,chan) - optp%optpicl%abs(k1,chan))

                  sca = (optp%optpicl%sca(k1,chan) + dgfrac * &
                      (optp%optpicl%sca(k2,chan) - optp%optpicl%sca(k1,chan))) * profiles_int(prof)%cloud(icld,lay)
                  sca_tl = &
                      dgfrac_tl * (optp%optpicl%sca(k2,chan) - optp%optpicl%sca(k1,chan)) * &
                      profiles_int(prof)%cloud(icld,lay) + &
                      (optp%optpicl%sca(k1,chan) + dgfrac * &
                      (optp%optpicl%sca(k2,chan) - optp%optpicl%sca(k1,chan))) * &
                      profiles_int_tl(prof)%cloud(icld,lay)
                  cld_tl%partsca(icld,lay,j) = &
                      sca_tl * raytracing%ltick(lay,prof) + sca * raytracing_tl%ltick(lay,prof)
                  cld_tl%opdpsca(lay,j) = cld_tl%opdpsca(lay,j) + cld_tl%partsca(icld,lay,j)

                  IF (do_chou_scaling_chan) THEN
                    bpr_tl = dgfrac_tl * (optp%optpicl%bpr(k2,chan) - optp%optpicl%bpr(k1,chan))
                    cld_tl%opdpscabpr(lay,j) = cld_tl%opdpscabpr(lay,j) + &
                        bpr_tl * cld%partsca(icld,lay,j) + &
                        cld%partbpr(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                  ENDIF

                  IF (do_dom_chan) THEN
                    thislegcoef(:) = 0._jprb
                    sumsca = sumsca + sca
                    sumsca_tl = sumsca_tl + sca_tl
                    nmom = MIN(optp%optpicl%nmom(1,chan), dom_nstr)
                    thislegcoef(0:nmom) = &
                        optp%optpicl%legcoef(1:nmom+1,k1,chan) + dgfrac * &
                        (optp%optpicl%legcoef(1:nmom+1,k2,chan) - optp%optpicl%legcoef(1:nmom+1,k1,chan))
                    thislegcoef_tl(0:nmom) = &
                        dgfrac_tl * (optp%optpicl%legcoef(1:nmom+1,k2,chan) - optp%optpicl%legcoef(1:nmom+1,k1,chan))

                    legcoef(:) = legcoef(:) + thislegcoef(:) * sca
                    legcoef_tl(:) = legcoef_tl(:) + thislegcoef_tl(:) * sca + thislegcoef(:) * sca_tl
                  ENDIF

                  IF (solar(j)) THEN
                    musat =  1._jprb / raytracing%pathsat(lay,prof)
                    musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
                    musun = -1._jprb / raytracing%pathsun(lay,prof)
                    musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
                    zminphadiff = coef_scatt_ir%icl_phfn_int%zminphadiff / deg2rad

                    phchan = coef_scatt_ir%icl_pha_index(chan)
                    icl_phfn(:) = &
                        optp%optpicl%pha(:,k1,phchan) + dgfrac * &
                        (optp%optpicl%pha(:,k2,phchan) - optp%optpicl%pha(:,k1,phchan))
                    icl_phfn_tl(:) = &
                        dgfrac_tl * (optp%optpicl%pha(:,k2,phchan) - optp%optpicl%pha(:,k1,phchan))

                    CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                         icl_phfn, coef_scatt_ir%icl_phfn_int%cosphangle, &
                                         coef_scatt_ir%icl_phfn_int%iphangle, phasint_tl, icl_phfn_tl)

                    cld_tl%phtotup(lay,j) = cld_tl%phtotup(lay,j) + &
                        phasint_tl * cld%partsca(icld,lay,j) + &
                        cld%phintup(icld,lay,j) * cld_tl%partsca(icld,lay,j)

                    IF (do_single_scatt_chan) THEN
                      musat = -musat
                      musat_tl = -musat_tl

                      CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                           icl_phfn, coef_scatt_ir%icl_phfn_int%cosphangle, &
                                           coef_scatt_ir%icl_phfn_int%iphangle, phasint_tl, icl_phfn_tl)

                      cld_tl%phtotdo(lay,j) = cld_tl%phtotdo(lay,j) + &
                          phasint_tl * cld%partsca(icld,lay,j) + &
                          cld%phintdo(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                    ENDIF
                  ENDIF
                ENDIF
              ELSE
                !--------------------------------------------------------------
                ! Optical parameters computed using Baran scheme
                !--------------------------------------------------------------
                IF (ice_scheme == ice_scheme_baran2018) THEN
                  CALL rttov_baran2018_calc_optpar_tl(optp, chan, &
                        profiles(prof)%t(lay), profiles_int(prof)%cloud(icld,lay), &
                        profiles_tl(prof)%t(lay), profiles_int_tl(prof)%cloud(icld,lay), &
                        abso, sca, bpr, asym, abso_tl, sca_tl, bpr_tl, asym_tl)
                ELSE
                  CALL rttov_baran2014_calc_optpar_tl(optp, chan, &
                        profiles(prof)%t(lay), profiles_int(prof)%cloud(icld,lay), &
                        profiles_tl(prof)%t(lay), profiles_int_tl(prof)%cloud(icld,lay), &
                        abso, sca, bpr, asym, abso_tl, sca_tl, bpr_tl, asym_tl)
                ENDIF

                cld_tl%opdpabs(lay,j) = cld_tl%opdpabs(lay,j) + &
                    abso_tl * raytracing%ltick(lay,prof) + abso * raytracing_tl%ltick(lay,prof)
                cld_tl%partsca(icld,lay,j) = &
                    sca_tl * raytracing%ltick(lay,prof) + sca * raytracing_tl%ltick(lay,prof)
                cld_tl%opdpsca(lay,j) = cld_tl%opdpsca(lay,j) + cld_tl%partsca(icld,lay,j)

                IF (do_chou_scaling_chan) THEN
                  cld_tl%opdpscabpr(lay,j) = cld_tl%opdpscabpr(lay,j) + &
                      bpr_tl * cld%partsca(icld,lay,j) + &
                      cld%partbpr(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                ENDIF

                ! Baran phase function
                IF (do_single_scatt_chan .OR. do_dom_chan) THEN

                  ! Set up angular grid for Baran phase fn
                  IF (solar(j)) THEN
                    thisnphangle = nphangle_hires
                    thisphangle = phangle_hires
                    thiscosphangle = optp%optpiclbaran2018%phfn_int%cosphangle
                  ELSE
                    thisnphangle = nphangle_lores
                    thisphangle(1:nphangle_lores) = phangle_lores
                    thiscosphangle(1:nphangle_lores) = COS(phangle_lores * deg2rad)
                  ENDIF

                  ! Compute Baran phase fn
                  CALL rttov_baran_calc_phase_tl(asym, asym_tl, thisphangle(1:thisnphangle), &
                        baran_phfn(1:thisnphangle), baran_phfn_tl(1:thisnphangle))

                  ! Compute Legendre coefficients
                  IF (do_dom_chan) THEN
                    thislegcoef(:) = 0._jprb
                    sumsca = sumsca + sca
                    sumsca_tl = sumsca_tl + sca_tl
                    nmom = dom_nstr

                    CALL spline_interp_tl(thisnphangle, thiscosphangle(thisnphangle:1:-1), &
                                          baran_phfn(thisnphangle:1:-1), baran_phfn_tl(thisnphangle:1:-1), &
                                          baran_ngauss, optp%optpiclbaran2018%q, baran_phfn_interp, baran_phfn_interp_tl)

                    CALL normalise_tl(baran_ngauss, optp%optpiclbaran2018%w, baran_phfn_interp, baran_phfn_interp_tl)

                    CALL calc_legendre_coef_gauss_tl(optp%optpiclbaran2018%q, optp%optpiclbaran2018%w, &
                                                     baran_phfn_interp, baran_phfn_interp_tl, dom_nstr, dom_nstr, &
                                                     nmom, thislegcoef(:), thislegcoef_tl(:))

                    legcoef(:) = legcoef(:) + thislegcoef(:) * sca
                    legcoef_tl(:) = legcoef_tl(:) + thislegcoef_tl(:) * sca + thislegcoef(:) * sca_tl
                  ENDIF

                  ! Evaluate phase function for solar scattering
                  IF (solar(j)) THEN
                    musat =  1._jprb / raytracing%pathsat(lay,prof)
                    musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
                    musun = -1._jprb / raytracing%pathsun(lay,prof)
                    musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
                    zminphadiff = optp%optpiclbaran2018%phfn_int%zminphadiff / deg2rad

                    CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                         baran_phfn, optp%optpiclbaran2018%phfn_int%cosphangle, &
                                         optp%optpiclbaran2018%phfn_int%iphangle, phasint_tl, baran_phfn_tl)

                    cld_tl%phtotup(lay,j) = cld_tl%phtotup(lay,j) + &
                        phasint_tl * cld%partsca(icld,lay,j) + &
                        cld%phintup(icld,lay,j) * cld_tl%partsca(icld,lay,j)

                    IF (do_single_scatt_chan) THEN
                      musat = -musat
                      CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                           baran_phfn, optp%optpiclbaran2018%phfn_int%cosphangle, &
                                           optp%optpiclbaran2018%phfn_int%iphangle, phasint_tl, baran_phfn_tl)

                      cld_tl%phtotdo(lay,j) = cld_tl%phtotdo(lay,j) + &
                          phasint_tl * cld%partsca(icld,lay,j) + &
                          cld%phintdo(icld,lay,j) * cld_tl%partsca(icld,lay,j)
                    ENDIF
                  ENDIF
                ENDIF

              ENDIF ! ice_scheme
            ENDIF ! water or ice
          ENDDO ! cloud types

          !------------------------------------------------------------------
          ! Calculate final phase function Leg. coefs for all cloud types
          !------------------------------------------------------------------
          IF (do_dom_chan) THEN
            IF (ABS(sumsca) > realtol) THEN
              cld_tl%sca(lay,j) = sumsca_tl
              trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,1,lay) = &
                  legcoef_tl(:) / sumsca - sumsca_tl * legcoef(:) / sumsca ** 2_jpim
            ENDIF
          ENDIF
        ENDDO ! layers
      ENDDO ! chanprof
    ENDIF ! sccld coef file

    DO j = 1, nchanprof
      do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou

      !------------------------------------------------------------------------
      ! Calculate total cloud optical depths
      !------------------------------------------------------------------------
      IF (thermal(j)) THEN
        IF (do_chou_scaling_chan) THEN
          ! Chou-scaled optical depth for thermal channels
          cld_tl%opdp(:,j) = cld_tl%opdpabs(:,j) + cld_tl%opdpscabpr(:,j)
        ELSE
          ! Full optical depth for thermal channels
          cld_tl%opdp(:,j) = cld_tl%opdpabs(:,j) + cld_tl%opdpsca(:,j)
        ENDIF
      ENDIF

      ! Full optical depth for solar channels
      IF (solar(j) .AND. .NOT. do_mfasis) cld_tl%opdpsun(:,j) = cld_tl%opdpabs(:,j) + cld_tl%opdpsca(:,j)
    ENDDO ! chanprof
  ENDIF ! addclouds

  IF (do_mfasis) RETURN

  !----------------------------------------------------------------------------
  ! CALCULATE TOTAL OPTICAL DEPTHS AND PARAMETERS FOR EACH CLOUD STREAM
  !----------------------------------------------------------------------------
  DO j = 1, nchanprof
    chan = chanprof(j)%chan
    prof = chanprof(j)%prof

    do_dom_chan = (solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom) .OR. &
                  (thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom)
    do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
    do_single_scatt_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single

    ! For layer-specific quantities store just the non-cloudy and cloudy values
    ! When used later the code looks up the appropriate value for each cloud stream

    ! Determine layer total aerosol/cloud optical depths
    IF (thermal(j)) THEN
      IF (opts%rt_ir%addaerosl) THEN
        trans_scatt_ir_tl%opdpacl(0,:,j) = coef%ff_gam(chan) * &
            (aer_tl%opdp(:,j) * raytracing%pathsat(:,prof) + &
             aer%opdp(:,j) * raytracing_tl%pathsat(:,prof))
      ENDIF
      IF (opts%rt_ir%addclouds) THEN
        trans_scatt_ir_tl%opdpacl(1,:,j) = &
            trans_scatt_ir_tl%opdpacl(0,:,j) + coef%ff_gam(chan) * &
            (cld_tl%opdp(:,j) * raytracing%pathsat(:,prof) + &
             cld%opdp(:,j) * raytracing_tl%pathsat(:,prof))
      ENDIF
    ENDIF
    IF (solar(j)) THEN
      IF (opts%rt_ir%addaerosl) THEN
        trans_scatt_ir_tl%opdpaclsun(0,:,j) = coef%ff_gam(chan) * &
            (aer_tl%opdpsun(:,j) * raytracing%patheff(:,prof) + &
             aer%opdpsun(:,j) * raytracing_tl%patheff(:,prof))
      ENDIF
      IF (opts%rt_ir%addclouds) THEN
        trans_scatt_ir_tl%opdpaclsun(1,:,j) = &
            trans_scatt_ir_tl%opdpaclsun(0,:,j) + coef%ff_gam(chan) * &
            (cld_tl%opdpsun(:,j) * raytracing%patheff(:,prof) + &
             cld%opdpsun(:,j) * raytracing_tl%patheff(:,prof))
      ENDIF
    ENDIF

    IF (do_dom_chan .OR. do_single_scatt_chan) THEN
      ! Determine final layer *nadir* absorption and scattering optical depths
      IF (opts%rt_ir%addaerosl) THEN
        trans_scatt_ir_tl%opdpabs(0,:,j) = coef%ff_gam(chan) * aer_tl%opdpabs(:,j)
        trans_scatt_ir_tl%opdpsca(0,:,j) = coef%ff_gam(chan) * aer_tl%opdpsca(:,j)
      ELSE
        trans_scatt_ir_tl%opdpabs(0,:,j) = 0._jprb
        trans_scatt_ir_tl%opdpsca(0,:,j) = 0._jprb
      ENDIF
      IF (opts%rt_ir%addclouds) THEN
        trans_scatt_ir_tl%opdpabs(1,:,j) = trans_scatt_ir_tl%opdpabs(0,:,j) + &
            coef%ff_gam(chan) * cld_tl%opdpabs(:,j)
        trans_scatt_ir_tl%opdpsca(1,:,j) = trans_scatt_ir_tl%opdpsca(0,:,j) + &
            coef%ff_gam(chan) * cld_tl%opdpsca(:,j)
      ENDIF

      DO lay = 1, nlayers

        IF (do_dom_chan) THEN
          ! Determine combined phase functions for aer+cld case
          IF (opts%rt_ir%addaerosl .AND. opts%rt_ir%addclouds) THEN
            IF (aer%sca(lay,j) + cld%sca(lay,j) > 0._jprb) THEN

              ! NB In the direct model trans_scatt_ir_dyn%phasefn(j)%legcoef(:,1,lay) initially contains
              !    just the cloud phase fn. If aerosols are also present then it is overwritten
              !    with the combined phase function. We need to be careful about this in the TL/AD/K.
              !    We don't want to store the cloud phase fn in this case because the phase fns take
              !    a lot of memory.

              IF (cld%sca(lay,j) > 0._jprb) THEN
                legcoefcld = (trans_scatt_ir_dyn%phasefn(j)%legcoef(:,1,lay) * &
                              (aer%sca(lay,j) + cld%sca(lay,j)) - &
                              trans_scatt_ir_dyn%phasefn(j)%legcoef(:,0,lay) * &
                              aer%sca(lay,j)) / cld%sca(lay,j)
              ELSE
                legcoefcld = 0._jprb
              ENDIF

              trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,1,lay) = &
                  (trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,0,lay) * aer%sca(lay,j) + &
                   trans_scatt_ir_dyn%phasefn(j)%legcoef(:,0,lay) * aer_tl%sca(lay,j) + &
                   trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,1,lay) * cld%sca(lay,j) + &
                   legcoefcld(:) * cld_tl%sca(lay,j) - &
                   trans_scatt_ir_dyn%phasefn(j)%legcoef(:,1,lay) * & ! Re-use direct calculation
                   (aer_tl%sca(lay,j) + cld_tl%sca(lay,j))) / &
                  (aer%sca(lay,j) + cld%sca(lay,j))
            ENDIF
          ENDIF
        ENDIF

        IF (solar(j)) THEN
          IF (opts%rt_ir%addclouds .AND. opts%rt_ir%addaerosl) THEN
            IF (ABS(cld%opdpsca(lay,j) + aer%opdpsca(lay,j)) > realtol) THEN
              tmpval = 1._jprb / (cld%opdpsca(lay,j) + aer%opdpsca(lay,j))
              trans_scatt_ir_tl%phup(1,lay,j) = &
                  (aer_tl%phtotup(lay,j) + cld_tl%phtotup(lay,j)) * tmpval - &
                  (cld_tl%opdpsca(lay,j) + aer_tl%opdpsca(lay,j)) * &
                  (aer%phtotup(lay,j) + cld%phtotup(lay,j)) * tmpval**2
              IF (do_single_scatt_chan) &
                trans_scatt_ir_tl%phdo(1,lay,j) = &
                    (aer_tl%phtotdo(lay,j) + cld_tl%phtotdo(lay,j)) * tmpval - &
                    (cld_tl%opdpsca(lay,j) + aer_tl%opdpsca(lay,j)) * &
                    (aer%phtotdo(lay,j) + cld%phtotdo(lay,j)) * tmpval**2
            ENDIF
          ELSEIF (opts%rt_ir%addclouds) THEN
            IF (ABS(cld%opdpsca(lay,j)) > realtol) THEN
              tmpval = 1._jprb / cld%opdpsca(lay,j)
              trans_scatt_ir_tl%phup(1,lay,j) = &
                 cld_tl%phtotup(lay,j) * tmpval - &
                 cld_tl%opdpsca(lay,j) * cld%phtotup(lay,j) * tmpval**2
              IF (do_single_scatt_chan) &
                trans_scatt_ir_tl%phdo(1,lay,j) = &
                   cld_tl%phtotdo(lay,j) * tmpval - &
                   cld_tl%opdpsca(lay,j) * cld%phtotdo(lay,j) * tmpval**2
            ENDIF
          ENDIF
        ENDIF

      ENDDO ! layers
    ENDIF ! do dom or do single_scatt

    DO ist = 0, ircld%nstream(prof)
      IF (thermal(j)) THEN
        opd_tl = 0._jprb
        trans_scatt_ir_dyn_tl%opdpac(1,ist,j) = 0._jprb
      ENDIF
      IF (solar(j)) THEN
        opdsun_tl = 0._jprb
        trans_scatt_ir_dyn_tl%opdpacsun(1,ist,j) = 0._jprb
      ENDIF
      IF (ist == 0) THEN
        IF (opts%rt_ir%addaerosl) THEN
          DO lay = 1, nlayers
            lev = lay + 1
            IF (thermal(j)) THEN
              opd_tl = opd_tl + trans_scatt_ir_tl%opdpacl(0,lay,j)
              trans_scatt_ir_dyn_tl%opdpac(lev,ist,j) = opd_tl
            ENDIF
            IF (solar(j)) THEN
              opdsun_tl = opdsun_tl + trans_scatt_ir_tl%opdpaclsun(0,lay,j)
              trans_scatt_ir_dyn_tl%opdpacsun(lev,ist,j) = opdsun_tl
            ENDIF
          ENDDO ! layers
        ELSE
          IF (thermal(j)) trans_scatt_ir_dyn_tl%opdpac(:,ist,j) = 0._jprb
          IF (solar(j)) trans_scatt_ir_dyn_tl%opdpacsun(:,ist,j) = 0._jprb
        ENDIF
      ELSE
        DO lay = 1, nlayers
          lev = lay + 1
          isti = ircld%icldarr(ist,lay,prof) ! This is 0 or 1 for clear(+aer)/cloud(+aer)
          IF (thermal(j)) THEN
            opd_tl = opd_tl + trans_scatt_ir_tl%opdpacl(isti,lay,j)
            trans_scatt_ir_dyn_tl%opdpac(lev,ist,j) = opd_tl
          ENDIF
          IF (solar(j)) THEN
            opdsun_tl = opdsun_tl + trans_scatt_ir_tl%opdpaclsun(isti,lay,j)
            trans_scatt_ir_dyn_tl%opdpacsun(lev,ist,j) = opdsun_tl
          ENDIF
        ENDDO ! layers
      ENDIF ! istream == 0
    ENDDO ! istream
  ENDDO ! channels

  IF (LHOOK) CALL DR_HOOK('RTTOV_OPDPSCATTIR_TL', 1_jpim, ZHOOK_HANDLE)

CONTAINS

  SUBROUTINE calc_user_opt_param_tl(opt_param, opt_param_tl, aercld, aercld_tl, iaercld)
    ! Process aer/cld user optical property inputs
    TYPE(rttov_opt_param),       INTENT(IN)           :: opt_param
    TYPE(rttov_opt_param),       INTENT(IN), OPTIONAL :: opt_param_tl
    TYPE(rttov_scatt_ir_aercld), INTENT(IN)           :: aercld
    TYPE(rttov_scatt_ir_aercld), INTENT(INOUT)        :: aercld_tl
    INTEGER(jpim),               INTENT(IN)           :: iaercld ! aer=>0, cld=>1

    INTEGER(jpim) :: j, lay, nmom, prof
    LOGICAL(jplm) :: do_chou_scaling_chan, do_dom_chan, do_single_scatt_chan, do_opt_param_tl
    REAL(jprb)    :: musat, musun, zminphadiff, phasint_tl

    ! This is useful for the parallel interface which always passes opt_param_tl
    ! for convenience even when not allocated
    do_opt_param_tl = .FALSE.
    IF (PRESENT(opt_param_tl) .AND. .NOT. opts%dev%no_opt_param_tladk) &
      do_opt_param_tl = (ASSOCIATED(opt_param_tl%sca))

    DO j = 1, nchanprof
      prof = chanprof(j)%prof

      do_dom_chan = (solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_dom) .OR. &
                    (thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_dom)
      do_chou_scaling_chan = thermal(j) .AND. opts%rt_ir%ir_scatt_model == ir_scatt_chou
      do_single_scatt_chan = solar(j) .AND. opts%rt_ir%vis_scatt_model == vis_scatt_single

      relazi = profiles(prof)%azangle - profiles(prof)%sunazangle

      DO lay = 1, nlayers

        IF (opt_param%abs(lay,j) > 0._jprb .OR. &
            opt_param%sca(lay,j) > 0._jprb) THEN

          IF (do_opt_param_tl) THEN
            aercld_tl%opdpabs(lay,j) = opt_param%abs(lay,j) * raytracing_tl%ltick(lay,prof) + &
                                       opt_param_tl%abs(lay,j) * raytracing%ltick(lay,prof)
            aercld_tl%opdpsca(lay,j) = opt_param%sca(lay,j) * raytracing_tl%ltick(lay,prof) + &
                                       opt_param_tl%sca(lay,j) * raytracing%ltick(lay,prof)
            IF (do_chou_scaling_chan) THEN
              aercld_tl%opdpscabpr(lay,j) = &
                  opt_param%sca(lay,j) * opt_param%bpr(lay,j) * raytracing_tl%ltick(lay,prof) + &
                  opt_param%sca(lay,j) * opt_param_tl%bpr(lay,j) * raytracing%ltick(lay,prof) + &
                  opt_param_tl%sca(lay,j) * opt_param%bpr(lay,j) * raytracing%ltick(lay,prof)
            ENDIF

            IF (do_dom_chan) THEN
              aercld_tl%sca(lay,j) = opt_param_tl%sca(lay,j)
              nmom = MIN(opt_param%nmom, dom_nstr)
              trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(0:nmom,iaercld,lay) = opt_param_tl%legcoef(1:nmom+1,lay,j)
            ENDIF

            IF (solar(j)) THEN
              musat =  1._jprb / raytracing%pathsat(lay,prof)
              musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
              musun = -1._jprb / raytracing%pathsun(lay,prof)
              musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
              zminphadiff = opt_param%phasefn_int%zminphadiff / deg2rad

              CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                   opt_param%pha(:,lay,j), opt_param%phasefn_int%cosphangle, &
                                   opt_param%phasefn_int%iphangle, phasint_tl, opt_param_tl%pha(:,lay,j))

              aercld_tl%phtotup(lay,j) = aercld_tl%phtotup(lay,j) + phasint_tl * aercld%opdpsca(lay,j) + &
                                         aercld%phintup(1,lay,j) * aercld_tl%opdpsca(lay,j)
              IF (do_single_scatt_chan) THEN
                musat = -musat
                musat_tl = -musat_tl

                CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                     opt_param%pha(:,lay,j), opt_param%phasefn_int%cosphangle, &
                                     opt_param%phasefn_int%iphangle, phasint_tl, opt_param_tl%pha(:,lay,j))

                aercld_tl%phtotdo(lay,j) = aercld_tl%phtotdo(lay,j) + phasint_tl * aercld%opdpsca(lay,j) + &
                                           aercld%phintdo(1,lay,j) * aercld_tl%opdpsca(lay,j)
              ENDIF
            ENDIF
          ELSE
            ! No opt_param_tl
            aercld_tl%opdpabs(lay,j) = opt_param%abs(lay,j) * raytracing_tl%ltick(lay,prof)
            aercld_tl%opdpsca(lay,j) = opt_param%sca(lay,j) * raytracing_tl%ltick(lay,prof)
            IF (do_chou_scaling_chan) THEN
              aercld_tl%opdpscabpr(lay,j) = opt_param%sca(lay,j) * opt_param%bpr(lay,j) * raytracing_tl%ltick(lay,prof)
            ENDIF

            IF (do_dom_chan) THEN
              aercld_tl%sca(lay,j) = 0._jprb
              trans_scatt_ir_dyn_tl%phasefn(j)%legcoef(:,iaercld,lay) = 0._jprb
            ENDIF

            IF (solar(j)) THEN
              musat =  1._jprb / raytracing%pathsat(lay,prof)
              musat_tl = -raytracing_tl%pathsat(lay,prof) * musat**2
              musun = -1._jprb / raytracing%pathsun(lay,prof)
              musun_tl = raytracing_tl%pathsun(lay,prof) * musun**2
              zminphadiff = opt_param%phasefn_int%zminphadiff / deg2rad

              CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, 180.0_jprb - relazi, zminphadiff, &
                                   opt_param%pha(:,lay,j), opt_param%phasefn_int%cosphangle, &
                                   opt_param%phasefn_int%iphangle, phasint_tl)

              aercld_tl%phtotup(lay,j) = aercld_tl%phtotup(lay,j) + phasint_tl * aercld%opdpsca(lay,j) + &
                                         aercld%phintup(1,lay,j) * aercld_tl%opdpsca(lay,j)

              IF (do_single_scatt_chan) THEN
                musat = -musat
                musat_tl = -musat_tl

                CALL int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                                     opt_param%pha(:,lay,j), opt_param%phasefn_int%cosphangle, &
                                     opt_param%phasefn_int%iphangle, phasint_tl)

                aercld_tl%phtotdo(lay,j) = aercld_tl%phtotdo(lay,j) + phasint_tl * aercld%opdpsca(lay,j) + &
                                           aercld%phintdo(1,lay,j) * aercld_tl%opdpsca(lay,j)
              ENDIF
            ENDIF
          ENDIF
        ENDIF

      ENDDO
    ENDDO

  END SUBROUTINE calc_user_opt_param_tl

  SUBROUTINE int_phase_fn_tl(musat, musat_tl, musun, musun_tl, relazi, zminphadiff, &
                             pha, cospha, ipha, phasint_tl, pha_tl)
    ! Interpolate phase function to scattering angle
    ! pha_tl may be omitted if the phase function is static
    REAL(KIND=jprb),           INTENT(IN)  :: musat, musat_tl, musun, musun_tl, relazi
    REAL(KIND=jprb),           INTENT(IN)  :: zminphadiff
    REAL(KIND=jprb),           INTENT(IN)  :: pha(:)
    REAL(KIND=jprb),           INTENT(IN)  :: cospha(:)
    INTEGER(KIND=jpim),        INTENT(IN)  :: ipha(:)
    REAL(KIND=jprb),           INTENT(OUT) :: phasint_tl
    REAL(KIND=jprb), OPTIONAL, INTENT(IN)  :: pha_tl(:)

    INTEGER(KIND=jpim) :: ikk, kk
    REAL(KIND=jprb)    :: ztmpx, ztmpx_tl
    REAL(KIND=jprb)    :: scattangle, scattangle_tl, deltap, deltap_tl, delta

    phasint_tl = 0._jprb

    ztmpx = SQRT((1._jprb - musat ** 2) * (1._jprb - musun ** 2))
    IF (ABS(ztmpx) < realtol) THEN
      ztmpx_tl = 0._jprb
    ELSE
      ztmpx_tl = - ((1._jprb - musun ** 2) * musat * musat_tl + &
                    (1._jprb - musat ** 2) * musun * musun_tl) / ztmpx
    ENDIF

    scattangle = musat * musun + ztmpx * COS(relazi * deg2rad)
    scattangle_tl = musat_tl * musun + musat * musun_tl + ztmpx_tl * COS(relazi * deg2rad)
    ikk        = MAX(1_jpim, INT(ACOS(scattangle) * zminphadiff, jpim))
    kk         = ipha(ikk) - 1_jpim
    deltap     = pha(kk + 1) - pha(kk)
    delta      = cospha(kk) - cospha(kk + 1)
    IF (PRESENT(pha_tl)) THEN
      deltap_tl   = pha_tl(kk + 1) - pha_tl(kk)
      phasint_tl  = pha_tl(kk) + deltap_tl * (cospha(kk) - scattangle) / delta - &
                                 deltap * scattangle_tl / delta
    ELSE
      phasint_tl  = - deltap * scattangle_tl / delta
    ENDIF

  END SUBROUTINE int_phase_fn_tl

END SUBROUTINE rttov_opdpscattir_tl
