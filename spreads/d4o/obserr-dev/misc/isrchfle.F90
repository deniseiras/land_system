function isrchfle(array, target) result (ind)
      real, dimension(:), intent(in) :: array
      real, intent(in) :: target
      integer :: ind
      do ind=1,size(array)
         if ( array(ind) <= target ) then
            exit
         end if
      end do
      ! ind = size(array+1) if it gets to the end of the loop without exiting
   end function isrchfle
