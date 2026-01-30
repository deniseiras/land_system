program fortest
  use fd4o_mod
  implicit none
  integer :: rc
  integer(4) :: dbh, qh
  integer :: i,j,ntmp,nparcnt
  type(fd4o_obsdata_t) :: obs
  type(fd4o_obsdata_t), allocatable :: newobs
  integer :: debug_io
  character(len=80) :: dbname
  integer :: k,iargc
  character(len=80) :: key,value
  character(len=255) :: select
  real(8) :: dtmp
  character(len=:), allocatable :: ctmp
  character(len=20) :: xtmp
  real(8), allocatable :: arr(:,:)
  integer(4), allocatable :: parnum(:)
  integer :: xdate,xtime
  real(8) :: oldvalue

  debug_io = fd4o_debug_io

  iargc = COMMAND_ARGUMENT_COUNT()
  
!  do k=0,iargc
!     call GET_COMMAND_ARGUMENT(k,dbname)
!     write(fd4o_debug_io,'(1x,a,i0,a)') 'arg#',k,' : '//trim(dbname)
!  enddo
!  stop

  if (iargc >= 1) then
     call GET_COMMAND_ARGUMENT(1,dbname)
  else
     dbname='upd.db'
  endif
  if (iargc >= 2) then
     call GET_COMMAND_ARGUMENT(2,key)
  else
     key='key'
  endif
  if (iargc >= 3) then
     call GET_COMMAND_ARGUMENT(3,value)
  else
     value='value'
  endif
  if (iargc >= 4) then
     call GET_COMMAND_ARGUMENT(4,select)
  else
     select=' '
  endif
  
  !-- readonly access first

  write(debug_io,'(1x,a,1p,g25.16)') 'NULL-value = ',fd4o_null()
  write(debug_io,'(1x,a,1p,g25.16,a,L5)') 'Value = ',fd4o_null(),' is NULL ? ',fd4o_is_null(fd4o_null())
  oldvalue = fd4o_null(1.234_8)
  write(debug_io,'(1x,a,1p,2g25.16)') 'NULL-value = ',fd4o_null(),oldvalue
  oldvalue = fd4o_null(oldvalue)
  write(debug_io,'(1x,a,1p,g25.16)') 'NULL-value = ',fd4o_null()
  
  
  dbh = fd4o_open(dbname,'readonly',dbinfo=.true.)

  write(debug_io,'(1x,i0,a,a,a,i0,a,a)') dbh,': dbname fullpath = ',fd4o_dbname(dbh),&
       & ' : error code = ',dbh,' ',fd4o_errmsg(dbh)

  newobs = fd4o_new(rowmajor=.FALSE.)
  
  rc = fd4o_reset(newobs)

  if (select /= ' ') then
     qh = fd4o_prepare(dbh,select,obs=newobs)
     if (qh >= 0) then
        call fd4o_info(debug_io,newobs,msg='after fd4o_prepare('//newobs%query//')')
        rc = fd4o_getdb(newobs)
        call fd4o_info(debug_io,newobs)
        write(debug_io,*) "Fortran index of 'value' = ",fd4o_colidx(newobs%qh,"value")
        write(debug_io,*) "Fortran index of 'HDR.key' = ",fd4o_colidx(newobs%qh,"HDR.key")
        call fd4o_print(debug_io,newobs,'after fd4o_getdb')
        call fd4o_print(debug_io,newobs,'after fd4o_getdb',std=.false.)
        call fd4o_print(debug_io,newobs,'after fd4o_getdb',csv=.true.)
     endif
     rc = fd4o_destroy(newobs)
     rc = fd4o_close(dbh)
     stop
  endif
  
  rc = fd4o_exec(dbh,'create temp view foobar as select '//trim(key)//','//&
       & trim(value)//' from hdr order by '//trim(key)//' desc limit 10')
  
  qh = fd4o_prepare(dbh,'select * from foobar',obs=newobs,rowmajor=.FALSE.)

  write(debug_io,'(1x,i0,a,a)') newobs%qh,': query = ',fd4o_query(newobs%qh)
  write(debug_io,'(1x,i0,a,a)') newobs%qh,': query (expanded) = ',fd4o_query(newobs%qh,expanded=.true.)
  write(debug_io,'(1x,i0,a,i0)') newobs%qh,': query dbh = ',fd4o_dbh(newobs%qh)
  
  call fd4o_info(debug_io,newobs,msg='after fd4o_prepare')
  rc = fd4o_getdb(newobs)

  call fd4o_print(debug_io,newobs,'after fd4o_getdb 1')
  call fd4o_print(debug_io,newobs,'after fd4o_getdb 2',std=.false.)
  call fd4o_print(debug_io,newobs,'after fd4o_getdb 3',csv=.true.)

  if (allocated(newobs%types)) then
     if (newobs%types(2) == fd4o_coltype("text")) then
        
        write(debug_io,*) newobs%d(2,1)
1111    format(1x,1p,g25.16," = [",a,"]")
        write(debug_io,1111) newobs%d(2,1),fd4o_text(newobs%d(2,1))
        dtmp = 1.234_8
        write(debug_io,1111) dtmp,fd4o_text(dtmp)
        ctmp = fd4o_text(dtmp)
        write(debug_io,1111) dtmp,ctmp
        xtmp = fd4o_text(dtmp)
        write(debug_io,1111) dtmp,xtmp

        ctmp = 'string text'
        dtmp = fd4o_text(ctmp)
        write(debug_io,1111) dtmp,ctmp

        ctmp = fd4o_text(dtmp)
        write(debug_io,1111) dtmp,ctmp
     endif
     
  endif
  
  rc = fd4o_destroy(newobs)
  call fd4o_info(debug_io,newobs,'after fd4o_destroy')
  rc = fd4o_close(dbh)

  rc =  fd4o_delete(newobs)
  
  if (dbname == 'upd.db') then
     !-- accessing as old database
     dbh = fd4o_open(trim(dbname),'update')
     write(debug_io,'(1x,i0,a,a,a,i0,a,a)') dbh,': dbname fullpath = ',fd4o_dbname(dbh),&
          & ' : error code = ',dbh,' ',fd4o_errmsg(rc)
     obs = fd4o_getdb(dbh,'select '//trim(key)//','//&
          & trim(value)//' from hdr order by '//trim(key)//' desc',err=rc)
     write(debug_io,'(1x,a)') fd4o_errmsg(rc,'fd4o_getdb_direct')
     call fd4o_info(debug_io,obs,msg='after fd4o_getdb_direct')
!     call fd4o_getdb(rc,obs)
     call fd4o_print(debug_io,obs,'after fd4o_getdb')

     qh = fd4o_prepare(dbh,'update hdr set '//trim(value)//' = 100+?1 where '//&
          & trim(key)//' = ?3 and '//trim(value)//' is not NULL',ncols=ntmp,nparcnt=nparcnt)

     if (qh >= 0) then
        ! below : parnum(:) gets automatically allocated +
        !         ?1 aka parnum(1) gets fetched from col#2
        !         ?2 aka parnum(2) unused
        !         ?3 aka parnum(3) gets fetched from col#1
        parnum = [2,0,1]
        write(debug_io,*)qh,'[1]: ntmp=',ntmp,', nparcnt=',nparcnt,', parnum=',parnum(:)
        call fd4o_info(debug_io,obs,msg='before fd4o_putdb')
        
        rc = fd4o_putdb(qh,obs,parnum=parnum)
        write(debug_io,*)rc,': fd4o_putdb[1]: '//fd4o_errmsg(rc)
        rc = fd4o_destroy(qh)

        rc = fd4o_getdb(obs)
        call fd4o_print(debug_io,obs,'after 2nd fd4o_getdb')

        qh = fd4o_prepare(dbh,'insert into hdr ('//trim(key)//','//&
             & trim(value)//') values (?1,?2)',ncols=ntmp,nparcnt=nparcnt)
        write(debug_io,*)qh,'[2]: ntmp=',ntmp,', nparcnt=',nparcnt,', parnum=',parnum(:)

        !allocate(arr(2,4))
        arr = reshape([10.0_8,1.23_8,11.0_8,2.56_8,12.0_8,55.66_8,13.0_8,-8.9_8],[2,4])
        write(debug_io,*)'[2]: size(arr),shape(arr)=',size(arr),shape(arr)
        write(debug_io,*)'[2]: arr=',arr
        rc = fd4o_putdb(qh,array=arr,rowmajor=.FALSE.)
        write(debug_io,*)rc,': fd4o_putdb[2]: '//fd4o_errmsg(rc)
        rc = fd4o_destroy(qh)

        rc = fd4o_getdb(obs)
        call fd4o_print(debug_io,obs,'after 3rd fd4o_getdb')
        
        rc = fd4o_destroy(obs)

        call fd4o_print(debug_io,dbh,"select rowid,* from hdr limit -1 offset 3", limit=3)
     endif
        
     
     rc = fd4o_destroy(obs)
     rc = fd4o_close(dbh)
  endif

end program fortest
