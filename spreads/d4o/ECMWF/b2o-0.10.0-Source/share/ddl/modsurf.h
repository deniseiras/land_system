//
// Table Definition: modsurf tables
//

CREATE TABLE modsurf AS (
  lsm                pk9real,     // model land-sea mask
  seaice             pk9real,     // model sea-ice  mask
  orography          pk9real,     // model orography 
  snow_depth         pk9real,     // model snow depth (m)
  t2m                pk9real,     // 2m temperature
  albedo             pk9real,     // albedo
  windspeed10m       pk9real,     // 10 metre wind speed
  u10m               pk9real,     // 10 metre U wind component
  v10m               pk9real,     // 10 metre V wind component
  surface_class      pk1int,      // surface type (used for radiances only; see satrad/emiss/amsu_sfc.F90)
  tsfc               pk9real,     // model skin temperature (used for some radiances only)
);

