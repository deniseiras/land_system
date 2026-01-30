! Description:
!> @file
!!   Creates aer_opt_param.txt and cld_opt_param.txt files for the test suite
!!   from input aerosl.txt and cloud.txt files and the pre-defined aerosol and
!!   cloud optical properties.
!
!> @brief
!!   Creates aer_opt_param.txt and cld_opt_param.txt files for the test suite
!!   from input aerosl.txt and cloud.txt files and the pre-defined aerosol and
!!   cloud optical properties.
!!
!! @details
!!   This is called by rttov_test.pl to automatically generate optical property
!!   input files for the test suite. The output from the direct model for the
!!   original test (using scaer/sccld coefs) and for the test using the
!!   resulting optical property files should be identical.
!!
!!   Usage:
!!   $ rttov_make_opt_param --rtcoef_file  coef_file
!!                          --scaer_file   aer_file
!!                          --sccld_file   cld_file
!!                          --test_dir     test_dir
!!                          --nchanprof    nchanprof
!!                          --nlayers      nlayers
!!   where
!!     coef_file is the instrument rtcoef file
!!     aer_file is the aerosol coef file (mandatory if
!!       an aerosl.txt test file is present)
!!     cld_file is the cloud coef file (mandatory if
!!       a cloud.txt test file is present)
!!     test_dir is the top level test folder containing
!!       cloud and/or aerosol profiles
!!       (e.g. tests.0/seviri/081/in/)
!!     nchanprof is the size of the chanprof array
!!       associated with the test. The channels.txt and
!!       lprofiles.txt files determine the channels/
!!       profiles defined in the output file.
!!     nlayers is the number of layers in the profiles
!!
!!   This outputs an aer_opt_param.txt file if there is
!!   an aerosl.txt present in test_dir/profiles/001/atm/
!!   and it outputs a cld_opt_param.txt file if there is
!!   a cloud.txt present in test_dir/profiles/001/atm/.
!!
!!   NB For clouds it requires that the phase functions in the coef
!!      file are defined on the phangle_hires angle grid defined in
!!      rttov_const: this should always be true since this same grid
!!      is used in the sccld coef generation.
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
!    Copyright 2017, EUMETSAT, All Rights Reserved.
!
PROGRAM rttov_make_opt_param

  USE rttov_getoptions, ONLY : getoption
  USE rttov_unix_env, ONLY: rttov_iargc
  USE rttov_lun, ONLY : rttov_get_lun, rttov_put_lun

  USE parkind1, ONLY : jprb, jpim, jplm

  USE rttov_types, ONLY : &
      rttov_options,      &
      rttov_coefs,        &
      rttov_opt_param,    &
      rttov_chanprof,     &
      rttov_profile,      &
      rttov_profile_aux

  USE rttov_const, ONLY:    &
      deg2rad,              &
      nphangle_lores,       &
      phangle_lores,        &
      nphangle_hires,       &
      phangle_hires,        &
      baran_ngauss,         &
      clw_scheme_opac,      &
      ice_scheme_ssec,      &
      ice_scheme_baran2018, &
      nwcl_max

  USE rttov_scattering_mod, ONLY: &
      spline_interp,              &
      normalise,                  &
      calc_legendre_coef_gauss

  IMPLICIT NONE

#include "rttov_read_coefs.interface"
#include "rttov_dealloc_coefs.interface"
#include "rttov_alloc_opt_param.interface"
#include "rttov_alloc_prof.interface"
#include "rttov_alloc_aux_prof.interface"
#include "rttov_baran2014_calc_optpar.interface"
#include "rttov_baran2018_calc_optpar.interface"
#include "rttov_baran_calc_phase.interface"
#include "rttov_convert_profile_units.interface"
#include "rttov_profaux.interface"

  CHARACTER(256) :: rtcoef_file
  CHARACTER(256) :: scaer_file
  CHARACTER(256) :: sccld_file
  CHARACTER(256) :: test_dir
  INTEGER(jpim)  :: nchanprof
  INTEGER(jpim)  :: nlayers, nlevels
  INTEGER(jpim)  :: nmom, nmomcalc
  INTEGER(jpim)  :: nphangle

  LOGICAL(jplm)  :: exists
  CHARACTER(256) :: pathstr
  INTEGER(jpim)  :: nprof, prof, chan, phchan, lay
  INTEGER(jpim)  :: i, n, iae, iwc, k1, k2
  INTEGER(jpim)  :: naer, ncld
  LOGICAL(jplm)  :: thermal, solar
  INTEGER(jpim)  :: err, file_id
  INTEGER(jpim)  :: gas_units
  LOGICAL(jplm)  :: mmr_cldaer
  INTEGER(jpim)  :: clw_scheme, ice_scheme, idg
  REAL(jprb)     :: dgfrac, asym
  INTEGER(jpim)  :: thisnphangle
  REAL(jprb)     :: thisphangle(nphangle_hires), thiscosphangle(nphangle_hires)
  REAL(jprb)     :: baran_phfn_interp(baran_ngauss)

  REAL(jprb), ALLOCATABLE :: absch(:)
  REAL(jprb), ALLOCATABLE :: scach(:)
  REAL(jprb), ALLOCATABLE :: bparh(:)
  REAL(jprb), ALLOCATABLE :: legcoef(:,:)
  REAL(jprb), ALLOCATABLE :: phfn(:,:)

  TYPE(rttov_options)   :: opts
  TYPE(rttov_coefs)     :: coefs
  TYPE(rttov_opt_param) :: opt_param
  TYPE(rttov_chanprof), ALLOCATABLE :: chanprof(:)
  TYPE(rttov_profile),  ALLOCATABLE :: profiles(:), profiles_int(:)
  TYPE(rttov_profile_aux) :: aux

  NAMELIST / clw_scheme_nml / clw_scheme
  NAMELIST / ice_scheme_nml / idg, ice_scheme
  NAMELIST / units / gas_units
  NAMELIST / cldaer_units / mmr_cldaer

! ----------------------------------------------------------------------------

! ------------------------------------
! Process arguments
! ------------------------------------

  IF (rttov_iargc() == 0) THEN
    PRINT *, 'Usage: --rtcoef_file   input rtcoef file name'
    PRINT *, '       --scaer_file    input aerosol file name (optional)'
    PRINT *, '       --sccld_file    input cloud file name (optional)'
    PRINT *, '       --test_dir      path to test directory'
    PRINT *, '       --nchanprof     integer'
    PRINT *, '       --nlayers       integer'
    STOP
  ENDIF

  CALL getoption('--rtcoef_file', rtcoef_file, mnd=.TRUE._jplm)
  INQUIRE(FILE=rtcoef_file, EXIST=exists)
  IF (.NOT. exists) THEN
    PRINT *, 'Cannot find rtcoef file: '//TRIM(rtcoef_file)
    STOP
  ENDIF

  scaer_file = ''
  CALL getoption('--scaer_file', scaer_file)
  IF (TRIM(scaer_file) /= '') THEN
    INQUIRE(FILE=scaer_file, EXIST=exists)
    IF (.NOT. exists) THEN
      PRINT *, 'Cannot find scaer file: '//TRIM(scaer_file)
      STOP
    ENDIF
  ENDIF

  sccld_file = ''
  CALL getoption('--sccld_file', sccld_file)
  IF (TRIM(sccld_file) /= '') THEN
    INQUIRE(FILE=sccld_file, EXIST=exists)
    IF (.NOT. exists) THEN
      PRINT *, 'Cannot find sccld file: '//TRIM(sccld_file)
      STOP
    ENDIF
  ENDIF

  CALL getoption('--test_dir', test_dir, mnd=.TRUE._jplm)
  INQUIRE(FILE=TRIM(test_dir)//'/in/channels.txt', EXIST=exists)
  IF (.NOT. exists) THEN
    PRINT *, 'Cannot find valid test dir: '//TRIM(test_dir)//'/in/channels.txt'
    STOP
  ENDIF

  CALL getoption('--nchanprof', nchanprof, mnd=.TRUE._jplm)
  IF (nchanprof <= 0) THEN
    nchanprof = 1
  ENDIF

  CALL getoption('--nlayers', nlayers, mnd=.TRUE._jplm)
  IF (nlayers <= 0) THEN
    nlayers = 1
  ENDIF
  nlevels = nlayers + 1


! ------------------------------------
! Aerosols
! ------------------------------------

  IF (TRIM(scaer_file) /= '') THEN

  ! ------------------------------------
  ! Read coefs
  ! ------------------------------------
    opts%rt_ir%addaerosl = .TRUE.
    opts%rt_ir%addclouds = .FALSE.

    CALL rttov_read_coefs(err, coefs, opts, file_coef=rtcoef_file, file_scaer=scaer_file)
    opts%rt_ir%addsolar = (coefs%coef%fmv_model_ver == 9)

  ! ------------------------------------
  ! Read in data from test directory
  ! ------------------------------------

    CALL rttov_get_lun(file_id)

    ALLOCATE(chanprof(nchanprof))
    OPEN(file_id, file=TRIM(test_dir)//'/in/channels.txt', form='formatted', status='old')
    READ(file_id, *) chanprof(:)%chan
    CLOSE(file_id)
    OPEN(file_id, file=TRIM(test_dir)//'/in/lprofiles.txt', form='formatted', status='old')
    READ(file_id, *) chanprof(:)%prof
    CLOSE(file_id)

    nprof = MAXVAL(chanprof(:)%prof)

    ALLOCATE(profiles(nprof))
    ALLOCATE(profiles_int(nprof))
    CALL rttov_alloc_prof(err,      &
                          nprof,    &
                          profiles, &
                          nlevels,  &
                          opts,     &
                          1_jpim,   &
                          coefs,    &
                          .TRUE._jplm)
    CALL rttov_alloc_prof(err,          &
                          nprof,        &
                          profiles_int, &
                          nlevels,      &
                          opts,         &
                          1_jpim,       &
                          coefs,        &
                          .TRUE._jplm)
    CALL rttov_alloc_aux_prof( &
            err,                  &
            nprof,                &
            nlevels,              &
            coefs%coef%id_sensor, &
            aux,                  &
            opts,                 &
            coefs%coef,           &
            1_jpim,               &
            .TRUE._jplm,          &
            alloc_layer_vars = .FALSE._jplm)

    DO prof = 1, nprof
      WRITE(pathstr, '(A,I3.3)') TRIM(test_dir)//'/in/profiles/', prof

      OPEN(file_id, file=TRIM(pathstr)//'/atm/aerosl.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%aerosols(:,:)
      CLOSE(file_id)

      OPEN(file_id, file=TRIM(pathstr)//'/atm/p.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%p(:)
      CLOSE(file_id)
      profiles(prof)%s2m%p = profiles(prof)%p(nlevels)
      OPEN(file_id, file=TRIM(pathstr)//'/atm/t.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%t(:)
      CLOSE(file_id)
      OPEN(file_id, file=TRIM(pathstr)//'/atm/q.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%q(:)
      CLOSE(file_id)

      OPEN(file_id, file=TRIM(pathstr)//'/atm/mmr_cldaer.txt', form='formatted', status='old')
      READ(file_id, nml=cldaer_units)
      CLOSE(file_id)
      profiles(prof)%mmr_cldaer = mmr_cldaer

      INQUIRE(file=TRIM(pathstr)//'/gas_units.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/gas_units.txt', form='formatted', status='old')
        READ(file_id, nml=units)
        CLOSE(file_id)
        profiles(prof)%gas_units = gas_units
      ENDIF
    ENDDO

    CALL rttov_put_lun(file_id)

    CALL rttov_convert_profile_units(opts, coefs, profiles, profiles_int)

  ! ------------------------------------
  ! Init opt params
  ! ------------------------------------
    naer = SIZE(profiles(1)%aerosols, DIM=1)
    nmom = coefs%coef_scatt_ir%fmv_aer_maxnmom
    opts%rt_ir%dom_nstreams = nmom
    nphangle = coefs%coef_scatt_ir%aer_nphangle
    CALL rttov_alloc_opt_param(err,       &
                               opt_param, &
                               nchanprof, &
                               nlevels,   &
                               nmom,      &
                               nphangle,  &
                               1_jpim)

    ALLOCATE(absch(naer), scach(naer), bparh(naer), &
             legcoef(0:nmom,naer), phfn(nphangle,naer))

  ! ------------------------------------
  ! Compute layer relative humidities (only required for aerosols)
  ! ------------------------------------
    CALL rttov_profaux(              &
              opts,                  &
              profiles,              &
              profiles_int,          &
              coefs%coef,            &
              aux,                   &
              on_coef_levels = .FALSE._jplm)

  ! ------------------------------------
  ! Main loop
  ! ------------------------------------

    DO i = 1, nchanprof
      chan = chanprof(i)%chan
      prof = chanprof(i)%prof

      thermal = coefs%coef%ss_val_chn(chan) < 2
      solar   = coefs%coef%ss_val_chn(chan) > 0

      DO lay = 1, nlayers

        ! ------------------------------------
        ! Calculate layer abs, sca and bpr
        ! ------------------------------------

        DO iae = 1, naer
          IF (profiles_int(prof)%aerosols(iae,lay) > 0.) THEN
            CALL aer_interp_relhum(chan, nmom, iae, solar, &
                                   coefs%coef_scatt_ir, coefs%optp, aux%relhum(lay,prof), &
                                   absch(iae), scach(iae), bparh(iae), legcoef(:,iae), phfn(:,iae))
          ELSE
            absch(iae) = 0.
            scach(iae) = 0.
            bparh(iae) = 0.
            legcoef(:,iae) = 0.
            phfn(:,iae) = 0.
          ENDIF
        ENDDO

        opt_param%abs(lay,i) = SUM((/ (absch(n) * profiles_int(prof)%aerosols(n,lay), n = 1, naer) /))
        opt_param%sca(lay,i) = SUM((/ (scach(n) * profiles_int(prof)%aerosols(n,lay), n = 1, naer) /))
        IF (thermal .AND. opt_param%sca(lay,i) > 0.) THEN
          opt_param%bpr(lay,i) = SUM((/ (bparh(n) * scach(n) * &
                                         profiles_int(prof)%aerosols(n,lay), n = 1, naer) /)) / opt_param%sca(lay,i)
        ELSE
          opt_param%bpr(lay,i) = 0.
        ENDIF

        opt_param%nmom = nmom
        opt_param%legcoef(:,lay,i) = 0.
        opt_param%pha(:,lay,i) = 0.

        IF (opt_param%sca(lay,i) > 0.) THEN
          DO iae = 1, naer
            opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) + &
                                         legcoef(:,iae) * scach(iae) * profiles_int(prof)%aerosols(iae,lay)
          ENDDO
          opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) / opt_param%sca(lay,i)
        ENDIF

        IF (solar) THEN

          ! ------------------------------------
          ! Calculate layer phase fn
          ! ------------------------------------

          IF (opt_param%sca(lay,i) > 0.) THEN
            DO iae = 1, naer
              opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) + &
                                       phfn(:,iae) * scach(iae) * profiles_int(prof)%aerosols(iae,lay)
            ENDDO
            opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) / opt_param%sca(lay,i)
          ENDIF

        ENDIF

      ENDDO ! layers
    ENDDO ! chanprof

  ! ------------------------------------
  ! Write out opt_param file
  ! ------------------------------------

    CALL rttov_get_lun(file_id)

    OPEN(file_id, file=TRIM(test_dir)//'/in/aer_opt_param.txt', form='formatted')
    WRITE(file_id, *) opt_param%nmom, nphangle
    WRITE(file_id, '(10E20.12)') opt_param%abs(:,:)
    WRITE(file_id, '(10E20.12)') opt_param%sca(:,:)
    WRITE(file_id, '(10E20.12)') opt_param%bpr(:,:)
    IF (opt_param%nmom > 0) THEN
      DO i = 1, nchanprof
        DO lay = 1, nlayers
          IF (opt_param%sca(lay,i) > 0._jprb) WRITE(file_id, '(10E20.12)') opt_param%legcoef(:,lay,i)
        ENDDO
      ENDDO
    ENDIF
    IF (nphangle > 0) THEN
      WRITE(file_id, '(10E20.12)') coefs%coef_scatt_ir%aer_phangle
      DO i = 1, nchanprof
        IF (coefs%coef%ss_val_chn(chanprof(i)%chan) > 0) THEN
          DO lay = 1, nlayers
            IF (opt_param%sca(lay,i) > 0._jprb) WRITE(file_id, '(10E20.12)') opt_param%pha(:,lay,i)
          ENDDO
        ENDIF
      ENDDO
    ENDIF
    CLOSE(file_id)

    CALL rttov_put_lun(file_id)

  ! ------------------------------------
  ! Clean up
  ! ------------------------------------

    DEALLOCATE(chanprof, absch, scach, bparh, legcoef, phfn)

    CALL rttov_alloc_opt_param(err,       &
                               opt_param, &
                               nchanprof, &
                               nlevels,   &
                               nmom,      &
                               nphangle,  &
                               0_jpim)

    CALL rttov_alloc_prof(err,      &
                          nprof,    &
                          profiles, &
                          nlevels,  &
                          opts,     &
                          0_jpim,   &
                          coefs)
    DEALLOCATE(profiles)

    CALL rttov_alloc_prof(err,          &
                          nprof,        &
                          profiles_int, &
                          nlevels,      &
                          opts,         &
                          0_jpim,       &
                          coefs)
    DEALLOCATE(profiles_int)

    CALL rttov_alloc_aux_prof( &
            err,                  &
            nprof,                &
            nlevels,              &
            coefs%coef%id_sensor, &
            aux,                  &
            opts,                 &
            coefs%coef,           &
            0_jpim,               &
            alloc_layer_vars = .FALSE._jplm)

    CALL rttov_dealloc_coefs(err, coefs)

  ENDIF ! scaer file


! ------------------------------------
! Clouds
! ------------------------------------

  IF (TRIM(sccld_file) /= '') THEN

  ! ------------------------------------
  ! Read coefs
  ! ------------------------------------

    opts%rt_ir%addaerosl = .FALSE.
    opts%rt_ir%addclouds = .TRUE.

    CALL rttov_read_coefs(err, coefs, opts, file_coef=rtcoef_file, file_sccld=sccld_file)
    opts%rt_ir%addsolar = (coefs%coef%fmv_model_ver == 9)

    IF (coefs%coef_scatt_ir%wcl_nphangle > 0) THEN
      IF (coefs%coef_scatt_ir%wcl_nphangle /= nphangle_hires .OR. &
          coefs%coef_scatt_ir%icl_nphangle /= nphangle_hires) THEN
        PRINT *,'Water and ice cloud phase fn angle grids differ from phangle_hires'
        STOP
      ENDIF
      IF (ANY(ABS(coefs%coef_scatt_ir%wcl_phangle - phangle_hires) > 1.E-8_jprb) .OR. &
          ANY(ABS(coefs%coef_scatt_ir%icl_phangle - phangle_hires) > 1.E-8_jprb)) THEN
        PRINT *,'Water and ice cloud phase fn angle grids differ from phangle_hires'
        STOP
      ENDIF
    ENDIF

    IF (coefs%coef_scatt_ir%wcldeff_nphangle > 0) THEN
      IF (coefs%coef_scatt_ir%wcldeff_nphangle /= nphangle_hires) THEN
        PRINT *,'Deff clw scheme phase fn angle grid differs from phangle_hires'
        STOP
      ENDIF
      IF (ANY(ABS(coefs%coef_scatt_ir%wcldeff_phangle - phangle_hires) > 1.E-8_jprb)) THEN
        PRINT *,'Deff clw scheme phase fn angle grid differs from phangle_hires'
        STOP
      ENDIF
    ENDIF

  ! ------------------------------------
  ! Read in data from test directory
  ! ------------------------------------

    CALL rttov_get_lun(file_id)

    ALLOCATE(chanprof(nchanprof))
    OPEN(file_id, file=TRIM(test_dir)//'/in/channels.txt', form='formatted', status='old')
    READ(file_id, *) chanprof(:)%chan
    CLOSE(file_id)
    OPEN(file_id, file=TRIM(test_dir)//'/in/lprofiles.txt', form='formatted', status='old')
    READ(file_id, *) chanprof(:)%prof
    CLOSE(file_id)

    nprof = MAXVAL(chanprof(:)%prof)

    ALLOCATE(profiles(nprof))
    ALLOCATE(profiles_int(nprof))
    CALL rttov_alloc_prof(err,      &
                          nprof,    &
                          profiles, &
                          nlevels,  &
                          opts,     &
                          1_jpim,   &
                          coefs,    &
                          .TRUE._jplm)
    CALL rttov_alloc_prof(err,          &
                          nprof,        &
                          profiles_int, &
                          nlevels,      &
                          opts,         &
                          1_jpim,       &
                          coefs,        &
                          .TRUE._jplm)
    CALL rttov_alloc_aux_prof( &
            err,                  &
            nprof,                &
            nlevels,              &
            coefs%coef%id_sensor, &
            aux,                  &
            opts,                 &
            coefs%coef,           &
            1_jpim,               &
            .TRUE._jplm,          &
            alloc_layer_vars = .FALSE._jplm)

    DO prof = 1, nprof
      WRITE(pathstr, '(A,I3.3)') TRIM(test_dir)//'/in/profiles/', prof

      OPEN(file_id, file=TRIM(pathstr)//'/atm/cloud.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%cloud(:,:)
      CLOSE(file_id)

      OPEN(file_id, file=TRIM(pathstr)//'/atm/p.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%p(:)
      CLOSE(file_id)
      profiles(prof)%s2m%p = profiles(prof)%p(nlevels)
      OPEN(file_id, file=TRIM(pathstr)//'/atm/t.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%t(:)
      CLOSE(file_id)
      OPEN(file_id, file=TRIM(pathstr)//'/atm/q.txt', form='formatted', status='old')
      READ(file_id, *) profiles(prof)%q(:)
      CLOSE(file_id)

      INQUIRE(file=TRIM(pathstr)//'/atm/clwde.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/atm/clwde.txt', form='formatted', status='old')
        READ(file_id, *) profiles(prof)%clwde(:)
        CLOSE(file_id)
      ENDIF

      INQUIRE(file=TRIM(pathstr)//'/atm/clw_scheme.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/atm/clw_scheme.txt', form='formatted', status='old')
        READ(file_id, nml = clw_scheme_nml)
        CLOSE(file_id)
        profiles(prof)%clw_scheme = clw_scheme
      ENDIF

      INQUIRE(file=TRIM(pathstr)//'/atm/icede.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/atm/icede.txt', form='formatted', status='old')
        READ(file_id, *) profiles(prof)%icede(:)
        CLOSE(file_id)
      ENDIF

      INQUIRE(file=TRIM(pathstr)//'/atm/ice_scheme.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/atm/ice_scheme.txt', form='formatted', status='old')
        READ(file_id, nml = ice_scheme_nml) 
        CLOSE(file_id)
        profiles(prof)%ice_scheme = ice_scheme
        profiles(prof)%idg = idg
      ENDIF

      OPEN(file_id, file=TRIM(pathstr)//'/atm/mmr_cldaer.txt', form='formatted', status='old')
      READ(file_id, nml=cldaer_units)
      CLOSE(file_id)
      profiles(prof)%mmr_cldaer = mmr_cldaer

      INQUIRE(file=TRIM(pathstr)//'/gas_units.txt', exist=exists)
      IF (exists) THEN
        OPEN(file_id, file=TRIM(pathstr)//'/gas_units.txt', form='formatted', status='old')
        READ(file_id, nml=units)
        CLOSE(file_id)
        profiles(prof)%gas_units = gas_units
      ENDIF
    ENDDO

    CALL rttov_put_lun(file_id)

    CALL rttov_convert_profile_units(opts, coefs, profiles, profiles_int)


  ! ------------------------------------
  ! Init opt params
  ! ------------------------------------
    ncld = SIZE(profiles(1)%cloud, DIM=1)
    nmom = MAX(coefs%coef_scatt_ir%fmv_wcl_maxnmom, &
               coefs%coef_scatt_ir%fmv_wcldeff_maxnmom, &
               coefs%coef_scatt_ir%fmv_icl_maxnmom)
    opts%rt_ir%dom_nstreams = nmom
    nphangle = coefs%coef_scatt_ir%wcl_nphangle
    CALL rttov_alloc_opt_param(err,       &
                               opt_param, &
                               nchanprof, &
                               nlevels,   &
                               nmom,      &
                               nphangle,  &
                               1_jpim)

    ALLOCATE(absch(ncld), scach(ncld), bparh(ncld), &
             legcoef(0:nmom,ncld), phfn(nphangle_hires,ncld))

    ! Calculate clw and ice deff
    CALL rttov_profaux(              &
              opts,                  &
              profiles,              &
              profiles_int,          &
              coefs%coef,            &
              aux,                   &
              on_coef_levels = .FALSE._jplm)

  ! ------------------------------------
  ! Main loop
  ! ------------------------------------

    DO i = 1, nchanprof
      chan = chanprof(i)%chan
      prof = chanprof(i)%prof

      thermal = coefs%coef%ss_val_chn(chan) < 2
      solar   = coefs%coef%ss_val_chn(chan) > 0

      IF (solar) phchan = coefs%coef_scatt_ir%wcl_pha_index(chan)

      DO lay = 1, nlayers

        ! ------------------------------------
        ! Calculate layer abs, sca and bpr
        ! ------------------------------------
        absch(:) = 0.
        scach(:) = 0.
        bparh(:) = 0.
        legcoef(:,:) = 0.
        phfn(:,:) = 0._jprb

        DO iwc = 1, ncld
          IF (iwc <= nwcl_max) THEN ! Water cloud

            IF (profiles(prof)%clw_scheme == clw_scheme_opac) THEN  ! OPAC
              IF (profiles_int(prof)%cloud(iwc,lay) <= 0._jprb) CYCLE

              absch(iwc) = coefs%optp%optpwcl(iwc)%abs(chan,1)
              scach(iwc) = coefs%optp%optpwcl(iwc)%sca(chan,1)
              bparh(iwc) = coefs%optp%optpwcl(iwc)%bpr(chan,1)
              legcoef(:,iwc) = coefs%optp%optpwcl(iwc)%legcoef(:,chan,1)
              IF (solar) THEN
                phfn(:,iwc) = coefs%optp%optpwcl(iwc)%pha(:,phchan,1)
              ENDIF

            ELSE ! Deff

              IF (iwc > 1) CYCLE
              IF (SUM(profiles_int(prof)%cloud(1:nwcl_max,lay)) <= 0._jprb .OR. aux%clw_dg(lay,prof) <= 0._jprb) CYCLE

              IF (aux%clw_dg(lay,prof) >= coefs%optp%optpwcldeff%fmv_wcldeff_deff(1) .AND. &
                  aux%clw_dg(lay,prof) < coefs%optp%optpwcldeff%fmv_wcldeff_deff(coefs%coef_scatt_ir%fmv_wcldeff_ndeff)) THEN
                ! Find deff index below this channel
                DO k1 = 1, coefs%coef_scatt_ir%fmv_wcldeff_ndeff - 1
                  IF (coefs%optp%optpwcldeff%fmv_wcldeff_deff(k1+1) > aux%clw_dg(lay,prof)) EXIT
                ENDDO
                k2 = k1 + 1
                dgfrac = (aux%clw_dg(lay,prof) - coefs%optp%optpwcldeff%fmv_wcldeff_deff(k1)) / &
                          (coefs%optp%optpwcldeff%fmv_wcldeff_deff(k2) - coefs%optp%optpwcldeff%fmv_wcldeff_deff(k1))
              ELSE
                ! Take first or last value if deff lies beyond data range
                IF (aux%clw_dg(lay,prof) < coefs%optp%optpwcldeff%fmv_wcldeff_deff(1)) THEN
                  k1 = 1
                  k2 = 1
                ELSE
                  k1 = coefs%coef_scatt_ir%fmv_wcldeff_ndeff
                  k2 = coefs%coef_scatt_ir%fmv_wcldeff_ndeff
                ENDIF
                dgfrac = 0._jprb
              ENDIF
              absch(iwc) = SUM(profiles_int(prof)%cloud(1:nwcl_max,lay)) * (coefs%optp%optpwcldeff%abs(k1,chan) + dgfrac * &
                          (coefs%optp%optpwcldeff%abs(k2,chan) - coefs%optp%optpwcldeff%abs(k1,chan)))
              scach(iwc) = SUM(profiles_int(prof)%cloud(1:nwcl_max,lay)) * (coefs%optp%optpwcldeff%sca(k1,chan) + dgfrac * &
                          (coefs%optp%optpwcldeff%sca(k2,chan) - coefs%optp%optpwcldeff%sca(k1,chan)))
              bparh(iwc) = coefs%optp%optpwcldeff%bpr(k1,chan) + dgfrac * &
                          (coefs%optp%optpwcldeff%bpr(k2,chan) - coefs%optp%optpwcldeff%bpr(k1,chan))
              legcoef(:,iwc) = coefs%optp%optpwcldeff%legcoef(:,k1,chan) + dgfrac * &
                          (coefs%optp%optpwcldeff%legcoef(:,k2,chan) - coefs%optp%optpwcldeff%legcoef(:,k1,chan))
              IF (solar) THEN
                phfn(:,iwc) = coefs%optp%optpwcldeff%pha(:,k1,phchan) + dgfrac * &
                          (coefs%optp%optpwcldeff%pha(:,k2,phchan) - coefs%optp%optpwcldeff%pha(:,k1,phchan))
              ENDIF

            ENDIF

          ELSE ! Ice cloud

            IF (profiles_int(prof)%cloud(iwc,lay) <= 0._jprb) CYCLE

            IF (profiles(prof)%ice_scheme == ice_scheme_ssec) THEN ! SSEC/Baum
              IF (aux%ice_dg(lay,prof) >= coefs%optp%optpicl%fmv_icl_deff(1) .AND. &
                  aux%ice_dg(lay,prof) < coefs%optp%optpicl%fmv_icl_deff(coefs%coef_scatt_ir%fmv_icl_ndeff)) THEN
                ! Find deff index below this channel
                DO k1 = 1, coefs%coef_scatt_ir%fmv_icl_ndeff - 1
                  IF (coefs%optp%optpicl%fmv_icl_deff(k1+1) > aux%ice_dg(lay,prof)) EXIT
                ENDDO
                k2 = k1 + 1
                dgfrac = (aux%ice_dg(lay,prof) - coefs%optp%optpicl%fmv_icl_deff(k1)) / &
                          (coefs%optp%optpicl%fmv_icl_deff(k2) - coefs%optp%optpicl%fmv_icl_deff(k1))
              ELSE
                ! Take first or last value if deff lies beyond data range
                IF (aux%ice_dg(lay,prof) < coefs%optp%optpicl%fmv_icl_deff(1)) THEN
                  k1 = 1
                  k2 = 1
                ELSE
                  k1 = coefs%coef_scatt_ir%fmv_icl_ndeff
                  k2 = coefs%coef_scatt_ir%fmv_icl_ndeff
                ENDIF
                dgfrac = 0._jprb
              ENDIF
              absch(iwc) = profiles_int(prof)%cloud(ncld,lay) * (coefs%optp%optpicl%abs(k1,chan) + dgfrac * &
                          (coefs%optp%optpicl%abs(k2,chan) - coefs%optp%optpicl%abs(k1,chan)))
              scach(iwc) = profiles_int(prof)%cloud(ncld,lay) * (coefs%optp%optpicl%sca(k1,chan) + dgfrac * &
                          (coefs%optp%optpicl%sca(k2,chan) - coefs%optp%optpicl%sca(k1,chan)))
              bparh(iwc) = coefs%optp%optpicl%bpr(k1,chan) + dgfrac * &
                          (coefs%optp%optpicl%bpr(k2,chan) - coefs%optp%optpicl%bpr(k1,chan))
              legcoef(:,iwc) = coefs%optp%optpicl%legcoef(:,k1,chan) + dgfrac * &
                          (coefs%optp%optpicl%legcoef(:,k2,chan) - coefs%optp%optpicl%legcoef(:,k1,chan))
              IF (solar) THEN
                phfn(:,iwc) = coefs%optp%optpicl%pha(:,k1,phchan) + dgfrac * &
                          (coefs%optp%optpicl%pha(:,k2,phchan) - coefs%optp%optpicl%pha(:,k1,phchan))
              ENDIF

            ELSE ! Baran

              IF (profiles(prof)%ice_scheme == ice_scheme_baran2018) THEN
                CALL rttov_baran2018_calc_optpar(coefs%optp, chan, &
                    profiles(prof)%t(lay), profiles_int(prof)%cloud(ncld,lay), absch(ncld), &
                    scach(ncld), bparh(ncld), asym)
              ELSE
                CALL rttov_baran2014_calc_optpar(coefs%optp, chan, &
                    profiles(prof)%t(lay), profiles_int(prof)%cloud(ncld,lay), absch(ncld), &
                    scach(ncld), bparh(ncld), asym)
              ENDIF

              IF (solar) THEN
                ! For *all* solar channels use higher resolution angle grid
                ! (for mixed thermal+solar channels with solar scattering we need iphangle and we have this on
                !  the hi-res grid; saves calculating it for both hi-res and lo-res grids - this could be changed)
                thisnphangle = nphangle_hires
                thisphangle = phangle_hires
                thiscosphangle = coefs%optp%optpiclbaran2018%phfn_int%cosphangle
              ELSE
                thisnphangle = nphangle_lores
                thisphangle(1:nphangle_lores) = phangle_lores
                thiscosphangle(1:nphangle_lores) = COS(phangle_lores * deg2rad)
              ENDIF

              ! Compute Baran phase fn
              CALL rttov_baran_calc_phase(asym, thisphangle(1:thisnphangle), phfn(1:thisnphangle,ncld))

              ! Compute Legendre coefficients
              CALL spline_interp(thisnphangle, thiscosphangle(thisnphangle:1:-1), &
                                  phfn(thisnphangle:1:-1,ncld), baran_ngauss, &
                                  coefs%optp%optpiclbaran2018%q, baran_phfn_interp)
              CALL normalise(baran_ngauss, coefs%optp%optpiclbaran2018%w, baran_phfn_interp)
              CALL calc_legendre_coef_gauss(coefs%optp%optpiclbaran2018%q, coefs%optp%optpiclbaran2018%w, &
                                            baran_phfn_interp, nmom, nmom, nmomcalc, legcoef(:,ncld))
            ENDIF
          ENDIF
        ENDDO

        ! Combine liquid and ice properties
        IF (profiles(prof)%clw_scheme == clw_scheme_opac) THEN
          opt_param%abs(lay,i) = &
            SUM((/ (absch(n) * profiles_int(prof)%cloud(n,lay) * &
                    coefs%coef_scatt_ir%confac(n), n = 1, nwcl_max) /)) + absch(ncld)
          opt_param%sca(lay,i) = &
            SUM((/ (scach(n) * profiles_int(prof)%cloud(n,lay) * &
                    coefs%coef_scatt_ir%confac(n), n = 1, nwcl_max) /)) + scach(ncld)
          IF (thermal .AND. opt_param%sca(lay,i) > 0.) THEN
            opt_param%bpr(lay,i) = (SUM((/ (bparh(n) * scach(n) * coefs%coef_scatt_ir%confac(n) * &
                                            profiles_int(prof)%cloud(n,lay), n = 1, nwcl_max) /)) + &
                                            bparh(ncld) * scach(ncld)) / opt_param%sca(lay,i)
          ELSE
            opt_param%bpr(lay,i) = 0.
          ENDIF
        ELSE
          opt_param%abs(lay,i) = absch(1) + absch(ncld)
          opt_param%sca(lay,i) = scach(1) + scach(ncld)
          IF (thermal .AND. opt_param%sca(lay,i) > 0.) THEN
            opt_param%bpr(lay,i) = (bparh(1) * scach(1) + bparh(ncld) * scach(ncld)) / opt_param%sca(lay,i)
          ELSE
            opt_param%bpr(lay,i) = 0.
          ENDIF
        ENDIF

        opt_param%nmom = nmom
        opt_param%legcoef(:,lay,i) = 0.
        opt_param%pha(:,lay,i) = 0.

        IF (opt_param%sca(lay,i) > 0.) THEN
          opt_param%legcoef(:,lay,i) = 0.
          IF (profiles(prof)%clw_scheme == clw_scheme_opac) THEN
            DO iwc = 1, nwcl_max
              opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) + &
                  legcoef(:,iwc) * scach(iwc) * profiles_int(prof)%cloud(iwc,lay) * coefs%coef_scatt_ir%confac(iwc)
            ENDDO
          ELSE
            opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) + legcoef(:,1) * scach(1)
          ENDIF
          opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) + legcoef(:,ncld) * scach(ncld)
          opt_param%legcoef(:,lay,i) = opt_param%legcoef(:,lay,i) / opt_param%sca(lay,i)
        ENDIF

        IF (solar) THEN

          ! ------------------------------------
          ! Calculate layer phase fn
          ! ------------------------------------

          IF (opt_param%sca(lay,i) > 0.) THEN
            IF (profiles(prof)%clw_scheme == clw_scheme_opac) THEN
              DO iwc = 1, nwcl_max
                opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) + &
                    phfn(:,iwc) * scach(iwc) * profiles_int(prof)%cloud(iwc,lay) * coefs%coef_scatt_ir%confac(iwc)
              ENDDO
            ELSE
              opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) + phfn(:,1) * scach(1)
            ENDIF
            opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) + phfn(:,ncld) * scach(ncld)
            opt_param%pha(:,lay,i) = opt_param%pha(:,lay,i) / opt_param%sca(lay,i)
          ENDIF

        ENDIF

      ENDDO ! layers
    ENDDO ! chanprof

  ! ------------------------------------
  ! Write out opt_param file
  ! ------------------------------------

    CALL rttov_get_lun(file_id)

    OPEN(file_id, file=TRIM(test_dir)//'/in/cld_opt_param.txt', form='formatted')
    WRITE(file_id, *) opt_param%nmom, nphangle
    WRITE(file_id, '(10E20.12)') opt_param%abs(:,:)
    WRITE(file_id, '(10E20.12)') opt_param%sca(:,:)
    WRITE(file_id, '(10E20.12)') opt_param%bpr(:,:)
    IF (opt_param%nmom > 0) THEN
      DO i = 1, nchanprof
        DO lay = 1, nlayers
          IF (opt_param%sca(lay,i) > 0._jprb) WRITE(file_id, '(10E20.12)') opt_param%legcoef(:,lay,i)
        ENDDO
      ENDDO
    ENDIF
    IF (nphangle > 0) THEN
      WRITE(file_id, '(10E20.12)') phangle_hires
      DO i = 1, nchanprof
        IF (coefs%coef%ss_val_chn(chanprof(i)%chan) > 0) THEN
          DO lay = 1, nlayers
            IF (opt_param%sca(lay,i) > 0._jprb) WRITE(file_id, '(10E20.12)') opt_param%pha(:,lay,i)
          ENDDO
        ENDIF
      ENDDO
    ENDIF
    CLOSE(file_id)

    CALL rttov_put_lun(file_id)

  ! ------------------------------------
  ! Clean up
  ! ------------------------------------

    DEALLOCATE(chanprof, absch, scach, bparh, legcoef, phfn)

    CALL rttov_alloc_opt_param(err,       &
                               opt_param, &
                               nchanprof, &
                               nlevels,   &
                               nmom,      &
                               nphangle,  &
                               0_jpim)

    CALL rttov_alloc_prof(err,      &
                          nprof,    &
                          profiles, &
                          nlevels,  &
                          opts,     &
                          0_jpim,   &
                          coefs)
    DEALLOCATE(profiles)

    CALL rttov_alloc_prof(err,          &
                          nprof,        &
                          profiles_int, &
                          nlevels,      &
                          opts,         &
                          0_jpim,       &
                          coefs)
    DEALLOCATE(profiles_int)

    CALL rttov_alloc_aux_prof( &
            err,                  &
            nprof,                &
            nlevels,              &
            coefs%coef%id_sensor, &
            aux,                  &
            opts,                 &
            coefs%coef,           &
            0_jpim,               &
            alloc_layer_vars = .FALSE._jplm)

    CALL rttov_dealloc_coefs(err, coefs)

  ENDIF ! sccld file

CONTAINS

  ! We need a special version of this subroutine which calculates all parameters regardless
  ! of options (bpr, legcoefs, phfn). The one in rttov_scattering_mod only calculates what
  ! is required for the simulation being carried out
  SUBROUTINE aer_interp_relhum(chan, dom_nstr, iaer, solar, coef_scatt_ir, optp, relhum, &
                               absch, scach, bparh, legcoef, phfn)

    USE parkind1, ONLY : jprb, jpim, jplm

    USE rttov_types, ONLY : &
      rttov_coef_scatt_ir,  &
      rttov_optpar_ir

    IMPLICIT NONE

    INTEGER(jpim),             INTENT(IN)    :: chan, dom_nstr, iaer
    LOGICAL(jplm),             INTENT(IN)    :: solar
    TYPE(rttov_coef_scatt_ir), INTENT(IN)    :: coef_scatt_ir
    TYPE(rttov_optpar_ir),     INTENT(IN)    :: optp
    REAL(jprb),                INTENT(IN)    :: relhum
    REAL(jprb),                INTENT(INOUT) :: absch, scach, bparh
    REAL(jprb),                INTENT(INOUT) :: legcoef(0:)
    REAL(jprb),                INTENT(INOUT) :: phfn(coef_scatt_ir%aer_nphangle)

    INTEGER(jpim) :: k, phchan, nmom
    REAL(jprb)    :: frach
    REAL(jprb)    :: afac, sfac, gfac
    REAL(jprb)    :: pfac1(0:dom_nstr)
    REAL(jprb)    :: pfac2(coef_scatt_ir%aer_nphangle)
    ! ------------------------------------------------------------------------

    k = coef_scatt_ir%fmv_aer_rh(iaer)
    IF (k /= 1 .AND. aux%relhum(lay,prof) <= optp%optpaer(iaer)%fmv_aer_rh_val(k)) THEN
      ! Interpolate scattering parameters to actual value of relative humidity
      DO k = 1, coef_scatt_ir%fmv_aer_rh(iaer) - 1
        IF (relhum >= optp%optpaer(iaer)%fmv_aer_rh_val(k) .AND. &
            relhum <= optp%optpaer(iaer)%fmv_aer_rh_val(k+1)) THEN

          frach = (relhum - optp%optpaer(iaer)%fmv_aer_rh_val(k)) / &
                  (optp%optpaer(iaer)%fmv_aer_rh_val(k+1) - &
                   optp%optpaer(iaer)%fmv_aer_rh_val(k))
          afac  = (optp%optpaer(iaer)%abs(chan,k+1) - optp%optpaer(iaer)%abs(chan,k))
          absch = optp%optpaer(iaer)%abs(chan,k) + afac * frach
          sfac  = (optp%optpaer(iaer)%sca(chan,k+1) - optp%optpaer(iaer)%sca(chan,k))
          scach = optp%optpaer(iaer)%sca(chan,k) + sfac * frach

          gfac  = (optp%optpaer(iaer)%bpr(chan,k+1) - optp%optpaer(iaer)%bpr(chan,k))
          bparh = optp%optpaer(iaer)%bpr(chan,k) + gfac * frach

          nmom = MIN(MAX(optp%optpaer(iaer)%nmom(chan,k), optp%optpaer(iaer)%nmom(chan,k+1)), dom_nstr)
          pfac1(0:nmom) = (optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k+1) - &
                           optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k))
          legcoef(0:nmom) = optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k) + pfac1(0:nmom) * frach

          IF (solar) THEN
            phchan = coef_scatt_ir%aer_pha_index(chan)
            pfac2(:) = (optp%optpaer(iaer)%pha(:,phchan,k+1) - &
                        optp%optpaer(iaer)%pha(:,phchan,k))
            phfn(:) = optp%optpaer(iaer)%pha(:,phchan,k) + pfac2(:) * frach
          ENDIF
          EXIT
        ENDIF
      ENDDO
    ELSE
      ! Particle doesn't change with rel. hum. (k=1) or rel. hum. exceeds max (k=max_rh_index)
      absch = optp%optpaer(iaer)%abs(chan,k)
      scach = optp%optpaer(iaer)%sca(chan,k)
      bparh = optp%optpaer(iaer)%bpr(chan,k)
      nmom = MIN(optp%optpaer(iaer)%nmom(chan,k), dom_nstr)
      legcoef(0:nmom) = optp%optpaer(iaer)%legcoef(1:nmom+1,chan,k)
      IF (solar) THEN
        phchan = coef_scatt_ir%aer_pha_index(chan)
        phfn(:) = optp%optpaer(iaer)%pha(:,phchan,k)
      ENDIF
    ENDIF
  END SUBROUTINE aer_interp_relhum

END PROGRAM rttov_make_opt_param
