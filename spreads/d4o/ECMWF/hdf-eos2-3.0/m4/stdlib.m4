#################################################################################
## Utility functions for testing the availability of generic libraries
## on a list of paths
#################################################################################
# HDF_CHECK_LIB_PATH([lib],[func],[path1,path2,path3])

AC_DEFUN(
    [HDF_CHECK_LIB_PATH],
    [
        m4_foreach([path], [$3], [
            lib_path=path
            AS_IF(
                [test "x$AS_TR_SH([ac_cv_lib_$1_$2])" != "xyes"],
                [
                    unset AS_TR_SH([ac_cv_lib_$1_$2])
                    saved_LDFLAGS="$LDFLAGS"

                    AS_IF([test -n "$lib_path"], [LDFLAGS="-L$lib_path $LDFLAGS"])

                    AC_CHECK_LIB(
                        [$1],[$2],
                        [
                            AS_TR_SH([ac_cv_lib_$1_$2])="yes"
                            AS_TR_SH([AS_TR_SH([m4_toupper([HAVE_LIB$1])])])="yes"
                            lib_name=AS_TR_SH([m4_toupper([HAVE_LIB$1])])
                            AC_DEFINE_UNQUOTED([$lib_name],[1],[something here])
                            LIBS="-l$1 $LIBS"
                        ],[
                            LDFLAGS="$saved_LDFLAGS"
                            AS_TR_SH([ac_cv_lib_$1_$2])="no"
                        ])
                ])
        ])
    ])


#################################################################################
## Utility functions for testing the availability of generic libraries
#################################################################################
# HDF_CHECK_LIB([zlib],[z],[compress2],[path])
AC_DEFUN(
    [HDF_CHECK_LIB],
    [
        AC_ARG_WITH([$1],
            [AC_HELP_STRING([--with-$1=DIR],
                [Specify path to external $1 library.
                    Linker must be able to find $1 if HDF4
                    was built with $1.
                    [default=yes]])],,
            withval=yes)

        AS_IF(

            ## --with-<lib> with no directory. We must find it.
            ##
            [test "x$withval" == "xyes"],
            [
                HDF_CHECK_LIB_PATH([$2],[$3],[$4])
            ],


            ## --without-<lib>
            ## Nothing to do -  library just does not get added.
            ##
            [test "x$withval" == "xno"],,


            ## All other cases
            ##
            [
                AS_IF(
                    [test -z "$withval"],[
                        AC_MSG_ERROR([no $1 library path provided])
                    ],
                    [
                        LDFLAGS="-L$withval $LDFLAGS"
                        AC_CHECK_LIB(
                            [$2],[$3],,
                            [
                                AC_MSG_ERROR([couldn't find $1 library])
                            ])
                    ])
            ]
        )
    ])


