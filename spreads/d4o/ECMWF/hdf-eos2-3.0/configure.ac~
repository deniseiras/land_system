###################################
#       -*- Autoconf -*-
###################################



###################################
# Boilerplate autoconf setup
###################################
AC_PREREQ([2.59])
AC_INIT([hdf-eos2], [3.0], [null@bogus.email])
AC_CONFIG_AUX_DIR([config])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign])
AM_MAINTAINER_MODE


## Note we disable shared libraries otherwise gfortran fails linking against the resulting
## libX.la files. With shared libraries disables, libtool links gfortran against the static
## library libX.a. If fortran is disabled, this can be overridden using --enabled-shared
## with configure

LT_INIT([disable-shared])


###################################
# Files that need to be configured
###################################

AC_CONFIG_HEADER([include/HE2_config.h])
AC_CONFIG_FILES([Makefile
                include/Makefile
                doc/Makefile
                src/Makefile
                gctp/Makefile
                gctp/include/Makefile
                gctp/src/Makefile
                samples/Makefile
                testdrivers/Makefile
                testdrivers/grid/Makefile
                testdrivers/point/Makefile
                testdrivers/swath/Makefile])


###################################
#     Additional Macros
###################################
m4_include(m4/hdf4.m4)
m4_include(m4/stdlib.m4)
m4_include(m4/stdinc.m4)



###################################
#       Start checks
###################################

AC_LANG(C)

# Check for the math library that HDF4 needs
#
AC_CHECK_LIB([m], [ceil])


######################################################################
#  Check size of some types
# We pass these through directly via the cpp flags rather than the config
# file to make it easier (given the current code state) to get it where
# it needs to go.
######################################################################
AC_CHECK_SIZEOF(long)
CPPFLAGS="${CPPFLAGS} -DSIZEOF_LONG=$ac_cv_sizeof_long"



###################################
#  Check endian-ness
###################################
AC_C_BIGENDIAN([
    AC_DEFINE([BIG_ENDIAN],[1],[Define if system is big-endian])
    CPPFLAGS="${CPPFLAGS} -DBIG_ENDIAN=1"
])


###################################
#  JPEG library checks
###################################

# HDFEOS does not need libjpeg directly, but the HDF library might. This means
# we only need to find the libary, not the header files.

HDF_CHECK_LIB([jpeg],[jpeg],[jpeg_set_defaults],[,/usr/local/lib,/opt/local/lib,/usr/lib64])
AS_IF(
    [test -z "$HAVE_LIBJPEG"],
    [AC_MSG_ERROR(unable to find libjpeg)]
)



###################################
#  ZLIB library checks
###################################

# HDFEOS does not need libz directly, but the HDF library might. This means
# we only need to find the libary, not the header files.

HDF_CHECK_LIB([zlib],[z],[compress2],[,/usr/local/lib,/opt/local/lib,/usr/lib64])
AS_IF(
    [test -z "$HAVE_LIBZ"],
    [AC_MSG_ERROR(unable to find libz)]
)



###################################
#  FORTRAN compiler check
###################################

# User may enable fortran components explicity with --enable-fortran
# or --enable-fortran=yes

AC_PROG_F77
AC_ARG_ENABLE(
    [fortran],
    AS_HELP_STRING([--enable-fortran], [Enable fortran components/tests]),,)


# Check to see if explicitly disabled

AS_IF(
    [test "x$enable_fortran" == "xyes"],
    [
        # If we have Fortran 77, check its name mangling
        # We expect this to be one of UL, ul, UL_, ul_, _UL, _ul, _UL_, _ul_
        #
        AS_IF(
            [test -n "$F77"],
            [
                FORTRAN_77="yes"

                # Explicitly include known dependent macros, otherwise autotools will
                # bind them into the main body of the configure script where they will
                # be executed, regardeless as to whether or not FORTRAN is requested or
                # exists. This leads to failures on systems without FORTRAN compilers.
                
                AC_F77_LIBRARY_LDFLAGS
                AC_F77_DUMMY_MAIN
                _AC_F77_NAME_MANGLING
                AC_F77_FUNC([Ul],FORTRAN_NAME_MANGLE)

                # Set up the appropriate control definitions to give us the appropriate
                # FORTRAN api.
                #
                AS_IF(
                    # Check the common name mangling 'standards'

                    [test "$FORTRAN_NAME_MANGLE" == "ul"],[
                        FORTRAN_NAME_MANGLE="lower case"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API _DFORTRAN_API_LOWERCASE -DFORTRAN_API_SUFFIX= -DFORTRAN_API_PREFIX="
                    ],

                    [test "$FORTRAN_NAME_MANGLE" == "ul_"],[
                        FORTRAN_NAME_MANGLE="lower case, trailing underscore"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API -DFORTRAN_API_LOWERCASE -DFORTRAN_API_SUFFIX=_ -DFORTRAN_API_PREFIX="
                    ],

                    [test "$FORTRAN_NAME_MANGLE" == "_ul"],[
                        FORTRAN_NAME_MANGLE="lower case, leading underscore"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API -DFORTRAN_API_LOWERCASE -DFORTRAN_API_SUFFIX= -DFORTRAN_API_PREFIX=_"
                    ],

                    [test "$FORTRAN_NAME_MANGLE" == "UL"],[
                        FORTRAN_NAME_MANGLE="upper case"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API _DFORTRAN_API_UPPERCASE -DFORTRAN_API_SUFFIX= -DFORTRAN_API_PREFIX="
                    ],

                    [test "$FORTRAN_NAME_MANGLE" == "UL_"],[
                        FORTRAN_NAME_MANGLE="upper case, trailing underscore"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API -DFORTRAN_API_UPPERCASE -DFORTRAN_API_SUFFIX=_ -DFORTRAN_API_PREFIX="
                    ],

                    [test "$FORTRAN_NAME_MANGLE" == "_UL"],[
                        FORTRAN_NAME_MANGLE="upper case, leading underscore"
                        CPPFLAGS="$CPPFLAGS -DFORTRAN_API -DFORTRAN_API_UPPERCASE -DFORTRAN_API_SUFFIX= -DFORTRAN_API_PREFIX=_"
                    ],

                    [test -n "$FORTRAN_NAME_MANGLE"],
                    [
                        AC_MSG_ERROR([Unsupported fortran name-mangling - please use --disable-fortran])
                        FORTRAN_77="no"
                    ]
                )
            ])
    ])









###################################
#  SZLIB checks
###################################

dnl --------------------------------------------------
dnl Check whether szlib is enabled.
dnl If HDF4 is built with szlib, user should use --with-szlib=DIR option.
dnl If this option is given, whether SZIP is decoder only or decoder plus encoder
dnl should be checked.

AC_ARG_WITH([szlib],
            [AC_HELP_STRING([--with-szlib=DIR],
                            [Use szlib library for external szlib I/O
                             filter.  Linker must be able to find szlib
                             if HDF4 was build with szip.])],,
            withval=default)

AS_IF(
    ## if withval==no szlib is disabled
    ##
    [test "x$withval" == "xno"],
    [
        HAVE_LIBSZ="no"
    ],


    ## Look for it, but do not abort if we can't find it
    ##
    [test "x$withval" == "xdefault"],
    [
        HDF_CHECK_INC_PATH([szlib.h],[,/usr/local/include,/opt/local/include,/opt/local/lib/libaec/include])
        HDF_CHECK_LIB_PATH([sz],[SZ_BufftoBuffCompress],[,/usr/local/lib,/opt/local/lib,/opt/local/lib/libaec/lib,/usr/lib64])
    ],


    ## if withval==yes We need to find szlib
    ##
    [test "x$withval" == "xyes"],
    [

        HDF_CHECK_INC_PATH([szlib.h],[,/usr/local/include,/opt/local/include,/opt/local/lib/libaec/include])
        AS_IF(
            [test "x$ac_cv_header_szlib_h" != "xyes"],
            [AC_MSG_ERROR([couldn't find szlib header])]
        )

        HDF_CHECK_LIB_PATH([sz],[SZ_BufftoBuffCompress],[,/usr/local/lib,/opt/local/lib,/opt/local/lib/libaec/lib,/usr/lib64])
        AS_IF(
            [test "x$HAVE_LIBSZ" != "xyes"],
            [AC_MSG_ERROR([couldn't find szlib library])]
        )
    ],

    ##  Else
    ##
    [
        szlib_inc="`echo $withval |awk -F, '{print $1}'`"
        szlib_lib="`echo $withval |awk -F, '{print $2}'`"
        AS_IF(
            [test -z "$szlib_inc"],
            [
                # No options provided at all
            ],
            [
                # A single option provided - use it for both inc and lib, but add suffix
                AS_IF(
                    [test -z "$szlib_lib"],
                    [
                        szlib_lib="$szlib_inc/lib"
                        szlib_inc="$szlib_inc/include"
                    ])
                CPPFLAGS="-I$szlib_inc $CPPFLAGS"
                LDFLAGS="-L$szlib_lib $LDFLAGS"
            ])

        AC_CHECK_HEADERS(
            [szlib.h],,
            [
                AC_MSG_ERROR([couldn't find szlib header file])
            ])
        AC_CHECK_LIB(
            [sz],
            [SZ_BufftoBuffCompress],,
            [
                AC_MSG_ERROR([couldn't find szlib library])
            ])

        HAVE_LIBSZ="yes"
    ])



# If szlib is available, additional checks are required to determine the
# available functionality. By default decoding is assumed. We are really just
# interested in whether or not encoding is also enabled.

AS_IF(
    [test "x$HAVE_LIBSZ" == "xyes"],
    [
        # Check for encoding functionality

        AC_MSG_CHECKING([if szlib is functional])
        AC_TRY_RUN(
            [
                #include <stddef.h>
                #include <szlib.h>

                int main(void)
                {
                    SZ_encoder_enabled();
                    exit(0);
                }
            ],[
                AC_MSG_RESULT([yes])
            ],[
                AC_MSG_ERROR([szlib is not functional])
            ])
        AC_DEFINE(HAVE_FILTER_SZIP, 1, [Define if support for szip filter is enabled])

        AC_MSG_CHECKING([szlib encoding])
        AC_TRY_RUN(
            [
                #include <stddef.h>
                #include <szlib.h>

                int main(void)
                {
                    /* SZ_encoder_enabled returns 1 if encoder is present */
                    if(SZ_encoder_enabled() == 1)
                        exit(0);
                    else
                        exit(1);
                }
            ],[
                AC_MSG_RESULT([yes])
                AC_DEFINE(HAVE_FILTER_SZIP_ENCODER, 1, [Define if support for szip encoder filter is enabled])
                USE_SZIP_ENCODER="yes"
            ],[
                AC_MSG_RESULT([no])
            ])
    ])



###################################
#  Check for HDF4 library
###################################

# Note that this is a required component - we cannot build HDFEOS without it

AC_ARG_WITH(
    [hdf4],
    [AC_HELP_STRING(
        [--with-hdf4=DIR],
        [Specify path to HDF4 library to use while building
        [default=yes]]
    )],,
    withval=yes)


AS_IF(
    [test "x$withval" == "xno"],
    [
        AC_MSG_ERROR([HDF4 is a required dependency.])
    ],

    # No options, so we must try and find the HDF4 library

    [test "x$withval" == "xyes"],
    [
        # Test some library locations to see if we can find the HDF libraries

        CHECK_LIBHDF4([,/usr/local/lib,/opt/local/lib,/usr/lib64/hdf])


        # Check to see if we can find the HDF4 header file

        CHECK_INCHDF4([,/usr/local/include,/opt/local/include,/usr/include/hdf])
    ],


    # A user specified directory (one or two)

    [
        hdf4_inc="`echo $withval |awk -F, '{print $1}'`"
        hdf4_lib="`echo $withval |awk -F, '{print $2}'`"
        AS_IF(
            [test -z "$hdf4_lib"],
            [
                hdf4_lib="$hdf4_inc/lib"
                hdf4_inc="$hdf4_inc/include"
            ])

        CPPFLAGS="-I$hdf4_inc $CPPFLAGS"
        LDFLAGS="-L$hdf4_lib $LDFLAGS"

        AC_CHECK_LIB([df],[Hopen])
        AC_CHECK_LIB([mfhdf],[hdf_close])
        AC_CHECK_HEADERS([hdf.h])
        AC_CHECK_HEADERS([mfhdf.h])
    ])


# Verify presence of all required headers and libraries, and
# that we can link an hdf4 program. This will set
# HAVE_HDF4 if found, otherwise it will error out.

CHECK_HDF4





###################################
#  Check for SZIP in HDF4 library
###################################

# At this point, we know we can link against hdf4.

AC_MSG_CHECKING([for hdf4 szip decoding filter])
AC_RUN_IFELSE(
    [AC_LANG_PROGRAM(
        [
            #include <hdf.h>
        ],[
            comp_coder_t codertype = COMP_CODE_SZIP;
            uint32 configinfo;
            int decoder = 0;

            HCget_config_info(codertype, &configinfo);
            decoder = configinfo & COMP_DECODER_ENABLED;
            if (decoder) exit(0);
            else exit(1);
        ])
    ],
    [
        AC_MSG_RESULT([yes])

        # HDF4 supports decoding. We have to make sure szlib is included. In the case
        # of static library linkage, this would already have been verified (the program
        # wouldn't run), but shared object libraries might use lazy resolution, so we
        # verify
        AS_IF(
            [test "x$HAVE_LIBSZ" != "xyes"],
            [
                AC_MSG_ERROR([HDF4 requires SZIP, please use --with-szlib])
            ])

        AC_DEFINE(HAVE_HDF4_SZIP_DECODER, 1, [Define if HDF4 has szip decoder filter])
    ],[
        AC_MSG_RESULT([no])
    ])



AC_MSG_CHECKING([for hdf4 szip encoding support])
AC_RUN_IFELSE(
    [AC_LANG_PROGRAM(
        [
            #include <hdf.h>
        ],[
            comp_coder_t codertype = COMP_CODE_SZIP;
            uint32 configinfo;
            int encoder = 0;

            HCget_config_info(codertype, &configinfo);
            encoder = configinfo & COMP_ENCODER_ENABLED;
            if (encoder) exit(0);
            else exit(1);
        ])
    ],[
        AC_MSG_RESULT([yes])
        AS_IF(
            [test "x$USE_SZIP_ENCODER" != "xyes"],
            [
                AC_MSG_ERROR([HDF4 requires SZIP with encoding support])
            ])

        AC_DEFINE(HAVE_HDF4_SZIP_ENCODER, 1, [Define if HDF4 has szip encoder filter])
    ],[
        AC_MSG_RESULT([no])
    ])



###################################
#  Enable/disable installation of
# GCTP headers (usually not needed)
###################################
AC_ARG_ENABLE(
    [gctp-include],
    AS_HELP_STRING([--enable-gctp-include], [Enable installation of GCTP library headers]),,)

AM_CONDITIONAL([GCTP_INCLUDE_CONDITIONAL], [test "x$enable_gctp_include" == "xyes"])




###################################
#  Miscellaneous checks
###################################

CFLAGS=$CFLAGS

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET

# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([limits.h malloc.h stdlib.h string.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_OFF_T
AC_TYPE_SIZE_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MEMCMP
AC_FUNC_REALLOC
AC_FUNC_ERROR_AT_LINE
AC_CHECK_FUNCS([memchr memmove memset pow sqrt strchr strstr])

# Add a macro to distinguish automatic configuration from
# the original configuration; this will affect the handling
# of HDFEOSVersion.h file.
AC_DEFINE([EOS2_AUTO_CONFIG], [1], [Define the automatic configuration macro.])



AM_CONDITIONAL([FORTRAN_77_CONDITIONAL], [test "X$FORTRAN_77" = "Xyes"])
AM_CONDITIONAL([FORTRAN_90_CONDITIONAL], [test "X$FORTRAN_90" = "Xyes"])
AM_CONDITIONAL([SZIP_ENCODER_CONDITIONAL], [test "X$USE_SZIP_ENCODER" = "Xyes"])


AC_OUTPUT


###################################
# SUMMARY
###################################

AC_MSG_NOTICE([------------------------------------------])
AC_MSG_NOTICE([        Configuration Summary])
AC_MSG_NOTICE([------------------------------------------])

AC_MSG_NOTICE([ ])
AC_MSG_NOTICE([        ----- C ------])
AC_MSG_NOTICE([CC:                       $CC])
AC_MSG_NOTICE([C flags:                  $CFLAGS])
AC_MSG_NOTICE([CPP flags:                $CPPFLAGS])
AC_MSG_NOTICE([LD flags:                 $LDFLAGS])
AC_MSG_NOTICE([LIB flags:                $LIBS])

AC_MSG_NOTICE([ ])
AC_MSG_NOTICE([        -- FORTRAN --])
AS_IF(
    [test "x$FORTRAN_77" == "xyes"],
    [
        AC_MSG_NOTICE([F77:                      $F77])
        AC_MSG_NOTICE([FORTRAN name mangling:    $FORTRAN_NAME_MANGLE ])
    ],
    [
        AC_MSG_NOTICE([Not building FORTRAN 77 code])
    ])


