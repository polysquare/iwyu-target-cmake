# /tests/IWYUFatalErrorOnFailureVerify.cmake
# Check that include-what-you-use was run on both the
# header and sources files.
#
# See LICENCE.md for Copyright information

include (${IWYU_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)
set (BUILD_ERROR ${CMAKE_CURRENT_BINARY_DIR}/BUILD.error)

file (READ ${BUILD_OUTPUT} BUILD_OUTPUT_CONTENTS)
file (READ ${BUILD_ERROR} BUILD_ERROR_CONTENTS)

set (ALL_BUILD
     ${CMAKE_CURRENT_BINARY_DIR}/ALL_BUILD)

file (WRITE ${ALL_BUILD}
      ${BUILD_OUTPUT_CONTENTS}
      ${BUILD_ERROR_CONTENTS})

assert_file_has_line_matching (${ALL_BUILD}
                               "^.*include-what-you-use found problems with.*$")