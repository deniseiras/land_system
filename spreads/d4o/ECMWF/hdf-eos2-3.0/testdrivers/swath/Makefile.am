# testdrivers/swath Makefile.am

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
check_PROGRAMS = testswath
TEST_SEQUENCES=test_c
VERBOSE_TEST_SEQUENCES=test_c_verbose



if FORTRAN_77_CONDITIONAL
check_PROGRAMS += testswath_f77
testswath_f77_SOURCES = testswath77.f

TEST_SEQUENCES+=test_f77
VERBOSE_TEST_SEQUENCES+=test_f77
endif



test_c: $(check_PROGRAMS)
	./testswath
test_c_verbose: $(check_PROGRAMS)
	./testswath -v h
test_f77: $(check_PROGRAMS)
	rm -f Swath_2.hdf Swathc_Test.hdf Swathf_Test.hdf testswathf.txt testswath_f.txtout
	./testswath_f77
test_f90: $(check_PROGRAMS)
	rm -f Swath_2.hdf Swathc_Test.hdf Swathf_Test.hdf testswathf.txt testswath_f.txtout
	./testswath_f90

DISTCLEANFILES=Swath_2.hdf Swathc_Test.hdf Swathf_Test.hdf testswathf.txt testswath_f.txtout

check-local: $(TEST_SEQUENCES)
verbose_check: $(VERBOSE_TEST_SEQUENCES)

.PHONY: $(TEST_SEQUENCES)

