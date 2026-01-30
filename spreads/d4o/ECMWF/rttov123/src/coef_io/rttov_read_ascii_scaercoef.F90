! Description:
!> @file
!!   Read an ASCII aerosol coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read an ASCII aerosol coefficient file, optionally extracting a subset of channels.
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
SUBROUTINE rttov_read_ascii_scaercoef( &
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
  USE rttov_const, ONLY : lensection, errorstatus_fatal
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
#include "rttov_skipcommentline.interface"
#include "rttov_findnextsection.interface"
#include "rttov_nullify_coef_scatt_ir.interface"
#include "rttov_alloc_phfn_int.interface"
#include "rttov_channel_extract_sublist.interface"

  INTEGER(KIND=jpim) :: file_channels
  INTEGER(KIND=jpim) :: n_phase_channels
  LOGICAL(KIND=jplm) :: all_channels
  INTEGER(KIND=jpim) :: io_status
  INTEGER(KIND=jpim) :: i, j, k, n, nrh
  INTEGER(KIND=jpim), ALLOCATABLE :: list_of_channels(:)
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_channels(:)     ! Solar channel numbers in original file
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_ext_index(:)    ! Indexes of phase data to extract

  REAL(KIND=jprb),    POINTER :: abs_aer_array(:,:)
  REAL(KIND=jprb),    POINTER :: sca_aer_array(:,:)
  REAL(KIND=jprb),    POINTER :: bpr_aer_array(:,:)
  INTEGER(KIND=jpim), POINTER :: nmom_aer_array(:,:)
  REAL(KIND=jprb),    POINTER :: legcoef_aer_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: pha_aer_array(:,:,:)
  CHARACTER(LEN=32)           :: aer_comp_name
  CHARACTER(LEN=lensection)   :: section
!- End of header --------------------------------------------------------
  TRY

  all_channels = .NOT. PRESENT(channels)

  readfile : DO
    CALL rttov_findnextsection(file_id, io_status, section)
    IF (io_status < 0) EXIT !end-of-file

    SELECT CASE (TRIM(section))

    CASE ('WATERCLOUD_TYPES')
      ! Aerosol/cloud files have very similar formats which could cause confusion
      ! (reported by v12 beta tester). This check helps prevent that.
      err = errorstatus_fatal
      THROWM(err.NE.0, "Trying to read cloud coefficient file as an aerosol file")

    CASE ('AEROSOLS_COMPONENTS')

      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Number of channels for which optical parameters are stored
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_aer_chn
      THROWM(err.NE.0, "io status while reading section "//section)

      IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_aer_chn) THEN
        err = errorstatus_fatal
        THROWM(err.NE.0, "Incompatible channels between rtcoef and scaercoef files")
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

      ! Number of channels for which phase functions are stored
      READ (file_id,  * , iostat=err) n_phase_channels
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Max number of Leg. coefs stored for each phase function
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_aer_maxnmom
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Sort out the solar channels/phase functions
      IF (n_phase_channels > 0) THEN

        ! Read the solar channel numbers
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(phase_channels(n_phase_channels))
        READ (file_id,  *, iostat=err) phase_channels(:)
        THROWM(err.NE.0, "io status while reading section "//section)

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

        ! At this point:
        !   n_phase_channels                  = total number of solar channels in file
        !   phase_channels(:)                 = list of solar channel numbers
        !   coef_scatt_ir%fmv_aer_pha_chn     = number of solar chans being extracted
        !   coef_scatt_ir%aer_pha_chanlist(:) = list of solar channels to extract from file (indexes into extracted
        !                                         chan list, NOT original channel numbers)
        !   phase_ext_index(:)                = list of indexes into the phase fns which are to be extracted to pha
        !   coef_scatt_ir%aer_pha_index(:)    = indexes for each extracted channel into the pha array

        ! Read phase function angle data
        READ (file_id,  *, iostat=err) coef_scatt_ir%aer_nphangle
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(coef_scatt_ir%aer_phangle(coef_scatt_ir%aer_nphangle), STAT = err)
        THROWM(err.NE.0, "allocation of aer_phangle")
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        READ (file_id,  *, iostat=err) coef_scatt_ir%aer_phangle(:)
        THROWM(err.NE.0, "io status while reading section "//section)

        CALL rttov_alloc_phfn_int(err, coef_scatt_ir%aer_phangle, coef_scatt_ir%aer_phfn_int, 1_jpim)
        THROWM(err.NE.0, "initialisation of coef_scatt_ir%aer_phfn_int")
      ELSE
        coef_scatt_ir%fmv_aer_pha_chn = 0
        coef_scatt_ir%aer_nphangle = 0
      ENDIF

      ! Number of aerosol types
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_aer_comp
      THROWM(err.NE.0, "io status while reading section "//section)

      ALLOCATE (coef_scatt_ir%fmv_aer_comp_name(coef_scatt_ir%fmv_aer_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_aer_comp_name")

      ALLOCATE (coef_scatt_ir%fmv_aer_rh(coef_scatt_ir%fmv_aer_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_aer_rh")

      ALLOCATE (coef_scatt_ir%aer_mmr2nd(coef_scatt_ir%fmv_aer_comp), STAT=err)
      THROWM(err.NE.0,"allocation of aer_mmr2nd")

      ALLOCATE (optp%optpaer(coef_scatt_ir%fmv_aer_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_aer_comp")

      DO n = 1, coef_scatt_ir%fmv_aer_comp
        CALL rttov_nullify_coef_scatt_ir(optp%optpaer(n))

        READ (file_id, '(a5)', iostat=err) aer_comp_name
        THROWM(err.NE.0, "io status while reading section "//section)
        coef_scatt_ir%fmv_aer_comp_name(n) = TRIM(ADJUSTL(aer_comp_name))

        READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_aer_rh(n)
        THROWM(err.NE.0, "io status while reading section "//section)

        ALLOCATE (optp%optpaer(n)%fmv_aer_rh_val(coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optpaer(n)% fmv_aer_rh_val")

        READ (file_id,  * , iostat=err) (optp%optpaer(n)%fmv_aer_rh_val(i), i = 1, coef_scatt_ir%fmv_aer_rh(n))
        THROWM(err.NE.0, "io status while reading section "//section)

        READ (file_id,  * , iostat=err) coef_scatt_ir%aer_mmr2nd(n)
        THROWM(err.NE.0, "io status while reading section "//section)
      ENDDO

      DEALLOCATE (list_of_channels)

    CASE ('AEROSOLS_PARAMETERS')
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      DO n = 1, coef_scatt_ir%fmv_aer_comp
        ALLOCATE (optp%optpaer(n)%abs(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpaer(n)%abs)")

        ALLOCATE (optp%optpaer(n)%sca(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpaer(n)%sca")

        ALLOCATE (optp%optpaer(n)%bpr(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpaer(n)%bpr")

        ALLOCATE (optp%optpaer(n)%nmom(coef_scatt_ir%fmv_aer_chn, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpaer(n)%nmom")

        ALLOCATE (optp%optpaer(n)%legcoef(1:coef_scatt_ir%fmv_aer_maxnmom+1, &
                                          coef_scatt_ir%fmv_aer_chn, &
                                          coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpaer(n)%legcoef")

        IF (coef_scatt_ir%fmv_aer_pha_chn > 0) THEN
          ALLOCATE (optp%optpaer(n)%pha(coef_scatt_ir%aer_nphangle, &
                                        coef_scatt_ir%fmv_aer_pha_chn, &
                                        coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of optp%optpaer(n)%pha")
        ENDIF

        IF (all_channels) THEN
          abs_aer_array => optp%optpaer(n)%abs
          sca_aer_array => optp%optpaer(n)%sca
          bpr_aer_array => optp%optpaer(n)%bpr
          nmom_aer_array => optp%optpaer(n)%nmom
          legcoef_aer_array => optp%optpaer(n)%legcoef
          pha_aer_array => optp%optpaer(n)%pha
        ELSE
          ALLOCATE (abs_aer_array(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of abs_aer_array")

          ALLOCATE (sca_aer_array(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of sca_aer_array")

          ALLOCATE (bpr_aer_array(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of bpr_aer_array")

          ALLOCATE (nmom_aer_array(file_channels, coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of nmom_aer_array")

          ALLOCATE (legcoef_aer_array(1:coef_scatt_ir%fmv_aer_maxnmom+1, file_channels, &
                                      coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of legcoef_aer_array")

          IF (n_phase_channels > 0) THEN
            ALLOCATE (pha_aer_array(coef_scatt_ir%aer_nphangle, n_phase_channels, &
                                    coef_scatt_ir%fmv_aer_rh(n)), STAT = err)
            THROWM(err.NE.0, "allocation of pha_aer_array")
          ENDIF
        ENDIF


        DO nrh = 1, coef_scatt_ir%fmv_aer_rh(n)
          CALL rttov_skipcommentline(file_id, err)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err) aer_comp_name
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err) (abs_aer_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err) (sca_aer_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err) (bpr_aer_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          k = 1
          DO i = 1, file_channels
            READ (file_id,  * , iostat=err) nmom_aer_array(i,nrh)
            THROWM(err.NE.0, "io status while reading nmom_aer_array section "//section)

            legcoef_aer_array(:, i, nrh) = 0
            READ (file_id,  * , iostat=err) (legcoef_aer_array(j,i,nrh), j = 1, nmom_aer_array(i, nrh) + 1)
            THROWM(err.NE.0, "io status while reading legcoef_aer_array section "//section)

            IF (n_phase_channels > 0 .AND. k <= n_phase_channels) THEN
              IF (phase_channels(k) == i) THEN
                READ (file_id,  * , iostat=err) (pha_aer_array(j,k,nrh), j = 1, coef_scatt_ir%aer_nphangle)
                THROWM(err.NE.0, "io status while reading pha_aer_array section "//section)
                k = k + 1
              ENDIF
            ENDIF
          ENDDO
        ENDDO


        IF (.NOT. all_channels) THEN
          optp%optpaer(n)%abs(:,:)  = abs_aer_array(channels(:), :)
          optp%optpaer(n)%sca(:,:)  = sca_aer_array(channels(:), :)
          optp%optpaer(n)%bpr(:,:)  = bpr_aer_array(channels(:), :)
          optp%optpaer(n)%nmom(:,:) = nmom_aer_array(channels(:),:)
          optp%optpaer(n)%legcoef(:,:,:) = legcoef_aer_array(:,channels(:),:)
          IF (coef_scatt_ir%fmv_aer_pha_chn > 0) THEN
            optp%optpaer(n)%pha(:,:,:) = pha_aer_array(:,phase_ext_index(1:coef_scatt_ir%fmv_aer_pha_chn),:)
          ENDIF

          DEALLOCATE (abs_aer_array, STAT = err)
          THROWM(err.NE.0, "deallocation of abs_aer_array")

          DEALLOCATE (sca_aer_array, STAT = err)
          THROWM(err.NE.0, "deallocation of sca_aer_array")

          DEALLOCATE (bpr_aer_array, STAT = err)
          THROWM(err.NE.0, "deallocation of bpr_aer_array")

          DEALLOCATE (nmom_aer_array, STAT = err)
          THROWM(err.NE.0, "deallocation of nmom_aer_array")

          DEALLOCATE (legcoef_aer_array, STAT = err)
          THROWM(err.NE.0, "deallocation of legcoef_aer_array")

          IF (n_phase_channels > 0) THEN
            DEALLOCATE (pha_aer_array, STAT = err)
            THROWM(err.NE.0, "deallocation of pha_aer_array")
          ENDIF
        ENDIF
      ENDDO

      IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)
      IF (ALLOCATED(phase_channels))  DEALLOCATE(phase_channels)

    CASE ('END')
      RETURN
    CASE DEFAULT
      CYCLE readfile
    END SELECT

  ENDDO readfile

  CATCH
END SUBROUTINE rttov_read_ascii_scaercoef
