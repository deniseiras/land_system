! Description:
!> @file
!!   Read a binary aerosol coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read a binary aerosol coefficient file, optionally extracting a subset of channels.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
!!
!!   Note that after reading a subset of channels RTTOV will identify them by
!!   indexes 1...SIZE(channels), not by the original channel numbers.
!!
!! @param[out]    err             status on exit
!! @param[in]     coef            RTTOV optical depth coefficient structure
!! @param[in,out] coef_scatt_ir   RTTOV aerosol coef_scatt_ir coefficient structure
!! @param[in,out] optp            RTTOV aerosol optp coefficient structure
!! @param[in]     file_id         logical unit for input scaercoef file
!! @param[in]     channels        list of channels to read, optional
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
SUBROUTINE rttov_read_binary_scaercoef( &
              err,           &
              coef,          &
              coef_scatt_ir, &
              optp,          &
              file_id,       &
              channels)
!INTF_OFF
#include "throw.h"
!INTF_ON
  USE rttov_types, ONLY : rttov_coef, rttov_optpar_ir, rttov_coef_scatt_ir
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE rttov_const, ONLY : rttov_magic_string, rttov_magic_number, errorstatus_fatal
  USE parkind1, ONLY : jprb, jplm
!INTF_ON
  IMPLICIT NONE

  INTEGER(KIND=jpim),        INTENT(OUT)          :: err
  TYPE(rttov_coef),          INTENT(IN)           :: coef
  TYPE(rttov_coef_scatt_ir), INTENT(INOUT)        :: coef_scatt_ir
  TYPE(rttov_optpar_ir),     INTENT(INOUT)        :: optp
  INTEGER(KIND=jpim),        INTENT(IN)           :: file_id
  INTEGER(KIND=jpim),        INTENT(IN), OPTIONAL :: channels(:)

!INTF_END
#include "rttov_errorreport.interface"
#include "rttov_nullify_coef_scatt_ir.interface"
#include "rttov_alloc_phfn_int.interface"
#include "rttov_channel_extract_sublist.interface"

  INTEGER(KIND=jpim) :: file_channels
  LOGICAL(KIND=jplm) :: all_channels
  INTEGER(KIND=jpim) :: n, r
  INTEGER(KIND=jpim) :: i
  INTEGER(KIND=jpim) :: n_phase_channels
  INTEGER(KIND=jpim), ALLOCATABLE :: list_of_channels(:)
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_channels(:)     ! Solar channel numbers in original file
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_ext_index(:)    ! Indexes of phase data to extract

  REAL   (KIND=jprb), POINTER     :: dvalues0(:,:)
  REAL   (KIND=jprb), POINTER     :: tvalues0(:,:,:)
  INTEGER(KIND=jpim), POINTER     :: ivalues0(:,:)
  CHARACTER(LEN=16) :: bin_check_string
  REAL(KIND=jprb)   :: bin_check_number
  REAL(KIND=jprb)   :: bin_check_value
  CHARACTER(LEN=10) :: filetype_check_string
!- End of header --------------------------------------------------------
  TRY

  all_channels = .NOT. PRESENT(channels)

  READ (file_id, iostat=err) bin_check_string, bin_check_number
  THROWM(err.NE.0,'io status while reading header')

  ! Verification of header string
  IF (bin_check_string /= rttov_magic_string) err = errorstatus_fatal
  THROWM(err.NE.0,'Wrong header string in file')

  ! Verification of single/double precision using a 5 digit number
  ! with exponent 12, which is always Ok for single precision
  bin_check_value = 1._jprb - ABS(bin_check_number - rttov_magic_number)
  IF (bin_check_value > 1.01_jprb .OR. bin_check_value < 0.99_jprb) err = errorstatus_fatal
  THROWM(err.NE.0,'File created with a different real precision (R4<->R8)')

  ! Verify this is an aerosol file (to avoid mixing up with cloud files)
  READ (file_id, iostat=err) filetype_check_string
  IF (TRIM(filetype_check_string) /= 'scaer_coef') err = errorstatus_fatal
  THROWM(err.NE.0,'This is not an aerosol coefficient file')


  ! AEROSOLS_COMPONENTS

  READ (file_id, iostat=err) coef_scatt_ir%fmv_aer_chn,  &
                             n_phase_channels,           &
                             coef_scatt_ir%fmv_aer_comp, &
                             coef_scatt_ir%fmv_aer_maxnmom
  THROWM(err.NE.0,"reading aerosol dimensions")

  IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_aer_chn) THEN
    err = errorstatus_fatal
    THROWM(err.ne.0,"Incompatible channels between rtcoef and scaercoef files")
  ENDIF

  IF (.NOT. all_channels) THEN
    ALLOCATE (list_of_channels(SIZE(channels)))
    list_of_channels = channels
  ELSE
    ALLOCATE (list_of_channels(coef%fmv_chn))
    list_of_channels = (/(i, i = 1, coef%fmv_chn)/)
  ENDIF

  ! Take care of the user list of channels
  ! file_channels store the number of channels in the file
  ! coef_scatt_ir%fmv_aer_chn is the number of channels that the user requests
  file_channels = coef_scatt_ir%fmv_aer_chn

  IF (.NOT. all_channels) THEN
    coef_scatt_ir%fmv_aer_chn = SIZE(channels)
  ENDIF

  ! Sort out the solar channels/phase functions
  IF (n_phase_channels > 0) THEN

    ! Read the solar channel numbers
    ALLOCATE(phase_channels(n_phase_channels))
    READ (file_id, iostat=err)phase_channels(:)
    THROWM(err.ne.0,"reading solar channel numbers")

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE (phase_ext_index(n_phase_channels))
    CALL rttov_channel_extract_sublist( &
          err,                            &
          phase_channels,                 &
          list_of_channels,               &
          coef_scatt_ir%fmv_aer_pha_chn,  &
          coef_scatt_ir%aer_pha_chanlist, &
          coef_scatt_ir%aer_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)
    DEALLOCATE(phase_channels)

    ! See rttov_read_ascii_scaercoef.F90 for a description of what the various arrays contain.

    ! Read phase function angle data
    READ (file_id, iostat=err) coef_scatt_ir%aer_nphangle
    THROWM(err.NE.0,"reading aer_nphangle")
    ALLOCATE(coef_scatt_ir%aer_phangle(coef_scatt_ir%aer_nphangle), STAT=err)
    THROWM(err.NE.0,"allocation of aer_phangle")
    READ (file_id, iostat=err) coef_scatt_ir%aer_phangle(:)
    THROWM(err.NE.0,"reading aer_phangle")

    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%aer_phangle, coef_scatt_ir%aer_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%aer_phfn_int")

  ELSE
    coef_scatt_ir%fmv_aer_pha_chn = 0
    coef_scatt_ir%aer_nphangle = 0
  ENDIF

  ! Aerosol type names are not stored in binary files, but allocate the array anyway
  ALLOCATE (coef_scatt_ir%fmv_aer_comp_name(coef_scatt_ir%fmv_aer_comp), STAT=err)
  THROWM(err.NE.0,"allocation of fmv_aer_comp_name")
  coef_scatt_ir%fmv_aer_comp_name(:) = ""

  ALLOCATE (coef_scatt_ir%fmv_aer_rh(coef_scatt_ir%fmv_aer_comp), STAT=err)
  THROWM(err.NE.0,"allocation of fmv_aer_rh")

  ALLOCATE (coef_scatt_ir%aer_mmr2nd(coef_scatt_ir%fmv_aer_comp), STAT=err)
  THROWM(err.NE.0,"allocation of aer_mmr2nd")

  ALLOCATE (optp%optpaer(coef_scatt_ir%fmv_aer_comp), STAT=err)
  THROWM(err.NE.0,"allocation of optpaer")

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    CALL rttov_nullify_coef_scatt_ir(optp%optpaer(n))
  ENDDO

  READ (file_id, iostat=err) coef_scatt_ir%fmv_aer_rh
  THROWM(err.NE.0,"reading coef_scatt_ir%fmv_aer_rh")

  READ (file_id, iostat=err) coef_scatt_ir%aer_mmr2nd
  THROWM(err.NE.0,"reading aer_mmr2nd")

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    ALLOCATE (optp%optpaer(n)%fmv_aer_rh_val(coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%fmv_aer_rh_val")

    READ (file_id, iostat=err) optp%optpaer(n)%fmv_aer_rh_val
    THROWM(err.NE.0,"reading optp%optpaer(n)%fmv_aer_rh_val")
  ENDDO


  ! AEROSOLS_PARAMETERS
  DO n = 1, coef_scatt_ir%fmv_aer_comp
    ALLOCATE (optp%optpaer(n)%abs(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%abs")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpaer(n)%abs
      THROWM(err.NE.0,"reading optp%optpaer(n)%abs")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpaer(n)%abs(:,:) = dvalues0(channels(:), :)

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO


  DO n = 1, coef_scatt_ir%fmv_aer_comp
    ALLOCATE (optp%optpaer(n)%sca(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%sca")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpaer(n)%sca
      THROWM(err.NE.0,"reading optp%optpaer(n)%sca")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpaer(n)%sca(:,:) = dvalues0(channels(:), :)

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO


  DO n = 1, coef_scatt_ir%fmv_aer_comp
    ALLOCATE (optp%optpaer(n)%bpr(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%bpr")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpaer(n)%bpr
      THROWM(err.NE.0,"reading optp%optpaer(n)%bpr")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpaer(n)%bpr(:,:) = dvalues0(channels(:), :)

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    ALLOCATE (optp%optpaer(n)%nmom(coef_scatt_ir%fmv_aer_chn,coef_scatt_ir%fmv_aer_rh(n)),STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%nmom")

    ALLOCATE (optp%optpaer(n)%legcoef(1:coef_scatt_ir%fmv_aer_maxnmom+1,coef_scatt_ir%fmv_aer_chn, &
                                      coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpaer(n)%legcoef")

    IF (all_channels) THEN
      DO r = 1, coef_scatt_ir%fmv_aer_rh(n)
        DO i = 1, coef_scatt_ir%fmv_aer_chn
          READ (file_id, iostat=err) optp%optpaer(n)%nmom(i,r)
          THROWM(err.NE.0,"reading optp%optpaer(n)%nmom")

          READ (file_id, iostat=err) optp%optpaer(n)%legcoef(1:optp%optpaer(n)%nmom(i,r)+1,i,r)
          THROWM(err.NE.0,"reading optp%optpaer(n)%legcoef")
        ENDDO
      ENDDO
    ELSE
      ALLOCATE (ivalues0(file_channels,coef_scatt_ir%fmv_aer_rh(n)))
      ALLOCATE (tvalues0(0:coef_scatt_ir%fmv_aer_maxnmom,file_channels,coef_scatt_ir%fmv_aer_rh(n)), STAT=err)

      DO r = 1, coef_scatt_ir%fmv_aer_rh(n)
        DO i = 1, file_channels
          READ (file_id, iostat=err) ivalues0(i,r)
          THROWM(err.NE.0,"reading optp%optpaer(n)%nmom")

          READ (file_id, iostat=err) tvalues0(0:ivalues0(i,r),i,r)
          THROWM(err.NE.0,"reading optp%optpaer(n)%legcoef")
        ENDDO
      ENDDO

      optp%optpaer(n)%nmom(:,:) = ivalues0(channels(:),:)
      optp%optpaer(n)%legcoef(:,:,:) = tvalues0(:,channels(:),:)

      DEALLOCATE (ivalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of ivalues0")
      DEALLOCATE (tvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of tvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_aer_comp
    IF (coef_scatt_ir%fmv_aer_pha_chn > 0) THEN
      ALLOCATE (optp%optpaer(n)%pha(coef_scatt_ir%aer_nphangle,coef_scatt_ir%fmv_aer_pha_chn, &
                                    coef_scatt_ir%fmv_aer_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of optp%optpaer(n)%pha")
    ENDIF

    IF (n_phase_channels > 0) THEN
      IF (all_channels) THEN
        READ (file_id, iostat=err) optp%optpaer(n)%pha(:,:,:)
        THROWM(err.NE.0,"reading optp%optpaer(n)%pha")
      ELSE
        ALLOCATE (tvalues0(coef_scatt_ir%aer_nphangle,n_phase_channels,coef_scatt_ir%fmv_aer_rh(n)), STAT=err)

        READ (file_id, iostat=err) tvalues0(:,:,:)
        THROWM(err.NE.0,"reading optp%optpaer(n)%pha")

        IF (coef_scatt_ir%fmv_aer_pha_chn > 0) THEN
          optp%optpaer(n)%pha(:,:,:) = tvalues0(:,phase_ext_index(1:coef_scatt_ir%fmv_aer_pha_chn),:)
        ENDIF

        DEALLOCATE (tvalues0, STAT=err)
        THROWM(err.NE.0,"deallocation of tvalues0")
      ENDIF
    ENDIF
  ENDDO

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)
  DEALLOCATE (list_of_channels)

  CATCH
END SUBROUTINE rttov_read_binary_scaercoef
