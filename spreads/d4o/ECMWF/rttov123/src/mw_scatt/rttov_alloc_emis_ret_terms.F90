! Description:
!> @file
!!   Allocate/deallocate RTTOV-SCATT emissivity retrieval terms structure.
!
!> @brief
!!   Allocate/deallocate RTTOV-SCATT emissivity retrieval terms structure.
!!
!! @details
!!   The emissivity retrieval terms structure is an optional argument to
!!   the rttov_scatt subroutine which returns upward and downward radiances
!!   and transmittances enabling all-sky dynamic emissivity retrieval
!!   (see Baordo and Geer, 2016, DOI:10.1002/qj.2873).
!!
!!
!! @param[out]    err                     status on exit
!! @param[in]     nchanprof               size of the chanprof array (total number of channels being simulated)
!! @param[in,out] emis_retrieval_terms    emissivity retrieval terms structure to allocate/deallocate
!! @param[in]     asw                     1_jpim => allocate; 0_jpim => deallocate
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
!    Copyright 2018, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_alloc_emis_ret_terms(err, nchanprof, emis_retrieval_terms, asw)
!INTF_OFF
#include "throw.h"
!INTF_ON
  use parkind1, only: jpim
  use rttov_types, only : rttov_scatt_emis_retrieval_type
!INTF_OFF
  use parkind1, only: jprb
  USE YOMHOOK,  ONLY: LHOOK , DR_HOOK
!INTF_ON
  IMPLICIT NONE

  integer(kind=jpim),                    intent(out)   :: err
  integer(kind=jpim),                    intent(in)    :: nchanprof
  type(rttov_scatt_emis_retrieval_type), intent(inout) :: emis_retrieval_terms
  integer(kind=jpim),                    intent(in)    :: asw
!INTF_END

#include "rttov_errorreport.interface"

  real(kind=jprb)    :: ZHOOK_HANDLE
!- End of header --------------------------------------------------------

  TRY
  if (lhook) call dr_hook('RTTOV_ALLOC_EMIS_RET_TERMS',0_jpim,zhook_handle)

  if (asw .eq. 1) then
    allocate(emis_retrieval_terms%cfrac(nchanprof), &
             emis_retrieval_terms%bsfc(nchanprof), &
             emis_retrieval_terms%tau_cld(nchanprof), &
             emis_retrieval_terms%up_cld(nchanprof), &
             emis_retrieval_terms%down_cld(nchanprof), &
             emis_retrieval_terms%tau_clr(nchanprof), &
             emis_retrieval_terms%up_clr(nchanprof), &
             emis_retrieval_terms%down_clr(nchanprof), STAT = err )
    THROWM(err.NE.0, "error allocating emis_retrieval_terms")
  else
    deallocate(emis_retrieval_terms%cfrac, &
               emis_retrieval_terms%bsfc, &
               emis_retrieval_terms%tau_cld, &
               emis_retrieval_terms%up_cld, &
               emis_retrieval_terms%down_cld, &
               emis_retrieval_terms%tau_clr, &
               emis_retrieval_terms%up_clr, &
               emis_retrieval_terms%down_clr, STAT = err )
    THROWM(err.NE.0, "error deallocating emis_retrieval_terms")

    nullify(emis_retrieval_terms%cfrac, &
            emis_retrieval_terms%bsfc, &
            emis_retrieval_terms%tau_cld, &
            emis_retrieval_terms%up_cld, &
            emis_retrieval_terms%down_cld, &
            emis_retrieval_terms%tau_clr, &
            emis_retrieval_terms%up_clr, &
            emis_retrieval_terms%down_clr)
  endif

  if (lhook) call dr_hook('RTTOV_ALLOC_EMIS_RET_TERMS',1_jpim,zhook_handle)
  CATCH
  if (lhook) call dr_hook('RTTOV_ALLOC_EMIS_RET_TERMS',1_jpim,zhook_handle)
end subroutine rttov_alloc_emis_ret_terms

