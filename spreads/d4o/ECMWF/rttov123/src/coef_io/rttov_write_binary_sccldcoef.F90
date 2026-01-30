! Description:
!> @file
!!   Read a binary cloud coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read a binary cloud coefficient file, optionally extracting a subset of channels.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
!!
!!   Note that after reading a subset of channels RTTOV will identify them by
!!   indexes 1...SIZE(channels), not by the original channel numbers.
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
SUBROUTINE rttov_write_binary_sccldcoef( &
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
  INTEGER(KIND=jpim) :: wcl_pha_chn, wcldeff_pha_chn, icl_pha_chn
  LOGICAL(KIND=jplm) :: section_present
  LOGICAL(KIND=jplm) :: lverbose
  CHARACTER(LEN=80)  :: errMessage
!- End of header --------------------------------------------------------
  TRY
  IF (PRESENT(verbose)) THEN
    lverbose = verbose
  ELSE
    lverbose = .TRUE._jplm
  END IF

  ! Ensure we don't write out phase functions unnecessarily
  IF (ALL(coef%ss_val_chn(:) == 0)) THEN
    wcl_pha_chn  = 0
    wcldeff_pha_chn  = 0
    icl_pha_chn  = 0
  ELSE
    wcl_pha_chn  = coef_scatt_ir%fmv_wcl_pha_chn
    wcldeff_pha_chn  = coef_scatt_ir%fmv_wcldeff_pha_chn
    icl_pha_chn  = coef_scatt_ir%fmv_icl_pha_chn
  ENDIF

  IF (lverbose) THEN
    WRITE (errMessage, '( "write coefficient to file_id ", i2, " in binary format")') file_id
    INFO(errMessage)
  END IF

  ! Write a string that could be displayed
  ! Write a real number to be able to check single/double precision
  WRITE (file_id, iostat=err) rttov_magic_string, rttov_magic_number
  THROW(err.NE.0)

  ! Write an identifying string for cloud files (to avoid mixing up with aerosol files)
  WRITE (file_id, iostat=err) 'sccld_coef'
  THROW(err.NE.0)

  ! WATERCLOUD_TYPES

  WRITE (file_id, iostat=err) coef_scatt_ir%fmv_wcl_chn,  &   ! Number of channels
                              wcl_pha_chn,                &   ! Number of channels with phase fns
                              coef_scatt_ir%fmv_wcl_comp, &   ! Number of water cloud types
                              coef_scatt_ir%fmv_wcl_maxnmom   ! Max number of Leg coefs
  THROW(err.NE.0)

  IF (wcl_pha_chn > 0) THEN
    WRITE (file_id, iostat=err) coef_scatt_ir%wcl_pha_chanlist(:)
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) coef_scatt_ir%wcl_nphangle
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) coef_scatt_ir%wcl_phangle(:)
    THROW(err.NE.0)
  ENDIF

  WRITE (file_id, iostat=err) coef_scatt_ir%fmv_wcl_rh
  THROW(err.NE.0)

  WRITE (file_id, iostat=err) coef_scatt_ir%confac
  THROW(err.NE.0)

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    WRITE (file_id, iostat=err) optp%optpwcl(n)%fmv_wcl_rh_val
    THROW(err.NE.0)
  ENDDO


  ! WATERCLOUD_PARAMETERS

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    WRITE (file_id, iostat=err) optp%optpwcl(n)%abs
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    WRITE (file_id, iostat=err) optp%optpwcl(n)%sca
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    WRITE (file_id, iostat=err) optp%optpwcl(n)%bpr
    THROW(err.NE.0)
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    DO r = 1, coef_scatt_ir%fmv_wcl_rh(n)
      DO i = 1, coef_scatt_ir%fmv_wcl_chn
        WRITE (file_id, iostat=err) optp%optpwcl(n)%nmom(i,r)
        THROW(err.NE.0)

        WRITE (file_id, iostat=err) optp%optpwcl(n)%legcoef(1:optp%optpwcl(n)%nmom(i,r)+1,i,r)
        THROW(err.NE.0)
      ENDDO
    ENDDO
  ENDDO

  IF (wcl_pha_chn > 0) THEN
    DO n = 1, coef_scatt_ir%fmv_wcl_comp
      WRITE (file_id, iostat=err) optp%optpwcl(n)%pha
      THROW(err.NE.0)
    ENDDO
  ENDIF


  IF (ASSOCIATED(optp%optpicl)) THEN

    ! ICECLOUD_PARAMETERS

    WRITE (file_id, iostat=err) coef_scatt_ir%fmv_icl_chn,   &    ! Number of channels
                                icl_pha_chn,                 &    ! Number of channels with phase fns
                                coef_scatt_ir%fmv_icl_ndeff, &    ! Number of ice Deff values
                                coef_scatt_ir%fmv_icl_maxnmom     ! Max number of Leg coefs
    THROW(err.NE.0)

    IF (icl_pha_chn > 0) THEN
      WRITE (file_id, iostat=err) coef_scatt_ir%icl_pha_chanlist(:)
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) coef_scatt_ir%icl_nphangle
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) coef_scatt_ir%icl_phangle(:)
      THROW(err.NE.0)
    ENDIF

    WRITE (file_id, iostat=err) optp%optpicl%fmv_icl_deff(:)
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpicl%abs
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpicl%sca
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpicl%bpr
    THROW(err.NE.0)

    DO i = 1, coef_scatt_ir%fmv_icl_chn
      WRITE (file_id, iostat=err) optp%optpicl%nmom(1,i)
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) optp%optpicl%legcoef(1:optp%optpicl%nmom(1,i)+1,:,i)
      THROW(err.NE.0)
    ENDDO

    IF (icl_pha_chn > 0) THEN
      WRITE (file_id, iostat=err) optp%optpicl%pha
      THROW(err.NE.0)
    ENDIF

  ENDIF

  section_present = ASSOCIATED(optp%optpwcldeff)
  WRITE (file_id, iostat=err) section_present
  THROW(err.NE.0)

  IF (section_present) THEN

    ! WATERCLOUD_DEFF_PARAMETERS

    WRITE (file_id, iostat=err) coef_scatt_ir%fmv_wcldeff_chn,   &    ! Number of channels
                                wcldeff_pha_chn,                 &    ! Number of channels with phase fns
                                coef_scatt_ir%fmv_wcldeff_ndeff, &    ! Number of clw Deff values
                                coef_scatt_ir%fmv_wcldeff_maxnmom     ! Max number of Leg coefs
    THROW(err.NE.0)

    IF (wcldeff_pha_chn > 0) THEN
      WRITE (file_id, iostat=err) coef_scatt_ir%wcldeff_pha_chanlist(:)
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) coef_scatt_ir%wcldeff_nphangle
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) coef_scatt_ir%wcldeff_phangle(:)
      THROW(err.NE.0)
    ENDIF

    WRITE (file_id, iostat=err) optp%optpwcldeff%fmv_wcldeff_deff(:)
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpwcldeff%abs
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpwcldeff%sca
    THROW(err.NE.0)

    WRITE (file_id, iostat=err) optp%optpwcldeff%bpr
    THROW(err.NE.0)

    DO i = 1, coef_scatt_ir%fmv_wcldeff_chn
      WRITE (file_id, iostat=err) optp%optpwcldeff%nmom(1,i)
      THROW(err.NE.0)

      WRITE (file_id, iostat=err) optp%optpwcldeff%legcoef(1:optp%optpwcldeff%nmom(1,i)+1,:,i)
      THROW(err.NE.0)
    ENDDO

    IF (wcldeff_pha_chn > 0) THEN
      WRITE (file_id, iostat=err) optp%optpwcldeff%pha
      THROW(err.NE.0)
    ENDIF

  ENDIF

  IF (lverbose) INFO("end of write coefficient")
  CATCH
END SUBROUTINE
