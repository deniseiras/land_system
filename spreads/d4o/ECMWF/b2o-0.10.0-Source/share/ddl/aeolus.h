//
// Table Definition: aeolus tables
//

// aeolus header table, things that don't change at measurement level
CREATE TABLE aeolus_hdr AS (
  aeolus_hdrflag aeolus_hdrflag_t,      // Aeolus header flags

  aeolus_auxmet @LINK, 

  aeolus_l2c @LINK, 

  aeolus_l2b @LINK,
);

// table for auxiliary meteorological data
CREATE TABLE aeolus_auxmet AS (
  lev           pk9real,              // Model level (zero for surface values)
  ptop          pk9real,              // Pressure at top of layer
  pnom          pk9real,              // Nominal pressure within layer
  ztop          pk9real,              // Geopotential height at top of layer
  znom          pk9real,              // Nominal geopotential height within layer
  u             pk9real,              // Uwind
  v             pk9real,              // Vwind
  t             pk9real,              // Temperature
  rh            pk9real,              // Relative humidity
  q             pk9real,              // Specific humidity
  cc            pk9real,              // Cloud cover
  clwc          pk9real,              // Cloud liquid water content
  ciwc          pk9real,              // Cloud ice water content
  error_t       pk9real,              // Error estimate for temperature
  error_rh      pk9real,              // Error estimate for relative humidity
  error_p       pk9real,              // Error estimate for pressure
);

// table for Level 2C products
CREATE TABLE aeolus_l2c AS (
  hlos_ob_err   pk9real,              // Final HLOS obs error
  hlos_fg       pk9real,              // HLOS from first guess
  u_fg          pk9real,              // First guess zonal wind
  u_fg_err      pk9real,              // u component first guess error
  v_fg          pk9real,              // First guess meridional wind
  v_fg_err      pk9real,              // v component first guess error
  hlos_fg_err   pk9real,              // HLOS err from first guess
  hlos_an       pk9real,              // HLOS from analysis
  hlos_an_err   pk9real,              // HLOS err from analysis
  u_an          pk9real,              // Analysis zonal wind
  v_an          pk9real,              // Analysis meridional wind
);

// table for Level 2B meta data
CREATE TABLE aeolus_l2b AS (
  t_ref         pk9real,              // Reference temperature used in retrieval
  p_ref         pk9real,              // Reference pressure used in retrieval
  beta          pk9real,              // Scattering ratio for observation
  dhlos_dt      pk9real,              // Derivative of HLOS wind wrt temperature
  dhlos_dp      pk9real,              // Derivative of HLOS wind wrt pressure
  dhlos_dbeta   pk9real,              // Derivative of HLOS wind wrt scattering ratio
  horiz_length  pk9real,              // Observation horizontal length-scale
  vert_length   pk9real,              // Observation vertical length-scale
  conf_flag     pk1int,               // Confidence flag
);



