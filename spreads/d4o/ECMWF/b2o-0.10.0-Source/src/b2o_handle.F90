module b2o_handle

use b2o_accessor
use b2o_common
use b2o_context
use b2o_schema, only : create_all_tables
use b2o_table

implicit none

#include "b2o_debug.h"

type b2o_handle_t
    integer(b2o_int) :: bufr_id

    integer(b2o_int) :: subtype
    integer(b2o_int) :: reports   ! number of reports (usually equal to subsets)
    integer(b2o_int), dimension(:), pointer :: entries => null()
    integer(b2o_int) :: subset_number = 0

    type(b2o_context_t), pointer :: context => null()
    type(b2o_table_t), pointer :: tables => null()
    class(b2o_accessor_t), allocatable :: accessor

    logical :: new_columns = .true.

    type(b2o_handle_t), pointer :: self => null()
end type

interface b2o_reserve
    module procedure b2o_reserve_regular
    module procedure b2o_reserve_irregular
end interface

interface b2o_log
    module procedure b2o_log_via_handle
end interface

contains

subroutine b2o_log_via_handle(handle, level, text)

    use b2o_option, only : B2O_LOG_LEVEL

    type(b2o_handle_t), intent(in) :: handle
    integer(b2o_int), intent(in) :: level
    character(*), intent(in) :: text
    type(b2o_context_t), pointer :: context
    character(512) :: extended_text

    context => handle%context

    if (level < B2O_LOG_LEVEL) then
        return
    end if

    if (context%message_number > 0) then
        write(extended_text, "(a,' [file=',a,' count=',i0,' subtype=',i0,']')") &
           & trim(text), trim(context%message_source), context%message_number, context%message_subtype
        call b2o_log(context, level, extended_text)
    else
        call b2o_log(context, level, text)
    end if

end subroutine

subroutine b2o_new_converter(c_handle) bind(c)

    use, intrinsic :: iso_c_binding

    type(c_ptr) :: c_handle
    type(b2o_handle_t), pointer :: handle
    type(b2o_context_t), pointer :: context
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_new_converter"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    context => b2o_get_default_context()
    allocate(handle)

    call b2o_converter_initialize(context, handle)

    handle%self => handle
    c_handle = c_loc(handle)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_converter_initialize(context, handle)

    type(b2o_context_t), intent(inout), target :: context
    type(b2o_handle_t), intent(inout) :: handle
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_converter_initialize"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    handle%context => context
    handle%tables  => create_all_tables()

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_delete_converter(c_converter) bind(c)

    use, intrinsic :: iso_c_binding

    type(c_ptr), value :: c_converter
    type(b2o_handle_t), pointer :: converter, self

    call b2o_assert(c_associated(c_converter))
    call c_f_pointer(c_converter, converter)

    call b2o_converter_finalize(converter)

    call b2o_assert(associated(converter%self))
    self => converter%self
    deallocate(self)

end subroutine

subroutine b2o_converter_finalize(handle)

    type(b2o_handle_t), intent(inout) :: handle
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_converter_finalize"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_table_finalize(handle%tables)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_reserve_regular(handle, entries_per_report, reports)

    type(b2o_handle_t), intent(inout) :: handle
    integer(b2o_int), intent(in) :: entries_per_report
    integer(b2o_int), intent(in), optional :: reports
    integer(b2o_int) :: n
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_reserve_regular"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_assert(entries_per_report > 0)

    n = handle%reports

    if (present(reports)) then
        n = reports ! override number of reports (e.g. in case of thinning)
    end if

    call b2o_reserve_irregular(handle, spread(entries_per_report, 1, n))

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine b2o_reserve_irregular(handle, entries)

    type(b2o_handle_t), intent(inout) :: handle
    integer(b2o_int), intent(in) :: entries(:)
    type(b2o_table_t), pointer :: table
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_reserve_irregular"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_assert(size(entries) > 0)
    call b2o_assert(all(entries > 0))

    table => handle%tables
    do while (associated(table))
        table%is_used = .false.
        table => table%next
    end do

    handle%reports = size(entries)

    if (associated(handle%entries)) then
        if (size(handle%entries) < handle%reports) then
            deallocate(handle%entries)
            allocate(handle%entries(handle%reports))
        end if
    else
        allocate(handle%entries(handle%reports))
    end if

    handle%entries(1:handle%reports) = entries(:)

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

function b2o_use_table(handle, name, table_ptr) result(data)

    type(b2o_handle_t), intent(in) :: handle
    character(len=*), intent(in) :: name
    type(b2o_table_t), pointer, optional :: table_ptr
    real(b2o_double), dimension(:,:), pointer :: data
    type(b2o_table_t), pointer :: table
    integer(b2o_int) :: rows
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_use_table"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)
    
    table => b2o_table_lookup(handle%tables, name)
    if (.not.associated(table)) then
        call b2o_log(handle%context, B2O_ERROR, "Table not found: " // trim(name))
        call b2o_exit(B2O_INTERNAL_ERROR)
    end if

    select case (table%kind)
    case (B2O_KIND_HEADER)
        rows = handle%reports
    case (B2O_KIND_BODY)
        rows = sum(handle%entries(1:handle%reports))
    case default
        call b2o_log(handle%context, B2O_ERROR, "Unsupported table: " // trim(name))
        call b2o_exit(B2O_INTERNAL_ERROR)
    end select

    call b2o_table_resize(table, rows)

    data => table%data(1:table%rows,1:table%columns)
    table%is_used = .true.
    if (present(table_ptr)) table_ptr => table

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end function

function b2o_next_subset(handle) result(has_next)

    type(b2o_handle_t), intent(inout) :: handle
    logical :: has_next
    integer(b2o_int) :: subsets
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_next_subset"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call codes_get(handle%bufr_id, "numberOfSubsets", subsets)

    has_next = (handle%subset_number + 1 <= subsets)

    if (has_next) then
        handle%subset_number = handle%subset_number + 1
    end if

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end function

subroutine b2o_handle_shrink(handle, n_reports)

    type(b2o_handle_t), intent(inout) :: handle
    integer(b2o_int), intent(in) :: n_reports
    type(b2o_table_t), pointer :: table
    integer(b2o_int) :: total_entries
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_handle_shrink"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    call b2o_assert(n_reports <= handle%reports)

    handle%reports = n_reports
    total_entries = sum(handle%entries(1:handle%reports))

    table => handle%tables
    do while (associated(table))
        if (table%is_used) then
            select case (table%kind)
            case (B2O_KIND_HEADER) ; table%rows = handle%reports
            case (B2O_KIND_BODY)   ; table%rows = total_entries
            end select
        end if
        table => table%next
    end do

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

function b2o_pack(handle, mask) result(rows)

    type(b2o_handle_t), intent(inout) :: handle
    logical, intent(in) :: mask(:)
    integer(b2o_int) :: rows, j
    type(b2o_table_t), pointer :: table

    ! At the momment, this function only makes sense for single reports.
    call b2o_assert(handle%reports == 1)
    call b2o_assert(size(mask) == handle%entries(1))

    if (all(mask)) then
        rows = size(mask)
        return
    end if

    rows = count(mask)

    table => handle%tables
    do while (associated(table))
        if (table%is_used .and. table%kind == B2O_KIND_BODY) then
            call b2o_table_pack(table, mask, rows)
        end if
        table => table%next
    end do

    handle%entries(1) = rows

end function

function b2o_pack_reports(handle, report_mask) result(report_count)

    type(b2o_handle_t), intent(inout) :: handle
    logical, intent(in) :: report_mask(:)
    logical, allocatable :: entry_mask(:)
    integer(b2o_int) :: report_count, entry_count, i, lo, hi
    type(b2o_table_t), pointer :: table

    call b2o_assert(size(report_mask) == handle%reports)

    if (all(report_mask)) then
        report_count = handle%reports
        return
    end if

    allocate(entry_mask(sum(handle%entries(1:handle%reports))))

    lo = 1
    do i = 1, handle%reports
        hi = lo + handle%entries(i) - 1
        entry_mask(lo:hi) = report_mask(i)
        lo = hi + 1
    end do

    report_count = count(report_mask)
    entry_count = count(entry_mask)

    table => handle%tables
    do while (associated(table))
        if (table%is_used) then
            select case (table%kind)
            case (B2O_KIND_HEADER) ; call b2o_table_pack(table, report_mask, report_count)
            case (B2O_KIND_BODY)   ; call b2o_table_pack(table, entry_mask, entry_count)
            end select
        end if
        table => table%next
    end do

    handle%entries(1:report_count) = pack(handle%entries(1:handle%reports), report_mask)
    handle%reports = report_count

end function

end module
