! Description:
!> @file
!!   Initialise the clear-sky optical depth coefficients structure.
!!   This should usually be called via rttov_init_coefs.
!
!> @brief
!!   Initialise the clear-sky optical depth coefficients structure.
!!   This should usually be called via rttov_init_coefs.
!!
!! @details
!!   This is automatically called after the coefficients are read by
!!   rttov_read_coefs. It allocates some additional arrays and carries
!!   out some useful pre-calculations.
!!
!! @param[out]     err      status on exit
!! @param[in,out]  coef     the coefficient structure to nullify/zero
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
SUBROUTINE rttov_init_coef(err, coef)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE rttov_const, ONLY :  &
         sensor_id_mw,       &
         sensor_id_po,       &
         sensor_id_hi,       &
         gas_id_mixed,       &
         gas_id_watervapour, &
         gas_id_ozone,       &
         gas_id_co2,         &
         gas_id_n2o,         &
         gas_id_co,          &
         gas_id_ch4,         &
         gas_id_so2,         &
         tscale_def,         &
         gscale_def,         &
         earthradius,        &
         mwcldtp,            &
         deg2rad,            &
         speedl
  USE parkind1, ONLY : jprb, jplm
  USE rttov_solar_refl_mod, ONLY : rttov_refl_water_interp
  USE rttov_fast_coef_utils_mod, ONLY : set_fastcoef_level_bounds
!INTF_ON
  IMPLICIT NONE
  INTEGER(KIND=jpim), INTENT(OUT)   :: err
  TYPE(rttov_coef),   INTENT(INOUT) :: coef
!INTF_END

#include "rttov_errorreport.interface"

  INTEGER(KIND=jpim) :: i, n
!- End of header --------------------------------------------------------

  TRY

!Allocate bounds array to store opdep calculation layer limits
!1st dim: upper boundary layer [ub](above which coefs all zeros), lower boundary layer [lb]
!4th dim: thermal layer limits, solar layer limits
    ALLOCATE(coef%bounds(2, coef%fmv_gas, coef%fmv_chn, 2))

    CALL set_fastcoef_level_bounds(coef, coef%thermal, thermal = .TRUE._jplm)

! If the SOLAR_FAST_COEFFICIENTS section is not present then point the solar coefs to the thermal coefs
   
    IF (coef%solarcoef) THEN
      CALL set_fastcoef_level_bounds(coef, coef%solar, thermal = .FALSE._jplm)
    ELSE
      coef%solar => coef%thermal
      coef%bounds(:,:,:,2) = coef%bounds(:,:,:,1)
    ENDIF

! If there is no PLANCK_WEIGHTED section then all channels are non-PW
  IF (.NOT. ASSOCIATED(coef%pw_val_chn)) THEN
    ALLOCATE(coef%pw_val_chn(coef%fmv_chn), STAT = err)
    THROWM(err.NE.0, "allocation of Planck section")
    coef%pw_val_chn(:) = 0_jpim
  ENDIF

! If there is no SOLAR_SPECTRUM section then all channels are thermal (useful for v7/v8pred coefs)
  IF (.NOT. ASSOCIATED(coef%ss_val_chn)) THEN
    ALLOCATE(coef%ss_val_chn(coef%fmv_chn), STAT = err)
    THROWM(err.NE.0, "allocation of Solar section")
    coef%ss_val_chn(:) = 0_jpim
  ENDIF

! If there is no TRANSMITTANCE_THRESHOLD section then make one
  IF (coef%id_sensor == sensor_id_hi .AND. coef%fmv_model_ver >= 9) THEN
    IF (.NOT. ASSOCIATED(coef%tt_val_chn)) THEN
      ALLOCATE(coef%tt_val_chn(coef%fmv_chn), STAT = err)
      THROWM(err.NE.0, "allocation of Transmittance Threshold section")
      coef%tt_val_chn(:) = 0_jpim
    ENDIF
  ENDIF

! Compute auxillary variables
!--------------------------------------------------------------------
! ratio satellite altitude to earth radius
  coef%ratoe = (earthradius + coef%fc_sat_height) / earthradius
! planck variables
  ALLOCATE(coef%planck1(coef%fmv_chn), &
           coef%planck2(coef%fmv_chn), STAT = err)
  THROWM(err.NE.0, "allocation of Planck arrays")

!DAR: useful variable to check whether FF section is useful 
!(all IR sounders (not HI) and AMSUB!)
  coef%ff_val_bc = ANY(coef%ff_bco(:) /= 0.0_jprb) .OR. ANY(coef%ff_bcs(:) /= 1.0_jprb)
  coef%ff_val_gam = ANY(coef%ff_gam(:) /= 1.0_jprb)

  coef%planck1(:) = coef%fc_planck_c1 * coef%ff_cwn(:) ** 3
  coef%planck2(:) = coef%fc_planck_c2 * coef%ff_cwn(:)

! frequency in GHz for MicroWaves
  IF (coef%id_sensor == sensor_id_mw .OR. coef%id_sensor == sensor_id_po) THEN
    ALLOCATE(coef%frequency_ghz(coef%fmv_chn), STAT = err)
    THROWM(err.NE.0, "allocation of frequency_ghz")
    coef%frequency_ghz(:) = speedl * 1.0E-09_jprb * coef%ff_cwn(:)
  ENDIF

! Surface water reflectance for visible/near-IR channels
  IF (ANY(coef%ss_val_chn == 2)) THEN
    ALLOCATE(coef%refl_visnir_ow(coef%fmv_chn), &
             coef%refl_visnir_fw(coef%fmv_chn), STAT = err)
    THROWM(err.NE.0, "allocation of visible/near-IR reflectance arrays")
    CALL rttov_refl_water_interp(coef%ff_cwn, coef%refl_visnir_ow, coef%refl_visnir_fw)
  ENDIF


  ! pressure intervals dp
  ! ------------------
  ALLOCATE(coef%dp(coef%nlayers), STAT = err)
  THROWM(err.NE.0, "allocation of dp")

  ALLOCATE(coef%dpp(0:coef%nlayers), STAT = err)
  THROWM(err.NE.0, "allocation of dpp")

  ! dp(layer=N), where layer N lies between levels N and N+1
  coef%dp(1:coef%nlayers)      = coef%ref_prfl_p(2:coef%nlevels) - coef%ref_prfl_p(1:coef%nlevels - 1)
  ! pressure quantity dpp
  ! -----------------
  ! special coef % dpp(0) replaces RTTOV-9 coef % dpp(1)
  ! needed for predictor variables ww and ow (but not tw)
  coef%dpp(0)                  = coef%dp(1) * coef%ref_prfl_p(1)
  ! NB coef % ref_prfl_p(1) replaces RTTOV-9 parameter pressure_top
  ! coef % dpp(layer=N), where layer N bounded by levels N and N+1
  ! coef % dpp(N) replaces RTTOV-9 coef % dpp(N+1) -  NB coef % dpp(43) not used
  coef%dpp(1:coef%nlayers - 1) = coef%dp(1:coef%nlayers - 1) * coef%ref_prfl_p(2:coef%nlevels - 1)

  DO i = 1, coef%nlevels
    IF (coef%ref_prfl_p(i) < mwcldtp) coef%mwcldtop = i
  ENDDO


! Construct variables from reference profile
! --------------------------------------------

! temperature
  ALLOCATE(coef%tstar(coef%nlayers), STAT = err)
  THROWM(err.NE.0, "allocation of tstar")

  n = coef%fmv_gas_pos(gas_id_mixed)
  coef%tstar(1:coef%nlayers) = (coef%ref_prfl_t(1:coef%nlevels - 1, n) + coef%ref_prfl_t(2:coef%nlevels, n)) / 2

! water vapour
  ALLOCATE(coef%wstar(coef%nlayers), STAT = err)
  THROWM(err.NE.0, "allocation of wstar")
  n = coef%fmv_gas_pos(gas_id_watervapour)
  coef%wstar(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2

! ozone
  IF (coef%nozone > 0) THEN
    ! temperature for O3 profiles
    ALLOCATE(coef%to3star(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of to3star")
    n = coef%fmv_gas_pos(gas_id_ozone)
    coef%to3star(1:coef%nlayers) = (coef%ref_prfl_t(1:coef%nlevels - 1, n) + coef%ref_prfl_t(2:coef%nlevels, n)) / 2

    ! ozone
    ALLOCATE(coef%ostar(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of ostar")
    n = coef%fmv_gas_pos(gas_id_ozone)
    coef%ostar(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF

! CO2
  IF (coef%nco2 > 0) THEN
    ALLOCATE(coef%co2star(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of co2star")
    n = coef%fmv_gas_pos(gas_id_co2)
    coef%co2star(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF

! N2O
  IF (coef%nn2o > 0) THEN
    ALLOCATE(coef%n2ostar(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of n2ostar")
    n = coef%fmv_gas_pos(gas_id_n2o)
    coef%n2ostar(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF

! CO
  IF (coef%nco > 0) THEN
    ALLOCATE(coef%costar(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of costar")
    n = coef%fmv_gas_pos(gas_id_co)
    coef%costar(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF

! CH4
  IF (coef%nch4 > 0) THEN
    ALLOCATE(coef%ch4star(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of ch4star")
    n = coef%fmv_gas_pos(gas_id_ch4)
    coef%ch4star(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF

! SO2
  IF (coef%nso2 > 0) THEN
    ALLOCATE(coef%so2star(coef%nlayers), STAT = err)
    THROWM(err.NE.0, "allocation of so2star")
    n = coef%fmv_gas_pos(gas_id_so2)
    coef%so2star(1:coef%nlayers) = (coef%ref_prfl_mr(1:coef%nlevels - 1, n) + coef%ref_prfl_mr(2:coef%nlevels, n)) / 2
  ENDIF


! Create regression limit profiles from envelopes
! -----------------------------------------------

  ALLOCATE(coef%lim_prfl_tmax(coef%fmv_lvl(gas_id_mixed)), &
           coef%lim_prfl_tmin(coef%fmv_lvl(gas_id_mixed)), &
           coef%lim_prfl_gmax(coef%fmv_lvl(gas_id_mixed), coef%fmv_gas), &
           coef%lim_prfl_gmin(coef%fmv_lvl(gas_id_mixed), coef%fmv_gas), stat=err)
  THROWM(err.NE.0, "allocation of profile limit arrays")
  coef%lim_prfl_tmax = coef%env_prfl_tmax * (1._jprb + tscale_def)
  coef%lim_prfl_tmin = coef%env_prfl_tmin * (1._jprb - tscale_def)
  coef%lim_prfl_gmax = coef%env_prfl_gmax * (1._jprb + gscale_def)
  coef%lim_prfl_gmin = coef%env_prfl_gmin * (1._jprb - gscale_def)


  IF (coef%nltecoef) THEN
    ALLOCATE(coef%nlte_coef%cos_sol(coef%nlte_coef%nsol), &
             coef%nlte_coef%sat_zen_angle(coef%nlte_coef%nsat), STAT = err)
    THROWM(err.NE.0, "allocation of NLTE angle arrays")

    coef%nlte_coef%end_chan = coef%nlte_coef%start_chan + coef%nlte_coef%nchan - 1
    coef%nlte_coef%cos_sol = COS(coef%nlte_coef%sol_zen_angle * deg2rad) ! 1d array
    coef%nlte_coef%sat_zen_angle = ACOS(1./coef%nlte_coef%sec_sat) / deg2rad! 1d array
    coef%nlte_coef%max_sat_angle = coef%nlte_coef%sat_zen_angle(coef%nlte_coef%nsat)
  ENDIF

  IF (coef%pmc_shift) THEN
    ALLOCATE(coef%pmc_ppmc(coef%fmv_chn), STAT = err)
    THROWM(err.NE.0, "allocation of coef%pmc_ppmc")
  ELSE
    NULLIFY(coef%pmc_pnominal, coef%pmc_coef, coef%pmc_ppmc)
  ENDIF

  CATCH
END SUBROUTINE 
