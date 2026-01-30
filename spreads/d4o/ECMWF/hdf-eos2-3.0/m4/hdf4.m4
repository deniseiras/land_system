#################################################################################
## Utility functions for testing the availability of HDF4 libraries and headers
#################################################################################
# CHECK_LIBHDF4([path1,path2,..])

AC_DEFUN(
    [CHECK_LIBHDF4],
    [
        m4_foreach([path], [$1], [
            lib_path=path
            saved_LDFLAGS="$LDFLAGS"
            HDFSTATE="x$ac_cv_lib_df_Hopen x$ac_cv_lib_mfhdf_hdf_close"
            AS_IF([test -n "$lib_path"], [LDFLAGS="-L$lib_path $LDFLAGS"])

            AS_IF(
                [test "x$ac_cv_lib_df_Hopen" != "xyes"],
                [
                    unset ac_cv_lib_df_Hopen
                    AC_CHECK_LIB([df],[Hopen])
                ])
            AS_IF(
                [test "x$ac_cv_lib_mfhdf_hdf_close" != "xyes"],
                [
                    unset ac_cv_lib_mfhdf_hdf_close
                    AC_CHECK_LIB([mfhdf],[hdf_close])
                ])

            AS_IF(
                [test "$HDFSTATE" == "x$ac_cv_lib_df_Hopen x$ac_cv_lib_mfhdf_hdf_close"],
                [
                    # We found nothing extra, do revert LDFLAGS
                    LDFLAGS="$saved_LDFLAGS"
                ])
            ])
    ])

AC_DEFUN(
    [CHECK_INCHDF4],
    [
        m4_foreach([path], [$1], [
            inc_path=path
            saved_CPPFLAGS="$CPPFLAGS"
            AS_IF([test -n "$inc_path"], [CPPFLAGS="$CPPFLAGS -I$inc_path"])
            HDFSTATE="x$ac_cv_header_hdf_h x$ac_cv_header_mfhdf_h"

            AS_IF(
                [test "x$ac_cv_header_hdf_h" != "xyes"],
                [
                    unset ac_cv_header_hdf_h
                    AC_CHECK_HEADERS([hdf.h])
                ])
            AS_IF(
                [test "x$ac_cv_header_mfhdf_h" != "xyes"],
                [
                    unset ac_cv_header_mfhdf_h
                    AC_CHECK_HEADERS([mfhdf.h])
                ])

            AS_IF(
                [test "$HDFSTATE" == "x$ac_cv_header_hdf_h x$ac_cv_header_mfhdf_h"],
                [
                    CPPFLAGS="$saved_CPPFLAGS"
                ])
            ])
    ])

AC_DEFUN(
    [CHECK_HDF4],
    [
        # Check if we have the minimal headers and libraries

        AS_IF(
            [test "x$ac_cv_header_hdf_h" != xyes],
            [AC_MSG_ERROR([HDF4 header file hdf.h not found])]
        )
        AS_IF(
            [test "x$ac_cv_header_mfhdf_h" != xyes],
            [AC_MSG_ERROR([HDF4 header file mfhdf.h not found])]
        )
        AS_IF(
            [test "x$ac_cv_lib_df_Hopen" != xyes],
            [AC_MSG_ERROR([HDF4 library 'df' not found])]
        )
        AS_IF(
            [test "x$ac_cv_lib_mfhdf_hdf_close" != xyes],
            [AC_MSG_ERROR([HDF4 library 'mfhdf' not found])]
        )


        # Check to see if we can link a minimum HDF4 program

        AC_MSG_CHECKING([if we can link with hdf4])
        AC_LINK_IFELSE(
            [AC_LANG_PROGRAM(
                [
                    #include <hdf.h>
                ],[
                    Hopen(0, 0, 0);
                ])
            ],[
                AC_MSG_RESULT([yes])
            ],[
                AC_MSG_RESULT([no])
                AC_MSG_FAILURE([Unable to link with the hdf4 libraries - possibly a missing dependency (e.g. szlib)])
            ])

        HAVE_HDF4="yes"
    ])
