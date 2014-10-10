# /tests/IWYUPassCXXFlagsForCXXHeadersVerify.cmake
# Check that include-what-you-use was passed CMAKE_C_FLAGS
# (eg -DUSING_C_FLAGS)
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

set (IWYU_COMMAND
     "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*-x.*c.*Header.h.*$")
assert_file_has_line_matching (${BUILD_OUTPUT} ${IWYU_COMMAND})