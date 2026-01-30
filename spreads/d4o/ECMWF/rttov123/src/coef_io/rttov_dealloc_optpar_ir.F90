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
!! @param[in,out]  optp            the cloud/aerosol optical properties structure to deallocate
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
SUBROUTINE rttov_dealloc_optpar_ir(err, optp)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_optpar_ir
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE rttov_const, ONLY : phangle_hires
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),    INTENT(OUT)   :: err
  TYPE(rttov_optpar_ir), INTENT(INOUT) :: optp
!INTF_END

#include "rttov_errorreport.interface"
#include "rttov_dealloc_coef_scatt_ir.interface"
#include "rttov_nullify_optpar_ir.interface"
#include "rttov_alloc_phfn_int.interface"

  INTEGER(KIND=jpim) :: n
!- End of header --------------------------------------------------------
  TRY

    IF (ASSOCIATED(optp%optpaer)) THEN
      DO n = 1, SIZE(optp%optpaer)
        CALL rttov_dealloc_coef_scatt_ir(err, optp%optpaer(n))
        THROW(err.NE.0)
      ENDDO

      DEALLOCATE (optp%optpaer, STAT=err)
      THROW(err.NE.0)
    ENDIF

    IF (ASSOCIATED(optp%optpwcl)) THEN
      DO n = 1, SIZE(optp%optpwcl)
        CALL rttov_dealloc_coef_scatt_ir(err, optp%optpwcl(n))
        THROW(err.NE.0)
      ENDDO

      DEALLOCATE (optp%optpwcl, STAT=err)
      THROW(err.NE.0)
    ENDIF

    IF (ASSOCIATED(optp%optpwcldeff)) THEN
      CALL rttov_dealloc_coef_scatt_ir(err, optp%optpwcldeff)
      THROW(err.NE.0)

      DEALLOCATE (optp%optpwcldeff, STAT=err)
      THROW(err.NE.0)
    ENDIF

    IF (ASSOCIATED(optp%optpicl)) THEN
      CALL rttov_dealloc_coef_scatt_ir(err, optp%optpicl)
      THROW(err.NE.0)

      DEALLOCATE (optp%optpicl, STAT=err)
      THROW(err.NE.0)
    ENDIF

    IF (ASSOCIATED(optp%optpiclbaran)) THEN
      ! CALL rttov_alloc_phfn_int(err, phangle_hires, optp%optpiclbaran%phfn_int, 0_jpim)
      ! THROW(err.NE.0)
      ! 
      ! DEALLOCATE(optp%optpiclbaran%q, optp%optpiclbaran%w, STAT=err)
      ! THROW(err.NE.0)

      DEALLOCATE (optp%optpiclbaran%iwn, STAT=err)
      THROW(err.NE.0)
      DEALLOCATE (optp%optpiclbaran%jwn, STAT=err)
      THROW(err.NE.0)
      DEALLOCATE (optp%optpiclbaran%dx_dwn, STAT=err)
      THROW(err.NE.0)
      NULLIFY (optp%optpiclbaran%iwn)
      NULLIFY (optp%optpiclbaran%jwn)
      NULLIFY (optp%optpiclbaran%dx_dwn)

      DEALLOCATE (optp%optpiclbaran, STAT=err)
      THROW(err.NE.0)
    ENDIF

    IF (ASSOCIATED(optp%optpiclbaran2018)) THEN
      CALL rttov_alloc_phfn_int(err, phangle_hires, optp%optpiclbaran2018%phfn_int, 0_jpim)
      THROW(err.NE.0)

      DEALLOCATE(optp%optpiclbaran2018%q, optp%optpiclbaran2018%w, STAT=err)
      THROW(err.NE.0)

      DEALLOCATE (optp%optpiclbaran2018%iwn, STAT=err)
      THROW(err.NE.0)
      DEALLOCATE (optp%optpiclbaran2018%jwn, STAT=err)
      THROW(err.NE.0)
      DEALLOCATE (optp%optpiclbaran2018%dx_dwn, STAT=err)
      THROW(err.NE.0)
      NULLIFY (optp%optpiclbaran2018%iwn)
      NULLIFY (optp%optpiclbaran2018%jwn)
      NULLIFY (optp%optpiclbaran2018%dx_dwn)

      DEALLOCATE (optp%optpiclbaran2018, STAT=err)
      THROW(err.NE.0)
    ENDIF

    CALL rttov_nullify_optpar_ir(optp)

  CATCH
END SUBROUTINE 
