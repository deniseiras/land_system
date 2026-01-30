SUBROUTINE SATOBFREQ(SATID,FREQ,ID_FREQ)
USE PARKIND1  ,ONLY : JPIM     ,JPRD
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK


!**** SUBROUTINE SATOBFREQ - CHANNEL ID FROM CHANNEL FREQUENCY FOR SATOB
!
!          LUEDER VON BREMEN, ECMWF          05/SEPT/2003
!
!     PURPOSE
!     -------
!     
!     WITH THE INTRODUCTION OF SATOBS FROM SEVERAL CHANNELS WITHIN THE SAME BAND 
!     IT GETS NECESSARY TO DISTINGUISH THESE FREQUENCIES WITHIN THE COMPUTATIONAL
!     METHOD. THEREFORE A FREQUENCY ID FOR EACH BAND IS CHOSEN. 
!     THE FREQUENCY ID IS DETERMINED IN THIS ROUTINE FOR EACH SATELLITE HAVING MORE 
!     ONE FREQUENCY PER BAND (COMPUTATIONAL METHOD). IT STARTS WITH METEOSAT SECOND 
!     GENERATION (MSG).
!
!     INTERFACE
!     ---------
!
!     ***CALL*SATOBFREQ(SATID,FREQ,ID_FREQ)
!     WHERE SATID   = SATELLITE IDENTIFIER
!           FREQ    = CHANNEL FREQUENCY 
!           ID_FREQ = ID (NUMBER) OF THE FREQUENCY WITHIN THE BAND
!
!     SATOBFREQ IS CALLED BY SUBROUTINE bufr2odb_satob (odb/bufr2odb) AND buxtract (obstat/src)
!
!*    METHOD
!     ------
!     
!     THE CHANNEL FREQUENCY IS COMPARED WITH THE KNOWN VALUES. IF A CHANNEL FREQUENCY 
!     CAN NOT BE SORTED, THE ID_FREQ KEEPS ZERO AND THIS CHANNEL WILL BE BLACKLISTED BY
!     THE 'notin' COMMAND IN THE BLACKLIST.
!
!*    EXTERNALS
!     ---------

!**   MODIFICATIONS
!     -------------
!     05/06/06   CLAIRE DELSOL  Added ID for MET-9 and GOES-11
!
!     06/2005 C. PAYAN : GOES11, Meteosat-9 added, sorted by increasing satid

INTEGER(KIND=JPIM), INTENT(IN)  :: SATID
REAL(KIND=JPRD), INTENT(IN)     :: FREQ                  ! Hz
INTEGER(KIND=JPIM), INTENT(OUT) :: ID_FREQ
REAL(KIND=JPRD),parameter       :: epsilon=0.00001D+15 ! Hz

REAL(KIND=JPRD) :: ZHOOK_HANDLE

!--------------------------------------------------------------------------------------

IF (LHOOK) CALL DR_HOOK('SATOBFREQ',0,ZHOOK_HANDLE)

         ID_FREQ=0
         if ((SATID == 55) .or. (SATID == 56) .or. (SATID == 57) .or. & ! Meteosat-8, Meteosat-9, Meteosat-10
          &  (SATID == 70)) then !Meteosat-11
            if(FREQ .gt. 0.4721142137D15-epsilon     .and. FREQ .lt. 0.4721142137D15+epsilon ) then
               ID_FREQ=1        ! VIS1
            elseif(FREQ .gt. 0.399723D15-epsilon .and. FREQ .lt. 0.399723D15+epsilon ) then
               ID_FREQ=3        ! VIS2 (high resolution)
            elseif(FREQ .gt. 0.3701142098D15-epsilon .and. FREQ .lt. 0.3701142098D15+epsilon ) then
               ID_FREQ=2        ! VIS3
            elseif(FREQ .gt. 0.4796679874D14-epsilon .and. FREQ .lt. 0.4796679874D14+epsilon ) then
               ID_FREQ=1        ! WV1
            elseif(FREQ .gt. 0.4078810064D14-epsilon .and. FREQ .lt. 0.4078810064D14+epsilon ) then
               ID_FREQ=2        ! WV2
            elseif(FREQ .gt. 0.344589D14-epsilon .and. FREQ .lt. 0.344589D14+epsilon ) then 
               ID_FREQ=1        ! IR1
            elseif(FREQ .gt. 0.310344D14-epsilon .and. FREQ .lt. 0.310344D14+epsilon ) then 
               ID_FREQ=2        ! IR2
            elseif(FREQ .gt. 0.2775860013D14-epsilon .and. FREQ .lt. 0.2775860013D14+epsilon ) then 
               ID_FREQ=3        ! IR3
            else 
               WRITE(*,*) '%E SATOBFREQ: channel frequency for',SATID,' has not been recognized',FREQ
            endif
         endif

         if ((SATID == 254) .or. (SATID == 255) .or. (SATID == 256) .or. & ! GOES-10,11,12
          &  (SATID == 257) .or. (SATID == 258) .or. (SATID == 259)) then  ! GOES-13,14,15
            if(FREQ .gt. 0.461538D15-epsilon     .and. FREQ .lt. 0.461538D15+epsilon ) then
               ID_FREQ=1        ! VIS1 (0.65um)
            elseif(FREQ .gt. 0.405405D14-epsilon .and. FREQ .lt. 0.405405D14+epsilon ) then
               ID_FREQ=1        ! WV1 (7.4um)
            elseif(FREQ .gt. 0.428571D14-epsilon .and. FREQ .lt. 0.428571D14+epsilon ) then
               ID_FREQ=2        ! WV2 (7.0um)
            elseif(FREQ .gt. 0.441176D14-epsilon .and. FREQ .lt. 0.461219D14+epsilon ) then
               ID_FREQ=3        ! WV3 (6.8um)
            elseif(FREQ .gt. 0.280374D14-epsilon .and. FREQ .lt. 0.280374D14+epsilon ) then 
               ID_FREQ=1        ! IR1 (10.7um)
            elseif(FREQ .gt. 0.768699D14-epsilon .and. FREQ .lt. 0.768699D14+epsilon ) then 
               ID_FREQ=2        ! IR2 (3.9um)
!-- pollutes output --> removed by SS on 14-Dec-2005
!            else 
!               WRITE(*,*) '%E SATOBFREQ: channel frequency for',SATID,' has not been recognized',FREQ
            endif
         endif
         
         if ((SATID == 270) .or. (SATID == 271)) then ! GOES-16,-17
            if(FREQ .gt. 0.4684257D15-epsilon     .and. FREQ .lt. 0.4684257D15+epsilon ) then
               ID_FREQ=1        ! VIS1 (0.64um)
            elseif(FREQ .gt. 0.408437D14-epsilon .and. FREQ .lt. 0.408437D14+epsilon ) then
               ID_FREQ=1        ! WV1 (7.4um)
            elseif(FREQ .gt. 0.431356D14-epsilon .and. FREQ .lt. 0.431356D14+epsilon ) then
               ID_FREQ=2        ! WV2 (7.0um)
            elseif(FREQ .gt. 0.484317D14-epsilon .and. FREQ .lt. 0.484317D14+epsilon ) then
               ID_FREQ=3        ! WV3 (6.15um)
            elseif(FREQ .gt. 0.267672D14-epsilon .and. FREQ .lt. 0.267672D14+epsilon ) then 
               ID_FREQ=1        ! IR1 (11.2um)
            elseif(FREQ .gt. 0.768699D14-epsilon .and. FREQ .lt. 0.768699D14+epsilon ) then 
               ID_FREQ=2        ! IR2 (3.9um)
            else 
               WRITE(*,*) '%E SATOBFREQ: channel frequency for',SATID,' has not been recognized',FREQ
            endif
         endif

         if (SATID == 471) then ! INSAT-3D AMVs
            if(FREQ .gt. 0.4357D14-epsilon .and. FREQ .lt. 0.4357D14+epsilon ) then
               ID_FREQ=1        ! WV mixed
            elseif(FREQ .gt. 0.78299D14-epsilon .and. FREQ .lt. 0.78299D14+epsilon ) then
               ID_FREQ=2        ! IR2
            elseif(FREQ .gt. 0.277D14-epsilon .and. FREQ .lt.  0.277D14+epsilon ) then
               ID_FREQ=1        ! IR1
            elseif(FREQ .gt. 0.4600D15-epsilon .and. FREQ .lt.  0.4600D15+epsilon ) then
               ID_FREQ=1        ! VIS
            else 
               WRITE(*,*) '%E SATOBFREQ: channel frequency for',SATID,' has not been recognized',FREQ
            endif
         endif

         if (SATID == 810) then  ! COMS AMVs
            ID_FREQ=1
            if(FREQ .gt. 0.8D14-epsilon .and. FREQ .lt. 0.8D14+epsilon ) then
               ID_FREQ=2        ! IR2 (3.75um)
            endif
         endif

         if ((SATID == 173)) then ! Himawari-8
            if(FREQ .gt. 0.46842570D15-epsilon     .and. FREQ .lt.  0.46842570D15+epsilon ) then
               ID_FREQ=1        ! VIS1
            elseif(FREQ .gt. 0.41067400D14-epsilon .and. FREQ .lt. 0.41067400D14+epsilon ) then
               ID_FREQ=1        ! WV1
            elseif(FREQ .gt. 0.43448100D14-epsilon .and. FREQ .lt.  0.43448100D14+epsilon ) then
               ID_FREQ=2        ! WV2
            elseif(FREQ .gt. 0.48353600D14-epsilon .and. FREQ .lt.  0.48353600D14+epsilon ) then
               ID_FREQ=3        ! WV3
            elseif(FREQ .gt. 0.28826100D14-epsilon .and. FREQ .lt. 0.28826100D14+epsilon ) then 
               ID_FREQ=1        ! IR1
            else 
               WRITE(*,*) '%E SATOBFREQ: channel frequency for',SATID,' has not been recognized',FREQ
            endif
         endif

IF (LHOOK) CALL DR_HOOK('SATOBFREQ',1,ZHOOK_HANDLE)

END SUBROUTINE SATOBFREQ
