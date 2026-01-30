! Description:
!> @file
!!   Nullify Mie coefficients.
!
!> @brief
!!   Nullify Mie coefficients.
!!
!! @details
!!   Nuliifies the pointers in the Mie table structure passed as an argument.
!!
!! @param[in,out]  coef_scatt   Mie table structure to nullify
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
SUBROUTINE rttov_nullify_scattcoeffs(coef_scatt)

  USE rttov_types, ONLY : rttov_scatt_coef

  IMPLICIT NONE

  TYPE(rttov_scatt_coef), INTENT(INOUT) :: coef_scatt
!INTF_END

  NULLIFY(coef_scatt%mie_freq, &
          coef_scatt%ext,      &
          coef_scatt%ssa,      &
          coef_scatt%asp)

END SUBROUTINE rttov_nullify_scattcoeffs
