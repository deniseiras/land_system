!> @author Tomas Kral
!> @date 2016

module b2o_functional

    use b2o_common, only : b2o_int, b2o_double, ODB_MISSING_REAL

    implicit none

    interface b2o_compose
        module procedure compose_filter2, compose_filter3, compose_filter4
        module procedure compose_mapcat_partition_by
    end interface

    interface b2o_partition_by
        module procedure partition_by, partial_partition_by
    end interface

    interface b2o_map
        module procedure map_doubles_to_double
        module procedure map_bools_to_int
    end interface

    interface b2o_mapcat
        module procedure mapcat, partial_mapcat
    end interface

    private

    public :: b2o_compose
    public :: b2o_count
    public :: b2o_first
    public :: b2o_last
    public :: b2o_map
    public :: b2o_mapcat
    public :: b2o_mean
    public :: b2o_partition_by

    interface

    function filter_f(array, unpacked_mask) result(mask)
        use b2o_common
        real(b2o_double), intent(in) :: array(:)
        logical, intent(in) :: unpacked_mask(:)
        logical, dimension(size(array)) :: mask
    end function

    function transform_f(x)
        use b2o_common
        real(b2o_double), intent(in) :: x
        real(b2o_double) :: transform_f
    end function

    function filter_range_f(subarray, a, b) result(submask)
        use b2o_common
        integer(b2o_int), intent(in) :: a, b
        real(b2o_double), intent(in), dimension(b-a+1) :: subarray
        logical, dimension(size(subarray)) :: submask
    end function

    function doubles_to_double(subarray, a, b) result(value)
        use b2o_common
        integer(b2o_int), intent(in) :: a, b
        real(b2o_double), intent(in), dimension(b-a+1) :: subarray
        real(b2o_double) :: value
    end function

    function bools_to_int(subarray, a, b) result(value)
        use b2o_common
        integer(b2o_int), intent(in) :: a, b
        logical, intent(in), dimension(b-a+1) :: subarray
        integer(b2o_int) :: value
    end function

    end interface

    type partial_partition_by_t
        private
        procedure(transform_f), pointer, nopass :: f => null()
    end type

    type partial_mapcat_t
        private
        procedure(filter_range_f), pointer, nopass :: f => null()
    end type

contains

function compose_filter2(g, f, array) result(composed_mask)

    procedure(filter_f) :: g, f
    real(b2o_double), intent(in) :: array(:)
    logical, dimension(size(array)) :: composed_mask

    composed_mask = bind(g, array, f(array, spread(.true., 1, size(array))))

end function

function compose_filter3(h, g, f, array) result(composed_mask)

    procedure(filter_f) :: h, g, f
    real(b2o_double), intent(in) :: array(:)
    logical, dimension(size(array)) :: composed_mask

    composed_mask = bind(h, array, compose_filter2(g, f, array))

end function

function compose_filter4(p, h, g, f, array) result(composed_mask)

    procedure(filter_f) :: p, h, g, f
    real(b2o_double), intent(in) :: array(:)
    logical, dimension(size(array)) :: composed_mask

    composed_mask = bind(p, array, compose_filter3(h, g, f, array))

end function

function bind(f, array, mask) result(unpacked_mask)

    procedure(filter_f) :: f
    real(b2o_double), intent(in) :: array(:)
    logical, intent(in), dimension(size(array)) :: mask
    logical, dimension(size(array)) :: unpacked_mask

    unpacked_mask = unpack(f(pack(array, mask), mask), mask, spread(.false., 1, size(mask)))

end function

function partition_by(f, array) result(partition_mask)

    procedure(transform_f) :: f
    real(b2o_double), intent(in) :: array(:)
    logical, dimension(size(array)) :: partition_mask
    real(b2o_double) :: last, next
    integer :: i

    if (size(array) == 0) return

    last = f(array(1))
    partition_mask(1) = .true.

    do i = 2, size(array)
        next = f(array(i))
        if (next == last) then
            partition_mask(i) = .false.
        else
            last = next
            partition_mask(i) = .true.
        end if
    end do

end function

type(partial_partition_by_t) function partial_partition_by(f)

    procedure(transform_f) :: f
    partial_partition_by%f => f

end function

function map_doubles_to_double(f, array, partition_mask) result (values)

    procedure(doubles_to_double) :: f
    real(b2o_double), intent(in) :: array(:)
    logical, intent(in), dimension(size(array)) :: partition_mask
    real(b2o_double), allocatable :: values(:)
    integer(b2o_int) :: n, a, b, i

    n = count(partition_mask)

    allocate(values(n))

    a = 1
    b = 1
    i = 1

    do while (a <= size(array))

        do while (b < size(array))
            if (partition_mask(b+1)) exit
            b = b + 1
        end do

        values(i) = f(array(a:b), a, b)

        a = b + 1
        b = a
        i = i + 1

    end do

end function

function map_bools_to_int(f, array, partition_mask) result (values)

    procedure(bools_to_int) :: f
    logical, intent(in) :: array(:)
    logical, intent(in), dimension(size(array)) :: partition_mask
    integer(b2o_int), allocatable :: values(:)
    integer(b2o_int) :: n, a, b, i

    n = count(partition_mask)

    allocate(values(n))

    a = 1
    b = 1
    i = 1

    do while (a <= size(array))

        do while (b < size(array))
            if (partition_mask(b+1)) exit
            b = b + 1
        end do

        values(i) = f(array(a:b), a, b)

        a = b + 1
        b = a
        i = i + 1

    end do

end function

function mapcat(f, array, partition_mask) result(mask)

    procedure(filter_range_f) :: f
    real(b2o_double), intent(in) :: array(:)
    logical, intent(in), dimension(size(array)) :: partition_mask
    logical, dimension(size(array)) :: mask
    integer(b2o_int) :: a, b

    a = 1
    b = 1

    do while (a <= size(array))

        do while (b < size(array))
            if (partition_mask(b+1)) exit
            b = b + 1
        end do

        mask(a:b) = f(array(a:b), a, b)

        a = b + 1
        b = a

    end do

end function

type(partial_mapcat_t) function partial_mapcat(f)

    procedure(filter_range_f) :: f
    partial_mapcat%f => f

end function

function compose_mapcat_partition_by(m, p, array) result(composed_mask)

    type(partial_mapcat_t), intent(in) :: m
    type(partial_partition_by_t), intent(in) :: p
    real(b2o_double), intent(in) :: array(:)
    logical, dimension(size(array)) :: composed_mask

    composed_mask = mapcat(m%f, array, partition_by(p%f, array))

end function

function b2o_mean(subarray, a, b)

    integer(b2o_int), intent(in) :: a, b
    real(b2o_double), intent(in), dimension(b-a+1) :: subarray
    real(b2o_double) :: b2o_mean, s
    integer(b2o_int) :: i, n

    s = 0
    n = 0

    do i = 1, size(subarray)
        if (subarray(i) == ODB_MISSING_REAL) cycle
        s = s + subarray(i)
        n = n + 1
    end do

    if (n == 0) then
        b2o_mean = ODB_MISSING_REAL
    else
        b2o_mean = s / n
    end if

end function

pure function b2o_count(subarray, a, b)

    integer(b2o_int), intent(in) :: a, b
    logical, intent(in), dimension(b-a+1) :: subarray
    integer(b2o_int) :: b2o_count

    b2o_count = count(subarray)

end function

pure function b2o_first(subarray, a, b)

    integer(b2o_int), intent(in) :: a, b
    real(b2o_double), intent(in), dimension(b-a+1) :: subarray
    real(b2o_double) :: b2o_first

    b2o_first = subarray(1)

end function

pure function b2o_last(subarray, a, b)

    integer(b2o_int), intent(in) :: a, b
    real(b2o_double), intent(in), dimension(b-a+1) :: subarray
    real(b2o_double) :: b2o_last

    b2o_last = subarray(size(subarray))

end function

end module b2o_functional
