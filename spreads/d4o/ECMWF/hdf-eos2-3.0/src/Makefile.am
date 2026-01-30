##
## HDFEOS source directory Makefile
##

include $(top_srcdir)/config/include.am



## Library to build

lib_LTLIBRARIES=libhdfeos.la


## Location of library header files

AM_CPPFLAGS=-I$(top_srcdir)/include/



# Set LDFLAGS to alow the HDF-EOS library to use extern variables from HDF4
#LDFLAGS=-Wl,-single_module



## Library source files

libhdfeos_la_SOURCES=EHapi.c GDapi.c PTapi.c SWapi.c

