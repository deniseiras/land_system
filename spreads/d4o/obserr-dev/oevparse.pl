#!/usr/bin/env perl

use strict;
use warnings;

our $schema_file = exists($ENV{"ODB_SCHEMA_FILE"}) ? $ENV{"ODB_SCHEMA_FILE"} : "../ECMWF/b2o-0.10.0-Source/share/b2o/cma.ddl";
$schema_file = undef unless (defined($schema_file) && -r $schema_file);

our $schema_dir = exists($ENV{"ODB_SCHEMA_DIR"}) ? $ENV{"ODB_SCHEMA_DIR"} : undef;
$schema_dir = qx(dirname $schema_file), chomp($schema_dir) if (!defined($schema_dir) && defined($schema_file) && -r $schema_file);

our $oevdb = "oev.db";
unless (-r $oevdb) {
    $oevdb = sprintf("%s/oev.db",$schema_dir) if (defined($schema_dir) && -d $schema_dir);
}
$oevdb = undef unless (defined($oevdb) && -r $oevdb);
our %oev_cache = (); # key as {reportype,obstype,codetype,geoarea,varclass} => value as {varnos,levtype,levs,oevars}

# Keep $varclass consistent with ../scripts/obseqd4o (apart from dd & ff)
our $varclass = {
    WIND => "u|v|dd|ff", # drop dd & ff from the final version
    TEMP => "t",
    HEIG => "z",
    TB => "rawbt",
    GPSRO => "refrac",
    PS => "ps",
    T2M => "t2m",
    W10M => "u10m|v10m",
    PRC => "q2m",
};

our $ecmwf_varno_descr = undef;
$ecmwf_varno_descr = sprintf("%s/ecmwf_varno_descr.db",$schema_dir) if (defined($schema_dir) && -d $schema_dir);
$ecmwf_varno_descr = undef unless (defined($ecmwf_varno_descr) && -r $ecmwf_varno_descr);

our $stdlevdb = undef;
$stdlevdb = sprintf("%s/std_plevels.db",$schema_dir) if (defined($schema_dir) && -d $schema_dir);
$stdlevdb = undef unless (defined($oevdb) && -r $stdlevdb);
our %plevel = (); # key = {id} => value = {plevel} -- NB: plevel in Pascals
our %log_plevel = (); # key = {id} => value = {plevel} -- log_plevel = ln(plevel) pre-calculated for convenience (plevel in Pascals)

printf("### %s",qx(basename $stdlevdb));
{
    my $sql = sprintf("SELECT id,plevel,log_plevel FROM std_plevels");
    my $cmd = sprintf("sqlite3 -batch -init /dev/null -nullvalue NULL -readonly -csv %s \"%s\"",$stdlevdb,$sql);
    printf("Running %s\n",$cmd);
    open(IN,"$cmd |") || die "$cmd";
    my @in = <IN>;
    close(IN);
    for (@in) {
	chomp;
	s/\"//g;
	printf("%s\n",$_);
	my ($id,$plevel,$log_plevel) = split(/,/,$_);
	$plevel{$id} = $plevel;
	$log_plevel{$id} = $log_plevel;
    }
    for (sort { $a <=> $b } keys %plevel) {
	my ($id,$plevel,$log_plevel) = ($_,$plevel{$_},$log_plevel{$_});
	printf("std level %2d = %-20s : natural log (ln) = %-20s\n",$id,$plevel,$log_plevel);
    }
}
printf("\n");

printf("### %s",qx(basename $ecmwf_varno_descr));
for (sort keys %$varclass) {
    my ($key,$value) = ($_,$varclass->{$_});
    my $sql = sprintf("SELECT GROUP_CONCAT(varno,'|') FROM ecmwf_varno_descr WHERE description REGEXP '^\\s*(%s)\\s*--\\s*'",$value);
    my $cmd = sprintf("sqlite3 -batch -init /dev/null -nullvalue NULL -readonly -csv %s \"%s\"",$ecmwf_varno_descr,$sql);
    printf("Running %s\n",$cmd);
    open(IN,"$cmd |") || die "$cmd";
    my @in = <IN>;
    close(IN);
    my $nin = @in;
    printf("%s => %s -- %d records\n",$key,$value,$nin);
    for (@in) {
	chomp;
	s/\"//g;
	printf(" => %s",$_);
	$varclass->{$key} = $_;
    }
    printf("\n");
}
printf("\n");

printf("### %s",qx(basename $oevdb));
for (sort keys %$varclass) {
    my ($key,$value) = ($_,$varclass->{$_});
    my $sql = sprintf("SELECT reportype,obstype,codetype,geoarea,varclass,levtype,levs,oevars FROM oev WHERE varclass = '%s' AND geoarea = 1",$key); # we care about area = 1 only for now
    my $cmd = sprintf("sqlite3 -batch -init /dev/null -nullvalue NULL -readonly -csv %s \"%s\"",$oevdb,$sql);
    printf("Running %s\n",$cmd);
    open(IN,"$cmd |") || die "$cmd";
    my @in = <IN>;
    close(IN);
    my $nin = @in;
    printf("%s => %s -- %d records\n",$key,$value,$nin);
    for (@in) {
	chomp;
	s/\"//g;
	printf("  %s\n",$_);
	my ($reportype,$obstype,$codetype,$geoarea,$classkey,$levtype,$levs,$oevars) = split(/,/,$_);
	#my @levs = split(/:/,$levs);
	my $oevkey = sprintf("%d,%d,%d,%d,%s",$reportype,$obstype,$codetype,$geoarea,$classkey);
	my $varnos = $varclass->{"$classkey"};
	$oev_cache{$oevkey} = sprintf("%s,%s,%s,%s",$varnos,$levtype,$levs,$oevars);
    }
}
printf("\n");

my $db = "sample.db";
printf("### %s",qx(basename $db));
printf("%%oev=\n");
for (sort keys %oev_cache) {
    my ($key,$value) = ($_,$oev_cache{$_});
    my ($reportype,$obstype,$codetype,$geoarea,$classkey) = split(/,/,$key);
    my ($varnos,$levtype,$levs,$oevars) = split(/,/,$value);
    $varnos =~ s/\|/,/g;
    $geoarea = 1; # always for now
    my $sql = sprintf("SELECT IIF(reportype=%d,reportype,-1),obstype,codetype,IIF(geoarea=1,geoarea,1),varno,levelht,vertco_type,obs_error_variance FROM sample WHERE varno IN (%s) AND obstype = %d AND codetype = %d",
		      $reportype,$varnos,$obstype,$codetype);
    my $cmd = sprintf("sqlite3 -batch -init /dev/null -nullvalue NULL -readonly -csv %s \"%s\"",$db,$sql);
    printf("Running %s\n",$cmd);
    open(IN,"$cmd |") || die "$cmd";
    my @in = <IN>;
    close(IN);
    my $nin = @in;
    if ($nin > 0) {
	$cmd =~ s/\"/\n\t"/;
	printf("%s: %s => %s : %d records matched\n  %s\n",$classkey,$key,$value,$nin,$cmd);
    }
    else {
	#printf("%s: %s -- no match\n",$classkey,$key);
    }
    for (@in) {
	chomp;
	s/\"//g;
	printf("  %s",$_);
	my ($_reportype,$_obstype,$_codetype,$_geoarea,$_varno,$_levelht,$_vertco_type,$oev) = split(/,/,$_);
	if ($_vertco_type == 2) {
	    # convert geopotential height (m) to pressure (Pascals)
	    $_levelht = &ICAO_ht2ps($_levelht);
	    $_vertco_type = 1;
	}
	printf(" => %s",join(",",($_reportype,$_obstype,$_codetype,$_geoarea,$_varno,$_levelht,$_vertco_type,$oev)));
	printf("\n");
    }
}

exit 0;

sub ICAO_ht2ps {
    # ICAO height (m) to pressure (Pascal) conversion
    my ($ht) = @_; # geopotential height in metres
    return undef unless (defined($ht));
    my $g = 9.80665; # WMO "g" (not used here)
    my $ZA = 5.252368255329;
    my $ZB = 44330.769230769;
    my $ZC = 0.000157583169442;
    my $ZP0 = 101325.00; # Pascals
    my $ZP11 = 22654.7172; # Pascals
    my $ZZ11 = 11000.0;
    my $p = undef;
    if ($ht <= $ZZ11) {
        $p = $ZP0 * (1.0-$ht/$ZB)**$ZA;
    }
    else {
        $p = $ZP11 * exp(-$ZC*($ht-$ZZ11));
    }
    return $p; # pressure in Pascals
}

