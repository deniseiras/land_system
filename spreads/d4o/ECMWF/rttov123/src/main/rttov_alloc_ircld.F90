! Description:
!> @file
!!   Allocate/deallocate internal ircld structure.
!
!> @brief
!!   Allocate/deallocate internal ircld structure.
!!
!! @details
!!   The ircld structure contains information about the calculated
!!   cloud columns ("streams") for cloudy IR scattering calculations.
!!
!! @param[out]    err            status on exit
!! @param[in]     opts           options to configure the simulations
!! @param[in]     nprofiles      number of profiles being simulated
!! @param[in,out] ircld          ircld structure to (de)allocate
!! @param[in]     nlayers        number of layers in input profiles
!! @param[in]     asw            1_jpim => allocate; 0_jpim => deallocate
!! @param[in]     init           set .TRUE. to initialise newly allocated structures, optional
!! @param[in]     direct         set .TRUE. if allocating direct model ircld structure, optional
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
SUBROUTINE rttov_alloc_ircld( &
              err,       &
              opts,      &
              nprofiles, &
              ircld,     &
              nlayers,   &
              asw,       &
              init,      &
              direct)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_ircld, rttov_options
  USE parkind1, ONLY : jpim, jplm
!INTF_OFF
  USE parkind1, ONLY : jprb
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),  INTENT(OUT)          :: err
  TYPE(rttov_options), INTENT(IN)           :: opts
  INTEGER(KIND=jpim),  INTENT(IN)           :: nprofiles
  INTEGER(KIND=jpim),  INTENT(IN)           :: nlayers
  TYPE(rttov_ircld),   INTENT(INOUT)        :: ircld
  INTEGER(KIND=jpim),  INTENT(IN)           :: asw      ! 1=allocate, 0=deallocate
  LOGICAL(KIND=jplm),  INTENT(IN), OPTIONAL :: init
  LOGICAL(KIND=jplm),  INTENT(IN), OPTIONAL :: direct
!INTF_END
#include "rttov_errorreport.interface"
#include "rttov_init_ircld.interface"

  LOGICAL(KIND=jplm) :: init1, direct1
!- End of header --------------------------------------------------------
  TRY
  init1 = .FALSE.
  IF (PRESENT(init)) init1 = init

  direct1 = .FALSE.
  IF (PRESENT(direct)) direct1 = direct

  IF (asw == 1) THEN
    CALL nullify_struct()

    ! This is used as a lookup: for each channel/layer/stream it tells us
    ! whether the layer is cloudy or non-cloudy
    IF (direct1) THEN
      IF (opts%rt_ir%addclouds) THEN
        ALLOCATE (ircld%icldarr(0:2*nlayers, nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%icldarr")
      ELSE
        ALLOCATE (ircld%icldarr(0:0, nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%icldarr")
      ENDIF
    ENDIF

    IF (opts%rt_ir%addclouds) THEN
      ALLOCATE (ircld%xstr(2*nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%xstr")
      ALLOCATE (ircld%cldcfr(nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%cldcfr")
      ALLOCATE (ircld%maxcov(nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%maxcov")
      ALLOCATE (ircld%xstrmax(nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%xstrmax")
      ALLOCATE (ircld%xstrmin(nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%xstrmin")
      ALLOCATE (ircld%a(2*nlayers, nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%a")

      IF (direct1) THEN
        ALLOCATE (ircld%xstrref1(2*nlayers, 2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%xstrref1")
        ALLOCATE (ircld%xstrref2(2*nlayers, 2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%xstrref2")
        ALLOCATE (ircld%xstrref(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%xstrref")
        ALLOCATE (ircld%xstrminref(nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%xstrminref")
        ALLOCATE (ircld%ntotref(nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%ntotref")
        ALLOCATE (ircld%indexstr(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%indexstr")
        ALLOCATE (ircld%icount1ref(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%icount1ref")
        ALLOCATE (ircld%iloopin(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%iloopin")
        ALLOCATE (ircld%flag(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%flag")
        ALLOCATE (ircld%iflag(2*nlayers, nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld%iflag")
      ENDIF

      IF (direct1) THEN
        ALLOCATE (ircld%nstreamref(nprofiles), &
                  ircld%iloop(nprofiles),      &
                  ircld%icount(nprofiles),     &
                  ircld%icounstr(nprofiles),   &
                  ircld%icount1(nprofiles), STAT = err)
        THROWM(err .NE. 0, "allocation of ircld")
      ENDIF
    ENDIF

    ALLOCATE (ircld%xstrclr(nprofiles), STAT = err)
    THROWM(err .NE. 0, "allocation of ircld%xstrclr")
    ircld%xstrclr = 1._jprb

    IF (direct1) THEN
      ALLOCATE (ircld%nstream(nprofiles), STAT = err)
      THROWM(err .NE. 0, "allocation of ircld%nstream")
      ircld%nstream = 0_jpim
    ENDIF

    IF (init1) THEN
      IF (direct1 .AND. opts%rt_ir%addclouds) THEN
        ircld%nstreamref = 0_jpim
        ircld%iloop      = 0_jpim
        ircld%icount     = 0_jpim
        ircld%icounstr   = 0_jpim
        ircld%icount1    = 0_jpim
      ENDIF
      CALL rttov_init_ircld(ircld)
    ENDIF
  ENDIF

  IF (asw == 0) THEN
    IF (ASSOCIATED(ircld%icldarr)) THEN
      DEALLOCATE (ircld%icldarr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%icldarr")
    ENDIF
    IF (ASSOCIATED(ircld%xstrref1)) THEN
      DEALLOCATE (ircld%xstrref1, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrref1")
    ENDIF
    IF (ASSOCIATED(ircld%xstrref2)) THEN
      DEALLOCATE (ircld%xstrref2, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrref2")
    ENDIF
    IF (ASSOCIATED(ircld%xstr)) THEN
      DEALLOCATE (ircld%xstr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstr")
    ENDIF
    IF (ASSOCIATED(ircld%xstrminref)) THEN
      DEALLOCATE (ircld%xstrminref, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrminref")
    ENDIF
    IF (ASSOCIATED(ircld%xstrref)) THEN
      DEALLOCATE (ircld%xstrref, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrref")
    ENDIF
    IF (ASSOCIATED(ircld%cldcfr)) THEN
      DEALLOCATE (ircld%cldcfr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%cldcfr")
    ENDIF
    IF (ASSOCIATED(ircld%maxcov)) THEN
      DEALLOCATE (ircld%maxcov, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%maxcov")
    ENDIF
    IF (ASSOCIATED(ircld%xstrmax)) THEN
      DEALLOCATE (ircld%xstrmax, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrmax")
    ENDIF
    IF (ASSOCIATED(ircld%xstrmin)) THEN
      DEALLOCATE (ircld%xstrmin, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrmin")
    ENDIF
    IF (ASSOCIATED(ircld%a)) THEN
      DEALLOCATE (ircld%a, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%a")
    ENDIF
    IF (ASSOCIATED(ircld%ntotref)) THEN
      DEALLOCATE (ircld%ntotref, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%ntotref")
    ENDIF
    IF (ASSOCIATED(ircld%indexstr)) THEN
      DEALLOCATE (ircld%indexstr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%indexstr")
    ENDIF
    IF (ASSOCIATED(ircld%icount1ref)) THEN
      DEALLOCATE (ircld%icount1ref, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%icount1ref")
    ENDIF
    IF (ASSOCIATED(ircld%iloopin)) THEN
      DEALLOCATE (ircld%iloopin, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%iloopin")
    ENDIF
    IF (ASSOCIATED(ircld%flag)) THEN
      DEALLOCATE (ircld%flag, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%flag")
    ENDIF
    IF (ASSOCIATED(ircld%iflag)) THEN
      DEALLOCATE (ircld%iflag, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%iflag")
    ENDIF

    IF (ASSOCIATED(ircld%nstream)) THEN
      DEALLOCATE (ircld%nstream, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%nstream")
    ENDIF
    IF (ASSOCIATED(ircld%nstreamref)) THEN
      DEALLOCATE (ircld%nstreamref, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%nstreamref")
    ENDIF
    IF (ASSOCIATED(ircld%iloop)) THEN
      DEALLOCATE (ircld%iloop, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%iloop")
    ENDIF
    IF (ASSOCIATED(ircld%icount)) THEN
      DEALLOCATE (ircld%icount, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%icount")
    ENDIF
    IF (ASSOCIATED(ircld%icounstr)) THEN
      DEALLOCATE (ircld%icounstr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%icounstr")
    ENDIF
    IF (ASSOCIATED(ircld%icount1)) THEN
      DEALLOCATE (ircld%icount1, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%icount1")
    ENDIF
    IF (ASSOCIATED(ircld%xstrclr)) THEN
      DEALLOCATE (ircld%xstrclr, STAT = err)
      THROWM(err .NE. 0, "deallocation of ircld%xstrclr")
    ENDIF

    CALL nullify_struct()

  ENDIF
  CATCH

CONTAINS

  SUBROUTINE nullify_struct()
    NULLIFY (ircld%icldarr)
    NULLIFY (ircld%xstrref1)
    NULLIFY (ircld%xstrref2)
    NULLIFY (ircld%xstr)
    NULLIFY (ircld%xstrminref)
    NULLIFY (ircld%xstrref)
    NULLIFY (ircld%cldcfr)
    NULLIFY (ircld%maxcov)
    NULLIFY (ircld%xstrmax)
    NULLIFY (ircld%xstrmin)
    NULLIFY (ircld%a)
    NULLIFY (ircld%ntotref)
    NULLIFY (ircld%indexstr)
    NULLIFY (ircld%icount1ref)
    NULLIFY (ircld%iloopin)
    NULLIFY (ircld%flag)
    NULLIFY (ircld%iflag)
    NULLIFY (ircld%nstream)
    NULLIFY (ircld%nstreamref)
    NULLIFY (ircld%iloop)
    NULLIFY (ircld%icount)
    NULLIFY (ircld%icounstr)
    NULLIFY (ircld%icount1)
    NULLIFY (ircld%xstrclr)
  END SUBROUTINE nullify_struct

END SUBROUTINE rttov_alloc_ircld
