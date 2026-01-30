! Description:
!> @file
!!   Calculates information related to the viewing and solar
!!   geometry.
!
!> @brief
!!   Calculates information related to the viewing and solar
!!   geometry.
!!
!! @details
!!   Angle-related calculations are done here. There are no
!!   associated TL/AD/K calculations for these.
!!
!!   The input profiles(:)%zenangle is the geometrical (no refraction)
!!   zenith angle to satellite at surface
!!
!!   The calculated angles(:)%viewang is the geometrical (no refraction)
!!   nadir angle to surface at satellite: viewang is calculated from
!!   zenangle by application of the sine rule.
!!
!!   This subroutine then calls rttov_locpat to calculate local path
!!   zenith angles due to refraction and curvature (if the optional
!!   aux, raytracing and profiles_dry arguments are supplied).
!!
!! @param[in]     opts            RTTOV options structure
!! @param[in]     dosolar         flag indicating whether solar computations are being performed
!! @param[in]     plane_parallel  flag for strict plane parallel geometry
!! @param[in]     profiles        profiles structure (on user levels or coefficient levels)
!! @param[in]     aux             RTTOV profile_aux structure, optional
!! @param[in]     coef            rttov_coef structure
!! @param[out]    angles          geometry structure
!! @param[in,out] raytracing      raytracing structure, optional
!! @param[in]     profiles_dry    profiles structure containing gas profiles in units of ppmv dry, optional
!! @param[in]     do_pmc_calc     flag indicating PMC calculations should be performed, optional, optional
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
SUBROUTINE rttov_setgeometry( &
              opts,           &
              dosolar,        &
              plane_parallel, &
              profiles,       &
              aux,            &
              coef,           &
              angles,         &
              raytracing,     &
              profiles_dry,   &
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
  USE rttov_const, ONLY : deg2rad
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_options),     INTENT(IN)              :: opts
  LOGICAL(jplm),           INTENT(IN)              :: dosolar
  LOGICAL(jplm),           INTENT(IN)              :: plane_parallel
  TYPE(rttov_profile),     INTENT(IN)              :: profiles(:)
  TYPE(rttov_profile_aux), INTENT(IN),    OPTIONAL :: aux
  TYPE(rttov_coef),        INTENT(IN)              :: coef
  TYPE(rttov_geometry),    INTENT(OUT)             :: angles(SIZE(profiles))
  TYPE(rttov_raytracing),  INTENT(INOUT), OPTIONAL :: raytracing
  TYPE(rttov_profile),     INTENT(IN),    OPTIONAL :: profiles_dry(SIZE(profiles))
  LOGICAL(jplm),           INTENT(IN),    OPTIONAL :: do_pmc_calc
!INTF_END
#include "rttov_locpat.interface"

  INTEGER(KIND=jpim) :: i, nprofiles
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------

!Notes on notation:
! zen  => zenith angle
!   (definition: angle at surface between view path to satellite and zenith)
! view => view angle
!   (definition: angle at the satellite between view path and nadir)
! _sq = square of given value
! _sqrt = square root of given value
! _minus1 = given value - 1
! trigonometric function abbreviations have their usual meanings
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETGEOMETRY', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(profiles)
  DO i = 1, nprofiles
    angles(i)%sinzen           = SIN(profiles(i)%zenangle * deg2rad)
    angles(i)%sinzen_sq        = angles(i)%sinzen * angles(i)%sinzen
    angles(i)%coszen           = COS(profiles(i)%zenangle * deg2rad)
    angles(i)%coszen_sq        = angles(i)%coszen * angles(i)%coszen
    angles(i)%seczen           = 1.0_jprb / ABS(angles(i)%coszen)
    angles(i)%seczen_sq        = angles(i)%seczen * angles(i)%seczen
    IF (plane_parallel) THEN
      angles(i)%sinview        = angles(i)%sinzen
    ELSE
      angles(i)%sinview        = angles(i)%sinzen / coef%ratoe
    ENDIF
    angles(i)%sinview_sq       = angles(i)%sinview * angles(i)%sinview
    angles(i)%cosview_sq       = 1.0_jprb - angles(i)%sinview_sq
    angles(i)%normzen          = profiles(i)%zenangle / 60.0_jprb   ! normalized zenith angle for ISEM

    angles(i)%coszen_sun       = COS(profiles(i)%sunzenangle * deg2rad)
    angles(i)%sinzen_sun       = SIN(profiles(i)%sunzenangle * deg2rad)

    angles(i)%sinlat           = SIN(profiles(i)%latitude * deg2rad)
    angles(i)%coslat           = COS(profiles(i)%latitude * deg2rad)
  ENDDO
  IF (PRESENT(raytracing) .AND. PRESENT(aux) .AND. PRESENT(profiles_dry)) THEN
    CALL rttov_locpat( &
            opts,           &
            dosolar,        &
            plane_parallel, &
            profiles,       &
            profiles_dry,   &
            aux,            &
            coef,           &
            angles,         &
            raytracing,     &
            do_pmc_calc)
  ENDIF
  IF (LHOOK) CALL DR_HOOK('RTTOV_SETGEOMETRY', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_setgeometry
