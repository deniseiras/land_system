FUNCTION DATASTREAM(BUFRTYPE,BUFRSUBTYPE,&
 &   GEN_CENTRE,GEN_SUBCENTRE,SATID)

USE PARKIND1  ,ONLY : JPRD

IMPLICIT NONE

REAL(KIND=JPRD)   :: DATASTREAM

REAL(KIND=JPRD), INTENT(IN)   :: BUFRTYPE
REAL(KIND=JPRD), INTENT(IN)   :: BUFRSUBTYPE
REAL(KIND=JPRD), INTENT(IN)   :: GEN_CENTRE
REAL(KIND=JPRD), INTENT(IN)   :: GEN_SUBCENTRE
REAL(KIND=JPRD), INTENT(IN)   :: SATID


!  11/11/2008   I. Genkova     Modify db MODIS datastream
!======================================


DATASTREAM = 0._JPRD          ! Global data is default

IF(          BUFRTYPE    == 3._JPRD            &     ! SATEM
 &     .AND. (     BUFRSUBTYPE == 55._JPRD &         ! ATOVS
 &            .OR. BUFRSUBTYPE == 154._JPRD ) ) THEN ! VASS

  ! Special streams for ATOVS data
  !-------------------------------

  IF(          GEN_CENTRE    == 254._JPRD      &   ! EUMETSAT
   &     .AND. GEN_SUBCENTRE > 0._JPRD ) THEN      ! Some sub-centre
    DATASTREAM = 1._JPRD                            ! EARS

  ELSEIF(    ( GEN_CENTRE <= 72._JPRD .AND. GEN_CENTRE /= 46 ) &
          .OR. GEN_CENTRE == 110 .OR. GEN_CENTRE == 191 .OR. GEN_CENTRE == 204 ) THEN      
    DATASTREAM = 2._JPRD                            ! Pacific RARS/DBNet

  ELSEIF(      GEN_CENTRE == 46 .OR. GEN_CENTRE == 147 ) THEN
    DATASTREAM = 3._JPRD                            ! South American RARS/DBNet
  ENDIF

ELSEIF(       BUFRTYPE    == 5._JPRD            & ! SATOB/AMV
 &      .AND. BUFRSUBTYPE == 87._JPRD ) THEN      ! Ext. AMV with QI

  ! Special streams for AMVs 
  !-------------------------



  IF( ( GEN_CENTRE == 173._JPRD .OR. GEN_CENTRE == 176._JPRD  & ! CIMSS
   &    .OR.( GEN_CENTRE == 160._JPRD              & ! NESDIS
   &          .AND. GEN_SUBCENTRE > 0._JPRD )  )   &
   &  .AND. ( SATID == 783 .OR. SATID == 784) ) THEN
    DATASTREAM = 1._JPRD                             ! Direct broadcast MODIS
  ENDIF

ELSEIF(       BUFRTYPE    == 12._JPRD            & ! SCATT
 &      .AND. BUFRSUBTYPE == 139._JPRD           & ! ASCAT
 &      .AND. GEN_SUBCENTRE > 0._JPRD  ) THEN      ! Non-EUMETSAT 
    DATASTREAM = 1._JPRD                           ! EARS
END IF


END FUNCTION DATASTREAM
