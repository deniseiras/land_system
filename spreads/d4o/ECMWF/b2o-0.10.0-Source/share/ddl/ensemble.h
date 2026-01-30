// Define up to $NMXENKF enkf-tables with
// the naming convention enkf_1 enkf_2, ..., enkf_<$NMXENKF>.
// Each of them has got exactly the same attributes.
// Note: It is up to the software to decide how many of these tables will
// actually be filled !!

CREATE TABLE ensemble AS (
 nensemble                            pk1int,   // Number of members active (<=$NMXENKF or <=$NMXENDA
 enkf[1:$NMXENKF]                      @LINK,
 enda[1:$NMXENDA]                      @LINK,       // one table for each member
 surfbody_feedback[1:$NMXENDA]         @LINK,       // one table for each member
);

CREATE TABLE enkf[1:$NMXENKF] AS (
  member          pk1int,             // enkf-member number
  hprior          pk9real,            // H(x)
);
// Define up to $NMXENDA enda-tables with
// the naming convention enda_1, enda_2, ..., enda_<$NMXENDA>.
// Each of them has got exactly the same attributes.
// Note: It is up to the software to decide how many of these tables will
// actually be filled !!

CREATE TABLE enda[1:$NMXENDA] AS (
  member                pk1int,                      // enda-member number
  report_status         STATUS_t,                    // REPORT'S STATUS
  report_event1         REPORT_EVENT1_t,             // REPORT'S EVENTS (PART 1)
  obsvalue              pk9real,                     // OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag          DATUM_FLAG_t,                // OBSERVATION FLAGS
  datum_status          TYPEOF(report_status@hdr),   // New feature; equivalent to old def : "status STATUS_t"
  datum_event1          DATUM_EVENT1_t,              // OBSERVATION EVENTS (PART 1)
  biascorr              pk9real,                     // RADIANCE BIAS CORRECTION
  biascorr_fg           pk9real,                     // FG bias correction
  an_depar              pk9real,                     // OBSERVED MINUS ANALYSED VALUE
  fg_depar              pk9real,                     // OBSERVED MINUS FIRST GUESS VALUE
  qc_pge                pk9real,                     // VAR QC a posteriori probability of gross error
  final_obs_error       pk9real,                     // FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error             pk9real,                     // Prescribed observation error
  fg_error              pk9real,                     // FIRST GUESS ERROR
  skintemp[$NMXUPD+1]   pk9real,                     // skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
);

CREATE TABLE surfbody_feedback[1:$NMXENDA] AS (
  datum_status          TYPEOF(report_status@hdr),   // New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event       datum_sfc_event_t,           // OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar              pk9real,                     // OBSERVED MINUS ANALYSED VALUE
  fg_depar              pk9real,                     // OBSERVED MINUS FIRST GUESS VALUE
  snow_depth            pk9real,                     // model first-guess snow depth (m)
  snow_density          pk9real,                     // model first-guess snow density 
  lsm                   pk9real,                     // model land-sea mask
);

