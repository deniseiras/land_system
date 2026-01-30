//
// Type definitions
//

CREATE TYPE report_rdbflag_t AS (
  lat_humon bit1,  
  lat_QCsub bit1,  
  lat_override bit1,  
  lat_flag bit2,  
  lat_HQC_flag bit1,  
  lon_humon bit1,  
  lon_QCsub bit1,  
  lon_override bit1,  
  lon_flag bit2,  
  lon_HQC_flag bit1,  
  date_humon bit1,  
  date_QCsub bit1,  
  date_override bit1,  
  date_flag bit2,  
  date_HQC_flag bit1,  
  time_humon bit1,  
  time_QCsub bit1,  
  time_override bit1,  
  time_flag bit2,  
  time_HQC_flag bit1,  
  stalt_humon bit1,  
  stalt_QCsub bit1,  
  stalt_override bit1,  
  stalt_flag bit2,  
  stalt_HQC_flag bit1,  
  roll_angle_quality bit1,  
);

CREATE TYPE status_t AS (
  active bit1,                          // ACTIVE FLAG
  passive bit1,                         // PASSIVE FLAG
  rejected bit1,                        // REJECTED FLAG
  blacklisted bit1,                     // BLACKLISTED
  use_emiskf_only bit1,                 // to be used for emiskf only
);

CREATE TYPE datum_rdbflag_t AS (
  press_humon bit1,  
  press_QCsub bit1,  
  press_override bit1,  
  press_flag bit2,  
  press_HQC_flag bit1,  
  press_judged_prev_an bit2,  
  press_used_prev_an bit1,  
  _press_unused_6 bit6,  
  varno_humon bit1,  
  varno_QCsub bit1,  
  varno_override bit1,  
  varno_flag bit2,  
  varno_HQC_flag bit1,  
  varno_judged_prev_an bit2,  
  varno_used_prev_an bit1,  
//  _varno_unused_6 bit6,  
);

CREATE TYPE datum_flag_t AS (
  final bit4,                           // FINAL FLAG
  fg bit4,                              // FIRST GUESS FLAG
  depar bit4,                           // DEPARTURE FLAG
  varQC bit4,                           // VARIATIONAL QUALITY FLAG
  blacklist bit4,                       // BLACKLIST FLAG
  ups bit1,                             // d'utilisation par analyse de pression de surface
  uvt bit1,                             // d'utilisation par analyse de vent et temperature
  uhu bit1,                             // d'utilisation par analyse d'humidite
  ut2 bit1,                             // d'utilisation par analyse de temperat ure a 2m
  uh2 bit1,                             // d'utilisation par analyse d'humidite a 2m
  uv1 bit1,                             // d'utilisation par analyse de vent a 10m
  urr bit1,                             // d'utilisation par analyse de precipitations
  usn bit1,                             // d'utilisation par analyse de neige
  usst bit1,                            // d'utilisation par analyse de temperature de surface de la mer
);

CREATE TYPE level_t AS (
  //id bit9,                              // PILOT LEV. ID.
  maxwind bit1,                         // MAX WIND LEVEL
  tropopause bit1,                      // TROPOPAUSE 
  D_part bit1,                          // D PART
  C_part bit1,                          // C PART
  B_part bit1,                          // B PART
  A_part bit1,                          // A PART
  surface bit1,                         // SURFACE LEVEL
  signwind bit1,                        // SIGNIFICANT WIND LEVEL
  signtemp bit1,                        // SIGNIFICANT TEMPR. LEVEL
);

CREATE TYPE report_event1_t AS (
  no_data bit1,                         // no data in the report
  all_rejected bit1,                    // all data rejected
  bad_practice bit1,                    // bad reporting practice
  rdb_rejected bit1,                    // rejected due to RDB flag
  redundant bit1,                       // redundant report
  stalt_missing bit1,                   // missing station altitude
  QC_failed bit1,                       // failed quality control
  overcast_ir bit1,                     // report overcast IR
  thinned bit1,                         // wvc thinned out
  latlon_corrected bit1,                // position corrected using station database value
  stalt_corrected bit1,                 // station altitude corrected using station database value
);

CREATE TYPE report_event2_t AS (        // bits are obstype dependent
);

CREATE TYPE report_blacklist_t AS (
  obstype bit1,  
  statid bit1,  
  codetype bit1,  
  instype bit1,  
  date bit1,  
  time bit1,  
  lat bit1,  
  lon bit1,  
  stalt bit1,
  scanpos bit1,  
  retrtype bit1,  
  QI_fc bit1,  
  RFF bit1,  
  QI_nofc bit1,  
  modoro bit1,  
  lsmask bit1,  
  rlsmask bit1,  
  modPS bit1,  
  modTS bit1,  
  modT2M bit1,  
  modtop bit1,
  sensor bit1,
  fov bit1,
  satza bit1,
  andate bit1,
  antime bit1,
  solar_elevation bit1,
  quality_retrieval bit1,
  cloud_cover bit1,
  cloud_top_pressure bit1,
  product_type bit1,
  sonde_type  bit1,
);

CREATE TYPE datum_event1_t AS (
  vertco_missing bit1,               // missing vertical coordinate
  obsvalue_missing bit1,             // missing observed value
  fg_missing bit1,                   // missing first guess value
  rdb_rejected bit1,                 // rejected due ti RDB flag
  assim_cld_flag bit1,               // assim of cloud-affected radiance
  bad_practice bit1,                 // bad reporting practice
  vertpos_outrange bit1,             // vertical position out of range
  fg2big bit1,                       // too big first guess departure
  depar2big bit1,                    // too big departure in assimilation
  obs_error2big bit1,                // too big observation error
  datum_redundant bit1,              // redundant datum
  level_redundant bit1,              // redundant level
  not_analysis_varno bit1,           // not an analysis variable
  duplicate bit1,                    // duplicated datum/level
  levels2many bit1,                  // too many surface data/levels
  level_selection bit1,              // level selection
  vertco_consistency bit1,           // vertical consistency check
  vertco_type_changed bit1,          // vertical coordinate changed from Z to P
  combined_flagging bit1,            // combined flagging
  report_rejected bit1,              // datum rejected due to rejected report
  varQC_performed bit1,              // variational QC performed
  obserror_increased bit1,           // obs error increased
  contam_cld_flag bit1,              // cloud contamination
  contam_rain_flag bit1,             // rain contamination
  contam_aerosol_flag bit1,          // aerosol contamination
  bad_emissivity bit1,               // missing or not sensible emissivity values
  model_cld_flag bit1,               // model cloud		       
  contam_trgas_flag bit1,            // trace gas contamination
  land_sensitivity bit1,             // channel sensitive to land
);

CREATE TYPE datum_event2_t AS (      // bits are obstype dependent
);

CREATE TYPE datum_sfc_event_t AS (
  statid bit1,                       // bad statid (blacklisted, etc.)
  lsmask bit1,                       // rejection due to land-sea mask
  stalt_missing bit1,                // missing station altitude
  obsvalue_missing bit1,             // missing observed value
  fg_missing bit1,                   // missing first guess value
  fg2big bit1,                       // too big first guess departure
  not_analysis_varno bit1,           // not an analysis variable
  redundant bit1,                    // redundant report
  report_rejected bit1,              // datum rejected due to rejected report
);

CREATE TYPE datum_blacklist_t AS (
  varno bit1,  
  vertco_type bit1,  
  press bit1,  
  press_rl bit1,  
  ppcode bit1,
  obsvalue bit1,  
  fg_depar bit1,  
  obs_error bit1,  
  fg_error bit1,  
  winchan_dep bit1,
  obs_t bit1,
  elevation bit1,
  winchan_dep2 bit1,
  tausfc bit1,
  csr_pclear bit1,
);

CREATE TYPE aeolus_hdrflag_t AS ( 
  nadir_location    bit1, //  bit#0 = 1 for location at nadir (calibration mode)
  orbit_predicted   bit1, //      1         location from orbit predictor
  omit_from_EE      bit1, //      2         predicted location to omit from EE product
);
