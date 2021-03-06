# /FindIWYU.cmake
#
# This CMake script will search for include-what-you-use and set the following
# variables
#
# IWYU_FOUND : Whether or not include-what-you-use is available on the
#                    target system
# IWYU_VERSION : Version of include-what-you-use
# IWYU_EXECUTABLE : Fully qualified path to the include-what-you-use
#                         executable
#
# The following variables will affect the operation of this script
# IWYU_SEARCH_PATHS : List of directories to search for
#                           include-what-you-use in,
#                           before searching any system paths. This should be
#                           the prefix to which include-what-you-use was
#                           installed, and not the path that contains the
#                           include-what-you-use binary.
#                           Eg /opt/ not /opt/bin/
#
# See /LICENCE.md for Copyright information

include ("cmake/tooling-find-pkg-util/ToolingFindPackageUtil")

function (iwyu_find)

    # Set-up the directory tree of the include-what-you-use installation
    set (BIN_SUBDIR bin)
    set (IWYU_EXECUTABLE_NAMES include-what-you-use iwyu)

    foreach (IWYU_EXECUTABLE_NAME ${IWYU_EXECUTABLE_NAMES})

        psq_find_tool_executable (${IWYU_EXECUTABLE_NAME}
                                  IWYU_EXECUTABLE
                                  PATHS ${IWYU_SEARCH_PATHS}
                                  PATH_SUFFIXES "${BIN_SUBDIR}")

        if (IWYU_EXECUTABLE)

            break ()

        endif ()

    endforeach ()

    psq_find_tool_executable (${IWYU_EXECUTABLE_NAME}
                              IWYU_EXECUTABLE
                              PATHS ${IWYU_SEARCH_PATHS}
                              PATH_SUFFIXES "${BIN_SUBDIR}")

    psq_report_not_found_if_not_quiet (IWYU IWYU_EXECUTABLE
                                       "The 'include-what-you-use' executable"
                                       "was not found in any search or system"
                                       "paths.\n..Please adjust"
                                       "IWYU_SEARCH_PATHS to the"
                                       "installation prefix of the"
                                       "'include-what-you-use'\n.. executable"
                                       "or install include-what-you-use")

    if (IWYU_EXECUTABLE)

        set (IWYU_VERSION_HEADER
             "clang version ")

        psq_find_tool_extract_version ("${IWYU_EXECUTABLE}"
                                       IWYU_VERSION
                                       VERSION_ARG --version
                                       VERSION_HEADER
                                       "${IWYU_VERSION_HEADER}"
                                       VERSION_END_TOKEN " ")

    endif ()

    psq_check_and_report_tool_version (IWYU
                                       "${IWYU_VERSION}"
                                       REQUIRED_VARS
                                       IWYU_EXECUTABLE
                                       IWYU_VERSION)

    set (IWYU_FOUND ${IWYU_FOUND} PARENT_SCOPE)

endfunction ()

iwyu_find ()
