#---------------------------------------------------------
# Makefile for C and C++ examples of calling RTTOV
#---------------------------------------------------------

# First compile RTTOV. Then:
# - set FC to the Fortran compiler used to build RTTOV and specify
#     appropriate compiler flags.
# - if necessary modify the path for the RTTOV libraries in RTTOV_LIBDIR


# NB The build/Makefile.local file is included below to determine
# whether RTTOV was compiled against the HDF5 library and if so
# the LDFLAGS_HDF5 macro provides the location of the HDF5 library
# and the rttov12_hdf library is included. If RTTOV was not compiled
# against the HDF5 library then the rttov12_hdf lib is omitted from
# the linking step.


#--- Compilers -------------------------------------------

# Select Fortran compiler used to compile RTTOV and specify flags:
FC=gfortran -g -fPIC
# FC=ifort -g -fPIC -nofor_main
# FC=pgf90 -g -fPIC -Mnomain
# FC=nagfor -g -PIC

# Location of RTTOV libraries
RTTOV_LIBDIR=../lib

# C and C++ compilers
CC=cc -w -g -fPIC -std=c99
CPP=c++ -w -g -pg -fPIC -std=c++0x

AR=ar rv

#---------------------------------------------------------


# --- Specify RTTOV libraries to link against ------------

# The LDFLAGS_HDF5 macro is defined in Makefile.local if RTTOV was
# compiled with HDF5. In this case the rttov12_hdf lib must be included.
include ../build/Makefile.local

ifdef LDFLAGS_HDF5
	# RTTOV libraries including HDF5
	RTTOV_LIBS=-L$(RTTOV_LIBDIR) -lrttov12_wrapper -lrttov12_other \
	                    -lrttov12_emis_atlas -lrttov12_brdf_atlas \
	                    -lrttov12_mw_scatt -lrttov12_parallel \
	                    -lrttov12_coef_io -lrttov12_hdf \
	                    -lrttov12_main
else
	# RTTOV libraries without HDF5
	RTTOV_LIBS=-L$(RTTOV_LIBDIR) -lrttov12_wrapper -lrttov12_other \
	                    -lrttov12_emis_atlas -lrttov12_brdf_atlas \
	                    -lrttov12_mw_scatt -lrttov12_parallel \
	                    -lrttov12_coef_io -lrttov12_main
endif

#---------------------------------------------------------


LIB=librttovcppwrapper.a

all : interface_example_c interface_example_cpp interface_example_rttovscatt_cpp Rttov_example Rttov_visirscatt_example RttovScatt_example RttovSafe_example RttovSafe_visirscatt_example RttovScattSafe_example

clean :
	\rm -f $(LIB) interface_example_c interface_example_cpp interface_example_rttovscatt_cpp Rttov_example Rttov_visirscatt_example RttovScatt_example RttovSafe_example RttovSafe_visirscatt_example RttovScattSafe_example *.o


# Compile object-oriented library librttovcppwrapper

Options.o : Options.h Options.cpp
	$(CPP) -I. -c Options.cpp

Profile.o : Profile.h Profile.cpp
	$(CPP) -I. -c Profile.cpp

Profiles.o : Profiles.h Profiles.cpp
	$(CPP) -I. -c Profiles.cpp

ProfileScatt.o : ProfileScatt.h ProfileScatt.cpp
	$(CPP) -I. -c ProfileScatt.cpp

ProfilesScatt.o : ProfilesScatt.h ProfilesScatt.cpp
	$(CPP) -I. -c ProfilesScatt.cpp

Rttov.o : Rttov.cpp Rttov.h Options.h Profiles.h
	$(CPP) -I. -c Rttov.cpp

RttovSafe.o : RttovSafe.cpp RttovSafe.h Options.h Profiles.h Rttov.h
	$(CPP) -I. -c RttovSafe.cpp

RttovScatt.o : RttovScatt.cpp RttovScatt.h Options.h ProfilesScatt.h
	$(CPP) -I. -c RttovScatt.cpp

RttovScattSafe.o : RttovScattSafe.cpp RttovScattSafe.h Options.h ProfilesScatt.h RttovScatt.h
	$(CPP) -I. -c RttovScattSafe.cpp

Atlas.o : Atlas.cpp Atlas.h RttovScatt.h RttovScattSafe.h Rttov.h RttovSafe.h ProfileScatt.h ProfilesScatt.h Profile.h Profiles.h
	$(CPP) -I. -c Atlas.cpp

$(LIB) : Atlas.o RttovScattSafe.o RttovScatt.o RttovSafe.o Rttov.o ProfilesScatt.o ProfileScatt.o Profiles.o Profile.o Options.o
	$(AR) $(LIB) Atlas.o RttovScattSafe.o RttovScatt.o RttovSafe.o Rttov.o ProfilesScatt.o ProfileScatt.o Profiles.o Profile.o Options.o


# Compile example code using object-oriented librttovcppwrapper

Rttov_example:  Rttov_example.cpp $(LIB)
	$(CPP) -I. -c Rttov_example.cpp
	$(FC) -I. -o Rttov_example Rttov_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

Rttov_visirscatt_example:  Rttov_visirscatt_example.cpp $(LIB)
	$(CPP) -I. -c Rttov_visirscatt_example.cpp
	$(FC) -I. -o Rttov_visirscatt_example Rttov_visirscatt_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

RttovScatt_example:  RttovScatt_example.cpp $(LIB)
	$(CPP) -I. -c RttovScatt_example.cpp
	$(FC) -I. -o RttovScatt_example RttovScatt_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

RttovSafe_visirscatt_example:  RttovSafe_visirscatt_example.cpp $(LIB)
	$(CPP) -I. -c RttovSafe_visirscatt_example.cpp
	$(FC) -I. -o RttovSafe_visirscatt_example RttovSafe_visirscatt_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

RttovSafe_example:  RttovSafe_example.cpp $(LIB)
	$(CPP) -I. -c RttovSafe_example.cpp
	$(FC) -I. -o RttovSafe_example RttovSafe_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

RttovScattSafe_example:  RttovScattSafe_example.cpp $(LIB)
	$(CPP) -I. -c RttovScattSafe_example.cpp
	$(FC) -I. -o RttovScattSafe_example RttovScattSafe_example.o $(LIB) $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++


# Compile example code using Fortran interface (does not require librttovcppwrapper)

interface_example_c:  interface_example_c.c
	$(CC) -I. -c interface_example_c.c
	$(FC) -I. -o interface_example_c interface_example_c.o $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm

interface_example_cpp:  interface_example_cpp.cpp
	$(CPP) -I. -c interface_example_cpp.cpp
	$(FC) -I. -o interface_example_cpp interface_example_cpp.o $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

interface_example_rttovscatt_cpp:  interface_example_rttovscatt_cpp.cpp
	$(CPP) -I. -c interface_example_rttovscatt_cpp.cpp
	$(FC) -I. -o interface_example_rttovscatt_cpp interface_example_rttovscatt_cpp.o $(RTTOV_LIBS) $(LDFLAGS_NETCDF) $(LDFLAGS_HDF5) $(LDFLAGS_LAPACK) -lm -lstdc++

