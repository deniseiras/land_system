export SHELL=/bin/bash

CINCL ?= 
ifeq ($(COMPILER),GNU)
  CC=gcc
  CFLAGS=-g -std=c99 -fopenmp -fPIC
  COPT=-O2
  FC=gfortran
  FCFLAGS=-g -std=f2008 -fopenmp -fPIC -fbacktrace
  FOPT=-O2
  #LDSHARED=gcc -g -fPIC -gstabs -shared -Wl,--eh-frame-hdr -Wl,--disable-new-dtags -Wl,-E
  #SOLIBS=-lgfortran -lsqlite3 -lm -ldl -lrt
  SOLIBS=-lm -ldl -lrt
else ifeq ($(COMPILER),INTEL)
  CC=$(shell which icx 2>/dev/null || echo icc)
  CFLAGS=-g -std=c99 -qopenmp -fPIC -traceback -diag-disable=10441
  COPT=-O2
  #FC=$(shell which ifx 2>/dev/null || echo ifort)
  FC=ifort
  FCFLAGS=-g -std08 -qopenmp -fPIC -traceback -assume buffered_io -no-wrap-margin -diag-disable=10448
  FOPT=-O2
  #LDSHARED=icc -g -fPIC -shared -Wl,--eh-frame-hdr -Wl,--disable-new-dtags -Wl,-E
  SOLIBS=-lm -ldl -lrt
else ifeq ($(COMPILER),INTELPROF)
  CC=$(shell which icx 2>/dev/null || echo icc)
  CFLAGS=-g -std=c99 -qopenmp -fPIC -traceback -diag-disable=10441 -finstrument-functions
  COPT=-O2
  #FC=$(shell which ifx 2>/dev/null || echo ifort)
  FC=ifort
  FCFLAGS=-g -std08 -qopenmp -fPIC -traceback -assume buffered_io -no-wrap-margin -diag-disable=10448 -finstrument-functions
  FOPT=-O2
  #LDSHARED=icc -g -fPIC -shared -Wl,--eh-frame-hdr -Wl,--disable-new-dtags -Wl,-E
  SOLIBS=-lm -ldl -lrt
else ifeq ($(COMPILER),PGI)
  CC=nvc
  CFLAGS=-g -c99 -mp -fPIC -traceback
  COPT=-O2
  FC=nvfortran
  FCFLAGS=-g -mp -fPIC -traceback
  FOPT=-O2
  #LDSHARED=nvc -g -fPIC -shared -Wl,--eh-frame-hdr -Wl,--disable-new-dtags -Wl,-E
  SOLIBS=-lm -ldl -lrt
else
  $(error Unsupported COMPILER=$(COMPILER) -- currently supporting only GNU or INTEL (or INTELPROF) or PGI)
endif

SQLITELIB=-lsqlite3

LD=$(CC)
LDFLAGS=$(CFLAGS)
LDSHARED=ld -shared --eh-frame-hdr --disable-new-dtags -E
LDLIBS ?=

#LDFC=$(FC)
#LDFCFLAGS=$(FCFLAGS)
#LIBS=-Wl,-rpath=$(PWD) -L$(PWD) -ld4o

export CC
export BL_CC=$(CC)
export BL_CFLAGS=$(CFLAGS) $(COPT)

PREFIX=/dev/null

MOD=mod

SCRIPTS_FILES=obseqd4o bufr2d4o catalogd4o trim_path bulk_create create_bufr_counts odcsql csv2sqlite box2csv \
reduce_obs_count.pl calltree.pl mode_paste nytprof-perl traceback_filter d4odiff d4osplit gregdate.pl \
d4omerge d4oshow d4ojoin d4ojoinall d4ocatalog \
d4omup d4omupall \
bufr_dump2csv bufr_dump2db gpsro_refrac get_gdb_trbk \
ICAO_ht2ps d4ofixtoc \
blcomp bl95.x \
oscargala.py synop_station_list.modify \
d4odropidx

KIND_FILES=obs_kind_mod.F90.clm obs_kind_mod.F90.camfv kindmap.clm.txt kindmap.camfv.txt obs_kind_mod.F90.anykind

OTHER_INCFILES=status_bits.F90.txt

DEL_FILES=$(PREFIX)/include/kindmap.clm $(PREFIX)/include/kindmap.camfv $(PREFIX)/bin/catalogd4o
DEL_FILES+=$(PREFIX)/../b2o/share/b2o/iasichannels # we now have equivalent to this as iasichannels.ecmwf

.SUFFIXES:
.SUFFIXES: .c .h .x .o .a .F90 .so .$(MOD)
.PHONY: .always

install: bl95.x
	pwd
	ls -ltra
	@set -e; [ -d $(PREFIX) ] || mkdir -pv $(PREFIX)
	@mkdir -pv $(PREFIX)/lib
	@mkdir -pv $(PREFIX)/bin
	@mkdir -pv $(PREFIX)/include
	rm -fv $(DEL_FILES) || :
	rsync -avL --stats libd4o.so $(PREFIX)/lib/
	rsync -avL --stats libblacklist.so $(PREFIX)/lib/
	rsync -avL --stats fd4o_mod.$(MOD) status_bits.$(MOD) $(KIND_FILES) $(OTHER_INCFILES) $(PREFIX)/include/
	rsync -avL --stats $(SCRIPTS_FILES) $(PREFIX)/bin/

bl95.x: libblacklist.so .always
	set -e; cd blacklist/scripts; ./build_bl95x; ./blcomp; cd -; cp -fv blacklist/scripts/bl95.x .

libd4o.so: fd4o.o d4o.o rsort32.o rsort64.o endian.o status_bits.o
#	$(LDSHARED) -Wl,-soname,$@ $^ $(SQLITELIB) $(SOLIBS) -o $@
	$(LDSHARED) -soname=$@ $^ $(SQLITELIB) $(SOLIBS) -o $@ $(LDLIBS)
	ldd -v $@

rsort32.o: rsort32.c d4o.h
rsort64.o: rsort64.c d4o.h
endian.o: endian.c d4o.h
d4o.o:	d4o.c d4o.h cas.h
fd4o.o: fd4o.F90 d4o.o
status_bits.o: status_bits.F90

libblacklist.so: blackbox.o blackbox_init.o blacklist.o dynamic_linking.o dynamic_symbols.o fail_nodefsh.o fast_strcmp.o funcs_varargs.o numarg_error.o parkind1.o wildcard_strcmp.o yomblackbox.o
#	$(LDSHARED) -Wl,-soname,$@ $^ $(SOLIBS) -o $@
	$(LDSHARED) -soname=$@ $^ $(SOLIBS) -o $@ $(LDLIBS)
	ldd -v $@

blackbox.o: blackbox.F90 parkind1.o yomblackbox.o
blackbox_init.o: blackbox_init.F90 parkind1.o yomblackbox.o
blacklist.o: blacklist.c meta.h
dynamic_linking.o: dynamic_linking.c
dynamic_symbols.o: dynamic_symbols.c d4o.h libd4o.so
fail_nodefsh.o: fail_nodefsh.c fail.h
fast_strcmp.o: fast_strcmp.c
funcs_varargs.o: funcs_varargs.c funcs_bla.h
numarg_error.o: numarg_error.c
parkind1.o: parkind1.F90
wildcard_strcmp.o: wildcard_strcmp.c
yomblackbox.o: parkind1.o

%.o:	%.c Makefile
	$(CC) -c $(CFLAGS) $(CINCL) $(COPT) $< -o $@

%.o:	%.F90 Makefile
	$(FC) -c $(FCFLAGS) $(FOPT) $< -o $@

clean:
	rm -fv *~
	rm -fv *.o
	rm -fv *.so
	rm -fv *.a
	rm -fv *.x
	rm -fv *.$(MOD)

