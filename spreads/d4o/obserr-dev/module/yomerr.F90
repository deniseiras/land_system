MODULE YOMERR

USE PARKIND1  ,ONLY : JPRB

IMPLICIT NONE

SAVE

!*     YOMERR - ERROR PARAMETERS

!        D. VASILJEVIC   ECMWF     15/9/94

!     NAME      TYPE                  MEANING
!     ----      ----                  -------
!     LHEAREAD    L       HEIGHT ERROR DEPENDENT ON AREA SWITCH
!     LRHERRMO    L       REL. HUM. OBS. ERROR MODELED SWITCH
!     LPERERCO    L       PERSISTENCE ERROR EVALUATIN VIA IFS ROUTINES SWITCH

LOGICAL :: LHEAREAD
LOGICAL :: LRHERRMO
LOGICAL :: LPERERCO

!-----------------------------------------------------------------------

END MODULE YOMERR
