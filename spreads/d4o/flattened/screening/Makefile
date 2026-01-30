include mkmf.template

export CC
export BL_CC=$(CC)
export BL_CFLAGS=$(CFLAGS) $(COPT)

MOD=mod

.SUFFIXES:
.SUFFIXES: .F90 .o

TARGETS=screening.x

all: $(TARGETS)

%.o: %.F90 Makefile mkmf.template
	$(MPIFC) $(FFLAGS) $(OTHERFLAGS) -c $<

screening.x: screening.o ecmwf_varno_descr.o parkind.o blmod.o C_code.o
	$(MPILD) $^ $(LDFLAGS) -o $@ -lblacklist
	-ln -fsv $@ prescreening.x
	-ln -fsv $@ postscreening.x

screening.o: screening.F90 blmod.o parkind.o ecmwf_varno_descr.o

ecmwf_varno_descr.o: ecmwf_varno_descr.F90 parkind.o

parkind.o: parkind.F90

blmod.o: parkind.o blackbox.h blackbox_init.h

C_code.o: Blacklist.txt Makefile mkmf.template
	blcomp `readlink -f $<`

clean:
	-rm -fv *.o *.$(MOD) $(TARGETS) *.x
	-rm -fv C_code.c C_blacklist_header.h C_blacklist_body_entry.h


