ecbuild_configure_file(test.sh.in test.sh @ONLY)

function(test name)

  cmake_parse_arguments(PARSE_ARGV 1 "test" "" "" "CONDITION;OPTIONS;RESOURCES")

  list(TRANSFORM test_OPTIONS REPLACE "(--|=)" "-" OUTPUT_VARIABLE suffixes)
  list(JOIN suffixes "-" suffix)

  ecbuild_add_test(LABELS b2o TARGET b2o-${name}${suffix}
    COMMAND ${PROJECT_BINARY_DIR}/tests/test.sh
    ARGS    ${test_OPTIONS} ${name} ${name}${suffix}
    ENVIRONMENT PATH=${CMAKE_BINARY_DIR}/bin:${odc_BASE_DIR}:$ENV{PATH}
                B2O_HOME=${PROJECT_BINARY_DIR}
                ECCODES_DEFINITION_PATH=${ECCODES_DEFINITION_PATH}
    RESOURCES ${name}.input ${name}${suffix}.expected ${test_RESOURCES}
    CONDITION ${test_CONDITION})

endfunction()
