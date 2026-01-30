! Description:
!> @file
!!   Initialise internal ircld structure.
!
!> @brief
!!   Initialise internal ircld structure.
!!
!! @param[in,out] ircld          ircld structure to initialise
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
SUBROUTINE rttov_init_ircld(ircld)

  USE rttov_types, ONLY : rttov_ircld
!INTF_OFF
  USE parkind1, ONLY : jprb, jpim
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_ircld), INTENT(INOUT) :: ircld
!INTF_END
  ircld%xstrclr = 0._jprb
  IF (ASSOCIATED(ircld%icldarr)   ) ircld%icldarr    = 0_jpim
  IF (ASSOCIATED(ircld%xstrref1)  ) ircld%xstrref1   = 0._jprb
  IF (ASSOCIATED(ircld%xstrref2)  ) ircld%xstrref2   = 0._jprb
  IF (ASSOCIATED(ircld%indexstr)  ) ircld%indexstr   = 0_jpim
  IF (ASSOCIATED(ircld%icount1ref)) ircld%icount1ref = 0_jpim
  IF (ASSOCIATED(ircld%iloopin)   ) ircld%iloopin    = 0_jpim
  IF (ASSOCIATED(ircld%iflag)     ) ircld%iflag      = 0_jpim
  IF (ASSOCIATED(ircld%xstr)      ) ircld%xstr       = 0._jprb
  IF (ASSOCIATED(ircld%xstrminref)) ircld%xstrminref = 0._jprb
  IF (ASSOCIATED(ircld%xstrref)   ) ircld%xstrref    = 0._jprb
  IF (ASSOCIATED(ircld%cldcfr)    ) ircld%cldcfr     = 0._jprb
  IF (ASSOCIATED(ircld%maxcov)    ) ircld%maxcov     = 0._jprb
  IF (ASSOCIATED(ircld%xstrmax)   ) ircld%xstrmax    = 0._jprb
  IF (ASSOCIATED(ircld%xstrmin)   ) ircld%xstrmin    = 0._jprb
  IF (ASSOCIATED(ircld%a)         ) ircld%a          = 0._jprb
  IF (ASSOCIATED(ircld%ntotref)   ) ircld%ntotref    = 0._jprb
  IF (ASSOCIATED(ircld%flag)      ) ircld%flag       = .FALSE.
END SUBROUTINE 
