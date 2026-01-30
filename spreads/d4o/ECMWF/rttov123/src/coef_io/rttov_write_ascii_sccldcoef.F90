! Description:
!> @file
!!   Write an ASCII cloud coefficient file.
!
!> @brief
!!   Write an ASCII cloud coefficient file.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
!!
!! @param[out]    err             status on exit
!! @param[in]     coef            RTTOV optical depth coefficient structure
!! @param[in]     coef_scatt_ir   RTTOV cloud coef_scatt_ir coefficient structure
!! @param[in]     optp            RTTOV cloud optp coefficient structure
!! @param[in]     file_id         logical unit for output sccldcoef file
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
SUBROUTINE rttov_write_ascii_sccldcoef ( &
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

  INTEGER(KIND=jpim) :: i, n, nrh, ideff
  INTEGER(KIND=jpim) :: wcl_pha_chn, wcldeff_pha_chn, icl_pha_chn
  LOGICAL(KIND=jplm) :: lverbose
  CHARACTER(LEN=32)  :: section
  CHARACTER(LEN=80)  :: errMessage
  CHARACTER(LEN=*), PARAMETER :: routinename = 'rttov_write_ascii_sccldcoef'
!- End of header --------------------------------------------------------
  TRY
  IF (PRESENT(verbose)) THEN
    lverbose = verbose
  ELSE
    lverbose = .TRUE._jplm
  END IF

  ! Ensure we don't write out phase functions unnecessarily
  IF (ALL(coef%ss_val_chn(:) == 0)) THEN
    wcl_pha_chn     = 0
    wcldeff_pha_chn = 0
    icl_pha_chn     = 0
  ELSE
    wcl_pha_chn     = coef_scatt_ir%fmv_wcl_pha_chn
    wcldeff_pha_chn = coef_scatt_ir%fmv_wcldeff_pha_chn
    icl_pha_chn     = coef_scatt_ir%fmv_icl_pha_chn
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

  section = 'WATERCLOUD_TYPES'
  WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) TRIM(section)
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' !'
  THROW(err.NE.0)

  WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
    coef_scatt_ir%fmv_wcl_chn, '! Number of channels for which optical parameters are stored'
  THROW(err.NE.0)

  WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
    wcl_pha_chn, '! Number of channels for which phase functions are stored'
  THROW(err.NE.0)

  WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
    coef_scatt_ir%fmv_wcl_maxnmom, '! Maximum number of Legendre coefficients'
  THROW(err.NE.0)

  IF (wcl_pha_chn > 0) THEN
    WRITE(file_id,'(1x,a)', iostat=err) '! Channel list for which phase functions are stored'
    THROW(err.NE.0)
    WRITE(file_id,'(10i6)', iostat=err) coef_scatt_ir%wcl_pha_chanlist(1:wcl_pha_chn)
    THROW(err.NE.0)

    WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%wcl_nphangle, '! Number of angles for phase function'
    THROW(err.NE.0)
    WRITE(file_id,'(1x,a)', iostat=err) '! Phase function angles'
    THROW(err.NE.0)
    WRITE (file_id, '(10f8.3)', iostat=err) coef_scatt_ir%wcl_phangle
    THROW(err.NE.0)
  ENDIF

  WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
    coef_scatt_ir%fmv_wcl_comp, '! Number of water cloud types'
  THROW(err.NE.0)

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    IF (LEN_TRIM(coef_scatt_ir%fmv_wcl_comp_name(n)) > 0) THEN
      WRITE (file_id, '(a5,i2.2)', iostat=err) TRIM(coef_scatt_ir%fmv_wcl_comp_name(n))
    ELSE
      WRITE (file_id, '(a)', iostat=err) ' cloud   ! default name for '//routinename
    ENDIF
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_wcl_rh(n), '! RH values for which parameters are available'
    THROW(err.NE.0)

    WRITE (file_id, '(10f7.2)', iostat=err) optp%optpwcl(n)%fmv_wcl_rh_val
    THROW(err.NE.0)

    WRITE (file_id, '(1x,f12.6,t20,a)', iostat=err) &
      coef_scatt_ir%confac(n), '! Conversion factor from LWC to particle density'
    THROW(err.NE.0)
  ENDDO

  section = 'WATERCLOUD_PARAMETERS'
  WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) TRIM(section)
  THROW(err.NE.0)

  WRITE (file_id, '(a)', iostat=err) ' !'
  THROW(err.NE.0)

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    DO nrh = 1, coef_scatt_ir%fmv_wcl_rh(n)

      WRITE (file_id, '(a)', iostat=err) ' ! ---------------------'
      THROW(err.NE.0)

      IF (LEN_TRIM(coef_scatt_ir%fmv_wcl_comp_name(n)) > 0) THEN
        WRITE (file_id, '(a5,i2.2)', iostat=err) TRIM(coef_scatt_ir%fmv_wcl_comp_name(n)), &
                                                 INT(optp%optpwcl(n)%fmv_wcl_rh_val(nrh))
      ELSE
        WRITE (file_id, '(a)', iostat=err) ' cloud   ! default name for '//routinename
      ENDIF
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcl(n)%abs(:,nrh)
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcl(n)%sca(:,nrh)
      THROW(err.NE.0)

      WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcl(n)%bpr(:,nrh)
      THROW(err.NE.0)

      DO i = 1, coef%fmv_chn
        WRITE (file_id, '(i6)', iostat=err) optp%optpwcl(n)%nmom(i,nrh)
        THROW(err.NE.0)

        WRITE (file_id, '(5e16.8)', iostat=err) &
          optp%optpwcl(n)%legcoef(1:optp%optpwcl(n)%nmom(i,nrh)+1,i,nrh)
        THROW(err.NE.0)

        IF (wcl_pha_chn > 0) THEN
          IF (coef_scatt_ir%wcl_pha_index(i) > 0) THEN
            WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcl(n)%pha(:,coef_scatt_ir%wcl_pha_index(i),nrh)
            THROW(err.NE.0)
          ENDIF
        ENDIF
      ENDDO

    ENDDO
  ENDDO

  IF (ASSOCIATED(optp%optpwcldeff)) THEN

    section = 'WATERCLOUD_DEFF_TYPES'
    WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) TRIM(section)
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) ' !'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_wcldeff_chn, '! Number of channels for which optical parameters are stored'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      wcldeff_pha_chn, '! Number of channels for which phase functions are stored'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_wcldeff_maxnmom, '! Maximum number of Legendre coefficients'
    THROW(err.NE.0)

    IF (wcldeff_pha_chn > 0) THEN
      WRITE(file_id,'(1x,a)', iostat=err) '! Channel list for which phase functions are stored'
      THROW(err.NE.0)
      WRITE(file_id,'(10i6)', iostat=err) coef_scatt_ir%wcldeff_pha_chanlist(1:wcldeff_pha_chn)
      THROW(err.NE.0)

      WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
        coef_scatt_ir%wcldeff_nphangle, '! Number of angles for phase function'
      THROW(err.NE.0)
      WRITE(file_id,'(1x,a)', iostat=err) '! Phase function angles'
      THROW(err.NE.0)
      WRITE (file_id, '(8f8.3)', iostat=err) coef_scatt_ir%wcldeff_phangle
      THROW(err.NE.0)
    ENDIF

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_wcldeff_ndeff, '! Number of effective diameters'
    THROW(err.NE.0)
    WRITE (file_id, '(1x,a)', iostat=err) '! Effective diameters'
    THROW(err.NE.0)
    WRITE (file_id, '(6e14.6)', iostat=err) optp%optpwcldeff%fmv_wcldeff_deff(:)
    THROW(err.NE.0)

    section = 'WATERCLOUD_DEFF_PARAMETERS'
    WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) TRIM(section)
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) ' !'
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcldeff%abs
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcldeff%sca
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcldeff%bpr
    THROW(err.NE.0)

    DO i = 1, coef%fmv_chn
      WRITE (file_id, '(i6)', iostat=err) optp%optpwcldeff%nmom(1,i)
      THROW(err.NE.0)

      DO ideff = 1, coef_scatt_ir%fmv_wcldeff_ndeff
        WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcldeff%legcoef(1:optp%optpwcldeff%nmom(1,i)+1,ideff,i)
        THROW(err.NE.0)
      ENDDO

      IF (wcldeff_pha_chn > 0) THEN
        IF (coef_scatt_ir%wcldeff_pha_index(i) > 0) THEN
          DO ideff = 1, coef_scatt_ir%fmv_wcldeff_ndeff
            WRITE (file_id, '(5e16.8)', iostat=err) optp%optpwcldeff%pha(:,ideff,coef_scatt_ir%wcldeff_pha_index(i))
            THROW(err.NE.0)
          ENDDO
        ENDIF
      ENDIF
    ENDDO

  ENDIF ! associated(optp%optpwcldeff)

  IF (ASSOCIATED(optp%optpicl)) THEN

    section = 'ICECLOUD_TYPES'
    WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) TRIM(section)
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) ' !'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_icl_chn, '! Number of channels for which optical parameters are stored'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      icl_pha_chn, '! Number of channels for which phase functions are stored'
    THROW(err.NE.0)

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_icl_maxnmom, '! Maximum number of Legendre coefficients'
    THROW(err.NE.0)

    IF (icl_pha_chn > 0) THEN
      WRITE(file_id,'(1x,a)', iostat=err) '! Channel list for which phase functions are stored'
      THROW(err.NE.0)
      WRITE(file_id,'(10i6)', iostat=err) coef_scatt_ir%icl_pha_chanlist(1:icl_pha_chn)
      THROW(err.NE.0)

      WRITE(file_id,'(1x,i8,t20,a)', iostat=err) &
        coef_scatt_ir%icl_nphangle, '! Number of angles for phase function'
      THROW(err.NE.0)
      WRITE(file_id,'(1x,a)', iostat=err) '! Phase function angles'
      THROW(err.NE.0)
      WRITE (file_id, '(8f8.3)', iostat=err) coef_scatt_ir%icl_phangle
      THROW(err.NE.0)
    ENDIF

    WRITE (file_id, '(1x,i8,t20,a)', iostat=err) &
      coef_scatt_ir%fmv_icl_ndeff, '! Number of effective diameters'
    THROW(err.NE.0)
    WRITE (file_id, '(1x,a)', iostat=err) '! Effective diameters'
    THROW(err.NE.0)
    WRITE (file_id, '(6e14.6)', iostat=err) optp%optpicl%fmv_icl_deff(:)
    THROW(err.NE.0)

    section = 'ICECLOUD_PARAMETERS'
    WRITE (file_id, '(a)', iostat=err) ' ! ------------------------------------------------------'
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) TRIM(section)
    THROW(err.NE.0)

    WRITE (file_id, '(a)', iostat=err) ' !'
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpicl%abs
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpicl%sca
    THROW(err.NE.0)

    WRITE (file_id, '(5e16.8)', iostat=err) optp%optpicl%bpr
    THROW(err.NE.0)

    DO i = 1, coef%fmv_chn
      WRITE (file_id, '(i6)', iostat=err) optp%optpicl%nmom(1,i)
      THROW(err.NE.0)

      DO ideff = 1, coef_scatt_ir%fmv_icl_ndeff
        WRITE (file_id, '(5e16.8)', iostat=err) optp%optpicl%legcoef(1:optp%optpicl%nmom(1,i)+1,ideff,i)
        THROW(err.NE.0)
      ENDDO

      IF (icl_pha_chn > 0) THEN
        IF (coef_scatt_ir%icl_pha_index(i) > 0) THEN
          DO ideff = 1, coef_scatt_ir%fmv_icl_ndeff
            WRITE (file_id, '(5e16.8)', iostat=err) optp%optpicl%pha(:,ideff,coef_scatt_ir%icl_pha_index(i))
            THROW(err.NE.0)
          ENDDO
        ENDIF
      ENDIF
    ENDDO

  ENDIF ! associated(optp%optpicl)

  IF (lverbose) INFO("end of write coefficient")
  CATCH
END SUBROUTINE 
