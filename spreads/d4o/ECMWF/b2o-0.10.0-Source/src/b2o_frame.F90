module b2o_frame

use, intrinsic :: iso_c_binding

use b2o_internal

implicit none

type :: b2o_frame_t
    character(len=128), allocatable :: column_names(:)
    real(b2o_double), pointer :: data(:,:) => null() ! note: with allocatable, Cray fails on c_loc(frame%data)
    integer(b2o_int) :: width = 0
    integer(b2o_int) :: height = 0
    integer(b2o_int) :: max_height = 0
    type(b2o_frame_t), pointer :: self => null()
end type

#include "b2o_debug.h"

contains

function b2o_new_frame(c_frame) result(status) bind(c)

    type(c_ptr) :: c_frame
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame

    allocate(frame)

    frame%self => frame
    c_frame = c_loc(frame)

    status = B2O_SUCCESS

end function

function b2o_delete_frame(c_frame) result (status) bind(c)

    type(c_ptr), value :: c_frame
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame, self

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)
    call b2o_assert(associated(frame%self))

    if (associated(frame%data)) then
       deallocate(frame%data)
       nullify(frame%data)
    endif
    self => frame%self
    deallocate(self)
    nullify(frame%self)

    status = B2O_SUCCESS

end function

function b2o_frame_column_count(c_frame, count) result(status) bind(c)

    type(c_ptr), value :: c_frame
    integer(c_int), intent(out) :: count
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)
    if (allocated(frame%column_names)) then
       count = size(frame%column_names)
    else
       count = 0
    endif

    status = B2O_SUCCESS

end function

function b2o_frame_column_name(c_frame, c_index, c_name, c_name_len) result(status) bind(c)
    use b2o_string, only : foo_car_string

    type(c_ptr), value :: c_frame
    integer(c_int), value :: c_index
    character(kind=c_char, len=1), dimension(*) :: c_name
    integer(c_int), value :: c_name_len
    integer(c_int) :: status

    type(b2o_frame_t), pointer :: frame

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)
    call b2o_assert(allocated(frame%column_names))
    call b2o_assert(c_name_len > len_trim(frame%column_names(c_index+1)))
    call foo_car_string(frame%column_names(c_index+1), c_name, c_name_len)

    status = B2O_SUCCESS

end function

function b2o_frame_shape(c_frame, width, height) result(status) bind(c)

    type(c_ptr), value :: c_frame
    integer(c_long), intent(out) :: width, height
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)

    width  = frame%width
    height = frame%height

    status = B2O_SUCCESS

end function

function b2o_frame_data(c_frame, c_data, c_elem_len, c_size) result(status) bind(c)

    type(c_ptr), value :: c_frame
    type(c_ptr) :: c_data
    integer(c_int), value :: c_elem_len
    integer(c_long), intent(out) :: c_size
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)

    if (associated(frame%data)) then
       c_data = c_loc(frame%data)
       c_size = frame%width * frame%height * c_elem_len;
    else
       c_data = c_null_ptr
       c_size = 0
    endif

    status = B2O_SUCCESS

end function

function b2o_frame_clear(c_frame) result(status) bind(c)

    type(c_ptr), value :: c_frame
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame

    call b2o_assert(c_associated(c_frame))
    call c_f_pointer(c_frame, frame)

#if 0
    write(0,'(a,2L2,3(1x,i0))') 'b2o_frame_clear(): '//&
         & 'allocated(frame%column_names),associated(frame%data),width,height,max_height=',&
         &  allocated(frame%column_names),associated(frame%data),frame%width,frame%height,frame%max_height
#endif
    
    if (allocated(frame%column_names)) deallocate(frame%column_names)
    if (associated(frame%data)) then
       deallocate(frame%data)
       nullify(frame%data)
    endif
    frame%width = 0
    frame%height = 0
    frame%max_height = 0

    status = B2O_SUCCESS

end function

function b2o_frame_append(c_frame, c_other) result(status) bind(c)

    type(c_ptr), value :: c_frame, c_other
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame, other
    real(b2o_double), pointer :: new_data(:,:)
    integer(b2o_int) :: new_height

    call b2o_assert(c_associated(c_frame))
    call b2o_assert(c_associated(c_other))

    call c_f_pointer(c_frame, frame)
    call c_f_pointer(c_other, other)

    if (.not.allocated(frame%column_names)) then
        frame%column_names = other%column_names
        frame%width = other%width
    end if

    call b2o_assert(associated(other%data))

#if 0
    if (   size(frame%column_names) /= size(other%column_names) .or. &
         & frame%width /= other%width) then
       write(0,'(a,4(i0,:,1x))') 'b2o_frame_append: size(frame%column_names),size(other%column_names),frame%width,other%width=',&
            &                                       size(frame%column_names),size(other%column_names),frame%width,other%width
       write(0,'(a,4(i0,:,1x))') 'b2o_frame_append: frame%max_height,frame%height,other%height=',frame%max_height,frame%height,other%height
    endif
#endif
    
    call b2o_assert(size(frame%column_names) == size(other%column_names))
    call b2o_assert(frame%width == other%width)

    new_height = frame%height + other%height

    if (frame%max_height < new_height) then
        frame%max_height = 2 * new_height
        if (.not.associated(frame%data)) then
            allocate(frame%data(frame%width,frame%max_height))
            frame%data(:,frame%height+1:new_height) = other%data(:,1:other%height)
        else
            allocate(new_data(frame%width,frame%max_height))
            new_data(:,1:frame%height) = frame%data(:,1:frame%height)
            new_data(:,frame%height+1:new_height) = other%data(:,1:other%height)
            deallocate(frame%data)
            frame%data => new_data
        end if
    else
        call b2o_assert(associated(frame%data))
        frame%data(:,frame%height+1:new_height) = other%data(:,1:other%height)
    end if

    frame%height = new_height

    status = B2O_SUCCESS

end function

function b2o_frame_masked_append(c_frame, c_other, mask, nmask) result(status) bind(c)

    type(c_ptr), value :: c_frame, c_other
    integer(c_int), value :: nmask
    integer(c_int), intent(in) :: mask(nmask)
    integer(c_int) :: status
    type(b2o_frame_t), pointer :: frame, other
    real(b2o_double), pointer :: new_data(:,:)
    integer(b2o_int) :: new_height
    integer(b2o_int) :: nsize, j, k
    character(len=128), allocatable :: colnames(:)
    integer(b2o_int), allocatable :: jidx(:)

    call b2o_assert(c_associated(c_frame))
    call b2o_assert(c_associated(c_other))

    call c_f_pointer(c_frame, frame)
    call c_f_pointer(c_other, other)

    nsize = count(mask(:) >= 1)

    allocate(jidx(nsize))
    k = 0
    do j=1,nmask
       if (mask(j) == j) then
          k = k + 1
          jidx(k) = j
       endif
    enddo

    call b2o_assert(k == nsize)
    
    if (allocated(frame%column_names)) then
       if (size(frame%column_names) == nmask .and. nsize < nmask) then
          colnames = frame%column_names
          deallocate(frame%column_names)
          allocate(frame%column_names(nsize))
          do k=1,nsize
             frame%column_names(k) = colnames(jidx(k))
          enddo
          deallocate(colnames)
          frame%width = nsize
       endif
    endif

    call b2o_assert(nmask <= other%width)
    
    if (.not.allocated(frame%column_names)) then
       allocate(frame%column_names(nsize))
       do k=1,nsize
          frame%column_names(k) = other%column_names(jidx(k))
       enddo
       frame%width = nsize
    end if

    call b2o_assert(size(frame%column_names) <= size(other%column_names))
    call b2o_assert(frame%width <= other%width)
    call b2o_assert(nsize <= frame%width)
    call b2o_assert(associated(other%data))

    new_height = frame%height + other%height

    if (frame%max_height < new_height) then
        frame%max_height = 2 * new_height
        if (.not.associated(frame%data)) then
           frame%width = nsize
           allocate(frame%data(frame%width,frame%max_height))
           do k=1,nsize
              frame%data(k,frame%height+1:new_height) = other%data(jidx(k),1:other%height)
           enddo
        else
           frame%width = nsize
           allocate(new_data(frame%width,frame%max_height))
           new_data(:,1:frame%height) = frame%data(:,1:frame%height)
           do k=1,nsize
              new_data(k,frame%height+1:new_height) = other%data(jidx(k),1:other%height)
           enddo
           deallocate(frame%data)
           frame%data => new_data
        end if
    else
       call b2o_assert(associated(frame%data))
       frame%width = nsize
       do k=1,nsize
          frame%data(k,frame%height+1:new_height) = other%data(jidx(k),1:other%height)
       enddo
    end if

    deallocate(jidx)
    
    frame%height = new_height

    status = B2O_SUCCESS

end function

end module
