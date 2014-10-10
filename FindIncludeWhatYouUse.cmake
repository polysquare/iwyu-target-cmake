# FindIncludeWhatYouUse.cmake
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
#                           E.g. /opt/ not /opt/bin/
#
# See LICENCE.md for Copyright info

include (${CMAKE_CURRENT_LIST_DIR}/tooling-find-package-cmake-util/ToolingFindPackageUtil.cmake)

function (_find_iwyu)

    # Set-up the directory tree of the include-what-you-use installation
    set (BIN_SUBDIR bin)
    set (IWYU_EXECUTABLE_NAME include-what-you-use)

    psq_find_tool_executable (${IWYU_EXECUTABLE_NAME}
                              IWYU_EXECUTABLE
                              PATHS ${IWYU_SEARCH_PATHS}
                              PATH_SUFFIXES "${BIN_SUBDIR}")

    psq_report_not_found_if_not_quiet (IncludeWhatYouUse IWYU_EXECUTABLE
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

        psq_find_tool_extract_version (${IWYU_EXECUTABLE}
                                       IWYU_VERSION
                                       VERSION_ARG --version
                                       VERSION_HEADER
                                       "${IWYU_VERSION_HEADER}"
                                       VERSION_END_TOKEN " ")
        psq_check_and_report_tool_version (IncludeWhatYouUse
                                           ${IWYU_VERSION}
                                           FOUND_APPROPRIATE_VERSION)

        # If we found all the paths set IncludeWhatYouUse_FOUND and other
        # related variables
        if (FOUND_APPROPRIATE_VERSION)

            set (IncludeWhatYouUse_FOUND TRUE)
            set (IWYU_FOUND TRUE PARENT_SCOPE)
            set (IWYU_EXECUTABLE ${IWYU_EXECUTABLE} PARENT_SCOPE)
            set (IWYU_VERSION ${IWYU_VERSION} PARENT_SCOPE)

            psq_print_if_not_quiet (IncludeWhatYouUse
                                    "IncludeWhatYouUse version"
                                    "${IWYU_VERSION} found at"
                                    "${IWYU_EXECUTABLE}")

        else (FOUND_APPROPRIATE_VERSION)

            set (IncludeWhatYouUse_FOUND FALSE)

        endif (FOUND_APPROPRIATE_VERSION)

    endif (IWYU_EXECUTABLE)

    set (IncludeWhatYouUse_FOUND ${IncludeWhatYouUse_FOUND} PARENT_SCOPE)

    if (NOT IncludeWhatYouUse_FOUND)

        psq_report_tool_not_found (IncludeWhatYouUse
                                   "IncludeWhatYouUse was not found")

    endif (NOT IncludeWhatYouUse_FOUND)

endfunction (_find_iwyu)

_find_iwyu ()
