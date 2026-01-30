SUBROUTINE b2o_convert_aeolus(handle, status)

!---------------------------------------------------------------------
!  Convert Aeolus Level-2B BUFR to ODB
!  Method:
!  A modification of the method used in aeolus project: l2b_bufr_and_odb.F90
!  Optionally checks for near duplicate observations and flags them
!  written by: M. Rennie
!
!  Modifications:
!  24/05/2017 M. Rennie  First version
!  20/12/2017 M. Rennie  Include more variables and duplicate obs checks
!  22/11/2018 M. Rennie  Switch on QC with new variables
!  03/01/2019 M. Rennie  Add ability to add an offset correction to heights
!                        and the ability to add a constant bias correction
!                        to HLOS winds
!  12/03/2019 M. Rennie  Modify settings to be suitable for operations
!  17/06/2019 M. Rennie  Fix indexing bug in filling arg_lat@sat
!  20/06/2019 M. Rennie  Add ability to read in bias correction (namelist) 
!                        as function of argument of latitude
!  09/07/2019 M. Rennie  Extend namelist to read other QC thresholds
!  10/10/2019 M. Rennie  Add longitude dimension to bias correction
!  27/02/2020 M. Rennie  Ensure control of Mie-clear and Ray-cloudy is in blacklist
!                        Add max_vert_length to namelist
!                        Add rep. error to namelist and use in obs error calc. and
!                        store in repres_error@errstat
!----------------------------------------------------------------------

USE b2o_internal
USE b2o_utility,      only: b2o_find_free_unit
USE b2o_option,       only: &
     &   namelist_mie => B2O_AEOLUS_MIE_SETTINGS &
     & , namelist_ray => B2O_AEOLUS_RAY_SETTINGS

USE eccodes,          only: codes_get
USE DateTimeMod_aeol, only: date_type, time_type, set_time, &
                            set_date, increment_datetime, geoloc_type, &
                            julday
                                            
IMPLICIT NONE
TYPE(b2o_handle_t), intent(inout) :: handle
INTEGER(kind=b2o_int), intent(inout) :: status

REAL(kind=b2o_double) :: to_double

REAL(kind=b2o_double), pointer :: hdr(:,:)
REAL(kind=b2o_double), pointer :: body(:,:)
REAL(kind=b2o_double), pointer :: errstat(:,:)
REAL(kind=b2o_double), pointer :: sat(:,:)
REAL(kind=b2o_double), pointer :: aeolus_hdr(:,:)
!REAL(kind=b2o_double), pointer :: aeolus_l2c(:,:)
REAL(kind=b2o_double), pointer :: aeolus_l2b(:,:)

INTEGER(kind=b2o_int) :: date, time
INTEGER(kind=b2o_int) :: n_levels

REAL(kind=b2o_double) :: zhook_handle

INTEGER(kind=b2o_int) :: ibufr
INTEGER(kind=b2o_int) :: numObs
TYPE(date_type), dimension(:), pointer :: date_array
TYPE(time_type), dimension(:), pointer :: time_array 
REAL(b2o_double), dimension(:), allocatable :: lat_array,lon_array,time_inc_array,   &
                                               HLOS_wind_array, HLOS_wind_err_array, &
                                               geom_height_array, azimuth_array,     &
                                               elevation_array, range_array,         &
                                               arg_lat_array, t_ref_array, p_ref_array, &
                                               beta_array, dhlos_dt_array, dhlos_dp_array, &
                                               dhlos_dbeta_array, horiz_length_array, &
                                               top_height_array, bottom_height_array, &
                                               vert_length_array, HLOS_wind_bias_array, &
                                               HLOS_wind_err_rep_array

INTEGER(kind=4), dimension(:), allocatable  :: channel_array, class_array,           &
                                               confid_flag_array, wind_id_array,     &
                                               class_val_array, channel_val_array
INTEGER            :: AllocStatus
REAL(b2o_double)   :: sat_id, sat_instr
REAL(b2o_double)   :: ref_year, ref_month, ref_day, ref_hour, ref_minute, ref_second
TYPE(date_type)    :: tmp_ref_date, ref_date
TYPE(time_type)    :: tmp_ref_time, ref_time

! Aeolus L2B parameters
! coordinatesSignificance codes in the L2B BUFR
!integer, parameter :: start_ind   = 2
!integer, parameter :: stop_ind    = 3
INTEGER, parameter :: cog_ind     = 4
INTEGER, parameter :: top_ind     = 6
INTEGER, parameter :: bottom_ind  = 7
INTEGER, parameter :: v_cog_ind   = 5
CHARACTER(len=1)   :: coord_sig_txt

! Height conversion variables for ODB
REAL(b2o_double), dimension(:), allocatable :: geop_hgt, geop
REAL(b2o_double), parameter  :: ifs_g   = 9.80665_b2o_double   ! standard g, m/s^2
REAL(b2o_double), parameter  :: pi      = 3.14159265358979323846264338328_b2o_double
REAL(b2o_double), parameter  :: deg2rad = pi/180._b2o_double !  degree to radian factor
REAL(b2o_double), parameter  :: rad2deg = 180._b2o_double/pi !  radian to degree factor
REAL(b2o_double), parameter  :: R_earth_equatorial = 6378.1_b2o_double ! [km]

! For calculating orbit phase angle
REAL(b2o_double), parameter  :: week_to_seconds = 7.*24.*60.*60.    ! seconds in a week
REAL(b2o_double), parameter  :: day_to_seconds = 24.*60.*60.        ! seconds in a day
REAL(b2o_double), parameter  :: orbit_period = week_to_seconds/111. ! orbit period in seconds; 
                                                                    ! this is based on 111 orbits per week
! Switches for QC and data manipulation
LOGICAL, parameter  :: QC_obs = .true.               ! whether or not to QC obs here
LOGICAL, parameter  :: scale_errors = .true.         ! whether or not to scale the assigned observation errors
LOGICAL, parameter  :: correct_altitudes = .false.   ! whether or not to correct the geometric altitudes;
                                                              ! to be switched off eventually!
LOGICAL, parameter  :: bias_corr_Mie_HLOS = .true. ! whether or not to apply an arg_lat and lon dependent bias correction to the Mie winds
LOGICAL, parameter  :: bias_corr_Ray_HLOS = .true. ! whether or not to apply an arg_lat and lon dependent bias correction to the Ray winds

!-------------------------------------
! Aeolus settings namelist parameters:
!-------------------------------------
! See examples on cca: /perm/rd/da7/aeolus_bias_correction/
!CHARACTER(len=*), parameter :: namelist_mie = 'aeolus_mie_settings'
!CHARACTER(len=*), parameter :: namelist_ray = 'aeolus_ray_settings'
LOGICAL, save :: has_namelist_mie = .false.
LOGICAL, save :: has_namelist_ray = .false.

! Argument of latitude and longitude dependent bias correction parameters
! Mie and Rayleigh arrays of argument of latitude, longitude and corresponding bias (to be subtracted off)
! Only needs to be read and stored once from namelist, hence save
INTEGER(kind=b2o_int), parameter :: max_size_arg_lat_arr = 100
INTEGER(kind=b2o_int), parameter :: max_size_lon_arr = 36
INTEGER(kind=b2o_int), save :: mie_size_arg_lat_arr, mie_size_lon_arr, ray_size_arg_lat_arr, ray_size_lon_arr
REAL(b2o_double), dimension(:), allocatable, save ::  mie_arg_lat_arr, ray_arg_lat_arr, mie_lon_arr, ray_lon_arr
REAL(b2o_double), dimension(:,:), allocatable, save ::  mie_bias_corr_arr, ray_bias_corr_arr  ! bias correction values in m/s HLOS
REAL(b2o_double) :: delta_arg_lat_mie, delta_arg_lat_ray  ! radians
REAL(b2o_double) :: delta_lon_mie, delta_lon_ray  ! degrees

! Other QC related settings to read from the namelist; again save since read only once
! Observations with 1-sigma error estimates greater than thresholds are set to rejected (m/s)
! Observations with too small horizontal accumulation lengths are rejected  (m)
! Observations with too small range-bin thickness are rejected (m)
! Observations with too large range-bin thickness are rejected (m)
! Scale factor for estimated 1-sigma error estimates for use in data assimilation
! A representativeness error for each channel (m/s)
! Offset to be added to the geometric heights (m)
REAL(b2o_double), save :: error_est_max_Mie, error_est_min_Mie, min_horiz_length_mie, &
& min_vert_length_mie, max_vert_length_mie, err_scale_factor_Mie, err_rep_Mie, geom_height_corr_Mie
REAL(b2o_double), save :: error_est_max_Ray, error_est_min_Ray, min_horiz_length_ray, &
& min_vert_length_ray, max_vert_length_ray, err_scale_factor_Ray, err_rep_Ray, geom_height_corr_Ray

INTEGER                      :: QC_event                     ! e.g. 10 for observation error too big
INTEGER                      :: QC_int                       ! overall decimal integer from set bits
LOGICAL, dimension(:), allocatable :: reject_flag_array, duplicate_flag_array
REAL(b2o_double), dimension(:), allocatable :: tmp_QC, report_event1_QC, datum_event1_QC 
LOGICAL, parameter           :: find_duplicate = .true.      ! whether or not to flag duplicates
INTEGER, parameter           :: max_obs = 700000             ! Maximum number of obs per BUFR file
INTEGER, save                :: current_obs_count = 0        ! initialise to zero
REAL(b2o_double)             :: seconds, julian
! Some parameters for detecting duplicate observations
REAL(b2o_double), parameter  :: max_time_diff = 9./86400.    ! maximum allowed time difference (days)
REAL(b2o_double), parameter  :: max_dist_diff = 37.          ! maximum allowed distance difference (km)
REAL(b2o_double), parameter  :: max_height_diff = 20.        ! maximum allowed height difference (m)
! duplicates tend to be at end of one file and start of next file, hence wind id differ by large amount
INTEGER,          parameter  :: min_wind_id_diff = 150       ! minimum allowed wind id difference
REAL(b2o_double)             :: time_diff                    ! days
REAL(b2o_double)             :: dist_diff                    ! km
REAL(b2o_double)             :: height_diff                  ! m
INTEGER                      :: channel_diff, class_diff, wind_id_diff
INTEGER, save                :: duplicate_count = 0          ! initialise to zero

! For detecing duplicates need to keep some info from previous messages
TYPE(geoloc_type), save, dimension(max_obs)  :: whole_bufr

! Unit conversions and parameters for ODB
INTEGER,   parameter   :: obstype     = 15                   ! LIDAR
INTEGER,   parameter   :: codetype    = 187                  ! Doppler Wind Lidar
INTEGER,   parameter   :: groupid     = 46                   ! Doppler Wind Lidar
INTEGER,   parameter   :: reportype   = 45001                ! Aeolus HLOS Wind Level 2B 
INTEGER,   parameter   :: distribtype = 0                    ! type of distribution
INTEGER,   parameter   :: missing_int = 2147483647           ! missing integer value
INTEGER,   parameter   :: file_number = 0                    ! Not actually needed for L2C any more
REAL(b2o_double), parameter   :: missing_real = -missing_int !missing real value  

! Aeolus Channel types in BUFR
INTEGER,   parameter   :: BUFR_Mie = 0
INTEGER,   parameter   :: BUFR_Ray = 1
! Aeolus classifications in BUFR
INTEGER,   parameter   :: BUFR_clear  = 0
INTEGER,   parameter   :: BUFR_cloudy = 1
! valid wind result in BUFR
INTEGER,   parameter   :: BUFR_confid_valid = 0
!integer,   parameter   :: BUFR_confid_invalid = 1

! for looping over obs
INTEGER     :: i, j

! settings for ODB output
INTEGER, parameter :: Mie_Channel       = 1
INTEGER, parameter :: Rayleigh_Channel  = 2
INTEGER, parameter :: Obs_Type_cloudy_returns = 1
INTEGER, parameter :: Obs_Type_clear_returns  = 2  

! constants relating to WGS-84 ellipsoid and gravity above ellipsoid
REAL(b2o_double),    parameter  :: ecc     = 0.081819_b2o_double      ! eccentricity
REAL(b2o_double),    parameter  :: k_somig = 1.931853E-3_b2o_double   ! Somigliana's constant
REAL(b2o_double),    parameter  :: g_equat = 9.7803253359_b2o_double  ! equatorial gravity (ms-2)
REAL(b2o_double),    parameter  :: a_earth = 6378.137E3_b2o_double    ! semi-major axis of earth (m)
REAL(b2o_double),    parameter  :: flatt   = 0.003352811_b2o_double   ! flattening
REAL(b2o_double),    parameter  :: m_ratio = 0.003449787_b2o_double   ! gravity ratio  
! Parameter from ifs
REAL(b2o_double),    parameter  :: g_stan  = 9.80665_b2o_double       ! standard gravity (ms-2)

LOGICAL, parameter  :: debug = .true.      ! whether or not to print debug info

!--------------------------------------------------------------------------------------

IF (lhook) call dr_hook('b2o_convert_aeolus',0,zhook_handle)

! Note that this subroutine is called at the level of BUFR messages, not the whole BUFR file

! For Aeolus have one body entry for each header
n_levels = 1

CALL b2o_reserve(handle, n_levels)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")
!aeolus_l2c => b2o_use_table(handle, "aeolus_l2c")
aeolus_hdr => b2o_use_table(handle, "aeolus_hdr")
aeolus_l2b => b2o_use_table(handle, "aeolus_l2b")

ibufr=handle%bufr_id

! Read the total number of subsets in this BUFR message
CALL codes_get(ibufr,'numberOfSubsets',numObs)    

IF (debug) PRINT *, 'Number of subsets (i.e. observations) for this BUFR message:',numObs

! Allocate arrays

! The rest are allocated for each BUFR meesage
ALLOCATE(lat_array(numObs),stat=AllocStatus)
IF (AllocStatus .ne. 0) THEN
  print *, 'Allocation error: lat_array'
  STOP 1
ENDIF

ALLOCATE(lon_array(numObs),stat=AllocStatus)
IF (AllocStatus .ne. 0) THEN
  print *, 'Allocation error: lon_array'
  STOP 1
ENDIF

ALLOCATE(geom_height_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: geom_height_array'
  stop 1
endif

allocate(azimuth_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: azimuth_array'
  stop 1
endif

allocate(elevation_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: elevation_array'
  stop 1
endif

allocate(range_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: range_array'
  stop 1
endif

allocate(t_ref_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: t_ref_array'
  stop 1
endif

allocate(p_ref_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: p_ref_array'
  stop 1
endif

allocate(beta_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: beta_array'
  stop 1
endif

allocate(dhlos_dt_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: dhlos_dt_array'
  stop 1
endif

allocate(dhlos_dp_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: dhlos_dp_array'
  stop 1
endif

allocate(dhlos_dbeta_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: dhlos_dbeta_array'
  stop 1
endif

allocate(horiz_length_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: horiz_length_array'
  stop 1
endif

allocate(top_height_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: top_height_array'
  stop 1
endif

allocate(bottom_height_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: bottom_height_array'
  stop 1
endif

allocate(vert_length_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: vert_length_array'
  stop 1
endif

allocate(arg_lat_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: arg_lat_array'
  stop 1
endif

allocate(HLOS_wind_bias_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: HLOS_wind_bias_array'
  stop 1
endif

allocate(HLOS_wind_err_rep_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: HLOS_wind_err_rep_array'
  stop 1
endif

allocate(HLOS_wind_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: HLOS_wind_array'
  stop 1
endif

allocate(HLOS_wind_err_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: HLOS_wind_err_array'
  stop 1
endif

allocate(confid_flag_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: confid_flag_array'
  stop 1
endif

allocate(channel_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: channel_array'
  stop 1
endif

allocate(class_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: class_array'
  stop 1
endif

allocate(wind_id_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: wind_id_array'
  stop 1
endif

allocate(date_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: date_array'
  stop 1
endif

allocate(time_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: time_array'
  stop 1
endif

allocate(time_inc_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: time_inc_array'
  stop 1
endif

allocate(reject_flag_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: reject_flag_array'
  stop 1
endif

allocate(duplicate_flag_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: duplicate_flag_array'
  stop 1
endif

allocate(channel_val_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: channel_val_array'
  stop 1
endif

allocate(class_val_array(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: class_val_array'
  stop 1
endif

allocate(tmp_QC(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: tmp_QC'
  stop 1
endif

allocate(report_event1_QC(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: report_event1_QC'
  stop 1
endif

allocate(datum_event1_QC(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: datum_event1_QC'
  stop 1
endif

allocate(geop_hgt(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: geop_hgt'
  stop 1
endif

allocate(geop(numObs),stat=AllocStatus)
if (AllocStatus .ne. 0) then
  print *, 'Allocation error: geop'
  stop 1
endif

!----------------------------------------
! Get all the data from the BUFR message
!----------------------------------------        

! The following have one value per message
!-----------------------------------------
! Get the reference date/time
ref_year   = b2o_get_real(handle,'year')
ref_month  = b2o_get_real(handle,'month')
ref_day    = b2o_get_real(handle,'day')
ref_hour   = b2o_get_real(handle,'hour')
ref_minute = b2o_get_real(handle,'minute')
ref_second = b2o_get_real(handle,'secondsWithinAMinuteMicrosecond')

IF (any([ref_year,ref_month,ref_day,ref_hour,ref_minute,ref_second] == ODB_MISSING_REAL)) THEN
  CALL b2o_log(handle, B2O_ERROR, &
         & "Some information is missing in date-time of Aeolus BUFR message, skipping this message." )
  status = B2O_SKIP_MESSAGE
  CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)
  RETURN
ENDIF

! Convert to a date and time structure
ref_time = set_time(int(ref_hour),int(ref_minute),ref_second)
ref_date = set_date(int(ref_year),int(ref_month),int(ref_day))    

sat_id    = b2o_get_int(handle,'satelliteIdentifier')
sat_instr = b2o_get_int(handle,'satelliteInstruments')

! The following have (potentially) many values per message:
! ----------------------------------------------------------
! Get Aeolus receiver channel
CALL codes_get(ibufr,'receiverChannel',channel_array)
WHERE (channel_array == CODES_MISSING_LONG) channel_array = ODB_MISSING_INT

! Get L2B classification type
CALL codes_get(ibufr,'lidarL2bClassificationType',class_array)
WHERE (class_array == CODES_MISSING_LONG) class_array = ODB_MISSING_INT

! Get L2B wind id number
CALL codes_get(ibufr,'observationIdentifier',wind_id_array)
WHERE (wind_id_array == CODES_MISSING_LONG) wind_id_array = ODB_MISSING_INT

IF (ANY(channel_array == ODB_MISSING_INT)  .OR. ANY(class_array == ODB_MISSING_INT).OR. &
    ANY(wind_id_array  == ODB_MISSING_INT)) THEN
  CALL b2o_log(handle, B2O_ERROR, &
         & "Missing values in channel, class or wind_id of Aeolus BUFR message, skipping this message." )
  status = B2O_SKIP_MESSAGE
  CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)
  RETURN
ENDIF

! Get horizontal centre-of-gravity geolocations
!----------------------------------
WRITE(coord_sig_txt,'(I1)') cog_ind

! Get latitude    
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/latitude',lat_array)
WHERE (lat_array == CODES_MISSING_DOUBLE) lat_array = ODB_MISSING_REAL

! Get longitude
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/longitude',lon_array)
WHERE (lon_array == CODES_MISSING_DOUBLE) lon_array = ODB_MISSING_REAL
lon_array=ensure_lon_range_180_180(lon_array)

! Get timeIncrement
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/timeIncrement',time_inc_array)
WHERE (time_inc_array == CODES_MISSING_DOUBLE) time_inc_array = ODB_MISSING_REAL

IF (ANY(lat_array == ODB_MISSING_REAL)  .OR. ANY(lon_array == ODB_MISSING_REAL).OR. &
    ANY(time_inc_array  == ODB_MISSING_REAL)) THEN
  CALL b2o_log(handle, B2O_ERROR, &
         & "Some information is missing in latitude, longitude or time-increment of Aeolus BUFR message, skipping this message." )
  status = B2O_SKIP_MESSAGE
  CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)
  RETURN
ENDIF

! Convert the time increment for each ob to a proper date time structure
DO i=1,numobs
  tmp_ref_date=ref_date
  tmp_ref_time=ref_time
  ! Need the time increment to be in seconds
  CALL increment_datetime(tmp_ref_date,tmp_ref_time,time_inc_array(i))
  date_array(i)=tmp_ref_date
  time_array(i)=tmp_ref_time 
ENDDO

! Get vertical centre-of-gravity values
!-----------------------------------
WRITE(coord_sig_txt,'(I1)') v_cog_ind

! Get geometric height (relative to geoid), m
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/height',geom_height_array)
WHERE (geom_height_array == CODES_MISSING_DOUBLE) geom_height_array = ODB_MISSING_REAL

! Get azimuth angle, degrees
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/bearingOrAzimuth',azimuth_array)
WHERE (azimuth_array == CODES_MISSING_DOUBLE) azimuth_array = ODB_MISSING_REAL

! TODO: Switch back on check for any missing azimuth angle when issue in Aeolus L2Bp for Rayleigh filling of azimuth is fixed
!  Should always have this geolocation information
!IF (ANY(geom_height_array == ODB_MISSING_REAL)  .OR. ANY(azimuth_array == ODB_MISSING_REAL)) THEN
!  CALL b2o_log(handle, B2O_ERROR, &
!         & "Some information is missing in geometric height or azimuth angle of Aeolus BUFR message, skipping this message." )
!  status = B2O_SKIP_MESSAGE
!  CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)
!  RETURN
!ENDIF

IF (ANY(geom_height_array == ODB_MISSING_REAL)) THEN
  CALL b2o_log(handle, B2O_ERROR, &
         & "Some information is missing in geometric height of Aeolus BUFR message, skipping this message." )
  status = B2O_SKIP_MESSAGE
  CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)
  RETURN
ENDIF

! Get elevation angle, degrees
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/elevation',elevation_array)
WHERE (elevation_array == CODES_MISSING_DOUBLE) elevation_array = ODB_MISSING_REAL

! Get satellite range, m
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/satelliteRange',range_array)
WHERE (range_array == CODES_MISSING_DOUBLE) range_array = ODB_MISSING_REAL

! Satellite orbit argument of latitude is not in BUFR; so just fill with missing for now (estimate later)
arg_lat_array = ODB_MISSING_REAL

! HLOS wind bias array.  To be calculated later (if needed)
HLOS_wind_bias_array = ODB_MISSING_REAL

! HLOS wind representativeness error array.  To be calculated later (if needed)
HLOS_wind_err_rep_array = ODB_MISSING_REAL

! Get HLOS wind value, m/s
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/horizontalLineOfSightWind',HLOS_wind_array)
WHERE (HLOS_wind_array == CODES_MISSING_DOUBLE) HLOS_wind_array = ODB_MISSING_REAL

! Get HLOS wind error estimate, m/s
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)// &
                      '/errorEstimateOfHorizontalLineOfSightWind',HLOS_wind_err_array)
WHERE (HLOS_wind_err_array == CODES_MISSING_DOUBLE) HLOS_wind_err_array = ODB_MISSING_REAL

! Get reference temperature, K
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/airTemperature',t_ref_array)
WHERE (t_ref_array == CODES_MISSING_DOUBLE) t_ref_array = ODB_MISSING_REAL

! Get reference pressure, Pa
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/nonCoordinatePressure',p_ref_array)
WHERE (p_ref_array == CODES_MISSING_DOUBLE) p_ref_array = ODB_MISSING_REAL

! Get scattering ratio
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/backscatterRatio',beta_array)
WHERE (beta_array == CODES_MISSING_DOUBLE) beta_array = ODB_MISSING_REAL

! Get partial derivative of HLOS wind wrt temperature, m s-1 K-1
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/derivativeWindToTemperature',dhlos_dt_array)
WHERE (dhlos_dt_array == CODES_MISSING_DOUBLE) dhlos_dt_array = ODB_MISSING_REAL

! Get partial derivative of HLOS wind wrt pressure, m s-1 Pa-1
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/derivativeWindToPressure',dhlos_dp_array)
WHERE (dhlos_dp_array == CODES_MISSING_DOUBLE) dhlos_dp_array = ODB_MISSING_REAL

! Get partial derivative of HLOS wind wrt scattering ratio, m s-1
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/derivativeWindToBackscatterRatio',dhlos_dbeta_array)
WHERE (dhlos_dbeta_array == CODES_MISSING_DOUBLE) dhlos_dbeta_array = ODB_MISSING_REAL

! Get horizontal integration length, m
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/horizontalObservationIntegrationLength',horiz_length_array)
WHERE (horiz_length_array == CODES_MISSING_DOUBLE) horiz_length_array = ODB_MISSING_REAL

! Get confidence flag, 0=valid, 1=invalid
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/confidenceFlag',confid_flag_array)

! Get top of observation values
!-----------------------------------
WRITE(coord_sig_txt,'(I1)') top_ind

! Get geometric height at top of range-bin, m
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/height', top_height_array)
WHERE (top_height_array == CODES_MISSING_DOUBLE) top_height_array = ODB_MISSING_REAL

! Get bottom of observation values
!-----------------------------------
WRITE(coord_sig_txt,'(I1)') bottom_ind

! Get geometric height at top of range-bin, m
CALL codes_get(ibufr,'/coordinatesSignificance='//trim(coord_sig_txt)//'/height', bottom_height_array)
WHERE (bottom_height_array == CODES_MISSING_DOUBLE) bottom_height_array = ODB_MISSING_REAL

! Vertical length (range-bin size) will be calculated later, so initialise to missing for now
vert_length_array = ODB_MISSING_REAL
WHERE((top_height_array /= ODB_MISSING_REAL) .AND. (bottom_height_array /= ODB_MISSING_REAL)) &
      vert_length_array = top_height_array - bottom_height_array

! Check that all arrays are the same size
IF (size(lat_array)/= numObs .OR. size(lon_array)/= numObs .OR. size(HLOS_wind_array)/= numObs &
    .OR. size(time_inc_array)/= numObs .OR. size(geom_height_array)/= numObs &
    .OR. size(azimuth_array)/= numObs .OR. size(class_array)/= numObs .OR. size(range_array)/= numObs &
    .OR. size(confid_flag_array)/= numObs) then 
  PRINT *,'Inconsistent array dimension(s):'
  PRINT *,'size(HLOS_wind_array)',size(HLOS_wind_array)
  PRINT *,'size(lat_array)',size(lat_array)
  PRINT *,'size(lon_array)',size(lon_array)
  PRINT *,'size(time_inc_array)',size(time_inc_array)
  PRINT *,'size(geom_height_array)',size(geom_height_array)
  PRINT *,'size(azimuth_array)',size(azimuth_array)
  PRINT *,'size(elevation_array)',size(elevation_array)
  PRINT *,'size(range_array)',size(range_array) 
  PRINT *,'size(channel_array)',size(channel_array)
  PRINT *,'size(class_array)',size(class_array)
  PRINT *,'size(confid_flag_array)',size(confid_flag_array)
  PRINT *,'size(wind_id_array)',size(wind_id_array)

  STOP 1
ENDIF 

!Fill in the whole BUFR file information for use in the duplicate checks
DO i=1,numobs
  whole_bufr(current_obs_count + i) % wind_id     = wind_id_array(i)
  whole_bufr(current_obs_count + i) % hlos_wind   = HLOS_wind_array(i)
  whole_bufr(current_obs_count + i) % latitude    = lat_array(i)
  whole_bufr(current_obs_count + i) % longitude   = lon_array(i)
  whole_bufr(current_obs_count + i) % channel     = channel_array(i)
  whole_bufr(current_obs_count + i) % class       = class_array(i)
  whole_bufr(current_obs_count + i) % geom_height = geom_height_array(i)
  !seconds=60.*60.*real(time_array(i) % hour) + 60.*real(time_array(i) % minute) + time_array(i) % second
  !call ymds2ju(date_array(i) % year,date_array(i) % month,date_array(i) % day,seconds,julian)
  !whole_bufr(current_obs_count + i) % julian_date = julian
  whole_bufr(current_obs_count + i) % julian_date = real(julday(date_array(i) % day, &
  & date_array(i) % month, date_array(i) % year)) + &  !fraction of day added on
  & (60.*60.*real(time_array(i) % hour) + 60.*real(time_array(i) % minute) + time_array(i) % second)/86400.
    
ENDDO

!-------------------
! Namelist reading
!-------------------
! Read Aeolus settings namelist for Mie
IF (.NOT. has_namelist_mie) THEN
  call read_aeol_namelist(namelist_mie, mie_arg_lat_arr, mie_lon_arr, mie_bias_corr_arr, mie_size_arg_lat_arr, &
&                         mie_size_lon_arr, error_est_max_Mie, error_est_min_Mie, min_horiz_length_mie, &
&                         min_vert_length_mie, max_vert_length_mie, err_scale_factor_Mie, err_rep_Mie, geom_height_corr_Mie)
  has_namelist_mie = .true.

  IF (debug) THEN
    print *, 'mie_size_arg_lat_arr',mie_size_arg_lat_arr
    print *, 'mie_size_lon_arr',mie_size_lon_arr
    print *, 'mie_arg_lat_arr',mie_arg_lat_arr
    print *, 'mie_lon_arr',mie_lon_arr
    print *, 'mie_bias_corr_arr',mie_bias_corr_arr
    print *, 'error_est_max_Mie',error_est_max_Mie
    print *, 'error_est_min_Mie',error_est_min_Mie
    print *, 'min_horiz_length_mie',min_horiz_length_mie
    print *, 'min_vert_length_mie',min_vert_length_mie
    print *, 'max_vert_length_mie',max_vert_length_mie
    print *, 'err_scale_factor_Mie',err_scale_factor_Mie
    print *, 'err_rep_Mie', err_rep_Mie
    print *, 'geom_height_corr_Mie',geom_height_corr_Mie
  ENDIF
ENDIF

! Read Aeolus settings namelist for Rayleigh
IF (.NOT. has_namelist_ray) THEN
  call read_aeol_namelist(namelist_ray, ray_arg_lat_arr, ray_lon_arr, ray_bias_corr_arr, ray_size_arg_lat_arr, &
&                         ray_size_lon_arr,error_est_max_Ray, error_est_min_Ray, min_horiz_length_ray, &
&                         min_vert_length_ray, max_vert_length_ray, err_scale_factor_Ray, err_rep_Ray, geom_height_corr_Ray)
  has_namelist_ray = .true.

  IF (debug) THEN
    print *, 'ray_size_arg_lat_arr',ray_size_arg_lat_arr
    print *, 'ray_size_lon_arr',ray_size_lon_arr
    print *, 'ray_arg_lat_arr',ray_arg_lat_arr
    print *, 'ray_lon_arr',ray_lon_arr
    print *, 'ray_bias_corr_arr',ray_bias_corr_arr
    print *, 'error_est_max_Ray',error_est_max_Ray
    print *, 'error_est_min_Ray',error_est_min_Ray
    print *, 'min_horiz_length_Ray',min_horiz_length_ray
    print *, 'min_vert_length_Ray',min_vert_length_ray
    print *, 'max_vert_length_Ray',max_vert_length_ray
    print *, 'err_scale_factor_Ray',err_scale_factor_Ray
    print *, 'err_rep_Ray', err_rep_Ray
    print *, 'geom_height_corr_Ray',geom_height_corr_Ray
  ENDIF
ENDIF

!-----------------------------
! QC on the observations
!-----------------------------
! initialise all subsets to not being rejected
reject_flag_array=.false.

IF (QC_obs) THEN
  ! Do QC here
  ! Reject if:
  ! 1. obs error estimate is too large or too small (for channel in question)
  ! 2. or if the horizontal or vertical integration length is too small
  ! 3. or if missing values for HLOS wind or error estimate
  ! 4. or if missing values for latitude, longitude azimuth or height
  ! 5. or if L2Bp overall confidence flag is invalid
  reject_flag_array = (((channel_array .eq. BUFR_Mie) .AND. &
                       ((HLOS_wind_err_array .GE. error_est_max_Mie) .OR. &
                        (HLOS_wind_err_array .LE. error_est_min_Mie) .OR. &
                        (vert_length_array .LT. min_vert_length_mie) .OR. &
                        (vert_length_array .GT. max_vert_length_mie) .OR. &
                        (horiz_length_array .LT. min_horiz_length_mie)))  .OR. &
                       ((channel_array .eq. BUFR_Ray) .AND. &
                       ((HLOS_wind_err_array .GE. error_est_max_Ray) .OR. &
                        (HLOS_wind_err_array .LE. error_est_min_Ray) .OR. &
                        (vert_length_array .LT. min_vert_length_ray) .OR. &
                        (vert_length_array .GT. max_vert_length_ray) .OR. &
                        (horiz_length_array .LT. min_horiz_length_ray))) .OR. &
                       (HLOS_wind_array .EQ. ODB_MISSING_REAL)     .OR. &
                       (HLOS_wind_err_array .EQ. ODB_MISSING_REAL) .OR. &
                       (lat_array .EQ. ODB_MISSING_REAL)           .OR. &
                       (lon_array .EQ. ODB_MISSING_REAL)           .OR. &
                       (azimuth_array .EQ. ODB_MISSING_REAL)       .OR. &
                       (geom_height_array .EQ. ODB_MISSING_REAL)   .OR. &
                       (confid_flag_array .EQ. 1))

ELSE
  ! QC will be done in blacklist for flexibility; here just do basic checks on missing values
  ! Reject if:
  ! 1. or if missing values for HLOS wind or error estimate
  ! 2. or if missing values for latitude, longitude azimuth or height
  reject_flag_array = ((HLOS_wind_array .EQ. ODB_MISSING_REAL).OR.(HLOS_wind_err_array .EQ. ODB_MISSING_REAL)                   .OR. &
                (lat_array .EQ. ODB_MISSING_REAL).OR.(lon_array .EQ. ODB_MISSING_REAL).OR.(azimuth_array .EQ. ODB_MISSING_REAL) .OR. &
                (geom_height_array .EQ. ODB_MISSING_REAL))

ENDIF

! map some values for use in retrtype
! Map BUFR values to ODB values (like original L2B EE values)
! Since this is what we used in the past
!initialise
class_val_array=missing_int
channel_val_array=missing_int

WHERE (class_array == BUFR_clear) class_val_array = Obs_Type_clear_returns
WHERE (class_array == BUFR_cloudy) class_val_array = Obs_Type_cloudy_returns
WHERE (channel_array == BUFR_Mie) channel_val_array = Mie_Channel
WHERE (channel_array == BUFR_Ray) channel_val_array = Rayleigh_Channel

! Store representativeness errors in array
WHERE ((channel_array == BUFR_Mie) .AND. (HLOS_wind_err_array /= ODB_MISSING_REAL)) &
    HLOS_wind_err_rep_array = err_rep_Mie
WHERE ((channel_array == BUFR_Ray) .AND. (HLOS_wind_err_array /= ODB_MISSING_REAL)) &
    HLOS_wind_err_rep_array = err_rep_Ray

IF (scale_errors) THEN
  ! Scale the instrument errors and add representativeness error for use in data assimilation
  WHERE ((channel_array == BUFR_Mie) .AND. (HLOS_wind_err_array /= ODB_MISSING_REAL)) &
    HLOS_wind_err_array = SQRT((err_scale_factor_Mie*HLOS_wind_err_array)**2.0_b2o_double + HLOS_wind_err_rep_array**2.0_b2o_double)
  WHERE ((channel_array == BUFR_Ray) .AND. (HLOS_wind_err_array /= ODB_MISSING_REAL)) &
    HLOS_wind_err_array = SQRT((err_scale_factor_Ray*HLOS_wind_err_array)**2.0_b2o_double + HLOS_wind_err_rep_array**2.0_b2o_double)
ENDIF

IF (correct_altitudes) THEN
  ! Correct the reported altitudes (this will not be needed once corrected in L1Bp)
  WHERE ((channel_array == BUFR_Mie) .AND. (geom_height_array /= ODB_MISSING_REAL)) geom_height_array = geom_height_array + geom_height_corr_Mie
  WHERE ((channel_array == BUFR_Ray) .AND. (geom_height_array /= ODB_MISSING_REAL)) geom_height_array = geom_height_array + geom_height_corr_Ray
ENDIF

! Calculate a psuedo-argument of latitude angle for now (would need ANX times to do correctly)
! Calculated from time of observation and orbit period, assuming a circular orbit
arg_lat_array=2.0_b2o_double*pi*MOD(whole_bufr(current_obs_count+1:current_obs_count + numobs) % julian_date*day_to_seconds, orbit_period) &
                    /orbit_period  ! radians

IF ((bias_corr_Mie_HLOS) .AND. (has_namelist_mie)) THEN
  ! Do Mie bias correction as function of arg_lat and longitude

  IF (mie_size_arg_lat_arr .EQ. 1) THEN
    delta_arg_lat_mie = 2.0_b2o_double*pi  ! if only one arg_lat band
  ELSE
    delta_arg_lat_mie = mie_arg_lat_arr(2)-mie_arg_lat_arr(1)
  ENDIF

  IF (mie_size_lon_arr .EQ. 1) THEN
    delta_lon_mie=360._b2o_double ! if only one longitude band
  ELSE
    delta_lon_mie = mie_lon_arr(2)-mie_lon_arr(1) 
  ENDIF

  ! loop over arg_lat dimension
  DO i=1,mie_size_arg_lat_arr
    ! loop over lon dimension
    DO j=1, mie_size_lon_arr
      WHERE ((channel_array == BUFR_Mie) .AND. (HLOS_wind_array /= ODB_MISSING_REAL) &
      &       .AND. (arg_lat_array /= ODB_MISSING_REAL) &
      &       .AND. (arg_lat_array >= (mie_arg_lat_arr(i) - delta_arg_lat_mie/2.0))  &
      &       .AND. (arg_lat_array < (mie_arg_lat_arr(i) + delta_arg_lat_mie/2.0))  &  
      &       .AND. (lon_array /= ODB_MISSING_REAL) &
      &       .AND. (lon_array >= (mie_lon_arr(j) - delta_lon_mie/2.0))  &
      &       .AND. (lon_array < (mie_lon_arr(j) + delta_lon_mie/2.0))  &
      &       ) HLOS_wind_bias_array = mie_bias_corr_arr(i,j)

    ENDDO
  ENDDO

  !print *, 'Mie bias corr'
  !print *, 'arg_lat_array',arg_lat_array
  !print *, 'lon_array',lon_array
  !print *, 'HLOS_wind_bias_array',HLOS_wind_bias_array 

ENDIF

IF ((bias_corr_Ray_HLOS) .AND. (has_namelist_ray)) THEN
  ! Do Rayleigh bias correction as function of arg_lat and longitude

  IF (ray_size_arg_lat_arr .EQ. 1) THEN
    delta_arg_lat_ray = 2.0_b2o_double*pi  ! if only one arg_lat band
  ELSE
    delta_arg_lat_ray = ray_arg_lat_arr(2)-ray_arg_lat_arr(1)
  ENDIF

  IF (ray_size_lon_arr .EQ. 1) THEN
    delta_lon_ray=360._b2o_double ! if only one longitude band
  ELSE
    delta_lon_ray = ray_lon_arr(2)-ray_lon_arr(1)
  ENDIF

  ! loop over arg_lat dimension
  DO i=1,ray_size_arg_lat_arr
    ! loop over lon dimension
    DO j=1, ray_size_lon_arr
      WHERE ((channel_array == BUFR_Ray) .AND. (HLOS_wind_array /= ODB_MISSING_REAL) &
      &       .AND. (arg_lat_array /= ODB_MISSING_REAL) &
      &       .AND. (arg_lat_array >= (ray_arg_lat_arr(i) - delta_arg_lat_ray/2.0))  &
      &       .AND. (arg_lat_array < (ray_arg_lat_arr(i) + delta_arg_lat_ray/2.0))  &
      &       .AND. (lon_array /= ODB_MISSING_REAL) &
      &       .AND. (lon_array >= (ray_lon_arr(j) - delta_lon_ray/2.0))  &
      &       .AND. (lon_array < (ray_lon_arr(j) + delta_lon_ray/2.0))  &
      &       ) HLOS_wind_bias_array = ray_bias_corr_arr(i,j)
    ENDDO
  ENDDO

  !print *, 'Ray bias corr'
  !print *, 'arg_lat_array',arg_lat_array
  !print *, 'lon_array',lon_array
  !print *, 'HLOS_wind_bias_array',HLOS_wind_bias_array

ENDIF

IF (find_duplicate) THEN
  ! Attempt to find duplicates due to possibly multiple X-band ground station dumps
  ! L2B data is not necessarily identical, but can be rather similar in geolocation values

  ! initialise to all subsets of current message having no duplicates
  duplicate_flag_array = .false.

  ! Check current batch of subsets against all previous ones for a match i.e. a duplicate
  ! In effect only allow the first occurence of the observation to be used
  DO i=1, numobs  ! loop over current message obs
    DO j=1, current_obs_count+i-1  ! loop over all "other" obs
      time_diff   = abs(whole_bufr(i+current_obs_count)%julian_date - whole_bufr(j)%julian_date)
      IF (time_diff < max_time_diff) THEN   
        height_diff = abs(whole_bufr(i+current_obs_count)%geom_height - whole_bufr(j)%geom_height)
        !dist_diff   = get_distance_grcircle(whole_bufr(i+current_obs_count)%latitude,  &
        !                                  whole_bufr(i+current_obs_count)%longitude, &
        !                                  whole_bufr(j)%latitude,                    &
        !                                  whole_bufr(j)%longitude)
        class_diff   = abs(whole_bufr(i+current_obs_count)%class - whole_bufr(j)%class)
        channel_diff = abs(whole_bufr(i+current_obs_count)%channel - whole_bufr(j)%channel)
        wind_id_diff = abs(whole_bufr(i+current_obs_count)%wind_id - whole_bufr(j)%wind_id)

        !if ((height_diff .LT. max_height_diff) .AND. (dist_diff .LT. max_dist_diff) &
        !   .AND. (class_diff .EQ. 0) .AND. (channel_diff .EQ. 0)) then 
        IF ((height_diff < max_height_diff) .AND. (class_diff == 0) .AND. (channel_diff == 0) &
             .AND.(wind_id_diff > min_wind_id_diff)) THEN 
          IF (debug) THEN
            PRINT *, 'Duplicate found:'
            PRINT *, 'Current ob:',i+current_obs_count
            PRINT *, 'Similar ob:',j
            PRINT *, 'Current ob wind id:',whole_bufr(i+current_obs_count)%wind_id
            PRINT *, 'Similar ob wind id:',whole_bufr(j)%wind_id
            PRINT *, 'time_diff (s)', time_diff*86400.
            PRINT *, 'julian_date (day) of current ob',whole_bufr(i+current_obs_count)%julian_date
            PRINT *, 'date of current ob', date_array(i) % year, date_array(i) % month, date_array(i) % day
            PRINT *, 'time of current ob', time_array(i) % hour, time_array(i) % minute, time_array(i) % second
            PRINT *, 'julian_date (day) of similar ob',whole_bufr(j)%julian_date
            PRINT *, 'height_diff (m)', height_diff
            !PRINT *, 'dist_diff (km)', dist_diff
            PRINT *, 'latitude, current ob',whole_bufr(i+current_obs_count)%latitude
            PRINT *, 'latitude, similar ob',whole_bufr(j)%latitude
            PRINT *, 'longitude, current ob',whole_bufr(i+current_obs_count)%longitude
            PRINT *, 'longitude, similar ob',whole_bufr(j)%longitude
            PRINT *, 'HLOS wind, current ob',whole_bufr(i+current_obs_count)%hlos_wind
            PRINT *, 'HLOS wind, similar ob',whole_bufr(j)%hlos_wind
            PRINT *, 'Channel', whole_bufr(j)%channel
            PRINT *, 'Class', whole_bufr(j)%class
            PRINT *, ' '
          ENDIF
          duplicate_flag_array(i)=.true.
          duplicate_count=duplicate_count + 1
          EXIT  ! no need to continue searching for ob i 
        ENDIF
      ENDIF
    ENDDO
  ENDDO
ENDIF

! The overall "saved" count of the number of observations i.e. for all messages so far
current_obs_count = current_obs_count + numobs
IF (debug) THEN
  PRINT *, 'current_obs_count', current_obs_count
  PRINT *, 'duplicate_count', duplicate_count
ENDIF

IF (current_obs_count .GT. (max_obs-100)) THEN
  PRINT *, 'Warning: not enough elements in whole_bufr array to proceed'
  STOP 1
ENDIF

!-------------------------------------
! Write arrays of BUFR data to ODB
!-------------------------------------

hdr(1:numObs,hdr_groupid)   = groupid     !groupid@hdr
hdr(1:numObs,hdr_reportype) = reportype   !reportype@hdr
hdr(1:numObs,hdr_obstype)   = obstype     !obstype@hdr
hdr(1:numObs,hdr_codetype)  = codetype    !codetype@hdr

hdr(1:numObs,hdr_lat) = lat_array         !lat@hdr, units degN
hdr(1:numObs,hdr_lon) = lon_array !lon@hdr, units degE

! Store various properties of wind in retrtype@hdr, a hashed value
hdr(1:numObs,hdr_retrtype) = class_val_array   *100000000 + &      ! 1 digit needed
                             channel_val_array  *10000000 + &      ! 1 digit needed
                             file_number          *100000 + &      ! 2 digits needed
                             wind_id_array                         ! 5 digits needed
                                                                   ! Total=9 digits needed

! Fill the date-time info
! date@hdr
hdr(1:numObs,hdr_date) = date_array%year*10000 + &
                         date_array%month *100 + &
                         date_array%day    !YYYYMMDD
! time@hdr               
hdr(1:numObs,hdr_time) = time_array%hour*10000 + &
                         time_array%minute*100 + &
                         NINT(time_array%second) !HHMMSS

body(1:numObs,body_varno)    = g_los                 ! varno@body
body(1:numObs,body_obsvalue) = HLOS_wind_array       ! obsvalue@body, units m/s
body(1:numObs,body_biascorr) = HLOS_wind_bias_array  ! biascorr@body, HLOS wind bias correction (m/s) 

!convert geometric height to geopotential for the IFS
geop_hgt = geom_to_geop(geom_height_array,lat_array) ! convert geometric height (m) to geopotential height, m
geop = ODB_MISSING_REAL  !initialise
WHERE (geop_hgt /= ODB_MISSING_REAL) geop = ifs_g*geop_hgt ! convert to geopotential, m^2/s^2
body(1:numObs,body_vertco_reference_1) = geop        ! vertco_reference_1@body, geopotential, units m^2/s^2
body(1:numObs,body_vertco_type)  = g_gpheight        ! vertco_type@body, geopotential height vertical co-ordinate type

WHERE(azimuth_array /= ODB_MISSING_REAL) azimuth_array = azimuth_array*deg2rad  ! convert into radians
sat(1:numObs,sat_azimuth) =  azimuth_array           ! azimuth@sat, units radians
WHERE(elevation_array /= ODB_MISSING_REAL) elevation_array = elevation_array*deg2rad  ! convert into radians
sat(1:numObs,sat_zenith)  =  elevation_array         ! zenith@sat, units radians (Aeolus elevation angle)
sat(1:numObs,sat_range)   =  range_array             ! range@sat, m

sat(1:numObs,sat_arg_lat) = arg_lat_array ! arg_lat@sat, radians

sat(1:numObs,sat_satellite_identifier) = sat_id      ! satellite_identifier@sat
sat(1:numObs,sat_satellite_instrument) = sat_instr   ! satellite_instrument@sat

errstat(1:numObs,errstat_obs_error) = HLOS_wind_err_array        ! obs_error@errstat, units m/s 
errstat(1:numObs,errstat_final_obs_error) = HLOS_wind_err_array  ! final_obs_error@errstat, units m/s
errstat(1:numObs,errstat_repres_error) = HLOS_wind_err_rep_array ! repres_error@errstat, units m/s

! Specify flags for observations that are rejected
! Note that duplicates should also be rejected

! Overwrite any rejections
QC_event=3
tmp_QC=0  ! nothing flagged
WHERE (reject_flag_array .OR. duplicate_flag_array) tmp_QC=2**(QC_event-1)           !report_status@hdr, event 3=rejected
hdr(1:numObs,hdr_report_status)=tmp_QC

QC_event=2
report_event1_QC=0  ! nothing flagged
WHERE (reject_flag_array .OR. duplicate_flag_array) report_event1_QC=2**(QC_event-1) !report_event1@hdr, event 2=all rejected
hdr(1:numObs,hdr_report_event1)=report_event1_QC

QC_event=3
tmp_QC=0  ! nothing flagged
WHERE (reject_flag_array .OR. duplicate_flag_array) tmp_QC=2**(QC_event-1)           !datum_status@body, event 3=rejected       
body(1:numObs,body_datum_status)=tmp_QC

QC_event=10
datum_event1_QC=0  ! nothing flagged
WHERE (reject_flag_array) datum_event1_QC=2**(QC_event-1)  !datum_event1@body, event 10=too big observation error
body(1:numObs,body_datum_event1)=datum_event1_QC


! Flagging of duplicates; avoiding overwriting previously set flags
QC_event=5
tmp_QC=0  ! nothing flagged
WHERE (duplicate_flag_array) tmp_QC=2**(QC_event-1)        !report_event1@hdr, event 5=redundant report
hdr(1:numObs,hdr_report_event1)=report_event1_QC + tmp_QC  ! don't wipe earlier QC

!Set three bits:
!datum_event1@body, event 11=redundant datum
!datum_event1@body, event 12=redundant level
!datum_event1@body, event 14=duplicated datum/level
QC_int=2**(11-1) + 2**(12-1) + 2**(14-1)  ! combined integer with QC flags set
tmp_QC=0  ! nothing flagged
WHERE (duplicate_flag_array) tmp_QC=QC_int
body(1:numObs,body_datum_event1)=datum_event1_QC + tmp_QC  ! don't wipe earlier QC


! Set the aeolus_l2c table to missing values
!aeolus_l2c(1:numObs,aeolus_l2c_hlos_ob_err) = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_hlos_fg)     = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_u_fg)        = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_u_fg_err)    = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_v_fg)        = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_v_fg_err)    = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_hlos_fg_err) = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_hlos_an)     = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_hlos_an_err) = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_u_an)        = missing_real
!aeolus_l2c(1:numObs,aeolus_l2c_v_an)        = missing_real

! Set aeolus_hdr table flag value to missing ; the presence of aeouls_hdr is enough to generate an empty
! aeolus_l2c table in the IFS code
aeolus_hdr(1:numObs,aeolus_hdr_aeolus_hdrflag) = ODB_MISSING_INT

! Fill in aeolus_l2b table
aeolus_l2b(1:numObs,aeolus_l2b_t_ref)        =  t_ref_array         ! t_ref@aeolus_l2b, K
aeolus_l2b(1:numObs,aeolus_l2b_p_ref)        =  p_ref_array         ! p_ref@aeolus_l2b, Pa
aeolus_l2b(1:numObs,aeolus_l2b_beta)         =  beta_array          ! beta@aeolus_l2b, Pa
aeolus_l2b(1:numObs,aeolus_l2b_dhlos_dt)     =  dhlos_dt_array      ! dhlos_dt@aeolus_l2b, m s-1 K-1
aeolus_l2b(1:numObs,aeolus_l2b_dhlos_dp)     =  dhlos_dp_array      ! dhlos_dp@aeolus_l2b, m s-1 Pa-1
aeolus_l2b(1:numObs,aeolus_l2b_dhlos_dbeta)  =  dhlos_dbeta_array   ! dhlos_dbeta@aeolus_l2b, m s-1 Pa-1
aeolus_l2b(1:numObs,aeolus_l2b_horiz_length) =  horiz_length_array  ! horiz_length@aeolus_l2b, m
aeolus_l2b(1:numObs,aeolus_l2b_vert_length)  =  vert_length_array   ! vert_length@aeolus_l2b, m
aeolus_l2b(1:numObs,aeolus_l2b_conf_flag)    =  confid_flag_array   ! conf_flag@aeolus_l2b

! free arrays    
DEALLOCATE(lat_array)
DEALLOCATE(lon_array)
DEALLOCATE(time_inc_array)
DEALLOCATE(time_array)
DEALLOCATE(date_array)
DEALLOCATE(geom_height_array)
DEALLOCATE(HLOS_wind_array)
DEALLOCATE(HLOS_wind_err_array)
DEALLOCATE(azimuth_array)
DEALLOCATE(elevation_array)
DEALLOCATE(range_array)
DEALLOCATE(arg_lat_array)
DEALLOCATE(HLOS_wind_bias_array)
DEALLOCATE(HLOS_wind_err_rep_array)
DEALLOCATE(channel_array)
DEALLOCATE(class_array)
DEALLOCATE(confid_flag_array)
DEALLOCATE(wind_id_array)
DEALLOCATE(reject_flag_array)
DEALLOCATE(duplicate_flag_array)
DEALLOCATE(tmp_QC)
DEALLOCATE(report_event1_QC)
DEALLOCATE(datum_event1_QC)
DEALLOCATE(class_val_array)
DEALLOCATE(channel_val_array)
DEALLOCATE(geop_hgt)
DEALLOCATE(geop)
DEALLOCATE(t_ref_array)
DEALLOCATE(p_ref_array)
DEALLOCATE(beta_array)
DEALLOCATE(dhlos_dt_array)
DEALLOCATE(dhlos_dp_array)
DEALLOCATE(dhlos_dbeta_array)
DEALLOCATE(horiz_length_array)
DEALLOCATE(top_height_array)
DEALLOCATE(bottom_height_array)
DEALLOCATE(vert_length_array)

!Need these variables since saved. How to deallocate?
!IF (ALLOCATED(mie_arg_lat_arr)) DEALLOCATE(mie_arg_lat_arr)
!IF (ALLOCATED(ray_arg_lat_arr)) DEALLOCATE(ray_arg_lat_arr)
!IF (ALLOCATED(mie_lon_arr)) DEALLOCATE(mie_lon_arr)
!IF (ALLOCATED(ray_lon_arr)) DEALLOCATE(ray_lon_arr)
!IF (ALLOCATED(mie_bias_corr_arr)) DEALLOCATE(mie_bias_corr_arr)
!IF (ALLOCATED(ray_bias_corr_arr)) DEALLOCATE(ray_bias_corr_arr)

IF (lhook) CALL dr_hook('b2o_convert_aeolus',1,zhook_handle)

contains
FUNCTION ensure_lon_range_180_180(lon) RESULT(norm_lon)
  real(b2o_double), dimension(:), intent(in) :: lon      ! input  in [deg]
  real(b2o_double), dimension(size(lon))     :: norm_lon ! result in [deg]

  norm_lon =  modulo(lon+180.0_b2o_double, 360.0_b2o_double)-180.0_b2o_double
  WHERE (lon == ODB_MISSING_REAL) norm_lon = ODB_MISSING_REAL

END FUNCTION ensure_lon_range_180_180

!---------------------------------------------------------
!  A set of functions for the conversion between geometric 
!  height and geopotential height.
!  written by: M. Rennie
!
!  Modifications:
!  05-Dec-2011 M. Rennie  First version
!---------------------------------------------------------

FUNCTION r_eff(lat) RESULT(r_res)
  !Calculate effective radius value

  !input variable
  REAL(b2o_double), dimension(:), INTENT(IN) :: lat  !latitude in radians
  !output variable
  REAL(b2o_double), dimension(size(lat))     :: r_res     !effective radius in m

  r_res = a_earth/(1.0_b2o_double  + flatt + m_ratio -2.0_b2o_double *flatt*(sin(lat))**2)
  
END FUNCTION r_eff

FUNCTION g_somig(lat) RESULT(g_res)
  !Calculate gravitational acceleration using Somigliana's equation for an ellipsoid

  !input variable
  REAL(b2o_double), dimension(:),    INTENT(IN) :: lat       !latitude in radians
  !output variable
  REAL(b2o_double), dimension(size(lat))        :: g_res     !gravitational acc

  g_res = g_equat*(1.0_b2o_double  + k_somig*(sin(lat))**2)/(SQRT(1.0_b2o_double  - (ecc**2)*(sin(lat))**2))
  
END FUNCTION g_somig

FUNCTION geom_to_geop(geom_hgt,lat) RESULT(geop_hgt)
  !Convert geometric height (m) to geopotential height (m)

  !input variables
  REAL(b2o_double), dimension(:),   INTENT(IN) :: lat       !latitude in degrees
  REAL(b2o_double), dimension(:),   INTENT(IN) :: geom_hgt  !geometric height in m
  !local variables
  REAL(b2o_double), dimension(size(lat))       :: latrad    !latitude in radians
  REAL(b2o_double), dimension(size(lat))       :: g_res     !gravitational acceleration over ellipsoid, ms-2
  REAL(b2o_double), dimension(size(lat))       :: r_res     !earth effective radius, m    
  !output variable
  REAL(b2o_double), dimension(size(lat))       :: geop_hgt  !geopotential height, m

  latrad=lat*deg2rad  !convert latitude from degrees to radians

  g_res=g_somig(latrad)      !get gravitational acceleration for specified latitude
  r_res=r_eff(latrad)        !get Earth effective radius for specified latitude 

  !Calculate geopotential height given the geometric height
  geop_hgt = (g_res/g_stan)*(r_res*geom_hgt)/(r_res+geom_hgt)
  WHERE ((geom_hgt == ODB_MISSING_REAL) .OR. (lat == ODB_MISSING_REAL)) geop_hgt = ODB_MISSING_REAL
  
END FUNCTION geom_to_geop

FUNCTION get_distance_grcircle(lat1,lon1,lat2,lon2) RESULT(distance)
  !  #[
  ! this function converts the angle-distance between 
  ! 2 latlon pairs to a km distance

  real(b2o_double) :: lat1,lon1,lat2,lon2 ! input
  real(b2o_double) :: distance            ! result [km]

  ! local variables
  real(b2o_double) :: angle_distance

  ! since angle_distance will always yield a non-negative
  ! number, distance will always be non-negative as well
  angle_distance = get_angle_distance_grcircle(lat1,lon1,lat2,lon2)
  distance = 2._b2o_double*pi*R_earth_equatorial*angle_distance/360._b2o_double

END FUNCTION Get_distance_grcircle

FUNCTION get_angle_distance_grcircle(lat1,lon1,lat2,lon2) RESULT(angle_dist)
  !  #[
  ! determine the angle (in degrees) on the earths surface
  ! between 2 sets of lat-lon coordinates
  ! along a great-circle 
  ! (assuming that the shape of the earth is a perfect globe)

  ! equations taken from:
  ! http://mathworld.wolfram.com/GreatCircle.html

  ! use the property that the angle alpha between 2 vectors in
  ! cartesian coordinates is given by the inner product of the 2 vectors:
  !              _    _
  ! cos(alpha) = v1 . v2

  ! note that the error for using a sperical earth in stead of the proper
  ! spheroid must always be between the result using R_earth_equatorial
  ! and the result using R_earth_polar. Therefore the maximum error
  ! is estimated at: 
  ! 100.*(R_earth_equatorial - R_earth_polar)/R_earth_polar = 0.34 percent
  ! which is an acceptable accuracy for our use

  real(b2o_double), intent(in) :: lat1,lon1,lat2,lon2
  real(b2o_double) :: angle_dist

  ! loal variables
  real(b2o_double) :: x1,y1,z1
  real(b2o_double) :: x2,y2,z2
  real(b2o_double) :: inner_prod

  call latlon2xyz_radius1(lat1,lon1,x1,y1,z1)
  call latlon2xyz_radius1(lat2,lon2,x2,y2,z2)
  inner_prod = (x1*x2+y1*y2+z1*z2)

  ! extra check, abs(inner_prod) should never be larger than 1 !
  ! however, due to rounding errors it might happen anyway
  if (abs(inner_prod) .gt. 1._b2o_double) inner_prod = 1._b2o_double

  ! extra check, abs(inner_prod) should never be smaller than -1 !
  ! however, due to rounding errors it might happen anyway
  if (abs(inner_prod) .lt. -1._b2o_double) inner_prod = -1._b2o_double

  ! note that an inner product may be negative
  ! so apply abs() to ensure the distance is always positive or zero
  angle_dist = abs(acos(inner_prod)*rad2deg)

END FUNCTION get_angle_distance_grcircle

SUBROUTINE latlon2xyz_radius1(lat,lon,x,y,z)
  !  #[
  ! convert spherical to cartesian coordinates, i.e.
  ! calculate x,y,z coordinates for a given lat,lon pair on a sphere
  ! of radius 1

  ! equations taken from:
  ! http://mathworld.wolfram.com/GreatCircle.html

  real(b2o_double), intent(in)  :: lat,lon
  real(b2o_double), intent(out) :: x,y,z

  ! local variables
  real(b2o_double) :: lon_rad,lat_rad
  real(b2o_double) :: coslat

  lon_rad   = lon*deg2rad
  lat_rad   = lat*deg2rad
  coslat = cos(lat_rad)
  x      = cos(lon_rad)*coslat
  y      = sin(lon_rad)*coslat
  z      = sin(lat_rad)

END SUBROUTINE latlon2xyz_radius1

SUBROUTINE read_aeol_namelist(filename, arg_lat_values, lon_values, bias_values, size_arg_lat, size_lon,  &
&                             error_est_max, error_est_min, min_horiz_length,       &
&                             min_vert_length, max_vert_length, err_scale_factor, err_rep, geom_height_corr)

    ! arguments
    CHARACTER(len=*), intent(in) :: filename
    REAL(b2o_double), intent(out), dimension(:), allocatable :: arg_lat_values, lon_values
    REAL(b2o_double), intent(out), dimension(:,:), allocatable :: bias_values
    INTEGER(b2o_int), intent(out) :: size_arg_lat, size_lon
    REAL(b2o_double), intent(out) :: error_est_max, error_est_min, min_horiz_length, &
&                                    min_vert_length, max_vert_length, err_scale_factor, err_rep, geom_height_corr

    ! local variables
    INTEGER(b2o_int) :: input_num_arg_lats, input_num_lons
    REAL(b2o_double), dimension(:) :: input_arg_lat_values(max_size_arg_lat_arr)
    REAL(b2o_double), dimension(:) :: input_lon_values(max_size_lon_arr)
    REAL(b2o_double), dimension(:,:) :: input_bias_values(max_size_arg_lat_arr,max_size_lon_arr)
    REAL(b2o_double) :: input_error_est_max, input_error_est_min, input_min_horiz_length, &
&                       input_min_vert_length, input_max_vert_length, input_err_scale_factor, input_err_rep, input_geom_height_corr    
    INTEGER(b2o_int) :: k, ios, local_unit
    CHARACTER(len=256) :: iom

    namelist /aeol_settings/ input_num_arg_lats, input_arg_lat_values, input_num_lons, input_lon_values, &
&                            input_bias_values, input_error_est_max, input_error_est_min, input_min_horiz_length, &
&                            input_min_vert_length, input_max_vert_length, input_err_scale_factor, input_err_rep, input_geom_height_corr

    ! Default values
    input_num_arg_lats = max_size_arg_lat_arr
    input_arg_lat_values(:)=ODB_MISSING_REAL
    input_num_lons = max_size_lon_arr
    input_lon_values(:)=ODB_MISSING_REAL 
    input_bias_values(:,:)=ODB_MISSING_REAL
    input_error_est_max=ODB_MISSING_REAL
    input_error_est_min=ODB_MISSING_REAL
    input_min_horiz_length=ODB_MISSING_REAL
    input_min_vert_length=ODB_MISSING_REAL
    input_max_vert_length=ODB_MISSING_REAL
    input_err_scale_factor=ODB_MISSING_REAL
    input_err_rep=ODB_MISSING_REAL
    input_geom_height_corr=ODB_MISSING_REAL

    ! Write out the namelist to see the format
    !open(88,file='example_namelist.nl')
    !write(88,aeol_settings)
    !close(88)

    local_unit=b2o_find_free_unit() 

    open(unit=local_unit, file=filename, status='old', iostat=ios, iomsg=iom)
    if (ios /= 0) then
      call b2o_log(handle%context, B2O_ERROR, "Cannot open file:"//trim(filename)//", IO message: "//trim(iom))
      call b2o_exit(2)
    end if
    
    read(local_unit, nml=aeol_settings, iostat=ios, iomsg=iom)
    if (ios /= 0) then
      call b2o_log(handle%context, B2O_ERROR, "Cannot read 'aeol_settings' namelist filename: "//trim(filename)//", IO message: "//trim(iom))
      call b2o_exit(2)
    end if
    close(local_unit)

    ! Should use the namelist updated value for the array size now, not the max
    allocate(arg_lat_values(input_num_arg_lats))
    allocate(lon_values(input_num_lons))
    allocate(bias_values(input_num_arg_lats,input_num_lons))
    ! Default values
    arg_lat_values(:)=ODB_MISSING_REAL
    lon_values(:)=ODB_MISSING_REAL
    bias_values(:,:)=ODB_MISSING_REAL

    ! Assign values from the namelist
    arg_lat_values(:) = input_arg_lat_values(1:input_num_arg_lats)
    lon_values(:) = input_lon_values(1:input_num_lons)
    bias_values(:,:) = input_bias_values(1:input_num_arg_lats,1:input_num_lons)
    size_arg_lat = input_num_arg_lats
    size_lon = input_num_lons

    error_est_max = input_error_est_max
    error_est_min = input_error_est_min
    min_horiz_length = input_min_horiz_length
    min_vert_length = input_min_vert_length
    max_vert_length = input_max_vert_length
    err_scale_factor = input_err_scale_factor
    err_rep = input_err_rep
    geom_height_corr = input_geom_height_corr
    
END SUBROUTINE read_aeol_namelist

END SUBROUTINE b2o_convert_aeolus
