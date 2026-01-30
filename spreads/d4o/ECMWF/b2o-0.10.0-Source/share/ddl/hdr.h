//
// Table Definitions: hdr (header table)
//
CREATE TABLE hdr AS (
  seqno                  pk1int,              // OBSERVATION SEQUENCE
  subseqno               pk1int,              // OBSERVATION SEQUENCE for SUB-WINDOWS
  reportno               pk1int,              // report number, unique per pool (e.g. radiosonde profile)
  bufrtype               pk1int,              // BUFR-type
  subtype                pk1int,              // BUFR subtype for reference
  subsetno               pk9int,              // Multisubset number in BUFR-msg (=0 for single subset) useful for odb2bufr
// Local classification of observation
  groupid                pk1int,              // MARS key - Observation group
  reportype              pk1int,              // MARS key - report type for MAR
  obstype                pk1int,              // OBSERVATION TYPE
  codetype               pk1int,              // OBSERVATION CODE TYPE
  sensor                 pk1int,              // ECMWF SATELLITE LOCAL (RTTOV) SENSOR INDICATOR

  retrtype               pk1int,              // OBSERVATION RETRIEVAL TYPE

// to be removed? 
  instrument_type        pk1int,              // OBSERVATION INSTRUMENT TYPE

  stalt                  pk9real,             // ALTITUDE 


  date                   YYYYMMDD,            // OBS. DATE
  time                   HHMMSS,              // OBS. EXACT TIME
  rdbdate                YYYYMMDD,            // OBS. ARRIVAL/PROCESSING DATE
  rdbtime                HHMMSS,              // OBS. ARRIVAL/PROCESSING TIME

  distribtype            pk1int,              // type of distribution - default is 0 i.e. no redistribution
  distribid              pk1int,              // target pool when data is re-distributed (for instance on model grid)
  gp_dist                pk9real,             // DIST TO NEAREST GP - only if observations need to be distributed on model grid
  gp_number              pk1int,              // JROF - grid point number (on the local PE grid)
  numlev                 pk1int,              // No. of distinct pressure levels in bodies
  numactiveb             pk1int,              // No. of active body entries (i.e. status.active@body == 1)
  checksum               pk9real,             // A check sum of obsvalues where press & obsvalue is not NULL
  sortbox                pk1int,              // SORTING BOX
  areatype               pk1int,              // OBSERVATION AREA TYPE

  report_status          STATUS_t,            // REPORT'S STATUS
  report_event1          REPORT_EVENT1_t,     // REPORT'S EVENTS (PART 1)
  report_rdbflag         REPORT_RDBFLAG_t,    // REPORT'S FLAGS
  report_blacklist       REPORT_BLACKLIST_t,  // REPORT'S BLACKLIST EVENTS
  report_event2          REPORT_EVENT2_t,     // REPORT EVENTS (PART 2) WORD POS.

  thinningkey[$NUMTHBOX] pk9real,             // Thinning key
  thinningtimekey        pk9real,             // Thinning time key

// why do we have datastream, gen_centre + gen_subcentre in sat table??? They should be here, no?
  sitedep                pk1int,             // site dependent
  source                 string,             // Source ID of obs. (CHARACTER*8) : Reanalysis purposes

  lat                    pk9real,            // LATITUDE
  lon                    pk9real,            // LONGITUDE
  trlat                  pk9real,            // TRANSFORMED LAT. 
  trlon                  pk9real,            // TRANSFORMED LON.

  restricted             pk1int,             // Flag to identify observations with access restrictions (0 = no restrictions)

  modsurf                @LINK,              // Model surface fields, at observation points

  statid                 string,             // STATION ID (CHARACTER*8)
  wigosid[4]             string,             // WIGOS STATION ID (CHARACTER*32)

  conv                   @LINK,              // put here all ODB conventional for conventional data only
  sat                    @LINK,  
  body                   @LINK,  
  errstat                @LINK,             // errstat table to be cleaned...
  update[1:$NMXUPD]      @LINK,             // update tables to be cleaned...
  auxiliary              @LINK,             // only created if ODB_AUXILIARY=1
  ensemble               @LINK,             // one enkf or enda table per ensemble

  gbrad                  @LINK,             // ground-based radar
  raingg                 @LINK,             // rain gauges

  surfbody_feedback      @LINK,             // storage of feedbacks from the surface analysis

 // for subwindows
  window_offset          pk1int,  // use for subwindows to identify the subwindow 
);

