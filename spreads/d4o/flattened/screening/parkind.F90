MODULE parkind
  implicit none
  public
  save
  INTEGER, PARAMETER :: JPIM = SELECTED_INT_KIND(9)       ! = 4-byte integer
  INTEGER, PARAMETER :: JPIB = SELECTED_INT_KIND(12)      ! = 8-byte integer
  INTEGER, PARAMETER :: JPRD = SELECTED_REAL_KIND(13,300) ! = 8-byte integer (always)
END MODULE parkind
