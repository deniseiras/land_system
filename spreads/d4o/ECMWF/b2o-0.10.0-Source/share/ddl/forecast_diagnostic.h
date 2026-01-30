// Define forecast_diagnostic table
// Define up to $NMXFDIAG forecast_diagnostic-tables with
// the naming convention forecast_diagnostic_1 forecast_diagnostic_2, ..., forecast_diagnostic_<$NMXFDIAG>.
// Each of them has got exactly the same attributes.
// Note: It is up to the software to decide how many of these tables will
// actually be filled !!


CREATE TABLE fcdiagnostic AS (
  max_fcdiag        pk1int,               // number of forecast diagnostic valid for this experiment 
  fcdiagnostic_body[$NMXFCDIAG] @LINK,     // one table for each forecast departure to run in //
);

CREATE TABLE fcdiagnostic_body[1:$NMXFCDIAG] AS (
  fc_depar          pk9real,            // forecast departure
  fc_step           YYYYMMDD,            // Corresponding forecast step
);
