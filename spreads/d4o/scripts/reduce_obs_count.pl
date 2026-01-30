#!/usr/bin/env perl

use strict;
use warnings;

my ($min,$max) = (shift @ARGV, shift @ARGV);

exit 0 unless (defined($min) && defined($max));

my $input = do { local $/; <>; };

my $num_obs = 0;
my $max_num_obs = 0;
my $first = undef;
my $last = 0;

my $header = undef;
my %obs = ();
if ($input =~ m{^(\s*obs_sequence.*\s+last:\s+\d+)\s*$}ms) {
    $header = $1;
    $input =~ s{(\s*OBS\s+\d+)}{\n\a$1}g;
    $input .= "\a";
    while ($input =~ m{\n(\s*OBS\s+\d+.*?)\n\a}msg) {
	my $obs = $1;
	if ($obs =~ m{^\s*OBS\s+(\d+)}) {
	    my $num = $1;
	    if ($min <= $num && $num <= $max) {
		#printf("%s\n",$obs);
		$obs{$num} = $obs;
		$first = $num unless (defined($first));
		$last = $num;
		++$num_obs;
		$max_num_obs = $num if ($max_num_obs < $num);
	    }
	}
    }
}

if (defined($header)) {
    $num_obs = sprintf("%12d",$num_obs);
    $max_num_obs = sprintf("%12d",$max_num_obs);
    $header =~ s{\n(\s+num_obs:)\s+\d{1,12}(\s+max_num_obs:)\s+\d{1,12}}{\n$1 ${num_obs}$2 ${max_num_obs}}ms;
    
    $first = 0 unless (defined($first));
    $first = sprintf("%12d",$first);
    $last = sprintf("%12d",$last);
    $header =~ s{\n(\s+first:)\s+\d{1,12}(\s+last:)\s+\d{1,12}}{\n$1 ${first}$2 ${last}}ms;
    printf("%s\n",$header);

    my $prev = -1;
    my @next = sort {$a <=> $b} keys %obs;
    shift @next;
    push(@next,-1);
    my $idx = 0;
    for my $num (sort {$a <=> $b} keys %obs) {
	my $obs = $obs{$num};
	$prev = sprintf("%12d",$prev);
	my $next = $next[$idx++];
	$next = sprintf("%12d",$next);
	$obs =~ s{(OBS\s+\d+.*\n)(\s{10}-1|\s+\d{1,12})(\s{10}-1|\s+\d{1,12})(\s{10}-1)}{$1${prev}${next}$4}ms;
	printf("%s\n",$obs);
	$prev = $num;
    }
}

__DATA__
 obs_sequence
obs_type_definitions
          23
           4 GPSRO_REFRACTIVITY             
           5 RADIOSONDE_U_WIND_COMPONENT    
           6 RADIOSONDE_V_WIND_COMPONENT    
           9 RADIOSONDE_TEMPERATURE         
          10 RADIOSONDE_SPECIFIC_HUMIDITY   
          16 AIRCRAFT_U_WIND_COMPONENT      
          17 AIRCRAFT_V_WIND_COMPONENT      
          18 AIRCRAFT_TEMPERATURE           
          20 ACARS_U_WIND_COMPONENT         
          21 ACARS_V_WIND_COMPONENT         
          22 ACARS_TEMPERATURE              
          24 MARINE_SFC_U_WIND_COMPONENT    
          25 MARINE_SFC_V_WIND_COMPONENT    
          26 MARINE_SFC_TEMPERATURE         
          27 MARINE_SFC_SPECIFIC_HUMIDITY   
          34 SAT_U_WIND_COMPONENT           
          35 SAT_V_WIND_COMPONENT           
          37 AIRS_TEMPERATURE               
          38 AIRS_SPECIFIC_HUMIDITY         
          44 RADIOSONDE_SURFACE_ALTIMETER   
          46 MARINE_SFC_ALTIMETER           
          47 LAND_SFC_ALTIMETER             
         214 EOS_2_AMSUA_TB                 
  num_copies:            1  num_qc:            1
  num_obs:       993302  max_num_obs:       993302
observation                                                     
Data QC                                                         
  first:            1  last:       993302
 OBS            1
   228.401260375977     
  0.000000000000000E+000
          -1           2          -1
obdef
loc3d
     2.754002041236042       -0.9615621751400152         15000.00000000000      2
kind
         214
 mw   
  -84.6431801030405        47.9048423767090     
           9           2           3           8
  -888888.000000000       -888888.000000000     
   3.00000000000000        5.00000000000000        15.0000000000000     
  0.100000000000000       0.300000000000000     
       59228
 54002     152225
  2.250000178813938E-002
 OBS            2
   226.635696411133     
  0.000000000000000E+000
           1           3          -1
obdef
loc3d
     2.754002041236042       -0.9615621751400152         9000.000000000000      2
kind
         214
 mw   
  -84.6431801030405        47.9048423767090     
           9           2           3           9
  -888888.000000000       -888888.000000000     
   3.00000000000000        5.00000000000000        15.0000000000000     
  0.100000000000000       0.300000000000000     
       59229
 54002     152225
  2.250000178813938E-002
 OBS            3
   226.553207397461     
  0.000000000000000E+000
           2           4          -1
obdef
loc3d
     2.754002041236042       -0.9615621751400152         5000.000000000000      2
kind
         214
 mw   
  -84.6431801030405        47.9048423767090     
           9           2           3          10
  -888888.000000000       -888888.000000000     
   3.00000000000000        5.00000000000000        15.0000000000000     
  0.100000000000000       0.300000000000000     
       59230
 54002     152225
  2.250000178813938E-002
