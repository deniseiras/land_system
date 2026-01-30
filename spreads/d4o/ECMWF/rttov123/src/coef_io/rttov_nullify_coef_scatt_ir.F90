! Description:
!> @file
!!   Nullify/zero a VIS/IR cloud optical properties structure.
!
!> @brief
!!   Nullify/zero a VIS/IR cloud optical properties structure.
!!
!!
!! @param[in,out]  coef_scatt_ir     the cloud/aerosol optical properties structure to nullify/zero
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
SUBROUTINE rttov_nullify_coef_scatt_ir(coef_scatt_ir)
!INTF_OFF
  USE parkind1, ONLY : jpim
!INTF_ON
  USE rttov_types, ONLY : rttov_coef_scatt_ir
  IMPLICIT NONE
  TYPE(rttov_coef_scatt_ir), INTENT(INOUT) :: coef_scatt_ir
!INTF_END
  coef_scatt_ir%fmv_aer_chn         = 0_jpim
  coef_scatt_ir%fmv_wcl_chn         = 0_jpim
  coef_scatt_ir%fmv_wcldeff_chn     = 0_jpim
  coef_scatt_ir%fmv_icl_chn         = 0_jpim
  coef_scatt_ir%fmv_aer_pha_chn     = 0_jpim
  coef_scatt_ir%fmv_wcl_pha_chn     = 0_jpim
  coef_scatt_ir%fmv_wcldeff_pha_chn = 0_jpim
  coef_scatt_ir%fmv_icl_pha_chn     = 0_jpim
  coef_scatt_ir%fmv_aer_comp        = 0_jpim
  coef_scatt_ir%fmv_wcl_comp        = 0_jpim
  coef_scatt_ir%fmv_wcldeff_ndeff   = 0_jpim
  coef_scatt_ir%fmv_icl_ndeff       = 0_jpim
  coef_scatt_ir%aer_nphangle        = 0_jpim
  coef_scatt_ir%wcl_nphangle        = 0_jpim
  coef_scatt_ir%wcldeff_nphangle    = 0_jpim
  coef_scatt_ir%icl_nphangle        = 0_jpim
  coef_scatt_ir%fmv_aer_maxnmom     = 0_jpim
  coef_scatt_ir%fmv_wcl_maxnmom     = 0_jpim
  coef_scatt_ir%fmv_wcldeff_maxnmom = 0_jpim
  coef_scatt_ir%fmv_icl_maxnmom     = 0_jpim
  coef_scatt_ir%aer_phfn_int%zminphadiff     = 0
  coef_scatt_ir%wcl_phfn_int%zminphadiff     = 0
  coef_scatt_ir%wcldeff_phfn_int%zminphadiff = 0
  coef_scatt_ir%icl_phfn_int%zminphadiff     = 0
  NULLIFY (coef_scatt_ir%fmv_aer_comp_name)
  NULLIFY (coef_scatt_ir%fmv_wcl_comp_name)
  NULLIFY (coef_scatt_ir%fmv_aer_rh)
  NULLIFY (coef_scatt_ir%fmv_wcl_rh)
  NULLIFY (coef_scatt_ir%fmv_aer_rh_val)
  NULLIFY (coef_scatt_ir%fmv_wcl_rh_val)
  NULLIFY (coef_scatt_ir%fmv_wcldeff_deff)
  NULLIFY (coef_scatt_ir%fmv_icl_deff)
  NULLIFY (coef_scatt_ir%aer_pha_chanlist)
  NULLIFY (coef_scatt_ir%wcl_pha_chanlist)
  NULLIFY (coef_scatt_ir%wcldeff_pha_chanlist)
  NULLIFY (coef_scatt_ir%icl_pha_chanlist)
  NULLIFY (coef_scatt_ir%aer_pha_index)
  NULLIFY (coef_scatt_ir%wcl_pha_index)
  NULLIFY (coef_scatt_ir%wcldeff_pha_index)
  NULLIFY (coef_scatt_ir%icl_pha_index)
  NULLIFY (coef_scatt_ir%aer_phfn_int%iphangle)
  NULLIFY (coef_scatt_ir%wcl_phfn_int%iphangle)
  NULLIFY (coef_scatt_ir%wcldeff_phfn_int%iphangle)
  NULLIFY (coef_scatt_ir%icl_phfn_int%iphangle)
  NULLIFY (coef_scatt_ir%aer_phangle)
  NULLIFY (coef_scatt_ir%wcl_phangle)
  NULLIFY (coef_scatt_ir%wcldeff_phangle)
  NULLIFY (coef_scatt_ir%icl_phangle)
  NULLIFY (coef_scatt_ir%aer_phfn_int%cosphangle)
  NULLIFY (coef_scatt_ir%wcl_phfn_int%cosphangle)
  NULLIFY (coef_scatt_ir%wcldeff_phfn_int%cosphangle)
  NULLIFY (coef_scatt_ir%icl_phfn_int%cosphangle)
  NULLIFY (coef_scatt_ir%abs)
  NULLIFY (coef_scatt_ir%sca)
  NULLIFY (coef_scatt_ir%bpr)
  NULLIFY (coef_scatt_ir%nmom)
  NULLIFY (coef_scatt_ir%legcoef)
  NULLIFY (coef_scatt_ir%pha)
  NULLIFY (coef_scatt_ir%confac)
  NULLIFY (coef_scatt_ir%aer_mmr2nd)
END SUBROUTINE 
