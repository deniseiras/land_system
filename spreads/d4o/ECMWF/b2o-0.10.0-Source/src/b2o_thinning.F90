!> @author Tomas Kral
!> @date 2016

module b2o_thinning

    use b2o_thinning_heap

    implicit none

    private

    public :: b2o_non_adaptive_thinning

contains

function b2o_non_adaptive_thinning(array, N, apriory_errors) result(mask)

    real(8), intent(in) :: array(:)
    integer(4), intent(in) :: N
    real(8), intent(in), dimension(size(array)) :: apriory_errors
    logical, dimension(size(array)) :: mask

    type(b2o_heap_node_t) :: node
    type(b2o_heap_t) :: heap
    real(8) :: error
    real(8), dimension(size(array)) :: x
    integer(4), dimension(size(array)) :: points
    integer(4) :: index, version
    integer(4) :: i, a, b

    x = normalized(array)

    heap = make_heap(2 * size(x) - N)

    do i = 2, size(x) - 1
        error = anticipated_error(x, i, i-1, i+1) + apriory_errors(i)
        index = i
        version = 1
        node = make_node(error, index, version)
        call push(heap, node)
    end do

    points(:) = 1

    do i = 1, size(x) - N

        node = peek(heap)
        do while (node%version /= points(node%index))
            call pop(heap)
            node = peek(heap)
        end do

        call pop(heap)
        points(node%index) = 0

        a = left_neighbor(node%index, points)
        b = right_neighbor(node%index, points)

        if (a > 1) then
            points(a) = points(a) + 1
            error = anticipated_error(x, a, left_neighbor(a, points), b)
            call push(heap, make_node(error + apriory_errors(a), a, points(a)))
        end if

        if (b < size(x)) then
            points(b) = points(b) + 1
            error = anticipated_error(x, b, a, right_neighbor(b, points))
            call push(heap, make_node(error + apriory_errors(b), b, points(b)))
        end if

    end do

    mask(:) = points(:) > 0

    call finalize(heap)

end function

pure function normalized(array)

    real(8), intent(in) :: array(:)
    real(8), dimension(size(array)) :: normalized
    real(8) :: x_min, x_max
    integer(4) :: i

    x_min = huge(x_min)
    x_max = -x_min

    do i = 1, size(array)
       x_min = min(array(i), x_min)
       x_max = max(array(i), x_max)
    end do

    normalized = (array - x_min) / (x_max - x_min)

end function

pure function anticipated_error(x, i, a, b) result(e)

    real(8), intent(in) :: x(:)
    integer(4), intent(in) :: i, a, b
    real(8) :: e

    e = (x(i) - x(a)) * (x(b) - x(i))

end function

pure function left_neighbor(i, array) result(a)

    integer(4), intent(in) :: i
    integer(4), intent(in) :: array(:)
    integer(4) :: a

    a = i - 1
    do while (a > 1 .and. array(a) == 0)
        a = a - 1
    end do

end function

pure function right_neighbor(i, array) result(b)

    integer(4), intent(in) :: i
    integer(4), intent(in) :: array(:)
    integer(4) :: b

    b = i + 1;
    do while (b < size(array) .and. array(b) == 0)
        b = b + 1
    end do

end function

end module b2o_thinning
