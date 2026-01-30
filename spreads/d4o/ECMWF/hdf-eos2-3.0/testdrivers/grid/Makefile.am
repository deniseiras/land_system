# testdrivers/grid Makefile.am

# Boilerplate definitions
#
include $(top_srcdir)/config/include.am
EXTRA_DIST = tutils.h



# Link against HDF-EOS2 libraries
#
AM_CPPFLAGS=-I$(top_srcdir)/include
LDADD=$(LIBHDFEOS2) $(LIBGCTP)


# Configure the test programs to build and run
#
check_PROGRAMS = testgrid
TEST_SEQUENCES=test_c
VERBOSE_TEST_SEQUENCES=test_c_verbose



if FORTRAN_77_CONDITIONAL
check_PROGRAMS += testgrid_f77

TEST_SEQUENCES+=test_f77
VERBOSE_TEST_SEQUENCES+=test_f77

if SZIP_ENCODER_CONDITIONAL
testgrid_f77_SOURCES = testgrid_szip77.f
else
testgrid_f77_SOURCES = testgrid77.f
endif
endif



test_c: $(check_PROGRAMS)
	./testgrid
test_c_verbose: $(check_PROGRAMS)
	./testgrid -v h
test_f77: $(check_PROGRAMS)
	rm -f Grid3.hdf Gridc_Test.hdf Gridf_Test.hdf testgridf.txt testgrid_f.txtout
	./testgrid_f77
test_f90: $(check_PROGRAMS)
	rm -f Grid3.hdf Gridc_Test.hdf Gridf_Test.hdf testgridf.txt testgrid_f.txtout
	./testgrid_f90

DISTCLEANFILES=Grid3.hdf Gridc_Test.hdf Gridf_Test.hdf testgridf.txt testgrid_f.txtout

check-local: $(TEST_SEQUENCES)
verbose_check: $(VERBOSE_TEST_SEQUENCES)

.PHONY: $(TEST_SEQUENCES)

