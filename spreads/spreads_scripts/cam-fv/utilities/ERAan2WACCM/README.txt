In order to convert ERA analysis file to WACCM .i files we need to

1 - convert the grib files to netcdf 
    (grib2nc.sh)

2 - generate the weights for the bilinear interpolation 
    (weights_horizontal_int_gen.ncl, weights_horizontal_int_stagLat_gen.ncl, weights_horizontal_int_stagLon_gen.ncl)

3 - interpolate on the new grid 
    (regrid.ncl)


