//
//  Data layout (schema) for CY37R3 : 
//
//   ECMA & CCMA table hierarchy:
//
//      1  desc
//      2  +---> poolmask
//      3  +---> timeslot_index
//      4  |     +---> index
//      5  |     |     +---> hdr
//      6  |     |     |     +---> sat
//      7  |     |     |     |     +---> radiance
//      8  |     |     |     |     |     +---> allsky
//      9  |     |     |     |     |           +---> allsky_body
//     11  |     |     |     |     |     +---> cloud_sink
//     12  |     |     |     |     |     +---> radiance_body
//     14  |     |     |     |     |     +---> collocated_imager_information
//     15  |     |     |     |     +---> resat
//     16  |     |     |     |     |     +---> resat_averaging_kernel
//     17  |     |     |     |     +---> gnssro
//     18  |     |     |     |     |     +---> gnssro_body
//     19  v     v     v     v     +---> satob
//     20  |     |     |     |     +---> scatt
//     21  |     |     |     |     |     +---> scatt_body
//     22  |     |     |     |     +---> ssmi
//     23  |     |     |     |     |     +---> ssmi_body
//     24  |     |     |     |     +---> limb
//     25  |     |     |     |     +---> aeolus_hdr
//     26  |     |     |     |     |     +---> aeolus_auxmet
//     27  |     |     |     |     |     +---> aeolus_l2c
//     28  |     |     |     |     |     +---> aeolus_l2b
//     29  |     |     |     |     +---> radar_station
//     30  |     |     |     |     +---> radar            
//     31  |     |     |     |     |     +---> radar_body 
//     32  |     |     !     !     +---> smos
//     33  |     |     |     +---> body
//     34  |     |     |     +---> auxiliary
//     35  |     |     |     +---> errstat
//     36  |     |     |     +---> update_1
//     37  |     |     |     +---> update_2
//     38  |     |     |     +---> update_3
//
// Variables
//

#ifndef ODB_NMXUPD
SET  $NMXUPD  = 10; // Maximum number of updates supported with this layout (min = 1 & max = 10)
#endif

#ifdef ODB_NMXUPD
SET  $NMXUPD = ODB_NMXUPD; // Maximum number of updates supported with this layout (min = 1 & max = 10)
#endif


#ifdef ODB_NMXENKF
SET  $NMXENKF  = ODB_NMXENKF; // Maximum number of ensembles
#endif

#ifndef ODB_NMXENKF
SET  $NMXENKF  = 120; // Maximum number of ensembles
#endif

#ifdef ODB_NMXENDA
SET  $NMXENDA  = ODB_NMXENDA; // Maximum number of ensembles
#endif

#ifndef ODB_NMXENDA
SET  $NMXENDA  = 100; // Maximum number of ensembles
#endif

SET  $NMXFCDIAG  = 20; // Maximum number of forecast diagnostics

SET  $NUMAUX = 9; // No. of auxiliary obsvalue's per body; aux1 ==> aux[$NUMAUX]
SET  $NUMTHBOX = 3; // No. of thinning boxes (see also ifs/module/yomdb.F90)
SET  $NUMEV = 1;  // Maximum number of retained eigenvectors of obs. err. corr. matrix
SET  $NUMDIAG = 1;  // Maximum number of retained diagnostics of obs. err. corr. matrix (must be the same as JP_NUMDIAG in yomdb.h)

// Aligned tables (contain the same no. of rows when requested over the @LINK)
RESET ALIGN;
ALIGN(body,surfbody_feedback);
ALIGN(body,errstat,update[1:$NMXUPD],fcdiagnostic_body[1:$NMXFCDIAG],conv_body, scatt_body,ssmi_body,gbrad_body, radar_body,resat_averaging_kernel, auxiliary_body, allsky_body, radiance_body, gnssro_body, raingg_body);
ALIGN(body,enkf[1:$NMXENKF]);
ALIGN(body,enda[1:$NMXENDA]);
ALIGN(body,surfbody_feedback[1:$NMXENDA]);

// @LINKs with maximum jump of one ("one-loopers")
// Rows in these tables have one-to-one correspondence over the @LINK
RESET ONELOOPER;
ALIGN(hdr, fcdiagnostic);
ONELOOPER(index,hdr);
ONELOOPER(hdr, auxiliary);
ONELOOPER(hdr, ensemble);
ONELOOPER(hdr,sat);
ONELOOPER(hdr,modsurf);
ONELOOPER(hdr,gbrad);
ONELOOPER(hdr,raingg);
ONELOOPER(hdr,conv);
ONELOOPER(sat,radiance,ssmi,scatt,satob,resat,limb,radar,radar_station,smos, gnssro, aeolus_hdr);
ONELOOPER(radiance,allsky, cloud_sink, collocated_imager_information, surfemiss);

// Define shared links (new option; not available through command line)
// (these aren't working properly ... yet (as of 29/8/2001 SS)
//SHAREDLINK(body,errstat,update[1:$NMXUPD]);

#include "mdi.h"
#include "obstype.h"
#include "varno.h"
#include "vertco_type.h"
#include "ppcode.h"
#include "sensor.h"

SET  $BG = 1;
SET  $ADJ = 2;

//
// Type definitions
//

#include "type_definitions.h"

//
// Table definitions 
//

CREATE TABLE desc AS (
  expver string,     // MARS key - Experiment ID
  class  pk1int,     // MARS key - ECMWF classification for data
  stream pk1int,     // MARS key - forecasting system used to generate data
  type   pk1int,     // MARS key - type of field used to retrieve data

  andate YYYYMMDD,   // Analysis date 
  antime HHMMSS,     // Analysis time

  inidate YYYYMMDD, // The starting date for the whole assimilation period
  initime HHMMSS,   // The starting time for the whole assimilation period 

  creadate YYYYMMDD, // Creation date
  creatime HHMMSS,   // Creation time
  creaby   string,   // Created by whom (username)

  moddate YYYYMMDD,  // Modification date
  modtime HHMMSS,    // Modification time
  modby   string,    // Modified by whom (username)

  mxup_traj pk1int,  // max. no. of updates for this database (= $MXUP_TRAJ)
  numtsl pk1int,     // total number of timeslots

  poolmask @LINK,
  timeslot_index @LINK,  
  fcdiagnostic    @LINK,                    // table used to store forecast diagnostics (post-processing only)

  latlon_rad pk1int, // ==1 if (lat,lon) is in radians, ==0 if in degrees 

  // Ensemble Data Assimilation (enda)-setup
  enda_member     pk1int, // enda-member number : 0=control, >0 member#

);

CREATE TABLE poolmask AS (
  timeslot pk1int,                 // Timeslot number
  obstype pk1int,                  // IFS Observation type
  codetype pk1int,                 // IFS Codetype
  sensor pk1int,                   // IFS Local Satellite Sensor (not necessarily WMO)
  bufrtype pk1int,                 // WMO BUFR type
  subtype pk1int,                  // WMO BUFR subtype
  poolno pk1int,                   // Pool number
  hdr_count pk1int,                // Number of reports
  body_count pk1int,               // Number of datum
  max_bodylen pk1int,              // Maximum number of datum
);

CREATE TABLE timeslot_index AS ( // More direct access to time slot data
  timeslot pk1int,    // Timeslot number
  model_timestep  pk1int,    // Model time step
  enddate  YYYYMMDD,  // End date of the timeslot
  endtime  HHMMSS,    // End time of the timeslot
  index @LINK,
);

CREATE TABLE index AS (
  target pk1int,      // Target pool number for CCMA
  procid pk1int,      // Normally the same as pool number (in ECMA)
  timeslot pk1int,    // Timeslot number
  kset pk1int,        // kset as from ECSET
  abnob pk1int,       // ECxxx-array pointer
  mapomm pk1int,      // GOMxxx-array pointer 
  maptovscv pk1int,   // TOVS control variable array pointer 
  hdr @LINK,  
);

#include "hdr.h"
#include "ensemble.h"
#include "forecast_diagnostic.h"
#include "gbrad.h"
#include "raingg.h"
#include "conv.h"

#include "sat.h"

#include "modsurf.h"
#include "surfbody_feedback.h"

#include "radiance.h"
#include "allsky.h"
#include "cloud_sink.h"
#include "collocated_imager_information.h"
#include "auxiliary.h"

#include "resat.h"

#include "gnssro.h"

#include "satob.h"

#include "scatt.h"

#include "ssmi1d.h"

#include "smos.h"

#include "radar_station.h"

#include "radar.h"

#include "limb.h"

#include "body.h"

#include "errstat.h"

#include "update.h"

#include "aeolus.h"

