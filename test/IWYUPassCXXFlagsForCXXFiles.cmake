# /tests/IWYUPassCXXFlagsForCXXFiles.cmake
# Sets up a target and runs include-what-you-use on it, ensuring that
# CMAKE_CXX_FLAGS are passed for C++ sources.
#
# See LICENCE.md for Copyright information

include (${IWYU_CMAKE_TESTS_DIRECTORY}/CMakeUnit.cmake)
include (${IWYU_CMAKE_DIRECTORY}/IncludeWhatYouUse.cmake)

_validate_include_what_you_use (CONTINUE)

set (SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp)
set (SOURCE_FILE_CONTENTS
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n")

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE}
                ${SOURCE_FILE})

set (CMAKE_CXX_FLAGS "-DUSING_CXX_FLAGS")

iwyu_target_sources (${EXECUTABLE})