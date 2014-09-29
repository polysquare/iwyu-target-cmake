# /tests/IWYUPassCXXFlagsForCXXFilesVerify.cmake
# Check that include-what-you-use was passed CMAKE_CXX_FLAGS
# (eg -DUSING_CXX_FLAGS)
#
# See LICENCE.md for Copyright information

include (${IWYU_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (IWYU_COMMAND
     "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*-x.*c.*Source.cpp.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${IWYU_COMMAND})