// To be cleaned. 
CREATE TABLE errstat AS (
  final_obs_error pk9real,              // FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                    // Prescribed observation error
  repres_error pk9real,                 // REPRESENTATIVENESS ERROR
  pers_error pk9real,                   // PERSISTENCE ERROR
  fg_error pk9real,                     // FIRST GUESS ERROR
  eda_spread pk9real,                   // SPREAD FROM EDA

// very specific to resat... why everybody has it?
  obs_ak_error pk9real,                 // OBSERVATION ERROR WITHOUT CONTRIBUTION FROM PROFILE ERROR

  obs_corr_ev[$NUMEV] pk9real,          // OBS. ERR. CORRELATION EIGENVECTORS
  obs_corr_mask pk1int,                 // OBS. ERROR CORRELATION MASK

  obs_corr_diag[$NUMDIAG] pk9real,      // OBS. ERR. CORRELATION DIAGNOSTICS
);

