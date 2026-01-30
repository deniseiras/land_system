! Description:
!> @file
!!   Compute RTTOV-SCATT cloud profile increment suitable for use in TL
!
!> @brief
!!   Compute RTTOV-SCATT cloud profile increment suitable for use in TL
!!
!! @details
!!   The various members of the increment are computed as small fractions of
!!   the corresponding members of the input profiles structures.
!!
!! @param[in,out] cld_profiles_inc     array of computed cloud profile increments
!! @param[in]     cld_profiles         cloud profiles
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
!    Copyright 2017, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_make_cld_profile_inc(cld_profiles_inc, cld_profiles)

  USE rttov_types, ONLY : rttov_profile_cloud
!INTF_OFF
  USE parkind1, ONLY : jprb, jpim
!INTF_ON
  IMPLICIT NONE
  TYPE(rttov_profile_cloud), INTENT(INOUT) :: cld_profiles_inc(:)
  TYPE(rttov_profile_cloud), INTENT(IN)    :: cld_profiles(SIZE(cld_profiles_inc))
!INTF_END
  INTEGER(KIND=jpim) :: j, nprofiles

  nprofiles = SIZE(cld_profiles_inc)
  DO j = 1, nprofiles
     ! Increment for PH has to match 2m p increment
    cld_profiles_inc(j)%ph    =  - 0.00001_jprb * cld_profiles(j)%ph

    cld_profiles_inc(j)%cfrac =  - 0.01_jprb * cld_profiles(j)%cfrac

    cld_profiles_inc(j)%cc    =  - 0.01_jprb * cld_profiles(j)%cc
    cld_profiles_inc(j)%clw   =  - 0.0001_jprb * cld_profiles(j)%clw
    cld_profiles_inc(j)%rain  =  - 0.0001_jprb * cld_profiles(j)%rain

    IF (cld_profiles(j)%use_totalice) THEN
      cld_profiles_inc(j)%totalice =  - 0.0001_jprb * cld_profiles(j)%totalice
    ELSE
      cld_profiles_inc(j)%ciw =  - 0.0001_jprb * cld_profiles(j)%ciw
      cld_profiles_inc(j)%sp  =  - 0.0001_jprb * cld_profiles(j)%sp
    ENDIF
  ENDDO

END SUBROUTINE rttov_make_cld_profile_inc
