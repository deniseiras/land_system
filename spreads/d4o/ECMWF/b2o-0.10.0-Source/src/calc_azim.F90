! Calculates the azimuth between the spacecraft and the observation.
!
! Adapted from calc_azimuth.F90 and distance_between.F90 in SatRad
! 26-Oct-2017  Chris Burrows

function calc_azim(latdeg,londeg,latSdeg,lonSdeg) result(azm)

  use b2o_internal
  implicit none

  real(b2o_double),intent(in)  :: latdeg
  real(b2o_double),intent(in)  :: londeg
  real(b2o_double),intent(in)  :: latSdeg
  real(b2o_double),intent(in)  :: lonSdeg
  real(b2o_double) :: azm

  real(b2o_double) :: lat
  real(b2o_double) :: lon
  real(b2o_double) :: latS
  real(b2o_double) :: lonS
  real(b2o_double) :: distOS
  real(b2o_double) :: azmsin
  real(b2o_double) :: azmcos
  real(b2o_double) :: rad2deg
  real(b2o_double) :: pi_r8=3.14159265359
  real(b2o_double) :: zdlon, zdlat, za

  rad2deg = 180.d0 / pi_r8

  ! Check to avoid divide by zero if ob is at sub-satellite point
  if ((abs(latdeg-latSdeg) .gt. 0.00001) .and. (abs(londeg-lonSdeg) .gt. 0.00001)) then

    lat = latdeg / rad2deg
    lon = londeg / rad2deg
    latS = latSdeg / rad2deg
    lonS = lonSdeg / rad2deg

    ! Calculate angular distance
    zdlon = lonS - lon
    zdlat = latS - lat
    za = (sin(zdlat/2.0_b2o_double))**2 + cos(lat) * cos(latS) * (sin(zdlon/2.0_b2o_double))**2
    distOS = 2.0_b2o_double * asin( min(1.0_b2o_double,sqrt(za)) ) ! angular distance in radians


    ! -- law of sines
    ! sin(distNS)/sin(NOS) = sin(distOS)/sin(ONS)
    !  NOS = azimuth angle
    !  ONS = lonO - lonS
    !  sin(distNS) = sin(pi/2-latS)
    !              = cos(latS)
    azmsin = cos(latS) / sin(distOS) * sin(lon-lonS)
    azmsin = max( -1.d0, min( 1.d0, azmsin ) )
    azmsin = asin(azmsin) ! -pi/2 <= asin <= pi/2

    ! -- law of cosines
    ! cos(distNS) = cos(distNO)*cos(distOS) + sin(distNO)*sin(distOS)*cos(NOS)
    azmcos = ( sin(latS) - sin(lat)*cos(distOS) ) / ( cos(lat)*sin(distOS) )
    azmcos = max( -1.d0, min( 1.d0, azmcos ) )
    azmcos = acos(azmcos) ! 0 <= acos <= pi
    if ( azmsin>0 ) azmcos = - azmcos

    azm = azmcos

    if ( azm >= pi_r8 ) azm = azm - 2.d0*pi_r8
    if ( azm < -pi_r8 ) azm = azm + 2.d0*pi_r8

    azm = azm * rad2deg

    ! Ensure azimuth angle is in range 0-360, to make it easy to pass through bufr fields
    azm = modulo(azm,360.0_b2o_double)

  else
    azm = -999.0
  end if

  return

end function calc_azim
