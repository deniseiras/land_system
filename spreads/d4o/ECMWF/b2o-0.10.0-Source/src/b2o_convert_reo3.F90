#include "b2o_debug.h"

subroutine b2o_convert_reo3(handle, status)

use b2o_internal
use b2o_option, only : B2O_CAMS_OZONE, B2O_CAMS_AND_IFS_OZONE

implicit none
type(b2o_handle_t), intent(inout) :: handle
integer(kind=b2o_int), intent(inout) :: status

real(kind=b2o_double) :: to_double

real(kind=b2o_double), pointer :: hdr(:,:)
real(kind=b2o_double), pointer :: body(:,:)
real(kind=b2o_double), pointer :: sat(:,:)
real(kind=b2o_double), pointer :: resat(:,:)
real(kind=b2o_double), pointer :: errstat(:,:)

integer(kind=b2o_int) :: satinst
integer(kind=b2o_int) :: iobs, jobs, k
integer(kind=b2o_int) :: n_reports, n_layers, n_variables
integer(kind=b2o_int) :: varno
character(len=16) :: statid
real(kind=b2o_double) :: press1, press2

real(kind=b2o_double) :: zhook_handle

integer, parameter :: GOMOS = 161
integer, parameter :: MIPAS = 172
integer, parameter :: MLS = 386

!--------------------------------------------------------------------------------------

if (lhook) call dr_hook('b2o_convert_reo3',0,zhook_handle)

satinst = b2o_get_int(handle, "satelliteInstruments")

select case (satinst)
case (GOMOS,MIPAS,MLS) ; n_variables = 3
case default           ; n_variables = 1
end select

if (B2O_CAMS_OZONE .or. B2O_CAMS_AND_IFS_OZONE) then
  varno = g_chem5 ! GEMS/MACC/CAMS ozone
else
  varno = g_o3lay ! IFS ozone
end if

n_layers = b2o_get_int(handle, "numberOfRetrievedLayers")
n_reports = handle%reports

if (B2O_CAMS_AND_IFS_OZONE) then
  n_reports = 2 * n_reports ! extra report with IFS ozone (varno=206)
end if

call b2o_reserve(handle, n_variables * n_layers, n_reports)

hdr => b2o_use_table(handle, "hdr")
sat => b2o_use_table(handle, "sat")
resat => b2o_use_table(handle, "resat")
body => b2o_use_table(handle, "body")
errstat => b2o_use_table(handle, "errstat")

iobs = 0
jobs = 0

subset_loop: do while (b2o_next_subset(handle))

  ! Either IFS ozone (varno=206), or GEMS/MACC/CAMS ozone (varno=185)

  call convert_subset(varno, status)

  ! Extra report with IFS ozone (varno=206) for GEMS/MACC/CAMS testing purposes

  if (B2O_CAMS_AND_IFS_OZONE) then
    call convert_subset(g_o3lay, status)
  end if

  if (status /= B2O_SUCCESS) exit subset_loop

end do subset_loop

if (lhook) call dr_hook('b2o_convert_reo3',1,zhook_handle)

contains

subroutine convert_subset(varno, status)

  integer(b2o_int), intent(in) :: varno
  integer(b2o_int), intent(inout) :: status
  real(b2o_double) :: hook_handle

  if (lhook) call dr_hook('b2o_convert_reo3:convert_subset', 0, hook_handle)

  iobs = iobs + 1

  statid = ' '
  write (statid,'(i8)') b2o_get_int(handle, "satelliteIdentifier")

  hdr(iobs,hdr_retrtype) = 0
  hdr(iobs,hdr_date) = b2o_get_date(handle)
  hdr(iobs,hdr_time) = b2o_get_time(handle)
  hdr(iobs,hdr_lat) = b2o_get_lat(handle)
  hdr(iobs,hdr_lon) = b2o_get_lon(handle)
  hdr(iobs,hdr_statid) = transfer(statid,to_double)
  hdr(iobs,hdr_numlev) = n_layers
  hdr(iobs,hdr_sensor) = satinst
  hdr(iobs,hdr_instrument_type) = satinst

  layer_loop: do k = 1, n_layers

    press1 = b2o_get_real(handle, "pressure", rank=2*(k-1)+1)
    press2 = b2o_get_real(handle, "pressure", rank=2*(k-1)+2)

    call append_if_defined("integratedOzoneDensity", varno)
    call append_if_defined("airTemperature", g_t)
    call append_if_defined("integratedWaterVapourDensity", g_pwc)

  end do layer_loop

  resat(iobs,resat_instrument_type) = b2o_get_int(handle, "satelliteInstruments")
  resat(iobs,resat_product_type) = b2o_get_int(handle, "productTypeForRetrievedAtmosphericGases")
  resat(iobs,resat_solar_elevation) = b2o_get_real(handle, "solarElevation")
  resat(iobs,resat_scanpos) = b2o_get_real(handle, "fieldOfViewNumber")
  resat(iobs,resat_cloud_cover) = b2o_get_real(handle, "cloudCoverTotal")
  resat(iobs,resat_cloud_top_press) = b2o_get_real(handle, "pressureAtTopOfCloud")
  resat(iobs,resat_quality_retrieval) = b2o_get_int(handle, "qualityInformation")
  resat(iobs,resat_number_layers) = n_layers

  do k = 1, 4
    resat(iobs,resat_lat_fovcorner(k)) = b2o_get_real(handle, "nonCoordinateLatitude", rank=k)
    resat(iobs,resat_lon_fovcorner(k)) = b2o_get_real(handle, "nonCoordinateLongitude", rank=k)
  end do

  sat(iobs,sat_satellite_identifier) = b2o_get_int(handle, "satelliteIdentifier")
  sat(iobs,sat_satellite_instrument) = satinst

  if (lhook) call dr_hook('b2o_convert_reo3:convert_subset', 1, hook_handle)

end subroutine

subroutine append_if_defined(key, varno)

    character(len=*), intent(in) :: key 
    integer(b2o_int), intent(in) :: varno

    if (.not.b2o_is_defined(handle, key, rank=k)) return

    jobs = jobs + 1

    body(jobs,body_varno) = varno
    body(jobs,body_vertco_type) = g_pressure
    body(jobs,body_vertco_reference_1) = press1
    body(jobs,body_vertco_reference_2) = press2
    body(jobs,body_obsvalue) = b2o_get_real(handle, key, rank=k)
    body(jobs,body_nlayer) = k
    errstat(jobs, errstat_obs_error) = b2o_get_real_if_defined(handle, trim(key) // "->firstOrderStatisticalValue", rank=k)

end subroutine

end subroutine b2o_convert_reo3
