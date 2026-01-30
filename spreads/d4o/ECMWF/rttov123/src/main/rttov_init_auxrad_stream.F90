! Description:
!> @file
!!   Initialise internal dyanmically-sized auxiliary radiance
!!   structure.
!
!> @brief
!!   Initialise internal dyanmically-sized auxiliary radiance
!!   structure.
!!
!! @param[in,out] auxrad_stream          auxiliary radiance structure to initialise
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
SUBROUTINE rttov_init_auxrad_stream(auxrad_stream)

  USE rttov_types, ONLY : rttov_radiance_aux
!INTF_OFF
  USE parkind1, ONLY : jprb
!INTF_ON
  IMPLICIT NONE
  TYPE(rttov_radiance_aux), INTENT(INOUT) :: auxrad_stream
!INTF_END

  IF (ASSOCIATED(auxrad_stream%up))                 auxrad_stream%up                 = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down))               auxrad_stream%down               = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down_p))             auxrad_stream%down_p             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%up_solar))           auxrad_stream%up_solar           = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down_solar))         auxrad_stream%down_solar         = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down_ref))           auxrad_stream%down_ref           = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down_p_ref))         auxrad_stream%down_p_ref         = 0._jprb
  IF (ASSOCIATED(auxrad_stream%down_ref_solar))     auxrad_stream%down_ref_solar     = 0._jprb
  IF (ASSOCIATED(auxrad_stream%meanrad_up))         auxrad_stream%meanrad_up         = 0._jprb
  IF (ASSOCIATED(auxrad_stream%meanrad_down))       auxrad_stream%meanrad_down       = 0._jprb
  IF (ASSOCIATED(auxrad_stream%meanrad_down_p))     auxrad_stream%meanrad_down_p     = 0._jprb
  IF (ASSOCIATED(auxrad_stream%meanrad_up_solar))   auxrad_stream%meanrad_up_solar   = 0._jprb
  IF (ASSOCIATED(auxrad_stream%meanrad_down_solar)) auxrad_stream%meanrad_down_solar = 0._jprb
  IF (ASSOCIATED(auxrad_stream%cloudy))             auxrad_stream%cloudy             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac1_2))             auxrad_stream%fac1_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac3_2))             auxrad_stream%fac3_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac4_2))             auxrad_stream%fac4_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac5_2))             auxrad_stream%fac5_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac6_2))             auxrad_stream%fac6_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac7_2))             auxrad_stream%fac7_2             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac4_3))             auxrad_stream%fac4_3             = 0._jprb
  IF (ASSOCIATED(auxrad_stream%fac5_3))             auxrad_stream%fac5_3             = 0._jprb

END SUBROUTINE 
