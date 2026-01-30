! Description:
!> @file
!!   Nullify/zero a VIS/IR cloud optical properties structure.
!
!> @brief
!!   Nullify/zero a VIS/IR cloud optical properties structure.
!!
!!
!! @param[in,out]  optp     the cloud/aerosol optical properties structure to nullify/zero
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
SUBROUTINE rttov_nullify_optpar_ir(optp)

  USE rttov_types, ONLY : rttov_optpar_ir
  IMPLICIT NONE
  TYPE(rttov_optpar_ir), INTENT(INOUT) :: optp
!INTF_END
  NULLIFY (optp%optpaer)
  NULLIFY (optp%optpwcl)
  NULLIFY (optp%optpwcldeff)
  NULLIFY (optp%optpicl)
  NULLIFY (optp%optpiclbaran)
END SUBROUTINE 
