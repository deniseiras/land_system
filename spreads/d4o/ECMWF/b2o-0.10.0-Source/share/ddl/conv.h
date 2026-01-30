//
// Table Definitions: conv (header table)
//
CREATE TABLE conv AS (
  flight_phase           pk1int,             // BUFR aircraft flight phase
  flight_dp_o_dt         pk9real,            // aircraft flight dp/dt
// should be movde from hdr to here... statid                 string,             // STATION ID (CHARACTER*8)
  anemoht                pk9real,            // HEIGHT OF ANEMOMETER
  baroht                 pk9real,            // HEIGHT OF BAROMETRE
  station_type           pk1int,             // SYNOP/SHIPs (needed to find out if DRIBU)
  sonde_type             pk1int,             // In order to do bias corr. of TEMPs
  collection_identifier  pk1int,             // Identifier for a collection within a specific source        
  country                pk1int,             // WMO State Identifier (Code Table 0 01 101). Used if statid is national id rather than WMO station id.
  unique_identifier      pk1int,             // Unique record identifier for a given date and time and source : Reanalysis purpose
  timeseries_index       pk1int,             // Index to uniquely identify data timeseries from station/ship/buoy/radiosonde/etc.: Reanalysis purpose
  heading                pk9real,            // Aircraft heading
  aircraft_type          string,             // Aircraft type
  conv_body              @LINK,             
);

CREATE TABLE conv_body AS (
  ppcode                pk1int,              // PRESSURE CODE
  level                 LEVEL_t,             // PILOT LEVEL ID.
  datum_qcflag          pk1int,              // quality flag coming from BUFR for windprofiler
);
