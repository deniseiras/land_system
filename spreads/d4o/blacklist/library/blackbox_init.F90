      SUBROUTINE blackbox_init(KOUT, CDATA_NAME, KDATA, &
     &                         RMDI, &
     &                         KANDATE, KANTIME, &
     &                         KCOMPDATE, KCOMPTIME, &
     &                         KFEEDBACK_SIZE, KRETCODE)
USE PARKIND1  ,ONLY : JPIM     ,JPRB, JPRD
!USE YOMHOOK, ONLY : DR_HOOK, LHOOK
!--   NAME_INDEX-definition
USE yomblackbox
implicit none
INTEGER(KIND=JPIM), INTENT(IN)       :: KOUT, KDATA
REAL(KIND=JPRD), INTENT(IN)          :: RMDI
CHARACTER(LEN=*), INTENT(IN)         :: CDATA_NAME(KDATA)
INTEGER(KIND=JPIM),  INTENT(OUT)     :: KANDATE, KANTIME
INTEGER(KIND=JPIM),  INTENT(OUT)     :: KCOMPDATE, KCOMPTIME
INTEGER(KIND=JPIM),  INTENT(OUT)     :: KFEEDBACK_SIZE, KRETCODE
! === END OF INTERFACE BLOCK ===

CHARACTER(LEN=80) CL
INTEGER(KIND=JPIM) J, JJ, IS_CHAR, IS_SPECIAL
CHARACTER(LEN=5) CL_IS_CHAR, CL_IS_SPECIAL
LOGICAL :: LLVERBOSE
!REAL(KIND=JPRB) :: zhook_handle

!IF (LHOOK) CALL DR_HOOK('BLACKBOX_INIT', 0, ZHOOK_HANDLE)

      LLVERBOSE = (KOUT >= 0)

!--   Perform dynamic linking
      KRETCODE = 0
      CALL dynamic_linking(KRETCODE)
      if (KRETCODE /= 0) then
         write(KOUT,*) 'BLACKBOX_INIT: Dynamic linking failed'
         !IF (LHOOK) CALL DR_HOOK('BLACKBOX_INIT', 1, ZHOOK_HANDLE)
         return
      endif

!--   Provide the universal missing data indicator, typically the -2147483647.0 i.e. -(2^31-1)
      IF (LLVERBOSE) write(KOUT,*) &
     &'BLACKBOX_INIT: Missing Data Indicator to be used = ',RMDI
      CALL fput_mdi(RMDI)       ! C-routine in "dynamic_symbols.c"

!--   Get the analysis date and time for which the BLACKLIST was compiled
      CALL fget_date_and_time( &
     &     KANDATE, KANTIME, &
     &     KCOMPDATE, KCOMPTIME &
     &     )                    ! C-routine in "dynamic_symbols.c"
      IF (LLVERBOSE) write(KOUT,'(1x,a,i12.8,i12.6)') &
     &'BLACKBOX_INIT:    Analysis date & time of the BLACKLIST: ', &
     &KANDATE, KANTIME
      IF (LLVERBOSE) write(KOUT,'(1x,a,i12.8,i12.6)') &
     &'BLACKBOX_INIT: Compilation date & time of the BLACKLIST: ', &
     &KCOMPDATE, KCOMPTIME

      CALL fget_symbol_table_len(NAME_INDEX_LEN)      ! C-routine in "dynamic_symbols.c"
      IF (LLVERBOSE) write(KOUT,*) &
     &'BLACKBOX_INIT: Number of predefined symbols=', &
     & NAME_INDEX_LEN

      IF (LLVERBOSE) write(KOUT,*)
      IF (LLVERBOSE) write(KOUT,*) 'BLACKBOX_INIT: List of predefined symbols:'
      IF (LLVERBOSE) write(KOUT,1004) &
     &     ' ','Symbol name', 'C-index', 'String ?', 'Special ?', &
     &     ' ','===========', '=======', '========', '========='

      do j=0,NAME_INDEX_LEN-1
         call fget_symbol(j, CL, is_char, is_special) ! C-routine in "dynamic_symbols.c"
         CL_is_char = 'No'
         if (is_char == 1) CL_is_char = 'Yes'
         CL_is_special = 'No'
         if (is_special == 1) CL_is_special = 'Yes'
         IF (LLVERBOSE) write(KOUT,1002) &
     &        trim(adjustl(CL)), j, CL_is_char, CL_is_special
 1002    format(1x,12x,2x,a30,2x,i12,2x,a10,2x,a10)
      enddo

      allocate(NAME_INDEX(0:NAME_INDEX_LEN-1))
      NAME_INDEX(:) = 2147483647

      IF (LLVERBOSE) write(KOUT,*)
      IF (LLVERBOSE) write(KOUT,*) &
     &'BLACKBOX_INIT: Number of user supplied symbols=', &
     & KDATA

      IF (LLVERBOSE) write(KOUT,*)
      IF (LLVERBOSE) write(KOUT,*) 'BLACKBOX_INIT: List of user supplied symbols:'
      IF (LLVERBOSE) write(KOUT,1004) &
     &'User index', 'User symbol', 'C-index', 'String ?', 'Special ?', &
     &'==========', '===========', '=======', '========', '========='
 1004 format((1x,a12,2x,a30,2x,a12,2x,a10,2x,a10))

      KRETCODE = 0
      do j=1,KDATA
         CL = trim(adjustl(CDATA_NAME(j)))            ! C-routine in "dynamic_symbols.c"
         if (len_trim(CL) <= 0) cycle ! Skip blank strings
         CALL fget_symbol_info(trim(CL)//char(0), &
     &                         jj, is_char, is_special)
         if (jj >= 0 .and. jj < NAME_INDEX_LEN) then
            NAME_INDEX(jj) = j-1 ! Minus one because of C-indexing in ZDATA[]
         else
            KRETCODE = KRETCODE + 1
         endif
         CL_is_char = 'No'
         if (is_char == 1) CL_is_char = 'Yes'
         if (is_char == 2) CL_is_char = 'ERROR'
         CL_is_special = 'No'
         if (is_special == 1) CL_is_special = 'Yes'
         if (is_special == 2) CL_is_special = 'ERROR'
         IF (LLVERBOSE) write(KOUT,1001) j, trim(CL), jj, CL_is_char, CL_is_special
 1001    format(1x,i12,2x,a30,2x,i12,2x,a10,2x,a10)
      enddo

      IF (LLVERBOSE) write(KOUT,'(/,1x,a,/,(10x,a))') &
     &'BLACKBOX_INIT: CONTENTS OF THE BLACKLIST FEEDBACK-vector',' ', &
     &'vvv----- Locations in the FEEDBACK-vector', &
     &'  0=Blacklist code LINE NUMBER where the blacklisting occurred'

      do j=1,KDATA
         CL = trim(adjustl(CDATA_NAME(j)))            ! C-routine in "dynamic_symbols.c"
         if (len_trim(CL) > 0) then
            IF (LLVERBOSE) write(KOUT,'(10x,i3,"=",a," causes blacklisting")') j,CL
         endif
      enddo
      IF (LLVERBOSE) write(KOUT,*)

      KFEEDBACK_SIZE = min(KDATA,NAME_INDEX_LEN)

      if (KRETCODE > 0) then
         write(KOUT,*)'BLACKBOX_INIT: ',KRETCODE,' errors were found'
      endif

!IF (LHOOK) CALL DR_HOOK('BLACKBOX_INIT', 1, ZHOOK_HANDLE)
END SUBROUTINE blackbox_init


