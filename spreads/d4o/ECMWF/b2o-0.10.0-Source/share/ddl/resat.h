//
// Table Definition: resat table
// contains ozone, aerosols, CO2, etc.
//
// retrtype@hdr = 1 when it contains averaging kernel 
// retrtype@hdr = 0 when it does not contain averaging kernel
SET $resat_retrtype_ak = 1; 
SET $resat_retrtype = 0;

-- The following depends on resat data, so watch for it!
SET $mx_ak = 50;                        // depends on jpmx_ak in module/parcma and bufr2odb_gch2.F90  and  varindex_module.F90!!
CREATE TABLE resat AS (
  instrument_type pk1int,               // SATELLITE INSTRUMENT
  product_type pk1int,                  // PRODUCT TYPE FOR RETRIEVED ATMOSPHERIC GASES
  lat_fovcorner[1:4] pk9real,           // LATITUDE FIELD OF VIEW CORNER 1-4
  lon_fovcorner[1:4] pk9real,           // LONGITUDE FIELD OF VIEW CORNER 1-4
  solar_elevation pk9real,              // SOLAR ELEVATION
  scanpos pk1int,                       // SCAN POSITION i.e. FIELD OF VIEW NUMBER
  cloud_cover pk9real,                  // CLOUD COVER
  cloud_top_press pk9real,              // PRESSURE AT TOP OF CLOUD
  quality_retrieval pk1int,             // QUALITY OF RETRIEVAL
  number_layers pk1int,                 // NUMBER OF RETRIEVED LAYERS
  resat_averaging_kernel @LINK,
  snow_ice_indicator pk1int,            // SNOW/ICE INDICATOR 
  surface_type_indicator pk1int,        // SURFACE TYPE 
  methane_correction pk9real,           // SCIAMACHY METHANE CORRECTION FACTOR
  surface_height pk9real,               // SURFACE HEIGHT
  retrsource pk1int,                    // SOURCE/ORIGINATOR OF RETRIEVED ATMOSPHERIC CONSTITUENT
);

CREATE TABLE resat_averaging_kernel AS (
  nak pk1int,                           // number of averaging kernel elements
  wak[$mx_ak] pk9real,                  // averaging kernel weights
  pak[$mx_ak] pk9real,                  // averaging kernel pressures
  apak[$mx_ak] pk9real,                 // averaging kernel prior profile
);


