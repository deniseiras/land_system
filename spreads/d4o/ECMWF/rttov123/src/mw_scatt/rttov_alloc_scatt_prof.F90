! Description:
!> @file
!!   Allocate/deallocate RTTOV-SCATT cloud profiles structure.
!
!> @brief
!!   Allocate/deallocate RTTOV-SCATT cloud profiles structure.
!!
!! @details
!!   The cloud profiles structure contains the cloud liquid and
!!   ice water and hydrometeor profiles for the RTTOV-SCATT direct
!!   model, the input cloud profile perturbations for the TL model,
!!   and the output gradients and Jacobians for the AD and K models.
!!   This subroutine allocates all array members of this structure
!!   for each cloud profile.
!!
!!   The profiles argument should be declared as an array of size
!!   nprof. For the K model cld_profiles_k should have size nchanprof
!!   (i.e. the total number of channels being simulated).
!!
!!
!! @param[out]    err            status on exit
!! @param[in]     nprof          number of profiles being simulated
!! @param[in,out] cld_profiles   input cloud profiles
!! @param[in]     nlev           number of levels in cloud profiles (must match the RTTOV profiles structure)
!! @param[in]     use_totalice   if true use the totalice member for total ice content, otherwise use separate
!!                                 cloud ice water and solid precip members
!! @param[in]     asw            1_jpim => allocate; 0_jpim => deallocate
!! @param[in]     init           set .TRUE. to initialise newly allocated structures, optional
!! @param[in]     mmr_snowrain   set snow and rain input units: True (default) => kg/kg, False => kg/m2/s, optional
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
SUBROUTINE rttov_alloc_scatt_prof ( err, nprof, cld_profiles, nlev, use_totalice, asw, init, mmr_snowrain)
!INTF_OFF
#include "throw.h"
!INTF_ON
  use parkind1, only: jpim, jplm
  use rttov_types, only : rttov_profile_cloud
!INTF_OFF
  use parkind1, only: jprb
  USE YOMHOOK,  ONLY: LHOOK , DR_HOOK
!INTF_ON
  IMPLICIT NONE

  integer(kind=jpim), intent(out) :: err
  integer(kind=jpim), intent(in) :: nlev         ! number of levels
  integer(kind=jpim), intent(in) :: nprof        ! number of profiles
  integer(kind=jpim), intent(in) :: asw          ! 1=allocate,      0=deallocate
  logical(kind=jplm), optional,  intent(in) :: init         ! true=zero contents, false=don't bother
  logical(kind=jplm), intent(in) :: use_totalice ! Choose separate ciw and snow, or totalice
  logical(kind=jplm), optional, intent(in) :: mmr_snowrain ! snow and rain input units are: False => kg/m2/s  True => kg/kg
  type(rttov_profile_cloud), intent(inout) :: cld_profiles (nprof)
!INTF_END

#include "rttov_init_scatt_prof.interface"
#include "rttov_errorreport.interface"

  integer(kind=jpim) :: iprof
  logical(kind=jplm) :: init1, lmmr
  real(kind=jprb)    :: ZHOOK_HANDLE

!- End of header --------------------------------------------------------

  TRY
  if (lhook) call dr_hook('RTTOV_ALLOC_SCATT_PROF',0_jpim,zhook_handle)

  init1 = .false.
  if(present(init)) init1 = init

  lmmr = .true.
  if(present(mmr_snowrain)) lmmr = mmr_snowrain

  if (asw .eq. 1) then
    do iprof = 1, nprof

      cld_profiles (iprof) % nlevels      = nlev
      cld_profiles (iprof) % use_totalice = use_totalice
      cld_profiles (iprof) % mmr_snowrain = lmmr
      cld_profiles (iprof) % cfrac        = 0.0_JPRB

      nullify( cld_profiles (iprof) % ph )
      nullify( cld_profiles (iprof) % cc )
      nullify( cld_profiles (iprof) % clw )
      nullify( cld_profiles (iprof) % rain )
      nullify( cld_profiles (iprof) % totalice )
      nullify( cld_profiles (iprof) % sp )
      nullify( cld_profiles (iprof) % ciw )

      allocate( cld_profiles (iprof) % ph (nlev+1), STAT = err )
      THROWM(err.NE.0, "error allocating cld_profiles")
      allocate( cld_profiles (iprof) % cc (nlev), STAT = err )
      THROWM(err.NE.0, "error allocating cld_profiles")
      allocate( cld_profiles (iprof) % clw (nlev), STAT = err )
      THROWM(err.NE.0, "error allocating cld_profiles")
      allocate( cld_profiles (iprof) % rain (nlev), STAT = err )
      THROWM(err.NE.0, "error allocating cld_profiles")
      if (use_totalice) then
        allocate( cld_profiles (iprof) % totalice (nlev), STAT = err )
        THROWM(err.NE.0, "error allocating cld_profiles")
      else
        allocate( cld_profiles (iprof) % sp (nlev), STAT = err )
        THROWM(err.NE.0, "error allocating cld_profiles")
        allocate( cld_profiles (iprof) % ciw (nlev), STAT = err )
        THROWM(err.NE.0, "error allocating cld_profiles")
      endif
    enddo
    if (init1) call rttov_init_scatt_prof(cld_profiles)
  else
    do iprof = 1, nprof

      deallocate( cld_profiles (iprof) % ph, STAT = err )
      THROWM(err.NE.0, "error deallocating cld_profiles")
      deallocate( cld_profiles (iprof) % cc, STAT = err )
      THROWM(err.NE.0, "error deallocating cld_profiles")
      deallocate( cld_profiles (iprof) % clw, STAT = err )
      THROWM(err.NE.0, "error deallocating cld_profiles")
      deallocate( cld_profiles (iprof) % rain, STAT = err )
      THROWM(err.NE.0, "error deallocating cld_profiles")
      if (cld_profiles (iprof) % use_totalice) then
        deallocate( cld_profiles (iprof) % totalice, STAT = err )
        THROWM(err.NE.0, "error deallocating cld_profiles")
      else
        deallocate( cld_profiles (iprof) % ciw, STAT = err )
        THROWM(err.NE.0, "error deallocating cld_profiles")
        deallocate( cld_profiles (iprof) % sp, STAT = err )
        THROWM(err.NE.0, "error deallocating cld_profiles")
      endif

      nullify( cld_profiles (iprof) % ph )
      nullify( cld_profiles (iprof) % cc )
      nullify( cld_profiles (iprof) % clw )
      nullify( cld_profiles (iprof) % rain )
      nullify( cld_profiles (iprof) % totalice )
      nullify( cld_profiles (iprof) % sp )
      nullify( cld_profiles (iprof) % ciw )

    enddo
  endif

  if (lhook) call dr_hook('RTTOV_ALLOC_SCATT_PROF',1_jpim,zhook_handle)
  CATCH
  if (lhook) call dr_hook('RTTOV_ALLOC_SCATT_PROF',1_jpim,zhook_handle)
end subroutine

