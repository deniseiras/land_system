#!/usr/bin/env perl

use strict;
use warnings;

my $debug = exists($ENV{'OEVDEBUG'}) ? 1 : 0;

my $tmpdir = exists($ENV{'TMPDIR'}) ? $ENV{'TMPDIR'} : ".";

my %var = ();
my $oe = undef;

my $RG = undef;
my $ZRETUNE = undef;
my $IAREA = undef;

my $s = sprintf("#OE:text,obsname:text,codename:text,geoarea:int,reportype:int,nlevels:text,OEvar:text");

my @s = ();
push(@s,$s);

for (<DATA>) {
    chomp;
    
    next if (m{^\s*$} || m{^\s*\!} || m{^\s*#});
    s/\s+//g unless (m{:=});
    
    if (m{^(\w+)=(\S+)}) {
	printf(STDERR "\n".'Matched {^(\w+)=(\S+)} : %s'."\n",$_) if ($debug);
	my ($name,$value) = ($1,$2);
	if ($value =~ m{\*\b[A-Z]\w*} || $value =~ m{\d+\.\d+}) {
	    $value =~ s/\*\b([A-Z]\w*)/*\$$1/g if ($value =~ m{\*\b[A-Z]\w*});
	    my $evalme = sprintf("\$%s = %s",$name,$value);
	    printf(STDERR "evalme: %s\n",$evalme) if ($debug);
	    eval "$evalme";
	    my $tmp = 0;
	    $evalme = sprintf("\$tmp = %s",$value);
	    printf(STDERR "evalme: %s\n",$evalme) if ($debug);
	    eval "$evalme";
	    printf(STDERR "=> \$tmp = %s\n",defined($tmp) ? $tmp : "<undef>") if ($debug);
	    $value = $tmp;
	}
	$var{$name} = $value;
	printf(STDERR "%s=%s\n",$name,$value) if ($debug);
    }
    elsif (m{^\s*(\w+)\s*:=\s*(.*)\s*$}) {
	printf(STDERR "\n".'Matched {^\s*(\w+)\s*:=\s*(.*)\s*$} : %s'."\n",$_) if ($debug);
	my ($label,$cmd) = ($1,$2);
	open(IN,"$cmd |") || die "$cmd";
	my @in = <IN>;
	close(IN);
	for (@in) {
	    chomp;
	    s/^\s+//;
	    my ($channel,$value) = split(/\s+/);
	    my $name = sprintf("%s(%d)",$label,$channel);
	    $var{$name} = $value;
	    printf(STDERR "%s=%s\n",$name,$value) if ($debug);
	}
    }
    elsif (m{^(\S+)=(\S+)}) {
	printf(STDERR "\n".'Matched {^(\S+)=(\S+)} : %s'."\n",$_) if ($debug);
	my ($name,$value) = ($1,$2);
	if ($value =~ m{\*\b[A-Z]\w*} || $value =~ m{\d+\.\d+}) {
	    $value =~ s/\*\b([A-Z]\w*)/*\$$1/g if ($value =~ m{\*\b[A-Z]\w*});
	    my $tmp = 0;
	    my $evalme = sprintf("\$tmp = %s",$value);
	    printf(STDERR "evalme: %s\n",$evalme)  if ($debug);
	    eval "$evalme";
	    printf(STDERR "=> \$tmp = %s\n",defined($tmp) ? $tmp : "<undef>") if ($debug);
	    $value = $tmp;
	}
	$var{$name} = $value;
	printf(STDERR "%s=%s\n",$name,$value) if ($debug);
    }
    elsif (m{^\&(\w+)}) {
	printf(STDERR "\n".'Matched {^\&(\w+)} : %s'."\n",$_) if ($debug);
	$oe = uc($1);
	$var{'IAREA'} = 1;
	$var{'OT'} = "NULL";
	$var{'CT'} = "*";
	$var{'RT'} = -1;
    }
    elsif (m{^/}) {
	printf(STDERR "\n".'Matched {^/} : %s'."\n",$_) if ($debug);
	my @keys = ();
	printf(STDERR "oe=%s\n",$oe) if ($debug);
	for (keys %var) {
	    push(@keys,uc($_)) if (m{^$oe\(}i);
	}
	if (@keys) {
	    my @levs = ();
	    for (@keys) {
		push(@levs,$1) if (m{\((\d+)\)});
	    }
	    if (@levs) {
		my $iarea = $var{'IAREA'};
		@levs = sort { $a <=> $b } @levs;
		my @rtlist = &GetList($var{'RT'});
		if ($iarea == 1) {
		    for my $rt (@rtlist) {
			my $nlev = @levs;
			printf(STDERR "\tnlev=%d: ",$nlev) if ($debug);
			$var{'STDLEVS'} = join(":",@levs);
			$s = sprintf("%s,%s,%s,%d,%s,%s",$oe,$var{'OT'},$var{'CT'},$iarea,$rt,$var{'STDLEVS'});
			my $delim = ",";
			for my $lev (@levs) {
			    my $name = sprintf("%s(%d)",$oe,$lev);
			    my $plainoe = $var{$name};
			    my $oevar = $plainoe * $plainoe;
			    $s .= sprintf("%s%s",$delim,$oevar);
			    $delim = ":";
			}
			$delim = ",";
                        for my $lev (@levs) {
                            my $name = sprintf("%s(%d)",$oe,$lev);
                            my $plainoe	= $var{$name};
                            $s .= sprintf("%s%s",$delim,$plainoe);
                            $delim = ":";
                        }
			push(@s,$s);
			printf(STDERR "%s\n",$s) if ($debug);
		    }
		}
		my $nrtlist = @rtlist;
		#if ($nrtlist == 1 && $rtlist[0] != -1)
		{
		    for my $lev (@levs) {
			my $name = sprintf("%s(%d)",$oe,$lev);
			delete $var{$name};
		    }
		}
		$oe = undef;
	    }
	}
    }
    elsif (m{^exit$}) {
	last;
    }
}

#for (@s) {
#    chomp;
#    printf("%s\n",$_);
#}

my $cmd = sprintf("./create_tmphdr.pl module/yomcoctp.F90 setup/cmoctmap.F90 > tmphdr.csv && env TMPDIR=. ./csv2sqlite tmphdr.csv > /dev/null && /bin/rm -f tmphdr.sql");
die "Failed $cmd" unless (system($cmd) == 0);

my $db = sprintf("tmphdr.db");
if (-r $db) {
    #my $pipeout = sprintf("| tee %s/oev.csv",$tmpdir);
    my $pipeout = sprintf("> %s/oev.csv",$tmpdir);
    open(OUT,$pipeout) || die "Failed $pipeout";
    printf(OUT "#obsname:text,obstype:int,obsnamesq:text,obstypesq:int,obstype_descr:text,codename:text,codetype:int,codenamesq:text,codetypesq:int,codetype_descr:text,varclass:text,geoarea:int,reportype:int,levtype:text,nlevs:int,levs:text,oevars:text,obs_error:text\n");
    for (@s) {
	chomp;
	next if (m{^\#});
	my ($oe,$ot,$ct,$iarea,$rt,$levs,$oevar,$plainoe) = split(/,/,$_);
	my $nlevs = split(/:/,$levs);
	next unless ($iarea == 1);
	my $levtype = "stdlevs";
	$levtype = "channel" if ($oe =~ m{^OETB$});
	$levtype = "ht" if ($oe =~ m{^OEGPSRO$});
	$levtype = "prc" if ($oe =~ m{^OEPRC$});
	$levtype = "raw" if ($oe =~ m{^OE(T2M|W10M|PS)$});
	$oe =~ s/^OE//;
	$s = sprintf("%s,%d,%d,%s,%d,%s,%s,%s",$oe,$iarea,$rt,$levtype,$nlevs,$levs,$oevar,$plainoe);
	#$s = sprintf("%s,%d,%d,%s,%s,%s",$oe,$iarea,$rt,$levtype,$levs,$oevar);
	printf(STDERR "[oe=%s:levtype=%s] Appeding %s\n",$oe,$levtype,$s) if ($debug);
	my $sql = sprintf("SELECT * FROM tmphdr WHERE obsname = '%s'",$ot);
	unless ($ct eq "*") {
	    if ($ct =~ m{^\!(\S+)$}) {
		my @ctlist = split(/:/,$1);
		for (@ctlist) {
		    $sql .= sprintf(" AND codename <> '%s'",$_);
		}
	    }
	    elsif ($ct =~ m{^(\w+)$}) {
		$sql .= sprintf(" AND codename = '%s'",$1);
	    }
	}
	printf(STDERR "[oe=%s:levtype=%s] %s : sql => %s\n",$oe,$levtype,$db,$sql) if ($debug);
	my $pipein = sprintf("sqlite3 %s -batch -init /dev/null -readonly -csv \"%s\" |",$db,$sql);
	my $nrows = -1;
	if (open(IN,$pipein)) {
	    ++$nrows;
	    for (<IN>) {
		chomp;
		s/\"//g;
		printf(OUT "%s,%s\n",$_,$s);
		++$nrows;
		printf(STDERR "[oe=%s:levtype=%s:row#%d] %s,%s\n",$oe,$levtype,$nrows,$_,$s) if ($debug);
	    }
	    close(IN);
	}
	printf(STDERR "[oe=%s:levtype=%s] nrows=%d\n",$oe,$levtype,$nrows) if ($debug);
    }
    close(OUT);
    $cmd = sprintf("./csv2sqlite %s/oev.csv > /dev/null && /bin/cp -fv %s/oev.csv %s/oev.db . && pwd && ls -ltra",$tmpdir,$tmpdir,$tmpdir);
    die "Failed $cmd" unless (system($cmd) == 0);
}

exit 0;

sub GetList {
    my ($v) = @_;
    $v =~ s/\s+//g;
    return split(/,/,$v);
}

__DATA__
#obs_error/suobserr.F90

RG=9.80665

!        3.       OBSERVATION RADIOSONDE WIND ERRORS

&OEWIND
OT=NTEMP
CT=*
    OEWIND ( 1)  =  1.80
    OEWIND ( 2)  =  1.80
    OEWIND ( 3)  =  1.90
    OEWIND ( 4)  =  2.10
    OEWIND ( 5)  =  2.50
    OEWIND ( 6)  =  2.60
    OEWIND ( 7)  =  2.50
    OEWIND ( 8)  =  2.50
    OEWIND ( 9)  =  2.40
    OEWIND (10)  =  2.20
    OEWIND (11)  =  2.10
    OEWIND (12)  =  2.00
    OEWIND (13)  =  2.10
    OEWIND (14)  =  2.30
    OEWIND (15)  =  3.00
/

!        4.       OBS. RADIOSONDE HEIGHT ERRORS

!*          4.1   AREA 1 (NORTH AMERICA)

&OEHEIG
OT=NTEMP
CT=*

IAREA = 1
  OEHEIG ( 1)  =  4.30*RG
  OEHEIG ( 2)  =  4.40*RG
  OEHEIG ( 3)  =  5.20*RG
  OEHEIG ( 4)  =  8.40*RG
  OEHEIG ( 5)  =  9.80*RG
  OEHEIG ( 6)  = 10.70*RG
  OEHEIG ( 7)  = 11.80*RG
  OEHEIG ( 8)  = 13.20*RG
  OEHEIG ( 9)  = 15.20*RG
  OEHEIG (10)  = 18.10*RG
  OEHEIG (11)  = 19.50*RG
  OEHEIG (12)  = 22.50*RG
  OEHEIG (13)  = 25.00*RG
  OEHEIG (14)  = 32.00*RG
  OEHEIG (15)  = 40.00*RG
/

!*          4.2   AREA 2 (AFRICA, ARABIA AND SOUTH AMERICA)

&OEHEIG
OT=NTEMP
CT=*

IAREA = 2
  OEHEIG ( 1)  =  6.45*RG
  OEHEIG ( 2)  =  6.60*RG
  OEHEIG ( 3)  =  7.80*RG
  OEHEIG ( 4)  = 12.60*RG
  OEHEIG ( 5)  = 14.70*RG
  OEHEIG ( 6)  = 16.05*RG
  OEHEIG ( 7)  = 17.70*RG
  OEHEIG ( 8)  = 19.80*RG
  OEHEIG ( 9)  = 22.80*RG
  OEHEIG (10)  = 27.15*RG
  OEHEIG (11)  = 29.25*RG
  OEHEIG (12)  = 33.75*RG
  OEHEIG (13)  = 37.50*RG
  OEHEIG (14)  = 48.00*RG
  OEHEIG (15)  = 60.00*RG
/

!*          4.3   AREA 3 (THE REST)

&OEHEIG
OT=NTEMP
CT=*

IAREA = 3
  OEHEIG ( 1)  =  8.60*RG
  OEHEIG ( 2)  =  8.80*RG
  OEHEIG ( 3)  = 10.40*RG
  OEHEIG ( 4)  = 16.80*RG
  OEHEIG ( 5)  = 19.60*RG
  OEHEIG ( 6)  = 21.40*RG
  OEHEIG ( 7)  = 23.60*RG
  OEHEIG ( 8)  = 26.40*RG
  OEHEIG ( 9)  = 30.40*RG
  OEHEIG (10)  = 36.20*RG
  OEHEIG (11)  = 39.00*RG
  OEHEIG (12)  = 45.00*RG
  OEHEIG (13)  = 50.00*RG
  OEHEIG (14)  = 64.00*RG
  OEHEIG (15)  = 80.00*RG
/

!        5.       OBS. RADIOSONDE TEMPERATURE ERRORS

&OETEMP
OT=NTEMP
CT=*

ZRETUNE=0.7
  OETEMP ( 1)  =  1.40*ZRETUNE
  OETEMP ( 2)  =  1.25*ZRETUNE
  OETEMP ( 3)  =  1.10*ZRETUNE
  OETEMP ( 4)  =  0.95*ZRETUNE
  OETEMP ( 5)  =  0.90*ZRETUNE
  OETEMP ( 6)  =  1.00*ZRETUNE
  OETEMP ( 7)  =  1.15*ZRETUNE
  OETEMP ( 8)  =  1.20*ZRETUNE
  OETEMP ( 9)  =  1.25*ZRETUNE
  OETEMP (10)  =  1.30*ZRETUNE
  OETEMP (11)  =  1.40*ZRETUNE
  OETEMP (12)  =  1.40*ZRETUNE
  OETEMP (13)  =  1.40*ZRETUNE
  OETEMP (14)  =  1.50*ZRETUNE
  OETEMP (15)  =  2.10*ZRETUNE
/

!        6.       OBSERVATION SATOB WIND ERRORS

&OEWIND
OT=NSATOB
CT=*
    OEWIND ( 1)  =  2.00
    OEWIND ( 2)  =  2.00
    OEWIND ( 3)  =  2.00
    OEWIND ( 4)  =  3.50
    OEWIND ( 5)  =  4.30
    OEWIND ( 6)  =  5.00
    OEWIND ( 7)  =  5.00
    OEWIND ( 8)  =  5.00
    OEWIND ( 9)  =  5.00
    OEWIND (10)  =  5.00
    OEWIND (11)  =  5.00
    OEWIND (12)  =  5.00
    OEWIND (13)  =  5.00
    OEWIND (14)  =  5.00
    OEWIND (15)  =  5.70
/

!        7.       OBSERVATION AIREP WIND ERRORS

&OEWIND
OT=NAIREP
CT=!NAIRCD
    OEWIND ( 1)  =  2.46
    OEWIND ( 2)  =  2.51
    OEWIND ( 3)  =  2.56
    OEWIND ( 4)  =  2.71
    OEWIND ( 5)  =  2.81
    OEWIND ( 6)  =  2.86
    OEWIND ( 7)  =  2.91
    OEWIND ( 8)  =  2.96
    OEWIND ( 9)  =  2.91
    OEWIND (10)  =  2.76
    OEWIND (11)  =  2.66
    OEWIND (12)  =  2.66
    OEWIND (13)  =  2.86
    OEWIND (14)  =  3.06
    OEWIND (15)  =  3.36
/

!*          7.1.2 AIREP-MANUAL (NAIRCD=141)

&OEWIND
OT=NAIREP
CT=NAIRCD
  OEWIND ( 1)  =  2.86
  OEWIND ( 2)  =  2.91
  OEWIND ( 3)  =  2.96
  OEWIND ( 4)  =  3.11
  OEWIND ( 5)  =  3.21
  OEWIND ( 6)  =  3.26
  OEWIND ( 7)  =  3.31
  OEWIND ( 8)  =  3.36
  OEWIND ( 9)  =  3.31
  OEWIND (10)  =  3.16
  OEWIND (11)  =  3.06
  OEWIND (12)  =  3.06
  OEWIND (13)  =  3.26
  OEWIND (14)  =  3.46
  OEWIND (15)  =  3.76
/

!        8.       OBSERVATION AIREP TEMPERATURE ERRORS

&OETEMP
OT=NAIREP
CT=!NAIRCD
    OETEMP ( 1)  =  1.40
    OETEMP ( 2)  =  1.18
    OETEMP ( 3)  =  1.00
    OETEMP ( 4)  =  0.98
    OETEMP ( 5)  =  0.96
    OETEMP ( 6)  =  0.95
    OETEMP ( 7)  =  0.95
    OETEMP ( 8)  =  1.06
    OETEMP ( 9)  =  1.18
    OETEMP (10)  =  1.30
    OETEMP (11)  =  1.40
    OETEMP (12)  =  1.50
    OETEMP (13)  =  1.60
    OETEMP (14)  =  1.80
    OETEMP (15)  =  2.10
/

&OETEMP
OT=NAIREP
CT=NAIRCD
  OETEMP ( 1)  =  1.65
  OETEMP ( 2)  =  1.43
  OETEMP ( 3)  =  1.25
  OETEMP ( 4)  =  1.23
  OETEMP ( 5)  =  1.21
  OETEMP ( 6)  =  1.20
  OETEMP ( 7)  =  1.20
  OETEMP ( 8)  =  1.31
  OETEMP ( 9)  =  1.43
  OETEMP (10)  =  1.55
  OETEMP (11)  =  1.65
  OETEMP (12)  =  1.75
  OETEMP (13)  =  1.85
  OETEMP (14)  =  2.05
  OETEMP (15)  =  2.35
/

!        9.       OBSERVATION SYNOP WIND ERRORS

&OEWIND
OT=NSYNOP
CT=*
    OEWIND ( 1)  =  2.00
    OEWIND ( 2)  =  2.00
    OEWIND ( 3)  =  2.00
    OEWIND ( 4)  =  3.10
    OEWIND ( 5)  =  3.30
    OEWIND ( 6)  =  3.50
    OEWIND ( 7)  =  2.90
    OEWIND ( 8)  =  2.90
    OEWIND ( 9)  =  2.10
    OEWIND (10)  =  1.90
    OEWIND (11)  =  1.70
    OEWIND (12)  =  1.70
    OEWIND (13)  =  1.70
    OEWIND (14)  =  2.20
    OEWIND (15)  =  2.70
/

!        10.      OBS. SYNOP HEIGHT ERRORS

!*          10.1.1 LAND STATION (CODE TYPE 11; manual)

&OEHEIG
OT=NSYNOP
CT=NSRSCD
ZRETUNE   = 1.0*RG
  OEHEIG ( 1)  =  5.60*ZRETUNE
  OEHEIG ( 2)  =  7.20*ZRETUNE
  OEHEIG ( 3)  =  8.60*ZRETUNE
  OEHEIG ( 4)  = 12.10*ZRETUNE
  OEHEIG ( 5)  = 14.90*ZRETUNE
  OEHEIG ( 6)  = 18.80*ZRETUNE
  OEHEIG ( 7)  = 25.40*ZRETUNE
  OEHEIG ( 8)  = 27.70*ZRETUNE
  OEHEIG ( 9)  = 32.40*ZRETUNE
  OEHEIG (10)  = 39.40*ZRETUNE
  OEHEIG (11)  = 50.30*ZRETUNE
  OEHEIG (12)  = 59.30*ZRETUNE
  OEHEIG (13)  = 69.80*ZRETUNE
  OEHEIG (14)  = 96.00*ZRETUNE
  OEHEIG (15)  =114.20*ZRETUNE
/

!*          10.1.2 LAND STATION (CODE TYPE 14; automatic)

&OEHEIG
OT=NSYNOP
CT=NATSCD
ZRETUNE   = 0.75*RG
  OEHEIG ( 1)  =  5.60*ZRETUNE
  OEHEIG ( 2)  =  7.20*ZRETUNE
  OEHEIG ( 3)  =  8.60*ZRETUNE
  OEHEIG ( 4)  = 12.10*ZRETUNE
  OEHEIG ( 5)  = 14.90*ZRETUNE
  OEHEIG ( 6)  = 18.80*ZRETUNE
  OEHEIG ( 7)  = 25.40*ZRETUNE
  OEHEIG ( 8)  = 27.70*ZRETUNE
  OEHEIG ( 9)  = 32.40*ZRETUNE
  OEHEIG (10)  = 39.40*ZRETUNE
  OEHEIG (11)  = 50.30*ZRETUNE
  OEHEIG (12)  = 59.30*ZRETUNE
  OEHEIG (13)  = 69.80*ZRETUNE
  OEHEIG (14)  = 96.00*ZRETUNE
  OEHEIG (15)  =114.20*ZRETUNE
/

!*          10.1.X LAND STATION (CODE TYPE 170; BUFR)

&OEHEIG
OT=NSYNOP
CT=NBLSCD
ZRETUNE   = 0.75*RG
  OEHEIG ( 1)  =  5.60*ZRETUNE
  OEHEIG ( 2)  =  7.20*ZRETUNE
  OEHEIG ( 3)  =  8.60*ZRETUNE
  OEHEIG ( 4)  = 12.10*ZRETUNE
  OEHEIG ( 5)  = 14.90*ZRETUNE
  OEHEIG ( 6)  = 18.80*ZRETUNE
  OEHEIG ( 7)  = 25.40*ZRETUNE
  OEHEIG ( 8)  = 27.70*ZRETUNE
  OEHEIG ( 9)  = 32.40*ZRETUNE
  OEHEIG (10)  = 39.40*ZRETUNE
  OEHEIG (11)  = 50.30*ZRETUNE
  OEHEIG (12)  = 59.30*ZRETUNE
  OEHEIG (13)  = 69.80*ZRETUNE
  OEHEIG (14)  = 96.00*ZRETUNE
  OEHEIG (15)  =114.20*ZRETUNE
/

!*          10.1.3 SHIP STATION (CODE TYPE 21; manual)

&OEHEIG
OT=NSYNOP
CT=NSHSCD
ZRETUNE   = 0.71*RG
  OEHEIG ( 1)  = 10.00*ZRETUNE
  OEHEIG ( 2)  = 10.00*ZRETUNE
  OEHEIG ( 3)  = 10.00*ZRETUNE
  OEHEIG ( 4)  = 10.00*ZRETUNE
  OEHEIG ( 5)  = 10.00*ZRETUNE
  OEHEIG ( 6)  = 10.00*ZRETUNE
  OEHEIG ( 7)  = 10.00*ZRETUNE
  OEHEIG ( 8)  = 10.00*ZRETUNE
  OEHEIG ( 9)  = 10.00*ZRETUNE
  OEHEIG (10)  = 10.00*ZRETUNE
  OEHEIG (11)  = 10.00*ZRETUNE
  OEHEIG (12)  = 10.00*ZRETUNE
  OEHEIG (13)  = 10.00*ZRETUNE
  OEHEIG (14)  = 10.00*ZRETUNE
  OEHEIG (15)  = 10.00*ZRETUNE
/

!*          10.1.4 SHIP STATION (CODE TYPE 22; manual)

&OEHEIG
OT=NSYNOP
CT=NABSCD
ZRETUNE   = 0.71*RG
  OEHEIG ( 1)  = 10.00*ZRETUNE
  OEHEIG ( 2)  = 10.00*ZRETUNE
  OEHEIG ( 3)  = 10.00*ZRETUNE
  OEHEIG ( 4)  = 10.00*ZRETUNE
  OEHEIG ( 5)  = 10.00*ZRETUNE
  OEHEIG ( 6)  = 10.00*ZRETUNE
  OEHEIG ( 7)  = 10.00*ZRETUNE
  OEHEIG ( 8)  = 10.00*ZRETUNE
  OEHEIG ( 9)  = 10.00*ZRETUNE
  OEHEIG (10)  = 10.00*ZRETUNE
  OEHEIG (11)  = 10.00*ZRETUNE
  OEHEIG (12)  = 10.00*ZRETUNE
  OEHEIG (13)  = 10.00*ZRETUNE
  OEHEIG (14)  = 10.00*ZRETUNE
  OEHEIG (15)  = 10.00*ZRETUNE
/

!*          10.1.5 SHIP STATION (CODE TYPE 23; manual)

&OEHEIG
OT=NSYNOP
CT=NSHRED
ZRETUNE   = 0.71*RG
  OEHEIG ( 1)  = 10.00*ZRETUNE
  OEHEIG ( 2)  = 10.00*ZRETUNE
  OEHEIG ( 3)  = 10.00*ZRETUNE
  OEHEIG ( 4)  = 10.00*ZRETUNE
  OEHEIG ( 5)  = 10.00*ZRETUNE
  OEHEIG ( 6)  = 10.00*ZRETUNE
  OEHEIG ( 7)  = 10.00*ZRETUNE
  OEHEIG ( 8)  = 10.00*ZRETUNE
  OEHEIG ( 9)  = 10.00*ZRETUNE
  OEHEIG (10)  = 10.00*ZRETUNE
  OEHEIG (11)  = 10.00*ZRETUNE
  OEHEIG (12)  = 10.00*ZRETUNE
  OEHEIG (13)  = 10.00*ZRETUNE
  OEHEIG (14)  = 10.00*ZRETUNE
  OEHEIG (15)  = 10.00*ZRETUNE
/

!*          10.1.6 SHIP STATION (CODE TYPE 24; automatic)

&OEHEIG
OT=NSYNOP
CT=NATSHS
ZRETUNE   = 0.42*RG
  OEHEIG ( 1)  = 10.00*ZRETUNE
  OEHEIG ( 2)  = 10.00*ZRETUNE
  OEHEIG ( 3)  = 10.00*ZRETUNE
  OEHEIG ( 4)  = 10.00*ZRETUNE
  OEHEIG ( 5)  = 10.00*ZRETUNE
  OEHEIG ( 6)  = 10.00*ZRETUNE
  OEHEIG ( 7)  = 10.00*ZRETUNE
  OEHEIG ( 8)  = 10.00*ZRETUNE
  OEHEIG ( 9)  = 10.00*ZRETUNE
  OEHEIG (10)  = 10.00*ZRETUNE
  OEHEIG (11)  = 10.00*ZRETUNE
  OEHEIG (12)  = 10.00*ZRETUNE
  OEHEIG (13)  = 10.00*ZRETUNE
  OEHEIG (14)  = 10.00*ZRETUNE
  OEHEIG (15)  = 10.00*ZRETUNE
/

!*          10.1.X SHIP STATION (CODE TYPE 182; BUFR)

&OEHEIG
OT=NSYNOP
CT=NBSSCD
ZRETUNE   = 0.42*RG
  OEHEIG ( 1)  = 10.00*ZRETUNE
  OEHEIG ( 2)  = 10.00*ZRETUNE
  OEHEIG ( 3)  = 10.00*ZRETUNE
  OEHEIG ( 4)  = 10.00*ZRETUNE
  OEHEIG ( 5)  = 10.00*ZRETUNE
  OEHEIG ( 6)  = 10.00*ZRETUNE
  OEHEIG ( 7)  = 10.00*ZRETUNE
  OEHEIG ( 8)  = 10.00*ZRETUNE
  OEHEIG ( 9)  = 10.00*ZRETUNE
  OEHEIG (10)  = 10.00*ZRETUNE
  OEHEIG (11)  = 10.00*ZRETUNE
  OEHEIG (12)  = 10.00*ZRETUNE
  OEHEIG (13)  = 10.00*ZRETUNE
  OEHEIG (14)  = 10.00*ZRETUNE
  OEHEIG (15)  = 10.00*ZRETUNE
/

!*          10.1.7 METAR STATION (CODE TYPE 140)

&OEHEIG
OT=NSYNOP
CT=NMETAR
ZRETUNE   = 1.00*RG
  OEHEIG ( 1)  =  5.60*ZRETUNE
  OEHEIG ( 2)  =  7.20*ZRETUNE
  OEHEIG ( 3)  =  8.60*ZRETUNE
  OEHEIG ( 4)  = 12.10*ZRETUNE
  OEHEIG ( 5)  = 14.90*ZRETUNE
  OEHEIG ( 6)  = 18.80*ZRETUNE
  OEHEIG ( 7)  = 25.40*ZRETUNE
  OEHEIG ( 8)  = 27.70*ZRETUNE
  OEHEIG ( 9)  = 32.40*ZRETUNE
  OEHEIG (10)  = 39.40*ZRETUNE
  OEHEIG (11)  = 50.30*ZRETUNE
  OEHEIG (12)  = 59.30*ZRETUNE
  OEHEIG (13)  = 69.80*ZRETUNE
  OEHEIG (14)  = 96.00*ZRETUNE
  OEHEIG (15)  =114.20*ZRETUNE
/

!        11.      OBS. SYNOP TEMPERATURE ERRORS

!*          11.1.1 LAND STATION (CODE TYPE 11)

&OETEMP
OT=NSYNOP
CT=NSRSCD
  OETEMP ( 1)  =  2.00
  OETEMP ( 2)  =  1.50
  OETEMP ( 3)  =  1.30
  OETEMP ( 4)  =  1.20
  OETEMP ( 5)  =  1.30
  OETEMP ( 6)  =  1.50
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.90
  OETEMP (10)  =  2.00
  OETEMP (11)  =  2.20
  OETEMP (12)  =  2.40
  OETEMP (13)  =  2.50
  OETEMP (14)  =  2.50
  OETEMP (15)  =  2.50
/

!*          11.1.2 LAND STATION (CODE TYPE 14)

&OETEMP
OT=NSYNOP
CT=NATSCD
  OETEMP ( 1)  =  2.00
  OETEMP ( 2)  =  1.50
  OETEMP ( 3)  =  1.30
  OETEMP ( 4)  =  1.20
  OETEMP ( 5)  =  1.30
  OETEMP ( 6)  =  1.50
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.90
  OETEMP (10)  =  2.00
  OETEMP (11)  =  2.20
  OETEMP (12)  =  2.40
  OETEMP (13)  =  2.50
  OETEMP (14)  =  2.50
  OETEMP (15)  =  2.50
/

!*          11.1.X LAND STATION (CODE TYPE 170)

&OETEMP
OT=NSYNOP
CT=NBLSCD
  OETEMP ( 1)  =  2.00
  OETEMP ( 2)  =  1.50
  OETEMP ( 3)  =  1.30
  OETEMP ( 4)  =  1.20
  OETEMP ( 5)  =  1.30
  OETEMP ( 6)  =  1.50
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.90
  OETEMP (10)  =  2.00
  OETEMP (11)  =  2.20
  OETEMP (12)  =  2.40
  OETEMP (13)  =  2.50
  OETEMP (14)  =  2.50
  OETEMP (15)  =  2.50
/

!*          11.1.3 SHIP STATION (CODE TYPE 21)

&OETEMP
OT=NSYNOP
CT=NSHSCD
  OETEMP ( 1)  =  1.80
  OETEMP ( 2)  =  1.80
  OETEMP ( 3)  =  1.80
  OETEMP ( 4)  =  1.80
  OETEMP ( 5)  =  1.80
  OETEMP ( 6)  =  1.80
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.80
  OETEMP (10)  =  1.80
  OETEMP (11)  =  1.80
  OETEMP (12)  =  1.80
  OETEMP (13)  =  1.80
  OETEMP (14)  =  1.80
  OETEMP (15)  =  1.80
/

!*          11.1.4 SHIP STATION (CODE TYPE 22)

&OETEMP
OT=NSYNOP
CT=NABSCD
  OETEMP ( 1)  =  1.80
  OETEMP ( 2)  =  1.80
  OETEMP ( 3)  =  1.80
  OETEMP ( 4)  =  1.80
  OETEMP ( 5)  =  1.80
  OETEMP ( 6)  =  1.80
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.80
  OETEMP (10)  =  1.80
  OETEMP (11)  =  1.80
  OETEMP (12)  =  1.80
  OETEMP (13)  =  1.80
  OETEMP (14)  =  1.80
  OETEMP (15)  =  1.80
/

!*          11.1.5 SHIP STATION (CODE TYPE 23)

&OETEMP
OT=NSYNOP
CT=NSHRED
  OETEMP ( 1)  =  1.80
  OETEMP ( 2)  =  1.80
  OETEMP ( 3)  =  1.80
  OETEMP ( 4)  =  1.80
  OETEMP ( 5)  =  1.80
  OETEMP ( 6)  =  1.80
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.80
  OETEMP (10)  =  1.80
  OETEMP (11)  =  1.80
  OETEMP (12)  =  1.80
  OETEMP (13)  =  1.80
  OETEMP (14)  =  1.80
  OETEMP (15)  =  1.80
/

!*          11.1.6 SHIP STATION (CODE TYPE 24)

&OETEMP
OT=NSYNOP
CT=NATSHS
  OETEMP ( 1)  =  1.80
  OETEMP ( 2)  =  1.80
  OETEMP ( 3)  =  1.80
  OETEMP ( 4)  =  1.80
  OETEMP ( 5)  =  1.80
  OETEMP ( 6)  =  1.80
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.80
  OETEMP (10)  =  1.80
  OETEMP (11)  =  1.80
  OETEMP (12)  =  1.80
  OETEMP (13)  =  1.80
  OETEMP (14)  =  1.80
  OETEMP (15)  =  1.80
/  

!*          11.1.X SHIP STATION (CODE TYPE 182)

&OETEMP
OT=NSYNOP
CT=NBSSCD
  OETEMP ( 1)  =  1.80
  OETEMP ( 2)  =  1.80
  OETEMP ( 3)  =  1.80
  OETEMP ( 4)  =  1.80
  OETEMP ( 5)  =  1.80
  OETEMP ( 6)  =  1.80
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.80
  OETEMP (10)  =  1.80
  OETEMP (11)  =  1.80
  OETEMP (12)  =  1.80
  OETEMP (13)  =  1.80
  OETEMP (14)  =  1.80
  OETEMP (15)  =  1.80
/

!*          11.1.7 METAR STATION (CODE TYPE 140)

&OETEMP
OT=NSYNOP
CT=NMETAR
  OETEMP ( 1)  =  2.00
  OETEMP ( 2)  =  1.50
  OETEMP ( 3)  =  1.30
  OETEMP ( 4)  =  1.20
  OETEMP ( 5)  =  1.30
  OETEMP ( 6)  =  1.50
  OETEMP ( 7)  =  1.80
  OETEMP ( 8)  =  1.80
  OETEMP ( 9)  =  1.90
  OETEMP (10)  =  2.00
  OETEMP (11)  =  2.20
  OETEMP (12)  =  2.40
  OETEMP (13)  =  2.50
  OETEMP (14)  =  2.50
  OETEMP (15)  =  2.50
/

!        12.      OBS. DRIBU WIND ERRORS

&OEWIND
OT=NDRIBU
CT=*
    OEWIND ( 1)  =  1.80
    OEWIND ( 2)  =  1.80
    OEWIND ( 3)  =  1.80
    OEWIND ( 4)  =  1.80
    OEWIND ( 5)  =  1.80
    OEWIND ( 6)  =  1.80
    OEWIND ( 7)  =  1.80
    OEWIND ( 8)  =  1.80
    OEWIND ( 9)  =  1.80
    OEWIND (10)  =  1.80
    OEWIND (11)  =  1.80
    OEWIND (12)  =  1.80
    OEWIND (13)  =  1.80
    OEWIND (14)  =  1.80
    OEWIND (15)  =  1.80
/

!        13.      OBS. DRIBU HEIGHT ERRORS

&OEHEIG
OT=NDRIBU
CT=*
  ZRETUNE   = 0.71*RG
    OEHEIG ( 1)  =  7.00*ZRETUNE
    OEHEIG ( 2)  =  7.00*ZRETUNE
    OEHEIG ( 3)  =  7.00*ZRETUNE
    OEHEIG ( 4)  =  7.00*ZRETUNE
    OEHEIG ( 5)  =  7.00*ZRETUNE
    OEHEIG ( 6)  =  7.00*ZRETUNE
    OEHEIG ( 7)  =  7.00*ZRETUNE
    OEHEIG ( 8)  =  7.00*ZRETUNE
    OEHEIG ( 9)  =  7.00*ZRETUNE
    OEHEIG (10)  =  7.00*ZRETUNE
    OEHEIG (11)  =  7.00*ZRETUNE
    OEHEIG (12)  =  7.00*ZRETUNE
    OEHEIG (13)  =  7.00*ZRETUNE
    OEHEIG (14)  =  7.00*ZRETUNE
    OEHEIG (15)  =  7.00*ZRETUNE
/   

!        14.      OBS. DRIBU TEMPERATURE ERRORS

&OETEMP
OT=NDRIBU
CT=*
    OETEMP ( 1)  =  1.80
    OETEMP ( 2)  =  1.50
    OETEMP ( 3)  =  1.30
    OETEMP ( 4)  =  1.20
    OETEMP ( 5)  =  1.30
    OETEMP ( 6)  =  1.50
    OETEMP ( 7)  =  1.80
    OETEMP ( 8)  =  1.80
    OETEMP ( 9)  =  1.90
    OETEMP (10)  =  2.00
    OETEMP (11)  =  2.20
    OETEMP (12)  =  2.40
    OETEMP (13)  =  2.50
    OETEMP (14)  =  2.50
    OETEMP (15)  =  2.50
/   

!        15.      OBS. PAOB HEIGHT ERRORS

&OEHEIG
OT=NPAOB
CT=*
    OEHEIG ( 1)  = 24.00*RG
    OEHEIG ( 2)  = 24.00*RG
    OEHEIG ( 3)  = 24.00*RG
    OEHEIG ( 4)  = 24.00*RG
    OEHEIG ( 5)  = 24.00*RG
    OEHEIG ( 6)  = 24.00*RG
    OEHEIG ( 7)  = 24.00*RG
    OEHEIG ( 8)  = 24.00*RG
    OEHEIG ( 9)  = 24.00*RG
    OEHEIG (10)  = 24.00*RG
    OEHEIG (11)  = 24.00*RG
    OEHEIG (12)  = 24.00*RG
    OEHEIG (13)  = 24.00*RG
    OEHEIG (14)  = 24.00*RG
    OEHEIG (15)  = 24.00*RG
/   

!        16.      OBSERVATION PILOT WIND ERRORS

&OEWIND
OT=NPILOT
CT=*
    OEWIND ( 1)  =  1.80
    OEWIND ( 2)  =  1.80
    OEWIND ( 3)  =  1.90
    OEWIND ( 4)  =  2.10
    OEWIND ( 5)  =  2.50
    OEWIND ( 6)  =  2.60
    OEWIND ( 7)  =  2.50
    OEWIND ( 8)  =  2.50
    OEWIND ( 9)  =  2.40
    OEWIND (10)  =  2.20
    OEWIND (11)  =  2.10
    OEWIND (12)  =  2.00
    OEWIND (13)  =  2.10
    OEWIND (14)  =  2.30
    OEWIND (15)  =  3.00
/   

!        17.      PILOT HEIGHT ERRORS

!*          17.1  AREA 1 (NORTH AMERICA)

&OEHEIG
OT=NPILOT
CT=*
IAREA = 1
  OEHEIG ( 1)  =  4.30*RG
  OEHEIG ( 2)  =  4.40*RG
  OEHEIG ( 3)  =  5.20*RG
  OEHEIG ( 4)  =  8.40*RG
  OEHEIG ( 5)  =  9.80*RG
  OEHEIG ( 6)  = 10.70*RG
  OEHEIG ( 7)  = 11.80*RG
  OEHEIG ( 8)  = 13.20*RG
  OEHEIG ( 9)  = 15.20*RG
  OEHEIG (10)  = 18.10*RG
  OEHEIG (11)  = 19.50*RG
  OEHEIG (12)  = 22.50*RG
  OEHEIG (13)  = 25.00*RG
  OEHEIG (14)  = 32.00*RG
  OEHEIG (15)  = 40.00*RG
/   

!*          17.2  AREA 2 (AFRICA, ARABIA AND SOUTH AMERICA)

&OEHEIG
OT=NPILOT
CT=*
IAREA = 2
  OEHEIG ( 1)  =  8.60*RG
  OEHEIG ( 2)  =  8.80*RG
  OEHEIG ( 3)  = 10.40*RG
  OEHEIG ( 4)  = 16.80*RG
  OEHEIG ( 5)  = 19.60*RG
  OEHEIG ( 6)  = 21.40*RG
  OEHEIG ( 7)  = 23.60*RG
  OEHEIG ( 8)  = 26.40*RG
  OEHEIG ( 9)  = 30.40*RG
  OEHEIG (10)  = 36.20*RG
  OEHEIG (11)  = 39.00*RG
  OEHEIG (12)  = 45.00*RG
  OEHEIG (13)  = 50.00*RG
  OEHEIG (14)  = 64.00*RG
  OEHEIG (15)  = 80.00*RG
/   

!*          17.3  AREA 3 (THE REST)

&OEHEIG
OT=NPILOT
CT=*
IAREA = 3
  OEHEIG ( 1)  =  6.45*RG
  OEHEIG ( 2)  =  6.60*RG
  OEHEIG ( 3)  =  7.80*RG
  OEHEIG ( 4)  = 12.60*RG
  OEHEIG ( 5)  = 14.70*RG
  OEHEIG ( 6)  = 16.05*RG
  OEHEIG ( 7)  = 17.70*RG
  OEHEIG ( 8)  = 19.80*RG
  OEHEIG ( 9)  = 22.80*RG
  OEHEIG (10)  = 27.15*RG
  OEHEIG (11)  = 29.25*RG
  OEHEIG (12)  = 33.75*RG
  OEHEIG (13)  = 37.50*RG
  OEHEIG (14)  = 48.00*RG
  OEHEIG (15)  = 60.00*RG
/   

! Swapan AMSU-A

&OETB
OT=NSATEM
CT=NGTHRB
RT=1001,1002,1003,1004,1005,1007,1008,1009,1010
OETB(8)  = sqrt(        2.25)
OETB(9)  = sqrt(        1.50)
OETB(10) = sqrt(        1.50)
OETB(11) = sqrt(        1.50)
OETB(12) = sqrt(        1.50)
OETB(13) = sqrt(        1.50)
OETB(14) = sqrt(        2.00)
/

! exit

! IASI by Swapan / Cristina Lupu (ECMWF)

! METOP-A IASI Radiances
&OETB
OT=NSATEM
CT=NGTHRB
RT=11001
OETB := awk '/^Des /,/^CORRELATIONS/ {if (NF == 2) {print}}' sat/rmtberr_metop_2_iasi 
/

! METOP-B IASI Radiances
&OETB
OT=NSATEM
CT=NGTHRB
RT=11002
OETB := awk '/^Des /,/^CORRELATIONS/ {if (NF == 2) {print}}' sat/rmtberr_metop_1_iasi 
/

! METOP-C IASI Radiances
&OETB
OT=NSATEM
CT=NGTHRB
RT=11003
OETB := awk '/^Des /,/^CORRELATIONS/ {if (NF == 2) {print}}' sat/rmtberr_metop_3_iasi 
/

! GPSRO from Swapan (note: input values as obs-err not as obs-err-var thus sqrt())

&OEGPSRO
OT=NLIMB
CT=NGPSRO
OEGPSRO(500) = sqrt(11.5)
OEGPSRO(1000) = sqrt(9.5)
OEGPSRO(1500) = sqrt(7.5)
OEGPSRO(2000) = sqrt(5.5)
OEGPSRO(2500) = sqrt(3.5)
OEGPSRO(3000) = sqrt(2.5)
OEGPSRO(3500) = sqrt(1.9)
OEGPSRO(4000) = sqrt(1.7)
OEGPSRO(4500) = sqrt(1.0)
OEGPSRO(5000) = sqrt(0.9)
OEGPSRO(5500) = sqrt(0.7)
OEGPSRO(6000) = sqrt(0.5)
OEGPSRO(6500) = sqrt(0.3)
OEGPSRO(7000) = sqrt(0.2)
OEGPSRO(7500) = sqrt(0.18)
OEGPSRO(8000) = sqrt(0.17)
OEGPSRO(8500) = sqrt(0.15)
OEGPSRO(9000) = sqrt(0.13)
OEGPSRO(9500) = sqrt(0.10)
OEGPSRO(10000) = sqrt(0.08)
OEGPSRO(10500) = sqrt(0.06)
OEGPSRO(11000) = sqrt(0.04)
OEGPSRO(11500) = sqrt(0.02)
OEGPSRO(12000) = sqrt(0.02)
OEGPSRO(12500) = sqrt(0.02)
OEGPSRO(13000) = sqrt(0.02)
OEGPSRO(13500) = sqrt(0.02)
OEGPSRO(14000) = sqrt(0.01)
/

! PS (surface pressure from Carla) -- buoys (dribu) : (note: input values as obs-err)

&OEPS
OT=NDRIBU
CT=*
OEPS(1) = 47.0
/

! Various SYNOP t2m : fixed to 1.5K

&OET2M
OT=NSYNOP
CT=*
OET2M(1) = 1.5
/

! Various SYNOP 10m u & v : fixed to 1.5 m/s

&OEW10M
OT=NSYNOP
CT=*
OEW10M(1) = 1.5
/

! SYNOP q2m -- 2m specific humidity : obs-err 10% (percent aka PRC) of obsvalue (for now ...)

&OEPRC
OT=NSYNOP
CT=*
OEPRC(1) = 10.0
/

! Generic SYNOP PS

&OEPS
OT=NSYNOP
CT=!NATSCD:NSRSCD:NBLSC
OEPS(1) = 47.0
/

! Explicit SYNOP PS definitions

&OEPS
OT=NSYNOP
CT=NATSCD
OEPS(1) = 40.0
/

&OEPS
OT=NSYNOP
CT=NSRSCD
OEPS(1) = 54.0
/

&OEPS
OT=NSYNOP
CT=NBLSCD
OEPS(1) = 40.0
/


