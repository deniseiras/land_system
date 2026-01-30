# Makefile created by mkmf $Id$ 

include ../mkmf.template


.SUFFIXES:
.SUFFIXES: .F90 .o .so
all:  perfect_model_obs
 
quality_control_mod.o: quality_control_mod.F90 types_mod.o utilities_mod.o location_mod.o obs_sequence_mod.o obs_def_mod.o
utilities_mod.o: utilities_mod.F90 types_mod.o
reg_factor_mod.o: reg_factor_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
netcdf_utilities_mod.o: netcdf_utilities_mod.F90 types_mod.o utilities_mod.o
parse_args_mod.o: parse_args_mod.F90 utilities_mod.o
distributed_state_mod.o: distributed_state_mod.F90 mpi_utilities_mod.o types_mod.o ensemble_manager_mod.o no_cray_win_mod.o utilities_mod.o
obs_model_mod.o: obs_model_mod.F90 utilities_mod.o assim_model_mod.o state_vector_io_mod.o obs_sequence_mod.o obs_def_mod.o time_manager_mod.o ensemble_manager_mod.o mpi_utilities_mod.o io_filenames_mod.o
adaptive_inflate_mod.o: adaptive_inflate_mod.F90 types_mod.o time_manager_mod.o utilities_mod.o random_seq_mod.o ensemble_manager_mod.o mpi_utilities_mod.o
filter_mod.o: filter_mod.F90 types_mod.o options_mod.o obs_sequence_mod.o obs_def_mod.o obs_def_utilities_mod.o time_manager_mod.o utilities_mod.o assim_model_mod.o assim_tools_mod.o obs_model_mod.o ensemble_manager_mod.o adaptive_inflate_mod.o mpi_utilities_mod.o smoother_mod.o random_seq_mod.o state_vector_io_mod.o io_filenames_mod.o direct_netcdf_mod.o state_structure_mod.o forward_operator_mod.o quality_control_mod.o
state_structure_mod.o: state_structure_mod.F90 utilities_mod.o obs_kind_mod.o types_mod.o netcdf_utilities_mod.o sort_mod.o
options_mod.o: options_mod.F90 types_mod.o
forward_operator_mod.o: forward_operator_mod.F90 types_mod.o time_manager_mod.o utilities_mod.o mpi_utilities_mod.o obs_sequence_mod.o obs_def_mod.o obs_kind_mod.o ensemble_manager_mod.o distributed_state_mod.o quality_control_mod.o
obs_sequence_mod.o: obs_sequence_mod.F90 types_mod.o location_mod.o obs_def_mod.o obs_kind_mod.o time_manager_mod.o utilities_mod.o
location_io_mod.o: location_io_mod.F90 types_mod.o netcdf_utilities_mod.o location_mod.o
obs_impact_mod.o: obs_impact_mod.F90 types_mod.o utilities_mod.o obs_kind_mod.o parse_args_mod.o
time_manager_mod.o: time_manager_mod.F90 types_mod.o utilities_mod.o
location_mod.o: location_mod.F90 types_mod.o utilities_mod.o random_seq_mod.o obs_kind_mod.o mpi_utilities_mod.o ensemble_manager_mod.o
io_filenames_mod.o: io_filenames_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o mpi_utilities_mod.o state_structure_mod.o ensemble_manager_mod.o netcdf_utilities_mod.o
dart_time_io_mod.o: dart_time_io_mod.F90 types_mod.o time_manager_mod.o utilities_mod.o netcdf_utilities_mod.o
ensemble_manager_mod.o: ensemble_manager_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o mpi_utilities_mod.o sort_mod.o
assim_tools_mod.o: assim_tools_mod.F90 types_mod.o options_mod.o utilities_mod.o sort_mod.o random_seq_mod.o obs_sequence_mod.o obs_def_mod.o obs_kind_mod.o cov_cutoff_mod.o reg_factor_mod.o obs_impact_mod.o sampling_error_correction_mod.o location_mod.o ensemble_manager_mod.o mpi_utilities_mod.o adaptive_inflate_mod.o time_manager_mod.o assim_model_mod.o distributed_state_mod.o quality_control_mod.o
quad_utils_mod.o: quad_utils_mod.F90 types_mod.o location_mod.o utilities_mod.o options_mod.o
types_mod.o: types_mod.F90
sort_mod.o: sort_mod.F90 types_mod.o
chem_tables_mod.o: chem_tables_mod.F90 types_mod.o utilities_mod.o obs_kind_mod.o
sampling_error_correction_mod.o: sampling_error_correction_mod.F90 types_mod.o utilities_mod.o netcdf_utilities_mod.o
state_vector_io_mod.o: state_vector_io_mod.F90 adaptive_inflate_mod.o direct_netcdf_mod.o types_mod.o mpi_utilities_mod.o ensemble_manager_mod.o utilities_mod.o time_manager_mod.o io_filenames_mod.o model_mod.o state_structure_mod.o
random_seq_mod.o: random_seq_mod.F90 types_mod.o utilities_mod.o
direct_netcdf_mod.o: direct_netcdf_mod.F90 types_mod.o options_mod.o ensemble_manager_mod.o time_manager_mod.o utilities_mod.o netcdf_utilities_mod.o mpi_utilities_mod.o state_structure_mod.o io_filenames_mod.o assim_model_mod.o model_mod.o
no_cray_win_mod.o: no_cray_win_mod.F90 mpi_utilities_mod.o types_mod.o ensemble_manager_mod.o
assim_model_mod.o: assim_model_mod.F90 types_mod.o time_manager_mod.o ensemble_manager_mod.o model_mod.o
smoother_mod.o: smoother_mod.F90 types_mod.o mpi_utilities_mod.o utilities_mod.o ensemble_manager_mod.o time_manager_mod.o options_mod.o assim_tools_mod.o obs_sequence_mod.o adaptive_inflate_mod.o io_filenames_mod.o
default_location_mod.o: default_location_mod.F90 types_mod.o ensemble_manager_mod.o
obs_def_utilities_mod.o: obs_def_utilities_mod.F90 types_mod.o
cov_cutoff_mod.o: cov_cutoff_mod.F90 types_mod.o utilities_mod.o location_mod.o
obs_def_mod.o: obs_def_mod.F90 types_mod.o utilities_mod.o location_mod.o assim_model_mod.o obs_kind_mod.o ensemble_manager_mod.o obs_def_utilities_mod.o time_manager_mod.o
obs_kind_mod.o: obs_kind_mod.F90 types_mod.o utilities_mod.o
mpi_utilities_mod.o: mpi_utilities_mod.F90 types_mod.o utilities_mod.o time_manager_mod.o
perfect_model_obs.o: perfect_model_obs.F90 types_mod.o utilities_mod.o time_manager_mod.o obs_sequence_mod.o obs_def_mod.o obs_model_mod.o assim_model_mod.o mpi_utilities_mod.o random_seq_mod.o ensemble_manager_mod.o filter_mod.o state_vector_io_mod.o io_filenames_mod.o direct_netcdf_mod.o quality_control_mod.o distributed_state_mod.o forward_operator_mod.o
model_mod.o: model_mod.F90 types_mod.o time_manager_mod.o location_mod.o utilities_mod.o obs_kind_mod.o mpi_utilities_mod.o random_seq_mod.o ensemble_manager_mod.o distributed_state_mod.o state_structure_mod.o netcdf_utilities_mod.o chem_tables_mod.o quad_utils_mod.o default_model_mod.o
default_model_mod.o: default_model_mod.F90 types_mod.o time_manager_mod.o location_mod.o utilities_mod.o netcdf_utilities_mod.o ensemble_manager_mod.o dart_time_io_mod.o
SRC = quality_control_mod.F90 utilities_mod.F90 reg_factor_mod.F90 netcdf_utilities_mod.F90 parse_args_mod.F90 distributed_state_mod.F90 obs_model_mod.F90 adaptive_inflate_mod.F90 filter_mod.F90 state_structure_mod.F90 options_mod.F90 forward_operator_mod.F90 obs_sequence_mod.F90 location_io_mod.F90 obs_impact_mod.F90 time_manager_mod.F90 location_mod.F90 io_filenames_mod.F90 dart_time_io_mod.F90 ensemble_manager_mod.F90 assim_tools_mod.F90 quad_utils_mod.F90 types_mod.F90 sort_mod.F90 chem_tables_mod.F90 sampling_error_correction_mod.F90 state_vector_io_mod.F90 random_seq_mod.F90 direct_netcdf_mod.F90 no_cray_win_mod.F90 assim_model_mod.F90 smoother_mod.F90 default_location_mod.F90 obs_def_utilities_mod.F90 cov_cutoff_mod.F90 obs_def_mod.F90 obs_kind_mod.F90 mpi_utilities_mod.F90 perfect_model_obs.F90 model_mod.F90 default_model_mod.F90
OBJ = quality_control_mod.o utilities_mod.o reg_factor_mod.o netcdf_utilities_mod.o parse_args_mod.o distributed_state_mod.o obs_model_mod.o adaptive_inflate_mod.o filter_mod.o state_structure_mod.o options_mod.o forward_operator_mod.o obs_sequence_mod.o location_io_mod.o obs_impact_mod.o time_manager_mod.o location_mod.o io_filenames_mod.o dart_time_io_mod.o ensemble_manager_mod.o assim_tools_mod.o quad_utils_mod.o types_mod.o sort_mod.o chem_tables_mod.o sampling_error_correction_mod.o state_vector_io_mod.o random_seq_mod.o direct_netcdf_mod.o no_cray_win_mod.o assim_model_mod.o smoother_mod.o default_location_mod.o obs_def_utilities_mod.o cov_cutoff_mod.o obs_def_mod.o obs_kind_mod.o mpi_utilities_mod.o perfect_model_obs.o model_mod.o default_model_mod.o
clean: neat
	-rm -f *.mod $(OBJ) perfect_model_obs
neat:
	-rm -f $(TMPFILES)
perfect_model_obs: $(OBJ)
	$(MPILD) $(OBJ) -o perfect_model_obs  $(LDFLAGS)

%.o: %.F90
	$(MPIFC) $(FFLAGS) $(OTHERFLAGS) -c	$<

symlinks:
	set -e;for X in $(SRC); do ln -fs ../src/$$X .; git add $$X || :; done
