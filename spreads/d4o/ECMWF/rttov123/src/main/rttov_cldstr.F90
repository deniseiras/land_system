! Description:
!> @file
!!   Compute cloud streams (columns) for visible/IR scattering simulations
!
!> @brief
!!   Compute cloud streams (columns) for visible/IR scattering simulations
!!
!! @details
!!   For visible/IR cloud simulations the vertical profile is divided in a
!!   number of cloud streams or columns, each with a unique distribution of
!!   cloud among the layers. Each column has an associated weight. The
!!   radiative transfer equation is solved for each column and the TOA
!!   radiances are linearly combined using their respective column weights
!!   to obtain the total cloudy radiance.
!!
!!   Within RTTOV cloud stream/column zero is always the clear-sky column. The
!!   stream calculation and total number of streams varies from profile to
!!   profile.
!!
!!   The algorithm used is based on maximum/random overlap and is described in
!!   Matricardi, M., 2005 The inclusion of aerosols and clouds in RTIASI, the
!!   ECMWF fast radiative transfer model for the Infrared Atmospheric Sounding
!!   Interferometer. ECMWF Technical Memorandum 474.
!!
!!   This can result in a large number of cloud columns which increases the
!!   memory requirement and computational burden of the simulation. The
!!   cldstr_threshold parameter in the options structure can be used to ignore
!!   cloud streams with weights below the specified threshold (they are
!!   excluded and the clear stream weight is increased in compensation). See
!!   the user guide for more details.
!!
!!   There is also a cldstr_simple option which generates just two streams: one
!!   clear and one cloudy. The single cloud fraction is calculated as the
!!   maximum cloud fraction in the input profile above the boundary layer. This
!!   is much more efficient in CPU and memory, but is only appropriate for
!!   higher-peaking channels and is only recommended for advanced users who
!!   understand what they are doing.
!!
!! @param[in]     opts_rt_ir          visible/IR-specific options structure
!! @param[in]     profiles            input atmospheric profiles and surface variables
!! @param[in]     profiles_int        input atmospheric profiles converted to RTTOV internal units
!! @param[in,out] ircld               cloud column data
!! @param[out]    nstreams            largest number of cloud streams across all profiles
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
SUBROUTINE rttov_cldstr( &
              opts_rt_ir,   &
              profiles,     &
              profiles_int, &
              ircld,        &
              nstreams)

  USE rttov_types, ONLY : rttov_profile, rttov_ircld, rttov_opts_rt_ir
  USE parkind1, ONLY : jpim
!INTF_OFF
  USE parkind1, ONLY : jprb
  USE rttov_const, ONLY : realtol
  USE yomhook, ONLY : LHOOK, DR_HOOK
!INTF_ON
  IMPLICIT NONE
  TYPE(rttov_opts_rt_ir), INTENT(IN)    :: opts_rt_ir
  TYPE(rttov_profile),    INTENT(IN)    :: profiles(:)
  TYPE(rttov_profile),    INTENT(IN)    :: profiles_int(SIZE(profiles))
  TYPE(rttov_ircld),      INTENT(INOUT) :: ircld
  INTEGER(KIND=jpim),     INTENT(OUT)   :: nstreams
!INTF_END

  INTEGER(KIND=jpim) :: i, j, istr, ijstr, ilay
  REAL   (KIND=jprb) :: delta_cfrac
  INTEGER(KIND=jpim) :: ibdy_layer(1), imax_cfrac(1)
  REAL   (KIND=jprb) :: cfrac_max, cloud_tot(profiles(1)%nlayers)
  INTEGER(KIND=jpim) :: nprofiles
  REAL   (KIND=jprb) :: ntot(profiles(1)%nlevels)
  REAL   (KIND=jprb) :: ZHOOK_HANDLE
!-----End of header-------------------------------------------------------------
  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR', 0_jpim, ZHOOK_HANDLE)
  nprofiles = SIZE(profiles)

  IF (opts_rt_ir%cldstr_simple) THEN

    ! A simpler, faster, but quite approximate "Cmax" single-stream approach. 
    ! Main benefit is that it is much more memory efficient. Intended mainly
    ! for mid- and upper-tropospheric channels.
    DO j = 1, nprofiles

      ircld%icldarr(:, :, j) = 0_jpim

      ! Find maximum cloud fraction and cloud amount above the boundary layer
      ! NB pressure is on levels, cloud in layers, so p(1:nlevels-1) is the top of the layer

      ! NAG compiler with optimisation gives wrong answers with this...
!       ibdy_layer = MINLOC(ABS(profiles(j)%p(1:profiles(j)%nlevels-1) - opts_rt_ir%cldstr_low_cloud_top))
      ! ...so instead use this
      ibdy_layer = MINLOC(ABS(profiles(j)%p(:) - opts_rt_ir%cldstr_low_cloud_top))
      ibdy_layer(1) = MIN(ibdy_layer(1), profiles(j)%nlayers)

      imax_cfrac = MAXLOC(profiles(j)%cfrac(1:ibdy_layer(1)))
      cfrac_max  = profiles(j)%cfrac(imax_cfrac(1))
      cloud_tot(:) = SUM(profiles_int(j)%cloud(:,:), DIM=1)

      ! Ignoring trivial amounts of cloud and precip
      IF (ANY(cloud_tot(1:ibdy_layer(1)) > 1E-6_jprb) .AND. cfrac_max > 1E-3_jprb) THEN

        ! Cloudy stream required
        ircld%nstream(j) = 1
        ircld%xstr(1,j)  = 0._jprb
        ircld%xstr(2,j)  = cfrac_max
        ircld%xstrclr(j) = 1._jprb - cfrac_max
        WHERE (cloud_tot > 1E-6_jprb) ircld%icldarr(1,:,j) = 1

      ELSE

        ! Pure clear-sky
        ircld%nstream(j)  = 0
        ircld%xstr(1:2,j) = 0._jprb
        ircld%xstrclr(j)  = 1._jprb

      ENDIF

    ENDDO
    nstreams = MAXVAL(ircld%nstream(1:nprofiles))

  ELSE

    nstreams  = 0_jpim
    delta_cfrac = 10._jprb * EPSILON(1._jprb)
    DO j = 1, nprofiles
      ircld%iflag(:, j)      = 1_jpim
      ircld%icldarr(:, :, j) = 0_jpim
      ircld%cldcfr(:, j)     = 0._jprb
      ircld%xstr(:, j)       = 0._jprb
      ircld%xstrmin(:, j)    = 0._jprb
      ircld%xstrmax(:, j)    = 0._jprb
      ircld%flag(:, j)       = .FALSE.
      ntot = 0._jprb
      DO ilay = 1, profiles(1)%nlayers
        IF (profiles(j)%cfrac(ilay) > 0._jprb) THEN
          ircld%cldcfr(ilay, j) = profiles(j)%cfrac(ilay)
        ENDIF
      ENDDO

      ! Check for overcast layers and identical cfrac values on consecutive layers
      ! These need adjusting to ensure TL/AD/K models are correct
      DO ilay = 2, profiles(1)%nlayers
        IF (ircld%cldcfr(ilay, j) > 0.) THEN

          ! Check for overcast layers
          IF (ircld%cldcfr(ilay, j) >= 1._jprb) THEN
            ircld%cldcfr(ilay, j) = 1._jprb - ilay*delta_cfrac
          ENDIF

          ! Check for identical adjacent cfrac (note that this won't always work if cldstr_threshold is +ve)
          IF (ircld%cldcfr(ilay, j) == ircld%cldcfr(ilay-1, j)) THEN
            ircld%cldcfr(ilay, j) = ircld%cldcfr(ilay, j) - SIGN(delta_cfrac, ircld%cldcfr(ilay, j)-0.5_jprb)
          ENDIF

        ENDIF
      ENDDO

  !---------Compute the cumulative cloud coverage using the maximum-random---------
  !         overlap assumption
      ntot(1)             = 1._jprb - ircld%cldcfr(1, j)
      ircld%ntotref(1, j) = ntot(1)
      DO ilay = 2, profiles(1)%nlayers
        ircld%maxcov(ilay, j) = (1._jprb - MAX(ircld%cldcfr(ilay - 1, j), ircld%cldcfr(ilay, j)))
        IF (ntot(ilay - 1) == 0._jprb .AND. ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ntot(ilay) = ircld%maxcov(ilay, j)
        ELSEIF (ABS(ircld%cldcfr(ilay - 1, j) - 1._jprb) < realtol) THEN
          ntot(ilay) = ntot(ilay - 1)
        ELSE
          ntot(ilay) = ntot(ilay - 1) * ircld%maxcov(ilay, j) / (1._jprb - ircld%cldcfr(ilay - 1, j))
        ENDIF
        ircld%ntotref(ilay, j) = ntot(ilay)
      ENDDO
      DO ilay = 1, profiles(1)%nlayers
        IF (ircld%cldcfr(ilay, j) > 0._jprb) THEN
          ntot(ilay) = 1._jprb - ntot(ilay)
        ELSE
          ntot(ilay) = 0._jprb
        ENDIF
      ENDDO
  !---------Determine the limits of each stream----------------------------------
      ircld%icount(j) = 1_jpim
      DO ilay = 1, profiles(1)%nlayers
        ircld%xstrmax(ilay, j)    = ntot(ilay)
        ircld%xstrmin(ilay, j)    = ntot(ilay) - ircld%cldcfr(ilay, j)
        ircld%xstrminref(ilay, j) = ircld%xstrmin(ilay, j)
        IF (ircld%xstrmin(ilay, j) < 0._jprb) ircld%xstrmin(ilay, j) = 0._jprb
        IF (ircld%xstrmax(ilay, j) > 0._jprb) THEN
          ircld%xstr(ircld%icount(j), j) = ircld%xstrmin(ilay, j)
          ircld%icount(j)                = ircld%icount(j) + 1
          ircld%xstr(ircld%icount(j), j) = ircld%xstrmax(ilay, j)
          ircld%icount(j)                = ircld%icount(j) + 1
        ENDIF
      ENDDO
      ircld%xstrref(:, j) = ircld%xstr(:, j)
  !---------Re-arrange the limits of each stream in ascending order---------------
      loop1 : DO istr = 2, ircld%icount(j) - 1
        ircld%a(istr, j) = ircld%xstr(istr, j)
        DO i = istr - 1, 1, -1
          IF (ircld%xstr(i, j) <= ircld%a(istr, j)) THEN
            ircld%xstr(i + 1, j) = ircld%a(istr, j)
            ircld%iflag(istr, j) = i
            ircld%flag(istr, j)  = .TRUE.
            CYCLE loop1
          ELSE
            ircld%xstr(i + 1, j) = ircld%xstr(i, j)
          ENDIF
        ENDDO
        ircld%xstr(1, j) = ircld%a(istr, j)
      ENDDO loop1
      ircld%icount1(j)    = ircld%icount(j) - 1
      ircld%iloop(j)      = 0_jpim
      ircld%iloopin(:, j) = 0_jpim
      outer : DO
        ircld%iloop(j)                       = ircld%iloop(j) + 1
        ircld%icount1ref(ircld%iloop(j), j)  = ircld%icount1(j)
        ircld%xstrref2(ircld%iloop(j), :, j) = ircld%xstr(:, j)
        inner : DO istr = 1, ircld%icount1(j) - 1
          ircld%iloopin(ircld%iloop(j), j) = ircld%iloopin(ircld%iloop(j), j) + 1
          IF (ircld%xstr(istr, j) == ircld%xstr(istr + 1, j)) THEN
            IF (ircld%xstr(istr, j) < 1._jprb) THEN
              ircld%icount1(j) = ircld%icount1(j) - 1
              DO ijstr = istr, ircld%icount1(j)
                ircld%xstr(ijstr, j) = ircld%xstr(ijstr + 1, j)
              ENDDO
              CYCLE outer
            ELSE
              EXIT outer
            ENDIF
          ENDIF
        ENDDO inner
        EXIT outer
      ENDDO outer
      ircld%nstream(j) = ircld%icount1(j) - 1
  !---------Compute the weight of the clear stream------------------------------
      DO istr = 1, ircld%nstream(j)
        DO ilay = 1, profiles(1)%nlayers
          IF (ircld%xstrmin(ilay, j) <= ircld%xstr(istr, j) .AND. ircld%xstrmax(ilay, j) >= ircld%xstr(istr + 1, j)) THEN
            ircld%icldarr(istr, ilay, j) = 1_jpim
          ENDIF
        ENDDO
      ENDDO
      IF (ircld%nstream(j) == -1_jpim) THEN
        ircld%nstream(j) = 0_jpim
      ENDIF
      ircld%xstrclr(j)    = 1._jprb - (ircld%xstr(ircld%nstream(j) + 1, j) - ircld%xstr(1, j))
      ircld%nstreamref(j) = ircld%nstream(j)
  !---------Consider only the streams whose weight is greater than cldstr_threshold-------
      IF (ircld%nstream(j) /= 0_jpim) THEN
        ircld%icounstr(j) = 0_jpim
        DO istr = 1, ircld%nstream(j)
          IF ((ircld%xstr(istr + 1, j) - ircld%xstr(istr, j)) >= opts_rt_ir%cldstr_threshold) THEN
            ircld%icounstr(j)                    = ircld%icounstr(j) + 1
            ircld%indexstr(ircld%icounstr(j), j) = istr
          ENDIF
        ENDDO
        IF (ircld%icounstr(j) /= 0_jpim) THEN
          DO istr = 1, ircld%icounstr(j)
            DO ilay = 1, profiles(1)%nlayers
              ircld%icldarr(istr, ilay, j) = ircld%icldarr(ircld%indexstr(istr, j), ilay, j)
            ENDDO
          ENDDO
          DO istr = 1, ircld%icounstr(j) + 1
            IF (istr == 1_jpim) THEN
              ircld%xstr(istr, j) = ircld%xstr(ircld%indexstr(istr, j), j)
            ELSE
              ircld%xstr(istr, j) = ircld%xstr(istr - 1, j) +      &
                  (ircld%xstr(ircld%indexstr(istr - 1, j) + 1, j) - ircld%xstr(ircld%indexstr(istr - 1, j), j))
            ENDIF
          ENDDO
          ircld%xstrclr(j) = 1._jprb - (ircld%xstr(ircld%icounstr(j) + 1, j) - ircld%xstr(1, j))
          ircld%nstream(j) = ircld%icounstr(j)
        ELSE
          ircld%xstrclr(j) = 1._jprb
          ircld%nstream(j) = 0_jpim
        ENDIF
      ELSE
        ircld%nstream(j) = 0_jpim
      ENDIF
      nstreams = MAX(nstreams, ircld%nstream(j))
    ENDDO

  ENDIF

  IF (LHOOK) CALL DR_HOOK('RTTOV_CLDSTR', 1_jpim, ZHOOK_HANDLE)
END SUBROUTINE rttov_cldstr
