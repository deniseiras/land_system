execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_SOURCE_DIR}/b2o ${CMAKE_CURRENT_BINARY_DIR}/b2o)
install(DIRECTORY b2o DESTINATION ${INSTALL_DATA_DIR}/..)
file(GLOB_RECURSE resources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "b2o/*")
ecbuild_add_resources(TARGET b2o_resources SOURCES_PACK ${resources})
