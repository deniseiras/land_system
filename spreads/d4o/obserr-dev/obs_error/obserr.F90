SUBROUTINE OBSERR(KVAR,KOBTYP,KSQOBTYP,KCDTYP,KSQCDTYP,PLAT,PLON,&
 & PRES1, &
 & POBSERR                                        )  

!****  SUBROUTINE OBSERR - RETRIEVE OBSERVATION ERROR

!         D. VASILJEVIC     ECMWF    21/10/94

!      PURPOSE
!      -------

!        RETRIEVE OBSERVATION ERROR

!**   INTERFACE
!     ---------

!        CALL OBSERR(KVAR,KOBTYP,KSQOBTYP,KCDTYP,KSQCDTYP,PLAT,PLON,
!                    PRES1, 
!                    POBSERR                                        )
!     WHERE:
!           KVAR     = OBS. VARIABLE NUMBER
!           KOBTYP   = OBS. TYPE
!           KSQOBTYP = OBS. TYPE SQ. NO.
!           KCDTYP   = CODE TYPE
!           KSQCDTYP = CODE TYPE SQ. NO.
!           PLAT     = LATITUDE
!           PLON     = LONGITUDE
!           PRES1    = PRESSURE (VERTICAL REF. 1)
!           POBSERR  = OBS. ERROR

!         OBSERR IS CALLED BY SUBROUTINES

!     METHOD
!     ------

!        THE OBSERVATION ERROR IS ASSIGNED DEPENDING ON THE OBSERVATION
!     TYPE, ITS VERTICAL POSITION.

!     EXTERNALS
!     ---------

!        FIXERR - INTERPOLATE OBSERVATION ERROR IN VERTICAL
!        ENDRUN - ABORT

!**   MODIFICATIONS
!     -------------

!-----------------------------------------------------------------------

USE PARKIND1  ,ONLY : JPIM     ,JPRB
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK

USE YOMANCS  , ONLY : RMDI
USE YOMOERR  , ONLY : OEWIND   ,OETEMP   ,OEHEIG
USE YOMCOCTP , ONLY : NTEMP    ,NPILOT
USE YOMERR   , ONLY : LHEAREAD
USE VARNO_MODULE, ONLY : VARNO
USE YOMLUN   , ONLY : NULOUT

IMPLICIT NONE

INTEGER(KIND=JPIM),INTENT(IN)    :: KVAR 
INTEGER(KIND=JPIM),INTENT(IN)    :: KOBTYP 
INTEGER(KIND=JPIM),INTENT(IN)    :: KSQOBTYP 
INTEGER(KIND=JPIM),INTENT(IN)    :: KCDTYP 
INTEGER(KIND=JPIM),INTENT(IN)    :: KSQCDTYP 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PLAT 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PLON 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PRES1 
REAL(KIND=JPRB)   ,INTENT(OUT)   :: POBSERR 
INTEGER(KIND=JPIM) :: IAREA

REAL(KIND=JPRB) :: ZERROR, ZLATA11, ZLATA12, ZLATA13, ZLATA14,&
 & ZLATA31, ZLATA32, ZLATA33, ZLATA34, ZLONA11, &
 & ZLONA12, ZLONA13, ZLONA14, ZLONA31, ZLONA32, &
 & ZLONA33, ZLONA34  
REAL(KIND=JPRB) :: ZHOOK_HANDLE

#include "abor1.intfb.h"
#include "fixerr.intfb.h"

!*

!        0.       PRESET
!                 ------

!*          0.1   MISSING IND. FOR OBS. ERROR

IF (LHOOK) CALL DR_HOOK('OBSERR',0,ZHOOK_HANDLE)
ZERROR = RMDI

!*          0.2   GEOGRAPHICAL AREA TO AREA 1

IAREA  =   1

!*          0.3   GEOGRAPHICAL AREA 1 LAT/LON LIMITS

ZLATA11  =  80._JPRB
ZLATA12  =  30._JPRB
ZLONA11  = -50._JPRB
ZLONA12  =-170._JPRB

ZLATA13  =  70._JPRB
ZLATA14  =  45._JPRB
ZLONA13  = -30._JPRB
ZLONA14  =  20._JPRB

!*          0.3   GEOGRAPHICAL AREA 3 LAT/LON LIMITS

ZLATA31  =  10._JPRB
ZLATA32  = -60._JPRB
ZLONA31  = -30._JPRB
ZLONA32  = -90._JPRB

ZLATA33  =  30._JPRB
ZLATA34  = -40._JPRB
ZLONA33  =  60._JPRB
ZLONA34  = -20._JPRB
!*
!-----------------------------------------------------------------------

!        1.       WIND ERRORS
!                 -----------

IF(KVAR == VARNO%U.OR.&
   & KVAR == VARNO%V.OR.&
   & KVAR == VARNO%U10M.OR.&
   & KVAR == VARNO%V10M    ) THEN  

!*          1.1   INTERPOLATE WIND ERRORS

  CALL FIXERR(OEWIND,IAREA,KSQOBTYP,KSQCDTYP,PRES1,ZERROR)
!*
!-----------------------------------------------------------------------

!        2.       HEIGHT ERRORS
!                 -------------

ELSEIF(KVAR == VARNO%Z)                       THEN

!*          2.1   FIND OUT AREA

  IF(LHEAREAD)                                      THEN

!*          2.1.1 ERRORS DEPENDENT ON AREA

!*          2.1.1.1 TEMP/PILOT

    IF(KOBTYP == NTEMP .OR.KOBTYP == NPILOT    )            THEN
      IAREA = 2
!              IF(PLAT.LE.  80..AND.
!    1            PLAT.GE.  30..AND.
!    2            PLON.LE. -50..AND.
!    3            PLON.GE.-170.    )               THEN
      IF(PLAT <= ZLATA11.AND.&
         & PLAT >= ZLATA12.AND.&
         & PLON <= ZLONA11.AND.&
         & PLON >= ZLONA12     )            THEN  
        IAREA = 1
!              ELSEIF(PLAT.LE.  70..AND.
!    1                 PLAT.GE.  45..AND.
!    2                 PLON.GE. -30..AND.
!    3                 PLON.LE.  20.     )         THEN
      ELSEIF(PLAT <= ZLATA13.AND.&
         & PLAT >= ZLATA14.AND.&
         & PLON >= ZLONA13.AND.&
         & PLON <= ZLONA14     )       THEN  
        IAREA = 1
!              ELSEIF(PLAT.LE.  10..AND.
!    1                 PLAT.GE. -60..AND.
!    2                 PLON.LE. -30..AND.
!    3                 PLON.GE. -90.     .OR.
!    4                 PLAT.LE.  30..AND.
!    5                 PLAT.GE. -40..AND.
!    6                 PLON.LE.  60..AND.
!    7                 PLON.GE. -20.         )     THEN
      ELSEIF((PLAT <= ZLATA31.AND.&
         & PLAT >= ZLATA32.AND.&
         & PLON <= ZLONA31.AND.&
         & PLON >= ZLONA32     ).OR.&
         & (PLAT <= ZLATA33.AND.&
         & PLAT >= ZLATA34.AND.&
         & PLON <= ZLONA33.AND.&
         & PLON >= ZLONA34     )    ) THEN  
        IAREA = 3
      ENDIF

!*          2.1.1.2 OTHERS

    ELSE
      IAREA = 1
    ENDIF

!*          2.1.2 ERRORS NOT DEPENDENT ON AREA

  ELSE
    IAREA = 1
  ENDIF

!*          2.2   INTERPOLATE HEIGHT ERRORS

  CALL FIXERR(OEHEIG,IAREA,KSQOBTYP,KSQCDTYP,PRES1,ZERROR)
!*
!-----------------------------------------------------------------------

!        3.       TEMPERATURE ERRORS
!                 ------------------

ELSEIF(KVAR == VARNO%T.OR.KVAR == VARNO%T2M    )                    THEN

!*          3.2   INTERPOLATE TEMPERATURE ERRORS

  CALL FIXERR(OETEMP,IAREA,KSQOBTYP,KSQCDTYP,PRES1,ZERROR)
!*
!-----------------------------------------------------------------------

!        4.       UNKNOWN TYPE OF ERROR
!                 ---------------------

ELSE
  WRITE(NULOUT,'(''0ERROR IN SUBROUTINE OBSERR'')')
  WRITE(NULOUT,'('' INVALID ERROR TYPE'')')
  WRITE(NULOUT,'('' OBSERVATION TYPE = '',I10)') KOBTYP
  WRITE(NULOUT,'('' CODE TYPE        = '',I10)') KCDTYP
  WRITE(NULOUT,'('' VARIABLE NUMBER  = '',I10)') KVAR
  CALL ABOR1('SUBROUTINE OBSERR')
ENDIF
!*
!-----------------------------------------------------------------------

!        5.       ASSIGN OBS. ERROR
!                 -----------------

POBSERR = ZERROR
!*
!-----------------------------------------------------------------------

!        6.       RETURN
!                 ------

IF (LHOOK) CALL DR_HOOK('OBSERR',1,ZHOOK_HANDLE)
END SUBROUTINE OBSERR
