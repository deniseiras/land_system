INTERFACE

function calc_azim(lat,lon,latS,lonS) result(azm)

  use b2o_internal
  implicit none

  real(kind=b2o_double),intent(in)  :: lat
  real(kind=b2o_double),intent(in)  :: lon
  real(kind=b2o_double),intent(in)  :: latS
  real(kind=b2o_double),intent(in)  :: lonS
  real(kind=b2o_double) :: azm

end function calc_azim
END INTERFACE
