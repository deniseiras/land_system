--
--  Data layout (schema) for CY37R3 : 
--
--   ECMA & CCMA table hierarchy:
--
--      1  desc
--      2  +---> poolmask
--      3  +---> timeslot_index
--      4  |     +---> index
--      5  |     |     +---> hdr
--      6  |     |     |     +---> sat
--      7  |     |     |     |     +---> radiance
--      8  |     |     |     |     |     +---> allsky
--      9  |     |     |     |     |           +---> allsky_body
--     11  |     |     |     |     |     +---> cloud_sink
--     12  |     |     |     |     |     +---> radiance_body
--     14  |     |     |     |     |     +---> collocated_imager_information
--     15  |     |     |     |     +---> resat
--     16  |     |     |     |     |     +---> resat_averaging_kernel
--     17  |     |     |     |     +---> gnssro
--     18  |     |     |     |     |     +---> gnssro_body
--     19  v     v     v     v     +---> satob
--     20  |     |     |     |     +---> scatt
--     21  |     |     |     |     |     +---> scatt_body
--     22  |     |     |     |     +---> ssmi
--     23  |     |     |     |     |     +---> ssmi_body
--     24  |     |     |     |     +---> limb
--     25  |     |     |     |     +---> aeolus_hdr
--     26  |     |     |     |     |     +---> aeolus_auxmet
--     27  |     |     |     |     |     +---> aeolus_l2c
--     28  |     |     |     |     |     +---> aeolus_l2b
--     29  |     |     |     |     +---> radar_station
--     30  |     |     |     |     +---> radar            
--     31  |     |     |     |     |     +---> radar_body 
--     32  |     |     !     !     +---> smos
--     33  |     |     |     +---> body
--     34  |     |     |     +---> auxiliary
--     35  |     |     |     +---> errstat
--     36  |     |     |     +---> update_1
--     37  |     |     |     +---> update_2
--     38  |     |     |     +---> update_3
--
-- Variables
--

SET  $NMXUPD  = 10; -- Maximum number of updates supported with this layout (min = 1 & max = 10)




SET  $NMXENKF  = 120; -- Maximum number of ensembles


SET  $NMXENDA  = 100; -- Maximum number of ensembles

SET  $NMXFCDIAG  = 20; -- Maximum number of forecast diagnostics

SET  $NUMAUX = 9; -- No. of auxiliary obsvalue's per body; aux1 ==> aux[$NUMAUX]
SET  $NUMTHBOX = 3; -- No. of thinning boxes (see also ifs/module/yomdb.F90)
SET  $NUMEV = 1;  -- Maximum number of retained eigenvectors of obs. err. corr. matrix
SET  $NUMDIAG = 1;  -- Maximum number of retained diagnostics of obs. err. corr. matrix (must be the same as JP_NUMDIAG in yomdb.h)

-- Aligned tables (contain the same no. of rows when requested over the @LINK)

-- @LINKs with maximum jump of one ("one-loopers")
-- Rows in these tables have one-to-one correspondence over the @LINK

-- Define shared links (new option; not available through command line)
-- (these aren't working properly ... yet (as of 29/8/2001 SS)
--SHAREDLINK(body,errstat,update[1:$NMXUPD]);

SET $MDI = 2147483647; -- Absolute value of the Missing Data Indicator
-- CMA observation types (obstype@hdr) :

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

-- CMA codetypes (used to be in obschar.codetype@hdr) for $SATEM :

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

-- Report types (various SYNOP rain gauge accumulations)
SET $synop_rg1h  = 39001;
SET $synop_rg3h  = 39002;
SET $synop_rg6h  = 39003;
SET $synop_rg12h = 39004;
SET $synop_rg24h = 39005;
-- Variable numbers (varno@body) :
SET  $u  =  3 ;                  --   upper air u component     
SET  $v  =  4 ;                  --   upper air v component     
SET  $z  =  1 ;                  --   geopotential              
SET  $dz  =  57 ;                --   thickness                 
SET  $rh  =  29 ;                --   upper air rel. humidity   
SET  $pwc  =  9 ;                --   precipitable water content      
SET  $rh2m  =  58 ;              --   2m rel. humidity          
SET  $t  =  2 ;                  --   upper air temperature (K)
SET  $td  =  59 ;                --   upper air dew point (K) 
SET  $t2m  =  39 ;               --   2m temperature (K)           
SET  $td2m  =  40 ;              --   2m dew point (K)             
SET  $ts  =  11 ;                --   surface temperature (K)      
SET  $ptend  =  30 ;             --   pressure tendency         
SET  $w  =  60 ;                 --   past weather (w)          
SET  $ww  =  61 ;                --   present weather (ww)      
SET  $vv  =  62 ;                --   visibility                
SET  $ch  =  63 ;                --   type of high clouds (ch)  
SET  $cm  =  64 ;                --   type of middle clouds (cm)   
SET  $cl  =  65 ;                --   type of low clouds (cl)   
SET  $nh  =  66 ;                --   cloud base height (nh)    
SET  $nn  =  67 ;                --   low cloud amount (n)      
SET  $hshs  =  68 ;              --   additional cloud group height (hh)   
SET  $c  =  69 ;                 --   additional cloud group type (c)   
SET  $ns  =  70 ;                --   additional cloud group amount (ns)   
SET  $sdepth  =  71 ;            --   snow depth                
SET  $e  =  72 ;                 --   state of ground (e)       
SET  $tgtg  =  73 ;              --   ground temperature (tgtg)   
SET  $spsp1  =  74 ;             --   special phenomena (spsp)#1   
SET  $spsp2  =  75 ;             --   special phenomena (spsp)#2   
SET  $rs  =  76 ;                --   ice code type (rs)        
SET  $eses  =  77 ;              --   ice thickness (eses)      
SET  $is  =  78 ;                --   ice (is)                  
SET  $trtr  =  79 ;              --   original time period of rain obs. (trtr)   
SET  $rr  =  80 ;                --   6hr rain (liquid part)    
SET  $jj  =  81 ;                --   max. temperature (jj)     
SET  $vs  =  82 ;                --   ship speed (vs)           
SET  $ds  =  83 ;                --   ship direction (ds)       
SET  $hwhw  =  84 ;              --   wave height               
SET  $pwpw  =  85 ;              --   wave period               
SET  $dwdw  =  86 ;              --   wave direction            
SET  $gclg  =  87 ;              --   general cloud group       
SET  $rhlc  =  88 ;              --   rel. humidity from low clouds      
SET  $rhmc  =  89 ;              --   rel. humidity from middle clouds   
SET  $rhhc  =  90 ;              --   rel. humidity from high clouds     
SET  $n  =  91 ;                 --   total amount of clouds    
SET  $sfall  =  92 ;             --   6hr snowfall (solid part of rain)   
SET  $ps  =  110 ;               --   surface pressure          
SET  $dd  =  111 ;               --   wind direction            
SET  $ff  =  112 ;               --   wind force                
SET  $rawbt  =  119 ;            --   brightness temperature (K)
SET  $rawra  =  120 ;            --   raw radiance              
SET  $satcl  =  121 ;            --   cloud amount from satellite   
SET  $scatss  =  122 ;           --   sigma 0   
SET  $du  =  5 ;                 --   wind shear (du)   
SET  $dv  =  6 ;                 --   wind shear (dv)   
SET  $u10m  =  41 ;              --   10m u component (m/s)
SET  $v10m  =  42 ;              --   10m v component (m/s)  
SET  $rhlay  =  19 ;             --   layer rel. humidity   
SET  $cllqw  =  123 ;            --   cloud liquid water   
SET  $scatv  =  124 ;            --   ambiguous v component   
SET  $scatu  =  125 ;            --   ambiguous u component   
SET  $q  =  7 ;                  --   specific humidity (q)   
SET  $scatwd  =  126 ;           --   ambiguous wind direction   
SET  $scatws  =  127 ;           --   ambiguous wind speed       
SET  $vsp  =  8 ;                --   vertical speed   
SET  $vt  =  56 ;                --   virtual temperature   
SET  $o3lay  =  206 ;            --   layer ozone   
SET  $height  =  156 ;           --   height   
SET  $1dvar  =  215 ;            --   1d-var model level (pseudo)-variable   
SET  $w2  =  160 ;               --   past weather 2 (used in synoptic maps)   
SET  $cpt  =  130 ;              --   characteristic of pressure tendency (used in synoptic maps)   
SET  $tsts  =  12 ;              --   sea water temperature (used in synoptic maps)   
SET  $refl  =  192 ;             --   radar reflectivity  
SET  $apdss  =  128 ;            --   atmospheric path delay in satellite signal   
SET  $bend_angle  =  162 ;       --   radio occultation bending angle   
SET  $los  =  187 ;              --   horizontal line-of-sight wind component     
SET  $aerod  =  174 ;            --   aerosol optical depth at 0.55 microns  
SET  $limb_radiance =  163 ;     --   Limb Radiances  
SET  $chem1  =  181 ;            --   chem1: no2/nox   
SET  $chem2  =  182 ;            --   chem2: so2   
SET  $chem3  =  183 ;            --   chem3: co   
SET  $chem4  =  184 ;            --   chem4: hcho   
SET  $chem5  =  185 ;            --   chem5: go3   
SET  $chem6  =  284 ;            --   chem6: so2 volcanic
SET  $cod  =  175 ;              --   cloud optical depth   
SET  $rao  =  176 ;              --   Ratio of fine mode to total aerosol optical depth at 0.55 microns   
SET  $od  =  177 ;               --   optical depth   
SET  $rfltnc  =  178 ;           --   Aerosol reflectance multi-channel   
SET  $nsoilm  =  179 ;           --   normalized soil moisture  (0-100%) 
SET  $soilm  =  180 ;            --   soil moisture   
SET  $flgt_phase  =  201 ;       --   phase of aircraft flight  
SET  $height_assignment_method  =  211 ;                  --  Height assignment method   
SET  $dopp  =  195 ;             --   radar doppler wind   
SET  $ghg1  =  186 ;             --   ghg1: carbon dioxide   
SET  $ghg2  =  188 ;             --   ghg2: methane   
SET  $ghg3  =  189 ;             --   ghg3: nitrous oxide   
SET  $bt_real  =  190 ;          --   brightness temperature real part  
SET  $bt_imaginary  =  191 ;     --   brightness temperature imaginary part  
SET  $prc  =  202 ;              --   radar rain rate   
SET  $lnprc  =  203 ;            --   log(radar rain rate mm/h + epsilon)   
SET  $libksc  =  222 ;           --   lidar backscattering  
SET  $ralt_swh  =  220 ;         --   significant wave height (m)           
SET  $ralt_sws  =  221 ;         --   surface wind speed (m/s)              
SET  $rawbt_clear  =  193 ;      --   brightness temperature for clear  (K) 
SET  $rawbt_cloudy  =  194 ;     --   brightness temperature for cloudy (K)
SET  $binary_snow_cover = 223;   --   binary snow cover (0: no snow / 1: presence of snow)
SET  $salinity = 224;            --   ocean salinity (PSU)
SET  $potential_temp = 225;      --   potential temperature (Kelvin)
SET  $humidity_mixing_ratio = 226;    -- humidity mixing ratio (kg/kg)
SET  $airframe_icing = 227;           -- airframe icing
SET  $turbulence_index = 228;         -- turbulence index
SET  $lidar_aerosol_extinction = 236; -- lidar aerosol extinction
SET  $lidar_cloud_backscatter  = 237; -- lidar cloud backscatter
SET  $lidar_cloud_extinction   = 238; -- lidar cloud extinction
SET  $cloud_radar_reflectivity = 239; -- cloud radar reflectivity
SET  $q2m = 281;                 --   2m specific humidity

-- Additional variable numbers required by Met Office
SET $pstation = 107;             -- Station pressure (Pa)
SET $pmsl = 108;                 -- Mean sea-level pressure (Pa)
SET $pstandard = 109;            -- Standard level pressure (Pa)
SET $vert_vv = 218;              -- Vertical visibility (m)
SET $max_wind_shear1 = 219;      -- Wind shear above and below 1st maximum wind in sonde profile (s-1)
SET $tot_zen_delay = 229;        -- Total zenith delay (GPS)
SET $tot_zen_delay_err = 230;    -- Total zenith delay error (GPS)
SET $cloud_top_temp = 231;       -- Cloud top temperature (K)
SET $rawsca = 233;               -- Scaled radiance
SET $cloud_top_press = 235;      -- Cloud top pressure (Pa)
SET $mean_freq = 241;            -- GPSRO mean frequency
SET $u_amb = 242;                -- Ambiguous u-wind component (m/s)
SET $v_amb = 243;                -- Ambiguous v-wind component (m/s)
SET $lwp = 244;                  -- Liquid water path
SET $tcwv = 245;                 -- Total column water vapour
SET $theta = 225;                -- [alias to $potential_temp]
SET $cloud_frac_clear = 247;     -- Cloud clear fraction
SET $rawbt_hirs = 248;           -- Raw brightness temperature specific to HIRS (K)
SET $rawbt_amsu = 249;           -- Raw brightness temperature specific to AMSU (K)
SET $rawbt_hirs20 = 250;         -- Raw brightness temperature specific to HIRS (K)
SET $sea_ice = 253;              -- Sea ice fraction
SET $cloud_frac_covered = 257;   -- Cloud covered fraction
SET $level_mixing_ratio = 258;   -- [alias for $humidity_mixing_ratio]
SET $radial_velocity = 259;      -- Radial velocity from doppler radar
SET $cloud_ice_water = 260;      -- Cloud ice water
SET $wind_gust = 261;            -- Maximum wind gust (m/s)
SET $mass_density = 262;         -- Mass density
SET $atmosphere_number = 263;    -- SFERICS number of atmospheres
SET $lightning = 265;            -- Lightning strike observation (ATDNET)
SET $level_cloud = 266;          -- Cloud fraction (multi-level)
SET $rawbt_amsr_89ghz = 267;     -- Raw brightness temperature specific to AMSR 89GHz channels (K)
SET $max_wind_shear2 = 268;      -- Wind shear above and below 2nd maximum wind in sonde profile
SET $lower_layer_p = 269;        -- Pressure at bottom of layer SBUV (Pa)
SET $upper_layer_p = 270;        -- Pressure at top of later SBUV (Pa)
SET $cloud_cover = 271;          -- Total cloud cover
SET $depth = 272;                -- Depth (m)
SET $ssh = 273;                  -- Sea surface height (m)
SET $rawbt_mwts = 274;           -- Raw brightness temperature specific to MWTS (K)
SET $rawbt_mwhs = 275;           -- Raw brightness temperature specific to MWHS (K)
-- Vertical coordinate types (vertco_type@body) :

SET $pressure = 1;            -- vertco_reference_1@body is a pressure (in Pa)
SET $gpheight = 2;            -- vertco_reference_1@body is a geopotential height
SET $tovs_cha = 3;            -- vertco_reference_1@body is a TOVS channel
SET $scat_cha = 4;            -- vertco_reference_1@body is a Scatterometer channel
SET $modlevno = 5;            -- vertco_reference_1@body is a model level number
SET $imp_param = 6;           -- vertco_reference_1@body is an impact parameter
SET $cha_number = 7;          -- vertco_reference_1@body is a channel number
SET $cha_wavelength = 8;      -- vertco_reference_1@body is channel wavelength (in metres)
SET $cha_frequency = 9;       -- vertco_reference_1@body is channel frequency (in Hz)
SET $ocean_depth = 10;        -- vertco_reference_1@body is depth below surface (in metres)
SET $derived_pressure = 11;   -- vertco_reference_1@body is a derived pressure (in Pa)
SET $amb_wind_num = 12;       -- vertco_reference_1@body is an ambivalent wind number
SET $cloud_top_pressure = 13; -- vertco_reference_1@body is a cloud top pressure (in Pa)
SET $tangent_height = 14;     -- vertco_reference_1@body is a tangent height (metres) for SBUV
SET $model_pressure = 15;     -- vertco_reference_1@body is a model level pressure (in Pa)
-- Synop pressure codes (ppcode@body) :

SET $psealev  = 0;      -- press@body is SEA LEVEL PRESSURE
SET $pstalev  = 1;	--      "        STATION LEVEL PRESSURE
SET $g850hpa  = 2;	--      "	 850MB GEOPOTENTIAL
SET $g700hpa  = 3;	--      "	 700MB GEOPOTENTIAL
SET $p500gpm  = 4;	--      "	 500GPM PRESSURE
SET $p1000gpm = 5;	--      "	 1000GPM PRESSURE
SET $p2000gpm = 6;	--      "	 2000GPM PRESSURE
SET $p3000gpm = 7;	--      "	 3000GPM PRESSURE
SET $p4000gpm = 8;	--      "	 4000GPM PRESSURE
SET $g900hpa  = 9;	--      "	 900MB GEOPOTENTIAL
SET $g1000hpa = 10;	--      "	 1000MB GEOPOTENTIAL
SET $g500hpa  = 11;	--      "	 500MB GEOPOTENTIAL
SET $g925hpa  = 12;	--      "	 925MB GEOPOTENTIAL
-- sensor id's (sensor@hdr) :

SET $hirs      =  0;
SET $msu       =  1;
SET $ssu       =  2;
SET $amsua     =  3;
SET $amsub     =  4;
SET $tmi       =  9;
SET $ssmis     = 10;
SET $iasi      = 16;
SET $amsre     = 17;
SET $amsr2     = 63;
SET $mwri      = 18;
SET $atms      = 19;
SET $meteosat  = 20;
SET $iras      = 26;
SET $mwts      = 27;
SET $mwhs      = 28;
SET $gmi       = 71;

SET  $BG = 1;
SET  $ADJ = 2;

--
-- Type definitions
--

--
-- Type definitions
--

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
  active bit1,                          -- ACTIVE FLAG
  passive bit1,                         -- PASSIVE FLAG
  rejected bit1,                        -- REJECTED FLAG
  blacklisted bit1,                     -- BLACKLISTED
  use_emiskf_only bit1,                 -- to be used for emiskf only
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
--  _varno_unused_6 bit6,  
);

CREATE TYPE datum_flag_t AS (
  final bit4,                           -- FINAL FLAG
  fg bit4,                              -- FIRST GUESS FLAG
  depar bit4,                           -- DEPARTURE FLAG
  varQC bit4,                           -- VARIATIONAL QUALITY FLAG
  blacklist bit4,                       -- BLACKLIST FLAG
  ups bit1,                             -- d'utilisation par analyse de pression de surface
  uvt bit1,                             -- d'utilisation par analyse de vent et temperature
  uhu bit1,                             -- d'utilisation par analyse d'humidite
  ut2 bit1,                             -- d'utilisation par analyse de temperat ure a 2m
  uh2 bit1,                             -- d'utilisation par analyse d'humidite a 2m
  uv1 bit1,                             -- d'utilisation par analyse de vent a 10m
  urr bit1,                             -- d'utilisation par analyse de precipitations
  usn bit1,                             -- d'utilisation par analyse de neige
  usst bit1,                            -- d'utilisation par analyse de temperature de surface de la mer
);

CREATE TYPE level_t AS (
  --id bit9,                              -- PILOT LEV. ID.
  maxwind bit1,                         -- MAX WIND LEVEL
  tropopause bit1,                      -- TROPOPAUSE 
  D_part bit1,                          -- D PART
  C_part bit1,                          -- C PART
  B_part bit1,                          -- B PART
  A_part bit1,                          -- A PART
  surface bit1,                         -- SURFACE LEVEL
  signwind bit1,                        -- SIGNIFICANT WIND LEVEL
  signtemp bit1,                        -- SIGNIFICANT TEMPR. LEVEL
);

CREATE TYPE report_event1_t AS (
  no_data bit1,                         -- no data in the report
  all_rejected bit1,                    -- all data rejected
  bad_practice bit1,                    -- bad reporting practice
  rdb_rejected bit1,                    -- rejected due to RDB flag
  redundant bit1,                       -- redundant report
  stalt_missing bit1,                   -- missing station altitude
  QC_failed bit1,                       -- failed quality control
  overcast_ir bit1,                     -- report overcast IR
  thinned bit1,                         -- wvc thinned out
  latlon_corrected bit1,                -- position corrected using station database value
  stalt_corrected bit1,                 -- station altitude corrected using station database value
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
  vertco_missing bit1,               -- missing vertical coordinate
  obsvalue_missing bit1,             -- missing observed value
  fg_missing bit1,                   -- missing first guess value
  rdb_rejected bit1,                 -- rejected due ti RDB flag
  assim_cld_flag bit1,               -- assim of cloud-affected radiance
  bad_practice bit1,                 -- bad reporting practice
  vertpos_outrange bit1,             -- vertical position out of range
  fg2big bit1,                       -- too big first guess departure
  depar2big bit1,                    -- too big departure in assimilation
  obs_error2big bit1,                -- too big observation error
  datum_redundant bit1,              -- redundant datum
  level_redundant bit1,              -- redundant level
  not_analysis_varno bit1,           -- not an analysis variable
  duplicate bit1,                    -- duplicated datum/level
  levels2many bit1,                  -- too many surface data/levels
  level_selection bit1,              -- level selection
  vertco_consistency bit1,           -- vertical consistency check
  vertco_type_changed bit1,          -- vertical coordinate changed from Z to P
  combined_flagging bit1,            -- combined flagging
  report_rejected bit1,              -- datum rejected due to rejected report
  varQC_performed bit1,              -- variational QC performed
  obserror_increased bit1,           -- obs error increased
  contam_cld_flag bit1,              -- cloud contamination
  contam_rain_flag bit1,             -- rain contamination
  contam_aerosol_flag bit1,          -- aerosol contamination
  bad_emissivity bit1,               -- missing or not sensible emissivity values
  model_cld_flag bit1,               -- model cloud		       
  contam_trgas_flag bit1,            -- trace gas contamination
  land_sensitivity bit1,             -- channel sensitive to land
);


CREATE TYPE datum_sfc_event_t AS (
  statid bit1,                       -- bad statid (blacklisted, etc.)
  lsmask bit1,                       -- rejection due to land-sea mask
  stalt_missing bit1,                -- missing station altitude
  obsvalue_missing bit1,             -- missing observed value
  fg_missing bit1,                   -- missing first guess value
  fg2big bit1,                       -- too big first guess departure
  not_analysis_varno bit1,           -- not an analysis variable
  redundant bit1,                    -- redundant report
  report_rejected bit1,              -- datum rejected due to rejected report
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
  nadir_location    bit1, --  bit#0 = 1 for location at nadir (calibration mode)
  orbit_predicted   bit1, --      1         location from orbit predictor
  omit_from_EE      bit1, --      2         predicted location to omit from EE product
);

--
-- Table definitions 
--

CREATE TABLE desc AS (
  expver string,     -- MARS key - Experiment ID
  class pk1int,     -- MARS key - ECMWF classification for data
  stream pk1int,     -- MARS key - forecasting system used to generate data
  type pk1int,     -- MARS key - type of field used to retrieve data
  andate YYYYMMDD,   -- Analysis date 
  antime HHMMSS,     -- Analysis time
  inidate YYYYMMDD, -- The starting date for the whole assimilation period
  initime HHMMSS,   -- The starting time for the whole assimilation period 
  creadate YYYYMMDD, -- Creation date
  creatime HHMMSS,   -- Creation time
  creaby string,   -- Created by whom (username)
  moddate YYYYMMDD,  -- Modification date
  modtime HHMMSS,    -- Modification time
  modby string,    -- Modified by whom (username)
  mxup_traj pk1int,  -- max. no. of updates for this database (= $MXUP_TRAJ)
  numtsl pk1int,     -- total number of timeslots
  poolmask @LINK,
  timeslot_index @LINK,  
  fcdiagnostic @LINK,                    -- table used to store forecast diagnostics (post-processing only)
  latlon_rad pk1int, -- ==1 if (lat,lon) is in radians, ==0 if in degrees 
  enda_member pk1int, -- enda-member number : 0=control, >0 member#
);


CREATE TABLE poolmask AS (
  timeslot pk1int,                 -- Timeslot number
  obstype pk1int,                  -- IFS Observation type
  codetype pk1int,                 -- IFS Codetype
  sensor pk1int,                   -- IFS Local Satellite Sensor (not necessarily WMO)
  bufrtype pk1int,                 -- WMO BUFR type
  subtype pk1int,                  -- WMO BUFR subtype
  poolno pk1int,                   -- Pool number
  hdr_count pk1int,                -- Number of reports
  body_count pk1int,               -- Number of datum
  max_bodylen pk1int,              -- Maximum number of datum
);


CREATE TABLE timeslot_index AS ( -- More direct access to time slot data
  timeslot pk1int,    -- Timeslot number
  model_timestep pk1int,    -- Model time step
  enddate YYYYMMDD,  -- End date of the timeslot
  endtime HHMMSS,    -- End time of the timeslot
  index @LINK,
);


CREATE TABLE index AS (
  target pk1int,      -- Target pool number for CCMA
  procid pk1int,      -- Normally the same as pool number (in ECMA)
  timeslot pk1int,    -- Timeslot number
  kset pk1int,        -- kset as from ECSET
  abnob pk1int,       -- ECxxx-array pointer
  mapomm pk1int,      -- GOMxxx-array pointer 
  maptovscv pk1int,   -- TOVS control variable array pointer 
  hdr @LINK,  
);


--
-- Table Definitions: hdr (header table)
--
CREATE TABLE hdr AS (
  seqno pk1int,              -- OBSERVATION SEQUENCE
  subseqno pk1int,              -- OBSERVATION SEQUENCE for SUB-WINDOWS
  reportno pk1int,              -- report number, unique per pool (e.g. radiosonde profile)
  bufrtype pk1int,              -- BUFR-type
  subtype pk1int,              -- BUFR subtype for reference
  subsetno pk9int,              -- Multisubset number in BUFR-msg (=0 for single subset) useful for odb2bufr
  groupid pk1int,              -- MARS key - Observation group
  reportype pk1int,              -- MARS key - report type for MAR
  obstype pk1int,              -- OBSERVATION TYPE
  codetype pk1int,              -- OBSERVATION CODE TYPE
  sensor pk1int,              -- ECMWF SATELLITE LOCAL (RTTOV) SENSOR INDICATOR
  retrtype pk1int,              -- OBSERVATION RETRIEVAL TYPE
  instrument_type pk1int,              -- OBSERVATION INSTRUMENT TYPE
  stalt pk9real,             -- ALTITUDE 
  date YYYYMMDD,            -- OBS. DATE
  time HHMMSS,              -- OBS. EXACT TIME
  rdbdate YYYYMMDD,            -- OBS. ARRIVAL/PROCESSING DATE
  rdbtime HHMMSS,              -- OBS. ARRIVAL/PROCESSING TIME
  distribtype pk1int,              -- type of distribution - default is 0 i.e. no redistribution
  distribid pk1int,              -- target pool when data is re-distributed (for instance on model grid)
  gp_dist pk9real,             -- DIST TO NEAREST GP - only if observations need to be distributed on model grid
  gp_number pk1int,              -- JROF - grid point number (on the local PE grid)
  numlev pk1int,              -- No. of distinct pressure levels in bodies
  numactiveb pk1int,              -- No. of active body entries (i.e. status.active@body == 1)
  checksum pk9real,             -- A check sum of obsvalues where press & obsvalue is not NULL
  sortbox pk1int,              -- SORTING BOX
  areatype pk1int,              -- OBSERVATION AREA TYPE
  report_status STATUS_t,            -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,     -- REPORT'S EVENTS (PART 1)
  report_rdbflag REPORT_RDBFLAG_t,    -- REPORT'S FLAGS
  report_blacklist REPORT_BLACKLIST_t,  -- REPORT'S BLACKLIST EVENTS
  report_event2 REPORT_EVENT2_t,     -- REPORT EVENTS (PART 2) WORD POS.
  thinningkey_1 pk9real,             -- Thinning key
  thinningkey_2 pk9real,             -- Thinning key
  thinningkey_3 pk9real,             -- Thinning key
  thinningtimekey pk9real,             -- Thinning time key
  sitedep pk1int,             -- site dependent
  source string,             -- Source ID of obs. (CHARACTER*8) : Reanalysis purposes
  lat pk9real,            -- LATITUDE
  lon pk9real,            -- LONGITUDE
  trlat pk9real,            -- TRANSFORMED LAT. 
  trlon pk9real,            -- TRANSFORMED LON.
  restricted pk1int,             -- Flag to identify observations with access restrictions (0 = no restrictions)
  modsurf @LINK,              -- Model surface fields, at observation points
  statid string,             -- STATION ID (CHARACTER*8)
  wigosid_1 string,             -- WIGOS STATION ID (CHARACTER*32)
  wigosid_2 string,             -- WIGOS STATION ID (CHARACTER*32)
  wigosid_3 string,             -- WIGOS STATION ID (CHARACTER*32)
  wigosid_4 string,             -- WIGOS STATION ID (CHARACTER*32)
  conv @LINK,              -- put here all ODB conventional for conventional data only
  sat @LINK,  
  body @LINK,  
  errstat @LINK,             -- errstat table to be cleaned...
  update_1 @LINK,             -- update tables to be cleaned...
  update_2 @LINK,             -- update tables to be cleaned...
  update_3 @LINK,             -- update tables to be cleaned...
  update_4 @LINK,             -- update tables to be cleaned...
  update_5 @LINK,             -- update tables to be cleaned...
  update_6 @LINK,             -- update tables to be cleaned...
  update_7 @LINK,             -- update tables to be cleaned...
  update_8 @LINK,             -- update tables to be cleaned...
  update_9 @LINK,             -- update tables to be cleaned...
  update_10 @LINK,             -- update tables to be cleaned...
  auxiliary @LINK,             -- only created if ODB_AUXILIARY=1
  ensemble @LINK,             -- one enkf or enda table per ensemble
  gbrad @LINK,             -- ground-based radar
  raingg @LINK,             -- rain gauges
  surfbody_feedback @LINK,             -- storage of feedbacks from the surface analysis
  window_offset pk1int,  -- use for subwindows to identify the subwindow 
);


-- Define up to $NMXENKF enkf-tables with
-- the naming convention enkf_1 enkf_2, ..., enkf_<$NMXENKF>.
-- Each of them has got exactly the same attributes.
-- Note: It is up to the software to decide how many of these tables will
-- actually be filled !!

CREATE TABLE ensemble AS (
  nensemble pk1int,   -- Number of members active (<=$NMXENKF or <=$NMXENDA
  enkf_1 @LINK,
  enkf_2 @LINK,
  enkf_3 @LINK,
  enkf_4 @LINK,
  enkf_5 @LINK,
  enkf_6 @LINK,
  enkf_7 @LINK,
  enkf_8 @LINK,
  enkf_9 @LINK,
  enkf_10 @LINK,
  enkf_11 @LINK,
  enkf_12 @LINK,
  enkf_13 @LINK,
  enkf_14 @LINK,
  enkf_15 @LINK,
  enkf_16 @LINK,
  enkf_17 @LINK,
  enkf_18 @LINK,
  enkf_19 @LINK,
  enkf_20 @LINK,
  enkf_21 @LINK,
  enkf_22 @LINK,
  enkf_23 @LINK,
  enkf_24 @LINK,
  enkf_25 @LINK,
  enkf_26 @LINK,
  enkf_27 @LINK,
  enkf_28 @LINK,
  enkf_29 @LINK,
  enkf_30 @LINK,
  enkf_31 @LINK,
  enkf_32 @LINK,
  enkf_33 @LINK,
  enkf_34 @LINK,
  enkf_35 @LINK,
  enkf_36 @LINK,
  enkf_37 @LINK,
  enkf_38 @LINK,
  enkf_39 @LINK,
  enkf_40 @LINK,
  enkf_41 @LINK,
  enkf_42 @LINK,
  enkf_43 @LINK,
  enkf_44 @LINK,
  enkf_45 @LINK,
  enkf_46 @LINK,
  enkf_47 @LINK,
  enkf_48 @LINK,
  enkf_49 @LINK,
  enkf_50 @LINK,
  enkf_51 @LINK,
  enkf_52 @LINK,
  enkf_53 @LINK,
  enkf_54 @LINK,
  enkf_55 @LINK,
  enkf_56 @LINK,
  enkf_57 @LINK,
  enkf_58 @LINK,
  enkf_59 @LINK,
  enkf_60 @LINK,
  enkf_61 @LINK,
  enkf_62 @LINK,
  enkf_63 @LINK,
  enkf_64 @LINK,
  enkf_65 @LINK,
  enkf_66 @LINK,
  enkf_67 @LINK,
  enkf_68 @LINK,
  enkf_69 @LINK,
  enkf_70 @LINK,
  enkf_71 @LINK,
  enkf_72 @LINK,
  enkf_73 @LINK,
  enkf_74 @LINK,
  enkf_75 @LINK,
  enkf_76 @LINK,
  enkf_77 @LINK,
  enkf_78 @LINK,
  enkf_79 @LINK,
  enkf_80 @LINK,
  enkf_81 @LINK,
  enkf_82 @LINK,
  enkf_83 @LINK,
  enkf_84 @LINK,
  enkf_85 @LINK,
  enkf_86 @LINK,
  enkf_87 @LINK,
  enkf_88 @LINK,
  enkf_89 @LINK,
  enkf_90 @LINK,
  enkf_91 @LINK,
  enkf_92 @LINK,
  enkf_93 @LINK,
  enkf_94 @LINK,
  enkf_95 @LINK,
  enkf_96 @LINK,
  enkf_97 @LINK,
  enkf_98 @LINK,
  enkf_99 @LINK,
  enkf_100 @LINK,
  enkf_101 @LINK,
  enkf_102 @LINK,
  enkf_103 @LINK,
  enkf_104 @LINK,
  enkf_105 @LINK,
  enkf_106 @LINK,
  enkf_107 @LINK,
  enkf_108 @LINK,
  enkf_109 @LINK,
  enkf_110 @LINK,
  enkf_111 @LINK,
  enkf_112 @LINK,
  enkf_113 @LINK,
  enkf_114 @LINK,
  enkf_115 @LINK,
  enkf_116 @LINK,
  enkf_117 @LINK,
  enkf_118 @LINK,
  enkf_119 @LINK,
  enkf_120 @LINK,
  enda_1 @LINK,       -- one table for each member
  enda_2 @LINK,       -- one table for each member
  enda_3 @LINK,       -- one table for each member
  enda_4 @LINK,       -- one table for each member
  enda_5 @LINK,       -- one table for each member
  enda_6 @LINK,       -- one table for each member
  enda_7 @LINK,       -- one table for each member
  enda_8 @LINK,       -- one table for each member
  enda_9 @LINK,       -- one table for each member
  enda_10 @LINK,       -- one table for each member
  enda_11 @LINK,       -- one table for each member
  enda_12 @LINK,       -- one table for each member
  enda_13 @LINK,       -- one table for each member
  enda_14 @LINK,       -- one table for each member
  enda_15 @LINK,       -- one table for each member
  enda_16 @LINK,       -- one table for each member
  enda_17 @LINK,       -- one table for each member
  enda_18 @LINK,       -- one table for each member
  enda_19 @LINK,       -- one table for each member
  enda_20 @LINK,       -- one table for each member
  enda_21 @LINK,       -- one table for each member
  enda_22 @LINK,       -- one table for each member
  enda_23 @LINK,       -- one table for each member
  enda_24 @LINK,       -- one table for each member
  enda_25 @LINK,       -- one table for each member
  enda_26 @LINK,       -- one table for each member
  enda_27 @LINK,       -- one table for each member
  enda_28 @LINK,       -- one table for each member
  enda_29 @LINK,       -- one table for each member
  enda_30 @LINK,       -- one table for each member
  enda_31 @LINK,       -- one table for each member
  enda_32 @LINK,       -- one table for each member
  enda_33 @LINK,       -- one table for each member
  enda_34 @LINK,       -- one table for each member
  enda_35 @LINK,       -- one table for each member
  enda_36 @LINK,       -- one table for each member
  enda_37 @LINK,       -- one table for each member
  enda_38 @LINK,       -- one table for each member
  enda_39 @LINK,       -- one table for each member
  enda_40 @LINK,       -- one table for each member
  enda_41 @LINK,       -- one table for each member
  enda_42 @LINK,       -- one table for each member
  enda_43 @LINK,       -- one table for each member
  enda_44 @LINK,       -- one table for each member
  enda_45 @LINK,       -- one table for each member
  enda_46 @LINK,       -- one table for each member
  enda_47 @LINK,       -- one table for each member
  enda_48 @LINK,       -- one table for each member
  enda_49 @LINK,       -- one table for each member
  enda_50 @LINK,       -- one table for each member
  enda_51 @LINK,       -- one table for each member
  enda_52 @LINK,       -- one table for each member
  enda_53 @LINK,       -- one table for each member
  enda_54 @LINK,       -- one table for each member
  enda_55 @LINK,       -- one table for each member
  enda_56 @LINK,       -- one table for each member
  enda_57 @LINK,       -- one table for each member
  enda_58 @LINK,       -- one table for each member
  enda_59 @LINK,       -- one table for each member
  enda_60 @LINK,       -- one table for each member
  enda_61 @LINK,       -- one table for each member
  enda_62 @LINK,       -- one table for each member
  enda_63 @LINK,       -- one table for each member
  enda_64 @LINK,       -- one table for each member
  enda_65 @LINK,       -- one table for each member
  enda_66 @LINK,       -- one table for each member
  enda_67 @LINK,       -- one table for each member
  enda_68 @LINK,       -- one table for each member
  enda_69 @LINK,       -- one table for each member
  enda_70 @LINK,       -- one table for each member
  enda_71 @LINK,       -- one table for each member
  enda_72 @LINK,       -- one table for each member
  enda_73 @LINK,       -- one table for each member
  enda_74 @LINK,       -- one table for each member
  enda_75 @LINK,       -- one table for each member
  enda_76 @LINK,       -- one table for each member
  enda_77 @LINK,       -- one table for each member
  enda_78 @LINK,       -- one table for each member
  enda_79 @LINK,       -- one table for each member
  enda_80 @LINK,       -- one table for each member
  enda_81 @LINK,       -- one table for each member
  enda_82 @LINK,       -- one table for each member
  enda_83 @LINK,       -- one table for each member
  enda_84 @LINK,       -- one table for each member
  enda_85 @LINK,       -- one table for each member
  enda_86 @LINK,       -- one table for each member
  enda_87 @LINK,       -- one table for each member
  enda_88 @LINK,       -- one table for each member
  enda_89 @LINK,       -- one table for each member
  enda_90 @LINK,       -- one table for each member
  enda_91 @LINK,       -- one table for each member
  enda_92 @LINK,       -- one table for each member
  enda_93 @LINK,       -- one table for each member
  enda_94 @LINK,       -- one table for each member
  enda_95 @LINK,       -- one table for each member
  enda_96 @LINK,       -- one table for each member
  enda_97 @LINK,       -- one table for each member
  enda_98 @LINK,       -- one table for each member
  enda_99 @LINK,       -- one table for each member
  enda_100 @LINK,       -- one table for each member
  surfbody_feedback_1 @LINK,       -- one table for each member
  surfbody_feedback_2 @LINK,       -- one table for each member
  surfbody_feedback_3 @LINK,       -- one table for each member
  surfbody_feedback_4 @LINK,       -- one table for each member
  surfbody_feedback_5 @LINK,       -- one table for each member
  surfbody_feedback_6 @LINK,       -- one table for each member
  surfbody_feedback_7 @LINK,       -- one table for each member
  surfbody_feedback_8 @LINK,       -- one table for each member
  surfbody_feedback_9 @LINK,       -- one table for each member
  surfbody_feedback_10 @LINK,       -- one table for each member
  surfbody_feedback_11 @LINK,       -- one table for each member
  surfbody_feedback_12 @LINK,       -- one table for each member
  surfbody_feedback_13 @LINK,       -- one table for each member
  surfbody_feedback_14 @LINK,       -- one table for each member
  surfbody_feedback_15 @LINK,       -- one table for each member
  surfbody_feedback_16 @LINK,       -- one table for each member
  surfbody_feedback_17 @LINK,       -- one table for each member
  surfbody_feedback_18 @LINK,       -- one table for each member
  surfbody_feedback_19 @LINK,       -- one table for each member
  surfbody_feedback_20 @LINK,       -- one table for each member
  surfbody_feedback_21 @LINK,       -- one table for each member
  surfbody_feedback_22 @LINK,       -- one table for each member
  surfbody_feedback_23 @LINK,       -- one table for each member
  surfbody_feedback_24 @LINK,       -- one table for each member
  surfbody_feedback_25 @LINK,       -- one table for each member
  surfbody_feedback_26 @LINK,       -- one table for each member
  surfbody_feedback_27 @LINK,       -- one table for each member
  surfbody_feedback_28 @LINK,       -- one table for each member
  surfbody_feedback_29 @LINK,       -- one table for each member
  surfbody_feedback_30 @LINK,       -- one table for each member
  surfbody_feedback_31 @LINK,       -- one table for each member
  surfbody_feedback_32 @LINK,       -- one table for each member
  surfbody_feedback_33 @LINK,       -- one table for each member
  surfbody_feedback_34 @LINK,       -- one table for each member
  surfbody_feedback_35 @LINK,       -- one table for each member
  surfbody_feedback_36 @LINK,       -- one table for each member
  surfbody_feedback_37 @LINK,       -- one table for each member
  surfbody_feedback_38 @LINK,       -- one table for each member
  surfbody_feedback_39 @LINK,       -- one table for each member
  surfbody_feedback_40 @LINK,       -- one table for each member
  surfbody_feedback_41 @LINK,       -- one table for each member
  surfbody_feedback_42 @LINK,       -- one table for each member
  surfbody_feedback_43 @LINK,       -- one table for each member
  surfbody_feedback_44 @LINK,       -- one table for each member
  surfbody_feedback_45 @LINK,       -- one table for each member
  surfbody_feedback_46 @LINK,       -- one table for each member
  surfbody_feedback_47 @LINK,       -- one table for each member
  surfbody_feedback_48 @LINK,       -- one table for each member
  surfbody_feedback_49 @LINK,       -- one table for each member
  surfbody_feedback_50 @LINK,       -- one table for each member
  surfbody_feedback_51 @LINK,       -- one table for each member
  surfbody_feedback_52 @LINK,       -- one table for each member
  surfbody_feedback_53 @LINK,       -- one table for each member
  surfbody_feedback_54 @LINK,       -- one table for each member
  surfbody_feedback_55 @LINK,       -- one table for each member
  surfbody_feedback_56 @LINK,       -- one table for each member
  surfbody_feedback_57 @LINK,       -- one table for each member
  surfbody_feedback_58 @LINK,       -- one table for each member
  surfbody_feedback_59 @LINK,       -- one table for each member
  surfbody_feedback_60 @LINK,       -- one table for each member
  surfbody_feedback_61 @LINK,       -- one table for each member
  surfbody_feedback_62 @LINK,       -- one table for each member
  surfbody_feedback_63 @LINK,       -- one table for each member
  surfbody_feedback_64 @LINK,       -- one table for each member
  surfbody_feedback_65 @LINK,       -- one table for each member
  surfbody_feedback_66 @LINK,       -- one table for each member
  surfbody_feedback_67 @LINK,       -- one table for each member
  surfbody_feedback_68 @LINK,       -- one table for each member
  surfbody_feedback_69 @LINK,       -- one table for each member
  surfbody_feedback_70 @LINK,       -- one table for each member
  surfbody_feedback_71 @LINK,       -- one table for each member
  surfbody_feedback_72 @LINK,       -- one table for each member
  surfbody_feedback_73 @LINK,       -- one table for each member
  surfbody_feedback_74 @LINK,       -- one table for each member
  surfbody_feedback_75 @LINK,       -- one table for each member
  surfbody_feedback_76 @LINK,       -- one table for each member
  surfbody_feedback_77 @LINK,       -- one table for each member
  surfbody_feedback_78 @LINK,       -- one table for each member
  surfbody_feedback_79 @LINK,       -- one table for each member
  surfbody_feedback_80 @LINK,       -- one table for each member
  surfbody_feedback_81 @LINK,       -- one table for each member
  surfbody_feedback_82 @LINK,       -- one table for each member
  surfbody_feedback_83 @LINK,       -- one table for each member
  surfbody_feedback_84 @LINK,       -- one table for each member
  surfbody_feedback_85 @LINK,       -- one table for each member
  surfbody_feedback_86 @LINK,       -- one table for each member
  surfbody_feedback_87 @LINK,       -- one table for each member
  surfbody_feedback_88 @LINK,       -- one table for each member
  surfbody_feedback_89 @LINK,       -- one table for each member
  surfbody_feedback_90 @LINK,       -- one table for each member
  surfbody_feedback_91 @LINK,       -- one table for each member
  surfbody_feedback_92 @LINK,       -- one table for each member
  surfbody_feedback_93 @LINK,       -- one table for each member
  surfbody_feedback_94 @LINK,       -- one table for each member
  surfbody_feedback_95 @LINK,       -- one table for each member
  surfbody_feedback_96 @LINK,       -- one table for each member
  surfbody_feedback_97 @LINK,       -- one table for each member
  surfbody_feedback_98 @LINK,       -- one table for each member
  surfbody_feedback_99 @LINK,       -- one table for each member
  surfbody_feedback_100 @LINK,       -- one table for each member
);


CREATE TABLE enkf_1 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_2 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_3 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_4 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_5 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_6 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_7 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_8 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_9 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_10 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_11 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_12 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_13 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_14 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_15 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_16 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_17 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_18 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_19 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_20 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_21 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_22 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_23 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_24 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_25 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_26 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_27 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_28 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_29 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_30 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_31 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_32 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_33 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_34 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_35 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_36 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_37 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_38 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_39 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_40 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_41 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_42 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_43 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_44 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_45 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_46 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_47 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_48 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_49 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_50 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_51 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_52 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_53 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_54 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_55 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_56 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_57 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_58 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_59 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_60 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_61 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_62 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_63 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_64 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_65 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_66 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_67 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_68 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_69 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_70 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_71 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_72 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_73 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_74 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_75 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_76 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_77 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_78 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_79 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_80 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_81 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_82 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_83 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_84 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_85 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_86 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_87 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_88 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_89 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_90 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_91 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_92 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_93 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_94 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_95 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_96 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_97 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_98 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_99 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_100 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_101 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_102 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_103 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_104 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_105 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_106 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_107 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_108 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_109 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_110 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_111 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_112 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_113 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_114 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_115 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_116 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_117 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_118 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_119 AS (
  member pk1int,             -- enkf-member number
);

CREATE TABLE enkf_120 AS (
  member pk1int,             -- enkf-member number
);

-- Define up to $NMXENDA enda-tables with
-- the naming convention enda_1, enda_2, ..., enda_<$NMXENDA>.
-- Each of them has got exactly the same attributes.
-- Note: It is up to the software to decide how many of these tables will
-- actually be filled !!

CREATE TABLE enda_1 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_2 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_3 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_4 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_5 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_6 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_7 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_8 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_9 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_10 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_11 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_12 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_13 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_14 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_15 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_16 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_17 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_18 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_19 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_20 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_21 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_22 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_23 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_24 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_25 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_26 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_27 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_28 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_29 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_30 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_31 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_32 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_33 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_34 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_35 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_36 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_37 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_38 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_39 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_40 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_41 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_42 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_43 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_44 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_45 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_46 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_47 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_48 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_49 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_50 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_51 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_52 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_53 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_54 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_55 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_56 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_57 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_58 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_59 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_60 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_61 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_62 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_63 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_64 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_65 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_66 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_67 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_68 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_69 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_70 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_71 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_72 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_73 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_74 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_75 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_76 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_77 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_78 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_79 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_80 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_81 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_82 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_83 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_84 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_85 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_86 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_87 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_88 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_89 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_90 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_91 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_92 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_93 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_94 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_95 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_96 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_97 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_98 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_99 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);

CREATE TABLE enda_100 AS (
  member pk1int,                      -- enda-member number
  report_status STATUS_t,                    -- REPORT'S STATUS
  report_event1 REPORT_EVENT1_t,             -- REPORT'S EVENTS (PART 1)
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  final_obs_error pk9real,                     -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                     -- Prescribed observation error
  fg_error pk9real,                     -- FIRST GUESS ERROR
);


CREATE TABLE surfbody_feedback_1 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_2 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_3 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_4 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_5 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_6 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_7 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_8 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_9 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_10 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_11 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_12 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_13 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_14 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_15 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_16 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_17 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_18 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_19 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_20 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_21 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_22 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_23 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_24 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_25 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_26 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_27 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_28 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_29 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_30 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_31 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_32 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_33 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_34 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_35 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_36 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_37 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_38 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_39 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_40 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_41 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_42 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_43 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_44 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_45 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_46 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_47 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_48 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_49 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_50 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_51 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_52 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_53 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_54 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_55 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_56 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_57 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_58 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_59 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_60 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_61 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_62 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_63 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_64 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_65 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_66 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_67 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_68 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_69 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_70 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_71 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_72 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_73 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_74 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_75 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_76 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_77 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_78 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_79 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_80 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_81 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_82 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_83 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_84 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_85 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_86 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_87 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_88 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_89 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_90 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_91 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_92 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_93 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_94 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_95 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_96 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_97 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_98 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_99 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);

CREATE TABLE surfbody_feedback_100 AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
);


-- Define forecast_diagnostic table
-- Define up to $NMXFDIAG forecast_diagnostic-tables with
-- the naming convention forecast_diagnostic_1 forecast_diagnostic_2, ..., forecast_diagnostic_<$NMXFDIAG>.
-- Each of them has got exactly the same attributes.
-- Note: It is up to the software to decide how many of these tables will
-- actually be filled !!


CREATE TABLE fcdiagnostic AS (
  max_fcdiag pk1int,               -- number of forecast diagnostic valid for this experiment 
  fcdiagnostic_body_1 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_2 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_3 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_4 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_5 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_6 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_7 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_8 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_9 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_10 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_11 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_12 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_13 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_14 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_15 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_16 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_17 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_18 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_19 @LINK,     -- one table for each forecast departure to run in --
  fcdiagnostic_body_20 @LINK,     -- one table for each forecast departure to run in --
);


CREATE TABLE fcdiagnostic_body_1 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_2 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_3 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_4 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_5 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_6 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_7 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_8 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_9 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_10 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_11 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_12 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_13 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_14 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_15 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_16 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_17 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_18 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_19 AS (
  fc_depar pk9real,            -- forecast departure
);

CREATE TABLE fcdiagnostic_body_20 AS (
  fc_depar pk9real,            -- forecast departure
);

--
-- Table Definition: gbrad tables
--
CREATE TABLE gbrad AS (
  report_rrflag pk1int,       -- Rain Rate status flag - See yomgbrad.F90
  gbrad_body @LINK,
);


CREATE TABLE gbrad_body AS (
  rrvalue pk9real,       -- Simulated rain rates
  rrvaluetl pk9real,       -- Simulated TL of rain rates
  rrvaluead pk9real,       -- Simulated AD of rain rates
);


--
-- Table Definition: raingg tables
--
CREATE TABLE raingg AS (
  report_rrflag pk1int,       -- Rain Rate status flag - See yomraingg.F90
  raingg_body @LINK,
);


CREATE TABLE raingg_body AS (
  rrvalue pk9real,       -- Simulated rain rates
  rrvaluetl pk9real,       -- Simulated TL of rain rates
  rrvaluead pk9real,       -- Simulated AD of rain rates
);


--
-- Table Definitions: conv (header table)
--
CREATE TABLE conv AS (
  flight_phase pk1int,             -- BUFR aircraft flight phase
  flight_dp_o_dt pk9real,            -- aircraft flight dp/dt
  anemoht pk9real,            -- HEIGHT OF ANEMOMETER
  baroht pk9real,            -- HEIGHT OF BAROMETRE
  station_type pk1int,             -- SYNOP/SHIPs (needed to find out if DRIBU)
  sonde_type pk1int,             -- In order to do bias corr. of TEMPs
  collection_identifier pk1int,             -- Identifier for a collection within a specific source        
  country pk1int,             -- WMO State Identifier (Code Table 0 01 101). Used if statid is national id rather than WMO station id.
  unique_identifier pk1int,             -- Unique record identifier for a given date and time and source : Reanalysis purpose
  timeseries_index pk1int,             -- Index to uniquely identify data timeseries from station/ship/buoy/radiosonde/etc.: Reanalysis purpose
  heading pk9real,            -- Aircraft heading
  aircraft_type string,             -- Aircraft type
  conv_body @LINK,             
);


CREATE TABLE conv_body AS (
  ppcode pk1int,              -- PRESSURE CODE
  level LEVEL_t,             -- PILOT LEVEL ID.
  datum_qcflag pk1int,              -- quality flag coming from BUFR for windprofiler
);


--
-- Table Definitions: sat (header-like satellite table)
--
CREATE TABLE sat AS (
  satellite_identifier pk1int,     -- WMO Satellite platform identifier
  satellite_instrument pk1int,     -- WMO Satellite instrument on board
  zenith pk9real,    -- SATELLITE INSTRUMENT ZENITH ANGLE 
  azimuth pk9real,    -- SATELLITE INSTRUMENT AZIMUTH ANGLE
  solar_zenith pk9real,    -- SOLAR ZENITH ANGLE 
  solar_azimuth pk9real,    -- SOLAR AZIMUTH ANGLE
  range pk9real,    -- Range (distance) from satellite to observed volume
  arg_lat pk9real,    -- Argument of latitude; angle from ascending node to satellite's position
  lsm_fov pk9real,    -- LSM OF FOV
  gen_centre pk1int,     -- WMO Generating Centre
  gen_subcentre pk1int,     -- WMO Generating sub-centre
  datastream pk1int,     -- Datastream
  radiance @LINK,      -- Radiance table  (entry point for all atmospheric radiances)
  resat @LINK,      -- Retrieval of satellite data (ozone, co2, aerosols, etc.).
  gnssro @LINK,      -- gnssro table 
  satob @LINK,      -- satob winds
  limb @LINK,      -- For 2D observation operators?
  ssmi @LINK,      -- obsolete table for 1DVAR. Will be removed...
  smos @LINK,      -- smos satellite 
  scatt @LINK,      -- Scatterometer satellite
  aeolus_hdr @LINK,      -- Aeolus table
  radar_station @LINK,      -- ??? Meteo-France specific
  radar @LINK,      -- ??? Meteo-France specific
);



--
-- Table Definition: modsurf tables
--

CREATE TABLE modsurf AS (
  lsm pk9real,     -- model land-sea mask
  seaice pk9real,     -- model sea-ice  mask
  orography pk9real,     -- model orography 
  snow_depth pk9real,     -- model snow depth (m)
  t2m pk9real,     -- 2m temperature
  albedo pk9real,     -- albedo
  windspeed10m pk9real,     -- 10 metre wind speed
  u10m pk9real,     -- 10 metre U wind component
  v10m pk9real,     -- 10 metre V wind component
  surface_class pk1int,      -- surface type (used for radiances only; see satrad/emiss/amsu_sfc.F90)
  tsfc pk9real,     -- model skin temperature (used for some radiances only)
);


--
-- Table Definition: surface analysis feedback tables
--

CREATE TABLE surfbody_feedback AS (
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_sfc_event datum_sfc_event_t,           -- OBSERVATION EVENTS FOR SURFACE ANALYSIS 
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  snow_depth pk9real,                     -- model first-guess snow depth (m)
  snow_density pk9real,                     -- model first-guess snow density 
  lsm pk9real,                     -- model land-sea mask
);



--
-- Table Definitions: radiance (header-like table for all radiances)
--
CREATE TABLE radiance AS (
  scanline pk1int,   -- Scan line number
  scanpos pk1int,   -- Position number along scan / Field of View number
  orbit pk1int,   -- Orbit number
  typesurf pk1int,   -- Type of surface
  corr_version pk1int,   -- non linear correction version (a set of coefficients for each version)
  cldcover pk1int,   -- CLOUD PERCENTAGE FROM VISNIR FOR AIRS
  cldptop_1 pk9real,  -- CLOUD TOP PRESS. FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldptop_2 pk9real,  -- CLOUD TOP PRESS. FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldptop_3 pk9real,  -- CLOUD TOP PRESS. FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldne_1 pk9real,  -- CLOUD EMISSIVITY FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldne_2 pk9real,  -- CLOUD EMISSIVITY FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  cldne_3 pk9real,  -- CLOUD EMISSIVITY FROM TOVS HIRS RADIANCES: 3 values for 3 differents methods
  skintemper pk9real,  -- skin temperture background error 
  skintemp_1 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_2 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_3 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_4 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_5 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_6 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_7 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_8 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_9 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  skintemp_10 pk9real,  -- skin temperture per NRESUPD, 1 - FG, 2 - end of 1st min, 3 - end of 2nd min, etc
  scatterindex_89_157 pk9real,  -- Scatter index from 89 and 157 GHz channels
  scatterindex_23_89 pk9real,  -- Scatter index from 23 and 89 GHz channels
  scatterindex_23_165 pk9real,  -- Scatter index from 23 and 165 GHz channels
  lwp_obs pk9real,  -- Regression-based liquid water path from observations
  asr_pclear pk1int,   -- All-sky AMOUNT SEGMENT CLOUD FREE ASR RADIANCES
  asr_pcloudy pk1int,   -- All-sky CLOUD AMOUNT IN SEGMENT ASR RADIANCES
  asr_pcloudy_low pk1int,   -- All-sky CLOUD AMOUNT IN SEGMENT LOW-CLOUDS
  asr_pcloudy_middle pk1int,   -- All-sky CLOUD AMOUNT IN SEGMENT MIDLE-CLOUDS
  asr_pcloudy_high pk1int,   -- All-sky CLOUD AMOUNT IN SEGMENT HIGH-CLOUDS
  allsky @LINK,    -- allsky/mwave processing
  cloud_sink @LINK,    -- processing of cloud sink variables, still unclear...
  collocated_imager_information @LINK,    -- specific entries (from bufr2odb) for IASI - for post-processing only
  radiance_body @LINK,    -- specific entries for all radiances boody-like table
);



CREATE TABLE radiance_body AS(
  csr_pclear pk9real,      -- Percentage of clear pixels in mean CSR
  cld_fg_depar pk9real,      -- FG departure for cloudy radiances
  rank_cld pk9real,      -- channel ranking for cloud detection for AIRS and IASI only.
  tausfc pk9real,      -- Surface transmittance for radiances - to be moved to radiance_body table
  skintemp_retr pk9real,      -- Skin temperature retrieved from observations, emissivity atlas and FG
  tbclear pk9real,      -- Diagnostic clear-sky FG brightness temperature
  emis_rtin pk9real,      -- Input surface emissivity for RTTOV (can be outside 0-1 to prompt internal calculations)
  emis_atlas pk9real,      -- Surface emissivity estimate from an atlas
  emis_atlas_error pk9real,     -- Error in surface emissivity estimate from an atlas
  emis_retr pk9real,      -- Surface emissivity retrieved from observations and FG
  emis_fg pk9real,      -- Surface emissivity used in FG simulations (pre-set or RTTOV-internal)
  cold_nedt pk9real,      --  NOISE-EQUIVALENT DELTA TEMPERATURE WHILE VIEWING COLD TARGET
  warm_nedt pk9real,      --  NOISE-EQUIVALENT DELTA TEMPERATURE WHILE VIEWING COLD TARGET
  channel_qc pk1int,       --  Channel quality 12 bits
  nobs_averaged pk1int,       -- number of obs. used for averaging obsvalues (mask can be 2x2, 3x3, etc.)
  stdev_averaged pk9real,      -- Standard deviation of averaged values
  zenith_by_channel pk9real,      -- Satellite zenith angle (if variable by channel, rarely, some microwave imagers, e.g. GMI)
  dust_aod_ir pk9real,      -- AOD for IR instrument at 10 micron (AIRS, IASI, CrIS)
);


--
-- Table Definition: allsky tables
--
CREATE TABLE allsky AS (
  fg_rain_rate pk9real,      -- Surface rain @ FG [mm h-1] 
  fg_snow_rate pk9real,      -- Surface frozen precipitation @ FG [ mm h-1]
  fg_tcwv pk9real,      -- Total column water vapour @ FG [ kg m-2]
  fg_cwp pk9real,      -- Cloud liquid water path @ FG [ kg m-2 ] 
  fg_iwp pk9real,      -- Cloud ice water path @ FG [ kg m-2 ]
  fg_rwp pk9real,      -- Rain water path @ FG [ kg m-2 ]
  fg_swp pk9real,      -- Snow water path @ FG [ kg m-2 ] 
  fg_rttov_cld_fraction pk9real,      -- Cloud fraction used in RTTOV_SCATT [0-1] 
  fg_theta700 pk9real,      -- Potential Temperature in 700hPa @ FG [K]
  fg_thetasfc pk9real,      -- Potential Temperature at the surface @ FG [K]
  fg_uth pk9real,      -- 200-500hPa weighted average relative humidity wrt water @ FG [0-1] 
  fg_conv pk9real,      -- convection type 
  fg_pbl pk9real,      -- PBL type 
  an_rain_rate pk9real,      -- Surface rain @ AN [mm h-1] 
  an_snow_rate pk9real,      -- Surface frozen precipitation @ AN [ mm h-1]
  an_tcwv pk9real,      -- Total column water vapour @ AN [ kg m-2]
  an_cwp pk9real,      -- Cloud liquid water path @ AN [ kg m-2 ] 
  an_iwp pk9real,      -- Cloud ice water path @ AN [ kg m-2 ]
  an_rwp pk9real,      -- Rain water path @ AN [ kg m-2 ]
  an_swp pk9real,      -- Snow water path @ AN [ kg m-2 ] 
  an_rttov_cld_fraction pk9real,      -- Cloud fraction used in RTTOV_SCATT [0-1] 
  an_theta700 pk9real,      -- Potential Temperature in 700hPa @ FG [K]
  an_thetasfc pk9real,      -- Potential Temperature at the surface @ FG [K]
  an_uth pk9real,      -- 200-500hPa weighted average relative humidity wrt water @ AN [0-1] 
  an_conv pk9real,      -- convection type 
  an_pbl pk9real,      -- PBL type 
  gnorm_10mwind pk9real,      -- Norm of gradient against 10m wind 
  gnorm_skintemp pk9real,      -- Norm of gradient against skin temperature 
  gnorm_temp pk9real,      -- Norm of gradient against temperature
  gnorm_q pk9real,      -- Norm of gradient against specific humidity 
  gnorm_rainflux pk9real,      -- Norm of gradient against rain flux 
  gnorm_snowflux pk9real,      -- Norm of gradient against snow flux
  gnorm_clw pk9real,      -- Norm of gradient against cloud water
  gnorm_ciw pk9real,      -- Norm of gradient against cloud ice
  gnorm_cc pk9real,      -- Norm of gradient against cloud cover
  ob_p19 pk9real,      -- 19 GHz normalised polarisation difference observed
  fg_p19 pk9real,      -- 19 GHz normalised polarisation difference first guess
  an_p19 pk9real,      -- 19 GHz normalised polarisation difference analysis
  ob_p37 pk9real,      -- 19 GHz normalised polarisation difference observed
  fg_p37 pk9real,      -- 19 GHz normalised polarisation difference first guess
  an_p37 pk9real,      -- 19 GHz normalised polarisation difference analysis
  report_tbcloud pk1int,       -- Cloud and rain cloud bitfield flag determined from TB bitfield - See yommwave.F90
  allsky_body @LINK,
);


CREATE TABLE allsky_body AS (
  tbvalue pk9real,       -- Simulated brightness temperature
  tbvaluetl pk9real,       -- Simulated TL of brightness temperature
  tbvaluead pk9real,       -- Simulated AD in brightness temperature
  datum_tbflag pk1int,        -- Status flag for all-sky  - See yommwave.F90
);


--
-- Table Definition: cloud_sink tables
--
CREATE TABLE cloud_sink AS (
  ctop_1 pk9real,      -- CTOP per NRESUPD
  ctop_2 pk9real,      -- CTOP per NRESUPD
  ctop_3 pk9real,      -- CTOP per NRESUPD
  ctop_4 pk9real,      -- CTOP per NRESUPD
  ctop_5 pk9real,      -- CTOP per NRESUPD
  ctop_6 pk9real,      -- CTOP per NRESUPD
  ctop_7 pk9real,      -- CTOP per NRESUPD
  ctop_8 pk9real,      -- CTOP per NRESUPD
  ctop_9 pk9real,      -- CTOP per NRESUPD
  ctop_10 pk9real,      -- CTOP per NRESUPD
  camt_1 pk9real,      -- Camt per NRESUPD
  camt_2 pk9real,      -- Camt per NRESUPD
  camt_3 pk9real,      -- Camt per NRESUPD
  camt_4 pk9real,      -- Camt per NRESUPD
  camt_5 pk9real,      -- Camt per NRESUPD
  camt_6 pk9real,      -- Camt per NRESUPD
  camt_7 pk9real,      -- Camt per NRESUPD
  camt_8 pk9real,      -- Camt per NRESUPD
  camt_9 pk9real,      -- Camt per NRESUPD
  camt_10 pk9real,      -- Camt per NRESUPD
  ctopbg pk9real,      -- CTOP BACKGROUND
  ctoper pk9real,      -- CTOP BACKGROUND ERROR
  ctopinc pk9real,      -- CTOP INCREMENT 
  camtbg pk9real,      -- CAMT BACKGROUND
  camter pk9real,      -- CAMT BACKGROUND ERROR
  camtinc pk9real,      -- CAMT INCREMENT 
);


--
-- Table Definition: collocated_imager_information tables
--
-- For collocated_imager_information only - these ODB attributes are not used in IFS (table not loaded) but
-- can be used to post-process IASI data
--
CREATE TABLE collocated_imager_information AS (
  avhrr_mean_ir pk9real,               -- Mean BT on channel Ir in FOV
  avhrr_stddev_ir pk9real,             -- Std. Dev. of BT on channel Ir in FOV
  avhrr_stddev_ir2 pk9real,             -- Std. Dev. of BT on channel Ir2 in FOV
  avhrr_num_clusters pk9real,           -- Number of clusters FOV
  avhrr_mean_vis pk9real,               -- Mean visible reflectance in FOV
  avhrr_stddev_vis pk9real,             -- Std. Dev. of visible reflectance in FOV
  avhrr_max_cluster pk9real,            -- Fractional size of the largest cluster
  avhrr_coldest_cluster_ir pk9real,    -- Mean Ir BT for the coldest cluster
  avhrr_warmest_cluster_ir pk9real,    -- Mean Ir BT for the warmest cluster
  avhrr_largest_cluster_ir pk9real,    -- Mean Ir BT for the largest cluster
  provider_qc pk1int,                    -- QC as determined by data provider
  avhrr_frac_cl1 pk9real,               -- Fractional size of cluster 1
  avhrr_frac_cl2 pk9real,               -- Fractional size of cluster 2
  avhrr_frac_cl3 pk9real,               -- Fractional size of cluster 3
  avhrr_frac_cl4 pk9real,               -- Fractional size of cluster 4
  avhrr_frac_cl5 pk9real,               -- Fractional size of cluster 5
  avhrr_frac_cl6 pk9real,               -- Fractional size of cluster 6
  avhrr_frac_cl7 pk9real,               -- Fractional size of cluster 7
  avhrr_m_ir1_cl1 pk9real,              -- Mean Ir1 BT in cluster 1
  avhrr_m_ir1_cl2 pk9real,              -- Mean Ir1 BT in cluster 2
  avhrr_m_ir1_cl3 pk9real,              -- Mean Ir1 BT in cluster 3
  avhrr_m_ir1_cl4 pk9real,              -- Mean Ir1 BT in cluster 4
  avhrr_m_ir1_cl5 pk9real,              -- Mean Ir1 BT in cluster 5
  avhrr_m_ir1_cl6 pk9real,              -- Mean Ir1 BT in cluster 6
  avhrr_m_ir1_cl7 pk9real,              -- Mean Ir1 BT in cluster 7
  avhrr_m_ir2_cl1 pk9real,              -- Mean Ir2 BT in cluster 1
  avhrr_m_ir2_cl2 pk9real,              -- Mean Ir2 BT in cluster 2
  avhrr_m_ir2_cl3 pk9real,              -- Mean Ir2 BT in cluster 3
  avhrr_m_ir2_cl4 pk9real,              -- Mean Ir2 BT in cluster 4
  avhrr_m_ir2_cl5 pk9real,              -- Mean Ir2 BT in cluster 5
  avhrr_m_ir2_cl6 pk9real,              -- Mean Ir2 BT in cluster 6
  avhrr_m_ir2_cl7 pk9real,              -- Mean Ir2 BT in cluster 7
  avhrr_fg_ir1 pk9real,                 -- First guess Ir1 BT
  avhrr_fg_ir2 pk9real,                 -- First guess Ir2 BT
  avhrr_cloud_flag pk1int,              -- AVHRR cloud flag (determined during screening)
);


--
-- Table Definition: auxiliary tables
--
CREATE TABLE auxiliary AS (
  report_aux_1 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_2 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_3 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_4 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_5 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_6 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_7 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_8 pk9real,                     -- Auxiliary header-like entries; 
  report_aux_9 pk9real,                     -- Auxiliary header-like entries; 
  auxiliary_body @LINK,
);


CREATE TABLE auxiliary_body AS (
  datum_aux_1 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_2 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_3 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_4 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_5 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_6 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_7 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_8 pk9real,                     -- Auxiliary body-like entries;
  datum_aux_9 pk9real,                     -- Auxiliary body-like entries;
);




--
-- Table Definition: resat table
-- contains ozone, aerosols, CO2, etc.
--
-- retrtype@hdr = 1 when it contains averaging kernel 
-- retrtype@hdr = 0 when it does not contain averaging kernel
SET $resat_retrtype_ak = 1; 
SET $resat_retrtype = 0;

-- The following depends on resat data, so watch for it!
SET $mx_ak = 50;                        -- depends on jpmx_ak in module/parcma and bufr2odb_gch2.F90  and  varindex_module.F90!!
CREATE TABLE resat AS (
  instrument_type pk1int,               -- SATELLITE INSTRUMENT
  product_type pk1int,                  -- PRODUCT TYPE FOR RETRIEVED ATMOSPHERIC GASES
  lat_fovcorner_1 pk9real,           -- LATITUDE FIELD OF VIEW CORNER 1-4
  lat_fovcorner_2 pk9real,           -- LATITUDE FIELD OF VIEW CORNER 1-4
  lat_fovcorner_3 pk9real,           -- LATITUDE FIELD OF VIEW CORNER 1-4
  lat_fovcorner_4 pk9real,           -- LATITUDE FIELD OF VIEW CORNER 1-4
  lon_fovcorner_1 pk9real,           -- LONGITUDE FIELD OF VIEW CORNER 1-4
  lon_fovcorner_2 pk9real,           -- LONGITUDE FIELD OF VIEW CORNER 1-4
  lon_fovcorner_3 pk9real,           -- LONGITUDE FIELD OF VIEW CORNER 1-4
  lon_fovcorner_4 pk9real,           -- LONGITUDE FIELD OF VIEW CORNER 1-4
  solar_elevation pk9real,              -- SOLAR ELEVATION
  scanpos pk1int,                       -- SCAN POSITION i.e. FIELD OF VIEW NUMBER
  cloud_cover pk9real,                  -- CLOUD COVER
  cloud_top_press pk9real,              -- PRESSURE AT TOP OF CLOUD
  quality_retrieval pk1int,             -- QUALITY OF RETRIEVAL
  number_layers pk1int,                 -- NUMBER OF RETRIEVED LAYERS
  resat_averaging_kernel @LINK,
  snow_ice_indicator pk1int,            -- SNOW/ICE INDICATOR 
  surface_type_indicator pk1int,        -- SURFACE TYPE 
  methane_correction pk9real,           -- SCIAMACHY METHANE CORRECTION FACTOR
  surface_height pk9real,               -- SURFACE HEIGHT
  retrsource pk1int,                    -- SOURCE/ORIGINATOR OF RETRIEVED ATMOSPHERIC CONSTITUENT
);


CREATE TABLE resat_averaging_kernel AS (
  nak pk1int,                           -- number of averaging kernel elements
  wak_1 pk9real,                  -- averaging kernel weights
  wak_2 pk9real,                  -- averaging kernel weights
  wak_3 pk9real,                  -- averaging kernel weights
  wak_4 pk9real,                  -- averaging kernel weights
  wak_5 pk9real,                  -- averaging kernel weights
  wak_6 pk9real,                  -- averaging kernel weights
  wak_7 pk9real,                  -- averaging kernel weights
  wak_8 pk9real,                  -- averaging kernel weights
  wak_9 pk9real,                  -- averaging kernel weights
  wak_10 pk9real,                  -- averaging kernel weights
  wak_11 pk9real,                  -- averaging kernel weights
  wak_12 pk9real,                  -- averaging kernel weights
  wak_13 pk9real,                  -- averaging kernel weights
  wak_14 pk9real,                  -- averaging kernel weights
  wak_15 pk9real,                  -- averaging kernel weights
  wak_16 pk9real,                  -- averaging kernel weights
  wak_17 pk9real,                  -- averaging kernel weights
  wak_18 pk9real,                  -- averaging kernel weights
  wak_19 pk9real,                  -- averaging kernel weights
  wak_20 pk9real,                  -- averaging kernel weights
  wak_21 pk9real,                  -- averaging kernel weights
  wak_22 pk9real,                  -- averaging kernel weights
  wak_23 pk9real,                  -- averaging kernel weights
  wak_24 pk9real,                  -- averaging kernel weights
  wak_25 pk9real,                  -- averaging kernel weights
  wak_26 pk9real,                  -- averaging kernel weights
  wak_27 pk9real,                  -- averaging kernel weights
  wak_28 pk9real,                  -- averaging kernel weights
  wak_29 pk9real,                  -- averaging kernel weights
  wak_30 pk9real,                  -- averaging kernel weights
  wak_31 pk9real,                  -- averaging kernel weights
  wak_32 pk9real,                  -- averaging kernel weights
  wak_33 pk9real,                  -- averaging kernel weights
  wak_34 pk9real,                  -- averaging kernel weights
  wak_35 pk9real,                  -- averaging kernel weights
  wak_36 pk9real,                  -- averaging kernel weights
  wak_37 pk9real,                  -- averaging kernel weights
  wak_38 pk9real,                  -- averaging kernel weights
  wak_39 pk9real,                  -- averaging kernel weights
  wak_40 pk9real,                  -- averaging kernel weights
  wak_41 pk9real,                  -- averaging kernel weights
  wak_42 pk9real,                  -- averaging kernel weights
  wak_43 pk9real,                  -- averaging kernel weights
  wak_44 pk9real,                  -- averaging kernel weights
  wak_45 pk9real,                  -- averaging kernel weights
  wak_46 pk9real,                  -- averaging kernel weights
  wak_47 pk9real,                  -- averaging kernel weights
  wak_48 pk9real,                  -- averaging kernel weights
  wak_49 pk9real,                  -- averaging kernel weights
  wak_50 pk9real,                  -- averaging kernel weights
  pak_1 pk9real,                  -- averaging kernel pressures
  pak_2 pk9real,                  -- averaging kernel pressures
  pak_3 pk9real,                  -- averaging kernel pressures
  pak_4 pk9real,                  -- averaging kernel pressures
  pak_5 pk9real,                  -- averaging kernel pressures
  pak_6 pk9real,                  -- averaging kernel pressures
  pak_7 pk9real,                  -- averaging kernel pressures
  pak_8 pk9real,                  -- averaging kernel pressures
  pak_9 pk9real,                  -- averaging kernel pressures
  pak_10 pk9real,                  -- averaging kernel pressures
  pak_11 pk9real,                  -- averaging kernel pressures
  pak_12 pk9real,                  -- averaging kernel pressures
  pak_13 pk9real,                  -- averaging kernel pressures
  pak_14 pk9real,                  -- averaging kernel pressures
  pak_15 pk9real,                  -- averaging kernel pressures
  pak_16 pk9real,                  -- averaging kernel pressures
  pak_17 pk9real,                  -- averaging kernel pressures
  pak_18 pk9real,                  -- averaging kernel pressures
  pak_19 pk9real,                  -- averaging kernel pressures
  pak_20 pk9real,                  -- averaging kernel pressures
  pak_21 pk9real,                  -- averaging kernel pressures
  pak_22 pk9real,                  -- averaging kernel pressures
  pak_23 pk9real,                  -- averaging kernel pressures
  pak_24 pk9real,                  -- averaging kernel pressures
  pak_25 pk9real,                  -- averaging kernel pressures
  pak_26 pk9real,                  -- averaging kernel pressures
  pak_27 pk9real,                  -- averaging kernel pressures
  pak_28 pk9real,                  -- averaging kernel pressures
  pak_29 pk9real,                  -- averaging kernel pressures
  pak_30 pk9real,                  -- averaging kernel pressures
  pak_31 pk9real,                  -- averaging kernel pressures
  pak_32 pk9real,                  -- averaging kernel pressures
  pak_33 pk9real,                  -- averaging kernel pressures
  pak_34 pk9real,                  -- averaging kernel pressures
  pak_35 pk9real,                  -- averaging kernel pressures
  pak_36 pk9real,                  -- averaging kernel pressures
  pak_37 pk9real,                  -- averaging kernel pressures
  pak_38 pk9real,                  -- averaging kernel pressures
  pak_39 pk9real,                  -- averaging kernel pressures
  pak_40 pk9real,                  -- averaging kernel pressures
  pak_41 pk9real,                  -- averaging kernel pressures
  pak_42 pk9real,                  -- averaging kernel pressures
  pak_43 pk9real,                  -- averaging kernel pressures
  pak_44 pk9real,                  -- averaging kernel pressures
  pak_45 pk9real,                  -- averaging kernel pressures
  pak_46 pk9real,                  -- averaging kernel pressures
  pak_47 pk9real,                  -- averaging kernel pressures
  pak_48 pk9real,                  -- averaging kernel pressures
  pak_49 pk9real,                  -- averaging kernel pressures
  pak_50 pk9real,                  -- averaging kernel pressures
  apak_1 pk9real,                 -- averaging kernel prior profile
  apak_2 pk9real,                 -- averaging kernel prior profile
  apak_3 pk9real,                 -- averaging kernel prior profile
  apak_4 pk9real,                 -- averaging kernel prior profile
  apak_5 pk9real,                 -- averaging kernel prior profile
  apak_6 pk9real,                 -- averaging kernel prior profile
  apak_7 pk9real,                 -- averaging kernel prior profile
  apak_8 pk9real,                 -- averaging kernel prior profile
  apak_9 pk9real,                 -- averaging kernel prior profile
  apak_10 pk9real,                 -- averaging kernel prior profile
  apak_11 pk9real,                 -- averaging kernel prior profile
  apak_12 pk9real,                 -- averaging kernel prior profile
  apak_13 pk9real,                 -- averaging kernel prior profile
  apak_14 pk9real,                 -- averaging kernel prior profile
  apak_15 pk9real,                 -- averaging kernel prior profile
  apak_16 pk9real,                 -- averaging kernel prior profile
  apak_17 pk9real,                 -- averaging kernel prior profile
  apak_18 pk9real,                 -- averaging kernel prior profile
  apak_19 pk9real,                 -- averaging kernel prior profile
  apak_20 pk9real,                 -- averaging kernel prior profile
  apak_21 pk9real,                 -- averaging kernel prior profile
  apak_22 pk9real,                 -- averaging kernel prior profile
  apak_23 pk9real,                 -- averaging kernel prior profile
  apak_24 pk9real,                 -- averaging kernel prior profile
  apak_25 pk9real,                 -- averaging kernel prior profile
  apak_26 pk9real,                 -- averaging kernel prior profile
  apak_27 pk9real,                 -- averaging kernel prior profile
  apak_28 pk9real,                 -- averaging kernel prior profile
  apak_29 pk9real,                 -- averaging kernel prior profile
  apak_30 pk9real,                 -- averaging kernel prior profile
  apak_31 pk9real,                 -- averaging kernel prior profile
  apak_32 pk9real,                 -- averaging kernel prior profile
  apak_33 pk9real,                 -- averaging kernel prior profile
  apak_34 pk9real,                 -- averaging kernel prior profile
  apak_35 pk9real,                 -- averaging kernel prior profile
  apak_36 pk9real,                 -- averaging kernel prior profile
  apak_37 pk9real,                 -- averaging kernel prior profile
  apak_38 pk9real,                 -- averaging kernel prior profile
  apak_39 pk9real,                 -- averaging kernel prior profile
  apak_40 pk9real,                 -- averaging kernel prior profile
  apak_41 pk9real,                 -- averaging kernel prior profile
  apak_42 pk9real,                 -- averaging kernel prior profile
  apak_43 pk9real,                 -- averaging kernel prior profile
  apak_44 pk9real,                 -- averaging kernel prior profile
  apak_45 pk9real,                 -- averaging kernel prior profile
  apak_46 pk9real,                 -- averaging kernel prior profile
  apak_47 pk9real,                 -- averaging kernel prior profile
  apak_48 pk9real,                 -- averaging kernel prior profile
  apak_49 pk9real,                 -- averaging kernel prior profile
  apak_50 pk9real,                 -- averaging kernel prior profile
);




--
-- Table Definitions: gnssro (header-like table)
--
CREATE TABLE gnssro AS (
  radcurv pk9real,        -- RADIUS OF CURVATURE 
  undulation pk9real,        -- UNDULATION AT OBS LOCATION  
  gnssro_body @LINK,  
);


-- Filled by Meteo-France only
CREATE TABLE gnssro_body AS (
  obs_dndz pk9real,                     -- Vertical gradient of refractivity (dN/Dz in m-1) from the observation
  obs_refractivity pk9real,                     -- Refractivity observation
  bg_dndz pk9real,                     -- Vertical gradient of refractivity (dN/Dz in m-1) from the background
  bg_refractivity pk9real,                     -- Refractivity from the background
  bg_layerno pk9real,                     -- Background layer number in which the observation is found (1=layer
  obs_tvalue pk9real,                     -- observed temperature
  obs_zvalue pk9real,                     -- observed geopotential height
  bg_tvalue pk9real,                     -- background temperature
);


--
-- Table Definition: satob table
--

CREATE TABLE satob AS (
  comp_method pk1int,                   -- CLOUD MOTION COMP. METHOD
  instdata pk1int,                      -- INS. DATA USED IN PROC.
  dataproc pk1int,                      -- DATA PROC. TECHNIQUE USED
  QI_fc pk1int,                         -- EUMETSAT Quality Indicators: with forecast dependence
  QI_nofc pk1int,                       -- EUMETSAT Quality Indicators: without forecast dependence
  RFF pk1int,                           -- CIMSS Quality Indicator: Recursive Filter Flag
  EE pk9real,                           -- Expected Error [m/s]
  segment_size_x pk9real,               -- RESOLUTION, x-direction
  segment_size_y pk9real,               -- RESOLUTION, y-direction
  chan_freq pk9real,                    -- Satellite Channel Centre Frequency [Hz] (02197) for subtype=87 only
  tb pk9real,                           -- Coldest cluster temperature
  t pk9real,                            -- Temperature at SATOB p
  shear pk9real,                        -- Diff. in speed 50hPa above/below
  t200 pk9real,                         -- 200 hPa temperature
  t500 pk9real,                         -- 500 hPa temperature
  top_mean_t pk9real,                   -- Mean temperature between 80 hPa & p
  top_wv pk9real,                       -- Integrated WV above p
  dt_by_dp pk9real,                     -- Diff in temp. 50hPa above/below
  p_best pk9real,                       -- "Best fit" pressure
  u_best pk9real,                       -- U at "best fit" pressure
  v_best pk9real,                       -- V at "best fit" pressuree
  dd_best pk9real,                      -- wind direction at "best fit" pressure
  ff_best pk9real,                      -- wind speed at "best fit" pressure
  p_old pk9real,                        -- Originally assigned pressure
  u_old pk9real,                        -- U at old pressure
  v_old pk9real,                        -- V at old pressure
  height_assignment_method pk1int,      -- Height assignment method ( bufr code table 002231)
  tracer_correlation_method pk1int,     -- Tracer correlation method( bufr code table 002232)
  land_sea pk1int,                      -- Land/sea qualifier( bufr code table 008012)
  tracking_error_u pk9real,             -- Error in u due to AMV tracking (m/s)
  tracking_error_v pk9real,             -- Error in v due to AMV tracking (m/s)
  h_assignment_error_u pk9real,         -- Error in u due to to height assignment error (m/s)
  h_assignment_error_v pk9real,         -- Error in v due to to height assignment error (m/s)
  error_in_h_assignment pk9real,        -- Error in height assignment (Pa)
  ct_p pk9real,                         -- Cloud top pressure
  cb_p pk9real,                         -- Cloud base pressure
  umod_old pk9real,                     -- Model u at old pressure
  vmod_old pk9real,                     -- Model v at old pressure
);



--
-- Table Definition: scatt table
--
CREATE TABLE scatt AS (
  cellno pk1int,                        -- WAVE-VECTOR CELL NO.
  nretr_amb pk1int,                     -- NUMBER OF RETRIEVED AMBIGUITIES
  prodflag pk1int,                      -- ECMWF PRODUCT FLAG
  wvc_qf pk1int,                        -- ORIGINAL WIND VECTOR CELL QUALITY FLAG
  scatt_body @LINK,  
);


CREATE TABLE scatt_body AS (
  azimuth pk9real,                      -- BEAM AZIMUTH ANGLE
  incidence pk9real,                    -- BEAM INCIDENCE ANGLE
  Kp pk9real,                           -- Kp (INSTRUMENT NOISE; Antenna Noise)
  invresid pk9real,                     -- WIND-INVERSION RESIDUAL
  dirskill pk9real,                     -- DIRECTIONAL SKILL
  mpc pk1int,                           -- MISSING PACKET COUNTER
  Kp_qf pk1int,                         -- ASCAT Kp QUALITY FLAG
  ambig_select pk1int,                  -- Selected ambiguous wind, bit indicates outer loop (NUPTRA)
  sigma0_qf pk1int,                     -- SIGMA 0 USABILITY FLAG
  sigma0_sm pk9real,                    -- EFFECTIVE SIGMA0 FOR SOIL MOISTURE
  soilmoist_sd pk9real,                 -- SOIL MOISTURE STD ERROR
  soilmoist_cf pk1int,                 -- SOIL MOISTURE CORRECTION FLAG
  soilmoist_pf pk1int,                 -- SOIL MOISTURE PROCESSING FLAG
  land_fraction pk9real,                -- ASCAT LAND FRACTION
  wetland_fraction pk9real,             -- ASCAT WETLAND FRACTION
  topo_complex pk9real,                 -- ASCAT TOPOGRAPHIC COMPLEXITY
  likelihood pk9real,                 -- likelihood computed in the model (added for MF)
);



--
-- Table Definition: ssmi1d tables
-- These tables were used when ssmi data were assimilated with 1DVAR algorithm
-- Currently obsolete
--
CREATE TABLE ssmi AS (
  iterno_conv_1dvar pk1int,         -- NO. OF ITERATIONS 
  simno_conv_1dvar pk1int,          -- NO. OF SIMULATIONS 
  failure_1dvar pk1int,             -- FAILURE INDICATOR
  epsg_1dvar pk9real,               -- 1D VAR CONVERGENCE CRITERION
  minim_status_1dvar pk1int,        -- 1D VAR MINIMISATION STATUS
  surfpress_1 pk9real,             -- from slev, SFC PRESSURE
  skintemp_1 pk9real,              -- from slev, SKIN TEMPERATURE
  u10m_1 pk9real,                  -- from slev, U-WIND 10M
  u10m_2 pk9real,                  -- from slev, U-WIND 10M
  v10m_1 pk9real,                  -- from slev, V-WIND 10M
  v10m_2 pk9real,                  -- from slev, V-WIND 10M
  prec_st_1 pk9real,               -- new      , SFC STRAT. PRECIP.
  prec_st_2 pk9real,               -- new      , SFC STRAT. PRECIP.
  prec_cv_1 pk9real,               -- new      , SFC CONV. PRECIP.
  prec_cv_2 pk9real,               -- new      , SFC CONV. PRECIP.
  cost pk9real,                     -- Ratio of cost functions Jo/Jo_n
  sfc_rain_3d_fg pk9real,           -- Rain at FG from 3D model
  sfc_snow_3d_fg pk9real,           -- ditto snow
  sfc_rain_3d_an pk9real,           -- Rain at 4D-Var analysis from 3D model
  sfc_snow_3d_an pk9real,           -- ditto snow  
  rwp_1 pk9real,                   -- Rain, snow, cloud water and cloud ice paths [kg m^-2]
  rwp_2 pk9real,                   -- Rain, snow, cloud water and cloud ice paths [kg m^-2]
  rwp_3 pk9real,                   -- Rain, snow, cloud water and cloud ice paths [kg m^-2]
  rwp_4 pk9real,                   -- Rain, snow, cloud water and cloud ice paths [kg m^-2]
  swp_1 pk9real,                   -- ???
  swp_2 pk9real,                   -- ???
  swp_3 pk9real,                   -- ???
  swp_4 pk9real,                   -- ???
  cwp_1 pk9real,                   -- ???
  cwp_2 pk9real,                   -- ???
  cwp_3 pk9real,                   -- ???
  cwp_4 pk9real,                   -- ???
  iwp_1 pk9real,                   -- ???
  iwp_2 pk9real,                   -- ???
  iwp_3 pk9real,                   -- ???
  iwp_4 pk9real,                   -- ???
  ssmi_body @LINK,  
);


CREATE TABLE ssmi_body AS (
  tcwv_fg pk9real,         -- TCWV OBS -> MDB1BPWS  Used for 1D only 
  tcwv_fg_err pk9real,     -- TCWV FG  -> MDB1DREP
  radcost pk9real,         -- 1D VAR RADIANCE COST 
  rad_obs pk9real,    -- new, RADIANCE OBSERVATION
  rad_fg_depar pk9real,    -- new, RADIANCE FG DEPARTURE
  rad_an_depar pk9real,    -- new, RADIANCE AN DEPARTURE
  rad_obs_err pk9real,    -- new, RADIANCE OBS. ERROR
  rad_bias pk9real,    -- new, RADIANCE BIAS
  rad_fg_3d pk9real,    -- new, RADIANCES AT FG USING 3D MODEL CLOUDS
  rad_4dan pk9real,    -- new, RADIANCES AT 4D AN USING 3D MODEL CLOUDS
  frequency pk9real,       -- CHANNEL CENTRE FREQUENCY
  bandwidth pk9real,       -- CHANNEL BAND WIDTH
  polarisation pk9real,    -- ANTENNA POLARISATION
  press pk9real,           -- from mlev, PRESSURE
  temp_1 pk9real,         -- from mlev, TEMPERATURE
  temp_2 pk9real,         -- from mlev, TEMPERATURE
  q_1 pk9real,            -- from mlev, SPEC. HUMIDITY
  q_2 pk9real,            -- from mlev, SPEC. HUMIDITY
  rain_1 pk9real,         -- new      , LIQUID PRECIP FLUX
  rain_2 pk9real,         -- new      , LIQUID PRECIP FLUX
  snow_1 pk9real,         -- new      , FROZEN PRECIP FLUX.
  snow_2 pk9real,         -- new      , FROZEN PRECIP FLUX.
);



CREATE TABLE smos AS (
  snapshot_id pk1int,          -- snapshot indentifier
  grid_point_id pk1int,          -- grid point identifier
  electron_count pk9real,         -- total electron count 
  sun_bt pk9real,         -- direct sun BT
  snapshot_acc pk9real,         -- snapshot accuracy
  rad_acc_pure pk9real,         -- radiometric accuracy(pure polarisation)
  rad_acc_cross pk9real,         -- radiometric accuracy(cross polarisation)
  footprint_axis_1 pk9real,         -- footprint axis
  footprint_axis_2 pk9real,         -- footprint axis
  polarisation pk1int,          -- polarisation
  water_fraction pk9real,         -- water fraction
  incidence_angle pk9real,         -- incidence angle
  faradey_rot_angle pk9real,         -- faradey ratational angle
  pixel_rot_angle pk9real,         -- pixel radiometric accuracy
  info pk1int,          -- smos information flag
  snapshot_quality pk1int,          -- snapshot owerall quality
  report_tbflag pk1int,          -- observation flag in grid point
  tbvalue pk9real,         -- modelled brightness temperature
  nobs_averaged pk1int,          -- number of obs. used for averaging obsvalues (mask can be 2x2, 3x3, etc.)
  stdev_averaged pk9real,         -- Standard deviation of averaged values
);



CREATE TABLE radar_station AS (
  ident pk1int,          -- radar identifier
  type string,          -- type of radar
  lat pk9real,         -- latitude of the radar
  lon pk9real,         -- longitude of the radar
  stalt pk9real,         -- altitude of the radar
  antenht pk9real,         -- height of the antenna
  beamwidth pk9real,         -- aperture at 3dBz
  frequency pk9real,         -- pulse frequency
);



--
-- Table Definition: radar tables
-- Used by MF
--
SET $mx_radar_niv = 15;
CREATE TABLE radar AS (
  iternoconv_1dv pk1int,          -- Number of iterations (1DVAR)
  failure_1dv pk1int,          -- Error indicator (1DVAR) 
  qmod_1 pk9real,      -- humidity at model levels 
  qmod_2 pk9real,      -- humidity at model levels 
  qmod_3 pk9real,      -- humidity at model levels 
  qmod_4 pk9real,      -- humidity at model levels 
  qmod_5 pk9real,      -- humidity at model levels 
  qmod_6 pk9real,      -- humidity at model levels 
  qmod_7 pk9real,      -- humidity at model levels 
  qmod_8 pk9real,      -- humidity at model levels 
  qmod_9 pk9real,      -- humidity at model levels 
  qmod_10 pk9real,      -- humidity at model levels 
  qmod_11 pk9real,      -- humidity at model levels 
  qmod_12 pk9real,      -- humidity at model levels 
  qmod_13 pk9real,      -- humidity at model levels 
  qmod_14 pk9real,      -- humidity at model levels 
  qmod_15 pk9real,      -- humidity at model levels 
  zsimp_1 pk9real,      -- simple reflectivity          
  zsimp_2 pk9real,      -- simple reflectivity          
  zsimp_3 pk9real,      -- simple reflectivity          
  zsimp_4 pk9real,      -- simple reflectivity          
  zsimp_5 pk9real,      -- simple reflectivity          
  zsimp_6 pk9real,      -- simple reflectivity          
  zsimp_7 pk9real,      -- simple reflectivity          
  zsimp_8 pk9real,      -- simple reflectivity          
  zsimp_9 pk9real,      -- simple reflectivity          
  zsimp_10 pk9real,      -- simple reflectivity          
  zsimp_11 pk9real,      -- simple reflectivity          
  zsimp_12 pk9real,      -- simple reflectivity          
  zsimp_13 pk9real,      -- simple reflectivity          
  zsimp_14 pk9real,      -- simple reflectivity          
  zsimp_15 pk9real,      -- simple reflectivity          
  radar_body @LINK, 
);


CREATE TABLE radar_body AS (
  flgdyn pk1int,              -- dynamic quality flag 
  time HHMMSS,              -- Site starting hour associated to one pixel ???
  distance pk9real,             -- distance to the radar (meters) 
  elevation pk9real,             -- elevation 
  polarisation pk9real,             -- polarity
  anaprop pk1int,              -- Indicator of anaprop ???
  reflcost pk9real,             -- Cost function of the 1DVAR 
  azimuth pk9real,             -- azimuth (of the measurement (angle N/radar->pixel))
  press pk9real,            -- pressure 1Dvar
  temp_1 pk9real,            -- temperature 1Dvar
  temp_2 pk9real,            -- temperature 1Dvar
  q_1 pk9real,            -- specific humidity 
  q_2 pk9real,            -- specific humidity 
  temp_1dv pk9real,            -- error 1Dvar for temperature
  q_1dv pk9real,            -- error 1Dvar for humidity 
);




-- The following depends on rtlimb instruments (jpmxtan in mod_rtlimb_cparam),
-- so watch for it!
SET $mx_limb_tan = 17;

CREATE TABLE limb AS (
  ntan pk1int,                           -- Number of sweeps
  ztan_1 pk9real,            -- Tangent height
  ztan_2 pk9real,            -- Tangent height
  ztan_3 pk9real,            -- Tangent height
  ztan_4 pk9real,            -- Tangent height
  ztan_5 pk9real,            -- Tangent height
  ztan_6 pk9real,            -- Tangent height
  ztan_7 pk9real,            -- Tangent height
  ztan_8 pk9real,            -- Tangent height
  ztan_9 pk9real,            -- Tangent height
  ztan_10 pk9real,            -- Tangent height
  ztan_11 pk9real,            -- Tangent height
  ztan_12 pk9real,            -- Tangent height
  ztan_13 pk9real,            -- Tangent height
  ztan_14 pk9real,            -- Tangent height
  ztan_15 pk9real,            -- Tangent height
  ztan_16 pk9real,            -- Tangent height
  ztan_17 pk9real,            -- Tangent height
  ptan_1 pk9real,            -- Tangent pressure
  ptan_2 pk9real,            -- Tangent pressure
  ptan_3 pk9real,            -- Tangent pressure
  ptan_4 pk9real,            -- Tangent pressure
  ptan_5 pk9real,            -- Tangent pressure
  ptan_6 pk9real,            -- Tangent pressure
  ptan_7 pk9real,            -- Tangent pressure
  ptan_8 pk9real,            -- Tangent pressure
  ptan_9 pk9real,            -- Tangent pressure
  ptan_10 pk9real,            -- Tangent pressure
  ptan_11 pk9real,            -- Tangent pressure
  ptan_12 pk9real,            -- Tangent pressure
  ptan_13 pk9real,            -- Tangent pressure
  ptan_14 pk9real,            -- Tangent pressure
  ptan_15 pk9real,            -- Tangent pressure
  ptan_16 pk9real,            -- Tangent pressure
  ptan_17 pk9real,            -- Tangent pressure
  thtan_1 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_2 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_3 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_4 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_5 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_6 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_7 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_8 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_9 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_10 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_11 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_12 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_13 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_14 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_15 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_16 pk9real,           -- Along-orbit angle, relative to lat/long
  thtan_17 pk9real,           -- Along-orbit angle, relative to lat/long
  cloud_index_1 pk9real,     -- Remedios & Spang cloud index
  cloud_index_2 pk9real,     -- Remedios & Spang cloud index
  cloud_index_3 pk9real,     -- Remedios & Spang cloud index
  cloud_index_4 pk9real,     -- Remedios & Spang cloud index
  cloud_index_5 pk9real,     -- Remedios & Spang cloud index
  cloud_index_6 pk9real,     -- Remedios & Spang cloud index
  cloud_index_7 pk9real,     -- Remedios & Spang cloud index
  cloud_index_8 pk9real,     -- Remedios & Spang cloud index
  cloud_index_9 pk9real,     -- Remedios & Spang cloud index
  cloud_index_10 pk9real,     -- Remedios & Spang cloud index
  cloud_index_11 pk9real,     -- Remedios & Spang cloud index
  cloud_index_12 pk9real,     -- Remedios & Spang cloud index
  cloud_index_13 pk9real,     -- Remedios & Spang cloud index
  cloud_index_14 pk9real,     -- Remedios & Spang cloud index
  cloud_index_15 pk9real,     -- Remedios & Spang cloud index
  cloud_index_16 pk9real,     -- Remedios & Spang cloud index
  cloud_index_17 pk9real,     -- Remedios & Spang cloud index
  window_rad_1 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_2 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_3 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_4 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_5 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_6 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_7 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_8 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_9 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_10 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_11 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_12 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_13 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_14 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_15 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_16 pk9real,      -- Radiance in 960.7 cm-1 channel
  window_rad_17 pk9real,      -- Radiance in 960.7 cm-1 channel
);


--
-- Table Definition: body table
--
CREATE TABLE body AS (
  entryno pk1int,                      -- ENTRY SQ. NO. 
  obsvalue pk9real,                     -- OBSERVED VARIABLE as used in IFS (may contain noise correction, etc.)
  varno pk1int,                      -- VARIABLE NUMBER
  vertco_type pk1int,                      -- VERTICAL COORDINATE TYPE
  vertco_reference_1 pk9real,                     -- VERTICAL COORDINATE REFERENCE 1
  vertco_reference_2 pk9real,                     -- VERTICAL COORDINATE REFERENCE 2
  datum_anflag DATUM_FLAG_t,                -- OBSERVATION FLAGS
  datum_status status_t,   -- New feature; equivalent to old def : "status STATUS_t"
  datum_event1 DATUM_EVENT1_t,              -- OBSERVATION EVENTS (PART 1)
  datum_rdbflag DATUM_RDBFLAG_t,             -- OBSERVATION FLAGS (RDB)
  datum_blacklist DATUM_BLACKLIST_t,           -- OBSERVATION BLACKLIST EVENTS
  datum_event2 DATUM_EVENT2_t,              -- DATUM EVENTS (PART 2) WORD POS.
  varbc_ix pk1int,                      -- VarBC group index
  biascorr pk9real,                     -- RADIANCE BIAS CORRECTION
  biascorr_fg pk9real,                     -- FG bias correction
  tbcorr pk9real,                     -- Correction to Brightness temperature (radiance only)
  bias_volatility pk9real,                     -- Estimated volatility of the observation bias
  wdeff_bcorr pk9real,                     -- Wind-induced error bias correction for rain gauges
  an_depar pk9real,                     -- OBSERVED MINUS ANALYSED VALUE
  fg_depar pk9real,                     -- OBSERVED MINUS FIRST GUESS VALUE
  actual_depar pk9real,                     -- We store the actual departure during the minimization
  actual_ndbiascorr pk9real,                     -- Store the actual normalised bias difference during minimisation
  qc_a pk9real,                     -- VAR QC prior probability of gross error (by variable and obstype) 
  qc_l pk9real,                     -- VAR QC width of the distribution
  qc_pge pk9real,                     -- VAR QC a posteriori probability of gross error
  fc_sens_obs pk9real,                     -- forecast sensitivity to the observations
  an_sens_obs pk9real,                     -- analysis sensitivity to the obs
  jacobian_peak pk9real,  -- used for ENKF; to move to radiance_body and gnssro_body
  jacobian_peakl pk9real, -- used for ENKF; to move to radiance_body and gnssro_body
  jacobian_hpeak pk9real, -- used for ENKF; to move to radiance_body and gnssro_body
  jacobian_hpeakl pk9real, -- used for ENKF; to move to radiance_body and gnssro_body
  mf_vertco_type pk1int,                      -- vertical coordinate type
  mf_log_p pk9real,                     -- pressure used in CANARI (Log P)
  mf_stddev pk9real,                     -- obs. std dev at bottom layer
  nlayer pk1int,                      -- layer number used in resat varbc  
);



-- To be cleaned. 
CREATE TABLE errstat AS (
  final_obs_error pk9real,              -- FINAL OBSERVATION ERROR (combination of Prescribed and persistence errors)
  obs_error pk9real,                    -- Prescribed observation error
  repres_error pk9real,                 -- REPRESENTATIVENESS ERROR
  pers_error pk9real,                   -- PERSISTENCE ERROR
  fg_error pk9real,                     -- FIRST GUESS ERROR
  eda_spread pk9real,                   -- SPREAD FROM EDA
  obs_ak_error pk9real,                 -- OBSERVATION ERROR WITHOUT CONTRIBUTION FROM PROFILE ERROR
  obs_corr_ev_1 pk9real,          -- OBS. ERR. CORRELATION EIGENVECTORS
  obs_corr_mask pk1int,                 -- OBS. ERROR CORRELATION MASK
  obs_corr_diag_1 pk9real,      -- OBS. ERR. CORRELATION DIAGNOSTICS
);



-- The following declares up to $NMXUPD update-tables with
-- the naming convention update_1, update_2, ..., update_<$NMXUPD>.
-- Each of them has got exactly the same attributes.
-- Note: It is up to the software to decide how many of these tables will
-- actually be filled !!

-- To be cleaned!!! These table should be used to make sure we can restart an IFS task
-- without having to store the entire CCMA/ECMAs.
CREATE TABLE update_1 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_2 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_3 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_4 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_5 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_6 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_7 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_8 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_9 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);

CREATE TABLE update_10 AS (
  hires pk9real,               -- OBS. MINUS UPD. U HIGH RES. VALUE (filled by each trajectory)
  lores pk9real,               -- OBS. MINUS UPD. U LOW RES. VALUE  (filled by each minimisation)
  datum_tbflag_hires pk1int,         -- Status flag for all-sky  - See yommwave.F90 (for backup to avoid CCMA copy)
  datum_status_hires status_t, -- Status flag at hires (for backup to avoid CCMA copy)
);



--
-- Table Definition: aeolus tables
--

-- aeolus header table, things that don't change at measurement level
CREATE TABLE aeolus_hdr AS (
  aeolus_hdrflag aeolus_hdrflag_t,      -- Aeolus header flags
  aeolus_auxmet @LINK, 
  aeolus_l2c @LINK, 
  aeolus_l2b @LINK,
);


-- table for auxiliary meteorological data
CREATE TABLE aeolus_auxmet AS (
  lev pk9real,              -- Model level (zero for surface values)
  ptop pk9real,              -- Pressure at top of layer
  pnom pk9real,              -- Nominal pressure within layer
  ztop pk9real,              -- Geopotential height at top of layer
  znom pk9real,              -- Nominal geopotential height within layer
  u pk9real,              -- Uwind
  v pk9real,              -- Vwind
  t pk9real,              -- Temperature
  rh pk9real,              -- Relative humidity
  q pk9real,              -- Specific humidity
  cc pk9real,              -- Cloud cover
  clwc pk9real,              -- Cloud liquid water content
  ciwc pk9real,              -- Cloud ice water content
  error_t pk9real,              -- Error estimate for temperature
  error_rh pk9real,              -- Error estimate for relative humidity
  error_p pk9real,              -- Error estimate for pressure
);


-- table for Level 2C products
CREATE TABLE aeolus_l2c AS (
  hlos_ob_err pk9real,              -- Final HLOS obs error
  hlos_fg pk9real,              -- HLOS from first guess
  u_fg pk9real,              -- First guess zonal wind
  u_fg_err pk9real,              -- u component first guess error
  v_fg pk9real,              -- First guess meridional wind
  v_fg_err pk9real,              -- v component first guess error
  hlos_fg_err pk9real,              -- HLOS err from first guess
  hlos_an pk9real,              -- HLOS from analysis
  hlos_an_err pk9real,              -- HLOS err from analysis
  u_an pk9real,              -- Analysis zonal wind
  v_an pk9real,              -- Analysis meridional wind
);


-- table for Level 2B meta data
CREATE TABLE aeolus_l2b AS (
  t_ref pk9real,              -- Reference temperature used in retrieval
  p_ref pk9real,              -- Reference pressure used in retrieval
  beta pk9real,              -- Scattering ratio for observation
  dhlos_dt pk9real,              -- Derivative of HLOS wind wrt temperature
  dhlos_dp pk9real,              -- Derivative of HLOS wind wrt pressure
  dhlos_dbeta pk9real,              -- Derivative of HLOS wind wrt scattering ratio
  horiz_length pk9real,              -- Observation horizontal length-scale
  vert_length pk9real,              -- Observation vertical length-scale
  conf_flag pk1int,               -- Confidence flag
);





