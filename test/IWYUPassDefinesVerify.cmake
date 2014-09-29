# /tests/IWYUPassDefinesVerify.cmake
# Check that include-what-you-use was run on both the
# header and sources files without custom define.
#
# See LICENCE.md for Copyright information

include (${IWYU_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (SOURCE_COMMAND "^.*include-what-you-use.*-DMY_DEFINE=1.*Source.cpp.*$")
set (HEADER_COMMAND "^.*include-what-you-use.*-DMY_DEFINE=1.*Header.h.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${SOURCE_COMMAND})
assert_file_has_line_matching (${BUILD_OUTPUT} ${HEADER_COMMAND})