module b2o_algorithm

use b2o_common

implicit none

#include "b2o_debug.h"

private

public :: order_by
public :: sort
public :: binary_search
public :: select
public :: equal_range
public :: lower_bound
public :: upper_bound
public :: swap
public :: less_than
public :: string_less_than
public :: reversed

interface equal_range
    module procedure equal_range_1d
    module procedure equal_range_2d
end interface

interface

logical pure function binary_predicate(a, b)
    use b2o_common
    real(b2o_double), intent(in) :: a, b
end function

end interface

contains

subroutine order_by(table, key, compare)

    real(b2o_double), intent(inout) :: table(:,:)
    integer, intent(in) :: key(:)
    procedure(binary_predicate), optional :: compare
    integer :: indices(size(table, 1))
    real(b2o_double) :: A(size(table, 1))
    integer :: i, j, n, lo, hi

    indices = [(i, i = 1, size(indices))]

    do j = size(key), 1, -1
        A(:) = table(indices,key(j))
        call sort(A, indices, compare)
    end do

    do j = 1, size(table, 2)
        table(:,j) = table(indices,j)
    end do

end subroutine

subroutine sort(A, D, compare)

    real(b2o_double), intent(inout) :: A(:)
    integer, intent(inout) :: D(size(A))
    procedure(binary_predicate), optional :: compare
    procedure(binary_predicate), pointer  :: c

    if (present(compare)) then
        c => compare
    else
        c => less_than
    end if

    if (.not.is_sorted(A, c)) then
        call merge_sort(A, D, 1, size(A), c)
    end if

end subroutine

logical pure function is_sorted(A, compare)

    real(b2o_double), intent(in) :: A(:)
    procedure(binary_predicate) :: compare
    integer :: i

    is_sorted = .true.
    do i = 1, size(A) - 1
        if (compare(A(i+1), A(i))) then
            is_sorted = .false.
            exit
        end if
    end do

end function

recursive subroutine merge_sort(A, D, lo, hi, compare)

    real(b2o_double), intent(inout) :: A(:)
    integer, intent(inout) :: D(size(A))
    integer, intent(in) :: lo, hi
    procedure(binary_predicate) :: compare
    integer :: mi

    if (lo < hi) then
        if ((hi - lo) < 16) then
            call insertion_sort(A, D, lo, hi, compare)
        else
            mi = (lo + hi) / 2
            call merge_sort(A, D, lo, mi, compare)
            call merge_sort(A, D, mi + 1, hi, compare)
            call merge(lo, mi, hi)
        end if
    end if

contains

subroutine merge(lo, mi, hi)

    integer, intent(in) :: lo, mi, hi
    real(b2o_double) :: L(mi-lo+1,2), R(hi-mi,2)
    integer :: i, j, k

    i = 1
    j = 1
    k = lo

    L(:,1) = A(lo:mi)
    L(:,2) = D(lo:mi)
    R(:,1) = A(mi+1:hi)
    R(:,2) = D(mi+1:hi)

    do while (i <= size(L,1) .and. j <= size(R,1))
        if (compare(L(i,1), R(j,1)) .or. L(i,1) == R(j,1)) then
            A(k) = L(i,1)
            D(k) = L(i,2)
            i = i + 1
        else
            A(k) = R(j,1)
            D(k) = R(j,2)
            j = j + 1
        end if
        k = k + 1
    end do

    do while (i <= size(L,1))
        A(k) = L(i,1)
        D(k) = L(i,2)
        i = i + 1
        k = k + 1
    end do

    do while (j <= size(R,1))
        A(k) = R(j,1)
        D(k) = R(j,2)
        j = j + 1
        k = k + 1
    end do

end subroutine

end subroutine merge_sort

subroutine insertion_sort(A, B, lo, hi, compare)

    real(b2o_double), intent(inout) :: A(:)
    integer, intent(inout) :: B(size(A))
    integer, intent(in) :: lo, hi
    procedure(binary_predicate) :: compare
    real(b2o_double) :: Ai
    integer :: i, j, Bi

    do i = lo + 1, hi
        Ai = A(i)
        Bi = B(i)
        j = i - 1
        do while (j >= lo)
            if (compare(Ai, A(j))) then
                A(j+1) = A(j)
                B(j+1) = B(j)
            else
                exit
            end if
            j = j - 1
        end do
        A(j+1) = Ai
        B(j+1) = Bi
    end do

end subroutine

function binary_search(A, v, compare) result(p)

    real(b2o_double), intent(in) :: A(:), v
    procedure(binary_predicate) :: compare
    integer :: p

    p = lower_bound(A, v, compare)

    if (p > size(A)) then
        p = -1
    else if (A(p) /= v) then
        p = -1
    end if

end function

function select(columns, from, match, against, compare, limit) result(result)

    integer(b2o_int), intent(in) :: columns(:)
    integer(b2o_int), intent(in), optional :: match(:), limit
    real(b2o_double), intent(in), optional :: from(:,:), against(:)
    procedure(binary_predicate),  optional :: compare
    real(b2o_double), allocatable :: result(:,:)
    integer :: n, bounds(2)

    call assert(present(from))
    call assert(present(match))
    call assert(present(against))
    call assert(present(compare))

    call assert(all([size(columns),size(match)] > 0))
    call assert(size(match) == size(against))

    n = equal_range(from(:,match), against, bounds, compare)

    if (n == 0) then
        allocate(result(0,size(columns)))
    else if (present(limit)) then
        call assert(limit > 0)
        result = from(bounds(1):bounds(1)+limit-1,columns)
    else
        result = from(bounds(1):bounds(2),columns)
    end if

end function

function equal_range_2d(A, V, r, compare) result(n)

    real(b2o_double), intent(in) :: A(:,:)
    real(b2o_double), intent(in) :: V(size(A, 2))
    procedure(binary_predicate), optional :: compare
    integer, intent(inout) :: r(2)
    integer :: n, m
    integer :: j, lo, hi

    n  = 0
    lo = 1
    hi = size(A, 1)

    do j = 1, size(A, 2)
        m = equal_range(A(lo:hi,j), V(j), r, compare)
        if (m == 0) return
        hi = lo + r(2) - 1
        lo = lo + r(1) - 1
    end do

    n = hi - lo + 1
    r(1:2) = [lo, hi]

end function

function equal_range_1d(A, v, r, compare) result(n)

    real(b2o_double), intent(in) :: A(:)
    real(b2o_double), intent(in) :: v
    procedure(binary_predicate), optional :: compare
    integer, intent(inout) :: r(2)
    integer :: n
    integer :: lo, hi

    n = 0

    lo = lower_bound(A, v, compare)

    if (lo > size(A)) return
    if (A(lo) /= v)   return

    hi = upper_bound(A, v, compare) - 1

    if (hi == 0)    return
    if (A(hi) /= v) return

    n = hi - lo + 1
    r(1:2) = [lo, hi]

end function

integer function lower_bound(A, v, compare)

    real(b2o_double), intent(in) :: A(:), v
    procedure(binary_predicate), optional :: compare
    procedure(binary_predicate), pointer :: c
    integer :: lo, n, p, step

    if (present(compare)) then
        c => compare
    else
        c => less_than
    end if

    lo = 1
    n = size(A)

    do while (n > 128)
        step = n / 2
        p = lo + step
        if (c(A(p), v)) then
            lo = p + 1
            n = n - step - 1
        else
            n = step
        end if
    end do

    do while (n > 0)
        if (.not.c(A(lo), v)) exit
        lo = lo + 1
        n = n - 1
    end do

    lower_bound = lo

end function

integer function upper_bound(A, v, compare)

    real(b2o_double), intent(in) :: A(:), v
    procedure(binary_predicate), optional :: compare
    procedure(binary_predicate), pointer :: c
    integer :: hi, n, p, step

    if (present(compare)) then
        c => compare
    else
        c => less_than
    end if

    hi = 1
    n = size(A)

    do while (n > 128)
        step = n / 2
        p = hi + step
        if (.not.c(v, A(p))) then
            hi = p + 1
            n = n - step - 1
        else
            n = step
        end if
    end do

    do while (n > 0)
        if (c(v, A(hi))) exit
        hi = hi + 1
        n = n - 1
    end do

   upper_bound = hi

end function

subroutine swap(a, b)

    real(b2o_double) :: a, b, t; t = a; a = b; b = t

end subroutine

logical pure function less_than(a, b)

    real(b2o_double), intent(in) :: a, b; less_than = (a < b)

end function

logical pure function string_less_than(a, b)

    real(b2o_double), intent(in) :: a, b
    character(len=8) :: string
    string_less_than = (transfer(a, string) < transfer(b, string))

end function

pure function reversed(A) result(B)

    integer, intent(in) :: A(:)
    integer :: i, n, B(size(A))

    n = size(A); forall (i = 1:n) B(n-i+1) = A(i)

end function

end module
