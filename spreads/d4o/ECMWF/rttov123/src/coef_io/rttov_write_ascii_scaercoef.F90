! Description:
!> @file
!!   Write an ASCII aerosol coefficient file.
!
!> @brief
!!   Write an ASCII aerosol coefficient file.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
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
SUBROUTINE rttov_write_ascii_scaercoef( &
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
  IMPLICIT NONE

  INTEGER(KIND=jpim),        INTENT(OUT)          :: err
  TYPE(rttov_coef),          INTENT(IN)           :: coef
  TYPE(rttov_coef_scatt_ir), INTENT(IN)           :: coef_scatt_ir
  TYPE(rttov_optpar_ir),     INTENT(IN)           :: optp
  INTEGER(KIND=jpim),        INTENT(IN)           :: file_id
  LOGICAL(KIND=jplm),        INTENT(IN), OPTIONAL :: verbose

!INTF_END
#include "rttov_errorreport.interface"

  INTEGER(KIND=jpim) :: i, n, nrh
  INTEGER(KIND=jpim) :: aer_pha_chn
  LOGICAL(KIND=jplm) :: lverbose
  CHARACTER(LEN=32)  :: section
  CHARACTER(LEN=80)  :: errMessage
  CHARACTER(LEN=*), PARAMETER :: routinename = 'rttov_write_ascii_scaercoef'
!- End of header --------------------------------------------------------
  TRY
  IF (PRESENT(verbose)) THEN
    lverbose = verbose
  ELSE
    lverbose = .TRUE._jplm
  END IF

  ! Ensure we don't write out phase functions unnecessarily
  IF (ALL(coef%ss_val_chn(:) == 0)) THEN
    aer_pha_chn = 0
  ELSE
    aer_pha_chn = coef_scatt_ir%fmv_aer_pha_chn
  ENDIF


  IF (lverbose) THEN
    WRITE (errMessage, '( "write coefficient to file_id ", i2, " in ASCII format")') file_id
    INFO(errMessage)
  END IF

  WRITE (file_id, '(a)', iostat=err) ' ! RTTOV coefficient file '//TRIM(coef%id_common_name)
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' ! Automatic creation by subroutine '//routinename
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
  THROW(err.NE.0)


  section = 'AEROSOLS_COMPONENTS'
  WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) TRIM(section)
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' !'
  THROW(err.NE.0)

  WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
    coef_scatt_ir%fmv_aer_chn, '! Number of channels for which optical parameters are stored'
  THROW(err.NE.0)

  WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
    aer_pha_chn, '! Number of channels for which phase functions are stored'
  THROW(err.NE.0)

  WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
    coef_scatt_ir%fmv_aer_maxnmom, '! Maximum number of Legendre coefficients'
  THROW(err.NE.0)

  IF (aer_pha_chn > 0) THEN
    WRITE(file_id,'(1x,a)', iostat=err) '! Channel list for which phase functions are stored'
    THROW(err.NE.0)
    WRITE(file_id,'(10i6)', iostat=err) coef_scatt_ir%aer_pha_chanlist(1:aer_pha_chn)
    THROW(err.NE.0)

    WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%aer_nphangle, '! Number of angles for phase function'
    THROW(err.NE.0)
    WRITE(file_id,'(1x,a)', iostat=err) '! Phase function angles'
    THROW(err.NE.0)
    WRITE (file_id, '(10f8.3)', iostat=err) coef_scatt_ir%aer_phangle
    THROW(err.NE.0)
  ENDIF

  WRITE(file_id,'(1x,i8,t20,a)') &
    coef_scatt_ir%fmv_aer_comp, '! Number of aerosol types'

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    IF (LEN_TRIM(coef_scatt_ir%fmv_aer_comp_name(n)) > 0) THEN
      WRITE (file_id, '(a5)', iostat=err) TRIM(coef_scatt_ir%fmv_aer_comp_name(n))
    ELSE
      WRITE (file_id, '(a)', iostat=err)' aerosol ! default name for '//routinename
    ENDIF
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_aer_rh(n), '! RH values for which parameters are available'
    THROW(err.NE.0)

    WRITE (file_id, '(10f7.2)', iostat=err) optp%optpaer(n)%fmv_aer_rh_val
    THROW(err.NE.0)

    WRITE (file_id, '(1x,e16.8,t20,a)', iostat=err) &
      coef_scatt_ir%aer_mmr2nd(n), '! Conversion factor for MMR to particle density'
    THROW(err.NE.0)
  ENDDO


  section = 'AEROSOLS_PARAMETERS'
  WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) TRIM(section)
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' !'
  THROW(err.NE.0)

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    DO nrh = 1, coef_scatt_ir%fmv_aer_rh(n)

      WRITE (file_id, '(a)', iostat=err) ' ! ---------------------'
      THROW(err.NE.0)

      IF (LEN_TRIM(coef_scatt_ir%fmv_aer_comp_name(n)) > 0) THEN
        WRITE (file_id, '(a5,i2.2)', iostat=err) TRIM(coef_scatt_ir%fmv_aer_comp_name(n)), &
                                                 INT(optp%optpaer(n)%fmv_aer_rh_val(nrh))
      ELSE
        WRITE (file_id, '(a)', iostat=err) ' aerosol ! default name for '//routinename
      ENDIF
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpaer(n)%abs(:,nrh)
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpaer(n)%sca(:,nrh)
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpaer(n)%bpr(:,nrh)
      THROW(err.NE.0)

      DO i = 1, coef%fmv_chn
        WRITE (file_id, '(i6)', iostat=err) optp%optpaer(n)%nmom(i,nrh)
        THROW(err.NE.0)

        WRITE (file_id, '(5e16.8)', iostat=err) &
          optp%optpaer(n)%legcoef(1:optp%optpaer(n)%nmom(i,nrh)+1,i,nrh)
        THROW(err.NE.0)

        IF (aer_pha_chn > 0) THEN
          IF (coef_scatt_ir%aer_pha_index(i) > 0) THEN
            WRITE (file_id, '(5e16.8)', iostat=err) optp%optpaer(n)%pha(:,coef_scatt_ir%aer_pha_index(i),nrh)
            THROW(err.NE.0)
          ENDIF
        ENDIF
      ENDDO

    ENDDO
  ENDDO

  IF (lverbose) INFO("end of write coefficient")
  CATCH
END SUBROUTINE 
