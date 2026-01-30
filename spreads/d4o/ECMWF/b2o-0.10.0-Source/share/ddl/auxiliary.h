//
// Table Definition: auxiliary tables
//
CREATE TABLE auxiliary AS (
// only exist if LAUXILIARY
// temporary table (auxiliary) which is never archived

  report_aux[$NUMAUX]          pk9real,                     // Auxiliary header-like entries; 
  auxiliary_body               @LINK,
);

CREATE TABLE auxiliary_body AS (
// only exist if LAUXILIARY
// temporary table (auxiliary) which is never archived
  datum_aux[$NUMAUX]          pk9real,                     // Auxiliary body-like entries;
);


