//
// Table Definition: raingg tables
//
CREATE TABLE raingg AS (
  report_rrflag           pk1int,       // Rain Rate status flag - See yomraingg.F90
  raingg_body              @LINK,
);

CREATE TABLE raingg_body AS (
  rrvalue                 pk9real,       // Simulated rain rates
  rrvaluetl               pk9real,       // Simulated TL of rain rates
  rrvaluead               pk9real,       // Simulated AD of rain rates
);

