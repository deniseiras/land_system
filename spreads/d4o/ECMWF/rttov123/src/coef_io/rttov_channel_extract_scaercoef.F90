! Description:
!> @file
!!   Extract data for given channel list from an aerosol coefficients
!!   structure.
!
!> @brief
!!   Extract data for given channel list from an aerosol coefficients
!!   structure.
!!
!! @details
!!   This is used by HDF5 I/O code to read in a subset of channels from a
!!   coefficient file. The first coef arguments contain the coefficients
!!   from the file. The second arguments are uninitialised structures
!!   which contain the extracted coefficients on exit.
!!
!! @param[out]     err              status on exit
!! @param[in]      coef_scatt_ir1   input aerosol rttov_coef_scatt_ir structure read from file
!! @param[in]      optp1            input aerosol rttov_optpar_ir structure read from file
!! @param[in,out]  coef_scatt_ir2   output rttov_coef_scatt_ir structure, uninitialised on entry
!! @param[in,out]  optp2            output rttov_optpar_ir structure, uninitialised on entry
!! @param[in]      channels         list of channels to extract
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
SUBROUTINE rttov_channel_extract_scaercoef(err, coef_scatt_ir1, optp1, coef_scatt_ir2, optp2, channels)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE parkind1, ONLY : jpim
  USE rttov_types, ONLY : rttov_coef_scatt_ir, rttov_optpar_ir

  IMPLICIT NONE

  INTEGER(jpim),             INTENT(OUT)   :: err
  TYPE(rttov_coef_scatt_ir), INTENT(IN)    :: coef_scatt_ir1
  TYPE(rttov_optpar_ir),     INTENT(IN)    :: optp1
  TYPE(rttov_coef_scatt_ir), INTENT(INOUT) :: coef_scatt_ir2
  TYPE(rttov_optpar_ir),     INTENT(INOUT) :: optp2
  INTEGER(jpim),             INTENT(IN)    :: channels(:)
!INTF_END

#include "rttov_nullify_coef_scatt_ir.interface"
#include "rttov_alloc_phfn_int.interface"
#include "rttov_channel_extract_sublist.interface"

  INTEGER(jpim)              :: n
  INTEGER(jpim), ALLOCATABLE :: phase_channels(:)
  INTEGER(jpim), ALLOCATABLE :: phase_ext_index(:)
! ----------------------------------------------------------------------------

TRY

  ! Scalar variables

  ! A few of these are the same...
  coef_scatt_ir2%fmv_aer_comp       = coef_scatt_ir1%fmv_aer_comp

  ! ... but we have to work out the solar channel numbers
  coef_scatt_ir2%fmv_aer_chn      = SIZE(channels)

  IF (coef_scatt_ir1%fmv_aer_pha_chn > 0) THEN
    ALLOCATE(phase_channels(coef_scatt_ir1%fmv_aer_pha_chn))

    ! Determine the solar channel numbers
    phase_channels(:) = coef_scatt_ir1%aer_pha_chanlist(:)

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE(phase_ext_index(coef_scatt_ir1%fmv_aer_pha_chn))
    CALL rttov_channel_extract_sublist( &
          err,                             &
          phase_channels,                  &
          channels,                        &
          coef_scatt_ir2%fmv_aer_pha_chn,  &
          coef_scatt_ir2%aer_pha_chanlist, &
          coef_scatt_ir2%aer_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)

    IF (coef_scatt_ir2%fmv_aer_pha_chn > 0) THEN
      coef_scatt_ir2%aer_nphangle = coef_scatt_ir1%aer_nphangle
      ALLOCATE(coef_scatt_ir2%aer_phangle(coef_scatt_ir2%aer_nphangle))
      coef_scatt_ir2%aer_phangle = coef_scatt_ir1%aer_phangle

      CALL rttov_alloc_phfn_int(err, coef_scatt_ir2%aer_phangle, coef_scatt_ir2%aer_phfn_int, 1_jpim)
      THROWM(err.NE.0, "initialisation of coef_scatt_ir2%aer_phfn_int")
    ENDIF

    ! See rttov_read_ascii_scaercoef.F90 for a description of what the various arrays contain.

    IF (ALLOCATED(phase_channels)) DEALLOCATE(phase_channels)
  ELSE
    ! What do we need to do if there are no phase fns at all?
    coef_scatt_ir2%fmv_aer_pha_chn = 0
    coef_scatt_ir2%aer_nphangle = 0
  ENDIF

  ALLOCATE(coef_scatt_ir2%fmv_aer_comp_name(coef_scatt_ir2%fmv_aer_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%fmv_aer_comp_name')
  coef_scatt_ir2%fmv_aer_comp_name = coef_scatt_ir1%fmv_aer_comp_name

  ALLOCATE(coef_scatt_ir2%fmv_aer_rh(coef_scatt_ir2%fmv_aer_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%fmv_aer_rh')
  coef_scatt_ir2%fmv_aer_rh = coef_scatt_ir1%fmv_aer_rh

  ALLOCATE (coef_scatt_ir2%aer_mmr2nd(coef_scatt_ir2%fmv_aer_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%aer_mmr2nd')
  coef_scatt_ir2%aer_mmr2nd = coef_scatt_ir1%aer_mmr2nd

  ALLOCATE(optp2%optpaer(coef_scatt_ir2%fmv_aer_comp), stat=err)
  THROWM(err.NE.0, 'allocation of optpaer')

  coef_scatt_ir2%fmv_aer_maxnmom = 0
  DO n = 1, coef_scatt_ir2%fmv_aer_comp

    CALL rttov_nullify_coef_scatt_ir(optp2%optpaer(n))
    ALLOCATE(optp2%optpaer(n)%fmv_aer_rh_val(coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%fmv_aer_rh_val')
    optp2%optpaer(n)%fmv_aer_rh_val = optp1%optpaer(n)%fmv_aer_rh_val

    ALLOCATE(optp2%optpaer(n)%abs(coef_scatt_ir2%fmv_aer_chn,coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%abs')
    optp2%optpaer(n)%abs(:,:) = optp1%optpaer(n)%abs(channels,:)

    ALLOCATE(optp2%optpaer(n)%sca(coef_scatt_ir2%fmv_aer_chn,coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%sca')
    optp2%optpaer(n)%sca(:,:) = optp1%optpaer(n)%sca(channels,:)

    ALLOCATE(optp2%optpaer(n)%bpr(coef_scatt_ir2%fmv_aer_chn,coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%bpr')
    optp2%optpaer(n)%bpr(:,:) = optp1%optpaer(n)%bpr(channels,:)

    ALLOCATE(optp2%optpaer(n)%nmom(coef_scatt_ir2%fmv_aer_chn,coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%nmom')
    optp2%optpaer(n)%nmom(:,:) = optp1%optpaer(n)%nmom(channels,:)

    coef_scatt_ir2%fmv_aer_maxnmom = MAX(coef_scatt_ir2%fmv_aer_maxnmom, MAXVAL(optp2%optpaer(n)%nmom(:,:)))

    ALLOCATE(optp2%optpaer(n)%legcoef(1:coef_scatt_ir2%fmv_aer_maxnmom+1, &
                                      coef_scatt_ir2%fmv_aer_chn, &
                                      coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpaer(n)%legcoef')
    optp2%optpaer(n)%legcoef(:,:,:) = optp1%optpaer(n)%legcoef(1:coef_scatt_ir2%fmv_aer_maxnmom+1,channels,:)

    IF (coef_scatt_ir2%fmv_aer_pha_chn > 0) THEN

      ALLOCATE(optp2%optpaer(n)%pha(coef_scatt_ir2%aer_nphangle, &
                                    coef_scatt_ir2%fmv_aer_pha_chn, &
                                    coef_scatt_ir2%fmv_aer_rh(n)), stat=err)
      THROWM(err.NE.0, 'allocation of optpaer(n)%pha')
      optp2%optpaer(n)%pha(:,:,:) = optp1%optpaer(n)%pha(:,phase_ext_index(1:coef_scatt_ir2%fmv_aer_pha_chn),:)

    ENDIF

  ENDDO

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE (phase_ext_index)

CATCH
END SUBROUTINE rttov_channel_extract_scaercoef