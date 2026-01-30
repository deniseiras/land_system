! Description:
!> @file
!!   AD of cloud stream (column) computation for visible/IR scattering simulations
!
!> @brief
!!   AD of cloud stream (column) computation for visible/IR scattering simulations
!!
!!
!! @param[in]     opts_rt_ir          visible/IR-specific options structure
!! @param[in]     profiles            input atmospheric profiles and surface variables
!! @param[in,out] profiles_ad         atmospheric profile increments
!! @param[in]     profiles_int        input atmospheric profiles converted to RTTOV internal units
!! @param[in,out] ircld               cloud column data
!! @param[in,out] ircld_ad            cloud column increments
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
SUBROUTINE rttov_cldstr_ad( &
              opts_rt_ir,   &
              profiles,     &
              profiles_ad,  &
              profiles_int, &
              ircld,        &
              ircld_ad)

  USE rttov_types, ONLY : rttov_profile, rttov_ircld, rttov_opts_rt_ir
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
  USE rttov_const, ONLY : realtol
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_opts_rt_ir), INTENT(IN)    :: opts_rt_ir
  TYPE(rttov_profile),    INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),    INTENT(INOUT) :: profiles_ad(SIZE(profiles))
  TYPE(rttov_profile),    INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld_ad
!INTF_END

  INTEGER(KIND=jpim) :: i, j, istr, ijstr, ilay, ic
  INTEGER(KIND=jpim) :: nprofiles
  INTEGER(KIND=jpim) :: ibdy_layer(1), imax_cfrac(1)
  REAL   (KIND=jprb) :: cfrac_max, cloud_tot(profiles(1)%nlayers) 
  REAL   (KIND=jprb) :: cfrac_max_ad 
  REAL   (KIND=jprb) :: ntot(profiles(1)%nlevels)
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-----End of header-------------------------------------------------------------
!---------Compute number of streams and cloud distribution in each stream-------
  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_AD', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(profiles)

  IF (opts_rt_ir%cldstr_simple) THEN

    ! A simpler, faster, but quite approximate "Cmax" single-stream approach. 
    ! Main benefit is that it is much more memory efficient. Intended mainly
    ! for mid- and upper-tropospheric channels.
    DO j = 1, nprofiles

      ! Find maximum cloud fraction and cloud amount above the boundary layer
      ! NB pressure is on levels, cloud in layers, so p(1:nlevels-1) is the top of the layer
      ibdy_layer = MINLOC(ABS(profiles(j)%p(:) - opts_rt_ir%cldstr_low_cloud_top))
      ibdy_layer(1) = MIN(ibdy_layer(1), profiles(j)%nlayers)
      imax_cfrac = MAXLOC(profiles(j)%cfrac(1:ibdy_layer(1)))
      cfrac_max  = profiles(j)%cfrac(imax_cfrac(1))
      cloud_tot(:) = SUM(profiles_int(j)%cloud(:,:), DIM=1)

      cfrac_max_ad = 0._jprb

      ! Ignoring trivial amounts of cloud and precip
      IF (ANY(cloud_tot(1:ibdy_layer(1)) > 1E-6_jprb) .AND. cfrac_max > 1E-3_jprb) THEN

        ! Cloudy stream required
        cfrac_max_ad = cfrac_max_ad + ircld_ad%xstr(2,j)
        cfrac_max_ad = cfrac_max_ad - ircld_ad%xstrclr(j)

      ENDIF

      profiles_ad(j)%cfrac(imax_cfrac(1)) = profiles_ad(j)%cfrac(imax_cfrac(1)) + cfrac_max_ad

    ENDDO

  ELSE

    DO j = 1, nprofiles
      loop2 : DO istr = 2, ircld%icount(j) - 1
        DO i = istr - 1, 1, -1
          ircld%xstrref1(istr, i, j) = ircld%xstrref(i, j)
          IF (ircld%xstrref(i, j) <= ircld%a(istr, j)) THEN
            ircld%xstrref(i + 1, j) = ircld%a(istr, j)
            CYCLE loop2
          ELSE
            ircld%xstrref(i + 1, j) = ircld%xstrref(i, j)
          ENDIF
        ENDDO
        i = 0
        ircld%xstrref(i + 1, j) = ircld%a(istr, j)
      ENDDO loop2
      ircld_ad%a(:, j)       = 0._jprb
      ircld_ad%maxcov(:, j)  = 0._jprb
      ircld_ad%cldcfr(:, j)  = 0._jprb
      ircld_ad%xstrmin(:, j) = 0._jprb
      ircld_ad%xstrmax(:, j) = 0._jprb
      ntot(:)                = 0._jprb
  !---------Consider only the streams whose weight is greater than cldstr_threshold-------
      IF (ircld%nstreamref(j) /= 0_jpim) THEN
        IF (ircld%icounstr(j) /= 0_jpim) THEN
          ircld_ad%xstr(ircld%icounstr(j) + 1, j) = ircld_ad%xstr(ircld%icounstr(j) + 1, j) - ircld_ad%xstrclr(j)
          ircld_ad%xstr(1, j)                     = ircld_ad%xstr(1, j) + ircld_ad%xstrclr(j)
          ircld_ad%xstrclr(j)                     = 0._jprb
          DO istr = ircld%icounstr(j) + 1, 1, -1
            IF (istr == 1) THEN
              IF (ircld%indexstr(istr, j) /= istr) THEN
                ircld_ad%xstr(ircld%indexstr(istr, j), j) =      &
                    ircld_ad%xstr(ircld%indexstr(istr, j), j) + ircld_ad%xstr(istr, j)
                ircld_ad%xstr(istr, j)                    = 0._jprb
              ENDIF
            ELSE
              ircld_ad%xstr(istr - 1, j) = ircld_ad%xstr(istr - 1, j) + ircld_ad%xstr(istr, j)
              IF ((ircld%indexstr(istr - 1, j) + 1) /= istr) THEN
                ircld_ad%xstr(ircld%indexstr(istr - 1, j) + 1, j) =      &
                    ircld_ad%xstr(ircld%indexstr(istr - 1, j) + 1, j) + ircld_ad%xstr(istr, j)
              ELSE
                ircld_ad%xstr(ircld%indexstr(istr - 1, j) + 1, j) = ircld_ad%xstr(istr, j)
              ENDIF
              IF (ircld%indexstr(istr - 1, j) /= istr) THEN
                ircld_ad%xstr(ircld%indexstr(istr - 1, j), j) =      &
                    ircld_ad%xstr(ircld%indexstr(istr - 1, j), j) - ircld_ad%xstr(istr, j)
              ELSE
                ircld_ad%xstr(ircld%indexstr(istr - 1, j), j) =  - ircld_ad%xstr(istr, j)
              ENDIF
              IF (((ircld%indexstr(istr - 1, j) + 1) /= istr) .AND. (ircld%indexstr(istr - 1, j) /= istr)) THEN
                ircld_ad%xstr(istr, j) = 0._jprb
              ENDIF
            ENDIF
          ENDDO
        ELSE
          ircld_ad%xstrclr(j) = 0._jprb
        ENDIF
      ENDIF
  !---------Compute the weight of the clear stream--------------------------------
      ircld_ad%xstr(ircld%nstreamref(j) + 1, j) = ircld_ad%xstr(ircld%nstreamref(j) + 1, j) - ircld_ad%xstrclr(j)
      ircld_ad%xstr(1, j)                       = ircld_ad%xstr(1, j) + ircld_ad%xstrclr(j)
  !---------Re-arrange the limits of each stream in ascending order---------------
      outer : DO i = ircld%iloop(j), 1, -1
        inner : DO istr = ircld%iloopin(i, j), 1, -1
          IF (ircld%xstrref2(i, istr, j) == ircld%xstrref2(i, istr + 1, j)) THEN
            IF (ircld%xstrref2(i, istr, j) < 1._jprb) THEN
              ircld%icount1ref(i, j) = ircld%icount1ref(i, j) - 1
              DO ijstr = ircld%icount1ref(i, j), istr, -1
                ircld_ad%xstr(ijstr + 1, j) = ircld_ad%xstr(ijstr + 1, j) + ircld_ad%xstr(ijstr, j)
                ircld_ad%xstr(ijstr, j)     = 0._jprb
              ENDDO
            ENDIF
          ENDIF
        ENDDO inner
      ENDDO outer
      loop1 : DO istr = ircld%icount(j) - 1, 2, -1
        IF (.NOT. ircld%flag(istr, j)) THEN
          ircld_ad%a(istr, j) = ircld_ad%a(istr, j) + ircld_ad%xstr(1, j)
          ircld_ad%xstr(1, j) = 0._jprb                                      !
        ENDIF
        DO i = ircld%iflag(istr, j), istr - 1
          IF (ircld%xstrref1(istr, i, j) <= ircld%a(istr, j)) THEN
            ircld_ad%a(istr, j)     = ircld_ad%a(istr, j) + ircld_ad%xstr(i + 1, j)
            ircld_ad%xstr(i + 1, j) = 0._jprb
          ELSE
            ircld_ad%xstr(i, j)     = ircld_ad%xstr(i, j) + ircld_ad%xstr(i + 1, j)
            ircld_ad%xstr(i + 1, j) = 0._jprb
          ENDIF
        ENDDO
        ircld_ad%xstr(istr, j) = ircld_ad%xstr(istr, j) + ircld_ad%a(istr, j)
        ircld_ad%a(istr, j)    = 0._jprb
      ENDDO loop1
  !---------Determine the limits of each stream----------------------------------
      ic = ircld%icount(j)
      DO ilay = profiles(1)%nlayers, 1, -1
        IF (ircld%xstrmax(ilay, j) > 0._jprb) THEN
          ic = ic - 1
          ircld_ad%xstrmax(ilay, j) = ircld_ad%xstrmax(ilay, j) + ircld_ad%xstr(ic, j)
          ic = ic - 1
          ircld_ad%xstrmin(ilay, j) = ircld_ad%xstrmin(ilay, j) + ircld_ad%xstr(ic, j)
        ENDIF
        IF (ircld%xstrminref(ilay, j) < 0._jprb) THEN
          ircld_ad%xstrmin(ilay, j) = 0._jprb
        ENDIF
        ntot(ilay)               = ntot(ilay) + ircld_ad%xstrmin(ilay, j)
        ircld_ad%cldcfr(ilay, j) = ircld_ad%cldcfr(ilay, j) - ircld_ad%xstrmin(ilay, j)
        ntot(ilay)               = ntot(ilay) + ircld_ad%xstrmax(ilay, j)
      ENDDO
  !---------Compute the cumulative cloud coverage using the maximum-random---------
  !         overlap assumption
      DO ilay = profiles(1)%nlayers, 1, -1
        IF (ircld%cldcfr(ilay, j) > 0._jprb) THEN
          ntot(ilay) =  - ntot(ilay)
        ELSE
          ntot(ilay) = 0._jprb
        ENDIF
      ENDDO
      DO ilay = profiles(1)%nlayers, 2, -1
        IF (ircld%ntotref(ilay - 1, j) == 0._jprb .AND. ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ircld_ad%maxcov(ilay, j) = ircld_ad%maxcov(ilay, j) + ntot(ilay)
        ELSEIF (ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ntot(ilay - 1)               =      &
              ntot(ilay - 1) + ntot(ilay)
        ELSE
          ntot(ilay - 1)               =      &
              ntot(ilay - 1) + ntot(ilay) * ircld%maxcov(ilay, j) / (1._jprb - ircld%cldcfr(ilay - 1, j))
          ircld_ad%cldcfr(ilay - 1, j) = ircld_ad%cldcfr(ilay - 1, j) +      &
              ntot(ilay) * ircld%ntotref(ilay - 1, j) * ircld%maxcov(ilay, j) / (1._jprb - ircld%cldcfr(ilay - 1, j)) ** 2
          ircld_ad%maxcov(ilay, j)     =      &
              ircld_ad%maxcov(ilay, j) + ntot(ilay) * ircld%ntotref(ilay - 1, j) / (1._jprb - ircld%cldcfr(ilay - 1, j))
        ENDIF
        IF ((ircld%cldcfr(ilay - 1, j) > ircld%cldcfr(ilay, j))) THEN
          ircld_ad%cldcfr(ilay - 1, j) = ircld_ad%cldcfr(ilay - 1, j) - ircld_ad%maxcov(ilay, j)
          ircld_ad%maxcov(ilay, j)     = 0._jprb
        ELSE
          ircld_ad%cldcfr(ilay, j) = ircld_ad%cldcfr(ilay, j) - ircld_ad%maxcov(ilay, j)
          ircld_ad%maxcov(ilay, j) = 0._jprb
        ENDIF
      ENDDO
      ircld_ad%cldcfr(1, j) = ircld_ad%cldcfr(1, j) - ntot(1)

      DO ilay = profiles(1)%nlayers, 1, -1
        IF (profiles(j)%cfrac(ilay) > 0._jprb) THEN
          profiles_ad(j)%cfrac(ilay) = profiles_ad(j)%cfrac(ilay) + ircld_ad%cldcfr(ilay, j)
        ENDIF
      ENDDO
      ircld_ad%cldcfr(:, j)  = 0._jprb
      ircld_ad%xstrmin(:, j) = 0._jprb
      ircld_ad%xstrmax(:, j) = 0._jprb
      ircld_ad%xstr(:, j) = 0._jprb
      ntot = 0._jprb
    ENDDO

  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_AD', 1_jpim, ZHOOK_HANDLE)
!      ircld_ad(:)%xstrclr=0._jprb
END SUBROUTINE rttov_cldstr_ad
