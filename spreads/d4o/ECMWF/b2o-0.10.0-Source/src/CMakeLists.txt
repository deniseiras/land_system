

list(APPEND b2o_headers

    b2o_api.h
    b2o/Reader.h
    b2o/Row.h
    b2o/SharedIterator.h
    b2o/schema.h
    datastream.h
)

list(APPEND b2o_sources ${b2o_headers}

#    b2o/Select.cc
    b2o/schema.cc
    b2o_convert_hiras.F90
    b2o_convert_ikfs2.F90
    b2o_convert_modes.F90
    b2o_convert_smap.F90
    b2o_convert_synop_land_tac.F90
    b2o_convert_synop_ship_tac.F90
    b2o_heap_template.h
    b2o_kind.F90
    b2o_schema.F90
    b2o_string.F90
    odbmap_reportype.F90

    b2o/Reader.cc
    b2o_accessor.F90
    b2o_accessor_abstract.F90
    b2o_accessor_compressed.F90
    b2o_accessor_uncompressed_multi.F90
    b2o_accessor_uncompressed_single.F90
    b2o_algorithm.F90
    b2o_amend.F90
    b2o_api.cc
    b2o_common.F90
    b2o_context.F90
    b2o_convert.F90
    b2o_convert_acars.F90
    b2o_convert_aeolus.F90
    b2o_convert_airep.F90
    b2o_convert_airs.F90
    b2o_convert_amdar_wigos.F90
    b2o_convert_amsr2_1d.F90
    b2o_convert_amsre_1d.F90
    b2o_convert_ascat.F90
    b2o_convert_asr.F90
    b2o_convert_atms.F90
    b2o_convert_atovs.F90
    b2o_convert_buoy_drifting.F90
    b2o_convert_buoy_moored.F90
    b2o_convert_cris.F90
    b2o_convert_fscat.F90
    b2o_convert_fy3.F90
    b2o_convert_gch1.F90
    b2o_convert_gch2.F90
    b2o_convert_gch3.F90
    b2o_convert_gch4.F90
    b2o_convert_gch5.F90
    b2o_convert_gmi.F90
    b2o_convert_grad.F90
    b2o_convert_iasi.F90
    b2o_convert_ims.F90
    b2o_convert_meris.F90
    b2o_convert_metar.F90
    b2o_convert_modisaer.F90
    b2o_convert_msg.F90
    b2o_convert_mwri_1d.F90
    b2o_convert_oscat.F90
    b2o_convert_paob.F90
    b2o_convert_pgps.F90
    b2o_convert_pilot.F90
    b2o_convert_pilot_tac.F90
    b2o_convert_qscat.F90
    b2o_convert_radio.F90
    b2o_convert_radio_lat_long.F90
    b2o_convert_rain_gauges.F90
    b2o_convert_rain_rates.F90
    b2o_convert_reo3.F90
    b2o_convert_satem.F90
    b2o_convert_satob.F90
    b2o_convert_scat.F90
    b2o_convert_smos.F90
    b2o_convert_snow.F90
    b2o_convert_ssmi.F90
    b2o_convert_ssmis_1d.F90
    b2o_convert_synop_land.F90
    b2o_convert_synop_ship.F90
    b2o_convert_tamdar.F90
    b2o_convert_temp_tac.F90
    b2o_convert_temp_hires.F90
    b2o_convert_tmi_1d.F90
    b2o_convert_viirs_aot.F90
    b2o_convert_windprofiler.F90
    b2o_convert_windsat.F90
    b2o_crc.c
    b2o_debug.h
    b2o_frame.F90
    b2o_functional.F90
    b2o_get.F90
    b2o_handle.F90
    b2o_internal.F90
#    b2o_log.F90
    b2o_option.F90
    b2o_set.F90
    b2o_table.F90
    b2o_thinning.F90
    b2o_thinning_heap.F90
    b2o_thinning_heap_node.F90
    b2o_utility.c
    b2o_utility.F90
    calc_azim.h
    calc_azim.F90
    datastream.F90
    datetimemod_aeol.F90
    fy3_corrections.F90
    geosangl.F90
 #   get_varindex.F90
    getval_module.F90
    satobfreq.F90
 #   varindex_module.F90
)

foreach(header b2o_config.h b2o_version.h)
    configure_file(${header}.in ${header})
endforeach()

foreach(file b2o_config.h b2o_version.h)
  configure_file(${file}.in ${file})
endforeach()

foreach(file b2o_schema_varno.h b2o_schema_vertco_type.h)
  string(REPLACE "b2o_schema_" "ddl/" ddl_file ${file})
  if(odb${PROJECT_PRECISION_SUFFIX}_SOURCE_DIR)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)
    add_custom_command(OUTPUT ${file}
      COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/b2o_schema.py ${odb${PROJECT_PRECISION_SUFFIX}_SOURCE_DIR}/${ddl_file} -o ${file}
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/b2o_schema.py ${odb${PROJECT_PRECISION_SUFFIX}_SOURCE_DIR}/${ddl_file}
      COMMENT "Generating ${file}")
    list(APPEND sources ${file})
  else()
    configure_file(${file}.in ${file} COPYONLY)
  endif()
endforeach()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    add_definitions(-D_ABI64)
endif()

if(NOT B2O_HAVE_ECLIB)
    list(APPEND b2o_sources eclib.h eclib_c.c error.c julian.h julian_lib.c myhdr.h)
endif()

if(NOT B2O_HAVE_IFSAUX)
    list(APPEND b2o_sources ifsaux.F90)
endif()

if(NOT HAVE_HAVE_ODB)
    list(APPEND b2o_sources solar.c twindow.c)
endif()

ecbuild_add_library(TARGET b2o
    INSTALL_HEADERS_LIST ${b2o_headers}
    HEADER_DESTINATION include/b2o
    DEFINITIONS B2O_STANDALONE
    SOURCES ${b2o_sources}
    PUBLIC_LIBS eccodes eccodes_f90 odccore eckit )

target_include_directories(b2o
    PUBLIC "$<INSTALL_INTERFACE:include>"
    PUBLIC "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src;${PROJECT_BINARY_DIR}/src>")

set(B2O_LIBRARIES b2o PARENT_SCOPE)

ecbuild_add_executable(
    TARGET b2o_tool
    OUTPUT_NAME b2o
    SOURCES b2o_main.cc b2o/Tool.cc b2o/Tool.h
    LIBS b2o)
