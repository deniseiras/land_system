# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  obs_impact_tool
 
types_mod.o: types_mod.F90
parse_args_mod.o: parse_args_mod.F90 utilities_mod.o
obs_kind_mod.o: obs_kind_mod.F90 types_mod.o utilities_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
null_mpi_utilities_mod.o: null_mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
obs_impact_tool.o: obs_impact_tool.F90 types_mod.o utilities_mod.o obs_impact_mod.o
utilities_mod.o: utilities_mod.F90 types_mod.o
obs_impact_mod.o: obs_impact_mod.F90 types_mod.o utilities_mod.o obs_kind_mod.o parse_args_mod.o
SRC = types_mod.F90 parse_args_mod.F90 obs_kind_mod.F90 time_manager_mod.F90 null_mpi_utilities_mod.F90 obs_impact_tool.F90 utilities_mod.F90 obs_impact_mod.F90
OBJ = types_mod.o parse_args_mod.o obs_kind_mod.o time_manager_mod.o null_mpi_utilities_mod.o obs_impact_tool.o utilities_mod.o obs_impact_mod.o
clean: neat
	-rm -f *.mod $(OBJ) obs_impact_tool
neat:
	-rm -f $(TMPFILES)
obs_impact_tool: $(OBJ)
	$(LD) $(OBJ) -o obs_impact_tool  $(LDFLAGS)

%.o: %.F90
	$(FC) $(FFLAGS) $(OTHERFLAGS) -c	$<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
