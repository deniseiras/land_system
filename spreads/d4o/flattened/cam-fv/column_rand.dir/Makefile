# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  column_rand
 
null_mpi_utilities_mod.o: null_mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
utilities_mod.o: utilities_mod.F90 types_mod.o
column_rand.o: column_rand.F90 types_mod.o utilities_mod.o random_seq_mod.o
random_seq_mod.o: random_seq_mod.F90 types_mod.o utilities_mod.o
types_mod.o: types_mod.F90
SRC = null_mpi_utilities_mod.F90 time_manager_mod.F90 utilities_mod.F90 column_rand.F90 random_seq_mod.F90 types_mod.F90
OBJ = null_mpi_utilities_mod.o time_manager_mod.o utilities_mod.o column_rand.o random_seq_mod.o types_mod.o
clean: neat
	-rm -f *.mod $(OBJ) column_rand
neat:
	-rm -f $(TMPFILES)
column_rand: $(OBJ)
	$(LD) $(OBJ) -o column_rand  $(LDFLAGS)

%.o: %.F90
	$(FC) $(FFLAGS) $(OTHERFLAGS) -c	$<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
