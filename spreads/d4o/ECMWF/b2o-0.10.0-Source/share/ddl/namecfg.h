#ifdef _NAMECFG_
! odb_name mapname long_name units conversion_factor_a conversion_factor_b
! conversion : A * obtained_value + B

lat@hdr latitude - degrees_north 57.295779513082323 0
lon@hdr longitude - degrees_east 57.295779513082323 0
date@hdr date 'Observation date' yyyymmdd
time@hdr time 'Observation time' hhmmss

$t2m  t2m  '2m temperature' K
$ts   ts   'surface temperature' K
$u10m u10m 'u-component of 10m wind' 'm/s'
$v10m v10m 'v-component of 10m wind' 'm/s'
#endif

