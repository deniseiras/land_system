! Description:
!> @file
!!   Add two internal auxiliary profile structures.
!
!> @brief
!!   Add two internal auxiliary profile structures.
!!
!! @details
!!   Aux prof structures are allocated on coef levels and on user levels
!!   and there is only a small amount of overlap in the data required
!!   for each set of levels (see rttov_alloc_aux_prof).
!!
!!   This add subroutine is used to accumulate AD/K data from the user level
!!   structure in the coef level structure when the interpolator is not
!!   used. Only the data required on both coef and user levels is added.
!!
!! @param[in,out] aux_prof          output summed auxiliary profile structure
!! @param[in]     aux_prof1         first input auxiliary profile structure
!! @param[in]     aux_prof2         second input auxiliary profile structure
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
SUBROUTINE rttov_add_aux_prof(aux_prof, aux_prof1, aux_prof2)

  USE rttov_types, ONLY : rttov_profile_aux
  IMPLICIT NONE
  TYPE(rttov_profile_aux), INTENT(INOUT) :: aux_prof
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux_prof1
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux_prof2
!INTF_END
  aux_prof%s%pfraction_surf = aux_prof1%s%pfraction_surf + aux_prof2%s%pfraction_surf
  aux_prof%s%pfraction_ctp  = aux_prof1%s%pfraction_ctp  + aux_prof2%s%pfraction_ctp
  aux_prof%s%cfraction      = aux_prof1%s%cfraction      + aux_prof2%s%cfraction
END SUBROUTINE
