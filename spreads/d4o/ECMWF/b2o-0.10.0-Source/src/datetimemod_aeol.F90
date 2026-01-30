module DateTimeMod_aeol 
  ! ---------------------------------- 
  !  #[ Description: 
  !   This module facilitates date and time processing for Aeolus BUFR
  !
  ! Modifications
  ! 03-Jan-2018   Michael Rennie  Using some functions from the Aeolus L2B processing code
  !                               Originally by Jos de Kloe
  !
  !  #]
  !  #[ Modules used: 

  !  #]  
  !  #[ parameter/variable/type declarations
  implicit none 

  integer, parameter   :: r8_ = Selected_Real_Kind(15,307)  ! = real*8
  real(r8_), parameter :: missing_indicator_real    = 1.7E38_r8_
  real(r8_), parameter :: missing_indicator_real_lower  = missing_indicator_real*0.99
  integer,   parameter :: missing_indicator_integer = (2**30-1)+2**30! = 2**31-1
  integer, parameter   :: no_error                = 0
  integer, parameter   :: error_invalid_date  = 50001
  integer, parameter   :: error_invalid_time  = 50002

  TYPE date_type
     integer   :: year
     integer   :: month
     integer   :: day
  END TYPE date_type

  TYPE time_type
     integer   :: hour
     integer   :: minute
     real(r8_) :: second
  END TYPE time_type

  TYPE geoloc_type
     real(r8_)   :: latitude
     real(r8_)   :: longitude
     real(r8_)   :: julian_date
     real(r8_)   :: geom_height
     real(r8_)   :: hlos_wind
     integer(kind=4) :: class
     integer(kind=4) :: channel
     integer         :: wind_id
  END TYPE geoloc_type

  ! a date or time is defined as missing if all the 
  ! components in its struct are set to missing

  type(date_type), parameter :: &
       missing_date_value = date_type(missing_indicator_integer, &
                                      missing_indicator_integer, &
                                      missing_indicator_integer)
  !  #]  
  !  #[ interface/operator definitions
  ! ----------------------------------
contains 
  function missing_real(x) result(m)
    !  #[
    real(r8_) :: x
    logical  :: m
    m=.false.
    if (x .ge. missing_indicator_real_lower) m=.true.
  end function missing_real

  function missing_int(x) result(m)
    !  #[
    integer :: x
    logical :: m
    m=.false.
    if (x .eq. (missing_indicator_integer)) m=.true.
  end function missing_int

  ! ----------------------------------
  !  #[ Date functions
    !  #]
  function missing_date(date) result(is_missing)
    !  #[
    TYPE(date_type) :: date       ! input
    logical         :: is_missing ! result

    is_missing = .false.
    IF ( missing_int(date%year)  .and. &
         missing_int(date%month) .and. &
         missing_int(date%day)         ) THEN
       is_missing = .true.
    END IF

  end function missing_date
    !  #]
  function convert_date_to_int(date) result(date_int)
    !  #[ date2int
    ! to enable sorting
    TYPE(date_type) :: date
    integer :: date_int

    if (missing_date(date)) then
       date_int = missing_indicator_integer
       return
    end if

    date_int = 100*100*date%year  + &
                   100*date%month + &
                       date%day
  end function convert_date_to_int
    !  #]
  function convert_int_to_date(date_int) result(date)
    !  #[ int2date
    TYPE(date_type) :: date
    integer :: date_int, rest

    if (missing_int(date_int)) then
       date = missing_date_value
       return
    end if

    date%year  = date_int/(100*100)
    rest       = date_int - 100*100*date%year
    date%month = rest/100
    rest       = rest     - 100*date%month
    date%day   = rest

  end function convert_int_to_date
    !  #]
  function set_date(year,month,day) result(date)
    !  #[ yyyy,mm,dd to date_struct

    ! identical to the default initialisation function date_type()
    ! interface
    TYPE(date_type) :: date
    integer         :: year,month,day

    date%year  = year
    date%month = month
    date%day   = day

  end function set_date
    !  #]
  function conv_date_to_daycount(date) result(daycount)
    !  #[
    ! for given date (ccyymmdd) return day number since 19000101
    ! an adapted version of the IDAT2C.f routine in the lib_util library
    ! Since 2000 was a leap year, all years/4 are leapyears
    ! This will break down for the year 2100.....
    ! (which is not of my concern right now)

    integer, intent(in) :: date ! CCYY*100*100 + MM*100 + DD
    integer :: daycount

    ! local variables
    integer :: yy,mm,dd,rest
    integer :: num_leapyears
    integer, parameter, dimension(12) :: monthstart = &
         (/ 0,31,59,90,120,151,181,212,243,273,304,334 /)

    yy = date/10000
    rest = date - yy*10000
    yy = yy - 1900
    mm = rest/100
    dd = rest - mm*100

    ! allow the special end-of-mission year, but only if month=12 and day=31
    if (date .ne. 99991231) then
       if ( (date .lt. 19000101) .or. &
            (date .gt. 20991231)      ) then
          print *,"ERROR: conv_date_to_daycount cannot handle dates outside"
          print *,"ERROR: the range 19000101...20991231"
          daycount = missing_indicator_integer
          return
       end if
    end if

    !  subtract 1 to let dayrange start with zero
    daycount = monthstart(mm) + dd - 1
    
    ! take leap years into account

    ! Add 1 if current year is a leapyear, and month .gt. 2
    if ( (mod(yy,4) .eq. 0) .and. &
         (yy .ne. 0)        .and. &
         (mm .gt. 2)              ) then
       daycount = daycount + 1
       !print *,"yy = ",yy," mm = ",mm," dd = ",dd
       !print *,"daycount = ",daycount
       !print *,"monthstart(mm) = ",monthstart(mm)
    endif

    ! Remember: 1900 was not a leapyear, but 2000 was one
    ! Take leapyears that occurred BEFORE the curent year into account
    ! NOTE: this will fail beyond the year 2100, so the actual daycount
    ! value for then end-of-mission code 99991231 is wrong.
    ! Don't know yet how important this is. 
    num_leapyears = (yy-1)/4 

    daycount = daycount + yy*365 + num_leapyears

  end function conv_date_to_daycount
  !---------------------------------------------------
    !  #]
  function conv_daycount_to_date(daycount) result(date)
    !  #[

    ! for given day number since 19000101 return the date (ccyymmdd)
    ! an adapted version of the IDAT2C.f routine in the lib_util library
    ! Since 2000 was a leap year, all years/4 are leapyears
    ! This will break down for the year 2100.....
    ! (which is not of my concern right now)

    integer, intent(in) :: daycount
    integer :: date ! CCYY*100*100 + MM*100 + DD

    ! local variables
    integer :: yy,mm,dd,rest
!    integer :: num_leapyears
    integer, parameter, dimension(12) :: monthstart = &
         (/ 0,31,59,90,120,151,181,212,243,273,304,334 /)

    if (daycount .lt. 0) then
       print *,"ERROR: conv_daycount_to_date cannot handle negative daycounts!"
       print *,"ERROR: This would mean a date soutside the range"
       print *,"19000101...20991231, which is not implemented at this time"
       print *,"daycount = ",daycount
       date = missing_indicator_integer
       return
    end if

    yy=0
    rest = daycount
    yearloop: DO
       IF ( (mod(yy,4) .eq. 0) .and. (yy .ne. 0) ) THEN
          ! this is a leapyear
          IF (rest .ge. 366) THEN
             rest = rest - 366
             yy = yy + 1
          ELSE
             exit yearloop
          END IF
       ELSE
          IF (rest .ge. 365) THEN
             rest = rest - 365
             yy = yy + 1
          ELSE
             exit yearloop
          END IF
       END IF
    END DO yearloop

    ! Remember: 1900 was not a leapyear, but 2000 was
    ! Take leapyears that occurred BEFORE the curent year into account


!    yy = int(1.0*daycount/365.25)
!    num_leapyears = (yy-1)/4
!    rest = daycount - yy*365 - num_leapyears

    mm = 1
    monthloop: DO 
       if (rest .lt. monthstart(mm+1)) exit monthloop
       mm = mm+1
       if (mm .eq. 12) exit monthloop
    END DO monthloop

    dd = rest - monthstart(mm) + 1

    ! Add 1 if current year is a leapyear, and month .gt. 2
    if ( (mod(yy,4) .eq. 0) .and. &
         (yy .ne. 0)        .and. &
         (mm .gt. 2)              ) then
       if (rest .eq. monthstart(3) ) then
          ! setting month back to 2
          mm = 2
       else
          ! one extra day for this year ...
          rest = rest - 1
       end if
       dd = rest - monthstart(mm) + 1
       ! for leap years this can result in a day of 0, for the next month
       ! so correct for this
       IF (dd .eq. 0) THEN
          mm = mm - 1
          dd = rest - monthstart(mm) + 1
       END IF
    end if

    !print *,"test: yy = ",yy," mm=",mm," dd=",dd, "rest=",rest

    date = 100*100*(yy+1900) + 100*mm + dd

    ! allow the special end-of-mission year, but only if month=12 and day=31
    if (date .ne. 99991231) then
       IF (date .gt. 20991231) THEN
          print *,"ERROR: The date ",date," is outside the range"
          print *,"19000101...20991231, this is not implemented at this time"
          date = missing_indicator_integer
          return
       END IF
    end if
    
  end function conv_daycount_to_date
  !---------------------------------------------------

    !  #]
  !  #]
  !  #[ Time functions
    !  #]
  function convert_time_to_real(time) result(time_real)
    !  #[
    ! to enable sorting
    TYPE(time_type) :: time   
    real(r8_)       :: time_real
    time_real = real(60*60*time%hour + &
                     60*time%minute,    r8_) + &
                        time%second
  end function convert_time_to_real
    !  #]
  function convert_real_to_time(time_real) result(time)
    !  #[
    ! interface
    TYPE(time_type) :: time       ! struct holding h,m,s in separate fields
    real(r8_)       :: time_real  ! time in seconds since midnight

    ! local variable
    real(r8_) :: rest

    time%hour   = floor(time_real/(60*60))
    rest        = time_real - 60*60*time%hour
    time%minute = floor(rest/60)
    rest        = rest - 60*time%minute
    time%second = rest

  end function convert_real_to_time
    !  #]
  function set_time(h,m,s) result(time)
    !  #[ h,m,s to time
    ! identical to the default initialisation function time_type()
    TYPE(time_type) :: time       ! struct holding h,m,s in separate fields
    integer         :: h,m
    real(r8_)       :: s
    
    time%hour   = h
    time%minute = m
    time%second = s

  end function set_time
    !  #]
  !  #[ combined date-time functions
  subroutine increment_datetime(date,time,time_increment)
    !  #[
    ! add a given time_increment (in seconds) to the time struct, 
    ! and update the date struct if necessary
    
    ! interface
    type(time_type), intent(inout) :: time
    type(date_type), intent(inout) :: date
    real(r8_),       intent(in)    :: time_increment

    ! local variables
    real(r8_) :: time_real, new_time_real
    integer   :: date_int, new_date_int
    integer   :: day_offset, daycount
    real(r8_), parameter :: seconds_per_day = 24._r8_*60*60

    ! convert time to time_real (in seconds since midnight)
    time_real = convert_time_to_real(time) 

    ! calculate new time
    time_real = time_real + time_increment

    ! convert date to date_int
    date_int = convert_date_to_int(date)

    ! first assume the new date equals the old date
    new_date_int = date_int

    ! first assume the new time_real is ok
    new_time_real = time_real

    ! then test time_real 
    if (time_real .lt. 0.) then
       ! we stepped to a previous day, so the date needs to be updated
       day_offset    = 1+floor(abs(time_real)/seconds_per_day)
       daycount      = conv_date_to_daycount(date_int)
       daycount      = daycount - day_offset
       new_date_int  = conv_daycount_to_date(daycount)
       new_time_real = time_real + day_offset*seconds_per_day
    endif

    if (time_real .ge. seconds_per_day) then
       ! we stepped to a next day, so the date needs to be updated
       day_offset    = floor(time_real/seconds_per_day)
       daycount      = conv_date_to_daycount(date_int)
       daycount      = daycount + day_offset
       new_date_int  = conv_daycount_to_date(daycount)
       new_time_real = time_real - day_offset*seconds_per_day
    endif

    ! copy the date_int and time_real values to the 
    ! output values date and time

    date = convert_int_to_date( new_date_int)
    time = convert_real_to_time(new_time_real)

  end subroutine increment_datetime
    !  #]
  INTEGER FUNCTION julday(iday,imonth,iyear)
      !     ==================================================
      !
      !  purpose:
      !  ------
      !        Produce the day relative to "julref" of the current date
      !
      !  arguments:
      !  --------
      !        iday     : day of the current date
      !        imonth   : month of the current date
      !        iyear    : year of the current date (e.g. 1961)
      !           e.g. 21 sep 1987 is called by (21,9,1987)
      !
      IMPLICIT NONE
      INTEGER :: iday,imonth,iyear
      INTEGER, PARAMETER :: igreg=15+31*(10+12*1582)
      INTEGER, PARAMETER :: julref=2415021 !Monday, A.D. 1900 Jan 1 12:00:00.0
      INTEGER :: jy,jm,jultmp,ja

      IF (iyear.LT.0) iyear=iyear+1
      IF (imonth.GT.2) THEN
         jy=iyear
         jm=imonth+1
      ELSE
         jy=iyear-1
         jm=imonth+13
      ENDIF
      jultmp=INT(365.25*jy)+INT(30.6001*jm)+iday+1720995
      IF (iday+31*(imonth+12*iyear).GE.igreg) THEN
         ja=INT(0.01*jy)
         jultmp=jultmp+2-ja+INT(0.25*ja)
      ENDIF
      julday = (jultmp-julref)
      RETURN
  END FUNCTION julday
    !  #]
  ! ----------------------------------
end module DateTimeMod_aeol
