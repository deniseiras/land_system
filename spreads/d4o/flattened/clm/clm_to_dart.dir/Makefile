# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  clm_to_dart
 
sort_mod.o: sort_mod.F90 types_mod.o
state_vector_io_mod.o: state_vector_io_mod.F90 adaptive_inflate_mod.o direct_netcdf_mod.o types_mod.o null_mpi_utilities_mod.o ensemble_manager_mod.o utilities_mod.o time_manager_mod.o io_filenames_mod.o model_mod.o state_structure_mod.o
null_mpi_utilities_mod.o: null_mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
utilities_mod.o: utilities_mod.F90 types_mod.o
obs_sequence_mod.o: obs_sequence_mod.F90 types_mod.o location_mod.o obs_def_mod.o obs_kind_mod.o time_manager_mod.o utilities_mod.o
obs_def_mod.o: obs_def_mod.F90 types_mod.o location_mod.o utilities_mod.o assim_model_mod.o ensemble_manager_mod.o obs_kind_mod.o time_manager_mod.o netcdf_utilities_mod.o obs_def_utilities_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
location_mod.o: location_mod.F90 types_mod.o utilities_mod.o random_seq_mod.o obs_kind_mod.o null_mpi_utilities_mod.o ensemble_manager_mod.o
location_io_mod.o: location_io_mod.F90 types_mod.o netcdf_utilities_mod.o location_mod.o
dart_time_io_mod.o: dart_time_io_mod.F90 types_mod.o time_manager_mod.o utilities_mod.o netcdf_utilities_mod.o
random_seq_mod.o: random_seq_mod.F90 types_mod.o utilities_mod.o
distributed_state_mod.o: distributed_state_mod.F90 null_mpi_utilities_mod.o types_mod.o ensemble_manager_mod.o null_win_mod.o utilities_mod.o
ensemble_manager_mod.o: ensemble_manager_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o null_mpi_utilities_mod.o sort_mod.o
obs_kind_mod.o: obs_kind_mod.F90 types_mod.o utilities_mod.o
obs_def_utilities_mod.o: obs_def_utilities_mod.F90 types_mod.o
io_filenames_mod.o: io_filenames_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o null_mpi_utilities_mod.o state_structure_mod.o ensemble_manager_mod.o netcdf_utilities_mod.o
netcdf_utilities_mod.o: netcdf_utilities_mod.F90 types_mod.o utilities_mod.o
options_mod.o: options_mod.F90 types_mod.o
model_mod.o: model_mod.F90 types_mod.o time_manager_mod.o location_mod.o utilities_mod.o netcdf_utilities_mod.o obs_kind_mod.o ensemble_manager_mod.o distributed_state_mod.o state_structure_mod.o obs_def_utilities_mod.o null_mpi_utilities_mod.o random_seq_mod.o default_model_mod.o
clm_to_dart.o: clm_to_dart.F90 types_mod.o utilities_mod.o model_mod.o time_manager_mod.o
assim_model_mod.o: assim_model_mod.F90 types_mod.o time_manager_mod.o ensemble_manager_mod.o model_mod.o
state_structure_mod.o: state_structure_mod.F90 utilities_mod.o obs_kind_mod.o types_mod.o netcdf_utilities_mod.o sort_mod.o
null_win_mod.o: null_win_mod.F90 types_mod.o ensemble_manager_mod.o
types_mod.o: types_mod.F90
adaptive_inflate_mod.o: adaptive_inflate_mod.F90 types_mod.o time_manager_mod.o utilities_mod.o random_seq_mod.o ensemble_manager_mod.o null_mpi_utilities_mod.o
default_model_mod.o: default_model_mod.F90 types_mod.o time_manager_mod.o location_mod.o utilities_mod.o netcdf_utilities_mod.o ensemble_manager_mod.o dart_time_io_mod.o
direct_netcdf_mod.o: direct_netcdf_mod.F90 types_mod.o options_mod.o ensemble_manager_mod.o time_manager_mod.o utilities_mod.o netcdf_utilities_mod.o null_mpi_utilities_mod.o state_structure_mod.o io_filenames_mod.o assim_model_mod.o model_mod.o
obs_d4o_mod.o: obs_d4o_mod.F90 utilities_mod.o obs_sequence_mod.o obs_def_mod.o location_mod.o time_manager_mod.o types_mod.o
SRC = sort_mod.F90 state_vector_io_mod.F90 null_mpi_utilities_mod.F90 utilities_mod.F90 obs_sequence_mod.F90 obs_def_mod.F90 time_manager_mod.F90 location_mod.F90 location_io_mod.F90 dart_time_io_mod.F90 random_seq_mod.F90 distributed_state_mod.F90 ensemble_manager_mod.F90 obs_kind_mod.F90 obs_def_utilities_mod.F90 io_filenames_mod.F90 netcdf_utilities_mod.F90 options_mod.F90 model_mod.F90 clm_to_dart.F90 assim_model_mod.F90 state_structure_mod.F90 null_win_mod.F90 types_mod.F90 adaptive_inflate_mod.F90 default_model_mod.F90 direct_netcdf_mod.F90 obs_d4o_mod.F90
OBJ = sort_mod.o state_vector_io_mod.o null_mpi_utilities_mod.o utilities_mod.o obs_sequence_mod.o obs_def_mod.o time_manager_mod.o location_mod.o location_io_mod.o dart_time_io_mod.o random_seq_mod.o distributed_state_mod.o ensemble_manager_mod.o obs_kind_mod.o obs_def_utilities_mod.o io_filenames_mod.o netcdf_utilities_mod.o options_mod.o model_mod.o clm_to_dart.o assim_model_mod.o state_structure_mod.o null_win_mod.o types_mod.o adaptive_inflate_mod.o default_model_mod.o direct_netcdf_mod.o obs_d4o_mod.o
clean: neat
	-rm -f *.mod $(OBJ) clm_to_dart
neat:
	-rm -f $(TMPFILES)
clm_to_dart: $(OBJ)
	$(MPILD) $(OBJ) -o clm_to_dart  $(LDFLAGS)

%.o: %.F90 Makefile ../mkmf.template
	$(MPIFC) $(FFLAGS) $(OTHERFLAGS) -c -D_clm_ $<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
