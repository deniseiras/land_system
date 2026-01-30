//
// Table Definition: cloud_sink tables
//
CREATE TABLE cloud_sink AS (
// only created if LCLDSINK is TRUE
  ctop[$NMXUPD]    pk9real,      // CTOP per NRESUPD
  camt[$NMXUPD]    pk9real,      // Camt per NRESUPD
  ctopbg           pk9real,      // CTOP BACKGROUND
  ctoper           pk9real,      // CTOP BACKGROUND ERROR
  ctopinc          pk9real,      // CTOP INCREMENT 
  camtbg           pk9real,      // CAMT BACKGROUND
  camter           pk9real,      // CAMT BACKGROUND ERROR
  camtinc          pk9real,      // CAMT INCREMENT 
);

