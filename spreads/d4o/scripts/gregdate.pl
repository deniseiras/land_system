#!/usr/bin/env perl
#
# Usage: gregdate.pl days secs [days secs [days secs [...]]]
#        gregdate.pl < assimilate.out
#

use strict;
use warnings;

sub IsGregLeapYear {
    my ($yyyy) = @_;
    my $is_leap = ($yyyy % 4 == 0) ? 1 : 0;
    $is_leap = 0 if ($is_leap && ($yyyy % 100 == 0) && ($yyyy % 400 != 0));
    return $is_leap;
}

sub GregDate {
    my ($days,$secs) = @_;
    return undef unless (defined($days) && defined($secs));
    return undef unless ($days =~ m{^\d+$} && $secs =~ m{^\d+$});
    #my ($yyyymmdd,$hhmmss) = ("YYYY-MM-DD","HH:MM:SS");
    my $key = sprintf("%d:%d",$secs,$days);
    # Implemented DART get_date_gregorian() subroutine here
    my $leap = 0;
    my $yyyy = undef;
    my $month = undef;
    my $num_days = $days;
    my $base_year = 1601;
    my $max_year = 10000;
    for (my $iyear = $base_year; $iyear <= $max_year; ++$iyear) {
	$leap = &IsGregLeapYear($iyear);
	my $days_this_year = $leap ? 366 : 365;
	if ($num_days >= $days_this_year) {
	    $num_days -= $days_this_year;
	}
	else {
	    $yyyy = $iyear;
	    last;
	}
    }
    my @days_per_month = (undef,31,28,31,30,31,30,31,31,30,31,30,31); # 1 + 12
    for (my $m = 1 ; $m <= 12 ; ++$m) {
	$month = $m;
	my $days_this_month = $days_per_month[$m];
	$days_this_month = 29 if ($leap && $m == 2);
	last if ($num_days < $days_this_month);
	$num_days -= $days_this_month;
    }
    my $day = $num_days + 1;
    
    my $t = $secs;
    my $hh = int($t / (60 * 60));
    $t -= $hh * (60 * 60);
    my $mm = int($t/60);
    my $ss = $t - 60 * $mm;

    return sprintf("%s %s => %4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d",
		   $days,$secs,
		   $yyyy,$month,$day,$hh,$mm,$ss);
}

if (@ARGV) {
    while (@ARGV) {
	my $date = &GregDate(@ARGV);
	printf("%s\n",$date) if (defined($date));
	shift @ARGV if (@ARGV);
	shift @ARGV if (@ARGV);
    }
}
else {
    for (<>) {
	chomp;
	my $date = undef;
	if (m{^DATE}) {
	   printf("%s\n",$_); 
	}
	elsif (m{day=\s*(\d+)\s*[,]?\s*sec=\s*(\d+)}) {
	    # PE 0: move_ahead Next available observation         at:  day=  152764 sec= 77400
	    $date = &GregDate($1,$2);
	}
	elsif (m{(\d+)\s+days\s+(\d+)\s+seconds}) {
	    # PE 0: shortest_time_between_assimilations:  assimilation period is            0  days        21600  seconds
	    $date = &GregDate($1,$2);
	}
	else {
	    $date = &GregDate(split(/\s+/));
	}
	printf("\n%s\n%s\n",$_,$date) if (defined($date));
    }
}

