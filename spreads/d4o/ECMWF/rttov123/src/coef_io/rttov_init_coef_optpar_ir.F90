! Description:
!> @file
!!   Initialise a VIS/IR cloud optical properties structure.
!!   This should usually be called via rttov_init_coefs.
!
!> @brief
!!   Initialise a VIS/IR cloud optical properties structure.
!!   This should usually be called via rttov_init_coefs.
!!
!! @details
!!   This subroutine precalculates some data related to the Baran
!!   ice scheme for VIS/IR cloud scattering simulations.
!!
!! @param[out]     err      status on exit
!! @param[in]      coef     the optical depth coefficient structure
!! @param[in,out]  optp     the cloud/aerosol optical properties structure to initialise
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
SUBROUTINE rttov_init_coef_optpar_ir(err, coef, optp)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef, rttov_optpar_ir
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE mod_rttov_baran2014_icldata, ONLY : baran2014_wvn, n_baran2014_wn
  USE mod_rttov_baran2018_icldata, ONLY : baran2018_wvn, n_baran2018_wn
  USE parkind1, ONLY : jprb
  USE rttov_const, ONLY : phangle_hires, baran_ngauss
  USE rttov_scattering_mod, ONLY : gauss_quad
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),    INTENT(OUT)   :: err
  TYPE(rttov_coef),      INTENT(IN)    :: coef
  TYPE(rttov_optpar_ir), INTENT(INOUT) :: optp

!INTF_END
#include "rttov_errorreport.interface"
#include "rttov_alloc_phfn_int.interface"

  INTEGER(KIND=jpim) :: ichn, iwn, jwn
  REAL(KIND=jprb)    :: dx_dwn
!- End of header --------------------------------------------------------
  TRY

  ! Baran 2014

  ALLOCATE (optp%optpiclbaran, STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran" )

  ALLOCATE (optp%optpiclbaran%iwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran%iwn" )

  ALLOCATE (optp%optpiclbaran%jwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran%jwn" )

  ALLOCATE (optp%optpiclbaran%dx_dwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran%dx_dwn" )

  DO ichn = 1, coef%fmv_chn

    IF (baran2014_wvn(1) .GE. coef%ff_cwn(ichn)) THEN
      iwn = 1_jpim
      jwn = 1_jpim
      dx_dwn  = 0.0_jprb
    ELSEIF (baran2014_wvn(n_baran2014_wn) .LE. coef%ff_cwn(ichn)) THEN
      iwn = n_baran2014_wn
      jwn = n_baran2014_wn
      dx_dwn  = 0.0_jprb
    ELSE
      iwn = 1_jpim
      DO WHILE (baran2014_wvn(iwn) .LE. coef%ff_cwn(ichn))
       iwn = iwn + 1_jpim
      ENDDO
      iwn = iwn - 1_jpim
      jwn = iwn + 1_jpim
      dx_dwn  = (coef%ff_cwn(ichn) - baran2014_wvn(iwn)) / (baran2014_wvn(jwn)  - baran2014_wvn(iwn))
    ENDIF

    optp%optpiclbaran%iwn(ichn) = iwn
    optp%optpiclbaran%jwn(ichn) = jwn
    optp%optpiclbaran%dx_dwn(ichn) = dx_dwn

    ! Interpolations will be done like this:
    ! value = value(iwn) + ( value(jwn) - value(iwn) ) * dx_dwn

  ENDDO

  ! For the phase functions use the Baran 2018 arrays
  ! CALL rttov_alloc_phfn_int(err, phangle_hires, optp%optpiclbaran%phfn_int, 1_jpim)
  ! THROW(err.NE.0)
  ! 
  ! ALLOCATE(optp%optpiclbaran%q(baran_ngauss), optp%optpiclbaran%w(baran_ngauss), STAT=err)
  ! THROWM(err.NE.0, "allocation of Baran Gaussian quadrature arrays")
  ! 
  ! CALL gauss_quad(-1._jprb, 1._jprb, optp%optpiclbaran%q, optp%optpiclbaran%w)


  ! Baran 2018

  ALLOCATE (optp%optpiclbaran2018, STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran2018" )

  ALLOCATE (optp%optpiclbaran2018%iwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran2018%iwn" )

  ALLOCATE (optp%optpiclbaran2018%jwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran2018%jwn" )

  ALLOCATE (optp%optpiclbaran2018%dx_dwn(coef%fmv_chn), STAT=err)
  THROWM(err.NE.0, "allocation of optp%optpiclbaran2018%dx_dwn" )

  DO ichn = 1, coef%fmv_chn

    IF (baran2018_wvn(1) .GE. coef%ff_cwn(ichn)) THEN
      iwn = 1_jpim
      jwn = 1_jpim
      dx_dwn  = 0.0_jprb
    ELSEIF (baran2018_wvn(n_baran2018_wn) .LE. coef%ff_cwn(ichn)) THEN
      iwn = n_baran2018_wn
      jwn = n_baran2018_wn
      dx_dwn = 0.0_jprb
    ELSE
      iwn = 1_jpim
      DO WHILE (baran2018_wvn(iwn) .LE. coef%ff_cwn(ichn))
       iwn = iwn + 1_jpim
      ENDDO
      iwn = iwn - 1_jpim
      jwn = iwn + 1_jpim
      dx_dwn = (coef%ff_cwn(ichn) - baran2018_wvn(iwn)) / (baran2018_wvn(jwn)  - baran2018_wvn(iwn))
    ENDIF

    optp%optpiclbaran2018%iwn(ichn) = iwn
    optp%optpiclbaran2018%jwn(ichn) = jwn
    optp%optpiclbaran2018%dx_dwn(ichn) = dx_dwn

    ! Interpolations will be done like this:
    ! value = value(iwn) + ( value(jwn) - value(iwn) ) * dx_dwn

  ENDDO

  CALL rttov_alloc_phfn_int(err, phangle_hires, optp%optpiclbaran2018%phfn_int, 1_jpim)
  THROW(err.NE.0)

  ALLOCATE(optp%optpiclbaran2018%q(baran_ngauss), optp%optpiclbaran2018%w(baran_ngauss), STAT=err)
  THROWM(err.NE.0, "allocation of Baran Gaussian quadrature arrays")

  CALL gauss_quad(-1._jprb, 1._jprb, optp%optpiclbaran2018%q, optp%optpiclbaran2018%w)

  CATCH
END SUBROUTINE
