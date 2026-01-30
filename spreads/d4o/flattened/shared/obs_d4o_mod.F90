module obs_d4o_mod
  use fd4o_mod
  use fd4o_mod, only : dio => fd4o_debug_io
  use utilities_mod, only : error_handler, E_ERR, to_upper
  use obs_sequence_mod
  use obs_def_mod, only : init_obs_def, set_obs_def_key
  use location_mod, only : set_location, location_type
  use time_manager_mod, only : set_date, set_time_missing, time_type
  use types_mod
  
#ifdef _camfv_
use obs_def_rttov_mod,only : set_mw_metadata, set_visir_metadata, set_iasiir_metadata
use obs_def_gps_mod,  only : set_gpsro_ref
#endif

  implicit none

#include "mpif.h"
  
  private

  character(len=*), parameter :: source = __FILE__

#define d4o_int1 4
#define d4o_mpi_integer1 MPI_INTEGER4
  
  real(r8), parameter :: twopi = 2.0_r8 * PI
  
  character(len=4096), save, public  :: d4o_catalog = ' '
  
  character(len=:), save, private, allocatable :: d4o_departures ! Can ONLY have values 'YES','NO' or 'ALL' (no defaults)
  integer, private, save :: i_d4o_departures = -9999 ! YES=1, NO=0, ALL=-1 ; anything else = -9999
  
  ! d4o_departures='YES' (aka i_d4o_departures =  1) : compute the departures with the first_guess ensemble, before the real assimilation.
  ! d4o_departures='NO'  (aka i_d4o_departures =  0) : read the prior departure from the database in order to do the assimilation ... then write the posterior departures.
  ! d4o_departures='ALL' (aka i_d4o_departures = -1) : run as we are doing now (so we compute the prior departure, assimilation, and posterior departures), a one shot run.
  ! *** The values are case insensitive ***
  ! 'YES' can be replaced not only (say) with 'yes' or 'yeS' or 'YEs' etc. but also (case insensitive) "Y", "T", "TRUE", ".TRUE." or "1"
  ! 'NO' similarly to 'YES' but also values "N", "F","FALSE", ".FALSE." or "0" are accepted
  ! 'ALL' similarly to 'NO' but also (case insensitive) "A", "Both" and "-1" are accepted
  
  character(len=:), save, private, allocatable :: d4o_inflation ! Can ONLY have values 'YES','NO' or 'FINAL' (no defaults)
  integer, private, save :: i_d4o_inflation = -9999 ! YES=1, NO=0, FINAL=-1 ; anything else = -9999
  ! d4o_inflation='YES'   : 
  ! d4o_inflation='NO'    : 
  ! d4o_inflation='FINAL' : 
  ! *** The values are case insensitive ***
  ! 'YES' can be replaced not only (say) with 'yes' or 'yeS' or 'YEs' etc. but also (case insensitive) "Y", "T", "TRUE", ".TRUE." or "1"
  ! 'NO' similarly to 'YES' but also values "N", "F","FALSE", ".FALSE." or "0" are accepted
  ! 'FINAL' similarly to 'NO' but also (case insensitive) and the value "-1" is accepted
  
  logical, save, public :: d4o_format = .FALSE.
  logical, save, public :: d4o_debug = .FALSE.

  character(len=:), save, allocatable :: d4o_timeslot
  character(len=:), save, allocatable :: d4o_hdr
  character(len=:), save, allocatable :: d4o_body
  character(len=:), save, allocatable :: d4o_ens

  integer, save :: dbs_max_num_obs = 0 ! max number of body entries (active, passive -- ALL available -- derived from catalog)
  integer, save :: dbs_num_obs = 0 ! number of active body entries
  
  integer, save :: dbs_numens = 0 ! number of ensembles
  integer, save :: dbs_numens_env = 0 ! number of ensembles from env variable export d4o_ens_size=<value> (and it must match with the input, e.g. catalog database)
  
  integer, save :: dbs_numtsl = 0 ! number of timeslots
  
  ! When dbs_numtsl > 0, we will also have these filled up
  integer(i8), save :: dbs_basetime = -1 ! basetime (if available) in format YYYYMMDDhhmmss
  integer(i8), save, allocatable :: dbs_timeslot_start(:) ! 1 .. dbs_numtsl ; in format YYYYMMDDhhmmss ; 0 if empty timeslot
  integer(i8), save, allocatable :: dbs_timeslot_end(:)   ! 1 .. dbs_numtsl ; in format YYYYMMDDhhmmss ; 0 if empty timeslot

  type obs_dbs_t
     private
     character(len=:), allocatable :: dbname
     integer :: idx = -1 ! 1 .. dbs_max_alloc
     integer :: dbh = -1
     integer :: datapool = 0 ! =0 if catalog, > 0 if data (is_data == .TRUE.)
     logical :: is_readonly = .FALSE.
     logical :: is_open = .FALSE.
     logical :: is_data = .TRUE. ! when .FALSE., then "catalog"-database
     ! fast_physproc(poolno) = mod(poolno-1,numranks)
     logical :: is_writable = .FALSE. ! .TRUE. if datapool > 0 .and. mod(datapool - 1,numranks) == myrank
     ! indices to seq%obs(:) where this data pool holds its DART data -- needed when updating the database
     integer :: start_seq_i = 0
     integer :: end_seq_i = -1
     ! derived
     logical :: has_sat = .FALSE.   ! .TRUE. if catalog nsat > 0
   contains
     procedure, private :: fmtdump_obs_dbs_t
     generic :: write(formatted) => fmtdump_obs_dbs_t
  end type obs_dbs_t

  !public :: obs_dbs_t

  type(obs_dbs_t), allocatable, target :: dbs(:)
  integer, save :: dbs_max_alloc = 0 ! Maximum number of dbs that can be opened per task
  integer, save :: dbs_num_alloc = 0 ! Number of dbs allocated <= dbs_max_alloc
  integer, save :: dbs_num_pools = 0 ! Number of distinct (non-catalog) database files, which have data (is_data == .TRUE.)
  
  !public :: get_dbs_index
  
  type obs_catalog_t
     private
     type(obs_dbs_t), pointer :: dbs => NULL()
     character(len=:), allocatable :: description
     integer :: idx = -1 ! 1 .. size(array) or 0 if scalar
     integer :: timeslot = 0
     integer :: reportype = 0
     integer :: obstype = 0
     integer :: codetype = 0
     integer :: bufrtype = 0
     integer :: subtype = 0
     integer :: varno = 0
     integer :: kind = 0
     integer :: sat_id = -1 ! ECMWF
     integer :: sensor_id = -1 ! ECMWF
     integer :: sat_instr = -1 ! ECMWF 
     integer :: platform_id = -1 ! RTTOV
     integer :: rttov_sat_id = -1 ! RTTOV
     integer :: rttov_sensor_id = -1 ! RTTOV
     integer :: nsat = 0
     integer :: nbody = 0 ! all body entries including non-active
   contains
     procedure, private :: fmtdump_obs_catalog_t
     generic :: write(formatted) => fmtdump_obs_catalog_t
  end type obs_catalog_t
  
  !public :: obs_catalog_t

  type(obs_catalog_t), allocatable :: dbs_catalog(:)

  public :: doread_d4o_catalog
  public :: doread_d4o_data
  public :: dowrite_d4o_data
  public :: get_d4o_departures
  public :: get_d4o_inflation
  public :: get_d4o_numens_env
  public :: get_d4o_aux
  public :: put_d4o_aux

  ! MPI & shmem -specific -- by default still private
  
  public :: dostatic_d4o_init
  public :: doalloc_d4o_data
  public :: dofree_d4o_data
  public :: dosync_d4o_data
  !public :: d4o_shmem ! NOT a public function
  public :: d4o_bcast ! a public function

  logical, save :: has_shmem = .FALSE.
  logical, save :: has_mpi = .FALSE.
  integer, save :: global_comm = -1
  integer, save :: myrank = -1
  integer, save :: numranks = 0

  character(len=MPI_MAX_PROCESSOR_NAME), save :: node_hostname = ' '
  integer, save :: node_seqno = -1
  integer, save :: node_comm = -1
  integer, save :: node_rank = -1
  integer, save :: node_size = 0
  
contains

  subroutine dostatic_d4o_init(comm)
    integer, intent(in), optional :: comm
    logical, save :: once = .TRUE.
    integer :: ilen, ierr, ishmem
    if (once) then
       if (present(comm)) then ! we *ONLY* do this in presence of a valid communicator "comm"
          has_mpi = .TRUE.
          global_comm = comm
          CALL MPI_comm_rank(global_comm,myrank,ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Comm_rank(global) returned error code ',ierr,1)
          CALL MPI_comm_size(global_comm,numranks,ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Comm_size(global) returned error code ',ierr,1)
          ishmem = d4o_shmem()
          if (ishmem /= 0) then ! this opens up possibilities to share objects (like seq%obs(:)) inside each node
             CALL MPI_Get_processor_name(node_hostname,ilen,ierr)
             if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Get_processor_name returned error code ',ierr,1)
             CALL MPI_Comm_split_type(global_comm,MPI_COMM_TYPE_SHARED,0,MPI_INFO_NULL,node_comm,ierr)
             if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Comm_split_type(global->node) returned error code ',ierr,1)          
             CALL MPI_Comm_rank(node_comm,node_rank,ierr)
             if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Comm_rank(node) returned error code ',ierr,1)
             CALL MPI_Comm_size(node_comm,node_size,ierr)
             if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Comm_size(node) returned error code ',ierr,1)
             ! The "node" concept : not necessarily SMP-node -- most likely a ccNUMA-code !!
             node_seqno = myrank/node_size ! master node = 0, siblings > 0 
             if (node_rank == 0) then ! all master ranks of each "node_comm" write this message (for now)
                write(0,'(1x,"[",i0,"]",1x,a,i0,a,i0,a,2(1x,i0),1x,"0x",z0)') &
                     & myrank,'dostatic_d4o_init: d4o_shmem=',ishmem,&
                     & ' => shmem MPI operations enabled on host#',node_seqno,&
                     & ' "'//trim(node_hostname)//'" : node_size,numranks,hostid=',&
                     & node_size,numranks,fd4o_gethostid()
             endif
             has_shmem = .TRUE. ! in case "seq%windowsize > 0" -comparison is not available, like when deciding whether to read catalog or not
          else if (myrank == 0) then
             write(0,'(1x,"[",i0,"]",1x,a,i0)') &
                  & myrank,'dostatic_d4o_init: d4o_shmem=0 => shmem MPI operations NOT enabled : numranks=',numranks
             has_shmem = .FALSE.
          endif
       else ! w/o proper MPI
          has_shmem = .FALSE.
          has_mpi = .FALSE.
          global_comm = -1 ! generally shouldn't matter
          myrank = 0
          numranks = 1
       endif
       once = .FALSE.
    endif
  
  end subroutine dostatic_d4o_init
  
  subroutine dosync_d4o_data(seq)
    type(obs_sequence_type), intent(in) :: seq
    integer :: ierr
    if (associated(seq%obs)) then
       if (seq%windowsize > 0) then
          CALL MPI_Win_fence(0, seq%win, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('dosync_d4o_data: MPI_Win_fence returned error code ',ierr,1)
          CALL MPI_Barrier(seq%comm, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('dosync_d4o_data: MPI_Barrier returned error code ',ierr,1)
       endif
    endif
  end subroutine dosync_d4o_data
    
  subroutine dofree_d4o_data(seq)
    type(obs_sequence_type), intent(inout) :: seq
    integer :: ierr
    if (associated(seq%obs)) then
       if (seq%windowsize > 0) then
          CALL MPI_Win_fence(0, seq%win, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('dofree_d4o_data: MPI_Win_fence returned error code ',ierr,1)
          CALL MPI_Barrier(node_comm, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('dofree_d4o_data: MPI_Barrier returned error code ',ierr,1)
          CALL MPI_Win_free(seq%win, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('dofree_d4o_data: MPI_Win_free returned error code ',ierr,1)
          seq%windowsize = 0
          seq%win = 0
       else
          deallocate(seq%obs)
       endif
       nullify(seq%obs)
    endif
  end subroutine dofree_d4o_data
    
  subroutine doalloc_d4o_data(seq,num_obs,shmem,init,ierr)
    USE, INTRINSIC :: ISO_C_BINDING, ONLY : C_PTR, C_F_POINTER
    type(obs_sequence_type), intent(inout) :: seq
    integer, intent(in) :: num_obs
    logical, intent(in) :: shmem
    logical, intent(out) :: init
    integer, intent(out) :: ierr
    logical :: LLshmem
    integer :: win, disp_unit, ishape(1), bitsperbyte
    integer(i8) :: windowsize
    character(len=1) :: onebyte
    TYPE(C_PTR) ::  baseptr
    integer(i8) :: ibaseptr
    init = .TRUE.
    ierr = 0
    if (.not.associated(seq%obs)) then
       LLshmem = shmem .and. (node_size > 0) .and. (d4o_shmem() /= 0)
       if (LLshmem) then
          init = (node_rank == 0)
          bitsperbyte = storage_size(onebyte) ! number of bits in a byte (usually 8)
          disp_unit = (storage_size(seq%obs)+bitsperbyte-1)/bitsperbyte ! in bytes
          if (init) then
             windowsize = int(num_obs,kind(windowsize)) * int(disp_unit,kind(windowsize))
          else
             windowsize = 0
          endif
          CALL MPI_Win_allocate_shared(windowsize, disp_unit, MPI_INFO_NULL, node_comm, baseptr, win, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('doalloc_d4o_data: MPI_Win_allocate_shared returned error code ',ierr,1)
          CALL MPI_Win_shared_query(win, 0, windowsize, disp_unit, baseptr, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('doalloc_d4o_data: MPI_Win_shared_query returned error code ',ierr,1)
          ishape(1) = num_obs
          CALL C_F_POINTER(baseptr, seq%obs, ishape)
          ibaseptr = transfer(baseptr,ibaseptr)
          if (init) then
             write(0,'(1x,a,i0,1x,L1,1x,"0x",z0)') &
                  'doalloc_d4o_data: num_obs,associated(seq%obs),baseptr=',num_obs,associated(seq%obs),ibaseptr
             write(0,*) &
                  'doalloc_d4o_data: bitsperbyte,storage_size(seq%obs),disp_unit,windowsize,ishape(1)=',&
                  bitsperbyte,storage_size(seq%obs),disp_unit,windowsize,ishape(1)
             if (associated(seq%obs)) then
                write(0,*) 'doalloc_d4o_data: num_obs,size(seq%obs)=',num_obs,size(seq%obs)
             endif
          endif
          seq%windowsize = windowsize
          seq%win = win
          seq%comm = node_comm
          CALL MPI_Barrier(node_comm, ierr)
          if (ierr /= MPI_SUCCESS) call fd4o_exit('doalloc_d4o_data: MPI_Barrier returned error code ',ierr,1)
       else
          allocate(seq%obs(num_obs))
       endif
    endif
    ierr = size(seq%obs)
  end subroutine doalloc_d4o_data

  function d4o_shmem(enforced) result(iresult)
    integer, intent(in), optional :: enforced
    logical, save :: once = .TRUE.
    integer, save :: value = 0 ! the default is currently not to use shmem approach
    integer :: iresult, tmp
    character(len=12) :: clenv
    if (once) then
       once = .FALSE.
       tmp = value
       call get_environment_variable('d4o_shmem',clenv)
       if (clenv /= ' ') then
          clenv = trim(adjustl(clenv))
          read(clenv,*,err=999,end=999) tmp
       endif
       value = tmp
       if (myrank == 0) & 
            write(dio,'(a,i0)') 'd4o_shmem(): export d4o_shmem=',value
    endif
999 continue
    if (present(enforced)) then
       value = enforced
       if (myrank == 0) & 
            write(dio,'(a,i0,a)') 'd4o_shmem(): export d4o_shmem=',value,' (enforced)'
    endif
    iresult = value
  end function d4o_shmem
  
  function d4o_bcast() result(lresult)
    logical, save :: once = .TRUE.
    logical, save :: truth = .FALSE.
    logical :: lresult
    integer :: value
    character(len=7) :: clenv
    if (once) then
       once = .FALSE.
       call get_environment_variable('d4o_bcast',clenv)
       if (clenv /= ' ') then
          clenv = trim(adjustl(clenv))
          call to_upper(clenv)
          select case (trim(clenv))
          case ("Y","YES","T","TRUE",".TRUE.","1","ON")
             truth = .TRUE.
          case ("N","NO","F","FALSE",".FALSE.","0","OFF")
             truth = .FALSE.
          case default
             truth = .FALSE.
          end select
       else
          truth = .FALSE.
       endif
       value=0
       if (truth) value=1
       if (myrank == 0) & 
            write(dio,'(a,i0)') 'd4o_bcast(): export d4o_bcast=',value
    endif
    lresult = truth
  end function d4o_bcast
  
  function get_d4o_departures() result(iresult)
    integer :: iresult
    logical, save :: once = .TRUE.
    logical :: LLokay
    character(len=7) :: clenv
    if (once) then
       call get_environment_variable('d4o_departures',clenv)
       if (clenv /= ' ') then
          clenv = trim(adjustl(clenv))
          call to_upper(clenv)
          select case (trim(clenv))
          case ("Y","YES","T","TRUE",".TRUE.","1","ON")
             d4o_departures = "YES"
             i_d4o_departures = 1
          case ("N","NO","F","FALSE",".FALSE.","0","OFF")
             d4o_departures = "NO"
             i_d4o_departures = 0
          case ("A","ALL","BOTH","-1")
             d4o_departures = "ALL"
             i_d4o_departures = -1
          case default
             d4o_departures = " "
             i_d4o_departures = -9999
          end select
          !LLokay = (d4o_departures == 'ALL' .or. d4o_departures == 'YES' .or. d4o_departures == 'NO')
          LLokay = (i_d4o_departures >= -1 .and. i_d4o_departures <= 1)
       else
          LLokay = .FALSE.
       endif
       
       if (.not.LLokay) then
          call error_handler(E_ERR, 'get_d4o_departures',&
               & "the environment variable 'd4o_departures' must be set to 'YES'/'ON', 'NO'/'OFF' or 'ALL'",&
               & source, lineno=__LINE__)
       endif
       
       if (myrank == 0) & 
            write(dio,'(a)') 'get_d4o_departures(): export d4o_departures='//d4o_departures

       once = .FALSE.
    endif
    iresult = i_d4o_departures
  end function get_d4o_departures
  
  function get_d4o_inflation() result(iresult)
    integer :: iresult
    logical, save :: once = .TRUE.
    logical :: LLokay
    character(len=7) :: clenv
    if (once) then
       call get_environment_variable('d4o_inflation',clenv)
       if (clenv == ' ') clenv = "NO" ! the default
       if (clenv /= ' ') then
          clenv = trim(adjustl(clenv))
          call to_upper(clenv)
          select case (trim(clenv))
          case ("Y","YES","T","TRUE",".TRUE.","1","ON")
             d4o_inflation = "YES"
             i_d4o_inflation = 1
          case ("N","NO","F","FALSE",".FALSE.","0","OFF")
             d4o_inflation = "NO"
             i_d4o_inflation = 0
          case ("FINAL","-1")
             d4o_inflation = "FINAL"
             i_d4o_inflation = -1
          case default
             d4o_inflation = " "
             i_d4o_inflation = -9999
          end select
          !LLokay = (d4o_inflation == 'FINAL' .or. d4o_inflation == 'YES' .or. d4o_inflation == 'NO')
          LLokay = (i_d4o_inflation >= -1 .and. i_d4o_inflation <= 1)
       else
          LLokay = .FALSE.
       endif
       
       if (.not.LLokay) then
          call error_handler(E_ERR, 'get_d4o_inflation',&
               & "the environment variable 'd4o_inflation' must be set to 'YES'/'ON', 'NO'/'OFF' (=default) or 'FINAL'",&
               & source, lineno=__LINE__)
       endif
       
       if (myrank == 0) & 
            write(dio,'(a)') 'get_d4o_inflation(): export d4o_inflation='//d4o_inflation

       once = .FALSE.
    endif
    iresult = i_d4o_inflation
  end function get_d4o_inflation

  function get_d4o_numens_env() result(n)
    integer n, idummy, istat
    character(len=5) :: clenv
    logical, save :: once = .TRUE.
    if (once) then
       dbs_numens_env = 0
       call get_environment_variable('d4o_ens_size',clenv)
       if (clenv /= ' ') then
          clenv = trim(adjustl(clenv))
          read(clenv,*,iostat=istat) idummy
          if (istat == 0) dbs_numens_env = idummy
       endif

       if (dbs_numens_env < 2) then
          call error_handler(E_ERR, 'get_d4o_numens_env',&
               & "the environment variable 'd4o_ens_size' must be consistently defined with input file(s) and > 1",&
               & source, lineno=__LINE__)
       endif
       
       if (myrank == 0) & 
            write(dio,'(a,i0)') 'get_d4o_numens_env(): export d4o_ens_size=',dbs_numens_env
       
       once = .FALSE.
    endif
    n = dbs_numens_env
  end function get_d4o_numens_env
  
  function get_dbs_index(dbname,is_data) result(idx)
    character(len=*), intent(in), optional :: dbname
    logical, intent(in), optional :: is_data
    character(len=:), allocatable :: errmsg
    logical LLdata
    integer :: idx, j, poolno, idummy
1000 format(a,i0,a,i0,a,i0,a)
    
    if (.not.allocated(dbs)) then
       dbs_max_alloc = fd4o_maxdb() ! env $d4o_maxdb
       allocate(dbs(dbs_max_alloc))
       dbs_num_alloc = 0
       dbs_num_pools = 0
       idummy = get_d4o_departures() ! in case it had not yet been initialized
       idummy = get_d4o_inflation()  ! in case it had not yet been initialized
       idummy = get_d4o_numens_env() ! in case it had not yet been initialized
    endif
    
    idx = dbs_num_alloc + 1 ! candidate for next db-index
    
    if (present(dbname)) then
       do j=1,dbs_num_alloc
          if (trim(dbs(j)%dbname) == trim(dbname)) then
             idx = j
             exit
          endif
       enddo
    endif
    
    if (idx < 1 .or. idx > dbs_max_alloc) then
       allocate(character(len=256)::errmsg)
       write(errmsg,1000) &
            & 'Obtained db-index = ',idx,' not in the valid range [1..',dbs_max_alloc,&
            & '] -- increase via export d4o_maxdb=<value> (currently <value> = ',dbs_max_alloc,')'
       call error_handler(E_ERR, 'get_dbs_index', errmsg, source, lineno=__LINE__)
    endif
    
    if (dbs(idx)%idx == -1) then ! new entry => initialize
       dbs(idx)%idx = idx
       LLdata = .true.
       if (present(is_data)) LLdata = is_data
       if (LLdata) then ! New data pool "arrived"
          dbs_num_pools = dbs_num_pools + 1
          dbs(idx)%datapool = dbs_num_pools
          poolno = dbs_num_pools
          if (poolno > 0) then
             !dbs(idx)%is_writable = (mod(poolno-1,numranks) == myrank) ! only one task updates a pool
             dbs(idx)%is_writable = (myrank == 0) ! only the first rank updates ALL pools
          else
             dbs(idx)%is_writable = .FALSE.
          endif
       endif
    endif
    
    if (idx == dbs_num_alloc + 1) then
       dbs_num_alloc = dbs_num_alloc + 1
       if (d4o_debug) & 
            write(dio,1000) &
            & 'get_dbs_index(): New db-index = ',idx,' : Total allocated = ',dbs_num_alloc,' <= ',dbs_max_alloc,' = max'
    endif
  end function get_dbs_index

  subroutine fmtdump_obs_catalog_t(d, unit, iotype, v_list, iostat, iomsg)
    class(obs_catalog_t), intent(in) :: d
    integer, intent(in) :: unit
    character(*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(*), intent(inout) :: iomsg
    iostat = 0
    if (allocated(d%description)) then
1000   format(TL1,"fmtdump_obs_catalog_t(",i0,") timeslot=",i0,&
            & " (reportype,obstype,codetype,bufrtype,subtype,varno,kind,sat_id,sensor_id,sat_instr,platform_id,rttov_sat_id,rttov_sensor_id)=(",12(i0,","),i0,&
            & ") (nsat,nbody)=(",i0,",",i0,") : '",a,"' : dbs => ")
       write(unit,1000,iostat=iostat,iomsg=iomsg,advance='no') &
            & d%idx, &
            & d%timeslot,d%reportype,d%obstype,d%codetype,&
            & d%bufrtype,d%subtype,&
            & d%varno,d%kind,&
            & d%sat_id,d%sensor_id,d%sat_instr,d%platform_id,d%rttov_sat_id,d%rttov_sensor_id,&
            & d%nsat,d%nbody,&
            & d%description
       if (associated(d%dbs)) then
          write(unit,'(a,/)') '...'
          write(unit,*) d%dbs
       else
          write(unit,'(a)') 'N/A'
       endif
    endif
  end subroutine fmtdump_obs_catalog_t
  
  subroutine fmtdump_obs_dbs_t(d, unit, iotype, v_list, iostat, iomsg)
    class(obs_dbs_t), intent(in) :: d
    integer, intent(in) :: unit
    character(*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(*), intent(inout) :: iomsg
    iostat = 0
    if (allocated(d%dbname)) then
1000   format(TL1,"fmtdump_obs_dbs_t(",i0,") dbname='",a,&
            & "' dbh=",i0," datapool=",i0," is_readonly?",L1," is_open?",L1," is_data?",L1,&
            & " is_writable?",L1," has_sat?",L1)
       write(unit,1000,iostat=iostat,iomsg=iomsg) &
            & d%idx, d%dbname, &
            & d%dbh, d%datapool, d%is_readonly, d%is_open, d%is_data, d%is_writable, &
            & d%has_sat
    endif
  end subroutine fmtdump_obs_dbs_t
  
  subroutine doread_d4o_catalog(file_name, read_format, num_copies, num_qc, num_obs, max_num_obs, ens_size)
    character(len=*),  intent(in)  :: file_name
    character(len=*),  intent(out) :: read_format
    integer,           intent(out) :: num_copies, num_qc, num_obs, max_num_obs
    integer, optional, intent(in)  :: ens_size

    integer :: j, dbh, qh, idxdb, idxcol, tslot, poolno, rc, jdb, num_ens
    character(len=:), allocatable :: sql, sqlhdr, sqlbody
    character(len=:), allocatable :: dbname
    character(len=:), allocatable :: fmt
    character(len=:), allocatable :: errmsg
    type(fd4o_obsdata_t),allocatable :: data
    type(obs_dbs_t), pointer, save :: this_catalog_db => NULL()
    character(len=4096) :: clenv
    integer io_task
    logical LLshmem, LLbcast, LLreturn, LLprior
    integer :: comm, ierr, nobs_in(2), nobs_out(2)

    read_format = 'd4o'
    num_copies = 1 !! aka obsvalue
    num_qc = 1     !! aka qc
    num_ens = get_d4o_numens_env() !! "ens_size" even if "ens_size" optional arg was not provided
    num_obs = 0
    max_num_obs = 0
    
    io_task = 0
    LLshmem = (d4o_shmem() /= 0)
    LLbcast = d4o_bcast()
    LLprior = (i_d4o_departures == 0 .and. myrank >= 0) ! Now all tasks read the "ens" table when d4o_departures='NO' (but skip "prior" unless myrank = 0)
    
    if (LLshmem) then
       LLreturn = (node_rank /= io_task)
    else if (LLbcast) then
       LLreturn = (myrank /= io_task)
    else
       LLreturn = .FALSE. ! a flag for immediate return and thus skipping "catalog.db" access
    endif

    if (LLreturn) goto 2023
    
    if (.not.allocated(d4o_timeslot)) then
       call get_environment_variable('d4o_timeslot',clenv)
       if (clenv /= ' ') then
          d4o_timeslot = " AND timeslot IN ("//trim(clenv)//")" ! f.ex. env d4o_timeslot="1,5,8" => " AND timeslot IN (1,5,8)"
       else
          d4o_timeslot = " AND 1" ! any timeslot will do
       endif
       if (d4o_debug) then
          write(dio,'(a)') 'd4o_timeslot='//trim(clenv)//' => WHERE ... '//d4o_timeslot
       endif
    endif
    
    if (.not.allocated(d4o_hdr)) then
       call get_environment_variable('d4o_hdr',clenv)
       if (clenv /= ' ') then
          d4o_hdr = " AND ("//trim(clenv)//")" ! f.ex. env d4o_hdr="obstype = 2" => " AND (obstype = 2)"
       else
          d4o_hdr = " AND 1" ! any hdr will do
       endif
       if (d4o_debug) then
          write(dio,'(a)') 'd4o_hdr='//trim(clenv)//' => WHERE ... '//d4o_hdr
       endif
    endif
    
    if (.not.allocated(d4o_body)) then
       call get_environment_variable('d4o_body',clenv)
       if (clenv /= ' ') then
          d4o_body = " AND ("//trim(clenv)//")" ! f.ex. env d4o_body="obsvalue < 273.15" => " AND (obsvalue < 273.15)"
       else
          d4o_body = " AND 1" ! any body will do
       endif
       if (d4o_debug) then
          write(dio,'(a)') 'd4o_body='//trim(clenv)//' => WHERE ... '//d4o_body
       endif
    endif

    if (.not.allocated(d4o_ens)) then
       d4o_ens = " AND member <=           "
       write(d4o_ens,'(a,i0)') " AND member <= ",num_ens
       d4o_ens = trim(d4o_ens)
       if (d4o_debug) then
          write(dio,'(a)') 'd4o_ens becomes => WHERE ... '//d4o_ens
       endif
    endif
    
    if (.not.allocated(dbs_catalog)) then
       dbh = fd4o_opendb(file_name,'r') ! The file_name must be "catalog.db" -derivative -- usually behind env $d4o_catalog
       if (dbh >= 0) then
          sql = "SELECT MAX(numtsl) as numtsl, MAX(numens) AS numens FROM catalog WHERE label IS NOT NULL"
          data = fd4o_getdb(dbh, sql, err=rc, rowmajor=.FALSE.)
          if (rc == 1) then ! Exactly one row retrieved
             if (d4o_debug) call fd4o_print(dio,data) ! debug only
             qh = data%qh ! Query handle
             idxcol = fd4o_colidx(qh,"numtsl")
             dbs_numtsl = data%d(idxcol,1) ! NB: rowmajor=.FALSE.
             idxcol = fd4o_colidx(qh,"numens")
             dbs_numens = data%d(idxcol,1) ! NB: rowmajor=.FALSE.
          else
             dbs_numtsl = 0
             dbs_numens = 0
          endif

          if (dbs_numens < num_ens) then
             allocate(character(len=256)::errmsg)
             write(errmsg,'(a,i0,a,i0)') &
                  "The assumed ensemble size (",dbs_numens,") from '"//trim(file_name)// &
                  "' must be >= than the environment variable 'd4o_ens_size' value = ",num_ens
             call error_handler(E_ERR, 'doread_d4o_catalog',&
                  & trim(errmsg),&
                  & source, lineno=__LINE__)
          endif

          if (dbs_numtsl > 0) then ! get basetime and timeslot start & end timestamps (YYYYMMDDhhmmss)
             sql =  "SELECT timeslot,MAX(basetimestamp) AS basetimestamp,timeslot_start,timeslot_end"//&
                  & " FROM catalog"//&
                  & " WHERE label is NOT NULL"//&
                  & " AND timeslot is NOT NULL"//&
!                  & d4o_timeslot//&
                  & " GROUP BY 1,3,4 ORDER BY 1"
             data = fd4o_getdb(dbh, sql, err=rc, rowmajor=.TRUE.)
             if (rc > 0) then
                if (d4o_debug) call fd4o_print(dio,data) ! debug only
                dbs_basetime = -1
                allocate(dbs_timeslot_start(dbs_numtsl)) ; dbs_timeslot_start(:) = 0
                allocate(dbs_timeslot_end(dbs_numtsl))   ; dbs_timeslot_end(:) = 0
                qh = data%qh ! Query handle
                idxcol = fd4o_colidx(qh,"basetimestamp")
                dbs_basetime = fd4o_int8(data%d(1,idxcol))
                do j=1,rc
                   idxcol = fd4o_colidx(qh,"timeslot")
                   tslot = data%d(j,idxcol)
                   if (tslot >= 1 .and. tslot <= dbs_numtsl) then
                      idxcol = fd4o_colidx(qh,"timeslot_start")
                      dbs_timeslot_start(tslot) = fd4o_int8(data%d(j,idxcol)) 
                      idxcol = fd4o_colidx(qh,"timeslot_end")
                      dbs_timeslot_end(tslot) = fd4o_int8(data%d(j,idxcol))
                   endif
                enddo
             endif
          endif
          
          sql =  "SELECT timeslot,reportype,obstype,codetype,bufrtype,subtype,sat_id,sensor_id,sat_instr,platform_id,rttov_sat_id,rttov_sensor_id,"//&
               & "varno,kind,description,dbfile,"//&
               & "SUM(nsat) AS nsat, SUM(nbody) AS nbody"//&
               & " FROM catalog"//&
               & " WHERE label IS NOT NULL"//&
!               & d4o_timeslot//&
               & " GROUP BY timeslot,reportype,obstype,codetype,bufrtype,subtype,sat_id,sensor_id,sat_instr,platform_id,rttov_sat_id,rttov_sensor_id,"//&
               & "varno,kind,description,dbfile"//&
               & " ORDER BY timeslot,reportype,obstype,codetype,bufrtype,subtype,sat_id,sensor_id,sat_instr,platform_id,rttov_sat_id,rttov_sensor_id,"//&
               & "varno,kind,description,dbfile"
          
          data = fd4o_getdb(dbh, sql, err=rc, rowmajor=.TRUE.)
          if (rc > 0) then
             if (d4o_debug) call fd4o_print(dio,data) ! debug only
             
             idxdb = get_dbs_index(is_data=.FALSE.)
             this_catalog_db => dbs(idxdb)
             this_catalog_db%dbname = trim(file_name)
             this_catalog_db%dbh = dbh
             this_catalog_db%idx = idxdb
             this_catalog_db%datapool = 0
             this_catalog_db%is_readonly = .TRUE.
             this_catalog_db%is_open = .TRUE.
             this_catalog_db%is_data = .FALSE.
             if (d4o_debug) write(dio,*) this_catalog_db
             
             allocate(dbs_catalog(rc))
             
             qh = data%qh ! Query handle
             
             do j=1,rc
                dbs_catalog(j)%idx = j

                idxcol = fd4o_colidx(qh,"timeslot",fail=.FALSE.)
                if (fd4o_is_null(idxcol)) then ! if we did not have timeslot in our query
                   dbs_catalog(j)%timeslot = fd4o_null()
                else
                   dbs_catalog(j)%timeslot = data%d(j,idxcol)
                endif
                if (fd4o_is_null(dbs_catalog(j)%timeslot)) dbs_catalog(j)%timeslot = 0

                idxcol = fd4o_colidx(qh,"reportype")
                dbs_catalog(j)%reportype = data%d(j,idxcol)
                
                idxcol = fd4o_colidx(qh,"obstype")
                dbs_catalog(j)%obstype = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"codetype")
                dbs_catalog(j)%codetype = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"bufrtype")
                dbs_catalog(j)%bufrtype = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"subtype")
                dbs_catalog(j)%subtype = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"rttov_sat_id");
                dbs_catalog(j)%rttov_sat_id = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"rttov_sensor_id")
                dbs_catalog(j)%rttov_sensor_id = data%d(j,idxcol)
                !print*,"MALLICK33 SENSOR", idxcol

                idxcol = fd4o_colidx(qh,"sat_id");
                dbs_catalog(j)%sat_id = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"sensor_id")
                dbs_catalog(j)%sensor_id = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"sat_instr");
                dbs_catalog(j)%sat_instr = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"platform_id");
                dbs_catalog(j)%platform_id = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"varno")
                dbs_catalog(j)%varno = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"kind")
                dbs_catalog(j)%kind = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"description")
                dbs_catalog(j)%description = fd4o_text(data%d(j,idxcol))

                idxcol = fd4o_colidx(qh,"nsat")
                dbs_catalog(j)%nsat = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"nbody")
                dbs_catalog(j)%nbody = data%d(j,idxcol)

                idxcol = fd4o_colidx(qh,"dbfile")
                dbname = fd4o_text(data%d(j,idxcol))

                idxdb = get_dbs_index(dbname)
                dbs_catalog(j)%dbs => dbs(idxdb)
                dbs_catalog(j)%dbs%dbname = dbname
                if (dbs_catalog(j)%nsat   > 0) dbs_catalog(j)%dbs%has_sat   = .TRUE.

                if (d4o_debug) write(dio,*) dbs_catalog(j)
             enddo
          endif
          rc = fd4o_delete(data)
       endif ! if (dbh >= 0)

       ! Maximum overall count of body entries (i.e. includes active, passive -- ALL available)

       dbs_max_num_obs = 0
       if (allocated(dbs_catalog)) dbs_max_num_obs = sum(dbs_catalog(:)%nbody)
       
       ! Find the actual dbs_num_obs i.e. active ones by looking into count(*) of bodies ...
       ! ... at the same time count(*) of hdr must not be == 0

       dbs_num_obs = 0
       
       ! hdr-related items
       sqlhdr = "SELECT count(*)"//&
            & " FROM hdr"//&
            & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
            & " WHERE hdr.status & 1 = 1"//&
            & d4o_timeslot//&
            & d4o_hdr
       
       ! body-related items
       if (LLprior) then
          sqlbody= "SELECT count(distinct id||':'||entryno)"//&
               & " FROM hdr"//&
               & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
               & " JOIN body ON id = body.hdr_id"//&
               & " JOIN ens ON body.hdr_id = ens.hdr_id AND entryno = body_entryno"//&
               & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1 AND ens.status & 1 = 1"//&
               & d4o_timeslot//&
               & d4o_hdr//&
               & d4o_body//&
               & d4o_ens
       else
          sqlbody= "SELECT count(*)"//&
               & " FROM hdr"//&
               & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
               & " JOIN body ON id = body.hdr_id"//&
               & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1"//&
               & d4o_timeslot//&
               & d4o_hdr//&
               & d4o_body
       endif
       
       do jdb = 1, dbs_num_alloc
          if (.not.dbs(jdb)%is_data) cycle ! catalog db entry ? skip

          if (.not.dbs(jdb)%is_open) then
             dbs(jdb)%dbh = fd4o_opendb(dbs(jdb)%dbname,'r')
             if (dbs(jdb)%dbh >= 0) then
                dbs(jdb)%is_open = .TRUE.
                dbs(jdb)%is_readonly = .TRUE.
             endif
          endif

          if (dbs(jdb)%dbh >= 0) then
             data = fd4o_getdb(dbs(jdb)%dbh, sqlhdr, err=rc)
             if (rc == 1) then ! exactly one row found
                if (data%d(1,1) > 0) then ! data%d(1,1) := count(*) FROM hdr
                   rc = fd4o_delete(data)
                   data = fd4o_getdb(dbs(jdb)%dbh, sqlbody, err=rc)
                   if (rc == 1) then ! exactly one row found
                      if (data%d(1,1) > 0) then ! data%d(1,1) := count(...) FROM body
                         dbs_num_obs = dbs_num_obs + int(data%d(1,1))
                      endif
                   endif
                endif
             endif
             rc = fd4o_delete(data)
             
             ! No need to leave this open
             rc = fd4o_closedb(dbs(jdb)%dbh)
             
             dbs(jdb)%dbh = -1
             dbs(jdb)%is_open = .FALSE.
          endif ! if (dbs(jdb)%dbh >= 0) then
       enddo
    endif ! if (.not.allocated(dbs_catalog))

    num_obs = dbs_num_obs
    max_num_obs = dbs_max_num_obs

    if (present(ens_size)) then
       !if (dbs_numens /= ens_size) then ! these MUST match !!!
       if (dbs_numens < ens_size) then ! a database cannot have LESS members than requested by the input
          allocate(character(len=256)::errmsg)
          write(errmsg,'(a,i0,a,i0)') &
               & 'Incompatible number of ENS-members (',dbs_numens,&
               & ') in the d4o-database(s) -- expected number at least ',ens_size
          call error_handler(E_ERR, 'doread_d4o_catalog', errmsg, source, lineno=__LINE__)
       endif
    endif

    ! Close catalog -- if open
    if (associated(this_catalog_db)) then
       if (this_catalog_db%is_open) then
          dbh = this_catalog_db%dbh
          rc = fd4o_closedb(dbh)
          this_catalog_db%dbh = -1
          this_catalog_db%is_open = .FALSE.
       endif
    endif

2023 continue
    comm = global_comm
    nobs_in = [num_obs, max_num_obs]
    CALL MPI_Allreduce(nobs_in,nobs_out,size(nobs_in),MPI_INTEGER4,MPI_MAX,comm,ierr)
    if (ierr /= MPI_SUCCESS) call fd4o_exit('MPI_Allreduce(nobs...MPI_MAX) returned error code ',ierr,1)
    num_obs = nobs_out(1)
    max_num_obs = nobs_out(2)

  end subroutine doread_d4o_catalog
  
  subroutine doread_d4o_data(seq)
    type(obs_sequence_type), intent(inout) :: seq
    
    integer :: i, rc, jdb, varno, kind, which_vert, entryno, this_epoch
    integer :: j, prev_time
    integer :: reportype,obstype,codetype,bufrtype,subtype,sat_id,sensor_id,platform_id,timeslot,channel
    integer :: yyyymmdd, hhmmss, id, hdr_id, rttovkey, gpsrokey
    integer :: min_epoch, max_epoch
    character(len=:), allocatable :: errmsg
    logical :: on_error
    character(len=:), allocatable :: sqlhdr, sqlbody, sqlsat, sqlens
    type(fd4o_obsdata_t),allocatable :: datahdr, databody, datasat, dataens
    integer :: jhdr, jbody, jsat, jens
    integer, allocatable :: idxhdr(:), idxbody(:), idxsat(:), idxens(:)
    type(location_type) :: location
    type(time_type) :: obtime
    real(r8) :: obs_error_variance, lat, lon, levelht, prior
    real(r8) :: azimuth,zenith,mag_field,cosbk,fastem_p(5) ! mw
    real(r8) :: solar_azimuth,solar_zenith ! IR SM IASI
    ! gpsro next 3 lines: we only support GPSREF !!!
    real(r8) :: rfict0,ds,htop,nx,ny,nz
    integer :: subset0_index ! reflectivity: 0=N/A, local type: 1=GPSREF, non-local type/excess phase delay: 2=GPSEXC"
    character(len=6), parameter :: subset0(0:2) = ['N/A   ','GPSREF','GPSEXC'];
    integer :: num_copies, num_qc, num_obs, num_ens
    integer :: member, ens_id, ens_be
    integer, allocatable :: epoch(:)
    integer, allocatable :: time_index(:)
    character(len=20) :: clrc
    integer :: no_data, no_data_min
    logical :: has_sat, is_gpsro
    integer :: istatus_prior, ierr
    logical :: LLprior, LLshmem
    integer :: io_task
    real(r8), parameter :: specularity = 0.11111_r8
    
1000 format(a,5(:,1x,i0))
    
    if (dbs_max_alloc <= 0) return
    if (.not.allocated(dbs_catalog)) return
    ! prepare seq
    num_obs = 0
    if (associated(seq%obs)) num_obs = size(seq%obs(:))
    if (num_obs == 0) return

    io_task = 0
    LLprior = (i_d4o_departures == 0 .and. myrank >= 0) ! Now all tasks read the "ens" table when d4o_departures='NO' (but skip "prior" unless myrank = 0)

    LLshmem = (seq%windowsize > 0) ! the clearest indication that each node shares their seq%obs(:) data
    if (LLshmem) then
       ! Only node_rank = 0 (of each node) reads database file(s)
       ! sync_d4o_data() (and any other sync-) calls done outside this routine
       if (node_rank /= io_task) return
    endif
    
    ! only myrank 0 has num_copies and num_qc > 1 -- other tasks : just one element
    num_copies = 1 ! we always have seq%obs(:)%obsvalue now
    num_qc = 1 ! we always have seq%obs(:)%dataqc now

    if (associated(seq%spill)) then
       if (allocated(seq%spill(1)%xvalues)) num_copies = num_copies + size(seq%spill(1)%xvalues)
       if (allocated(seq%spill(1)%xqc)) num_qc = num_qc + size(seq%spill(1)%xqc)
    endif
    
    !num_ens = (num_copies - 5)/2 ! reverse engineering
    num_ens = get_d4o_numens_env() ! robust

    write(dio,*) myrank,': doread_d4o_data() : num_obs,num_copies,num_qc,num_ens=',num_obs,num_copies,num_qc,num_ens
    
    ! to get obs sequence in time order
    allocate(epoch(num_obs))
    allocate(time_index(0:num_obs+1))
    
    ! hdr-related items
    !sqlhdr = "SELECT id,timeslot,reportype,obstype,codetype,bufrtype,subtype,deglat,deglon"//& ! (lat,lon) in degrees (converted via SQLite virtual functions -- see ".schema hdr")
    sqlhdr = "SELECT id,timeslot,reportype,obstype,codetype,bufrtype,subtype,lat,lon"//&        ! (lat,lon) in radians (native)
         & ",yyyymmdd,hhmmss,epoch"//&
         & " FROM hdr"//&
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " WHERE hdr.status & 1 = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & " ORDER BY epoch,id"

    ! sat-related items (or NULL records whenever no actual data)
    sqlsat = "SELECT"//&
         & " IIF(rttov_sat_id IS NOT NULL,rttov_sat_id,sat_id) AS sat_id"//&
         & ",IIF(rttov_sensor_id IS NOT NULL,rttov_sensor_id,sensor_id) AS sensor_id"//&
         & ",platform_id,azimuth,zenith,solar_azimuth,solar_zenith"//&
         & " FROM hdr"//&
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " WHERE hdr.status & 1 = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & " ORDER BY epoch,id"

    ! body-related items

    if (LLprior) then
       sqlbody= "SELECT DISTINCT id,entryno,varno,kind,obsvalue,qc,dart_qc"//&
            & ",which_vert,levelht,obs_error_variance,channel"//&
            & ",prior_mean,prior_spread"//&
            & " FROM hdr"//&
            & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
            & " JOIN body ON id = body.hdr_id"//&
            & " JOIN ens ON body.hdr_id = ens.hdr_id AND entryno = body_entryno"//&
            & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1 AND ens.status & 1 = 1"//&
            & d4o_timeslot//&
            & d4o_hdr//&
            & d4o_body//&
            & d4o_ens//&
            & " ORDER BY epoch,id,entryno"
    else
       sqlbody= "SELECT id,entryno,varno,kind,obsvalue,qc,dart_qc"//&
            & ",which_vert,levelht,obs_error_variance,channel"//&
            & " FROM hdr"//&
            & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
            & " JOIN body ON id = body.hdr_id"//&
            & " WHERE hdr.status & 1 = 1 AND body.status & 1 = 1"//&
            & d4o_timeslot//&
            & d4o_hdr//&
            & d4o_body//&
            & " ORDER BY epoch,id,entryno"
    endif
    
    if (LLprior) then
       sqlens = "SELECT id,entryno,member,prior,istatus_prior"//&
         & " FROM hdr"//&
         & " LEFT OUTER JOIN sat ON id = sat.hdr_id"//&
         & " JOIN body ON id = body.hdr_id"//&
         & " JOIN ens ON body.hdr_id = ens.hdr_id AND entryno = body_entryno"//&
         & " WHERE hdr.status & 1 = 1 AND body.status & 1  = 1 AND ens.status & 1 = 1"//&
         & d4o_timeslot//&
         & d4o_hdr//&
         & d4o_body//&
         & d4o_ens//&
         & " ORDER BY epoch,id,entryno,member"
    endif
    
    ! In the subsequent nested loops over jhdr & jbody ...
    ! ... we will match [hdr.]id records from the sqlhdr with [body.]hdr_id records of the sqlbody
    ! And for the sqlsat : thanks to the LEFT OUTER JOIN we will *always* have some data ...
    ! ... (NULL if not a "proper" satellite) & fully aligned with "hdr"

    i = 0 ! Global DART sequence key

    ! Loop over available databases (of which one is normally the catalog ($d4o_catalog) and will be skipped)
    
    do jdb = 1, dbs_num_alloc
       if (.not.dbs(jdb)%is_data) cycle ! catalog db entry ? skip

       if (.not.dbs(jdb)%is_open) then
          dbs(jdb)%dbh = fd4o_opendb(dbs(jdb)%dbname,'r')
          if (dbs(jdb)%dbh >= 0) then
             dbs(jdb)%is_open = .TRUE.
             dbs(jdb)%is_readonly = .TRUE.
          endif
       endif

       has_sat = dbs(jdb)%has_sat
       no_data_min = 4
       
       if (dbs(jdb)%dbh >= 0) then
          ! When the "rc" from "err=rc" is >= 0 then that also indicates the number of rows available from "getdb"
          ! A "no data" -condition: the "rc" must not be in error (< 0) and "rc" must be > 0 i.e. so that at least one row is returned
          on_error = .FALSE.
          no_data = 0

          datahdr = fd4o_getdb(dbs(jdb)%dbh,sqlhdr,err=rc,rowmajor=.FALSE.)
          if (rc < 0) then
             write(clrc,'(i0)') rc
             errmsg = "Error: rc="//trim(clrc)//" from '"//trim(dbs(jdb)%dbname)//"'-database HDR-query : "//sqlhdr
             call fd4o_traceback(errmsg)
             on_error = .TRUE.
          else if (rc == 0) then
             no_data = no_data + 1
          endif

          if (has_sat) then
             datasat = fd4o_getdb(dbs(jdb)%dbh,sqlsat,err=rc,rowmajor=.FALSE.)
             if (rc < 0) then
                write(clrc,'(i0)') rc
                errmsg = "Error: rc="//trim(clrc)//" from '"//trim(dbs(jdb)%dbname)//"'-database SAT-query : "//sqlsat
                call fd4o_traceback(errmsg)
                on_error = .TRUE.
             else if (rc == 0) then
                no_data = no_data + 1
             endif
             
             if (no_data == 2) then ! Short-circuit#1 : No data from both HDR & SAT ; also implies on_error is still FALSE
                errmsg = "No data found satisfying the HDR/SAT SQL-conditions for database '"//trim(dbs(jdb)%dbname)//'"'
                if (d4o_debug) & 
                     & call fd4o_traceback(errmsg) ! No error -- skipping BODY queries, nested loops below & carrying on to the next database
                goto 9999
             endif
          
             if (.not.on_error) then
                if (datahdr%nrows /= datasat%nrows) then
                   errmsg = "Error: HDR & SAT queries from '"//trim(dbs(jdb)%dbname)//&
                        & "'-database should produce the same number of rows -- difference ="
                   call fd4o_traceback(errmsg,abs(datahdr%nrows - datasat%nrows))
                   on_error = .TRUE.
                endif
             endif
          else
             no_data_min = no_data_min - 1
          endif
          
          databody = fd4o_getdb(dbs(jdb)%dbh,sqlbody,err=rc,rowmajor=.FALSE.)
          if (rc < 0) then
             write(clrc,'(i0)') rc
             errmsg = "Error: rc="//trim(clrc)//" from '"//trim(dbs(jdb)%dbname)//"'-database BODY-query : "//sqlbody
             call fd4o_traceback(errmsg)
             on_error = .TRUE.
          else if (rc == 0) then
             no_data = no_data + 1
          endif

          if (LLprior) then
             dataens = fd4o_getdb(dbs(jdb)%dbh,sqlens,err=rc,rowmajor=.FALSE.)
             if (rc < 0) then
                write(clrc,'(i0)') rc
                errmsg = "Error: rc="//trim(clrc)//" from '"//trim(dbs(jdb)%dbname)//"'-database ENS-query : "//sqlens
                call fd4o_traceback(errmsg)
                on_error = .TRUE.
             else if (rc == 0) then
                no_data = no_data + 1
             endif
          endif

          if (on_error) then ! A definitive error
             call error_handler(E_ERR, 'doread_d4o_data', &
                  & 'issues in one or more HDR/SAT/BODY (and possibly ENS) queries earlier', source, lineno=__LINE__)
          endif

          if (no_data >= no_data_min) then ! Short-circuit#2 : No data from all queries abobe
             errmsg = "No data found satisfying the SQL-conditions for database '"//trim(dbs(jdb)%dbname)//'"'
             if (d4o_debug) & 
                  & call fd4o_traceback(errmsg) ! No error -- skipping nested loops below & carrying on to the next database
             goto 9999
          else if (no_data /= 0) then ! An error : cannot be that some SQLs return something -- must be all or nothing
             errmsg = "Some SQLs did not return any rows for database '"//trim(dbs(jdb)%dbname)//'"'
             call fd4o_traceback(errmsg//' : no_data=',no_data)
             call error_handler(E_ERR, 'doread_d4o_data', &
                  & errmsg, source, lineno=__LINE__)
          endif
          
          dbs(jdb)%start_seq_i = i + 1

          !if (d4o_debug) call fd4o_print(dio,datahdr,limit=5,msg="HDR") ! debug only
          if (.not.allocated(idxhdr)) then
             allocate(idxhdr(datahdr%ncols))
             !idxhdr(1) = fd4o_colidx(datahdr%qh,"deglat")
             !idxhdr(2) = fd4o_colidx(datahdr%qh,"deglon") ! SQLite def deglon := mod(degrees(lon)+360,360) drops one bit => bit reprod. problem
             idxhdr(1) = fd4o_colidx(datahdr%qh,"lat") ! radians
             idxhdr(2) = fd4o_colidx(datahdr%qh,"lon") ! radians
             idxhdr(3) = fd4o_colidx(datahdr%qh,"yyyymmdd")
             idxhdr(4) = fd4o_colidx(datahdr%qh,"hhmmss")
             idxhdr(5) = fd4o_colidx(datahdr%qh,"id")
             idxhdr(6) = fd4o_colidx(datahdr%qh,"obstype")
             idxhdr(7) = fd4o_colidx(datahdr%qh,"codetype")
             idxhdr(8) = fd4o_colidx(datahdr%qh,"timeslot")
             idxhdr(9) = fd4o_colidx(datahdr%qh,"bufrtype")
             idxhdr(10) = fd4o_colidx(datahdr%qh,"subtype")
             idxhdr(11) = fd4o_colidx(datahdr%qh,"reportype")
             idxhdr(12) = fd4o_colidx(datahdr%qh,"epoch")
          endif

          if (has_sat) then
             !if (d4o_debug) call fd4o_print(dio,datasat,limit=5,msg="SAT") ! debug only
             if (.not.allocated(idxsat)) then
                allocate(idxsat(datasat%ncols))
                idxsat(1) = fd4o_colidx(datasat%qh,"sat_id") ! usually rttov_sat_id unless it is NULL, then (ECMWF) sat_id
                idxsat(2) = fd4o_colidx(datasat%qh,"sensor_id") ! usually rttov_sensor_id unless it is NULL, then (ECMWF) sensor_id
                idxsat(3) = fd4o_colidx(datasat%qh,"platform_id")
                idxsat(4) = fd4o_colidx(datasat%qh,"azimuth")
                idxsat(5) = fd4o_colidx(datasat%qh,"zenith")
                idxsat(6) = fd4o_colidx(datasat%qh,"solar_azimuth")
                idxsat(7) = fd4o_colidx(datasat%qh,"solar_zenith")
             endif
          endif

          !if (d4o_debug) call fd4o_print(dio,databody,limit=5,msg="BODY") ! debug only
          if (.not.allocated(idxbody)) then
             allocate(idxbody(databody%ncols))
             idxbody(1) = fd4o_colidx(databody%qh,"obsvalue")
             idxbody(2) = fd4o_colidx(databody%qh,"qc")
             idxbody(3) = fd4o_colidx(databody%qh,"varno")
             idxbody(4) = fd4o_colidx(databody%qh,"obs_error_variance")
             idxbody(5) = fd4o_colidx(databody%qh,"levelht")
             idxbody(6) = fd4o_colidx(databody%qh,"which_vert")
             idxbody(7) = fd4o_colidx(databody%qh,"id")
             idxbody(8) = fd4o_colidx(databody%qh,"kind")
             idxbody(9) = fd4o_colidx(databody%qh,"channel")
             idxbody(10) = fd4o_colidx(databody%qh,"entryno")
             idxbody(11) = fd4o_colidx(databody%qh,"dart_qc")
             if (LLprior) then
                idxbody(12) = fd4o_colidx(databody%qh,"prior_mean")
                idxbody(13) = fd4o_colidx(databody%qh,"prior_spread")
             endif
          endif

          if (LLprior) then
             if (.not.allocated(idxens)) then
                allocate(idxens(dataens%ncols))
                idxens(1) = fd4o_colidx(dataens%qh,"id")
                idxens(2) = fd4o_colidx(dataens%qh,"entryno")
                idxens(3) = fd4o_colidx(dataens%qh,"member")
                idxens(4) = fd4o_colidx(dataens%qh,"prior")
                idxens(5) = fd4o_colidx(dataens%qh,"istatus_prior")
             endif
          endif

          ! Fixed for "life"
          mag_field = fd4o_null()
          cosbk = fd4o_null()
          fastem_p(1:5) = [3.0_r8,5.0_r8,15.0_r8,0.1_r8,0.3_r8]
          
          jbody = 0
          jens = 0
          hdrloop: do jhdr=1,datahdr%nrows
             if (has_sat) jsat = jhdr ! Always

             ! HDR
             lat = datahdr%d(idxhdr(1),jhdr) ! now in radians and between -pi/2 .. +pi/2
             lon = datahdr%d(idxhdr(2),jhdr) ! now in radians and from BUFR between -pi .. +pi
             lon = mod(lon + twopi, twopi)   ! Dart requires longitudes to be between 0 .. 2*pi
             this_epoch = datahdr%d(idxhdr(12),jhdr)
             yyyymmdd = datahdr%d(idxhdr(3),jhdr)
             hhmmss = datahdr%d(idxhdr(4),jhdr)
             if (.not.fd4o_is_null(yyyymmdd) .and. .not.fd4o_is_null(hhmmss)) then
                obtime = set_date(&
                     & yyyymmdd/10000,mod(yyyymmdd,10000)/100,mod(yyyymmdd,100),&
                     & hhmmss/10000,mod(hhmmss,10000)/100,mod(hhmmss,100))
             else
                obtime = set_time_missing()
             endif
             id = datahdr%d(idxhdr(5),jhdr)
             reportype = datahdr%d(idxhdr(12),jhdr)
             obstype = datahdr%d(idxhdr(6),jhdr)
             codetype = datahdr%d(idxhdr(7),jhdr)
             timeslot = datahdr%d(idxhdr(8),jhdr)
             bufrtype = datahdr%d(idxhdr(9),jhdr)
             subtype = datahdr%d(idxhdr(10),jhdr)

             ! SAT
             if (has_sat) then
                sat_id = datasat%d(idxsat(1),jsat)
                sensor_id = datasat%d(idxsat(2),jsat)
                platform_id = datasat%d(idxsat(3),jsat)
                azimuth = datasat%d(idxsat(4),jsat)
                zenith = datasat%d(idxsat(5),jsat)
                solar_azimuth = datasat%d(idxsat(6),jsat)
                solar_zenith = datasat%d(idxsat(7),jsat)
             else
                sat_id = fd4o_null()
                sensor_id = fd4o_null()
                platform_id = fd4o_null()
             endif

             bodyloop: do while (jbody < databody%nrows)
                hdr_id = databody%d(idxbody(7),jbody+1)
                if (hdr_id /= id) exit bodyloop

                jbody = jbody + 1

                i = i + 1

                ! for time index sorting
                epoch(i) = this_epoch

                ! BODY

                entryno = databody%d(idxbody(10),jbody)

                if ((num_copies > 1 .or. num_qc > 1).and.associated(seq%spill)) then
                   call init_obs(seq%obs(i),num_copies,num_qc,fill=.TRUE.,spill=seq%spill(i))
                else
                   call init_obs(seq%obs(i),num_copies,num_qc,fill=.TRUE.)
                endif
                
                seq%obs(i)%key = i
                seq%obs(i)%obsvalue = databody%d(idxbody(1),jbody) ! obsvalue
                seq%obs(i)%dataqc = databody%d(idxbody(2),jbody) ! qc
                if (myrank == 0) seq%spill(i)%xqc(2) = databody%d(idxbody(11),jbody) ! only the task#0 stores dart_qc

                if (LLprior) then
                   if (myrank == 0) then ! only the task#0 stores these
                      seq%spill(i)%xvalues(2) = databody%d(idxbody(12),jbody) ! prior_mean
                      seq%spill(i)%xvalues(4) = databody%d(idxbody(13),jbody) ! prior_spread
                      allocate(seq%spill(i)%istatus_prior(num_ens))
                      seq%spill(i)%istatus_prior = 0
                   endif
                   ensloop: do while (jens < dataens%nrows)
                      ens_id = dataens%d(idxens(1),jens+1)
                      ens_be = dataens%d(idxens(2),jens+1)
                      if (ens_id /= id .or. ens_be /= entryno) exit ensloop
                      jens = jens + 1
                      member = dataens%d(idxens(3),jens) ! member number
                      if (myrank == 0) then
                         ! only myrank = 0 has got %xvalues() allocated & istatus_prior
                         prior = dataens%d(idxens(4),jens) ! prior in concern
                         seq%spill(i)%xvalues(5+2*(member-1)+1) = prior
                         istatus_prior = dataens%d(idxens(5),jens)
                         seq%spill(i)%istatus_prior(member) = istatus_prior 
                      endif
                   enddo ensloop
                endif
                
                levelht = databody%d(idxbody(5),jbody)
                which_vert = databody%d(idxbody(6),jbody) 

                location = set_location(&
                     !DART:  lon  lat   vloc    which_vert
                     &       lon, lat, levelht, which_vert, radians=.TRUE.)

                obs_error_variance = databody%d(idxbody(4),jbody)
                !!if (.not.fd4o_is_null(obs_error)) obs_error = obs_error**2 ! error covariance

                varno = databody%d(idxbody(3),jbody) ! ECMWF

                kind = databody%d(idxbody(8),jbody)
                call init_obs_def(seq%obs(i)%def,location,kind,obtime,obs_error_variance)
                call set_obs_def_key(seq%obs(i)%def,0)

#ifdef _camfv_
                channel = databody%d(idxbody(9),jbody)
                is_gpsro = (varno == 301)
                if (is_gpsro) then
                   call set_gpsro_ref(gpsrokey) ! Always 'GPSREF'
                   call set_obs_def_key(seq%obs(i)%def,gpsrokey)
                else if (has_sat .and. .not.fd4o_is_null(channel)) then
                   if (sensor_id == 3) then
                      ! MW-data sensor_id==3
                      rttovkey = fd4o_null()
                      call set_mw_metadata(rttovkey, azimuth, zenith, platform_id, sat_id, sensor_id, &
                           & channel, mag_field, cosbk, fastem_p(1), fastem_p(2), fastem_p(3), &
                           & fastem_p(4), fastem_p(5))
                      call set_obs_def_key(seq%obs(i)%def,rttovkey)
                   else if (sensor_id == 16) then
                      ! IR-data IASI sensor_id==16
                      rttovkey = fd4o_null()
                      call set_iasiir_metadata(rttovkey, azimuth, zenith, solar_azimuth, solar_zenith, platform_id, sat_id, sensor_id, &
                           & channel, specularity) 
                      ! specularity ! specularity (0-1, only used with do_lambertian) 
                      call set_obs_def_key(seq%obs(i)%def,rttovkey)
                   endif
                endif   ! SAT ASSIM
#endif

                ! Fill in ECMWF entries
#if 0
                seq%obs(i)%ecmwf%timeslot = timeslot
                seq%obs(i)%ecmwf%varno = varno
                seq%obs(i)%ecmwf%reportype = reportype
                seq%obs(i)%ecmwf%obstype = obstype
                seq%obs(i)%ecmwf%codetype = codetype
                seq%obs(i)%ecmwf%bufrtype = bufrtype
                seq%obs(i)%ecmwf%subtype = subtype
                seq%obs(i)%ecmwf%sat_id = sat_id
                seq%obs(i)%ecmwf%sensor_id = sensor_id
                !seq%obs(i)%ecmwf%sat_instr = sat_instr
                seq%obs(i)%ecmwf%platform_id = platform_id
#endif
                ! To be frank (and to save space), we probably only need these 2 :
                seq%obs(i)%ecmwf%hdr_id = hdr_id
                seq%obs(i)%ecmwf%body_entryno = entryno 
             enddo bodyloop

          enddo hdrloop

          dbs(jdb)%end_seq_i = i

9999      continue
          
          rc = fd4o_delete(datahdr)
          if (has_sat) rc = fd4o_delete(datasat)
          rc = fd4o_delete(databody)
          if (LLprior) rc = fd4o_delete(dataens)

          ! No need to leave this open
          rc = fd4o_closedb(dbs(jdb)%dbh)
          
          dbs(jdb)%dbh = -1
          dbs(jdb)%is_open = .FALSE.
       endif ! if (dbs(jdb)%dbh >= 0) then
    enddo ! do jdb = 1, dbs_num_alloc

    if (i /= num_obs) then
       allocate(character(len=128)::errmsg)
       write(errmsg,'(a,i0,a,i0,a)') &
            & "Expected number of obs must be exactly = ",num_obs,&
            & ", but got ",i," !!!"
       call error_handler(E_ERR, 'doread_d4o_data', &
            & errmsg, source, lineno=__LINE__)
    endif

    ! After prepending "epoch" in ORDER BY's this sorting becomes less nearly a no-op
    ! time_index(1:num_obs) should in fact now be [1 .. num_obs] directly :: TRUE ONLY if ONE pool of data
    ! Keep the coding since multiple pools cannot preserve time order -- thus timesorting NEEDED
    
    time_index(0) = -1
    call fd4o_rsort32(1,num_obs,1,1,epoch,time_index(1),1,rc)
    time_index(num_obs+1) = -1

    if (rc /= num_obs) then
       allocate(character(len=128)::errmsg)
       write(errmsg,'(a,i0,a,i0,a)') &
            & "Sorting failed: expected rc=",num_obs,&
            & ", but got ",rc," !!!"
       call error_handler(E_ERR, 'doread_d4o_data', &
            & errmsg, source, lineno=__LINE__)
    endif

    prev_time = time_index(0)
    do j=1,num_obs
       i = time_index(j)
       seq%obs(i)%prev_time = prev_time
       seq%obs(i)%next_time = time_index(j+1)
       prev_time = i
    enddo

    seq%first_time = time_index(1)
    seq%last_time = time_index(num_obs)
    
    deallocate(time_index)
    deallocate(epoch)

  end subroutine doread_d4o_data
  
  subroutine dowrite_d4o_data(seq)
    type(obs_sequence_type), intent(in) :: seq
    
    character(len=:), allocatable :: sql
    integer :: rc, i, jdb, nrows, ncols_body, ncols_ens, j, ii, e, k, hdr_id, entryno
    real(r8), allocatable :: body(:,:)  ! rowmajor = .FALSE. => ncols x nrows
    real(r8), allocatable :: ens(:,:) ! rowmajor = .FALSE. => ncols x (nrows x ens_size)
    real(r8) :: dart_qc, prior, posterior
    integer :: maxrows ! the actual number of (consecutive) rows that will be updated aka limit-option to putdb
    logical :: LLreopen, LLadvance, LLinvoke_rmscalc
    integer :: istatus_prior
    integer :: d4o_update_threads, itmp, istat
    character(len=4) :: clenv
    
    if (dbs_max_alloc <= 0) return
    if (.not.allocated(dbs_catalog)) return

    if (myrank /= 0) return ! Only task#0 does UPDATEs at the moment

    d4o_update_threads = 1
    call get_environment_variable('d4o_update_threads',clenv)
    if (clenv /= ' ') then
       read(clenv,*,iostat=istat) itmp
       if (istat == 0) then
          d4o_update_threads = max(1,min(itmp,dbs_num_alloc-1)) ! dbs_num_alloc minus one since there is always one catalog.db that which we skip
       endif
    endif
    
    write(dio,'(1x,i0,a,i0,a,i0,a)') &
         myrank,': dowrite_d4o_data() : Updating up to ',dbs_num_alloc-1,' databases using d4o_update_threads=',d4o_update_threads,' OpenMP-threads ...'
    
    !$omp  parallel default(shared) num_threads(d4o_update_threads) &
    !$omp& private(jdb,LLreopen,rc,nrows,ncols_body,ii,i,hdr_id,entryno) &
    !$omp& private(dart_qc,sql,body,ens,ncols_ens,k,e,LLadvance,prior,posterior,istatus_prior,maxrows)
    !$omp  do schedule(dynamic,1)
    
    do jdb = 1, dbs_num_alloc ! a candidate for being an OpenMP-loop
       if (.not.dbs(jdb)%is_data) cycle ! catalog db entry ? skip
       if (.not.dbs(jdb)%is_writable) cycle ! not "my" database (data pool) -- in practice just myrank == 0
       
       LLreopen = .not.dbs(jdb)%is_open
       if (dbs(jdb)%is_open .and. dbs(jdb)%is_readonly) then ! re-open for write
          rc = fd4o_closedb(dbs(jdb)%dbh)
          dbs(jdb)%is_open = .FALSE.
          LLreopen = .TRUE.
       endif
       if (LLreopen) then
          dbs(jdb)%dbh = fd4o_opendb(dbs(jdb)%dbname,'w', cascade= .FALSE.)
          if (dbs(jdb)%dbh >= 0) then
             dbs(jdb)%is_open = .TRUE.
             dbs(jdb)%is_readonly = .FALSE.
          else
             call error_handler(E_ERR, 'dowrite_d4o_data',&
                  & 'could not open database "'//trim(dbs(jdb)%dbname)//'" for writing',&
                  & source, lineno=__LINE__)
          endif
       endif
       
       if (dbs(jdb)%is_open) then
          write(dio,'(1x,i0,a)') &
               myrank,': dowrite_d4o_data() : Updating database "'//trim(dbs(jdb)%dbname)//'" ...'
          nrows = dbs(jdb)%end_seq_i - dbs(jdb)%start_seq_i + 1
          ! we will update in the body-table the following entries -- total 5 :
          ! prior_mean,posterior_mean,prior_spread,posterior_spread,dart_qc
          ! in each ens-member (providing ens_size > 0) we update 2 values :
          ! ens.prior     ! ens.fg_depar would be body.obsvalue-ens.prior
          ! ens.posterior ! ens.an_depar would be body.obsvalue-ens.posterior
          if (nrows > 0) then
             ncols_body = 2 ! for referencing purposes only : hdr_id & entryno
             if (i_d4o_departures == -1) then ! [d4o_departures=ALL] updated : dart_qc + prior/posterior mean/spread
                ncols_body = ncols_body + 5
             else if (i_d4o_departures == 1) then ! [d4o_departures=YES] updated : dart_qc + only prior mean/spread
                ncols_body = ncols_body + 3
             else if (i_d4o_departures == 0) then ! [d4o_departures=NO] updated : dart_qc + only posterior mean/spread
                ncols_body = ncols_body + 3
             endif
             allocate(body(ncols_body,nrows)) ! rowmajor = .FALSE. for speed
             ii = 1
             do i=dbs(jdb)%start_seq_i,dbs(jdb)%end_seq_i
                !obsvalue = seq%obs(i)%obsvalue
                hdr_id = seq%obs(i)%ecmwf%hdr_id
                body(1,ii) = hdr_id
                entryno = seq%obs(i)%ecmwf%body_entryno
                body(2,ii) = entryno
                dart_qc = seq%spill(i)%xqc(2)
                body(3,ii) = dart_qc
                if (i_d4o_departures == -1) then
                   body(4:7,ii) = seq%spill(i)%xvalues(1+1:1+4) ! i.e. 2:5
                else if (i_d4o_departures == 1) then
                   body(4,ii) = seq%spill(i)%xvalues(2) ! prior mean
                   body(5,ii) = seq%spill(i)%xvalues(4) ! prior spread
                else if (i_d4o_departures == 0) then
                   body(4,ii) = seq%spill(i)%xvalues(3) ! posterior mean
                   body(5,ii) = seq%spill(i)%xvalues(5) ! posterior spread
                endif
                ii = ii + 1
             enddo
             
             ! Hint: the "x" in ?x corresponds to the first dimension of the body-array (when rowmajor=.FALSE.)
             if (i_d4o_departures == -1) then ! [d4o_departures=ALL]
                sql = "dart_qc = ?3,prior_mean = ?4,posterior_mean = ?5,prior_spread = ?6,posterior_spread = ?7" ! body(3:7,:)
             else if (i_d4o_departures == 1) then ! [d4o_departures=YES]
                sql = "dart_qc = ?3,prior_mean = ?4,prior_spread = ?5" ! body(3:5,:)
             else if (i_d4o_departures == 0) then ! [d4o_departures=NO]
                sql = "dart_qc = ?3,posterior_mean = ?4,posterior_spread = ?5" ! body(3:5,:)
             endif
             sql = "UPDATE body SET " // sql // " WHERE hdr_id = ?1 AND entryno = ?2"
             rc = fd4o_putdb(dbs(jdb)%dbh,body,rowmajor=.FALSE.,query=sql)
             write(dio,'(1x,i0,a,i0)') &
                  myrank,": dowrite_d4o_data() : UPDATE body of '"//trim(dbs(jdb)%dbname)//"' : rows=",rc
             deallocate(body)
             if (dbs_numens_env > 0) then
                ncols_ens = 3 + 1 ! referencing = (hdr_id,body_entryno,member) + either prior or posterior for update
                if (i_d4o_departures == -1) ncols_ens = ncols_ens + 1 ! add one for posterior or prior
                if (i_d4o_departures ==  1) ncols_ens = ncols_ens + 1 ! add one for istatus_prior
                allocate(ens(ncols_ens,nrows*dbs_numens_env)) ! rowmajor = .FALSE. for speed
                ii = 1
                do i=dbs(jdb)%start_seq_i,dbs(jdb)%end_seq_i
                   !obsvalue = seq%obs(i)%obsvalue
                   hdr_id = seq%obs(i)%ecmwf%hdr_id
                   entryno = seq%obs(i)%ecmwf%body_entryno
                   k = 5
                   do e=1,dbs_numens_env
                      LLadvance = .FALSE.
                      prior = seq%spill(i)%xvalues(k+1) ! prior of e
                      posterior = seq%spill(i)%xvalues(k+2) ! posterior of e 
                      if (i_d4o_departures == -1) then ! [d4o_departures=ALL]
                         LLadvance = (.not.fd4o_is_null(prior) .or. .not.fd4o_is_null(posterior))
                         if (LLadvance) then
                            ens(4,ii) = prior
                            ens(5,ii) = posterior
                         endif
                      else if (i_d4o_departures == 1) then ! [d4o_departures=YES]
                         istatus_prior = seq%spill(i)%istatus_prior(e)
                         LLadvance = .not.fd4o_is_null(prior) .or. (istatus_prior /= 0)
                         if (LLadvance) then
                            ens(4,ii) = prior
                            ens(5,ii) = istatus_prior
                         endif
                      else if (i_d4o_departures == 0) then ! [d4o_departures=NO]
                         LLadvance = .not.fd4o_is_null(posterior)
                         if (LLadvance) ens(4,ii) = posterior
                      endif
                      if (LLadvance) then
                         ens(1,ii) = hdr_id
                         ens(2,ii) = entryno
                         ens(3,ii) = e ! the ensemble member number
                         !ens(4,ii) = obsvalue - seq%spill(i)%xvalues(k+1) ! was fg_depar
                         !ens(5,ii) = obsvalue - seq%spill(i)%xvalues(k+2) ! was an_depar
                         ii = ii + 1
                      endif
                      k = k + 2
                   enddo
                enddo
                maxrows = ii - 1

                LLinvoke_rmscalc = .FALSE. ! .TRUE. when d4o_departures=ALL or NO i.e. when BOTH prior & posterior have been stored
                if (maxrows > 0) then
                   ! A hint: the "x" in ?x corresponds to the first dimension of the ens-array (when rowmajor=.FALSE.)
                   sql = "UPDATE ens SET "
                   if (i_d4o_departures == -1) then ! [d4o_departures=ALL]
                      sql = sql // "prior = ?4,posterior = ?5" ! ens(4:5,:)
                      LLinvoke_rmscalc = .TRUE.
                   else if (i_d4o_departures == 1) then ! [d4o_departures=YES]
                      sql = sql // "prior = ?4,istatus_prior = ?5" ! ens(4:5,:)
                   else if (i_d4o_departures == 0) then ! [d4o_departures=NO]
                      sql = sql // "posterior = ?4" ! ens(4,:)
                      LLinvoke_rmscalc = .TRUE.
                   endif
                   sql = sql // " WHERE hdr_id = ?1 AND body_entryno = ?2 AND member = ?3"
                   rc = fd4o_putdb(dbs(jdb)%dbh,ens,rowmajor=.FALSE.,limit=maxrows,query=sql)
                else
                   rc = 0
                endif
                
                write(dio,'(1x,i0,a,i0,a,i0)') &
                     myrank,": dowrite_d4o_data() : UPDATE ens of '"//trim(dbs(jdb)%dbname)//"' : rows=",rc,' of ',size(ens,dim=2)

                deallocate(ens)

                if (LLinvoke_rmscalc) then
                   write(dio,'(1x,i0,a)') &
                        myrank,": dowrite_d4o_data() : Updating body.rms & body.rmse for '"//trim(dbs(jdb)%dbname)//"' ..."
                   !sql = "UPDATE body SET rms  = (SELECT rms  FROM rmscalc WHERE body.hdr_id=id and body.entryno = entryno)"
                   sql = "UPDATE body SET rms  = r.rms  FROM (SELECT rms ,id,entryno FROM rmscalc) AS r WHERE body.hdr_id=r.id and body.entryno = r.entryno" ! more correct
                   rc = fd4o_exec(dbs(jdb)%dbh,sql)
                   write(dio,'(1x,i0,a,i0)') myrank,": dowrite_d4o_data() : '"//sql//"' : body.rms rc=",rc
                   !sql = "UPDATE body SET rmse = (SELECT rmse FROM rmscalc WHERE body.hdr_id=id and body.entryno = entryno)"
                   sql = "UPDATE body SET rmse = r.rmse FROM (SELECT rmse,id,entryno FROM rmscalc) AS r WHERE body.hdr_id=r.id and body.entryno = r.entryno" ! more correct
                   rc = fd4o_exec(dbs(jdb)%dbh,sql)
                   write(dio,'(1x,i0,a,i0)') myrank,": dowrite_d4o_data() : '"//sql//"' : body.rmse rc=",rc
                endif
             endif
          endif

          rc = fd4o_closedb(dbs(jdb)%dbh)
          dbs(jdb)%is_open = .FALSE.
          dbs(jdb)%dbh = -1
       endif
    enddo
    !$omp end do
    !$omp end parallel
  end subroutine dowrite_d4o_data

  subroutine get_d4o_aux(io_task,seq,istatus_prior,prior,ierr,comm)
    ! Called when d4o_departures=NO (phase-2)
    ! Fetches istatus_prior (aka ens.istatus_prior) and prior-values (aka ens.prior)
    ! that are stored in task#0's seq%spill(:)%istatus_prior(member) & seq%spill(:)%xvalues(5+2*(member-1)+1), member=1,num_ens
    ! and get restored into istatus_prior(1:num_ens,num_obs) & prior(1:num_ens,num_obs) structures
    ! ierr returns the global number of obs num_obs >= num_obs_local determined from the size (length) of seq%obs(:)
    integer, intent(in) :: io_task
    type(obs_sequence_type), intent(in) :: seq
    integer(d4o_int1), intent(out), allocatable :: istatus_prior(:,:) ! num_obs x num_ens
    real(r8),intent(out), allocatable :: prior(:,:)            ! num_obs x num_ens
    integer, intent(out) :: ierr
    integer, intent(in), optional :: comm
    integer :: num_ens, num_obs
    integer :: icomm, mype, npes
    integer :: i, member, retcode, ilen, idummy
    character(len=:), allocatable :: errmsg
    character(len=:), allocatable :: candidate
    character(len=80) :: mpierrstr

    num_obs = 0
    if (associated(seq%obs)) num_obs = size(seq%obs(:))
    num_ens = get_d4o_numens_env()
    ierr = num_obs
    retcode = MPI_SUCCESS
    candidate = ' '
    icomm = MPI_COMM_WORLD
    if (present(comm)) icomm = comm
    mype = -1
    npes = 0

    CALL MPI_Comm_rank(icomm, mype, retcode)
    if (retcode /= MPI_SUCCESS) then
       ierr = -11
       CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
       candidate = '? MPI_Comm_rank(icomm, mype, retcode) : '//mpierrstr(1:ilen)
       goto 9999
    endif
    
    CALL MPI_Comm_size(icomm, npes, retcode)
    if (retcode /= MPI_SUCCESS) then
       ierr = -12
       CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
       candidate = '? MPI_Comm_size(icomm, npes, retcode) : '//mpierrstr(1:ilen)
       goto 9999
    endif

    if (num_ens <= 0) then
       ierr = -1
       candidate = '? num_ens <= 0'
    else if (num_obs /= size(seq%obs(:))) then
       ierr = -2
       candidate = '? num_obs /= size(seq%obs(:))'
    else if (mype == io_task .and. .not.allocated(seq%spill(1)%istatus_prior)) then
       ierr = -3
       candidate = '? mype == io_task .and. .not.allocated(seq%spill(1)%istatus_prior)'
    else if (allocated(istatus_prior) .or. allocated(prior)) then
       ierr = -4
       candidate = '? allocated(istatus_prior) .or. allocated(prior)'
    else ! all ok so far
       ierr = num_obs
       if (ierr == 0) return

       !! potentially huge arrays !!
       allocate(istatus_prior(num_obs,num_ens))
       allocate(prior(num_obs,num_ens))
       
       do member=1,num_ens
          if (mype == io_task) then
             ! Fill in ibuf & rbuf
             do i=1,num_obs
                istatus_prior(i,member) = seq%spill(i)%istatus_prior(member) ! our precious "istatus"
                prior(i,member) = seq%spill(i)%xvalues(5+2*(member-1)+1) ! our precious "expected_obs"
             enddo
          endif

          CALL MPI_Bcast(istatus_prior(1,member),num_obs,d4o_mpi_integer1,io_task,icomm,retcode)
          if (retcode /= MPI_SUCCESS) then
             ierr = -(100*member+1)
             CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
             candidate = '? MPI_Bcast(istatus_prior(1,member),num_obs,d4o_mpi_integer1,io_task,icomm,retcode) : '//mpierrstr(1:ilen)
             goto 9999
          endif
          CALL MPI_Barrier(icomm, retcode)
          if (retcode /= MPI_SUCCESS) call fd4o_exit('get_d4o_aux: MPI_Barrier (1st) returned error code ',retcode,1)
          
          CALL MPI_Bcast(prior(1,member),num_obs,MPI_REAL8,io_task,icomm,retcode)
          if (retcode /= MPI_SUCCESS) then
             ierr = -(100*member+2)
             CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
             candidate = '? MPI_Bcast(prior(1,member),num_obs,MPI_REAL8,io_task,icomm,retcode) : '//mpierrstr(1:ilen)
             goto 9999
          endif
          CALL MPI_Barrier(icomm, retcode)
          if (retcode /= MPI_SUCCESS) call fd4o_exit('get_d4o_aux: MPI_Barrier (2nd) returned error code ',retcode,1)
       enddo ! do member=1,num_ens

    endif
    
9999 continue
    
    if (ierr /= num_obs) then
       allocate(character(len=4096)::errmsg)
       write(errmsg,'(a,i0,a,5(i0,:,1x),a)') &
            & 'Something went wrong in get_d4o_aux() on task#',mype,&
            & ' num_obs,num_ens,ierr,retcode,icomm=',&
            &   num_obs,num_ens,ierr,retcode,icomm,&
            & trim(candidate)
       call error_handler(E_ERR, 'get_d4o_aux', trim(errmsg), source, lineno=__LINE__)
    endif
  end subroutine get_d4o_aux
  
  subroutine put_d4o_aux(io_task,seq,istatus_prior,ierr,comm)
    ! Called when d4o_departures=YES (phase-1)
    ! Each participating task send its istatus_prior to task#0, which
    ! stores it into its seq%spill(:)%istatus_prior for database update on ens.istatus_prior
    integer, intent(in) :: io_task
    type(obs_sequence_type), intent(inout) :: seq
    integer(d4o_int1), intent(in) :: istatus_prior(:,:) ! num_obs x num_ens
    integer, intent(out) :: ierr
    integer, intent(in), optional :: comm
    integer(d4o_int1), allocatable :: ibuf(:)
    integer :: num_ens, num_obs
    integer :: icomm, mype, npes
    integer :: i, member, retcode, ilen, idummy
    integer(d4o_int1) :: idumber1
    character(len=:), allocatable :: errmsg
    character(len=:), allocatable :: candidate
    character(len=80) :: mpierrstr
    
    num_obs = 0
    if (associated(seq%obs)) num_obs = size(seq%obs(:))
    num_ens = size(istatus_prior,dim=2)
    ierr = num_obs
    retcode = MPI_SUCCESS
    candidate = ' '
    icomm = MPI_COMM_WORLD
    if (present(comm)) icomm = comm
    mype = -1
    npes = 0

    CALL MPI_Comm_rank(icomm, mype, retcode)
    if (retcode /= MPI_SUCCESS) then
       ierr = -11
       CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
       candidate = '? MPI_Comm_rank(icomm, mype, retcode) : '//mpierrstr(1:ilen)
       goto 9999
    endif
    
    CALL MPI_Comm_size(icomm, npes, retcode)
    if (retcode /= MPI_SUCCESS) then
       ierr = -12
       CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
       candidate = '? MPI_Comm_size(icomm, npes, retcode) : '//mpierrstr(1:ilen)
       goto 9999
    endif

    if (num_ens /= get_d4o_numens_env()) then
       ierr = -1
       candidate = '? num_ens /= get_d4o_numens_env()'
    else if (num_obs /= size(seq%obs(:))) then
       ierr = -2
       candidate = '? num_obs /= size(seq%obs(:))'
    else if (num_obs /= size(istatus_prior,dim=1)) then
       ierr = -3
       candidate = '? num_obs /= size(istatus_prior,dim=1)'
    else if (mype == io_task .and. allocated(seq%spill(1)%istatus_prior)) then
       ierr = -4
       candidate = '? mype == io_task .and. allocated(seq%spill(1)%istatus_prior)'
    else ! all ok so far
       ierr = num_obs
       if (ierr == 0) return

       allocate(ibuf(num_obs))

       do member=1,num_ens
          ibuf(:) = istatus_prior(:,member) ! It's assumed that every index (:) is updated by a single task only
          IF (mype == io_task) THEN          
             CALL MPI_Reduce(MPI_IN_PLACE,ibuf,num_obs,d4o_mpi_integer1,MPI_SUM,io_task,icomm,retcode)
             if (retcode /= MPI_SUCCESS) then
                ierr = -(100*member + 1)
                CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
                candidate = '? MPI_Reduce(MPI_IN_PLACE,ibuf,num_obs,d4o_mpi_integer1,MPI_SUM,io_task,icomm,retcode) : '//mpierrstr(1:ilen)
                goto 9999
             endif
             if (member == 1) then
                do i=1,num_obs
                   allocate(seq%spill(i)%istatus_prior(num_ens))
                enddo
             endif
             do i=1,num_obs
                seq%spill(i)%istatus_prior(member) = ibuf(i)
             enddo
          ELSE
             CALL MPI_Reduce(ibuf,idumber1,num_obs,d4o_mpi_integer1,MPI_SUM,io_task,icomm,retcode)
             if (retcode /= MPI_SUCCESS) then
                ierr = -(100*member + 2)
                CALL MPI_Error_string(retcode, mpierrstr, ilen, idummy)
                candidate = '? MPI_Reduce(ibuf,idumber1,num_obs,d4o_mpi_integer1,MPI_SUM,io_task,icomm,retcode) : '//mpierrstr(1:ilen)
                goto 9999
             endif
          END IF
          CALL MPI_Barrier(icomm, retcode)
          if (retcode /= MPI_SUCCESS) call fd4o_exit('put_d4o_aux: MPI_Barrier returned error code ',retcode,1)
       enddo ! do member=1,num_ens

    endif

9999 continue
    
    if (ierr /= num_obs) then
       allocate(character(len=4096)::errmsg)
       write(errmsg,'(a,i0,a,5(i0,:,1x),a)') &
            & 'Something went wrong in put_d4o_aux() on task#',mype,&
            & ' num_obs,num_ens,ierr,retcode,icomm=',&
            &   num_obs,num_ens,ierr,retcode,icomm,&
            & trim(candidate)
       call error_handler(E_ERR, 'put_d4o_aux', trim(errmsg), source, lineno=__LINE__)
    endif
    if (allocated(ibuf)) deallocate(ibuf)
  end subroutine put_d4o_aux
  
end module obs_d4o_mod

!-- Externally callable --

logical function is_d4o_debug()
  use obs_d4o_mod, only : d4o_debug
  implicit none
  is_d4o_debug = d4o_debug
end function is_d4o_debug

logical function is_d4o_format()
  use obs_d4o_mod, only : d4o_format
  implicit none
  is_d4o_format = d4o_format
end function is_d4o_format

logical function allow_d4o_bcast()
  use obs_d4o_mod, only : d4o_bcast
  implicit none
  allow_d4o_bcast = d4o_bcast()
end function allow_d4o_bcast

integer function d4o_numens_env()
  use obs_d4o_mod, only : get_d4o_numens_env
  implicit none
  d4o_numens_env = get_d4o_numens_env()
end function d4o_numens_env

subroutine read_d4o_catalog(file_name, read_format, num_copies, num_qc, num_obs, max_num_obs, ens_size)
  use obs_d4o_mod, only : doread_d4o_catalog
  implicit none
  character(len=*),  intent(in)  :: file_name
  character(len=*),  intent(out) :: read_format
  integer,           intent(out) :: num_copies, num_qc, num_obs, max_num_obs
  integer, optional, intent(in)  :: ens_size
  call doread_d4o_catalog(file_name, read_format, num_copies, num_qc, num_obs, max_num_obs, ens_size)
end subroutine read_d4o_catalog

subroutine read_d4o_data(seq)
  use obs_d4o_mod, only : doread_d4o_data
  use obs_sequence_mod, only : obs_sequence_type
  implicit none
  type(obs_sequence_type), intent(inout) :: seq
  call doread_d4o_data(seq)
end subroutine read_d4o_data

subroutine write_d4o_data(seq)
  use obs_d4o_mod, only : dowrite_d4o_data
  use obs_sequence_mod, only : obs_sequence_type
  implicit none
  type(obs_sequence_type), intent(in) :: seq
  call dowrite_d4o_data(seq)
end subroutine write_d4o_data

subroutine static_d4o_init(comm)
  use obs_d4o_mod, only : dostatic_d4o_init
  implicit none
  integer, intent(in), optional :: comm
  call dostatic_d4o_init(comm)
end subroutine static_d4o_init

subroutine alloc_d4o_data(seq,num_obs,shmem,init,ierr)
  use obs_d4o_mod, only : doalloc_d4o_data
  use obs_sequence_mod, only : obs_sequence_type
  implicit none
  type(obs_sequence_type), intent(inout) :: seq
  integer, intent(in) :: num_obs
  logical, intent(in) :: shmem
  logical, intent(out) :: init
  integer, intent(out) :: ierr
  call doalloc_d4o_data(seq,num_obs,shmem,init,ierr)
end subroutine alloc_d4o_data

subroutine sync_d4o_data(seq)
  use obs_d4o_mod, only : dosync_d4o_data
  use obs_sequence_mod, only : obs_sequence_type
  implicit none
  type(obs_sequence_type), intent(in) :: seq
  call dosync_d4o_data(seq)
end subroutine sync_d4o_data

subroutine free_d4o_data(seq)
  use obs_d4o_mod, only : dofree_d4o_data
  use obs_sequence_mod, only : obs_sequence_type
  implicit none
  type(obs_sequence_type), intent(inout) :: seq
  call dofree_d4o_data(seq)
end subroutine free_d4o_data
