//
// Table Definitions: gnssro (header-like table)
//
CREATE TABLE gnssro AS (

// GNSSRO
  radcurv                            pk9real,        // RADIUS OF CURVATURE 
  undulation                         pk9real,        // UNDULATION AT OBS LOCATION  
  gnssro_body                        @LINK,  
);

// Filled by Meteo-France only
CREATE TABLE gnssro_body AS (
// GNSSRO
  obs_dndz              pk9real,                     // Vertical gradient of refractivity (dN/Dz in m-1) from the observation
  obs_refractivity      pk9real,                     // Refractivity observation
  bg_dndz               pk9real,                     // Vertical gradient of refractivity (dN/Dz in m-1) from the background
  bg_refractivity       pk9real,                     // Refractivity from the background
  bg_layerno            pk9real,                     // Background layer number in which the observation is found (1=layer
                                                     // immediately above the surface
  obs_tvalue            pk9real,                     // observed temperature
  obs_zvalue            pk9real,                     // observed geopotential height
  bg_tvalue             pk9real,                     // background temperature
);
