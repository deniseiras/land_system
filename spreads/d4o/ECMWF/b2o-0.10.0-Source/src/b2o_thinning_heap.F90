!> @author Tomas Kral
!> @date 2016

module b2o_thinning_heap

    use b2o_thinning_heap_node, b2o_heap_node_t => node_t

    implicit none

    public :: b2o_heap_node_t
    public :: make_node

#include "b2o_heap_template.h"

end module b2o_thinning_heap
