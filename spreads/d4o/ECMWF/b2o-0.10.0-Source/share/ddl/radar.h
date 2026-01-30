//
// Table Definition: radar tables
// Used by MF
//
SET $mx_radar_niv = 15;
CREATE TABLE radar AS (
  iternoconv_1dv     pk1int,          // Number of iterations (1DVAR)
  failure_1dv        pk1int,          // Error indicator (1DVAR) 
  qmod[$mx_radar_niv]   pk9real,      // humidity at model levels 
  zsimp[$mx_radar_niv]  pk9real,      // simple reflectivity          
  radar_body  @LINK, 
);

CREATE TABLE radar_body AS (
  flgdyn        pk1int,              // dynamic quality flag 
  time          HHMMSS,              // Site starting hour associated to one pixel ???
  distance      pk9real,             // distance to the radar (meters) 
  elevation     pk9real,             // elevation 
  polarisation  pk9real,             // polarity
  anaprop       pk1int,              // Indicator of anaprop ???
  reflcost      pk9real,             // Cost function of the 1DVAR 
  azimuth       pk9real,             // azimuth (of the measurement (angle N/radar->pixel))
  press          pk9real,            // pressure 1Dvar
  temp[2]        pk9real,            // temperature 1Dvar
  q[2]           pk9real,            // specific humidity 
  temp_1dv       pk9real,            // error 1Dvar for temperature
  q_1dv          pk9real,            // error 1Dvar for humidity 
);

