module b2o_accessor

use b2o_accessor_abstract
use b2o_accessor_compressed
use b2o_accessor_uncompressed_single
use b2o_accessor_uncompressed_multi
use b2o_common

implicit none

contains

subroutine b2o_new_accessor(message, accessor)

    use eccodes

    integer(b2o_int), intent(in) :: message
    class(b2o_accessor_t), intent(inout), allocatable :: accessor
    integer(b2o_int) :: compressedData, numberOfSubsets

    if (allocated(accessor)) then
        deallocate(accessor)
    end if

    call codes_get(message, "compressedData", compressedData)
    call codes_get(message, "numberOfSubsets", numberOfSubsets)

    if (compressedData == 1) then
        allocate(b2o_accessor_compressed_t::accessor)
    else
        if (numberOfSubsets > 1) then
            allocate(b2o_accessor_uncompressed_multi_t::accessor)
        else
            allocate(b2o_accessor_uncompressed_single_t::accessor)
        end if
    end if

end subroutine

end module
