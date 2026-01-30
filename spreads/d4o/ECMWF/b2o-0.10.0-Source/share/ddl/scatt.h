//
// Table Definition: scatt table
//
CREATE TABLE scatt AS (
  cellno pk1int,                        // WAVE-VECTOR CELL NO.
  nretr_amb pk1int,                     // NUMBER OF RETRIEVED AMBIGUITIES
  prodflag pk1int,                      // ECMWF PRODUCT FLAG
  wvc_qf pk1int,                        // ORIGINAL WIND VECTOR CELL QUALITY FLAG
  scatt_body @LINK,  
);

CREATE TABLE scatt_body AS (
  azimuth pk9real,                      // BEAM AZIMUTH ANGLE
  incidence pk9real,                    // BEAM INCIDENCE ANGLE
  Kp pk9real,                           // Kp (INSTRUMENT NOISE; Antenna Noise)
  invresid pk9real,                     // WIND-INVERSION RESIDUAL
  dirskill pk9real,                     // DIRECTIONAL SKILL
  mpc pk1int,                           // MISSING PACKET COUNTER
  Kp_qf pk1int,                         // ASCAT Kp QUALITY FLAG
  ambig_select pk1int,                  // Selected ambiguous wind, bit indicates outer loop (NUPTRA)
  sigma0_qf pk1int,                     // SIGMA 0 USABILITY FLAG
  sigma0_sm pk9real,                    // EFFECTIVE SIGMA0 FOR SOIL MOISTURE
  soilmoist_sd pk9real,                 // SOIL MOISTURE STD ERROR
  soilmoist_cf  pk1int,                 // SOIL MOISTURE CORRECTION FLAG
  soilmoist_pf  pk1int,                 // SOIL MOISTURE PROCESSING FLAG
  land_fraction pk9real,                // ASCAT LAND FRACTION
  wetland_fraction pk9real,             // ASCAT WETLAND FRACTION
  topo_complex pk9real,                 // ASCAT TOPOGRAPHIC COMPLEXITY
  likelihood   pk9real,                 // likelihood computed in the model (added for MF)
);

