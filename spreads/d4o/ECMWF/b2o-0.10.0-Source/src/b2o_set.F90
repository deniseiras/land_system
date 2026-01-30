module b2o_set

use b2o_internal

implicit none

#include "b2o_debug.h"

private

public :: b2o_set_odb_codes

contains

subroutine b2o_set_odb_codes(handle)

    use b2o_algorithm, only : equal_range, reversed
    use b2o_option, only : B2O_ALL_SKY, ODB_CODE_MAPPINGS

    type(b2o_handle_t), intent(inout) :: handle
    type(b2o_table_t), pointer :: table
    real(b2o_double) :: bufrtype
    real(b2o_double) :: subtype
    real(b2o_double) :: codetype
    real(b2o_double) :: sensor
    real(b2o_double) :: satid
    real(b2o_double) :: satinst
    real(b2o_double) :: accumulation_length
    real(b2o_double) :: values(4)
    integer(b2o_int) :: columns(6)
    logical :: has_sat_table, mask(2)
    real(b2o_double), dimension(:,:), pointer :: hdr, sat

    real(b2o_double), allocatable, target, save :: csv_table(:,:)
    integer(b2o_int) :: rows
    character(len=256) :: message
    integer :: i, m, n, p

    integer, parameter :: csv_reportype = 1
    integer, parameter :: csv_groupid = 2
    integer, parameter :: csv_bufrtype = 3
    integer, parameter :: csv_subtype = 4
    integer, parameter :: csv_obstype = 5
    integer, parameter :: csv_codetype = 6
    integer, parameter :: csv_sensor = 7
    integer, parameter :: csv_satellite_instrument = 8
    integer, parameter :: csv_satellite_identifier = 9
    integer, parameter :: csv_accumulation_length = 10
    integer :: bounds(2)

    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_set_odb_codes"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    if (.not.allocated(csv_table)) then
        csv_table = load(ODB_CODE_MAPPINGS)
    end if

    table => b2o_table_lookup(handle%tables, "hdr", used_only=.true.)
    call b2o_assert(associated(table))

    hdr => table%data
    rows = table%rows

    table => b2o_table_lookup(handle%tables, "sat", used_only=.true.)
    has_sat_table = associated(table)

    if (has_sat_table) then
        sat => table%data
    end if

    bufrtype = b2o_get_int(handle, "dataCategory")
    subtype = b2o_get_int(handle, "dataSubCategory")

    where (hdr(1:rows,hdr_bufrtype) == ODB_MISSING_INT) hdr(1:rows,hdr_bufrtype) = bufrtype
    where (hdr(1:rows,hdr_subtype)  == ODB_MISSING_INT)  hdr(1:rows,hdr_subtype)  = subtype

    do i = 1, rows

        if (.not.all(hdr(i,[hdr_reportype,hdr_groupid]) == ODB_MISSING_INT)) cycle

        bufrtype  = hdr(i,hdr_bufrtype)
        subtype   = hdr(i,hdr_subtype)

        if (has_sat_table) then
            sensor  = hdr(i,hdr_sensor)
            satid   = sat(i,sat_satellite_identifier)
        else
            sensor  = ODB_MISSING_INT
            satid   = ODB_MISSING_INT
        end if

        if (subtype == 96) then
            m = 3
            codetype = wind_profiler_codetype(hdr(i,hdr_statid))
            columns(1:m) = [csv_bufrtype, csv_subtype, csv_codetype]
            values(1:m)  = [bufrtype, subtype, codetype]
        else if (subtype == 126) then
            m = 3
            accumulation_length = b2o_get_int(handle, "blockNumber") * 3600
            columns(1:m) = [csv_bufrtype, csv_subtype, csv_accumulation_length]
            values(1:m)  = [bufrtype, subtype, accumulation_length]
        else if (bufrtype == 5 .or. sensor == ODB_MISSING_INT) then
            m = 3
            columns(1:m) = [csv_bufrtype, csv_subtype, csv_satellite_identifier]
            values(1:m)  = [bufrtype, subtype, satid]
        else
            m = 4
            columns(1:m) = [csv_bufrtype, csv_subtype, csv_satellite_identifier, csv_sensor]
            values(1:m)  = [bufrtype, subtype, satid, sensor]
        end if

        n = equal_range(csv_table(:,columns(1:m)), values(1:m), bounds)

        if (n == 2) then
            select case (B2O_ALL_SKY)
            case (.true.)  ; mask = (csv_table(bounds,csv_obstype) == 16)
            case (.false.) ; mask = (csv_table(bounds,csv_obstype) /= 16)
            end select
            bounds = merge(bounds, reversed(bounds), mask)
            n = bounds(2) - bounds(1) + 1
        end if

!        if (n /= 1) then
!            write (message, "(a,i0,a,4(a,i0))") "Found ", n, " matches for:", &
!                & " bufrtype=", int(bufrtype), " subtype=", int(subtype), &
!                & " sensor=", int(sensor), " satid=", int(satid)
!            call b2o_log(handle, B2O_ERROR, trim(message))
!            call b2o_exit(1)
!        end if

        if (n /= 1) then
            write (message, "(a,i0,a,4(a,i0))") "Found ", n, " matches for:", &
                & " bufrtype=", int(bufrtype), " subtype=", int(subtype), &
                & " sensor=", int(sensor), " satid=", int(satid)
            call b2o_log(handle, B2O_WARNING, trim(message))
            bounds(1) = ODB_MISSING_INT
        end if

        p = bounds(1)

        if (p == ODB_MISSING_INT) then
           hdr(i,hdr_reportype) = ODB_MISSING_INT
           hdr(i,hdr_groupid)   = ODB_MISSING_INT
           hdr(i,hdr_obstype)   = ODB_MISSING_INT
           hdr(i,hdr_codetype)  = ODB_MISSING_INT
        else
           hdr(i,hdr_reportype) = csv_table(p,csv_reportype)
           hdr(i,hdr_groupid)   = csv_table(p,csv_groupid)
           hdr(i,hdr_obstype)   = csv_table(p,csv_obstype)
           hdr(i,hdr_codetype)  = csv_table(p,csv_codetype)
           
           if (has_sat_table) then
              if (sat(i,sat_satellite_instrument) == ODB_MISSING_INT) then
                 sat(i,sat_satellite_instrument) = csv_table(p,csv_satellite_instrument)
              end if
           end if
        endif

    end do

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

contains

function load(file) result(csv_table)

    use b2o_algorithm, only : order_by
    use b2o_utility,   only : b2o_read_csv

    character(len=*), intent(in) :: file
    real(b2o_double), allocatable :: csv_table(:,:)
    character(len=36), allocatable :: table(:,:)
    integer :: i, j, m, n, code

    call b2o_log(handle%context, B2O_INFO, "Loading ODB code mappings from: " // trim(file))

    call b2o_read_csv(file, table, skip_rows=[1])

    if (size(table) == 0) then
        call b2o_log(handle%context, B2O_ERROR, "Could not load ODB code mappings from: " // trim(file))
        call b2o_exit(1)
    end if

    m = size(table, 1)
    n = size(table, 2)

    allocate(csv_table(m, n))

    do j = 1, n
        do i = 1, m
            if (len_trim(table(i,j)) == 0) then
                csv_table(i,j) = -1
            else
                read (table(i,j), "(i10)") code
                csv_table(i,j) = real(code, kind=b2o_double)
            end if
        end do
    end do

    where (csv_table == -1)
        csv_table = ODB_MISSING_INT
    end where

    columns(1:4) = [csv_bufrtype, csv_subtype, csv_satellite_identifier, csv_sensor]
    columns(5:6) = [csv_codetype, csv_accumulation_length]

    call order_by(csv_table, columns(1:6))

end function

function wind_profiler_codetype(statid) result(codetype)

    real(b2o_double), intent(in) :: statid
    real(b2o_double) :: codetype
    character(len=8) :: string
    integer :: number, wmo_block

    string = transfer(statid, string)
    read (string, "(i5)") number
    wmo_block = number / 1000

    select case (wmo_block)
    case (72,74,70) ; codetype = 34  ! American
    case (47)       ; codetype = 131 ! Japanese
    case default    ; codetype = 134 ! European
    end select

end function

end subroutine b2o_set_odb_codes

end module
