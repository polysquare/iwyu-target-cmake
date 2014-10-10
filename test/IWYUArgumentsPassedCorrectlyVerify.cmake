# /test/IWYUArgumentsPassedCorrectlyVerify.cmake
#
# Verify that passed args have no backslashes.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
set (BUILD_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BUILD.output)

assert_file_does_not_have_line_matching (${BUILD_OUTPUT}
                                         "^.*include-what-you-use.*\\\*$")