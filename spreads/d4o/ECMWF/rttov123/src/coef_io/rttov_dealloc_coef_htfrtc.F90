! Description:
!> @file
!!   Deallocate an HTFRTC coefficients structure.
!!   This should usually be called via rttov_dealloc_coefs.
!
!> @brief
!!   Deallocate an HTFRTC coefficients structure.
!!   This should usually be called via rttov_dealloc_coefs.
!!
!! @param[out]     err           status on exit
!! @param[in,out]  coef_htfrtc   the HTFRTC coefficient structure to deallocate
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
!    Copyright 2018, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_dealloc_coef_htfrtc(err, coef_htfrtc)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef_htfrtc
  USE parkind1, ONLY : jpim
  IMPLICIT NONE
  INTEGER(KIND=jpim),      INTENT(OUT)   :: err
  TYPE(rttov_coef_htfrtc), INTENT(INOUT) :: coef_htfrtc
!INTF_END
#include "rttov_errorreport.interface"
#include "rttov_nullify_coef_htfrtc.interface"
!- End of header --------------------------------------------------------
  TRY

  IF (ASSOCIATED(coef_htfrtc%gasid_l)) &
      DEALLOCATE(coef_htfrtc%gasid_l, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%gasid_nl)) &
      DEALLOCATE(coef_htfrtc%gasid_nl, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%freq)) &
      DEALLOCATE(coef_htfrtc%freq, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%p)) &
      DEALLOCATE(coef_htfrtc%p, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_l)) &
      DEALLOCATE(coef_htfrtc%val_l, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_nl)) &
      DEALLOCATE(coef_htfrtc%val_nl, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_t)) &
      DEALLOCATE(coef_htfrtc%val_t, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_mf_l)) &
      DEALLOCATE(coef_htfrtc%val_mf_l, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_mf_nl)) &
      DEALLOCATE(coef_htfrtc%val_mf_nl, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_b)) &
      DEALLOCATE(coef_htfrtc%val_b, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_lt)) &
      DEALLOCATE(coef_htfrtc%val_lt, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_l)) &
      DEALLOCATE(coef_htfrtc%coef_l, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_nl)) &
      DEALLOCATE(coef_htfrtc%coef_nl, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_b)) &
      DEALLOCATE(coef_htfrtc%coef_b, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_lt)) &
      DEALLOCATE(coef_htfrtc%coef_lt, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_ssemp)) &
      DEALLOCATE(coef_htfrtc%coef_ssemp, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_pdt)) &
      DEALLOCATE(coef_htfrtc%coef_pdt, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_mean)) &
      DEALLOCATE(coef_htfrtc%val_mean, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%val_norm)) &
      DEALLOCATE(coef_htfrtc%val_norm, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%sensor_freq)) &
      DEALLOCATE(coef_htfrtc%sensor_freq, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%ch_mean)) &
      DEALLOCATE(coef_htfrtc%ch_mean, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%pc)) &
      DEALLOCATE(coef_htfrtc%pc, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%coef_aux)) &
      DEALLOCATE(coef_htfrtc%coef_aux, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%mixed_ref_frac)) &
      DEALLOCATE(coef_htfrtc%mixed_ref_frac, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%solar)) &
      DEALLOCATE(coef_htfrtc%solar, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%mftlb)) &
      DEALLOCATE(coef_htfrtc%mftlb, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%alpha)) &
      DEALLOCATE(coef_htfrtc%alpha, STAT = err)
  THROW(err.NE.0)

  IF (ASSOCIATED(coef_htfrtc%gen_val)) &
      DEALLOCATE(coef_htfrtc%gen_val, STAT = err)
  THROW(err.NE.0)

  CALL rttov_nullify_coef_htfrtc(coef_htfrtc)

  CATCH
END SUBROUTINE
