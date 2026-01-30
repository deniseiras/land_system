// The following declares up to $NMXUPD update-tables with
// the naming convention update_1, update_2, ..., update_<$NMXUPD>.
// Each of them has got exactly the same attributes.
// Note: It is up to the software to decide how many of these tables will
// actually be filled !!

// To be cleaned!!! These table should be used to make sure we can restart an IFS task
// without having to store the entire CCMA/ECMAs.
CREATE TABLE update[1:$NMXUPD] AS (
  hires pk9real,               // OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               // OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         // Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires  TYPEOF(report_status@hdr), // Status flag at hires (for backup to avoid CCMA copy)
  obs_diags[1:3] pk9real,      // Diagnostics in observation space (Yannick - Note: hardcoded #3 ;-()
);

