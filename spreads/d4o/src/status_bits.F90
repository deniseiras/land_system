MODULE status_bits
  implicit none

  public
  save

  ! bits for statuses here
  
  integer(4), parameter :: minbitno =  0
  integer(4), parameter :: maxbitno = 52

  character(len=*), parameter :: sb_descr(minbitno:maxbitno) =  &
       & ['active                  =  0-bit' &
       & ,'blacklisted             =  1-bit' &
       & ,'thinned                 =  2-bit' &
       & ,'problematic             =  3-bit' &
       
       & ,'hdr.statid              =  4-bit' &
       & ,'hdr.reportype           =  5-bit' &
       & ,'hdr.group_id            =  6-bit' &
       & ,'hdr.obstype             =  7-bit' &
       & ,'hdr.codetype            =  8-bit' &
       & ,'hdr.bufrtype            =  9-bit' &
       & ,'hdr.subtype             = 10-bit' &
       & ,'hdr.geoarea             = 11-bit' &
       & ,'hdr.deglat              = 12-bit' &
       & ,'hdr.deglon              = 13-bit' &
       & ,'hdr.stalt               = 14-bit' &
       & ,'hdr.timeslot            = 15-bit' &
       & ,'hdr.epoch               = 16-bit' &
       & ,'hdr.yyyymmdd            = 17-bit' &
       & ,'hdr.hhmmss              = 18-bit' &
       & ,'hdr.nbody               = 19-bit' &
       
       & ,'sat.platform_id         = 20-bit' &
       & ,'sat.rttov_sat_id        = 21-bit' &
       & ,'sat.rttov_sensor_id     = 22-bit' &
       & ,'sat.sat_id              = 23-bit' &
       & ,'sat.sensor_id           = 24-bit' &
       & ,'sat.sat_instr           = 25-bit' &
       & ,'sat.azimuth             = 26-bit' &
       & ,'sat.zenith              = 27-bit' &
       & ,'sat.solar_azimuth       = 28-bit' &
       & ,'sat.solar_zenith        = 29-bit' &
       & ,'sat.scanpos             = 30-bit' &
       
       & ,'body.varno              = 31-bit' &
       & ,'body.kind               = 32-bit' & 
       & ,'body.qc                 = 33-bit' &
       & ,'body.dart_qc            = 34-bit' &
       & ,'body.obsvalue           = 35-bit' &
       & ,'body.obs_error          = 36-bit' &
       & ,'body.obs_error_variance = 37-bit' &
       & ,'body.vertco_type        = 38-bit' & 
       & ,'body.which_vert         = 39-bit' &
       & ,'body.levelht            = 40-bit' &
       & ,'body.height             = 41-bit' &
       & ,'body.channel            = 42-bit' &
       & ,'body.press              = 43-bit' &
       & ,'body.ppcode             = 44-bit' &
       
       & ,'<unused>                = 45-bit' &
       & ,'<unused>                = 46-bit' &
       & ,'<unused>                = 47-bit' &
       & ,'<unused>                = 48-bit' &
       & ,'<unused>                = 49-bit' &
       
       & ,'ens.member              = 50-bit' &
       & ,'ens.fg_depar            = 51-bit' &
       
       & ,'<unused>                = 52-bit' &
       & ]

  integer(4), parameter :: sb_unused_bits(6) = [45,46,47,48,49,52]
  
  integer(4), parameter :: sb_active                  =  0
  integer(4), parameter :: sb_blacklisted             =  1
  integer(4), parameter :: sb_thinned                 =  2
  integer(4), parameter :: sb_problematic             =  3
  
  integer(4), parameter :: sb_hdr_statid              =  4
  integer(4), parameter :: sb_hdr_reportype           =  5
  integer(4), parameter :: sb_hdr_group_id            =  6
  integer(4), parameter :: sb_hdr_obstype             =  7
  integer(4), parameter :: sb_hdr_codetype            =  8
  integer(4), parameter :: sb_hdr_bufrtype            =  9
  integer(4), parameter :: sb_hdr_subtype             = 10
  integer(4), parameter :: sb_hdr_geoarea             = 11
  integer(4), parameter :: sb_hdr_deglat              = 12
  integer(4), parameter :: sb_hdr_deglon              = 13
  integer(4), parameter :: sb_hdr_stalt               = 14
  integer(4), parameter :: sb_hdr_timeslot            = 15
  integer(4), parameter :: sb_hdr_epoch               = 16
  integer(4), parameter :: sb_hdr_yyyymmdd            = 17
  integer(4), parameter :: sb_hdr_hhmmss              = 18
  integer(4), parameter :: sb_hdr_nbody               = 19

  integer(4), parameter :: sb_sat_platform_id         = 20
  integer(4), parameter :: sb_sat_rttov_sat_id        = 21
  integer(4), parameter :: sb_sat_rttov_sensor_id     = 22
  integer(4), parameter :: sb_sat_sat_id              = 23
  integer(4), parameter :: sb_sat_sensor_id           = 24
  integer(4), parameter :: sb_sat_sat_instr           = 25
  integer(4), parameter :: sb_sat_azimuth             = 26
  integer(4), parameter :: sb_sat_zenith              = 27
  integer(4), parameter :: sb_sat_solar_azimuth       = 28
  integer(4), parameter :: sb_sat_solar_zenith        = 29
  integer(4), parameter :: sb_sat_scanpos             = 30

  integer(4), parameter :: sb_body_varno              = 31
  integer(4), parameter :: sb_body_kind               = 32
  integer(4), parameter :: sb_body_qc                 = 33
  integer(4), parameter :: sb_body_dart_qc            = 34
  integer(4), parameter :: sb_body_obsvalue           = 35
  integer(4), parameter :: sb_body_obs_error          = 36
  integer(4), parameter :: sb_body_obs_error_variance = 37
  integer(4), parameter :: sb_body_vertco_type        = 38 
  integer(4), parameter :: sb_body_which_vert         = 39
  integer(4), parameter :: sb_body_levelht            = 40
  integer(4), parameter :: sb_body_height             = 41
  integer(4), parameter :: sb_body_channel            = 42
  integer(4), parameter :: sb_body_press              = 43
  integer(4), parameter :: sb_body_ppcode             = 44

  ! Bits 45-49 unused
  
  integer(4), parameter :: sb_ens_member              = 50
  integer(4), parameter :: sb_ens_fg_depar            = 51

  ! Bit 52 unused

  ! IEEE 754 : can't represent losslesly more than 53-bits i.e. sign + 52-bits with real(8) when converted from integer(8)
  
  private :: bitrange

contains

  SUBROUTINE bitrange(ifirst,ilast,first,last)
    integer(4), intent(out) :: ifirst,ilast
    integer(4), intent(in), optional :: first,last
    ifirst = minbitno
    if (present(first)) then
       if (first >= minbitno .and. first <= maxbitno) ifirst = first
    endif
    ilast = ifirst
    if (present(last)) then
       if (last >= minbitno .and. last <= maxbitno) ilast = last
    endif
    if (ilast < ifirst) ilast = ifirst
  END SUBROUTINE bitrange

  FUNCTION getbits(istatus,first,last)
    integer(8) :: getbits
    integer(8), intent(in) :: istatus
    integer(4), intent(in), optional :: first,last
    integer(4) :: ifirst,ilast,ilen
    CALL bitrange(ifirst,ilast,first,last)
    ilen = ilast - ifirst + 1
    getbits = ibits(istatus,ifirst,ilen)
  END FUNCTION getbits

  SUBROUTINE setbits(istatus,first,last)
    integer(8), intent(inout) :: istatus
    integer(4), intent(in), optional :: first,last
    integer(4) :: ifirst,ilast,jpos
    CALL bitrange(ifirst,ilast,first,last)
    do jpos=ifirst,ilast
       istatus = ibset(istatus,jpos)
    enddo
  END SUBROUTINE setbits

  SUBROUTINE clrbits(istatus,first,last)
    integer(8), intent(inout) :: istatus
    integer(4), intent(in), optional :: first,last
    integer(4) :: ifirst,ilast,jpos
    CALL bitrange(ifirst,ilast,first,last)
    do jpos=ifirst,ilast
       istatus = ibclr(istatus,jpos)
    enddo
  END SUBROUTINE clrbits

END MODULE status_bits
