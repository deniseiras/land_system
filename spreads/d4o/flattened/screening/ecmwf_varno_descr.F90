module ecmwf_varno_descr
  ! generated with help of the following command :
  ! sqlite3 -readonly -batch -init /dev/null -nullvalue NULL -box \
  ! $D4ODIR/../b2o/share/b2o/ecmwf_varno_descr.db "select * from ecmwf_varno_descr" -csv|perl -pe 's/"//g;'|\
  ! awk -F, '{print $2,"=",$1}' |\
  ! perl -pe 's/\s+--\s+(.*)(\s+=\s+\d+)/$2 ! $1/; s/^/integer(kind=jpim),parameter :: /' > ecmwf_varno_descr.F90
  use parkind, only : jpim
  implicit none
  public
  integer(kind=jpim),parameter :: z = 1 ! geopotential
  integer(kind=jpim),parameter :: t = 2 ! upper air temperature (K)
  integer(kind=jpim),parameter :: u = 3 ! upper air u component
  integer(kind=jpim),parameter :: v = 4 ! upper air v component
  integer(kind=jpim),parameter :: du = 5 ! wind shear (du)
  integer(kind=jpim),parameter :: dv = 6 ! wind shear (dv)
  integer(kind=jpim),parameter :: q = 7 ! specific humidity (q)
  integer(kind=jpim),parameter :: vsp = 8 ! vertical speed
  integer(kind=jpim),parameter :: pwc = 9 ! precipitable water content
  integer(kind=jpim),parameter :: ts = 11 ! surface temperature (K)
  integer(kind=jpim),parameter :: tsts = 12 ! sea water temperature (used in synoptic maps)
  integer(kind=jpim),parameter :: rhlay = 19 ! layer rel. humidity
  integer(kind=jpim),parameter :: rh = 29 ! upper air rel. humidity
  integer(kind=jpim),parameter :: ptend = 30 ! pressure tendency
  integer(kind=jpim),parameter :: t2m = 39 ! 2m temperature (K)
  integer(kind=jpim),parameter :: td2m = 40 ! 2m dew point (K)
  integer(kind=jpim),parameter :: u10m = 41 ! 10m u component (m/s)
  integer(kind=jpim),parameter :: v10m = 42 ! 10m v component (m/s)
  integer(kind=jpim),parameter :: vt = 56 ! virtual temperature
  integer(kind=jpim),parameter :: dz = 57 ! thickness
  integer(kind=jpim),parameter :: rh2m = 58 ! 2m rel. humidity
  integer(kind=jpim),parameter :: td = 59 ! upper air dew point (K)
  integer(kind=jpim),parameter :: w = 60 ! past weather (w)
  integer(kind=jpim),parameter :: ww = 61 ! present weather (ww)
  integer(kind=jpim),parameter :: vv = 62 ! visibility
  integer(kind=jpim),parameter :: ch = 63 ! type of high clouds (ch)
  integer(kind=jpim),parameter :: cm = 64 ! type of middle clouds (cm)
  integer(kind=jpim),parameter :: cl = 65 ! type of low clouds (cl)
  integer(kind=jpim),parameter :: nh = 66 ! cloud base height (nh)
  integer(kind=jpim),parameter :: nn = 67 ! low cloud amount (n)
  integer(kind=jpim),parameter :: hshs = 68 ! additional cloud group height (hh)
  integer(kind=jpim),parameter :: c = 69 ! additional cloud group type (c)
  integer(kind=jpim),parameter :: ns = 70 ! additional cloud group amount (ns)
  integer(kind=jpim),parameter :: sdepth = 71 ! snow depth
  integer(kind=jpim),parameter :: e = 72 ! state of ground (e)
  integer(kind=jpim),parameter :: tgtg = 73 ! ground temperature (tgtg)
  integer(kind=jpim),parameter :: spsp1 = 74 ! special phenomena (spsp)#1
  integer(kind=jpim),parameter :: spsp2 = 75 ! special phenomena (spsp)#2
  integer(kind=jpim),parameter :: rs = 76 ! ice code type (rs)
  integer(kind=jpim),parameter :: eses = 77 ! ice thickness (eses)
  integer(kind=jpim),parameter :: is = 78 ! ice (is)
  integer(kind=jpim),parameter :: trtr = 79 ! original time period of rain obs. (trtr)
  integer(kind=jpim),parameter :: rr = 80 ! 6hr rain (liquid part)
  integer(kind=jpim),parameter :: jj = 81 ! max. temperature (jj)
  integer(kind=jpim),parameter :: vs = 82 ! ship speed (vs)
  integer(kind=jpim),parameter :: ds = 83 ! ship direction (ds)
  integer(kind=jpim),parameter :: hwhw = 84 ! wave height
  integer(kind=jpim),parameter :: pwpw = 85 ! wave period
  integer(kind=jpim),parameter :: dwdw = 86 ! wave direction
  integer(kind=jpim),parameter :: gclg = 87 ! general cloud group
  integer(kind=jpim),parameter :: rhlc = 88 ! rel. humidity from low clouds
  integer(kind=jpim),parameter :: rhmc = 89 ! rel. humidity from middle clouds
  integer(kind=jpim),parameter :: rhhc = 90 ! rel. humidity from high clouds
  integer(kind=jpim),parameter :: n = 91 ! total amount of clouds
  integer(kind=jpim),parameter :: sfall = 92 ! 6hr snowfall (solid part of rain)
  integer(kind=jpim),parameter :: pstation = 107 ! Station pressure (Pa)
  integer(kind=jpim),parameter :: pmsl = 108 ! Mean sea-level pressure (Pa)
  integer(kind=jpim),parameter :: pstandard = 109 ! Standard level pressure (Pa)
  integer(kind=jpim),parameter :: ps = 110 ! surface pressure
  integer(kind=jpim),parameter :: dd = 111 ! wind direction
  integer(kind=jpim),parameter :: ff = 112 ! wind force
  integer(kind=jpim),parameter :: rawbt = 119 ! brightness temperature (K)
  integer(kind=jpim),parameter :: rawra = 120 ! raw radiance
  integer(kind=jpim),parameter :: satcl = 121 ! cloud amount from satellite
  integer(kind=jpim),parameter :: scatss = 122 ! sigma 0
  integer(kind=jpim),parameter :: cllqw = 123 ! cloud liquid water
  integer(kind=jpim),parameter :: scatv = 124 ! ambiguous v component
  integer(kind=jpim),parameter :: scatu = 125 ! ambiguous u component
  integer(kind=jpim),parameter :: scatwd = 126 ! ambiguous wind direction
  integer(kind=jpim),parameter :: scatws = 127 ! ambiguous wind speed
  integer(kind=jpim),parameter :: apdss = 128 ! atmospheric path delay in satellite signal
  integer(kind=jpim),parameter :: cpt = 130 ! characteristic of pressure tendency (used in synoptic maps)
  integer(kind=jpim),parameter :: height = 156 ! height
  integer(kind=jpim),parameter :: w2 = 160 ! past weather 2 (used in synoptic maps)
  integer(kind=jpim),parameter :: bend_angle = 162 ! radio occultation bending angle
  integer(kind=jpim),parameter :: limb_radiance = 163 ! Limb Radiances
  integer(kind=jpim),parameter :: aerod = 174 ! aerosol optical depth at 0.55 microns
  integer(kind=jpim),parameter :: cod = 175 ! cloud optical depth
  integer(kind=jpim),parameter :: rao = 176 ! Ratio of fine mode to total aerosol optical depth at 0.55 microns
  integer(kind=jpim),parameter :: od = 177 ! optical depth
  integer(kind=jpim),parameter :: rfltnc = 178 ! Aerosol reflectance multi-channel
  integer(kind=jpim),parameter :: nsoilm = 179 ! normalized soil moisture  (0-100%)
  integer(kind=jpim),parameter :: soilm = 180 ! soil moisture
  integer(kind=jpim),parameter :: chem1 = 181 ! chem1: no2/nox
  integer(kind=jpim),parameter :: chem2 = 182 ! chem2: so2
  integer(kind=jpim),parameter :: chem3 = 183 ! chem3: co
  integer(kind=jpim),parameter :: chem4 = 184 ! chem4: hcho
  integer(kind=jpim),parameter :: chem5 = 185 ! chem5: go3
  integer(kind=jpim),parameter :: ghg1 = 186 ! ghg1: carbon dioxide
  integer(kind=jpim),parameter :: los = 187 ! horizontal line-of-sight wind component
  integer(kind=jpim),parameter :: ghg2 = 188 ! ghg2: methane
  integer(kind=jpim),parameter :: ghg3 = 189 ! ghg3: nitrous oxide
  integer(kind=jpim),parameter :: bt_real = 190 ! brightness temperature real part
  integer(kind=jpim),parameter :: bt_imaginary = 191 ! brightness temperature imaginary part
  integer(kind=jpim),parameter :: refl = 192 ! radar reflectivity
  integer(kind=jpim),parameter :: rawbt_clear = 193 ! brightness temperature for clear  (K)
  integer(kind=jpim),parameter :: rawbt_cloudy = 194 ! brightness temperature for cloudy (K)
  integer(kind=jpim),parameter :: dopp = 195 ! radar doppler wind
  integer(kind=jpim),parameter :: flgt_phase = 201 ! phase of aircraft flight
  integer(kind=jpim),parameter :: prc = 202 ! radar rain rate
  integer(kind=jpim),parameter :: lnprc = 203 ! log(radar rain rate mm/h + epsilon)
  integer(kind=jpim),parameter :: o3lay = 206 ! layer ozone
  integer(kind=jpim),parameter :: height_assignment_method = 211 ! Height assignment method
  integer(kind=jpim),parameter :: onedvar = 215 ! 1d-var model level (pseudo)-variable
  integer(kind=jpim),parameter :: vert_vv = 218 ! Vertical visibility (m)
  integer(kind=jpim),parameter :: max_wind_shear1 = 219 ! Wind shear above and below 1st maximum wind in sonde profile (s-1)
  integer(kind=jpim),parameter :: ralt_swh = 220 ! significant wave height (m)
  integer(kind=jpim),parameter :: ralt_sws = 221 ! surface wind speed (m/s)
  integer(kind=jpim),parameter :: libksc = 222 ! lidar backscattering
  integer(kind=jpim),parameter :: binary_snow_cover = 223 ! binary snow cover (0: no snow / 1: presence of snow)
  integer(kind=jpim),parameter :: salinity = 224 ! ocean salinity (PSU)
  integer(kind=jpim),parameter :: potential_temp = 225 ! potential temperature (Kelvin) or theta -- [alias to $potential_temp]
  integer(kind=jpim),parameter :: humidity_mixing_ratio = 226 ! humidity mixing ratio (kg/kg)
  integer(kind=jpim),parameter :: airframe_icing = 227 ! airframe icing
  integer(kind=jpim),parameter :: turbulence_index = 228 ! turbulence index
  integer(kind=jpim),parameter :: tot_zen_delay = 229 ! Total zenith delay (GPS)
  integer(kind=jpim),parameter :: tot_zen_delay_err = 230 ! Total zenith delay error (GPS)
  integer(kind=jpim),parameter :: cloud_top_temp = 231 ! Cloud top temperature (K)
  integer(kind=jpim),parameter :: rawsca = 233 ! Scaled radiance
  integer(kind=jpim),parameter :: cloud_top_press = 235 ! Cloud top pressure (Pa)
  integer(kind=jpim),parameter :: lidar_aerosol_extinction = 236 ! lidar aerosol extinction
  integer(kind=jpim),parameter :: lidar_cloud_backscatter = 237 ! lidar cloud backscatter
  integer(kind=jpim),parameter :: lidar_cloud_extinction = 238 ! lidar cloud extinction
  integer(kind=jpim),parameter :: cloud_radar_reflectivity = 239 ! cloud radar reflectivity
  integer(kind=jpim),parameter :: mean_freq = 241 ! GPSRO mean frequency
  integer(kind=jpim),parameter :: u_amb = 242 ! Ambiguous u-wind component (m/s)
  integer(kind=jpim),parameter :: v_amb = 243 ! Ambiguous v-wind component (m/s)
  integer(kind=jpim),parameter :: lwp = 244 ! Liquid water path
  integer(kind=jpim),parameter :: tcwv = 245 ! Total column water vapour
  integer(kind=jpim),parameter :: cloud_frac_clear = 247 ! Cloud clear fraction
  integer(kind=jpim),parameter :: rawbt_hirs = 248 ! Raw brightness temperature specific to HIRS (K)
  integer(kind=jpim),parameter :: rawbt_amsu = 249 ! Raw brightness temperature specific to AMSU (K)
  integer(kind=jpim),parameter :: rawbt_hirs20 = 250 ! Raw brightness temperature specific to HIRS (K)
  integer(kind=jpim),parameter :: sea_ice = 253 ! Sea ice fraction
  integer(kind=jpim),parameter :: cloud_frac_covered = 257 ! Cloud covered fraction
  integer(kind=jpim),parameter :: level_mixing_ratio = 258 ! [alias for $humidity_mixing_ratio]
  integer(kind=jpim),parameter :: radial_velocity = 259 ! Radial velocity from doppler radar
  integer(kind=jpim),parameter :: cloud_ice_water = 260 ! Cloud ice water
  integer(kind=jpim),parameter :: wind_gust = 261 ! Maximum wind gust (m/s)
  integer(kind=jpim),parameter :: mass_density = 262 ! Mass density
  integer(kind=jpim),parameter :: atmosphere_number = 263 ! SFERICS number of atmospheres
  integer(kind=jpim),parameter :: lightning = 265 ! Lightning strike observation (ATDNET)
  integer(kind=jpim),parameter :: level_cloud = 266 ! Cloud fraction (multi-level)
  integer(kind=jpim),parameter :: rawbt_amsr_89ghz = 267 ! Raw brightness temperature specific to AMSR 89GHz channels (K)
  integer(kind=jpim),parameter :: max_wind_shear2 = 268 ! Wind shear above and below 2nd maximum wind in sonde profile
  integer(kind=jpim),parameter :: lower_layer_p = 269 ! Pressure at bottom of layer SBUV (Pa)
  integer(kind=jpim),parameter :: upper_layer_p = 270 ! Pressure at top of later SBUV (Pa)
  integer(kind=jpim),parameter :: cloud_cover = 271 ! Total cloud cover
  integer(kind=jpim),parameter :: depth = 272 ! Depth (m)
  integer(kind=jpim),parameter :: ssh = 273 ! Sea surface height (m)
  integer(kind=jpim),parameter :: rawbt_mwts = 274 ! Raw brightness temperature specific to MWTS (K)
  integer(kind=jpim),parameter :: rawbt_mwhs = 275 ! Raw brightness temperature specific to MWHS (K)
  integer(kind=jpim),parameter :: q2m = 281 ! 2m specific humidity
  integer(kind=jpim),parameter :: chem6 = 284 ! chem6: so2 volcanic
  integer(kind=jpim),parameter :: refrac = 301 ! refractivity (Dart/SPREADS)
end module ecmwf_varno_descr
