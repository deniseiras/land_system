! DART software - Copyright UCAR. This open source software is provided
! by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

#define d4o_int1 4

!> @{ 
!> @brief Manage lists of observations 
!>
!> Time-ordered sequences of observations.
!> get expected obs is in here
!> @}

module obs_sequence_mod

! WARNING OPERATOR OVERLOAD FOR EQUIVALENCE???
! FURTHER WARNING: Compiler problems exist with the use of assignment(=) in
! use only statement. First, can only use it at the level above if the internals
! of the type are not private. Second, if I inherit assignment(=) from obs_def
! and also define one in obs_sequence, I get an error if I try to make it public
! to a module that uses obs_sequence but not obs_def with the intel compiler. No
! obvious workaround exists. For now, make modules at higher levels use explicit
! copy subroutines. USERS MUST BE VERY CAREFUL TO NOT DO DEFAULT ASSIGNMENT
! FOR THESE TYPES THAT HAVE COPY SUBROUTINES.

use        types_mod, only : r8, i8, MISSING_R8, metadatalength, zero

use     location_mod, only : location_type, is_location_in_region, get_location

use      obs_def_mod, only : obs_def_type, get_obs_def_time, read_obs_def, &
                             write_obs_def, destroy_obs_def, copy_obs_def, &
                             interactive_obs_def, get_obs_def_location, &
                             get_obs_def_type_of_obs, get_obs_def_key,  &
                             operator(==), operator(/=), print_obs_def, &
                             get_obs_def_error_variance
#ifdef _camfv_
  use obs_def_rttov_mod,only : write_rttov_metadata
  use obs_def_rttov_mod,only : get_mw_metadata, set_mw_metadata, mw_metadata_type
  use obs_def_rttov_mod,only : get_iasiir_metadata, set_iasiir_metadata, iasiir_metadata_type
  use obs_def_gps_mod,  only : get_gpsro_ref, set_gpsro_ref, gps_nonlocal_type, write_gpsro_ref
#endif

use     obs_kind_mod, only : write_type_of_obs_table, &
                             read_type_of_obs_table, &
                             max_defined_types_of_obs, &
                             get_index_for_type_of_obs, &
                             get_name_for_type_of_obs

use time_manager_mod, only : time_type, set_time, print_time, print_date, get_date, &
                             operator(-), operator(+), &
                             operator(>), operator(<), &
                             operator(>=), operator(/=), operator(==)

use    utilities_mod, only : get_unit, error_handler, &
                             find_namelist_in_file, check_namelist_read, &
                             E_ERR, E_MSG, nmlfileunit, do_nml_file, do_nml_term, &
                             open_file, close_file, log_it

use mpi_utilities_mod,only : my_task_id, task_count, task_comm, task_sync

use fd4o_mod, only : fd4o_exit

implicit none

#include "mpif.h"

private

interface assignment(=)
   module procedure copy_obs
   module procedure copy_spill
end interface
interface operator(==)
   module procedure eq_obs
   module procedure eq_spill
end interface
interface operator(/=)
   module procedure ne_obs
   module procedure ne_spill
end interface

! Public interfaces for obs sequences
public :: obs_sequence_type, init_obs_sequence, &
   get_num_copies, get_num_qc, get_num_obs, get_max_num_obs, &
   get_copy_meta_data, get_qc_meta_data, get_next_obs, get_prev_obs, &
   insert_obs_in_seq, delete_obs_from_seq, set_copy_meta_data, &
   set_qc_meta_data, get_first_obs, get_last_obs, add_qc, &
   write_obs_seq, read_obs_seq, &
   get_obs_from_key, get_obs_time_range, get_time_range_keys, &
   get_num_times, get_num_key_range, operator(==), operator(/=), &
   static_init_obs_sequence, destroy_obs_sequence, read_obs_seq_header, &
   delete_seq_head, delete_seq_tail, &
   get_next_obs_from_key, get_prev_obs_from_key, &
   print_obs_seq_summary, validate_obs_seq_time
!add_copies not used
!interactive_obs_sequence not used
!select_obs_by_location not used
!delete_obs_by_typelist not used
!delete_obs_by_qc not used
!delete_obs_by_copy not used
!append_obs_to_seq not used
!set_obs not used

! Public interfaces for obs
public :: obs_type, dobs_type, init_obs, destroy_obs, get_obs_def, set_obs_def, &
   get_obs_values, set_obs_values, replace_obs_values, get_qc, set_qc, &  
   read_obs, write_obs, replace_qc, &
   copy_obs, copy_spill, assignment(=), &
   get_obs_key, print_obs, print_seq
!copy_partial_obs not used
!interactive_obs not used

! Public interfaces for obs covariance modeling (not used)
!public :: obs_cov_type

character(len=*), parameter :: source = 'obs_sequence_mod.f90'

type obs_sequence_type
   !private
   integer(i8) :: windowsize = 0
   integer :: win = 0
   integer :: comm = -1
   integer :: num_copies = -1   ! task#0 : 1+4+2*ens_size ; task>0 : 1
   integer :: num_qc = -1       ! task#0 : 2              ; task>0 : 1
   integer :: num_obs = -1
   integer :: max_num_obs = -1
   !TBD: integer :: ens_size = -1
   character(len=metadatalength), allocatable :: copy_meta_data(:)
   character(len=metadatalength), allocatable :: qc_meta_data(:)
   integer :: first_time = -1
   integer :: last_time = -1
!   integer :: first_avail_time, last_avail_time
   type(obs_type), pointer :: obs(:) => NULL()   ! Can now be subject to node shmem allocation
   ! Usually (always ?) only the very first task (= io_task=0) allocates "spill" i.e. when num_copies > 1 & num_qc > 1
   logical :: has_spill = .FALSE.
   type(dobs_type), pointer :: spill(:) => NULL() ! pointer, not allocatable, since we need sometimes C_LOC of spill for debugging
! What to do about groups
end type obs_sequence_type

type ecmwf_obs_def
   !private
#if 0
   integer :: timeslot = -1
   integer :: varno = 0    ! ECMWF variable number
   integer :: reportype = 0
   integer :: obstype = 0
   integer :: codetype = 0
   integer :: bufrtype = 0
   integer :: subtype = 0
   integer :: sat_id = 0
   integer :: sensor_id = 0
   integer :: sat_instr = 0
   integer :: platform_id = 0
#endif
   ! To be frank (and to save space), we probably only need these 2 :
   integer :: hdr_id = 0
   integer :: body_entryno = 0
end type ecmwf_obs_def

type obs_type
   !private
! The key is needed to indicate the element number in the storage for the obs_sequence
! Do I want to enforce the identity of the particular obs_sequence?
   integer :: key = 0
   type(obs_def_type) :: def
   real(r8) :: obsvalue = MISSING_R8
   real(r8) :: dataqc   = zero
   ! Put sort indices directly into the data structure
   integer :: prev_time = -1
   integer :: next_time = -1
   integer :: cov_group = -1
   ! ECMWF/d4o specific
   type(ecmwf_obs_def) :: ecmwf
end type obs_type

type dobs_type ! "d" stands for dynamic
   !private
   integer :: key = 0 ! safety : alignment with type(obs_type)%key
   real(r8), allocatable :: xvalues(:)       ! 2:num_copies
   real(r8), allocatable :: xqc(:)           ! 2:num_qc
   integer(d4o_int1), allocatable :: istatus_prior(:) ! 1:ens_size
end type dobs_type

!type obs_cov_type
!   !private
!   integer :: num_cov_groups
!end type obs_cov_type ! not used

! for errors
character(len=512) :: string1, string2, string3

!-------------------------------------------------------------
! Namelist with default values

! if .true., use unformatted files which are full precision, 
! faster, smaller but not necessarily portable between machines.
logical :: write_binary_obs_sequence = .false.

! try reading in binary obs_seq files with a different byte order.
! valid values are: native, little_endian, big_endian
character(len=32) :: read_binary_file_format = 'native'

namelist /obs_sequence_nml/ write_binary_obs_sequence, read_binary_file_format

!--------------------------------------------------------------

interface
   logical function is_d4o_debug()
   end function is_d4o_debug
   
   logical function is_d4o_format()
   end function is_d4o_format
   
   logical function allow_d4o_bcast()
   end function allow_d4o_bcast

   integer function d4o_numens_env()
   end function d4o_numens_env
   
   subroutine read_d4o_catalog(file_name, read_format, num_copies, num_qc, num_obs, max_num_obs, ens_size)
     character(len=*),  intent(in) :: file_name
     character(len=*),  intent(out) :: read_format
     integer,           intent(out) :: num_copies, num_qc, num_obs, max_num_obs
     integer, optional, intent(in)  :: ens_size
   end subroutine read_d4o_catalog

#if 0
   subroutine read_d4o_data(seq)
     !use obs_sequence_mod, only : obs_sequence_type
     type(obs_sequence_type), intent(inout) :: seq
   end subroutine read_d4o_data

   subroutine write_d4o_data(seq)
     !use obs_sequence_mod, only : obs_sequence_type
     type(obs_sequence_type), intent(in) :: seq
   end subroutine write_d4o_data

   subroutine alloc_d4o_data(seq,num_obs,shmem,init,ierr)
     !use obs_sequence_mod, only : obs_sequence_type
     type(obs_sequence_type), intent(inout) :: seq
     integer, intent(in) :: num_obs
     logical, intent(in) :: shmem
     logical, intent(out) :: init
     integer, intent(out) :: ierr
   end subroutine alloc_d4o_data
   
   subroutine sync_d4o_data(seq)
     !use obs_sequence_mod, only : obs_sequence_type
     type(obs_sequence_type), intent(in) :: seq
   end subroutine sync_d4o_data
   
   subroutine free_d4o_data(seq)
     !use obs_sequence_mod, only : obs_sequence_type
     type(obs_sequence_type), intent(inout) :: seq
   end subroutine free_d4o_data
#endif
   
end interface

contains

!--------------------------------------------------------------


subroutine static_init_obs_sequence

! reads namelist and registers module
! Read the namelist input

integer :: iunit, io

! Read the namelist entry
call find_namelist_in_file("input.nml", "obs_sequence_nml", iunit)
read(iunit, nml = obs_sequence_nml, iostat = io)
call check_namelist_read(iunit, io, "obs_sequence_nml")

if (do_nml_file()) write(nmlfileunit,nml=obs_sequence_nml)
if (do_nml_term()) write(     *     ,nml=obs_sequence_nml)

end subroutine static_init_obs_sequence

!--------------------------------------------------------------

!WHAT ABOUT PASS THROUGHS TO THE OBS_DEF???
! WHAT ABOUT copy_obs_sequence similar to read.
!-------------------------------------------------
subroutine init_obs_sequence(seq, num_copies, num_qc, &
     expected_max_num_obs,fill,shmem)

! Constructor for an obs_sequence

type(obs_sequence_type), intent(out) :: seq
integer,                 intent(in)  :: num_copies, num_qc, expected_max_num_obs
logical, optional,       intent(in)  :: fill,shmem

integer :: i,ierr,num_obs
logical :: LLfill,LLshmem,LLinit

LLfill = .TRUE.
if (present(fill)) LLfill = fill

LLshmem = .FALSE.
if (present(shmem)) LLshmem = shmem

seq%num_copies  = num_copies
seq%num_qc      = num_qc
seq%num_obs     = 0
seq%max_num_obs = expected_max_num_obs

allocate(seq%copy_meta_data(seq%num_copies))
allocate(seq%qc_meta_data(seq%num_qc))

do i = 1, seq%num_copies
   seq%copy_meta_data(i) = 'Copy metadata not initialized'
end do

do i = 1, seq%num_qc
   seq%qc_meta_data(i) = 'QC metadata not initialized'
end do

! Initialize the pointers to allocated and initialize to something benign
! (Go ahead and allocated even in the case the counts are 0.)

!allocate(seq%obs(seq%max_num_obs))
LLinit = .true.
call alloc_d4o_data(seq,seq%max_num_obs,LLshmem,LLinit,ierr)

num_obs = seq%max_num_obs

if (ierr /= num_obs) then
   call error_handler(E_ERR,'Unable to allocate memory for seq%obs(:)', ' ',source, lineno=__LINE__)
endif

if (LLfill .and. LLinit) then
   if (num_copies > 0) seq%obs(:)%obsvalue = MISSING_R8
   if (num_qc > 0)     seq%obs(:)%dataqc = zero
endif

if (num_copies > 1 .or. num_qc > 1) allocate(seq%spill(num_obs))
seq%has_spill = associated(seq%spill)

if (seq%has_spill) then ! sync keys
   do i = 1, num_obs
      seq%spill(i)%key = i ! as with seq%obs(i)%key, right ?
   enddo
endif

if (num_copies > 1) then
   do i = 1, num_obs
      allocate(seq%spill(i)%xvalues(2:num_copies))
      if (LLfill) seq%spill(i)%xvalues = MISSING_R8
   enddo
endif

if (num_qc > 1) then
   do i = 1, num_obs
      allocate(seq%spill(i)%xqc(2:num_qc))
      if (LLfill) seq%spill(i)%xqc = zero
   enddo
endif

seq%first_time = -1
seq%last_time  = -1

call sync_d4o_data(seq)

end subroutine init_obs_sequence


!--------------------------------------------------------------


subroutine destroy_obs_sequence(seq)
! Destructor for an obs_sequence

type(obs_sequence_type), intent(inout) :: seq

integer :: i

if ( seq%max_num_obs > 0 ) then ! NB: not seq%num_obs
   call sync_d4o_data(seq) ! Important for SHMEM : otherwise we start premature dealloc
   
   if (allocated(seq%copy_meta_data)) deallocate(seq%copy_meta_data)

   if (allocated(seq%qc_meta_data)) deallocate(seq%qc_meta_data)

   if (associated(seq%spill)) then
      do i = 1, seq%max_num_obs
         call destroy_obs( seq%obs(i), spill=seq%spill(i) )
      end do
   else
      do i = 1, seq%max_num_obs
         call destroy_obs( seq%obs(i) )
      end do
   endif

   ! Also free up the obs storage in the sequence
   if (associated(seq%obs)) then
      call free_d4o_data(seq)
   else
      print *, 'destroy_obs_sequence called but seq%obs was not associated'
   endif

   if (associated(seq%spill)) then
      deallocate(seq%spill)
      nullify(seq%spill)
   endif
   seq%has_spill = .FALSE.
   
   seq%first_time  = -1
   seq%last_time   = -1
   seq%num_copies  = -1                                                       
   seq%num_qc      = -1
   seq%num_obs     = -1
   seq%max_num_obs = -1                                                       

endif


end subroutine destroy_obs_sequence


!--------------------------------------------------------------

#if 0
! not used
function interactive_obs_sequence()

! Interactive creation of an observation sequence
type(obs_sequence_type) :: interactive_obs_sequence

type(obs_type)     :: obs, prev_obs
type(obs_def_type) :: obs_def
type(time_type)    :: obs_time, prev_time
integer            :: max_num_obs, num_copies, num_qc, i, end_it_all

write(*, *) 'Input upper bound on number of observations in sequence'
read(*, *) max_num_obs

write(*, *) 'Input number of copies of data (0 for just a definition)'
read(*, *) num_copies

write(*, *) 'Input number of quality control values per field (0 or greater)'
read(*, *) num_qc

! Initialize an obs_sequence structure
call init_obs_sequence(interactive_obs_sequence, num_copies, num_qc, max_num_obs, shmem=.FALSE.)

do i = 1, num_copies
   write(*, *) 'input meta data for data copy ', i
   read(*, *) interactive_obs_sequence%copy_meta_data(i)
end do

do i = 1, num_qc
   write(*, *) 'input meta data for qc field ', i
   read(*, *) interactive_obs_sequence%qc_meta_data(i)
end do

! Initialize the obs variable
call init_obs(obs, num_copies, num_qc)
call init_obs(prev_obs, num_copies, num_qc)

! Loop to initialize each observation in turn; terminate by -1
do i = 1, max_num_obs
   write(*, *) 'input a -1 if there are no more obs'
   read(*, *) end_it_all
   if(end_it_all == -1) exit
   ! Need to have key available for specialized observation modules
   call interactive_obs(num_copies, num_qc, obs, i)
   if(i == 1) then
      call insert_obs_in_seq(interactive_obs_sequence, obs)
   else
      ! if this is not the first obs, make sure the time is larger
      ! than the previous observation.  if so, we can start the
      ! linked list search at the location of the previous obs.
      ! otherwise, we have to start at the beginning of the entire
      ! sequence to be sure the obs are ordered correctly in
      ! monotonically increasing times. 
      call get_obs_def(obs, obs_def)
      obs_time = get_obs_def_time(obs_def)
      call get_obs_def(prev_obs, obs_def)
      prev_time = get_obs_def_time(obs_def)
      if(prev_time > obs_time) then
         call insert_obs_in_seq(interactive_obs_sequence, obs)
      else
         call insert_obs_in_seq(interactive_obs_sequence, obs, prev_obs)
      endif
   endif
   prev_obs = obs
end do

call destroy_obs(obs)
call destroy_obs(prev_obs)

end function interactive_obs_sequence
#endif

!---------------------------------------------------------

!---------------------------------------------------------

function get_num_copies(seq)


type(obs_sequence_type), intent(in) :: seq
integer                             :: get_num_copies

get_num_copies = seq%num_copies

end function get_num_copies

!-------------------------------------------------

function get_num_qc(seq)


type(obs_sequence_type), intent(in) :: seq
integer                             :: get_num_qc

get_num_qc= seq%num_qc

end function get_num_qc

!-------------------------------------------------

function get_num_obs(seq)


type(obs_sequence_type), intent(in) :: seq
integer                             :: get_num_obs

get_num_obs = seq%num_obs

end function get_num_obs

!-------------------------------------------------

function get_max_num_obs(seq)


type(obs_sequence_type), intent(in) :: seq
integer                             :: get_max_num_obs

get_max_num_obs = seq%max_num_obs

end function get_max_num_obs
!-------------------------------------------------

function get_copy_meta_data(seq, copy_num)


type(obs_sequence_type), intent(in) :: seq
integer,                 intent(in) :: copy_num
character(len=metadatalength)       :: get_copy_meta_data

! Should have an error check for copy_num range
get_copy_meta_data = seq%copy_meta_data(copy_num)

end function get_copy_meta_data

!-------------------------------------------------
function get_qc_meta_data(seq, qc_num)


type(obs_sequence_type), intent(in) :: seq
integer,                 intent(in) :: qc_num
character(len=metadatalength)       :: get_qc_meta_data

! Should have an error check for qc_num range
get_qc_meta_data = seq%qc_meta_data(qc_num)

end function get_qc_meta_data

!-------------------------------------------------

subroutine get_next_obs(seq, obs, next_obs, is_this_last)


type(obs_sequence_type), intent(in)  :: seq
type(obs_type),          intent(in)  :: obs
type(obs_type),          intent(out) :: next_obs
logical,                 intent(out) :: is_this_last

integer :: next_index

! Get index of the next observation
next_index = obs%next_time
if(next_index == -1) then
   is_this_last = .true.
   return
else
   is_this_last = .false.
   next_obs = seq%obs(next_index)
endif
!print *, 'next index = ', next_index

end subroutine get_next_obs

!-------------------------------------------------

subroutine get_prev_obs(seq, obs, prev_obs, is_this_first)


type(obs_sequence_type), intent(in)  :: seq
type(obs_type),          intent(in)  :: obs
type(obs_type),          intent(out) :: prev_obs
logical,                 intent(out) :: is_this_first

integer :: prev_index

! Get index of the next observation
prev_index = obs%prev_time
if(prev_index == -1) then
   is_this_first= .true.
   return
else
   is_this_first= .false.
   prev_obs = seq%obs(prev_index)
endif

end subroutine get_prev_obs

!-------------------------------------------------------------

subroutine get_obs_from_key(seq, key, obs)

type(obs_sequence_type), intent(in) :: seq
integer,                 intent(in) :: key

type(obs_type) :: obs

obs = seq%obs(key)

end subroutine get_obs_from_key

!-------------------------------------------------

subroutine get_next_obs_from_key(seq, last_key_used, next_obs, is_this_last)


type(obs_sequence_type), intent(in)  :: seq
integer,                 intent(in)  :: last_key_used
type(obs_type),          intent(out) :: next_obs
logical,                 intent(out) :: is_this_last

integer :: next_index

! Get index of the next observation
next_index = seq%obs(last_key_used)%next_time
if(next_index == -1) then
   is_this_last = .true.
   return
else
   is_this_last = .false.
   next_obs = seq%obs(next_index)
endif

end subroutine get_next_obs_from_key

!-------------------------------------------------

subroutine get_prev_obs_from_key(seq, last_key_used, prev_obs, is_this_first)


type(obs_sequence_type), intent(in)  :: seq
integer,                 intent(in)  :: last_key_used
type(obs_type),          intent(out) :: prev_obs
logical,                 intent(out) :: is_this_first

integer :: prev_index

! Get index of the next observation
prev_index = seq%obs(last_key_used)%prev_time
if(prev_index == -1) then
   is_this_first= .true.
   return
else
   is_this_first= .false.
   prev_obs = seq%obs(prev_index)
endif

end subroutine get_prev_obs_from_key

!-----------------------------------------------------------------

#if 0
!not used
subroutine set_obs(seq, obs, key_in)

! Copies the obs into the key element of sequence where key is the key field
! in obs. If the integer argument key is present, the obs is copied into
! the key-th element of the sequence.

type(obs_sequence_type), intent(inout) :: seq
type(obs_type),          intent(in)    :: obs
integer,                 intent(in), optional :: key_in

integer :: key

! Get the key to copy into
if(present(key_in)) then 
   key = key_in
else
   key = obs%key
endif

seq%obs(key) = obs

! Make sure the key in sequence is set properly
seq%obs(key)%key = key

end subroutine set_obs
#endif

!-------------------------------------------------------------------

subroutine get_obs_time_range(seq, time1, time2, key_bounds, num_keys, out_of_range, obs)

! Add other options for getting the first time to minimize search
type(obs_sequence_type), intent(in)  :: seq
type(time_type),         intent(in)  :: time1, time2
integer,                 intent(out) :: key_bounds(2)
integer,                 intent(out) :: num_keys
logical,                 intent(out) :: out_of_range
type(obs_type),          intent(in), optional :: obs

type(time_type)    :: cur_time
type(obs_def_type) :: obs_def
integer            :: current, last_key

! Returns the first key and last key of sequence of obs between time1 and
! time2 along with the total number.
! A complete list of the keys can be obtained by call to get_time_range_keys
! Logical out_of_range is true if the time range is all past the end of sequence times

num_keys = 0
out_of_range = .false.

! The optional argument obs says the search can be started at this observation

! Figure out where to begin search
if(present(obs)) then
   current = obs%key
else
   current = seq%first_time
endif

! Check for all observations after the last time in the window
call get_obs_def(seq%obs(current), obs_def)
cur_time = get_obs_def_time(obs_def)
if(cur_time > time2) then
   out_of_range = .true.
   return
endif

! Find the first element in the time window
do while(current /= -1)
   call get_obs_def(seq%obs(current), obs_def)
   cur_time = get_obs_def_time(obs_def)
   if(cur_time >= time1) goto 10
   current = seq%obs(current)%next_time
end do
! Falling off the end means there are no times greater than time1
out_of_range = .true.
return

10 continue
! current is pointer to first

! First pass, count the keys for storage requirements
key_bounds(1) = current
last_key = current
do while(current /= -1)
   call get_obs_def(seq%obs(current), obs_def)
   cur_time = get_obs_def_time(obs_def)
   if(cur_time > time2) goto 20
! Found a time in the range
   num_keys = num_keys + 1
   last_key = current
   current = seq%obs(current)%next_time
end do

20 continue
key_bounds(2) = last_key

end subroutine get_obs_time_range

!---------------------------------------------------------------

subroutine get_time_range_keys(seq, key_bounds, num_keys, keys)

! Given bounds from get_obs_time_range and an array keys big enough to hold
! all the keys in the range, returns the keys in the range

type(obs_sequence_type), intent(in)  :: seq
integer,                 intent(in)  :: key_bounds(2), num_keys
integer,                 intent(out) :: keys(num_keys)

integer :: current, i

! Now loop through again to get these keys
current = key_bounds(1)
do i = 1, num_keys
   keys(i) = seq%obs(current)%key
   current = seq%obs(current)%next_time
end do

end subroutine get_time_range_keys


!-------------------------------------------------

subroutine insert_obs_in_seq(seq, obs, prev_obs)

type(obs_sequence_type), intent(inout) :: seq
type(obs_type),          intent(inout) :: obs
type(obs_type),          intent(in), optional :: prev_obs

type(time_type) :: obs_time, current_time
integer :: prev, next, current

! Inserts an observation into a sequence, optional argument
! prev_obs says that this was the predecessor in time.
! This avoids time search in cases where one is building
! a sequence from scratch.

! Make sure there is room, fail for now if not
if(seq%num_obs >= seq%max_num_obs) then
   ! Later do an increase of space and copy
   write(string1,*) 'ran out of room, num_obs (',seq%num_obs, &
                               ') > max_num_obs (',seq%max_num_obs,')'
   call error_handler(E_ERR,'insert_obs_in_seq',string1, source)
endif

! Set the key for the observation
obs%key     = seq%num_obs + 1
seq%num_obs = seq%num_obs + 1

! Get the time for the observation
obs_time = get_obs_def_time(obs%def)

! Assume we're starting at the beginning.
! If we make this smarter eventually, here is where
! we'd set the initial key number for a search.

! If given an existing obs, be sure the new obs time is
! consistent - later or equal to the given previous obs. 
if(present(prev_obs)) then
   prev = prev_obs%key
   current = prev
   next = prev_obs%next_time
   
   ! it is an error to try to insert an observation after an
   ! existing obs which has a smaller timestamp.
   if (prev /= -1) then
       current_time = get_obs_def_time(seq%obs(prev)%def)
       if (obs_time < current_time) then
          !! or, do the insert searching from the start
          !prev = -1
          !current = -1
          !next = seq%first_time
          ! error out 
          write(string1,*) 'time of prev_obs cannot be > time of new obs'
          call error_handler(E_ERR,'insert_obs_in_seq',string1, source)
       endif
    endif
   
    ! the insert code will search forward starting at the
    ! given obs, so it is not an error to give an obs which
    ! has a larger time than the next obs.
else
   ! Start search at beginning
   prev = -1
   current = -1
   next = seq%first_time
endif

! Have to search through the linked list to find last member
! already in with a time less than or equal to obs time
do while(next /= -1)
   prev = current
   current = next
   next = seq%obs(current)%next_time
   current_time = get_obs_def_time(seq%obs(current)%def)
! If the time of the observation in the sequence is >, stop
   if(current_time > obs_time) then 
! The observation that will follow the one being inserted is current
      next = current
      goto 10 
   endif
end do

! Falling off the end means that next is -1, so current should be previous for insertion
prev = current

! If the time check occured, previous is already pointing to previous
10 continue

! prev now holds the key of the previous observation, next holds the one after

! Link into the foward moving pointer chain
! If prev is -1, new observation goes at the start
if(prev == -1) then
   obs%next_time = seq%first_time
   obs%prev_time = -1
   seq%first_time = obs%key
else
   obs%prev_time = prev
   obs%next_time = next
   seq%obs(prev)%next_time = obs%key
endif

! Link into the backward moving pointer chain
if(next == -1) then
   obs%prev_time = seq%last_time
   obs%next_time = -1
   seq%last_time = obs%key
else
   seq%obs(next)%prev_time = obs%key
endif

! Finally, copy this obs structure into the sequence
seq%obs(obs%key) = obs

end subroutine insert_obs_in_seq

!----------------------------------------------------------------------

#if 0
! not used
subroutine append_obs_to_seq(seq, obs)

! Appends an observation to an existing sequence; Error if new obs is 
! not later than time of last obs already in seq

type(obs_sequence_type), intent(inout) :: seq
type(obs_type),          intent(inout) :: obs

type(obs_type) :: last_obs
type(time_type) :: obs_time, last_time

! Initialize obs_type before using
call init_obs(last_obs, 0, 0)

! If this is first, just put it in
if(.not. get_last_obs(seq, last_obs)) then
   call insert_obs_in_seq(seq, obs)
else

! Otherwise, get last obs from sequence and do insert with it as
! the previous after checking times

! Get the time for the observation
   obs_time = get_obs_def_time(obs%def)
   last_time = get_obs_def_time(last_obs%def)
   if(obs_time < last_time) then
      write(string1, *) 'time of appended obs cannot be < time of last obs in sequence'
      call error_handler(E_ERR,'append_obs_to_seq',string1, source)
   endif

!!!   call insert_obs_in_seq(seq, obs)
!!!   if(1 == 1) return

! Make sure there is room, fail for now if not
   if(seq%num_obs >= seq%max_num_obs) then
! Later do an increase of space and copy
      write(string1,*) 'ran out of room, max_num_obs = ',seq%max_num_obs
      call error_handler(E_ERR,'append_obs_to_seq',string1, source)
   endif

! Set the key for the observation
   obs%key = seq%num_obs + 1
   seq%num_obs = seq%num_obs + 1
! Link into the pointer chains
! Previous last points to this one, this one points back to previous last
   obs%prev_time = seq%last_time
   seq%obs(seq%last_time)%next_time = obs%key
   seq%last_time = obs%key
! Appended is at end, put a -1 for the next
   obs%next_time = -1

! Put this obs into the sequence's last slot
   seq%obs(seq%num_obs) = obs

endif

! free any space allocated at init time.
call destroy_obs(last_obs)

end subroutine append_obs_to_seq
#endif

!---------------------------------------------------------------

!subroutine insert_obs_group_in_seq(seq, obs_grp, prev_obs)

! Insert a group of observations from the same time into a sequence
!type(obs_sequence_type), intent(inout) :: seq
!type(obs_type),          intent(inout) :: obs
!type(obs_type),          intent(in), optional :: prev_obs
!
!end subroutine insert_obs_group_in_seq

!-------------------------------------------------

subroutine delete_obs_from_seq(seq, obs)

! Removes this observation from the sequence, does not free storage in this implementation
type(obs_sequence_type), intent(inout) :: seq
type(obs_type),          intent(inout) :: obs

integer :: prev, next

call error_handler(E_ERR,'delete_obs_from_seq','we should not enter this routine at all', source)

prev = obs%prev_time
next = obs%next_time

!print *, 'del key, initial prev,next=', obs%key, prev, next

! update obs count??  i think this should be done, but other code
! is not prepared to deal with it.
seq%num_obs = seq%num_obs - 1 ! should be ok

! If only one obs, seq first_time and last_time to -1
if(prev == -1 .and. next == -1) then
  seq%first_time = -1
  seq%last_time  = -1
  return
endif

! Previous should now point to next; if deleted was first update sequence first_time
if(prev /= -1) then
   seq%obs(prev)%next_time = next
else
   seq%obs(next)%prev_time = -1
   seq%first_time = next
endif

! Next should point to previous; if deleted is last, set previous next_time to -1
if(next /= -1) then
   seq%obs(next)%prev_time = prev
else
   seq%obs(prev)%next_time = -1
   seq%last_time = prev
endif


!print *, 'prev key, next = ', prev, seq%obs(prev)%next_time
!print *, 'next key, prev = ', next, seq%obs(next)%prev_time
!print *, 'seq entire first/last = ', seq%first_time, seq%last_time

end subroutine delete_obs_from_seq

!-------------------------------------------------

subroutine set_copy_meta_data(seq, copy_num, meta_data)

! Need all sorts of error checking to avoid silly stuff eventually

type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: copy_num
character(len=*),        intent(in)    :: meta_data

character(len=len(meta_data)) :: lj_meta_data ! left justified version

lj_meta_data = adjustl(meta_data)

if (len_trim(lj_meta_data) > metadatalength) then
   write(string1,*) 'metadata string [', trim(lj_meta_data),']'
   write(string2,*) 'must be shorter than ',metadatalength
   call error_handler(E_ERR, 'set_copy_meta_data', string1, source, text2=string2)
endif

if (copy_num > seq%num_copies) then
   write(string1,*) 'trying to set copy (', copy_num, &
                      ') which is larger than num_copies (', seq%num_copies, ')'
   call error_handler(E_ERR,'set_copy_meta_data',string1, source)
endif

seq%copy_meta_data(copy_num) = trim(lj_meta_data)

end subroutine set_copy_meta_data

!-------------------------------------------------

subroutine set_qc_meta_data(seq, qc_num, meta_data)

! Need error checks
type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: qc_num
character(len=*),        intent(in)    :: meta_data

character(len=len(meta_data)) :: lj_meta_data ! left justified version

lj_meta_data = adjustl(meta_data)

if (len_trim(lj_meta_data) > metadatalength) then
   write(string1,*) 'metadata string [', trim(lj_meta_data),']'
   write(string2,*) 'must be shorter than ',metadatalength
   call error_handler(E_ERR, 'set_qc_meta_data', string1, source, text2=string2)
endif

if (qc_num > seq%num_qc) then
   write(string1,*) 'trying to set qc (', qc_num, &
                      ') which is larger than num_qc (', seq%num_qc, ')'
   call error_handler(E_ERR,'set_qc_meta_data',string1, source)
endif

seq%qc_meta_data(qc_num) = trim(lj_meta_data)

end subroutine set_qc_meta_data

!-------------------------------------------------

function get_first_obs(seq, obs)

type(obs_sequence_type), intent(in)  :: seq
type(obs_type),          intent(out) :: obs
logical                              :: get_first_obs

if(seq%num_obs == 0 .or. seq%first_time <= 0) then
   get_first_obs = .false.
else
   get_first_obs = .true.
   obs = seq%obs(seq%first_time)
endif

end function get_first_obs

!-------------------------------------------------

function get_last_obs(seq, obs)

type(obs_sequence_type), intent(in)  :: seq
type(obs_type),          intent(out) :: obs
logical                              :: get_last_obs

if(seq%num_obs == 0 .or. seq%last_time <=0) then
   get_last_obs = .false.
   return
else
   get_last_obs = .true.
   obs = seq%obs(seq%last_time)
endif

end function get_last_obs

!-------------------------------------------------

#if 0
! not used
subroutine add_copies(seq, num_to_add)

! This requires a complete recreation of the entire obs sequence
! Add additional copies to an observation sequence. This increases
! the space for copy meta_data and goes through the whole string of
! observations deallocating and allocating (yuck), to add space.
! In the long run, may want a smoother way to do this globally.

type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: num_to_add

character(len=metadatalength) :: meta_temp(seq%num_copies)
real(r8) :: values_temp(seq%num_copies)
integer :: i, old_num

old_num = seq%num_copies
seq%num_copies = old_num + num_to_add

! Copy the old copy metadata to temp storage, reallocate and copy
if(old_num > 0) then
   meta_temp = seq%copy_meta_data
endif

! Deallocate and reallocate with enhanced length
deallocate(seq%copy_meta_data)
allocate(seq%copy_meta_data(old_num + num_to_add))
seq%copy_meta_data(1:old_num) = meta_temp
seq%copy_meta_data(old_num+1 : old_num + num_to_add) = 'Copy metadata not initialized'

! Loop through all the observations, copy and increase size
do i = 1, seq%max_num_obs

! Copy the existing values
   if(old_num > 0) values_temp = seq%obs(i)%values

! Deallocate, reallocate and copy
   deallocate(seq%obs(i)%values)
   allocate(seq%obs(i)%values(old_num + num_to_add))
   seq%obs(i)%values(1:old_num) = values_temp
   seq%obs(i)%values(old_num+1:old_num+num_to_add) = MISSING_r8

end do

end subroutine add_copies
#endif

!-------------------------------------------------

subroutine add_qc(seq, num_to_add)

! This requires a complete recreation of the entire obs sequence
! Add additional copies to an observation sequence. This increases
! the space for copy meta_data and goes through the whole string of
! observations deallocating and allocating (yuck), to add space.
! In the long run, may want a smoother way to do this globally.

type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: num_to_add

character(len=metadatalength) :: qc_temp(seq%num_qc)
real(r8)                      :: values_temp(2:seq%num_qc)
integer                       :: i, old_num

if (num_to_add < 1) return

old_num = seq%num_qc
if (old_num < 0) return ! should not happen unless totally "virgin" seq'uence

! Copy the old copy metadata to temp storage, reallocate and copy
if (old_num > 0) qc_temp = seq%qc_meta_data

! Deallocate and reallocate with enhanced length
if (allocated(seq%qc_meta_data)) deallocate(seq%qc_meta_data)
allocate(seq%qc_meta_data(old_num + num_to_add))
if (old_num > 0) seq%qc_meta_data(1:old_num) = qc_temp
seq%qc_meta_data(old_num+1 : old_num + num_to_add) = 'QC metadata not initialized'

! Loop through all the observations, copy and increase size
if (old_num >= 1) then ! old_num aka (input) seq%num_qc
   do i = 1, seq%max_num_obs
      ! Copy the existing values
      if (old_num > 1) values_temp = seq%spill(i)%xqc
      ! Deallocate, reallocate and copy
      if (allocated(seq%spill(i)%xqc)) deallocate(seq%spill(i)%xqc)
      allocate(seq%spill(i)%xqc(2:old_num + num_to_add))
      seq%spill(i)%xqc = zero
      if (old_num > 1) seq%spill(i)%xqc(2:old_num) = values_temp
   end do
else ! old_num == 0 .. again, shouldn't happen
   if (num_to_add > 1) then
      do i = 1, seq%max_num_obs
         allocate(seq%spill(i)%xqc(2:num_to_add))
         seq%spill(i)%xqc = zero
      end do
      seq%has_spill = .true.
   else
      ! do nothing since the first entry is always kept in "static" seq%obs(:)%dataqc variables
   endif
endif

seq%num_qc = old_num + num_to_add

end subroutine add_qc

!------------------------------------------------------------------

subroutine write_obs_seq(seq, file_name)

type(obs_sequence_type), intent(in) :: seq
character(len=*),        intent(in) :: file_name
character(len=:), allocatable :: obs_seq_final
character(len=4096) :: clenv

integer :: i, file_id, rc, num_obs
integer :: have(max_defined_types_of_obs)
character(len=11) :: useform

call sync_d4o_data(seq)

num_obs = seq%num_obs
if (my_task_id() == 0) then
   call print_seq('w',seq,keys=[1,2,3,num_obs-2,num_obs-1,num_obs]) ! debug -- to be removed (or only task#0 prints something)
endif

if (is_d4o_format()) then
   call write_d4o_data(seq)
   call get_environment_variable('d4o_final',clenv)
   if (clenv == ' ') goto 2023
   obs_seq_final = trim(clenv)
endif

if (my_task_id() /= 0) goto 2023 ! Only task id 0 does the rest

if (.not.allocated(obs_seq_final)) obs_seq_final = trim(file_name)

if(write_binary_obs_sequence) then
   useform = 'unformatted'
   file_id = open_file(obs_seq_final, form=useform, action='write',               return_rc=rc)
else
   useform = 'formatted'
   file_id = open_file(obs_seq_final, form=useform, action='write', delim='none', return_rc=rc)
endif

if (rc /= 0) then
   write(string1, *) 'unable to create observation sequence file "'//trim(obs_seq_final)//'"'
   write(string2, *) 'open file return code = ', rc
   call error_handler(E_ERR,'write_obs_seq',string1, source, text2=string2)
else
   write(string1, *) 'opening '// trim(useform) // ' observation sequence file "'//trim(obs_seq_final)//'"'
   call error_handler(E_MSG,'write_obs_seq',string1)
endif

! Write the initial string for help in figuring out binary
if(write_binary_obs_sequence) then
   write(file_id) 'obs_sequence'
else
   write(file_id, *) 'obs_sequence'
endif

! Figure out which of the total possible kinds (really types) exist in this
! sequence, and set the array values to 0 for no, 1 for yes.
call set_used_kinds(seq, have)

! Write the TOC, with only the kinds that exist in this seq.
call write_type_of_obs_table(file_id, useform, have)

! First inefficient ugly pass at writing an obs sequence, need to 
! update for storage size.  CHANGE - use num_obs for the max_num_obs, to
! limit the amount of memory needed when this sequence is read in.
if(write_binary_obs_sequence) then
   write(file_id) seq%num_copies, seq%num_qc, seq%num_obs, seq%num_obs
else
   write(file_id, *) ' num_copies: ',seq%num_copies, ' num_qc: ',     seq%num_qc
   write(file_id, *) ' num_obs: ',   seq%num_obs,    ' max_num_obs: ',seq%num_obs
endif 

do i = 1, seq%num_copies
   if(write_binary_obs_sequence) then
      write(file_id) seq%copy_meta_data(i)
   else
      write(file_id, '(a)') seq%copy_meta_data(i)
   endif
end do

do i = 1, seq%num_qc
   if(write_binary_obs_sequence) then
      write(file_id) seq%qc_meta_data(i)
   else
      write(file_id, '(a)') seq%qc_meta_data(i)
   endif
end do

if(write_binary_obs_sequence) then
   write(file_id) seq%first_time, seq%last_time
else
   write(file_id, *) ' first: ',seq%first_time, ' last: ',seq%last_time
endif

do i = 1, seq%num_obs
   if(.not. write_binary_obs_sequence) write(file_id, *) 'OBS ',seq%obs(i)%key
   call write_obs(seq, i, file_id, seq%num_copies, seq%num_qc)
end do

! Close up the file
call close_file(file_id)

write(string1, *) 'closed observation sequence file "'//trim(obs_seq_final)//'"'
call error_handler(E_MSG,'write_obs_seq',string1)

2023 continue

call task_sync()

end subroutine write_obs_seq

!------------------------------------------------------------------

subroutine read_obs_seq(file_name, add_copies, add_qc, add_obs, seq)

! Be able to increase size at read in time for efficiency

character(len=*),        intent(in)  :: file_name
integer,                 intent(in)  :: add_copies, add_qc, add_obs
type(obs_sequence_type), intent(out) :: seq

integer :: i, num_copies, num_qc, num_obs, max_num_obs, file_id, io
integer :: io_task, my_task, comm
character(len=16) :: label(2)
character(len=32) :: read_format
logical :: dummy, LLshmem, LLbcast

!write(0,*) 'read_obs_seq: add_copies,add_qc,add_obs = ',add_copies,add_qc,add_obs

! Use read_obs_seq_header to get file format and header info
call read_obs_seq_header(file_name, num_copies, num_qc, num_obs, &
     max_num_obs, file_id, read_format, dummy)

!write(0,*) 'read_obs_seq: num_copies,num_qc,num_obs,max_num_obs = ',&
!                          num_copies,num_qc,num_obs,max_num_obs
!write(0,*) 'read_obs_seq: num_copies+add_copies,num_qc+add_qc,num_obs+add_obs,max_num_obs = ',&
!                          num_copies+add_copies,num_qc+add_qc,num_obs+add_obs,max_num_obs

call init_obs_sequence(seq, num_copies + add_copies, num_qc + add_qc, num_obs + add_obs, shmem=.TRUE.)

! Set the number of obs available at present
seq%num_obs = num_obs

! Only the io_task physically reads the input data and then broadcasts required components to other tasks
io_task = 0
comm = task_comm()
LLshmem = (seq%windowsize > 0)
if (LLshmem) comm = seq%comm
my_task = my_task_id(comm)

LLbcast = LLshmem .or. allow_d4o_bcast()

call sync_d4o_data(seq)

if (LLbcast .and. my_task /= io_task) goto 2023

! Get the available copy_meta_data
if (is_d4o_format()) then
   seq%copy_meta_data(1) = 'observation' ! body.obsvalue
else
   do i = 1, num_copies
      if(read_format == 'unformatted') then
         read(file_id, iostat=io) seq%copy_meta_data(i)
      else
         read(file_id, '(a)', iostat=io) seq%copy_meta_data(i)
      endif
      if (io /= 0) then
         ! Read error of some type
         write(string1, *) 'Read error in copy metadata ', i, ' rc= ', io
         call error_handler(E_ERR, 'read_obs_seq', string1, source)
      endif
   end do
endif
   
! Get the available qc_meta_data
if (is_d4o_format()) then
   seq%qc_meta_data(1) = 'Data QC' ! body.qc
else
   do i = 1, num_qc
      if(read_format == 'unformatted') then
         read(file_id, iostat=io) seq%qc_meta_data(i)
      else
         read(file_id, '(a)', iostat=io) seq%qc_meta_data(i)
      endif
      if (io /= 0) then
         ! Read error of some type
         write(string1, *) 'Read error in qc metadata ', i, ' rc= ', io
         call error_handler(E_ERR, 'read_obs_seq', string1, source)
      endif
   end do
endif

if (is_d4o_format()) then
   call read_d4o_data(seq)
else
   ! Read the first and last avail_time pointers
   if(read_format == 'unformatted') then
      read(file_id, iostat=io) seq%first_time, seq%last_time
   else
      read(file_id, *, iostat=io) label(1),seq%first_time,label(2), seq%last_time
   endif
   if (io /= 0) then
      ! Read error of some type
      write(string1, *) 'Read error in first/last times, rc= ', io
      call error_handler(E_ERR, 'read_obs_seq', string1, source)
   endif
endif

if (seq%first_time < -1 .or. seq%first_time > max_num_obs) then
   write(string1, *) 'Bad value for first', seq%first_time, ', min is -1, max is ', max_num_obs 
   call error_handler(E_ERR, 'read_obs_seq', string1, source)
endif
if (seq%last_time < -1 .or. seq%last_time > max_num_obs) then
   write(string1, *) 'Bad value for last', seq%last_time, ', min is -1, max is ', max_num_obs 
   call error_handler(E_ERR, 'read_obs_seq', string1, source)
endif

! Now read in all the previously defined observations
if (.not.is_d4o_format()) then
   do i = 1, num_obs
      if(.not. read_format == 'unformatted') read(file_id,*, iostat=io) label(1)
      if (io /= 0) then
         ! Read error of some type
         write(string1, *) 'Read error in obs label', i, ' rc= ', io
         call error_handler(E_ERR, 'read_obs_seq', string1, source)
      endif
      call read_obs(file_id, num_copies, add_copies, num_qc, add_qc, seq, i, &
           read_format, num_obs)
      ! Also set the key in the obs
      seq%obs(i)%key = i
   end do

   ! Close up the file -- only relevant when not in d4o-format
   call close_file(file_id)
endif

2023 continue

call sync_d4o_data(seq)

if (LLbcast) call bcast_seq(seq,comm,io_task,num_obs,num_copies,num_qc)

if (my_task_id() == 0) then
   call print_seq('r',seq,keys=[1,2,3,num_obs-2,num_obs-1,num_obs],results=.FALSE.) ! debug -- to be removed (or only task#0 prints something)
endif

end subroutine read_obs_seq

!------------------------------------------------------------------

subroutine mpierr_check(routine,msg,ierr,lineno)
  character(len=*), intent(in) :: routine, msg
  integer, intent(in)          :: ierr,lineno
  integer :: ilen, idummy
  character(len=80) :: mpierrstr
  character(len=len(routine)+20) :: rln
  if (ierr /= MPI_SUCCESS) then
     CALL MPI_Error_string(ierr, mpierrstr, ilen, idummy)
     write(rln,'(a,":",i0)') trim(routine),lineno
     call fd4o_exit(trim(rln)//' : '//trim(mpierrstr)//' : '//trim(msg)//' ierr=',ierr,1)
  endif
end subroutine mpierr_check

subroutine bcast_seq(seq,comm,io_task,num_obs,num_copies,num_qc)
  type(obs_sequence_type), intent(inout) :: seq
  integer, intent(in) :: comm,io_task,num_obs,num_copies,num_qc
  integer :: my_task, npes, ierr, i, j, bitsperbyte
  integer :: sizer8, sizeint
  real(r8), allocatable :: rbuf(:)
  integer, allocatable :: ibuf(:)
  integer(i8) :: nbytes
  character(len=1) :: onebyte
  logical :: LLshmem
  LLshmem = (seq%windowsize > 0)

  if (num_copies /= 1 .or. num_qc /= 1) then ! something went wrong !!
     call fd4o_exit('bcast_seq: Program logic error -- both "num_copies" and "num_qc" must be 1 ',-1,1)
  endif
  
  npes = task_count(comm)
  if (npes <= 1) return ! do nothing if just one task (rare)

  if (LLshmem) goto 2023 ! seq%obs(:)%<vars> within a node is already shared

  my_task = my_task_id(comm)
  call task_sync(comm)

  bitsperbyte = storage_size(onebyte) ! usually 8

  CALL MPI_Type_size(MPI_REAL8,sizer8,ierr)     ! should be 8
  if (ierr /= MPI_SUCCESS) sizer8 = (storage_size(rbuf)+bitsperbyte-1)/bitsperbyte

  allocate(rbuf(num_obs*(num_copies+num_qc)))
  
  if (my_task == io_task) then
     nbytes = int(size(rbuf),i8) * int(sizer8,i8)
     write(0,*) 'bcast_seq: num_obs,num_copies,num_qc,size(rbuf),nbytes,sizer8=',&
                            num_obs,num_copies,num_qc,size(rbuf),nbytes,sizer8
     do i=1,num_obs
        j = 2*(i-1)
        rbuf(j+1) = seq%obs(i)%obsvalue
        rbuf(j+2) = seq%obs(i)%dataqc
     enddo
  endif

  CALL MPI_Bcast(rbuf,size(rbuf),MPI_REAL8,io_task,comm,ierr)
  call mpierr_check('bcast_seq','MPI_Bcast(rbuf,size(rbuf),MPI_REAL8)',ierr,__LINE__)
  
  if (my_task /= io_task) then
     do i=1,num_obs
        j = 2*(i-1)
        seq%obs(i)%obsvalue = rbuf(j+1)
        seq%obs(i)%dataqc   = rbuf(j+2)
     enddo
  endif

  deallocate(rbuf)

  CALL MPI_Type_size(MPI_INTEGER4,sizeint,ierr) ! should be 4
  if (ierr /= MPI_SUCCESS) sizeint = (storage_size(ibuf)+bitsperbyte-1)/bitsperbyte

  allocate(ibuf(num_obs*2)) ! num_obs x (prev_time + next_time)
  
  if (my_task == io_task) then
     nbytes = int(size(ibuf),i8) * int(sizeint,i8)
     write(0,*) 'bcast_seq: num_obs,size(ibuf),nbytes,sizeint=',&
                            num_obs,size(ibuf),nbytes,sizeint
     do i=1,num_obs
        j = 2*(i-1)
        ibuf(j+1) = seq%obs(i)%prev_time
        ibuf(j+2) = seq%obs(i)%next_time
     enddo
  endif

  CALL MPI_Bcast(ibuf,size(ibuf),MPI_INTEGER4,io_task,comm,ierr)
  call mpierr_check('bcast_seq','MPI_Bcast(ibuf,size(ibuf),MPI_INTEGER4)',ierr,__LINE__)
  
  if (my_task /= io_task) then
     do i=1,num_obs
        seq%obs(i)%key = i
        j = 2*(i-1)
        seq%obs(i)%prev_time = ibuf(j+1)
        seq%obs(i)%next_time = ibuf(j+2)
     enddo
  endif
  
  deallocate(ibuf)

  call bcast_seq_def(seq,comm,io_task,num_obs)

2023 continue
  call bcast_seq_metadata(seq,comm,io_task,num_copies,num_qc)
  
end subroutine bcast_seq

subroutine bcast_seq_def(seq,comm,io_task,num_obs)
  type(obs_sequence_type), intent(inout) :: seq
  integer, intent(in) :: comm,io_task,num_obs
  character(len=1) :: onebyte
  integer :: bitsperbyte, nbytes, ierr, my_task, npes
  integer(i8) :: nshare
  type(obs_def_type), allocatable :: def(:)
  logical :: LLshmem
  LLshmem = (seq%windowsize > 0)
  
  if (LLshmem) return ! seq%obs(:)%def within a node is already shared
  
  npes = task_count(comm)
  if (npes <= 1) return ! do nothing if just one task (rare)
  
  my_task = my_task_id(comm)
  bitsperbyte = storage_size(onebyte) ! usually 8
  
  nbytes = (storage_size(def)+bitsperbyte-1)/bitsperbyte ! in bytes
  nshare = int(num_obs,kind(nshare)) * int(nbytes,kind(nshare)) ! can this exceed 2GBytes ??? TBD
  
  if (my_task == io_task) then
     write(0,*) 'bcast_seq_def: bitsperbyte,nbytes,num_obs,nshare,storage_size(def)=',&
                                bitsperbyte,nbytes,num_obs,nshare,storage_size(def)
  endif
  
  allocate(def(num_obs))
  if (my_task == io_task) def(:) = seq%obs(:)%def
  CALL MPI_Bcast(def,nshare,MPI_BYTE,io_task,comm,ierr) ! beware of not exceeding 2GB !!
  call mpierr_check('bcast_seq_def','MPI_Bcast(def,nshare,MPI_BYTE)',ierr,__LINE__)
  if (my_task /= io_task) seq%obs(:)%def = def(:)
  
  call task_sync(comm)
end subroutine bcast_seq_def

subroutine bcast_seq_metadata(seq,comm,io_task,num_copies,num_qc)
  type(obs_sequence_type), intent(inout) :: seq
  integer, intent(in) :: comm,io_task,num_copies,num_qc

  character(len=1) :: onebyte
  integer :: bitsperbyte, nchunk, ierr, my_task, npes
  integer(i8) :: nbytes
  integer(i8), parameter :: tgtdisp = 0 ! the "kind" must be 8 or MPI_ADDRESS_KIND
  integer :: ibuf(2)
  integer :: jw, win(2), xwin
  character(len=metadatalength) :: copy_meta_data
  character(len=metadatalength) :: qc_meta_data
#ifdef _camfv_
  integer :: j, numkeys
  integer, allocatable :: keys(:)
  type(mw_metadata_type), allocatable  :: mw(:)
  type(iasiir_metadata_type), allocatable  :: iasiir(:)
  type(gps_nonlocal_type), allocatable :: gpsro(:)
#endif
  logical :: LLshmem
  LLshmem = (seq%windowsize > 0)
  
  if (num_copies /= 1 .or. num_qc /= 1) then ! something went wrong !!
     call fd4o_exit('bcast_seq_metadata: Program logic error -- both "num_copies" and "num_qc" must be 1 ',-1,1)
  endif
  
  npes = task_count(comm)
  if (npes <= 1) return ! do nothing if just one task (rare)
  
  my_task = my_task_id(comm)
  bitsperbyte = storage_size(onebyte) ! usually 8

  if (my_task == io_task) then
     ibuf(1) = seq%first_time
     ibuf(2) = seq%last_time
     copy_meta_data = seq%copy_meta_data(1)
     qc_meta_data = seq%qc_meta_data(1)
  endif

  CALL MPI_Bcast(ibuf,size(ibuf),MPI_INTEGER4,io_task,comm,ierr)
  call mpierr_check('bcast_seq_metadata','MPI_Bcast(ibuf,size(ibuf),MPI_INTEGER4)',ierr,__LINE__)
  
  nbytes = int(metadatalength,i8)
  CALL MPI_Win_create(copy_meta_data,nbytes,1,MPI_INFO_NULL,comm,win(1),ierr)
  call mpierr_check('bcast_seq_metadata','MPI_Win_create(copy_meta_data,nbytes,1,MPI_INFO_NULL,comm,win(1),ierr)',ierr,__LINE__)
  CALL MPI_Win_fence(0,win(1),ierr)
  call mpierr_check('bcast_seq_metadata','copy_meta_data MPI_Win_fence(0,win(1),ierr)',ierr,__LINE__)
  if (my_task /= io_task) then
     CALL MPI_Get(copy_meta_data,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,win(1),ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Get(copy_meta_data,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,win(1),ierr)',ierr,__LINE__)
  endif
  
  nbytes = int(metadatalength,i8)
  CALL MPI_Win_create(qc_meta_data,nbytes,1,MPI_INFO_NULL,comm,win(2),ierr)
  call mpierr_check('bcast_seq_metadata','MPI_Win_create(qc_meta_data,nbytes,1,MPI_INFO_NULL,comm,win(2),ierr)',ierr,__LINE__)
  CALL MPI_Win_fence(0,win(2),ierr)
  call mpierr_check('bcast_seq_metadata','qc_meta_data MPI_Win_fence(0,win(2),ierr)',ierr,__LINE__)
  if (my_task /= io_task) then
     CALL MPI_Get(qc_meta_data,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,win(2),ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Get(qc_meta_data,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,win(2),ierr)',ierr,__LINE__)
  endif

  do jw=1,size(win)
     CALL MPI_Win_fence(0,win(jw),ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Win_fence(0,win(jw),ierr)',ierr,__LINE__)
     CALL MPI_Win_free(win(jw),ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Win_free(win(jw),ierr)',ierr,__LINE__)
  enddo
  
  if (my_task /= io_task) then
     seq%first_time = ibuf(1)
     seq%last_time = ibuf(2)
     seq%copy_meta_data(1) = copy_meta_data
     seq%qc_meta_data(1) = qc_meta_data
  endif

#ifdef _camfv_
  ! MW -- LLshmem dependent
  if (my_task == io_task) call get_mw_metadata(numkeys, mw, keys)
  CALL MPI_Bcast(numkeys,1,MPI_INTEGER4,io_task,comm,ierr)
  call mpierr_check('bcast_seq_metadata','get_mw_metadata MPI_Bcast(numkeys,1,MPI_INTEGER4)',ierr,__LINE__)
  if (numkeys > 0) then
     if (my_task /= io_task) allocate(mw(numkeys))
     nchunk = (storage_size(mw)+bitsperbyte-1)/bitsperbyte ! in bytes
     nbytes = int(numkeys,kind(nbytes)) * int(nchunk,kind(nbytes)) ! << 2GB ? not necessarely as numkeys can be ~ num_obs !!! (beware of IASI)
     if (my_task == io_task) then
        write(0,*) 'bcast_seq_metadata(mw): bitsperbyte,nchunk,numkeys,nbytes,storage_size(mw)=',&
                                            bitsperbyte,nchunk,numkeys,nbytes,storage_size(mw)
     endif
     CALL MPI_Win_create(mw,nbytes,1,MPI_INFO_NULL,comm,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Win_create(mw,nbytes,1,...)',ierr,__LINE__)
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','mw[pre] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) then
        CALL MPI_Get(mw,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,xwin,ierr)
        call mpierr_check('bcast_seq_metadata','MPI_Get(mw,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,...)',ierr,__LINE__)
     endif
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','mw[post] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) call set_mw_metadata(mw,keys)
     CALL MPI_Win_free(xwin,ierr)
     call mpierr_check('bcast_seq_metadata','mw MPI_Win_free(xwin,ierr)',ierr,__LINE__)
  endif
#if 0
  if (allocated(mw) .and. allocated(keys)) then
     do j=1,size(keys)
        call write_rttov_metadata(keys(j),0,compact=.TRUE.)
     enddo
  endif
#endif
  if (allocated(mw)) deallocate(mw)
  if (allocated(keys)) deallocate(keys)
  
  ! IASIIR -- LLshmem dependent
  if (my_task == io_task) call get_iasiir_metadata(numkeys, iasiir, keys)
  CALL MPI_Bcast(numkeys,1,MPI_INTEGER4,io_task,comm,ierr)
  call mpierr_check('bcast_seq_metadata','get_iasiir_metadata MPI_Bcast(numkeys,1,MPI_INTEGER4)',ierr,__LINE__)
  if (numkeys > 0) then
     if (my_task /= io_task) allocate(iasiir(numkeys))
     nchunk = (storage_size(iasiir)+bitsperbyte-1)/bitsperbyte ! in bytes
     nbytes = int(numkeys,kind(nbytes)) * int(nchunk,kind(nbytes)) ! << 2GB ? not necessarely as numkeys can be ~ num_obs !!! (beware of IASI)
     if (my_task == io_task) then
        write(0,*) 'bcast_seq_metadata(iasiir): bitsperbyte,nchunk,numkeys,nbytes,storage_size(iasiir)=',&
                                                bitsperbyte,nchunk,numkeys,nbytes,storage_size(iasiir)
     endif
     CALL MPI_Win_create(iasiir,nbytes,1,MPI_INFO_NULL,comm,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Win_create(iasiir,nbytes,1,...)',ierr,__LINE__)
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','iasiir[pre] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) then
        CALL MPI_Get(iasiir,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,xwin,ierr)
        call mpierr_check('bcast_seq_metadata','MPI_Get(iasiir,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,...)',ierr,__LINE__)
     endif
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','iasiir[post] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) call set_iasiir_metadata(iasiir,keys)
     CALL MPI_Win_free(xwin,ierr)
     call mpierr_check('bcast_seq_metadata','iasiir MPI_Win_free(xwin,ierr)',ierr,__LINE__)
  endif
#if 0
  if (allocated(iasiir) .and. allocated(keys)) then
     do j=1,size(keys)
        call write_rttov_metadata(keys(j),0,compact=.TRUE.)
     enddo
  endif
#endif
  if (allocated(iasiir)) deallocate(iasiir)
  if (allocated(keys)) deallocate(keys)

  ! GPSRO -- LLshmem dependent
  if (my_task == io_task) call get_gpsro_ref(numkeys, gpsro, keys)
  CALL MPI_Bcast(numkeys,1,MPI_INTEGER4,io_task,comm,ierr)
  call mpierr_check('bcast_seq_metadata','get_gpsro_metadata MPI_Bcast(numkeys,1,MPI_INTEGER4)',ierr,__LINE__)
  if (numkeys > 0) then
     if (my_task /= io_task) allocate(gpsro(numkeys))
     nchunk = (storage_size(gpsro)+bitsperbyte-1)/bitsperbyte ! in bytes
     nbytes = int(numkeys,kind(nbytes)) * int(nchunk,kind(nbytes)) ! << 2GB ? not necessarely as numkeys can be ~ num_obs !!! (probably not in case of GPSRO, though)
     if (my_task == io_task) then
        write(0,*) 'bcast_seq_metadata(gpsro): bitsperbyte,nchunk,numkeys,nbytes,storage_size(gpsro)=',&
                                               bitsperbyte,nchunk,numkeys,nbytes,storage_size(gpsro)
     endif
     CALL MPI_Win_create(gpsro,nbytes,1,MPI_INFO_NULL,comm,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','MPI_Win_create(gpsro,nbytes,1,...)',ierr,__LINE__)
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','gpsro[pre] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) then
        CALL MPI_Get(gpsro,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,xwin,ierr)
        call mpierr_check('bcast_seq_metadata','MPI_Get(gpsro,nbytes,MPI_BYTE,io_task,tgtdisp,nbytes,MPI_BYTE,...)',ierr,__LINE__)
     endif
     CALL MPI_Win_fence(0,xwin,ierr)
     call mpierr_check('bcast_seq_metadata','gpsro[post] MPI_Win_fence(0,xwin,ierr)',ierr,__LINE__)
     if (my_task /= io_task) call set_gpsro_ref(gpsro,keys)
     CALL MPI_Win_free(xwin,ierr)
     call mpierr_check('bcast_seq_metadata','gpsro MPI_Win_free(xwin,ierr)',ierr,__LINE__)
  endif
  if (allocated(gpsro)) deallocate(gpsro)
  if (allocated(keys)) deallocate(keys)
#endif
  
  call task_sync(comm)
end subroutine bcast_seq_metadata

!------------------------------------------------------------------

! previous versions of this code had logic to read an older
! format obs_seq file.  that code can't work with the current
! files so it's been removed to simplify the code.  since pre_I_format
! is in the interface it stays for now, but it always returns .false.
! it should be deprecated at some point.
!
! Return the num_copies, num_qc, num_obs and max_num_obs along
! with the file format:  formatted or unformatted

subroutine read_obs_seq_header(file_name, num_copies, num_qc, num_obs, &
   max_num_obs, file_id, read_format, pre_I_format, close_the_file, ens_size)

character(len=*),  intent(in)  :: file_name
integer,           intent(out) :: num_copies, num_qc, num_obs, max_num_obs, file_id
character(len=*),  intent(out) :: read_format
logical,           intent(out) :: pre_I_format
logical, optional, intent(in)  :: close_the_file
integer, optional, intent(in)  :: ens_size

character(len=16) :: label(2)
integer :: ios

! always false now, should be deprecated
pre_I_format = .false.

! Try opening the file.  if it doesn't exist or can't be
! opened this call won't return.

if (is_d4o_format()) then
   file_id = -1 ! not in use
   call read_d4o_catalog(file_name, read_format, num_copies, num_qc, num_obs, max_num_obs, ens_size)
else
   read_format = 'formatted'
   file_id = open_file(file_name, form=read_format, action='read')

   ! if open_file() returns, we have opened the file.  try to read
   ! what we expect to find in a valid obs_seq file. if that fails
   ! close the file and reopen as unformatted and try again to read.

   ! the check routine reads enough of the file to verify it is ok,
   ! and leaves the file positioned right after reading the initial 
   ! header string 'obs_sequence'

   ios = check_obs_seq_header(file_id, read_format)
   if(ios /= 0) then  ! try reading binary formats
      call close_file(file_id)

      read_format = 'unformatted'
      file_id = open_file(file_name, form=read_format, action='read', convert=read_binary_file_format)
      ios     = check_obs_seq_header(file_id, read_format)

      if(ios /= 0) then ! try the other flavor

         !>@todo Can we check the other binary file endianness ... can only be native, big or little ... 
         !>      could remove obs_sequence_nml:read_binary_file_format

         ! the file exists but isn't recognizable as one of our obs_seq files.
         ! it could be the wrong byte order, or just not an obs_seq file.
         write(string1, *) 'File "', trim(file_name), '" is not recognized as a DART observation sequence file.'
         write(string2, *) 'Attempted to read both as a formatted (ascii) and unformatted (binary) file.'
         write(string3, *) 'For binary files, endian selection was "'//trim(read_binary_file_format)//'"' 
         call error_handler(E_ERR, 'read_obs_seq_header', string1, &
              source, text2=string2, text3=string3)
      endif
   endif

   ! if we get here we've opened the file in the right format
   ! and we've read the 'obs_sequence' header string.

   ! Read in the obs_kind mapping table.  (second arg was pre_I_format)
   call read_type_of_obs_table(file_id, .false., read_format)

   ! Read in the rest of the header information
   if (read_format == 'formatted') then
      read(file_id, *) label(1), num_copies, label(2), num_qc
      read(file_id, *) label(1), num_obs, label(2), max_num_obs
   else
      read(file_id) num_copies, num_qc, num_obs, max_num_obs
   endif

   ! Close the file if requested by optional argument
   if(present(close_the_file)) then
      if(close_the_file) call close_file(file_id)
   endif
endif

end subroutine read_obs_seq_header

!-------------------------------------------------

! ok, this needs some explanation.  for a binary formatted file,
! even if the wrong endian-ness, the first read succeeds and only
! when trying to read the second string does it fail.  at that
! point we're in the obs_kind module and there's no context to 
! tell you what file, what might be wrong, etc.  so this routine
! reads the first 2 lines of the file and returns 0 only if both succeed.
! it then rewinds the file and rereads the first line so the calling code
! is able to call the table_of_contents read routine.

function check_obs_seq_header(file_id, read_format)
 
integer,          intent(in) :: file_id
character(len=*), intent(in) :: read_format
integer :: check_obs_seq_header

integer :: ios
character(len=12) :: file_header   ! 'obs_sequence'
character(len=20) :: toc_header    ! 'obs_kind_definitions' (old) OR 'obs_type_definitions' (new, and correct)

if (read_format == 'formatted') then
   read(file_id, *, iostat = ios) file_header
else
   read(file_id, iostat = ios) file_header
endif
   
if(ios /= 0 .or. file_header /= 'obs_sequence') then
   check_obs_seq_header = -1
   return
endif

if (read_format == 'formatted') then
   read(file_id, *, iostat = ios) toc_header
else
   read(file_id, iostat = ios) toc_header
endif
   
if(ios /= 0 .or. (toc_header /= 'obs_kind_definitions' .and. toc_header /= 'obs_type_definitions')) then
   check_obs_seq_header = -1
   return
endif

rewind(file_id)

if (read_format == 'formatted') then
   read(file_id, *, iostat = ios) file_header
else
   read(file_id, iostat = ios) file_header
endif
   
check_obs_seq_header = 0

end function check_obs_seq_header

!-------------------------------------------------

subroutine delete_seq_head(first_time, seq, all_gone)

! Deletes all observations in the sequence with times before first_time. 
! If no observations remain, return all_gone as .true.

type(time_type),         intent(in)    :: first_time
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_def_type)   :: obs_def
type(obs_type)       :: obs
type(time_type)      :: pre_first_time, time0, seq_start_time
integer              :: key_bounds(2), num_keys, i
integer, allocatable :: keys(:)
logical              :: out_of_range

call error_handler(E_ERR,'delete_seq_head','we should not enter this routine at all', source)

! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))

! Set lowest possible time
time0 = set_time(0, 0)

! Get time of first observation in sequence; if there isn't one, return all_gone
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   return
else
   call get_obs_def(obs, obs_def)
   seq_start_time = get_obs_def_time(obs_def)
endif

! If first_time is lowest possible time no need to delete
if(first_time == time0) then
   all_gone = .false.
   call destroy_obs(obs)
   return
end if

! Get last possible time for observations that should NOT be used
pre_first_time = first_time - set_time(1, 0)

! Get bounds of keys in sequence that are before the first time
call get_obs_time_range(seq, time0, pre_first_time, key_bounds, num_keys, out_of_range)

! If it is out_of_range could be because all obs are after or all are before
if(out_of_range) then
   if(seq_start_time > pre_first_time) then
      ! Whole sequence is after
      all_gone = .false.
   else
      ! Whole sequence is before; but sequence is not altered?
      all_gone = .true.
   endif
   ! Destroy temp storage and return
   call destroy_obs(obs)
   return
endif

! compare num_keys with all possible keys in file; if equal, you have
! also removed all obs and should return all_gone = .true.  
if (num_keys == get_num_key_range(seq)) then
   all_gone = .true.
   ! Destroy temp storage and return
   call destroy_obs(obs)
   return
endif

! If here, then there are a set of observations that are not being used at beginning
! Delete them from the sequence
all_gone = .false.
allocate(keys(num_keys))
call get_time_range_keys(seq, key_bounds, num_keys, keys)

! Loop through the keys and delete these observations
do i = 1, num_keys
   call get_obs_from_key(seq, keys(i), obs)
   call delete_obs_from_seq(seq, obs)
end do

! Free up storage before returning
deallocate(keys)
call destroy_obs(obs)

end subroutine delete_seq_head


!-------------------------------------------------


subroutine delete_seq_tail(last_time, seq, all_gone)

! Delete all observations in the sequence with times after last_time.
! If there are none before this time return that the sequence is all_gone.

type(time_type),         intent(in)    :: last_time
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_def_type)   :: obs_def
type(obs_type)       :: obs
type(time_type)      :: post_last_time, end_of_seq_time
integer              :: key_bounds(2), num_keys, i
integer, allocatable :: keys(:)
logical              :: out_of_range

call error_handler(E_ERR,'delete_seq_tail','we should not enter this routine at all', source)

! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))

! Get earliest time of observations that should be deleted
post_last_time = last_time + set_time(1, 0)

! Get time of last observation in sequence; if there are none, return all_gone
if(.not. get_last_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   return
endif
call get_obs_def(obs, obs_def)
end_of_seq_time = get_obs_def_time(obs_def)

! Get bounds of keys in sequence that are after the last_time
call get_obs_time_range(seq, post_last_time, end_of_seq_time, &
   key_bounds, num_keys, out_of_range)

! If it is out_of_range could be because all obs are before or all are after (none left)
if(out_of_range) then
   if(end_of_seq_time < post_last_time) then
      ! Whole sequence is after, start at beginning
      all_gone = .false.
   else
      ! Whole sequence is before
      all_gone = .true.
   endif
   ! Free storage and return
   call destroy_obs(obs)
   return
endif

! compare num_keys with all possible keys in file; if equal, you have
! also removed all obs and should return all_gone = .true.  
if (num_keys == get_num_key_range(seq)) then
   all_gone = .true.
   ! Destroy temp storage and return
   call destroy_obs(obs)
   return
endif

! If here, then there are a set of observations that are not being used at the end
! Delete them from the sequence
all_gone = .false.
allocate(keys(num_keys))
call get_time_range_keys(seq, key_bounds, num_keys, keys)

! Loop through the keys and delete these observations
do i = 1, num_keys
   call get_obs_from_key(seq, keys(i), obs)
   call delete_obs_from_seq(seq, obs)
end do

! Free storage before ending
deallocate(keys)
call destroy_obs(obs)

end subroutine delete_seq_tail


!-------------------------------------------------

#if 0
! not used
subroutine delete_obs_by_typelist(num_obs_input_types, obs_input_types, &
                                  keep_list, seq, all_gone)

! Delete all observations in the sequence which either are or are not
! in the given obs types list; the sense depends on the keep flag.
! If there are no obs left afterwards return that the sequence is all_gone.

integer,                 intent(in)    :: num_obs_input_types
character(len=*),        intent(in)    :: obs_input_types(:)
logical,                 intent(in)    :: keep_list
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_def_type)   :: obs_def
type(obs_type)       :: obs, prev_obs
integer              :: i
logical              :: is_this_last, remove_me, first_obs
integer              :: obs_type_index(num_obs_input_types), this_obs_type

! Some sanity checking on the input args.
if (num_obs_input_types <= 0) then
   write(string1,*) 'num_obs_input_types must be > 0'
   call error_handler(E_ERR,'delete_obs_by_typelist', string1, source)
endif
! Ok for list to be longer; only first N items will be used.  But list
! cannot be shorter.
if (size(obs_input_types) < num_obs_input_types) then
   write(string1,*) 'num_obs_input_types must be >= length of list'
   call error_handler(E_ERR,'delete_obs_by_typelist', string1, source)
endif


! Get index numbers for each type string
do i=1, num_obs_input_types
   obs_type_index(i) = get_index_for_type_of_obs(obs_input_types(i))
   if (obs_type_index(i) < 0) then
      write(string1,*) 'obs_type ', trim(obs_input_types(i)), ' not found'
      call error_handler(E_ERR,'delete_obs_by_typelist', string1, source)
   endif
enddo

! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))
call init_obs(prev_obs, get_num_copies(seq), get_num_qc(seq))

! Iterate entire sequence, deleting obs which are (are not) on the list
! First, make sure there are obs to delete, and initialize first obs.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   call destroy_obs(prev_obs)
   return
endif

first_obs = .true.
prev_obs = obs

! This is going to be O(n*m), n=num obs in seq, m=typelist length
is_this_last = .false.
allobs : do while (.not. is_this_last)

   call get_obs_def(obs, obs_def)
   this_obs_type = get_obs_def_type_of_obs(obs_def)
!print *, 'this_obs_key, type = ', obs%key, this_obs_type

   ! Do we keep things on the list, or toss them?
   if (keep_list) then
      ! Assume we are going to delete the obs unless we find it on the list
      ! (can exit do loop early this way).
      remove_me = .true.
      do i=1, num_obs_input_types
         if (obs_type_index(i) == this_obs_type) then
            remove_me = .false.
            exit
         endif
      end do
   else
      ! Assume we are going to keep the obs unless we find it on the list
      ! (can exit do loop early this way).
      remove_me = .false.
      do i=1, num_obs_input_types
         if (obs_type_index(i) == this_obs_type) then
            remove_me = .true.
            exit
         endif
      end do
   endif

   ! either remove the obs and update prev, or move to next obs
   ! must be careful here; wrong order == wrong output
   if (remove_me) then
      if (first_obs) then
         call delete_obs_from_seq(seq, obs)
         if(.not. get_first_obs(seq, obs)) exit allobs
      else
         call delete_obs_from_seq(seq, obs)
         ! cannot simply use prev_obs; cached copy out of sync with seq one
         call get_next_obs_from_key(seq, prev_obs%key, obs, is_this_last)
      endif
   else
      first_obs = .false.
      prev_obs = obs
      call get_next_obs(seq, prev_obs, obs, is_this_last)
   endif
   
end do allobs

! Figure out if there are no more obs left in the sequence.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
else
   all_gone = .false.
endif

! Done.  delete temp storage and return.
call destroy_obs(obs)
call destroy_obs(prev_obs)

end subroutine delete_obs_by_typelist
#endif

!-------------------------------------------------

#if 0
! not used
subroutine delete_obs_by_qc(qc_index, qc_min, qc_max, seq, all_gone)

! Delete all observations in the sequence which are outside min/max range.
! missing_r8 means infinity in that direction.
! If there are no obs left afterwards return that the sequence is all_gone.

integer,                 intent(in)    :: qc_index
real(r8),                intent(in)    :: qc_min, qc_max
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_type)       :: obs, prev_obs
logical              :: is_this_last, remove_me, first_obs
real(r8)             :: qcval(1)

! Some sanity checking on the input args.
if (qc_index > seq%num_qc) then
   write(string1,*) 'qc_index must be <', seq%num_qc
   call error_handler(E_ERR,'delete_obs_by_qc', string1, source)
endif
! Ok for min/max to be missing_r8; if both specified, min must be <= max.
if (qc_min /= missing_r8 .and. qc_max /= missing_r8 .and. qc_min > qc_max) then
   write(string1,*) 'qc_min must be less than or equal qc_max'
   call error_handler(E_ERR,'delete_obs_by_qc', string1, source)
endif

! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))
call init_obs(prev_obs, get_num_copies(seq), get_num_qc(seq))
 
! Iterate entire sequence, deleting obs which have a qc outside the range
! First, make sure there are obs to delete, and initialize first obs.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   call destroy_obs(prev_obs)
   return
endif

first_obs = .true.
prev_obs = obs

! This is going to be O(n), n=num obs in seq
is_this_last = .false.
allobs : do while (.not. is_this_last)

   call get_qc(obs, qcval, qc_index)
!print *, 'this_obs_key, qc = ', obs%key, qcval(1)

   remove_me = .false.
   if (qc_min /= missing_r8 .and. qcval(1) < qc_min) remove_me = .true.
   if (qc_max /= missing_r8 .and. qcval(1) > qc_max) remove_me = .true.

   ! either remove the obs and update prev, or move to next obs
   if (remove_me) then
      if (first_obs) then
         call delete_obs_from_seq(seq, obs)
         if(.not. get_first_obs(seq, obs)) exit allobs
      else
         call delete_obs_from_seq(seq, obs)
         ! cannot simply use prev_obs; cached copy out of sync with seq one
         call get_next_obs_from_key(seq, prev_obs%key, obs, is_this_last)
      endif
   else
      first_obs = .false.
      prev_obs = obs
      call get_next_obs(seq, prev_obs, obs, is_this_last)
   endif
   
end do allobs

! Figure out if there are no more obs left in the sequence.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
else
   all_gone = .false.
endif

! Done.  delete temp storage and return.
call destroy_obs(obs)
call destroy_obs(prev_obs)

end subroutine delete_obs_by_qc
#endif

!-------------------------------------------------

#if 0
! not used
subroutine delete_obs_by_copy(copy_index, copy_min, copy_max, obs_type_name, &
                              seq, all_gone)

! Delete all observations in the sequence which are outside min/max range.
! missing_r8 means infinity in that direction.
! If there are no obs left afterwards return that the sequence is all_gone.

integer,                 intent(in)    :: copy_index
real(r8),                intent(in)    :: copy_min, copy_max
character(len=*),        intent(in)    :: obs_type_name
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_def_type)   :: obs_def
type(obs_type)       :: obs, prev_obs
integer              :: obs_type_index, this_obs_type
logical              :: is_this_last, remove_me, first_obs
real(r8)             :: copyval(1)

! Some sanity checking on the input args.
if (copy_index > seq%num_copies) then
   write(string1,*) 'copy_index must be <', seq%num_copies
   call error_handler(E_ERR,'delete_obs_by_copy', string1, source)
endif
! Ok for min/max to be missing_r8; if both specified, min must be <= max.
if (copy_min /= missing_r8 .and. copy_max /= missing_r8 .and. &
    copy_min > copy_max) then
   write(string1,*) 'copy_min must be less than or equal copy_max'
   call error_handler(E_ERR,'delete_obs_by_copy', string1, source)
endif

! Get index number for the type
if (len(trim(obs_type_name)) > 0) then
   obs_type_index = get_index_for_type_of_obs(obs_type_name)
   if (obs_type_index < 0) then
      write(string1,*) 'obs_type ', trim(obs_type_name), ' not found'
      call error_handler(E_ERR,'delete_obs_by_copy', string1, source)
   endif
else
   obs_type_index = -1
endif

! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))
call init_obs(prev_obs, get_num_copies(seq), get_num_qc(seq))
 
! Iterate entire sequence, deleting obs which have a copyval outside the range
! First, make sure there are obs to delete, and initialize first obs.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   call destroy_obs(prev_obs)
   return
endif

first_obs = .true.
prev_obs = obs

! This is going to be O(n), n=num obs in seq
is_this_last = .false.
allobs : do while (.not. is_this_last)

   call get_obs_values(obs, copyval, copy_index)
!print *, 'this_obs_key, val = ', obs%key, copyval(1)

   remove_me = .false.

   ! need to check type here, or below?
   if (obs_type_index > 0) then
      call get_obs_def(obs, obs_def)
      this_obs_type = get_obs_def_type_of_obs(obs_def)
      !print *, 'this_obs_key, type = ', obs%key, this_obs_type
      if (this_obs_type /= obs_type_index) remove_me = .true.
   endif

   if (copy_min /= missing_r8 .and. copyval(1) < copy_min) remove_me = .true.
   if (copy_max /= missing_r8 .and. copyval(1) > copy_max) remove_me = .true.

   ! either remove the obs and update prev, or move to next obs
   if (remove_me) then
      if (first_obs) then
         call delete_obs_from_seq(seq, obs)
         if(.not. get_first_obs(seq, obs)) exit allobs
      else
         call delete_obs_from_seq(seq, obs)
         ! cannot simply use prev_obs; cached copy out of sync with seq one
         call get_next_obs_from_key(seq, prev_obs%key, obs, is_this_last)
      endif
   else
      first_obs = .false.
      prev_obs = obs
      call get_next_obs(seq, prev_obs, obs, is_this_last)
   endif
   
end do allobs

! Figure out if there are no more obs left in the sequence.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
else
   all_gone = .false.
endif

! Done.  delete temp storage and return.
call destroy_obs(obs)
call destroy_obs(prev_obs)


end subroutine delete_obs_by_copy
#endif

!-------------------------------------------------

#if 0
! Not used
! To be portable between different location types (i.e. 1D, 3D sphere)
! this can only refer to the location type and the actual comparison must
! be inside the locations module itself.
subroutine select_obs_by_location(min_loc, max_loc, seq, all_gone)

! Delete all observations in the sequence which are outside the bounding box.
! If there are no obs left afterwards return that the sequence is all_gone.

type(location_type),     intent(in)    :: min_loc, max_loc
type(obs_sequence_type), intent(inout) :: seq
logical,                 intent(out)   :: all_gone

type(obs_def_type)   :: obs_def
type(obs_type)       :: obs, prev_obs
type(location_type)  :: location
logical              :: is_this_last, inside, first_obs


! Initialize an observation type with appropriate size
call init_obs(obs, get_num_copies(seq), get_num_qc(seq))
call init_obs(prev_obs, get_num_copies(seq), get_num_qc(seq))

! Iterate entire sequence, deleting obs which are (are not) on the list
! First, make sure there are obs to delete, and initialize first obs.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
   call destroy_obs(obs)
   call destroy_obs(prev_obs)
   return
endif

first_obs = .true.
prev_obs = obs

! This is going to be O(n*m), n=num obs in seq, m=typelist length
is_this_last = .false.
allobs : do while (.not. is_this_last)

   call get_obs_def(obs, obs_def)
   location = get_obs_def_location(obs_def)

   ! each diff locations mod has a different one of these
   inside = is_location_in_region(location, min_loc, max_loc)
   
   ! same code as delete/keep by obstype; do any code fixes both places
   if (.not. inside) then
      if (first_obs) then
         call delete_obs_from_seq(seq, obs)
         if(.not. get_first_obs(seq, obs)) exit allobs
      else
!print *, 'going to del obs key ', obs%key
!print *, 'prev key is ', prev_obs%key
         call delete_obs_from_seq(seq, obs)
         ! cannot simply use prev_obs; cached copy out of sync with seq one
         call get_next_obs_from_key(seq, prev_obs%key, obs, is_this_last)
!print *, 'next obs now is key ', obs%key
      endif
   else
!print *, 'no del, keep this obs key ', obs%key
      first_obs = .false.
     prev_obs = obs
!print *, 'prev obs now is key ', prev_obs%key
!print *, 'obs was key ', obs%key
      call get_next_obs(seq, prev_obs, obs, is_this_last)
!print *, 'obs now is key ', obs%key
   endif
   
end do allobs

! Figure out if there are no more obs left in the sequence.
if(.not. get_first_obs(seq, obs)) then
   all_gone = .true.
else
   all_gone = .false.
endif

! Done.  delete temp storage and return.
call destroy_obs(obs)
call destroy_obs(prev_obs)

end subroutine select_obs_by_location
#endif

!------------------------------------------------------------------
! Figure out which of the total possible kinds (really types) exist in this
! sequence, and set the array values to 0 for no, 1 for yes.

subroutine set_used_kinds(seq, have)
type(obs_sequence_type), intent(in)  :: seq
integer,                 intent(out) :: have(:)

integer :: i, num_copies, num_qc
integer :: num_obs
type(obs_type) :: obs
!type(dobs_type) :: spill
type(obs_def_type) :: obs_def
integer :: obs_kind_ind

! Get existing header info
num_copies  = min(1,get_num_copies(seq))
num_qc      = min(1,get_num_qc(seq))
num_obs     = get_num_obs(seq)

call init_obs(obs, num_copies, num_qc) !, spill=spill)

! start with no types
have(:) = 0
do i=1, num_obs
   ! cheating here, i know.  iterate the list in order the obs occur in
   ! the file, not linked list order.  i just want to know about the type
   ! of each obs, nothing about time or anything else.
   call get_obs_from_key(seq, i, obs)
   call get_obs_def(obs, obs_def)
   obs_kind_ind = get_obs_def_type_of_obs(obs_def)
   if (obs_kind_ind < 1) cycle   ! ignore identity obs
   have(obs_kind_ind) = 1
enddo

call destroy_obs(obs) !,spill=spill)

end subroutine set_used_kinds


!------------------------------------------------------------------
! Follow the linked list entries to copy only the linked observations
! from one sequence to the other.

!>@ todo ... test this routine and make public or get rid of it

#if 0
! not used
subroutine copy_obs_seq(oldseq, newseq, time1, time2)

type(obs_sequence_type),   intent(in)  :: oldseq
type(obs_sequence_type),   intent(out) :: newseq
type(time_type), optional, intent(in)  :: time1, time2

integer :: i, num_copies, num_qc, max_num_obs
integer :: num_keys, key_bounds(2)
integer, pointer :: keylist(:)
type(obs_type) :: obs
type(time_type) :: first_time, last_time
logical :: out_of_range

! Get existing header info
num_copies  = get_num_copies(oldseq)
num_qc      = get_num_qc(oldseq)
max_num_obs = get_max_num_obs(oldseq)

call init_obs(obs, num_copies, num_qc)

! Really count how many obs are in the linked list, with
! optional time starts and ends.
if (present(time1)) then
   first_time = time1
else
   call get_obs_from_key(oldseq, oldseq%first_time, obs)
   first_time = get_obs_def_time(obs%def)
endif
if (present(time2)) then
   last_time = time2
else
   call get_obs_from_key(oldseq, oldseq%last_time, obs)
   last_time = get_obs_def_time(obs%def)
endif

call destroy_obs(obs)

call get_obs_time_range(oldseq, first_time, last_time, &
                        key_bounds, num_keys, out_of_range)
if (out_of_range) then
   write(string1, *) 'All keys out of range'
   call error_handler(E_ERR, 'copy_obs_seq', string1, source)
endif

call init_obs_sequence(newseq, num_copies, num_qc, num_keys, shmem=.FALSE.)

allocate(keylist(num_keys))
call get_time_range_keys(oldseq, key_bounds, num_keys, keylist)

call init_obs(obs, num_copies, num_qc)

do i=1, num_keys
   call get_obs_from_key(oldseq, keylist(i), obs)
   call set_obs(newseq, obs, i)
enddo

! Release the temp storage
deallocate(keylist)
call destroy_obs(obs)

end subroutine copy_obs_seq
#endif

!=================================================

! Functions for the obs_type
!-------------------------------------------------
subroutine init_obs(obs, num_copies, num_qc, fill, spill)

! Sort of a constructor for obs_type
! Should this be public or private just for sequence?

integer,        intent(in)    :: num_copies, num_qc
type(obs_type), intent(inout) :: obs
logical, optional, intent(in) :: fill
type(dobs_type), intent(inout), optional :: spill
logical :: LLfill

LLfill = .TRUE.
if (present(fill)) LLfill = fill

if ((num_copies > 1 .or. num_qc > 1) .and. .not.present(spill)) then
   call error_handler(E_ERR, 'init_obs:', 'When num_copies or num_qc > 1, then spill must be present', source, lineno=__LINE__)
endif

if (num_copies >= 1 .and. LLfill) obs%obsvalue = missing_r8
if (num_qc >= 1 .and. LLfill)     obs%dataqc = zero

if (present(spill) .and. num_copies > 1) then
   if (allocated(spill%xvalues)) then
      if (size(spill%xvalues) /= num_copies-1) deallocate(spill%xvalues)
   endif
   if (.not.allocated(spill%xvalues)) allocate(spill%xvalues(2:num_copies))
   if (LLfill) spill%xvalues = missing_r8
endif

if (present(spill) .and. num_qc > 1) then
   if (allocated(spill%xqc)) then
      if (size(spill%xqc) /= num_qc-1) deallocate(spill%xqc)
   endif
   if (.not.allocated(spill%xqc)) allocate(spill%xqc(2:num_qc))
   if (LLfill) spill%xqc = zero
endif

if (present(spill)) spill%key = -1

obs%key = -1
obs%prev_time = -1
obs%next_time = -1
obs%cov_group = -1

end subroutine init_obs

!-----------------------------------------------------

subroutine copy_obs(obs1, obs2)

! This routine is overloaded with the = operator

type(obs_type), intent(inout) :: obs1
type(obs_type), intent(in) :: obs2

obs1%key = obs2%key
call copy_obs_def(obs1%def, obs2%def)

obs1%obsvalue = obs2%obsvalue
obs1%dataqc = obs2%dataqc

obs1%prev_time = obs2%prev_time
obs1%next_time = obs2%next_time
obs1%cov_group = obs2%cov_group

end subroutine copy_obs

subroutine copy_spill(spill1, spill2)

! This routine is overloaded with the = operator

type(dobs_type), intent(inout) :: spill1
type(dobs_type), intent(in) :: spill2
integer ubxv, ubqc

call error_handler(E_MSG, 'copy_spill', 'entering ...')

spill1%key = spill2%key
ubxv = ubound(spill2%xvalues,dim=1)
ubqc = ubound(spill2%xqc,dim=1)

if (allocated(spill1%xvalues)) then
   if (size(spill1%xvalues) /= size(spill2%xvalues)) then
      deallocate(spill1%xvalues)
      allocate(spill1%xvalues(2:ubxv))
   endif
else
   allocate(spill1%xvalues(2:ubxv))
endif

if (allocated(spill1%xqc)) then
   if (size(spill1%xqc) /= size(spill2%xqc)) then
      deallocate(spill1%xqc)
      allocate(spill1%xqc(2:ubqc))
   endif
else
   allocate(spill1%xqc(2:ubqc))
endif

spill1%xvalues(2:ubxv) = spill2%xvalues(2:ubxv)
spill1%xqc(2:ubqc) = spill2%xqc(2:ubqc)

end subroutine copy_spill

!-----------------------------------------------------

subroutine print_seq(where,seq,iunit,keys,results)
  USE, INTRINSIC :: ISO_C_BINDING, ONLY : C_LOC, C_PTR
  character(len=*),intent(in) :: where
  type(obs_sequence_type), intent(in) :: seq
  integer, intent(in), optional :: iunit
  integer, intent(in), optional :: keys(:)
  logical, intent(in), optional :: results
  integer :: num_obs, io, nkeys, i, j, mytask
  type(time_type) :: t
  integer :: year, month, day, hour, minute, second
  integer :: kind, defkey
  integer :: num_copies, num_qc, ens_size, member, lo, hi
  integer :: bitsperbyte
  character(len=19) :: YYYYMMDDhhmmss
  type(location_type) :: location
  real(r8), target :: xyz(3), oev, outqc, prior, posterior
  real(r8), pointer :: lat,lon,vert
  integer :: which_vert
  type(obs_def_type) :: def
  logical LLresults
  type(c_ptr) :: obs_addr, spill_addr
  integer(i8) :: iobs_addr, ispill_addr
  integer(i8) :: iobs_size, ispill_size
  character(len=len(where)+80) :: prefix
  character(len=1) :: onebyte
  
  if (.not.associated(seq%obs)) return
  io = 6
  if (present(iunit)) io = iunit
  if (io < 0) return
  nkeys = 0
  if (present(keys)) nkeys = size(keys)
  num_obs = size(seq%obs)
  if (num_obs <= 0) return

  mytask = my_task_id()
  
  lat => xyz(2)
  lon => xyz(1)
  vert => xyz(3)
  
  num_copies = seq%num_copies
  num_qc = seq%num_qc
  ens_size = 0
  if (num_copies > 1) ens_size = (num_copies - 5)/2 ! reverse engineering

  LLresults = .true.
  if (present(results)) LLresults = results

  bitsperbyte = storage_size(onebyte) ! usually 8

  obs_addr = C_LOC(seq%obs)
  iobs_addr = transfer(obs_addr,iobs_addr)
  if (iobs_addr /= 0) then
     iobs_size = (storage_size(seq%obs)+bitsperbyte-1)/bitsperbyte
     iobs_size = iobs_size * int(num_obs,i8)
  endif
  
  spill_addr = C_LOC(seq%spill)
  ispill_addr = transfer(spill_addr,ispill_addr)
  ispill_size = 0
  if (ispill_addr /= 0) then
     ispill_size = (storage_size(seq%spill)+bitsperbyte-1)/bitsperbyte
     ispill_size = ispill_size * int(num_obs,i8)
  endif

  write(io,1000) trim(where),mytask &
       & ,num_obs,num_copies,num_qc,ens_size,d4o_numens_env()

  write(io,1001) trim(where),mytask &
       & ,iobs_addr,iobs_size,ispill_addr,ispill_size
  
  write(io,1002) trim(where),mytask &
       & ,'Obs(i)','ObsKey','Prev_time','Next_time' &
       & ,'YYYY-MM-DD HH:MM:SS' &
       & ,'ObsErrorVariance','Latitude(deg)    ','Longitude(deg)    ','VerticalCoord    '&
       & ,'VType','Kind','DefKey' &
       & ,'ObsValue    ','Data_QC    '
  
#ifdef _camfv_
  write(prefix,1003) trim(where),mytask
#endif

1000 format("print_seq@",a,"#",i6.6,'@ num_obs=',i0,' num_copies=',i0,' num_qc=',i0,' ens_size=',i0,' (true ens_size=',i0,')')
1001 format("print_seq@",a,"#",i6.6,'@ obs_addr=0x',z0,' (size=',i0,' bytes) spill_addr=0x',z0,' (size=',i0,' bytes)')
1002 format("print_seq@",a,"#",i6.6,':',4a10,1x,a,1x,1p,4a20   ,1x,2a6,a10,2a20   )
1003 format("print_seq@",a,"#",i6.6,':')
2000 format("print_seq@",a,"#",i6.6,':',4i10,1x,a,1x,1p,4g20.12,1x,2i6,i10,2g20.12)
3000 format("print_seq@",a,"#",i6.6,'>','   2x(mean+spread) >>',10x,1p,5g20.12,' = Output_QC')
4000 format("print_seq@",a,"#",i6.6,'>','      member#',i4.4,14x,1p,2g20.12)
5000 format(i4.4,2('-',i2.2),1x,i2.2,2(':',i2.2))
  
  if (nkeys == 0) nkeys = num_obs
  do j=1,nkeys
     i = j
     if (present(keys)) i = keys(j)
     if (i < 1 .or. i > num_obs) cycle
     
     def = seq%obs(i)%def
     oev = get_obs_def_error_variance(def)
     kind = get_obs_def_type_of_obs(def)
     defkey = get_obs_def_key(def)
     t = get_obs_def_time(seq%obs(i)%def)
     call get_date(t, year, month, day, hour, minute, second)
     write(YYYYMMDDhhmmss,5000) year, month, day, hour, minute, second
     location = get_obs_def_location(def)
     xyz = get_location(location,which_vert)
     
     write(io,2000) trim(where),mytask &
          &,i,seq%obs(i)%key,seq%obs(i)%prev_time,seq%obs(i)%next_time &
          &,YYYYMMDDhhmmss &
          &,oev,lat,lon,vert&
          &,which_vert,kind,defkey &
          &,seq%obs(i)%obsvalue,seq%obs(i)%dataqc
     
#ifdef _camfv_
     call write_rttov_metadata(defkey,io,compact=.TRUE.,prefix=trim(prefix),bailout=.TRUE.)
#endif
     
     if (LLresults .and. ens_size > 0 .and. associated(seq%spill)) then
        lo = lbound(seq%spill(i)%xvalues,dim=1)
        hi = ubound(seq%spill(i)%xvalues,dim=1)
        if (lo == 2 .and. hi == num_copies) then
           outqc = missing_r8
           if (num_qc > 1) outqc = seq%spill(i)%xqc(2)
           write(io,3000) trim(where),mytask &
                &,seq%spill(i)%xvalues(2:5),outqc
           do member=1,ens_size
              prior = seq%spill(i)%xvalues(5+2*(member-1)+1)
              posterior = seq%spill(i)%xvalues(5+2*(member-1)+2)
              write(io,4000) trim(where),mytask &
                   &,member,prior,posterior
           enddo
        endif
     endif
  enddo

  flush(io)
end subroutine print_seq

subroutine print_obs(obs,spill,index)

type(obs_type), intent(in) :: obs
type(dobs_type), intent(in), optional :: spill
integer, intent(in), optional :: index  

character(len=256) :: string
integer :: i
real(r8) :: obs_error_variance

1000 format(i12,2x,1p,G30.20,2x,"0x",Z16.16)
1001 format(1p,G30.20,2x,"0x",Z16.16)

if (present(index)) then
   write(string, *) index
   call error_handler(E_MSG, '', '=== print_obs('//trim(adjustl(string))//') follows ===')
endif

write(string, *) obs%key
call error_handler(E_MSG, '', 'obs key: '//trim(string))

call error_handler(E_MSG, '', 'obs def: ')
call print_obs_def(obs%def)

call print_date(get_obs_def_time(obs%def))
obs_error_variance = get_obs_def_error_variance(obs%def)
write(string,1001) obs_error_variance, obs_error_variance
call error_handler(E_MSG, '', 'obs_error_variance = '//trim(string))

call error_handler(E_MSG, '', 'obs_copies: ')
write(string, 1000) i, obs%obsvalue, obs%obsvalue
call error_handler(E_MSG, '', '  '//trim(string))
if (present(spill)) then
   if (allocated(spill%xvalues)) then
      do i = 2, ubound(spill%xvalues,dim=1)
         write(string, 1000) i, spill%xvalues(i), spill%xvalues(i)
         call error_handler(E_MSG, '', '  '//trim(string))
      enddo
   endif
endif

call error_handler(E_MSG, '', 'obs_QCs: ')
write(string, 1000) i, obs%dataqc, obs%dataqc
if (present(spill)) then
   if (allocated(spill%xqc)) then
      call error_handler(E_MSG, '', 'obs_QCs: ')
      do i = 2, ubound(spill%xqc,dim=1)
         write(string, 1000) i, spill%xqc(i), spill%xqc(i)
         call error_handler(E_MSG, '', '  '//trim(string))
      enddo
   endif
endif

call error_handler(E_MSG, '', 'obs linked list info:')
write(string, *) obs%prev_time
call error_handler(E_MSG, '', 'prev obs key: '//trim(string))
write(string, *) obs%next_time
call error_handler(E_MSG, '', 'next obs key: '//trim(string))
write(string, *) obs%cov_group
call error_handler(E_MSG, '', 'cov group (unused): '//trim(string))

end subroutine print_obs

!-----------------------------------------------------

function eq_obs(obs1, obs2)

! This routine is overloaded with the == operator

type(obs_type), intent(in) :: obs1
type(obs_type), intent(in) :: obs2
logical :: eq_obs

integer :: i

eq_obs = .false.

if (obs1%def /= obs2%def) return
if (obs1%obsvalue /= obs2%obsvalue) return
if (obs1%dataqc /= obs2%dataqc) return

eq_obs = .true.

end function eq_obs

function eq_spill(spill1, spill2)

! This routine is overloaded with the == operator

type(dobs_type), intent(in) :: spill1
type(dobs_type), intent(in) :: spill2
logical :: eq_spill

integer :: i

eq_spill = .false.

if (allocated(spill1%xvalues) .and. .not. allocated(spill2%xvalues)) return
if (allocated(spill2%xvalues) .and. .not. allocated(spill1%xvalues)) return
if (size(spill1%xvalues) /= size(spill2%xvalues)) return
   
do i = 2, ubound(spill1%xvalues,dim=1)
   if (spill1%xvalues(i) /= spill2%xvalues(i)) return
enddo

if (allocated(spill1%xqc) .and. .not. allocated(spill2%xqc)) return
if (allocated(spill2%xqc) .and. .not. allocated(spill1%xqc)) return
if (size(spill1%xqc) /= size(spill2%xqc)) return
   
do i = 2,ubound(spill1%xqc,dim=1)
   if (spill1%xqc(i) /= spill2%xqc(i)) return
enddo

eq_spill = .true.

end function eq_spill

!-------------------------------------------------

function ne_obs(obs1, obs2)

! This routine is overloaded with the /= operator

type(obs_type), intent(in) :: obs1
type(obs_type), intent(in) :: obs2
logical :: ne_obs

ne_obs = .not. eq_obs(obs1, obs2)

end function ne_obs

function ne_spill(spill1, spill2)

! This routine is overloaded with the /= operator

type(dobs_type), intent(in) :: spill1
type(dobs_type), intent(in) :: spill2
logical :: ne_spill

ne_spill = .not. eq_spill(spill1, spill2)

end function ne_spill

!-------------------------------------------------

subroutine destroy_obs(obs,spill)

! Free up allocated storage in an observation type
type(obs_type), intent(inout) :: obs
type(dobs_type), intent(inout), optional :: spill

if (present(spill)) then
   if (allocated(spill%xvalues)) deallocate(spill%xvalues)
   if (allocated(spill%xqc)) deallocate(spill%xqc)
   if (allocated(spill%istatus_prior)) deallocate(spill%istatus_prior)
endif

call destroy_obs_def(obs%def)  ! volatile ? Yes. Very. But sync_d4o_data() in right places help

end subroutine destroy_obs

!-----------------------------------------------------

#if 0
! not used
subroutine copy_partial_obs(obs1, obs2, numcopies, copylist, &
                            numqc, qclist)

! Copy from obs2 to obs1, the entire contents of the
! obs def, but only the copies and qcs as listed (in order)
! Special value (0) means leave space but there is
! no existing value to copy.

type(obs_type), intent(inout) :: obs1
type(obs_type), intent(in)    :: obs2
integer,        intent(in)    :: numcopies, copylist(:), numqc, qclist(:)

integer :: i, ival

! only basic idiotproofing - detect bad indices in the lists
! without too much expense in time.  no checks here that length
! of lists are >= num sizes.

! numcopies and numqc are the new outgoing sizes in obs1.
! check the index lists to be sure they are >= 0 and <= size
! of existing data in obs2.  
ival = min(minval(copylist(1:numcopies)), minval(qclist(1:numqc)))
if (ival < 0) then
   write(string1, '(A,I8,A)') 'index list value, ', ival, ' must be >= 0'
   call error_handler(E_ERR, 'copy_partial_obs:', string1, source)
endif
ival = maxval(copylist(1:numcopies))
if (ival > size(obs2%values)) then
   write(string1, '(A,I8,A,I8)') 'index list value, ', ival, &
      ' is larger than copies length, ', size(obs2%values)
   call error_handler(E_ERR, 'copy_partial_obs:', string1, source)
endif
ival = maxval(qclist(1:numqc))
if (ival > size(obs2%qc)) then
   write(string1, '(A,I8,A,I8)') 'index list value, ', ival, &
      ' is larger than qc length, ', size(obs2%qc)
   call error_handler(E_ERR, 'copy_partial_obs:', string1, source)
endif

obs1%key = obs2%key
call copy_obs_def(obs1%def, obs2%def)

if (allocated(obs1%values)) then
   if (size(obs1%values) /= numcopies) then
      deallocate(obs1%values)
      allocate(obs1%values(numcopies))
   endif
else
   allocate(obs1%values(numcopies))
endif

if (allocated(obs1%qc)) then
   if (size(obs1%qc) /= numqc) then
      deallocate(obs1%qc)
      allocate(obs1%qc(numqc))
   endif
else
   allocate(obs1%qc(numqc))
endif

do i = 1, numcopies
   if (copylist(i) == 0) then
       obs1%values(i) = MISSING_R8
   else
       obs1%values(i) = obs2%values(copylist(i))
   endif
enddo
do i = 1, numqc
   if (qclist(i) == 0) then
      obs1%qc(i) = 0.0_r8
   else
      obs1%qc(i) = obs2%qc(qclist(i))
   endif
enddo

obs1%prev_time = obs2%prev_time
obs1%next_time = obs2%next_time
obs1%cov_group = obs2%cov_group

end subroutine copy_partial_obs
#endif

!-------------------------------------------------
subroutine get_obs_def(obs, obs_def)

type(obs_type),     intent(in)  :: obs
type(obs_def_type), intent(out) :: obs_def

! WARNING: NEED TO DEFINE A COPY ROUTINE FOR OBS_DEF !!!
call copy_obs_def(obs_def, obs%def)

end subroutine get_obs_def

!-------------------------------------------------
subroutine set_obs_def(obs, obs_def)

type(obs_type),     intent(inout) :: obs
type(obs_def_type), intent(in)    :: obs_def

call copy_obs_def(obs%def, obs_def)

end subroutine set_obs_def

!-------------------------------------------------

subroutine get_obs_values(obs, values, copy_indx, spill)

type(obs_type),    intent(in)  :: obs
real(r8),          intent(out) :: values(:)
integer, optional, intent(in)  :: copy_indx
type(dobs_type),   intent(in), optional  :: spill

if (size(values) <= 0) return

if (present(copy_indx)) then
   if (copy_indx == 1) then
      values(1) = obs%obsvalue
   else if (present(spill)) then
      values(1) = spill%xvalues(copy_indx)
   else ! abort
      !values(1) = missing_r8
      call error_handler(E_ERR, 'get_obs_values', 'With copy_idx, no access to spill%xvalues(2:) as spill was not present', source, lineno=__LINE__)
   endif
else
   values(1) = obs%obsvalue
   if (size(values) > 1) then
      if (present(spill)) then
         values(2:) = spill%xvalues
      else ! abort
         ! values(2:) = missing_r8
         call error_handler(E_ERR, 'get_obs_values', 'No access to spill%xvalues(2:) as spill was not present', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine get_obs_values

!-------------------------------------------------

subroutine set_obs_values(obs, values, copy_indx, spill)

type(obs_type),    intent(inout) :: obs
real(r8),          intent(in)    :: values(:)
integer, optional, intent(in)    :: copy_indx
type(dobs_type),   intent(inout), optional :: spill

if (size(values) <= 0) return

if(present(copy_indx)) then
   if (copy_indx == 1) then
      obs%obsvalue = values(1)
   else if (present(spill)) then
      spill%xvalues(copy_indx) = values(1)
   else ! abort
      call error_handler(E_ERR, 'set_obs_values', 'With copy_idx, no access to spill%xvalues(2:) as spill was not present', source, lineno=__LINE__)
   endif
else
   obs%obsvalue = values(1)
   if (size(values) > 1) then
      if (present(spill)) then
         spill%xvalues = values(2:)
      else ! abort
         call error_handler(E_ERR, 'set_obs_values', 'No access to spill%xvalues(2:) as spill was not present', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine set_obs_values

!-------------------------------------------------

subroutine replace_obs_values(seq, key, values, copy_indx)

type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: key
real(r8),                intent(in)    :: values(:)
integer, optional,       intent(in)    :: copy_indx

if (size(values) <= 0) return

if (present(copy_indx)) then
   if (copy_indx == 1) then
      seq%obs(key)%obsvalue = values(1)
   else if (associated(seq%spill)) then
      seq%spill(key)%xvalues(copy_indx) = values(1)
   else ! abort
      call error_handler(E_ERR, 'replace_obs_values', 'With copy_idx, seq%spill was not allocated', source, lineno=__LINE__)
   endif
else
   seq%obs(key)%obsvalue = values(1)
   if (size(values) > 1) then
      if (associated(seq%spill)) then
         seq%spill(key)%xvalues = values(2:)
      else ! abort
         call error_handler(E_ERR, 'replace_obs_values', 'With size(values) > 1, seq%spill must be allocated', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine replace_obs_values

!-------------------------------------------------
subroutine get_qc(obs, qc, qc_indx, spill)

type(obs_type),    intent(in)  :: obs
real(r8),          intent(out) :: qc(:)
integer, optional, intent(in)  :: qc_indx
type(dobs_type),    intent(in), optional :: spill

if (size(qc) <= 0) return

if (present(qc_indx)) then
   if (qc_indx == 1) then
      qc(1) = obs%dataqc
   else if (present(spill)) then
      qc(1) = spill%xqc(qc_indx)
   else ! abort
      !qc(1) = zero
      call error_handler(E_ERR, 'get_qc', 'With qc_idx, no access to spill%xqc(2:) as spill was not present', source, lineno=__LINE__)
   endif
else
   qc(1) = obs%dataqc
   if (size(qc) > 1) then
      if (present(spill)) then
         qc(2:) = spill%xqc
      else ! abort
         ! xqc(2:) = missing_r8
         call error_handler(E_ERR, 'get_obs', 'No access to spill%xqc(2:) as spill was not present', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine get_qc

!-------------------------------------------------
subroutine set_qc(obs, qc, qc_indx, spill)

type(obs_type),    intent(inout) :: obs
real(r8),          intent(in)    :: qc(:)
integer, optional, intent(in)    :: qc_indx
type(dobs_type),    intent(inout), optional :: spill

if (size(qc) <= 0) return

if (present(qc_indx)) then
   if (qc_indx == 1) then
      obs%dataqc = qc(1)
   else if (present(spill)) then
      spill%xqc(qc_indx) = qc(1)
   else ! abort
      !qc(1) = zero
      call error_handler(E_ERR, 'set_qc', 'With qc_idx, no access to spill%xqc(2:) as spill was not present', source, lineno=__LINE__)
   endif
else
   obs%dataqc = qc(1)
   if (size(qc) > 1) then
      if (present(spill)) then
         spill%xqc = qc(2:)
      else ! abort
         call error_handler(E_ERR, 'get_obs', 'No access to spill%xqc(2:) as spill was not present', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine set_qc

!-------------------------------------------------

subroutine replace_qc(seq, key, qc, qc_indx)

type(obs_sequence_type), intent(inout) :: seq
integer,                 intent(in)    :: key
real(r8),                intent(in)    :: qc(:)
integer, optional,       intent(in)    :: qc_indx

if (size(qc) <= 0) return

if (present(qc_indx)) then
   if (qc_indx == 1) then
      seq%obs(key)%obsvalue = qc(1)
   else if (associated(seq%spill)) then
      seq%spill(key)%xqc(qc_indx) = qc(1)
   else ! abort
      call error_handler(E_ERR, 'replace_qc', 'With copy_idx, seq%spill was not allocated', source, lineno=__LINE__)
   endif
else
   seq%obs(key)%obsvalue = qc(1)
   if (size(qc) > 1) then
      if (associated(seq%spill)) then
         seq%spill(key)%xqc = qc(2:)
      else ! abort
         call error_handler(E_ERR, 'replace_qc', 'With size(qc) > 1, seq%spill must be allocated', source, lineno=__LINE__)
      endif
   endif
endif

end subroutine replace_qc

!-------------------------------------------------------------
function get_obs_key(obs)

type(obs_type), intent(in) :: obs
integer                    :: get_obs_key

get_obs_key = obs%key

end function get_obs_key

!-------------------------------------------------

subroutine write_obs(seq, key, file_id, num_copies, num_qc)

! Write out an observation to file, inefficient

type(obs_sequence_type), intent(in) :: seq
integer,        intent(in) :: key,file_id, num_copies, num_qc

integer :: i

do i = 1, num_copies
   if(write_binary_obs_sequence) then
      if (i == 1) then
         write(file_id) seq%obs(key)%obsvalue
      else
         write(file_id) seq%spill(key)%xvalues(i)
      endif
   else
      if (i == 1) then
         write(file_id, *) seq%obs(key)%obsvalue
      else
         write(file_id, *) seq%spill(key)%xvalues(i)
      endif
   endif
end do

do i = 1, num_qc
   if(write_binary_obs_sequence) then
      if (i == 1) then
         write(file_id) seq%obs(key)%dataqc
      else
         write(file_id) seq%spill(key)%xqc(i)
      endif
   else
      if (i == 1) then
         write(file_id, *) seq%obs(key)%dataqc
      else
         write(file_id, *) seq%spill(key)%xqc(i)
      endif
   endif
end do

if(write_binary_obs_sequence) then
   write(file_id) seq%obs(key)%prev_time, seq%obs(key)%next_time, seq%obs(key)%cov_group
   call write_obs_def(file_id, seq%obs(key)%def, seq%obs(key)%key, 'unformatted')
else
   write(file_id, *) seq%obs(key)%prev_time, seq%obs(key)%next_time, seq%obs(key)%cov_group
   call write_obs_def(file_id, seq%obs(key)%def, seq%obs(key)%key)
endif

end subroutine write_obs

!-------------------------------------------------

subroutine read_obs(file_id, num_copies, add_copies, num_qc, add_qc, seq, &
                    key, read_format, max_obs)

! Read in observation from file, watch for allocation of storage
! This RELIES on the fact that obs%values(1) is ALWAYS the observation value
! (as opposed to the prior or mean or ...)
!
! Are the checks for num_copies == 0 or <0 necessary? 
! Yes, they happen in create_fixed_network_sequence

integer,            intent(in)    :: file_id, num_copies, add_copies
integer,            intent(in)    :: num_qc, add_qc, key
character(len=*),   intent(in)    :: read_format
type(obs_sequence_type), intent(inout) :: seq
integer, optional,  intent(in)    :: max_obs

integer  :: i, io
real(r8) :: temp_val

!if (key == 1) write(0,*) 'read_obs: key,num_copies,add_copies,num_qc,add_qc=',key,num_copies,add_copies,num_qc,add_qc

! Read in values and qc
if(num_copies > 0) then
   if(read_format == 'unformatted') then
      do i = 1, num_copies
         if (i == 1) then
            read(file_id, iostat=io) seq%obs(key)%obsvalue
         else
            read(file_id, iostat=io) seq%spill(key)%xvalues(i)
         endif
         if (io /= 0) then
            ! Read error of some type
            write(string1, *) 'Read error in obs values, obs ', i, ' rc= ', io
            call error_handler(E_ERR, 'read_obs', string1, source)
         endif
      end do
   else
      if (num_copies == 1) then
         read(file_id, *, iostat=io) seq%obs(key)%obsvalue
      else
         read(file_id, *, iostat=io) seq%obs(key)%obsvalue,seq%spill(key)%xvalues(2:num_copies)
      endif
      if (io /= 0) then
         ! Read error of some type
         write(string1, *) 'Read error in obs values, rc= ', io
         call error_handler(E_ERR, 'read_obs', string1, source)
      endif
   endif
endif

if(num_qc > 0) then
   if(read_format == 'unformatted') then
      do i = 1, num_qc
         if (i == 1) then
            read(file_id, iostat=io) seq%obs(key)%dataqc
         else
            read(file_id, iostat=io) seq%spill(key)%xqc(i)
         endif
         if (io /= 0) then
            ! Read error of some type
            write(string1, *) 'Read error in qc values, obs ', i, ' rc= ', io
            call error_handler(E_ERR, 'read_obs', string1, source)
         endif
      end do
   else
      if (num_qc == 1) then
         read(file_id, *, iostat=io) seq%obs(key)%dataqc
      else
         read(file_id, *, iostat=io) seq%obs(key)%dataqc,seq%spill(key)%xqc(2:num_qc)
      endif
      if (io /= 0) then
         ! Read error of some type
         write(string1, *) 'Read error in qc values, rc= ', io
         call error_handler(E_ERR, 'read_obs', string1, source)
      endif
   endif
endif

! Need to pass the value if available
if(num_copies > 0) then
   temp_val = seq%obs(key)%obsvalue
else
   temp_val = missing_r8
endif 

! Read in linked list pointers and error check
if(read_format == 'unformatted') then
   read(file_id, iostat=io) seq%obs(key)%prev_time, seq%obs(key)%next_time, seq%obs(key)%cov_group
else
   read(file_id, *, iostat=io) seq%obs(key)%prev_time, seq%obs(key)%next_time, seq%obs(key)%cov_group
endif
if (io /= 0) then
   ! Read error of some type
   write(string1, *) 'Read error in linked list or cov grp, rc= ', io
   call error_handler(E_ERR, 'read_obs', string1, source)
endif

! if max_obs specified, do additional error checking
if (present(max_obs)) then
   ! -1 is ok; used for first and last entries.
   if (seq%obs(key)%prev_time < -1 .or. seq%obs(key)%prev_time > max_obs) then
      write(string1, *) 'Bad value for previous obs, ', seq%obs(key)%prev_time, ', in obs ', key 
      call error_handler(E_ERR, 'read_obs', string1, source)
   endif
   if (seq%obs(key)%next_time < -1 .or. seq%obs(key)%next_time > max_obs) then
      write(string1, *) 'Bad value for next obs, ', seq%obs(key)%next_time, ', in obs ', key
      call error_handler(E_ERR, 'read_obs', string1, source)
   endif
endif

! Get model-dependent values
if(read_format == 'unformatted') then
   call read_obs_def(file_id, seq%obs(key)%def, key, temp_val, 'unformatted')
else
   call read_obs_def(file_id, seq%obs(key)%def, key, temp_val)
endif

! Copy the temp_val back to seq%obs(key)%values(1) if there are copies of data
if(num_copies > 0) seq%obs(key)%obsvalue = temp_val

end subroutine read_obs

!------------------------------------------------------------------------------

#if 0
! not used
subroutine interactive_obs(num_copies, num_qc, obs, key)

integer,        intent(in)    :: num_copies, num_qc, key
type(obs_type), intent(inout) :: obs

integer :: i

! Does interactive initialization of an observation type

call interactive_obs_def(obs%def, key)
do i = 1, num_copies
   write(*, *) 'Enter value ', i, 'for this observation'
   read(*, *) obs%values(i)
end do

do i = 1, num_qc
   write(*, *) 'Enter quality control value ', i, 'for this observation'
   read(*, *) obs%qc(i)
end do

! WHAT ABOUT THE COVARIANCE GROUPING???

end subroutine interactive_obs
#endif

!---------------------------------------------------------

function get_num_times(seq)

! Returns number of different times for observations in sequence
! Could also be computed as sequence is built?

type(obs_sequence_type), intent(in) :: seq
integer                             :: get_num_times

integer :: next
type(obs_def_type) :: obs_def
type(time_type) :: this_time, prev_time

! Just loop through the time sorted sequence and look for different times
get_num_times = 0
next = seq%first_time

do while (next /= -1)
   call get_obs_def(seq%obs(next), obs_def)
   this_time = get_obs_def_time(obs_def)
   if(get_num_times == 0) then
      get_num_times = 1
   else if(this_time /= prev_time) then
      get_num_times = get_num_times + 1
   endif
   prev_time = this_time
   next = seq%obs(next)%next_time
end do

end function get_num_times

!---------------------------------------------------------

function get_num_key_range(seq, key1, key2)

! Returns number of observations between the two given keys

type(obs_sequence_type), intent(in) :: seq
integer, optional,       intent(in) :: key1, key2
integer                             :: get_num_key_range

integer :: next, last


if (present(key1)) then
   if (key1 < seq%first_time .or. key1 > seq%last_time) then
      write(string1, *) 'Bad value for key1, must be between ', &
                            seq%first_time, ' and ', seq%last_time
      call error_handler(E_ERR, 'get_num_key_range', string1, source)
   endif
   next = key1
else
   next = seq%first_time
endif
if (present(key2)) then
   if (key2 < seq%first_time .or. key2 > seq%last_time) then
      write(string1, *) 'Bad value for key2, must be between ', &
                            seq%first_time, ' and ', seq%last_time
      call error_handler(E_ERR, 'get_num_key_range', string1, source)
   endif
   last = key2
else
   last = seq%last_time
endif

! count them up
get_num_key_range = 0
do while (next /= -1)
   get_num_key_range = get_num_key_range + 1
   if (next == last) exit
   next = seq%obs(next)%next_time
end do

end function get_num_key_range


!---------------------------------------------------------
! you can get more info by running the obs_diag program, but this
! prints out a quick table of obs types and counts, overall start and
! stop times, and metadata strings and counts.

subroutine print_obs_seq_summary(seq_in, filename)

type(obs_sequence_type),    intent(in) :: seq_in
character(len=*), optional, intent(in) :: filename

type(obs_type)     :: obs
type(obs_type)     :: next_obs
type(obs_def_type) :: this_obs_def
logical            :: is_there_one
logical            :: is_this_last
integer            :: size_seq_in
integer            :: i
integer            :: this_obs_kind
integer            :: identity_count

! max_defined_types_of_obs is a public from obs_kind_mod.f90 and really is
! counting the max number of types, not kinds
integer            :: type_count(max_defined_types_of_obs)

! Initialize input obs_types
do i = 1, max_defined_types_of_obs
   type_count(i) = 0
enddo
identity_count = 0

! make sure there are obs left to process before going on.
! num_obs should be ok since we just constructed this seq so it should
! have no unlinked obs.  if it might for some reason, use this instead:
! size_seq_in = get_num_key_range(seq_in)     !current size of seq_in

size_seq_in = get_num_obs(seq_in)
if (size_seq_in == 0) then
   if (present(filename)) then
      string1 = 'observation sequence file "'//trim(filename)//'" is empty'
   else
      string1 = 'observation sequence is empty'
   endif
   call error_handler(E_MSG,'print_obs_seq_summary',string1)
   return
endif

! Initialize individual observation variables 
call init_obs(     obs, get_num_copies(seq_in), get_num_qc(seq_in))
call init_obs(next_obs, get_num_copies(seq_in), get_num_qc(seq_in))

! blank line
call error_handler(E_MSG,'',' ')

if (present(filename)) then
   write(string1,*) 'Processing observation sequence file "'//trim(filename)//'"'
   call error_handler(E_MSG,'',string1)
endif

call print_sequence_metadata(seq_in, filename)

!-------------------------------------------------------------
! Start to process obs from seq_in
!--------------------------------------------------------------
is_there_one = get_first_obs(seq_in, obs)

if ( .not. is_there_one )  then
   write(string1,*)'no first observation'
   call error_handler(E_MSG,'obs_loop', string1)
endif

! process it here
is_this_last = .false.

call get_obs_def(obs, this_obs_def)
call print_time(get_obs_def_time(this_obs_def), ' First timestamp: ')
call print_date(get_obs_def_time(this_obs_def), '   calendar Date: ')

ObsLoop : do while ( .not. is_this_last)

   call get_obs_def(obs, this_obs_def)
   this_obs_kind = get_obs_def_type_of_obs(this_obs_def)
   if (this_obs_kind < 0) then
      identity_count = identity_count + 1
   else
      type_count(this_obs_kind) = type_count(this_obs_kind) + 1
   endif

!   print *, 'obs kind index = ', this_obs_kind
!   if(this_obs_kind > 0)print *, 'obs name = ', get_name_for_type_of_obs(this_obs_kind)

   call get_next_obs(seq_in, obs, next_obs, is_this_last)
   if (.not. is_this_last) then 
      obs = next_obs
   else
      call print_time(get_obs_def_time(this_obs_def), '  Last timestamp: ')
      call print_date(get_obs_def_time(this_obs_def), '   calendar Date: ')
   endif

enddo ObsLoop


write(string1, *) 'Number of obs processed  :          ', size_seq_in
write(string2, *) '---------------------------------------------------------'
call error_handler(E_MSG, '', string1)
call error_handler(E_MSG, '', string2)

do i = 1, max_defined_types_of_obs
   if (type_count(i) > 0) then 
      write(string1, '(a32,i8,a)') trim(get_name_for_type_of_obs(i)), &
                                     type_count(i), ' obs'
      call error_handler(E_MSG, '', string1)
   endif
enddo
if (identity_count > 0) then 
   write(string1, '(a32,i8,a)') 'Identity observations', &
                                  identity_count, ' obs'
   call error_handler(E_MSG, '', string1)
endif

! another blank line
call error_handler(E_MSG, '', ' ')

! Time to clean up

call destroy_obs(     obs)
call destroy_obs(next_obs)

end subroutine print_obs_seq_summary


!---------------------------------------------------------------------
! print out the (trimmed) metadata strings

subroutine print_sequence_metadata(seq, fname)

type(obs_sequence_type),    intent(in) :: seq
character(len=*), optional, intent(in) :: fname

integer :: num_copies , num_qc, i
character(len=metadatalength) :: str

num_copies = get_num_copies(seq)
num_qc     = get_num_qc(    seq)

if ( num_copies < 0 .or. num_qc < 0 ) then
   write(string1,*)' Illegal number of copies ', num_copies, '-OR-'
   write(string2,*)' illegal number of qc values ', num_qc, 'in observation sequence.'
   if (present(fname)) then 
      write(string3,*) 'Sequence came from file "'//trim(fname)//'"'
   else
      write(string3,*) 'Sequence came from unspecified file.'
   endif
   call error_handler(E_ERR, 'print_sequence_metadata', string1, source, &
                             text2=string2, text3=string3)
endif

MetaDataLoop : do i=1, num_copies
   str = get_copy_meta_data(seq,i)

   write(string1,*)'Data Metadata: ',trim(str)
   call error_handler(E_MSG, '', string1)

enddo MetaDataLoop

QCMetaData : do i=1, num_qc
   str = get_qc_meta_data(seq,i)

   write(string1,*)'  QC Metadata: ', trim(str)
   call error_handler(E_MSG, '', string1)

enddo QCMetaData

end subroutine print_sequence_metadata


!---------------------------------------------------------------------
! we fixed a hole in the interactive create observation sequence
! routine which would silently let you create out-of-time-order
! linked lists, which gave no errors but didn't assimilate the
! right obs at the right time when running filter.   this runs
! through the times in the entire sequence, ensuring they are
! monotonically increasing in time.  this should help catch any
! bad files which were created with older versions of code.

subroutine validate_obs_seq_time(seq, filename)

type(obs_sequence_type), intent(in) :: seq
character(len=*),        intent(in) :: filename

type(obs_type)          :: obs
type(obs_type)          :: next_obs
type(obs_def_type)      :: this_obs_def
logical                 :: is_there_one
logical                 :: is_this_last
integer                 :: size_seq
integer                 :: obs_count
integer                 :: key
type(time_type)         :: last_time
type(time_type)         :: this_time
character(len=*), parameter :: routine = 'validate_obs_seq_time'

! make sure there are obs left to process before going on.
size_seq = get_num_obs(seq) 
if (size_seq == 0) then
   string1 = 'Obs_seq file "'//trim(filename)//'" is empty.'
   call error_handler(E_MSG,routine,string1)
   return
endif

! Initialize individual observation variables 
call init_obs(     obs, get_num_copies(seq), get_num_qc(seq))
call init_obs(next_obs, get_num_copies(seq), get_num_qc(seq))

obs_count = 0

!-------------------------------------------------------------
! Start to process obs from seq
!--------------------------------------------------------------
is_there_one = get_first_obs(seq, obs)

! we already tested for 0 obs above, so there should be a first obs here.
if ( .not. is_there_one )  then
   write(string1,*)'no first obs in sequence "'//trim(filename)//'"'
   call error_handler(E_ERR, routine, string1, source)
endif

is_this_last = .false.
last_time = set_time(0, 0)
ObsLoop : do while ( .not. is_this_last)

   call get_obs_def(obs, this_obs_def)
   this_time = get_obs_def_time(this_obs_def)

   if (last_time > this_time) then
      ! bad time order of observations in linked list
      call print_time(last_time, ' previous timestamp: ')
      call print_date(last_time, '      calendar date: ')
      call print_time(this_time, '     next timestamp: ')
      call print_date(this_time, '      calendar date: ')

      key = get_obs_key(obs)
      write(string1,*)'obs number ', key, ' has earlier time than previous obs'
      write(string2,*)'observations must be in increasing time order'
      write(string3,*)' file "'//trim(filename)//'"'
      call error_handler(E_ERR, routine, string1, source, &
                         text2=string2, text3=string3)
   endif

   last_time = this_time
   obs_count = obs_count + 1

   call get_next_obs(seq, obs, next_obs, is_this_last)
   if (.not. is_this_last) obs = next_obs

enddo ObsLoop

! clean up
call destroy_obs(     obs)
call destroy_obs(next_obs)

! technically not a time validation, but easy to check.  obs_count should never
! be larger than size_seq - that's a fatal error.  obs_count < size_seq would 
! suggest there are obs in the file that aren't part of the linked list.  
! this does not necessarily indicate a fatal error but it's not a common 
! situation and might indicate someone should check on the file.

if (obs_count /= size_seq) then
   write(string1,*) 'input sequence from file "'//trim(filename)//'"'
   call error_handler(E_MSG, routine, string1)

   write(string1,*) 'total obs in file: ', size_seq, '  obs in linked list: ', obs_count

   if (obs_count > size_seq) then
      ! this is a fatal error
      write(string2,*) 'linked list obs_count > total size_seq, should not happen'
      call error_handler(E_ERR, routine, string1, source, text2=string2)
   else
      ! just warning msg
      write(string2,*) 'only observations in linked list will be processed'
      call error_handler(E_MSG, routine, string1, source, text2=string2)
   endif
endif

end subroutine validate_obs_seq_time



!-------------------------------------------------
!subroutine get_cov_group
!-------------------------------------------------
!subroutine set_cov_group ???

!=================================================


end module obs_sequence_mod

