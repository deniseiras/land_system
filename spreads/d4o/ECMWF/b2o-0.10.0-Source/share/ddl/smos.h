CREATE TABLE smos AS (
  snapshot_id       pk1int,          // snapshot indentifier
  grid_point_id     pk1int,          // grid point identifier
  electron_count    pk9real,         // total electron count 
  sun_bt            pk9real,         // direct sun BT
  snapshot_acc      pk9real,         // snapshot accuracy
  rad_acc_pure      pk9real,         // radiometric accuracy(pure polarisation)
  rad_acc_cross     pk9real,         // radiometric accuracy(cross polarisation)
  footprint_axis[2] pk9real,         // footprint axis
  polarisation      pk1int,          // polarisation
  water_fraction    pk9real,         // water fraction
  incidence_angle   pk9real,         // incidence angle
  faradey_rot_angle pk9real,         // faradey ratational angle
  pixel_rot_angle   pk9real,         // pixel radiometric accuracy
  info              pk1int,          // smos information flag
  snapshot_quality  pk1int,          // snapshot owerall quality
  report_tbflag     pk1int,          // observation flag in grid point
  tbvalue           pk9real,         // modelled brightness temperature
  nobs_averaged     pk1int,          // number of obs. used for averaging obsvalues (mask can be 2x2, 3x3, etc.)
  stdev_averaged    pk9real,         // Standard deviation of averaged values
);

