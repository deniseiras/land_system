//
// Table Definition: allsky tables
//
CREATE TABLE allsky AS (
  fg_rain_rate             pk9real,      // Surface rain @ FG [mm h-1] 
  fg_snow_rate             pk9real,      // Surface frozen precipitation @ FG [ mm h-1]
  fg_tcwv                  pk9real,      // Total column water vapour @ FG [ kg m-2]
  fg_cwp                   pk9real,      // Cloud liquid water path @ FG [ kg m-2 ] 
  fg_iwp                   pk9real,      // Cloud ice water path @ FG [ kg m-2 ]
  fg_rwp                   pk9real,      // Rain water path @ FG [ kg m-2 ]
  fg_swp                   pk9real,      // Snow water path @ FG [ kg m-2 ] 
  fg_rttov_cld_fraction    pk9real,      // Cloud fraction used in RTTOV_SCATT [0-1] 
  fg_theta700              pk9real,      // Potential Temperature in 700hPa @ FG [K]
  fg_thetasfc              pk9real,      // Potential Temperature at the surface @ FG [K]
  fg_uth                   pk9real,      // 200-500hPa weighted average relative humidity wrt water @ FG [0-1] 
  fg_conv                  pk9real,      // convection type 
  fg_pbl                   pk9real,      // PBL type 
 
  an_rain_rate             pk9real,      // Surface rain @ AN [mm h-1] 
  an_snow_rate             pk9real,      // Surface frozen precipitation @ AN [ mm h-1]
  an_tcwv                  pk9real,      // Total column water vapour @ AN [ kg m-2]
  an_cwp                   pk9real,      // Cloud liquid water path @ AN [ kg m-2 ] 
  an_iwp                   pk9real,      // Cloud ice water path @ AN [ kg m-2 ]
  an_rwp                   pk9real,      // Rain water path @ AN [ kg m-2 ]
  an_swp                   pk9real,      // Snow water path @ AN [ kg m-2 ] 
  an_rttov_cld_fraction    pk9real,      // Cloud fraction used in RTTOV_SCATT [0-1] 
  an_theta700              pk9real,      // Potential Temperature in 700hPa @ FG [K]
  an_thetasfc              pk9real,      // Potential Temperature at the surface @ FG [K]
  an_uth                   pk9real,      // 200-500hPa weighted average relative humidity wrt water @ AN [0-1] 
  an_conv                  pk9real,      // convection type 
  an_pbl                   pk9real,      // PBL type 
                   
  gnorm_10mwind            pk9real,      // Norm of gradient against 10m wind 
  gnorm_skintemp           pk9real,      // Norm of gradient against skin temperature 
  gnorm_temp               pk9real,      // Norm of gradient against temperature
  gnorm_q                  pk9real,      // Norm of gradient against specific humidity 
  gnorm_rainflux           pk9real,      // Norm of gradient against rain flux 
  gnorm_snowflux           pk9real,      // Norm of gradient against snow flux
  gnorm_clw                pk9real,      // Norm of gradient against cloud water
  gnorm_ciw                pk9real,      // Norm of gradient against cloud ice
  gnorm_cc                 pk9real,      // Norm of gradient against cloud cover

  ob_p19                   pk9real,      // 19 GHz normalised polarisation difference observed
  fg_p19                   pk9real,      // 19 GHz normalised polarisation difference first guess
  an_p19                   pk9real,      // 19 GHz normalised polarisation difference analysis
  
  ob_p37                   pk9real,      // 19 GHz normalised polarisation difference observed
  fg_p37                   pk9real,      // 19 GHz normalised polarisation difference first guess
  an_p37                   pk9real,      // 19 GHz normalised polarisation difference analysis

  report_tbcloud           pk1int,       // Cloud and rain cloud bitfield flag determined from TB bitfield - See yommwave.F90
  allsky_body              @LINK,
);

CREATE TABLE allsky_body AS (
  tbvalue                 pk9real,       // Simulated brightness temperature
  tbvaluetl               pk9real,       // Simulated TL of brightness temperature
  tbvaluead               pk9real,       // Simulated AD in brightness temperature
  datum_tbflag            pk1int,        // Status flag for all-sky  - See yommwave.F90
);

