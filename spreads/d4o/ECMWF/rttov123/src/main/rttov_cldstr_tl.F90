! Description:
!> @file
!!   TL of cloud stream (column) computation for visible/IR scattering simulations
!
!> @brief
!!   TL of cloud stream (column) computation for visible/IR scattering simulations
!!
!!
!! @param[in]     opts_rt_ir          visible/IR-specific options structure
!! @param[in]     profiles            input atmospheric profiles and surface variables
!! @param[in]     profiles_tl         atmospheric profile perturbations
!! @param[in]     profiles_int        input atmospheric profiles converted to RTTOV internal units
!! @param[in,out] ircld               cloud column data
!! @param[in,out] ircld_tl            cloud column perturbations
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
SUBROUTINE rttov_cldstr_tl( &
              opts_rt_ir,   &
              profiles,     &
              profiles_tl,  &
              profiles_int, &
              ircld,        &
              ircld_tl)

  USE rttov_types, ONLY : rttov_profile, rttov_ircld, rttov_opts_rt_ir
!INTF_OFF
  USE yomhook, ONLY : LHOOK, DR_HOOK
  USE parkind1, ONLY : jpim, jprb
  USE rttov_const, ONLY : realtol
!INTF_ON
  IMPLICIT NONE

  TYPE(rttov_opts_rt_ir), INTENT(IN)    :: opts_rt_ir
  TYPE(rttov_profile),    INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),    INTENT(IN)    :: profiles_tl(SIZE(profiles))
  TYPE(rttov_profile),    INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld_tl
!INTF_END

  INTEGER(KIND=jpim) :: i, j, istr, ijstr, ilay
  INTEGER(KIND=jpim) :: nprofiles
  INTEGER(KIND=jpim) :: ibdy_layer(1), imax_cfrac(1)
  REAL   (KIND=jprb) :: cfrac_max, cloud_tot(profiles(1)%nlayers)
  REAL   (KIND=jprb) :: cfrac_max_tl 
  REAL   (KIND=jprb) :: ntot(profiles(1)%nlevels)
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-----End of header-------------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_TL', 0_jpim, ZHOOK_HANDLE)
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
      cfrac_max_tl = profiles_tl(j)%cfrac(imax_cfrac(1))
      cloud_tot(:) = SUM(profiles_int(j)%cloud(:,:), DIM=1)

      ! Ignoring trivial amounts of cloud and precip
      IF (ANY(cloud_tot(1:ibdy_layer(1)) > 1E-6_jprb) .AND. cfrac_max > 1E-3_jprb) THEN

        ! Cloudy stream required
        ircld_tl%xstr(1,j)  = 0._jprb
        ircld_tl%xstr(2,j)  = cfrac_max_tl
        ircld_tl%xstrclr(j) = -1._jprb*cfrac_max_tl

      ELSE

        ! Pure clear-sky
        ircld_tl%xstr(1:2,j) = 0._jprb
        ircld_tl%xstrclr(j)  = 0._jprb

      ENDIF

    ENDDO

  ELSE

    DO j = 1, nprofiles
      ircld_tl%cldcfr(:, j)  = 0._jprb
      ircld_tl%xstrmin(:, j) = 0._jprb
      ircld_tl%xstrmax(:, j) = 0._jprb
      ircld_tl%xstr(:, j) = 0._jprb ! important when there is no cloud, as it would be undefined otherwise
      ntot = 0._jprb
      DO ilay = 1, profiles(1)%nlayers
        IF (profiles(j)%cfrac(ilay) > 0._jprb) THEN
          ircld_tl%cldcfr(ilay, j) = profiles_tl(j)%cfrac(ilay)
        ENDIF
      ENDDO
      ircld%icount(j) = 0_jpim
  !---------Compute the cumulative cloud coverage using the maximum-random---------
  !         overlap assumption
      ntot(1)         =  - ircld_tl%cldcfr(1, j)
      DO ilay = 2, profiles(1)%nlayers
        IF ((ircld%cldcfr(ilay - 1, j) > ircld%cldcfr(ilay, j))) THEN
          ircld_tl%maxcov(ilay, j) =  - ircld_tl%cldcfr(ilay - 1, j)
        ELSE
          ircld_tl%maxcov(ilay, j) =  - ircld_tl%cldcfr(ilay, j)
        ENDIF
        IF (ircld%ntotref(ilay - 1, j) == 0._jprb .AND. ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ntot(ilay) = ircld_tl%maxcov(ilay, j)
        ELSEIF (ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ntot(ilay) = ntot(ilay - 1)
        ELSE
          ntot(ilay) = ntot(ilay - 1) * ircld%maxcov(ilay, j) / (1._jprb - ircld%cldcfr(ilay - 1, j)) +      &
              ircld_tl%cldcfr(ilay - 1, j) * ircld%ntotref(ilay - 1, j) * ircld%maxcov(ilay, j) /            &
              (1._jprb - ircld%cldcfr(ilay - 1, j)) ** 2 +                                                   &
              ircld_tl%maxcov(ilay, j) * ircld%ntotref(ilay - 1, j) / (1._jprb - ircld%cldcfr(ilay - 1, j))
        ENDIF
      ENDDO
      DO ilay = 1, profiles(1)%nlayers
        IF (ircld%cldcfr(ilay, j) > 0._jprb) THEN
          ntot(ilay)   =  - ntot(ilay)
        ELSE
          ntot(ilay)   = 0._jprb
        ENDIF
      ENDDO
  !---------Determine the limits of each stream----------------------------------
      ircld%icount(j) = 1_jpim
      DO ilay = 1, profiles(1)%nlayers
        ircld_tl%xstrmax(ilay, j) = ntot(ilay)
        ircld_tl%xstrmin(ilay, j) = ntot(ilay) - ircld_tl%cldcfr(ilay, j)
        IF (ircld%xstrminref(ilay, j) < 0._jprb) ircld_tl%xstrmin(ilay, j) = 0._jprb
        IF (ircld%xstrmax(ilay, j) > 0._jprb) THEN
          ircld_tl%xstr(ircld%icount(j), j) = ircld_tl%xstrmin(ilay, j)
          ircld%icount(j)                   = ircld%icount(j) + 1
          ircld_tl%xstr(ircld%icount(j), j) = ircld_tl%xstrmax(ilay, j)
          ircld%icount(j)                   = ircld%icount(j) + 1
        ENDIF
      ENDDO
  !---------Re-arrange the limits of each stream in ascending order---------------
      loop1 : DO istr = 2, ircld%icount(j) - 1
        ircld%a(istr, j)    = ircld%xstrref(istr, j)
        ircld_tl%a(istr, j) = ircld_tl%xstr(istr, j)
        DO i = istr - 1, 1, -1
          IF (ircld%xstrref(i, j) <= ircld%a(istr, j)) THEN
            ircld%xstrref(i + 1, j) = ircld%a(istr, j)
            ircld_tl%xstr(i + 1, j) = ircld_tl%a(istr, j)
            CYCLE loop1
          ELSE
            ircld%xstrref(i + 1, j) = ircld%xstrref(i, j)
            ircld_tl%xstr(i + 1, j) = ircld_tl%xstr(i, j)
          ENDIF
        ENDDO
        ircld%xstrref(1, j) = ircld%a(istr, j)
        ircld_tl%xstr(1, j) = ircld_tl%a(istr, j)
      ENDDO loop1
      outer : DO i = 1, ircld%iloop(j)
        inner : DO istr = 1, ircld%iloopin(i, j)
          IF (ircld%xstrref2(i, istr, j) == ircld%xstrref2(i, istr + 1, j)) THEN
            IF (ircld%xstrref2(i, istr, j) < 1._jprb) THEN
              ircld%icount1ref(i, j) = ircld%icount1ref(i, j) - 1
              DO ijstr = istr, ircld%icount1ref(i, j)
                ircld_tl%xstr(ijstr, j) = ircld_tl%xstr(ijstr + 1, j)
              ENDDO
            ENDIF
          ENDIF
        ENDDO inner
      ENDDO outer
  !---------Compute the weight of the clear stream------------------------------
      ircld_tl%xstrclr(j) =  - ircld_tl%xstr(ircld%nstreamref(j) + 1, j) + ircld_tl%xstr(1, j)
  !---------Consider only the streams whose weight is greater than cldstr_threshold-------
      IF (ircld%nstreamref(j) /= 0_jpim) THEN
        IF (ircld%icounstr(j) /= 0_jpim) THEN
          DO istr = 1, ircld%icounstr(j) + 1
            IF (istr == 1) THEN
              ircld_tl%xstr(istr, j) = ircld_tl%xstr(ircld%indexstr(istr, j), j)
            ELSE
              ircld_tl%xstr(istr, j) = ircld_tl%xstr(istr - 1, j) +      &
                  (ircld_tl%xstr(ircld%indexstr(istr - 1, j) + 1, j) - ircld_tl%xstr(ircld%indexstr(istr - 1, j), j))
            ENDIF
          ENDDO
          ircld_tl%xstrclr(j) =  - ircld_tl%xstr(ircld%icounstr(j) + 1, j) + ircld_tl%xstr(1, j)
        ELSE
          ircld_tl%xstrclr(j) = 0._jprb
        ENDIF
      ENDIF
    ENDDO

  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR_TL', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_cldstr_tl
