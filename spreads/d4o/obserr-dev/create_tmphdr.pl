#!/usr/bin/env perl

use strict;
use warnings;

# KOBTYP ,KCDTYP ,KOTSQNO,KCDSQNO

my $kobtyp = undef;
my $label = "";

my %o = ();
my @o = ();

our %par = ();

for (<>) {
    chomp;
    if (m{^\s*\!\*\s+(\d+\.\d+(?:\.\w+)?)\s+(.*?)\s*$}) {
	$label = sprintf("%s %s",$1,$2);
	$label =~ s/SATTELITE/SATELLITE/g;
	next;
    }
    elsif (m{^\s*\!} || m{^\s*$}) {
	next;
    }
    elsif (m{^\s*INTEGER\(KIND=JPIM\),\s*PARAMETER\s*::\s*(\w+)\s*=\s*(\d+)}) {
	$par{$1} = $2;
	next;
    }
    if (m{IF\s*\(\s*KOBTYP\s*==\s*(\w+)}) {
	my $value = $1;
	my $p = &Par($value);
	$kobtyp = sprintf("%s,%d",$value,$p);
    }
    elsif (m{^\s*KOTSQNO\s*=\s*(\w+)\s*$}) {
	my $value = $1;
	my $p = &Par($value);
	$kobtyp .= sprintf(",%s,%d,%s",$value,$p,defined($label) ? $label : "'<undef>'");
	$o{$kobtyp} = "";
	push(@o,$kobtyp);
	#$label = undef;
    }
    elsif (m{IF\s*\(\s*KCDTYP\s*==\s*(\w+)}) {
	my $value = $1;
	my $p = &Par($value);
	$o{$kobtyp} .= sprintf(";%s,%d",$value,$p);
    }
    elsif (m{^\s*KCDSQNO\s*=\s*(\w+)\s*$}) {
	my $value = $1;
	my $p = &Par($value);
	$o{$kobtyp} .= sprintf(",%s,%d,%s",$value,$p,defined($label) ? $label : "'<undef>'");
	$label = undef;
    }
}

#'NDRIBU',4,'NDRIBUSQ',4,'1.4 DRIBU','NDERS1',160,'NDERS1SQ',4,'1.4.4 ERS1 AS DRIBU'

my $olen = @o;

if ($olen > 0) {
    printf("#obsname:text,obstype:int,obsnamesq:text,obstypesq:int,obstype_descr:text,codename:text,codetype:int,codenamesq:text,codetypesq:int,codetype_descr:text\n");
    for $kobtyp (@o) {
	my $s = $o{$kobtyp};
	for (split(/\;/,$s)) {
	    if (length($_) > 0) {
		my $t = sprintf("%s,%s",$kobtyp,$_);
		my @t = split(/,/,$t);
		#for (@t) {
		#    $_ = "'$1'" if (m{^([A-Z]\w+)$});
		#}
		$t = join(",",@t);
		printf("%s\n",$t);
	    }
	}
    }
}

exit 0;

sub Par {
    my ($value) = @_;
    return exists($par{$value}) ? $par{$value} : -1;
}
