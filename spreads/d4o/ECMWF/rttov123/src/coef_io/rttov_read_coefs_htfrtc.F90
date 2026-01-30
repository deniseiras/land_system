! Description:
!> @file
!!   Read HTFRTC coefficient files into RTTOV coefficients structure.
!
!> @brief
!!   Read HTFRTC coefficient files into RTTOV coefficients structure.
!!
!! @details
!!   This subroutine reads HTFRTC coefficient data. HTFRTC requires two files:
!!   one static file which is used for all HTFRTC simulations, and one sensor-
!!   specific file. Both files are read by this subroutine.
!!
!!
!! @param[out]    err                status on exit
!! @param[in,out] coefs              RTTOV coefs structure
!! @param[in]     fname_coef         file name of static HTFRTC data
!! @param[in]     fname_sensor       file name of sensor-specific HTFRTC data
!! @param[in]     channels_rec       list of channels for which PC reconstructed radiances are required, optional
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
SUBROUTINE rttov_read_coefs_htfrtc(err, coefs, fname_coef, fname_sensor, channels_rec)

!INTF_OFF
#include "throw.h"
!INTF_ON
  USE parkind1, ONLY: jpim
  USE rttov_types, ONLY : rttov_coefs
!INTF_OFF
#ifdef _RTTOV_NETCDF
  USE netcdf
#endif
!INTF_ON
  IMPLICIT NONE

  INTEGER(jpim)     , INTENT(OUT)          :: err
  TYPE(rttov_coefs) , INTENT(INOUT)        :: coefs
  CHARACTER(LEN=*)  , INTENT(IN)           :: fname_coef
  CHARACTER(LEN=*)  , INTENT(IN)           :: fname_sensor
  INTEGER(jpim)     , INTENT(IN), OPTIONAL :: channels_rec(:)
!INTF_END

#ifdef _RTTOV_NETCDF
#include "rttov_nullify_coefs.interface"

  INTEGER(jpim) :: lun
  INTEGER(jpim) :: dimid
  INTEGER(jpim) :: varid
  INTEGER(jpim) :: n_t
  INTEGER(jpim) :: i_ch, j_ch
#endif

  TRY

#ifndef _RTTOV_NETCDF
  err = errorstatus_fatal
  THROWM(err.NE.0,"HTFRTC requires RTTOV to be compiled against NetCDF")
#else

  CALL rttov_nullify_coefs(coefs)

  ! Read coefficient file
  err=NF90_OPEN(TRIM(fname_coef), NF90_NOWRITE, lun)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "linear_gas", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_gas_l)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "nonlinear_gas", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_gas_nl)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "pressure", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_p)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "temperature", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=n_t)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "mass_fraction", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_mf_nl)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "linear_coefficients", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_val_l)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "nonlinear_coefficients", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_val_nl)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "planck", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_b)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "wavenumber", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_f)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "lintau", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_lt)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "seasurfemparams", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_ssemp)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "pcs", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_pc)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "pcs_oc", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_pc_oc)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "mftlb", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_mftlb)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "opt_prop_type", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%opt_prop_type)
  THROW(err.NE.0)

  err=NF90_INQ_DIMID(lun, "pc_regression_type", dimid)
  THROW(err.NE.0)
  err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%pc_reg_type)
  THROW(err.NE.0)

  IF (coefs%coef_htfrtc%pc_reg_type.EQ.2) THEN

    err=NF90_INQ_DIMID(lun, "alpha", dimid)
    THROW(err.NE.0)
    err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_alpha)
    THROW(err.NE.0)

    err=NF90_INQ_DIMID(lun, "gen_dim", dimid)
    THROW(err.NE.0)
    err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_gen_dim)
    THROW(err.NE.0)

    err=NF90_INQ_DIMID(lun, "fit_dim", dimid)
    THROW(err.NE.0)
    err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_fit_dim)
    THROW(err.NE.0)

  ENDIF

  ALLOCATE(coefs%coef_htfrtc%p(coefs%coef_htfrtc%n_p))
  err=NF90_INQ_VARID(lun, "pressure", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%p)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_l(coefs%coef_htfrtc%n_val_l))
  err=NF90_INQ_VARID(lun, "temperature", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_l)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_mf_l(coefs%coef_htfrtc%n_gas_l))
  err=NF90_INQ_VARID(lun, "linear_mass_fraction", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_mf_l)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_mf_nl(coefs%coef_htfrtc%n_mf_nl,coefs%coef_htfrtc%n_gas_nl))
  err=NF90_INQ_VARID(lun, "nonlinear_mass_fraction", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_mf_nl)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%mixed_ref_frac(coefs%coef_htfrtc%n_p,coefs%coef_htfrtc%n_gas_l))
  err=NF90_INQ_VARID(lun, "mixed_ref_fraction", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%mixed_ref_frac)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_b(coefs%coef_htfrtc%n_b))
  err=NF90_INQ_VARID(lun, "planck_temp", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_b)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%coef_l(coefs%coef_htfrtc%n_val_l,coefs%coef_htfrtc%n_p,&
           coefs%coef_htfrtc%n_gas_l,coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "linear_mass_ext_coeff", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_l)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%coef_nl(coefs%coef_htfrtc%n_val_nl,coefs%coef_htfrtc%n_p,&
           coefs%coef_htfrtc%n_gas_nl,coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "nonlinear_mass_ext_coeff", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_nl)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%coef_b(coefs%coef_htfrtc%n_b,coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "planck", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_b)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_lt(coefs%coef_htfrtc%n_lt))
  err=NF90_INQ_VARID(lun, "val_lintau", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_lt)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%coef_lt(coefs%coef_htfrtc%n_lt))
  err=NF90_INQ_VARID(lun, "lintau", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_lt)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%coef_ssemp(coefs%coef_htfrtc%n_ssemp,coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "ssemp", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_ssemp)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_mean(coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "mean", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_mean)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%val_norm(coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "norm", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%val_norm)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%solar(coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "solar", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%solar)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%freq(coefs%coef_htfrtc%n_f))
  err=NF90_INQ_VARID(lun, "wavenumber", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%freq)
  THROW(err.NE.0)

  ALLOCATE(coefs%coef_htfrtc%mftlb(coefs%coef_htfrtc%n_mftlb))
  err=NF90_INQ_VARID(lun, "mftlb", varid)
  THROW(err.NE.0)
  err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%mftlb)
  THROW(err.NE.0)

  IF (coefs%coef_htfrtc%pc_reg_type.EQ.1) THEN
  
    ALLOCATE(coefs%coef_htfrtc%coef_pdt(coefs%coef_htfrtc%n_f,coefs%coef_htfrtc%n_pc))
    err=NF90_INQ_VARID(lun, "pdt", varid)
    THROW(err.NE.0)
    err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_pdt)
    THROW(err.NE.0)

  ELSE IF (coefs%coef_htfrtc%pc_reg_type.EQ.2) THEN

    ALLOCATE(coefs%coef_htfrtc%coef_pdt(coefs%coef_htfrtc%n_gen_dim,coefs%coef_htfrtc%n_pc))
    err=NF90_INQ_VARID(lun, "pdt", varid)
    THROW(err.NE.0)
    err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%coef_pdt)
    THROW(err.NE.0)

    ALLOCATE(coefs%coef_htfrtc%alpha(coefs%coef_htfrtc%n_alpha))
    err=NF90_INQ_VARID(lun, "alpha", varid)
    THROW(err.NE.0)
    err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%alpha)
    THROW(err.NE.0)

    ALLOCATE(coefs%coef_htfrtc%gen_val(coefs%coef_htfrtc%n_gen_dim,coefs%coef_htfrtc%n_fit_dim))
    err=NF90_INQ_VARID(lun, "gen_val", varid)
    THROW(err.NE.0)
    err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%gen_val)
    THROW(err.NE.0)

  ENDIF

  err=NF90_CLOSE(lun)
  THROW(err.NE.0)


  ! Read sensor file
  err=NF90_OPEN(TRIM(fname_sensor), NF90_NOWRITE, lun)
  THROW(err.NE.0)

  IF (PRESENT(channels_rec)) THEN
    coefs%coef_htfrtc%n_ch=size(channels_rec)
    ALLOCATE(coefs%coef_htfrtc%sensor_freq(coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "wavenumber", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      j_ch=channels_rec(i_ch)
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%sensor_freq(i_ch), start=(/j_ch/))
      THROW(err.NE.0)
    ENDDO
    ALLOCATE(coefs%coef_htfrtc%ch_mean(coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "mean", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      j_ch=channels_rec(i_ch)
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%ch_mean(i_ch), start=(/j_ch/))
      THROW(err.NE.0)
    ENDDO
    ALLOCATE(coefs%coef_htfrtc%pc(coefs%coef_htfrtc%n_pc,coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "eof", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      j_ch=channels_rec(i_ch)
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%pc(1:coefs%coef_htfrtc%n_pc,i_ch), start=(/1,j_ch/))
      THROW(err.NE.0)
    ENDDO
  ELSE
    err=NF90_INQ_DIMID(lun, "wavenumber", dimid)
    THROW(err.NE.0)
    err=NF90_INQUIRE_DIMENSION(lun, dimid, LEN=coefs%coef_htfrtc%n_ch)
    THROW(err.NE.0)

    ALLOCATE(coefs%coef_htfrtc%sensor_freq(coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "wavenumber", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%sensor_freq(i_ch), start=(/i_ch/))
      THROW(err.NE.0)
    ENDDO
    ALLOCATE(coefs%coef_htfrtc%ch_mean(coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "mean", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%ch_mean(i_ch), start=(/i_ch/))
      THROW(err.NE.0)
    ENDDO
    ALLOCATE(coefs%coef_htfrtc%pc(coefs%coef_htfrtc%n_pc,coefs%coef_htfrtc%n_ch))
    err=NF90_INQ_VARID(lun, "eof", varid)
    THROW(err.NE.0)
    DO i_ch=1,coefs%coef_htfrtc%n_ch
      err=NF90_GET_VAR(lun, varid, coefs%coef_htfrtc%pc(1:coefs%coef_htfrtc%n_pc,i_ch), start=(/1,i_ch/))
      THROW(err.NE.0)
    ENDDO
  ENDIF

  err=NF90_CLOSE(lun)
  THROW(err.NE.0)
#endif

  CATCH
END SUBROUTINE rttov_read_coefs_htfrtc
