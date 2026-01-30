MODULE fd4o_mod

  implicit none
  
  private

  LOGICAL, save :: fd4o_is_initialized = .FALSE.

!  LOGICAL, parameter :: f4o_rowmajor_default = .TRUE. ! T: obs%d as nrows x ncols, F: ncols x nrows
  LOGICAL, parameter :: f4o_rowmajor_default = .FALSE. ! T: obs%d as nrows x ncols, F: ncols x nrows

  INTEGER(4), parameter :: fd4o_default_destroy = 0
!  INTEGER(4), parameter :: fd4o_default_destroy = 1

  INTEGER(4), parameter :: fd4o_do_exit_upon_invalid_colidx = 1
!  INTEGER(4), parameter :: fd4o_do_exit_upon_invalid_colidx = 0
  
  ! Valid values in the types(:)
  INTEGER(4), save :: TYPE_INT  = 1 ! TBD: SQLITE_INTEGER
  INTEGER(4), save :: TYPE_REAL = 2 ! TBD: SQLITE_FLOAT
  INTEGER(4), save :: TYPE_TEXT = 3 ! TBD: SQLITE_TEXT
  !INTEGER(4), save :: TYPE_BLOB = 4 ! TBD: SQLITE_BLOB (to be implemented ?)
  !INTEGER(4), save :: TYPE_NULL = 5 ! TBD: SQLITE_NULL : we should NOT see this at all

  ! Selected error codes : eventually must match with /usr/include/sqlite3.h
  INTEGER(4), save :: ERR_SQLITE_OK = 0    ! TBD: SQLITE_OK
  INTEGER(4), save :: ERR_SQLITE_ERROR = 1 ! TBD: SQLITE_ERROR
  INTEGER(4), save :: ERR_SQLITE_ABORT = 4 ! TBD: SQLITE_ABORT
  INTEGER(4), save :: ERR_SQLITE_NOMEM = 7 ! TBD: SQLITE_NOMEM
  
!  INTEGER(4), save :: fd4o_debug_io = 0
  INTEGER(4), save :: fd4o_debug_io = 6

  TYPE fd4o_varchar_t
     CHARACTER(LEN=:), allocatable :: s
   !contains
   !  final :: fini_fd4o_varchar_t
   !  procedure, public :: dealloc => dealloc_fd4o_varchar_t
  END TYPE fd4o_varchar_t

  TYPE fd4o_obsdata_t
     REAL(8), allocatable :: d(:,:) ! rowmajor=T: nrows x ncols rowmajor=F: ncols x nrows
     INTEGER(4), allocatable :: types(:) ! ncols
     TYPE(fd4o_varchar_t), allocatable :: colname(:) ! ncols
     CHARACTER(LEN=:), allocatable :: query ! last query
     INTEGER(4) :: qh = -1
     INTEGER(4) :: ncols = 0
     INTEGER(4) :: nrows = 0
     INTEGER(4) :: nparcnt = 0
     LOGICAL :: rowmajor = f4o_rowmajor_default
   !contains
   !  final :: fini_fd4o_obsdata_t
   !  procedure, public :: dealloc => dealloc_fd4o_obsdata_t
  END TYPE fd4o_obsdata_t
    
  INTERFACE fd4o_exit
     subroutine fd4o_exit(msg,errcode,do_exit)
       implicit none
       character(len=*),intent(in) :: msg
       INTEGER(4), intent(in) :: errcode, do_exit
     end subroutine fd4o_exit
  END INTERFACE fd4o_exit

  INTERFACE fd4o_print
     MODULE PROCEDURE &
          &  fd4o_print_thru_object &
          & ,fd4o_print_thru_query
  END INTERFACE fd4o_print

  INTERFACE fd4o_new
     MODULE PROCEDURE &
          &  fd4o_new_thru_array &
          & ,fd4o_new_thru_opt_object
  END INTERFACE fd4o_new

  INTERFACE fd4o_destroy
     MODULE PROCEDURE &
          &  fd4o_destroy_thru_qh &
          & ,fd4o_destroy_thru_object
  END INTERFACE fd4o_destroy
  
  INTERFACE fd4o_getdb
     MODULE PROCEDURE &
          &  fd4o_getdb_thru_opt_query &
          & ,fd4o_getdb_thru_object
  END INTERFACE fd4o_getdb

  INTERFACE fd4o_putdb
     MODULE PROCEDURE &
          &  fd4o_putdb_thru_object_plus_opt_query &
          & ,fd4o_putdb_thru_array_plus_opt_query
  END INTERFACE fd4o_putdb

  INTERFACE fd4o_text
     MODULE PROCEDURE &
          &  fd4o_get_text &
          & ,fd4o_set_text
  END INTERFACE fd4o_text

  INTERFACE fd4o_debug
     MODULE PROCEDURE &
          &  fd4o_get_debug &
          & ,fd4o_set_debug
  END INTERFACE fd4o_debug

  INTERFACE fd4o_null
     MODULE PROCEDURE &
          &  fd4o_get_null &
          & ,fd4o_set_null
  END INTERFACE fd4o_null

  INTERFACE fd4o_is_null
     MODULE PROCEDURE &
          &  fd4o_is_null_double &
          & ,fd4o_is_null_int &
          & ,fd4o_is_null_int8
  END INTERFACE fd4o_is_null

  INTERFACE fd4o_bind
     MODULE PROCEDURE &
          &  fd4o_bind_double &
          & ,fd4o_bind_int8 &
          & ,fd4o_bind_text &
          & ,fd4o_bind_null
  END INTERFACE fd4o_bind

  public :: fd4o_debug_io

  public :: fd4o_varchar_t
  public :: fd4o_obsdata_t
  public :: fd4o_new
  public :: fd4o_delete
  public :: fd4o_opendb
  public :: fd4o_closedb
  public :: fd4o_exit
  public :: fd4o_exec
  public :: fd4o_execfile
  public :: fd4o_reset
  public :: fd4o_prepare
  public :: fd4o_destroy
  public :: fd4o_getdb
  public :: fd4o_putdb
  public :: fd4o_info
  public :: fd4o_print
  public :: fd4o_dbname
  public :: fd4o_query
  public :: fd4o_dbh
  public :: fd4o_coltype
  public :: fd4o_typename
  public :: fd4o_errmsg
  public :: fd4o_int8
  public :: fd4o_text
  public :: fd4o_textlen
  public :: fd4o_debug
  public :: fd4o_null
  public :: fd4o_is_null
  public :: fd4o_dbinfo
  public :: fd4o_cascade
  public :: fd4o_long_column_names
  public :: fd4o_ncols
  public :: fd4o_nparcnt
  public :: fd4o_bind
  public :: fd4o_colidx
  public :: fd4o_mpirank
  public :: fd4o_mpisize
  public :: fd4o_maxdb
  public :: fd4o_traceback
  public :: fd4o_coreid
  public :: fd4o_little_endian
  public :: fd4o_big_endian
  public :: fd4o_gethostid
  public :: fd4o_finalize
  public :: fd4o_wtime

  public :: fd4o_lowercase
  public :: fd4o_uppercase
  
  INTERFACE

     FUNCTION c_d4o_is_little_endian() result(rc)
       INTEGER(4) :: rc
     END FUNCTION c_d4o_is_little_endian

     FUNCTION c_d4o_is_big_endian() result(rc)
       INTEGER(4) :: rc
     END FUNCTION c_d4o_is_big_endian

     FUNCTION c_d4o_bind_double(qh,parnum,value) RESULT(rc)
       INTEGER(4), intent(in) :: qh
       INTEGER(4), intent(in) :: parnum
       REAL(8), intent(in) :: value
       INTEGER(4) :: rc
     END FUNCTION c_d4o_bind_double

     FUNCTION c_d4o_bind_int8(qh,parnum,value) RESULT(rc)
       INTEGER(4), intent(in) :: qh
       INTEGER(4), intent(in) :: parnum
       INTEGER(8), intent(in) :: value
       INTEGER(4) :: rc
     END FUNCTION c_d4o_bind_int8

     FUNCTION c_d4o_bind_text(qh,parnum,value) RESULT(rc)
       INTEGER(4), intent(in) :: qh
       INTEGER(4), intent(in) :: parnum
       CHARACTER(LEN=*), intent(in) :: value
       INTEGER(4) :: rc
     END FUNCTION c_d4o_bind_text
     
     FUNCTION c_d4o_bind_null(qh,parnum) RESULT(rc)
       INTEGER(4), intent(in) :: qh
       INTEGER(4), intent(in) :: parnum
       INTEGER(4) :: rc
     END FUNCTION c_d4o_bind_null

     FUNCTION c_d4o_colidx(qh,key) RESULT(cidx)
       INTEGER(4), intent(in) :: qh
       CHARACTER(LEN=*), intent(in) :: key
       INTEGER(4) :: cidx
     END FUNCTION c_d4o_colidx

     FUNCTION c_d4o_get_ncols(qh) RESULT(n)
       INTEGER(4), intent(in) :: qh
       INTEGER(4) :: n
     END FUNCTION c_d4o_get_ncols
     
     FUNCTION c_d4o_get_nparcnt(qh) RESULT(n)
       INTEGER(4), intent(in) :: qh
       INTEGER(4) :: n
     END FUNCTION c_d4o_get_nparcnt
     
     FUNCTION c_d4o_get_debug() RESULT(debug_mode)
       INTEGER(4) :: debug_mode
     END FUNCTION c_d4o_get_debug

     FUNCTION c_d4o_set_debug(newvalue) RESULT(oldvalue)
       INTEGER(4), intent(in) :: newvalue
       INTEGER(4) :: oldvalue
     END FUNCTION c_d4o_set_debug

     FUNCTION c_d4o_get_null() RESULT(mdi)
       REAL(8) :: mdi
     END FUNCTION c_d4o_get_null

     FUNCTION c_d4o_set_null(newvalue) RESULT(oldvalue)
       REAL(8), intent(in) :: newvalue
       REAL(8) :: oldvalue
     END FUNCTION c_d4o_set_null

     FUNCTION c_d4o_is_null(value) RESULT(x)
       REAL(8), intent(in) :: value
       INTEGER(4) :: x
     END FUNCTION c_d4o_is_null
     
     SUBROUTINE c_d4o_dealloc(ptr)
       INTEGER(8), intent(inout) :: ptr
     END SUBROUTINE c_d4o_dealloc
     
     FUNCTION c_d4o_get_dbh(qh) RESULT(dbh)
       INTEGER(4), intent(in) :: qh
       INTEGER(4) :: dbh
     END FUNCTION c_d4o_get_dbh
     
     FUNCTION c_d4o_get_dbname(dbh,len) RESULT(ptr)
       INTEGER(4), intent(in) :: dbh
       INTEGER(4), intent(out) :: len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_get_dbname

     FUNCTION c_d4o_get_query(qh,iexpanded,len) RESULT(ptr)
       INTEGER(4), intent(in) :: qh
       INTEGER(4), intent(in) :: iexpanded
       INTEGER(4), intent(out) :: len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_get_query
     
     FUNCTION c_d4o_get_typename(coltype,len) RESULT(ptr)
       INTEGER(4), intent(in) :: coltype
       INTEGER(4), intent(out) :: len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_get_typename
     
     FUNCTION c_d4o_get_coltype(typename) RESULT(coltype)
       CHARACTER(LEN=*), intent(in) :: typename
       INTEGER(4) :: coltype
     END FUNCTION c_d4o_get_coltype
     
     FUNCTION c_d4o_get_errmsg(rc,len) RESULT(ptr)
       INTEGER(4), intent(in) :: rc
       INTEGER(4), intent(out) :: len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_get_errmsg

     FUNCTION c_d4o_get_text(d,len) RESULT(ptr)
       REAL(8), intent(in) :: d
       INTEGER(4), intent(out) :: len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_get_text
     
     FUNCTION c_d4o_get_textlen(d) RESULT(clen)
       REAL(8), intent(in) :: d
       INTEGER(4) :: clen
     END FUNCTION c_d4o_get_textlen
     
     FUNCTION c_d4o_set_text(s) RESULT(d)
       CHARACTER(LEN=*), intent(in) :: s
       REAL(8) :: d
     END FUNCTION c_d4o_set_text

     FUNCTION c_d4o_cascade(dbh, onoff) RESULT(retcode)
       INTEGER(4), intent(in) :: dbh
       INTEGER(4), intent(in) :: onoff
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_cascade

     FUNCTION c_d4o_long_column_names(dbh, onoff) RESULT(retcode)
       INTEGER(4), intent(in) :: dbh
       INTEGER(4), intent(in) :: onoff
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_long_column_names

     FUNCTION c_d4o_opendb(dbname, mode) RESULT(dbh)
       CHARACTER(LEN=*), intent(in) :: dbname, mode
       INTEGER(4) :: dbh
     END FUNCTION c_d4o_opendb

     FUNCTION c_d4o_closedb(dbh) RESULT(retcode)
       INTEGER(4), intent(inout) :: dbh
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_closedb

     FUNCTION c_d4o_exec(dbh, query) RESULT(retcode)
       INTEGER(4), intent(in) :: dbh
       CHARACTER(LEN=*), intent(in) :: query
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_exec

     FUNCTION c_d4o_execfile(dbh, filename) RESULT(retcode)
       INTEGER(4), intent(in) :: dbh
       CHARACTER(LEN=*), intent(in) :: filename
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_execfile

     FUNCTION c_d4o_prepare(dbh, query, ncols, nparcnt) RESULT(qh)
       INTEGER(4), intent(in) :: dbh
       CHARACTER(LEN=*), intent(in) :: query
       INTEGER(4), intent(out) :: ncols, nparcnt
       INTEGER(4) :: qh
     END FUNCTION c_d4o_prepare

     FUNCTION c_d4o_destroy(qh,enforce) RESULT(retcode)
       INTEGER(4), intent(inout) :: qh
       INTEGER(4), intent(in) :: enforce
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_destroy

     FUNCTION c_d4o_getdb(qh, ncols, nrows, colnames_ptr, clen, types, sql_ptr, sql_len) RESULT(ptr)
       INTEGER(4), intent(inout) :: qh
       INTEGER(4), intent(in) :: ncols
       INTEGER(4), intent(out) :: nrows
       INTEGER(8), intent(inout) :: colnames_ptr
       INTEGER(4), intent(out) :: clen(ncols)
       INTEGER(4), intent(out) :: types(ncols)
       INTEGER(8), intent(inout) :: sql_ptr
       INTEGER(4), intent(out) :: sql_len
       INTEGER(8) :: ptr
     END FUNCTION c_d4o_getdb

     FUNCTION c_d4o_putdb(qh, array, ncols, nrows, types, nparcnt, parnum) RESULT(retcode)
       INTEGER(4), intent(inout) :: qh
       INTEGER(4), intent(in) :: ncols, nrows, nparcnt
       REAL(8), intent(in) :: array(ncols, nrows)
       INTEGER(4), intent(in) :: types(ncols), parnum(nparcnt)
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_putdb

     SUBROUTINE c_d4o_tsc(csv,n,w,types,fld,cout,len_cout)
       INTEGER(4), intent(in) :: csv,n
       REAL(8), intent(in) :: fld(n)
       INTEGER(4), intent(in) :: w(n),types(n)
       CHARACTER(LEN=*), intent(out) :: cout
       INTEGER(4), intent(out) :: len_cout
     END SUBROUTINE c_d4o_tsc

     SUBROUTINE c_d4o_ptr2array(ptr, ncols, nrows, elemsize, array)
       INTEGER(8), intent(in) :: ptr
       INTEGER(4), intent(in) :: ncols, nrows, elemsize
       REAL(8), intent(in) :: array(ncols, nrows)
     END SUBROUTINE c_d4o_ptr2array

     SUBROUTINE c_d4o_ptr2str(ptr, s)
       INTEGER(8), intent(in) :: ptr
       CHARACTER(LEN=*), intent(out) :: s
     END SUBROUTINE c_d4o_ptr2str
     
     FUNCTION c_d4o_mpirank(fix) RESULT(retcode)
       INTEGER(4), intent(in) :: fix
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_mpirank

     FUNCTION c_d4o_mpisize(fix) RESULT(retcode)
       INTEGER(4), intent(in) :: fix
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_mpisize
     
     FUNCTION c_d4o_maxdb() RESULT(retcode)
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_maxdb
     
     FUNCTION c_d4o_coreid() RESULT(retcode)
       INTEGER(4) :: retcode
     END FUNCTION c_d4o_coreid
     
     FUNCTION fd4o_gethostid() bind(c,name='gethostid')
       INTEGER(4) :: fd4o_gethostid
     END FUNCTION fd4o_gethostid

     SUBROUTINE fd4o_finalize() bind(c,name='d4o_finalize')
     END SUBROUTINE fd4o_finalize

     FUNCTION fd4o_wtime() bind(c,name='d4o_wtime')
       REAL(8) :: fd4o_wtime
     END FUNCTION fd4o_wtime
  END INTERFACE
  
contains

#if 0
  subroutine fini_fd4o_varchar_t (x)
    implicit none
    type(fd4o_varchar_t) :: x
    call x%dealloc()
  end subroutine fini_fd4o_varchar_t
  
  subroutine dealloc_fd4o_varchar_t(x)
    implicit none
    class(fd4o_varchar_t) :: x
    if (allocated(x%s)) deallocate(x%s)
  end subroutine dealloc_fd4o_varchar_t

  subroutine fini_fd4o_obsdata_t (x)
    implicit none
    type(fd4o_obsdata_t) :: x
    call x%dealloc()
  end subroutine fini_fd4o_obsdata_t
  
  subroutine dealloc_fd4o_obsdata_t(x)
    implicit none
    class(fd4o_obsdata_t) :: x
    integer :: j,n
    if (allocated(x%d)) deallocate(x%d)
    if (allocated(x%types)) deallocate(x%types)
    if (allocated(x%query)) deallocate(x%query)
    if (allocated(x%colname)) then
       n = size(x%colname)
       !do j=1,n
       !   call x%colname(j)%dealloc()
       !enddo
       deallocate(x%colname)
    endif
  end subroutine dealloc_fd4o_obsdata_t
#endif

  FUNCTION fd4o_lowercase(CDS) result(cout)
    CHARACTER(LEN=*), INTENT(IN) :: CDS
    INTEGER(4), PARAMETER :: ICH_A = ICHAR('a')
    INTEGER(4), PARAMETER :: ICHA  = ICHAR('A')
    INTEGER(4), PARAMETER :: ICHZ  = ICHAR('Z')
    INTEGER(4) :: I, ICH, NEW_ICH, ilen
    CHARACTER(LEN=1) CH
    character(len=:), allocatable :: cout
    ilen = LEN_TRIM(CDS)
    allocate(character(ilen)::cout)
    DO I=1,ilen
       CH = CDS(I:I)
       ICH = ICHAR(CH)
       IF ( ICH >= ICHA .AND. ICH <= ICHZ ) THEN
          NEW_ICH = ICH + (ICH_A - ICHA)
          CH = CHAR(NEW_ICH)
       ENDIF
       cout(I:I) = CH
    ENDDO
  END FUNCTION fd4o_lowercase

  FUNCTION fd4o_uppercase(CDS) result(cout)
    CHARACTER(LEN=*), INTENT(IN) :: CDS
    INTEGER(4), PARAMETER :: ICH_A = ICHAR('A')
    INTEGER(4), PARAMETER :: ICHA  = ICHAR('a')
    INTEGER(4), PARAMETER :: ICHZ  = ICHAR('z')
    INTEGER(4) :: I, ICH, NEW_ICH, ilen
    CHARACTER(LEN=1) CH
    character(len=:), allocatable :: cout
    ilen = LEN_TRIM(CDS)
    allocate(character(ilen)::cout)
    DO I=1,ilen
       CH = CDS(I:I)
       ICH = ICHAR(CH)
       IF ( ICH >= ICHA .AND. ICH <= ICHZ ) THEN
          NEW_ICH = ICH + (ICH_A - ICHA)
          CH = CHAR(NEW_ICH)
       ENDIF
       cout(I:I) = CH
    ENDDO
  END FUNCTION fd4o_uppercase
  
  FUNCTION fd4o_little_endian() result(truth)
    LOGICAL :: truth
    truth = (c_d4o_is_little_endian() == 1)
  END FUNCTION fd4o_little_endian
     
  FUNCTION fd4o_big_endian() result(truth)
    LOGICAL :: truth
    truth = (c_d4o_is_big_endian() == 1)
  END FUNCTION fd4o_big_endian
     
  FUNCTION fd4o_bind_double(qh,parnum,value) RESULT(rc)
    INTEGER(4), intent(in) :: qh
    INTEGER(4), intent(in) :: parnum
    REAL(8), intent(in) :: value
    INTEGER(4) :: rc
    rc = c_d4o_bind_double(qh,parnum,value)
  END FUNCTION fd4o_bind_double

  FUNCTION fd4o_bind_int8(qh,parnum,value) RESULT(rc)
    INTEGER(4), intent(in) :: qh
    INTEGER(4), intent(in) :: parnum
    INTEGER(8), intent(in) :: value
    INTEGER(4) :: rc
    rc = c_d4o_bind_int8(qh,parnum,value)
  END FUNCTION fd4o_bind_int8

  FUNCTION fd4o_bind_text(qh,parnum,value) RESULT(rc)
    INTEGER(4), intent(in) :: qh
    INTEGER(4), intent(in) :: parnum
    CHARACTER(LEN=*), intent(in) :: value
    INTEGER(4) :: rc
    rc = c_d4o_bind_text(qh,parnum,value)
  END FUNCTION fd4o_bind_text

  FUNCTION fd4o_bind_null(qh,parnum) RESULT(rc)
    INTEGER(4), intent(in) :: qh
    INTEGER(4), intent(in) :: parnum
    INTEGER(4) :: rc
    rc = c_d4o_bind_null(qh,parnum)
  END FUNCTION fd4o_bind_null

  FUNCTION fd4o_colidx(qh,key,fail) RESULT(fidx)
    INTEGER(4), intent(in) :: qh
    CHARACTER(LEN=*), intent(in) :: key
    LOGICAL, intent(in), optional :: fail
    LOGICAL :: LLfail
    INTEGER(4) :: fidx
    INTEGER(4) :: rc
    CHARACTER(LEN=:), allocatable :: dbname
    rc = c_d4o_colidx(qh,key)
    if (fd4o_is_null(rc)) then
       LLfail = .TRUE.
       if (present(fail)) LLfail = fail
       if (LLfail) then
          dbname = fd4o_dbname(qh)
          CALL fd4o_exit('fd4o_colidx:'//&
               & ' could not resolve column index for "'//trim(key)//'"'//&
               & ' dbname="'//trim(dbname)//"'",rc,fd4o_do_exit_upon_invalid_colidx)
       endif
       fidx = rc ! NULL
    else
       fidx = rc + 1 ! one-based Fortran
    endif
  END FUNCTION fd4o_colidx
     
  FUNCTION init_intvec(ni,intvec_in,ivalue) RESULT(intvec_out)
    INTEGER(4), intent(in) :: ni
    INTEGER(4), intent(in), optional :: intvec_in(:)
    INTEGER(4), intent(in), optional :: ivalue
    INTEGER(4), allocatable :: intvec_out(:)
    INTEGER(4) :: j,n
    if (present(ivalue)) then
       intvec_out = [(ivalue,j=1,ni)] ! automatic allocate
    else
       intvec_out = [(j,j=1,ni)] ! automatic allocate
    endif
    if (present(intvec_in)) then
       n = min(size(intvec_in),ni)
       do j=1,n
          intvec_out(j) = intvec_in(j)
       enddo
    endif
  END FUNCTION init_intvec

  FUNCTION fd4o_cascade(dbh, onoff, err) RESULT(Loldvalue)
    INTEGER(4), intent(in) :: dbh
    LOGICAL, intent(in), optional :: onoff ! if not present returns old value
    INTEGER(4), intent(out), optional :: err ! =0 if Loldvalue=.FALSE., =1 if .TRUE., < 0 => error
    INTEGER(4) :: oldvalue, newvalue, rc
    LOGICAL :: Lonoff, Loldvalue
    TYPE(fd4o_obsdata_t), allocatable :: data
    ! Do not rely on these two -- just initial values
    Loldvalue = .FALSE.
    oldvalue = 0
    ! Fetch previous value : do not rely on these two
    data = fd4o_getdb(dbh,"PRAGMA foreign_keys",err=rc)
    if (rc == 1) then
       oldvalue = data%d(1,1)
       Loldvalue = (oldvalue == 1)
    else ! something went wrong -- return & fill err-parameter if available
       if (present(err)) err = -ERR_SQLITE_ERROR
       return
    endif
    rc = 0
    if (present(onoff)) then
       Lonoff = onoff
       newvalue = 0
       if (Lonoff) newvalue = 1
       if (newvalue /= oldvalue) rc = c_d4o_cascade(dbh, newvalue)
    endif
    if (present(err)) then
       if (rc == 0) then
          err = oldvalue
       else if (rc < 0) then
          err = rc
       else
          err = -ERR_SQLITE_ERROR
       endif
    endif
  END FUNCTION fd4o_cascade

  FUNCTION fd4o_long_column_names(dbh, onoff) RESULT(retcode)
    INTEGER(4), intent(in) :: dbh
    LOGICAL, intent(in), optional :: onoff ! default = .TRUE.
    INTEGER(4) :: retcode
    INTEGER(4) :: value
    LOGICAL :: Lonoff
    Lonoff = .TRUE.
    if (present(onoff)) Lonoff = onoff
    value = 0
    if (Lonoff) value = 1
    retcode = c_d4o_long_column_names(dbh, value)
  END FUNCTION fd4o_long_column_names
     
  FUNCTION fd4o_get_debug() RESULT(debug_mode)
    INTEGER(4) :: debug_mode
    debug_mode = c_d4o_get_debug()
  END FUNCTION fd4o_get_debug
  
  FUNCTION fd4o_set_debug(newvalue) RESULT(oldvalue)
    INTEGER(4), intent(in) :: newvalue
    INTEGER(4) :: oldvalue
    oldvalue = c_d4o_set_debug(newvalue)
  END FUNCTION fd4o_set_debug

  FUNCTION fd4o_get_null() RESULT(mdi)
    REAL(8) :: mdi
    mdi = c_d4o_get_null()
  END FUNCTION fd4o_get_null
  
  FUNCTION fd4o_set_null(newvalue) RESULT(oldvalue)
    REAL(8), intent(in) :: newvalue
    REAL(8) :: oldvalue
    oldvalue = c_d4o_set_null(newvalue)
  END FUNCTION fd4o_set_null
  
  FUNCTION fd4o_is_null_double(value) RESULT(truth)
    REAL(8), intent(in) :: value
    LOGICAL :: truth
    truth = (c_d4o_is_null(value) == 1)
  END FUNCTION fd4o_is_null_double
  
  FUNCTION fd4o_is_null_int8(value) RESULT(truth)
    INTEGER(8), intent(in) :: value
    LOGICAL :: truth
    truth = fd4o_is_null(REAL(value,8))
  END FUNCTION fd4o_is_null_int8

  FUNCTION fd4o_is_null_int(value) RESULT(truth)
    INTEGER(4), intent(in) :: value
    LOGICAL :: truth
    truth = fd4o_is_null(REAL(value,8))
  END FUNCTION fd4o_is_null_int
  
  FUNCTION fd4o_dbname(dbh) RESULT(dbname)
    INTEGER(4), intent(in) :: dbh
    CHARACTER(LEN=:), allocatable :: dbname
    INTEGER(8) :: ptr
    INTEGER(4) :: len
    ptr = c_d4o_get_dbname(dbh,len)
    allocate(character(len)::dbname)
    CALL c_d4o_ptr2str(ptr,dbname)
    CALL c_d4o_dealloc(ptr)
  END FUNCTION fd4o_dbname

  FUNCTION fd4o_query(qh,expanded) RESULT(query)
    INTEGER(4), intent(in) :: qh
    LOGICAL, intent(in), optional :: expanded
    CHARACTER(LEN=:), allocatable :: query
    INTEGER(8) :: ptr
    INTEGER(4) :: len, iexpanded
    LOGICAL :: Lexpanded
    Lexpanded = .false.
    if (present(expanded)) Lexpanded = expanded
    iexpanded = 0
    if (Lexpanded) iexpanded = 1
    ptr = c_d4o_get_query(qh,iexpanded,len)
    allocate(character(len)::query)
    CALL c_d4o_ptr2str(ptr,query)
    CALL c_d4o_dealloc(ptr)
  END FUNCTION fd4o_query

  FUNCTION fd4o_dbh(qh) RESULT(dbh)
    INTEGER(4), intent(in) :: qh
    INTEGER(4) :: dbh
    dbh = c_d4o_get_dbh(qh)
  END FUNCTION fd4o_dbh
  
  FUNCTION fd4o_typename(coltype) RESULT(s)
    INTEGER(4), intent(in) :: coltype
    CHARACTER(LEN=:), allocatable :: s
    INTEGER(8) :: ptr
    INTEGER(4) :: len
    ptr = c_d4o_get_typename(coltype,len)
    allocate(character(len)::s)
    CALL c_d4o_ptr2str(ptr,s)
    CALL c_d4o_dealloc(ptr)
  END FUNCTION fd4o_typename
  
  FUNCTION fd4o_coltype(typename) RESULT(coltype)
    CHARACTER(LEN=*), intent(in) :: typename
    INTEGER(4) :: coltype
    coltype = c_d4o_get_coltype(typename)
  END FUNCTION fd4o_coltype
  
  FUNCTION fd4o_errmsg(rc,msg) RESULT(s)
    INTEGER(4), intent(in) :: rc
    CHARACTER(LEN=*), intent(in), optional :: msg
    CHARACTER(LEN=:), allocatable :: s
    INTEGER(8) :: ptr
    INTEGER(4) :: len, retcode
    if (rc < 0) then
       retcode = -rc
    else
       retcode = 0
    endif
    ptr = c_d4o_get_errmsg(retcode,len)
    allocate(character(len)::s)
    CALL c_d4o_ptr2str(ptr,s)
    CALL c_d4o_dealloc(ptr)
    if (present(msg)) s = s//' : '//trim(msg)
  END FUNCTION fd4o_errmsg

  FUNCTION fd4o_int8(d) RESULT(i8)
    REAL(8), intent(in) :: d
    INTEGER(8) :: i8
    INTEGER(4) :: err
    CHARACTER(LEN=:), allocatable :: s
    if (fd4o_is_null(d)) then
       i8 = fd4o_null()
    else
       s = fd4o_text(d)
       err = 0
       read(s,*,iostat=err) i8
       if (err /= 0) i8 = fd4o_null()
       deallocate(s)
    endif
  END FUNCTION fd4o_int8
  
  FUNCTION fd4o_get_text(d) RESULT(s)
    REAL(8), intent(in) :: d
    CHARACTER(LEN=:), allocatable :: s
    INTEGER(8) :: ptr
    INTEGER(4) :: len
    ptr = c_d4o_get_text(d,len)
    allocate(character(len)::s)
    CALL c_d4o_ptr2str(ptr,s)
    CALL c_d4o_dealloc(ptr)
  END FUNCTION fd4o_get_text
  
  FUNCTION fd4o_textlen(d) RESULT(clen)
    REAL(8), intent(in) :: d
    INTEGER(4) :: clen
    clen = c_d4o_get_textlen(d)
  END FUNCTION fd4o_textlen
  
  FUNCTION fd4o_set_text(s) RESULT(d)
    CHARACTER(LEN=*), intent(in) :: s
    REAL(8) :: d
    d = c_d4o_set_text(s)
  END FUNCTION fd4o_set_text
  
  FUNCTION fd4o_opendb(dbname, mode, dbinfo, cascade) RESULT(dbh)
    CHARACTER(LEN=*), intent(in) :: dbname, mode
    LOGICAL, intent(in), optional :: dbinfo, cascade
    INTEGER(4) :: dbh, rc
    LOGICAL :: Ldbinfo, Lcascade, Loldvalue, Lreadonly
    CHARACTER(LEN=:), allocatable :: msgtext
    INTEGER(4) :: clen
    if (.not.fd4o_is_initialized) then
       TYPE_INT  = fd4o_coltype("integer") ! SQLITE_INTEGER (1)
       TYPE_REAL = fd4o_coltype("real")    ! SQLITE_FLOAT   (2)
       TYPE_TEXT = fd4o_coltype("text")    ! SQLITE_TEXT    (3)
       fd4o_is_initialized = .TRUE.
    endif
    dbh = c_d4o_opendb(trim(dbname), trim(mode))
    
    ! PRAGMA foreign_keys = ON by default -- unless readonly (or OFF if cascade explicitly given as .FALSE.)
    Lreadonly = (trim(fd4o_lowercase(mode)) == 'r' .or. trim(fd4o_lowercase(mode)) == 'readonly')
    Lcascade = .not.Lreadonly
    if (present(cascade)) Lcascade = cascade ! override
    if (dbh >= 0) Loldvalue = fd4o_cascade(dbh,Lcascade,err=rc)
    
    Ldbinfo = .FALSE.
    if (present(dbinfo)) Ldbinfo = dbinfo
    if (dbh >= 0 .and. Ldbinfo) then
       clen = len_trim(dbname) + len_trim(mode) + 80
       allocate(character(clen)::msgtext)
       write(msgtext,1000) dbh,trim(dbname),trim(mode),Lcascade
1000   format("dbh = ",i0," fd4o_opendb(dbname='",a,"',mode='",a,"',dbinfo=.TRUE.,cascade=",L1,")")
       call fd4o_dbinfo(0,dbh,&
            & msg=msgtext,&
            & std=.TRUE.,csv=.FALSE.)
       deallocate(msgtext)
    endif
  END FUNCTION fd4o_opendb

  FUNCTION fd4o_closedb(dbh) RESULT(retcode)
    INTEGER(4), intent(inout) :: dbh
    INTEGER(4) :: retcode
    retcode = c_d4o_closedb(dbh)
  END FUNCTION fd4o_closedb

  FUNCTION fd4o_exec(dbh, query) RESULT(retcode)
    INTEGER(4), intent(in) :: dbh
    INTEGER(4) :: retcode
    CHARACTER(LEN=*), intent(in) :: query
    retcode = c_d4o_exec(dbh, trim(query))
  END FUNCTION fd4o_exec

  FUNCTION fd4o_execfile(dbh, filename) RESULT(retcode)
    INTEGER(4), intent(in) :: dbh
    INTEGER(4) :: retcode
    CHARACTER(LEN=*), intent(in) :: filename
    retcode = c_d4o_execfile(dbh, filename)
  END FUNCTION fd4o_execfile

  FUNCTION fd4o_reset(obs,rowmajor) RESULT(retcode)
    TYPE(fd4o_obsdata_t), intent(inout) :: obs
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4) :: j,n
    INTEGER(4) :: retcode
    if (allocated(obs%query)) deallocate(obs%query)
    if (allocated(obs%d)) deallocate(obs%d)
    allocate(obs%d(0,0))
    if (allocated(obs%types)) deallocate(obs%types)
    if (allocated(obs%colname)) then
       n = size(obs%colname)
       do j=1,n
          if (allocated(obs%colname(j)%s)) deallocate(obs%colname(j)%s)
       enddo
       deallocate(obs%colname)
    endif
    obs%qh = -1
    obs%ncols = 0
    obs%nrows = 0
    obs%nparcnt = 0
    if (present(rowmajor)) then
       obs%rowmajor = rowmajor
    else
       obs%rowmajor = f4o_rowmajor_default
    endif
    retcode = 0
  END FUNCTION fd4o_reset

  FUNCTION fd4o_new_thru_array(array,rowmajor,fillcolnames,err) RESULT(newobs)
    REAL(8), intent(in) :: array(:,:)
    LOGICAL, intent(in), OPTIONAL :: rowmajor,fillcolnames
    INTEGER(4), intent(out), OPTIONAL :: err
    TYPE(fd4o_obsdata_t), allocatable :: newobs
    LOGICAL :: Lrowmajor, Lfillcolnames
    INTEGER(4) :: j,n,rc,clen,istat
    CHARACTER(len=:), allocatable :: ctmp
    allocate(newobs,stat=istat)
    if (istat == 0) then
       Lrowmajor = f4o_rowmajor_default
       if (present(rowmajor)) Lrowmajor = rowmajor
       rc = fd4o_reset(newobs,rowmajor=Lrowmajor)
       if (Lrowmajor) then ! TDB : Expensive if big
          newobs%d = TRANSPOSE(array)
       else
          newobs%d = array
       endif
       newobs%rowmajor = .FALSE. ! Hmmm... TBD
       newobs%ncols = size(newobs%d,dim=1)
       newobs%nrows = size(newobs%d,dim=2)
       newobs%nparcnt = 0
       n = newobs%ncols
       newobs%types = init_intvec(n,ivalue=TYPE_REAL)
       Lfillcolnames = .FALSE.
       if (present(fillcolnames)) Lfillcolnames = fillcolnames
       if (Lfillcolnames) then
          ! fill colnames with anonymous names "colum#1" .. "column#<N>"
          ! this will enable printing of this "array" aka "obs%d"
          allocate(newobs%colname(n))
          clen = len("column#") + 20;
          allocate(character(clen)::ctmp)
          do j=1,n
             write(ctmp,'(a,i0)') "column#",j
             newobs%colname(j)%s = trim(ctmp)
          enddo
          deallocate(ctmp)
       endif
    else
       ! unable to allocate newobs
       istat = ERR_SQLITE_NOMEM
    endif
    if (present(err)) err = -istat
  END FUNCTION fd4o_new_thru_array

  FUNCTION fd4o_new_thru_opt_object(obs,rowmajor,err) RESULT(newobs)
    TYPE(fd4o_obsdata_t), intent(inout), optional :: obs
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4), intent(out), OPTIONAL :: err
    TYPE(fd4o_obsdata_t), allocatable :: newobs
    INTEGER(4) :: j,n,rc,istat
    allocate(newobs,stat=istat)
    if (istat == 0) then
       rc = fd4o_reset(newobs,rowmajor=rowmajor)
       if (present(obs)) then
          newobs%qh = obs%qh
          obs%qh = -1 ! ... since newobs%qh now holds the query handle
          if (allocated(obs%query)) newobs%query = obs%query
          newobs%ncols = obs%ncols
          newobs%nrows = obs%nrows
          newobs%nparcnt = obs%nparcnt
          newobs%rowmajor = obs%rowmajor
          if (allocated(obs%d)) newobs%d = obs%d
          if (allocated(obs%types)) newobs%types = obs%types
          if (allocated(obs%colname)) then
             n = size(obs%colname)
             allocate(newobs%colname(n))
             do j=1,n
                newobs%colname(j)%s = obs%colname(j)%s
             enddo
          endif
       else if (present(rowmajor)) then
          newobs%rowmajor = rowmajor
       endif
    else
       ! unable to allocate newobs
       istat = ERR_SQLITE_NOMEM
    endif
    if (present(err)) err = -istat
  END FUNCTION fd4o_new_thru_opt_object

  FUNCTION fd4o_delete(obs,enforce) RESULT(retcode)
    TYPE(fd4o_obsdata_t), intent(inout), allocatable :: obs
    LOGICAL, intent(in), OPTIONAL :: enforce
    INTEGER(4) :: retcode
    if (allocated(obs)) then
       retcode = fd4o_destroy(obs,enforce=enforce)
       deallocate(obs,stat=retcode)
       if (retcode /= 0) retcode = ERR_SQLITE_NOMEM
    else
       retcode = 0
    endif
    retcode = -retcode
  END FUNCTION fd4o_delete
  
  FUNCTION fd4o_prepare(dbh, query, obs, ncols, nparcnt, rowmajor) RESULT(qh)
    INTEGER(4), intent(in) :: dbh
    CHARACTER(LEN=*), intent(in) :: query
    TYPE(fd4o_obsdata_t), intent(inout), OPTIONAL :: obs
    INTEGER(4), intent(out), OPTIONAL :: ncols, nparcnt
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4) :: qh
    INTEGER(4) :: ncols_local, nparcnt_local, rc
    LOGICAL :: Lrowmajor
    qh = c_d4o_prepare(dbh, trim(query), ncols_local, nparcnt_local)
    if (present(ncols)) ncols = ncols_local
    if (present(nparcnt)) nparcnt = nparcnt_local
    if (present(obs)) then
       Lrowmajor = obs%rowmajor
    else
       Lrowmajor = f4o_rowmajor_default
    endif
    if (present(rowmajor)) Lrowmajor = rowmajor
    if (present(obs) .and. qh >= 0) then
       rc = fd4o_destroy(obs)
       obs%qh = qh
       obs%query = trim(query)
       obs%ncols = ncols_local
       obs%nparcnt = nparcnt_local
       obs%rowmajor = Lrowmajor
    endif
  END FUNCTION fd4o_prepare

  FUNCTION fd4o_destroy_thru_qh(qh,enforce) RESULT(retcode)
    INTEGER(4), intent(inout) :: qh
    LOGICAL, intent(in), OPTIONAL :: enforce
    INTEGER(4) :: retcode
    INTEGER(4) :: ienforce
    ienforce = fd4o_default_destroy
    if (present(enforce)) then
       if (enforce) then
          ienforce = 1
       else
          ienforce = 0
       endif
    endif
    retcode = c_d4o_destroy(qh,ienforce)
    qh = -1
  END FUNCTION fd4o_destroy_thru_qh

  FUNCTION fd4o_destroy_thru_object(obs,enforce) RESULT(retcode)
    TYPE(fd4o_obsdata_t), intent(inout) :: obs
    LOGICAL, intent(in), OPTIONAL :: enforce
    INTEGER(4) :: retcode, dummy
    retcode = fd4o_destroy(obs%qh,enforce=enforce)
    dummy = fd4o_reset(obs,rowmajor=obs%rowmajor)
  END FUNCTION fd4o_destroy_thru_object

  !--- GETDBs
  
  FUNCTION fd4o_getdb_thru_opt_query(h, query, rowmajor, err) RESULT(obs)
    INTEGER(4), intent(in) :: h ! dbh or qh
    CHARACTER(len=*), intent(in), OPTIONAL :: query
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4), intent(out), OPTIONAL :: err
    TYPE(fd4o_obsdata_t), allocatable :: obs
    INTEGER(4) :: dbh, qh, rc
    obs = fd4o_new(rowmajor=rowmajor)
    if (present(query)) then
       dbh = h
       qh = fd4o_prepare(dbh,trim(query),obs=obs,rowmajor=rowmajor)
    else
       qh = h
       obs%qh = h
    endif
    if (qh >= 0) then
       rc = fd4o_getdb(obs,rowmajor=rowmajor,err=err)
    else
       !rc = fd4o_delete(obs,enforce=.TRUE.)
       if (present(err)) err = -ERR_SQLITE_ERROR
    endif
  END FUNCTION fd4o_getdb_thru_opt_query
  
  FUNCTION fd4o_getdb_thru_object(obs, rowmajor, err) RESULT(rc)
    TYPE(fd4o_obsdata_t), intent(inout) :: obs
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4), intent(out), OPTIONAL :: err
    INTEGER(4) :: rc
    INTEGER(8) :: ptr, colnames_ptr, sql_ptr
    INTEGER(4) :: j, n, ctotlen, offset, sql_len, shp(2)
    LOGICAL :: Lrowmajor
    INTEGER(4), allocatable :: clen(:)
    CHARACTER(len=:), allocatable :: ctmp
    if (obs%qh >= 0 .and. obs%ncols > 0) then
       n = obs%ncols
       if (allocated(obs%types)) then
          if (size(obs%types) /= n) deallocate(obs%types)
       endif
       if (.not.allocated(obs%types)) allocate(obs%types(n))
       obs%types(:) = 0
       allocate(clen(n))
       ptr = c_d4o_getdb(obs%qh, obs%ncols, obs%nrows, &
            & colnames_ptr, clen, obs%types, sql_ptr, sql_len)
       if (obs%nrows >= 0) then
          if (.not.allocated(obs%colname)) then
             ctotlen = sum(clen(:))
             allocate(character(ctotlen)::ctmp)
             CALL c_d4o_ptr2str(colnames_ptr,ctmp)
             allocate(obs%colname(n))
             offset = 0
             do j=1,n
                allocate(character(clen(j))::obs%colname(j)%s)
                obs%colname(j)%s(1:clen(j)) = ctmp(offset+1:offset+clen(j))
                offset = offset + clen(j)
             enddo
             deallocate(ctmp)
          endif
          if (allocated(obs%d)) then
             shp(1:2) = shape(obs%d)
             if (.not.(shp(1) == obs%ncols .and. shp(2) == obs%nrows)) deallocate(obs%d)
          endif
          if (.not.allocated(obs%d)) allocate(obs%d(obs%ncols,obs%nrows))
          CALL c_d4o_ptr2array(ptr, obs%ncols, obs%nrows, kind(obs%d), obs%d)
          if (present(rowmajor)) then
             Lrowmajor = rowmajor
          else
             Lrowmajor = obs%rowmajor
          endif
          obs%rowmajor = Lrowmajor
          if (Lrowmajor) then ! TDB : Expensive if big
             obs%d = TRANSPOSE(obs%d)
             obs%nrows = size(obs%d,dim=1)
             obs%ncols = size(obs%d,dim=2)
          endif
          if (allocated(obs%query)) deallocate(obs%query)
          if (sql_len > 0) then
             allocate(character(sql_len)::obs%query)
             CALL c_d4o_ptr2str(sql_ptr,obs%query)
          else
             obs%query = ' '
          endif
       endif
       CALL c_d4o_dealloc(sql_ptr)
       CALL c_d4o_dealloc(colnames_ptr)
       CALL c_d4o_dealloc(ptr)
       deallocate(clen)
    else
       obs%nrows = -ERR_SQLITE_ERROR
    endif
    rc = obs%nrows
    if (present(err)) err = rc
  END FUNCTION fd4o_getdb_thru_object

  !--- PUTDBs
  
  FUNCTION fd4o_putdb_thru_object_plus_opt_query(h, obs, query, limit, parnum, err) RESULT(rc)
    INTEGER(4), intent(in) :: h ! dbh or qh
    TYPE(fd4o_obsdata_t), intent(in) :: obs
    CHARACTER(len=*), intent(in), OPTIONAL :: query
    INTEGER(4), intent(in), OPTIONAL :: limit
    INTEGER(4), intent(in), optional :: parnum(:)
    INTEGER(4), intent(out), OPTIONAL :: err
    INTEGER(4), allocatable :: parnum_local(:)
    INTEGER(4) :: dbh, qh, rc, nparcnt, ncols, nrows, mincol, maxcol, dummy, j, k, kk
    LOGICAL :: Lrowmajor
    REAL(8), allocatable :: tmp(:,:)
    INTEGER(4), allocatable :: types(:)
    nrows = obs%nrows
    if (present(limit)) nrows = max(0,limit)
    if (nrows <= 0) then
       rc = 0
       goto 9999
    endif
    if (present(query)) then
       dbh = h
       qh = fd4o_prepare(dbh,trim(query))
    else
       qh = h
    endif
    if (qh >= 0) then
       nparcnt = fd4o_nparcnt(qh)
!       write(fd4o_debug_io,*) qh,': putdb[1]: nparcnt,present(parnum)=',nparcnt,present(parnum)
       parnum_local = init_intvec(nparcnt,intvec_in=parnum)
!       write(fd4o_debug_io,*) qh,': putdb[2]: nparcnt,size(parnum_local)=',nparcnt,size(parnum_local)
       nparcnt = size(parnum_local)
!       write(fd4o_debug_io,*) qh,': putdb[3]: parnum_local(:)=',parnum_local
       Lrowmajor = obs%rowmajor
       if (Lrowmajor) then ! Slightly optimized : take only columns present in "parnum_local"
#if 0
          tmp = TRANSPOSE(obs%d) ! Expensive if big (works ok)
          rc = c_d4o_putdb(qh, tmp, obs%ncols, nrows, obs%types, nparcnt, parnum_local)
#else
          ! Also works now and should generally be cheaper than "tmp = TRANSPOSE(obs%d)" -method above
          if (nparcnt > 0) then
             ! parnum[0] = 2; // column 2 := value (?1 aka [0]+1)
             ! parnum[1] = 3; // column 3 := statid (?2 aka [1]+1)
             ! parnum[2] = 0; // ?3 aka [2]+1 unused
             ! parnum[3] = 1; // column 4 := key (?4 aka [3]+1)
             mincol = obs%ncols
             maxcol = 0
             do j=1,nparcnt
                k = parnum_local(j)
                if (k >= 1 .and. k <= obs%ncols) then
                   mincol = min(mincol,k)
                   maxcol = max(maxcol,k)
                endif
             enddo
             if (mincol >= 1 .and. mincol <= maxcol) then
                ncols = maxcol - mincol + 1
!                write(fd4o_debug_io,*) qh,': putdb[4a]: mincol,maxcol,ncols,nparcnt=',mincol,maxcol,ncols,nparcnt
             else
                nparcnt = 0
                ncols = 1
                mincol = 0
                maxcol = 0
!                write(fd4o_debug_io,*) qh,': putdb[4b]: mincol,maxcol,ncols,nparcnt=',mincol,maxcol,ncols,nparcnt
             endif
          else
             ncols = 1
             mincol = 0
             maxcol = 0
          endif
          allocate(tmp(ncols,nrows),types(ncols))
!          write(fd4o_debug_io,*) &
!               & qh,': putdb: nparcnt, ncols, nrows, obs%ncols, obs%nrows, mincol, maxcol = ', &
!               & nparcnt, ncols, nrows, obs%ncols, obs%nrows, mincol, maxcol
          if (nparcnt > 0) then
             types(:) = TYPE_REAL
             do j=1,nparcnt
                k = parnum_local(j)
                if (k >= 1 .and. k <= obs%ncols) then
                   kk = k - mincol + 1
                   tmp(kk,1:nrows) = obs%d(1:nrows,k) ! A cheaper "transpose" -- if nrows not massively big
                   types(kk) = obs%types(k)
                   parnum_local(j) = kk
                else
                   parnum_local(j) = 0
                endif
             enddo
          endif
          rc = c_d4o_putdb(qh, tmp, ncols, nrows, types, nparcnt, parnum_local)
          deallocate(tmp,types)
#endif
       else
          rc = c_d4o_putdb(qh, obs%d, obs%ncols, nrows, obs%types, nparcnt, parnum_local)
       endif
       if (present(query)) dummy = fd4o_destroy(qh,enforce=.TRUE.)
    else
       rc = -ERR_SQLITE_ERROR
    endif
9999 continue
    if (present(err)) err = rc
  END FUNCTION fd4o_putdb_thru_object_plus_opt_query
  
  FUNCTION fd4o_putdb_thru_array_plus_opt_query(h, array, query, rowmajor, limit, parnum, err) RESULT(rc)
    INTEGER(4), intent(in) :: h ! dbh or qh
    REAL(8), intent(in) :: array(:,:)
    CHARACTER(len=*), intent(in), OPTIONAL :: query
    LOGICAL, intent(in), OPTIONAL :: rowmajor
    INTEGER(4), intent(in), OPTIONAL :: limit
    INTEGER(4), intent(in), optional :: parnum(:)
    INTEGER(4), intent(out), OPTIONAL :: err
    TYPE(fd4o_obsdata_t), allocatable :: tmpobs
    INTEGER(4) :: rc, dummy
    tmpobs = fd4o_new(array,rowmajor=rowmajor)
    rc = fd4o_putdb(h,tmpobs,query=query,limit=limit,parnum=parnum,err=err)
    dummy = fd4o_delete(tmpobs)
  END FUNCTION fd4o_putdb_thru_array_plus_opt_query
  
  SUBROUTINE fd4o_dbinfo(unit, dbh, msg, std, csv, table)
    INTEGER(4), intent(in) :: unit
    INTEGER(4), intent(in) :: dbh
    CHARACTER(LEN=*), intent(in), optional :: msg, table
    LOGICAL, intent(in), optional :: std, csv
    TYPE(fd4o_obsdata_t), allocatable :: tables, nrows, tinfo
    TYPE(fd4o_varchar_t) :: ctmp
    CHARACTER(LEN=:), allocatable :: queryA, queryB, queryC, queryD
    INTEGER(4) :: rc,i,n,ncols,ii,nn,nparcnt,maxlen
    INTEGER(4) :: qh
    LOGICAL :: Lheader
    if (unit >= 0) then
       flush(unit)
       rc = fd4o_long_column_names(dbh,onoff=.FALSE.) ! Turn long names off
       !-- table names & how many rows
       queryA = "SELECT 0 AS id,name,type,0 AS ncols,0 AS nrows FROM sqlite_schema"// &
            & " WHERE type IN ('table')"
!            & " WHERE type IN ('table','view')"
       if (present(table)) then ! interested in specific table only ?
          queryA = queryA // " AND name LIKE '"//trim(table)//"'"
       endif
       tables = fd4o_getdb(dbh,query=queryA,err=rc,rowmajor=.FALSE.)
       if (allocated(tables)) then
          n = tables%nrows
          !$OMP PARALLEL DO SCHEDULE(dynamic,1) &
          !$OMP& PRIVATE(i,qh,rc,ncols,nrows,queryB,queryC,maxlen,ctmp)
          do i=1,n
             tables%d(1,i) = i
             ctmp%s = fd4o_text(tables%d(2,i))
             maxlen = len(ctmp%s) + len("SELECT * FROM ") + len(" LIMIT 0")
             allocate(character(maxlen)::queryB)
             queryB = "SELECT * FROM "//ctmp%s//" LIMIT 0"
             ncols = 0
             qh = fd4o_prepare(dbh,query=queryB)
             if (qh < 0) then
                !$OMP CRITICAL (fd4o_dbinfo_out)
                write(unit,'(1x,a)') fd4o_errmsg(qh,msg='fd4o_prepare(B:'//queryB//')')
                flush(unit)
                !$OMP END CRITICAL (fd4o_dbinfo_out)
             else
                ncols = fd4o_ncols(qh)
             endif
             deallocate(queryB)
             rc = fd4o_destroy(qh,enforce=.TRUE.)
             tables%d(4,i) = ncols
             maxlen = len(ctmp%s) + len("SELECT count(*) FROM ")
             allocate(character(maxlen)::queryC)
             queryC = "SELECT count(*) FROM "//ctmp%s
             nrows = fd4o_getdb(dbh,query=queryC,err=rc,rowmajor=.FALSE.)
!             !$OMP CRITICAL (fd4o_dbinfo_out)
!             write(unit,'(1x,a,a,a,L1)') 'allocated(nrows) status for "',queryC,'" : ',allocated(nrows)
!             flush(unit)
!             !$OMP END CRITICAL (fd4o_dbinfo_out)
             if (rc == 1) then
                ! Returned exactly one row => adjust "tables"-table's "ncols" & "nrows" -columns
                tables%d(5,i) = nrows%d(1,1)
             else
                !$OMP CRITICAL (fd4o_dbinfo_out)
                write(unit,'(1x,a)') fd4o_errmsg(rc,msg='fd4o_getdb(C:'//queryC//')')
                flush(unit)
                !$OMP END CRITICAL (fd4o_dbinfo_out)
                tables%d(5,i) = rc ! Error code
             endif
             deallocate(queryC)
             rc = fd4o_delete(nrows,enforce=.TRUE.)
          enddo
          !$OMP END PARALLEL DO
          flush(unit)
          CALL fd4o_print(unit, tables, msg=msg, std=std, csv=csv, info = .FALSE.)
          write(unit,'(a)')
          Lheader = .true.
          do i=1,n
             CALL fd4o_print(unit, tables, csv=csv, info = .FALSE., offset=i-1, limit=1, header=Lheader)
             queryD = "PRAGMA table_info("//fd4o_text(tables%d(2,i))//")"
             write(unit,'(1x,a)') 'Invoking "'//queryD//'" ...'
             tinfo = fd4o_getdb(dbh,query=queryD,err=rc,rowmajor=.FALSE.)
             if (rc < 0) then
                write(unit,'(1x,a)') fd4o_errmsg(rc,msg='fd4o_getdb(D:'//queryD//')')
             endif
             if (rc >= 1) then
                nn = rc
                do ii=1,nn
                   tinfo%d(1,ii) = -ABS(tinfo%d(1,ii) + 1) ! cid
                   tinfo%d(2,ii) = fd4o_text(&
                        & fd4o_text(tables%d(2,i))//"." &
                        & //fd4o_text(tinfo%d(2,ii))//":" &
                        & //fd4o_text(tinfo%d(3,ii)))
                enddo
                CALL fd4o_print(unit, tinfo, csv=csv, info = .FALSE., header=.FALSE., maxcol=2)
             endif
             Lheader = .false.
             rc = fd4o_delete(tinfo,enforce=.TRUE.)
          enddo
          rc = fd4o_delete(tables,enforce=.TRUE.)
       else
          write(unit,'(1x,a)') fd4o_errmsg(rc,msg='fd4o_getdb(A:'//queryA//')')
       endif
       rc = fd4o_long_column_names(dbh) ! Turns long names on again
    endif
  END SUBROUTINE fd4o_dbinfo
  
  SUBROUTINE fd4o_info(unit, obs, msg, limit, offset, maxcol)
    INTEGER(4), intent(in) :: unit
    TYPE(fd4o_obsdata_t), intent(in) :: obs
    CHARACTER(LEN=*), intent(in), optional :: msg
    INTEGER(4), intent(in), optional :: limit, offset, maxcol
    CHARACTER(LEN=80) :: fmt2
    INTEGER(4) :: j,n,maxcolw,maxtypew
    INTEGER(4) :: dbh
    TYPE(fd4o_varchar_t), allocatable :: typename(:)    
    if (unit >= 0) then
       if (present(msg)) then
          write(unit,'(/,a)')'# *** fd4o_info : '//trim(msg)
       else
          write(unit,'(/,a)')'# *** fd4o_info ***'
       endif
1000   format("# ",a," : ",3(i0,:,1x))
1001   format("# ",a,:," : ",a)
1003   format("# ",a,:," : ",L1)
1002   format('("# ",i3,". column = ",a',i0,'," : type = ",a',i0,'," [#",i0,"]")')
       dbh = fd4o_dbh(obs%qh)
       write(unit,1001) 'Database full path   ',fd4o_dbname(dbh)
       write(unit,1000) 'Database handle (dbh)',dbh
       write(unit,1000) 'SQL-handle (qh)      ',obs%qh
       if (allocated(obs%query)) then
          write(unit,1001) 'SQL-query',obs%query
       else
          write(unit,1001) 'SQL-query not available'
       endif
       if (present(limit))   write(unit,1000) 'LIMIT =              ',limit
       if (present(offset))  write(unit,1000) 'OFFSET =             ',offset
       if (present(maxcol))  write(unit,1000) 'MAXCOL =             ',maxcol
       write(unit,1003) 'Rowmajor (T/F)                ',obs%rowmajor
       write(unit,1000) 'Number of columns (ncols)     ',obs%ncols
       write(unit,1000) 'Number of rows (nrows)        ',obs%nrows
       write(unit,1000) 'Max param (?#) index (nparcnt)',obs%nparcnt
       if (allocated(obs%d)) then
          write(unit,1000) 'Size & shape of data',size(obs%d),shape(obs%d)
       else
          write(unit,1001) 'Size & shape of data not available'
       endif
       if (allocated(obs%types) .and. allocated(obs%colname)) then
          n = obs%ncols
          allocate(typename(n))
          maxcolw = 0
          maxtypew = 0
          do j=1,n
             maxcolw = max(maxcolw,len(obs%colname(j)%s))
             typename(j)%s = fd4o_typename(obs%types(j))
             maxtypew = max(maxtypew,len(typename(j)%s))
          enddo
          write(fmt2,1002) maxcolw, maxtypew
          do j=1,n
             write(unit,fmt=fmt2) j,obs%colname(j)%s,typename(j)%s,obs%types(j)
             deallocate(typename(j)%s)
          enddo
          deallocate(typename)
       endif
    endif
  END SUBROUTINE fd4o_info

  SUBROUTINE fd4o_print_thru_query(unit, dbh, query, msg, std, csv, limit, offset, info, header, maxcol)
    INTEGER(4), intent(in) :: unit, dbh
    CHARACTER(len=*), intent(in) :: query
    CHARACTER(LEN=*), intent(in), optional :: msg
    LOGICAL, intent(in), optional :: std, csv, info, header
    INTEGER(4), intent(in), optional :: limit, offset, maxcol
    TYPE(fd4o_obsdata_t), allocatable :: tmpobs
    INTEGER(4) :: rc, dummy
    if (unit >= 0 .and. dbh >= 0) then
       tmpobs = fd4o_getdb(dbh,query=query,rowmajor=.FALSE.,err=rc)
       !write(fd4o_debug_io,*) rc,': fd4o_print_thru_query: allocated(tmpobs)=',allocated(tmpobs)
       if (allocated(tmpobs) .and. rc >= 0) then
          CALL fd4o_print(unit, tmpobs, &
               & msg=msg, std=std, csv=csv, limit=limit, offset=offset, info=info, header=header, maxcol=maxcol)
       else
          write(fd4o_debug_io,'(1x,a)') fd4o_errmsg(rc,'fd4o_print(query='//trim(query)//')')
       endif
       dummy = fd4o_delete(tmpobs,enforce=.TRUE.)
    endif
  END SUBROUTINE fd4o_print_thru_query
  
  SUBROUTINE fd4o_print_thru_object(unit, obs, msg, std, csv, limit, offset, info, header, maxcol)
    INTEGER(4), intent(in) :: unit
    TYPE(fd4o_obsdata_t), intent(in) :: obs
    CHARACTER(LEN=*), intent(in), optional :: msg
    LOGICAL, intent(in), optional :: std, csv, info, header
    INTEGER(4), intent(in), optional :: limit, offset, maxcol
    CHARACTER(LEN=:), allocatable :: msgtext
    CHARACTER(LEN=80) :: fmt1, fmt2, fmt3, fmt4, fmt5
    LOGICAL :: Lstd, Lcsv, Linfo, Lheader
    INTEGER(4), parameter :: minwidth = 0
    INTEGER(4) :: i,j,k,maxlen,clen,icsv,maxwidth
    INTEGER(4) :: i_limit, i_offset, i_lo, i_hi, i_maxcol
    INTEGER(4), allocatable :: width(:)
    CHARACTER(LEN=:), allocatable :: cline
    TYPE(fd4o_varchar_t), allocatable :: typename(:)
    REAL(8), ALLOCATABLE :: tmp(:)
    LOGICAL :: Lrowmajor
    CHARACTER(LEN=*), parameter :: underscore = '='
    if (unit >= 0) then
1001   format('("#",',i0,'(1x,a',i0,'))')
1002   format('(1x,1p,',i0,'(1x,e',i0,'.16))')
1003   format('(a)')
1004   format('("#",',i0,'(a,:,","))')
1005   format('("#",',i0,'(',i0,'x,',i0,'a1))')
       if (present(msg)) then
          msgtext = msg
       else
          msgtext = 'fd4o_print'
       endif
       Lheader = .true.
       if (present(header)) Lheader = header
       Linfo = .true.
       if (present(info)) Linfo = info
       Lstd = .true.
       if (present(std)) Lstd = std
       Lcsv = .false.
       if (present(csv)) Lcsv = csv
       if (Lcsv) Lstd = .true.
       i_maxcol = obs%ncols
       if (present(maxcol)) i_maxcol = max(0,min(maxcol,obs%ncols))
       if (i_maxcol > 0 .and. obs%nrows > 0 .and. allocated(obs%d) .and. &
            & allocated(obs%types) .and. allocated(obs%colname)) then
          if (Linfo) CALL fd4o_info(unit, obs, msg=msgtext, limit=limit, offset=offset, maxcol=maxcol)
          Lrowmajor = obs%rowmajor
          i_offset = 0
          if (present(offset)) i_offset = offset
          i_limit = obs%nrows
          if (present(limit)) i_limit = limit
          i_lo = 1 + max(0,min(i_offset,obs%nrows-1))
          i_hi = max(0,min(i_offset+i_limit,obs%nrows))
          allocate(width(i_maxcol))
          width(:) = minwidth
          maxwidth = minwidth
          if (Lstd) then
             !if (any(obs%types(:) == TYPE_TEXT)) then
                do j=1,i_maxcol
                   !if (obs%types(j) == TYPE_TEXT) then
                      do i=i_lo,i_hi
                         if (Lrowmajor) then
                            clen = fd4o_textlen(obs%d(i,j))
                         else
                            clen = fd4o_textlen(obs%d(j,i))
                         endif
                         width(j) = max(width(j),clen)
                      enddo
                   !endif
                enddo
             !endif
          endif
          allocate(typename(i_maxcol))
          do j=1,i_maxcol
             typename(j)%s = fd4o_typename(obs%types(j)) ! implicit allocate(character(*)::typename(j)%s)
             width(j) = max(width(j),len(typename(j)%s))
             width(j) = max(width(j),len(obs%colname(j)%s))
             maxwidth = max(maxwidth,width(j))
          enddo
          if (Lstd) then ! Type sensitive conversion (tsc)
             if (Lcsv) then
                icsv = 1
                write(fmt4,1004) i_maxcol
                if (Lheader) then
                   write(unit,fmt=fmt4) (typename(j)%s,j=1,i_maxcol)
                   write(unit,fmt=fmt4) (obs%colname(j)%s,j=1,i_maxcol)
                endif
             else
                icsv = 0
                if (Lheader) then
                   do j=1,i_maxcol
                      write(fmt1,1001) 1, width(j)
                      if (j > 1) fmt1 = '('//fmt1(6:)
                      write(unit,fmt=fmt1,advance='no') typename(j)%s
                   enddo
                   write(unit,'(a)')
                   do j=1,i_maxcol
                      write(fmt1,1001) 1, width(j)
                      if (j > 1) fmt1 = '('//fmt1(6:)
                      write(unit,fmt=fmt1,advance='no') obs%colname(j)%s
                   enddo
                   write(unit,'(a)')
                   do j=1,i_maxcol
                      maxlen = max(len(typename(j)%s),len(obs%colname(j)%s))
                      write(fmt5,1005) 1, width(j)-maxlen+1, width(j)
                      if (j > 1) fmt5 = '('//fmt5(6:)
                      write(unit,fmt=fmt5,advance='no') (underscore,k=1,maxlen)
                   enddo
                   write(unit,'(a)')
                endif
             endif
             maxlen = (2+maxwidth) * i_maxcol + 1
             write(fmt3,1003)
             allocate(character(maxlen)::cline)
             if (Lrowmajor) then
                do i=i_lo,i_hi
                   tmp = obs%d(i,1:i_maxcol)
                   call c_d4o_tsc(icsv,i_maxcol,width,obs%types,tmp,cline,clen)
                   write(unit,fmt=fmt3) cline(1:clen)
                enddo
             else
                do i=i_lo,i_hi
                   call c_d4o_tsc(icsv,i_maxcol,width,obs%types,obs%d(1,i),cline,clen)
                   write(unit,fmt=fmt3) cline(1:clen)
                enddo
             endif
             deallocate(cline)
          else ! No type sensitive conversion, pure Fortran : "text" strings are incorrect (since no conversion done)
             write(fmt1,1001) i_maxcol, maxwidth
             if (Lheader) then
                write(unit,fmt=fmt1) (typename(j)%s,j=1,i_maxcol)
                write(unit,fmt=fmt1) (obs%colname(j)%s,j=1,i_maxcol)
                do j=1,i_maxcol
                   maxlen = max(len(typename(j)%s),len(obs%colname(j)%s))
                   write(fmt5,1005) 1, maxwidth-maxlen+1, maxwidth
                   if (j > 1) fmt5 = '('//fmt5(6:)
                   write(unit,fmt=fmt5,advance='no') (underscore,k=1,maxlen)
                enddo
                write(unit,'(a)')
             endif
             write(fmt2,1002) i_maxcol, maxwidth
             if (Lrowmajor) then
                do i=i_lo,i_hi
                   write(unit,fmt=fmt2) obs%d(i,1:i_maxcol)
                enddo
             else
                do i=i_lo,i_hi
                   write(unit,fmt=fmt2) obs%d(1:i_maxcol,i)
                enddo
             endif
          endif
          do j=1,i_maxcol
             deallocate(typename(j)%s)
          enddo
          deallocate(typename)
          deallocate(width)
       endif ! if (i_maxcol > 0 .and. obs%nrows > 0 ...
       deallocate(msgtext)
    endif
  END SUBROUTINE fd4o_print_thru_object

  FUNCTION fd4o_ncols(qh) RESULT(n)
    INTEGER(4), intent(in) :: qh
    INTEGER(4) :: n
    n = c_d4o_get_ncols(qh)
  END FUNCTION fd4o_ncols

  FUNCTION fd4o_nparcnt(qh) RESULT(n)
    INTEGER(4), intent(in) :: qh
    INTEGER(4) :: n
    n = c_d4o_get_nparcnt(qh)
  END FUNCTION fd4o_nparcnt

  FUNCTION fd4o_mpirank(fix) RESULT(retcode)
    INTEGER(4), intent(in), optional :: fix
    INTEGER(4) :: myrank
    INTEGER(4) :: retcode
    myrank = -1
    if (present(fix)) myrank = fix
    retcode = c_d4o_mpirank(myrank)
  END FUNCTION fd4o_mpirank

  FUNCTION fd4o_mpisize(fix) RESULT(retcode)
    INTEGER(4), intent(in), optional :: fix
    INTEGER(4) :: numranks
    INTEGER(4) :: retcode
    numranks = 0
    if (present(fix)) numranks = fix
    retcode = c_d4o_mpisize(numranks)
  END FUNCTION fd4o_mpisize
  
  FUNCTION fd4o_maxdb() RESULT(retcode)
    INTEGER(4) :: retcode
    retcode = c_d4o_maxdb()
  END FUNCTION fd4o_maxdb

  FUNCTION fd4o_coreid() RESULT(retcode)
    INTEGER(4) :: retcode
    retcode = c_d4o_coreid()
  END FUNCTION fd4o_coreid

  SUBROUTINE fd4o_traceback(msg,errcode)
    CHARACTER(LEN=*), intent(in) :: msg
    INTEGER(4), intent(in), optional :: errcode
    INTEGER(4) :: code
    code = fd4o_null()
    if (present(errcode)) code = errcode
    CALL fd4o_exit(msg,code,0)
  END SUBROUTINE fd4o_traceback
  
END MODULE fd4o_mod

! The following NOT in the fd4o_mod in order to access it from C-layer, too

subroutine fd4o_exit(msg,errcode,do_exit)
  use fd4o_mod, only : fd4o_mpirank, fd4o_is_null, fd4o_debug_io
#if defined(__INTEL_COMPILER)
  use ifcore, only : tracebackqq
#endif
  implicit none
  character(len=*),intent(in) :: msg
  INTEGER(4), intent(in) :: errcode, do_exit
  interface ! stdlib.h
     subroutine c_exit(errcode) bind (c, name="exit")
       use, intrinsic :: iso_c_binding
       integer(c_int), value :: errcode
     end subroutine c_exit
     subroutine c_putenv(s) bind (c, name="putenv")
       use, intrinsic :: iso_c_binding
       character(kind=c_char), dimension(*) :: s
     end subroutine c_putenv
     subroutine c_abort() bind (c, name="abort")
     end subroutine c_abort
  end interface
  logical :: LLdo_exit
  INTEGER(4) :: myrank
  myrank = fd4o_mpirank()
  LLdo_exit = (do_exit /= 0)
  if (LLdo_exit) then
     if (fd4o_is_null(errcode)) then
        write(fd4o_debug_io,'(a,i0,a,i0,a,i0,a)') &
             & '[',myrank,'] Error : '//trim(msg)//' : errcode=NULL'
     else
        write(fd4o_debug_io,'(a,i0,a,i0,a,i0,a)') &
             & '[',myrank,'] Error : '//trim(msg)//' : errcode=',errcode
     endif
  else
     if (fd4o_is_null(errcode)) then
        write(fd4o_debug_io,'(a,i0,a)') &
             & '[',myrank,'] TraceBack : '//trim(msg)
     else
        write(fd4o_debug_io,'(a,i0,a,i0,a)') &
             & '[',myrank,'] TraceBack : '//trim(msg)//' ',errcode
     endif
  endif
  flush(fd4o_debug_io)
#if defined(__INTEL_COMPILER)
  call tracebackqq(trim(msg),user_exit_code=-1)
  !write(0,*) 'after tracebackqq : LLdo_exit=',LLdo_exit,' do_exit,errcode=',do_exit,errcode
#endif
#if defined(__GFORTRAN__)
  call backtrace()
#endif 
#if defined(__PGI)
  call c_putenv('PGI_TERM=trace'//char(0))
  if (LLdo_exit) call c_abort()
#endif
  flush(fd4o_debug_io)
  if (LLdo_exit) call c_exit(errcode)
end subroutine fd4o_exit
  
