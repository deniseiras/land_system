CREATE TABLE radar_station AS (
  ident          pk1int,          // radar identifier
  type           string,          // type of radar

// Should be named something like latrad if different to lat, etc.? Why is it different?
// To be clarified by Meteo-France
  lat            pk9real,         // latitude of the radar
  lon            pk9real,         // longitude of the radar
  stalt          pk9real,         // altitude of the radar
  antenht        pk9real,         // height of the antenna
  beamwidth      pk9real,         // aperture at 3dBz
  frequency      pk9real,         // pulse frequency
);

