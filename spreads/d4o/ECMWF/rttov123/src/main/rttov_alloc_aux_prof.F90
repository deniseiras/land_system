! Description:
!> @file
!!   Allocate/deallocate internal auxiliary profiles structure.
!
!> @brief
!!   Allocate/deallocate internal auxiliary profiles structure.
!!
!! @details
!!   This structure contains results of various internal calculations
!!   related to the input profiles. Some data is required only on
!!   coefficient levels, some only on user levels and some on both:
!!   - information related to the near-surface level/layer (user and coef
!!     levels)
!!   - information related to the near-cloud level/layer (for the simple-
!!     cloud scheme; user and coef levels)
!!   - quantities used in predictor calculations (coef levels)
!!   - arrays for MW CLW absorption models (coef or user levels)
!!   - data for relative humidity calculations for interpolation of aerosol
!!     optical properties (for VIS/IR simulations; user levels)
!!   - liquid/ice cloud effective diameter calculations (for VIS/IR
!!     simulations; user levels)
!!
!! @param[out]    err               status on exit
!! @param[in]     nprofiles         number of profiles being simulated
!! @param[in]     nlevels           number of levels in input profiles
!! @param[in]     id_sensor         ID of sensor type (IR, hi-res IR, MW or polarimeter)
!! @param[in,out] aux_prof          auxiliary profiles structure to (de)allocate
!! @param[in]     opts              options to configure the simulations
!! @param[in]     coef              optical depth coefficients structure
!! @param[in]     asw               1_jpim => allocate; 0_jpim => deallocate
!! @param[in]     init              set .TRUE. to initialise newly allocated structures, optional
!! @param[in]     alloc_layer_vars  flag to indicate arrays for predictor calculations should be allocated,
!!                                    only required for aux_prof on coefficient levels, optional
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
SUBROUTINE rttov_alloc_aux_prof( &
              err,       &
              nprofiles, &
              nlevels,   &
              id_sensor, &
              aux_prof,  &
              opts,      &
              coef,      &
              asw,       &
              init,      &
              alloc_layer_vars)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_options, rttov_profile_aux, rttov_coef
  USE parkind1, ONLY : jpim, jplm
!INTF_OFF
  USE rttov_const, ONLY : &
    sensor_id_mw, sensor_id_po, &
    mw_clw_scheme_liebe,        &
    mw_clw_scheme_rosenkranz,   &
    mw_clw_scheme_tkc
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),      INTENT(OUT)            :: err
  INTEGER(KIND=jpim),      INTENT(IN)             :: nprofiles
  INTEGER(KIND=jpim),      INTENT(IN)             :: nlevels
  INTEGER(KIND=jpim),      INTENT(IN)             :: id_sensor
  TYPE(rttov_profile_aux), INTENT(INOUT)          :: aux_prof
  TYPE(rttov_options),     INTENT(IN)             :: opts
  TYPE(rttov_coef),        INTENT(IN)             :: coef
  INTEGER(KIND=jpim),      INTENT(IN)             :: asw
  LOGICAL(KIND=jplm),      INTENT(IN),   OPTIONAL :: init
  LOGICAL(KIND=jplm),      INTENT(IN),   OPTIONAL :: alloc_layer_vars
!INTF_END

#include "rttov_errorreport.interface"
#include "rttov_init_aux_prof.interface"

  LOGICAL(KIND=jplm) :: init1
  LOGICAL(KIND=jplm) :: alloc_layer_vars1
  INTEGER(KIND=jpim) :: nlayers

  TRY
  nlayers = nlevels - 1
  init1 = .FALSE.
  alloc_layer_vars1 = .FALSE.

  IF (PRESENT(alloc_layer_vars)) alloc_layer_vars1 = alloc_layer_vars
  IF (PRESENT(init)) init1 = init

  IF (asw == 1) THEN
    CALL nullify_struct()

    ALLOCATE (aux_prof%s(nprofiles), STAT = err)
    THROWM(err .NE. 0, "allocation of aux_prof%s")

    IF ((id_sensor == sensor_id_mw .OR. id_sensor == sensor_id_po) .AND. opts%rt_mw%clw_data) THEN
      IF (opts%rt_mw%clw_calc_on_coef_lev .AND. alloc_layer_vars .OR. &
          .NOT. opts%rt_mw%clw_calc_on_coef_lev .AND. .NOT. alloc_layer_vars) THEN
        IF (opts%rt_mw%clw_scheme == mw_clw_scheme_liebe) THEN
          ALLOCATE (aux_prof%debye_prof(5, nlevels, nprofiles), STAT = err)
          THROWM(err .NE. 0, "allocation of aux_prof%debye_prof")
        ELSEIF (opts%rt_mw%clw_scheme == mw_clw_scheme_rosenkranz) THEN
          ALLOCATE (aux_prof%ros_eps_s(nlayers, nprofiles),         &
                    aux_prof%ros_dr(nlayers, nprofiles),            &
                    aux_prof%ros_gammar(nlayers, nprofiles),        &
                    aux_prof%ros_db(nlayers, nprofiles),            &
                    aux_prof%ros_nu1(nlayers, nprofiles),           &
                    aux_prof%ros_z1(nlayers, nprofiles),            &
                    aux_prof%ros_log_abs_z1_sq(nlayers, nprofiles), &
                    aux_prof%ros_log_z1star_z2(nlayers, nprofiles), &
                    aux_prof%ros_div1(nlayers, nprofiles),          &
                    aux_prof%ros_div2(nlayers, nprofiles), STAT = err)
          THROWM(err .NE. 0, "allocation of aux_prof% Rosenkranz CLW parameters")
        ELSEIF (opts%rt_mw%clw_scheme == mw_clw_scheme_tkc) THEN
          ALLOCATE (aux_prof%tkc_eps_s(nlayers, nprofiles),   &
                    aux_prof%tkc_delta_1(nlayers, nprofiles), &
                    aux_prof%tkc_delta_2(nlayers, nprofiles), &
                    aux_prof%tkc_tau_1(nlayers, nprofiles),   &
                    aux_prof%tkc_tau_2(nlayers, nprofiles), STAT = err)
          THROWM(err .NE. 0, "allocation of aux_prof% TKC CLW parameters")
        ENDIF
        ALLOCATE (aux_prof%clw(nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of aux_prof%clw")
      ENDIF
    ENDIF

    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN
      ALLOCATE (aux_prof%clw_dg(nlevels, nprofiles),      &
                aux_prof%ice_dg(nlevels, nprofiles),      &
                aux_prof%fac1_ice_dg(nlevels, nprofiles), &
                aux_prof%fac2_ice_dg(nlevels, nprofiles), &
                aux_prof%fac3_ice_dg(nlevels, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ice effective diameter aux arrays")
    ENDIF

    IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
      ALLOCATE (aux_prof%relhum(nlayers, nprofiles),            &
                aux_prof%tave(nlayers, nprofiles),              &
                aux_prof%wmixave(nlayers, nprofiles),           &
                aux_prof%xpresave(nlayers, nprofiles),          &
                aux_prof%esw(nlayers, nprofiles),               &
                aux_prof%esi(nlayers, nprofiles),               &
                aux_prof%ppv(nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of aerosol scattering aux arrays")
    ENDIF

    IF (alloc_layer_vars1) THEN
      ALLOCATE(&
        aux_prof%t_layer(nlayers, nprofiles), aux_prof%w_layer(nlayers, nprofiles), aux_prof%o3_layer(nlayers, nprofiles), &
        aux_prof%dt(nlayers, nprofiles), aux_prof%dto(nlayers, nprofiles), &
        aux_prof%tr(nlayers, nprofiles), aux_prof%tr_r(nlayers, nprofiles), aux_prof%tr_sqrt(nlayers, nprofiles), &
        aux_prof%tw_sqrt(nlayers, nprofiles), aux_prof%wr_sqrt(nlayers, nprofiles), &
        aux_prof%wr_rsqrt(nlayers, nprofiles), &
        aux_prof%tw_4rt(nlayers, nprofiles), aux_prof%ww_r(nlayers, nprofiles), &
        aux_prof%ow_rsqrt(nlayers, nprofiles), aux_prof%ow_r(nlayers, nprofiles),& 
        aux_prof%or_sqrt(nlayers, nprofiles), aux_prof%ow_sqrt(nlayers, nprofiles), &
        aux_prof%wr(nlayers, nprofiles), aux_prof%or(nlayers, nprofiles), &
        aux_prof%tw(nlayers, nprofiles), aux_prof%ww(nlayers, nprofiles), &
        aux_prof%ow(nlayers, nprofiles), aux_prof%sum(nlayers, 5), STAT = err)
      THROWM(err .NE. 0, "allocation of aux_prof layer quantities")

      IF (coef%fmv_model_ver == 8) THEN
        ALLOCATE( &
          aux_prof%wwr(nlayers, nprofiles), aux_prof%wwr_r(nlayers, nprofiles), STAT=err)
        THROWM(err .NE. 0, "allocation of aux_prof layer quantities")

        IF (coef%nco2 > 0) THEN
          ALLOCATE( &
            aux_prof%co2_layer(nlayers, nprofiles), aux_prof%co2r(nlayers, nprofiles), &
            aux_prof%co2w(nlayers, nprofiles), aux_prof%twr(nlayers, nprofiles), STAT=err)
          THROWM(err .NE. 0, "allocation of aux_prof layer quantities")
        ENDIF
      ENDIF
    ENDIF

    IF (init1) CALL rttov_init_aux_prof(aux_prof)
  ENDIF

  IF (asw == 0) THEN
    DEALLOCATE (aux_prof%s, STAT = err)
    THROWM(err .NE. 0, "deallocation of aux_prof%s")

    IF ((id_sensor == sensor_id_mw .OR. id_sensor == sensor_id_po) .AND. opts%rt_mw%clw_data) THEN
      IF (opts%rt_mw%clw_calc_on_coef_lev .AND. alloc_layer_vars .OR. &
          .NOT. opts%rt_mw%clw_calc_on_coef_lev .AND. .NOT. alloc_layer_vars) THEN
        IF (opts%rt_mw%clw_scheme == mw_clw_scheme_liebe) THEN
          DEALLOCATE (aux_prof%debye_prof, STAT = err)
          THROWM(err .NE. 0, "deallocation of aux_prof%debye_prof")
        ELSEIF (opts%rt_mw%clw_scheme == mw_clw_scheme_rosenkranz) THEN
          DEALLOCATE (aux_prof%ros_eps_s,         &
                      aux_prof%ros_dr,            &
                      aux_prof%ros_gammar,        &
                      aux_prof%ros_db,            &
                      aux_prof%ros_nu1,           &
                      aux_prof%ros_z1,            &
                      aux_prof%ros_log_abs_z1_sq, &
                      aux_prof%ros_log_z1star_z2, &
                      aux_prof%ros_div1,          &
                      aux_prof%ros_div2, STAT = err)
          THROWM(err .NE. 0, "deallocation of aux_prof% Rosenkranz CLW parameters")
        ELSEIF (opts%rt_mw%clw_scheme == mw_clw_scheme_tkc) THEN
          DEALLOCATE (aux_prof%tkc_eps_s,   &
                      aux_prof%tkc_delta_1, &
                      aux_prof%tkc_delta_2, &
                      aux_prof%tkc_tau_1,   &
                      aux_prof%tkc_tau_2, STAT = err)
          THROWM(err .NE. 0, "deallocation of aux_prof% TKC CLW parameters")
        ENDIF
        DEALLOCATE (aux_prof%clw, STAT = err)
        THROWM(err .NE. 0, "deallocation of aux_prof%clw")
      ENDIF
    ENDIF

    IF (opts%rt_ir%addclouds .AND. .NOT. opts%rt_ir%user_cld_opt_param) THEN
      DEALLOCATE (aux_prof%clw_dg,      &
                  aux_prof%ice_dg,      &
                  aux_prof%fac1_ice_dg, &
                  aux_prof%fac2_ice_dg, &
                  aux_prof%fac3_ice_dg, STAT = err)
      THROWM(err .NE. 0, "deallocation of ice effective diameter aux arrays")
    ENDIF

    IF (opts%rt_ir%addaerosl .AND. .NOT. opts%rt_ir%user_aer_opt_param) THEN
      DEALLOCATE (aux_prof%relhum,    &
                  aux_prof%tave,      &
                  aux_prof%wmixave,   &
                  aux_prof%xpresave,  &
                  aux_prof%esw,       &
                  aux_prof%esi,       &
                  aux_prof%ppv, STAT = err)
      THROWM(err .NE. 0, "deallocation of aerosol scattering aux arrays")
    ENDIF

    IF (alloc_layer_vars1) THEN
      DEALLOCATE(&
        aux_prof%t_layer, aux_prof%w_layer, aux_prof%o3_layer, aux_prof%dt, &
        aux_prof%dto, aux_prof%tr, aux_prof%tr_r, aux_prof%tr_sqrt, aux_prof%tw_sqrt, &
        aux_prof%wr_sqrt, aux_prof%wr_rsqrt, aux_prof%tw_4rt, aux_prof%ww_r, aux_prof%ow_rsqrt,&
        aux_prof%ow_r, aux_prof%or_sqrt, aux_prof%ow_sqrt, aux_prof%wr, aux_prof%or, aux_prof%tw, &
        aux_prof%ww, aux_prof%ow, aux_prof%sum, STAT = err)
      THROWM(err .NE. 0, "deallocation of aux_prof layer quantities")

      IF (coef%fmv_model_ver == 8) THEN
        DEALLOCATE(aux_prof%wwr, aux_prof%wwr_r, STAT = err)
        THROWM(err .NE. 0, "deallocation of aux_prof layer quantities")

        IF (coef%nco2 > 0) THEN
          DEALLOCATE(aux_prof%co2_layer, aux_prof%co2r, aux_prof%co2w, aux_prof%twr, STAT = err)
          THROWM(err .NE. 0, "deallocation of aux_prof layer quantities")
        ENDIF
      ENDIF
    ENDIF

    CALL nullify_struct()
  ENDIF
  CATCH
CONTAINS
  SUBROUTINE nullify_struct()
    NULLIFY (aux_prof%s)
    NULLIFY (aux_prof%clw)
    NULLIFY (aux_prof%debye_prof)
    NULLIFY (aux_prof%ros_eps_s,         &
             aux_prof%ros_dr,            &
             aux_prof%ros_gammar,        &
             aux_prof%ros_db,            &
             aux_prof%ros_nu1,           &
             aux_prof%ros_z1,            &
             aux_prof%ros_log_abs_z1_sq, &
             aux_prof%ros_log_z1star_z2, &
             aux_prof%ros_div1,          &
             aux_prof%ros_div2)
    NULLIFY (aux_prof%tkc_eps_s,   &
             aux_prof%tkc_delta_1, &
             aux_prof%tkc_delta_2, &
             aux_prof%tkc_tau_1,   &
             aux_prof%tkc_tau_2)
    NULLIFY (aux_prof%clw_dg,      &
             aux_prof%ice_dg,      &
             aux_prof%fac1_ice_dg, &
             aux_prof%fac2_ice_dg, &
             aux_prof%fac3_ice_dg)
    NULLIFY (aux_prof%relhum,    &
             aux_prof%tave,      &
             aux_prof%wmixave,   &
             aux_prof%xpresave,  &
             aux_prof%esw,       &
             aux_prof%esi,       &
             aux_prof%ppv)
    NULLIFY(&
      aux_prof%t_layer, aux_prof%w_layer, aux_prof%o3_layer, aux_prof%dt, &
      aux_prof%dto, aux_prof%tr, aux_prof%tr_r, aux_prof%tw_sqrt, &
      aux_prof%wr_sqrt, aux_prof%wr_rsqrt, aux_prof%tw_4rt, aux_prof%ww_r, aux_prof%ow_rsqrt,&
      aux_prof%ow_r, aux_prof%or_sqrt, aux_prof%ow_sqrt, aux_prof%wr, aux_prof%or, aux_prof%tw, &
      aux_prof%ww, aux_prof%ow, aux_prof%sum, &
      aux_prof%co2_layer, aux_prof%co2r, aux_prof%co2w, aux_prof%twr, aux_prof%wwr, aux_prof%wwr_r)
  END SUBROUTINE nullify_struct
END SUBROUTINE 
