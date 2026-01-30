SUBROUTINE SULEVLAY

!**** SUBROUTINE SULEVLAY - SETUP LEVEL/LAYER PARAMETERS/ARRAYS

!        D. VASILJEVIC    ECMWF   06/09/1994

!**   PURPOSE
!     -------

!        SETUP LEVEL/LAYER STRUCTURES

!**   INTERFACE
!     ---------

!        CALL SULEVLAY

!        SULEVLAY IS CALLED BY MAKECMA

!**   METHOD
!     ------

!        NECESSARY PARAMETERS/ARRAYS ARE DEFINED.

!**   EXTERNALS
!     ---------

!**   MODIFICTIONS
!     ------------
!        K. Yessad (Jan 2010): remove useless variables.
!        A. Geer   (Dec 2016): remove useless variables
!-----------------------------------------------------------------------

USE PARKIND1  ,ONLY : JPIM     ,JPRB
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK

USE YOMLVLY  , ONLY : NMXSTLV , STPRELV  ,STPRELVL ,NMXLAYER  
USE YOMCOSJO , ONLY : NBDLAYER, NTROPOP
USE YOMLUN   , ONLY : NULOUT

!-----------------------------------------------------------------------

IMPLICIT NONE

INTEGER(KIND=JPIM) :: JLN
REAL(KIND=JPRB) :: ZHOOK_HANDLE

!-----------------------------------------------------------------------
IF (LHOOK) CALL DR_HOOK('SULEVLAY',0,ZHOOK_HANDLE)
!-----------------------------------------------------------------------

!*
!        0.       BASIC PARAMETERS
!                 ----------------

NMXSTLV  = 15
NMXLAYER = 14
!*
!        1.       STANDARD PRESSURE LEVELS AND THEIR LNS.
!                 ---------------------------------------

!*          1.1   STANDARD PRESSURE LEVELS IN Pa

STPRELV( 1) = 100000._JPRB
STPRELV( 2) =  85000._JPRB
STPRELV( 3) =  70000._JPRB
STPRELV( 4) =  50000._JPRB
STPRELV( 5) =  40000._JPRB
STPRELV( 6) =  30000._JPRB
STPRELV( 7) =  25000._JPRB
STPRELV( 8) =  20000._JPRB
STPRELV( 9) =  15000._JPRB
STPRELV(10) =  10000._JPRB
STPRELV(11) =   7000._JPRB
STPRELV(12) =   5000._JPRB
STPRELV(13) =   3000._JPRB
STPRELV(14) =   2000._JPRB
STPRELV(15) =   1000._JPRB

! Values to define the different layers used for the Huber Varqc, see defrun 1.8.14
NBDLAYER = 1
NTROPOP  = 9

!*          1.2   LN OF STANDARD PRESSURE LEVELS

DO JLN = 1 , NMXSTLV
  STPRELVL(JLN) = LOG(STPRELV(JLN))
ENDDO

WRITE(NULOUT,'(''0LEVEL/LAYER STRUCTURE SETUP'')')

!-----------------------------------------------------------------------
IF (LHOOK) CALL DR_HOOK('SULEVLAY',1,ZHOOK_HANDLE)
END SUBROUTINE SULEVLAY
