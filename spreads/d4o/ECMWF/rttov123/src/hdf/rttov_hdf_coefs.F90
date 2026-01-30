! Description:
!> @file
!!   Subroutines for HDF5 I/O of coefs structure
!
!> @brief
!!   Subroutines for HDF5 I/O of coefs structure
!!
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
     MODULE RTTOV_HDF_COEFS
#include "throw.h"
      USE RTTOV_TYPES
      USE RTTOV_HDF_MOD
      USE HDF5, only : HID_T
      USE H5LT

      USE RTTOV_CONST, ONLY :  &
        & gas_id_mixed,           &
        & gas_id_watervapour,     &
        & gas_id_ozone,           &
        & gas_id_wvcont,          &
        & gas_id_co2,             &
        & gas_id_n2o,             &
        & gas_id_co,              &
        & gas_id_ch4,             &
        & gas_id_so2

      USE RTTOV_FAST_COEF_UTILS_MOD, ONLY : set_pointers
!
      IMPLICIT NONE
#include "rttov_errorreport.interface"
#include "rttov_alloc_phfn_int.interface"

      PRIVATE
      PUBLIC :: RTTOV_HDF_COEF_WH,       RTTOV_HDF_COEF_RH
      PUBLIC :: RTTOV_HDF_SCCLDCOEF_WH,  RTTOV_HDF_SCCLDCOEF_RH
      PUBLIC :: RTTOV_HDF_SCAERCOEF_WH,  RTTOV_HDF_SCAERCOEF_RH
      PUBLIC :: RTTOV_HDF_PCCOEF_WH,     RTTOV_HDF_PCCOEF_RH
      PUBLIC :: RTTOV_HDF_MFASISCOEF_WH, RTTOV_HDF_MFASISCOEF_RH

      CONTAINS

!> Write an optical depth coefficient structure to HDF5 file
!! param[in]  x             optical depth coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_COEF_WH(X,LUN,ERR,COMPRESS,FORCE_DOUBLE)
USE RTTOV_HDF_RTTOV_COEF_IO
USE RTTOV_HDF_RTTOV_FAST_COEF_IO
USE RTTOV_HDF_RTTOV_NLTE_COEF_IO

      TYPE(RTTOV_COEF),INTENT(IN)    ::X
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

!
      INTEGER(HID_T) :: G_ID_SUB

      TYPE(rttov_fast_coef_hdf_io) :: FAST_COEF_temp
!
TRY

        CALL RTTOV_HDF_RTTOV_COEF_WH( x, LUN, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE)
        THROWM(ERR.NE.0,"CANNOT WRITE COEF")

        CALL H5LTSET_ATTRIBUTE_STRING_F(LUN, '.', "Description",   &
        "This is a RTTOV coefficient structure" // &
        CHAR(0), ERR )
        THROWM(ERR.NE.0,"CANNOT WRITE ATTRIBUTE")

        CALL MKPAR( LUN, "THERMAL", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP THERMAL")

! Move fast_coef structure in to temp for writing

        IF (x%ncmixed > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%mixedgas, gas_id_mixed)
        IF (x%ncwater > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%watervapour, gas_id_watervapour)
        IF (x%ncozone > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%ozone, gas_id_ozone)
        IF (x%ncwvcont > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%wvcont, gas_id_wvcont)
        IF (x%ncco2 > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%co2, gas_id_co2)
        IF (x%ncn2o > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%n2o, gas_id_n2o)
        IF (x%ncco > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%co, gas_id_co)
        IF (x%ncch4 > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%ch4, gas_id_ch4)
        IF (x%ncso2 > 0_jpim ) &
          CALL move_fast_coef_hdf(x, x%thermal(:), FAST_COEF_temp%so2, gas_id_so2)

        CALL RTTOV_HDF_RTTOV_FAST_COEF_WH( FAST_COEF_temp, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
        THROWM(ERR.NE.0,"CANNOT WRITE THERMAL COEFFICIENTS")

        IF (x%ncmixed > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%mixedgas)    ; NULLIFY(FAST_COEF_temp%mixedgas)
        IF (x%ncwater > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%watervapour) ; NULLIFY(FAST_COEF_temp%watervapour)
        IF (x%ncozone > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%ozone)       ; NULLIFY(FAST_COEF_temp%ozone)
        IF (x%ncwvcont > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%wvcont)      ; NULLIFY(FAST_COEF_temp%wvcont)
        IF (x%ncco2 > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%co2)         ; NULLIFY(FAST_COEF_temp%co2)
        IF (x%ncn2o > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%n2o)         ; NULLIFY(FAST_COEF_temp%n2o)
        IF (x%ncco > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%co)          ; NULLIFY(FAST_COEF_temp%co)
        IF (x%ncch4 > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%ch4)         ; NULLIFY(FAST_COEF_temp%ch4)
        IF (x%ncso2 > 0_jpim ) &
          DEALLOCATE(FAST_COEF_temp%so2)         ; NULLIFY(FAST_COEF_temp%so2)

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP THERMAL")

        IF( ASSOCIATED( x%SOLAR ) .AND. x%SOLARCOEF ) THEN
          CALL MKPAR( LUN, "SOLAR", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP SOLAR")

          IF (x%ncmixed > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%mixedgas, gas_id_mixed)
          IF (x%ncwater > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%watervapour, gas_id_watervapour)
          IF (x%ncozone > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%ozone, gas_id_ozone)
          IF (x%ncwvcont > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%wvcont, gas_id_wvcont)
          IF (x%ncco2 > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%co2, gas_id_co2)
          IF (x%ncn2o > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%n2o, gas_id_n2o)
          IF (x%ncco > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%co, gas_id_co)
          IF (x%ncch4 > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%ch4, gas_id_ch4)
          IF (x%ncso2 > 0_jpim ) &
            CALL move_fast_coef_hdf(x, x%solar(:), FAST_COEF_temp%so2, gas_id_so2)

          CALL RTTOV_HDF_RTTOV_FAST_COEF_WH( FAST_COEF_temp, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
          THROWM(ERR.NE.0,"CANNOT WRITE SOLAR COEFFICIENTS")

          IF (x%ncmixed > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%mixedgas)    ; NULLIFY(FAST_COEF_temp%mixedgas)
          IF (x%ncwater > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%watervapour) ; NULLIFY(FAST_COEF_temp%watervapour)
          IF (x%ncozone > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%ozone)       ; NULLIFY(FAST_COEF_temp%ozone)
          IF (x%ncwvcont > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%wvcont)      ; NULLIFY(FAST_COEF_temp%wvcont)
          IF (x%ncco2 > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%co2)         ; NULLIFY(FAST_COEF_temp%co2)
          IF (x%ncn2o > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%n2o)         ; NULLIFY(FAST_COEF_temp%n2o)
          IF (x%ncco > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%co)          ; NULLIFY(FAST_COEF_temp%co)
          IF (x%ncch4 > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%ch4)         ; NULLIFY(FAST_COEF_temp%ch4)
          IF (x%ncso2 > 0_jpim ) &
            DEALLOCATE(FAST_COEF_temp%so2)         ; NULLIFY(FAST_COEF_temp%so2)

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP SOLAR")
        ENDIF

        IF( x%NLTECOEF ) THEN
          CALL MKPAR( LUN, "NLTE_COEF", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP NLTE_COEF")

          CALL RTTOV_HDF_RTTOV_NLTE_COEF_WH( x%NLTE_COEF, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
          THROWM(ERR.NE.0,"CANNOT WRITE COEF%NLTE_COEF")

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP NLTE_COEF")
        ENDIF

CATCH
      END SUBROUTINE

!> Write a cloud coefficient structure to HDF5 file
!! param[in]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[in]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_SCCLDCOEF_WH(X, Y, LUN,ERR,COMPRESS,FORCE_DOUBLE)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(IN)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(IN)              :: Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

        CALL H5LTSET_ATTRIBUTE_STRING_F(LUN, '.', "Description",   &
        "This is a RTTOV cloud coefficient structure" // &
        CHAR(0), ERR )
        THROWM(ERR.NE.0,"CANNOT WRITE ATTRIBUTE")

        CALL MKPAR( LUN, "WATERCLOUDS", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP WATERCLOUDS")

        CALL RTTOV_HDF_RTTOV_WATERCLOUDS_WH( x, y, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
        THROWM(ERR.NE.0,"CANNOT WRITE WATERCLOUDS COEFS")

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP WATERCLOUDS")

        IF ( X%FMV_WCLDEFF_CHN > 0 ) THEN
          CALL MKPAR( LUN, "WATERCLOUDS_DEFF", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP WATERCLOUDS_DEFF")

          CALL RTTOV_HDF_RTTOV_WATERCLOUDS_DEFF_WH( x, y, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
          THROWM(ERR.NE.0,"CANNOT WRITE WATERCLOUDS_DEFF COEFS")

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP WATERCLOUDS_DEFF")
        ENDIF

        CALL MKPAR( LUN, "ICECLOUDS", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP ICECLOUDS")

        CALL RTTOV_HDF_RTTOV_ICECLOUDS_WH( x, y, G_ID_SUB, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE )
        THROWM(ERR.NE.0,"CANNOT WRITE ICECLOUDS COEFS")

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP ICECLOUDS")

CATCH
      END SUBROUTINE

!> Write an aerosol coefficient structure to HDF5 file
!! param[in]  x             RTTOV aerosol coef_scatt_ir coefficient structure
!! param[in]  y             RTTOV aerosol optpar_ir coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_SCAERCOEF_WH(X, Y, LUN,ERR,COMPRESS,FORCE_DOUBLE)
USE RTTOV_UNIX_ENV, ONLY : RTTOV_UPPER_CASE

      TYPE(RTTOV_COEF_SCATT_IR), INTENT(IN)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(IN)              :: Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

      INTEGER(KIND=JPIM)    :: I
!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

      CALL H5LTSET_ATTRIBUTE_STRING_F(LUN, '.', "Description",   &
        & "This is a RTTOV aerosol coefficient structure" // &
        & CHAR(0), ERR )
      THROWM(ERR.NE.0,"CANNOT WRITE ATTRIBUTE")

      sname='FMV_AER_CHN'
      call write_array_hdf(lun,sname,&
        & 'Number of channels for which optical parameters are stored',&
        & err,i0=x%FMV_AER_CHN )
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      sname='FMV_AER_PHA_CHN'
      call write_array_hdf(lun,sname,&
        & 'Number of channels for which phase function values are stored',&
        & err,i0=x%FMV_AER_PHA_CHN)
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      sname='FMV_AER_COMP'
      call write_array_hdf(lun,sname,&
        & 'Number of aerosols components',&
        & err,i0=x%FMV_AER_COMP )
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      sname='FMV_AER_MAXNMOM'
      call write_array_hdf(lun,sname,&
        & 'Maximum number of Legendre coefficients for phase functions for aerosols',&
        & err,i0=x%FMV_AER_MAXNMOM )
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      sname='AER_NPHANGLE'
      call write_array_hdf(lun,sname,&
        & 'Number of phase angles for phase functions for aerosols',&
        & err,i0=x%AER_NPHANGLE )
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      if(associated(x%AER_PHA_CHANLIST))then
        sname='AER_PHA_CHANLIST'
        call write_array_hdf(lun,sname,&
          & 'The solar channel indexes',&
          & err,i1=x%aer_pha_chanlist )
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
      endif

      if(associated(x%AER_PHANGLE))then
        sname='AER_PHANGLE'
        call write_array_hdf(lun,sname,&
          & 'The phase function angle grid',&
          & err,r1=x%aer_phangle )
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
      endif

      sname='FMV_AER_RH'
      if(associated(x%FMV_AER_RH))then
        call write_array_hdf(lun,sname,&
          & 'Number of relative humidity values for aerosols',&
          & err,i1=x%FMV_AER_RH )
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
      endif

      sname='AER_MMR2ND'
      if(associated(x%AER_MMR2ND))then
        call write_array_hdf(lun,sname,&
          & 'Conversion from MMR to particle density',&
          & err,r1=x%AER_MMR2ND )
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
      endif

      sname='FMV_AER_COMP_NAME'
      call write_array_hdf(lun,sname,&
        & 'Aerosol names',&
        & err,c1=x%fmv_aer_comp_name)
      THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

      DO I = 1, x%FMV_AER_COMP

        CALL RTTOV_UPPER_CASE(GNAME, x%fmv_aer_comp_name(I))

        CALL MKPAR( LUN, TRIM(GNAME), G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//TRIM(GNAME))

        sname='FMV_AER_RH_VAL'
        if(associated(y%optpaer(i)%FMV_AER_RH_VAL))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Relative humidity for aerosols',&
            & err,r1=y%optpaer(i)%FMV_AER_RH_VAL , units = 'percent')
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='ABS'
        if(associated(y%optpaer(i)%ABS))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Absorption (channels, humidity)',&
            & err,r2=y%optpaer(i)%ABS , units = 'm-1',compress=compress,force_double=force_double)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='SCA'
        if(associated(y%optpaer(i)%SCA))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Scattering (channels, humidity)',&
            & err,r2=y%optpaer(i)%SCA , units = 'm-1',compress=compress,force_double=force_double)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='BPR'
        if(associated(y%optpaer(i)%BPR))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Back scattering factor (channels, humidity or nbpr)',&
            & err,r2=y%optpaer(i)%BPR ,compress=compress,force_double=force_double)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='NMOM'
        if(associated(y%optpaer(i)%NMOM))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Number of Legendre coefficients (channels, humidity)',&
            & err,i2=y%optpaer(i)%NMOM ,compress=compress)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='LEGCOEF'
        if(associated(y%optpaer(i)%LEGCOEF))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Phase function Legendre coefficients (1:maxnmom+1, channels, humidity)',&
            & err,r3=y%optpaer(i)%LEGCOEF ,compress=compress,force_double=force_double)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        sname='PHA'
        if(associated(y%optpaer(i)%PHA))then
          call write_array_hdf(g_id_sub,sname,&
            & 'Phase functions for solar channels (nphangle, channels, humidity)',&
            & err,r3=y%optpaer(i)%PHA ,compress=compress,force_double=force_double)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        endif

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

ENDDO

CATCH
      END SUBROUTINE


!> Write the liquid water cloud section of a cloud coefficient structure to HDF5 file
!! param[in]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[in]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_RTTOV_WATERCLOUDS_WH(X, Y, LUN,ERR,COMPRESS,FORCE_DOUBLE)
USE RTTOV_UNIX_ENV, ONLY : RTTOV_UPPER_CASE
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(IN)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(IN)              :: Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

      INTEGER(KIND=JPIM) :: I

!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM
sname='FMV_WCL_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which optical parameters are stored',&
  & err,i0=x%FMV_WCL_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCL_PHA_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which phase function values are stored',&
  & err,i0=x%FMV_WCL_PHA_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCL_COMP'
call write_array_hdf(lun,sname,&
  & 'Number of water cloud types',&
  & err,i0=x%FMV_WCL_COMP )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCL_MAXNMOM'
call write_array_hdf(lun,sname,&
  & 'Maximum number of Legendre coefficients for phase functions for water clouds',&
  & err,i0=x%FMV_WCL_MAXNMOM )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='WCL_NPHANGLE'
call write_array_hdf(lun,sname,&
  & 'Number of phase angles for phase functions for water clouds',&
  & err,i0=x%WCL_NPHANGLE )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

if(associated(x%WCL_PHA_CHANLIST))then
  sname='WCL_PHA_CHANLIST'
  call write_array_hdf(lun,sname,&
    & 'The solar channel indexes',&
    & err,i1=x%wcl_pha_chanlist )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

if(associated(x%WCL_PHANGLE))then
  sname='WCL_PHANGLE'
  call write_array_hdf(lun,sname,&
    & 'The phase function angle grid',&
    & err,r1=x%wcl_phangle )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

sname='FMV_WCL_RH'
if(associated(x%FMV_WCL_RH))then
  call write_array_hdf(lun,sname,&
    & 'Number of relative humidity for water clouds',&
    & err,i1=x%FMV_WCL_RH )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

sname='CONFAC'
if(associated(x%CONFAC))then
  call write_array_hdf(lun,sname,&
    & 'Conversion from LWC to particle density',&
    & err,r1=x%CONFAC )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

sname='FMV_WCL_COMP_NAME'
call write_array_hdf(lun,sname,&
  & 'Cloud names',&
  & err,c1=x%fmv_wcl_comp_name)

DO I = 1, x%FMV_WCL_COMP

  CALL RTTOV_UPPER_CASE(GNAME, x%fmv_wcl_comp_name(I))

  CALL MKPAR( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//TRIM(GNAME))

  sname='FMV_WCL_RH_VAL'
  if(associated(y%optpwcl(i)%FMV_WCL_RH_VAL))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Relative humidity for water clouds',&
      & err,r1=y%optpwcl(i)%FMV_WCL_RH_VAL , units = 'percent')
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='ABS'
  if(associated(y%optpwcl(i)%ABS))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Absorption (channels, humidity)',&
      & err,r2=y%optpwcl(i)%ABS , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='SCA'
  if(associated(y%optpwcl(i)%SCA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Scattering (channels, humidity)',&
      & err,r2=y%optpwcl(i)%SCA , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='BPR'
  if(associated(y%optpwcl(i)%BPR))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Back scattering factor (channels, humidity)',&
      & err,r2=y%optpwcl(i)%BPR ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='NMOM'
  if(associated(y%optpwcl(i)%NMOM))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Number of Legendre coefficients (channels, humidity)',&
      & err,i2=y%optpwcl(i)%NMOM ,compress=compress)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='LEGCOEF'
  if(associated(y%optpwcl(i)%LEGCOEF))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase function Legendre coefficients (1:maxnmom+1, channels, humidity)',&
      & err,r3=y%optpwcl(i)%LEGCOEF ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='PHA'
  if(associated(y%optpwcl(i)%PHA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase functions for solar channels (nphangle, channels, humidity)',&
      & err,r3=y%optpwcl(i)%PHA ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

ENDDO

err=0_jpim

CATCH
      END SUBROUTINE


!> Write the Deff liquid water cloud section of a cloud coefficient structure to HDF5 file
!! param[in]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[in]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_RTTOV_WATERCLOUDS_DEFF_WH(X, Y, LUN,ERR,COMPRESS,FORCE_DOUBLE)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(IN)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(IN)              :: Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM
sname='FMV_WCLDEFF_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which optical parameters are stored',&
  & err,i0=x%FMV_WCLDEFF_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCLDEFF_PHA_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which phase function values are stored',&
  & err,i0=x%FMV_WCLDEFF_PHA_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCLDEFF_MAXNMOM'
call write_array_hdf(lun,sname,&
  & 'Maximum number of Legendre coefficients for phase functions for Deff water cloud scheme',&
  & err,i0=x%FMV_WCLDEFF_MAXNMOM )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='WCLDEFF_NPHANGLE'
call write_array_hdf(lun,sname,&
  & 'Number of phase angles for phase functions for Deff water cloud scheme',&
  & err,i0=x%WCLDEFF_NPHANGLE )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_WCLDEFF_NDEFF'
call write_array_hdf(lun,sname,&
  & 'Number of effective diameters for Deff water cloud scheme data',&
  & err,i0=x%FMV_WCLDEFF_NDEFF )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

if(associated(x%WCLDEFF_PHA_CHANLIST))then
  sname='WCLDEFF_PHA_CHANLIST'
  call write_array_hdf(lun,sname,&
    & 'The solar channel indexes',&
    & err,i1=x%wcldeff_pha_chanlist )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

if(associated(x%WCLDEFF_PHANGLE))then
  sname='WCLDEFF_PHANGLE'
  call write_array_hdf(lun,sname,&
    & 'The phase function angle grid',&
    & err,r1=x%wcldeff_phangle )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

  GNAME = "DATA"

  CALL MKPAR( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//TRIM(GNAME))

  sname='FMV_WCLDEFF_DEFF'
  if(associated(y%optpwcldeff%FMV_WCLDEFF_DEFF))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Effective diameters',&
      & err,r1=y%optpwcldeff%FMV_WCLDEFF_DEFF(:) , units = 'microns')
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='ABS'
  if(associated(y%optpwcldeff%ABS))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Absorption (channels, nabs)',&
      & err,r2=y%optpwcldeff%ABS , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='SCA'
  if(associated(y%optpwcldeff%SCA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Scattering (channels, nsca)',&
      & err,r2=y%optpwcldeff%SCA , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='BPR'
  if(associated(y%optpwcldeff%BPR))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Back scattering factor (channels, nbpr)',&
      & err,r2=y%optpwcldeff%BPR ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='NMOM'
  if(associated(y%optpwcldeff%NMOM))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Number of Legendre coefficients (channels, 1)',&
      & err,i2=y%optpwcldeff%NMOM ,compress=compress)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='LEGCOEF'
  if(associated(y%optpwcldeff%LEGCOEF))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase function Legendre coefficients (1:maxnmom+1, channels, deff)',&
      & err,r3=y%optpwcldeff%LEGCOEF ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='PHA'
  if(associated(y%optpwcldeff%PHA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase functions for solar channels (nphangle, channels, deff)',&
      & err,r3=y%optpwcldeff%PHA ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

err=0_jpim

CATCH
      END SUBROUTINE


!> Write the ice water cloud section of a cloud coefficient structure to HDF5 file
!! param[in]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[in]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_RTTOV_ICECLOUDS_WH(X, Y, LUN,ERR,COMPRESS,FORCE_DOUBLE)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(IN)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(IN)              :: Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM
sname='FMV_ICL_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which optical parameters are stored',&
  & err,i0=x%FMV_ICL_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_ICL_PHA_CHN'
call write_array_hdf(lun,sname,&
  & 'Number of channels for which phase function values are stored',&
  & err,i0=x%FMV_ICL_PHA_CHN )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_ICL_MAXNMOM'
call write_array_hdf(lun,sname,&
  & 'Maximum number of Legendre coefficients for phase functions for ice clouds',&
  & err,i0=x%FMV_ICL_MAXNMOM )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='ICL_NPHANGLE'
call write_array_hdf(lun,sname,&
  & 'Number of phase angles for phase functions for ice clouds',&
  & err,i0=x%ICL_NPHANGLE )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

sname='FMV_ICL_NDEFF'
call write_array_hdf(lun,sname,&
  & 'Number of effective diameters for ice cloud data',&
  & err,i0=x%FMV_ICL_NDEFF )
THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

if(associated(x%ICL_PHA_CHANLIST))then
  sname='ICL_PHA_CHANLIST'
  call write_array_hdf(lun,sname,&
    & 'The solar channel indexes',&
    & err,i1=x%icl_pha_chanlist )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

if(associated(x%ICL_PHANGLE))then
  sname='ICL_PHANGLE'
  call write_array_hdf(lun,sname,&
    & 'The phase function angle grid',&
    & err,r1=x%icl_phangle )
  THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
endif

  GNAME = "SSEC_ICE"

  CALL MKPAR( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//TRIM(GNAME))

  sname='FMV_ICL_DEFF'
  if(associated(y%optpicl%FMV_ICL_DEFF))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Effective diameters',&
      & err,r1=y%optpicl%FMV_ICL_DEFF(:) , units = 'microns')
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='ABS'
  if(associated(y%optpicl%ABS))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Absorption (channels, nabs)',&
      & err,r2=y%optpicl%ABS , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='SCA'
  if(associated(y%optpicl%SCA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Scattering (channels, nsca)',&
      & err,r2=y%optpicl%SCA , units = 'm-1',compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='BPR'
  if(associated(y%optpicl%BPR))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Back scattering factor (channels, nbpr)',&
      & err,r2=y%optpicl%BPR ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='NMOM'
  if(associated(y%optpicl%NMOM))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Number of Legendre coefficients (channels, 1)',&
      & err,i2=y%optpicl%NMOM ,compress=compress)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='LEGCOEF'
  if(associated(y%optpicl%LEGCOEF))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase function Legendre coefficients (1:maxnmom+1, channels, deff)',&
      & err,r3=y%optpicl%LEGCOEF ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  sname='PHA'
  if(associated(y%optpicl%PHA))then
    call write_array_hdf(g_id_sub,sname,&
      & 'Phase functions for solar channels (nphangle, channels, deff)',&
      & err,r3=y%optpicl%PHA ,compress=compress,force_double=force_double)
    THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

err=0_jpim

CATCH
      END SUBROUTINE

!> Write PC-RTTOV coefficient structure to HDF5 file
!! param[in]  x             PC coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_PCCOEF_WH(X,LUN,ERR,COMPRESS,FORCE_DOUBLE)
USE RTTOV_HDF_RTTOV_COEF_PCC_IO
USE RTTOV_HDF_RTTOV_COEF_PCC1_IO
USE RTTOV_HDF_RTTOV_COEF_PCC2_IO

      TYPE(RTTOV_COEF_PCCOMP),INTENT(IN)    ::X
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
      LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
      LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

      CHARACTER(LEN=LENSH)  :: GNAME, GNAME2
      INTEGER(KIND=JPIM)    :: I, J
!
      INTEGER(HID_T) :: G_ID_SUB, G_ID_SUB2, G_ID_SUB3
!
TRY

        CALL RTTOV_HDF_RTTOV_COEF_PCC_WH(X,LUN,ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE)
        THROWM(ERR.NE.0,"CANNOT WRITE PC COEF")

        CALL H5LTSET_ATTRIBUTE_STRING_F(LUN, '.', "Description",   &
        "This is a RTTOV coefficient structure PCCOMP" // &
        CHAR(0), ERR )
        THROWM(ERR.NE.0,"CANNOT WRITE ATTRIBUTE")

        ! PCREG structure
        CALL MKPAR( LUN, "PCREG", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP PCREG")

        DO J = 1, X%FMV_PC_BANDS
          WRITE(GNAME,'(I2.2)') J
          CALL MKPAR( G_ID_SUB, TRIM(GNAME), G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP PCREG/"//TRIM(GNAME))

          DO I = 1, X%FMV_PC_SETS(J)

            WRITE(GNAME2,'(I2.2)') I
            CALL MKPAR( G_ID_SUB2, TRIM(GNAME2), G_ID_SUB3, ERR )
            THROWM(ERR.NE.0,"CANNOT CREATE GROUP PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

            CALL RTTOV_HDF_RTTOV_COEF_PCC1_WH( X%PCREG(j,i), G_ID_SUB3, ERR , COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE)
            THROWM(ERR.NE.0,"CANNOT WRITE PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

            CALL H5GCLOSE_F( G_ID_SUB3, ERR )
            THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

          END DO

          CALL H5GCLOSE_F( G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG/"//TRIM(GNAME))

        END DO

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG")

        ! EIGEN structure
        CALL MKPAR( LUN, "EIGEN", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CREATE GROUP EIGEN")

        DO I = 1, X%FMV_PC_BANDS

          WRITE(GNAME,'(I2.2)') I
          CALL MKPAR( G_ID_SUB, TRIM(GNAME), G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP EIGEN/"//TRIM(GNAME))

          CALL RTTOV_HDF_RTTOV_COEF_PCC2_WH( X%EIGEN(i), G_ID_SUB2, ERR, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE)
          THROWM(ERR.NE.0,"CANNOT WRITE EIGEN/"//TRIM(GNAME))

          CALL H5GCLOSE_F( G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP EIGEN/"//TRIM(GNAME))

        END DO

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP EIGEN")


CATCH
      END SUBROUTINE

!> Write MFASIS LUT structure to HDF5 file
!! param[in]  x             MFASIS LUT structure
!! param[in]  file_type     CLD or AER for cloud or aerosol structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  compress      if true will apply internal HDF5 compression, optional
!! param[in]  force_double  if true all real values are stored as H5T_NATIVE_DOUBLE, optional
      SUBROUTINE RTTOV_HDF_MFASISCOEF_WH(X, FILE_TYPE, LUN,ERR,COMPRESS,FORCE_DOUBLE)
        USE RTTOV_CONST, ONLY: ERRORSTATUS_FATAL

        TYPE(RTTOV_COEF_MFASIS), INTENT(IN)    :: X
        CHARACTER(LEN=3),        INTENT(IN)    :: FILE_TYPE
        INTEGER(HID_T),          INTENT(IN)    :: LUN
        INTEGER(KIND=JPIM),      INTENT(OUT)   :: ERR
        LOGICAL,INTENT(IN),OPTIONAL    ::COMPRESS
        LOGICAL,INTENT(IN),OPTIONAL    ::FORCE_DOUBLE

        CHARACTER(LEN=LENSH) :: GNAME, SNAME
        INTEGER(KIND=JPIM)   :: I
        INTEGER(HID_T)       :: G_ID_SUB

        TRY

        SNAME = 'NCHANNELS_COEF'
        CALL write_array_hdf(LUN,SNAME,&
        'Number of channels in corresponding rtcoef file', &
        ERR,I0=X%NCHANNELS_COEF)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'VERSION'
        CALL write_array_hdf(LUN,SNAME,&
        'Version number',&
        ERR,I0=X%VERSION)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'FILE_TYPE'
        CALL write_array_hdf(LUN,SNAME,&
        'Type of MFASIS file: 1 => cloud, 2 => aerosol',&
        ERR,I0=X%FILE_TYPE)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'README_LUT'
        CALL write_array_hdf(LUN,SNAME,&
        'Readme for LUTs',&
        ERR,C1=X%README_LUT)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'NCHANNELS'
        CALL write_array_hdf(LUN,SNAME,&
        'Number of channels supported by MFASIS',&
        ERR,I0=X%NCHANNELS)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'CHANNEL_LIST'
        CALL write_array_hdf(LUN,SNAME,&
        'List of channels for which LUTs are stored',&
        ERR,I1=X%CHANNEL_LIST)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'CHANNEL_LUT_INDEX'
        CALL write_array_hdf(LUN,SNAME,&
        'Index into channel_list for each channel in rtcoef file',&
        ERR,I1=X%CHANNEL_LUT_INDEX)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'NDIMS'
        CALL write_array_hdf(LUN,SNAME,&
        'Number of dimensions in LUTs',&
        ERR,I0=X%NDIMS)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        SNAME = 'NPARTICLES'
        CALL write_array_hdf(LUN,SNAME,&
        'Number of particle types included in LUTs',&
        ERR,I0=X%NPARTICLES)
        THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

        IF (FILE_TYPE == 'AER') THEN
          SNAME = 'AER_TYPES'
          CALL write_array_hdf(LUN,SNAME,&
          'Aerosol types included in LUTs',&
          ERR,I1=X%AER_TYPES)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        ELSE
          SNAME = 'CLW_SCHEME'
          CALL write_array_hdf(LUN,SNAME,&
          'CLW scheme used for training LUT',&
          ERR,I0=X%CLW_SCHEME)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = 'ICE_SCHEME'
          CALL write_array_hdf(LUN,SNAME,&
          'ICE scheme used for training LUT',&
          ERR,I0=X%ICE_SCHEME)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))
        ENDIF

        DO I = 1, X%NDIMS
          WRITE(GNAME, '(A,I3.3)') 'DIM', I

          CALL MKPAR( LUN, GNAME, G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//GNAME)

          SNAME = TRIM(GNAME)//'/NAME'
          CALL write_array_hdf(LUN,SNAME,&
          'Dimension name',&
          ERR,C0=X%LUT_AXES(I)%NAME)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = TRIM(GNAME)//'/DIM_TYPE'
          CALL write_array_hdf(LUN,SNAME,&
          'Type of dimension',&
          ERR,I0=X%LUT_AXES(I)%DIM_TYPE)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = TRIM(GNAME)//'/NVALUES'
          CALL write_array_hdf(LUN,SNAME,&
          'Size of dimension',&
          ERR,I0=X%LUT_AXES(I)%NVALUES)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = TRIM(GNAME)//'/VALUES'
          CALL write_array_hdf(LUN,SNAME,&
          'Dimension values',&
          ERR,R1=X%LUT_AXES(I)%VALUES)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))
        ENDDO

        DO I = 1, X%NCHANNELS
          WRITE(GNAME, '(A,I6.6)') 'CH', I

          CALL MKPAR( LUN, GNAME, G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CREATE GROUP "//GNAME)

          SNAME = TRIM(GNAME)//'/NLUTS'
          CALL write_array_hdf(LUN,SNAME,&
          'Number of LUTs for channel '//TRIM(GNAME),&
          ERR,I0=X%LUT(I)%NLUTS)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = TRIM(GNAME)//'/QINT'
          CALL write_array_hdf(LUN,SNAME,&
          'Water vapour values for each LUT',&
          ERR,R2=X%LUT(I)%QINT)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          SNAME = TRIM(GNAME)//'/DATA'
          CALL write_array_hdf(LUN,SNAME,&
          'MFASIS LUT(s) for channel '//TRIM(GNAME),&
          ERR,R2=X%LUT(I)%DATA, COMPRESS=COMPRESS, FORCE_DOUBLE=FORCE_DOUBLE)
          THROWM(err.ne.0,"CANNOT WRITE "//trim(sname))

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))
        ENDDO

        CATCH
      END SUBROUTINE RTTOV_HDF_MFASISCOEF_WH


!> Read an optical depth coefficient structure from HDF5 file
!! param[out] x             optical depth coefficient structure
!! param[in]  lun           file ID of HDF5 file
!! param[out] err           return status
!! param[in]  lbl           set this to true only if reading optical depth coefs
!!                            from LBL code (default false), optional
      SUBROUTINE RTTOV_HDF_COEF_RH(X,LUN,ERR,LBL)

USE RTTOV_HDF_RTTOV_COEF_IO
USE RTTOV_HDF_RTTOV_FAST_COEF_IO
USE RTTOV_HDF_RTTOV_NLTE_COEF_IO

      TYPE(RTTOV_COEF),INTENT(OUT)    ::X
      INTEGER(HID_T),INTENT(IN)       ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT)  ::ERR
      LOGICAL(KIND=JPLM),INTENT(IN)   ::LBL

      LOGICAL :: LEXT
      INTEGER(HID_T) :: G_ID_SUB
      INTEGER(KIND=JPIM) :: n, i

      TYPE(rttov_fast_coef_hdf_io) :: FAST_COEF_temp
TRY


        CALL RTTOV_HDF_RTTOV_COEF_RH( x, LUN, ERR )
        THROWM(ERR.NE.0,"CANNOT READ COEF")

        ! No channel selection with HDF5 so number of channels
        ! in file is same as number of channels extracted
        x%fmv_ori_nchn = x%fmv_chn

        DO n = 1, x%fmv_gas
          SELECT CASE (x%fmv_gas_id(n))
          CASE (gas_id_mixed)
            x%nmixed  = x%fmv_var(n)
            x%ncmixed = x%fmv_coe(n)
            x%nlevels = x%fmv_lvl(n)
          CASE (gas_id_watervapour)
            x%nwater  = x%fmv_var(n)
            x%ncwater = x%fmv_coe(n)
          CASE (gas_id_ozone)
            x%nozone  = x%fmv_var(n)
            x%ncozone = x%fmv_coe(n)
          CASE (gas_id_wvcont)
            x%nwvcont  = x%fmv_var(n)
            x%ncwvcont = x%fmv_coe(n)
          CASE (gas_id_co2)
            x%nco2  = x%fmv_var(n)
            x%ncco2 = x%fmv_coe(n)
          CASE (gas_id_n2o)
            x%nn2o  = x%fmv_var(n)
            x%ncn2o = x%fmv_coe(n)
          CASE (gas_id_co)
            x%nco  = x%fmv_var(n)
            x%ncco = x%fmv_coe(n)
          CASE (gas_id_ch4)
            x%nch4  = x%fmv_var(n)
            x%ncch4 = x%fmv_coe(n)
          CASE (gas_id_so2)
            x%nso2  = x%fmv_var(n)
            x%ncso2 = x%fmv_coe(n)
          END SELECT
        END DO
        x%NLAYERS = x%NLEVELS - 1

        NULLIFY(FAST_COEF_temp%mixedgas)
        NULLIFY(FAST_COEF_temp%watervapour)
        NULLIFY(FAST_COEF_temp%ozone)
        NULLIFY(FAST_COEF_temp%wvcont)
        NULLIFY(FAST_COEF_temp%co2)
        NULLIFY(FAST_COEF_temp%n2o)
        NULLIFY(FAST_COEF_temp%co)
        NULLIFY(FAST_COEF_temp%ch4)
        NULLIFY(FAST_COEF_temp%so2)

        CALL H5GOPEN_F( LUN, "THERMAL", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT OPEN GROUP THERMAL")

!DAR read ALL gases in to temp structure that looks like old fast_coef
        CALL RTTOV_HDF_RTTOV_FAST_COEF_RH( FAST_COEF_temp, G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT READ COEF%THERMAL")

!DAR add code to move read in data to coef structure
        ALLOCATE (x%thermal(x%fmv_chn), STAT = ERR)
        THROWM(ERR.NE.0, "allocation of thermal fast coefs")
        DO i = 1, x%fmv_chn
          ALLOCATE (x%thermal(i)%gasarray(x%fmv_gas), STAT = ERR)
          THROWM(ERR.NE.0, "allocation of gasarray")
          NULLIFY (x%thermal(i)%mixedgas)
          NULLIFY (x%thermal(i)%watervapour)
          NULLIFY (x%thermal(i)%ozone)
          NULLIFY (x%thermal(i)%wvcont)
          NULLIFY (x%thermal(i)%co2)
          NULLIFY (x%thermal(i)%n2o)
          NULLIFY (x%thermal(i)%co)
          NULLIFY (x%thermal(i)%ch4)
          NULLIFY (x%thermal(i)%so2)
        ENDDO

        IF (ASSOCIATED(FAST_COEF_temp%mixedgas)) THEN
          CALL move_hdf_fast_coef(x, x%thermal, FAST_COEF_temp%mixedgas, gas_id_mixed, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%mixedgas)    ; NULLIFY(FAST_COEF_temp%mixedgas)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%watervapour)) THEN
          CALL move_hdf_fast_coef(x, x%thermal, FAST_COEF_temp%watervapour, gas_id_watervapour, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%watervapour) ; NULLIFY(FAST_COEF_temp%watervapour)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%ozone)) THEN
          CALL move_hdf_fast_coef(x, x%thermal, FAST_COEF_temp%ozone, gas_id_ozone, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%ozone)       ; NULLIFY(FAST_COEF_temp%ozone)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%wvcont)) THEN
          CALL move_hdf_fast_coef(x, x%thermal, FAST_COEF_temp%wvcont, gas_id_wvcont, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%wvcont)      ; NULLIFY(FAST_COEF_temp%wvcont)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%co2)) THEN
          CALL move_hdf_fast_coef(x, x%thermal,FAST_COEF_temp%co2, gas_id_co2, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%co2)         ; NULLIFY(FAST_COEF_temp%co2)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%n2o)) THEN
          CALL move_hdf_fast_coef(x, x%thermal,FAST_COEF_temp%n2o, gas_id_n2o, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%n2o)         ; NULLIFY(FAST_COEF_temp%n2o)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%co)) THEN
          CALL move_hdf_fast_coef(x, x%thermal,FAST_COEF_temp%co, gas_id_co, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%co)          ; NULLIFY(FAST_COEF_temp%co)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%ch4)) THEN
          CALL move_hdf_fast_coef(x, x%thermal,FAST_COEF_temp%ch4, gas_id_ch4, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%ch4)         ; NULLIFY(FAST_COEF_temp%ch4)
        ENDIF
        IF (ASSOCIATED(FAST_COEF_temp%so2)) THEN
          CALL move_hdf_fast_coef(x, x%thermal,FAST_COEF_temp%so2, gas_id_so2, lbl_mode = LBL)
          DEALLOCATE(FAST_COEF_temp%so2)         ; NULLIFY(FAST_COEF_temp%so2)
        ENDIF

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP THERMAL")

        x%PMC_SHIFT = ASSOCIATED(x%PMC_COEF)

        x%SOLARCOEF = .FALSE.
        NULLIFY( x%SOLAR)

        CALL H5LEXISTS_F( LUN, "SOLAR", LEXT, ERR )
        THROWM(ERR.NE.0,"CANNOT TEST SOLAR ")
        IF( LEXT ) THEN

          CALL H5GOPEN_F( LUN, "SOLAR", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT OPEN GROUP SOLAR")

!DAR read ALL gases in to temp structure that looks like old fast_coef
          CALL RTTOV_HDF_RTTOV_FAST_COEF_RH( FAST_COEF_temp, G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT READ COEF%SOLAR")

!DAR add code to move read in data to coef structure
          ALLOCATE (x%solar(x%fmv_chn), STAT = ERR)
          THROWM( ERR .NE. 0, "ALLOCATION OF SOLAR FAST COEFS")
          DO i = 1, x%fmv_chn
            ALLOCATE (x%solar(i)%gasarray(x%fmv_gas), STAT = ERR)
            THROWM(ERR.NE.0, "allocation of gasarray")
            NULLIFY (x%solar(i)%mixedgas)
            NULLIFY (x%solar(i)%watervapour)
            NULLIFY (x%solar(i)%ozone)
            NULLIFY (x%solar(i)%wvcont)
            NULLIFY (x%solar(i)%co2)
            NULLIFY (x%solar(i)%n2o)
            NULLIFY (x%solar(i)%co)
            NULLIFY (x%solar(i)%ch4)
            NULLIFY (x%solar(i)%so2)
          ENDDO

          IF (ASSOCIATED(FAST_COEF_temp%mixedgas)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%mixedgas, gas_id_mixed, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%mixedgas)    ; NULLIFY(FAST_COEF_temp%mixedgas)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%watervapour)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%watervapour, gas_id_watervapour, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%watervapour) ; NULLIFY(FAST_COEF_temp%watervapour)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%ozone)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%ozone, gas_id_ozone, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%ozone)       ; NULLIFY(FAST_COEF_temp%ozone)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%wvcont)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%wvcont, gas_id_wvcont, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%wvcont)      ; NULLIFY(FAST_COEF_temp%wvcont)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%co2)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%co2, gas_id_co2, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%co2)         ; NULLIFY(FAST_COEF_temp%co2)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%n2o)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%n2o, gas_id_n2o, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%n2o)         ; NULLIFY(FAST_COEF_temp%n2o)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%co)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%co, gas_id_co, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%co)          ; NULLIFY(FAST_COEF_temp%co)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%ch4)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%ch4, gas_id_ch4, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%ch4)         ; NULLIFY(FAST_COEF_temp%ch4)
          ENDIF
          IF (ASSOCIATED(FAST_COEF_temp%so2)) THEN
            CALL move_hdf_fast_coef(x, x%solar, FAST_COEF_temp%so2, gas_id_so2, lbl_mode = LBL)
            DEALLOCATE(FAST_COEF_temp%so2)         ; NULLIFY(FAST_COEF_temp%so2)
          ENDIF

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP SOLAR")

          x%SOLARCOEF = .TRUE.

        ENDIF


        x%NLTECOEF = .FALSE.
        NULLIFY( x%NLTE_COEF)

        CALL H5LEXISTS_F( LUN, "NLTE_COEF", LEXT, ERR )
        THROWM(ERR.NE.0,"CANNOT TEST NLTE_COEF ")
        IF( LEXT ) THEN

          CALL H5GOPEN_F( LUN, "NLTE_COEF", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT OPEN GROUP NLTE_COEF")

          ALLOCATE (x%NLTE_COEF, STAT = ERR)
          THROWM( ERR .NE. 0, "ALLOCATION OF NLTE_COEF FAST COEFS")

          CALL RTTOV_HDF_RTTOV_NLTE_COEF_RH( x%NLTE_COEF, G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT READ COEF%NLTE_COEF")

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP NLTE_COEF")

          x%NLTECOEF = .TRUE.

        ENDIF

CATCH
      END SUBROUTINE

!> Read a cloud coefficient structure from HDF5 file
!! param[inout]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[inout]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]     z             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_SCCLDCOEF_RH(X, Y, Z, LUN,ERR)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(INOUT)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(INOUT)              :: Y
      TYPE(RTTOV_COEF    ), INTENT(IN)              :: Z

      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR
!
      LOGICAL  :: LEXT
      INTEGER(HID_T) :: G_ID_SUB
!
TRY
        CALL H5GOPEN_F( LUN, "WATERCLOUDS", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT OPEN GROUP WATERCLOUDS")

        CALL RTTOV_HDF_RTTOV_WATERCLOUDS_RH( x, y, z, G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT READ WATERCLOUDS COEFS")

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP WATERCLOUDS")

        CALL H5LEXISTS_F( LUN, "WATERCLOUDS_DEFF", LEXT, ERR )
        THROWM(ERR.NE.0,"CANNOT TEST WATERCLOUDS_DEFF")
        IF( LEXT ) THEN
          CALL H5GOPEN_F( LUN, "WATERCLOUDS_DEFF", G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT OPEN GROUP WATERCLOUDS_DEFF")

          CALL RTTOV_HDF_RTTOV_WATERCLOUDS_DEFF_RH( x, y, z, G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT READ WATERCLOUDS_DEFF COEFS")

          CALL H5GCLOSE_F( G_ID_SUB, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP WATERCLOUDS_DEFF")
        ENDIF

        CALL H5GOPEN_F( LUN, "ICECLOUDS", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT OPEN GROUP ICECLOUDS")

        CALL RTTOV_HDF_RTTOV_ICECLOUDS_RH( x, y, z, G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT READ ICECLOUDS COEFS")

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP ICECLOUDS")

CATCH
      END SUBROUTINE

!> Read the liquid water cloud section of a cloud coefficient structure from HDF5 file
!! param[inout]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[inout]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]     z             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_RTTOV_WATERCLOUDS_RH(X, Y, Z, LUN,ERR)
      USE RTTOV_UNIX_ENV, ONLY : RTTOV_UPPER_CASE
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(INOUT)        :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(INOUT)        :: Y
      TYPE(RTTOV_COEF    ), INTENT(IN)                :: Z
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

      INTEGER(KIND=JPIM) :: I, N
      LOGICAL  :: LEXT
!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM

sname='FMV_WCL_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCL_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

IF (z%fmv_ori_nchn /= x%fmv_wcl_chn) THEN
    err = errorstatus_fatal
    THROWM(err.ne.0,"Incompatible channels between rtcoef and sccldcoef files")
ENDIF

! Read in variable n_phase_channels, FMV_WCL_PHA_CHN will be later affected
sname='FMV_WCL_PHA_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCL_PHA_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_WCL_COMP'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCL_COMP)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_WCL_MAXNMOM'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCL_MAXNMOM)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='WCL_NPHANGLE'
call read_array_hdf(lun,sname,err,i0=x%WCL_NPHANGLE)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))



! Sort out the solar channels/phase functions
IF (x%FMV_WCL_PHA_CHN > 0) THEN

    ! Always get solar channel indexes from HDF file
    sname='WCL_PHA_CHANLIST'
    call read_array_hdf(lun,sname,err,pi1=x%WCL_PHA_CHANLIST )
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    IF (x%fmv_wcl_pha_chn > 0) THEN
        ! Copy solar channels to extract into correctly-sized array

        ! Create map from extracted channel list into pha array
        ALLOCATE (x%wcl_pha_index(z%fmv_chn))
        x%wcl_pha_index(:) = 0
        x%wcl_pha_index(x%wcl_pha_chanlist(1:x%fmv_wcl_pha_chn)) = &
              (/ (i, i = 1, x%fmv_wcl_pha_chn) /)
    ENDIF

    sname='WCL_PHANGLE'
    call read_array_hdf(lun,sname,err,pr1=x%WCL_PHANGLE)
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    CALL rttov_alloc_phfn_int(err, x%wcl_phangle, x%wcl_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcl_phfn_int")

ENDIF

sname='FMV_WCL_RH'
call read_array_hdf(lun,sname,err,pi1=x%FMV_WCL_RH)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='CONFAC'
call read_array_hdf(lun,sname,err,pr1=x%CONFAC)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_WCL_COMP_NAME'
call read_array_hdf(lun,sname,err,pc1=x%fmv_wcl_comp_name)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

ALLOCATE (y%optpwcl(x%fmv_wcl_comp), STAT = ERR)
THROWM( ERR .NE. 0, "allocation of optpwcl")

DO n = 1, x%fmv_wcl_comp
  CALL rttov_hdf_nullify_coef_scatt_ir (y%optpwcl(n))
ENDDO


DO I = 1, x%FMV_WCL_COMP

  CALL RTTOV_UPPER_CASE(GNAME, x%fmv_wcl_comp_name(I))
!   write(0,*) "OPEN GROUP "//TRIM(GNAME)
  CALL H5GOPEN_F( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT OPEN GROUP "//TRIM(GNAME))

  sname='FMV_WCL_RH_VAL'
  call read_array_hdf(G_ID_SUB,sname,err,pr1=y%optpwcl(i)%FMV_WCL_RH_VAL)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='ABS'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcl(i)%ABS)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='SCA'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcl(i)%SCA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='BPR'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcl(i)%BPR)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='NMOM'
  call read_array_hdf(G_ID_SUB,sname,err,pi2=y%optpwcl(i)%NMOM)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='LEGCOEF'
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpwcl(i)%LEGCOEF)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='PHA'
  call h5lexists_f( G_ID_SUB, sname, lext, err )
  if( lext ) then
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpwcl(i)%PHA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

ENDDO

err=0_jpim

CATCH
      END SUBROUTINE

!> Read the Deff liquid water cloud section of a cloud coefficient structure from HDF5 file
!! param[inout]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[inout]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]     z             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_RTTOV_WATERCLOUDS_DEFF_RH(X, Y, Z,LUN,ERR)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(INOUT)        :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(INOUT)        :: Y
      TYPE(RTTOV_COEF    ), INTENT(IN)                :: Z
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME
!       CHARACTER(LEN=LENSH), POINTER  ::VNAME(:)
      INTEGER(KIND=JPIM) :: I
      LOGICAL :: LEXT


!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM

sname='FMV_WCLDEFF_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCLDEFF_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

IF (z%fmv_ori_nchn /= x%fmv_wcldeff_chn) THEN
    err = errorstatus_fatal
    THROWM(err.ne.0,"Incompatible channels between rtcoef and sccldcoef files")
ENDIF

sname='FMV_WCLDEFF_PHA_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCLDEFF_PHA_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_WCLDEFF_NDEFF'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCLDEFF_NDEFF)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_WCLDEFF_MAXNMOM'
call read_array_hdf(lun,sname,err,i0=x%FMV_WCLDEFF_MAXNMOM)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='WCLDEFF_NPHANGLE'
call read_array_hdf(lun,sname,err,i0=x%WCLDEFF_NPHANGLE)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))


! Sort out the solar channels/phase functions
IF (x%FMV_WCLDEFF_PHA_CHN > 0) THEN

        ! Always get solar channel indexes from HDF file
    sname='WCLDEFF_PHA_CHANLIST'
    call read_array_hdf(lun,sname,err,pi1=x%WCLDEFF_PHA_CHANLIST )
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    IF (x%fmv_wcldeff_pha_chn > 0) THEN
        ! Copy solar channels to extract into correctly-sized array

        ! Create map from extracted channel list into pha array
        ALLOCATE (x%wcldeff_pha_index(z%fmv_chn))
        x%wcldeff_pha_index(:) = 0
        x%wcldeff_pha_index(x%wcldeff_pha_chanlist(1:x%fmv_wcldeff_pha_chn)) = &
              (/ (i, i = 1, x%fmv_wcldeff_pha_chn) /)

    ENDIF

    sname='WCLDEFF_PHANGLE'
    call read_array_hdf(lun,sname,err,pr1=x%WCLDEFF_PHANGLE)
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    CALL rttov_alloc_phfn_int(err, x%wcldeff_phangle, x%wcldeff_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%wcldeff_phfn_int")

ENDIF

ALLOCATE (y%optpwcldeff, STAT = ERR)
THROWM( ERR .NE. 0, "allocation of optpwcldeff")
CALL rttov_hdf_nullify_coef_scatt_ir (y%optpwcldeff)

ALLOCATE(y%optpwcldeff%fmv_wcldeff_deff(x%fmv_wcldeff_ndeff))
THROWM( ERR .NE. 0, "allocation of optpwcldeff%fmv_wcldeff_deff")

GNAME = 'DATA'

  CALL H5GOPEN_F( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT OPEN GROUP "//TRIM(GNAME))

  sname='FMV_WCLDEFF_DEFF'
  call read_array_hdf(G_ID_SUB,sname,err,r1=y%optpwcldeff%fmv_wcldeff_deff(:))
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='ABS'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcldeff%ABS)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='SCA'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcldeff%SCA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='BPR'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpwcldeff%BPR)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='NMOM'
  call read_array_hdf(G_ID_SUB,sname,err,pi2=y%optpwcldeff%NMOM)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='LEGCOEF'
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpwcldeff%LEGCOEF)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='PHA'
  call h5lexists_f( G_ID_SUB, sname, lext, err )
  if( lext ) then
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpwcldeff%PHA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

err=0_jpim

CATCH
      END SUBROUTINE

!> Read the ice water cloud section of a cloud coefficient structure from HDF5 file
!! param[inout]  x             RTTOV cloud coef_scatt_ir coefficient structure
!! param[inout]  y             RTTOV cloud optpar_ir coefficient structure
!! param[in]     z             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_RTTOV_ICECLOUDS_RH(X, Y, Z,LUN,ERR)
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(INOUT)        :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(INOUT)        :: Y
      TYPE(RTTOV_COEF    ), INTENT(IN)                :: Z
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME
      INTEGER(KIND=JPIM) :: I
      LOGICAL :: LEXT


!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

ERR=0_JPIM

sname='FMV_ICL_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_ICL_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

IF (z%fmv_ori_nchn /= x%fmv_icl_chn) THEN
    err = errorstatus_fatal
    THROWM(err.ne.0,"Incompatible channels between rtcoef and sccldcoef files")
ENDIF

sname='FMV_ICL_PHA_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_ICL_PHA_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_ICL_NDEFF'
call read_array_hdf(lun,sname,err,i0=x%FMV_ICL_NDEFF)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_ICL_MAXNMOM'
call read_array_hdf(lun,sname,err,i0=x%FMV_ICL_MAXNMOM)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='ICL_NPHANGLE'
call read_array_hdf(lun,sname,err,i0=x%ICL_NPHANGLE)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))


! Sort out the solar channels/phase functions
IF (x%FMV_ICL_PHA_CHN > 0) THEN

        ! Always get solar channel indexes from HDF file
    sname='ICL_PHA_CHANLIST'
    call read_array_hdf(lun,sname,err,pi1=x%ICL_PHA_CHANLIST )
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    IF (x%fmv_icl_pha_chn > 0) THEN
        ! Copy solar channels to extract into correctly-sized array

        ! Create map from extracted channel list into pha array
        ALLOCATE (x%icl_pha_index(z%fmv_chn))
        x%icl_pha_index(:) = 0
        x%icl_pha_index(x%icl_pha_chanlist(1:x%fmv_icl_pha_chn)) = &
              (/ (i, i = 1, x%fmv_icl_pha_chn) /)

    ENDIF

    sname='ICL_PHANGLE'
    call read_array_hdf(lun,sname,err,pr1=x%ICL_PHANGLE)
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    CALL rttov_alloc_phfn_int(err, x%icl_phangle, x%icl_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%icl_phfn_int")

ENDIF

ALLOCATE (y%optpicl, STAT = ERR)
THROWM( ERR .NE. 0, "allocation of optpicl")
CALL rttov_hdf_nullify_coef_scatt_ir (y%optpicl)

ALLOCATE(y%optpicl%fmv_icl_deff(x%fmv_icl_ndeff))
THROWM( ERR .NE. 0, "allocation of optpicl%fmv_icl_deff")

GNAME = 'SSEC_ICE'

  CALL H5GOPEN_F( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT OPEN GROUP "//TRIM(GNAME))

  sname='FMV_ICL_DEFF'
  call read_array_hdf(G_ID_SUB,sname,err,r1=y%optpicl%fmv_icl_deff(:))
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='ABS'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpicl%ABS)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='SCA'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpicl%SCA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='BPR'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpicl%BPR)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='NMOM'
  call read_array_hdf(G_ID_SUB,sname,err,pi2=y%optpicl%NMOM)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='LEGCOEF'
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpicl%LEGCOEF)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='PHA'
  call h5lexists_f( G_ID_SUB, sname, lext, err )
  if( lext ) then
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpicl%PHA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))

err=0_jpim

CATCH
      END SUBROUTINE

!> Read an aerosol coefficient structure from HDF5 file
!! param[inout]  x             RTTOV aerosol coef_scatt_ir coefficient structure
!! param[inout]  y             RTTOV aerosol optpar_ir coefficient structure
!! param[in]     z             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_SCAERCOEF_RH(X, Y, Z, LUN,ERR)
      USE RTTOV_UNIX_ENV, ONLY : RTTOV_UPPER_CASE
      TYPE(RTTOV_COEF_SCATT_IR), INTENT(INOUT)              :: X
      TYPE(RTTOV_OPTPAR_IR    ), INTENT(INOUT)              :: Y
      TYPE(RTTOV_COEF    ), INTENT(IN)                      :: Z
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR

      CHARACTER(LEN=LENSH)  ::SNAME
      CHARACTER(LEN=LENSH)  ::GNAME

      INTEGER(KIND=JPIM)    :: I
      LOGICAL :: LEXT
!
      INTEGER(HID_T) :: G_ID_SUB
!
TRY

sname='FMV_AER_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_AER_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

IF (z%fmv_ori_nchn /= x%fmv_aer_chn) THEN
    err = errorstatus_fatal
    THROWM(err.ne.0,"Incompatible channels between rtcoef and scaercoef files")
ENDIF

sname='FMV_AER_PHA_CHN'
call read_array_hdf(lun,sname,err,i0=x%FMV_AER_PHA_CHN)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_AER_COMP'
call read_array_hdf(lun,sname,err,i0=x%FMV_AER_COMP)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='FMV_AER_MAXNMOM'
call read_array_hdf(lun,sname,err,i0=x%FMV_AER_MAXNMOM)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='AER_NPHANGLE'
call read_array_hdf(lun,sname,err,i0=x%AER_NPHANGLE)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

! Sort out the solar channels/phase functions
IF (x%FMV_AER_PHA_CHN > 0) THEN

        ! Always get solar channel indexes from HDF file
    sname='AER_PHA_CHANLIST'
    call read_array_hdf(lun,sname,err,pi1=x%aer_PHA_CHANLIST )
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    IF (x%fmv_aer_pha_chn > 0) THEN
        ! Copy solar channels to extract into correctly-sized array

        ! Create map from extracted channel list into pha array
        ALLOCATE (x%aer_pha_index(z%fmv_chn))
        x%aer_pha_index(:) = 0
        x%aer_pha_index(x%aer_pha_chanlist(1:x%fmv_aer_pha_chn)) = &
              (/ (i, i = 1, x%fmv_aer_pha_chn) /)

    ENDIF

    sname='AER_PHANGLE'
    call read_array_hdf(lun,sname,err,pr1=x%AER_PHANGLE)
    THROWM(err.ne.0,"CANNOT READ "//trim(sname))

    CALL rttov_alloc_phfn_int(err, x%aer_phangle, x%aer_phfn_int, 1_jpim)
    THROWM(err.NE.0, "initialisation of coef_scatt_ir%aer_phfn_int")

ENDIF

sname='FMV_AER_RH'
call read_array_hdf(lun,sname,err,pi1=x%FMV_AER_RH)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

sname='AER_MMR2ND'
call read_array_hdf(lun,sname,err,pr1=x%AER_MMR2ND)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

ALLOCATE (y%optpaer(x%fmv_aer_comp), STAT = ERR)
THROWM( ERR .NE. 0, "allocation of optaer")

DO i = 1, x%FMV_AER_COMP
  CALL rttov_hdf_nullify_coef_scatt_ir (y%optpaer(i))
ENDDO

sname='FMV_AER_COMP_NAME'
call read_array_hdf(lun,sname,err,pc1=x%FMV_AER_COMP_NAME)
THROWM(err.ne.0,"CANNOT READ "//trim(sname))

DO I = 1, x%FMV_AER_COMP

  CALL RTTOV_UPPER_CASE(GNAME, x%FMV_AER_COMP_NAME(I))

  CALL H5GOPEN_F( LUN, TRIM(GNAME), G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT OPEN GROUP "//TRIM(GNAME))

  sname='FMV_AER_RH_VAL'
  call read_array_hdf(G_ID_SUB,sname,err,pr1=y%optpaer(i)%FMV_AER_RH_VAL)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='ABS'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpaer(i)%ABS)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='SCA'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpaer(i)%SCA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='BPR'
  call read_array_hdf(G_ID_SUB,sname,err,pr2=y%optpaer(i)%BPR)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='NMOM'
  call read_array_hdf(G_ID_SUB,sname,err,pi2=y%optpaer(i)%NMOM)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='LEGCOEF'
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpaer(i)%LEGCOEF)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))

  sname='PHA'
  call h5lexists_f( G_ID_SUB, sname, lext, err )
  if( lext ) then
  call read_array_hdf(G_ID_SUB,sname,err,pr3=y%optpaer(i)%PHA)
  THROWM(err.ne.0,"CANNOT READ "//trim(sname))
  endif

  CALL H5GCLOSE_F( G_ID_SUB, ERR )
  THROWM(ERR.NE.0,"CANNOT CLOSE GROUP "//TRIM(GNAME))
ENDDO

CATCH
      END SUBROUTINE

!> Read PC-RTTOV coefficient structure from HDF5 file
!! param[inout]  x             PC coefficient structure
!! param[in]     y             optical depth coefficient structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_PCCOEF_RH(X, Y,LUN,ERR)
USE RTTOV_CONST, ONLY: ERRORSTATUS_FATAL, SENSOR_ID_HI
USE RTTOV_HDF_RTTOV_COEF_PCC_IO
USE RTTOV_HDF_RTTOV_COEF_PCC1_IO
USE RTTOV_HDF_RTTOV_COEF_PCC2_IO

      TYPE(RTTOV_COEF_PCCOMP),INTENT(INOUT)  ::X
      TYPE(RTTOV_COEF),INTENT(IN)            ::Y
      INTEGER(HID_T),INTENT(IN)      ::LUN
      INTEGER(KIND=JPIM),INTENT(OUT) ::ERR

      CHARACTER(LEN=LENSH)  :: GNAME, GNAME2
      INTEGER(KIND=JPIM)    :: I, J
!
      INTEGER(HID_T) :: G_ID_SUB, G_ID_SUB2, G_ID_SUB3
!
TRY

        CALL RTTOV_HDF_RTTOV_COEF_PCC_RH(X,LUN,ERR)
        THROWM(ERR.NE.0,"CANNOT READ COEF")

        IF ((y%id_sensor == sensor_id_hi)) THEN
          IF (y%id_comp_pc /= x%fmv_pc_comp_pc) THEN
            err = errorstatus_fatal
            THROWM( ERR .NE. 0, "Version of PC coef file is incompatible with RTTOV regression file")
          ENDIF
        ENDIF

        !PCREG structure
        CALL H5GOPEN_F( LUN, "PCREG", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT OPEN GROUP PCREG")

        ALLOCATE (X%PCREG(X%FMV_PC_BANDS,X%FMV_PC_MSETS), STAT = ERR)
        THROWM( ERR .NE. 0, "allocation of coef_pccomp %pcreg")

        DO J = 1, X%FMV_PC_BANDS

          WRITE(GNAME,'(I2.2)') J
          CALL H5GOPEN_F( G_ID_SUB, TRIM(GNAME), G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT OPEN GROUP PCREG/"//TRIM(GNAME))

          DO I = 1, X%FMV_PC_SETS(J)

            WRITE(GNAME2,'(I2.2)') I
            CALL H5GOPEN_F( G_ID_SUB2, TRIM(GNAME2), G_ID_SUB3, ERR )
            THROWM(ERR.NE.0,"CANNOT OPEN GROUP PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

            CALL RTTOV_HDF_RTTOV_COEF_PCC1_INIT(X%PCREG(j,i))

            CALL RTTOV_HDF_RTTOV_COEF_PCC1_RH( X%PCREG(j,i), G_ID_SUB3, ERR )
            THROWM(ERR.NE.0,"CANNOT READ PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

            CALL H5GCLOSE_F( G_ID_SUB3, ERR )
            THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG/"//TRIM(GNAME)//'/'//TRIM(GNAME2))

          END DO

          CALL H5GCLOSE_F( G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG/"//TRIM(GNAME))

        END DO

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP PCREG")

        !EIGEN structure
        CALL H5GOPEN_F( LUN, "EIGEN", G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT OPEN GROUP "//TRIM(GNAME))

        ALLOCATE (X%EIGEN(X%FMV_PC_BANDS), STAT = ERR)
        THROWM( ERR .NE. 0, "allocation of coef_pccomp %eigen")


        DO I = 1, X%FMV_PC_BANDS

          WRITE(GNAME,'(I2.2)') I
          CALL H5GOPEN_F( G_ID_SUB, TRIM(GNAME), G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT OPEN GROUP EIGEN/"//TRIM(GNAME))

          CALL RTTOV_HDF_RTTOV_COEF_PCC2_INIT(X%EIGEN(i))

          CALL RTTOV_HDF_RTTOV_COEF_PCC2_RH( X%EIGEN(i), G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT READ EIGEN/"//TRIM(GNAME))

          CALL H5GCLOSE_F( G_ID_SUB2, ERR )
          THROWM(ERR.NE.0,"CANNOT CLOSE GROUP EIGEN/"//TRIM(GNAME))

        END DO

        CALL H5GCLOSE_F( G_ID_SUB, ERR )
        THROWM(ERR.NE.0,"CANNOT CLOSE GROUP EIGEN")

CATCH
      END SUBROUTINE

!> Read MFASIS LUT structure from HDF5 file
!! param[inout]  x             MFASIS LUT structure
!! param[in]     file_type     CLD or AER for cloud or aerosol structure
!! param[in]     lun           file ID of HDF5 file
!! param[out]    err           return status
      SUBROUTINE RTTOV_HDF_MFASISCOEF_RH(X, FILE_TYPE, LUN,ERR)
        USE RTTOV_CONST, ONLY: ERRORSTATUS_FATAL

        TYPE(RTTOV_COEF_MFASIS), INTENT(INOUT) :: X
        CHARACTER(LEN=3),        INTENT(IN)    :: FILE_TYPE
        INTEGER(HID_T),          INTENT(IN)    :: LUN
        INTEGER(KIND=JPIM),      INTENT(OUT)   :: ERR

        CHARACTER(LEN=LENSH) :: GNAME
        INTEGER(KIND=JPIM)   :: I

        TRY

        CALL read_array_hdf(LUN,'NCHANNELS_COEF',ERR,I0=X%NCHANNELS_COEF)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'VERSION',ERR,I0=X%VERSION)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'FILE_TYPE',ERR,I0=X%FILE_TYPE)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'README_LUT',ERR,C1=X%README_LUT)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'NCHANNELS',ERR,I0=X%NCHANNELS)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'CHANNEL_LIST',ERR,PI1=X%CHANNEL_LIST)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'CHANNEL_LUT_INDEX',ERR,PI1=X%CHANNEL_LUT_INDEX)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'NDIMS',ERR,I0=X%NDIMS)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        CALL read_array_hdf(LUN,'NPARTICLES',ERR,I0=X%NPARTICLES)
        THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

        IF (FILE_TYPE == 'AER') THEN
          X%CLW_SCHEME = 0
          X%ICE_SCHEME = 0
          CALL read_array_hdf(LUN,'AER_TYPES',ERR,PI1=X%AER_TYPES)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")
        ELSE
          NULLIFY(X%AER_TYPES)
          CALL read_array_hdf(LUN,'CLW_SCHEME',ERR,I0=X%CLW_SCHEME)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")
          CALL read_array_hdf(LUN,'ICE_SCHEME',ERR,I0=X%ICE_SCHEME)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")
        ENDIF

        ALLOCATE(X%LUT_AXES(X%NDIMS), STAT=ERR)
        THROWM(ERR.NE.0,"Failure allocating MFASIS LUT")

        DO I = 1, X%NDIMS
          WRITE(GNAME, '(A,I3.3)') 'DIM', I

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/NAME',ERR,C0=X%LUT_AXES(I)%NAME)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/DIM_TYPE',ERR,I0=X%LUT_AXES(I)%DIM_TYPE)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/NVALUES',ERR,I0=X%LUT_AXES(I)%NVALUES)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/VALUES',ERR,PR1=X%LUT_AXES(I)%VALUES)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")
        ENDDO

        ALLOCATE(X%LUT(X%NCHANNELS), STAT=ERR)
        THROWM(ERR.NE.0,"Failure allocating MFASIS LUT")

        DO I = 1, X%NCHANNELS
          WRITE(GNAME, '(A,I6.6)') 'CH', I

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/NLUTS',ERR,I0=X%LUT(I)%NLUTS)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/QINT',ERR,PR2=X%LUT(I)%QINT)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")

          CALL read_array_hdf(LUN,TRIM(GNAME)//'/DATA',ERR,PR2=X%LUT(I)%DATA)
          THROWM(ERR.NE.0,"Failure reading MFASIS LUT")
        ENDDO

        CATCH
      END SUBROUTINE RTTOV_HDF_MFASISCOEF_RH


!> Nullify/initialise an RTTOV coef_scatt_ir coefficient structure
!! param[inout]  x             RTTOV coef_scatt_ir coefficient structure
      SUBROUTINE rttov_hdf_nullify_coef_scatt_ir(coef_scatt_ir)

        USE parkind1, ONLY : jpim
        USE rttov_types, ONLY : rttov_coef_scatt_ir
        IMPLICIT NONE
        TYPE(rttov_coef_scatt_ir), INTENT(INOUT) :: coef_scatt_ir
        coef_scatt_ir%fmv_aer_chn         = 0_JPIM
        coef_scatt_ir%fmv_wcl_chn         = 0_JPIM
        coef_scatt_ir%fmv_wcldeff_chn     = 0_JPIM
        coef_scatt_ir%fmv_icl_chn         = 0_JPIM
        coef_scatt_ir%fmv_aer_pha_chn     = 0_JPIM
        coef_scatt_ir%fmv_wcl_pha_chn     = 0_JPIM
        coef_scatt_ir%fmv_wcldeff_pha_chn = 0_JPIM
        coef_scatt_ir%fmv_icl_pha_chn     = 0_JPIM
        coef_scatt_ir%fmv_aer_comp        = 0_JPIM
        coef_scatt_ir%fmv_wcl_comp        = 0_JPIM
        coef_scatt_ir%fmv_wcldeff_ndeff   = 0_JPIM
        coef_scatt_ir%fmv_icl_ndeff       = 0_JPIM
        NULLIFY (coef_scatt_ir%fmv_aer_comp_name)
        NULLIFY (coef_scatt_ir%fmv_wcl_comp_name)
        NULLIFY (coef_scatt_ir%fmv_aer_rh)
        NULLIFY (coef_scatt_ir%fmv_wcl_rh)
        NULLIFY (coef_scatt_ir%fmv_aer_rh_val)
        NULLIFY (coef_scatt_ir%fmv_wcl_rh_val)
        NULLIFY (coef_scatt_ir%fmv_wcldeff_deff)
        NULLIFY (coef_scatt_ir%fmv_icl_deff)
        NULLIFY (coef_scatt_ir%aer_pha_chanlist)
        NULLIFY (coef_scatt_ir%wcl_pha_chanlist)
        NULLIFY (coef_scatt_ir%wcldeff_pha_chanlist)
        NULLIFY (coef_scatt_ir%icl_pha_chanlist)
        NULLIFY (coef_scatt_ir%aer_pha_index)
        NULLIFY (coef_scatt_ir%wcl_pha_index)
        NULLIFY (coef_scatt_ir%wcldeff_pha_index)
        NULLIFY (coef_scatt_ir%icl_pha_index)
        NULLIFY (coef_scatt_ir%aer_phfn_int%iphangle)
        NULLIFY (coef_scatt_ir%wcl_phfn_int%iphangle)
        NULLIFY (coef_scatt_ir%wcldeff_phfn_int%iphangle)
        NULLIFY (coef_scatt_ir%icl_phfn_int%iphangle)
        NULLIFY (coef_scatt_ir%aer_phangle)
        NULLIFY (coef_scatt_ir%wcl_phangle)
        NULLIFY (coef_scatt_ir%wcldeff_phangle)
        NULLIFY (coef_scatt_ir%icl_phangle)
        NULLIFY (coef_scatt_ir%aer_phfn_int%cosphangle)
        NULLIFY (coef_scatt_ir%wcl_phfn_int%cosphangle)
        NULLIFY (coef_scatt_ir%wcldeff_phfn_int%cosphangle)
        NULLIFY (coef_scatt_ir%icl_phfn_int%cosphangle)
        NULLIFY (coef_scatt_ir%abs)
        NULLIFY (coef_scatt_ir%sca)
        NULLIFY (coef_scatt_ir%bpr)
        NULLIFY (coef_scatt_ir%nmom)
        NULLIFY (coef_scatt_ir%legcoef)
        NULLIFY (coef_scatt_ir%pha)
        NULLIFY (coef_scatt_ir%confac)
        NULLIFY (coef_scatt_ir%aer_mmr2nd)
      END SUBROUTINE rttov_hdf_nullify_coef_scatt_ir

      !> Transfer fast coefficients from format in HDF5 files to coefficient structure
      !! @param[inout]    coef          optical depth coefficient structure
      !! @param[inout]    fast_coef     fast coefficient structure in coef
      !! @param[in]       gas_in        fast coefficients read from HDF5 file
      !! @param[in]       gas_id        gas ID of coefficients to transfer
      !! @param[in]       lbl_mode      set this to true only if reading optical depth coefs from LBL code
      !!                                  (forces reading of all coefs even where they are all zero)
      SUBROUTINE move_hdf_fast_coef(coef, fast_coef, gas_in, gas_id, lbl_mode)

        TYPE(rttov_coef), INTENT(INOUT) :: coef
        TYPE(rttov_fast_coef), INTENT(INOUT) :: fast_coef(:)
        REAL(jprb), INTENT(IN) :: gas_in(:,:,:)
        INTEGER(jpim), INTENT(IN) :: gas_id
        LOGICAL(jplm), INTENT(IN) :: lbl_mode

        INTEGER(jpim) :: gas_pos, ncoef
        INTEGER(jpim) :: i

        gas_pos = coef%fmv_gas_pos(gas_id)
        ncoef = coef%fmv_coe(gas_pos)

        DO i = 1, coef%fmv_chn
          IF (lbl_mode .OR. ANY(gas_in(:, i, :) /= 0._jprb)) THEN
            ALLOCATE (fast_coef(i)%gasarray(gas_pos)%coef(ncoef, coef%nlayers))
            fast_coef(i)%gasarray(gas_pos)%coef = TRANSPOSE(gas_in(:, i , :))
            CALL set_pointers(fast_coef(i), gas_pos, gas_id)
          ELSE
            NULLIFY(fast_coef(i)%gasarray(gas_pos)%coef)
          ENDIF
        ENDDO

      END SUBROUTINE move_hdf_fast_coef

      !> Transfer fast coefficients from coefficient structure to format for HDF5 files
      !! @param[in]       coef          optical depth coefficient structure
      !! @param[in]       fast_coef     fast coefficient structure in coef
      !! @param[inout]    gas_in        fast coefficients to write to HDF5 file
      !! @param[in]       gas_id        gas ID of coefficients to transfer
      SUBROUTINE move_fast_coef_hdf(coef, fast_coef, gas_in, gas_id)
        TYPE(rttov_coef), INTENT(IN) :: coef
        TYPE(rttov_fast_coef), INTENT(IN) :: fast_coef(:)
        REAL(jprb), INTENT(INOUT), POINTER :: gas_in(:,:,:)
        INTEGER(jpim), INTENT(IN) :: gas_id

        INTEGER(jpim) :: i, gas_pos, ncoef

        gas_pos = coef%fmv_gas_pos(gas_id)
        ncoef = coef%fmv_coe(gas_pos)

        ALLOCATE(gas_in(coef%nlayers,coef%fmv_chn,ncoef))

        DO i = 1, coef%fmv_chn
          IF (ASSOCIATED(fast_coef(i)%gasarray(gas_pos)%coef)) THEN
            gas_in(:,i,:) = TRANSPOSE(fast_coef(i)%gasarray(gas_pos)%coef)
          ELSE
            gas_in(:,i,:) = 0._jprb
          ENDIF
        ENDDO

      END SUBROUTINE move_fast_coef_hdf

    END MODULE RTTOV_HDF_COEFS

