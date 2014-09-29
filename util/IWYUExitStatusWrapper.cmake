# /util/IWYUExitStatusWrapper.cmake
# Wraps execution of include-what-you-use, exiting with 1
# if there are warnings or errors or 0 if include-what-you-use
# exits with the message "has correct #includes/fwd-decls"
#
# See LICENCE.md for Copyright information

set (IWYU_EXECUTABLE "" CACHE FORCE "")
set (IWYU_SOURCE "" CACHE FORCE "")
set (IWYU_COMPILER_ARGS "" CACHE FORCE "")
set (VERBOSE OFF CACHE FORCE "")
set (WARN_ONLY OFF CACHE FORCE "")

if (NOT IWYU_EXECUTABLE)

    message (FATAL_ERROR "include-what-you-use binary not specified. "
                         "This is a bug in IncludeWhatYouUse.cmake")

endif (NOT IWYU_EXECUTABLE)

if (NOT IWYU_SOURCE)

    message (FATAL_ERROR "IWYU_SOURCE not specified. "
                         "This is a bug in IncludeWhatYouUse.cmake")

endif (NOT IWYU_SOURCE)

set (IWYU_COMMAND_LINE
     ${IWYU_EXECUTABLE}
     ${IWYU_COMPILER_ARGS}
     ${IWYU_SOURCE})


if (VERBOSE)
    string (REPLACE ";" " " IWYU_PRINTED_COMMAND_LINE "${IWYU_COMMAND_LINE}")
    message (STATUS ${IWYU_PRINTED_COMMAND_LINE})
endif (VERBOSE)

execute_process (COMMAND
                 ${IWYU_COMMAND_LINE}
                 RESULT_VARIABLE RESULT
                 OUTPUT_VARIABLE OUTPUT
                 ERROR_VARIABLE ERROR
                 OUTPUT_STRIP_TRAILING_WHITESPACE
                 ERROR_STRIP_TRAILING_WHITESPACE)

string (REPLACE "\n" ";" ERROR_LINES "${ERROR}")

foreach (LINE ${ERROR_LINES})

    if ("${LINE}" MATCHES "^.*has correct #includes/fwd-decls.*$")

        set (SUCCESS TRUE)

    endif ("${LINE}" MATCHES "^.*has correct #includes/fwd-decls.*$")

endforeach ()

if (NOT SUCCESS)

    message ("${OUTPUT}")
    message ("${ERROR}")

    if (NOT WARN_ONLY)
        message (FATAL_ERROR
                 "include-what-you-use found problems with ${IWYU_SOURCE}")
    endif (NOT WARN_ONLY)

endif (NOT SUCCESS)