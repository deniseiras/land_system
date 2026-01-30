Subroutine FY3_Corrections(       &
&           Instr_Number,         & ! IN: FY3A=1, FY3B=2
&           IChannel_Number,      & ! IN 
&           ICorrection_Version,  & ! IN:0 = no corrections
&           ZTB,                  & ! IN: observed TB.
&           ZDelta_TB)              ! OUT: correction to Tb

! ======================================================================
!  Subroutine  FY3_Corrections
!  ---------------------------------
!
!  Purpose
!  -------
!  This routine calculates the non-linearity correction for 
!  the FY-3A and B sensors, based on coefficients stored in 
!  this subroutine, the observed brightness temperature,
!  instrument pararameters (sensor and channel numbers)
!  as well as a correction 'version number' 
!  which is stored (by the calling routine) in the ODB
!  This routine is only called for FY3 MWTS sensors.
!
!  The correction takes the form:
!
!  ZDelta_TB = a0 + a1*TB + a2*TB^2
!
!  In the calling routine, the new brightness temperature is:
!
!  TB_new = TB_old - ZDelta_TB
!  
!  Interface
!  ---------
!  Instr_Number         !IN : FY3A=1, FY3B=2
!  IChannel_Number      !IN : Integer in the range [1,4] for MWTS
!  ICorrection_Version  !IN : Currently 0 (no corrections) or 1,
!                             can be extended if new values required
!  ZTB                  !IN : Observed Brightness temperature.
!  ZDelta_TB            !OUT: correction to brightness temperature 
!                             note: TB_new = TB_old - ZDelta_TB
!                             in calling routine
!   
!  Structure
!  ---------
!  0. Initialise output (ZDelta_TB) to zero.
!  1. Initialise the coefficient array.
!  2. [If input sensible, then] Compute the correction.
!  
!  Date              Author                  Comments
!  ====              ======                  ========
!  19/10/2010        W. Bell                 First version
!  24/11/2011        Q. Lu                   Update for FY3B
!  15/01/2013        S. English              Further update for FY3B
!
!=======================================================================

! === USE statements ========


USE PARKIND1  ,ONLY : JPIM     ,JPRD
USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK

! === End USE statements ====

Implicit None

!=========== declarations ================================================= 

! argument list: inputs

INTEGER(KIND=JPIM),INTENT(IN)    :: Instr_Number
INTEGER(KIND=JPIM),INTENT(IN)    :: IChannel_Number
INTEGER(KIND=JPIM),INTENT(IN)    :: ICorrection_Version

REAL(KIND=JPRD)   ,INTENT(IN)   ::  ZTB

! argument list:  outputs

REAL(KIND=JPRD)   ,INTENT(OUT)   ::  ZDelta_TB


! local variables

INTEGER(KIND=JPIM),parameter     :: NVIND = 2147483647
INTEGER(KIND=JPIM),parameter     :: num_fy3s=2
INTEGER(KIND=JPIM),parameter     :: num_fy3_channels=4
INTEGER(KIND=JPIM),parameter     :: num_versions=1

REAL(KIND=JPRD) :: ZHOOK_HANDLE
REAL(KIND=JPRD), Dimension(1:num_fy3s,0:num_versions,3,num_fy3_channels) &
&                                :: non_lin_coeffs



!======== end declarations ===============================================

IF (LHOOK) CALL DR_HOOK('FY3_CORRECTION',0,ZHOOK_HANDLE)

! ==============================================
! Section 0: Initialise output argument to zero
!===============================================

ZDelta_TB=0.0

! ==============================================
! Section 1: Initialise Coefficient array.
! If new versions are added, both FY3A and FY3B
! coefficients need to be copied and updated
! as there is only one 'Version number' for the 
! corrections.
! Version 0: no corrections for FY-3A or FY-3B
! Version 1: optimal corrs for 3A, none for 3B
! Version #: update as appropriate ...
! DO NOT OVERWRITE EARLIER VERSIONS !
!===============================================


!                      a0                  a1                   a2

! FY-3A, Version 0 corrections

non_lin_coeffs(1,0,1:3,1:4) =        &
& reshape( source=(/ 0.00000,             0.00000,            0.00000, &
&                    0.00000,             0.00000,            0.00000, &
&                    0.00000,             0.00000,            0.00000, &
&                    0.00000,             0.00000,            0.00000 /), &
&                    shape=(/3, 4/)                                     )
                                             


! FY-3A, Version 1 corrections

non_lin_coeffs(1,1,1:3,1:4) =           &
& reshape( source=(/ 0.00000,             0.00000,            0.00000,            &
&                    0.079546796,         0.015843045,       -0.000060438557,  & 
&                    0.070824104,         0.025371222,       -0.000107616679,  &
&                    0.000859831,         0.027636840,       -0.000103839638 /), &
&                    shape=(/3, 4/)                                     )
                                             
                                             
! FY-3B, Version 0 corrections

non_lin_coeffs(2,0,1:3,1:4) =     & 
&   reshape( source=(/ 0.00000,             0.00000,            0.00000, &
&                      0.00000,             0.00000,            0.00000, &
&                      0.00000,             0.00000,            0.00000, &
&                      0.00000,             0.00000,            0.00000 /), &
&                      shape=(/3, 4/)                                     ) 
                                             
                                             
! FY-3B, Version 1 corrections

non_lin_coeffs(2,1,1:3,1:4) =        &
& reshape( source=(/ 0.00000,             0.00000,            0.00000, &
&                    -0.003809237,        0.001423785,       -0.000004799, &
&                    0.1338578223,       -0.003429888,       -0.000002933, &
&                   -0.0272090345,        0.010169968,       -0.000034277  /), &
&                      shape=(/3, 4/)                                     )

                                                      

! ==============================================
! Section 2: IF input parameters sensible  THEN
!  compute non-linearity correction
!  ELSE Do nothing and leave correction
!  set at zero.
!==============================================

If (        (Instr_Number .gt. 0)         .AND.   (Instr_Number .lt. 3)     .AND.     &
      &     (IChannel_Number .gt. 0)      .AND.   (IChannel_Number .lt. 5)  .AND.  &
      &     (ICorrection_Version .gt. -1) .AND.   (ICorrection_Version .lt. 2) .AND. &
      &     ZTB /= -NVIND ) Then


      ZDelta_TB =     &
      & non_lin_coeffs(Instr_Number,ICorrection_Version,1,IChannel_Number)     +  &
      & non_lin_coeffs(Instr_Number,ICorrection_Version,2,IChannel_Number)*ZTB +  &
      & non_lin_coeffs(Instr_Number,ICorrection_Version,3,IChannel_Number)*ZTB**2

End If

IF (LHOOK) CALL DR_HOOK('FY3_CORRECTION',1,ZHOOK_HANDLE)

End








