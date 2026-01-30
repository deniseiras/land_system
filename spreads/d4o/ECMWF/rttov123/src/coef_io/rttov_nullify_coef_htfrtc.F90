! Description:
!> @file
!!   Nullify/zero an HTFRTC coefficients structure.
!
!> @brief
!!   Nullify/zero an HTFRTC coefficients structure.
!!
!!
!! @param[in,out]  coef_htfrtc     the HTFRTC coefficients structure to nullify/zero
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
SUBROUTINE rttov_nullify_coef_htfrtc(coef_htfrtc)
!INTF_OFF
  USE parkind1, ONLY : jpim
!INTF_ON
  USE rttov_types, ONLY : rttov_coef_htfrtc
  IMPLICIT NONE
  TYPE(rttov_coef_htfrtc), INTENT(INOUT) :: coef_htfrtc
!INTF_END

  coef_htfrtc%opt_prop_type = 0_jpim
  coef_htfrtc%pc_reg_type   = 0_jpim
  coef_htfrtc%n_f           = 0_jpim
  coef_htfrtc%n_gas_l       = 0_jpim
  coef_htfrtc%n_gas_nl      = 0_jpim
  coef_htfrtc%n_p           = 0_jpim
  coef_htfrtc%n_val_l       = 0_jpim
  coef_htfrtc%n_val_nl      = 0_jpim
  coef_htfrtc%n_t           = 0_jpim
  coef_htfrtc%n_mf_nl       = 0_jpim
  coef_htfrtc%n_b           = 0_jpim
  coef_htfrtc%n_lt          = 0_jpim
  coef_htfrtc%n_ssemp       = 0_jpim
  coef_htfrtc%n_pc          = 0_jpim
  coef_htfrtc%n_pc_oc       = 0_jpim
  coef_htfrtc%n_pc_emis     = 0_jpim
  coef_htfrtc%n_ch          = 0_jpim
  coef_htfrtc%n_mftlb       = 0_jpim
  coef_htfrtc%n_alpha       = 0_jpim
  coef_htfrtc%n_gen_dim     = 0_jpim
  coef_htfrtc%n_fit_dim     = 0_jpim

  NULLIFY (coef_htfrtc%gasid_l)
  NULLIFY (coef_htfrtc%gasid_nl)
  NULLIFY (coef_htfrtc%freq)
  NULLIFY (coef_htfrtc%p)
  NULLIFY (coef_htfrtc%val_l)
  NULLIFY (coef_htfrtc%val_nl)
  NULLIFY (coef_htfrtc%val_t)
  NULLIFY (coef_htfrtc%val_mf_l)
  NULLIFY (coef_htfrtc%val_mf_nl)
  NULLIFY (coef_htfrtc%val_b)
  NULLIFY (coef_htfrtc%val_lt)
  NULLIFY (coef_htfrtc%coef_l)
  NULLIFY (coef_htfrtc%coef_nl)
  NULLIFY (coef_htfrtc%coef_b)
  NULLIFY (coef_htfrtc%coef_lt)
  NULLIFY (coef_htfrtc%coef_ssemp)
  NULLIFY (coef_htfrtc%coef_pdt)
  NULLIFY (coef_htfrtc%val_mean)
  NULLIFY (coef_htfrtc%val_norm)
  NULLIFY (coef_htfrtc%sensor_freq)
  NULLIFY (coef_htfrtc%ch_mean)
  NULLIFY (coef_htfrtc%pc)
  NULLIFY (coef_htfrtc%coef_aux)
  NULLIFY (coef_htfrtc%mixed_ref_frac)
  NULLIFY (coef_htfrtc%solar)
  NULLIFY (coef_htfrtc%mftlb)
  NULLIFY (coef_htfrtc%alpha)
  NULLIFY (coef_htfrtc%gen_val)
END SUBROUTINE
