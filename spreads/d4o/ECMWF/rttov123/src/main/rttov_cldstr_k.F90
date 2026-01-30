! Description:
!> @file
!!   K of cloud stream (column) computation for visible/IR scattering simulations
!
!> @brief
!!   K of cloud stream (column) computation for visible/IR scattering simulations
!!
!!
!! @param[in]     opts_rt_ir          visible/IR-specific options structure
!! @param[in]     chanprof            specifies channels and profiles to simulate
!! @param[in]     profiles            input atmospheric profiles and surface variables
!! @param[in,out] profiles_k          atmospheric profile increments
!! @param[in]     profiles_int        input atmospheric profiles converted to RTTOV internal units
!! @param[in,out] ircld               cloud column data
!! @param[in,out] ircld_k             cloud column increments
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
!    Copyright 2015, EUMETSAT, All Rights Reserved.
!
SUBROUTINE rttov_cldstr_k( &
              opts_rt_ir,   &
              chanprof,     &
              profiles,     &
              profiles_k,   &
              profiles_int, &
              ircld,        &
              ircld_k)

  USE rttov_types, ONLY :  &
         rttov_chanprof,   &
         rttov_profile,    &
         rttov_opts_rt_ir, &
         rttov_ircld
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
  USE rttov_const, ONLY : realtol
!INTF_ON
  IMPLICIT NONE
  TYPE(rttov_opts_rt_ir), INTENT(IN)    :: opts_rt_ir
  TYPE(rttov_chanprof),   INTENT(IN)    :: chanprof(:)
  TYPE(rttov_profile),    INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),    INTENT(INOUT) :: profiles_k(SIZE(chanprof))
  TYPE(rttov_profile),    INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld_k
!INTF_END

  INTEGER(KIND=jpim) :: i, j, istr, ijstr, ilay, ic, jpk
  INTEGER(KIND=jpim) :: nchannels
  INTEGER(KIND=jpim) :: ibdy_layer(1), imax_cfrac(1)
  REAL   (KIND=jprb) :: cfrac_max, cloud_tot(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: cfrac_max_k 
  REAL   (KIND=jprb) :: ntot(profiles(1)%nlevels)
  INTEGER(KIND=jpim) :: icount1ref(2*profiles(1)%nlayers)
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-----End of header-------------------------------------------------------------
!---------Compute number of streams and cloud distribution in each stream-------
  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_K', 0_jpim, ZHOOK_HANDLE)
  nchannels = SIZE(chanprof)

  IF (opts_rt_ir%cldstr_simple) THEN

    ! A simpler, faster, but quite approximate "Cmax" single-stream approach. 
    ! Main benefit is that it is much more memory efficient. Intended mainly
    ! for mid- and upper-tropospheric channels.
    DO j = 1, nchannels
      jpk = chanprof(j)%prof

      ! Find maximum cloud fraction and cloud amount above the boundary layer
      ! NB pressure is on levels, cloud in layers, so p(1:nlevels-1) is the top of the layer
      ibdy_layer = MINLOC(ABS(profiles(jpk)%p(:) - opts_rt_ir%cldstr_low_cloud_top))
      ibdy_layer(1) = MIN(ibdy_layer(1), profiles(jpk)%nlayers)
      imax_cfrac = MAXLOC(profiles(jpk)%cfrac(1:ibdy_layer(1)))
      cfrac_max  = profiles(jpk)%cfrac(imax_cfrac(1))
      cloud_tot(:) = SUM(profiles_int(jpk)%cloud(:,:), DIM=1)

      cfrac_max_k = 0._jprb

      ! Ignoring trivial amounts of cloud and precip
      IF (ANY(cloud_tot(1:ibdy_layer(1)) > 1E-6_jprb) .AND. cfrac_max > 1E-3_jprb) THEN

        ! Cloudy stream required
        cfrac_max_k = cfrac_max_k + ircld_k%xstr(2,j)
        cfrac_max_k = cfrac_max_k - ircld_k%xstrclr(j)

      ENDIF

      profiles_k(j)%cfrac(imax_cfrac(1)) = profiles_k(j)%cfrac(imax_cfrac(1)) + cfrac_max_k

    ENDDO

  ELSE

    DO j = 1, nchannels
      jpk = chanprof(j)%prof
      loop2 : DO istr = 2, ircld%icount(jpk) - 1
        DO i = istr - 1, 1, -1
          ircld%xstrref1(istr, i, jpk) = ircld%xstrref(i, jpk)
          IF (ircld%xstrref(i, jpk) <= ircld%a(istr, jpk)) THEN
            ircld%xstrref(i + 1, jpk) = ircld%a(istr, jpk)
            CYCLE loop2
          ELSE
            ircld%xstrref(i + 1, jpk) = ircld%xstrref(i, jpk)
          ENDIF
        ENDDO
        i = 0
        ircld%xstrref(i + 1, jpk) = ircld%a(istr, jpk)
      ENDDO loop2
      ircld_k%a(:, j)       = 0._jprb
      ircld_k%maxcov(:, j)  = 0._jprb
      ircld_k%cldcfr(:, j)  = 0._jprb
      ircld_k%xstrmin(:, j) = 0._jprb
      ircld_k%xstrmax(:, j) = 0._jprb
      ntot(:)               = 0._jprb
  !---------Consider only the streams whose weight is greater than cldstr_threshold-------
      IF (ircld%nstreamref(jpk) /= 0_jpim) THEN
        IF (ircld%icounstr(jpk) /= 0_jpim) THEN
          ircld_k%xstr(ircld%icounstr(jpk) + 1, j) = ircld_k%xstr(ircld%icounstr(jpk) + 1, j) - ircld_k%xstrclr(j)
          ircld_k%xstr(1, j)                       = ircld_k%xstr(1, j) + ircld_k%xstrclr(j)
          ircld_k%xstrclr(j)                       = 0._jprb
          DO istr = ircld%icounstr(jpk) + 1, 1, -1
            IF (istr == 1) THEN
              IF (ircld%indexstr(istr, jpk) /= istr) THEN
                ircld_k%xstr(ircld%indexstr(istr, jpk), j) =      &
                    ircld_k%xstr(ircld%indexstr(istr, jpk), j) + ircld_k%xstr(istr, j)
                ircld_k%xstr(istr, j)                      = 0._jprb
              ENDIF
            ELSE
              ircld_k%xstr(istr - 1, j) = ircld_k%xstr(istr - 1, j) + ircld_k%xstr(istr, j)
              IF ((ircld%indexstr(istr - 1, jpk) + 1) /= istr) THEN
                ircld_k%xstr(ircld%indexstr(istr - 1, jpk) + 1, j) =      &
                    ircld_k%xstr(ircld%indexstr(istr - 1, jpk) + 1, j) + ircld_k%xstr(istr, j)
              ELSE
                ircld_k%xstr(ircld%indexstr(istr - 1, jpk) + 1, j) = ircld_k%xstr(istr, j)
              ENDIF
              IF (ircld%indexstr(istr - 1, jpk) /= istr) THEN
                ircld_k%xstr(ircld%indexstr(istr - 1, jpk), j) =      &
                    ircld_k%xstr(ircld%indexstr(istr - 1, jpk), j) - ircld_k%xstr(istr, j)
              ELSE
                ircld_k%xstr(ircld%indexstr(istr - 1, jpk), j) =  - ircld_k%xstr(istr, j)
              ENDIF
              IF (((ircld%indexstr(istr - 1, jpk) + 1) /= istr) .AND. (ircld%indexstr(istr - 1, jpk) /= istr)) THEN
                ircld_k%xstr(istr, j) = 0._jprb
              ENDIF
            ENDIF
          ENDDO
        ELSE
          ircld_k%xstrclr(j) = 0._jprb
        ENDIF
      ENDIF
  !---------Compute the weight of the clear stream--------------------------------
      ircld_k%xstr(ircld%nstreamref(jpk) + 1, j) = ircld_k%xstr(ircld%nstreamref(jpk) + 1, j) - ircld_k%xstrclr(j)
      ircld_k%xstr(1, j)                         = ircld_k%xstr(1, j) + ircld_k%xstrclr(j)
  !---------Re-arrange the limits of each stream in ascending order---------------
      outer : DO i = ircld%iloop(jpk), 1, -1
        icount1ref(i) = ircld%icount1ref(i, jpk)
        inner : DO istr = ircld%iloopin(i, jpk), 1, -1
          IF (ircld%xstrref2(i, istr, jpk) == ircld%xstrref2(i, istr + 1, jpk)) THEN
            IF (ircld%xstrref2(i, istr, jpk) < 1._jprb) THEN
              icount1ref(i) = icount1ref(i) - 1
              DO ijstr = icount1ref(i), istr, -1
                ircld_k%xstr(ijstr + 1, j) = ircld_k%xstr(ijstr + 1, j) + ircld_k%xstr(ijstr, j)
                ircld_k%xstr(ijstr, j)     = 0._jprb
              ENDDO
            ENDIF
          ENDIF
        ENDDO inner
      ENDDO outer
      loop1 : DO istr = ircld%icount(jpk) - 1, 2, -1
        IF (.NOT. ircld%flag(istr, jpk)) THEN
          ircld_k%a(istr, j) = ircld_k%a(istr, j) + ircld_k%xstr(1, j)
          ircld_k%xstr(1, j) = 0._jprb                                    !
        ENDIF
        DO i = ircld%iflag(istr, jpk), istr - 1
          IF (ircld%xstrref1(istr, i, jpk) <= ircld%a(istr, jpk)) THEN
            ircld_k%a(istr, j)     = ircld_k%a(istr, j) + ircld_k%xstr(i + 1, j)
            ircld_k%xstr(i + 1, j) = 0._jprb
          ELSE
            ircld_k%xstr(i, j)     = ircld_k%xstr(i, j) + ircld_k%xstr(i + 1, j)
            ircld_k%xstr(i + 1, j) = 0._jprb
          ENDIF
        ENDDO
        ircld_k%xstr(istr, j) = ircld_k%xstr(istr, j) + ircld_k%a(istr, j)
        ircld_k%a(istr, j)    = 0._jprb
      ENDDO loop1
  !---------Determine the limits of each stream----------------------------------
      ic = ircld%icount(jpk)
      DO ilay = profiles(1)%nlayers, 1, -1
        IF (ircld%xstrmax(ilay, jpk) > 0._jprb) THEN
          ic = ic - 1
          ircld_k%xstrmax(ilay, j) = ircld_k%xstrmax(ilay, j) + ircld_k%xstr(ic, j)
          ic = ic - 1
          ircld_k%xstrmin(ilay, j) = ircld_k%xstrmin(ilay, j) + ircld_k%xstr(ic, j)
        ENDIF
        IF (ircld%xstrminref(ilay, jpk) < 0._jprb) THEN
          ircld_k%xstrmin(ilay, j) = 0._jprb
        ENDIF
        ntot(ilay)              = ntot(ilay) + ircld_k%xstrmin(ilay, j)
        ircld_k%cldcfr(ilay, j) = ircld_k%cldcfr(ilay, j) - ircld_k%xstrmin(ilay, j)
        ntot(ilay)              = ntot(ilay) + ircld_k%xstrmax(ilay, j)
      ENDDO
  !---------Compute the cumulative cloud coverage using the maximum-random---------
  !         overlap assumption
      DO ilay = profiles(1)%nlayers, 1, -1
        IF (ircld%cldcfr(ilay, jpk) > 0._jprb) THEN
          ntot(ilay) =  - ntot(ilay)
        ELSE
          ntot(ilay) = 0._jprb
        ENDIF
      ENDDO
      DO ilay = profiles(1)%nlayers, 2, -1
        IF (ircld%ntotref(ilay - 1, jpk) == 0._jprb .AND. ABS(ircld%cldcfr(ilay - 1, jpk) - 1._jprb) < realtol) THEN
          ircld_k%maxcov(ilay, j) = ircld_k%maxcov(ilay, j) + ntot(ilay)
        ELSEIF (ABS(ircld%cldcfr(ilay - 1, jpk) - 1._jprb) < realtol) THEN
          ntot(ilay - 1)              =      &
              ntot(ilay - 1) + ntot(ilay)
        ELSE
          ntot(ilay - 1)              =      &
              ntot(ilay - 1) + ntot(ilay) * ircld%maxcov(ilay, jpk) / (1._jprb - ircld%cldcfr(ilay - 1, jpk))
          ircld_k%cldcfr(ilay - 1, j) = ircld_k%cldcfr(ilay - 1, j) +                &
              ntot(ilay) * ircld%ntotref(ilay - 1, jpk) * ircld%maxcov(ilay, jpk) /  &
              (1._jprb - ircld%cldcfr(ilay - 1, jpk)) ** 2
          ircld_k%maxcov(ilay, j)     =      &
              ircld_k%maxcov(ilay, j) + ntot(ilay) * ircld%ntotref(ilay - 1, jpk) / (1._jprb - ircld%cldcfr(ilay - 1, jpk))
        ENDIF
        IF ((ircld%cldcfr(ilay - 1, jpk) > ircld%cldcfr(ilay, jpk))) THEN
          ircld_k%cldcfr(ilay - 1, j) = ircld_k%cldcfr(ilay - 1, j) - ircld_k%maxcov(ilay, j)
          ircld_k%maxcov(ilay, j)     = 0._jprb
        ELSE
          ircld_k%cldcfr(ilay, j) = ircld_k%cldcfr(ilay, j) - ircld_k%maxcov(ilay, j)
          ircld_k%maxcov(ilay, j) = 0._jprb
        ENDIF
      ENDDO
      ircld_k%cldcfr(1, j) = ircld_k%cldcfr(1, j) - ntot(1)

      DO ilay = profiles(1)%nlayers, 1, -1
        IF (profiles(jpk)%cfrac(ilay) > 0._jprb) THEN
          profiles_k(j)%cfrac(ilay) = profiles_k(j)%cfrac(ilay) + ircld_k%cldcfr(ilay, j)
        ENDIF
      ENDDO
      ircld_k%cldcfr(:, j)  = 0._jprb
      ircld_k%xstrmin(:, j) = 0._jprb
      ircld_k%xstrmax(:, j) = 0._jprb
      ircld_k%xstr(:, j) = 0._jprb
      ntot = 0._jprb
    ENDDO
  ENDIF
  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_K', 1_jpim, ZHOOK_HANDLE)
!      ircld_k(:)%xstrclr=0._jprb
END SUBROUTINE rttov_cldstr_k
