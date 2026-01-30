# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  advance_time
 
utilities_mod.o: utilities_mod.F90 types_mod.o
null_mpi_utilities_mod.o: null_mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
types_mod.o: types_mod.F90
parse_args_mod.o: parse_args_mod.F90 utilities_mod.o
advance_time.o: advance_time.F90 time_manager_mod.o utilities_mod.o parse_args_mod.o
SRC = utilities_mod.F90 null_mpi_utilities_mod.F90 time_manager_mod.F90 types_mod.F90 parse_args_mod.F90 advance_time.F90
OBJ = utilities_mod.o null_mpi_utilities_mod.o time_manager_mod.o types_mod.o parse_args_mod.o advance_time.o
clean: neat
	-rm -f *.mod $(OBJ) advance_time
neat:
	-rm -f $(TMPFILES)
advance_time: $(OBJ)
	$(LD) $(OBJ) -o advance_time  $(LDFLAGS)

%.o: %.F90
	$(FC) $(FFLAGS) $(OTHERFLAGS) -c	$<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
