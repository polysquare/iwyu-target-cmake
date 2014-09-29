# /tests/IWYUPassIncludesVerify.cmake
# Check that include-what-you-use was run on both the
# header and sources files with our includes.
#
# See LICENCE.md for Copyright information

include (${IWYU_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (HEADERS_REGEX ".*-I.*internal.*-isystem.*external.*")

set (SOURCE_COMMAND
	 "^.*include-what-you-use${HEADERS_REGEX}Source.cpp.*$")
set (HEADER_COMMAND
	 "^.*include-what-you-use${HEADERS_REGEX}Header.h.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${SOURCE_COMMAND})
assert_file_has_line_matching (${BUILD_OUTPUT} ${HEADER_COMMAND})