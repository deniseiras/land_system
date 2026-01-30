! Description:
!> @file
!!   Print out the contents of an RTTOV-SCATT cloud profile structure.
!
!> @brief
!!   Print out the contents of an RTTOV-SCATT cloud profile structure.
!!
!! @details
!!   If not supplied the output is written to the error_unit
!!   as set by rttov_errorhandling or the default if unset.
!!
!!   The optional text argument is printed at the top of the
!!   output.
!!
!! @param[in]   cld_profile   RTTOV-SCATT cloud profile structure
!! @param[in]   lu            logical unit for output, optional
!! @param[in]   text          additional text to print, optional
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
SUBROUTINE rttov_print_cld_profile(cld_profile, lu, text)

  USE rttov_types, ONLY : rttov_profile_cloud
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE rttov_global, ONLY : error_unit
!INTF_ON

  IMPLICIT NONE

  TYPE(rttov_profile_cloud), INTENT(IN)           :: cld_profile ! cloud profile
  INTEGER(KIND=jpim),        INTENT(IN), OPTIONAL :: lu          ! logical unit for print
  CHARACTER(LEN=*),          INTENT(IN), OPTIONAL :: text        ! text for print
!INTF_END

  INTEGER(KIND=jpim)  :: iu  ! logical unit for print
  INTEGER(KIND=jpim)  :: l   ! level
  CHARACTER(LEN=10)   :: snowrain_units

  iu = error_unit
  IF (PRESENT(lu)) iu = lu

  IF (cld_profile%mmr_snowrain) THEN
    snowrain_units = '(kg/kg)   '
  ELSE
    snowrain_units = '(kg/m^2/s)'
  ENDIF

  IF (PRESENT(text)) THEN
    WRITE(iu,'(/,a,a)') "RTTOV-SCATT cloud profile structure: ", TRIM(text)
  ELSE
    WRITE(iu,'(/,a)') "RTTOV-SCATT cloud profile structure"
  ENDIF
  WRITE(iu,'(2x,a,i4)') "number of levels ", cld_profile%nlevels
  WRITE(iu,'(2x,a,e14.6)') "user average cloud fraction (0 - 1)    ", cld_profile%cfrac

  WRITE(iu,'(a5,1x,a21,a10,2a15)',advance='no') &
    "level", "Pressure  top  bottom", "    CC    ", " CLW (kg/kg)  ", "Rain "//snowrain_units
  IF (cld_profile%use_totalice) THEN
    WRITE(iu,'(1x,a16)', advance='no') "Totalice (kg/kg)"
  ELSE
    WRITE(iu,'(2a15)', advance='no') " CIW (kg/kg)  ", "Snow "//snowrain_units
  ENDIF
  WRITE(iu,'(a)', advance='yes')

  DO l = 1, cld_profile%nlevels
    WRITE(iu,'(1x,i4,2(1x,f10.4),1x,f9.6,2(1x,e14.6))', advance='no') &
      l, cld_profile%ph(l), cld_profile%ph(l+1), cld_profile%cc(l), cld_profile%clw(l), cld_profile%rain(l)
    IF (cld_profile%use_totalice) THEN
      WRITE(iu,'(1x,e14.6)', advance='no') cld_profile%totalice(l)
    ELSE
      WRITE(iu,'(2(1x,e14.6))', advance='no') cld_profile%ciw(l), cld_profile%sp(l)
    ENDIF
    WRITE(iu,'(a)', advance='yes')
  ENDDO
END SUBROUTINE rttov_print_cld_profile
