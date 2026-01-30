//
// Table Definitions: sat (header-like satellite table)
//
CREATE TABLE sat AS (
  satellite_identifier pk1int,     // WMO Satellite platform identifier
  satellite_instrument pk1int,     // WMO Satellite instrument on board

  zenith               pk9real,    // SATELLITE INSTRUMENT ZENITH ANGLE 
  azimuth              pk9real,    // SATELLITE INSTRUMENT AZIMUTH ANGLE
  solar_zenith         pk9real,    // SOLAR ZENITH ANGLE 
  solar_azimuth        pk9real,    // SOLAR AZIMUTH ANGLE
  range                pk9real,    // Range (distance) from satellite to observed volume
  arg_lat              pk9real,    // Argument of latitude; angle from ascending node to satellite's position
  lsm_fov              pk9real,    // LSM OF FOV

// Why for satellite only?
  gen_centre           pk1int,     // WMO Generating Centre
  gen_subcentre        pk1int,     // WMO Generating sub-centre
  datastream           pk1int,     // Datastream

  radiance             @LINK,      // Radiance table  (entry point for all atmospheric radiances)
  resat                @LINK,      // Retrieval of satellite data (ozone, co2, aerosols, etc.).
  gnssro               @LINK,      // gnssro table 
  satob                @LINK,      // satob winds
  limb                 @LINK,      // For 2D observation operators?
  ssmi                 @LINK,      // obsolete table for 1DVAR. Will be removed...
  smos                 @LINK,      // smos satellite 
  scatt                @LINK,      // Scatterometer satellite
  aeolus_hdr           @LINK,      // Aeolus table
  radar_station        @LINK,      // ??? Meteo-France specific
  radar                @LINK,      // ??? Meteo-France specific
);

