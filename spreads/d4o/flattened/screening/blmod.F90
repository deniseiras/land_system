MODULE blmod
  use parkind
  use fd4o_mod, only : &
       & dio => fd4o_debug_io &
       &,fd4o_text &
       &,fd4o_null &
       &,fd4o_exit
  use status_bits
  
  implicit none
  
  save
  private

  INTEGER(KIND=JPIM) :: NULERR = 0
  INTEGER(KIND=JPIM) :: NULOUT = 6
  
  !     NAME      TYPE                  MEANING
  !     ----      ----                  -------
  
  !     NBHEAD       I    NO. INTERFACE VARIABLES RELATED TO OBSERVATION HEADER
  !     NBBODY       I    NO. INTERFACE VARIABLES RELATED TO OBSERVATION BODY
  !     NBDATA       I    TOTAL NO. INTERFACE VARIABLES 
  !     NFEEDBACK    I    LENGTH OF THE BLACKLIST FEEDBACK VECTOR

  INTEGER(KIND=JPIM) :: NBHEAD    = 0
  INTEGER(KIND=JPIM) :: NBBODY    = 0
  INTEGER(KIND=JPIM) :: NBDATA    = 0
  INTEGER(KIND=JPIM) :: NFEEDBACK = 0

  public :: blinit
  public :: bldyna
  public :: bllist
  public :: get_nandat, get_nantim

CONTAINS

  function get_nandat()
    integer(kind=jpim) :: get_nandat
    interface
       function analysis_date(defa) bind(C,name='analysis_date')
         USE, INTRINSIC :: ISO_C_BINDING, ONLY : C_SIZE_T
         INTEGER, VALUE :: defa
         INTEGER(C_SIZE_T) :: analysis_date
       end function analysis_date
    end interface
    get_nandat = analysis_date(19700101)
  end function get_nandat
  
  function get_nantim()
    integer(kind=jpim) :: get_nantim
    interface
       function analysis_time(defa) bind(C,name='analysis_time')
         USE, INTRINSIC :: ISO_C_BINDING, ONLY : C_SIZE_T
         INTEGER, VALUE :: defa
         INTEGER(C_SIZE_T) :: analysis_time
       end function analysis_time
    end interface
    get_nantim = analysis_time(000000)
  end function get_nantim
  
  SUBROUTINE BLINIT(IRET,LDVERBOSE)
    !        INITIALIZE BLACKLISTING INTERFACE
    !        BLINIT IS CALLED BY SCREENING

    !        THERE ARE A DEFINITE SET OF VARIABLES THAT ARE PASSED FOR THE
    !     BLACKLISTING THROUGH THE INTERFACE 'BLACKBOX'. THESE VARIABLES
    !     THAT ARE RELATED TO THE OBSERVATIONS AND TO MODEL FIELDS, ARE
    !     DEFINED HERE AND TOLD TO THE BLACKLIST INTERPRETER.

    IMPLICIT NONE
    INTEGER(KIND=JPIM), INTENT(OUT) :: IRET
    LOGICAL, INTENT(IN), OPTIONAL   :: LDVERBOSE
    CHARACTER(LEN=80), ALLOCATABLE :: CLDATA_NAME(:)
    INTEGER(KIND=JPIM) :: IANDAT_BL, IANTIM_BL, ICOMPDAT, ICOMPTIM
    REAL(KIND=JPRD) :: RMDI
    INTEGER(KIND=JPIM) :: J, IU
    LOGICAL :: LLVERBOSE

#include "blackbox_init.h"

    LLVERBOSE = .TRUE.
    IF (PRESENT(LDVERBOSE)) LLVERBOSE = LDVERBOSE
    
    IRET = 0
    RMDI = fd4o_null()
    NULERR = dio
    NULOUT = dio
    
    IU = NULOUT
    IF (.not.LLVERBOSE) IU = -1

    !*
    !     ------------------------------------------------------------------

    !        1.       INITIALIZE BLACKLIST PROCESSING
    !                 -------------------------------

    !*          1.1   NUMBER OF HEADER AND BODY VARIABLES IN THE INTERFACE

    NBHEAD = 16
    NBBODY = 12
    NBDATA = NBHEAD + NBBODY

    !*          1.2   ALLOCATE INPUT ARRAY FOR THE INTERFACE

    ALLOCATE(CLDATA_NAME(1:NBDATA))
    CLDATA_NAME(:) = ' '
    IF (LLVERBOSE) WRITE(NULOUT,9990)'CLDATA_NAME ',SIZE(CLDATA_NAME),SHAPE(CLDATA_NAME)

    !*          1.3   DEFINE THE INTERFACE VARIABLE NAMES ...

    !*             1.3.0   CURRENT ANALYSIS DATE & TIME

    CLDATA_NAME( 1) = 'NANDAT'   ! analysis date
    CLDATA_NAME( 2) = 'NANTIM'   ! analysis time
    CLDATA_NAME( 3) = 'PHASE'    ! phase: 1 (prescreening) or 2 (postscreening)

    !*             1.3.1   RELATED TO OBSERVATION HEADER

    CLDATA_NAME( 4) = 'hdr.statid' 
    CLDATA_NAME( 5) = 'hdr.obstype'
    CLDATA_NAME( 6) = 'hdr.codetype'
    CLDATA_NAME( 7) = 'hdr.reportype'
    CLDATA_NAME( 8) = 'hdr.bufrtype'
    CLDATA_NAME( 9) = 'hdr.subtype'
    CLDATA_NAME(10) = 'hdr.yyyymmdd'
    CLDATA_NAME(11) = 'hdr.hhmmss'
    CLDATA_NAME(12) = 'hdr.deglat'
    CLDATA_NAME(13) = 'hdr.deglon'
    CLDATA_NAME(14) = 'sat.sat_instr'
    CLDATA_NAME(15) = 'sat.sensor_id'
    CLDATA_NAME(16) = 'sat.sat_id'

    !*             1.3.2   RELATED TO MODEL FIELDS

    !*             1.3.3   RELATED TO OBSERVATION BODY ENTRY

    CLDATA_NAME(NBHEAD+ 1) = 'body.varno'
    CLDATA_NAME(NBHEAD+ 2) = 'body.kind'
    CLDATA_NAME(NBHEAD+ 3) = 'body.obsvalue'
    CLDATA_NAME(NBHEAD+ 4) = 'body.qc'
    CLDATA_NAME(NBHEAD+ 5) = 'body.dart_qc'
    CLDATA_NAME(NBHEAD+ 6) = 'body.which_vert'
    CLDATA_NAME(NBHEAD+ 7) = 'body.obs_error'
    CLDATA_NAME(NBHEAD+ 8) = 'body.levelht'
    CLDATA_NAME(NBHEAD+ 9) = 'body.channel'
    CLDATA_NAME(NBHEAD+10) = 'body.press'
    CLDATA_NAME(NBHEAD+11) = 'ens.member'
    CLDATA_NAME(NBHEAD+12) = 'ens.fg_depar'

    !*          1.4   INITIALIZE

    CALL BLACKBOX_INIT(IU,CLDATA_NAME,NBDATA,&
         & RMDI,                  & !Pass in the M.D.I.
         & IANDAT_BL, IANTIM_BL,  & !Analysis date and time for BL
         & ICOMPDAT, ICOMPTIM,    & !Compilation date and time for BL
         & NFEEDBACK,IRET)  
    
    !*          1.4.1 PRINT DATE & TIME AND OTHER INFO

    IF (LLVERBOSE) WRITE(NULOUT,9992) IANDAT_BL, IANTIM_BL
    IF (LLVERBOSE) WRITE(NULOUT,9993) ICOMPDAT , ICOMPTIM
    IF (LLVERBOSE) WRITE(NULOUT,9994) NBHEAD   , NBBODY
    IF (LLVERBOSE) WRITE(NULOUT,9995) NBDATA   , NFEEDBACK

    !*          1.4.2 PRINT AVAILABLE STATUS BITS (AS PER COMPILE TIME, **NOT** PER DB-FILE)

    IF (LLVERBOSE) WRITE(NULOUT,9996) MINBITNO,MAXBITNO
    DO J=MINBITNO,MAXBITNO
       IF (LLVERBOSE) WRITE(NULOUT,'(10X,"Bit#",i2.2," : ",A)') J,SB_DESCR(J)
    ENDDO
    IF (LLVERBOSE) WRITE(NULOUT,*)
    
    !*          1.5   CHECK RETURN CODE

    IF (IRET /= 0) THEN
       WRITE(NULERR,'(" * BLINIT: INVALID USER SYMBOL(S) FOUND ")')
       call    fd4o_exit('BLINIT: INVALID USER SYMBOL(S) FOUND',errcode=iret,do_exit=0) ! do NOT fail
    ENDIF

    !*          1.6   DEALLOCATE INPUT ARRAY

    DEALLOCATE(CLDATA_NAME)
    IF (LLVERBOSE) WRITE(NULOUT,9991) 'CLDATA_NAME'

9990 FORMAT(1X,'ARRAY ',A12,' ALLOCATED ',8I8)
9991 FORMAT(1X,'ARRAY ',A12,' DEALLOCATED ')
9992 FORMAT(1X,'BLINIT: The BLACKLIST meant for   : ',I8.8,' at ',I6.6)
9993 FORMAT(1X,'BLINIT: The BLACKLIST is compiled : ',I8.8,' at ',I6.6)
9994 FORMAT(1X,'BLINIT: The BLACKLIST has ',I0,' header and ',I0, ' body related entries')
9995 FORMAT(1X,'BLINIT: The BLACKLIST NBDATA=',I0,' and NFEEDBACK=',I0)
9996 FORMAT(1X,'BLINIT: Predefined status-bits between bits ',I0,' and ',I0)

    !*
    !     ------------------------------------------------------------------

    !        2.       RETURN
    !                 ------

  END SUBROUTINE BLINIT

  subroutine bldyna(sbdata,LDVERBOSE)
    !* PRINT DYNAMIC STATUS BITS (AS PER RUN-TIME, PER GIVEN DB-FILE)
    implicit none
    real(kind=jprd), intent(in) :: sbdata(:,:)
    LOGICAL, INTENT(IN), OPTIONAL   :: LDVERBOSE
    integer(kind=jpim) :: j, bitno
    integer(kind=jpim) :: ncols, nrows
    CHARACTER(LEN=:), allocatable :: descr
    LOGICAL :: LLVERBOSE
    LLVERBOSE = .TRUE.
    IF (PRESENT(LDVERBOSE)) LLVERBOSE = LDVERBOSE
    ncols = size(sbdata,dim=1)
    nrows = size(sbdata,dim=2)
    if (ncols >= 2 .and. nrows > 0) then
       IF (LLVERBOSE) WRITE(NULOUT,9996) MINBITNO,MAXBITNO
       DO j=1,nrows
          descr = fd4o_text(sbdata(1,j))
          bitno = sbdata(2,j)
          IF (LLVERBOSE) WRITE(NULOUT,'(10X,"Bit#",i2.2," : ",A23,A,I2,A)') bitno,descr," = ",bitno,"-bit"
       ENDDO
       deallocate(descr)
       IF (LLVERBOSE) WRITE(NULOUT,*)
    endif
9996 FORMAT(1X,'BLDYNA: Dynamic status-bits between bits ',I0,' and ',I0)
  end subroutine bldyna
  
  subroutine bllist(what_status,is_hdr,istat,&
       & sb_active, sb_blacklisted, &
       & zdata,ibits,debug_print)
    implicit none
    character(len=*), intent(in) :: what_status
    logical, intent(in) :: is_hdr
    integer(kind=jpib), intent(inout) :: istat
    integer(kind=jpim), intent(in) :: sb_active, sb_blacklisted
    real(kind=jprd), intent(in) :: zdata(:)    ! *must* be sized exactly as NBHEAD when is_hdr=.TRUE., and NBDATA when .FALSE.
    integer(kind=jpim), intent(in) :: ibits(:) ! *must* have the same size of zdata(:)
    logical, intent(in), optional :: debug_print
    integer(kind=jpib) :: IVAL
    integer(kind=jpim) :: J, IRET, ILEN, ICASE, IBIT, NBITS
    integer(kind=jpim) :: IFEEDBACK(0:NFEEDBACK)
    integer(kind=jpim), parameter :: KATEGORY(1:2) = [1,2] ! 1=hdr, 2=body related items
    integer(kind=jpim) :: KPRINT
    integer(kind=jpim), parameter :: KTEST_MDI = 0 ! for now (and probably always)
    integer(kind=jpim), parameter :: KFILL_FBVECTOR = 1 ! Always
    integer(kind=jpim) :: KCMBLI
    real(kind=jprd) :: ZCMCCC
    integer(kind=jpim) :: bits_set(maxbitno-minbitno+1)
    
#include "blackbox.h"

    ILEN = NBDATA
    if (is_hdr) ILEN = NBHEAD
    
    if (size(zdata) /= ILEN) then
       IRET = -size(zdata)
       WRITE(NULERR,'(" * BLLIST: ZDATA SIZE NOT CORRECTLY SET TO ",I0," SINCE is_hdr=",L1,", BUT INCORRECTLY SET TO ",I0)') ILEN,is_hdr,size(zdata)
       call    fd4o_exit('BLLIST: ZDATA SIZE NOT CORRECTLY SET TO',errcode=IRET,do_exit=1) ! *DO* fail
    endif

    if (size(ibits) /= ILEN) then
       IRET = -size(ibits)
       WRITE(NULERR,'(" * BLLIST: IBITS SIZE NOT CORRECTLY SET TO ",I0," SINCE is_hdr=",L1,", BUT INCORRECTLY SET TO ",I0)') ILEN,is_hdr,size(ibits)
       call    fd4o_exit('BLLIST: IBITS SIZE NOT CORRECTLY SET TO',errcode=IRET,do_exit=1) ! *DO* fail
    endif
    
    ICASE = KATEGORY(2)
    if (is_hdr) ICASE = KATEGORY(1)

    KPRINT = 0
    if (present(debug_print)) then
       if (debug_print) KPRINT = 1
    endif
    
    KCMBLI = 0 ! reason
    ZCMCCC = 0.0 ! seriousness

    CALL blackbox( &
         &     NULOUT, ICASE, KPRINT, &
         &     KTEST_MDI, KFILL_FBVECTOR, &
         &     KCMBLI, ZCMCCC, &
         &     IFEEDBACK, NFEEDBACK, &
         &     ZDATA, size(ZDATA), IRET)

    if (IRET /= 0 .and. KFILL_FBVECTOR == 1) then
       if (KPRINT == 1) then
          WRITE(NULOUT,'(1x,a,i20,2x)',advance='no') what_status//': ISTAT before       = ',ISTAT
          DO IBIT=MAXBITNO,MINBITNO,-1
             IVAL = GETBITS(ISTAT,IBIT)
             WRITE(NULOUT,'(I1)',advance='no') IVAL
          ENDDO
          WRITE(NULOUT,*)
       endif
       
       if (sb_active >= 0)      CALL CLRBITS(ISTAT,sb_active)      ! Set status active (usually the 0-bit) => 0
       if (sb_blacklisted >= 0) CALL SETBITS(ISTAT,sb_blacklisted) ! Set status blacklisted (usually the 1-bit) => 1

       NBITS = MIN(NFEEDBACK,ILEN)
       DO J=1,NBITS
          IBIT = IBITS(J)
          IF (IBIT >= MINBITNO .and. IBIT <= MAXBITNO) THEN
             IF (IFEEDBACK(J) == 1) THEN
                CALL SETBITS(ISTAT,IBIT) ! Set status bit# IBIT => 1
             !ELSE
             !   CALL CLRBITS(ISTAT,IBIT) ! Set status bit# IBIT => 0
             ENDIF
          ENDIF
       ENDDO
       
       if (KPRINT == 1) then
#if 0
          WRITE(NULOUT,'(1x,a,i20,2x)',advance='no') what_status//': # of FEEDBACK bits = ',NBITS
          DO IBIT=MAXBITNO,MINBITNO,-1
             IF (IBIT >= 0 .and. IBIT <= NBITS-1) THEN
                IVAL = GETBITS(ISTAT,IBIT)
                WRITE(NULOUT,'(I1)',advance='no') IVAL
             ELSE
                WRITE(NULOUT,'(A1)',advance='no') ' '
             ENDIF
          ENDDO
          WRITE(NULOUT,*)
#endif     
          NBITS = 0
          WRITE(NULOUT,'(1x,a,i20,2x)',advance='no') what_status//': ISTAT after        = ',ISTAT
          DO IBIT=MAXBITNO,MINBITNO,-1
             IVAL = GETBITS(ISTAT,IBIT)
             WRITE(NULOUT,'(I1)',advance='no') IVAL
             IF (IVAL == 1) THEN
                NBITS = NBITS + 1
                bits_set(NBITS) = IBIT
             ENDIF
          ENDDO
          WRITE(NULOUT,*)

          WRITE(NULOUT,*) 'Number of bits set = ',NBITS
          if (NBITS > 0) then
             DO J=NBITS,1,-1
                IBIT = bits_set(J)
                WRITE(NULOUT,'(20x,a)') sb_descr(IBIT)
             ENDDO
          endif
       endif
    endif
    
  end subroutine bllist
  
END MODULE blmod
