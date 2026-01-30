SUBROUTINE geosangl(lat,lon,satlon,satlat,satalt,zenith)

! Computes zenith angle for geostationnary satellite
! NB: assumes that the grid point is in the
!     sight of the satellite (i.e. angle defined!)
!
! Initial version:
!	F. Chevallier  	February 2000

USE PARKIND1  ,ONLY : JPIM     ,JPRD

IMPLICIT NONE

!
! Arguments
!
REAL(KIND=JPRD) :: lat    ! grid point latitude      (deg)
REAL(KIND=JPRD) :: lon    ! grid point longitude     (deg)
REAL(KIND=JPRD) :: satlon ! satellite longitude       (deg)
REAL(KIND=JPRD) :: satlat ! satellite latitude        (deg)
REAL(KIND=JPRD) :: satalt ! satellite altitude       (km)
REAL(KIND=JPRD) :: zenith ! zenith angle             (deg)
!
! Local variables
!
REAL(KIND=JPRD), parameter :: rearth = 6378.170_JPRD   ! earth equatorial radius (km)
REAL(KIND=JPRD) :: pi
REAL(KIND=JPRD) :: rlat, rlon, rsatlon, rsatlat    ! angles in radians
REAL(KIND=JPRD) :: ds, a , rm, rl, tb, b, z        ! for trigonometry
!

pi  = acos(-1._JPRD)

! conversion to radians
rsatlon = satlon  /180._JPRD*pi
rsatlat = satlat  /180._JPRD*pi
rlon = lon/180._JPRD*pi
rlat = lat/180._JPRD*pi

!Distance on the ground
ds = rearth * 2._JPRD * &
     asin(((1._JPRD-sin(rlat)*sin(rsatlat) -  &
     cos(rlat)*cos(rsatlat)*cos( rlon - rsatlon ))/2._JPRD)**(.5_JPRD))

!Easy trigonometry
a = ds / rearth
rl = rearth * sin(a)
rm = rearth * cos(a)
tb = rl / (rearth + satalt - rm)
b = atan(tb)
z = a + b

zenith = z/pi*180._JPRD  !! in degrees

END SUBROUTINE geosangl
