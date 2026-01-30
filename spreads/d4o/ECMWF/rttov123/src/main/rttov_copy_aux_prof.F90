! Description:
!> @file
!!   Copy an internal auxiliary profile structure.
!
!> @brief
!!   Copy an internal auxiliary profile structure.
!!
!! @details
!!   Aux prof structures are allocated on coef levels and on user levels
!!   and there is only a small amount of overlap in the data required
!!   for each set of levels (see rttov_alloc_aux_prof).
!!
!!   This copy subroutine is used to transfer data from the coef level
!!   structure to the user level structure when the interpolator is not
!!   used. Only the data required on both coef and user levels is copied.
!!
!! @param[in,out] aux_prof1         copy of auxiliary profile structure
!! @param[in]     aux_prof2         input auxiliary profile structure
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
SUBROUTINE rttov_copy_aux_prof(aux_prof1, aux_prof2)

  USE rttov_types, ONLY : rttov_profile_aux
  IMPLICIT NONE
  TYPE(rttov_profile_aux), INTENT(INOUT) :: aux_prof1
  TYPE(rttov_profile_aux), INTENT(IN)    :: aux_prof2
!INTF_END
  aux_prof1%s = aux_prof2%s
END SUBROUTINE
