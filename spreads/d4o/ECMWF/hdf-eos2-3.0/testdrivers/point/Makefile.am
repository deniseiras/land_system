# testdrivers/point Makefile.am

# Boilerplate definitions
#
include $(top_srcdir)/config/include.am
EXTRA_DIST = tutils.h fixedBuoy0.txt fixedBuoy1.txt floatBuoy0.txt floatBuoy1.txt simple.txt


# Link against HDF-EOS2 libraries
#
AM_CPPFLAGS=-I$(top_srcdir)/include
LDADD=$(LIBHDFEOS2) $(LIBGCTP)


# Configure the test programs to build
#
check_PROGRAMS = testpoint
TEST_SEQUENCES=test_c
VERBOSE_TEST_SEQUENCES=test_c_verbose

if FORTRAN_77_CONDITIONAL
check_PROGRAMS += testpoint_f77
testpoint_f77_SOURCES = testpoint77.f

TEST_SEQUENCES+=test_f77
VERBOSE_TEST_SEQUENCES+=test_f77
endif



test_c: $(check_PROGRAMS)
	./testpoint
test_c_verbose: $(check_PROGRAMS)
	./testpoint -v h
test_f77: $(check_PROGRAMS)
	rm -f Pointc_Test.hdf Pointf_Test.hdf testpointf.txt testpoint_f.txtout
	./testpoint_f77
test_f90: $(check_PROGRAMS)
	rm -f Pointc_Test.hdf Pointf_Test.hdf testpointf.txt testpoint_f.txtout
	./testpoint_f90

DISTCLEANFILES=Pointc_Test.hdf Pointf_Test.hdf testpointf.txt testpoint_f.txtout

check-local: $(TEST_SEQUENCES)
verbose_check: $(VERBOSE_TEST_SEQUENCES)

.PHONY: $(TEST_SEQUENCES)

