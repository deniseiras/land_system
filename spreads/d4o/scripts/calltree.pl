#!/usr/bin/env perl
#
# Usage example:
#
#   calltree.pl algor bl crm ecfftw enkf ifs ifsaux ifsobs odb radiation satrad surf trans wam --target=MASTER
#

use strict;
use warnings;

my $cmd0 = $0;
$cmd0 =~ s%.*/%%;

my $scrname = qx(readlink -f $0);
chomp($scrname); # script name with full path

my $scrdir = qx(dirname $scrname);
chomp($scrdir); # script dir path only

our $debug = 0;

my @prog = ();
my @subr = ();
my @func = ();
our %kind = (); # 0=prog , 1=subr, 2=func, 3=fio, 40=interface, 41=interface(subroutine), 42=interface(function)
our %tree = ();
our %file = ();
our %done = ();
our %module = ();
my @targets = ();
my $cmd;
my $dummies = 0;
my $drhook = 0;
my $abort = 0;
our $level = 1;
our $depth = undef; # unlimited nesting level depth e.g. --depth=2 included levels 0 and 1 but not 2 or greater
my $nofio = 0;
my @fio = ();
our $tidy = 0;
our %tidy = ();

# Use "cflow" -tool to generate all C-routine calling trees
my $cflow = qx(which cflow 2>/dev/null || echo "$scrdir/cflow");
chomp($cflow);
$cflow = "" unless (-x $cflow);
$cflow = undef unless (length($cflow) > 0);
our @cout = ();

# Find all readable files (others treated as keys)

my @defincs = qw(. include /usr/include);
my @incs = ();
my %incs = ();
my $inc;
map {
    $inc=$_;
    push(@incs,$inc),$incs{$inc}=1 unless (exists($incs{$inc}) || ! -d $inc);
} @defincs;

my @defs = (); # Both -D and -U

my @cfiles = ();
my @files = ();
my @exclfile = ();
my @exclfunc = ();

my $conly = 0;
my $Fonly = 0;

my $someargs = join(" ",@ARGV);
my $maxlen = 4096;
$someargs = substr($someargs,0,$maxlen)." ..." if (length($someargs) > $maxlen);
printf("# %s %s\n\n",$cmd0,$someargs);

# search files from RAPS deps.def (or similar) first
my @raps = ();
for my $f (@ARGV) {
    if ($f =~ m{--raps=(\S+)$}) {
	my $raps = $1;
	if (-r $raps) {
	    open(IN,"perl -pe 's/\\\\\\s*\$//' $raps|grep -P '^(DEFS|UNDEFS|OBJS_\\w+\\s*=)\\s*'|perl -pe 's/^OBJS_\\w+\\s*=\\s*//; s/\\.o\\s*/.o\\n/g'|") || last;
	    for (<IN>) {
		chomp;
		s/^(DEFS|UNDEFS)\s*[+]?=\s*(\S+)\s*$/$2/;
		push(@raps,$_);
	    }
	    close(IN);
	}
	last;
    }
}

#search %fppkeys_arch from NEMO config
my @nemo = ();
for my $f (@ARGV) {
    if ($f =~ m{--nemo=(\S+)$}) {
	my $nemo = $1;
	if (-r $nemo) {
	    open(IN,"grep -P '^%fppkeys_arch\\s+' $nemo|") || last;
	    for (<IN>) {
		chomp;
		s/^%fppkeys_arch\s+//;
		s/\s+$//;
		map { push(@nemo,"-D$_"); } split(/\s+/);
	    }
	    close(IN);
	}
	last;
    }
}

my @argv = ();
push(@argv,@raps) if (@raps);
push(@argv,@nemo) if (@nemo);
push(@argv,@ARGV);

for my $f (@argv) {
    chomp($f);
    $f =~ s%^\./(\S+)%$1%;
    if ($f =~ m{--(raps|nemo)=(\S+)$}) {
	next;
    }
    elsif ($f eq "--debug") {
	++$debug;
	next;
    }
    elsif ($f eq "--tidy") {
	$tidy = 1; # drop duplicate entries & show minimal information
	next;
    }
    elsif ($f eq "--dummies") {
	$dummies = 1; # include dummy routines
	next;
    }
    elsif ($f eq "--drhook") {
	$drhook = 1; # include DrHook (CALL DR_HOOK) calls
	next;
    }
    elsif ($f eq "--abort") {
	$abort = 1; # include any kind of ABORT-calls (e.g. ABOR1, MPL_ABORT, ...)
	next;
    }
    elsif ($f eq "--nofio") {
	$nofio = 1; # exclude Fortran I/O routines ("fio:") from output
	next;
    }
    elsif ($f eq "--nolevel") {
	$level = 0; # drop nesting level information
	next;
    }
    elsif ($f =~ m{^--(depth|nesting|level)=(\d+)$}) {
	$depth = $2;
	next;
    }
    elsif ($f =~ m{^--fio=(\S+)$}) {
	my $tmp = uc($1);
	my @tmp = split(/,/,$tmp);
	push(@fio,@tmp) if (@tmp);
	next;
    }
    elsif ($f eq "-c") {
	$conly = 1;
	next;
    }
    elsif ($f eq "-F") {
	$Fonly = 1;
	next;
    }
    elsif ($f =~ m{^--(target|main|root)=(\w+|\w+::\w+)$}) {
	push(@targets,&AdjustCase($2));
	next;
    }
    elsif ($f =~ m{^-D(\S+)$}) {
	push(@defs,"-D$1");
	next;
    }
    elsif ($f =~ m{^-U(\S+)$}) {
	push(@defs,"-U$1");
	next;
    }
    elsif ($f =~ m{^-I(\S+)$}) {
	$inc = $1;
	push(@incs,$inc),$incs{$inc}=1 unless (exists($incs{$inc}) || ! -d $inc);
	next;
    }
    elsif ($f =~ m{^--exclfile=(\S+)$}) {
	my $try = $1;
	push(@exclfile,$try) if (-r $try);
	next;
    }
    elsif ($f =~ m{^--exclfunc=(\S+)$}) {
	my $tmp = uc($1);
	my @tmp = split(/,/,$tmp);
	push(@exclfunc,@tmp) if (@tmp);
	next;
    }
    if (-d $f) { # the $f was a directory
	my $dir = $f;
	push(@incs,$dir),$incs{$dir}=1 unless (exists($incs{$dir}));
	
	my $trydir;
	$trydir = sprintf("%s/include",$dir);
	push(@incs,$trydir),$incs{$trydir}=1 unless (exists($incs{$trydir}) || ! -d $trydir);
	$trydir = sprintf("%s/../include",$dir);
	push(@incs,$trydir),$incs{$trydir}=1 unless (exists($incs{$trydir}) || ! -d $trydir);

	$cmd = sprintf("find %s -xtype f -name '*.F90' -o -name '*.F' -o -name '*.f90' -o -name '*.c' -o -name '*.h' 2>/dev/null | grep -Pv '(build\\S*/|/\\.\\w+)' | sort |",$dir);
	open(IN,$cmd) || next;
	for (<IN>) {
	    chomp;
	    s%^\./(\S+)%$1%;
	    $inc = m{^(.*)/} ? $1 : "include";
	    push(@incs,$inc),$incs{$inc}=1 unless (exists($incs{$inc}) || ! -d $inc);
	    if (-r $_) {
		if (m{\.c$}) {
		    push(@cfiles,$_);
		}
		elsif (m{\.h$}) {
		    push(@cfiles,$_) if (&IsCfile($_));
		}
		else {
		    push(@files,$_);
		}
	    }
	}
	close(IN);
	next;
    }

    $f = &CheckObjectFile($f);
    next unless (defined($f));
	
    $inc = ($f =~ m{^(.*)/}) ? $1 : "include";
    push(@incs,$inc),$incs{$inc}=1 unless (exists($incs{$inc}) || ! -d $inc);
    
    if (-r $f) {
	if ($f =~ m{\.c$}) {
	    push(@cfiles,$f);
	}
	elsif ($f =~ m{\.h$}) {
	    push(@cfiles,$f) if (&IsCfile($f));
	}
	else {
	    push(@files,$f);
	}
    }
    else {
	my @list = glob $f;
	if (@list) {
	    map {
		$inc = m{^(.*)/} ? $1 : "include";
		push(@incs,$inc),$incs{$inc}=1 unless (exists($incs{$inc}) || ! -d $inc);
		if (-r $_) {
		    if (m{\.c$}) {
			push(@cfiles,$_);
		    }
		    elsif (m{\.h$}) {
			push(@cfiles,$_) if (&IsCfile($_));
		    }
		    else {
			push(@files,$_);
		    }
		}
		else {
		    push(@targets,&AdjustCase($_));
		}
	    } @list;
	}
	else {
	    push(@targets,&AdjustCase($f));
	}
    }
}

$depth = undef if (defined($depth) && $depth < 1);

if ($conly) {
    @files = ();
}
else {
    @files = &Uniq(@files);
}
@cfiles = &Uniq(@cfiles);

unless ($dummies) {
    # Filter out routines that contain (case-insensitive) "dumm" in their path (directory and/or plain filename)
    if (@files) {
	my @tmp = ();
	map { push(@tmp,$_) unless (m{dumm}i);} @files;
	@files = @tmp;
    }
    if (@cfiles) {
	my @tmp = ();
	map { push(@tmp,$_) unless (m{dumm}i);} @cfiles;
	@cfiles = @tmp;
    }
}

if (@exclfile) { # exclfile these files
    if (@files) {
	my @tmp = ();
	for my $f (@files) {
	    my $found = 0;
	    for my $x (@exclfile) {
		$found = 1, last if ($f eq $x);
	    }
	    push(@tmp,$f) unless ($found);
	}
	@files = @tmp;
    }
    if (@cfiles) {
	my @tmp = ();
	for my $f (@cfiles) {
	    my $found = 0;
	    for my $x (@exclfile) {
		$found = 1, last if ($f eq $x);
	    }
	    push(@tmp,$f) unless ($found);
	}
	@cfiles = @tmp;
    }
}

@incs = &Uniq(@incs);
my $incs = (@incs) ? " -I".join(" -I",@incs) : "";

@defs = &Uniq(@defs);
my $defs = (@defs) ? " ".join(" ",@defs) : "";

# Scan#1: Make a list of functions defined & gather aggr max line count in any files
# Also, find routines behind CONTAINS-stmt in the modules & use statements (per file)

our %modfuncs = (); # key = (lowercase) modulename
our %uses = (); # key = filename
our %useonly = (); # key = "filename modulename" (combo)
our %aliases = (); # alias_func => true_func as in USE somemod, ONLY : alias_func => true_func
our %ifb = (); # module procedures : key = module_name::alias_name = interface_name 

my $maxlines = 0;
for my $f (@files) {
    next unless (-r $f);
    if ($f =~ m{\.f\w*$}) {
	open(IN,"< $f"); # no preproc
    }
    else {
	$cmd = sprintf("perl -pe 's/^\\s*\\#\\s*(include\\s+)/\$1/' %s | /lib/cpp -E%s - 2>/dev/null |",$f,$defs);
    }
    open(IN,$cmd) || next;
    my @in = <IN>;
    close(IN);
    my $nlines = @in;
    $maxlines = $nlines if ($maxlines < $nlines);
    
    my $mod = undef;
    my $contains = 0;
    my $interface = 0;
    my $cont = 0;
    my $usemod = undef;
    my $combo = undef;
    my $lineno = 0;
    my $ifbkey = undef;
    my @ifbval = ();
    my $ifblineno = undef;
    
    for (@in) {
	++$lineno;
	chomp;
	
	s/\s*\!.*$//; # strip comments
	next if (m{^\s*$});
	
	if (m{^\#\s+(\d+)\s+(\S+)}) {
	    my ($linenum,$file) = ($1,$2);
	    $lineno = $linenum - 1 if ($file eq '"<stdin>"');
	    next;
	}
	elsif (m{^\s*\#}) {
	    next;
	}
	
	if (m{^\s*interface(\s+\w+)?}i) {
	    if (defined($mod)) {
		$ifbkey = $1;
		$ifbkey =~ s/^\s+//, $ifbkey = uc($ifbkey), $ifblineno = $lineno if (defined($ifbkey));
	    }
	    @ifbval = ();
	    $cont = 0;
	    $interface = 1;
	    next;
	}
	elsif ($interface) {
	    if (m{^\s*end\s+interface\b}i) {
		if (defined($ifbkey) && @ifbval) {
		    my $ifbval = join(",",@ifbval);
		    $ifbval =~ s/[&]/ /g;
		    $ifbval =~ s/\s+//g;
		    $ifbval = uc($ifbval);
		    my @list = split(/,/,$ifbval);
		    map {
			if (length($_) > 0) {
			    my $key = &Merge($mod,$_);
			    $ifb{$key} = $ifbkey;
			}
		    } @list;
		    push(@{$modfuncs{$mod}},$ifbkey);
		    &NewCombo($f,$mod,$ifbkey);
		    my $this = &Merge($mod,$ifbkey);
		    $module{$this} = $mod;
		    $file{$this} = sprintf("%s:%d",$f,$ifblineno);
		    $kind{$this} = 40;
		}
		@ifbval = ();
		$ifbkey = undef;
		$ifblineno = undef;
		$cont = 0;
		$interface = 0;
	    }
	    elsif (defined($ifbkey)) {
		if (m{^\s*module\s+procedure\s*(.*)\s*$}i) {
		    my $name = $1;
		    if (length($name) > 0) {
			push(@ifbval,$name);
			$cont = 1 if ($name =~ m{[&]$});
		    }
		}
		elsif ($cont && m{^\s*(.*)\s*$}) {
		    my $name = $1;
		    if (length($name) > 0) {
			push(@ifbval,$name);
			$cont = 0 unless ($name =~ m{[&]$});
		    }
		}
	    }
            next;
        }

	if (!defined($mod) && m{^\s*module\s+(\w+)\b}i) {
	    my $name = lc($1);
	    next if ($name eq "procedure");
	    $mod = $name;
	    @{$modfuncs{$mod}} = ();
	    next;
	}
	elsif (defined($mod) && m{^\s*contains\b}i) {
	    $contains = 1;
	    next;
	}
	elsif (defined($mod) && m{^\s*end\s+module(\s+$mod)?}i) {
	    $contains = 0;
	    $mod = undef;
	    next;
	}

        if (m{^\s*use\s+(\w+)\b\s*(.*)\s*$}i) {
            $cont = 0;
            $usemod = lc($1); # NB: lowercase, since module name
            my $therest = uc($2);
	    $combo = &NewCombo($f,$usemod);
            if (defined($therest) && length($therest) > 0) {
                $therest =~ s/\s+//g;
                $cont = 1 if ($therest =~ m{[&]$});
                if ($therest =~ m{,ONLY:(.*)$}) {
                    my $last = $1;
                    $last =~ s/[,&]$//g;
                    my @symbols = split(/,/,$last);
		    &RemoveOperators(\@symbols);
		    &MarkAliases(\@symbols);
                    push(@{$useonly{$combo}},@symbols) if (@symbols);
                }
            }
        }
        elsif (defined($usemod) && $cont) {
            s/\s+//g;
            s/^[,&]//g;
            $cont = 0 unless (m{[&]$});
            s/[,&]$//g;
            $_ = uc($_);
            my @symbols = split(/,/);
	    &RemoveOperators(\@symbols);
	    &MarkAliases(\@symbols);
            push(@{$useonly{$combo}},@symbols) if (@symbols);
        }
        else {
            $cont = 0;
            $usemod = undef;
            $combo = undef;

	    my $name = undef;
	    my $newkind = 0;
	    if (m{^\s*subroutine\s+(\w+)\b}i) {
		$name = uc($1);
		$newkind = 41;
	    }
	    elsif (m{^\s*(\S*)\s*function\s+(\w+)\b}i) {
		$name = uc($2);
		$newkind = 42;
		push(@func,$name);
	    }
	    
	    if (defined($name) && $contains && defined($mod)) {
		push(@{$modfuncs{$mod}},$name);
		&NewCombo($f,$mod,$name);
		my $this = &Merge($mod,$name);
		my $keyifb = exists($ifb{$this}) ? &Merge($mod,$ifb{$this}) : undef;
		if (defined($keyifb) && exists($kind{$keyifb}) && $kind{$keyifb} == 40) {
		    $kind{$keyifb} = $newkind;
		    printf("# NB in %s : %s (%s) : kind{%s} = %d\n",$f,$name,$this,$keyifb,$kind{$keyifb}) if ($debug);
		}
	    }
	}
    }
}
exit 0 unless ($maxlines > 0 || @cfiles);

for my $mod (sort { $a cmp $b } keys %modfuncs) {
    my $cnt = @{$modfuncs{$mod}} = &Uniq(@{$modfuncs{$mod}});
    unless (@{$modfuncs{$mod}}) {
	my $s = sprintf("# Module %s CONTAINS #%d routines : {%s}",$mod,$cnt,join(",",@{$modfuncs{$mod}}));
	printf("%s\n",$s) if ($debug);
    }
    else {
	delete $modfuncs{$mod};
    }
}
printf("\n") if ($debug && keys %modfuncs > 0);

for my $combo (sort { $a cmp $b } keys %useonly) {
    my ($f,$mod) = split(/\s+/,$combo);
    unless (@{$useonly{$combo}}) { # Nothing filled := all symbols will be included
	push(@{$useonly{$combo}},@{$modfuncs{$mod}}) if (exists($modfuncs{$mod}));
    }
    delete $useonly{$combo} unless (@{$useonly{$combo}}); # no symbols here (e.g. a plain (external) "use netcdf")
    if (exists($useonly{$combo})) {
	@{$useonly{$combo}} = &Uniq(@{$useonly{$combo}});
	my $s = sprintf("# File %s : USE %s, ONLY : %s",$f,$mod,join(",",@{$useonly{$combo}}));
	printf("%s\n",$s) if ($debug);
    }
}
printf("\n") if ($debug && keys %useonly > 0);

for my $f (sort { $a cmp $b } keys %uses) {
    my $cnt = @{$uses{$f}} = &Uniq(@{$uses{$f}});
    my $s = sprintf("# File %s has #%d USE-stmts : {%s}",$f,$cnt,join(",",@{$uses{$f}}));
    printf("%s\n",$s) if ($debug);
}
printf("\n") if ($debug && keys %uses > 0);

our $ndigits = length(sprintf("%d",$maxlines));

# Add Fortran I/O "functions"

my @iofuncs = ();
if (@fio) {
    $nofio = 0;
    @iofuncs = &Uniq(@fio);
}
else {
    @iofuncs = qw(READ WRITE OPEN CLOSE REWIND INQUIRE FLUSH);
}
map { $kind{$_} = 3; } @iofuncs;

my $ioregex = $nofio ? undef : join("|",@iofuncs);
$ioregex = undef unless (defined($ioregex) && length($ioregex) > 0);

if (@exclfunc) {
    my @tmp = ();
    for my $f (@func) {
	my $found = 0;
	for my $x (@exclfunc) {
	    $found = 1, last if ($f eq $x);
	}
	push(@tmp,$f) unless ($found);
    }
    @func = @tmp;
}
my $funcregex = @func ? join("|",@func) : "";
$funcregex = undef unless (length($funcregex) > 0);

# Scan#2: Proper scan that makes use of function list

our %dupl = (); # routines with duplicate name occurrences

@func = ();
for my $f (@files) {
    next unless (-r $f);
    if ($f =~ m{\.f\w*$}) {
	open(IN,"< $f"); # no preproc
    }
    else {
	$cmd = sprintf("perl -pe 's/^\\s*\\#\\s*(include\\s+)/\$1/' %s | /lib/cpp -E%s - 2>/dev/null |",$f,$defs);
    }
    open(IN,$cmd) || next;
    my @in = <IN>;
    close(IN);
    my @list = ();
    my $this = undef;
    my $lineno = 0;
    my $mod = undef;
    my $contains = 0;
    my $interface = 0;
    for (@in) {
	++$lineno;
	chomp;

	s/\s*\!.*$//; # strip comments
	next if (m{^\s*$});

	if (m{^\#\s+(\d+)\s+(\S+)}) {
	    my ($linenum,$file) = ($1,$2);
	    $lineno = $linenum - 1 if ($file eq '"<stdin>"');
	    next;
	}
	elsif (m{^\s*\#}) {
	    next;
	}
	
	if (m{^\s*interface\b}i) {
	    $interface = 1;
	    next;
	}
	elsif ($interface) {
	    $interface = 0 if (m{^\s*end\s+interface\b}i);
            next;
        }
	
	if (!defined($mod) && m{^\s*module\s+(\w+)\b}i) {
	    my $name = lc($1);
	    next if ($name eq "procedure");
	    $mod = $name;
	    next;
	}
	elsif (defined($mod) && m{^\s*contains\b}i) {
	    $contains = 1;
	    next;
	}
	elsif (defined($mod) && m{^\s*end\s+module(\s+$mod)?}i) {
	    $contains = 0;
	    $mod = undef;
	    next;
	}

	s/\bcall\s+(flush)\b/$1/i;
	
	if (m{^\s*program\s+(\w+)\b}i) {
	    $this = uc($1);
	    push(@list,$this);
	    push(@prog,$this);
	    @{$tree{$this}} = ();
	    $file{$this} = sprintf("%s:%d",$f,$lineno);
	    $kind{$this} = 0;
	}
	elsif (m{^\s*subroutine\s+(\w+)\b}i) {
	    $this = uc($1);
	    $file{$this} = sprintf("%s:%d",$f,$lineno) if (@targets && !exists($file{$this}));
	    $kind{$this} = 1 if (@targets && !exists($kind{$this}));
	    if ($contains && defined($mod)) {
		$module{$this} = $mod, @{$dupl{$this}} = () unless (exists($module{$this}));
		push(@{$dupl{$this}},$mod);
		$this = &Merge($mod,$this);
		$module{$this} = $mod;
	    }
	    push(@list,$this);
	    push(@subr,$this);
	    @{$tree{$this}} = ();
	    $file{$this} = sprintf("%s:%d",$f,$lineno);
	    $kind{$this} = 1;
	}
	elsif (m{^\s*(\S*)\s*function\s+(\w+)\b}i) {
	    my $first = $1;
	    next if (defined($first) && $first =~ m{^end}i);
	    $this = uc($2);
	    $file{$this} = sprintf("%s:%d",$f,$lineno) if (@targets && !exists($file{$this}));
	    $kind{$this} = 2 if (@targets && !exists($kind{$this}));
	    if ($contains && defined($mod)) {
		$module{$this} = $mod, @{$dupl{$this}} = () unless (exists($module{$this}));
		push(@{$dupl{$this}},$mod);
		$this = &Merge($mod,$this);
		$module{$this} = $mod;
	    }
	    push(@list,$this);
	    push(@func,$this);
	    @{$tree{$this}} = ();
	    $file{$this} = sprintf("%s:%d",$f,$lineno);
	    $kind{$this} = 2;
	}
	elsif (defined($this)) {
	    my $iotmp = $_;
	    my $tmp = $_;
	    if (m{^\s*end\s*(function|subroutine|program)(\s+$this)?\b}i) {
		pop(@list);
		$this = $list[-1];
		next;
	    }
	    elsif (m{\bcall\s+([%\w]+)\b}i) { # subroutine calls
		my $name = uc($1);
		my $carryon1 = ($name =~ m{\bdr_hook\b}i) ? $drhook : 1;
		my $carryon2 = ($name =~ m{\w*abor\w*}i) ? $abort : 1;
		if ($carryon1 && $carryon2) {
		    my $modname = &WhichModule($name,$f);
		    $name = &Merge($modname,$name) if (defined($modname));
		    #next if ($this eq $name); # avoid recursion
		    push(@{$tree{$this}},sprintf("%s %s:%d",$name,$f,$lineno));
		}
		s/\bcall\s+([%\w]+)\b/ /; # remove CALL-stmt itself : this way "CALL OPEN(...)" does not qualify in ioregex below
		# fall thru
	    }
	    my $skip = undef;
	    if (defined($ioregex) && $iotmp =~ m{\b($ioregex)\s*\(\s*(.*)\s*$}io) { # fio:
		my $name = uc($1);
		$skip = $name; # avoid double counting as funcregex
		my $args = defined($2) ? $2 : ")";
		$args =~ s/\s*[&]\s*$//;
		push(@{$tree{$this}},sprintf("%s(%s %s:%d",$name,$args,$f,$lineno));
		# fall thru
	    }
	    if (defined($funcregex) && $tmp =~ m{\b($funcregex)\s*\(}io) { # fcall:
		while ($tmp =~ m{\b($funcregex)\s*\(}gio) {
		    my $name = uc($1);
		    unless (defined($skip) && $skip eq $name) { # roughly ok
			my $modname = &WhichModule($name,$f);
			$name = &Merge($modname,$name) if (defined($modname));
			push(@{$tree{$this}},sprintf("%s %s:%d",$name,$f,$lineno));
		    }
		}
	    }
	}
    }
}

# Ambiguous symbols found ?

our %amb = ();
for my $key (sort { $a cmp $b } keys %dupl) {
    my $cnt = @{$dupl{$key}};
    if ($cnt > 1) {
	my $s = sprintf("# Duplicate symbol %s found #%d modules : {%s}",$key,$cnt,join(",",@{$dupl{$key}}));
	printf("%s\n",$s) if ($debug);
	$amb{$key} = $cnt;
    }
}
printf("\n") if ($debug && keys %amb > 0);

# C-routines via cflow (if installed)
if (defined($cflow) && @cfiles) {
    for my $f (@cfiles) {
	my $s = sprintf("# %s",$f);
	push(@cout,$s);
	next unless (-r $f);
	$cmd = sprintf("%s%s%s --number --brief --tree --all --all --cpp %s%s%s 2>/dev/null",
		       $cflow,$defs,$incs,
		       $level ? "--print-level " : "",
		       defined($depth) ? sprintf("--depth=%d ",$depth) : "",
		       $f);
	$s = sprintf("# %s",$cmd);
	push(@cout,$s);
	$cmd .= " |";
	open(IN,$cmd) || next;
	for (<IN>) {
	    chomp;
	    unless ($level) {
		s/^(\s*\d+\s{1}).{2}/$1 /; # cut off leading two chars after the line number (+ one space)
	    }
	    else {
		s/^(\s*\d+\s*)(\{\s*\d+\})(\s{1}).{2}/$1$2$3 /;
	    }
	    s/([+\\])-/$1 /; # "+-" or "\-" become "+ " or "\ ", respectively 
	    s/\s+(\()/$1/g; # remove extra space before "("
	    s/(,)\s+/$1/g; # remove extra pace after ","
	    $s = sprintf("%s",$_);
	    push(@cout,$s);
	}
	close(IN);
	$s = sprintf("");
	push(@cout,$s);
    }
}

my $row;

if ($debug) {
    for my $key (sort { $a cmp $b } keys %tree) {
	my $tmp = join("|",@{$tree{$key}});
	printf("KEY=%s : {%s}\n",$key,$tmp);
    }
    printf("\n");
}

my $curly = $level ? sprintf(" {%4d}",0) : "";

if (@targets) {
    unless ($conly) {
	for my $name (@targets) {
	    my $f = &File($name);
	    my $mod = &WhichModule($name,$f);
	    $name = &Merge($mod,$name) if (defined($mod));
	    my $what = &KindStr($name);
	    #next unless (defined($what));
	    $what = "???" unless (defined($what)); 
	    %done = ();
	    $row = 1;
	    %tidy = ();
	    printf("# %s\n",$f);
	    &Tree(0,\$row,$name,undef,0,"$what ");
	    printf("%5d%s  END %s %s\n\n",$row,$curly,$what,&WithOutModule($name));
	}
    }
}
else {
    unless ($conly) {
	for my $name (@prog) {
	    %done = ();
	    $row = 1;
	    %tidy = ();
	    printf("# %s\n",&File($name));
	    &Tree(0,\$row,$name,undef,0,"PROGRAM ");
	    printf("%5d%s  END PROGRAM %s\n\n",$row,$curly,&WithOutModule($name));
	}
	
	for my $name (@subr) {
	    %done = ();
	    $row = 1;
	    %tidy = ();
	    printf("# %s\n",&File($name));
	    &Tree(0,\$row,$name,undef,0,"SUBROUTINE ");
	    printf("%5d%s  END SUBROUTINE %s\n\n",$row,$curly,&WithOutModule($name));
	}
	
	for my $name (@func) {
	    %done = ();
	    $row = 1;
	    %tidy = ();
	    printf("# %s\n",&File($name));
	    &Tree(0,\$row,$name,undef,0,"FUNCTION ");
	    printf("%5d%s  END FUNCTION %s\n\n",$row,$curly,&WithOutModule($name));
	}

    }
    
    # C-files, if any
    unless ($Fonly) {
	map { printf("%s\n",$_); } @cout if (@cout);
    }
}

exit 0;

# Functions

sub CheckObjectFile {
    my ($f) = @_;
    my $is_object = ($f =~ m{\.o$}) ? 1 : 0;
    if ($is_object) {
	my $plain = $f;
	$plain =~ s/\.o$//;
	for (qw(F90 F c h)) {
	    my $try = sprintf("%s.%s",$plain,$_);
	    return $try if (-r $try);
	};
	return undef;
    }
    return $f;
}

sub IsCfile {
    my ($f) = @_;
    my $is = 0;
    my $cmd = sprintf("file %s",$f);
    open(IN,"$cmd |");
    for (<IN>) {
	chomp;
	$is = 1 if (m{\bC\s+source\b});
	last;
    }
    close(IN);
    return $is;
}

sub NewCombo {
    my ($f,$mod,$name) = @_;
    my $combo = sprintf("%s %s",$f,$mod);
    @{$useonly{$combo}} = () unless (exists($useonly{$combo}));
    push(@{$useonly{$combo}},$name) if (defined($name));
    @{$uses{$f}} = () unless (exists($uses{$f}));
    push(@{$uses{$f}},$mod);
    return $combo;
}

sub RemoveOperators {
    my ($sym) = @_;
    if (defined($sym) && @$sym) {
	my @tmp = ();
	for (@$sym) {
	    push(@tmp,$_) unless (m{^OPERATOR\(\S+\)$});
	}
	@$sym = @tmp;
    }
}

sub MarkAliases {
    my ($sym) = @_;
    if (defined($sym) && @$sym) {
	my @tmp = ();
	for (@$sym) {
	    if (m{^(\w+)=>(\w+)$}) {
		my ($fake,$actual) = ($1,$2);
		$aliases{$fake} = $actual unless (exists($aliases{$fake})); # TBD multiple occurences
		#push(@tmp,$actual); # TBD
		push(@tmp,$fake); # TBD
	    }
	    else {
		push(@tmp,$_);
	    }
	}
	@$sym = @tmp;
    }
}
	
sub File {
    my ($name) = @_;
    my $file = exists($file{$name}) ? $file{$name} : "unknown";
    #$file =~ s/:\d+$//;
    $file .= sprintf(" (%s%s)",&KindStr($name,""," "),&WithModule($name));
    return $file;
}

sub Kind {
    my ($name) = @_;
    $name =~ s/^(\w+)\s*\(.*$/$1/;
    return exists($kind{$name}) ? $kind{$name} : undef;
}

sub KindStr {
    my ($name,$default,$append) = @_;
    $append = "" unless defined($append);
    my $what = &Kind($name);
    $what = -1 unless (defined($what));
    if (defined($what)) {
	if ($what == 0)    { $what = "PROGRAM".$append; }
	elsif ($what == 1) { $what = "SUBROUTINE".$append; }
	elsif ($what == 2) { $what = "FUNCTION".$append; }
	elsif ($what >= 40) { $what = "INTERFACE".$append; }
	else { $what = $default; }
    }
    return $what;
}

sub WithModule {
    my ($name) = @_;
    my $mod = &GetModule($name);
    my $expansion = defined($mod) ? &Merge($mod,$name) : sprintf("%s",$name);
    if (!defined($mod) && exists($module{$name})) {
	$mod = $module{$name};
	$expansion = &Merge($mod,$name);
    }
    return $expansion;
}

sub WithOutModule {
    my ($name) = @_;
    $name =~ s/^.*:://;
    return $name;
}

sub GetModule {
    my ($name) = @_;
    return ($name =~ m{^(\w+)::}) ? $1 : undef;
}

sub AdjustCase {
    my ($name) = @_;
    if ($name =~ m{^(\w+)::(\w+)}) {
	$name = &Merge(lc($1),uc($2));
    }
    else {
	$name = uc($name);
    }
    return $name;
}

sub Merge {
    my ($mod,$name) = @_;
    return sprintf("%s::%s",$mod,&WithOutModule($name));
}

sub WhichModule {
    my ($name,$file) = @_;
    return undef unless (defined($name));
    my $try = &GetModule($name);
    return $try if (defined($try));
    if (defined($file)) {
	$file =~ s/:\d+$//;
	my $f = $file;
	if (exists($uses{$f})) {
	    for my $mod (@{$uses{$f}}) {
		my $combo = sprintf("%s %s",$f,$mod);
		next unless (exists($useonly{$combo}));
		for my $symbol (@{$useonly{$combo}}) {
		    return $mod if ($symbol eq $name);
		}
	    }
	}
    }
    return undef;
}

sub FindCrefs {
    my ($name) = @_;
    my $s = "";
    if (@cout) {
	($name) = split(/\s+/,$name);
	$name =~ s/^\w+:://;
	$name =~ s/^(\w+)\b.*$/$1/;
	my @found;
	unless ($level) {
	    @found = grep { /^\s*\d+\s+($name)[_]?\s*\(/i } @cout;
	}
	else {
	    @found = grep { /^\s*\d+\s+\{\s*\d+\}\s+($name)[_]?\s*\(/i } @cout;
	}
	$s = $found[0] if (@found);
	if (length($s) > 0) {
	    $s = sprintf(" %s",$1) if ($s =~ m{\s*(<.*>)});
	}
    }
    return $s;
}

sub Tree {
    my ($last,$row,$this,$flin,$nest,$prefix,$postfix,$ambiguous) = @_;
    return if (defined($depth) && $nest >= $depth);
    if ($debug && $$row == 1) {
	printf("last=%d,row=%d,this=%s,flin=%s,nest=%d,prefix='%s',postfix='%s',ambiguous=%s\n",
	       $last,$$row,$this,
	       defined($flin)?$flin:"<undef>",
	       $nest,
	       defined($prefix)?$prefix:"<undef>",
	       defined($postfix)?$postfix:"<undef>",
	       defined($ambiguous)?$ambiguous:"<undef>");
    }
    my $ps = "";
    $ps .= sprintf(" {%4d}",$nest) if ($level);
    $ps .= sprintf("  ");
    for (1..($nest-1)) { $ps .= sprintf('| '); }
    $ps .= sprintf(($last && !$tidy) ? '\ ' : '+ ') if ($nest > 0);
    my $fl = exists($file{$this}) ? $file{$this} : undef;
    my $bulk = sprintf("%s%s%s%s%s%s",
		       defined($prefix) ? $prefix : "",
		       ($$row == 1) ? &WithOutModule($this) : $this,
		       defined($postfix) ? $postfix : "",
		       defined($flin) ? sprintf(" [%s]",$flin) : "",
		       defined($fl) ? sprintf(" <%s%s at %s>",&KindStr($this,""," "),&WithModule($this),$fl) : &FindCrefs($this),
		       defined($ambiguous) ? sprintf(" !!! duplicate symbol !!!") : "");
    if ($tidy) {
	$bulk =~ s/\s*<.*>\s*$//;
	$bulk =~ s/\s+\[\S+:\d+\].*$//;
	$bulk =~ s/\s*\([^\)].*$//;
    }
    $ps .= $bulk;
    my $savedrow = $$row;
    unless (exists($tree{$this})) {
	my $try = &WithModule($this);
	printf("\nthis='%s' try='%s' exists(tree{try})=%s",$this,$try,exists($tree{$try}) ? "YES" : "NO") if ($debug);
	$this = $try if (exists($tree{$try}));
    }
    if (exists($tree{$this})) {
	unless (exists($done{$this})) {
	    &PrintRow($row,$ps);
	    $done{$this} = $savedrow; # this line prevents expansion of deep recursions
	    my $cnt = @{$tree{$this}};
	    my $f = exists($file{$this}) ? $file{$this} : undef;
	    for my $label (@{$tree{$this}}) {
		--$cnt;
		next unless ($label =~ m{^(.*)\s+(\S+)\s*$}); # always matching
		my ($name,$flout) = ($1,$2);
		my $word = ($name =~ m{^(\S+)}) ? $1 : $name;
		$word =~ s/\s+//g;
		$word =~ s/\(.*//;
		my $mod = &WhichModule($word,$flout);
		if (defined($mod)) {
		    $word = &Merge($mod,$word);
		    $name = &Merge($mod,$name);
		}
		my $amb = exists($amb{$word}) ? $amb{$word} : undef;
		my $k0 = &Kind($word);
		my $k = defined($k0) ? $k0 : &Kind($name);
		unless (defined($k)) {
		    unless (exists($tree{$name})) {
			my $try = &WithModule($name);
			printf("mod='%s' name='%s' try='%s' exists(tree{try})=%s\n",
			       defined($mod) ? $mod : "<undef>",
			       $name,$try,exists($tree{$try}) ? "YES" : "NO") if (exists($tree{$try}) && $debug);
			$name = $try, $k = &Kind($name) if (exists($tree{$try}));
		    }
		}
		my ($pre,$post) = (undef,undef);
		if (defined($k)) {
		    if ($k == 1) { $pre = "CALL "; }
		    elsif ($k == 2) { $post = "()"; }
		    elsif ($k == 3) { }
		    elsif ($k == 40) { }
		    elsif ($k == 41) { $pre = "CALL "; }
		    elsif ($k == 42) { $post = "()"; }
		}
		else {
		    $pre = "Call ";
		}
		unless (defined($depth) && $nest+1 >= $depth) {
		    #$$row++;
		    &Tree(($cnt==0) ? 1 : 0,$row,$name,$flout,$nest+1,$pre,$post,$amb);
		}
	    }
	}
	else {
	    $ps .= sprintf(" [see %d]",$done{$this}) if (!$tidy && @{$tree{$this}});
	    &PrintRow($row,$ps);
	}
    }
    else {
	&PrintRow($row,$ps);
    }
    $done{$this} = $savedrow unless (exists($done{$this}));
}

sub PrintRow {
    my ($row,$ps) = @_;
    if (!$tidy || ($tidy && !exists($tidy{$ps}))) {
	printf("%5d%s\n",$$row++,$ps);
	$tidy{$ps} = 1 if ($tidy);
    }
}

sub Uniq { 
# Preserves the original array order, but removes duplicates
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub SortUniq { 
# Removes duplicates and returns sorted array
    return sort(&Uniq(@_));
}

sub Sort { 
# Returns sorted array
    return sort(@_);
}

sub NumSortUniq { 
# Removes duplicates and returns sorted array
    return sort { $a <=> $b } (&Uniq(@_));
}

