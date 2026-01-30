SUBROUTINE BLINIT

!**** SUBROUTINE BLINIT - INITIALIZE BLACKLISTING INTERFACE

!          HEIKKI JARVINEN   ECMWF          15/MAR/1995

!*    PURPOSE
!     -------

!        INITIALIZE BLACKLISTING INTERFACE

!**   INTERFACE
!     ---------

!     ***CALL BLINIT

!        BLINIT IS CALLED BY SUBROUTINE SCREEN

!*    METHOD
!     ------

!        THERE ARE A DEFINITE SET OF VARIABLES THAT ARE PASSED FOR THE
!     BLACKLISTING THROUGH THE INTERFACE 'BLACKLBOX'. THESE VARIABLES
!     THAT ARE RELATED TO THE OBSERVATIONS AND TO MODEL FIELDS, ARE
!     DEFINED HERE AND TOLD TO THE BLACKLIST INTERPRETOR.

!*    EXTERNALS
!     ---------

!        BLACKBOX_INIT - INTIALIZE BLACKLISTING

!**   MODIFICATIONS
!     -------------
!     01/04/19  E. Holm    : ADD SOLAR ELEVATION AND RETRIEVAL QUALITY FOR REO3
!     01/08/14  A. Dethof  : ADD CLOUD COVER, CLOUD TOP PRESSURE AND PRODUCT TYPE FOR REO3
!     04/01/12  E.Andersson: Sonde type
!     06/07/07  R.Engelen  : Add surface transmittance
!     07/06/01  H. Hersbach: ADD SEA ICE
!     07/11/14  N. Bormann : Add alternative window channel departure (for AMSU-A)
!     07/11/30  S. SAARINEN: Added IFS-cycle by request of the WAVE-group
!     08/02/06  C. Facani  :  Add radars
!     22/03/11  C. Lupu    : Add csr_pclear for GEOS
!     23/11/11  C. Lupu    : Add percentage of cloudy and clear scenes for ASR from MET-9
!     25/06/12  P. Poli    : Add source@hdr and collection_identifier@conv
!     16/07/18  C. Burrows : Add REPRES_ERROR (i.e. CSR standard deviation)
!     14/11/18  M. Martet  : Add radar azimuth
!     ------------------------------------------------------------------

USE PARKIND1  ,ONLY : JPIM     ,JPRB
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK

USE YOMLUN   , ONLY : NULOUT   ,NULERR
USE YOMBLINIT, ONLY : NBHEAD   ,NBBODY   ,NBDATA   ,NFEEDBACK
USE YOMANCS  , ONLY : NMDI

IMPLICIT NONE

CHARACTER (LEN = 30), ALLOCATABLE :: CLDATA_NAME(:)

INTEGER(KIND=JPIM) :: IANDAT_BL, IANTIM_BL, ICOMPDAT, ICOMPTIM, IRET
REAL(KIND=JPRB) :: ZHOOK_HANDLE

#include "abor1.intfb.h"

#include "blackbox_init.h"

!*
!     ------------------------------------------------------------------

!        1.       INITIALIZE BLACKLIST PROCESSING
!                 -------------------------------

!*          1.1   NUMBER OF HEADER AND BODY VARIABLES IN THE INTERFACE

IF (LHOOK) CALL DR_HOOK('BLINIT',0,ZHOOK_HANDLE)
NBHEAD = 54
NBBODY = 17
NBDATA = NBHEAD + NBBODY

!*          1.2   ALLOCATE INPUT ARRAY FOR THE INTERFACE

ALLOCATE(CLDATA_NAME(1:NBDATA))
CLDATA_NAME(:) = ' '
WRITE(NULOUT,9990)'CLDATA_NAME ',SIZE(CLDATA_NAME),SHAPE(CLDATA_NAME)

!*          1.3   DEFINE THE INTERFACE VARIABLE NAMES ...

!*             1.3.0   CURRENT ANALYSIS DATE & TIME, IFS_CYCLE

CLDATA_NAME(25) = 'NANDAT'   ! analysis date
CLDATA_NAME(26) = 'NANTIM'   ! analysis time
CLDATA_NAME(38) = 'IFS_CYCLE'! current IFS-cycle

!*             1.3.1   RELATED TO OBSERVATION HEADER

CLDATA_NAME( 1) = 'OBSTYP'   ! observation type
CLDATA_NAME( 2) = 'STATID'   ! station id
CLDATA_NAME( 3) = 'CODTYP'   ! code type
CLDATA_NAME( 4) = 'INSTRM'   ! instrument type
CLDATA_NAME( 5) = 'DATE'     ! date
CLDATA_NAME( 6) = 'TIME'     ! time
CLDATA_NAME( 7) = 'LAT'      ! latitude
CLDATA_NAME( 8) = 'LON'      ! longitude
CLDATA_NAME( 9) = 'STALT'    ! station altitude
CLDATA_NAME(10) = 'LINE_SAT' ! line number atovs
CLDATA_NAME(11) = 'RETR_TYP' ! retrieval type
CLDATA_NAME(12) = 'QI_FC'    ! EUMETSAT Quality Indicators: with forecast dependence
CLDATA_NAME(13) = 'RFF'      ! CIMSS Quality Indicator: Recursive Filter Flag
CLDATA_NAME(14) = 'QI_NOFC'  ! EUMETSAT Quality Indicators: without forecast dependence
CLDATA_NAME(22) = 'SENSOR'   ! satellite sensor indicator
CLDATA_NAME(23) = 'FOV'      ! field of view number
CLDATA_NAME(24) = 'SATZA'    ! satellite zenith angle
CLDATA_NAME(27) = 'SOE'      ! solar elevation
CLDATA_NAME(28) = 'QR'       ! quality of retrieval
CLDATA_NAME(29) = 'CLC'      ! cloud cover
CLDATA_NAME(30) = 'CP'       ! cloud top pressure
CLDATA_NAME(31) = 'PT'       ! product type       
CLDATA_NAME(32) = 'SONDE_TYPE' ! sonde type
CLDATA_NAME(33) = 'SPECIFIC' ! amsua=clwp 
CLDATA_NAME(35) = 'GEN_CENTRE' ! Generating centre
CLDATA_NAME(36) = 'GEN_SUBCENTRE' ! Generating sub-centre
CLDATA_NAME(37) = 'DATASTREAM'  ! defined in routine datastream in odb
CLDATA_NAME(39) = 'RETRSOURCE' ! retrieval source
CLDATA_NAME(40) = 'SURFTYPE' ! surface type indicator
CLDATA_NAME(41) = 'SZA'     ! solar zenith angle
CLDATA_NAME(42) = 'REPORTYPE' ! MARS reportype
CLDATA_NAME(43) = 'SOLAR_HOUR' ! solar hour used for allsky data
CLDATA_NAME(44) = 'STATION_IDENTIFIER' ! Station identifier (integer) valid for some conventional only
CLDATA_NAME(45) = 'SATELLITE_IDENTIFIER' ! satellite_identifier (integer) valid for all satellite observations
CLDATA_NAME(46) = 'ASR_PCLEAR' ! AMOUNT SEGMENT CLOUD FREEE ASR GEOS
CLDATA_NAME(47) = 'ASR_PCLOUDY' ! CLOUD AMOUNT IN SEGMENT (LOW+MIDDLE+HIGH)
CLDATA_NAME(48) = 'ASR_PCLOUDY_LOW' ! CLOUD AMOUNT IN SEGMENT LOW-CLOUDS
CLDATA_NAME(49) = 'ASR_PCLOUDY_MIDDLE' ! CLOUD AMOUNT IN SEGMENT MIDLE-CLOUDS
CLDATA_NAME(50) = 'ASR_PCLOUDY_HIGH' ! CLOUD AMOUNT IN SEGMENT HIGH-CLOUDS
CLDATA_NAME(51) = 'SOURCE' ! source@hdr (character)
CLDATA_NAME(52) = 'COLLECTION_IDENTIFIER' ! collection_identifier@conv (integer) valid for conventional only
CLDATA_NAME(53) = 'AIRCRAFT_TYPE' ! aircraft_type@conv
CLDATA_NAME(54) = 'HEADING'  ! heading@conv

!*             1.3.2   RELATED TO MODEL FIELDS

CLDATA_NAME(15) = 'MODORO'  ! model orography
CLDATA_NAME(16) = 'LSMASK'  ! land-sea mask (integer)
CLDATA_NAME(17) = 'RLSMASK' ! land-sea mask (real)
CLDATA_NAME(18) = 'MODPS'   ! model surface pressure
CLDATA_NAME(19) = 'MODTS'   ! model surface temperature
CLDATA_NAME(20) = 'MODT2M'  ! model 2 metre temperature
CLDATA_NAME(21) = 'MODTOP'  ! model top level pressure
CLDATA_NAME(34) = 'SEA_ICE' ! sea-ice fraction

!*             1.3.3   RELATED TO OBSERVATION BODY ENTRY

CLDATA_NAME(NBHEAD+ 1) = 'VARIAB'         ! variable name
CLDATA_NAME(NBHEAD+ 2) = 'VERT_CO'        ! type of vertical coordinate
CLDATA_NAME(NBHEAD+ 3) = 'PRESS'          ! pressure
CLDATA_NAME(NBHEAD+ 4) = 'PRESS_RL'       ! ref. level pressure
CLDATA_NAME(NBHEAD+ 5) = 'PPCODE'         ! synop pressure code
CLDATA_NAME(NBHEAD+ 6) = 'OBS_VALUE'      ! observed value
CLDATA_NAME(NBHEAD+ 7) = 'FG_DEPARTURE'   ! first guess departure
CLDATA_NAME(NBHEAD+ 8) = 'OBS_ERROR'      ! observation error
CLDATA_NAME(NBHEAD+ 9) = 'FG_ERROR'       ! first guess error
CLDATA_NAME(NBHEAD+10) = 'WINCHAN_DEP'    ! window channel departure
CLDATA_NAME(NBHEAD+11) = 'OBS_T'          ! observed temperature
CLDATA_NAME(NBHEAD+12) = 'ELEVATION'      ! antenna elevation for radar
CLDATA_NAME(NBHEAD+13) = 'WINCHAN_DEP2'   ! alternative window channel dep
CLDATA_NAME(NBHEAD+14) = 'TAUSFC'         ! channel surface transmittance
CLDATA_NAME(NBHEAD+15) = 'CSR_PCLEAR'     ! percentage of clear pixel (used by GEOS)
CLDATA_NAME(NBHEAD+16) = 'REPRES_ERROR'   ! CSR standard deviation (GEOS)
CLDATA_NAME(NBHEAD+17) = 'AZIMUTH'        ! azimuth for radar

!*          1.4   INITIALIZE

CALL BLACKBOX_INIT(NULOUT,CLDATA_NAME,NBDATA,&
 & NMDI,                 &!Pass in the M.D.I.
 & IANDAT_BL, IANTIM_BL,  &!Analysis date and time for BL
 & ICOMPDAT, ICOMPTIM,    &!Compilation date and time for BL
 & NFEEDBACK,IRET)  

!*          1.4.1 PRINT DATE & TIME AND OTHER INFO

WRITE(NULOUT,9992) IANDAT_BL, IANTIM_BL
WRITE(NULOUT,9993) ICOMPDAT , ICOMPTIM
WRITE(NULOUT,9994) NBHEAD   , NBBODY

!*          1.5   CHECK RETURN CODE

IF(IRET /= 0) THEN
  WRITE(NULERR,'('' * BLINIT: INVALID USER SYMBOL(S) FOUND '')')
  CALL ABOR1('BLINIT: INVALID USER SYMBOL(S) FOUND')
ENDIF

!*          1.6   DEALLOCATE INPUT ARRAY

DEALLOCATE(CLDATA_NAME)
WRITE(NULOUT,9991) 'CLDATA_NAME'

9990 FORMAT(1X,'ARRAY ',A12,' ALLOCATED ',8I8)
9991 FORMAT(1X,'ARRAY ',A12,' DEALLOCATED ')
9992 FORMAT(1X,'BLINIT: The BLACKLIST meant for   : ',I8.8,' at ',I6.6)
9993 FORMAT(1X,'BLINIT: The BLACKLIST is compiled : ',I8.8,' at ',I6.6)
9994 FORMAT(1X,'BLINIT: The BLACKLIST has ',I3,' header and ',I3, ' body related entries')
!*
!     ------------------------------------------------------------------

!        2.       RETURN
!                 ------

IF (LHOOK) CALL DR_HOOK('BLINIT',1,ZHOOK_HANDLE)
END SUBROUTINE BLINIT
