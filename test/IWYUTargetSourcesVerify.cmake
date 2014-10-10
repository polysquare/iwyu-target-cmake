# /tests/IWYUTargetSourcesVerify.cmake
# Check that include-what-you-use was run on both the
# header and sources files.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*include-what-you-use.*Source.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT}
                               "^.*include-what-you-use.*Header.h.*$")