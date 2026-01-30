! Description:
!> @file
!!   Deallocate a VIS/IR cloud/aerosol optical properties structure.
!!   This should usually be called via rttov_dealloc_coefs.
!
!> @brief
!!   Deallocate a VIS/IR cloud/aerosol optical properties structure.
!!   This should usually be called via rttov_dealloc_coefs.
!!
!! @param[out]     err             status on exit
!! @param[in,out]  coef_scatt_ir   the cloud/aerosol optical properties structure to deallocate
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
SUBROUTINE rttov_dealloc_coef_scatt_ir (err, coef_scatt_ir)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef_scatt_ir
  USE parkind1, ONLY : jpim

  IMPLICIT NONE

  INTEGER(jpim),             INTENT(OUT)   :: err
  TYPE(rttov_coef_scatt_ir), INTENT(INOUT) :: coef_scatt_ir
!INTF_END
#include "rttov_errorreport.interface"
#include "rttov_nullify_coef_scatt_ir.interface"
#include "rttov_alloc_phfn_int.interface"

!- End of header --------------------------------------------------------
  TRY

  IF (ASSOCIATED(coef_scatt_ir%fmv_aer_comp_name)) DEALLOCATE (coef_scatt_ir%fmv_aer_comp_name, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_wcl_comp_name)) DEALLOCATE (coef_scatt_ir%fmv_wcl_comp_name, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_aer_rh)) DEALLOCATE (coef_scatt_ir%fmv_aer_rh, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_wcl_rh)) DEALLOCATE (coef_scatt_ir%fmv_wcl_rh, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_aer_rh_val)) DEALLOCATE (coef_scatt_ir%fmv_aer_rh_val, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_wcl_rh_val)) DEALLOCATE (coef_scatt_ir%fmv_wcl_rh_val, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_wcldeff_deff)) DEALLOCATE (coef_scatt_ir%fmv_wcldeff_deff, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%fmv_icl_deff)) DEALLOCATE (coef_scatt_ir%fmv_icl_deff, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%aer_pha_chanlist)) DEALLOCATE (coef_scatt_ir%aer_pha_chanlist, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%wcl_pha_chanlist)) DEALLOCATE (coef_scatt_ir%wcl_pha_chanlist, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%wcldeff_pha_chanlist)) DEALLOCATE (coef_scatt_ir%wcldeff_pha_chanlist, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%icl_pha_chanlist)) DEALLOCATE (coef_scatt_ir%icl_pha_chanlist, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%aer_pha_index)) DEALLOCATE (coef_scatt_ir%aer_pha_index, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%wcl_pha_index)) DEALLOCATE (coef_scatt_ir%wcl_pha_index, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%wcldeff_pha_index)) DEALLOCATE (coef_scatt_ir%wcldeff_pha_index, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%icl_pha_index)) DEALLOCATE (coef_scatt_ir%icl_pha_index, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%aer_phangle)) THEN
    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%aer_phangle, coef_scatt_ir%aer_phfn_int, 0_jpim)
    THROW(err.NE.0)

    DEALLOCATE (coef_scatt_ir%aer_phangle, STAT=err)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coef_scatt_ir%wcl_phangle)) THEN
    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcl_phangle, coef_scatt_ir%wcl_phfn_int, 0_jpim)
    THROW(err.NE.0)

    DEALLOCATE (coef_scatt_ir%wcl_phangle, STAT=err)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coef_scatt_ir%wcldeff_phangle)) THEN
    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcldeff_phangle, coef_scatt_ir%wcldeff_phfn_int, 0_jpim)
    THROW(err.NE.0)

    DEALLOCATE (coef_scatt_ir%wcldeff_phangle, STAT=err)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coef_scatt_ir%icl_phangle)) THEN
    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%icl_phangle, coef_scatt_ir%icl_phfn_int, 0_jpim)
    THROW(err.NE.0)

    DEALLOCATE (coef_scatt_ir%icl_phangle, STAT=err)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coef_scatt_ir%abs)) DEALLOCATE (coef_scatt_ir%abs, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%sca)) DEALLOCATE (coef_scatt_ir%sca, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%bpr)) DEALLOCATE (coef_scatt_ir%bpr, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%nmom)) DEALLOCATE (coef_scatt_ir%nmom, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%legcoef)) DEALLOCATE (coef_scatt_ir%legcoef, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%pha)) DEALLOCATE (coef_scatt_ir%pha, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%confac)) DEALLOCATE (coef_scatt_ir%confac, STAT=err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_scatt_ir%aer_mmr2nd)) DEALLOCATE (coef_scatt_ir%aer_mmr2nd, STAT=err)
  THROW(err.NE.0)

  CALL rttov_nullify_coef_scatt_ir(coef_scatt_ir)

  CATCH
END SUBROUTINE
