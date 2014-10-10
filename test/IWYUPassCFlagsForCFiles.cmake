# /tests/IWYUTargetSources.cmake
# Sets up a target and runs include-what-you-use on it.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (IncludeWhatYouUse)

_validate_include_what_you_use (CONTINUE)

set (SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/Source.c)
set (SOURCE_FILE_CONTENTS
     "int main (void)\n"
     "{\n"
     "    return 0\;\n"
     "}\n")

file (WRITE ${SOURCE_FILE} ${SOURCE_FILE_CONTENTS})

set (EXECUTABLE executable)
add_executable (${EXECUTABLE}
                ${SOURCE_FILE})

set (CMAKE_C_FLAGS "-DUSING_C_FLAGS")

iwyu_target_sources (${EXECUTABLE})