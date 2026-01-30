//
// Table Definition: gbrad tables
//
CREATE TABLE gbrad AS (
  report_rrflag           pk1int,       // Rain Rate status flag - See yomgbrad.F90
  gbrad_body              @LINK,
);

CREATE TABLE gbrad_body AS (
  rrvalue                 pk9real,       // Simulated rain rates
  rrvaluetl               pk9real,       // Simulated TL of rain rates
  rrvaluead               pk9real,       // Simulated AD of rain rates
);

