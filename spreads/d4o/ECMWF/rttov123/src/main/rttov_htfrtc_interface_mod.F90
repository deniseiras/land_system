! Description:
!> @file
!!   Subroutines for interface to HTFRTC
!
!> @brief
!!   Subroutines for interface to HTFRTC
!!
!! @details
!!   The htfrtc_interface subroutine implements the HTFRTC forward and
!!   Jacobian models. The Jacobian model is run if the optional profiles_k_pc
!!   argument is present.
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
MODULE rttov_htfrtc_interface_mod

  USE parkind1, ONLY: jpim, jprb, jplm

  IMPLICIT NONE

  PRIVATE
  PUBLIC :: htfrtc_interface

CONTAINS

  SUBROUTINE htfrtc_interface(err, &
                              coefs, &
                              opts, &
                              profiles, &
                              pccomp, &
                              calcemis, &
                              emissivity, &
                              emissivity_k, &
                              profiles_k_pc, &
                              profiles_k_rec)
#include "throw.h"
    USE rttov_types, ONLY : &
        rttov_coefs, &
        rttov_options, &
        rttov_profile, &
        rttov_pccomp, &
        rttov_emissivity

    USE rttov_const, ONLY : &
        deg2rad, gravity, earthradius, mair, rgc, &
        planck_c1, planck_c2, &
        surftype_land, surftype_sea, surftype_seaice, &
        gas_unit_ppmvdry,   &
        gas_unit_specconc,  &
        gas_unit_ppmv,      &
        gas_id_watervapour, &
        gas_id_ozone,       &
        gas_id_co2,         &
        gas_id_n2o,         &
        gas_id_co,          &
        gas_id_ch4,         &
        gas_id_so2,         &
        gas_mass

    IMPLICIT NONE

! input/output
    INTEGER(jpim)         , INTENT(OUT)              :: err
    TYPE(rttov_coefs)     , INTENT(IN)               :: coefs
    TYPE(rttov_options)   , INTENT(IN)               :: opts
    TYPE(rttov_profile)   , INTENT(IN)               :: profiles(:)
    TYPE(rttov_pccomp)    , INTENT(INOUT)            :: pccomp
    LOGICAL(jplm)         , INTENT(IN)    , OPTIONAL :: calcemis(:)
    TYPE(rttov_emissivity), INTENT(INOUT) , OPTIONAL :: emissivity(:)
    TYPE(rttov_emissivity), INTENT(INOUT) , OPTIONAL :: emissivity_k(:)
    TYPE(rttov_profile)   , INTENT(INOUT) , OPTIONAL :: profiles_k_pc(:)
    TYPE(rttov_profile)   , INTENT(INOUT) , OPTIONAL :: profiles_k_rec(:)

    LOGICAL(jplm) :: do_k, do_lambertian, user_emis

    INTEGER(jpim) :: n_p,n_f,n_t,n_q,n_b,n_lt,n_prof
    INTEGER(jpim) :: nlayers,nlevels
    INTEGER(jpim) :: n_pc,n_pc_oc,n_ch
    ! INTEGER(jpim) :: n_pc_emis
    INTEGER(jpim) :: surf_level
    INTEGER(jpim) :: cloud_level
    INTEGER(jpim) :: i,i_f,i_p,i_pc,i_ch
    INTEGER(jpim) :: ja,jb,js
    INTEGER(jpim) :: t_b_surf_i
    INTEGER(jpim) :: sg
    INTEGER(jpim) :: n_fit_dim, i_fit

    INTEGER(jpim),DIMENSION(profiles(1)%nlayers) :: p_opt_ly_i,t_opt_ly_i,q_opt_ly_i
    INTEGER(jpim),DIMENSION(profiles(1)%nlevels) :: t_b_i
    INTEGER(jpim),DIMENSION(profiles(1)%nlayers,2) :: qt
    INTEGER(jpim),DIMENSION(coefs%coef_htfrtc%n_f) :: f_i
    INTEGER(jpim),DIMENSION(coefs%coef_htfrtc%n_ch) :: fb_i

    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: z
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: t_b_r,b
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: rdown,rup,rdownlb
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: rup_cld
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: dbdt
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: cv
    REAL(jprb),DIMENSION(profiles(1)%nlevels) :: totdown,totup,totdownlb

    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: p_ly,dp,dz
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: t_ly,t2_ly
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: p_opt_ly_r,t_opt_ly_r,q_opt_ly_r
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: blydown,blyup,blydownlb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: lt,ltlb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: q_ly,ln_q_ly,o3_ly
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: q2_ly
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: co2_ly,n2o_ly,co_ly,ch4_ly,so2_ly
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: tau,tausl,tausllb,tr,trlb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: gravm1,mpath,mft,mftlb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dblydowndt,dblyupdt,dblydowndtlb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dq,do3,dco2,dn2o,dco,dch4,dso2,dsg
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dttmp,dqtmp
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dtrdt,dtrdq,dtrdo3
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dtrdco2,dtrdn2o,dtrdco,dtrdch4,dtrdso2
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dtrdtlb,dtrdqlb,dtrdo3lb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: dtrdco2lb,dtrdn2olb,dtrdcolb,dtrdch4lb,dtrdso2lb
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: drdowndt,drdowndq,drdowndo3
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: drdowndco2,drdowndn2o,drdowndco,drdowndch4,drdowndso2
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: drupdt,drupdq,drupdo3
    REAL(jprb),DIMENSION(profiles(1)%nlayers) :: drupdco2,drupdn2o,drupdco,drupdch4,drupdso2

    REAL(jprb),DIMENSION(profiles(1)%nlayers,4) :: pt,pq
    REAL(jprb),DIMENSION(profiles(1)%nlayers,8) :: ptq

    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: rc,normm1
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f,profiles(1)%nlevels) :: drcdt,drcdq,drcdo3
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f,profiles(1)%nlevels) :: drcdco2,drcdn2o,drcdco,drcdch4,drcdso2
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: drcdst,drcdsp
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: drcds2mt,drcds2mq,drcds2mo
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: drcds2mp,drcds2mu,drcds2mv,drcdsem
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: drcdcf,drcdctp
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: surf_em,aems,bems,cems,expf
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: daems,dbems,dcems,dexpf,dsurf_em
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: dsurf_emdu,dsurf_emdv
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: f_r

    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_ch) :: wn,wn3
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_ch) :: planck_c1_wn3,planck_c2_wn
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_ch) :: swrad_tmp
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_ch) :: fb_r

    ! REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_pc_emis) :: drcdsempcs

    REAL(jprb),DIMENSION(profiles(1)%nlayers,coefs%coef_htfrtc%n_f) :: rc_oc
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f,profiles(1)%nlayers) :: rc_oc_t
    REAL(jprb),DIMENSION(coefs%coef_htfrtc%n_f) :: rc_cld,rc_tot

    REAL(jprb) :: t_b_min,t_b_inc,t_b_inc_m1
    REAL(jprb) :: lt_min,lt_inc,lt_inc_m1
    REAL(jprb) :: t_opt_min,t_opt_inc,t_opt_inc_m1
    REAL(jprb) :: q_opt_min,q_opt_inc,q_opt_inc_m1
    REAL(jprb) :: surf_wind,surf_wind2,surf_windm1
    REAL(jprb) :: surf_layer_frac,t_b_surf_r
    REAL(jprb) :: cloud_layer_frac
    REAL(jprb) :: rdown_surf,b_surf,rdown_surflb
    REAL(jprb) :: db_surfdt
    REAL(jprb) :: tot
    REAL(jprb) :: sg_ly
    REAL(jprb) :: cf,sp
    REAL(jprb) :: qscv

    REAL(jprb),ALLOCATABLE :: overcast_pcscores(:,:),overcast_pcscores_t(:,:)
    REAL(jprb),ALLOCATABLE :: dist(:),diste(:),dist_cld(:),diste_cld(:)
    REAL(jprb),ALLOCATABLE :: dist_tot(:),diste_tot(:)
    REAL(jprb),ALLOCATABLE :: dist_oc(:),diste_oc(:)
    REAL(jprb),ALLOCATABLE :: ddistedt(:,:),ddistedq(:,:),ddistedo3(:,:)
    REAL(jprb),ALLOCATABLE :: ddistedco2(:,:),ddistedn2o(:,:),ddistedco(:,:),ddistedch4(:,:),ddistedso2(:,:)
    REAL(jprb),ALLOCATABLE :: ddistedst(:),ddistedsp(:)
    REAL(jprb),ALLOCATABLE :: ddisteds2mt(:),ddisteds2mq(:),ddisteds2mo(:)
    REAL(jprb),ALLOCATABLE :: ddisteds2mp(:),ddisteds2mu(:),ddisteds2mv(:)
    REAL(jprb),ALLOCATABLE :: ddistedcf(:),ddistedctp(:)

    TRY

    IF (opts%htfrtc_opts%reconstruct .AND. PRESENT(profiles_k_rec) .AND. &
        .NOT. PRESENT(profiles_k_pc)) THEN
      err = errorstatus_fatal
      THROWM(err.NE.0,'HTFRTC K model requires both profiles_k_pc and profiles_k_rec for rec. rads')
    ENDIF

    n_ch=coefs%coef_htfrtc%n_ch
    nlevels=profiles(1)%nlevels
    nlayers=profiles(1)%nlayers
    n_f=coefs%coef_htfrtc%n_f
    n_p=coefs%coef_htfrtc%n_p
    n_b=coefs%coef_htfrtc%n_b
    n_lt=coefs%coef_htfrtc%n_lt
    n_prof=size(profiles)
    do_k=PRESENT(profiles_k_pc)

    IF (opts%htfrtc_opts%reconstruct) THEN
      IF (PRESENT(calcemis) .AND. .NOT. PRESENT(emissivity)) THEN
        err = errorstatus_fatal
        THROWM(err.NE.0,'emissivity argument is mandatory if calcemis argument is present')
      ENDIF
      IF (PRESENT(calcemis)) THEN
        IF (SIZE(calcemis) /= n_ch * n_prof) THEN
          err = errorstatus_fatal
          THROWM(err.NE.0,'calcemis argument must have size nchannels_rec * nprofiles')
        ENDIF
      ENDIF
      IF (PRESENT(emissivity)) THEN
        IF (SIZE(emissivity) /= n_ch * n_prof) THEN
          err = errorstatus_fatal
          THROWM(err.NE.0,'emissivity argument must have size nchannels_rec * nprofiles')
        ENDIF
      ENDIF
      IF (PRESENT(emissivity_k)) THEN
        IF (SIZE(emissivity_k) /= n_ch * n_prof) THEN
          err = errorstatus_fatal
          THROWM(err.NE.0,'emissivity_k argument must have size nchannels_rec * nprofiles')
        ENDIF
      ENDIF
    ENDIF

    IF(coefs%coef_htfrtc%opt_prop_type==1) THEN
       t_opt_min=coefs%coef_htfrtc%val_l(1)
       t_opt_inc=coefs%coef_htfrtc%val_l(2)-coefs%coef_htfrtc%val_l(1)
       t_opt_inc_m1=1.0/t_opt_inc
       n_t=coefs%coef_htfrtc%n_val_l
       q_opt_min=log(coefs%coef_htfrtc%val_mf_nl(1,1))
       q_opt_inc=log(coefs%coef_htfrtc%val_mf_nl(2,1))-log(coefs%coef_htfrtc%val_mf_nl(1,1))
       q_opt_inc_m1=1.0/q_opt_inc
       n_q=coefs%coef_htfrtc%n_mf_nl
    ENDIF

    IF(coefs%coef_htfrtc%pc_reg_type==2) THEN
       n_fit_dim=coefs%coef_htfrtc%n_fit_dim
       ALLOCATE(dist(n_fit_dim))
       ALLOCATE(diste(n_fit_dim))
       ALLOCATE(dist_cld(n_fit_dim))
       ALLOCATE(diste_cld(n_fit_dim))
       ALLOCATE(dist_tot(n_fit_dim))
       ALLOCATE(diste_tot(n_fit_dim))
       ALLOCATE(dist_oc(n_fit_dim))
       ALLOCATE(diste_oc(n_fit_dim))
       IF(do_k) THEN
         ALLOCATE(ddistedt(n_fit_dim,nlevels))
         ALLOCATE(ddistedq(n_fit_dim,nlevels))
         ALLOCATE(ddistedo3(n_fit_dim,nlevels))
         ALLOCATE(ddistedco2(n_fit_dim,nlevels))
         ALLOCATE(ddistedn2o(n_fit_dim,nlevels))
         ALLOCATE(ddistedco(n_fit_dim,nlevels))
         ALLOCATE(ddistedch4(n_fit_dim,nlevels))
         ALLOCATE(ddistedso2(n_fit_dim,nlevels))
         ALLOCATE(ddistedst(n_fit_dim))
         ALLOCATE(ddistedsp(n_fit_dim))
         ALLOCATE(ddisteds2mt(n_fit_dim))
         ALLOCATE(ddisteds2mq(n_fit_dim))
         ALLOCATE(ddisteds2mo(n_fit_dim))
         ALLOCATE(ddisteds2mp(n_fit_dim))
         ALLOCATE(ddisteds2mu(n_fit_dim))
         ALLOCATE(ddisteds2mv(n_fit_dim))
         ALLOCATE(ddistedcf(n_fit_dim))
         ALLOCATE(ddistedctp(n_fit_dim))
       ENDIF
    ENDIF

    t_b_min=coefs%coef_htfrtc%val_b(1)
    t_b_inc=coefs%coef_htfrtc%val_b(2)-coefs%coef_htfrtc%val_b(1)
    t_b_inc_m1=1.0/t_b_inc

    lt_min=coefs%coef_htfrtc%val_lt(1)
    lt_inc=coefs%coef_htfrtc%val_lt(2)-coefs%coef_htfrtc%val_lt(1)
    lt_inc_m1=1.0/lt_inc

    DO i_f=1,n_f
       normm1(i_f)=1.0/coefs%coef_htfrtc%val_norm(i_f)
    ENDDO

    n_pc=coefs%coef_htfrtc%n_pc
    IF((opts%htfrtc_opts%n_pc_in.GT.0).AND.(opts%htfrtc_opts%n_pc_in.LE.coefs%coef_htfrtc%n_pc)) THEN
       n_pc=opts%htfrtc_opts%n_pc_in
    ENDIF
    n_pc_oc=min(n_pc,coefs%coef_htfrtc%n_pc_oc)

    IF(opts%htfrtc_opts%overcast) THEN
      ALLOCATE(overcast_pcscores(profiles(1)%nlayers,n_pc_oc))
      ALLOCATE(overcast_pcscores_t(n_pc_oc,profiles(1)%nlayers))
      pccomp%overcast_pcscores=0.0_jprb
    ENDIF

    !Reconstruct for radiances / brightness temperatures, precalc
    IF(opts%htfrtc_opts%reconstruct) THEN
      FORALL(i=1:n_ch)
        wn(i)=coefs%coef_htfrtc%sensor_freq(i)
        wn3(i)=wn(i)**3
        planck_c1_wn3(i)=planck_c1*wn3(i)
        planck_c2_wn(i)=planck_c2*wn(i)
      ENDFORALL
    ENDIF

    !Introduction of the RTTOV variable, optional, trace gases
    !"supergas" (sg) type = RTTOV predictor type
    sg=9
    IF(.NOT.(opts%rt_ir%n2o_data.OR.opts%rt_ir%co_data.OR.opts%rt_ir%ch4_data.OR.opts%rt_ir%so2_data)) THEN
      sg=8
      dn2o=0.0
      dco=0.0
      dch4=0.0
      dso2=0.0
        IF(.NOT.(opts%rt_ir%co2_data)) THEN
        sg=7
        dco2=0.0
        ENDIF
    ENDIF

    sg_ly=coefs%coef_htfrtc%val_mf_l(sg)

    !Map between channel and centroid freq
    IF(opts%htfrtc_opts%reconstruct .AND. (PRESENT(emissivity) .OR. PRESENT(emissivity_k))) THEN
      DO jb=1,n_f
         IF (coefs%coef_htfrtc%freq(jb)<wn(1)) THEN
            f_i(jb)=1
            f_r(jb)=0.0
         ELSE IF (coefs%coef_htfrtc%freq(jb)>=wn(n_ch)) THEN
            f_i(jb)=n_ch-1
            f_r(jb)=1.0
         ELSE
            DO ja=1,n_ch-1
               IF (coefs%coef_htfrtc%freq(jb)>=wn(ja) .AND.coefs%coef_htfrtc%freq(jb)<wn(ja+1)) THEN
                  f_i(jb)=ja
                  f_r(jb)=(coefs%coef_htfrtc%freq(jb)-wn(ja))/(wn(ja+1)-wn(ja))
               ENDIF
            ENDDO
         ENDIF
      ENDDO

      DO jb=1,n_ch
         IF (wn(jb)<coefs%coef_htfrtc%freq(1)) THEN
            fb_i(jb)=1
            fb_r(jb)=0.0
         ELSE IF (wn(jb)>=coefs%coef_htfrtc%freq(n_f)) THEN
            fb_i(jb)=n_f-1
            fb_r(jb)=1.0
         ELSE
            DO ja=1,n_f-1
               IF (wn(jb)>=coefs%coef_htfrtc%freq(ja) .AND.wn(jb)<coefs%coef_htfrtc%freq(ja+1)) THEN
                  fb_i(jb)=ja
                  fb_r(jb)=(wn(jb)-coefs%coef_htfrtc%freq(ja))/(coefs%coef_htfrtc%freq(ja+1)-coefs%coef_htfrtc%freq(ja))
               ENDIF
            ENDDO
         ENDIF
      ENDDO
    ENDIF

    !Diffuse downwelling slant path
    mftlb=coefs%coef_htfrtc%mftlb(1)

    !Initialise some variables
    o3_ly  = 0._jprb
    co2_ly = 0._jprb
    n2o_ly = 0._jprb
    co_ly  = 0._jprb
    ch4_ly = 0._jprb
    so2_ly = 0._jprb

    !Main loop over profiles
    DO i_p=1,n_prof

       !User levels to layers
       FORALL(i=1:nlayers)
          p_ly(i)=0.5*(profiles(i_p)%p(i)+profiles(i_p)%p(i+1))
          dp(i)=profiles(i_p)%p(i+1)-profiles(i_p)%p(i)
          gravm1(i)=1.0/gravity
          mpath(i)=100.0*dp(i)*gravm1(i)
          t_ly(i)=0.5*(profiles(i_p)%t(i)+profiles(i_p)%t(i+1))
          !dz(i)=dp(i)*gravm1(i)*t_ly(i)/p_ly(i) !This was a bug in RTTOV12.2!
          dz(i)=dp(i)*gravm1(i)*rgc*t_ly(i)/mair/p_ly(i)
          mft(i)=1.0/cos(profiles(i_p)%zenangle*deg2rad)
       ENDFORALL

       !Map user levels and ref prof / coeff levels
       js=1
       DO jb=1,nlayers
          IF (p_ly(jb)<coefs%coef_htfrtc%p(1)) THEN
             p_opt_ly_i(jb)=1
             p_opt_ly_r(jb)=0.0
          ELSE IF (p_ly(jb)>=coefs%coef_htfrtc%p(n_p)) THEN
             p_opt_ly_i(jb)=n_p-1
             p_opt_ly_r(jb)=1.0
          ELSE
          DO ja=js,n_p-1
             IF (p_ly(jb)>=coefs%coef_htfrtc%p(ja) .AND. p_ly(jb)<coefs%coef_htfrtc%p(ja+1)) THEN
                js=ja
                p_opt_ly_i(jb)=ja
                p_opt_ly_r(jb)=(p_ly(jb)-coefs%coef_htfrtc%p(ja))/(coefs%coef_htfrtc%p(ja+1)-coefs%coef_htfrtc%p(ja))
             ENDIF
          ENDDO
          ENDIF
       ENDDO

       !Find the level just above the surface
       surf_level=nlevels-1
       surf_layer_frac=1.0
       DO jb=1,nlevels-1
          IF ((profiles(i_p)%s2m%p.GT.profiles(i_p)%p(jb)).AND.(profiles(i_p)%s2m%p.LE.profiles(i_p)%p(jb+1))) THEN
             surf_level=jb
             surf_layer_frac=(profiles(i_p)%s2m%p-profiles(i_p)%p(jb))/(profiles(i_p)%p(jb+1)-profiles(i_p)%p(jb))
          ENDIF
       ENDDO

       !Near surface layer
       p_ly(surf_level)=0.5*(profiles(i_p)%p(surf_level)+profiles(i_p)%s2m%p)
       dp(surf_level)=profiles(i_p)%s2m%p-profiles(i_p)%p(surf_level)
       gravm1(surf_level)=1.0/gravity
       mpath(surf_level)=100.0*dp(surf_level)*gravm1(surf_level)
       t_ly(surf_level)=0.5*(profiles(i_p)%t(surf_level)+profiles(i_p)%s2m%t)
       dz(surf_level)=dp(surf_level)*gravm1(surf_level)*rgc*t_ly(surf_level)/mair/p_ly(surf_level)
       z(surf_level+1)=profiles(i_p)%elevation
       DO i=surf_level,1,-1
          z(i)=z(i+1)+dz(i)
       ENDDO
       IF(.NOT.opts%rt_all%plane_parallel) THEN
         FORALL(i=1:surf_level)
           mft(i)=1.0/sqrt(1.0-(sin(profiles(i_p)%zenangle*deg2rad)*earthradius/(earthradius+0.5*(z(i)+z(i+1))))**2)
         ENDFORALL
       ENDIF

       !Planckians, precalc
       FORALL(i=1:nlevels)
          t_b_i(i)=min(n_b-1,max(1,1+int(t_b_inc_m1*(profiles(i_p)%t(i)-t_b_min))))
          t_b_r(i)=t_b_inc_m1*((profiles(i_p)%t(i)-t_b_min)-t_b_inc*(t_b_i(i)-1))
       ENDFORALL
       t_b_i(surf_level+1)=min(n_b-1,max(1,1+int(t_b_inc_m1*(profiles(i_p)%s2m%t-t_b_min))))
       t_b_r(surf_level+1)=t_b_inc_m1*((profiles(i_p)%s2m%t-t_b_min)-t_b_inc*(t_b_i(surf_level+1)-1))
       t_b_surf_i=min(n_b-1,max(1,1+int(t_b_inc_m1*(profiles(i_p)%skin%t-t_b_min))))
       t_b_surf_r=t_b_inc_m1*((profiles(i_p)%skin%t-t_b_min)-t_b_inc*(t_b_surf_i-1))

       !Unit conversions
       SELECT CASE(profiles(1)%gas_units)
       CASE(gas_unit_ppmvdry)
         FORALL(i=1:nlevels)
            cv(i)=1.0_jprb/(Mair * 1.E06_jprb + gas_mass(gas_id_watervapour) * profiles(i_p)%q(i))
         ENDFORALL
         FORALL(i=1:nlayers)
            q_ly(i)=gas_mass(gas_id_watervapour)*0.5*(profiles(i_p)%q(i)*cv(i)+profiles(i_p)%q(i+1)*cv(i+1))
         ENDFORALL
         IF(opts%rt_all%use_q2m) THEN
            qscv=1.0_jprb/(Mair * 1.E06_jprb + gas_mass(gas_id_watervapour) * profiles(i_p)%s2m%q)
            q_ly(surf_level)=gas_mass(gas_id_watervapour)*0.5* &
              (profiles(i_p)%q(surf_level)*cv(surf_level)+profiles(i_p)%s2m%q*qscv)
          ELSE
            q_ly(surf_level)=gas_mass(gas_id_watervapour)* &
            (profiles(i_p)%q(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%q(surf_level+1)*cv(surf_level+1)-profiles(i_p)%q(surf_level)*cv(surf_level)))
         ENDIF
       CASE(gas_unit_ppmv)
         FORALL(i=1:nlevels)
            cv(i)=1.0_jprb/(1.0e6_jprb*Mair+profiles(i_p)%q(i)*(gas_mass(gas_id_watervapour)-Mair))
         ENDFORALL
         FORALL(i=1:nlayers)
            q_ly(i)=gas_mass(gas_id_watervapour)*0.5*(profiles(i_p)%q(i)*cv(i)+profiles(i_p)%q(i+1)*cv(i+1))
         ENDFORALL
         IF(opts%rt_all%use_q2m) THEN
            qscv=1.0_jprb/(1.0e6_jprb*Mair+profiles(i_p)%s2m%q*(gas_mass(gas_id_watervapour)-Mair))
            q_ly(surf_level)=gas_mass(gas_id_watervapour)*0.5* &
              (profiles(i_p)%q(surf_level)*cv(surf_level)+profiles(i_p)%s2m%q*qscv)
          ELSE
            q_ly(surf_level)=gas_mass(gas_id_watervapour)* &
            (profiles(i_p)%q(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%q(surf_level+1)*cv(surf_level+1)-profiles(i_p)%q(surf_level)*cv(surf_level)))
         ENDIF
       END SELECT

       SELECT CASE(profiles(1)%gas_units)
       CASE(gas_unit_ppmvdry,gas_unit_ppmv)
         IF(opts%rt_ir%ozone_data) THEN
            FORALL(i=1:nlayers)
              o3_ly(i)=0.5*(profiles(i_p)%o3(i)*cv(i)+profiles(i_p)%o3(i+1)*cv(i+1))*gas_mass(gas_id_ozone)
            ENDFORALL
            o3_ly(surf_level)=(profiles(i_p)%o3(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%o3(surf_level+1)*cv(surf_level+1)-profiles(i_p)%o3(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_ozone)
         ENDIF
         IF(opts%rt_ir%co2_data) THEN
            FORALL(i=1:nlayers)
              co2_ly(i)=0.5*(profiles(i_p)%co2(i)*cv(i)+profiles(i_p)%co2(i+1)*cv(i+1))*gas_mass(gas_id_co2)
            ENDFORALL
            co2_ly(surf_level)=(profiles(i_p)%co2(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%co2(surf_level+1)*cv(surf_level+1)-profiles(i_p)%co2(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_co2)
         ENDIF
         IF(opts%rt_ir%n2o_data) THEN
            FORALL(i=1:nlayers)
              n2o_ly(i)=0.5*(profiles(i_p)%n2o(i)*cv(i)+profiles(i_p)%n2o(i+1)*cv(i+1))*gas_mass(gas_id_n2o)
            ENDFORALL
            n2o_ly(surf_level)=(profiles(i_p)%n2o(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%n2o(surf_level+1)*cv(surf_level+1)-profiles(i_p)%n2o(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_n2o)
         ENDIF
         IF(opts%rt_ir%co_data) THEN
            FORALL(i=1:nlayers)
              co_ly(i)=0.5*(profiles(i_p)%co(i)*cv(i)+profiles(i_p)%co(i+1)*cv(i+1))*gas_mass(gas_id_co)
            ENDFORALL
            co_ly(surf_level)=(profiles(i_p)%co(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%co(surf_level+1)*cv(surf_level+1)-profiles(i_p)%co(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_co)
         ENDIF
         IF(opts%rt_ir%ch4_data) THEN
            FORALL(i=1:nlayers)
              ch4_ly(i)=0.5*(profiles(i_p)%ch4(i)*cv(i)+profiles(i_p)%ch4(i+1)*cv(i+1))*gas_mass(gas_id_ch4)
            ENDFORALL
            ch4_ly(surf_level)=(profiles(i_p)%ch4(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%ch4(surf_level+1)*cv(surf_level+1)-profiles(i_p)%ch4(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_ch4)
         ENDIF
         IF(opts%rt_ir%so2_data) THEN
            FORALL(i=1:nlayers)
              so2_ly(i)=0.5*(profiles(i_p)%so2(i)*cv(i)+profiles(i_p)%so2(i+1)*cv(i+1))*gas_mass(gas_id_so2)
            ENDFORALL
            so2_ly(surf_level)=(profiles(i_p)%so2(surf_level)*cv(surf_level) &
            +surf_layer_frac*(profiles(i_p)%so2(surf_level+1)*cv(surf_level+1)-profiles(i_p)%so2(surf_level)*cv(surf_level))) &
            *gas_mass(gas_id_so2)
         ENDIF
       CASE(gas_unit_specconc)
         FORALL(i=1:nlayers)
            q_ly(i)=0.5*(profiles(i_p)%q(i)+profiles(i_p)%q(i+1))
         ENDFORALL
         IF(opts%rt_all%use_q2m) THEN
            q_ly(surf_level)=0.5*(profiles(i_p)%q(surf_level)+profiles(i_p)%s2m%q)
          ELSE
            q_ly(surf_level)=profiles(i_p)%q(surf_level) &
            +surf_layer_frac*(profiles(i_p)%q(surf_level+1)-profiles(i_p)%q(surf_level))
         ENDIF
         IF(opts%rt_ir%ozone_data) THEN
            FORALL(i=1:nlayers)
              o3_ly(i)=0.5*(profiles(i_p)%o3(i)+profiles(i_p)%o3(i+1))
            ENDFORALL
            o3_ly(surf_level)=profiles(i_p)%o3(surf_level) &
            +surf_layer_frac*(profiles(i_p)%o3(surf_level+1)-profiles(i_p)%o3(surf_level))
         ENDIF
         IF(opts%rt_ir%co2_data) THEN
            FORALL(i=1:nlayers)
              co2_ly(i)=0.5*(profiles(i_p)%co2(i)+profiles(i_p)%co2(i+1))
            ENDFORALL
            co2_ly(surf_level)=profiles(i_p)%co2(surf_level) &
            +surf_layer_frac*(profiles(i_p)%co2(surf_level+1)-profiles(i_p)%co2(surf_level))
         ENDIF
         IF(opts%rt_ir%n2o_data) THEN
            FORALL(i=1:nlayers)
              n2o_ly(i)=0.5*(profiles(i_p)%n2o(i)+profiles(i_p)%n2o(i+1))
            ENDFORALL
            n2o_ly(surf_level)=profiles(i_p)%n2o(surf_level) &
            +surf_layer_frac*(profiles(i_p)%n2o(surf_level+1)-profiles(i_p)%n2o(surf_level))
         ENDIF
         IF(opts%rt_ir%co_data) THEN
            FORALL(i=1:nlayers)
              co_ly(i)=0.5*(profiles(i_p)%co(i)+profiles(i_p)%co(i+1))
            ENDFORALL
            co_ly(surf_level)=profiles(i_p)%co(surf_level) &
            +surf_layer_frac*(profiles(i_p)%co(surf_level+1)-profiles(i_p)%co(surf_level))
         ENDIF
         IF(opts%rt_ir%ch4_data) THEN
            FORALL(i=1:nlayers)
              ch4_ly(i)=0.5*(profiles(i_p)%ch4(i)+profiles(i_p)%ch4(i+1))
            ENDFORALL
            ch4_ly(surf_level)=profiles(i_p)%ch4(surf_level) &
            +surf_layer_frac*(profiles(i_p)%ch4(surf_level+1)-profiles(i_p)%ch4(surf_level))
         ENDIF
         IF(opts%rt_ir%so2_data) THEN
            FORALL(i=1:nlayers)
              so2_ly(i)=0.5*(profiles(i_p)%so2(i)+profiles(i_p)%so2(i+1))
            ENDFORALL
            so2_ly(surf_level)=profiles(i_p)%so2(surf_level) &
            +surf_layer_frac*(profiles(i_p)%so2(surf_level+1)-profiles(i_p)%so2(surf_level))
         ENDIF
       END SELECT

       !Ref prof where no user prof
       FORALL(i=1:nlayers)
            cv(i)=1.0_jprb/(Mair * 1.E06_jprb + gas_mass(gas_id_watervapour) * profiles(i_p)%q(i))
       ENDFORALL
       IF(sg.GE.7) THEN
       IF(.NOT.opts%rt_ir%ozone_data) THEN
         FORALL(i=1:surf_level)
            o3_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),1)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,1)) &
            *cv(i)*gas_mass(gas_id_ozone)
         ENDFORALL
       ENDIF
       ENDIF
       IF(sg.GE.8) THEN
       IF(.NOT.opts%rt_ir%co2_data) THEN
         FORALL(i=1:surf_level)
            co2_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),2)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,2)) &
            *cv(i)*gas_mass(gas_id_co2)
         ENDFORALL
       ENDIF
       ENDIF
       IF(sg.GE.9) THEN
       IF(.NOT.opts%rt_ir%n2o_data) THEN
         FORALL(i=1:surf_level)
            n2o_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),3)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,3)) &
            *cv(i)*gas_mass(gas_id_n2o)
         ENDFORALL
       ENDIF
       IF(.NOT.opts%rt_ir%co_data) THEN
         FORALL(i=1:surf_level)
            co_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),4)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,4)) &
            *cv(i)*gas_mass(gas_id_co)
         ENDFORALL
       ENDIF
       IF(.NOT.opts%rt_ir%ch4_data) THEN
         FORALL(i=1:surf_level)
            ch4_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),5)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,5)) &
            *cv(i)*gas_mass(gas_id_ch4)
         ENDFORALL
       ENDIF
       IF(.NOT.opts%rt_ir%so2_data) THEN
         FORALL(i=1:surf_level)
            so2_ly(i)=((1.0-p_opt_ly_r(i))*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i),6)+ &
            p_opt_ly_r(i)*coefs%coef_htfrtc%mixed_ref_frac(p_opt_ly_i(i)+1,6)) &
            *cv(i)*gas_mass(gas_id_so2)
         ENDFORALL
       ENDIF
       ENDIF

       !Gaseous optical properties, precalc
       !1: LUT, 2: PARAM
       IF(coefs%coef_htfrtc%opt_prop_type==1) THEN

       FORALL(i=1:nlayers)

          t_opt_ly_i(i)=min(n_t-1,max(1,1+int(t_opt_inc_m1*(t_ly(i)-t_opt_min))))
          t_opt_ly_r(i)=t_opt_inc_m1*((t_ly(i)-t_opt_min)-t_opt_inc*(t_opt_ly_i(i)-1))

          ln_q_ly(i)=log(q_ly(i))
          q_opt_ly_i(i)=min(n_q-1,max(1,1+int(q_opt_inc_m1*(ln_q_ly(i)-q_opt_min))))
          !q_opt_ly_r(i)=q_opt_inc_m1*((ln_q_ly(i)-q_opt_min)-q_opt_inc*(q_opt_ly_i(i)-1))
          q_opt_ly_r(i)=(q_ly(i)-coefs%coef_htfrtc%val_mf_nl(q_opt_ly_i(i),1)) &
          /(coefs%coef_htfrtc%val_mf_nl(q_opt_ly_i(i)+1,1)-coefs%coef_htfrtc%val_mf_nl(q_opt_ly_i(i),1))

          pt(i,1)=(1.0-p_opt_ly_r(i))*(1.0-t_opt_ly_r(i))
          pt(i,2)=(1.0-p_opt_ly_r(i))*t_opt_ly_r(i)
          pt(i,3)=p_opt_ly_r(i)      *(1.0-t_opt_ly_r(i))
          pt(i,4)=p_opt_ly_r(i)      *t_opt_ly_r(i)

          pq(i,1)=(1.0-p_opt_ly_r(i))*(1.0-q_opt_ly_r(i))
          pq(i,2)=(1.0-p_opt_ly_r(i))*q_opt_ly_r(i)
          pq(i,3)=p_opt_ly_r(i)      *(1.0-q_opt_ly_r(i))
          pq(i,4)=p_opt_ly_r(i)      *q_opt_ly_r(i)

          ptq(i,1)=pt(i,1)*(1.0-q_opt_ly_r(i))
          ptq(i,2)=pt(i,1)*q_opt_ly_r(i)
          ptq(i,3)=pt(i,2)*(1.0-q_opt_ly_r(i))
          ptq(i,4)=pt(i,2)*q_opt_ly_r(i)
          ptq(i,5)=pt(i,3)*(1.0-q_opt_ly_r(i))
          ptq(i,6)=pt(i,3)*q_opt_ly_r(i)
          ptq(i,7)=pt(i,4)*(1.0-q_opt_ly_r(i))
          ptq(i,8)=pt(i,4)*q_opt_ly_r(i)

          qt(i,1)=(t_opt_ly_i(i)-1)*n_q+q_opt_ly_i(i)
          qt(i,2)=t_opt_ly_i(i)    *n_q+q_opt_ly_i(i)

       ENDFORALL

       ELSE IF(coefs%coef_htfrtc%opt_prop_type==2) THEN

       FORALL(i=1:nlayers)
          t2_ly(i)=t_ly(i)*t_ly(i)
          q2_ly(i)=q_ly(i)*q_ly(i)
       ENDFORALL

       ENDIF !opt_prop_type

       do_lambertian = opts%rt_all%do_lambertian
       IF(do_lambertian) THEN
         sp=profiles(i_p)%skin%specularity
       ELSE
         sp=1.0_jprb
       ENDIF

       !User defined surface emissivity (in pc oder otherwise)
       user_emis = .FALSE.
       IF(opts%htfrtc_opts%reconstruct .AND. PRESENT(calcemis)) THEN
         user_emis = (.NOT. ANY(calcemis((i_p-1)*n_ch+1:i_p*n_ch)))
       ENDIF
         
       IF (user_emis) THEN

          DO i_f=1,n_f
             surf_em(i_f)=(1.0-f_r(i_f))*emissivity((i_p-1)*n_ch+f_i(i_f))%emis_in &
                         +f_r(i_f)*emissivity((i_p-1)*n_ch+f_i(i_f)+1)%emis_in
          ENDDO

       ELSE

          !Non-directional horizontal wind
          IF(profiles(i_p)%skin%surftype==surftype_sea) THEN
             surf_wind=sqrt(profiles(i_p)%s2m%u**2 + profiles(i_p)%s2m%v**2)
             surf_wind2=surf_wind**2
             surf_windm1=1.0_jprb/(surf_wind+1.0e-6_jprb)
          ENDIF

          IF(profiles(i_p)%skin%surftype==surftype_sea) THEN
             do_lambertian = .FALSE.
             FORALL(i_f=1:n_f)
               aems(i_f)=coefs%coef_htfrtc%coef_ssemp(1,i_f) &
                   +surf_wind*coefs%coef_htfrtc%coef_ssemp(2,i_f) &
                   +surf_wind2*coefs%coef_htfrtc%coef_ssemp(3,i_f)
               bems(i_f)=coefs%coef_htfrtc%coef_ssemp(4,i_f) &
                   +surf_wind*coefs%coef_htfrtc%coef_ssemp(5,i_f) &
                   +surf_wind2*coefs%coef_htfrtc%coef_ssemp(6,i_f)
               cems(i_f)=coefs%coef_htfrtc%coef_ssemp(7,i_f) &
                   +surf_wind*coefs%coef_htfrtc%coef_ssemp(8,i_f)
               expf(i_f)=exp( ( (coefs%coef_htfrtc%coef_ssemp(9,i_f)-60.0_jprb)**2 &
                   - (profiles(i_p)%zenangle-coefs%coef_htfrtc%coef_ssemp(9,i_f))**2 ) /cems(i_f) )
               surf_em(i_f)=aems(i_f)+(bems(i_f)-aems(i_f))*expf(i_f)
             ENDFORALL
          ELSE IF (profiles(i_p)%skin%surftype==surftype_land) THEN
               surf_em=0.98_jprb
          ELSE IF (profiles(i_p)%skin%surftype==surftype_seaice) THEN
               surf_em=0.99_jprb
          ELSE
          ENDIF

          IF(do_k) THEN

             IF(profiles(i_p)%skin%surftype==surftype_sea) THEN
               FORALL(i_f=1:n_f)
                 daems(i_f)=surf_windm1*(coefs%coef_htfrtc%coef_ssemp(2,i_f) &
                           +2.0_jprb*surf_wind*coefs%coef_htfrtc%coef_ssemp(3,i_f))
                 dbems(i_f)=surf_windm1*(coefs%coef_htfrtc%coef_ssemp(5,i_f) &
                          +2.0_jprb*surf_wind*coefs%coef_htfrtc%coef_ssemp(6,i_f))
                 dcems(i_f)=surf_windm1*coefs%coef_htfrtc%coef_ssemp(8,i_f)
                 dexpf(i_f)= -( (coefs%coef_htfrtc%coef_ssemp(9,i_f)-60.0_jprb)**2 &
                   - (profiles(i_p)%zenangle-coefs%coef_htfrtc%coef_ssemp(9,i_f))**2 ) &
                   / (cems(i_f)*cems(i_f))
                 dsurf_em(i_f)=(daems(i_f)+(dbems(i_f)-daems(i_f)) &
                              +dcems(i_f)*(bems(i_f)-aems(i_f))*dexpf(i_f))*expf(i_f)
                 dsurf_emdu(i_f)=dsurf_em(i_f)*profiles(i_p)%s2m%u
                 dsurf_emdv(i_f)=dsurf_em(i_f)*profiles(i_p)%s2m%v
                ENDFORALL
              ELSE
                 dsurf_emdu=0.0_jprb
                 dsurf_emdv=0.0_jprb
              ENDIF

          ENDIF ! do_k

       ENDIF ! calcemis

       !Find the level just above the cloud
       IF(opts%htfrtc_opts%simple_cloud) THEN
         cloud_level=nlevels-1
         cloud_layer_frac=1.0
         DO jb=1,nlevels-1
           IF ((profiles(i_p)%ctp.GT.profiles(i_p)%p(jb)).AND.(profiles(i_p)%ctp.LE.profiles(i_p)%p(jb+1))) THEN
             cloud_level=jb
             cloud_layer_frac=(profiles(i_p)%ctp-profiles(i_p)%p(jb))/(profiles(i_p)%p(jb+1)-profiles(i_p)%p(jb))
           ENDIF
         ENDDO
         cf=profiles(i_p)%cfraction
       ELSE
         cf=0.0
       ENDIF

          !Main long loop over centroid frequencies
          DO i_f=1,n_f

             !Gaseous optical properties calc
             !1: LUT, 2: PARAM
             IF(coefs%coef_htfrtc%opt_prop_type==1) THEN

                IF (sg.GE.7) THEN
                FORALL(i=1:nlayers)
                dq(i)  =ptq(i,1)*coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i),  1,i_f) &
                       +ptq(i,2)*coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i),  1,i_f) &
                       +ptq(i,3)*coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i),  1,i_f) &
                       +ptq(i,4)*coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i),  1,i_f) &
                       +ptq(i,5)*coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)+1,1,i_f) &
                       +ptq(i,6)*coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)+1,1,i_f) &
                       +ptq(i,7)*coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)+1,1,i_f) &
                       +ptq(i,8)*coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)+1,1,i_f)
                do3(i) =pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  1,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  1,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,1,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,1,i_f)
                dsg(i) =pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  sg,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  sg,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,sg,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,sg,i_f)
                ENDFORALL
                ENDIF
                IF (sg.GE.8) THEN
                FORALL(i=1:nlayers)
                dco2(i)=pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  2,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  2,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,2,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,2,i_f)
                ENDFORALL
                ENDIF
                IF (sg.GE.9) THEN
                FORALL(i=1:nlayers)
                dn2o(i)=pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  3,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  3,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,3,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,3,i_f)
                dco(i) =pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  4,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  4,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,4,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,4,i_f)
                dch4(i)=pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  5,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  5,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,5,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,5,i_f)
                dso2(i)=pt(i,1)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  6,i_f) &
                       +pt(i,2)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  6,i_f) &
                       +pt(i,3)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,6,i_f) &
                       +pt(i,4)*coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,6,i_f)
                ENDFORALL
                ENDIF

             ELSE IF (coefs%coef_htfrtc%opt_prop_type==2) THEN

                IF (sg.GE.7) THEN
                FORALL(i=1:nlayers)
                dq(i)=((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_nl(1,p_opt_ly_i(i)  ,1,i_f)  &
                                   +t_ly(i) *coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)  ,1,i_f)  &
                                   +t2_ly(i)*coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)  ,1,i_f)  &
                                   +         q_ly(i)*coefs%coef_htfrtc%coef_nl(4,p_opt_ly_i(i)  ,1,i_f) &
                                   +t_ly(i) *q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)  ,1,i_f) &
                                   +t2_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)  ,1,i_f) &
                                   +         q2_ly(i)*coefs%coef_htfrtc%coef_nl(7,p_opt_ly_i(i)  ,1,i_f) &
                                   +t_ly(i) *q2_ly(i)*coefs%coef_htfrtc%coef_nl(8,p_opt_ly_i(i)  ,1,i_f) &
                                   +t2_ly(i)*q2_ly(i)*coefs%coef_htfrtc%coef_nl(9,p_opt_ly_i(i)  ,1,i_f)) &
                      +p_opt_ly_r(i)       *(coefs%coef_htfrtc%coef_nl(1,p_opt_ly_i(i)+1,1,i_f)  &
                                   +t_ly(i) *coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)+1,1,i_f)  &
                                   +t2_ly(i)*coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)+1,1,i_f)  &
                                   +         q_ly(i)*coefs%coef_htfrtc%coef_nl(4,p_opt_ly_i(i)+1,1,i_f) &
                                   +t_ly(i) *q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)+1,1,i_f) &
                                   +t2_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)+1,1,i_f) &
                                   +         q2_ly(i)*coefs%coef_htfrtc%coef_nl(7,p_opt_ly_i(i)+1,1,i_f) &
                                   +t_ly(i) *q2_ly(i)*coefs%coef_htfrtc%coef_nl(8,p_opt_ly_i(i)+1,1,i_f) &
                                   +t2_ly(i) *q2_ly(i)*coefs%coef_htfrtc%coef_nl(9,p_opt_ly_i(i)+1,1,i_f)))
                do3(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,1,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,1,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,1,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,1,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,1,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,1,i_f)))
                dsg(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,sg,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,sg,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,sg,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,sg,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,sg,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,sg,i_f)))
                ENDFORALL
                ENDIF
                IF (sg.GE.8) THEN
                FORALL(i=1:nlayers)
                dco2(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,2,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,2,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,2,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,2,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,2,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,2,i_f)))
                ENDFORALL
                ENDIF
                IF (sg.GE.9) THEN
                FORALL(i=1:nlayers)
                dn2o(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,3,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,3,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,3,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,3,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,3,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,3,i_f)))
                dco(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,4,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,4,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,4,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,4,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,4,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,4,i_f)))
                dch4(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,5,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,5,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,5,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,5,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,5,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,5,i_f)))
                dso2(i)=((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)  ,6,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,6,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,6,i_f)) &
                       +p_opt_ly_r(i)      *(coefs%coef_htfrtc%coef_l(1,p_opt_ly_i(i)+1,6,i_f)  &
                                  +t_ly(i) *coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,6,i_f)  &
                                  +t2_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,6,i_f)))
                ENDFORALL
                ENDIF

             ENDIF !opt_prop_type

             FORALL(i=1:nlayers)
                tau(i)=max(0._jprb,mpath(i)*(q_ly(i)*dq(i)+o3_ly(i)*do3(i)+co2_ly(i)*dco2(i)+ &
                       n2o_ly(i)*dn2o(i)+co_ly(i)*dco(i)+ch4_ly(i)*dch4(i)+so2_ly(i)*dso2(i)+sg_ly*dsg(i)))
             ENDFORALL
             tausl=tau*mft
             tr=exp(-tausl)

             IF(do_lambertian) THEN
               tausllb=tau*mftlb
               trlb=exp(-tausllb)
             ELSE
               tausllb = 0.0
               trlb = 0.0
             ENDIF

             !Planckians calc
             FORALL(i=1:nlevels)
                b(i)=coefs%coef_htfrtc%coef_b(t_b_i(i),i_f) &
                    +t_b_r(i)*(coefs%coef_htfrtc%coef_b(t_b_i(i)+1,i_f)-coefs%coef_htfrtc%coef_b(t_b_i(i),i_f))
             ENDFORALL
             b_surf=coefs%coef_htfrtc%coef_b(t_b_surf_i,i_f) &
                    +t_b_surf_r*(coefs%coef_htfrtc%coef_b(t_b_surf_i+1,i_f)-coefs%coef_htfrtc%coef_b(t_b_surf_i,i_f))

             FORALL(i=1:nlayers)
                lt(i)=coefs%coef_htfrtc%coef_lt(min(n_lt,max(1,1+int(lt_inc_m1*(tausl(i)-lt_min)))))
                blydown(i)=b(i)+lt(i)*(b(i+1)-b(i))
                blyup(i)=b(i+1)+lt(i)*(b(i)-b(i+1))
             ENDFORALL

             IF(do_lambertian) THEN
             FORALL(i=1:nlayers)
                ltlb(i)=coefs%coef_htfrtc%coef_lt(min(n_lt,max(1,1+int(lt_inc_m1*(tausllb(i)-lt_min)))))
                blydownlb(i)=b(i)+ltlb(i)*(b(i+1)-b(i))
             ENDFORALL
             ELSE
               blydownlb = 0.0
             ENDIF

             !Radiative transfer, downwelling, then upwelling
             rdown(1)=0.0
             DO i=2,nlevels
                rdown(i)=blydown(i-1)+(rdown(i-1)-blydown(i-1))*tr(i-1)
             ENDDO
             rdown_surf=blydown(surf_level)+(rdown(surf_level)-blydown(surf_level))*tr(surf_level)

             IF(do_lambertian) THEN
             rdownlb(1)=0.0
             DO i=2,nlevels
                rdownlb(i)=blydownlb(i-1)+(rdownlb(i-1)-blydown(i-1))*trlb(i-1)
             ENDDO
             rdown_surflb=blydownlb(surf_level)+(rdownlb(surf_level)-blydownlb(surf_level))*trlb(surf_level)
             ELSE
             rdownlb=0.0
             rdown_surflb=0.0
             ENDIF

             DO i=nlevels,surf_level+2,-1
             rup(i)=0.0
             ENDDO
             IF(do_lambertian) THEN
             rup(surf_level+1)=b_surf*surf_em(i_f)+ &
                               (rdown_surflb+sp*(rdown_surf-rdown_surflb))*(1.0-surf_em(i_f))
             ELSE
             rup(surf_level+1)=b_surf*surf_em(i_f)+rdown_surf*(1.0-surf_em(i_f))
             ENDIF
             rup(surf_level)=blyup(surf_level)+(rup(surf_level+1)-blyup(surf_level))*tr(surf_level)
             DO i=surf_level,2,-1
                rup(i-1)=blyup(i-1)+(rup(i)-blyup(i-1))*tr(i-1)
             ENDDO
             rc(i_f)=(rup(1)-coefs%coef_htfrtc%val_mean(i_f))*normm1(i_f)

             IF(opts%htfrtc_opts%overcast) THEN
               DO i=2,nlevels
                  totup(i)    =product(tr(1:i-1))
                  rc_oc(i-1,i_f)=(rup(1)+(b(i)-rup(i))*totup(i)-coefs%coef_htfrtc%val_mean(i_f))*normm1(i_f)
               ENDDO
             ENDIF

             IF(opts%htfrtc_opts%simple_cloud) THEN
               DO i=nlevels,cloud_level+1,-1
               rup_cld(i)=0.0
               ENDDO
               rup_cld(cloud_level)=b(cloud_level)+0.5*(b(cloud_level+1)-b(cloud_level))*cloud_layer_frac* &
                 (1.0+exp(-tausl(cloud_level)*cloud_layer_frac))
               DO i=cloud_level,2,-1
                 rup_cld(i-1)=blyup(i-1)+(rup_cld(i)-blyup(i-1))*tr(i-1)
               ENDDO
               rc_cld(i_f)=(rup_cld(1)-coefs%coef_htfrtc%val_mean(i_f))*normm1(i_f)
             ELSE
               rc_cld(i_f)=0.0
             ENDIF

             IF(do_k) THEN

             IF(coefs%coef_htfrtc%opt_prop_type==1) THEN

               IF (sg.EQ.7) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=t_opt_inc_m1* &
                          (q_ly(i)*(pq(i,1)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,2)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,3)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)+1,1,i_f)) &
                                   +pq(i,4)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)+1,1,i_f))) &
                          +o3_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  1,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  1,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  1,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  1,i_f))) &
                          +sg_ly*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  sg,i_f) &
                                                       +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  sg,i_f)) &
                                 +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  sg,i_f) &
                                                 +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  sg,i_f))))
               ENDFORALL
               ENDIF
               IF (sg.EQ.8) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=t_opt_inc_m1* &
                          (q_ly(i)*(pq(i,1)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,2)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,3)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)+1,1,i_f)) &
                                   +pq(i,4)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)+1,1,i_f))) &
                          +o3_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  1,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  1,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  1,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  1,i_f))) &
                          +co2_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  2,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  2,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  2,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  2,i_f))) &
                          +sg_ly*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  sg,i_f) &
                                                       +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  sg,i_f)) &
                                 +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  sg,i_f) &
                                                 +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  sg,i_f))))
               ENDFORALL
               ENDIF
               IF (sg.EQ.9) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=t_opt_inc_m1* &
                          (q_ly(i)*(pq(i,1)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,2)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i),  1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i),  1,i_f)) &
                                   +pq(i,3)*(coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)+1,1,i_f)) &
                                   +pq(i,4)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)+1,1,i_f) &
                                            -coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)+1,1,i_f))) &
                          +o3_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  1,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  1,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  1,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  1,i_f))) &
                          +co2_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  2,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  2,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  2,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  2,i_f))) &
                          +n2o_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  3,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  3,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  3,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  3,i_f))) &
                          +co_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  4,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  4,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  4,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  4,i_f))) &
                          +ch4_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  5,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  5,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  5,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  5,i_f))) &
                          +so2_ly(i)*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  6,i_f) &
                                                          +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  6,i_f)) &
                                    +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  6,i_f) &
                                                    +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  6,i_f))) &
                          +sg_ly*((1.0-p_opt_ly_r(i))*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i),  sg,i_f) &
                                                       +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i),  sg,i_f)) &
                                 +p_opt_ly_r(i)*(-coefs%coef_htfrtc%coef_l(t_opt_ly_i(i),  p_opt_ly_i(i)+1,  sg,i_f) &
                                                 +coefs%coef_htfrtc%coef_l(t_opt_ly_i(i)+1,p_opt_ly_i(i)+1,  sg,i_f))))
               ENDFORALL
               ENDIF

               FORALL(i=1:nlayers)
                  dqtmp(i)=(dq(i) &
                          +q_ly(i)/(coefs%coef_htfrtc%val_mf_nl(q_opt_ly_i(i)+1,1)-coefs%coef_htfrtc%val_mf_nl(q_opt_ly_i(i),1)) &
                          *(pt(i,1)*(coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)  , 1,i_f) &
                                    -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)  , 1,i_f)) &
                           +pt(i,2)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)  , 1,i_f) &
                                    -coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)  , 1,i_f)) &
                           +pt(i,3)*(coefs%coef_htfrtc%coef_nl(qt(i,1)+1, p_opt_ly_i(i)+1, 1,i_f) &
                                    -coefs%coef_htfrtc%coef_nl(qt(i,1)  , p_opt_ly_i(i)+1, 1,i_f)) &
                           +pt(i,4)*(coefs%coef_htfrtc%coef_nl(qt(i,2)+1, p_opt_ly_i(i)+1, 1,i_f) &
                                    -coefs%coef_htfrtc%coef_nl(qt(i,2)  , p_opt_ly_i(i)+1, 1,i_f))))
               ENDFORALL

             ELSE IF (coefs%coef_htfrtc%opt_prop_type==2) THEN

               IF (sg.EQ.7) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=(q_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)  ,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)  ,1,i_f)) &
                                  +p_opt_ly_r(i)        *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)+1,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)+1,1,i_f))) &
                           +o3_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,1,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,1,i_f))) &
                           +sg_ly*((1.0-p_opt_ly_r(i)) *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,sg,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,sg,i_f))))
               ENDFORALL
               ENDIF
               IF (sg.EQ.8) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=(q_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)  ,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)  ,1,i_f)) &
                                  +p_opt_ly_r(i)        *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)+1,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)+1,1,i_f))) &
                           +o3_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,1,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,1,i_f))) &
                           +co2_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,2,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,2,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,2,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,2,i_f))) &
                           +sg_ly*((1.0-p_opt_ly_r(i)) *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,sg,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,sg,i_f))))
               ENDFORALL
               ENDIF
               IF (sg.EQ.9) THEN
               FORALL(i=1:nlayers)
                  dttmp(i)=(q_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)  ,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)  ,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)  ,1,i_f)) &
                                  +p_opt_ly_r(i)        *(coefs%coef_htfrtc%coef_nl(2,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*        coefs%coef_htfrtc%coef_nl(3,p_opt_ly_i(i)+1,1,i_f)  &
                                     +            q_ly(i)*coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)+1,1,i_f)  &
                                     +2.0*t_ly(i)*q_ly(i)*coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)+1,1,i_f))) &
                           +o3_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,1,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,1,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,1,i_f))) &
                           +co2_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,2,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,2,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,2,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,2,i_f))) &
                           +n2o_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,3,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,3,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,3,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,3,i_f))) &
                           +co_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,4,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,4,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,4,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,4,i_f))) &
                           +ch4_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,5,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,5,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,5,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,5,i_f))) &
                           +so2_ly(i)*((1.0-p_opt_ly_r(i)) *(coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,6,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,6,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,6,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,6,i_f))) &
                           +sg_ly*((1.0-p_opt_ly_r(i)) *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)  ,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)  ,sg,i_f)) &
                                   +p_opt_ly_r(i)      *(    coefs%coef_htfrtc%coef_l(2,p_opt_ly_i(i)+1,sg,i_f)  &
                                                +2.0*t_ly(i)*coefs%coef_htfrtc%coef_l(3,p_opt_ly_i(i)+1,sg,i_f))))
               ENDFORALL
               ENDIF

                FORALL(i=1:nlayers)
                   dqtmp(i)=(dq(i)+ &
                           q_ly(i)*((1.0-p_opt_ly_r(i))*(coefs%coef_htfrtc%coef_nl(4,p_opt_ly_i(i)  ,1,i_f) &
                                              +t_ly(i) * coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)  ,1,i_f) &
                                              +t2_ly(i)* coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)  ,1,i_f)) &
                                  +p_opt_ly_r(i)       *(coefs%coef_htfrtc%coef_nl(4,p_opt_ly_i(i)+1,1,i_f) &
                                              +t_ly(i) * coefs%coef_htfrtc%coef_nl(5,p_opt_ly_i(i)+1,1,i_f) &
                                              +t2_ly(i)* coefs%coef_htfrtc%coef_nl(6,p_opt_ly_i(i)+1,1,i_f))))
                ENDFORALL

             ENDIF !opt_prop_type

             FORALL(i=1:nlayers)
                dtrdt(i)=-tr(i)*mpath(i)*mft(i)*dttmp(i)
                dtrdq(i)=-tr(i)*mpath(i)*mft(i)*dqtmp(i)
                dtrdo3(i)=-tr(i)*mpath(i)*mft(i)*do3(i)
                dtrdco2(i)=-tr(i)*mpath(i)*mft(i)*dco2(i)
                dtrdn2o(i)=-tr(i)*mpath(i)*mft(i)*dn2o(i)
                dtrdco(i)=-tr(i)*mpath(i)*mft(i)*dco(i)
                dtrdch4(i)=-tr(i)*mpath(i)*mft(i)*dch4(i)
                dtrdso2(i)=-tr(i)*mpath(i)*mft(i)*dso2(i)
             ENDFORALL

             IF(do_lambertian) THEN
             FORALL(i=1:nlayers)
                dtrdtlb(i)=-trlb(i)*mpath(i)*mftlb(i)*dttmp(i)
                dtrdqlb(i)=-trlb(i)*mpath(i)*mftlb(i)*dqtmp(i)
                dtrdo3lb(i)=-trlb(i)*mpath(i)*mftlb(i)*do3(i)
                dtrdco2lb(i)=-trlb(i)*mpath(i)*mftlb(i)*dco2(i)
                dtrdn2olb(i)=-trlb(i)*mpath(i)*mftlb(i)*dn2o(i)
                dtrdcolb(i)=-trlb(i)*mpath(i)*mftlb(i)*dco(i)
                dtrdch4lb(i)=-trlb(i)*mpath(i)*mftlb(i)*dch4(i)
                dtrdso2lb(i)=-trlb(i)*mpath(i)*mftlb(i)*dso2(i)
             ENDFORALL
             ENDIF

             FORALL(i=1:nlevels)
                dbdt(i)=t_b_inc_m1*(coefs%coef_htfrtc%coef_b(t_b_i(i)+1,i_f)-coefs%coef_htfrtc%coef_b(t_b_i(i),i_f))
             ENDFORALL
             db_surfdt=t_b_inc_m1*(coefs%coef_htfrtc%coef_b(t_b_surf_i+1,i_f)-coefs%coef_htfrtc%coef_b(t_b_surf_i,i_f))

             FORALL(i=1:nlayers)
                dblydowndt(i)=dbdt(i)+lt(i)*(dbdt(i+1)-dbdt(i))
                dblyupdt(i)=dbdt(i+1)+lt(i)*(dbdt(i)-dbdt(i+1))
             ENDFORALL
             IF(do_lambertian) THEN
             FORALL(i=1:nlayers)
                dblydowndtlb(i)=dbdt(i)+ltlb(i)*(dbdt(i+1)-dbdt(i))
             ENDFORALL
             ENDIF

             tot=product(tr(1:surf_level))
             IF(do_lambertian) THEN
             DO i=1,surf_level
                totdown(i)   =product(tr(i+1:surf_level))*tot*(1.0-surf_em(i_f))
                totdownlb(i) =product(trlb(i+1:surf_level))*tot*(1.0-surf_em(i_f))
                drdowndt(i)=(1.0-sp)*(dblydowndtlb(i)*(1.0-trlb(i))+(rdownlb(i)-blydownlb(i))*dtrdtlb(i))*totdownlb(i) &
                           +sp*(dblydowndt(i)*(1.0-tr(i))+(rdown(i)-blydown(i))*dtrdt(i))*totdown(i)
                drdowndq(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdqlb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdq(i)*totdown(i)
                drdowndo3(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdo3lb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdo3(i)*totdown(i)
                drdowndco2(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdco2lb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdco2(i)*totdown(i)
                drdowndn2o(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdn2olb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdn2o(i)*totdown(i)
                drdowndco(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdcolb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdco(i)*totdown(i)
                drdowndch4(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdch4lb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdch4(i)*totdown(i)
                drdowndso2(i)=(1.0-sp)*(rdownlb(i)-blydownlb(i))*dtrdso2lb(i)*totdownlb(i) &
                           +sp*(rdown(i)-blydown(i))*dtrdso2(i)*totdown(i)
             ENDDO
             ELSE
             DO i=1,surf_level
                totdown(i)   =product(tr(i+1:surf_level))*tot*(1.0-surf_em(i_f))
                drdowndt(i)  =(dblydowndt(i)*(1.0-tr(i))+(rdown(i)-blydown(i))*dtrdt(i))*totdown(i)
                drdowndq(i)  =(rdown(i)-blydown(i))*dtrdq(i)*totdown(i)
                drdowndo3(i) =(rdown(i)-blydown(i))*dtrdo3(i)*totdown(i)
                drdowndco2(i)=(rdown(i)-blydown(i))*dtrdco2(i)*totdown(i)
                drdowndn2o(i)=(rdown(i)-blydown(i))*dtrdn2o(i)*totdown(i)
                drdowndco(i) =(rdown(i)-blydown(i))*dtrdco(i)*totdown(i)
                drdowndch4(i)=(rdown(i)-blydown(i))*dtrdch4(i)*totdown(i)
                drdowndso2(i)=(rdown(i)-blydown(i))*dtrdso2(i)*totdown(i)
             ENDDO
             ENDIF

             IF(opts%htfrtc_opts%simple_cloud) THEN
             DO i=1,surf_level
                totup(i)   =product(tr(1:i-1))
                drupdq(i)  =((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdq(i)*totup(i)
                drupdo3(i) =((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdo3(i)*totup(i)
                drupdco2(i)=((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdco2(i)*totup(i)
                drupdn2o(i)=((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdn2o(i)*totup(i)
                drupdco(i) =((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdco(i)*totup(i)
                drupdch4(i)=((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdch4(i)*totup(i)
                drupdso2(i)=((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdso2(i)*totup(i)
             ENDDO
             DO i=1,cloud_level
                drupdt(i)  =(dblyupdt(i)*(1.0-tr(i)) &
                           +((1.0-cf)*rup(i+1)+cf*rup_cld(i+1)-blyup(i))*dtrdt(i))*totup(i)
             ENDDO
             DO i=cloud_level+1,surf_level
                drupdt(i)  =((1.0-cf)*rup(i+1)-blyup(i))*dtrdt(i)*totup(i)
             ENDDO
             ELSE
             DO i=1,surf_level
                totup(i)   =product(tr(1:i-1))
                drupdt(i)  =(dblyupdt(i)*(1.0-tr(i)) &
                           +(rup(i+1)-blyup(i))*dtrdt(i))*totup(i)
                drupdq(i)  =(rup(i+1)-blyup(i))*dtrdq(i)*totup(i)
                drupdo3(i) =(rup(i+1)-blyup(i))*dtrdo3(i)*totup(i)
                drupdco2(i)=(rup(i+1)-blyup(i))*dtrdco2(i)*totup(i)
                drupdn2o(i)=(rup(i+1)-blyup(i))*dtrdn2o(i)*totup(i)
                drupdco(i) =(rup(i+1)-blyup(i))*dtrdco(i)*totup(i)
                drupdch4(i)=(rup(i+1)-blyup(i))*dtrdch4(i)*totup(i)
                drupdso2(i)=(rup(i+1)-blyup(i))*dtrdso2(i)*totup(i)
             ENDDO
             ENDIF

             !Jacobians at centroids
             drcdt(i_f,1)  =0.5*(drdowndt(1)+drupdt(1))*normm1(i_f)
             drcdq(i_f,1)  =0.5*(drdowndq(1)+drupdq(1))*normm1(i_f)
             drcdo3(i_f,1) =0.5*(drdowndo3(1)+drupdo3(1))*normm1(i_f)
             drcdco2(i_f,1)=0.5*(drdowndco2(1)+drupdco2(1))*normm1(i_f)
             drcdn2o(i_f,1)=0.5*(drdowndn2o(1)+drupdn2o(1))*normm1(i_f)
             drcdco(i_f,1) =0.5*(drdowndco(1)+drupdco(1))*normm1(i_f)
             drcdch4(i_f,1)=0.5*(drdowndch4(1)+drupdch4(1))*normm1(i_f)
             drcdso2(i_f,1)=0.5*(drdowndso2(1)+drupdso2(1))*normm1(i_f)
             DO i=2, surf_level
                drcdt(i_f,i)=0.5*(drdowndt(i-1)+drdowndt(i)+drupdt(i-1)+drupdt(i))*normm1(i_f)
                drcdq(i_f,i)=0.5*(drdowndq(i-1)+drdowndq(i)+drupdq(i-1)+drupdq(i))*normm1(i_f)
                drcdo3(i_f,i)=0.5*(drdowndo3(i-1)+drdowndo3(i)+drupdo3(i-1)+drupdo3(i))*normm1(i_f)
                drcdco2(i_f,i)=0.5*(drdowndco2(i-1)+drdowndco2(i)+drupdco2(i-1)+drupdco2(i))*normm1(i_f)
                drcdn2o(i_f,i)=0.5*(drdowndn2o(i-1)+drdowndn2o(i)+drupdn2o(i-1)+drupdn2o(i))*normm1(i_f)
                drcdco(i_f,i)=0.5*(drdowndco(i-1)+drdowndco(i)+drupdco(i-1)+drupdco(i))*normm1(i_f)
                drcdch4(i_f,i)=0.5*(drdowndch4(i-1)+drdowndch4(i)+drupdch4(i-1)+drupdch4(i))*normm1(i_f)
                drcdso2(i_f,i)=0.5*(drdowndso2(i-1)+drdowndso2(i)+drupdso2(i-1)+drupdso2(i))*normm1(i_f)
             ENDDO
             drcdt(i_f,surf_level+1)=0.5*(drdowndt(surf_level)+drupdt(surf_level))*normm1(i_f)
             drcdq(i_f,surf_level+1)=0.5*(drdowndq(surf_level)+drupdq(surf_level))*normm1(i_f)
             drcdo3(i_f,surf_level+1)=0.5*(drdowndo3(surf_level)+drupdo3(surf_level))*normm1(i_f)
             drcdco2(i_f,surf_level+1)=0.5*(drdowndco2(surf_level)+drupdco2(surf_level))*normm1(i_f)
             drcdn2o(i_f,surf_level+1)=0.5*(drdowndn2o(surf_level)+drupdn2o(surf_level))*normm1(i_f)
             drcdco(i_f,surf_level+1)=0.5*(drdowndco(surf_level)+drupdco(surf_level))*normm1(i_f)
             drcdch4(i_f,surf_level+1)=0.5*(drdowndch4(surf_level)+drupdch4(surf_level))*normm1(i_f)
             drcdso2(i_f,surf_level+1)=0.5*(drdowndso2(surf_level)+drupdso2(surf_level))*normm1(i_f)
             DO i=surf_level+2, nlevels
             drcdt(i_f,i)=0.0
             drcdq(i_f,i)=0.0
             drcdo3(i_f,i)=0.0
             drcdco2(i_f,i)=0.0
             drcdn2o(i_f,i)=0.0
             drcdco(i_f,i)=0.0
             drcdch4(i_f,i)=0.0
             drcdso2(i_f,i)=0.0
             ENDDO

             drcdst(i_f)=(1.0-cf)*db_surfdt*surf_em(i_f)*tot*normm1(i_f)
             drcds2mt(i_f)=drcdt(i_f,surf_level+1)
             drcds2mq(i_f)=drcdq(i_f,surf_level+1)
             drcds2mo(i_f)=drcdo3(i_f,surf_level+1)
             IF(do_lambertian) THEN
             drcdsp(i_f)=(1.0-cf)*(rdown_surf-rdown_surflb)*(1.0-surf_em(i_f))
             drcds2mp(i_f)=(1.0-cf)*totup(surf_level)*normm1(i_f)/dp(surf_level)* &
             ((1.0-sp)*(rdownlb(surf_level)-blydownlb(surf_level))*(1.0-surf_em(i_f))*trlb(surf_level)*(-tausllb(surf_level)) &
             +((sp*(rdown(surf_level)-blydown(surf_level))*(1.0-surf_em(i_f)))+(rup(surf_level+1)-blyup(surf_level)))* &
             tr(surf_level)*(-tausl(surf_level)))
             drcds2mu(i_f)=0.0
             drcds2mv(i_f)=0.0
             drcdsem(i_f)=(1.0-cf)*(b_surf-(rdown_surflb+sp*(rdown_surf-rdown_surflb)))*tot*normm1(i_f)
             ELSE
             drcdsp(i_f)=0.0
             drcds2mp(i_f)=(1.0-cf)*totup(surf_level)*normm1(i_f)/dp(surf_level)* &
             ((rdown(surf_level)-blydown(surf_level))*(1.0-surf_em(i_f))+(rup(surf_level+1)-blyup(surf_level)))*tr(surf_level)* &
             (-tausl(surf_level))
             drcds2mu(i_f)=(1.0-cf)*(b_surf-rdown_surf)*dsurf_emdu(i_f)*tot*normm1(i_f)
             drcds2mv(i_f)=(1.0-cf)*(b_surf-rdown_surf)*dsurf_emdv(i_f)*tot*normm1(i_f)
             drcdsem(i_f)=(1.0-cf)*(b_surf-rdown_surf)*tot*normm1(i_f)
             ENDIF
             IF(opts%htfrtc_opts%simple_cloud) THEN
             drcdcf(i_f)=rc_cld(i_f)-rc(i_f)
             drcdctp(i_f)=(1.0-cf)*totup(cloud_level)*normm1(i_f)/dp(cloud_level)* &
             0.5*(b(cloud_level+1)-b(cloud_level))*(1.0+(1.0-tausl(cloud_level)*cloud_layer_frac)*exp(-tausl(cloud_level)* &
             cloud_layer_frac))
             ELSE
             drcdcf(i_f)=0.0
             drcdctp(i_f)=0.0
             ENDIF

             ENDIF ! do_k

          ENDDO ! n_f

       !Emissivity
       IF (opts%htfrtc_opts%reconstruct .AND. PRESENT(emissivity)) THEN
         DO i_ch=1,n_ch
            emissivity((i_p-1)*n_ch+i_ch)%emis_out=(1.0-fb_r(i_ch))*surf_em(fb_i(i_ch)) &
                      +fb_r(i_ch)*surf_em(fb_i(i_ch)+1)
         ENDDO
       ENDIF

       !PC scores
       IF (coefs%coef_htfrtc%pc_reg_type==1) THEN

          FORALL(i_pc=1:n_pc)
              pccomp%clear_pcscores((i_p-1)*n_pc+i_pc)=sum(rc(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
          END FORALL ! n_pc
          IF(opts%htfrtc_opts%simple_cloud) THEN
            FORALL(i_pc=1:n_pc)
              pccomp%cloudy_pcscores((i_p-1)*n_pc+i_pc)=sum(rc_cld(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
              pccomp%total_pcscores((i_p-1)*n_pc+i_pc)=(1.0-cf)*pccomp%clear_pcscores((i_p-1)*n_pc+i_pc) &
                                                      +cf*pccomp%cloudy_pcscores((i_p-1)*n_pc+i_pc)
            END FORALL ! n_pc
          ELSE
            FORALL(i_pc=1:n_pc)
              pccomp%total_pcscores((i_p-1)*n_pc+i_pc)=pccomp%clear_pcscores((i_p-1)*n_pc+i_pc)
            ENDFORALL
          ENDIF

          IF(opts%htfrtc_opts%overcast) THEN
            rc_oc_t=transpose(rc_oc)
            DO i = 1, nlayers
              DO i_pc = 1, n_pc_oc
                overcast_pcscores_t(i_pc,i)=sum(rc_oc_t(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
              ENDDO
            ENDDO
            overcast_pcscores=transpose(overcast_pcscores_t)
            DO i_pc=1,n_pc_oc
              DO i=1,nlayers
                pccomp%overcast_pcscores(i,(i_p-1)*n_pc+i_pc)=overcast_pcscores(i,i_pc)
              ENDDO
            ENDDO
          ENDIF

          IF(do_k) THEN

          FORALL(i_pc=1:n_pc)

             FORALL(i=1:nlevels)
                profiles_k_pc((i_p-1)*n_pc+i_pc)%t(i)=sum(drcdt(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%q(i)=sum(drcdq(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
             ENDFORALL

                profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%t=sum(drcdst(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%specularity=sum(drcdsp(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%t=sum(drcds2mt(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%q=sum(drcds2mq(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%o=sum(drcds2mo(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%p=sum(drcds2mp(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%u=sum(drcds2mu(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%v=sum(drcds2mv(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%cfraction=sum(drcdcf(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%ctp=sum(drcdctp(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))

          END FORALL ! n_pc

          IF(opts%rt_ir%ozone_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%o3(i)=sum(drcdo3(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%co2_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%co2(i)=sum(drcdco2(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%n2o_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%n2o(i)=sum(drcdn2o(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%co_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%co(i)=sum(drcdco(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%ch4_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%ch4(i)=sum(drcdch4(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%so2_data) THEN
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%so2(i)=sum(drcdso2(1:n_f,i)*coefs%coef_htfrtc%coef_pdt(1:n_f,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF

          ENDIF ! do_k

       ELSE IF (coefs%coef_htfrtc%pc_reg_type==2) THEN

          FORALL(i_fit=1:n_fit_dim)
             dist(i_fit)=sum((rc(1:n_f)-coefs%coef_htfrtc%gen_val(i_f,i_fit))**2)
             diste(i_fit)=exp(-coefs%coef_htfrtc%alpha(1)*dist(i_fit))
          ENDFORALL
          FORALL(i_pc=1:n_pc)
              pccomp%clear_pcscores((i_p-1)*n_pc+i_pc)=sum(diste(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
          END FORALL ! n_pc
          IF(opts%htfrtc_opts%simple_cloud) THEN
            FORALL(i_f=1:n_f)
              rc_tot(i_f)=(1.0-cf)*rc(i_f)+cf*rc_cld(i_f)
            ENDFORALL
            FORALL(i_fit=1:n_fit_dim)
              dist_cld(i_fit)=sum((rc_cld(1:n_f)-coefs%coef_htfrtc%gen_val(i_f,i_fit))**2)
              diste_cld(i_fit)=exp(-coefs%coef_htfrtc%alpha(1)*dist_cld(i_fit))
              dist_tot(i_fit)=sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(i_f,i_fit))**2)
              diste_tot(i_fit)=exp(-coefs%coef_htfrtc%alpha(1)*dist_tot(i_fit))
            ENDFORALL
            FORALL(i_pc=1:n_pc)
              pccomp%cloudy_pcscores((i_p-1)*n_pc+i_pc)=sum(diste_cld(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
              pccomp%total_pcscores((i_p-1)*n_pc+i_pc)=sum(diste_tot(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
            END FORALL ! n_pc
          ELSE
             rc_tot=rc
             dist_tot=dist
             diste_tot=diste
            FORALL(i_pc=1:n_pc)
              pccomp%total_pcscores((i_p-1)*n_pc+i_pc)=pccomp%clear_pcscores((i_p-1)*n_pc+i_pc)
            ENDFORALL
          ENDIF

          IF(opts%htfrtc_opts%overcast) THEN
            rc_oc_t=transpose(rc_oc)
            DO i = 1, nlayers
              FORALL(i_fit=1:n_fit_dim)
               dist_oc(i_fit)=sum((rc_oc_t(1:n_f,i)-coefs%coef_htfrtc%gen_val(i_f,i_fit))**2)
               diste_oc(i_fit)=exp(-coefs%coef_htfrtc%alpha(1)*dist_oc(i_fit))
              ENDFORALL
              DO i_pc = 1, n_pc_oc
                overcast_pcscores_t(i_pc,i)=sum(diste_oc(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
              ENDDO
            ENDDO
            overcast_pcscores=transpose(overcast_pcscores_t)
            DO i_pc=1,n_pc_oc
              DO i=1,nlayers
                pccomp%overcast_pcscores(i,(i_p-1)*n_pc+i_pc)=overcast_pcscores(i,i_pc)
              ENDDO
            ENDDO
          ENDIF

          IF(do_k) THEN

          DO i_fit=1,n_fit_dim

             FORALL(i=1:nlevels)
                ddistedt(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdt(1:n_f,i))
                ddistedq(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdq(1:n_f,i))
             ENDFORALL

                ddistedst(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdst(1:n_f))
                ddistedsp(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdsp(1:n_f))
                ddisteds2mt(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mt(1:n_f))
                ddisteds2mq(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mq(1:n_f))
                ddisteds2mo(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mo(1:n_f))
                ddisteds2mp(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mp(1:n_f))
                ddisteds2mu(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mu(1:n_f))
                ddisteds2mv(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcds2mv(1:n_f))
                ddistedcf(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdcf(1:n_f))
                ddistedctp(i_fit)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                  sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdctp(1:n_f))

          ENDDO

          FORALL(i_pc=1:n_pc)

             FORALL(i=1:nlevels)
                profiles_k_pc((i_p-1)*n_pc+i_pc)%t(i)=sum(ddistedt(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%q(i)=sum(ddistedq(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
             ENDFORALL

                profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%t=sum(ddistedst(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%specularity= &
                  sum(ddistedsp(1:n_f)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%t=sum(ddisteds2mt(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%q=sum(ddisteds2mq(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%o=sum(ddisteds2mo(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%p=sum(ddisteds2mp(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%u=sum(ddisteds2mu(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%v=sum(ddisteds2mv(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%cfraction= &
                  sum(ddistedcf(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                profiles_k_pc((i_p-1)*n_pc+i_pc)%ctp=sum(ddistedctp(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))

          END FORALL ! n_pc

          IF(opts%rt_ir%ozone_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedo3(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdo3(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%o3(i)= &
                     sum(ddistedo3(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%co2_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedco2(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdco2(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%co2(i)= &
                     sum(ddistedco2(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%n2o_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedn2o(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdn2o(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%n2o(i)= &
                     sum(ddistedn2o(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%co_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedco(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdco(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%co(i)= &
                     sum(ddistedco(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%ch4_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedch4(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdch4(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%ch4(i)= &
                     sum(ddistedch4(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF
          IF(opts%rt_ir%so2_data) THEN
             DO i_fit=1,n_fit_dim
                FORALL(i=1:nlevels)
                   ddistedso2(i_fit,i)=-2.0*coefs%coef_htfrtc%alpha(1)*diste_tot(i_fit)*dist_tot(i_fit)* &
                     sum((rc_tot(1:n_f)-coefs%coef_htfrtc%gen_val(1:n_f,i_fit))*drcdso2(1:n_f,i))
                ENDFORALL
             ENDDO
             FORALL(i_pc=1:n_pc)
                FORALL(i=1:nlevels)
                   profiles_k_pc((i_p-1)*n_pc+i_pc)%so2(i)= &
                     sum(ddistedso2(1:n_fit_dim,i)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc))
                ENDFORALL
             ENDFORALL
          ENDIF

          ENDIF ! do_k

       ENDIF !pc_reg_type

       IF (do_k) THEN
         SELECT CASE(profiles(1)%gas_units)
         CASE(gas_unit_ppmvdry,gas_unit_ppmv)
            FORALL(i_pc=1:n_pc)
               FORALL(i=1:nlevels)
                  profiles_k_pc((i_p-1)*n_pc+i_pc)%q(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%q(i)/(cv(i)*gas_mass(gas_id_watervapour))
               ENDFORALL
               profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%q= &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%q/(cv(surf_level)*gas_mass(gas_id_watervapour))
            ENDFORALL
            IF(opts%rt_ir%ozone_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%o3(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%o3(i)/(cv(i)*gas_mass(gas_id_ozone))
                  ENDFORALL
               ENDFORALL
            ENDIF
            IF(opts%rt_ir%co2_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%co2(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%co2(i)/(cv(i)*gas_mass(gas_id_co2))
                  ENDFORALL
               ENDFORALL
            ENDIF
            IF(opts%rt_ir%n2o_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%n2o(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%n2o(i)/(cv(i)*gas_mass(gas_id_n2o))
                  ENDFORALL
               ENDFORALL
            ENDIF
            IF(opts%rt_ir%co_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%co(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%co(i)/(cv(i)*gas_mass(gas_id_co))
                  ENDFORALL
               ENDFORALL
            ENDIF
            IF(opts%rt_ir%ch4_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%ch4(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%ch4(i)/(cv(i)*gas_mass(gas_id_ch4))
                  ENDFORALL
               ENDFORALL
            ENDIF
            IF(opts%rt_ir%so2_data) THEN
               FORALL(i_pc=1:n_pc)
                  FORALL(i=1:nlevels)
                     profiles_k_pc((i_p-1)*n_pc+i_pc)%so2(i)=profiles_k_pc((i_p-1)*n_pc+i_pc)%so2(i)/(cv(i)*gas_mass(gas_id_so2))
                  ENDFORALL
               ENDFORALL
            ENDIF
         END SELECT
       ENDIF

       !Reconstruct for radiances / brightness temperatures
       IF(opts%htfrtc_opts%reconstruct) THEN

         !Radiances
         FORALL(i_ch=1:n_ch)
            pccomp%clear_pccomp((i_p-1)*n_ch+i_ch)=coefs%coef_htfrtc%ch_mean(i_ch)+&
              sum(pccomp%clear_pcscores((i_p-1)*n_pc+1:i_p*n_pc)*coefs%coef_htfrtc%pc(1:n_pc,i_ch))
         END FORALL
         IF(opts%htfrtc_opts%simple_cloud) THEN
           FORALL(i_ch=1:n_ch)
             pccomp%cloudy_pccomp((i_p-1)*n_ch+i_ch)=coefs%coef_htfrtc%ch_mean(i_ch)+&
               sum(pccomp%cloudy_pcscores((i_p-1)*n_pc+1:i_p*n_pc)*coefs%coef_htfrtc%pc(1:n_pc,i_ch))
            pccomp%total_pccomp((i_p-1)*n_ch+i_ch)=coefs%coef_htfrtc%ch_mean(i_ch)+&
              sum(pccomp%total_pcscores((i_p-1)*n_pc+1:i_p*n_pc)*coefs%coef_htfrtc%pc(1:n_pc,i_ch))
           END FORALL
         ELSE
           FORALL(i_ch=1:n_ch)
            pccomp%total_pccomp((i_p-1)*n_ch+i_ch)=pccomp%clear_pccomp((i_p-1)*n_ch+i_ch)
           ENDFORALL
         ENDIF

         IF(opts%htfrtc_opts%overcast) THEN
           DO i_ch = 1, n_ch
              DO i = 1, nlayers
                 pccomp%overcast_pccomp(i,(i_p-1)*n_ch+i_ch)=coefs%coef_htfrtc%ch_mean(i_ch)+ &
                   sum(overcast_pcscores_t(1:n_pc_oc,i)* &
                   coefs%coef_htfrtc%pc(1:n_pc_oc,i_ch))
              ENDDO
           ENDDO
         ENDIF

         !Deal with unphysical values and calculate brightness temperatures
         WHERE (pccomp%clear_pccomp((i_p-1)*n_ch+1:i_p*n_ch)<0.0_jprb)
               pccomp%clear_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=0.0_jprb
               pccomp%bt_clear_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=0.0_jprb
         ELSEWHERE
               pccomp%bt_clear_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=planck_c2_wn(1:n_ch)/ &
               log(1.0+planck_c1_wn3(1:n_ch)/pccomp%clear_pccomp((i_p-1)*n_ch+1:i_p*n_ch))
         ENDWHERE
         IF(opts%htfrtc_opts%simple_cloud) THEN
            WHERE (pccomp%cloudy_pccomp((i_p-1)*n_ch+1:i_p*n_ch)<0.0_jprb)
               pccomp%cloudy_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=0.0_jprb
            ENDWHERE
            WHERE (pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch)<0.0_jprb)
               pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=0.0_jprb
               pccomp%bt_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=0.0_jprb
            ELSEWHERE
               pccomp%bt_pccomp((i_p-1)*n_ch+1:i_p*n_ch)=planck_c2_wn(1:n_ch)/ &
               log(1.0+planck_c1_wn3(1:n_ch)/pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch))
            ENDWHERE
         ELSE
            FORALL(i_ch=1:n_ch)
               pccomp%total_pccomp((i_p-1)*n_ch+i_ch)=pccomp%clear_pccomp((i_p-1)*n_ch+i_ch)
               pccomp%bt_pccomp((i_p-1)*n_ch+i_ch)=pccomp%bt_clear_pccomp((i_p-1)*n_ch+i_ch)
         ENDFORALL
         ENDIF

         IF(do_k) THEN

         DO i_ch = 1, n_ch

            profiles_k_rec((i_p-1)*n_ch+i_ch)%t(:) = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%q(:) = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%specularity = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%t = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%q = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%o = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%p = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%u = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%v = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%cfraction = 0._jprb
            profiles_k_rec((i_p-1)*n_ch+i_ch)%ctp = 0._jprb

            DO i_pc = 1, n_pc

                DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%t(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%t(i) + &
                    profiles_k_pc((i_p-1)*n_pc+i_pc)%t(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%q(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%q(i) + &
                    profiles_k_pc((i_p-1)*n_pc+i_pc)%q(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                ENDDO

               profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t=profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%t*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t=profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%specularity + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%skin%specularity*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%t=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%t + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%t*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%q=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%q + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%q*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%o=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%o + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%o*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%p=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%p + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%p*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%u=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%u + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%u*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%v=profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%v + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%s2m%v*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%cfraction=profiles_k_rec((i_p-1)*n_ch+i_ch)%cfraction + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%cfraction*coefs%coef_htfrtc%pc(i_pc,i_ch)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%ctp=profiles_k_rec((i_p-1)*n_ch+i_ch)%ctp + &
                 profiles_k_pc((i_p-1)*n_pc+i_pc)%ctp*coefs%coef_htfrtc%pc(i_pc,i_ch)

            ENDDO

         ENDDO

         IF(opts%rt_ir%ozone_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%o3(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%o3(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%o3(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%o3(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%co2_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%co2(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%co2(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%co2(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%co2(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%n2o_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%n2o(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%n2o(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%n2o(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%n2o(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%co_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%co(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%co(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%co(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%co(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%ch4_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%ch4(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%ch4(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%ch4(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%ch4(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%so2_data) THEN
            DO i_ch = 1, n_ch
               profiles_k_rec((i_p-1)*n_ch+i_ch)%so2(:) = 0._jprb
               DO i_pc = 1, n_pc
                   DO i = 1, nlevels
                     profiles_k_rec((i_p-1)*n_ch+i_ch)%so2(i)=profiles_k_rec((i_p-1)*n_ch+i_ch)%so2(i) + &
                       profiles_k_pc((i_p-1)*n_pc+i_pc)%so2(i)*coefs%coef_htfrtc%pc(i_pc,i_ch)
                   ENDDO
               ENDDO
            ENDDO
         ENDIF

         IF (opts%htfrtc_opts%reconstruct .AND. PRESENT(emissivity_k)) THEN

          IF (coefs%coef_htfrtc%pc_reg_type==1) THEN

           DO i_ch = 1, n_ch
              emissivity_k((i_p-1)*n_ch+i_ch)%emis_out = 0._jprb
              DO i_pc = 1, n_pc
                 emissivity_k((i_p-1)*n_ch+i_ch)%emis_out=emissivity_k((i_p-1)*n_ch+i_ch)%emis_out + &
                 ((1.0-fb_r(i_ch))*drcdsem(fb_i(i_ch))*coefs%coef_htfrtc%coef_pdt(fb_i(i_ch),i_pc) + &
                  fb_r(i_ch)*drcdsem(fb_i(i_ch)+1)*coefs%coef_htfrtc%coef_pdt(fb_i(i_ch)+1,i_pc)) &
                 *coefs%coef_htfrtc%pc(i_pc,i_ch)
              ENDDO
           ENDDO

          ELSE IF (coefs%coef_htfrtc%pc_reg_type==2) THEN

           DO i_ch = 1, n_ch
              emissivity_k((i_p-1)*n_ch+i_ch)%emis_out = 0._jprb
              DO i_pc = 1, n_pc
                 emissivity_k((i_p-1)*n_ch+i_ch)%emis_out=emissivity_k((i_p-1)*n_ch+i_ch)%emis_out + &
                 (-2.0)*coefs%coef_htfrtc%alpha(1)* &
                 sum(diste_tot(1:n_fit_dim)*dist_tot(1:n_fit_dim)*coefs%coef_htfrtc%coef_pdt(1:n_fit_dim,i_pc)* &
                 ((1.0-fb_r(i_ch))*(rc_tot(fb_i(i_ch))-coefs%coef_htfrtc%gen_val(fb_i(i_ch),1:n_fit_dim))*drcdsem(fb_i(i_ch)) &
                 +fb_r(i_ch)*(rc_tot(fb_i(i_ch)+1)-coefs%coef_htfrtc%gen_val(fb_i(i_ch)+1,1:n_fit_dim))*drcdsem(fb_i(i_ch)+1)))
              ENDDO
           ENDDO

          ENDIF

         ENDIF

         IF(opts%rt_all%switchrad) THEN

         WHERE (pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch)<=0.0_jprb)
            swrad_tmp(1:n_ch)=0.0_jprb
         ELSEWHERE
               swrad_tmp(1:n_ch)=planck_c1_wn3(1:n_ch)*(pccomp%bt_pccomp((i_p-1)*n_ch+1:i_p*n_ch))**2 &
               /(planck_c2_wn(1:n_ch)*pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch) &
                *(pccomp%total_pccomp((i_p-1)*n_ch+1:i_p*n_ch)+planck_c1_wn3(1:n_ch)))
         ENDWHERE

         DO i_ch = 1, n_ch

            DO i = 1, nlevels
               profiles_k_rec((i_p-1)*n_ch+i_ch)%t(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%t(i)
               profiles_k_rec((i_p-1)*n_ch+i_ch)%q(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%q(i)
            ENDDO

            profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%t
            profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%specularity=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%skin%specularity
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%t=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%t
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%q=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%q
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%o=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%o
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%p=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%p
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%u=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%u
            profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%v=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%s2m%v
            profiles_k_rec((i_p-1)*n_ch+i_ch)%cfraction=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%cfraction
            profiles_k_rec((i_p-1)*n_ch+i_ch)%ctp=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%ctp

         ENDDO

         IF(opts%rt_ir%ozone_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%o3(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%o3(i)
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%co2_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%co2(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%co2(i)
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%n2o_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%n2o(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%n2o(i)
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%co_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%co(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%co(i)
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%ch4_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%ch4(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%ch4(i)
               ENDDO
            ENDDO
         ENDIF
         IF(opts%rt_ir%so2_data) THEN
            DO i_ch = 1, n_ch
               DO i = 1, nlevels
                  profiles_k_rec((i_p-1)*n_ch+i_ch)%so2(i)=swrad_tmp(i_ch)*profiles_k_rec((i_p-1)*n_ch+i_ch)%so2(i)
               ENDDO
            ENDDO
         ENDIF

         IF (opts%htfrtc_opts%reconstruct .AND. PRESENT(emissivity_k)) THEN
            DO i_ch = 1, n_ch
               emissivity_k((i_p-1)*n_ch+i_ch)%emis_out=swrad_tmp(i_ch)*emissivity_k((i_p-1)*n_ch+i_ch)%emis_out
            ENDDO
         ENDIF

         ENDIF ! switchrad

         ENDIF ! do_k

       ENDIF ! reconstruct

    ENDDO ! i_p (main loop over profiles)

    !For backward compatibility
    pccomp%pcscores=pccomp%clear_pcscores

    IF(opts%htfrtc_opts%overcast) THEN
      WHERE(pccomp%overcast_pccomp<0.0_jprb) pccomp%overcast_pccomp=0.0_jprb
      DEALLOCATE(overcast_pcscores)
      DEALLOCATE(overcast_pcscores_t)
    ENDIF

    IF(coefs%coef_htfrtc%pc_reg_type==2) THEN
       DEALLOCATE(dist)
       DEALLOCATE(diste)
       DEALLOCATE(dist_cld)
       DEALLOCATE(diste_cld)
       DEALLOCATE(dist_tot)
       DEALLOCATE(diste_tot)
       DEALLOCATE(dist_oc)
       DEALLOCATE(diste_oc)
       IF(do_k) THEN
         DEALLOCATE(ddistedt)
         DEALLOCATE(ddistedq)
         DEALLOCATE(ddistedo3)
         DEALLOCATE(ddistedco2)
         DEALLOCATE(ddistedn2o)
         DEALLOCATE(ddistedco)
         DEALLOCATE(ddistedch4)
         DEALLOCATE(ddistedso2)
         DEALLOCATE(ddistedst)
         DEALLOCATE(ddistedsp)
         DEALLOCATE(ddisteds2mt)
         DEALLOCATE(ddisteds2mq)
         DEALLOCATE(ddisteds2mo)
         DEALLOCATE(ddisteds2mp)
         DEALLOCATE(ddisteds2mu)
         DEALLOCATE(ddisteds2mv)
         DEALLOCATE(ddistedcf)
         DEALLOCATE(ddistedctp)
       ENDIF
    ENDIF

    CATCH

  END SUBROUTINE htfrtc_interface

END MODULE rttov_htfrtc_interface_mod
