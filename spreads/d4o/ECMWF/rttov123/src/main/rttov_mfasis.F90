! Description:
!> @file
!!   Prepares inputs for MFASIS fast visible/near-IR scattering model, calls
!!   MFASIS and returns TOA radiances and reflectances.
!
!> @brief
!!   Prepares inputs for MFASIS fast visible/near-IR scattering model, calls
!!   MFASIS and returns TOA radiances and reflectances.
!!
!! @details
!!   Reference for MFASIS:
!!
!!   Scheck L., P. Frerebeau, R. Buras-Schnell, and B. Mayer, 2016: A fast
!!   radiative transfer method for the simulation of visible satellite imagery.
!!   Journal of Quantitative Spectroscopy and Radiative Transfer, 175:54-67.
!!
!! @param[out]    err               status on exit
!! @param[in]     chanprof          specifies channels and profiles to simulate
!! @param[in]     chanflag          flags to indicate which channels with LUT available
!! @param[in]     opts              options to configure the simulations
!! @param[in]     profiles          input atmospheric profiles and surface variables
!! @param[in]     profiles_int      profiles in internal units
!! @param[in]     coefs             coefficients structure for instrument to simulate
!! @param[in]     ircld             information on cloud columns
!! @param[in]     aux               additional internal profile variables
!! @param[in]     reflectance       surface BRDFs
!! @param[in]     solar_spectrum    TOA solar irradiance for each channel
!! @param[in]     trans_scatt_ir    cloud/aerosol optical depths
!! @param[in,out] radiance          output radiances and corresponding BRFs
!! @param[in,out] mfasis_refl       linear sensitivities of reflectance (used by TL/AD/K)
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
!    Copyright 2017, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_mfasis( &
              err,              &
              chanprof,         &
              chanflag,         &
              opts,             &
              profiles,         &
              profiles_int,     &
              coefs,            &
              ircld,            &
              aux,              &
              reflectance,      &
              solar_spectrum,   &
              trans_scatt_ir,   &
              radiance,         &
              mfasis_refl      )

  ! History:
  ! Version   Date     Comment
  ! -------   ----     -------
  !   0.0     2015     Orginal MFASIS code by L.Scheck (LMU-HErZ)
  !   1.0    03/2017   Implementation into RTTOV (A.Fernandez, DWD)

#include "throw.h"

  USE parkind1, ONLY : jpim, jprb, jplm

  USE rttov_types, ONLY :        &
    rttov_chanprof,              &
    rttov_options,               &
    rttov_profile,               &
    rttov_coefs,                 &
    rttov_ircld,                 &
    rttov_profile_aux,           &
    rttov_reflectance,           &
    rttov_transmission_scatt_ir, &
    rttov_radiance,              &
    rttov_mfasis_refl
!INTF_OFF
  ! Any USE statements which are not required by the subroutine interface go here
  USE rttov_types, ONLY : &
    rttov_coef_mfasis,           &
    rttov_mfasis_axis

  USE rttov_const, ONLY :        &
    wcl_deff,                    &
    pi,                          &
    deg2rad,                     &
    pi_r,                        &
    clw_scheme_deff,             &
    mfasis_cld,                  &
!     mfasis_aer,                  &
    mfasis_maxzenangle,          &
    mfasis_maxsumzenangle,       &
    mfasis_minscaangle,          &
    mfasis_maxscaangle,          &
    qflag_mfasis_zenangle,       &
    qflag_mfasis_sumzenangle,    &
    qflag_mfasis_loscaangle,     &
    qflag_mfasis_hiscaangle,     &
    qflag_mfasis_geometry_bounds,&
    qflag_mfasis_opdpedia_bounds,&
    mfasis_dim_albedo,           &
    mfasis_dim_kfourier,         &
    mfasis_dim_lfourier,         &
    mfasis_dim_opdp,             &
    mfasis_dim_effdia,           &
    mfasis_dim_scaangle,         &
    gas_id_watervapour,          &
    gas_mass,                    &
    mair,                        &
    gravity,                     &
    nwcl_max


!INTF_ON
  IMPLICIT NONE

  INTEGER(jpim),                      INTENT(OUT)   :: err
  TYPE(rttov_chanprof),               INTENT(IN)    :: chanprof(:)
  LOGICAL(jplm),                      INTENT(IN)    :: chanflag(SIZE(chanprof))
  TYPE(rttov_options),                INTENT(IN)    :: opts
  TYPE(rttov_profile),                INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),                INTENT(IN)    :: profiles_int(:)
  TYPE(rttov_coefs),                  INTENT(IN)    :: coefs
  TYPE(rttov_ircld),                  INTENT(IN)    :: ircld
  TYPE(rttov_profile_aux),            INTENT(IN)    :: aux
  TYPE(rttov_reflectance),            INTENT(IN)    :: reflectance(SIZE(chanprof))
  REAL(jprb),                         INTENT(IN)    :: solar_spectrum(SIZE(chanprof))
  TYPE(rttov_transmission_scatt_ir),  INTENT(IN)    :: trans_scatt_ir
  TYPE(rttov_radiance),               INTENT(INOUT) :: radiance
  TYPE(rttov_mfasis_refl), OPTIONAL,  INTENT(INOUT) :: mfasis_refl(0:,:)
!INTF_END

  INTEGER(jpim)              :: nchanprof, prof, chan, nstrms, npar
  INTEGER(jpim)              :: nlay, nlev, ndim, nid, nkt, nlt
  INTEGER(jpim)              :: kfdi, lfdi, aldi
  INTEGER(jpim)              :: d, n, i, j, k, cs, par, jj
  TYPE(rttov_coef_mfasis)    :: mfasis_coefs
  REAL(jprb),    ALLOCATABLE :: ip(:), iw(:)
  REAL(jprb),    ALLOCATABLE :: q_mxr(:),dvap(:)
  REAL(jprb)                 :: wvint_bot, wvint_top 
  REAL(jprb)                 :: iw_wv(3)
  INTEGER(jpim)              :: n_wvdim
  INTEGER(jpim), ALLOCATABLE :: lc(:), lc_aux(:), di(:)
  INTEGER(jpim), ALLOCATABLE :: idx(:,:,:,:)
  REAL(jprb),    ALLOCATABLE :: ckp(:,:), skp(:,:), clm(:,:)
  REAL(jprb),    ALLOCATABLE :: od(:,:), od_eff(:), ed(:,:), ed_eff(:), ed_aux(:)
  REAL(jprb)                 :: albedo
  REAL(jprb)                 :: theta, theta0, mu, mu0, cad, alpha_deg
  TYPE(rttov_mfasis_axis)    :: axis
  REAL(jprb)                 :: alpha_lb, alpha_hb!, alpha_rl
  REAL(jprb)                 :: refl, rflstr(3), strwei, refl_clr(3)
  REAL(jprb)                 :: od1_int,od1_mixed,od2_mixed, ooo1
  REAL(jprb),    ALLOCATABLE :: fac_mx(:)
  REAL(jprb)                 :: fac_sw,xxx1,xxx2   ! variables    used for switching on/off mixed cloud correction

  REAL(jprb), PARAMETER      :: rad2deg = 1._jprb/deg2rad
  REAL(jprb), PARAMETER      :: near0 =  1.E-6_jprb      ! Use in logs instead of zero

  ! --------------------------------------------------------------------------------------

  TRY

  ! TODO: Adapt to water vapor correction using three LUTs
  ! TODO: Test aerosol functionality

  ! --------------------------------------------------------------------------
  ! Initialisation
  ! --------------------------------------------------------------------------
  nchanprof = SIZE(chanprof)
  nlay = profiles(1)%nlayers
  nlev = nlay+1

  ! Check whether cloud or aerosol simulation (currently both simultaneously not supported)
  IF (opts%rt_ir%addclouds ) THEN
    mfasis_coefs = coefs%coef_mfasis_cld
  ELSE
    mfasis_coefs = coefs%coef_mfasis_aer
  ENDIF

  npar = mfasis_coefs%nparticles        ! # of particles: 2 for clouds (water and ice)
                                        !                 or # of aerosols considered
  ndim = mfasis_coefs%ndims             ! # of LUT dimensions

  ! Find number of dimensions that are not interpolated (fourier coefs and albedo)
  n = 0_jpim
  DO d = 1, ndim
    IF (mfasis_coefs%lut_axes(d)%dim_type /= mfasis_dim_kfourier .AND. &
        mfasis_coefs%lut_axes(d)%dim_type /= mfasis_dim_lfourier .AND. &
        mfasis_coefs%lut_axes(d)%dim_type /= mfasis_dim_albedo ) CYCLE
    n = n + 1
  END DO

  nid = ndim - n ! Total number of dimensions to be interpolated (total - albedo - fourier indices)

  ALLOCATE( ip     (nid) , &      ! interpolation point
            lc     (nid) , &      ! lut coordinates
            lc_aux (nid) , &      ! auxiliary lut coordinates
            iw     (nid) , &      ! interpolation weight
            di     (nid), STAT=err )  ! original dimension index in nid arrays
  THROWM(err.NE.0,"Allocation of memory for rttov_mfasis failed")

  ! Populate di and set some relevant dimensions indices
  aldi = -1_jpim  ! albedo dimension index
  kfdi = -1_jpim  ! k Fourier coefficient dimension index
  lfdi = -1_jpim  ! l Fourier coefficient dimension index
  di(:) = -1_jpim ! Indices of dimensions to interpolate

  n = 1_jpim
  DO d = 1, ndim
    SELECT CASE (mfasis_coefs%lut_axes(d)%dim_type)
    CASE (mfasis_dim_kfourier)
      kfdi = d
    CASE (mfasis_dim_lfourier)
      lfdi = d
    CASE (mfasis_dim_albedo)
      aldi = d
    CASE (mfasis_dim_scaangle)
      di(n) = d
      n = n + 1
    CASE DEFAULT
      di(n) = d
      n = n + 1
    END SELECT
  ENDDO

  nkt = mfasis_coefs%lut_axes(kfdi)%nvalues ! Number of Fourier k indices considered
  nlt = mfasis_coefs%lut_axes(lfdi)%nvalues ! Number of Fourier l indices considered

  ALLOCATE( idx    (3,0:nkt-1,0:nlt/2-1,2), &   ! LUT index for each albedo and fourier term
            ckp    (0:1,0:nkt-1)          , &   ! cos(k*thetap), upper and lower bounds
            skp    (0:1,0:nkt-1)          , &   ! sin((k+1)*thetap), upper and lower bounds
            clm    (0:1,0:nlt/2-1)        , &   ! cos(l*thetam), upper and lower bounds
            od_eff (npar)                 , &   ! Effective total optical depth per type of particle
            od     (npar, nlay), STAT=err   )   ! Effective optical depth per type of particle and layer
  THROWM(err.NE.0,"Allocation of memory for rttov_mfasis failed")

  ! For the time being we assume effective diameters will be out of LUT for aerosols
  IF ( mfasis_coefs%file_type .EQ. mfasis_cld ) THEN
    ALLOCATE( ed_eff (npar),   &         ! Total effective diameter per type of particle
              ed_aux (npar),   &         ! Effective diameters to be used with 0 opdp to avoid flagging
              fac_mx (nlay),   &         ! fraction of cloud considered as (potentially) mixed cloud
              ed (npar, nlay), STAT=err) ! Effective diameter per type of partoicle and layer
    THROWM(err.NE.0,"Allocation of memory for rttov_mfasis failed")

    ! Effective diameters to be used with 0 opdp to avoid incorrect flagging for clear stream
    n = 1_jpim
    DO d = 1, ndim
      IF (mfasis_coefs%lut_axes(d)%dim_type .NE. mfasis_dim_effdia) CYCLE
      ed_aux(n) = mfasis_coefs%lut_axes(d)%values(1)
      n = n + 1
    ENDDO
  ENDIF

    ! --------------------------------------------------------------------------
    
  ALLOCATE(q_mxr(nlev))
  ALLOCATE(dvap (nlay  ))

  ! --------------------------------------------------------------------------
  ! Channel loop
  ! --------------------------------------------------------------------------
  DO i = 1, nchanprof
    IF (.NOT. chanflag(i)) CYCLE

    prof = chanprof(i)%prof
    chan = chanprof(i)%chan

    n_wvdim=size(mfasis_coefs%lut(chan)%qint,2)
    dvap(:)=0._jprb

    IF(n_wvdim==3) THEN
      q_mxr(:) =  profiles_int(prof)%q(:)* gas_mass(gas_id_watervapour)/  &
                  (mair * 1.E06_jprb +profiles_int(prof)%q(:)*gas_mass(gas_id_watervapour))
      dvap(1:nlay)  = 100._jprb * (profiles(prof)%p(2:nlev)-profiles(prof)%p(1:nlev-1))* &
                                           0.5_jprb * (q_mxr(2:nlev)+q_mxr(1:nlev-1))/gravity

      jj = aux%s(prof)%nearestlev_surf - 1
      IF(jj>=1 .AND. jj<=nlay) THEN
        dvap(jj)=dvap(jj)*(1._jprb - aux%s(prof)%pfraction_surf)
      ENDIF

    ENDIF


    ! --------------------------------------------------------------------------
    ! Albedo
    ! --------------------------------------------------------------------------
    albedo = MIN(reflectance(i)%refl_out * pi, 1._jprb)

    ! --------------------------------------------------------------------------
    ! Angles (in radians except alpha_deg)
    ! --------------------------------------------------------------------------
    theta = profiles(prof)%zenangle * deg2rad
    theta0 = profiles(prof)%sunzenangle * deg2rad
    mu  = COS(theta)
    mu0 = COS(theta0)

    ! Angle convention opposite as DISORT/paper:
    ! Backscattering: phi = 0, alpha = 0
    ! Forward scatterng: phi = pi, alpha = pi
    cad = COS(profiles(prof)%azangle * deg2rad - profiles(prof)%sunazangle * deg2rad)
    alpha_deg =  rad2deg*(ACOS(mu*mu0 + SQRT(1 - mu**2)*SQRT(1 - mu0**2)*cad))

    ! --------------------------------------------------------------------------
    ! Write angle bit flags to quality field in radiance
    ! --------------------------------------------------------------------------
    IF (profiles(prof)%zenangle .GT. mfasis_maxzenangle) THEN
      radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_zenangle)
    ENDIF
    IF (profiles(prof)%sunzenangle .GT. mfasis_maxzenangle) THEN
      radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_zenangle)
    ENDIF
    IF (profiles(prof)%zenangle+profiles(prof)%sunzenangle .GT. mfasis_maxsumzenangle) THEN
      radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_sumzenangle)
    ENDIF
    IF (alpha_deg .LT. mfasis_minscaangle ) THEN
      radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_loscaangle)
    ENDIF
    IF (alpha_deg .GT. mfasis_maxscaangle ) THEN
      radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_hiscaangle)
    ENDIF

    ! --------------------------------------------------------------------------
    ! Write scattering angle to interpolation point array
    ! (to avoid repeating for every cloud stream)
    ! --------------------------------------------------------------------------
    ip(:) = -1._jprb          ! interpolation point

    ! --------------------------------------------------------------------------
    ! Look for nearest entries in LUT and compute interpolation weights
    ! Only for scattering angle in order to avoid repeating for every cloud stream
    ! --------------------------------------------------------------------------
    lc(:)     = -1_jpim  ! lut coordinates
    lc_aux(:) = 1_jpim   ! lower bound lut coordinates
    iw(:)     = 0._jprb  ! interpolation weight
    DO d = 1, nid
      IF ( mfasis_coefs%lut_axes(di(d))%dim_type .NE. mfasis_dim_scaangle ) CYCLE ! Skip all other dimensions

      ip(d) = alpha_deg
      axis = mfasis_coefs%lut_axes(di(d))

      ! Flag if out of bounds
      IF (ip(d) .LT. axis%values(1) .OR. ip(d) .GT. axis%values(axis%nvalues)) THEN
        radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_geometry_bounds)
      ENDIF

      IF (mfasis_coefs%lut_axes(di(d))%nvalues .EQ. 1_jpim) THEN
        ! No interpolation needed in that axis
        lc_aux(d) = 0_jpim
        iw(d)     = 1._jprb
      ELSE IF ( ip(d) .GE. axis%values(axis%nvalues) ) THEN
        lc_aux(d) = axis%nvalues - 1
        iw(d)     = 1._jprb
      ELSE
        DO j = 1, axis%nvalues - 1
          IF ( ip(d) .GT. axis%values(j) ) THEN
            lc_aux(d) = j
            iw(d) = ( ip(d) - axis%values(j)) &
              /( axis%values(j+1) - axis%values(j) )
          ENDIF
        ENDDO
      ENDIF

      IF ( iw(d) .GT. 0.5 ) THEN
        lc(d) = lc_aux(d) + 1
      ELSE
        lc(d) = lc_aux(d)
      ENDIF

      IF (lc_aux(d) .EQ. 0_jpim) THEN ! only an alpha value in table, no need to interpolate
        alpha_lb = axis%values(lc_aux(d)+1) * deg2rad
        alpha_hb = axis%values(lc_aux(d)+1) * deg2rad
      ELSE
        ! Set nearest table values to scattering angle (will be needed to compute additional angles
        ! for constrained linear interpolation) in radians
        alpha_lb = axis%values(lc_aux(d)) * deg2rad
        alpha_hb = axis%values(lc_aux(d)+1) * deg2rad
      ENDIF
    ENDDO

    ! --------------------------------------------------------------------------
    ! Compute angles for constrained linear interpolation in scattering angle
    ! and precompute cosines and sines for Fourier expansion
    ! --------------------------------------------------------------------------
    CALL rttov_mfasis_compute_angles(theta, theta0, alpha_deg*deg2rad, &
      alpha_lb, alpha_hb, nkt, nlt/2_jpim, ckp, skp, clm)


    ! --------------------------------------------------------------------------
    ! Loop over (cloud) streams
    ! --------------------------------------------------------------------------
    ! No cloud streams for aerosols calculations
    IF ( mfasis_coefs%file_type == mfasis_cld ) THEN
      nstrms = ircld%nstream(prof)
    ELSE
      nstrms = 1_jpim
    ENDIF


    refl = 0._jprb
    refl_clr = 0._jprb

    DO cs = 1, nstrms
      ! --------------------------------------------------------------------------
      ! Set stream weight, optical depth and effective diameters
      ! --------------------------------------------------------------------------
      IF ( mfasis_coefs%file_type .EQ. mfasis_cld ) then ! clouds
        strwei = ircld%xstr(cs+1,prof) - ircld%xstr(cs,prof)
        od(:,:) = 0._jprb
        ed(:,:) = 0._jprb
        od1_int = 0._jprb 
        od1_mixed= 0._jprb
        od2_mixed= 0._jprb
        fac_mx(:)= 0._jprb
        wvint_bot=0._jprb
        wvint_top=0._jprb

        DO j = 1, nlay
          IF (j > aux%s(prof)%nearestlev_surf - 1) EXIT    ! Layer is entirely below surface pressure so nothing more to do
          IF ( ircld%icldarr(cs,j,prof) .EQ. 1 ) THEN
            od(1,j) = SUM(trans_scatt_ir%opdpext(1:nwcl_max,j,i)) ! water clouds
            od(2,j) = trans_scatt_ir%opdpext(nwcl_max+1,j,i)      ! ice clouds
            IF (j == aux%s(prof)%nearestlev_surf - 1) THEN
              ! Modify optical depth in partial layer above surface
              od(:,j) = od(:,j) * (1 - aux%s(prof)%pfraction_surf)
            ENDIF
            !-----------------------------------------------------------------------
            ! determine fraction of ice cloud od counted (potentially) as mixed layer cloud
            !-----------------------------------------------------------------------
            od1_int = od1_int + od(1,j)
            ooo1 = od1_int - opts%dev%od1_thresh
            fac_mx(j) = (1._jprb + TANH(ooo1/opts%dev%o_del1))/2._jprb
            od1_mixed = od1_mixed + fac_mx(j)*od(1,j)
            od2_mixed = od2_mixed + fac_mx(j)*od(2,j)
            IF ( coefs%coef_mfasis_cld%clw_scheme == clw_scheme_deff ) THEN ! Deff water clouds scheme
              ed(1,j) = aux%clw_dg(j,prof)
            ELSE ! OPAC water cloud parametrization
              ! TODO: take into account optical depth surface correction in eff diameter calculation
              ed(1,j) = SUM(wcl_deff(1:nwcl_max) * trans_scatt_ir%opdpext(1:nwcl_max,j,i))
              IF ( od(1,j) .GT. 0. ) THEN
                ed(1,j) = ed(1,j)/SUM(trans_scatt_ir%opdpext(1:nwcl_max,j,i))
              ELSE
                ed(1,j) = 0._jprb
              ENDIF
            ENDIF
            ed(2,j) = aux%ice_dg(j,prof)
          ELSEIF(j>1) THEN
            fac_mx(j) = fac_mx(j-1) 
          ENDIF
          IF(n_wvdim==3) THEN
            wvint_bot = wvint_bot + fac_mx(j)          * dvap(j)
            wvint_top = wvint_top + (1._jprb-fac_mx(j))* dvap(j)
          ENDIF
        ENDDO
        DO k = 1, npar
          od_eff(k) = SUM(od(k,:))
          IF ( od_eff(k) .GT. 0. ) THEN
            ed_eff(k) = SUM( od(k,:)*ed(k,:))/od_eff(k)
          ELSE
            ed_eff(k) = ed_aux(k)
          ENDIF
        ENDDO
        !---------------------------------------------------------------------------------------------------------------
        ! subtract mixed layer cloud od from ice cloud if conditions apply (continuous transition through tanh function)
        !---------------------------------------------------------------------------------------------------------------
        xxx1 = opts%dev%qq_1*od1_mixed - od2_mixed
        xxx2 = opts%dev%qq_2*od_eff(1) - od_eff(2)
        fac_sw= (1._jprb + TANH(xxx1/opts%dev%x_del1))*(1._jprb + TANH(xxx2/opts%dev%x_del2))/4._jprb
        od_eff(1) = od_eff(1) + fac_sw*od2_mixed 
        od_eff(2) = od_eff(2) - fac_sw*od2_mixed

        IF (od_eff(2) > 0.) THEN
          ed_eff(2) = SUM( od(2,:)*ed(2,:)*(1._jprb - fac_sw*fac_mx(:)))/od_eff(2)
        ENDIF
      ELSE  ! aerosols
        strwei = 1._jprb          ! single stream for aerosols
        od(:,:) = 0._jprb
        DO k = 1, npar
          par = mfasis_coefs%aer_types(k)
          DO j = 1, nlay
            IF (j > aux%s(prof)%nearestlev_surf - 1) EXIT    ! Layer is entirely below surface pressure so nothing more to do
            od(k,j) = trans_scatt_ir%opdpext(par,j,i)
            IF (j == aux%s(prof)%nearestlev_surf - 1) THEN
              ! Modify optical depth in partial layer above surface
              od(k,j) = od(k,j) * (1 - aux%s(prof)%pfraction_surf)
            ENDIF
          ENDDO
          od_eff(k) = SUM(od(k,:))
        ENDDO
      ENDIF
      ! --------------------------------------------------------------------------
      ! Fill into the interpolation point array the rest of dimensions
      ! --------------------------------------------------------------------------
      !TODO: For aerosols check with aer_types and/or names to set correct order
      j = 1
      k = 1
      DO d = 1, nid
        SELECT CASE (mfasis_coefs%lut_axes(di(d))%dim_type)
        CASE (mfasis_dim_opdp)
          ip(d) = od_eff(j)
          j = j + 1
        CASE (mfasis_dim_effdia)
          ! Check if stored as radius or diamater in LUT
          IF (mfasis_coefs%lut_axes(di(d))%name(1:1) .EQ. "R") THEN
            ip(d) = ed_eff(k)/2
          ELSE
            ip(d) = ed_eff(k)
          ENDIF
          k = k + 1
        END SELECT
      ENDDO

      ! --------------------------------------------------------------------------
      ! Look for nearest entries in LUT and compute interpolation weights
      ! --------------------------------------------------------------------------
      ! Here we assume the LUT dimensions for optical depths (and effective
      ! diameter in the case of clouds) are always ordered as aer_types in the case
      ! of aerosols and first water and then ice in the case of clouds
       DO d = 1, nid
        IF (mfasis_coefs%lut_axes(di(d))%dim_type .EQ. mfasis_dim_scaangle) CYCLE ! Skip scattering angle (already done)
        axis = mfasis_coefs%lut_axes(di(d))
        ! Reset lc_aux and iw to make sure correct for every stream calculation
        lc(d)     = -1_jpim  ! lut coordinates
        lc_aux(d) = 1_jpim   ! lower bound lut coordinates
        iw(d)     = 0._jprb  ! interpolation weight

        ! Flag if out of bounds
        IF (ip(d) .LT. axis%values(1) .OR. ip(d) .GT. axis%values(axis%nvalues)) THEN
          radiance%quality(i) = IBSET(radiance%quality(i), qflag_mfasis_opdpedia_bounds)
        ENDIF

        IF (axis%nvalues .EQ. 1_jpim) THEN
          ! No interpolation needed in that axis
          lc_aux(d) = 1_jpim
          iw(d)     = 0._jprb
        ELSE IF ( ip(d) .GE. axis%values(axis%nvalues) ) THEN
          lc_aux(d) = axis%nvalues - 1
          iw(d)     = 1._jprb
        ELSE
          DO j = 1, axis%nvalues - 1
            IF ( ip(d) .GT. axis%values(j) ) THEN
              lc_aux(d) = j
              IF ( axis%dim_type .EQ. mfasis_dim_opdp .AND. j .NE. 1 ) THEN ! optical depths ( lin. int. in log)
                iw(d) = ( LOG(ip(d)) - LOG(axis%values(j)) ) &
                  / ( LOG(axis%values(j+1)) - LOG(axis%values(j)) )
              ELSE      ! effective radii and alpha, linear interpolation
                iw(d) = ( ip(d) - axis%values(j) ) &
                  / ( axis%values(j+1) - axis%values(j) )
              ENDIF
            ENDIF
          ENDDO
        ENDIF

        IF ( iw(d) .GT. 0.5 ) THEN
          lc(d) = lc_aux(d) + 1
        ELSE
          lc(d) = lc_aux(d)
        ENDIF
      ENDDO
      ! --------------------------------------------------------------------------
      ! Compute weights for WV LUTs
      ! --------------------------------------------------------------------------
      iw_wv(:)= 0._jprb
      iw_wv(1)= 1._jprb
      if( n_wvdim==3) THEN
          iw_wv(2)=(                 wvint_bot    - mfasis_coefs%lut(chan)%qint(1,1))/ &
               (mfasis_coefs%lut(chan)%qint(1,2) - mfasis_coefs%lut(chan)%qint(1,1)) 
          iw_wv(3)=(                 wvint_top    - mfasis_coefs%lut(chan)%qint(2,1))/ &
               (mfasis_coefs%lut(chan)%qint(2,3) - mfasis_coefs%lut(chan)%qint(2,1)) 
          iw_wv(1) = iw_wv(1) - iw_wv(2) - iw_wv(3)
      ENDIF
      ! --------------------------------------------------------------------------
      ! Linear interpolation in nid dimensions
      ! --------------------------------------------------------------------------
      IF (PRESENT(mfasis_refl)) THEN
        ALLOCATE(mfasis_refl(cs,i)%refl_lin_coef(nid), STAT=err)
        THROWM(err.NE.0,"Allocation of memory for rttov_mfasis failed")
        CALL rttov_mfasis_interpolate(chan, albedo, kfdi, lfdi, aldi,        &
                                     lc_aux, iw, ckp, skp, clm, di, n_wvdim, &
                                     iw_wv, mfasis_coefs, rflstr(1:n_wvdim), err,       &
                                     mfasis_refl(cs,i)%refl_lin_coef(:))
!       mfasis_refl(cs,i)%refl = rflstr(1)
        mfasis_refl(cs,i)%refl              = sum(iw_wv(1:n_wvdim)*rflstr(1:n_wvdim))
        mfasis_refl(cs,i)%refl_wv(1:n_wvdim)= rflstr(1:n_wvdim)
      ELSE
        CALL rttov_mfasis_interpolate(chan, albedo, kfdi, lfdi, aldi,        &
                                     lc_aux, iw, ckp, skp, clm, di, n_wvdim, &
                                     iw_wv, mfasis_coefs, rflstr(1:n_wvdim), err)
      ENDIF
      THROWM(err.NE.0, 'Error in rttov_mfasis_interpolate')

      ! --------------------------------------------------------------------------
      ! Add stream contribution to total reflectance
      ! --------------------------------------------------------------------------
      refl = refl + strwei * sum(iw_wv(1:n_wvdim)*rflstr(1:n_wvdim))

    ENDDO ! end of cloud stream loop

    ! --------------------------------------------------------------------------
    ! Compute clear reflectance and add clear stream to total reflectabce
    ! --------------------------------------------------------------------------
    ! Rerun linear interpolation in nid dimensions setting optical depths
    ! to zero with weight 1
    ! This assumes zero optical depth is always the first value
    IF(n_wvdim==3) THEN
      wvint_bot=0._jprb
      wvint_top=0._jprb
      DO j = 1, nlay
        wvint_top = wvint_top +  dvap(j)
      ENDDO
    ENDIF
!   ! --------------------------------------------------------------------------
!   ! Compute weights for WV LUTs
!   ! --------------------------------------------------------------------------
        iw_wv(:)= 0._jprb
        iw_wv(1)= 1._jprb
        if( n_wvdim==3) THEN
            iw_wv(2)=(                 wvint_bot    - mfasis_coefs%lut(chan)%qint(1,1))/ &
                 (mfasis_coefs%lut(chan)%qint(1,2) - mfasis_coefs%lut(chan)%qint(1,1)) 
            iw_wv(3)=(                 wvint_top    - mfasis_coefs%lut(chan)%qint(2,1))/ &
                 (mfasis_coefs%lut(chan)%qint(2,3) - mfasis_coefs%lut(chan)%qint(2,1)) 
            iw_wv(1) = iw_wv(1) - iw_wv(2) - iw_wv(3)
        ENDIF
    DO d = 1, nid
      IF ( mfasis_coefs%lut_axes(di(d))%dim_type .EQ. mfasis_dim_opdp ) THEN
        lc_aux(d) = 1_jpim
        iw(d) = 0._jprb
      ENDIF
    ENDDO

    IF (PRESENT(mfasis_refl)) THEN
      ALLOCATE(mfasis_refl(0,i)%refl_lin_coef(nid), STAT=err)
      THROWM(err.NE.0,"Allocation of memory for rttov_mfasis failed")
      CALL rttov_mfasis_interpolate(chan, albedo, kfdi, lfdi, aldi,         &
                                    lc_aux, iw, ckp, skp, clm, di, n_wvdim, &
                                    iw_wv, mfasis_coefs, refl_clr(1:n_wvdim), err,     &
                                    mfasis_refl(0,i)%refl_lin_coef(:))
      mfasis_refl(0,i)%refl              = sum(iw_wv(1:n_wvdim)*refl_clr(1:n_wvdim))
      mfasis_refl(0,i)%refl_wv(1:n_wvdim)= refl_clr(1:n_wvdim)
    ELSE
      CALL rttov_mfasis_interpolate(chan, albedo, kfdi, lfdi, aldi,         &
                                    lc_aux, iw, ckp, skp, clm, di, n_wvdim, &
                                    iw_wv, mfasis_coefs, refl_clr(1:n_wvdim), err)
    ENDIF
    THROWM(err.NE.0, 'Error in rttov_mfasis_interpolate')

    strwei = ircld%xstrclr(prof) ! clear stream
    refl = refl + strwei* sum(iw_wv(1:n_wvdim)*refl_clr(1:n_wvdim))

    ! --------------------------------------------------------------------------
    ! Fill radiance structure
    ! --------------------------------------------------------------------------
    radiance%refl(i) = refl
    radiance%refl_clear(i) = sum(iw_wv(1:n_wvdim)*refl_clr(1:n_wvdim))

    radiance%total(i) = refl * solar_spectrum(i) * pi_r  &
      * COS(profiles(prof)%sunzenangle * deg2rad)
    radiance%clear(i) =  radiance%refl_clear(i)  * solar_spectrum(i) * pi_r  &
      * COS(profiles(prof)%sunzenangle * deg2rad)
    radiance%cloudy(i) = radiance%total(i)

  ENDDO ! end of channel loop


  ! --------------------------------------------------------------------------
  ! Tidy up
  ! --------------------------------------------------------------------------

  DEALLOCATE(ip, lc, lc_aux, iw, di, idx, ckp, skp, clm, od, od_eff, q_mxr, dvap, STAT=err)
  THROWM(err.NE.0,"Deallocation of memory for rttov_mfasis failed")
  IF ( mfasis_coefs%file_type .EQ. mfasis_cld ) THEN
    DEALLOCATE(ed, ed_eff, ed_aux, fac_mx, STAT=err)
    THROWM(err.NE.0,"Deallocation of memory for rttov_mfasis failed")
  ENDIF

  CATCH

  CONTAINS

    ! Compute angles needed for constrained interpolation in scattering angle
    ! Precompute cosines and sines for Fourier expansion
    SUBROUTINE rttov_mfasis_compute_angles(   &
                 satzen,     &              ! satellite zenith angle in radians
                 sunzen,     &              ! sun zenith angle in radians
                 scaang,     &              ! scattering angle in radians
                 scaang_lb,  &              ! next lower entry in LUT in radians
                 scaang_hb,  &              ! next higher entry in LUT in radians
                 nkt,        &              ! Number of k Fourier terms
                 nlt,        &              ! Number of l Fourier terms
                 cosk,       &              ! cosines in theta+ for Fourier expansion
                 sink,       &              ! sines in theta+ for Fourier expansion
                 cosl)                      ! cosines in theta- for Fourier expansion

      IMPLICIT NONE

      REAL(jprb),     INTENT(IN) :: satzen
      REAL(jprb),     INTENT(IN) :: sunzen
      REAL(jprb),     INTENT(IN) :: scaang
      REAL(jprb),     INTENT(IN) :: scaang_lb
      REAL(jprb),     INTENT(IN) :: scaang_hb
      INTEGER(jpim),  INTENT(IN) :: nkt
      INTEGER(jpim),  INTENT(IN) :: nlt
      REAL(jprb),     INTENT(OUT):: cosk(0:,0:)
      REAL(jprb),     INTENT(OUT):: sink(0:,0:)
      REAL(jprb),     INTENT(OUT):: cosl(0:,0:)

      ! Controls which methos is used to compute upper and lower bounds
      LOGICAL(jplm) :: use_normalized = .TRUE.
      REAL(jprb)    :: thetap, thetam, scaang_aux
      REAL(jprb)    :: thetap_lb, thetap_hb, thetam_lb, thetam_hb
      ! These only needed if not using normalized thetas
      REAL(jprb)    :: theta0_lb, theta0_hb, theta_lb, theta_hb
      REAL(jprb)    :: theta0_max_lb, theta0_min_hb, theta_c, theta0_c
      REAL(jprb)    :: theta_max_lb, theta_min_hb, relalpha
      LOGICAL(jplm) :: use_thetapm
      INTEGER(jpim) :: k, l


      ! --------------------------------------------------------------------------
      ! Compute angles for constrained linear interpolation in scattering angle
      ! --------------------------------------------------------------------------

      IF ( scaang .LT. scaang_lb ) THEN
         scaang_aux = scaang_lb
      ELSE
         scaang_aux = scaang
      ENDIF

      IF ( use_normalized) THEN ! used normalized thetap and thetam to compute bounds

        ! --------------------------------------------------------------------------
        ! Normalized theta+ and theta- foar the closest values in table
        ! --------------------------------------------------------------------------
        thetap = MIN( 1.0_jprb, &
          MAX( 0.0_jprb, ((satzen + sunzen) - scaang_aux) / (pi-scaang_aux) ))
        thetam = MIN( 1.0_jprb, &
          MAX( -1.0_jprb, (satzen - sunzen) / MIN(scaang_aux,pi-scaang_aux) ))

        ! theta+ and theta- values in the upper and lower alpha planes
        thetap_lb = thetap * (pi-scaang_lb) + scaang_lb
        thetap_hb = thetap * (pi-scaang_hb) + scaang_hb
        thetam_lb = thetam * MIN(scaang_lb,pi-scaang_lb)
        thetam_hb = thetam * MIN(scaang_hb,pi-scaang_hb)

        IF ( 0.5*(thetap_hb + thetam_hb) > 0.5*pi ) THEN
          thetam_hb = pi - thetap_hb
        ENDIF
        IF ( 0.5*(thetap_lb + thetam_lb) > 0.5*pi ) THEN
          thetam_lb = pi - thetap_lb
        ENDIF
        IF ( 0.5*(thetam_hb - thetap_hb) > 0.5*pi ) THEN
          thetam_hb = pi + thetap_hb
        ENDIF
        IF ( 0.5*(thetam_lb - thetap_lb) > 0.5*pi ) THEN
          thetam_lb = pi + thetap_lb
        ENDIF

      ELSE ! use displacement method to compute upper and lower bounds

        ! --------------------------------------------------------------------------
        ! Displacement method (as described in paper)
        ! --------------------------------------------------------------------------
        relalpha = (scaang_aux - scaang_lb)/(scaang_hb - scaang_lb)

        ! set default values
        thetap = satzen + sunzen
        thetam = satzen - sunzen
        theta_hb  = satzen
        theta_lb  = satzen
        theta0_hb = sunzen
        theta0_lb = sunzen
        thetap_hb = thetap
        thetap_lb = thetap
        thetam_hb = thetam
        thetam_lb = thetam

        use_thetapm = .FALSE.
        IF ( thetap >= scaang_hb ) THEN
          IF ( ABS(thetam) > scaang_lb ) THEN
            IF ( thetap >= pi - scaang_hb ) THEN
              IF ( thetam > scaang_lb ) THEN
                !lab = 'Ib'
                theta0_lb = satzen - scaang_lb
                IF ( relalpha > near0 ) THEN
                  theta0_hb = theta0_lb - (theta0_lb-sunzen)/relalpha
                ENDIF
              ELSE
                !lab = 'Ic'
                theta_lb = sunzen - scaang_lb
                IF (relalpha > near0 ) THEN
                 theta_hb = theta_lb - (theta_lb-satzen)/relalpha
                ENDIF
              ENDIF
            ELSE
              IF (thetam > scaang_lb ) THEN
                !lab = 'Ia'
                thetam_lb = scaang_lb
                IF (relalpha > near0 ) THEN
                  thetam_hb = thetam_lb + (thetam-thetam_lb)/relalpha
                ENDIF
              ELSE
                !lab = 'Id'
                thetam_lb = -scaang_lb
                IF (relalpha > near0 ) THEN
                  thetam_hb = thetam_lb + (thetam-thetam_lb)/relalpha
                ENDIF
              ENDIF
              use_thetapm = .TRUE.
            ENDIF
          ELSE
           !lab = '0'
           ! no correction necessary
          ENDIF
        ELSE
          IF( ABS(thetam) <= scaang_lb ) THEN
            !lab = 'II'
            thetap_hb = scaang_hb
            IF (1-relalpha > near0 ) THEN
              thetap_lb = thetap_hb + (thetap-thetap_hb)/(1-relalpha)
            ENDIF
            use_thetapm = .true.
          ELSE
            IF (thetam > scaang_lb ) THEN
              !lab = 'III'
              theta_max_lb = scaang_lb + sunzen
              theta_min_hb = scaang_hb - sunzen
              theta_c = theta_min_hb*relalpha + (1-relalpha)*theta_max_lb
              IF (satzen > theta_c ) THEN
                theta_lb = theta_max_lb
                IF (relalpha > near0 ) THEN
                  theta_hb = theta_lb + (satzen-theta_lb)/relalpha
                ELSE
                  theta_hb = theta_min_hb
                ENDIF
              ELSE
                theta_hb = theta_min_hb
                IF (1-relalpha > near0 ) THEN
                  theta_lb = theta_hb - (theta_hb-satzen)/(1-relalpha)
                ELSE
                  theta_lb = theta_max_lb
                ENDIF
              ENDIF
            ELSE
              !lab = 'IV'
              theta0_max_lb = scaang_lb + satzen
              theta0_min_hb = scaang_hb - satzen
              theta0_c = theta0_min_hb*relalpha + (1-relalpha)*theta0_max_lb
              IF (sunzen > theta0_c ) THEN
                theta0_lb = theta0_max_lb
                IF (relalpha > near0 ) THEN
                  theta0_hb = theta0_lb + (sunzen-theta0_lb)/relalpha
                ELSE
                  theta0_hb = theta0_min_hb
                ENDIF
              ELSE
                theta0_hb = theta0_min_hb
                IF (1-relalpha > near0 ) THEN
                  theta0_lb = theta0_hb - (theta0_hb-sunzen)/(1-relalpha)
                ELSE
                  theta0_lb = theta0_max_lb
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        ENDIF

        IF( .NOT. use_thetapm ) THEN
          thetap_hb = theta_hb + theta0_hb
          thetam_hb = theta_hb - theta0_hb
          thetap_lb = theta_lb + theta0_lb
          thetam_lb = theta_lb - theta0_lb
        ENDIF
      ENDIF

      ! --------------------------------------------------------------------------
      ! Precompute cosines and sines for Fourier expansion
      ! --------------------------------------------------------------------------
      DO k = 0, nkt - 1
        cosk(0,k) = COS( k   *thetap_lb)
        sink(0,k) = SIN((k+1)*thetap_lb)
        cosk(1,k) = COS( k   *thetap_hb)
        sink(1,k) = SIN((k+1)*thetap_hb)
      ENDDO

      DO l = 0, nlt - 1
        cosl(0,l) = COS( l*thetam_lb )
        cosl(1,l) = COS( l*thetam_hb )
      ENDDO

    END SUBROUTINE rttov_mfasis_compute_angles


    ! Computes indeces of the required LUT elements (positions in flattened 1D array)
    SUBROUTINE rttov_mfasis_lut_indices(   &
                ki,                        &  ! k Fourier dimension index
                li,                        &  ! l Fourier dimension index
                ai,                        &  ! albedo dimension index
                dimidx,                    &  ! dimension index of dims to be interpolated
                coolut,                    &  ! coordinates in interpolation space of coeff wanted
                axes,                      &  ! info on LUT axes
                lutidx,                    &  ! indeces of LUT coefficients
                err)

      IMPLICIT NONE

      INTEGER(jpim)            ,INTENT(IN)  :: ki
      INTEGER(jpim)            ,INTENT(IN)  :: li
      INTEGER(jpim)            ,INTENT(IN)  :: ai
      INTEGER(jpim)            ,INTENT(IN)  :: dimidx(:)
      INTEGER(jpim)            ,INTENT(IN)  :: coolut(:)
      TYPE(rttov_mfasis_axis)  ,INTENT(IN)  :: axes(:)
      INTEGER(jpim)            ,INTENT(OUT) :: lutidx(:,0:,0:,:)
      INTEGER(jpim)            ,INTENT(OUT) :: err

      INTEGER(jpim)               :: nk, nl
      INTEGER(jpim)               :: d, n, j, k, l
      INTEGER(jpim) , ALLOCATABLE :: lext(:)
      INTEGER(jpim)               :: idx_aux

      TRY

      ALLOCATE( lext (SIZE(axes)), STAT=err )
      THROW(err.NE.0)

      ! Populate extended lut coordinate array
      lext(:) = -1_jpim
      DO d = 1, SIZE(dimidx)
        lext(dimidx(d)) = coolut(d)
      ENDDO

      nk = axes(ki)%nvalues
      nl = axes(li)%nvalues

      DO k = 0, nk - 1
        DO l = 0, nl/2 - 1
        ! L2 dimension in LUT holds nl*2 values accounting for Ckl and Skl
          DO j = 1, 3   ! albedo
            ! Find index of LUT values needed
            lutidx(j,k,l,:) = 0_jpim
            ! Set non interpolating dimensions by hand
            lext(ki) = k + 1
            lext(li) = l + 1
            lext(ai) = j
            DO d = 1, SIZE(axes)
              idx_aux = lext(d) - 1
              DO n = 1, d-1
                idx_aux = idx_aux * axes(n)%nvalues
              ENDDO
              lutidx(j,k,l,1) = lutidx(j,k,l,1) + idx_aux
            ENDDO
            IF (lutidx(j,k,l,1) .LT. 0_jpim ) THEN
              err = errorstatus_fatal
              THROW(err.NE.0)
            ENDIF
            lutidx(j,k,l,1) = lutidx(j,k,l,1) + 1 ! Ckl coefficients
            lutidx(j,k,l,2) = lutidx(j,k,l,1) + nk*nl/2 ! Skl coefficients
          ENDDO ! end j loop
        ENDDO ! end l loop
      ENDDO ! end k loop

      DEALLOCATE( lext, STAT=err )
      THROW(err.NE.0)

      CATCH
    END SUBROUTINE rttov_mfasis_lut_indices

    ! Finds coefficients for nearest points in LUT, calculates linear interpolation
    ! looping over all grid points surrounding interpolation point and finally
    ! computes reflectence using Jonkheid et al 2012

    SUBROUTINE rttov_mfasis_interpolate( &
              channel,                   &  ! instrument channel
              alb,                       &  ! albedo
              ki,                        &  ! k Fourier term dimension index
              li,                        &  ! l Fourier term dimension index
              ai,                        &  ! albedo dimension index
              lblc,                      &  ! lower bound of LUT coordinates
              iwei,                      &  ! interpolation weight of nearest LUT coord
              cosk,                      &  ! precomputed theta+ cosines for Fourier expansion
              sink,                      &  ! precomputed theta+ sines for Fourier expansion
              cosl,                      &  ! precomputed theta- cosines for Fourier expansion
              dimi,                      &  ! original dimension index in LUT
              nwv ,                      &  ! number of watervapour LUTs
              iw_wv,                     &  ! number of watervapour LUTs
              mfasis_coefs,              &  ! LUT
              refl_tot,                  &  ! Computed reflectance
              err,                       &  ! error status
              refl_lin_coef)                ! coefficients for linear schemes

      IMPLICIT NONE

      INTEGER(jpim)             ,INTENT(IN)    :: channel
      REAL(jprb)                ,INTENT(IN)    :: alb
      INTEGER(jpim)             ,INTENT(IN)    :: ki
      INTEGER(jpim)             ,INTENT(IN)    :: li
      INTEGER(jpim)             ,INTENT(IN)    :: ai
      INTEGER(jpim)             ,INTENT(IN)    :: lblc(:)
      REAL(jprb)                ,INTENT(IN)    :: iwei(:)
      REAL(jprb)                ,INTENT(IN)    :: cosk(0:,0:)
      REAL(jprb)                ,INTENT(IN)    :: sink(0:,0:)
      REAL(jprb)                ,INTENT(IN)    :: cosl(0:,0:)
      INTEGER(jpim)             ,INTENT(IN)    :: dimi(:)
      INTEGER(jpim)             ,INTENT(IN)    :: nwv
      REAL(jprb)                ,INTENT(IN)    :: iw_wv(:)
      TYPE(rttov_coef_mfasis)   ,INTENT(IN)    :: mfasis_coefs
      REAL(jprb)                ,INTENT(OUT)   :: refl_tot(nwv)
      INTEGER(jpim)             ,INTENT(OUT)   :: err
      REAL(jprb) , OPTIONAL     ,INTENT(INOUT) :: refl_lin_coef(:)

      INTEGER(jpim)                :: nd, k, l, j, d, d2, m, chi
      INTEGER(jpim)                :: si, nk, nl
      REAL(jprb)   ,  ALLOCATABLE  :: weif(:)
      INTEGER(jpim),  ALLOCATABLE  :: lutc(:), aid(:)
      REAL(jprb)  ,   ALLOCATABLE  :: refl_coef(:,:,:)
      REAL(jprb)                   :: refl_aux(3,nwv), refl_aux2(3,nwv), eta, gamma
      REAL(jprb)                   :: eta_lin, gamma_lin
      REAL(jprb)                   :: lut1, lut2
      INTEGER(jpim),  ALLOCATABLE  :: indx(:,:,:,:,:)

      INTEGER(jpim)                :: iwv
      TRY

      ! --------------------------------------------------------------------------
      ! Initialization
      ! --------------------------------------------------------------------------
      nd = SIZE(lblc)          ! Number of dimensions to interpolate

      chi = mfasis_coefs%channel_lut_index(channel) ! Channel index in LUT

      ALLOCATE( weif       (0:2**nd-1), &     ! interpolation weighing factor
                lutc       (nd)       , &     ! nearest LUT coordinate
                aid        (0:2**nd-1), &     ! difference between scattering angle indices
                refl_coef  (3,nid-1,nwv), &     ! coefficients for linearized scheme
                STAT=err)
      THROW(err.NE.0)

      DO d = 1, nd
        IF (mfasis_coefs%lut_axes(dimi(d))%dim_type .EQ. mfasis_dim_scaangle ) THEN
          si = d
        ENDIF
      ENDDO

      nk = mfasis_coefs%lut_axes(ki)%nvalues
      nl = mfasis_coefs%lut_axes(li)%nvalues
      ALLOCATE( indx       (0:2**nd-1,3,0:nk-1,0:nl/2-1,2), STAT=err) ! LUT index for each albedo and fourier term
      THROW(err.NE.0)

      ! --------------------------------------------------------------------------
      ! Loop over all grid points surrounding interpolation point
      ! Nearest LUT coord and weighing factor computed
      ! --------------------------------------------------------------------------
      lutc(:) = -1_jpim
      weif(:) = -1._jprb
      DO m = 0, 2**nd - 1
        weif(m) = 1._jprb
        ! Determine LUT indices and weighing factor
        DO d = 1, nd
          IF ( BTEST( m, d-1 ) ) THEN ! check if previous grid point for di already done
            lutc(d) = lblc(d) + 1
            weif(m)  = weif(m) * iwei(d)
          ELSE
            lutc(d) = lblc(d)
            weif(m)  = weif(m) * (1._jprb - iwei(d))
          ENDIF
        ENDDO
        aid(m) = lutc(si) - lblc(si)
        ! Find position of the coeffiecients in LUT associated to this point
        CALL rttov_mfasis_lut_indices(ki, li, ai, dimi, lutc, &
          mfasis_coefs%lut_axes, indx(m,:,0:,0:,:), err)
        THROW(err.NE.0)
      ENDDO ! end of m loop

      ! --------------------------------------------------------------------------
      ! Compute reflectance for the 3 albedos
      ! --------------------------------------------------------------------------
      refl_coef(:,:,:)= 0._jprb
      refl_aux(:,:) = 0._jprb
      DO m = 0, 2**nd - 1      ! loop over all grid points surrounding interpolation point
       ! This IF is needed to work with LUTs with only one point in any of the axes
       !IF (weif(m) .EQ. 0._jprb) CYCLE
        refl_aux2(:,:) = 0._jprb
        DO k = 0, nk-1
          DO l = 0, nl/2-1
          ! L2 dimension in LUT holds nl*2 values accounting for Ckl and Skl
            DO iwv = 1, nwv   ! water vapour
              DO j = 1, 3   ! albedo
                lut1 = mfasis_coefs%lut(chi)%data(indx(m,j,k,l,1),iwv)
                lut2 = mfasis_coefs%lut(chi)%data(indx(m,j,k,l,2),iwv)
                refl_aux2(j,iwv) = refl_aux2(j,iwv) + &
                              (lut1*cosk(aid(m),k) + lut2*sink(aid(m),k))*cosl(aid(m),l)
!                refl_aux(j) = refl_aux(j)&
!                  + weif(m)*(lut1*cosk(aid(m),k) + lut2*sink(aid(m),k))*cosl(aid(m),l)
              ENDDO
            ENDDO
          ENDDO
        ENDDO
        refl_aux(1:3,:) = refl_aux(1:3,:) + weif(m)*refl_aux2(1:3,:)

      !---------------------------------------------------------------------------
      ! Compute linear sensitivities of refl_aux(:) with respect to the sensitive LUT dimensions "d"
      !          refl_coef(:,d2) = D[refl_aux(:)]/D[d]
      !
      ! Note that D[weif(m)]/D[iwei(d)] = weif(m)/iwei(d)       if BTEST( m, d-1 )
      !       or  D[weif(m)]/D[iwei(d)] = weif(m)/(1-iwei(d))   otherwise
      ! It is used that  [for  BTEST( m, d-1 )=TRUE  and m*=m-2**(d-1)]
      !                  weif(m) + weif(m*) = weif(m)/iwei(d) = weif(m*)/(1-iwei(d))
      ! and therefore
      !           D[weif(m )]/D[iwei(d)] =  [weif(m) + weif(m*)]
      !  and      D[weif(m*)]/D[iwei(d)] = -[weif(m) + weif(m*)]
      !---------------------------------------------------------------------------

        IF (PRESENT(refl_lin_coef)) THEN
          d2=0    ! make d2 / d  consistent
          DO d = 1, nd
            IF(d == si) cycle ! no tl/ad for angle
            d2=d2+1
            IF ( BTEST( m, d-1 ) ) THEN !check that "btest(m-2**(d-1))=F" !!!!!!!!!!!
!wv              refl_coef(1:3,d2,iwv)= refl_coef(1:3,d2,iwv)+ (weif(m)+weif(m-2**(d-1)))*refl_aux2(1:3,iwv)
                 refl_coef(1:3,d2,:  )= refl_coef(1:3,d2,:  )+ (weif(m)+weif(m-2**(d-1)))*refl_aux2(1:3,:  )
            ELSE
!                refl_coef(1:3,d2)= refl_coef(1:3,d2)- (weif(m)+weif(m+2**(d-1)))*refl_aux2(1:3)
!                refl_coef(1:3,d2)= refl_coef(1:3,d2)+ (weif(m)+weif(m-2**(d-1)))*refl_aux2(1:3)

!wv              refl_coef(1:3,d2,iwv)= refl_coef(1:3,d2,iwv)- (weif(m)+weif(m+2**(d-1)))*refl_aux2(1:3,iwv)
                 refl_coef(1:3,d2,:  )= refl_coef(1:3,d2,:  )- (weif(m)+weif(m+2**(d-1)))*refl_aux2(1:3,:  )

            ENDIF
          ENDDO
        ENDIF
      ENDDO ! m = 0, 2**nd - 1      ! loop over all grid points surrounding interpolation point

      ! --------------------------------------------------------------------------
      ! Compute final reflectance using Jonkheid et al 2012
      ! --------------------------------------------------------------------------
      ! This assumes refl_aux(1) corresponds to albedo 0, refl_aux(2) to 0.5
      ! and refl_aux(3) to one

    refl_tot = 0
    refl_lin_coef(:) = 0._jprb
    DO iwv = 1, nwv   ! water vapour
      eta = (refl_aux(3,iwv) - 2*refl_aux(2,iwv) + refl_aux(1,iwv))&
        /(refl_aux(3,iwv) - refl_aux(2,iwv))
      gamma = (refl_aux(3,iwv) - refl_aux(1,iwv))*(refl_aux(2,iwv)-refl_aux(1,iwv)) &
        /(refl_aux(3,iwv) - refl_aux(2,iwv))
      
!AA   refl    = refl    + iw_wv(iwv) * (refl_aux(1,iwv) + alb*gamma/(1 - alb*eta))
!     refl_tot(1) = refl_tot(1) + iw_wv(iwv) * (refl_aux(1,iwv) + alb*gamma/(1 - alb*eta))
      refl_tot(iwv) =  (refl_aux(1,iwv) + alb*gamma/(1 - alb*eta))

      ! --------------------------------------------------------------------------
      ! Compute final linear sensitivities with Jonkheid et al 2012
      ! --------------------------------------------------------------------------
      IF (PRESENT(refl_lin_coef)) THEN
        d2=0
        DO d = 1, nd
          IF(d == si) cycle ! no tl/ad for angle
          d2=d2+1
          eta_lin = (refl_coef(3,d2,iwv) - 2*refl_coef(2,d2,iwv) + refl_coef(1,d2,iwv))&
                /(refl_aux(3,iwv) - refl_aux(2,iwv))    &
                -eta* (refl_coef(3,d2,iwv) - refl_coef(2,d2,iwv))    &
                     /(refl_aux   (3,iwv) - refl_aux   (2,iwv))
          gamma_lin = ( &
             (refl_coef(3,d2,iwv) - refl_coef(1,d2,iwv))*(refl_aux   (2,iwv)-refl_aux   (1,iwv)) &
            +(refl_aux   (3,iwv) - refl_aux   (1,iwv))*(refl_coef(2,d2,iwv)-refl_coef(1,d2,iwv)) &
                    ) &
                 /(refl_aux(3,iwv) - refl_aux(2,iwv))   &
                 - gamma * (refl_coef(3,d2,iwv) - refl_coef(2,d2,iwv)) /(refl_aux(3,iwv) - refl_aux(2,iwv))


          refl_lin_coef(d) = refl_lin_coef(d) + iw_wv(iwv)*  &
                                                (refl_coef(1,d2,iwv) + alb   *gamma_lin/(1 - alb*eta)  &
                                                   + alb   *gamma * alb*eta_lin/(1 - alb*eta)**2 )

        ENDDO
        ! --------------------------------------------------------------------------
        ! sensivity w.r.t. albedo is stored in dimension "si" (i.e., the angle dimension)
        ! (note that no linear sensivity is needed for the angle which is not a TL variable)
        ! --------------------------------------------------------------------------
        refl_lin_coef(si) = refl_lin_coef(si) + iw_wv(iwv)*  &
                                                       (gamma/(1 - alb*eta) + alb*gamma*eta/(1 - alb*eta)**2)
      ENDIF
    ENDDO! iwv = 1, nwv   ! water vapour

      ! --------------------------------------------------------------------------
      ! Tidy up
      ! --------------------------------------------------------------------------

      DEALLOCATE( weif, lutc, aid, indx, refl_coef, STAT=err )
      THROW(err.NE.0)

      CATCH
    END SUBROUTINE rttov_mfasis_interpolate

END SUBROUTINE rttov_mfasis
