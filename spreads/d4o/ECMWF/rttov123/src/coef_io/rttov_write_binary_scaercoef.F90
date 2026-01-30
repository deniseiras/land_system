! Description:
!> @file
!!   Read a binary aerosol coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read a binary aerosol coefficient file, optionally extracting a subset of channels.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
!!
!!   Note that after reading a subset of channels RTTOV will identify them by
!!   indexes 1...SIZE(channels), not by the original channel numbers.
!!
!! @param[out]    err             status on exit
!! @param[in]     coef            RTTOV optical depth coefficient structure
!! @param[in]     coef_scatt_ir   RTTOV aerosol coef_scatt_ir coefficient structure
!! @param[in]     optp            RTTOV aerosol optp coefficient structure
!! @param[in]     file_id         logical unit for output scaercoef file
!! @param[in]     verbose         flag to switch verbose output on/off (default TRUE), optional
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
SUBROUTINE rttov_write_binary_scaercoef( &
              err,           &
              coef,          &
              coef_scatt_ir, &
              optp,          &
              file_id,       &
              verbose)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef, rttov_optpar_ir, rttov_coef_scatt_ir
  USE parkind1, ONLY : jpim, jplm
!INTF_OFF
  USE rttov_const, ONLY : rttov_magic_string, rttov_magic_number
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),        INTENT(OUT)          :: err
  TYPE(rttov_coef),          INTENT(IN)           :: coef
  TYPE(rttov_coef_scatt_ir), INTENT(IN)           :: coef_scatt_ir
  TYPE(rttov_optpar_ir),     INTENT(IN)           :: optp
  INTEGER(KIND=jpim),        INTENT(IN)           :: file_id
  LOGICAL(KIND=jplm),        INTENT(IN), OPTIONAL :: verbose

!INTF_END
#include "rttov_errorreport.interface"

  INTEGER(KIND=jpim) :: n, r, i
  INTEGER(KIND=jpim) :: aer_pha_chn
  LOGICAL(KIND=jplm) :: lverbose
  CHARACTER(LEN=80)  :: errMessage
!- End of header --------------------------------------------------------
  TRY
  IF (PRESENT(verbose)) THEN
    lverbose = verbose
  ELSE
    lverbose = .TRUE._jplm
  ENDIF

  ! Ensure we don't write out phase functions unnecessarily
  IF (ALL(coef%ss_val_chn(:) == 0)) THEN
    aer_pha_chn = 0
  ELSE
    aer_pha_chn = coef_scatt_ir%fmv_aer_pha_chn
  ENDIF

  IF (lverbose) THEN
    WRITE (errMessage, '( "write coefficient to file_id ", i2, " in binary format")') file_id
    INFO(errMessage)
  ENDIF

  ! Write a string that could be displayed
  ! Write a real number to be able to check single/double precision
  WRITE (file_id, iostat=err) rttov_magic_string, rttov_magic_number
  THROW(err.NE.0)

  ! Write an identifying string for aerosol files (to avoid mixing up with cloud files)
  WRITE (file_id, iostat=err) 'scaer_coef'
  THROW(err.NE.0)

  WRITE (file_id, iostat=err) coef_scatt_ir%fmv_aer_chn,  &   ! Number of channels
                              aer_pha_chn,                &   ! Number of channels with phase fns
                              coef_scatt_ir%fmv_aer_comp, &   ! Number of aerosol types
                              coef_scatt_ir%fmv_aer_maxnmom   ! Max number of Leg coefs
  THROW(err.NE.0)

  IF (aer_pha_chn > 0) THEN
    WRITE (file_id, iostat=err) coef_scatt_ir%aer_pha_chanlist(:)
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) coef_scatt_ir%aer_nphangle
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) coef_scatt_ir%aer_phangle(:)
    THROW(err.NE.0)
  ENDIF

  WRITE (file_id, iostat=err) coef_scatt_ir%fmv_aer_rh
  THROW(err.NE.0)

  WRITE (file_id, iostat=err) coef_scatt_ir%aer_mmr2nd
  THROW(err.NE.0)

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    WRITE (file_id, iostat=err) optp%optpaer(n)%fmv_aer_rh_val
    THROW(err.NE.0)
  ENDDO

  ! AEROSOLS_PARAMETERS

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    WRITE (file_id, iostat=err) optp%optpaer(n)%abs
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    WRITE (file_id, iostat=err) optp%optpaer(n)%sca
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    WRITE (file_id, iostat=err) optp%optpaer(n)%bpr
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    DO r = 1, coef_scatt_ir%fmv_aer_rh(n)
      DO i = 1, coef_scatt_ir%fmv_aer_chn
        WRITE (file_id, iostat=err) optp%optpaer(n)%nmom(i,r)
        THROW(err.NE.0)

        WRITE (file_id, iostat=err) optp%optpaer(n)%legcoef(1:optp%optpaer(n)%nmom(i,r)+1,i,r)
        THROW(err.NE.0)
      ENDDO
    ENDDO
  ENDDO

  IF (aer_pha_chn > 0) THEN
    DO n = 1, coef_scatt_ir%fmv_aer_comp
      WRITE (file_id, iostat=err) optp%optpaer(n)%pha
      THROW(err.NE.0)
    ENDDO
  ENDIF

  IF (lverbose) INFO("end of write coefficient")
  CATCH
END SUBROUTINE 
