A tool to convert BUFR data to ODB2 format.

Dependencies
------------

 - C, C++ and Fortran compiler
 - [cmake](https://cmake.org)
 - [ecbuild](https://github.com/ecmwf/ecbuild)
 - [eccodes](https://github.com/ecmwf/eccodes)
 - [eckit](https://github.com/ecmwf/eckit)
 - [odc](https://github.com/ecmwf/odc)

Installation
------------

Extract the source code

    tar -xzf b2o-0.10.0-Source.tar.gz

Create build directory

    mkdir build

Set up environment variables

    SOURCE_DIR=b2o-0.10.0-Source 
    INSTALL_DIR=$HOME/local

Configure the build (here we assume dependecies were installed in `$INSTALL_DIR`)

    cd build
    ecbuild -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
            -Deccodes_ROOT=$INSTALL_DIR \
            -Deckit_ROOT=$INSTALL_DIR \
            -Dodc_ROOT=$INSTALL_DIR \
            $SOURCE_DIR

Build, test and install

    make -j2
    make test
    make install

Usage
-----

To do the conversion, simply run

    $ b2o synop.bufr -o synop.odb

To see more options, run

    $ b2o --help

