! Description:
!> @file
!!   Read a binary cloud coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read a binary cloud coefficient file, optionally extracting a subset of channels.
!!
!! @details
!!   The file unit must be open when this subroutine is called.
!!
!!   Note that after reading a subset of channels RTTOV will identify them by
!!   indexes 1...SIZE(channels), not by the original channel numbers.
!!
!! @param[out]    err             status on exit
!! @param[in]     coef            RTTOV optical depth coefficient structure
!! @param[in,out] coef_scatt_ir   RTTOV cloud coef_scatt_ir coefficient structure
!! @param[in,out] optp            RTTOV cloud optp coefficient structure
!! @param[in]     file_id         logical unit for input sccldcoef file
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
SUBROUTINE rttov_read_binary_sccldcoef( &
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
  LOGICAL(KIND=jplm) :: section_present
  INTEGER(KIND=jpim) :: n, r, i
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

  ! Verify this is a cloud file (to avoid mixing up with aerosol files)
  READ (file_id, iostat=err) filetype_check_string
  IF (TRIM(filetype_check_string) /= 'sccld_coef') err = errorstatus_fatal
  THROWM(err.NE.0,'This is not a cloud coefficient file')


  ! WATERCLOUD_TYPES
  READ (file_id, iostat=err) coef_scatt_ir%fmv_wcl_chn,  &
                             n_phase_channels,           &
                             coef_scatt_ir%fmv_wcl_comp, &
                             coef_scatt_ir%fmv_wcl_maxnmom
  THROWM(err.NE.0,"reading water cloud dimensions")

  IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_wcl_chn) THEN
    err = errorstatus_fatal
    THROWM(err.NE.0,"Incompatible channels between rtcoef and sccldcoef files")
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
  ! coef_scatt_ir%fmv_wcl_chn is the number of channels that the user requests
  file_channels = coef_scatt_ir%fmv_wcl_chn

  IF (.NOT. all_channels) THEN
    coef_scatt_ir%fmv_wcl_chn = SIZE(channels)
  ENDIF

  ! Sort out the solar channels/phase functions
  IF (n_phase_channels > 0) THEN

    ! Read the solar channel numbers
    ALLOCATE(phase_channels(n_phase_channels))
    READ (file_id, iostat=err)phase_channels(:)
    THROWM(err.NE.0,"reading solar channel numbers")

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE (phase_ext_index(n_phase_channels))
    CALL rttov_channel_extract_sublist( &
          err,                            &
          phase_channels,                 &
          list_of_channels,               &
          coef_scatt_ir%fmv_wcl_pha_chn,  &
          coef_scatt_ir%wcl_pha_chanlist, &
          coef_scatt_ir%wcl_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)
    DEALLOCATE(phase_channels)

    ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

    ! Read phase function angle data
    READ (file_id, iostat=err) coef_scatt_ir%wcl_nphangle
    THROWM(err.NE.0,"reading wcl_nphangle")
    ALLOCATE(coef_scatt_ir%wcl_phangle(coef_scatt_ir%wcl_nphangle), STAT=err)
    THROWM(err.NE.0,"allocation of wcl_phangle")
    READ (file_id, iostat=err) coef_scatt_ir%wcl_phangle(:)
    THROWM(err.NE.0,"reading wcl_phangle")

    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcl_phangle, coef_scatt_ir%wcl_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcl_phfn_int")

  ELSE
    coef_scatt_ir%fmv_wcl_pha_chn = 0
    coef_scatt_ir%wcl_nphangle = 0
  ENDIF

  ! Water cloud type names are not stored in binary files, but allocate the array anyway
  ALLOCATE (coef_scatt_ir%fmv_wcl_comp_name(coef_scatt_ir%fmv_wcl_comp), STAT=err)
  THROWM(err.NE.0,"allocation of fmv_wcl_comp_name")
  coef_scatt_ir%fmv_wcl_comp_name(:) = ""

  ALLOCATE (coef_scatt_ir%fmv_wcl_rh(coef_scatt_ir%fmv_wcl_comp), STAT=err)
  THROWM(err.NE.0,"allocation of fmv_wcl_rh")

  ALLOCATE (coef_scatt_ir%confac(coef_scatt_ir%fmv_wcl_comp), STAT=err)
  THROWM(err.NE.0,"allocation of confac")

  ALLOCATE (optp%optpwcl(coef_scatt_ir%fmv_wcl_comp), STAT=err)
  THROWM(err.NE.0,"allocation of optpwcl")

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    CALL rttov_nullify_coef_scatt_ir(optp%optpwcl(n))
  ENDDO

  READ (file_id, iostat=err) coef_scatt_ir%fmv_wcl_rh
  THROWM(err.NE.0,"reading fmv_wcl_rh")

  READ (file_id, iostat=err) coef_scatt_ir%confac
  THROWM(err.NE.0,"reading confac")

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    ALLOCATE (optp%optpwcl(n)%fmv_wcl_rh_val(coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcl(n)%fmv_wcl_rh_val")

    READ (file_id, iostat=err) optp%optpwcl(n)%fmv_wcl_rh_val
    THROWM(err.NE.0,"reading optpwcl(n)%fmv_wcl_rh_val")
  ENDDO


  ! WATERCLOUD_PARAMETERS

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    ALLOCATE (optp%optpwcl(n)%abs(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcl(n)%abs")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcl(n)%abs
      THROWM(err.NE.0,"reading optpwcl(n)%abs")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcl(n)%abs(:,:) = dvalues0(channels(:),:)

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    ALLOCATE (optp%optpwcl(n)%sca(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcl(n)%sca")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcl(n)%sca
      THROWM(err.NE.0,"reading optpwcl(n)%sca")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcl(n)%sca(:,:) = dvalues0(channels(:),:)

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    ALLOCATE (optp%optpwcl(n)%bpr(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcl(n)%bpr")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcl(n)%bpr
      THROWM(err.NE.0,"reading optpwcl(n)%bpr")
    ELSE
      ALLOCATE (dvalues0(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcl(n)%bpr(:,:) = dvalues0(channels(:),:)

      DEALLOCATE (dvalues0)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    ALLOCATE (optp%optpwcl(n)%nmom(coef_scatt_ir%fmv_wcl_chn,coef_scatt_ir%fmv_wcl_rh(n)),STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpwcl(n)%nmom")

    ALLOCATE (optp%optpwcl(n)%legcoef(1:coef_scatt_ir%fmv_wcl_maxnmom+1,coef_scatt_ir%fmv_wcl_chn, &
                                      coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpwcl(n)%legcoef")

    IF (all_channels) THEN
      DO r = 1, coef_scatt_ir%fmv_wcl_rh(n)
        DO i = 1, coef_scatt_ir%fmv_wcl_chn
          READ (file_id, iostat=err) optp%optpwcl(n)%nmom(i,r)
          THROWM(err.NE.0,"reading optp%optpwcl(n)%nmom")

          READ (file_id, iostat=err) optp%optpwcl(n)%legcoef(1:optp%optpwcl(n)%nmom(i,r)+1,i,r)
          THROWM(err.NE.0,"reading optp%optpwcl(n)%legcoef")
        ENDDO
      ENDDO
    ELSE
      ALLOCATE (ivalues0(file_channels,coef_scatt_ir%fmv_wcl_rh(n)))
      ALLOCATE (tvalues0(0:coef_scatt_ir%fmv_wcl_maxnmom,file_channels,coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)

      DO r = 1, coef_scatt_ir%fmv_wcl_rh(n)
        DO i = 1, file_channels
          READ (file_id, iostat=err) ivalues0(i,r)
          THROWM(err.NE.0,"reading optp%optpwcl(n)%nmom")

          READ (file_id, iostat=err) tvalues0(0:ivalues0(i,r),i,r)
          THROWM(err.NE.0,"reading optp%optpwcl(n)%legcoef")
        ENDDO
      ENDDO

      optp%optpwcl(n)%nmom(:,:) = ivalues0(channels(:),:)
      optp%optpwcl(n)%legcoef(:,:,:) = tvalues0(:,channels(:),:)

      DEALLOCATE (ivalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of ivalues0")
      DEALLOCATE (tvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of tvalues0")
    ENDIF
  ENDDO

  DO n = 1, coef_scatt_ir%fmv_wcl_comp
    IF (coef_scatt_ir%fmv_wcl_pha_chn > 0) THEN
      ALLOCATE (optp%optpwcl(n)%pha(coef_scatt_ir%wcl_nphangle,coef_scatt_ir%fmv_wcl_pha_chn, &
                                    coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)
      THROWM(err.NE.0,"allocation of optp%optpwcl(n)%pha")
    ENDIF

    IF (n_phase_channels > 0) THEN
      IF (all_channels) THEN
        READ (file_id, iostat=err) optp%optpwcl(n)%pha(:,:,:)
        THROWM(err.NE.0,"reading optp%optpwcl(n)%pha")
      ELSE
        ALLOCATE (tvalues0(coef_scatt_ir%wcl_nphangle,n_phase_channels,coef_scatt_ir%fmv_wcl_rh(n)), STAT=err)

        READ (file_id, iostat=err) tvalues0(:,:,:)
        THROWM(err.NE.0,"reading optp%optpwcl(n)%pha")

        IF (coef_scatt_ir%fmv_wcl_pha_chn > 0) THEN
          optp%optpwcl(n)%pha(:,:,:) = tvalues0(:,phase_ext_index(1:coef_scatt_ir%fmv_wcl_pha_chn),:)
        ENDIF

        DEALLOCATE (tvalues0, STAT=err)
        THROWM(err.NE.0,"deallocation of tvalues0")
      ENDIF
    ENDIF
  ENDDO

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)


  ! ICECLOUD_TYPES
  READ (file_id, iostat=err) coef_scatt_ir%fmv_icl_chn,   &
                             n_phase_channels,            &
                             coef_scatt_ir%fmv_icl_ndeff, &
                             coef_scatt_ir%fmv_icl_maxnmom
  THROWM(err.NE.0,"reading ice cloud dimensions")

  ! Take care of the user list of channels
  ! file_channels store the number of channels in the file
  ! coef_scatt_ir%fmv_icl_chn is the number of channels that the user requests
  file_channels = coef_scatt_ir%fmv_icl_chn

  IF (.NOT. all_channels) THEN
    coef_scatt_ir%fmv_icl_chn = SIZE(channels)
  ENDIF

  ! Sort out the solar channels/phase functions
  IF (n_phase_channels > 0) THEN

    ! Read the solar channel numbers
    ALLOCATE(phase_channels(n_phase_channels))
    READ (file_id, iostat=err)phase_channels(:)
    THROWM(err.NE.0,"reading solar channel numbers")

    ! Determine solar channels/phase functions to be extracted
    ALLOCATE (phase_ext_index(n_phase_channels))
    CALL rttov_channel_extract_sublist( &
          err,                            &
          phase_channels,                 &
          list_of_channels,               &
          coef_scatt_ir%fmv_icl_pha_chn,  &
          coef_scatt_ir%icl_pha_chanlist, &
          coef_scatt_ir%icl_pha_index,    &
          phase_ext_index)
    THROW(err.NE.0)
    DEALLOCATE(phase_channels)

    ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

    ! Read phase function angle data
    READ (file_id, iostat=err) coef_scatt_ir%icl_nphangle
    THROWM(err.NE.0,"reading icl_nphangle")
    ALLOCATE(coef_scatt_ir%icl_phangle(coef_scatt_ir%icl_nphangle), STAT=err)
    THROWM(err.NE.0,"allocation of icl_phangle")
    READ (file_id, iostat=err) coef_scatt_ir%icl_phangle(:)
    THROWM(err.NE.0,"reading icl_phangle")

    CALL rttov_alloc_phfn_int(err, coef_scatt_ir%icl_phangle, coef_scatt_ir%icl_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%icl_phfn_int")

  ELSE
    coef_scatt_ir%fmv_icl_pha_chn = 0
    coef_scatt_ir%icl_nphangle = 0
  ENDIF

  ! Allocate optical parameter structure
  ALLOCATE(optp%optpicl, STAT=err)
  THROWM(err.NE.0,"allocation of optpicl")
  CALL rttov_nullify_coef_scatt_ir(optp%optpicl)

  ! Read effective diameters
  ALLOCATE(optp%optpicl%fmv_icl_deff(coef_scatt_ir%fmv_icl_ndeff))
  READ (file_id, iostat=err)optp%optpicl%fmv_icl_deff(:)
  THROWM(err.NE.0,"reading optp%optpicl%deff")


  ! Read optical parameters
  ALLOCATE (optp%optpicl%abs(coef_scatt_ir%fmv_icl_ndeff, coef_scatt_ir%fmv_icl_chn), STAT=err)
  THROWM(err.NE.0,"allocation of optpicl%abs")

  IF (all_channels) THEN
    READ (file_id, iostat=err)optp%optpicl%abs
    THROWM(err.NE.0,"reading optpicl%abs")
  ELSE
    ALLOCATE (dvalues0(coef_scatt_ir%fmv_icl_ndeff, file_channels), STAT=err)
    THROWM(err.NE.0,"allocation of dvalues0")

    READ (file_id, iostat=err)dvalues0
    THROWM(err.NE.0,"reading dvalues0")

    optp%optpicl%abs(:,:) = dvalues0(:, channels(:))

    DEALLOCATE (dvalues0, STAT=err)
    THROWM(err.NE.0,"deallocation of dvalues0")
  ENDIF

  ALLOCATE (optp%optpicl%sca(coef_scatt_ir%fmv_icl_ndeff, coef_scatt_ir%fmv_icl_chn), STAT=err)
  THROWM(err.NE.0,"allocation of optpicl%sca")

  IF (all_channels) THEN
    READ (file_id, iostat=err)optp%optpicl%sca
    THROWM(err.NE.0,"reading optpicl%sca")
  ELSE
    ALLOCATE (dvalues0(coef_scatt_ir%fmv_icl_ndeff, file_channels), STAT=err)
    THROWM(err.NE.0,"allocation of dvalues0")

    READ (file_id, iostat=err)dvalues0
    THROWM(err.NE.0,"reading dvalues0")

    optp%optpicl%sca(:,:) = dvalues0(:, channels(:))

    DEALLOCATE (dvalues0, STAT=err)
    THROWM(err.NE.0,"deallocation of dvalues0")
  ENDIF

  ALLOCATE (optp%optpicl%bpr(coef_scatt_ir%fmv_icl_ndeff, coef_scatt_ir%fmv_icl_chn), STAT=err)
  THROWM(err.NE.0,"allocation of optpicl%bpr")

  IF (all_channels) THEN
    READ (file_id, iostat=err)optp%optpicl%bpr
    THROWM(err.NE.0,"reading optpicl%bpr")
  ELSE
    ALLOCATE (dvalues0(coef_scatt_ir%fmv_icl_ndeff, file_channels), STAT=err)
    THROWM(err.NE.0,"allocation of dvalues0")

    READ (file_id, iostat=err)dvalues0
    THROWM(err.NE.0,"reading dvalues0")

    optp%optpicl%bpr(:,:) = dvalues0(:, channels(:))

    DEALLOCATE (dvalues0)
    THROWM(err.NE.0,"deallocation of dvalues0")
  ENDIF

  ALLOCATE (optp%optpicl%nmom(1, coef_scatt_ir%fmv_icl_chn),STAT=err)
  THROWM(err.NE.0,"allocation of optp%optpicl%nmom")

  ALLOCATE (optp%optpicl%legcoef(1:coef_scatt_ir%fmv_icl_maxnmom+1, &
                                 coef_scatt_ir%fmv_icl_ndeff,       &
                                 coef_scatt_ir%fmv_icl_chn), STAT=err)
  THROWM(err.NE.0,"allocation of optp%optpicl%legcoef")

  IF (all_channels) THEN
    optp%optpicl%legcoef = 0._jprb
    DO i = 1, coef_scatt_ir%fmv_icl_chn
      READ (file_id, iostat=err) optp%optpicl%nmom(1,i)
      THROWM(err.NE.0,"reading optp%optpicl%nmom")

      READ (file_id, iostat=err) optp%optpicl%legcoef(1:optp%optpicl%nmom(1,i)+1,:,i)
      THROWM(err.NE.0,"reading optp%optpicl%legcoef")
    ENDDO
  ELSE
    ALLOCATE (ivalues0(1, file_channels))
    ALLOCATE (tvalues0(0:coef_scatt_ir%fmv_icl_maxnmom, &
                       coef_scatt_ir%fmv_icl_ndeff,     &
                       file_channels), STAT=err)
    tvalues0 = 0._jprb
    DO i = 1, file_channels
      READ (file_id, iostat=err) ivalues0(1,i)
      THROWM(err.NE.0,"reading optp%optpicl%nmom")

      READ (file_id, iostat=err) tvalues0(0:ivalues0(1,i),:,i)
      THROWM(err.NE.0,"reading optp%optpicl%legcoef")
    ENDDO

    optp%optpicl%nmom(:,:) = ivalues0(:,channels(:))
    optp%optpicl%legcoef(:,:,:) = tvalues0(:,:,channels(:))

    DEALLOCATE (ivalues0, STAT=err)
    THROWM(err.NE.0,"deallocation of ivalues0")
    DEALLOCATE (tvalues0, STAT=err)
    THROWM(err.NE.0,"deallocation of tvalues0")
  ENDIF

  IF (coef_scatt_ir%fmv_icl_pha_chn > 0) THEN
    ALLOCATE (optp%optpicl%pha(coef_scatt_ir%icl_nphangle,  &
                               coef_scatt_ir%fmv_icl_ndeff, &
                               coef_scatt_ir%fmv_icl_pha_chn), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpicl%pha")
  ENDIF

  IF (n_phase_channels > 0) THEN
    IF (all_channels) THEN
      READ (file_id, iostat=err) optp%optpicl%pha(:,:,:)
      THROWM(err.NE.0,"reading optp%optpicl%pha")
    ELSE
      ALLOCATE (tvalues0(coef_scatt_ir%icl_nphangle,  &
                         coef_scatt_ir%fmv_icl_ndeff, &
                         n_phase_channels), STAT=err)
      READ (file_id, iostat=err) tvalues0(:,:,:)
      THROWM(err.NE.0,"reading optp%optpicl%pha")

      IF (coef_scatt_ir%fmv_icl_pha_chn > 0) THEN
        optp%optpicl%pha(:,:,:) = tvalues0(:,:,phase_ext_index(1:coef_scatt_ir%fmv_icl_pha_chn))
      ENDIF

      DEALLOCATE (tvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of tvalues0")
    ENDIF
  ENDIF

  IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)


  ! WATERCLOUD_DEFF_TYPES - this section may not be present in old sccld coef files
  READ (file_id, iostat=err) section_present

  IF (err == 0 .AND. section_present) THEN

    READ (file_id, iostat=err) coef_scatt_ir%fmv_wcldeff_chn,   &
                               n_phase_channels,                &
                               coef_scatt_ir%fmv_wcldeff_ndeff, &
                               coef_scatt_ir%fmv_wcldeff_maxnmom
    THROWM(err.NE.0,"reading ice cloud dimensions")

    ! Take care of the user list of channels
    ! file_channels store the number of channels in the file
    ! coef_scatt_ir%fmv_wcldeff_chn is the number of channels that the user requests
    file_channels = coef_scatt_ir%fmv_wcldeff_chn

    IF (.NOT. all_channels) THEN
      coef_scatt_ir%fmv_wcldeff_chn = SIZE(channels)
    ENDIF

    ! Sort out the solar channels/phase functions
    IF (n_phase_channels > 0) THEN

      ! Read the solar channel numbers
      ALLOCATE(phase_channels(n_phase_channels))
      READ (file_id, iostat=err)phase_channels(:)
      THROWM(err.NE.0,"reading solar channel numbers")

      ! Determine solar channels/phase functions to be extracted
      ALLOCATE (phase_ext_index(n_phase_channels))
      CALL rttov_channel_extract_sublist( &
            err,                            &
            phase_channels,                 &
            list_of_channels,               &
            coef_scatt_ir%fmv_wcldeff_pha_chn,  &
            coef_scatt_ir%wcldeff_pha_chanlist, &
            coef_scatt_ir%wcldeff_pha_index,    &
            phase_ext_index)
      THROW(err.NE.0)
      DEALLOCATE(phase_channels)

      ! See rttov_read_ascii_sccldcoef.F90 for a description of what the various arrays contain.

      ! Read phase function angle data
      READ (file_id, iostat=err) coef_scatt_ir%wcldeff_nphangle
      THROWM(err.NE.0,"reading wcldeff_nphangle")
      ALLOCATE(coef_scatt_ir%wcldeff_phangle(coef_scatt_ir%wcldeff_nphangle), STAT=err)
      THROWM(err.NE.0,"allocation of wcldeff_phangle")
      READ (file_id, iostat=err) coef_scatt_ir%wcldeff_phangle(:)
      THROWM(err.NE.0,"reading wcldeff_phangle")

      CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcldeff_phangle, coef_scatt_ir%wcldeff_phfn_int, 1_jpim)
      THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcldeff_phfn_int")

    ELSE
      coef_scatt_ir%fmv_wcldeff_pha_chn = 0
      coef_scatt_ir%wcldeff_nphangle = 0
    ENDIF

    ! Allocate optical parameter structure
    ALLOCATE(optp%optpwcldeff, STAT=err)
    THROWM(err.NE.0,"allocation of optpwcldeff")
    CALL rttov_nullify_coef_scatt_ir(optp%optpwcldeff)

    ! Read effective diameters
    ALLOCATE(optp%optpwcldeff%fmv_wcldeff_deff(coef_scatt_ir%fmv_wcldeff_ndeff))
    READ (file_id, iostat=err)optp%optpwcldeff%fmv_wcldeff_deff(:)
    THROWM(err.NE.0,"reading optp%optpwcldeff%deff")


    ! Read optical parameters
    ALLOCATE (optp%optpwcldeff%abs(coef_scatt_ir%fmv_wcldeff_ndeff, coef_scatt_ir%fmv_wcldeff_chn), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcldeff%abs")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcldeff%abs
      THROWM(err.NE.0,"reading optpwcldeff%abs")
    ELSE
      ALLOCATE (dvalues0(coef_scatt_ir%fmv_wcldeff_ndeff, file_channels), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcldeff%abs(:,:) = dvalues0(:, channels(:))

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF

    ALLOCATE (optp%optpwcldeff%sca(coef_scatt_ir%fmv_wcldeff_ndeff, coef_scatt_ir%fmv_wcldeff_chn), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcldeff%sca")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcldeff%sca
      THROWM(err.NE.0,"reading optpwcldeff%sca")
    ELSE
      ALLOCATE (dvalues0(coef_scatt_ir%fmv_wcldeff_ndeff, file_channels), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcldeff%sca(:,:) = dvalues0(:, channels(:))

      DEALLOCATE (dvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF

    ALLOCATE (optp%optpwcldeff%bpr(coef_scatt_ir%fmv_wcldeff_ndeff, coef_scatt_ir%fmv_wcldeff_chn), STAT=err)
    THROWM(err.NE.0,"allocation of optpwcldeff%bpr")

    IF (all_channels) THEN
      READ (file_id, iostat=err)optp%optpwcldeff%bpr
      THROWM(err.NE.0,"reading optpwcldeff%bpr")
    ELSE
      ALLOCATE (dvalues0(coef_scatt_ir%fmv_wcldeff_ndeff, file_channels), STAT=err)
      THROWM(err.NE.0,"allocation of dvalues0")

      READ (file_id, iostat=err)dvalues0
      THROWM(err.NE.0,"reading dvalues0")

      optp%optpwcldeff%bpr(:,:) = dvalues0(:, channels(:))

      DEALLOCATE (dvalues0)
      THROWM(err.NE.0,"deallocation of dvalues0")
    ENDIF

    ALLOCATE (optp%optpwcldeff%nmom(1, coef_scatt_ir%fmv_wcldeff_chn),STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpwcldeff%nmom")

    ALLOCATE (optp%optpwcldeff%legcoef(1:coef_scatt_ir%fmv_wcldeff_maxnmom+1, &
                                   coef_scatt_ir%fmv_wcldeff_ndeff,       &
                                   coef_scatt_ir%fmv_wcldeff_chn), STAT=err)
    THROWM(err.NE.0,"allocation of optp%optpwcldeff%legcoef")

    IF (all_channels) THEN
      optp%optpwcldeff%legcoef = 0._jprb
      DO i = 1, coef_scatt_ir%fmv_wcldeff_chn
        READ (file_id, iostat=err) optp%optpwcldeff%nmom(1,i)
        THROWM(err.NE.0,"reading optp%optpwcldeff%nmom")

        READ (file_id, iostat=err) optp%optpwcldeff%legcoef(1:optp%optpwcldeff%nmom(1,i)+1,:,i)
        THROWM(err.NE.0,"reading optp%optpwcldeff%legcoef")
      ENDDO
    ELSE
      ALLOCATE (ivalues0(1, file_channels))
      ALLOCATE (tvalues0(0:coef_scatt_ir%fmv_wcldeff_maxnmom, &
                         coef_scatt_ir%fmv_wcldeff_ndeff,     &
                         file_channels), STAT=err)
      tvalues0 = 0._jprb
      DO i = 1, file_channels
        READ (file_id, iostat=err) ivalues0(1,i)
        THROWM(err.NE.0,"reading optp%optpwcldeff%nmom")

        READ (file_id, iostat=err) tvalues0(0:ivalues0(1,i),:,i)
        THROWM(err.NE.0,"reading optp%optpwcldeff%legcoef")
      ENDDO

      optp%optpwcldeff%nmom(:,:) = ivalues0(:,channels(:))
      optp%optpwcldeff%legcoef(:,:,:) = tvalues0(:,:,channels(:))

      DEALLOCATE (ivalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of ivalues0")
      DEALLOCATE (tvalues0, STAT=err)
      THROWM(err.NE.0,"deallocation of tvalues0")
    ENDIF

    IF (coef_scatt_ir%fmv_wcldeff_pha_chn > 0) THEN
      ALLOCATE (optp%optpwcldeff%pha(coef_scatt_ir%wcldeff_nphangle,  &
                                 coef_scatt_ir%fmv_wcldeff_ndeff, &
                                 coef_scatt_ir%fmv_wcldeff_pha_chn), STAT=err)
      THROWM(err.NE.0,"allocation of optp%optpwcldeff%pha")
    ENDIF

    IF (n_phase_channels > 0) THEN
      IF (all_channels) THEN
        READ (file_id, iostat=err) optp%optpwcldeff%pha(:,:,:)
        THROWM(err.NE.0,"reading optp%optpwcldeff%pha")
      ELSE
        ALLOCATE (tvalues0(coef_scatt_ir%wcldeff_nphangle,  &
                           coef_scatt_ir%fmv_wcldeff_ndeff, &
                           n_phase_channels), STAT=err)
        READ (file_id, iostat=err) tvalues0(:,:,:)
        THROWM(err.NE.0,"reading optp%optpwcldeff%pha")

        IF (coef_scatt_ir%fmv_wcldeff_pha_chn > 0) THEN
          optp%optpwcldeff%pha(:,:,:) = tvalues0(:,:,phase_ext_index(1:coef_scatt_ir%fmv_wcldeff_pha_chn))
        ENDIF

        DEALLOCATE (tvalues0, STAT=err)
        THROWM(err.NE.0,"deallocation of tvalues0")
      ENDIF
    ENDIF

    IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)

  ENDIF

  DEALLOCATE (list_of_channels)


  CATCH
END SUBROUTINE rttov_read_binary_sccldcoef
