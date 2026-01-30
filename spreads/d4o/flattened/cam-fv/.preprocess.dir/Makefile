# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  preprocess
 
utilities_mod.o: utilities_mod.F90 types_mod.o
preprocess.o: preprocess.F90 types_mod.o utilities_mod.o parse_args_mod.o
null_mpi_utilities_mod.o: null_mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
parse_args_mod.o: parse_args_mod.F90 utilities_mod.o
types_mod.o: types_mod.F90
SRC = utilities_mod.F90 preprocess.F90 null_mpi_utilities_mod.F90 time_manager_mod.F90 parse_args_mod.F90 types_mod.F90
OBJ = utilities_mod.o preprocess.o null_mpi_utilities_mod.o time_manager_mod.o parse_args_mod.o types_mod.o
clean: neat
	-rm -f *.mod $(OBJ) preprocess
neat:
	-rm -f $(TMPFILES)
preprocess: $(OBJ)
	$(LD) $(OBJ) -o preprocess  $(LDFLAGS)

%.o: %.F90
	$(FC) $(FFLAGS) $(OTHERFLAGS) -c	$<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
