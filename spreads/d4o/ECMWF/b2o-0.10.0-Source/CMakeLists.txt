cmake_minimum_required( VERSION 3.12 FATAL_ERROR )

find_package( ecbuild 3.4 REQUIRED HINTS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../ecbuild)

project(b2o LANGUAGES C CXX Fortran)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

ecbuild_find_package(NAME eccodes VERSION 2.19 REQUIRED)
ecbuild_find_package(NAME eckit   VERSION 1.13 REQUIRED)
ecbuild_find_package(NAME odc     VERSION 1.1  REQUIRED)

if(NOT eccodes_HAVE_FORTRAN)
  ecbuild_critical("b2o requires eccodes built with Fortran support, but eccodes package found was built without")
endif()

ecbuild_enable_fortran(REQUIRED MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/b2o/module)

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    ecbuild_add_fortran_flags("-ffree-line-length-none")
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
    ecbuild_add_fortran_flags("-assume realloc_lhs")
endif()

ecbuild_find_project_files()

add_subdirectory(src)
add_subdirectory(share)
add_subdirectory(tests)

ecbuild_pkgconfig(NAME ${PROJECT_NAME}
  DESCRIPTION "A tool (and a library) which converts (ECMWF) BUFR data to (IFS) ODB format"
  LIBRARIES ${B2O_LIBRARIES})

ecbuild_install_project(NAME ${PROJECT_NAME})

ecbuild_print_summary()
