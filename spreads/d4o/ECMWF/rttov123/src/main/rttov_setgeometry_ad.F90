! Description:
!> @file
!!   AD of geometric calculations.
!!
!> @brief
!!   AD of geometric calculations.
!!
!! @param[in]     opts            RTTOV options structure
!! @param[in]     dosolar         flag indicating whether solar computations are being performed
!! @param[in]     plane_parallel  flag for strict plane parallel geometry
!! @param[in]     profiles        profiles structure (on user levels or coefficient levels)
!! @param[in,out] profiles_ad     profiles structure containing increments
!! @param[in]     aux             RTTOV profile_aux structure
!! @param[in]     coef            rttov_coef structure
!! @param[in]     angles          geometry structure
!! @param[in]     raytracing      raytracing structure
!! @param[in,out] raytracing_ad   raytracing structure containing increments
!! @param[in]     profiles_dry    profiles structure containing gas profiles in units of ppmv dry
!! @param[in,out] profiles_dry_ad profiles structure containing gas increments in units of ppmv dry
!! @param[in]     do_pmc_calc     flag indicating PMC calculations should be performed, optional
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
SUBROUTINE rttov_setgeometry_ad( &
              opts,           &
              dosolar,        &
              plane_parallel, &
              profiles,       &
              profiles_ad,    &
              aux,            &
              coef,           &
              angles,         &
              raytracing,     &
              raytracing_ad,  &
              profiles_dry,   &
              profiles_dry_ad,&
              do_pmc_calc)

  USE rttov_types, ONLY :   &
         rttov_coef,        &
         rttov_profile,     &
         rttov_profile_aux, &
         rttov_geometry,    &
         rttov_raytracing,  &
         rttov_options
  USE parkind1, ONLY : jplm
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options),     INTENT(IN)           :: opts
  LOGICAL(jplm),           INTENT(IN)           :: dosolar
  LOGICAL(jplm),           INTENT(IN)           :: plane_parallel
  TYPE(rttov_profile),     INTENT(IN)           :: profiles(:)
  TYPE(rttov_profile),     INTENT(INOUT)        :: profiles_ad(SIZE(profiles))
  TYPE(rttov_profile_aux), INTENT(IN)           :: aux
  TYPE(rttov_coef),        INTENT(IN)           :: coef
  TYPE(rttov_geometry),    INTENT(IN)           :: angles(SIZE(profiles))
  TYPE(rttov_raytracing),  INTENT(IN)           :: raytracing
  TYPE(rttov_raytracing),  INTENT(INOUT)        :: raytracing_ad
  TYPE(rttov_profile),     INTENT(IN)           :: profiles_dry(SIZE(profiles))
  TYPE(rttov_profile),     INTENT(INOUT)        :: profiles_dry_ad(SIZE(profiles))
  LOGICAL(jplm),           INTENT(IN), OPTIONAL :: do_pmc_calc
!INTF_END
#include "rttov_locpat_ad.interface"

  REAL   (KIND=jprb) :: ZHOOK_HANDLE

  IF (LHOOK) CALL DR_HOOK('RTTOV_SETGEOMETRY_AD', 0_jpim, ZHOOK_HANDLE)
  CALL rttov_locpat_ad( &
          opts,            &
          dosolar,         &
          plane_parallel,  &
          profiles,        &
          profiles_ad,     &
          profiles_dry,    &
          profiles_dry_ad, &
          aux,             &
          coef,            &
          angles,          &
          raytracing,      &
          raytracing_ad,   &
          do_pmc_calc)
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETGEOMETRY_AD', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setgeometry_ad
