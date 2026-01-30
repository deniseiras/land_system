// CMA observation types (obstype@hdr) :

SET  $SYNOP = 1;
SET  $AIREP = 2;
SET  $SATOB = 3;
SET  $DRIBU = 4;
SET  $BUYO  = 4;
SET  $TEMP  = 5;
SET  $PILOT = 6;
SET  $SATEM = 7;
SET  $PAOB  = 8;
SET  $SCATT = 9;
SET  $LIMB  = 10;
SET  $ISAC  = 11;
SET  $RALT  = 12;
SET  $RADAR = 13;
SET  $GBRAD = 14;
SET  $LIDAR = 15;
SET  $ALLSKY = 16;
SET  $RAINGG = 17;
SET  $IMSIMS = 18;

// CMA codetypes (used to be in obschar.codetype@hdr) for $SATEM :

SET  $REO3 = 206;
SET  $RESAT = 206;
SET  $ATOVS = 210;
SET  $RTOVS = 211;
SET  $TOVS = 212;
SET  $SSMI = 215;
SET  $TCWC = 214;
SET  $RADRR = 3;
SET  $AEOLUS = 187;

SET $satem500 = 86;
SET $satem250 = 186;
SET $rad1c = 210;

SET $gpsro = 250;
SET $lrad  = 251;


SET $synop_land = 11;
SET $synop_land_auto = 14;
SET $add_land_surface = 17;

// Report types (various SYNOP rain gauge accumulations)
SET $synop_rg1h  = 39001;
SET $synop_rg3h  = 39002;
SET $synop_rg6h  = 39003;
SET $synop_rg12h = 39004;
SET $synop_rg24h = 39005;
