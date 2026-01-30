! Description:
!> @file
!!   Extract data for given channel list from a cloud coefficients
!!   structure.
!
!> @brief
!!   Extract data for given channel list from a cloud coefficients
!!   structure.
!!
!! @details
!!   This is used by HDF5 I/O code to read in a subset of channels from a
!!   coefficient file. The first coef arguments contain the coefficients
!!   from the file. The second arguments are uninitialised structures
!!   which contain the extracted coefficients on exit.
!!
!! @param[out]     err              status on exit
!! @param[in]      coef_scatt_ir1   input cloud rttov_coef_scatt_ir structure read from file
!! @param[in]      optp1            input cloud rttov_optpar_ir structure read from file
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
SUBROUTINE rttov_channel_extract_sccldcoef(err, coef_scatt_ir1, optp1, coef_scatt_ir2, optp2, channels)
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

  ! --------------------------------------------------------------------------
  ! Water cloud
  ! --------------------------------------------------------------------------

  ! Scalar variables

  ! A few of these are the same...
  coef_scatt_ir2%fmv_wcl_comp       = coef_scatt_ir1%fmv_wcl_comp

  ! ... but we have to work out the solar channel numbers
  coef_scatt_ir2%fmv_wcl_chn      = SIZE(channels)

  IF (coef_scatt_ir1%fmv_wcl_pha_chn > 0) THEN
    ALLOCATE(phase_channels(coef_scatt_ir1%fmv_wcl_pha_chn))

    ! Determine the solar channel numbers
    phase_channels(:) = coef_scatt_ir1%wcl_pha_chanlist(:)

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE(phase_ext_index(coef_scatt_ir1%fmv_wcl_pha_chn))
    CALL rttov_channel_extract_sublist( &
          err,                             &
          phase_channels,                  &
          channels,                        &
          coef_scatt_ir2%fmv_wcl_pha_chn,  &
          coef_scatt_ir2%wcl_pha_chanlist, &
          coef_scatt_ir2%wcl_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)

    IF (coef_scatt_ir2%fmv_wcl_pha_chn > 0) THEN
      coef_scatt_ir2%wcl_nphangle = coef_scatt_ir1%wcl_nphangle
      ALLOCATE(coef_scatt_ir2%wcl_phangle(coef_scatt_ir2%wcl_nphangle))
      coef_scatt_ir2%wcl_phangle = coef_scatt_ir1%wcl_phangle

      CALL rttov_alloc_phfn_int(err, coef_scatt_ir2%wcl_phangle, coef_scatt_ir2%wcl_phfn_int, 1_jpim)
      THROWM(err.NE.0, "initialisation of coef_scatt_ir2%wcl_phfn_int")
    ENDIF

    ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

    IF (ALLOCATED(phase_channels)) DEALLOCATE(phase_channels)
  ELSE
    ! What do we need to do if there are no phase fns at all?
    coef_scatt_ir2%fmv_wcl_pha_chn = 0
  ENDIF

  ALLOCATE(coef_scatt_ir2%fmv_wcl_comp_name(coef_scatt_ir2%fmv_wcl_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%fmv_wcl_comp_name')
  coef_scatt_ir2%fmv_wcl_comp_name = coef_scatt_ir1%fmv_wcl_comp_name

  ALLOCATE(coef_scatt_ir2%fmv_wcl_rh(coef_scatt_ir2%fmv_wcl_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%fmv_wcl_rh')
  coef_scatt_ir2%fmv_wcl_rh = coef_scatt_ir1%fmv_wcl_rh

  ALLOCATE (coef_scatt_ir2%confac(coef_scatt_ir2%fmv_wcl_comp), stat=err)
  THROWM(err.NE.0, 'allocation of coef_scatt_ir2%confac')
  coef_scatt_ir2%confac = coef_scatt_ir1%confac

  ALLOCATE(optp2%optpwcl(coef_scatt_ir2%fmv_wcl_comp), stat=err)
  THROWM(err.NE.0, 'allocation of optpwcl')

  coef_scatt_ir2%fmv_wcl_maxnmom = 0
  DO n = 1, coef_scatt_ir2%fmv_wcl_comp

    CALL rttov_nullify_coef_scatt_ir(optp2%optpwcl(n))
    ALLOCATE(optp2%optpwcl(n)%fmv_wcl_rh_val(coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%fmv_wcl_rh_val')
    optp2%optpwcl(n)%fmv_wcl_rh_val = optp1%optpwcl(n)%fmv_wcl_rh_val

    ALLOCATE(optp2%optpwcl(n)%abs(coef_scatt_ir2%fmv_wcl_chn,coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%abs')
    optp2%optpwcl(n)%abs(:,:) = optp1%optpwcl(n)%abs(channels,:)

    ALLOCATE(optp2%optpwcl(n)%sca(coef_scatt_ir2%fmv_wcl_chn,coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%sca')
    optp2%optpwcl(n)%sca(:,:) = optp1%optpwcl(n)%sca(channels,:)

    ALLOCATE(optp2%optpwcl(n)%bpr(coef_scatt_ir2%fmv_wcl_chn,coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%bpr')
    optp2%optpwcl(n)%bpr(:,:) = optp1%optpwcl(n)%bpr(channels,:)

    ALLOCATE(optp2%optpwcl(n)%nmom(coef_scatt_ir2%fmv_wcl_chn,coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%nmom')
    optp2%optpwcl(n)%nmom(:,:) = optp1%optpwcl(n)%nmom(channels,:)

    coef_scatt_ir2%fmv_wcl_maxnmom = MAX(coef_scatt_ir2%fmv_wcl_maxnmom, MAXVAL(optp2%optpwcl(n)%nmom(:,:)))

    ALLOCATE(optp2%optpwcl(n)%legcoef(1:coef_scatt_ir2%fmv_wcl_maxnmom+1, &
                                      coef_scatt_ir2%fmv_wcl_chn, &
                                      coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcl(n)%legcoef')
    optp2%optpwcl(n)%legcoef(:,:,:) = optp1%optpwcl(n)%legcoef(1:coef_scatt_ir2%fmv_wcl_maxnmom+1,channels,:)

    IF (coef_scatt_ir2%fmv_wcl_pha_chn > 0) THEN

      ALLOCATE(optp2%optpwcl(n)%pha(coef_scatt_ir2%wcl_nphangle, &
                                    coef_scatt_ir2%fmv_wcl_pha_chn, &
                                    coef_scatt_ir2%fmv_wcl_rh(n)), stat=err)
      THROWM(err.NE.0, 'allocation of optpwcl(n)%pha')
      optp2%optpwcl(n)%pha(:,:,:) = optp1%optpwcl(n)%pha(:,phase_ext_index(1:coef_scatt_ir2%fmv_wcl_pha_chn),:)

    ENDIF

  ENDDO

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE (phase_ext_index)


  ! --------------------------------------------------------------------------
  ! Water cloud - Deff scheme
  ! --------------------------------------------------------------------------

  IF (coef_scatt_ir1%fmv_wcldeff_chn > 0) THEN

    ! Scalar variables

    ! A few of these are the same...
    coef_scatt_ir2%fmv_wcldeff_ndeff = coef_scatt_ir1%fmv_wcldeff_ndeff


    ! ... but we have to work out the solar channel numbers
    coef_scatt_ir2%fmv_wcldeff_chn = SIZE(channels)

    IF (coef_scatt_ir1%fmv_wcldeff_pha_chn > 0) THEN
      ALLOCATE(phase_channels(coef_scatt_ir1%fmv_wcldeff_pha_chn))

      ! Determine the solar channel numbers
      phase_channels(:) = coef_scatt_ir1%wcldeff_pha_chanlist(:)

      ! Determine solar channels/phase functions to be extracted
      ALLOCATE(phase_ext_index(coef_scatt_ir1%fmv_wcldeff_pha_chn))
      CALL rttov_channel_extract_sublist( &
            err,                                 &
            phase_channels,                      &
            channels,                            &
            coef_scatt_ir2%fmv_wcldeff_pha_chn,  &
            coef_scatt_ir2%wcldeff_pha_chanlist, &
            coef_scatt_ir2%wcldeff_pha_index,    &
            phase_ext_index)
      THROW(err.NE.0)

      IF (coef_scatt_ir2%fmv_wcldeff_pha_chn > 0) THEN
        coef_scatt_ir2%wcldeff_nphangle = coef_scatt_ir1%wcldeff_nphangle
        ALLOCATE(coef_scatt_ir2%wcldeff_phangle(coef_scatt_ir2%wcldeff_nphangle))
        coef_scatt_ir2%wcldeff_phangle = coef_scatt_ir1%wcldeff_phangle

        CALL rttov_alloc_phfn_int(err, coef_scatt_ir2%wcldeff_phangle, coef_scatt_ir2%wcldeff_phfn_int, 1_jpim)
        THROWM(err.NE.0, "initialisation of coef_scatt_ir2%wcldeff_phfn_int")
      ENDIF

      ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

      IF (ALLOCATED(phase_channels)) DEALLOCATE(phase_channels)
    ELSE
      ! What do we need to do if there are no phase fns at all?
      coef_scatt_ir2%fmv_wcldeff_pha_chn = 0
    ENDIF

    ALLOCATE(optp2%optpwcldeff, stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff')

    CALL rttov_nullify_coef_scatt_ir(optp2%optpwcldeff)

    ALLOCATE(optp2%optpwcldeff%fmv_wcldeff_deff(coef_scatt_ir2%fmv_wcldeff_ndeff), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%fmv_wcldeff_deff')
    optp2%optpwcldeff%fmv_wcldeff_deff(:) = optp1%optpwcldeff%fmv_wcldeff_deff(:)

    ALLOCATE(optp2%optpwcldeff%abs(coef_scatt_ir2%fmv_wcldeff_ndeff, coef_scatt_ir2%fmv_wcldeff_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%abs')
    optp2%optpwcldeff%abs(:,:) = optp1%optpwcldeff%abs(:,channels)

    ALLOCATE(optp2%optpwcldeff%sca(coef_scatt_ir2%fmv_wcldeff_ndeff, coef_scatt_ir2%fmv_wcldeff_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%sca')
    optp2%optpwcldeff%sca(:,:) = optp1%optpwcldeff%sca(:,channels)

    ALLOCATE(optp2%optpwcldeff%bpr(coef_scatt_ir2%fmv_wcldeff_ndeff, coef_scatt_ir2%fmv_wcldeff_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%bpr')
    optp2%optpwcldeff%bpr(:,:) = optp1%optpwcldeff%bpr(:,channels)

    ALLOCATE(optp2%optpwcldeff%nmom(1,coef_scatt_ir2%fmv_wcldeff_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%nmom')
    optp2%optpwcldeff%nmom(:,:) = optp1%optpwcldeff%nmom(:,channels)

    coef_scatt_ir2%fmv_wcldeff_maxnmom = MAXVAL(optp2%optpwcldeff%nmom(:,:))

    ALLOCATE(optp2%optpwcldeff%legcoef(1:coef_scatt_ir2%fmv_wcldeff_maxnmom+1, &
                                      coef_scatt_ir2%fmv_wcldeff_ndeff, &
                                      coef_scatt_ir2%fmv_wcldeff_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpwcldeff%legcoef')
    optp2%optpwcldeff%legcoef(:,:,:) = optp1%optpwcldeff%legcoef(1:coef_scatt_ir2%fmv_wcldeff_maxnmom+1,:,channels)

    IF (coef_scatt_ir2%fmv_wcldeff_pha_chn > 0) THEN

      ALLOCATE(optp2%optpwcldeff%pha(coef_scatt_ir2%wcldeff_nphangle, &
                                 coef_scatt_ir2%fmv_wcldeff_ndeff, &
                                 coef_scatt_ir2%fmv_wcldeff_pha_chn), stat=err)
      THROWM(err.NE.0, 'allocation of optpwcldeff%pha')
      optp2%optpwcldeff%pha(:,:,:) = optp1%optpwcldeff%pha(:,:,phase_ext_index(1:coef_scatt_ir2%fmv_wcldeff_pha_chn))

    ENDIF

    IF (ALLOCATED(phase_ext_index)) DEALLOCATE (phase_ext_index)

  ENDIF


  ! --------------------------------------------------------------------------
  ! Ice cloud
  ! --------------------------------------------------------------------------

  ! Scalar variables

  ! A few of these are the same...
  coef_scatt_ir2%fmv_icl_ndeff = coef_scatt_ir1%fmv_icl_ndeff


  ! ... but we have to work out the solar channel numbers
  coef_scatt_ir2%fmv_icl_chn      = SIZE(channels)

  IF (coef_scatt_ir1%fmv_icl_pha_chn > 0) THEN
    ALLOCATE(phase_channels(coef_scatt_ir1%fmv_icl_pha_chn))

    ! Determine the solar channel numbers
    phase_channels(:) = coef_scatt_ir1%icl_pha_chanlist(:)

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE(phase_ext_index(coef_scatt_ir1%fmv_icl_pha_chn))
    CALL rttov_channel_extract_sublist( &
          err,                             &
          phase_channels,                  &
          channels,                        &
          coef_scatt_ir2%fmv_icl_pha_chn,  &
          coef_scatt_ir2%icl_pha_chanlist, &
          coef_scatt_ir2%icl_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)

    IF (coef_scatt_ir2%fmv_icl_pha_chn > 0) THEN
      coef_scatt_ir2%icl_nphangle = coef_scatt_ir1%icl_nphangle
      ALLOCATE(coef_scatt_ir2%icl_phangle(coef_scatt_ir2%icl_nphangle))
      coef_scatt_ir2%icl_phangle = coef_scatt_ir1%icl_phangle

      CALL rttov_alloc_phfn_int(err, coef_scatt_ir2%icl_phangle, coef_scatt_ir2%icl_phfn_int, 1_jpim)
      THROWM(err.NE.0, "initialisation of coef_scatt_ir2%icl_phfn_int")
    ENDIF

    ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

    IF (ALLOCATED(phase_channels)) DEALLOCATE(phase_channels)
  ELSE
    ! What do we need to do if there are no phase fns at all?
    coef_scatt_ir2%fmv_icl_pha_chn = 0
  ENDIF

  ALLOCATE(optp2%optpicl, stat=err)
  THROWM(err.NE.0, 'allocation of optpicl')

  CALL rttov_nullify_coef_scatt_ir(optp2%optpicl)

  ALLOCATE(optp2%optpicl%fmv_icl_deff(coef_scatt_ir2%fmv_icl_ndeff), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%fmv_icl_deff')
  optp2%optpicl%fmv_icl_deff(:) = optp1%optpicl%fmv_icl_deff(:)

  ALLOCATE(optp2%optpicl%abs(coef_scatt_ir2%fmv_icl_ndeff, coef_scatt_ir2%fmv_icl_chn), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%abs')
  optp2%optpicl%abs(:,:) = optp1%optpicl%abs(:,channels)

  ALLOCATE(optp2%optpicl%sca(coef_scatt_ir2%fmv_icl_ndeff, coef_scatt_ir2%fmv_icl_chn), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%sca')
  optp2%optpicl%sca(:,:) = optp1%optpicl%sca(:,channels)

  ALLOCATE(optp2%optpicl%bpr(coef_scatt_ir2%fmv_icl_ndeff, coef_scatt_ir2%fmv_icl_chn), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%bpr')
  optp2%optpicl%bpr(:,:) = optp1%optpicl%bpr(:,channels)

  ALLOCATE(optp2%optpicl%nmom(1,coef_scatt_ir2%fmv_icl_chn), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%nmom')
  optp2%optpicl%nmom(:,:) = optp1%optpicl%nmom(:,channels)

  coef_scatt_ir2%fmv_icl_maxnmom = MAXVAL(optp2%optpicl%nmom(:,:))

  ALLOCATE(optp2%optpicl%legcoef(1:coef_scatt_ir2%fmv_icl_maxnmom+1, &
                                    coef_scatt_ir2%fmv_icl_ndeff, &
                                    coef_scatt_ir2%fmv_icl_chn), stat=err)
  THROWM(err.NE.0, 'allocation of optpicl%legcoef')
  optp2%optpicl%legcoef(:,:,:) = optp1%optpicl%legcoef(1:coef_scatt_ir2%fmv_icl_maxnmom+1,:,channels)

  IF (coef_scatt_ir2%fmv_icl_pha_chn > 0) THEN

    ALLOCATE(optp2%optpicl%pha(coef_scatt_ir2%icl_nphangle, &
                               coef_scatt_ir2%fmv_icl_ndeff, &
                               coef_scatt_ir2%fmv_icl_pha_chn), stat=err)
    THROWM(err.NE.0, 'allocation of optpicl%pha')
    optp2%optpicl%pha(:,:,:) = optp1%optpicl%pha(:,:,phase_ext_index(1:coef_scatt_ir2%fmv_icl_pha_chn))

  ENDIF

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE (phase_ext_index)

CATCH
END SUBROUTINE rttov_channel_extract_sccldcoef
