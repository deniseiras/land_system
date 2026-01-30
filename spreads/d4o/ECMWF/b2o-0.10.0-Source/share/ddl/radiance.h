//
// Table Definitions: radiance (header-like table for all radiances)
//
CREATE TABLE radiance AS (
  scanline                                     pk1int,   // Scan line number
  scanpos                                      pk1int,   // Position number along scan / Field of View number
  orbit                                        pk1int,   // Orbit number
  typesurf                                     pk1int,   // Type of surface
  corr_version                                 pk1int,   // non linear correction version (a set of coefficients for each version)
  cldcover                                     pk1int,   // CLOUD PERCENTAGE FROM VISNIR FOR AIRS
  cldptop[1:3]                                 pk9real,  // CLOUD TOP PRESS. FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldne[1:3]                                   pk9real,  // CLOUD EMISSIVITY FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  skintemper                                   pk9real,  // skin temperture background error 
  skintemp[$NMXUPD+1]                          pk9real,  // skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  scatterindex_89_157                          pk9real,  // Scatter index from 89 and 157 GHz channels
  scatterindex_23_89                           pk9real,  // Scatter index from 23 and 89 GHz channels
  scatterindex_23_165                          pk9real,  // Scatter index from 23 and 165 GHz channels
  lwp_obs                                      pk9real,  // Regression-based liquid water path from observations

  asr_pclear                                   pk1int,   // All-sky AMOUNT SEGMENT CLOUD FREE ASR RADIANCES
  asr_pcloudy                                  pk1int,   // All-sky CLOUD AMOUNT IN SEGMENT ASR RADIANCES
  asr_pcloudy_low                              pk1int,   // All-sky CLOUD AMOUNT IN SEGMENT LOW-CLOUDS
  asr_pcloudy_middle                           pk1int,   // All-sky CLOUD AMOUNT IN SEGMENT MIDLE-CLOUDS
  asr_pcloudy_high                             pk1int,   // All-sky CLOUD AMOUNT IN SEGMENT HIGH-CLOUDS
// Children tables
  allsky                                       @LINK,    // allsky/mwave processing
  cloud_sink                                   @LINK,    // processing of cloud sink variables, still unclear...
  collocated_imager_information                @LINK,    // specific entries (from bufr2odb) for IASI - for post-processing only
  radiance_body                                @LINK,    // specific entries for all radiances boody-like table
);


CREATE TABLE radiance_body AS(
  csr_pclear        pk9real,      // Percentage of clear pixels in mean CSR
  cld_fg_depar      pk9real,      // FG departure for cloudy radiances
  rank_cld          pk9real,      // channel ranking for cloud detection for AIRS and IASI only.
  tausfc            pk9real,      // Surface transmittance for radiances - to be moved to radiance_body table
  skintemp_retr     pk9real,      // Skin temperature retrieved from observations, emissivity atlas and FG
  tbclear           pk9real,      // Diagnostic clear-sky FG brightness temperature

  emis_rtin         pk9real,      // Input surface emissivity for RTTOV (can be outside 0-1 to prompt internal calculations)
  emis_atlas        pk9real,      // Surface emissivity estimate from an atlas
  emis_atlas_error  pk9real,     // Error in surface emissivity estimate from an atlas
  emis_retr         pk9real,      // Surface emissivity retrieved from observations and FG
  emis_fg           pk9real,      // Surface emissivity used in FG simulations (pre-set or RTTOV-internal)
  cold_nedt         pk9real,      //  NOISE-EQUIVALENT DELTA TEMPERATURE WHILE VIEWING COLD TARGET
  warm_nedt         pk9real,      //  NOISE-EQUIVALENT DELTA TEMPERATURE WHILE VIEWING COLD TARGET
  channel_qc        pk1int,       //  Channel quality 12 bits
  nobs_averaged     pk1int,       // number of obs. used for averaging obsvalues (mask can be 2x2, 3x3, etc.)
  stdev_averaged    pk9real,      // Standard deviation of averaged values
  zenith_by_channel pk9real,      // Satellite zenith angle (if variable by channel, rarely, some microwave imagers, e.g. GMI)
  dust_aod_ir       pk9real,      // AOD for IR instrument at 10 micron (AIRS, IASI, CrIS)
);

