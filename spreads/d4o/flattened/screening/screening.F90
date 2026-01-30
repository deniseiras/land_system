PROGRAM Screening

  ! Usage : [mpirun -np <npes>] ./prescreening.x d4o-database-file(s)  ! before [or after] d4osplit of phase-1
  ! Usage : [mpirun -np <npes>] ./postscreening.x d4o-database-file(s) ! after d4ojoin of phase-1 (and before phase-2)

  use parkind
  use fd4o_mod, only : &
       & dio => fd4o_debug_io &
       &,fd4o_text &
       &,fd4o_null &
       &,fd4o_is_null &
       &,fd4o_exit &
       &,fd4o_opendb &
       &,fd4o_getdb &
       &,fd4o_putdb &
       &,fd4o_closedb &
       &,fd4o_delete &
       &,fd4o_colidx &
       &,fd4o_obsdata_t &
       &,fd4o_int8
  use blmod
  use status_bits, only : clrbits

  implicit none

#include "mpif.h"

  integer :: i, rc, myrank, numranks
  integer :: numargs, iostat
  character(len=4096) :: dbfile, clenv, exefile
  character(len=:), save, allocatable :: d4o_timeslot
  character(len=:), save, allocatable :: d4o_hdr
  character(len=:), save, allocatable :: d4o_body
  character(len=:), save, allocatable :: d4o_ens
  logical :: is_post, do_bl, is_verbose, do_something
  integer :: numens ! max num ens members to consider (default = all if d4o_ens_size is not defined)

  CALL MPI_Init(rc) ! Initialize MPI
  if (rc /= 0) call fd4o_exit('MPI_Init() failed',rc,1)

  CALL MPI_Comm_size(MPI_COMM_WORLD, numranks, rc) ! number of PEs
  if (rc /= 0) call fd4o_exit('MPI_Comm_size() failed',rc,1)

  CALL MPI_Comm_rank(MPI_COMM_WORLD, myrank, rc)   ! my PE-id, range from 0 to numranks-1
  if (rc /= 0) call fd4o_exit('MPI_Comm_rank() failed',rc,1)
  is_verbose = (myrank == 0) ! only rank#0 shouts out loud

  numargs = command_argument_count()

  call get_command_argument(0,exefile)
  is_post = (index(trim(exefile),'postscreening') > 0)

  if (is_verbose) then
     if (is_post) then
        write(dio,*) trim(exefile)//': this is the POST-screening (with prior and thus fg_depar)'
     else
        write(dio,*) trim(exefile)//': this is the PRE-screening (before prior was calculated)'
     endif
  endif

  ! We only perform blacklisting & screening up to numargs-tasks
  ! So if numargs < numranks, then only tasks 0..numargs-1 need to participate
  
  do_something = (myrank < numargs)

  if (do_something) then
     call blinit(rc,LDVERBOSE=is_verbose)
     do_bl = (rc == 0)
     if (is_verbose) write(dio,*) 'after call blinit : rc=',rc,', do_bl=',do_bl,', is_post=',is_post
  endif
  
  if (do_something .and. numargs > 0) then
     !
     ! Determine potentially extra components to HDR and BODY queries
     !

     call get_environment_variable('d4o_timeslot',clenv)
     if (clenv /= ' ') then
        d4o_timeslot = " AND timeslot IN ("//trim(clenv)//")" ! f.ex. env d4o_timeslot="1,5,8" => " AND timeslot IN (1,5,8)"
     else
        d4o_timeslot = " AND 1" ! any timeslot will do
     endif

     call get_environment_variable('d4o_hdr',clenv)
     if (clenv /= ' ') then
        d4o_hdr = " AND ("//trim(clenv)//")" ! f.ex. env d4o_hdr="obstype = 2" => " AND (obstype = 2)"
     else
        d4o_hdr = " AND 1" ! any hdr will do
     endif

     call get_environment_variable('d4o_body',clenv)
     if (clenv /= ' ') then
        d4o_body = " AND ("//trim(clenv)//")" ! f.ex. env d4o_body="obsvalue < 273.15" => " AND (obsvalue < 273.15)"
     else
        d4o_body = " AND 1" ! any body will do
     endif

     call get_environment_variable('d4o_ens_size',clenv) ! sets the max member number to consider
     if (clenv /= ' ') then
        read(clenv,*,iostat=iostat) numens
        if (iostat /= 0) then
           clenv = ' '
           numens = -1
        endif
     else
        numens = -1
     endif

     if (numens > 0) then
        d4o_ens = " AND member <=           "
        write(d4o_ens,'(a,i0)') " AND member <= ",numens
        d4o_ens = trim(d4o_ens)
     else
        d4o_ens = " AND 1" ! any ens will do
     endif
     
     ! Read command line arguments that are OBS database files -- do NOT supply catalog dbs here
     ! Each PE picks up its "own" OBS database in a round-robin fashion i.e. in one-file-one-PE -basis

     do i = 1, numargs
        if (mod(i-1,numranks) == myrank) then
           call get_command_argument(i, dbfile)
           call do_screening(trim(dbfile),is_post,do_bl) ! do the actual screening here, by task == "myrank"
           !call do_redundancy(trim(dbfile)) ! do the actual screening here, by task == "myrank"
        endif
     enddo
  endif

  write(dio,'(1x,a,i0,a)') trim(exefile)//': finishing up task#',myrank,' ...'
  
  CALL MPI_Barrier(MPI_COMM_WORLD,rc)
  
  CALL MPI_Finalize(rc) ! Finalize MPI
  if (rc /= 0) call fd4o_exit('MPI_Finalize() failed',errcode=rc,do_exit=1) ! DO fail

contains

  subroutine do_screening(dbfile,is_post,do_bl)
    ! the actual screening

    use ecmwf_varno_descr, only : z,t,u,v,ps
    
    implicit none
    character(len=*), intent(in) :: dbfile
    logical, intent(in) :: is_post, do_bl

    integer :: h, rc
    logical :: on_error
    character(len=:), allocatable :: sqlsb, sqlhdr, sqlbody, sql
    type(fd4o_obsdata_t),allocatable :: datasb, datahdr, databody
    integer, allocatable, dimension(:) :: idxhdr, idxbody
    integer :: jsb, jhdr, jbody, jflag
    real(jprd) :: id,timeslot,reportype,obstype,codetype,bufrtype,subtype,deglat,deglon,yyyymmdd,hhmmss,epoch,sat_id,sensor_id,sat_instr
    real(jprd) :: hdr_id,entryno,varno,kind,obsvalue,qc,dart_qc,which_vert,levelht,obs_error,channel,member,prior,press
    real(jprd) :: fg_depar,zlf,zright,zrh,oe,fge,raw_statid,raw_sbname
    integer :: hdr_status, body_status, ens_status
    integer :: hdr_rowid, body_rowid, ens_rowid
    real(jprd) :: nandat,nantim,phase
    CHARACTER(LEN=:), allocatable :: statid, sbname
    integer(jpib) :: istat
    integer, allocatable, dimension(:) :: rejected_hdr_rowids
    integer(jpib), allocatable, dimension(:) :: blacklisted_hdr_status
    integer, allocatable, dimension(:) :: rejected_body_rowids
    integer(jpib), allocatable, dimension(:) :: blacklisted_body_status
    integer, allocatable, dimension(:) :: rejected_ens_rowids
    integer(jpib), allocatable, dimension(:) :: blacklisted_ens_status
    integer :: cnt, numbl, i, flag, bitno
    real(jprd), allocatable, dimension(:,:) :: buffer
    logical :: skip_bodylooping
    integer :: ncols_sb, ncols_hdr, ncols_body
    integer :: nrows_sb, nrows_hdr, nrows_body
    !   FG Check SIGMA Multiplers
    real(jprd), dimension(3), parameter :: QC_U_T_H_Q = [9.0_8, 16.0_8, 25.0_8]
    real(jprd), dimension(3), parameter :: QC_PS_Z    = [12.25_8, 25.0_8, 36.0_8]
    real(jprd), dimension(3)            :: SIGMA
    !*** Dynamic status bits ***
    integer sb_active,sb_blacklisted
    !  hdr & sat-tables                                                                                                                                                                                                   
    integer :: sb_hdr_statid,sb_hdr_obstype,sb_hdr_codetype,sb_hdr_reportype,sb_hdr_bufrtype,sb_hdr_subtype
    integer :: sb_hdr_yyyymmdd,sb_hdr_hhmmss,sb_hdr_deglat,sb_hdr_deglon
    integer :: sb_sat_sat_instr,sb_sat_sensor_id,sb_sat_sat_id
    !  body & ens-tables                                                                                                                                                                                                  
    integer :: sb_body_varno,sb_body_kind,sb_body_obsvalue,sb_body_qc,sb_body_dart_qc,sb_body_which_vert,sb_body_obs_error
    integer :: sb_body_levelht,sb_body_channel,sb_body_press
    integer :: sb_ens_member,sb_ens_fg_depar
    logical :: LLdo_bl, LLdebug_print

    !   Open db

    h = fd4o_opendb(trim(dbfile),"old") ! "old" meaning: database MUST exist and will be updatable
    if (h < 0) then
       call fd4o_exit('fd4o_opendb("'//trim(dbfile)//'","old") failed -- does the dbfile exist ?',errcode=h,do_exit=0) ! Don't fail
       return
    endif

    LLdo_bl = do_bl
    
    nandat = get_nandat()
    nantim = get_nantim()

    if (is_post) then
       phase = 2
    else
       phase = 1 
    endif

    if (is_verbose) then
       write(dio,'(1x,a,i8.8)') 'nandat=',int(nandat,jpim)
       write(dio,'(1x,a,i8.6)') 'nantim=',int(nantim,jpim)
       write(dio,'(1x,a,i8  )') ' phase=',int(phase,jpim)
    endif
    
    !*** Dynamic status bits ***
    ! initialize
    sb_active=-1;sb_blacklisted=-1
    sb_hdr_statid=-1;sb_hdr_obstype=-1;sb_hdr_codetype=-1;sb_hdr_reportype=-1;sb_hdr_bufrtype=-1;sb_hdr_subtype=-1
    sb_hdr_yyyymmdd=-1;sb_hdr_hhmmss=-1;sb_hdr_deglat=-1;sb_hdr_deglon=-1
    sb_sat_sat_instr=-1;sb_sat_sensor_id=-1;sb_sat_sat_id=-1
    sb_body_varno=-1;sb_body_kind=-1;sb_body_obsvalue=-1;sb_body_qc=-1;sb_body_dart_qc=-1;sb_body_which_vert=-1;sb_body_obs_error=-1
    sb_body_levelht=-1;sb_body_channel=-1;sb_body_press=-1
    sb_ens_member=-1;sb_ens_fg_depar=-1
    ! only needed when blacklisting i.e. LLdo_bl is .TRUE.
    if (LLdo_bl) then
       sqlsb = "SELECT name,bitno FROM status_bits ORDER BY bitno"
       if (is_verbose) then
          write(dio,*) 'sqlsb='
          write(dio,*)  sqlsb
       endif
       ! process data
       datasb = fd4o_getdb(h,sqlsb,err=rc,rowmajor=.FALSE.)
       if (is_verbose .or. rc < 0) write(dio,*) 'do_screening: fd4o_getdb(sqlsb): rc,datasb%nrows,datasb%ncols = ',rc,datasb%nrows,datasb%ncols
       if (rc >= 0) then
          ncols_sb = datasb%ncols
          nrows_sb = datasb%nrows
          if (ncols_sb >= 2 .and. nrows_sb > 0) then ! num columns ok and at least one row fetched
             call bldyna(datasb%d,LDVERBOSE=is_verbose)
             
             do jsb=1,nrows_sb
                raw_sbname = datasb%d(1,jsb)
                sbname = fd4o_text(raw_sbname) ! note: a character string here
                bitno = datasb%d(2,jsb)

                select case (sbname)
                case('active')
                   sb_active=bitno
                case('blacklisted')
                   sb_blacklisted=bitno
                   
                case('hdr.statid')
                   sb_hdr_statid=bitno
                case('hdr.obstype')
                   sb_hdr_obstype=bitno
                case('hdr.codetype')
                   sb_hdr_codetype=bitno
                case('hdr.reportype')
                   sb_hdr_reportype=bitno
                case('hdr.bufrtype')
                   sb_hdr_bufrtype=bitno
                case('hdr.subtype')
                   sb_hdr_subtype=bitno
                case('hdr.yyyymmdd')
                   sb_hdr_yyyymmdd=bitno
                case('hdr.hhmmss')
                   sb_hdr_hhmmss=bitno
                case('hdr.deglat')
                   sb_hdr_deglat=bitno
                case('hdr.deglon')
                   sb_hdr_deglon=bitno
                   
                case('sat.sat_instr')
                   sb_sat_sat_instr=bitno
                case('sat.sensor_id')
                   sb_sat_sensor_id=bitno
                case('sat.sat_id')
                   sb_sat_sat_id=bitno
                   
                case('body.varno')
                   sb_body_varno=bitno
                case('body.kind')
                   sb_body_kind=bitno
                case('body.obsvalue')
                   sb_body_obsvalue=bitno
                case('body.qc')
                   sb_body_qc=bitno
                case('body.dart_qc')
                   sb_body_dart_qc=bitno
                case('body.which_vert')
                   sb_body_which_vert=bitno
                case('body.obs_error')
                   sb_body_obs_error=bitno
                case('body.levelht')
                   sb_body_levelht=bitno
                case('body.channel')
                   sb_body_channel=bitno
                case('body.press')
                   sb_body_press=bitno
                    
                case('ens.member')
                   sb_ens_member=bitno
                case('ens.fg_depar')
                   sb_ens_fg_depar=bitno

#if 0
! future defs (currently not in tentative Blacklist.txt)
                case('body.height')
                   sb_body_height=bitno
                case('body.obs_error_variance')
                   sb_body_obs_error_variance=bitno
                case('body.ppcode')
                   sb_body_ppcode=bitno
                case('body.vertco_type')
                   sb_body_vertco_type=bitno
                case('hdr.epoch')
                   sb_hdr_epoch=bitno
                case('hdr.geoarea')
                   sb_hdr_geoarea=bitno
                case('hdr.group_id')
                   sb_hdr_group_id=bitno
                case('hdr.nbody')
                   sb_hdr_nbody=bitno
                case('hdr.stalt')
                   sb_hdr_stalt=bitno
                case('hdr.timeslot')
                   sb_hdr_timeslot=bitno
                case('problematic')
                   sb_problematic=bitno
                case('sat.azimuth')
                   sb_sat_azimuth=bitno
                case('sat.platform_id')
                   sb_sat_platform_id=bitno
                case('sat.rttov_sat_id')
                   sb_sat_rttov_sat_id=bitno
                case('sat.rttov_sensor_id')
                   sb_sat_rttov_sensor_id=bitno
                case('sat.scanpos')
                   sb_sat_scanpos=bitno
                case('sat.solar_azimuth')
                   sb_sat_solar_azimuth=bitno
                case('sat.solar_zenith')
                   sb_sat_solar_zenith=bitno
                case('sat.zenith')
                   sb_sat_zenith=bitno
                case('thinned')
                   sb_thinned=bitno
#endif
                case default
                   write(dio,*) 'Warning: Currently unsupported status bit "'//sbname//'", bitno=',bitno
                end select
             enddo
             deallocate(sbname)
          else
             LLdo_bl = .FALSE. ! blacklisting turned off
          endif
       else
          LLdo_bl = .FALSE. ! blacklisting turned off
       endif
       rc = fd4o_delete(datasb)
    endif
    if (.not. LLdo_bl) sb_active = 0 ! due to potential calls to clrbits
    if (is_verbose) write(dio,*) 'Now do_bl=',LLdo_bl
    
    ! HDR and SAT-related items
    sqlhdr = "SELECT id,timeslot,statid"//&
         & ",reportype,obstype,codetype,bufrtype,subtype"//&
         & ",deglat,deglon,yyyymmdd,hhmmss,epoch,sat_id,sensor_id,sat_instr"//&
         & ",hdr.status FROM hdr"//& ! for coding convenience put hdr.status last
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " WHERE hdr.status & 1 = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & " ORDER BY id"

    if (is_verbose) then
       write(dio,*) 'sqlhdr='
       write(dio,*)  sqlhdr
    endif

    if (is_post) then 
       ! BODY and ENS-related items (when prior is present i.e. postscreening (after phase-1))
       sqlbody= "SELECT id,entryno,varno,kind,obsvalue,qc,dart_qc"//&
            & ",which_vert,levelht,obs_error,channel,press"//&
            & ",member,prior"//&
            & ",ens.rowid,ens.status FROM hdr"//&
            & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
            & " JOIN body ON id = body.hdr_id"//&
            & " JOIN ens ON body.hdr_id = ens.hdr_id AND entryno = body_entryno"//&
            & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1 AND ens.status & 1 = 1"//&
            & d4o_timeslot//&
            & d4o_hdr//&
            & d4o_body//&
            & d4o_ens//&
            & " ORDER BY id,entryno,member"
    else ! prescreening i.e. before phase-1 -- no prior data present, thus blacklisting potentially only the body-data
       ! BODY
       sqlbody= "SELECT id,entryno,varno,kind,obsvalue,qc,dart_qc"//&
            & ",which_vert,levelht,obs_error,channel,press"//&
            & ",body.rowid,body.status FROM hdr"//&
            & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
            & " JOIN body ON id = body.hdr_id"//&
            & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1"//&
            & d4o_timeslot//&
            & d4o_hdr//&
            & d4o_body//&
            & " ORDER BY id,entryno"
    endif
    
    if (is_verbose) then
       write(dio,*) 'sqlbody='
       write(dio,*)  sqlbody
    endif
    
    !   Get data
    on_error = .FALSE.

    !   Get hdr data
    datahdr  = fd4o_getdb(h,sqlhdr,err=rc,rowmajor=.FALSE.)
    if (is_verbose .or. rc < 0) write(dio,*) 'do_screening: fd4o_getdb(sqlhdr): rc,datahdr%nrows,datahdr%ncols = ',rc,datahdr%nrows,datahdr%ncols
    on_error = on_error .or. (rc < 0)
    
    !   Get body data
    databody = fd4o_getdb(h,sqlbody,err=rc,rowmajor=.FALSE.)
    if (is_verbose .or. rc < 0) write(dio,*) 'do_screening: fd4o_getdb(sqlbody): rc,databody%nrows,databody%ncols = ',rc,databody%nrows,databody%ncols
    on_error = on_error .or. (rc < 0)

    if (on_error .or. .not.(datahdr%nrows > 0 .and. databody%nrows > 0)) goto 9999

    ncols_hdr = datahdr%ncols
    nrows_hdr = datahdr%nrows

    allocate(idxhdr(ncols_hdr))
    idxhdr(1)  = fd4o_colidx(datahdr%qh,"id")
    idxhdr(2)  = fd4o_colidx(datahdr%qh,"timeslot")
    idxhdr(3)  = fd4o_colidx(datahdr%qh,"reportype")
    idxhdr(4)  = fd4o_colidx(datahdr%qh,"obstype")
    idxhdr(5)  = fd4o_colidx(datahdr%qh,"codetype")
    idxhdr(6)  = fd4o_colidx(datahdr%qh,"bufrtype")
    idxhdr(7)  = fd4o_colidx(datahdr%qh,"subtype")
    idxhdr(8)  = fd4o_colidx(datahdr%qh,"deglat") ! radians -pi/2 .. +pi/2 ; fetch "deglat" if you want in degrees -90..+90
    idxhdr(9)  = fd4o_colidx(datahdr%qh,"deglon") ! radians -pi .. +pi; fetch "deglon" if you want in degrees -180..+180
    idxhdr(10) = fd4o_colidx(datahdr%qh,"yyyymmdd")
    idxhdr(11) = fd4o_colidx(datahdr%qh,"hhmmss")
    idxhdr(12) = fd4o_colidx(datahdr%qh,"epoch") ! (linear) time in seconds since 1.1.1970 ("Unix 'birth' date)
    idxhdr(13) = fd4o_colidx(datahdr%qh,"sat_id") ! NULL if not satellite obs
    idxhdr(14) = fd4o_colidx(datahdr%qh,"sensor_id")
    idxhdr(15) = fd4o_colidx(datahdr%qh,"sat_instr")
    idxhdr(16) = fd4o_colidx(datahdr%qh,"statid")
    idxhdr(ncols_hdr) = fd4o_colidx(datahdr%qh,"hdr.status")

    allocate(rejected_hdr_rowids(nrows_hdr))
    rejected_hdr_rowids(:) = 0 ! When any of these are not 0, then the hdr.rowid will be marked as rejected and/or blacklisted
    allocate(blacklisted_hdr_status(nrows_hdr))
    blacklisted_hdr_status(:) = 0 ! Shall contain possibly updated hdr.status

    ncols_body = databody%ncols
    nrows_body = databody%nrows

    allocate(idxbody(ncols_body))
    idxbody(1)  = fd4o_colidx(databody%qh,"id") ! aka body.hdr_id
    idxbody(2)  = fd4o_colidx(databody%qh,"entryno")
    idxbody(3)  = fd4o_colidx(databody%qh,"varno")
    idxbody(4)  = fd4o_colidx(databody%qh,"kind")
    idxbody(5)  = fd4o_colidx(databody%qh,"obsvalue")
    idxbody(6)  = fd4o_colidx(databody%qh,"qc")
    idxbody(7)  = fd4o_colidx(databody%qh,"dart_qc")
    idxbody(8)  = fd4o_colidx(databody%qh,"which_vert")
    idxbody(9)  = fd4o_colidx(databody%qh,"levelht")
    idxbody(10) = fd4o_colidx(databody%qh,"obs_error")
    idxbody(11) = fd4o_colidx(databody%qh,"channel")
    idxbody(12) = fd4o_colidx(databody%qh,"press")
    if (is_post) then
       idxbody(13) = fd4o_colidx(databody%qh,"member")
       idxbody(14) = fd4o_colidx(databody%qh,"prior")
       idxbody(ncols_body-1) = fd4o_colidx(databody%qh,"ens.rowid")
       idxbody(ncols_body  ) = fd4o_colidx(databody%qh,"ens.status")
    else
       idxbody(ncols_body-1) = fd4o_colidx(databody%qh,"body.rowid")
       idxbody(ncols_body  ) = fd4o_colidx(databody%qh,"body.status")
    endif

    if (is_post) then
       allocate(rejected_ens_rowids(nrows_body))
       rejected_ens_rowids(:) = 0 ! When any of these are not 0, then the ens.rowid will be marked as rejected and/or blacklisted
       allocate(blacklisted_ens_status(nrows_body))
       blacklisted_ens_status(:) = 0 ! Shall contain possibly updated ens.status
    else
       allocate(rejected_body_rowids(nrows_body))
       rejected_body_rowids(:) = 0 ! When any of these are not 0, then the body.rowid will be marked as rejected and/or blacklisted
       allocate(blacklisted_body_status(nrows_body))
       blacklisted_body_status(:) = 0 ! Shall contain possibly updated body.status
    endif

    jbody = 0
    hdrloop: do jhdr=1,nrows_hdr ! hdr entries
       id        = datahdr%d(idxhdr(1),jhdr)
       timeslot  = datahdr%d(idxhdr(2),jhdr)
       reportype = datahdr%d(idxhdr(3),jhdr)
       obstype   = datahdr%d(idxhdr(4),jhdr)
       codetype  = datahdr%d(idxhdr(5),jhdr)
       bufrtype  = datahdr%d(idxhdr(6),jhdr)
       subtype   = datahdr%d(idxhdr(7),jhdr)
       deglat    = datahdr%d(idxhdr(8),jhdr)
       deglon    = datahdr%d(idxhdr(9),jhdr)
       yyyymmdd  = datahdr%d(idxhdr(10),jhdr)
       hhmmss    = datahdr%d(idxhdr(11),jhdr)
       epoch     = datahdr%d(idxhdr(12),jhdr)
       sat_id    = datahdr%d(idxhdr(13),jhdr)
       sensor_id = datahdr%d(idxhdr(14),jhdr)
       sat_instr = datahdr%d(idxhdr(15),jhdr)
       raw_statid = datahdr%d(idxhdr(16),jhdr)
       statid = fd4o_text(raw_statid) ! note: a character string here
       hdr_status = fd4o_int8(datahdr%d(idxhdr(ncols_hdr),jhdr))

       hdr_rowid = id ! in fact hdr.rowid
       
       skip_bodylooping = .FALSE.
       if (LLdo_bl) then
          ! Call blacklisting for HDR entries not rejected so far
          blacklisted_hdr_status(jhdr) = hdr_status
          istat = blacklisted_hdr_status(jhdr)
          LLdebug_print = is_verbose .and. (jhdr == 1 .or. jhdr == nrows_hdr/2 .or. jhdr == nrows_hdr)
          if (LLdebug_print) write(dio,'(1x,a,i0,a,i0,a)') 'Checking against blacklisting (hdr.status), row#',jhdr,'/',nrows_hdr,' ...'
          call bllist('hdr.status',.TRUE.,  & ! hdr & sat blacklisting
               &   istat,      & ! istat => blacklisted_hdr_status(jhdr)
               &   sb_active, sb_blacklisted, &
               & [ nandat,nantim,phase &
               !  hdr & sat-tables
               &  ,raw_statid,obstype,codetype,reportype,bufrtype,subtype &
               &  ,yyyymmdd,hhmmss,deglat,deglon &
               &  ,sat_instr,sensor_id,sat_id &
               !  body & ens-tables values NOT supplied purposely
               & ], &
               & [ -1, -1,-1 &
               &  ,sb_hdr_statid,sb_hdr_obstype,sb_hdr_codetype,sb_hdr_reportype,sb_hdr_bufrtype,sb_hdr_subtype &
               &  ,sb_hdr_yyyymmdd,sb_hdr_hhmmss,sb_hdr_deglat,sb_hdr_deglon &
               &  ,sb_sat_sat_instr,sb_sat_sensor_id,sb_sat_sat_id &
               & ], debug_print = LLdebug_print)
          if (blacklisted_hdr_status(jhdr) /= istat) then
             blacklisted_hdr_status(jhdr) = istat
             rejected_hdr_rowids(jhdr) = -hdr_rowid ! negative number indicates that the HDR rowid was blacklisted
             skip_bodylooping = .TRUE.
          endif
       endif
       
       bodyloop: do while (jbody < nrows_body) ! body entries
          hdr_id = databody%d(idxbody(1),jbody+1)
          if (hdr_id /= id) exit bodyloop
          jbody = jbody + 1
          if (skip_bodylooping) cycle bodyloop

          entryno = databody%d(idxbody(2),jbody)

          varno = databody%d(idxbody(3),jbody)
          kind = databody%d(idxbody(4),jbody)
          obsvalue = databody%d(idxbody(5),jbody)
          qc = databody%d(idxbody(6),jbody)
          dart_qc = databody%d(idxbody(7),jbody)
          which_vert = databody%d(idxbody(8),jbody)
          levelht = databody%d(idxbody(9),jbody)
          obs_error = databody%d(idxbody(10),jbody)
          channel = databody%d(idxbody(11),jbody)
          press = databody%d(idxbody(12),jbody)
          
          if (is_post) then
             member = databody%d(idxbody(13),jbody) ! ensemble member number
             prior = databody%d(idxbody(14),jbody)
             
             if (fd4o_is_null(obsvalue) .or. fd4o_is_null(prior)) then
                fg_depar = fd4o_null()
             else
                fg_depar = abs(obsvalue - prior)
             endif
             ens_rowid = databody%d(idxbody(ncols_body-1),jbody)
             ens_status = fd4o_int8(databody%d(idxbody(ncols_body),jbody))
             body_rowid = 0
             body_status = 0
          else
             member = fd4o_null() 
             prior = fd4o_null()
             fg_depar = fd4o_null()
             body_rowid = databody%d(idxbody(ncols_body-1),jbody)
             body_status  = fd4o_int8(databody%d(idxbody(ncols_body),jbody))
             ens_rowid = 0
             ens_status = 0
          endif

          if (is_post) then
             !       Check if anything missing (POST mode only)
             flag   = 0
             if (.not.sanity_check(obsvalue,obs_error,prior)) then
                if (is_verbose) write(dio,'(1x,a,2(1x,i0),a,3(1x,g0))') &
                     & 'do_screening: obs sanity-check failed for ens.rowid,member=',ens_rowid,int(member),' : NULLs in one of obsvalue,obs_error,prior=',obsvalue,obs_error,prior
                rejected_ens_rowids(jbody) = ens_rowid ! this ENS rowid gets out right rejected i.e. ens.status's first bit will be set 0 -- no blacklisting needed
             else if (varno == t .or. varno == u .or. varno == v .or. varno == z .or. varno == ps) then
                SIGMA = [9.0_8, 16.0_8, 25.0_8] ! the default SIGMA
                zlf      = fg_depar*fg_depar
                zright   = 2*obs_error*obs_error
                !       FG Check Flag 
                flagloop: do jflag = 1,3
                   !       Temperature Sigma Multiplier
                   if (varno == t) then
                      SIGMA(jflag)=QC_U_T_H_Q(jflag)
                      !       U Wind Component Sigma Multiplier
                   else if (varno == u) then
                      SIGMA(jflag)=QC_U_T_H_Q(jflag)
                      !       V Wind Component Sigma Multiplier
                   else if (varno == v) then
                      SIGMA(jflag)=QC_U_T_H_Q(jflag)
                      !       Pressure Sigma Multiplier
                   else if (varno == ps) then
                      SIGMA(jflag)=QC_PS_Z   (jflag)
                      !       Geopotential Sigma Multiplier
                   else if (varno == z) then
                      SIGMA(jflag)=QC_PS_Z   (jflag)
                   else
                      cycle flagloop
                   endif
                   !       First guess check (ECMWF style)
                   zrh      = zright*SIGMA(jflag)
                   if (zlf >= zrh ) flag = jflag
                enddo flagloop

                if (flag == 3) then
                   if (is_verbose) write(dio,*) 'do_screening: Rejected summary -- ens.status first bit to be changed to 0; flag=',flag,varno,obsvalue,prior,fg_depar,obs_error,ens_rowid
                   rejected_ens_rowids(jbody) = ens_rowid ! this ENS rowid gets rejected i.e. ens.status's first bit will be set 0
                else
                   if (flag == 2) then
                      if (is_verbose) write(dio,*) 'do_screening: Passed (probably incorrect) summary; flag=',flag,varno,obsvalue,prior,fg_depar,obs_error
                   else if (flag == 1) then
                      if (is_verbose) write(dio,*) 'do_screening: Passed (probably correct)   summary; flag=',flag,varno,obsvalue,prior,fg_depar,obs_error
                   !else if (flag == 0) then
                   !   if (is_verbose) write(dio,*) 'do_screening: Passed (correct)            summary; flag=',flag,varno,obsvalue,prior,fg_depar,obs_error
                   endif
                endif
             endif

             if (rejected_ens_rowids(jbody) == 0) then ! not yet rejected => apply blacklisting (TBD: should we apply regardless ?)
                if (LLdo_bl) then
                   ! Call blacklisting for ENS entries not rejected so far (we do NOT blacklist plain BODY entries, when in POST-mode)
                   blacklisted_ens_status(jbody) = ens_status
                   istat = blacklisted_ens_status(jbody) 
                   LLdebug_print = is_verbose .and. (jbody == 1 .or. jbody == nrows_body/2 .or. jbody == nrows_body)
                   if (LLdebug_print) write(dio,'(1x,a,i0,a,i0,a,i0,a)') 'Checking against blacklisting (ens.status), row#',jbody,'/',nrows_body,', member#',int(member),' ...'
                   call bllist('ens.status',.FALSE.,  & ! body & ens blacklisting
                        &   istat,       & ! istat => blacklisted_ens_status(jbody)
                        &   sb_active, sb_blacklisted, &
                        & [ nandat,nantim,phase &
                        !  hdr & sat-tables
                        &  ,raw_statid,obstype,codetype,reportype,bufrtype,subtype &
                        &  ,yyyymmdd,hhmmss,deglat,deglon &
                        &  ,sat_instr, sensor_id, sat_id &
                        !  body & ens-tables
                        &  ,varno,kind,obsvalue,qc,dart_qc,which_vert,obs_error &
                        &  ,levelht,channel,press &
                        &  ,member,fg_depar &
                        & ], &
                        & [ -1,-1,-1 &
                        !  hdr & sat-tables
                        &  ,sb_hdr_statid,sb_hdr_obstype,sb_hdr_codetype,sb_hdr_reportype,sb_hdr_bufrtype,sb_hdr_subtype &
                        &  ,sb_hdr_yyyymmdd,sb_hdr_hhmmss,sb_hdr_deglat,sb_hdr_deglon &
                        &  ,sb_sat_sat_instr,sb_sat_sensor_id,sb_sat_sat_id &
                        !  body & ens-tables
                        &  ,sb_body_varno,sb_body_kind,sb_body_obsvalue,sb_body_qc,sb_body_dart_qc,sb_body_which_vert,sb_body_obs_error &
                        &  ,sb_body_levelht,sb_body_channel,sb_body_press &
                        &  ,sb_ens_member,sb_ens_fg_depar &
                        & ], debug_print = LLdebug_print)
                   if (blacklisted_ens_status(jbody) /= istat) then
                      blacklisted_ens_status(jbody) = istat
                      rejected_ens_rowids(jbody) = -ens_rowid ! negative number indicates that the ENS rowid was blacklisted
                   endif
                endif
             else ! straight rejection -- no blacklist evaluated (... for the moment at least)
                if (sb_active >= 0) call clrbits(blacklisted_ens_status(jbody),sb_active)
             endif
             
          else ! (.not. is_post)

             if (.not.sanity_check(obsvalue,obs_error)) then
                if (is_verbose) write(dio,'(1x,a,1x,i0,a,2(1x,g0))') &
                     & 'do_screening: obs sanity-check failed for body.rowid=',body_rowid,' : NULLs found in one of obsvalue,obs_error=',obsvalue,obs_error
                rejected_body_rowids(jbody) = body_rowid ! this BODY rowid gets outright rejected i.e. body.status's first bit will be set 0 -- no blacklisting needed
             endif
             
             if (rejected_body_rowids(jbody) == 0) then ! not yet rejected => apply blacklisting (TBD: should we apply regardless ?)
                if (LLdo_bl) then
                   ! Call blacklisting for BODY entries not rejected so far
                   blacklisted_body_status(jbody) = body_status
                   istat = blacklisted_body_status(jbody) 
                   LLdebug_print = is_verbose .and. (jbody == 1 .or. jbody == nrows_body/2 .or. jbody == nrows_body)
                   if (LLdebug_print) write(dio,'(1x,a,i0,a,i0,a)') 'Checking against blacklisting (body.status), row#',jbody,'/',nrows_body,' ...'
                   call bllist('body.status',.FALSE.,  & ! body blacklisting
                        &   istat,       & ! istat => blacklisted_body_status(jbody)
                        &   sb_active, sb_blacklisted, &
                        & [ nandat,nantim,phase &
                        !  hdr & sat-tables
                        &  ,raw_statid,obstype,codetype,reportype,bufrtype,subtype &
                        &  ,yyyymmdd,hhmmss,deglat,deglon &
                        &  ,sat_instr,sensor_id,sat_id &
                        !  body -table
                        &  ,varno,kind,obsvalue,qc,dart_qc,which_vert,obs_error &
                        &  ,levelht,channel,press &
                        &  ,member,fg_depar & ! these are set to NULL in PRE-mode
                        & ], &
                        & [ -1,-1,-1 &
                        !  hdr & sat-tables
                        &  ,sb_hdr_statid,sb_hdr_obstype,sb_hdr_codetype,sb_hdr_reportype,sb_hdr_bufrtype,sb_hdr_subtype &
                        &  ,sb_hdr_yyyymmdd,sb_hdr_hhmmss,sb_hdr_deglat,sb_hdr_deglon &
                        &  ,sb_sat_sat_instr,sb_sat_sensor_id,sb_sat_sat_id &
                        !  body & ens-tables
                        &  ,sb_body_varno,sb_body_kind,sb_body_obsvalue,sb_body_qc,sb_body_dart_qc,sb_body_which_vert,sb_body_obs_error &
                        &  ,sb_body_levelht,sb_body_channel,sb_body_press &
                        &  ,-1,-1 &
                        & ], debug_print = LLdebug_print)
                   if (blacklisted_body_status(jbody) /= istat) then
                      blacklisted_body_status(jbody) = istat
                      rejected_body_rowids(jbody) = -body_rowid ! negative number indicates that the BODY rowid was blacklisted
                   endif
                endif
             else ! straight rejection -- no blacklist evaluated (... for the moment at least)
                if (sb_active >= 0) call clrbits(blacklisted_body_status(jbody),sb_active)
             endif
          endif ! if (is_post) then else ...
       enddo bodyloop
       deallocate(statid)
    enddo hdrloop

    rc = fd4o_delete(datahdr)
    rc = fd4o_delete(databody)

    deallocate(idxhdr)
    deallocate(idxbody)
    
    cnt = count(rejected_hdr_rowids(:) /= 0)
    numbl = count(rejected_hdr_rowids(:) < 0)
    write(dio,*) 'The number of rejected HDR-table entries  = ',cnt,' out of ',size(rejected_hdr_rowids),' of which blacklisted = ',numbl
    if (cnt > 0) then
       ! update database : hdr.status flag must be changed when rejected_hdr_rowids(i) /= 0
       sql = "UPDATE hdr SET status = ?2 WHERE rowid = ?1"
       allocate(buffer(cnt,2))
       i = 0
       do jbody=1,size(rejected_hdr_rowids)
          hdr_rowid = rejected_hdr_rowids(jbody)
          if (hdr_rowid /= 0) then
             i = i + 1
             buffer(i,1) = abs(hdr_rowid)                ! buffer index (:,1) relates to ?1
             buffer(i,2) = blacklisted_hdr_status(jbody) ! buffer index (:,2) relates to ?2
          endif
       enddo
       rc = fd4o_putdb(h,buffer,rowmajor=.TRUE.,query=sql)
       deallocate(buffer)
       if (rc /= cnt) call fd4o_exit('fd4o_putdb() of "'//sql//'" on "'//trim(dbfile)//'" failed',errcode=rc,do_exit=0) ! Don't fail
       deallocate(sql)
    endif
    deallocate(rejected_hdr_rowids)
    deallocate(blacklisted_hdr_status)

    if (is_post) then
       cnt = count(rejected_ens_rowids(:) /= 0)
       numbl = count(rejected_ens_rowids(:) < 0)
       write(dio,*) 'The number of rejected ENS-table entries  = ',cnt,' out of ',size(rejected_ens_rowids),' of which blacklisted = ',numbl
       if (cnt > 0) then
          ! update database : ens.status flag must be changed when rejected_ens_rowids(i) /= 0
          sql = "UPDATE ens SET status = ?2 WHERE rowid = ?1"
          allocate(buffer(cnt,2))
          i = 0
          do jbody=1,size(rejected_ens_rowids)
             ens_rowid = rejected_ens_rowids(jbody)
             if (ens_rowid /= 0) then
                i = i + 1
                buffer(i,1) = abs(ens_rowid)                ! buffer index (:,1) relates to ?1
                buffer(i,2) = blacklisted_ens_status(jbody) ! buffer index (:,2) relates to ?2
             endif
          enddo
          rc = fd4o_putdb(h,buffer,rowmajor=.TRUE.,query=sql)
          deallocate(buffer)
          if (rc /= cnt) call fd4o_exit('fd4o_putdb() of "'//sql//'" on "'//trim(dbfile)//'" failed',errcode=rc,do_exit=0) ! Don't fail
          deallocate(sql)
       endif
       deallocate(rejected_ens_rowids)
       deallocate(blacklisted_ens_status)
    else
       cnt = count(rejected_body_rowids(:) /= 0)
       numbl = count(rejected_body_rowids(:) < 0)
       write(dio,*) 'The number of rejected BODY-table entries = ',cnt,' out of ',size(rejected_body_rowids),' of which blacklisted = ',numbl
       if (cnt > 0) then
          ! update database : body.status flag must be changed when rejected_body_rowids(i) /= 0
          sql = "UPDATE body SET status = ?2 WHERE rowid = ?1"
          allocate(buffer(cnt,2))
          i = 0
          do jbody=1,size(rejected_body_rowids)
             body_rowid = rejected_body_rowids(jbody)
             if (body_rowid /= 0) then
                i = i + 1
                buffer(i,1) = abs(body_rowid)                ! buffer index (:,1) relates to ?1
                buffer(i,2) = blacklisted_body_status(jbody) ! buffer index (:,2) relates to ?2
             endif
          enddo
          rc = fd4o_putdb(h,buffer,rowmajor=.TRUE.,query=sql)
          deallocate(buffer)
          if (rc /= cnt) call fd4o_exit('fd4o_putdb() of "'//sql//'" on "'//trim(dbfile)//'" failed',errcode=rc,do_exit=0) ! Don't fail
          deallocate(sql)
       endif
       deallocate(rejected_body_rowids)
       deallocate(blacklisted_body_status)
    endif

9999 continue
    rc = fd4o_closedb(h)
    if (rc /= 0) call fd4o_exit('fd4o_closedb() of "'//trim(dbfile)//'" failed',errcode=rc,do_exit=0) ! Don't fail

    deallocate(sqlhdr)
    deallocate(sqlbody)
  end subroutine do_screening

  function sanity_check(obsvalue,oe,prior)
    implicit none
    real(jprd), intent(in) :: obsvalue,oe
    real(jprd), intent(in), optional :: prior
    logical :: sanity_check
    sanity_check = .TRUE.
    if (present(prior)) then
       if (fd4o_is_null(obsvalue) .or. fd4o_is_null(oe) .or. fd4o_is_null(prior)) then
          sanity_check = .FALSE.
       endif
    else
       if (fd4o_is_null(obsvalue) .or. fd4o_is_null(oe)) then
          sanity_check = .FALSE.
       endif
    endif
  end function sanity_check

END PROGRAM Screening
