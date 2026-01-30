
-- The following depends on rtlimb instruments (jpmxtan in mod_rtlimb_cparam),
-- so watch for it!
SET $mx_limb_tan = 17;

CREATE TABLE limb AS (
  ntan pk1int,                           // Number of sweeps
  ztan[$mx_limb_tan] pk9real,            // Tangent height
  ptan[$mx_limb_tan] pk9real,            // Tangent pressure
  thtan[$mx_limb_tan] pk9real,           // Along-orbit angle, relative to lat/long
  cloud_index[$mx_limb_tan] pk9real,     // Remedios & Spang cloud index
  window_rad[$mx_limb_tan] pk9real,      // Radiance in 960.7 cm-1 channel
);
