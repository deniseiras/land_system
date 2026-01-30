#################################################################################
## Utility functions for testing the availability a given header file
## on a list of paths
#################################################################################
# HDF_CHECK_INC_PATH([header],[path1,path2,path3])

AC_DEFUN(
    [HDF_CHECK_INC_PATH],
    [
        m4_foreach([path], [$2], [
            inc_path=path

            AS_IF(
                [test "x$AS_TR_SH([ac_cv_header_$1])" != "xyes"],
                [
                    saved_CPPFLAGS="$CPPFLAGS"
                    AS_IF([test -n "$inc_path"], [CPPFLAGS="$CPPFLAGS -I$inc_path"])

                    unset AS_TR_SH([ac_cv_header_$1])
                    AC_CHECK_HEADERS(
                        [$1],,[
                            CPPFLAGS="$saved_CPPFLAGS"
                        ])
                ])
        ])
    ])
