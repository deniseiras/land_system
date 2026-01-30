subroutine b2o_convert_ascat(handle, status)

use b2o_internal

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

type(b2o_table_t), pointer :: table
real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: scatt(:,:)
real(kind=b2o_double), pointer :: scatt_body(:,:)

integer(kind=b2o_int) :: ncols_body
integer(kind=b2o_int) :: ncols_scatt_body

real(kind=b2o_double) :: bufrtype, subtype
integer(kind=b2o_int) :: iobs, jobs, k

integer(kind=b2o_int), parameter :: n_beams = 3
integer(kind=b2o_int), parameter :: n_soil_moistures = 2
integer(kind=b2o_int), parameter :: n_wind_vectors = 2
integer(kind=b2o_int), parameter :: n_variables = n_beams + n_soil_moistures + 2 * n_wind_vectors
integer(kind=b2o_int), parameter :: n_levels = n_beams + n_soil_moistures

character(len=16) :: statid

real(kind=b2o_double) :: zhook_handle

#include "datastream.h"

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_ascat',0,zhook_handle)

call b2o_reserve(handle, n_variables)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
scatt => b2o_use_table(handle, "scatt")
scatt_body => b2o_use_table(handle, "scatt_body", table)
ncols_scatt_body = table%columns
body => b2o_use_table(handle, "body", table)
ncols_body = table%columns
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i5.5)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_levels
  hdr(iobs,hdr_sensor) = 190

  do k = 1, n_beams
    call backscatter(k)
  end do

  call normalized_soil_moisture(4)

  ! Reserve slots for calibrated soil moisture
  ! assuming that normalized soil moisture was read in last!

  jobs = jobs + 1

  body(jobs,1:ncols_body) = body(jobs-1,1:ncols_body)
  body(jobs,body_varno) = g_soilm
  scatt_body(jobs,1:ncols_scatt_body) = scatt_body(jobs-1,1:ncols_scatt_body)

  do k = 1, n_wind_vectors
    call wind_vector()
  enddo

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = b2o_get_real(handle, "satelliteInstruments")
  sat(iobs,sat_gen_centre) = b2o_get_int(handle, "centre")
  sat(iobs,sat_gen_subcentre) = b2o_get_int(handle, "subCentre")
  bufrtype = b2o_get_int(handle, "dataCategory")
  subtype  = b2o_get_int(handle, "dataSubCategory")
  sat(iobs,sat_datastream) = datastream(bufrtype, subtype, &
   &   sat(iobs,sat_gen_centre),sat(iobs,sat_gen_subcentre),&
   &   sat(iobs,sat_satellite_identifier))

  scatt(iobs,scatt_cellno) = b2o_get_int(handle, "crossTrackCellNumber")
  scatt(iobs,scatt_prodflag) = 0

end do subset_loop

if (lhook) call dr_hook('b2o_convert_ascat',1,zhook_handle)

contains

subroutine backscatter(k)

    integer(b2o_int), intent(in) :: k

    jobs = jobs + 1

    body(jobs,body_varno) = g_scatss
    body(jobs,body_vertco_type) = g_scat_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "backscatter", rank=k)

    scatt_body(jobs,scatt_body_azimuth) = b2o_get_real(handle, "antennaBeamAzimuth", rank=k)
    scatt_body(jobs,scatt_body_incidence) = b2o_get_real(handle, "radarIncidenceAngle", rank=k)
    scatt_body(jobs,scatt_body_kp) = b2o_get_real(handle, "radiometricResolutionNoiseValue", rank=k)
    scatt_body(jobs,scatt_body_kp_qf) = b2o_get_real(handle, "ascatKpEstimateQuality", rank=k)
    scatt_body(jobs,scatt_body_sigma0_qf) = b2o_get_real(handle, "ascatSigma0Usability", rank=k)
    scatt_body(jobs,scatt_body_land_fraction) = b2o_get_real(handle, "landFraction", rank=k)

end subroutine

subroutine normalized_soil_moisture(k)

    integer(b2o_int), intent(in) :: k

    jobs = jobs + 1

    body(jobs,body_varno) = g_nsoilm
    body(jobs,body_vertco_type) = g_scat_cha
    body(jobs,body_vertco_reference_1) = k
    body(jobs,body_obsvalue) = b2o_get_real(handle, "surfaceSoilMoisture")

    scatt_body(jobs,scatt_body_sigma0_sm) = b2o_get_real(handle, "backscatter", rank=k+2)
    scatt_body(jobs,scatt_body_soilmoist_sd) = b2o_get_real(handle, "estimatedErrorInSurfaceSoilMoisture")
    scatt_body(jobs,scatt_body_soilmoist_cf) = b2o_get_real(handle, "soilMoistureCorrectionFlag")
    scatt_body(jobs,scatt_body_soilmoist_pf) = b2o_get_real(handle, "soilMoistureProcessingFlag")
    scatt_body(jobs,scatt_body_wetland_fraction) = b2o_get_real(handle, "inundationAndWetlandFraction")
    scatt_body(jobs,scatt_body_topo_complex) = b2o_get_real(handle, "topographicComplexity")

end subroutine

subroutine wind_vector()

    jobs = jobs + 1
    body(jobs,body_varno) = g_scatu
    body(jobs,body_vertco_type) = g_scat_cha

    jobs = jobs + 1
    body(jobs,body_varno) = g_scatv
    body(jobs,body_vertco_type) = g_scat_cha

end subroutine

end subroutine b2o_convert_ascat
