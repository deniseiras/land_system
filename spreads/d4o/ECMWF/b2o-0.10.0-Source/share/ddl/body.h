//
// Table Definition: body table
//
CREATE TABLE body AS (
  entryno               pk1int,                      // ENTRY SQ. NO. 
  obsvalue              pk9real,                     // OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  varno                 pk1int,                      // VARIABLE NUMBER
  vertco_type           pk1int,                      // VERTICAL COORDINATE TYPE
  vertco_reference_1    pk9real,                     // VERTICAL COORDINATE REFERENCE 1
  vertco_reference_2    pk9real,                     // VERTICAL COORDINATE REFERENCE 2

// DATUM flags
  datum_anflag          DATUM_FLAG_t,                // OBSERVATION FLAGS
  datum_status          TYPEOF(report_status@hdr),   // New feature; equivalent to old def : "status STATUS_t"
  datum_event1          DATUM_EVENT1_t,              // OBSERVATION EVENTS (PART 1)
  datum_rdbflag         DATUM_RDBFLAG_t,             // OBSERVATION FLAGS (RDB)
  datum_blacklist       DATUM_BLACKLIST_t,           // OBSERVATION BLACKLIST EVENTS
  datum_event2          DATUM_EVENT2_t,              // DATUM EVENTS (PART 2) WORD POS.


  varbc_ix              pk1int,                      // VarBC group index
  biascorr              pk9real,                     // RADIANCE BIAS CORRECTION
  biascorr_fg           pk9real,                     // FG bias correction
  tbcorr                pk9real,                     // Correction to Brightness temperature (radiance only)
  bias_volatility       pk9real,                     // Estimated volatility of the observation bias
  wdeff_bcorr           pk9real,                     // Wind-induced error bias correction for rain gauges

  an_depar              pk9real,                     // OBSERVED MINUS ANALYSED VALUE
  fg_depar              pk9real,                     // OBSERVED MINUS FIRST GUESS VALUE
  actual_depar          pk9real,                     // We store the actual departure during the minimization
  actual_ndbiascorr     pk9real,                     // Store the actual normalised bias difference during minimisation
  qc_a                  pk9real,                     // VAR QC prior probability of gross error (by variable and obstype) 
  qc_l                  pk9real,                     // VAR QC width of the distribution
  qc_pge                pk9real,                     // VAR QC a posteriori probability of gross error
 
  fc_sens_obs           pk9real,                     // forecast sensitivity to the observations
  an_sens_obs           pk9real,                     // analysis sensitivity to the obs

  jacobian_peak         pk9real,  // used for ENKF; to move to radiance_body and gnssro_body
  jacobian_peakl        pk9real, // used for ENKF; to move to radiance_body and gnssro_body
  jacobian_hpeak        pk9real, // used for ENKF; to move to radiance_body and gnssro_body
  jacobian_hpeakl       pk9real, // used for ENKF; to move to radiance_body and gnssro_body


  mf_vertco_type        pk1int,                      // vertical coordinate type
  mf_log_p              pk9real,                     // pressure used in CANARI (Log P)
  mf_stddev             pk9real,                     // obs. std dev at bottom layer

// for resat data only
  nlayer                pk1int,                      // layer number used in resat varbc  

);

