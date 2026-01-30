! Description:
!> @file
!!   Allocate/deallocate structure for profiles input to DOM algorithm.
!
!> @brief
!!   Allocate/deallocate structure for profiles input to DOM algorithm.
!!
!! @details
!!   For the direct model this subroutine only allocates the array of
!!   structures according to nstreams and nchanprof. The allocation of
!!   member arrays is done within rttov_dom_setup_profile.
!!
!!   For the TL/AD/K models all the required member arrays are allocated
!!   here using the optional direct model profiles_dom_direct argument to
!!   size them. This is done to minimise memory usage.
!!
!!   For deallocation calls all memory is freed for all models.
!!
!! @param[out]    err                   status on exit
!! @param         profiles_dom          pointer to RTTOV array of rttov_profile_dom structures
!! @param[in]     nchanprof             total number of channels being simulated (SIZE(chanprof))
!! @param[in]     nstreams              number of cloud streams (columns) as calculated by rttov_cldstr
!! @param[in]     chanflag              flags to indicate which channels should be allocated (either channels with
!!                                      significant thermal or solar contributions)
!! @param[in]     asw                   1_jpim => allocate; 0_jpim => deallocate
!! @param[in]     profiles_dom_direct   pointer to RTTOV array of direct model rttov_profile_dom structures, optional
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
SUBROUTINE rttov_alloc_profiles_dom( &
              err,          &
              profiles_dom, &
              nchanprof,    &
              nstreams,     &
              chanflag,     &
              asw,          &
              profiles_dom_direct)

#include "throw.h"
  USE rttov_types, ONLY : &
      rttov_profile_dom

  USE parkind1, ONLY : jpim, jplm

  IMPLICIT NONE

  INTEGER(KIND=jpim),      INTENT(OUT)          :: err
  TYPE(rttov_profile_dom), POINTER              :: profiles_dom(:,:)
  INTEGER(KIND=jpim),      INTENT(IN)           :: nchanprof
  INTEGER(KIND=jpim),      INTENT(IN)           :: nstreams
  LOGICAL(KIND=jplm),      INTENT(IN)           :: chanflag(nchanprof)
  INTEGER(KIND=jpim),      INTENT(IN)           :: asw             ! 1=allocate, 0=deallocate
  TYPE(rttov_profile_dom), INTENT(IN), OPTIONAL :: profiles_dom_direct(0:,:)
!INTF_END
#include "rttov_errorreport.interface"

  INTEGER(jpim) :: i, ist

  TRY

  IF (asw == 1_jpim) THEN

    ALLOCATE(profiles_dom(0:nstreams,nchanprof), STAT=err)
    THROWM(err.NE.0,"allocation of profiles_dom")
    DO i = 1, nchanprof
      DO ist = 0, nstreams
        NULLIFY(profiles_dom(ist,i)%layerod, profiles_dom(ist,i)%laymap)
      ENDDO
    ENDDO

    ! The direct model member arrays are allocated in the DOM setup subroutine
    ! The TL/AD/K arrays are allocated here

    IF (PRESENT(profiles_dom_direct)) THEN
      DO i = 1, nchanprof
        IF (chanflag(i)) THEN
          DO ist = 0, nstreams
            ! A bug in NAG v5.3 with OpenMP causes failures deallocating zero-sized pointers so avoid allocating any
            IF (profiles_dom_direct(ist,i)%nlayers > 0) THEN
              ALLOCATE(profiles_dom(ist,i)%layerod(profiles_dom_direct(ist,i)%nlayers), STAT = err)
              THROWM(err.NE.0,"allocation of profiles_dom%layerod")
            ENDIF
          ENDDO
        ENDIF
      ENDDO
    ENDIF

  ENDIF

  IF (asw == 0_jpim) THEN

    DO i = 1, nchanprof
      DO ist = 0, nstreams
        IF (ASSOCIATED(profiles_dom(ist,i)%layerod)) THEN
          DEALLOCATE(profiles_dom(ist,i)%layerod, STAT = err)
          THROWM(err.NE.0,"deallocation of profiles_dom%layerod")
        ENDIF
        IF (ASSOCIATED(profiles_dom(ist,i)%laymap)) THEN
          DEALLOCATE(profiles_dom(ist,i)%laymap, STAT = err)
          THROWM(err.NE.0,"deallocation of profiles_dom%laymap")
        ENDIF
        NULLIFY(profiles_dom(ist,i)%layerod, profiles_dom(ist,i)%laymap)
      ENDDO
    ENDDO

    DEALLOCATE(profiles_dom, STAT=err)
    THROWM(err.NE.0,"deallocation of profiles_dom")

  ENDIF

  CATCH
END SUBROUTINE rttov_alloc_profiles_dom