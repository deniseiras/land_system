PROGRAM Screening
  
  ! Usage : ./Screening d4o-database-file(s)
  
  use fd4o_mod
  
  implicit none
  
#include "mpif.h"

  integer :: i, rc, myrank, numranks
  integer :: numargs
  character(len=4096) :: dbfile, clenv
  character(len=:), save, allocatable :: d4o_timeslot
  character(len=:), save, allocatable :: d4o_hdr
  character(len=:), save, allocatable :: d4o_body
  character(len=:), save, allocatable :: d4o_ens

  CALL MPI_Init(rc) ! Initialize MPI
  if (rc /= 0) call fd4o_exit('MPI_Init() failed',rc,1)

  CALL MPI_Comm_size(MPI_COMM_WORLD, numranks, rc) ! number of PEs
  if (rc /= 0) call fd4o_exit('MPI_Comm_size() failed',rc,1)
  
  CALL MPI_Comm_rank(MPI_COMM_WORLD, myrank, rc)   ! my PE-id, range from 0 to numranks-1
  if (rc /= 0) call fd4o_exit('MPI_Comm_rank() failed',rc,1)

  numargs = command_argument_count()

  if (numargs > 0) then
     !
     ! Determine potentially extra components to HDR and BODY queries
     !
     
     call get_environment_variable('d4o_timeslot',clenv)
     if (clenv /= '') then
        d4o_timeslot = " AND timeslot IN ("//trim(clenv)//")" ! f.ex. env d4o_timeslot="1,5,8" => " AND timeslot IN (1,5,8)"
     else
        d4o_timeslot = " AND 1" ! any timeslot will do
     endif

     call get_environment_variable('d4o_hdr',clenv)
     if (clenv /= '') then
        d4o_hdr = " AND ("//trim(clenv)//")" ! f.ex. env d4o_hdr="obstype = 2" => " AND (obstype = 2)"
     else
        d4o_hdr = " AND 1" ! any hdr will do
     endif
    
     call get_environment_variable('d4o_body',clenv)
     if (clenv /= '') then
        d4o_body = " AND ("//trim(clenv)//")" ! f.ex. env d4o_body="obsvalue < 273.15" => " AND (obsvalue < 273.15)"
     else
        d4o_body = " AND 1" ! any body will do
     endif

     call get_environment_variable('d4o_ens',clenv)
     if (clenv /= '') then
        d4o_ens = " AND ("//trim(clenv)//")" ! f.ex. env d4o_ens="member = 1" => " AND (member = 1)"
     else
        d4o_ens = " AND 1" ! any ens will do
     endif

     ! Read command line arguments that are OBS database files -- do NOT supply catalog dbs here
     ! Each PE picks up its "own" OBS database in a round-robin fashion i.e. in one-file-one-PE -basis

     do i = 1, numargs
        if (mod(i-1,numranks) == myrank) then
           call get_command_argument(i, dbfile)
           call do_screening(trim(dbfile)) ! do the actual screening here, by task == "myrank"
!          call do_redundancy(trim(dbfile)) ! do the actual screening here, by task == "myrank"
        endif
     enddo
  endif
  
  CALL MPI_Finalize(rc) ! Finalize MPI
  if (rc /= 0) call fd4o_exit('MPI_Finalize() failed',rc,1)

contains

  subroutine do_screening(dbfile)
    ! the actual screening
    
    implicit none
    character(len=*), intent(in) :: dbfile
    
    integer :: h, rc
    logical :: on_error
    character(len=:), allocatable :: sqlhdr, sqlbody, sql
    type(fd4o_obsdata_t),allocatable :: datahdr, databody
    integer, allocatable, dimension(:) :: idxhdr, idxbody
    integer :: jhdr, jbody, jflag
    real(8) :: id,timeslot,reportype,obstype,codetype,bufrtype,subtype,lat,lon,yyyymmdd,hhmmss,epoch,sat_id,sensor_id,sat_instr
    real(8) :: hdr_id,entryno,varno,kind,obsvalue,qc,vertco_type,levelht,obs_error_variance,fg_error_variance,channel,member,prior,rowid
    real(8) :: fg_depar,zlf,zright,zrh,oe,fge
    integer, allocatable, dimension(:) :: rejected_ens_rowids
    integer :: cnt, i, flag
    real(8), allocatable, dimension(:,:) :: buffer
    real(8), allocatable :: QC_U_T_H_Q(:),  QC_PS_Z(:),  SIGMA(:)
    real(8), parameter :: threshold = 0.1_8 ! i.e. "0.1" with real(8) precision
    logical :: passed

    allocate(QC_U_T_H_Q(3))
    allocate(QC_PS_Z(3))
    allocate(SIGMA(3))

!   FG Check SIGMA Multiplers

    QC_U_T_H_Q(1:3) = (/9.0_8,16.0_8,25.0_8/)
    QC_PS_Z(1:3)    = (/12.25_8,25.0_8,36.0_8/)
    SIGMA(1:3) = (/9.0_8,16.0_8,25.0_8/)

    !h = fd4o_opendb(trim(dbfile),"old",cascade=.FALSE.)

!   Open db

    h = fd4o_opendb(trim(dbfile),"old") ! "old" meaning: database MUST exist and will be updatable
    if (h < 0) then
       call fd4o_exit('fd4o_opendb("'//trim(dbfile)//'","old") failed -- does the dbfile exist ?',h,0) ! Don't fail
       return
    endif

    ! HDR-related items
    sqlhdr = "SELECT id,timeslot"//&
         & ",reportype,obstype,codetype,bufrtype,subtype"//&
         & ",lat,lon,yyyymmdd,hhmmss,epoch,sat_id,sensor_id,sat_instr"//&
         & " FROM hdr"//&
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " WHERE hdr.status = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & " ORDER BY id"

    ! BODY and ENS-related items
    ! Need to add fg_error
    ! Need to get db through DART to get fg (prior) values 
    ! Need to add sat obs_errors
    sqlbody= "SELECT id,entryno,varno,kind,obsvalue,qc"//&
         & ",vertco_type,levelht,obs_error_variance,channel"//&
         & ",member,prior,ens.rowid"//&
         & " FROM hdr"//&
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " JOIN body ON id = body.hdr_id"//&
         & " JOIN ens ON body.hdr_id = ens.hdr_id AND entryno = body_entryno"//&
         & " WHERE hdr.status = 1 AND body.status = 1 AND ens.status = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & d4o_body//&
         & d4o_ens//&
         & " ORDER BY id,entryno,member"
!   Get data
    on_error = .FALSE.
    write(fd4o_debug_io,*) 'Drasko Run'
!   Get hdr info
    datahdr  = fd4o_getdb(h,sqlhdr,err=rc,rowmajor=.FALSE.)
    write(fd4o_debug_io,*) 'fd4o_getdb(sqlhdr): rc,datahdr%nrows = ',rc,datahdr%nrows
    on_error = on_error .or. (rc < 0)
!   Get body info
    databody = fd4o_getdb(h,sqlbody,err=rc,rowmajor=.FALSE.)
    write(fd4o_debug_io,*) 'fd4o_getdb(sqlbody): rc,databody%nrows = ',rc,databody%nrows
    on_error = on_error .or. (rc < 0)

    if (on_error .or. .not.(datahdr%nrows > 0 .and. databody%nrows > 0)) goto 9999

    allocate(idxhdr(datahdr%ncols))
    idxhdr(1)  = fd4o_colidx(datahdr%qh,"id")
    idxhdr(2)  = fd4o_colidx(datahdr%qh,"timeslot")
    idxhdr(3)  = fd4o_colidx(datahdr%qh,"reportype")
    idxhdr(4)  = fd4o_colidx(datahdr%qh,"obstype")
    idxhdr(5)  = fd4o_colidx(datahdr%qh,"codetype")
    idxhdr(6)  = fd4o_colidx(datahdr%qh,"bufrtype")
    idxhdr(7)  = fd4o_colidx(datahdr%qh,"subtype")
    idxhdr(8)  = fd4o_colidx(datahdr%qh,"lat") ! radians -pi/2 .. +pi/2 ; fetch "deglat" if you want in degrees -90..+90
    idxhdr(9)  = fd4o_colidx(datahdr%qh,"lon") ! radians -pi .. +pi; fetch "deglon" if you want in degrees -180..+180
    idxhdr(10) = fd4o_colidx(datahdr%qh,"yyyymmdd")
    idxhdr(11) = fd4o_colidx(datahdr%qh,"hhmmss")
    idxhdr(12) = fd4o_colidx(datahdr%qh,"epoch") ! (linear) time in seconds since 1.1.1970 ("Unix 'birth' date)
    idxhdr(13) = fd4o_colidx(datahdr%qh,"sat_id") ! NULL if not satellite obs
    idxhdr(14) = fd4o_colidx(datahdr%qh,"sensor_id")
    idxhdr(15) = fd4o_colidx(datahdr%qh,"sat_instr")

    allocate(idxbody(databody%ncols))
    idxbody(1)  = fd4o_colidx(databody%qh,"id") ! aka body.hdr_id
    idxbody(2)  = fd4o_colidx(databody%qh,"entryno")
    idxbody(3)  = fd4o_colidx(databody%qh,"varno")
    idxbody(4)  = fd4o_colidx(databody%qh,"kind")
    idxbody(5)  = fd4o_colidx(databody%qh,"obsvalue")
    idxbody(6)  = fd4o_colidx(databody%qh,"qc")
    idxbody(7)  = fd4o_colidx(databody%qh,"vertco_type")
    idxbody(8)  = fd4o_colidx(databody%qh,"levelht")
    idxbody(9)  = fd4o_colidx(databody%qh,"obs_error_variance")
    idxbody(10) = fd4o_colidx(databody%qh,"channel")
    idxbody(11) = fd4o_colidx(databody%qh,"member")
    idxbody(12) = fd4o_colidx(databody%qh,"prior")
    idxbody(13) = fd4o_colidx(databody%qh,"ens.rowid")

    allocate(rejected_ens_rowids(databody%nrows))
    rejected_ens_rowids(:) = 0 ! When any of these > 0, then the ens.rowid will be marked as rejected
    
    jbody = 0
!   write(fd4o_debug_io,*) 'hdrloop: id, timeslot, obstype, codetype, lat, lon,yyyymmdd, hhmmss'
    hdrloop: do jhdr=1,datahdr%nrows ! hdr entries
       id        = datahdr%d(idxhdr(1),jhdr)
       timeslot  = datahdr%d(idxhdr(2),jhdr)
       reportype = datahdr%d(idxhdr(3),jhdr)
       obstype   = datahdr%d(idxhdr(4),jhdr)
       codetype  = datahdr%d(idxhdr(5),jhdr)
       bufrtype  = datahdr%d(idxhdr(6),jhdr)
       subtype   = datahdr%d(idxhdr(7),jhdr)
       lat       = datahdr%d(idxhdr(8),jhdr)
       lon       = datahdr%d(idxhdr(9),jhdr)
       yyyymmdd  = datahdr%d(idxhdr(10),jhdr)
       hhmmss    = datahdr%d(idxhdr(11),jhdr)
       epoch     = datahdr%d(idxhdr(12),jhdr)
       sat_id    = datahdr%d(idxhdr(13),jhdr)
       sensor_id = datahdr%d(idxhdr(14),jhdr)
       sat_instr = datahdr%d(idxhdr(15),jhdr)
!      write(fd4o_debug_io,*) id, timeslot, obstype, codetype, lat, lon,yyyymmdd, hhmmss
!      if(varno/=2) then
!         write(fd4o_debug_io,*)  'bodyloop: entryno, varno, obsvalue, qc, vertco_type, lelvht, obs_err_variance, fg_err_variance,member, prior, rowid'
!      endif

       bodyloop: do while (jbody < databody%nrows) ! body entries
          hdr_id = databody%d(idxbody(1),jbody+1)
          if (hdr_id /= id) exit bodyloop
          jbody = jbody + 1
          
          entryno = databody%d(idxbody(2),jbody)
          varno = databody%d(idxbody(3),jbody)
          kind = databody%d(idxbody(4),jbody)
          obsvalue = databody%d(idxbody(5),jbody)
          qc = databody%d(idxbody(6),jbody)        ! What is this?
          vertco_type = databody%d(idxbody(7),jbody)
          levelht = databody%d(idxbody(8),jbody)
          obs_error_variance = databody%d(idxbody(9),jbody)

!         Temporary Setup For FG Error

          fg_error_variance = obs_error_variance

          channel = databody%d(idxbody(10),jbody)
          member = databody%d(idxbody(11),jbody) ! ensemble member number
          prior = databody%d(idxbody(12),jbody)

!         Temporary Setup For FG Values

          if(varno == 2) prior = obsvalue+10._8
          if(varno == 3) prior = obsvalue+10._8
          if(varno == 4) prior = obsvalue+10._8

          rowid = databody%d(idxbody(13),jbody)

!         write(fd4o_debug_io,*)  entryno, varno, obsvalue, qc, vertco_type, levelht, obs_error_variance, fg_error_variance, member, prior, rowid

!         Preset Switch and Flag

          passed = .TRUE.
          flag   = 0

!       Check if anything missing

          if (.not.bg_check(obsvalue,prior,obs_error_variance,fg_error_variance)) then
            write(fd4o_debug_io,*) 'doscreening; Reject; Something missing', obsvalue,prior,obs_error_variance,fg_error_variance
            rejected_ens_rowids(jbody) = rowid ! this rowid gets rejected i.e. ens.status will be set 0
          else
!       FG Check Flag 
            flagloop: do jflag = 1,3
!       Temperature Sigma Multiplier
              if(varno==2) then
                SIGMA(jflag)=QC_U_T_H_Q(jflag)
!       U Wind Component Sigma Multiplier
              elseif (varno==3) then
                SIGMA(jflag)=QC_U_T_H_Q(jflag)
!       V Wind Component Sigma Multiplier
              elseif (varno==4) then
                SIGMA(jflag)=QC_U_T_H_Q(jflag)
!       Pressure Sigma Multiplier
              elseif (varno==110) then
                SIGMA(jflag)=QC_PS_Z   (jflag)
!       Geopotential Sigma Multiplier
              elseif (varno==1) then
                SIGMA(jflag)=QC_PS_Z   (jflag)
              endif

!       First guess check (ECMWF style)

              fg_depar = abs(obsvalue - prior)
              zlf      = fg_depar*fg_depar
              zright   = obs_error_variance*obs_error_variance + fg_error_variance*fg_error_variance
              zrh      = zright*sigma(jflag)
              if (zlf >= zrh ) then
                flag = jflag
              endif
!           write(fd4o_debug_io,*) 'test',jflag,flag,zlf,zright,sigma,zrh,varno,obsvalue,prior,fg_depar,obs_error_variance,fg_error_variance,rejected_ens_rowids(jbody)
            enddo flagloop
          endif
!         write(fd4o_debug_io,*) 'doscreening; Obs current status should be 0', rejected_ens_rowids(jbody)
          if(flag == 3) then
            rejected_ens_rowids(jbody) = rowid ! this rowid gets rejected i.e. ens.status will be set 0
            write(fd4o_debug_io,*) 'doscreening; Rejected summary, status to be changed to 1',flag,varno,obsvalue,prior,fg_depar,obs_error_variance,fg_error_variance,rejected_ens_rowids(jbody)
          else
            if(flag == 2) then
              write(fd4o_debug_io,*) 'doscreening; Passed (probably incorrect) summary',flag,varno,obsvalue,prior,fg_depar,obs_error_variance,fg_error_variance,rejected_ens_rowids(jbody)
            endif
            if(flag == 1) then
              write(fd4o_debug_io,*) 'doscreening; Passed (probably correct) summary',flag,varno,obsvalue,prior,fg_depar,obs_error_variance,fg_error_variance,rejected_ens_rowids(jbody)
            endif
            if(flag == 0) then
              write(fd4o_debug_io,*) 'doscreening; Passed (correct) summary',flag,varno,obsvalue,prior,fg_depar,obs_error_variance,fg_error_variance,rejected_ens_rowids(jbody)
            endif
          endif
       enddo bodyloop
    enddo hdrloop

    rc = fd4o_delete(datahdr)
    rc = fd4o_delete(databody)
    
    cnt = count(rejected_ens_rowids(:) > 0)
    write(fd4o_debug_io,*) 'number of rejected entries = ',cnt,' out of ',size(rejected_ens_rowids)
    if (cnt > 0) then
       ! update database : ens.status flag must be set to 0 when rejected_ens_rowids(i) > 0
       sql = "UPDATE ens SET status = 0 WHERE rowid = ?1"
       allocate(buffer(1,cnt))
       i = 0
       do jbody=1,size(rejected_ens_rowids)
          rowid = rejected_ens_rowids(jbody)
          if (rowid > 0) then
             i = i + 1
             buffer(1,i) = rowid ! buffer index (1,:) relates to ?1
          endif
       enddo

       rc = fd4o_putdb(h,buffer,rowmajor=.FALSE.,query=sql)

       if (rc /= cnt) call fd4o_exit('fd4o_putdb() of "'//trim(dbfile)//'" failed',rc,0) ! Don't fail
    endif

9999 continue
    rc = fd4o_closedb(h)
    if (rc /= 0) call fd4o_exit('fd4o_closedb() of "'//trim(dbfile)//'" failed',rc,0) ! Don't fail
  end subroutine do_screening

  function bg_check(obsvalue,prior,oe,fge) result(passed)
    implicit none
    real(8), intent(in) :: obsvalue,prior,oe,fge
    real(8) :: fg_depar,zleft,zright,zrh,zlf
    real(8), parameter :: threshold = 0.1_8 ! i.e. "0.1" with real(8) precision
    logical :: passed
    passed = .true.
    if (fd4o_is_null(obsvalue) .or. fd4o_is_null(prior) .or. fd4o_is_null(oe) .or. fd4o_is_null(fge)) then
       passed = .FALSE.
!   else
!      fg_depar = abs(obsvalue - prior)
!      zlf      = fg_depar*fg_depar
!      zright   = oe*oe + fge*fge
!      zrh      = zright*sigma
       
!      passed = (fg_depar < threshold)
!      passed = (zlf < zrh)
    endif
!   write(fd4o_debug_io,*) 'bg_check;',passed
  end function bg_check
  
END PROGRAM Screening
