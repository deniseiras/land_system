! Description:
!> @file
!!   Add two RTTOV-SCATT cloud profiles structures.
!
!> @brief
!!   Add two RTTOV-SCATT cloud profiles structures.
!!
!!
!! @param[in,out] cld_profiles       output summed cloud profiles structure
!! @param[in]     cld_profiles1      first input cloud profiles structure
!! @param[in]     cld_profiles2      second input cloud profiles structure
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
SUBROUTINE rttov_add_scatt_prof(cld_profiles, cld_profiles1, cld_profiles2)

  USE rttov_types, ONLY : rttov_profile_cloud
!INTF_OFF
  USE parkind1, ONLY : jpim
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_profile_cloud), INTENT(INOUT) :: cld_profiles(:)
  TYPE(rttov_profile_cloud), INTENT(IN)    :: cld_profiles1(SIZE(cld_profiles))
  TYPE(rttov_profile_cloud), INTENT(IN)    :: cld_profiles2(SIZE(cld_profiles))
!INTF_END
  INTEGER(KIND=jpim) :: iprof, nprofiles

  nprofiles = SIZE(cld_profiles)

  DO iprof = 1, nprofiles
    cld_profiles(iprof)%cfrac = cld_profiles1(iprof)%cfrac + cld_profiles2(iprof)%cfrac
    cld_profiles(iprof)%ph    = cld_profiles1(iprof)%ph + cld_profiles2(iprof)%ph
    cld_profiles(iprof)%cc    = cld_profiles1(iprof)%cc + cld_profiles2(iprof)%cc
    cld_profiles(iprof)%clw   = cld_profiles1(iprof)%clw + cld_profiles2(iprof)%clw
    cld_profiles(iprof)%rain  = cld_profiles1(iprof)%rain + cld_profiles2(iprof)%rain

    IF (ASSOCIATED(cld_profiles(iprof)%totalice) .AND. ASSOCIATED(cld_profiles1(iprof)%totalice) .AND. &
        ASSOCIATED(cld_profiles2(iprof)%totalice)) &
          cld_profiles(iprof)%totalice = cld_profiles1(iprof)%totalice + cld_profiles2(iprof)%totalice
    IF (ASSOCIATED(cld_profiles(iprof)%sp) .AND. ASSOCIATED(cld_profiles1(iprof)%sp) .AND. &
        ASSOCIATED(cld_profiles2(iprof)%sp)) &
          cld_profiles(iprof)%sp       = cld_profiles1(iprof)%sp + cld_profiles2(iprof)%sp
    IF (ASSOCIATED(cld_profiles(iprof)%ciw) .AND. ASSOCIATED(cld_profiles1(iprof)%ciw) .AND. &
        ASSOCIATED(cld_profiles2(iprof)%ciw)) &
          cld_profiles(iprof)%ciw      = cld_profiles1(iprof)%ciw + cld_profiles2(iprof)%ciw
  ENDDO
END SUBROUTINE rttov_add_scatt_prof
