!> @author Tomas Kral
!> @date 2016

    type b2o_heap_t
        private
        integer(kind=4) :: size = 0
        type(b2o_heap_node_t), pointer :: nodes(:) => null()
    end type

    private

    public :: b2o_heap_t
    public :: make_heap, push, peek, pop, finalize

contains

function make_heap(capacity_hint) result(heap)

    integer(kind=4), intent(in), optional :: capacity_hint
    type(b2o_heap_t) :: heap
    integer(kind=4) :: capacity

    capacity = 5
    if (present(capacity_hint)) then
        capacity = capacity_hint
    end if

    allocate(heap%nodes(capacity))

end function

subroutine push(heap, node)

    type(b2o_heap_t), intent(inout) :: heap
    type(b2o_heap_node_t), intent(in) :: node
    integer(kind=4) :: last

    last = heap%size + 1

    if (last > size(heap%nodes)) then
        call resize(heap)
    end if

    heap%size = last
    heap%nodes(last) = node

    call shift_up(heap%nodes, last)

end subroutine

pure function peek(heap) result(node)

    type(b2o_heap_t), intent(in) :: heap
    type(b2o_heap_node_t) :: node

    node = heap%nodes(1)

end function

subroutine pop(heap)

    type(b2o_heap_t), intent(inout) :: heap

    if (heap%size > 0) then
        heap%nodes(1) = heap%nodes(heap%size)
        heap%size = heap%size - 1
        call shift_down(heap%nodes, heap%size, 1)
    end if

end subroutine

subroutine finalize(heap)

    type(b2o_heap_t), intent(inout) :: heap

    if (associated(heap%nodes)) deallocate(heap%nodes)

end subroutine

subroutine reorder(nodes, size)

    type(b2o_heap_node_t), intent(inout) :: nodes(:)
    integer(kind=4), intent(in) :: size
    integer(kind=4) :: i

    do i = size, 1, -1
        call shift_down(nodes, size, i)
    end do

end subroutine

subroutine shift_up(nodes, child)

    type(b2o_heap_node_t), intent(inout) :: nodes(:)
    integer(kind=4), value :: child
    integer(kind=4) :: parent

    do while (child > 1)
        parent = child / 2
        if (.not.out_of_order(nodes(parent), nodes(child))) exit
        call swap(nodes(parent), nodes(child))
        child = parent
    end do

end subroutine

subroutine shift_down(nodes, size, parent)

    type(b2o_heap_node_t), intent(inout) :: nodes(:)
    integer(kind=4), intent(in) :: size
    integer(kind=4), value :: parent
    integer(kind=4) :: left, right, child

    do while (2 * parent < size)

        left = 2 * parent
        right = left + 1

        child = left
        if (right <= size) then
            if (out_of_order(nodes(left), nodes(right))) then
                child = right
            end if
        end if

        if (out_of_order(nodes(parent), nodes(child))) then
            call swap(nodes(parent), nodes(child))
            parent = child
        else
            exit
        end if

    end do

end subroutine

subroutine resize(heap)

    type(b2o_heap_t), intent(inout) :: heap
    type(b2o_heap_node_t), pointer :: new_nodes(:)

    allocate(new_nodes(int(1.5 * size(heap%nodes))))
    new_nodes(1:heap%size) = heap%nodes(1:heap%size)
    deallocate(heap%nodes)
    heap%nodes => new_nodes

end subroutine

! vim: filetype=fortran
