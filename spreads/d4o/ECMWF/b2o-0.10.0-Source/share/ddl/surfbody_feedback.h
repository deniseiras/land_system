//
// Table Definition: surface analysis feedback tables
//

CREATE TABLE surfbody_feedback AS (
  datum_status          TYPEOF(report_status@hdr),   // New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event       datum_sfc_event_t,           // OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar              pk9real,                     // OBSERVED MINUS ANALYSED VALUE
  fg_depar              pk9real,                     // OBSERVED MINUS FIRST GUESS VALUE
  snow_depth            pk9real,                     // model first-guess snow depth (m)
  snow_density          pk9real,                     // model first-guess snow density 
  lsm                   pk9real,                     // model land-sea mask
);

