!> @author Tomas Kral
!> @date 2016

module b2o_thinning_heap_node

    implicit none

    type node_t
        real(kind=8) :: value
        integer(kind=4) :: index
        integer(kind=4) :: version
    end type

contains

pure function make_node(value, index, version) result(node)

    real(kind=8), intent(in) :: value
    integer(kind=4), intent(in) :: index
    integer(kind=4), intent(in) :: version
    type(node_t) :: node

    node%value = value
    node%index = index
    node%version = version

end function

pure function out_of_order(parent, child)

    type(node_t), intent(in) :: parent, child
    logical :: out_of_order

    out_of_order = (parent%value > child%value)

end function

subroutine swap(parent, child)

    type(node_t), intent(inout) :: parent, child
    type(node_t) :: temp

    temp = parent
    parent = child
    child = temp

end subroutine

end module b2o_thinning_heap_node
