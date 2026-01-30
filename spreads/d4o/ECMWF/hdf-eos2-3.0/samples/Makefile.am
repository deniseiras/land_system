##
## Samples source directory Makefile
##


include $(top_srcdir)/config/include.am

EXTRA_DIST = README fixedBuoy0.txt fixedBuoy1.txt floatBuoy0.txt floatBuoy1.txt simple.txt

## Location of necessary library header files for compilation

AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/gctp/include


## hdfeso and gctp libraries for linking

LDADD=$(LIBHDFEOS2) $(LIBGCTP)



## The sample programs to be built when the user types 'make check'

check_PROGRAMS=SetupSwath DefineFields WriteFields AppendField DefineGDflds DefineLevels \
               InquireGrid InquireSwath ReadFields ReadGDflds                            \
               ReadLevels SetupGrid SetupPoint                                           \
               SubsetGrid SubsetPoint SubsetSwath UpdateLevels                           \
               WriteGDflds WriteLevels


## Additional test programs if fortran is available

if FORTRAN_77_CONDITIONAL
check_PROGRAMS +=   \
	appendfield     \
	definefields    \
	definegdflds    \
	definelevels    \
	inquiregrid     \
	inquireswath    \
	readfields      \
	readgdflds      \
	readlevels      \
	setupgrid       \
	setuppoint      \
	setupswath      \
	subsetgrid      \
	subsetpoint     \
	subsetswath     \
	updatelevels    \
	writefields     \
	writegdflds     \
	writelevels


appendfield_SOURCES = appendfield.f
definefields_SOURCES = definefields.f
definegdflds_SOURCES = definegdflds.f
definelevels_SOURCES = definelevels.f
inquiregrid_SOURCES = inquiregrid.f
inquireswath_SOURCES = inquireswath.f
readfields_SOURCES = readfields.f
readgdflds_SOURCES = readgdflds.f
readlevels_SOURCES = readlevels.f
setupgrid_SOURCES = setupgrid.f
setuppoint_SOURCES = setuppoint.f
setupswath_SOURCES = setupswath.f
subsetgrid_SOURCES = subsetgrid.f
subsetpoint_SOURCES = subsetpoint.f
subsetswath_SOURCES = subsetswath.f
updatelevels_SOURCES = updatelevels.f
writefields_SOURCES = writefields.f
writegdflds_SOURCES = writegdflds.f
writelevels_SOURCES = writelevels.f

endif


## Tests consist of several programs run in succession. Each of these
## names is the name of such a "sequence" of tests.

TEST_SEQUENCES=swath_demo grid_demo point_demo

if FORTRAN_77_CONDITIONAL
TEST_SEQUENCES+=reset_hdf_files
TEST_SEQUENCES+=swath_demo_fortran grid_demo_fortran point_demo_fortran
endif



## 'make check' should run each of the test sequences above

check-local: $(TEST_SEQUENCES)


## Manually list the tests to be run in order for each test sequence.

swath_demo: $(check_PROGRAMS)
	./SetupSwath
	./DefineFields
	./WriteFields
	./ReadFields
	./InquireSwath
	./AppendField
	./SubsetSwath
swath_demo_fortran: $(check_PROGRAMS)
	./setupswath
	./definefields
	./writefields
	./readfields
	./inquireswath
	./appendfield
	./subsetswath

grid_demo: $(check_PROGRAMS)
	./SetupGrid
	./DefineGDflds
	./WriteGDflds
	./ReadGDflds
	./InquireGrid
	./SubsetGrid
grid_demo_fortran: $(check_PROGRAMS)
	./setupgrid
	./definegdflds
	./writegdflds
	./readgdflds
	./inquiregrid
	./subsetgrid

point_demo: $(check_PROGRAMS)
	./SetupPoint
	./DefineLevels
	./WriteLevels
	./ReadLevels
point_demo_fortran: $(check_PROGRAMS)
	./setuppoint
	./definelevels
	./writelevels
	./readlevels


## Some files generated during configure that should be cleaned.

DISTCLEANFILES=SwathFile.hdf GridFile.hdf PointFile.hdf

## Some files generated during C check should be cleaned for fortran test

reset_hdf_files:
	rm -f SwathFile.hdf GridFile.hdf PointFile.hdf

## This avoids any confusion between the names of the sequences and
## files with the same names.

.PHONY: $(TEST_SEQUENCES)

