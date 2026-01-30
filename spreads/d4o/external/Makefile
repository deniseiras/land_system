include mkmf.template

.SUFFIXES:
.SUFFIXES: .F90 .o

TARGETS=Screening GlobalThinning

all: $(TARGETS)

%.o: %.F90 Makefile mkmf.template
	$(MPIFC) $(FFLAGS) $(OTHERFLAGS) -c $<

Screening: Screening.o
	$(MPILD) $< $(LDFLAGS) -o $@

GlobalThinning: GlobalThinning.o
	$(MPILD) $< $(LDFLAGS) -o $@

clean:
	-rm -fv *.o $(TARGETS)

