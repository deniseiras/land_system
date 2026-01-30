module b2o_accessor_abstract

use b2o_common

implicit none

type, abstract :: b2o_accessor_t
    contains
    procedure(b2o_accessor_get_int), deferred :: get_int
    procedure(b2o_accessor_get_real), deferred :: get_real
    procedure(b2o_accessor_get_string), deferred :: get_string
    procedure(b2o_accessor_is_defined), deferred :: is_defined
end type

abstract interface

    function b2o_accessor_get_int(this, message, subset, key, rank, status) result(value)
        import :: b2o_accessor_t, b2o_int
        class(b2o_accessor_t), intent(in) :: this
        integer(b2o_int), intent(in) :: message, subset, rank
        character(len=*), intent(in) :: key
        integer(b2o_int), intent(out) :: status
        integer(b2o_int) :: value
    end function

    function b2o_accessor_get_real(this, message, subset, key, rank, status) result(value)
        import :: b2o_accessor_t, b2o_int, b2o_double
        class(b2o_accessor_t), intent(in) :: this
        integer(b2o_int), intent(in) :: message, subset, rank
        character(len=*), intent(in) :: key
        integer(b2o_int), intent(out) :: status
        real(b2o_double) :: value
    end function

    subroutine b2o_accessor_get_string(this, message, subset, key, value, status)
        import :: b2o_accessor_t, b2o_int
        class(b2o_accessor_t), intent(in) :: this
        integer(b2o_int), intent(in) :: message, subset
        character(len=*), intent(in) :: key
        character(len=*), intent(out) :: value
        integer(b2o_int), intent(out) :: status
    end subroutine

    function b2o_accessor_is_defined(this, message, subset, key, rank) result(value)
        import :: b2o_accessor_t, b2o_int, b2o_double
        class(b2o_accessor_t), intent(in) :: this
        integer(b2o_int), intent(in) :: message, subset, rank
        character(len=*), intent(in) :: key
        logical :: value
    end function

end interface

end module
