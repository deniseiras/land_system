//
// Table Definition: satob table
//

CREATE TABLE satob AS (
  comp_method pk1int,                   // CLOUD MOTION COMP. METHOD
  instdata pk1int,                      // INS. DATA USED IN PROC.
  dataproc pk1int,                      // DATA PROC. TECHNIQUE USED
  QI_fc pk1int,                         // EUMETSAT Quality Indicators: with forecast dependence
  QI_nofc pk1int,                       // EUMETSAT Quality Indicators: without forecast dependence
  RFF pk1int,                           // CIMSS Quality Indicator: Recursive Filter Flag
  EE pk9real,                           // Expected Error [m/s]
  segment_size_x pk9real,               // RESOLUTION, x-direction
  segment_size_y pk9real,               // RESOLUTION, y-direction
  chan_freq pk9real,                    // Satellite Channel Centre Frequency [Hz] (02197) for subtype=87 only
  tb pk9real,                           // Coldest cluster temperature
  t pk9real,                            // Temperature at SATOB p
  shear pk9real,                        // Diff. in speed 50hPa above/below
  t200 pk9real,                         // 200 hPa temperature
  t500 pk9real,                         // 500 hPa temperature
  top_mean_t pk9real,                   // Mean temperature between 80 hPa & p
  top_wv pk9real,                       // Integrated WV above p
  dt_by_dp pk9real,                     // Diff in temp. 50hPa above/below
  p_best pk9real,                       // "Best fit" pressure
  u_best pk9real,                       // U at "best fit" pressure
  v_best pk9real,                       // V at "best fit" pressuree
  dd_best pk9real,                      // wind direction at "best fit" pressure
  ff_best pk9real,                      // wind speed at "best fit" pressure
  p_old pk9real,                        // Originally assigned pressure
  u_old pk9real,                        // U at old pressure
  v_old pk9real,                        // V at old pressure
  height_assignment_method pk1int,      // Height assignment method ( bufr code table 002231)
  tracer_correlation_method pk1int,     // Tracer correlation method( bufr code table 002232)
  land_sea pk1int,                      // Land/sea qualifier( bufr code table 008012)
  tracking_error_u pk9real,             // Error in u due to AMV tracking (m/s)
  tracking_error_v pk9real,             // Error in v due to AMV tracking (m/s)
  h_assignment_error_u pk9real,         // Error in u due to to height assignment error (m/s)
  h_assignment_error_v pk9real,         // Error in v due to to height assignment error (m/s)
  error_in_h_assignment pk9real,        // Error in height assignment (Pa)
  ct_p pk9real,                         // Cloud top pressure
  cb_p pk9real,                         // Cloud base pressure
  umod_old pk9real,                     // Model u at old pressure
  vmod_old pk9real,                     // Model v at old pressure
);

