! Description:
!> @file
!!   Deallocate a coefficients structure.
!
!> @brief
!!   Deallocate a coefficients structure.
!!
!! @details
!!   The various components of the coefficients structure are deallocated
!!   by calls to several deallocation subroutines: in general coefficients
!!   should be deallocated by calling this top-level subroutine so that
!!   the "initialised" flag is reset to false.
!!
!!   This subroutine should be called once per rttov_coefs structure
!!   when all RTTOV calls are completed.
!!
!!   The various coefficient arrays are allocated when the coefficients are
!!   read in by the call to rttov_read_coefs.
!!
!! @param[out]     err     status on exit
!! @param[in,out]  coefs   coefficients structure
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
SUBROUTINE rttov_dealloc_coefs(err, coefs)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coefs
  USE parkind1, ONLY : jpim

  IMPLICIT NONE

  INTEGER(KIND=jpim), INTENT(OUT)   :: err
  TYPE(rttov_coefs),  INTENT(INOUT) :: coefs
!INTF_END

#include "rttov_errorreport.interface"
#include "rttov_dealloc_optpar_ir.interface"
#include "rttov_dealloc_coef_scatt_ir.interface"
#include "rttov_dealloc_coef_pccomp.interface"
#include "rttov_dealloc_coef_mfasis.interface"
#include "rttov_dealloc_coef_htfrtc.interface"
#include "rttov_dealloc_coef.interface"
!- End of header --------------------------------------------------------

  TRY

  IF (ASSOCIATED(coefs%optp%optpaer)     .OR. &
      ASSOCIATED(coefs%optp%optpwcl)     .OR. &
      ASSOCIATED(coefs%optp%optpwcldeff) .OR. &
      ASSOCIATED(coefs%optp%optpicl)     .OR. &
      ASSOCIATED(coefs%optp%optpiclbaran)) THEN
    CALL rttov_dealloc_optpar_ir(err, coefs%optp)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coefs%coef_scatt_ir%fmv_aer_rh)       .OR. &
      ASSOCIATED(coefs%coef_scatt_ir%fmv_wcl_rh)       .OR. &
      ASSOCIATED(coefs%coef_scatt_ir%fmv_wcldeff_deff) .OR. &
      ASSOCIATED(coefs%coef_scatt_ir%fmv_icl_deff)) THEN
    CALL rttov_dealloc_coef_scatt_ir(err, coefs%coef_scatt_ir)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coefs%coef_pccomp%pcreg)) THEN
    CALL rttov_dealloc_coef_pccomp(err, coefs%coef_pccomp)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coefs%coef_mfasis_cld%lut)) THEN
    CALL rttov_dealloc_coef_mfasis(err, coefs%coef_mfasis_cld)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coefs%coef_mfasis_aer%lut)) THEN
    CALL rttov_dealloc_coef_mfasis(err, coefs%coef_mfasis_aer)
    THROW(err.NE.0)
  ENDIF

  IF (ASSOCIATED(coefs%coef_htfrtc%p)) THEN
    CALL rttov_dealloc_coef_htfrtc(err, coefs%coef_htfrtc)
    THROW(err.NE.0)
  ENDIF

  CALL rttov_dealloc_coef(err, coefs%coef)
  THROW(err.NE.0)

  coefs%initialised = .FALSE.

  CATCH
END SUBROUTINE
