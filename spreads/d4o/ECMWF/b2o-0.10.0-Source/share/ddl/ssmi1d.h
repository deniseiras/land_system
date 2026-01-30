//
// Table Definition: ssmi1d tables
// These tables were used when ssmi data were assimilated with 1DVAR algorithm
// Currently obsolete
//
CREATE TABLE ssmi AS (
  iterno_conv_1dvar pk1int,         // NO. OF ITERATIONS 
  simno_conv_1dvar pk1int,          // NO. OF SIMULATIONS 
  failure_1dvar pk1int,             // FAILURE INDICATOR
  epsg_1dvar pk9real,               // 1D VAR CONVERGENCE CRITERION
  minim_status_1dvar pk1int,        // 1D VAR MINIMISATION STATUS
  surfpress[1] pk9real,             // from slev, SFC PRESSURE
  skintemp[1] pk9real,              // from slev, SKIN TEMPERATURE
  u10m[2] pk9real,                  // from slev, U-WIND 10M
  v10m[2] pk9real,                  // from slev, V-WIND 10M
  prec_st[2] pk9real,               // new      , SFC STRAT. PRECIP.
  prec_cv[2] pk9real,               // new      , SFC CONV. PRECIP.
  cost pk9real,                     // Ratio of cost functions Jo/Jo_n
  sfc_rain_3d_fg pk9real,           // Rain at FG from 3D model
  sfc_snow_3d_fg pk9real,           // ditto snow
  sfc_rain_3d_an pk9real,           // Rain at 4D-Var analysis from 3D model
  sfc_snow_3d_an pk9real,           // ditto snow  
  rwp[4] pk9real,                   // Rain, snow, cloud water and cloud ice paths [kg m^-2]
  swp[4] pk9real,                   // ???
  cwp[4] pk9real,                   // ???
  iwp[4] pk9real,                   // ???
  ssmi_body @LINK,  
);

CREATE TABLE ssmi_body AS (
  tcwv_fg pk9real,         // TCWV OBS -> MDB1BPWS  Used for 1D only 

  tcwv_fg_err pk9real,     // TCWV FG  -> MDB1DREP
  radcost pk9real,         // 1D VAR RADIANCE COST 
  rad_obs      pk9real,    // new, RADIANCE OBSERVATION
  rad_fg_depar pk9real,    // new, RADIANCE FG DEPARTURE
  rad_an_depar pk9real,    // new, RADIANCE AN DEPARTURE
  rad_obs_err  pk9real,    // new, RADIANCE OBS. ERROR
  rad_bias     pk9real,    // new, RADIANCE BIAS
  rad_fg_3d    pk9real,    // new, RADIANCES AT FG USING 3D MODEL CLOUDS
  rad_4dan     pk9real,    // new, RADIANCES AT 4D AN USING 3D MODEL CLOUDS

  frequency pk9real,       // CHANNEL CENTRE FREQUENCY
  bandwidth pk9real,       // CHANNEL BAND WIDTH
  polarisation pk9real,    // ANTENNA POLARISATION

  press pk9real,           // from mlev, PRESSURE
  temp[2] pk9real,         // from mlev, TEMPERATURE
  q[2] pk9real,            // from mlev, SPEC. HUMIDITY
  rain[2] pk9real,         // new      , LIQUID PRECIP FLUX
  snow[2] pk9real,         // new      , FROZEN PRECIP FLUX.
);

