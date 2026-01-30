module b2o_table

use b2o_common

implicit none

#include "b2o_debug.h"

type b2o_table_t
    character(64) :: name = ""
    character(64), dimension(:), pointer :: column_names => null()
    real(b2o_double), dimension(:,:), pointer :: data => null()
    real(b2o_double), dimension(:), pointer :: default_values => null()
    integer(b2o_int) :: rows = 0
    integer(b2o_int) :: columns = 0
    integer(b2o_int) :: max_rows = 0
    integer(b2o_int) :: kind = B2O_KIND_UNKNOWN
    logical :: is_used = .false.
    type(b2o_table_t), pointer :: next => null()
end type

contains

function b2o_new_table(table_name, column_names, column_types) result(table)

    character(len=*), intent(in):: table_name
    character(len=*), dimension(:), intent(in) :: column_names
    integer(b2o_int), dimension(:), intent(in) :: column_types
    type(b2o_table_t), pointer :: table
    integer(b2o_int) :: i, n
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_new_table"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_assert(len_trim(table_name) > 0)
    call b2o_assert(size(column_names) > 0)
    call b2o_assert(size(column_names) == size(column_types))

    allocate(table)

    table%name = trim(table_name)
    table%kind = b2o_table_kind(table_name)
    table%is_used = .false.
    table%rows = 0
    table%columns = size(column_names)
    table%next => null()

    n = size(column_names)

    write(0,'(a,i0)') 'b2o_new_table('//trim(table%name)//'): # of columns=',n

    allocate(table%column_names(n))
    allocate(table%default_values(0:n))
    nullify(table%data)

    do i = 1, n
        table%column_names(i) = column_names(i)
        !write(0,'(a,i4,a)') 'b2o_new_table('//trim(table%name)//'): ',i,' = '//trim(table%column_names(i))//'@'//trim(table%name)
        select case (column_types(i))
        case (ODB_INTEGER)  ; table%default_values(i) = ODB_MISSING_INT
        case (ODB_REAL)     ; table%default_values(i) = ODB_MISSING_REAL
        case (ODB_STRING)   ; table%default_values(i) = 0
        case (ODB_BITFIELD) ; table%default_values(i) = 0
        case (ODB_DOUBLE)   ; table%default_values(i) = ODB_MISSING_REAL
        end select
        if (index(column_names(i), "LINK") == 1) then
            table%default_values(i) = 0 ! required by IFS (but only when creating ECMAs)
        end if
    end do

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end function

subroutine b2o_table_init(table)

    type(b2o_table_t), intent(inout) :: table
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_table_init"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_assert(associated(table%data))
    call b2o_assert(associated(table%default_values))

    table%data(1:table%rows,:) = spread(table%default_values(:), 1, table%rows)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_table_finalize(table_list)

    type(b2o_table_t), pointer :: table_list
    type(b2o_table_t), pointer :: table, next_table
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_table_finalize"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    table => table_list

    do while (associated(table))
        next_table => table%next
        if (associated(table%data)) deallocate(table%data)
        if (associated(table%column_names)) deallocate(table%column_names)
        if (associated(table%default_values)) deallocate(table%default_values)
        deallocate(table)
        table => next_table
    end do

    nullify(table_list)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

function b2o_table_kind(name) result(kind)

    character(len=*), intent(in) :: name
    integer(b2o_int) :: kind
    integer :: i

    kind = B2O_KIND_UNKNOWN

    do i = 1, size(ODB_HEADER_TABLES)
        if (trim(name) == trim(ODB_HEADER_TABLES(i))) then
            kind = B2O_KIND_HEADER
            return
        end if
    end do

    do i = 1, size(ODB_BODY_TABLES)
        if (trim(name) == trim(ODB_BODY_TABLES(i))) then
            kind = B2O_KIND_BODY
            return
        end if
    end do

end function

subroutine push(new_table, tables)

    type(b2o_table_t), pointer :: new_table, tables, table

    if (.not.associated(tables)) then
        tables => new_table
    else
        table => tables
        do while (associated(table%next))
            table => table%next
        end do
        table%next => new_table
    end if

end subroutine

function b2o_table_lookup(tables, name, used_only) result(table)

    type(b2o_table_t), pointer :: tables
    character(len=*), intent(in) :: name
    logical, intent(in), optional :: used_only
    type(b2o_table_t), pointer :: table
    logical :: found
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_table_lookup"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)
    
    found = .false.
    table => tables

    do while (associated(table))
        if (table%name == trim(name)) then
            if (present(used_only)) then
                if (used_only) then
                    found = table%is_used
                end if
            else
                found = .true.
            end if
            exit
        end if
        table => table%next
    end do

    if (.not.found) table => null()

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end function

subroutine b2o_table_resize(table, rows, init)

    type(b2o_table_t), intent(inout) :: table
    integer(b2o_int), intent(in) :: rows
    logical, intent(in), optional :: init
    logical :: init_
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_table_resize"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    init_ = .true.
    if (present(init)) init_ = init

    if (.not.associated(table%data)) then
        allocate(table%data(rows, 0:table%columns))
        table%rows = rows
        table%max_rows = rows
    else if (rows <= table%max_rows) then
        table%rows = rows
    else
        deallocate(table%data)
        allocate(table%data(rows, 0:table%columns))
        table%rows = rows
        table%max_rows = rows
    end if

    if (init_) then
        call b2o_table_init(table)
    end if

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_table_pack(table, mask, count_hint)

    type(b2o_table_t), intent(inout) :: table
    logical, intent(in), dimension(table%rows) :: mask
    integer(b2o_int), intent(in), optional :: count_hint
    integer(b2o_int) :: n, j

    if (present(count_hint)) then
        n = count_hint
    else
        n = count(mask)
    end if

    do j = 1, table%columns
        table%data(1:n,j) = pack(table%data(1:table%rows,j), mask)
    end do

    table%rows = n

end subroutine

end module
