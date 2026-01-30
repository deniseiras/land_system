! Description:
!> @file
!!   Read an ASCII cloud coefficient file, optionally extracting a subset of channels.
!
!> @brief
!!   Read an ASCII cloud coefficient file, optionally extracting a subset of channels.
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
SUBROUTINE rttov_read_ascii_sccldcoef( &
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
  INTEGER(KIND=jpim) :: i, j, k, n, nrh, ideff
  INTEGER(KIND=jpim), ALLOCATABLE :: list_of_channels(:)
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_channels(:)     ! Solar channel numbers in original file
  INTEGER(KIND=jpim), ALLOCATABLE :: phase_ext_index(:)    ! Indexes of phase data to extract

  REAL(KIND=jprb),    POINTER :: abs_wcl_array(:,:)
  REAL(KIND=jprb),    POINTER :: sca_wcl_array(:,:)
  REAL(KIND=jprb),    POINTER :: bpr_wcl_array(:,:)
  INTEGER(KIND=jpim), POINTER :: nmom_wcl_array(:,:)
  REAL(KIND=jprb),    POINTER :: legcoef_wcl_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: pha_wcl_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: abs_wcldeff_array(:,:)
  REAL(KIND=jprb),    POINTER :: sca_wcldeff_array(:,:)
  REAL(KIND=jprb),    POINTER :: bpr_wcldeff_array(:,:)
  INTEGER(KIND=jpim), POINTER :: nmom_wcldeff_array(:,:)
  REAL(KIND=jprb),    POINTER :: legcoef_wcldeff_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: pha_wcldeff_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: abs_icl_array(:,:)
  REAL(KIND=jprb),    POINTER :: sca_icl_array(:,:)
  REAL(KIND=jprb),    POINTER :: bpr_icl_array(:,:)
  INTEGER(KIND=jpim), POINTER :: nmom_icl_array(:,:)
  REAL(KIND=jprb),    POINTER :: legcoef_icl_array(:,:,:)
  REAL(KIND=jprb),    POINTER :: pha_icl_array(:,:,:)
  CHARACTER(LEN=32)           :: wcl_comp_name
  CHARACTER(LEN=lensection)   :: section
!- End of header --------------------------------------------------------
  TRY

  all_channels = .NOT. PRESENT(channels)

  readfile : DO
    CALL rttov_findnextsection(file_id, io_status, section)
    IF (io_status < 0) EXIT !end-of-file

    SELECT CASE (TRIM(section))

    CASE ('AEROSOLS_COMPONENTS')
      ! Aerosol/cloud files have very similar formats which could cause confusion
      ! (reported by v12 beta tester). This check helps prevent that.
      err = errorstatus_fatal
      THROWM(err.NE.0, "Trying to read aerosol coefficient file as a cloud file")

    CASE ('WATERCLOUD_TYPES')

      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Number of channels for which optical parameters are stored
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcl_chn
      THROWM(err.NE.0, "io status while reading section "//section)

      IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_wcl_chn) THEN
        err = errorstatus_fatal
        THROWM(err.NE.0, "Incompatible channels between rtcoef and sccldcoef files")
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

      ! Number of channels for which phase functions are stored
      READ (file_id,  * , iostat=err) n_phase_channels
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Max number of Leg. coefs stored for each phase function
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcl_maxnmom
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
              coef_scatt_ir%fmv_wcl_pha_chn,  &
              coef_scatt_ir%wcl_pha_chanlist, &
              coef_scatt_ir%wcl_pha_index,    &
              phase_ext_index)
        THROW(err.NE.0)

        ! At this point:
        !   n_phase_channels                  = total number of solar channels in file
        !   phase_channels(:)                 = list of solar channel numbers
        !   coef_scatt_ir%fmv_wcl_pha_chn     = number of solar chans being extracted
        !   coef_scatt_ir%wcl_pha_chanlist(:) = list of solar channels to extract from file (indexes into extracted
        !                                         chan list, NOT original channel numbers)
        !   phase_ext_index(:)                = list of indexes into the phase fns which are to be extracted to pha
        !   coef_scatt_ir%wcl_pha_index(:)    = indexes for each extracted channel into the pha array

        ! Read phase function angle data
        READ (file_id,  *, iostat=err) coef_scatt_ir%wcl_nphangle
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(coef_scatt_ir%wcl_phangle(coef_scatt_ir%wcl_nphangle), STAT = err)
        THROWM(err.NE.0, "allocation of wcl_phangle")
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        READ (file_id,  *, iostat=err) coef_scatt_ir%wcl_phangle(:)
        THROWM(err.NE.0, "io status while reading section "//section)

        CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcl_phangle, coef_scatt_ir%wcl_phfn_int, 1_jpim)
        THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcl_phfn_int")

      ELSE
        coef_scatt_ir%fmv_wcl_pha_chn = 0
        coef_scatt_ir%wcl_nphangle = 0
      ENDIF

      ! Number of water cloud types
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcl_comp
      THROWM(err.NE.0, "io status while reading section "//section)

      ALLOCATE (coef_scatt_ir%fmv_wcl_comp_name(coef_scatt_ir%fmv_wcl_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_wcl_comp_name")

      ALLOCATE (coef_scatt_ir%fmv_wcl_rh(coef_scatt_ir%fmv_wcl_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_wcl_rh")

      ALLOCATE (coef_scatt_ir%confac(coef_scatt_ir%fmv_wcl_comp), STAT = err)
      THROWM(err.NE.0, "allocation of confac")

      ALLOCATE (optp%optpwcl(coef_scatt_ir%fmv_wcl_comp), STAT = err)
      THROWM(err.NE.0, "allocation of fmv_wcl_comp")

      DO n = 1, coef_scatt_ir%fmv_wcl_comp
        CALL rttov_nullify_coef_scatt_ir(optp%optpwcl(n))

        READ (file_id, '(a5)', iostat=err) wcl_comp_name
        THROWM(err.NE.0, "io status while reading section "//section)
        coef_scatt_ir%fmv_wcl_comp_name(n) = TRIM(ADJUSTL(wcl_comp_name))

        READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcl_rh(n)
        THROWM(err.NE.0, "io status while reading section "//section)

        ALLOCATE (optp%optpwcl(n)%fmv_wcl_rh_val(coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of fmv_wcl_rh_val")

        READ (file_id,  * , iostat=err) (optp%optpwcl(n)%fmv_wcl_rh_val(i), i = 1, coef_scatt_ir%fmv_wcl_rh(n))
        THROWM(err.NE.0, "io status while reading section "//section)

        READ (file_id,  * , iostat=err) coef_scatt_ir%confac(n)
        THROWM(err.NE.0, "io status while reading section "//section)
      ENDDO

      DEALLOCATE (list_of_channels)

    CASE ('WATERCLOUD_PARAMETERS')
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      DO n = 1, coef_scatt_ir%fmv_wcl_comp
        ALLOCATE (optp%optpwcl(n)%abs(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optpwcl(n)%abs")

        ALLOCATE (optp%optpwcl(n)%sca(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optpwcl(n)%sca")

        ALLOCATE (optp%optpwcl(n)%bpr(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optpwcl(n)%bpr")

        ALLOCATE (optp%optpwcl(n)%nmom(coef_scatt_ir%fmv_wcl_chn, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpwcl(n)%nmom")

        ALLOCATE (optp%optpwcl(n)%legcoef(1:coef_scatt_ir%fmv_wcl_maxnmom+1, &
                                          coef_scatt_ir%fmv_wcl_chn, &
                                          coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpwcl(n)%legcoef")

        IF (coef_scatt_ir%fmv_wcl_pha_chn > 0) THEN
          ALLOCATE (optp%optpwcl(n)%pha(coef_scatt_ir%wcl_nphangle, &
                                        coef_scatt_ir%fmv_wcl_pha_chn, &
                                        coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of optp%optpwcl(n)%pha")
        ENDIF

        IF (all_channels) THEN
          abs_wcl_array => optp%optpwcl(n)%abs
          sca_wcl_array => optp%optpwcl(n)%sca
          bpr_wcl_array => optp%optpwcl(n)%bpr
          nmom_wcl_array => optp%optpwcl(n)%nmom
          legcoef_wcl_array => optp%optpwcl(n)%legcoef
          pha_wcl_array => optp%optpwcl(n)%pha
        ELSE
          ALLOCATE (abs_wcl_array(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of abs_wcl_array")

          ALLOCATE (sca_wcl_array(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of sca_wcl_array")

          ALLOCATE (bpr_wcl_array(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of bpr_wcl_array")

          ALLOCATE (nmom_wcl_array(file_channels, coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of nmom_wcl_array")

          ALLOCATE (legcoef_wcl_array(1:coef_scatt_ir%fmv_wcl_maxnmom+1, file_channels, &
                                      coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
          THROWM(err.NE.0, "allocation of legcoef_wcl_array")

          IF (n_phase_channels > 0) THEN
            ALLOCATE (pha_wcl_array(coef_scatt_ir%wcl_nphangle, n_phase_channels, &
                                    coef_scatt_ir%fmv_wcl_rh(n)), STAT = err)
            THROWM(err.NE.0, "allocation of pha_wcl_array")
          ENDIF
        ENDIF


        DO nrh = 1, coef_scatt_ir%fmv_wcl_rh(n)
          CALL rttov_skipcommentline(file_id, err)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err)wcl_comp_name
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err)(abs_wcl_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err)(sca_wcl_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          READ (file_id,  * , iostat=err)(bpr_wcl_array(i,nrh), i = 1, file_channels)
          THROWM(err.NE.0, "io status while reading section "//section)

          k = 1
          DO i = 1, file_channels
            READ (file_id,  * , iostat=err) nmom_wcl_array(i,nrh)
            THROWM(err.NE.0, "io status while reading nmom_wcl_array section "//section)

            legcoef_wcl_array(:, i, nrh) = 0
            READ (file_id,  * , iostat=err) (legcoef_wcl_array(j,i,nrh), j = 1, nmom_wcl_array(i, nrh) + 1)
            THROWM(err.NE.0, "io status while reading legcoef_wcl_array section "//section)

            IF (n_phase_channels > 0 .AND. k <= n_phase_channels) THEN
              IF (phase_channels(k) == i) THEN
                READ (file_id,  * , iostat=err) (pha_wcl_array(j,k,nrh), j = 1, coef_scatt_ir%wcl_nphangle)
                THROWM(err.NE.0, "io status while reading pha_wcl_array section "//section)
                k = k + 1
              ENDIF
            ENDIF
          ENDDO
        ENDDO

        IF (.NOT. all_channels) THEN
          optp%optpwcl(n)%abs(:,:)  = abs_wcl_array(channels(:), :)
          optp%optpwcl(n)%sca(:,:)  = sca_wcl_array(channels(:), :)
          optp%optpwcl(n)%bpr(:,:)  = bpr_wcl_array(channels(:), :)
          optp%optpwcl(n)%nmom(:,:) = nmom_wcl_array(channels(:),:)
          optp%optpwcl(n)%legcoef(:,:,:) = legcoef_wcl_array(:,channels(:),:)
          IF (coef_scatt_ir%fmv_wcl_pha_chn > 0) THEN
            optp%optpwcl(n)%pha(:,:,:) = pha_wcl_array(:,phase_ext_index(1:coef_scatt_ir%fmv_wcl_pha_chn),:)
          ENDIF

          DEALLOCATE (abs_wcl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of abs_wcl_array")

          DEALLOCATE (sca_wcl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of sca_wcl_array")

          DEALLOCATE (bpr_wcl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of bpr_wcl_array")

          DEALLOCATE (nmom_wcl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of nmom_wcl_array")

          DEALLOCATE (legcoef_wcl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of legcoef_wcl_array")

          IF (n_phase_channels > 0) THEN
            DEALLOCATE (pha_wcl_array, STAT = err)
            THROWM(err.NE.0, "deallocation of pha_wcl_array")
          ENDIF
        ENDIF
      ENDDO

      IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)
      IF (ALLOCATED(phase_channels))  DEALLOCATE(phase_channels)


!-------------------------------------------------------
    CASE ('WATERCLOUD_DEFF_TYPES')

      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Number of channels for which optical parameters are stored
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcldeff_chn
      THROWM(err.NE.0, "io status while reading section "//section)

      IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_wcldeff_chn) THEN
        err = errorstatus_fatal
        THROWM(err.NE.0, "Incompatible channels between rtcoef and sccldcoef files")
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
      ! coef_scatt_ir%fmv_wcldeff_chn is the number of channels that the user requests
      file_channels = coef_scatt_ir%fmv_wcldeff_chn

      IF (.NOT. all_channels) THEN
        coef_scatt_ir%fmv_wcldeff_chn = SIZE(channels)
      ENDIF

      ! Number of channels for which phase functions are stored
      READ (file_id,  * , iostat=err) n_phase_channels
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Max number of Leg. coefs stored for each phase function
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcldeff_maxnmom
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Sort out the solar channels/phase functions
      IF (n_phase_channels > 0) THEN

        ! Read the solar channel numbers
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(phase_channels(n_phase_channels))
        READ (file_id,  * , iostat=err) phase_channels(:)
        THROWM(err.NE.0, "io status while reading section "//section)

        ! Determine solar channels/phase functions to be extracted
        ALLOCATE (phase_ext_index(n_phase_channels))
        CALL rttov_channel_extract_sublist( &
              err,                                &
              phase_channels,                     &
              list_of_channels,                   &
              coef_scatt_ir%fmv_wcldeff_pha_chn,  &
              coef_scatt_ir%wcldeff_pha_chanlist, &
              coef_scatt_ir%wcldeff_pha_index,    &
              phase_ext_index)
        THROW(err.NE.0)

        ! At this point:
        !   n_phase_channels                      = total number of solar channels in file
        !   phase_channels(:)                     = list of solar channel numbers
        !   coef_scatt_ir%fmv_wcldeff_pha_chn     = number of solar chans being extracted
        !   coef_scatt_ir%wcldeff_pha_chanlist(:) = list of solar channels to extract from file (indexes into extracted
        !                                         chan list, NOT original channel numbers)
        !   phase_ext_index(:)                    = list of indexes into the phase fns which are to be extracted to pha
        !   coef_scatt_ir%wcldeff_pha_index(:)    = indexes for each extracted channel into the pha array

        ! Read phase function angle data
        READ (file_id,  *, iostat=err) coef_scatt_ir%wcldeff_nphangle
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(coef_scatt_ir%wcldeff_phangle(coef_scatt_ir%wcldeff_nphangle), STAT = err)
        THROWM(err.NE.0, "allocation of wcldeff_phangle")
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        READ (file_id,  *, iostat=err) coef_scatt_ir%wcldeff_phangle(:)
        THROWM(err.NE.0, "io status while reading section "//section)

        CALL rttov_alloc_phfn_int(err, coef_scatt_ir%wcldeff_phangle, coef_scatt_ir%wcldeff_phfn_int, 1_jpim)
        THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcldeff_phfn_int")

      ELSE
        coef_scatt_ir%fmv_wcldeff_pha_chn = 0
      ENDIF

      ! Allocate optical parameter structure
      ALLOCATE(optp%optpwcldeff, STAT = err)
      THROWM(err.NE.0, "allocation of optpwcldeff")
      CALL rttov_nullify_coef_scatt_ir(optp%optpwcldeff)

      ! Number of effective diameters
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_wcldeff_ndeff
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Read effective diameter list
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)
      ALLOCATE(optp%optpwcldeff%fmv_wcldeff_deff(coef_scatt_ir%fmv_wcldeff_ndeff))
      READ (file_id,  * , iostat=err) optp%optpwcldeff%fmv_wcldeff_deff(:)
      THROWM(err.NE.0, "io status while reading section "//section)
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      DEALLOCATE (list_of_channels)

    CASE ('WATERCLOUD_DEFF_PARAMETERS')
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Allocate arrays for optical parameters
      ALLOCATE (optp%optpwcldeff%abs(coef_scatt_ir%fmv_wcldeff_ndeff,coef_scatt_ir%fmv_wcldeff_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpwcldeff % abs")

      ALLOCATE (optp%optpwcldeff%sca(coef_scatt_ir%fmv_wcldeff_ndeff,coef_scatt_ir%fmv_wcldeff_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpwcldeff % sca")

      ALLOCATE (optp%optpwcldeff%bpr(coef_scatt_ir%fmv_wcldeff_ndeff,coef_scatt_ir%fmv_wcldeff_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpwcldeff % bpr")

      ALLOCATE (optp%optpwcldeff%nmom(1, coef_scatt_ir%fmv_wcldeff_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optp%optpwcldeff%nmom")

      ALLOCATE (optp%optpwcldeff%legcoef(1:coef_scatt_ir%fmv_wcldeff_maxnmom+1, &
                                     coef_scatt_ir%fmv_wcldeff_ndeff, &
                                     coef_scatt_ir%fmv_wcldeff_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optp%optpwcldeff%legcoef")

      IF (coef_scatt_ir%fmv_wcldeff_pha_chn > 0) THEN
        ALLOCATE (optp%optpwcldeff%pha(coef_scatt_ir%wcldeff_nphangle, &
                                   coef_scatt_ir%fmv_wcldeff_ndeff, &
                                   coef_scatt_ir%fmv_wcldeff_pha_chn), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpwcldeff%pha")
      ENDIF

      IF (all_channels) THEN
        abs_wcldeff_array => optp%optpwcldeff%abs
        sca_wcldeff_array => optp%optpwcldeff%sca
        bpr_wcldeff_array => optp%optpwcldeff%bpr
        nmom_wcldeff_array => optp%optpwcldeff%nmom
        legcoef_wcldeff_array => optp%optpwcldeff%legcoef
        pha_wcldeff_array => optp%optpwcldeff%pha
      ELSE
        ALLOCATE (abs_wcldeff_array(coef_scatt_ir%fmv_wcldeff_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of abs_wcldeff_array")

        ALLOCATE (sca_wcldeff_array(coef_scatt_ir%fmv_wcldeff_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of sca_wcldeff_array")

        ALLOCATE (bpr_wcldeff_array(coef_scatt_ir%fmv_wcldeff_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of bpr_wcldeff_array")

        ALLOCATE (nmom_wcldeff_array(1,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of nmom_wcldeff_array")

        ALLOCATE (legcoef_wcldeff_array(1:coef_scatt_ir%fmv_wcldeff_maxnmom+1, &
                                    coef_scatt_ir%fmv_wcldeff_ndeff, &
                                    file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of legcoef_wcldeff_array")

        IF (n_phase_channels > 0) THEN
          ALLOCATE (pha_wcldeff_array(coef_scatt_ir%wcldeff_nphangle, &
                                  coef_scatt_ir%fmv_wcldeff_ndeff, &
                                  n_phase_channels), STAT = err)
          THROWM(err.NE.0, "allocation of pha_wcldeff_array")
        ENDIF
      ENDIF

      ! Read the optical parameters for all eff. diameters and channels
      READ (file_id,  * , iostat=err) abs_wcldeff_array
      THROW(err.NE.0)

      READ (file_id,  * , iostat=err) sca_wcldeff_array
      THROW(err.NE.0)

      READ (file_id,  * , iostat=err) bpr_wcldeff_array
      THROW(err.NE.0)

      k = 1
      DO i = 1, file_channels
        READ (file_id,  * , iostat=err) nmom_wcldeff_array(1,i)
        THROWM(err.NE.0, "io status while reading nmom_wcldeff_array section "//section)

        legcoef_wcldeff_array(:,:,i) = 0
        DO ideff = 1, coef_scatt_ir%fmv_wcldeff_ndeff
          READ (file_id,  * , iostat=err) (legcoef_wcldeff_array(j,ideff,i), j = 1, nmom_wcldeff_array(1,i)+1)
          THROWM(err.NE.0, "io status while reading legcoef_wcldeff_array section "//section)
        ENDDO

        IF (n_phase_channels > 0 .AND. k <= n_phase_channels) THEN
          IF (phase_channels(k) == i) THEN
            DO ideff = 1, coef_scatt_ir%fmv_wcldeff_ndeff
              READ (file_id,  * , iostat=err) (pha_wcldeff_array(j,ideff,k), j = 1, coef_scatt_ir%wcldeff_nphangle)
              THROWM(err.NE.0, "io status while reading pha_wcldeff_array section "//section)
            ENDDO
            k = k + 1
          ENDIF
        ENDIF
      ENDDO

      IF (.NOT. all_channels) THEN
        optp%optpwcldeff%abs(:,:)  = abs_wcldeff_array(:,channels(:))
        optp%optpwcldeff%sca(:,:)  = sca_wcldeff_array(:,channels(:))
        optp%optpwcldeff%bpr(:,:)  = bpr_wcldeff_array(:,channels(:))
        optp%optpwcldeff%nmom(:,:) = nmom_wcldeff_array(:,channels(:))
        optp%optpwcldeff%legcoef(:,:,:) = legcoef_wcldeff_array(:,:,channels(:))
        IF (coef_scatt_ir%fmv_wcldeff_pha_chn > 0) THEN
          optp%optpwcldeff%pha(:,:,:) = pha_wcldeff_array(:,:,phase_ext_index(1:coef_scatt_ir%fmv_wcldeff_pha_chn))
        ENDIF

        DEALLOCATE (abs_wcldeff_array, STAT = err)
        THROWM(err.NE.0, "deallocation of abs_wcldeff_array")

        DEALLOCATE (sca_wcldeff_array, STAT = err)
        THROWM(err.NE.0, "deallocation of sca_wcldeff_array")

        DEALLOCATE (bpr_wcldeff_array, STAT = err)
        THROWM(err.NE.0, "deallocation of bpr_wcldeff_array")

        DEALLOCATE (nmom_wcldeff_array, STAT = err)
        THROWM(err.NE.0, "deallocation of nmom_wcldeff_array")

        DEALLOCATE (legcoef_wcldeff_array, STAT = err)
        THROWM(err.NE.0, "deallocation of legcoef_wcldeff_array")

        IF (n_phase_channels > 0) THEN
          DEALLOCATE (pha_wcldeff_array, STAT = err)
          THROWM(err.NE.0, "deallocation of pha_wcldeff_array")
        ENDIF
      ENDIF

      IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)
      IF (ALLOCATED(phase_channels))  DEALLOCATE(phase_channels)


!-------------------------------------------------------
    CASE ('ICECLOUD_TYPES')

      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Number of channels for which optical parameters are stored
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_icl_chn
      THROWM(err.NE.0, "io status while reading section "//section)

      IF (coef%fmv_ori_nchn /= coef_scatt_ir%fmv_icl_chn) THEN
        err = errorstatus_fatal
        THROWM(err.NE.0, "Incompatible channels between rtcoef and sccldcoef files")
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
      ! coef_scatt_ir%fmv_icl_chn is the number of channels that the user requests
      file_channels = coef_scatt_ir%fmv_icl_chn

      IF (.NOT. all_channels) THEN
        coef_scatt_ir%fmv_icl_chn = SIZE(channels)
      ENDIF

      ! Number of channels for which phase functions are stored
      READ (file_id,  * , iostat=err) n_phase_channels
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Max number of Leg. coefs stored for each phase function
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_icl_maxnmom
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Sort out the solar channels/phase functions
      IF (n_phase_channels > 0) THEN

        ! Read the solar channel numbers
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(phase_channels(n_phase_channels))
        READ (file_id,  * , iostat=err) phase_channels(:)
        THROWM(err.NE.0, "io status while reading section "//section)

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

        ! At this point:
        !   n_phase_channels                  = total number of solar channels in file
        !   phase_channels(:)                 = list of solar channel numbers
        !   coef_scatt_ir%fmv_icl_pha_chn     = number of solar chans being extracted
        !   coef_scatt_ir%icl_pha_chanlist(:) = list of solar channels to extract from file (indexes into extracted
        !                                         chan list, NOT original channel numbers)
        !   phase_ext_index(:)                = list of indexes into the phase fns which are to be extracted to pha
        !   coef_scatt_ir%icl_pha_index(:)    = indexes for each extracted channel into the pha array

        ! Read phase function angle data
        READ (file_id,  *, iostat=err) coef_scatt_ir%icl_nphangle
        THROWM(err.NE.0, "io status while reading section "//section)
        ALLOCATE(coef_scatt_ir%icl_phangle(coef_scatt_ir%icl_nphangle), STAT = err)
        THROWM(err.NE.0, "allocation of icl_phangle")
        CALL rttov_skipcommentline(file_id, err)
        THROWM(err.NE.0, "io status while reading section "//section)
        READ (file_id,  *, iostat=err) coef_scatt_ir%icl_phangle(:)
        THROWM(err.NE.0, "io status while reading section "//section)

        CALL rttov_alloc_phfn_int(err, coef_scatt_ir%icl_phangle, coef_scatt_ir%icl_phfn_int, 1_jpim)
        THROWM(err.NE.0, "initialisation of coef_scatt_ir%icl_phfn_int")

      ELSE
        coef_scatt_ir%fmv_icl_pha_chn = 0
      ENDIF

      ! Allocate optical parameter structure
      ALLOCATE(optp%optpicl, STAT = err)
      THROWM(err.NE.0, "allocation of optpicl")
      CALL rttov_nullify_coef_scatt_ir(optp%optpicl)

      ! Number of effective diameters
      READ (file_id,  * , iostat=err) coef_scatt_ir%fmv_icl_ndeff
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Read effective diameter list
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)
      ALLOCATE(optp%optpicl%fmv_icl_deff(coef_scatt_ir%fmv_icl_ndeff))
      READ (file_id,  * , iostat=err) optp%optpicl%fmv_icl_deff(:)
      THROWM(err.NE.0, "io status while reading section "//section)
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      DEALLOCATE (list_of_channels)


    CASE ('ICECLOUD_PARAMETERS')
      CALL rttov_skipcommentline(file_id, err)
      THROWM(err.NE.0, "io status while reading section "//section)

      ! Allocate arrays for optical parameters
      ALLOCATE (optp%optpicl%abs(coef_scatt_ir%fmv_icl_ndeff,coef_scatt_ir%fmv_icl_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpicl % abs")

      ALLOCATE (optp%optpicl%sca(coef_scatt_ir%fmv_icl_ndeff,coef_scatt_ir%fmv_icl_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpicl % sca")

      ALLOCATE (optp%optpicl%bpr(coef_scatt_ir%fmv_icl_ndeff,coef_scatt_ir%fmv_icl_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optpicl % bpr")

      ALLOCATE (optp%optpicl%nmom(1, coef_scatt_ir%fmv_icl_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optp%optpicl%nmom")

      ALLOCATE (optp%optpicl%legcoef(1:coef_scatt_ir%fmv_icl_maxnmom+1, &
                                     coef_scatt_ir%fmv_icl_ndeff, &
                                     coef_scatt_ir%fmv_icl_chn), STAT = err)
      THROWM(err.NE.0, "allocation of optp%optpicl%legcoef")

      IF (coef_scatt_ir%fmv_icl_pha_chn > 0) THEN
        ALLOCATE (optp%optpicl%pha(coef_scatt_ir%icl_nphangle, &
                                   coef_scatt_ir%fmv_icl_ndeff, &
                                   coef_scatt_ir%fmv_icl_pha_chn), STAT = err)
        THROWM(err.NE.0, "allocation of optp%optpicl%pha")
      ENDIF

      IF (all_channels) THEN
        abs_icl_array => optp%optpicl%abs
        sca_icl_array => optp%optpicl%sca
        bpr_icl_array => optp%optpicl%bpr
        nmom_icl_array => optp%optpicl%nmom
        legcoef_icl_array => optp%optpicl%legcoef
        pha_icl_array => optp%optpicl%pha
      ELSE
        ALLOCATE (abs_icl_array(coef_scatt_ir%fmv_icl_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of abs_icl_array")

        ALLOCATE (sca_icl_array(coef_scatt_ir%fmv_icl_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of sca_icl_array")

        ALLOCATE (bpr_icl_array(coef_scatt_ir%fmv_icl_ndeff,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of bpr_icl_array")

        ALLOCATE (nmom_icl_array(1,file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of nmom_icl_array")

        ALLOCATE (legcoef_icl_array(1:coef_scatt_ir%fmv_icl_maxnmom+1, &
                                    coef_scatt_ir%fmv_icl_ndeff, &
                                    file_channels), STAT = err)
        THROWM(err.NE.0, "allocation of legcoef_icl_array")

        IF (n_phase_channels > 0) THEN
          ALLOCATE (pha_icl_array(coef_scatt_ir%icl_nphangle, &
                                  coef_scatt_ir%fmv_icl_ndeff, &
                                  n_phase_channels), STAT = err)
          THROWM(err.NE.0, "allocation of pha_icl_array")
        ENDIF
      ENDIF

      ! Read the optical parameters for all eff. diameters and channels
      READ (file_id,  * , iostat=err) abs_icl_array
      THROW(err.NE.0)

      READ (file_id,  * , iostat=err) sca_icl_array
      THROW(err.NE.0)

      READ (file_id,  * , iostat=err) bpr_icl_array
      THROW(err.NE.0)

      k = 1
      DO i = 1, file_channels
        READ (file_id,  * , iostat=err) nmom_icl_array(1,i)
        THROWM(err.NE.0, "io status while reading nmom_icl_array section "//section)

        legcoef_icl_array(:,:,i) = 0
        DO ideff = 1, coef_scatt_ir%fmv_icl_ndeff
          READ (file_id,  * , iostat=err) (legcoef_icl_array(j,ideff,i), j = 1, nmom_icl_array(1,i)+1)
          THROWM(err.NE.0, "io status while reading legcoef_icl_array section "//section)
        ENDDO

        IF (n_phase_channels > 0 .AND. k <= n_phase_channels) THEN
          IF (phase_channels(k) == i) THEN
            DO ideff = 1, coef_scatt_ir%fmv_icl_ndeff
              READ (file_id,  * , iostat=err) (pha_icl_array(j,ideff,k), j = 1, coef_scatt_ir%icl_nphangle)
              THROWM(err.NE.0, "io status while reading pha_icl_array section "//section)
            ENDDO
            k = k + 1
          ENDIF
        ENDIF
      ENDDO

      IF (.NOT. all_channels) THEN
        optp%optpicl%abs(:,:)  = abs_icl_array(:,channels(:))
        optp%optpicl%sca(:,:)  = sca_icl_array(:,channels(:))
        optp%optpicl%bpr(:,:)  = bpr_icl_array(:,channels(:))
        optp%optpicl%nmom(:,:) = nmom_icl_array(:,channels(:))
        optp%optpicl%legcoef(:,:,:) = legcoef_icl_array(:,:,channels(:))
        IF (coef_scatt_ir%fmv_icl_pha_chn > 0) THEN
          optp%optpicl%pha(:,:,:) = pha_icl_array(:,:,phase_ext_index(1:coef_scatt_ir%fmv_icl_pha_chn))
        ENDIF

        DEALLOCATE (abs_icl_array, STAT = err)
        THROWM(err.NE.0, "deallocation of abs_icl_array")

        DEALLOCATE (sca_icl_array, STAT = err)
        THROWM(err.NE.0, "deallocation of sca_icl_array")

        DEALLOCATE (bpr_icl_array, STAT = err)
        THROWM(err.NE.0, "deallocation of bpr_icl_array")

        DEALLOCATE (nmom_icl_array, STAT = err)
        THROWM(err.NE.0, "deallocation of nmom_icl_array")

        DEALLOCATE (legcoef_icl_array, STAT = err)
        THROWM(err.NE.0, "deallocation of legcoef_icl_array")

        IF (n_phase_channels > 0) THEN
          DEALLOCATE (pha_icl_array, STAT = err)
          THROWM(err.NE.0, "deallocation of pha_icl_array")
        ENDIF
      ENDIF

      IF (ALLOCATED(phase_ext_index)) DEALLOCATE(phase_ext_index)
      IF (ALLOCATED(phase_channels))  DEALLOCATE(phase_channels)

    CASE ('END')
      RETURN
    CASE DEFAULT
      CYCLE readfile
    END SELECT

  ENDDO readfile

  CATCH
END SUBROUTINE rttov_read_ascii_sccldcoef
