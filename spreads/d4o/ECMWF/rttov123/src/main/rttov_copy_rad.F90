! Description:
!> @file
!!   Copy a radiance structure.
!
!> @brief
!!   Copy a radiance structure.
!!
!! @param[in,out] radiance1    copy of radiance structure
!! @param[in]     radiance2    input radiance structure
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
SUBROUTINE rttov_copy_rad(radiance1, radiance2)

  USE rttov_types, ONLY : rttov_radiance
  IMPLICIT NONE

  TYPE(rttov_radiance), INTENT(INOUT) :: radiance1
  TYPE(rttov_radiance), INTENT(IN)    :: radiance2
!INTF_END

  radiance1%clear       = radiance2%clear
  radiance1%total       = radiance2%total
  radiance1%bt_clear    = radiance2%bt_clear
  radiance1%bt          = radiance2%bt
  radiance1%refl_clear  = radiance2%refl_clear
  radiance1%refl        = radiance2%refl
  radiance1%cloudy      = radiance2%cloudy
  radiance1%overcast    = radiance2%overcast
END SUBROUTINE
