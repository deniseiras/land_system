! Description:
!> @file
!!   Allocate/deallocate any/all arrays and structures for RTTOV direct model.
!
!> @brief
!!   Allocate/deallocate any/all arrays and structures for RTTOV direct model.
!!
!! @details
!!   Argument order follows that of rttov_direct where possible.
!!   This allows all necessary input/output arguments to rttov_direct to be
!!   allocated or deallocated in a single subroutine call: pass only those
!!   arguments you wish to allocate/deallocate.
!!
!!   NB Array arguments must be pointers.
!!
!! @param[out]    err            status on exit
!! @param[in]     asw            1_jpim => allocate; 0_jpim => deallocate
!! @param[in]     nprofiles      number of profiles being simulated
!! @param[in]     nchanprof      total number of channels being simulated over all profiles
!! @param[in]     nlevels        number of levels in input profiles
!! @param         chanprof       specifies channels and profiles to simulate, optional
!! @param[in]     opts           options to configure the simulations
!! @param         profiles       input atmospheric profiles and surface variables, optional
!! @param[in]     coefs          coefficients structure for instrument to simulate
!! @param[in,out] transmission   output transmittances, optional
!! @param[in,out] radiance       output radiances and corresponding BTs and BRFs, optional
!! @param[in,out] radiance2      secondary output radiances, optional
!! @param         calcemis       flags for internal RTTOV surface emissivity calculation, optional
!! @param         emissivity     input/output surface emissivities, optional
!! @param         calcrefl       flags for internal RTTOV surface BRDF calculation, optional
!! @param         reflectance    input/output surface BRDFs, input cloud top BRDF for simple cloud, optional
!! @param[in]     aer_maxnmom    max number of Legendre coefficients specified for aerosol phase functions, optional
!! @param[in]     aer_nphangle   size of angular grid for aerosol phase functions, optional
!! @param[in,out] aer_opt_param  input aerosol optical parameters, optional
!! @param[in]     cld_maxnmom    max number of Legendre coefficients specified for cloud phase functions, optional
!! @param[in]     cld_nphangle   size of angular grid for cloud phase functions, optional
!! @param[in,out] cld_opt_param  input cloud optical parameters, optional
!! @param[in,out] traj           RTTOV internal state, can be initialised outside RTTOV, optional
!! @param[in]     npcscores      number of PC scores to calculate for PC-RTTOV, optional
!! @param[in]     nchannels_rec  number of channels for which to calculate reconstructed radiances, optional
!! @param[in,out] pccomp         output PC scores and radiances from PC-RTTOV, optional
!! @param         channels_rec   array for channels for which to calculate reconstructed radiances, optional
!! @param[in]     init           set .TRUE. to initialise newly allocated structures, optional
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
SUBROUTINE rttov_alloc_direct( &
              err,             &
              asw,             &
              nprofiles,       &
              nchanprof,       &
              nlevels,         &
              chanprof,        &
              opts,            &
              profiles,        &
              coefs,           &
              transmission,    &
              radiance,        &
              radiance2,       &
              calcemis,        &
              emissivity,      &
              calcrefl,        &
              reflectance,     &
              aer_maxnmom,     &
              aer_nphangle,    &
              aer_opt_param,   &
              cld_maxnmom,     &
              cld_nphangle,    &
              cld_opt_param,   &
              traj,            &
              npcscores,       &
              nchannels_rec,   &
              pccomp,          &
              channels_rec,    &
              init)

!INTF_OFF
#include "throw.h"
!INTF_ON

  USE parkind1, ONLY : jpim, jplm

  USE rttov_types, ONLY : &
      rttov_options,      &
      rttov_coefs,        &
      rttov_chanprof,     &
      rttov_emissivity,   &
      rttov_reflectance,  &
      rttov_profile,      &
      rttov_transmission, &
      rttov_radiance,     &
      rttov_radiance2,    &
      rttov_traj,         &
      rttov_pccomp,       &
      rttov_opt_param

  IMPLICIT NONE

  ! Input arguments
  INTEGER(jpim),            INTENT(OUT)             :: err             ! return code
  INTEGER(jpim),            INTENT(IN)              :: asw             ! 1=allocate, 0=deallocate
  INTEGER(jpim),            INTENT(IN)              :: nprofiles       ! number of profiles
  INTEGER(jpim),            INTENT(IN)              :: nchanprof       ! size of chanprof array
  INTEGER(jpim),            INTENT(IN)              :: nlevels         ! number of levels
  TYPE(rttov_options),      INTENT(IN)              :: opts            ! RTTOV options
  TYPE(rttov_coefs),        INTENT(IN),    TARGET   :: coefs           ! coefficients

  ! Output arguments
  TYPE(rttov_profile),      POINTER,       OPTIONAL :: profiles(:)     ! input profiles
  TYPE(rttov_transmission), INTENT(INOUT), OPTIONAL :: transmission    ! output transmission
  TYPE(rttov_radiance),     INTENT(INOUT), OPTIONAL :: radiance        ! output radiances
  TYPE(rttov_radiance2),    INTENT(INOUT), OPTIONAL :: radiance2       ! secondary output radiances

  TYPE(rttov_chanprof),     POINTER,       OPTIONAL :: chanprof(:)     ! channel and profile indices
  LOGICAL(jplm),            POINTER,       OPTIONAL :: calcemis(:)     ! switch for emissivity calculations
  TYPE(rttov_emissivity),   POINTER,       OPTIONAL :: emissivity(:)   ! input/output emissivity values
  LOGICAL(jplm),            POINTER,       OPTIONAL :: calcrefl(:)     ! switch for surface BRDF calculations
  TYPE(rttov_reflectance),  POINTER,       OPTIONAL :: reflectance(:)  ! input/output surface BRDF values

  TYPE(rttov_traj),         INTENT(INOUT), OPTIONAL :: traj            ! RTTOV internal data

  ! Aerosol/cloud optical parameter arguments
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: aer_maxnmom     ! max number of aerosol phase fn Legendre coefs
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: aer_nphangle    ! size of angular grid for aerosol phase fns
  TYPE(rttov_opt_param),    INTENT(INOUT), OPTIONAL :: aer_opt_param   ! input aerosol optical parameters
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: cld_maxnmom     ! max number of cloud phase fn Legendre coefs
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: cld_nphangle    ! size of angular grid for cloud phase fns
  TYPE(rttov_opt_param),    INTENT(INOUT), OPTIONAL :: cld_opt_param   ! input cloud optical parameters

  ! PC-RTTOV output arguments
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: npcscores       ! number of PC scores
  INTEGER(jpim),            INTENT(IN),    OPTIONAL :: nchannels_rec   ! number of reconstructed radiances
  TYPE(rttov_pccomp),       INTENT(INOUT), OPTIONAL :: pccomp          ! output PC scores
  INTEGER(jpim),            POINTER,       OPTIONAL :: channels_rec(:) ! reconstructed channel list

  ! Initialisation flag
  LOGICAL(jplm),            INTENT(IN),    OPTIONAL :: init            ! flag to select initialisation of structures
!INTF_END

#include "rttov_errorreport.interface"
#include "rttov_alloc_prof.interface"
#include "rttov_alloc_transmission.interface"
#include "rttov_alloc_rad.interface"
#include "rttov_alloc_traj.interface"
#include "rttov_alloc_pccomp.interface"
#include "rttov_alloc_opt_param.interface"

  INTEGER(KIND=jpim) :: alloc_status(7)
!- End of header --------------------------------------------------------

  TRY

  ! Check arguments before allocating anything
  IF (PRESENT(pccomp) .AND. .NOT. PRESENT(npcscores)) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0, 'npscores required when (de)allocating pccomp')
  ENDIF
  IF (PRESENT(channels_rec) .AND. .NOT. PRESENT(nchannels_rec) .AND. asw == 1) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0, 'nchannels_rec required when (de)allocating channels_rec')
  ENDIF
  IF (PRESENT(aer_opt_param)) THEN
    IF (.NOT. PRESENT(aer_maxnmom)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'aer_maxnmom required when (de)allocating aer_opt_param')
    ENDIF
    IF (.NOT. PRESENT(aer_nphangle)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'aer_nphangle required when (de)allocating aer_opt_param')
    ENDIF
  ENDIF
  IF (PRESENT(cld_opt_param)) THEN
    IF (.NOT. PRESENT(cld_maxnmom)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'cld_maxnmom required when (de)allocating cld_opt_param')
    ENDIF
    IF (.NOT. PRESENT(cld_nphangle)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'cld_nphangle required when (de)allocating cld_opt_param')
    ENDIF
  ENDIF

  IF (asw == 1) THEN
    alloc_status = 0
    IF (PRESENT(profiles))     ALLOCATE(profiles(nprofiles),         stat=alloc_status(1))
    IF (PRESENT(chanprof))     ALLOCATE(chanprof(nchanprof),         stat=alloc_status(2))
    IF (PRESENT(calcemis))     ALLOCATE(calcemis(nchanprof),         stat=alloc_status(3))
    IF (PRESENT(emissivity))   ALLOCATE(emissivity(nchanprof),       stat=alloc_status(4))
    IF (PRESENT(calcrefl))     ALLOCATE(calcrefl(nchanprof),         stat=alloc_status(5))
    IF (PRESENT(reflectance))  ALLOCATE(reflectance(nchanprof),      stat=alloc_status(6))
    IF (PRESENT(channels_rec)) ALLOCATE(channels_rec(nchannels_rec), stat=alloc_status(7))
    IF (ANY(alloc_status /= 0)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'Error allocating array arguments')
    ENDIF
  ENDIF

  IF (PRESENT(profiles)) THEN
    CALL rttov_alloc_prof( &
            err,       &
            nprofiles, &
            profiles,  &
            nlevels,   &
            opts,      &
            asw,       &
            coefs,     &
            init)
    THROWM(err.NE.0, 'Error (de)allocating profile structure')
  ENDIF

  IF (PRESENT(transmission)) THEN
    CALL rttov_alloc_transmission( &
            err,          &
            transmission, &
            nlevels,      &
            nchanprof,    &
            asw,          &
            init)
    THROWM(err.NE.0, 'Error (de)allocating transmission structure')
  ENDIF

  IF (PRESENT(radiance)) THEN
    CALL rttov_alloc_rad( &
            err,       &
            nchanprof, &
            radiance,  &
            nlevels,   &
            asw,       &
            radiance2, &
            init)
    THROWM(err.NE.0, 'Error (de)allocating radiance structure(s)')
  ENDIF

  IF (PRESENT(traj)) THEN
    CALL rttov_alloc_traj( &
            err,       &
            nprofiles, &
            nchanprof, &
            opts,      &
            nlevels,   &
            coefs,     &
            asw,       &
            traj=traj)
    THROWM(err.NE.0, 'Error (de)allocating traj structure')
  ENDIF

  IF (PRESENT(pccomp)) THEN
    CALL rttov_alloc_pccomp( &
            err,           &
            pccomp,        &
            npcscores,     &
            asw,           &
            init,          &
            nchannels_rec, &
            opts,          &
            nlevels)
    THROWM(err.NE.0, 'Error (de)allocating pccomp structure')
  ENDIF

  IF (PRESENT(aer_opt_param)) THEN
    CALL rttov_alloc_opt_param( &
            err,           &
            aer_opt_param, &
            nchanprof,     &
            nlevels,       &
            aer_maxnmom,   &
            aer_nphangle,  &
            asw,           &
            init)
    THROWM(err.NE.0, 'Error (de)allocating aer_opt_param structure')
  ENDIF

  IF (PRESENT(cld_opt_param)) THEN
    CALL rttov_alloc_opt_param( &
            err,           &
            cld_opt_param, &
            nchanprof,     &
            nlevels,       &
            cld_maxnmom,   &
            cld_nphangle,  &
            asw,           &
            init)
    THROWM(err.NE.0, 'Error (de)allocating cld_opt_param structure')
  ENDIF

  IF (asw == 0) THEN
    alloc_status = 0
    IF (PRESENT(profiles)) THEN
      IF (ASSOCIATED(profiles)) THEN
        DEALLOCATE(profiles, stat=alloc_status(1))
        NULLIFY(profiles)
      ENDIF
    ENDIF
    IF (PRESENT(chanprof)) THEN
      IF (ASSOCIATED(chanprof)) THEN
        DEALLOCATE(chanprof, stat=alloc_status(2))
        NULLIFY(chanprof)
      ENDIF
    ENDIF
    IF (PRESENT(calcemis)) THEN
      IF (ASSOCIATED(calcemis)) THEN
        DEALLOCATE(calcemis, stat=alloc_status(3))
        NULLIFY(calcemis)
      ENDIF
    ENDIF
    IF (PRESENT(emissivity)) THEN
      IF (ASSOCIATED(emissivity)) THEN
        DEALLOCATE(emissivity, stat=alloc_status(4))
        NULLIFY(emissivity)
      ENDIF
    ENDIF
    IF (PRESENT(calcrefl)) THEN
      IF (ASSOCIATED(calcrefl)) THEN
        DEALLOCATE(calcrefl, stat=alloc_status(5))
        NULLIFY(calcrefl)
      ENDIF
    ENDIF
    IF (PRESENT(reflectance)) THEN
      IF (ASSOCIATED(reflectance)) THEN
        DEALLOCATE(reflectance, stat=alloc_status(6))
        NULLIFY(reflectance)
      ENDIF
    ENDIF
    IF (PRESENT(channels_rec)) THEN
      IF (ASSOCIATED(channels_rec)) THEN
        DEALLOCATE(channels_rec, stat=alloc_status(7))
        NULLIFY(channels_rec)
      ENDIF
    ENDIF
    IF (ANY(alloc_status /= 0)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0, 'Error deallocating array arguments')
    ENDIF
  ENDIF

  CATCH
END SUBROUTINE rttov_alloc_direct
