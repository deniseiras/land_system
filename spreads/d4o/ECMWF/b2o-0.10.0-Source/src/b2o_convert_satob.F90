subroutine b2o_convert_satob(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: satob(:,:)

real(kind=b2o_double) :: obsvalue
real(kind=b2o_double) :: bufrtype, subtype
real(kind=b2o_double) :: ee, freq
real(kind=b2o_double), allocatable, dimension(:) :: unexp_desc
integer(kind=b2o_int) :: satid
integer(kind=b2o_int) :: satinst
integer(kind=b2o_int) :: year
integer(kind=b2o_int), parameter :: n_variables = 5
integer(kind=b2o_int) :: rdbflag
integer(kind=b2o_int) :: iobs, jobs, irank
character(len=16) :: statid
integer(kind=b2o_int) :: id_freq
integer(kind=b2o_int) :: dataproc
integer(kind=b2o_int) :: master_table
integer(kind=b2o_int) :: template2018_flag
integer(kind=b2o_int) :: std_gen_app
real(kind=b2o_double) :: zhook_handle
real(b2o_double) , parameter :: epsilon = 0.00001D+15 ! Hz

#include "datastream.h"

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_satob',0,zhook_handle)

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
satob => b2o_use_table(handle, "satob")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  ! Check if file is in new format (approved by WMO end 2018). Various elements have changed position
  ! or have been removed/added so different treatment is necessary in some cases.
  template2018_flag = 0
  ! Note that number of descriptors varies between new and old template. Check if new bufr table
  ! 310077 is being used indicating new tempate present.
  call codes_get(handle%bufr_id, "unexpandedDescriptors", unexp_desc)
  if ( ANY( unexp_desc==310077 ) ) then
    !BUFR file is in new format so set flag 
    template2018_flag = 1
  end if
  
  satid = b2o_get_int(handle, "satelliteIdentifier")

  select case (handle%subtype)
  case (87)
    if (template2018_flag ==1) then
      !If in new template, pick first instance of "centre" which is
      !generating centre of AMV (here, 2nd instance = generating centre of 
      !forecast information used)
      dataproc = b2o_get_int(handle, "centre") ! AMV
    else
      dataproc = b2o_get_int(handle, "centre", rank=2) ! AMV
    end if  
  case (82:83) ; dataproc = b2o_get_int(handle, "centre") ! SATOB
  case default ; dataproc = ODB_MISSING_INT
  end select

  ! Skew the satid number to 773/774 for CIMSS MODIS WINDS (MCIDAS)
  if ((satid == 783 .or. satid == 784) .and. dataproc == 98) then
    satid = satid - 10
  end if
  
  satob(iobs,satob_dataproc) = dataproc ! identification of originating/generating centre
  
  year = b2o_get_date(handle) / 10000

  if (year == 1979) then

    select case (satid)
    case (1)   ; satid = 58  ! Meteosat-1
    case (150) ; satid = 153 ! GMS-3
    end select

  end if

  select case (satid)
  case (0,200)     ; satid = 250 ! GOES-6
  case (2,101,103) ; satid = 154 ! GMS-2
  case (171)       ; satid = 179 ! MTSAT-1R (reprocessed VIS channel AMVs)
  end select

  statid = ' '
  write (statid, '(i3.3)') satid

  rdbflag = 0

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle, rdbflag)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle, rdbflag)
  hdr(iobs,hdr_report_rdbflag) = rdbflag
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = 1

  if (handle%subtype == 87) then
    select case (satid)
    case (0:99)    ; satinst = 996 ! Eumetsat HD winds
    case (200:299) ; satinst = 998 ! goes HD winds
    case (783)     ; satinst = 997 ! terra satellite modis winds
    case (784)     ; satinst = 995 ! aqua satellite modis winds
    case default   ; satinst = ODB_MISSING_INT
    end select
  end if

  ! Temperature

  if (b2o_is_defined(handle, "airTemperature")) then
    if (handle%subtype == 87) then
      obsvalue = ODB_MISSING_REAL
    else
      obsvalue = b2o_get_real(handle, "airTemperature")
    end if
    call append("airTemperature", g_t, obsvalue=obsvalue)
  else
    call append("", g_t) ! coldest cluster temperature
  end if

  ! Wind direction, speed and (reserved) u/v components

  call append("windDirection", g_dd)
  call append("windSpeed", g_ff)
  call append("", g_u)
  call append("", g_v)

  sat(iobs,sat_satellite_identifier) = satid
  sat(iobs,sat_satellite_instrument) = satinst

  if (handle%subtype == 87) then
    sat(iobs,sat_zenith) = b2o_get_real(handle, "satelliteZenithAngle")
  end if

  if (b2o_is_defined(handle, "centre")) then
    sat(iobs,sat_gen_centre) = b2o_get_int(handle, "centre")
    sat(iobs,sat_gen_subcentre) = b2o_get_int(handle, "bufrHeaderSubCentre")
  end if

  bufrtype = b2o_get_int(handle, "dataCategory")
  subtype = b2o_get_int(handle, "dataSubCategory")
  sat(iobs,sat_datastream) = datastream(bufrtype, subtype, &
   &   sat(iobs,sat_gen_centre),sat(iobs,sat_gen_subcentre),&
   &   sat(iobs,sat_satellite_identifier))

  call codes_get(handle%bufr_id, "masterTablesVersionNumber", master_table)
  if (b2o_is_defined(handle, "satelliteDerivedWindComputationMethod")) then
    satob(iobs,satob_comp_method) = b2o_get_int(handle, "satelliteDerivedWindComputationMethod")
    if (master_table > 6) then
       ! BUFR code table 002023 changed for version of master table > 6
       ! IFS expects old code values.
       if (satob(iobs,satob_comp_method) == 3) then
          satob(iobs,satob_comp_method) = 0
       else if(satob(iobs,satob_comp_method) == 7) then
          satob(iobs,satob_comp_method) = 3
       end if
    end if

    ! Map comp. method=8 (reserved value) to 1 = IR as 3.9um IR winds are meant by NOAA/NESDIS or KMA
    ! satobfreq.F90 is changed:channel number will be added to the computational method
    ! this remapping from 8 --> 1 is only temporarily!! It should be done during acquisition.
    if ((satid == 254 .or. satid == 256 .or. satid == 810 ) .and. &
      (satob(iobs,satob_comp_method) == 8)) then
         satob(iobs,satob_comp_method) = 1
    end if

    if(satid == 471) then
       freq = b2o_get_real(handle, "satelliteChannelCentreFrequency")
       if (freq > 0.4357D14-epsilon .and. freq < 0.4357D14+epsilon) then
          satob(iobs,satob_comp_method) = 3
       elseif (freq > 0.78299D14-epsilon .and. freq < 0.78299D14+epsilon) then
          satob(iobs,satob_comp_method) = 1
       elseif  (freq > 0.277D14-epsilon .and. freq < 0.277D14+epsilon) then
          satob(iobs,satob_comp_method) = 1
       elseif  (freq > 0.4600D15-epsilon .and. freq < 0.4600D15+epsilon) then
          satob(iobs,satob_comp_method) = 2
       endif
    endif

    ! Update of the computational method for satellites with more than one channel per band.
    if (handle%subtype == 87) then
      call satobfreq(satid, b2o_get_real(handle, "satelliteChannelCentreFrequency"), id_freq)
      satob(iobs,satob_comp_method) = satob(iobs,satob_comp_method) + id_freq * 100
    end if

    ! Computation method not defined for GOES-6 SATOB
    if (satid == 250) then
      satob(iobs,satob_comp_method) = 1
    end if

  end if

  ! Make computation method also available in the header
  hdr(iobs,hdr_sensor) = satob(iobs,satob_comp_method)

  if (b2o_is_defined(handle, "satelliteInstrumentDataUsedInProcessing")) then
    satob(iobs,satob_instdata) = b2o_get_int(handle, "satelliteInstrumentDataUsedInProcessing")
  else if (b2o_is_defined(handle, "satelliteInstrumentUsedInDataProcessing")) then
    satob(iobs,satob_instdata) = b2o_get_int(handle, "satelliteInstrumentUsedInDataProcessing")
  else if (b2o_is_defined(handle, "satelliteInstruments")) then
    !Use different name given in new template
    satob(iobs,satob_instdata) = b2o_get_int(handle, "satelliteInstruments")
  end if

  if (handle%subtype == 87) then

    !In the new bufr format, the generating method of the percent confidence 
    !is given by a "Standard generating application" table.
    !These pairs of elements are repeated 4 times and can hold any combination
    !Or ordering of percent confidence values.    
    if (template2018_flag == 1) then
      do irank = 1,4
        std_gen_app = b2o_get_int(handle, "standardGeneratingApplication", rank=irank)
        select case (std_gen_app)
          case (3) ! Recursive filter function
            satob(iobs,satob_rff) = b2o_get_int(handle, "percentConfidence", rank=irank)
          case (5) !QI without forecast
            satob(iobs,satob_qi_nofc) = b2o_get_int(handle, "percentConfidence", rank=irank)
          case (6) !QI with forecast
            satob(iobs,satob_qi_fc) = b2o_get_int(handle, "percentConfidence", rank=irank)
          case (7)  !Estimated error
            ee = b2o_get_real(handle, "percentConfidence", rank=irank)
            if (ee /= ODB_MISSING_REAL) then
              satob(iobs,satob_ee) = (100.0_B2O_DOUBLE - ee) / 10.0_B2O_DOUBLE
            end if            
        end select
      end do
    
      satob(iobs,satob_height_assignment_method) = b2o_get_int(handle, "extendedHeightAssignmentMethod") 
    
    else

      ! For each centre the order of QI values is different, but should be harmonized here to the following:
      ! QI_fc: Forecast-dependent EUMETSAT QI
      ! RFF: Recursive Filter Flag
      ! QI_nofc: Forecast-independent EUMETSAT QI

      select case (nint(satob(iobs,satob_dataproc)))
      case (254,34,39,40) ! EUMETSAT, JMA, CMA, KMA
         satob(iobs,satob_qi_fc) = b2o_get_int(handle, "windDirection->percentConfidence")
         satob(iobs,satob_qi_nofc) = b2o_get_int_if_defined(handle, "windDirection->percentConfidence->percentConfidence")
      case (160) ! NOAA/NESDIS
         ! The QI_fc, RFF, and QI_nofc is not defined for earlier ECMWF's NPP data
         satob(iobs,satob_qi_fc) = b2o_get_int_if_defined(handle, &
             & "windDirection->percentConfidence->percentConfidence->percentConfidence")
         satob(iobs,satob_rff) = b2o_get_int_if_defined(handle, "windDirection->percentConfidence->percentConfidence")
         satob(iobs,satob_qi_nofc) = b2o_get_int_if_defined(handle, "windDirection->percentConfidence")
         ee = b2o_get_real_if_defined(handle, &
             & "windDirection->percentConfidence->percentConfidence->percentConfidence->percentConfidence") ! expected error
         if (ee /= ODB_MISSING_REAL) then
           satob(iobs,satob_ee) = (100.0_B2O_DOUBLE - ee) / 10.0_B2O_DOUBLE
         end if
      case (98,173,176) ! CIMSS/WISCONSIN BUFR-ised at ECMWF
         satob(iobs,satob_qi_fc) = b2o_get_int(handle, "windDirection->percentConfidence")
         satob(iobs,satob_rff) = b2o_get_int(handle, "windDirection->percentConfidence->percentConfidence")
      case (28) ! IMD
         satob(iobs,satob_qi_nofc) = b2o_get_int(handle, "windDirection->percentConfidence")
      end select
      
      satob(iobs,satob_tb) = b2o_get_real(handle, "coldestClusterTemperature")
      satob(iobs,satob_height_assignment_method) = b2o_get_int(handle, "heightAssignmentMethod")

    end if

    satob(iobs,satob_segment_size_x) = b2o_get_real(handle, "segmentSizeAtNadirInXDirection")
    satob(iobs,satob_segment_size_y) = b2o_get_real(handle, "segmentSizeAtNadirInYDirection")
    satob(iobs,satob_chan_freq) = b2o_get_real(handle, "satelliteChannelCentreFrequency")
    satob(iobs,satob_tracer_correlation_method) = b2o_get_int(handle, "tracerCorrelationMethod")
    satob(iobs,satob_land_sea) = b2o_get_int(handle, "landOrSeaQualifier")

  end if
     
end do subset_loop

if (lhook) call dr_hook('b2o_convert_satob',1,zhook_handle)

contains

subroutine append(key, varno, obsvalue)

    character(len=*), intent(in) :: key
    integer(b2o_int), intent(in) :: varno
    real(b2o_double), intent(in), optional :: obsvalue
    integer(b2o_int) :: vertco_type
    integer(b2o_int) :: rdbflag
    real(b2o_double) :: obsvalue_
    character(len=32) :: k_vertco

    jobs = jobs + 1

    if (b2o_is_defined(handle, "height")) then
        vertco_type = g_gpheight
        k_vertco = "height"
    else if (b2o_is_defined(handle, "pressure")) then
        vertco_type = g_pressure
        k_vertco = "pressure"
    else if (b2o_is_defined(handle, "nonCoordinatePressure")) then
        vertco_type = g_pressure
        k_vertco = "nonCoordinatePressure"
    else
        call b2o_log(handle, B2O_WARNING, "Cannot find vertical coordinate")
        call b2o_exit(2)
    end if

    rdbflag = b2o_get_rdbflag(handle, k_vertco, 27, 0)
    rdbflag = b2o_get_rdbflag(handle, key, 12, rdbflag)

    if (present(obsvalue)) then
        obsvalue_ = obsvalue
    else
        obsvalue_ = b2o_get_real(handle, key)
    end if

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = vertco_type
    body(jobs,body_vertco_reference_1) = b2o_get_real(handle, k_vertco)
    body(jobs,body_datum_rdbflag) = rdbflag
    !Note when using new template, rdbflag is left as 0. For current processing,
    !rdbflag is not used for screening in AMVs.
    body(jobs,body_obsvalue) = obsvalue_

end subroutine

end subroutine b2o_convert_satob
