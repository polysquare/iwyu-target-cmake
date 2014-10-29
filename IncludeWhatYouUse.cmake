# /IncludeWhatYouUse.cmake
# CMake macro to run include-what-you-use on each target source file.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)
include (${CMAKE_CURRENT_LIST_DIR}/tooling-cmake-util/PolysquareToolingUtil.cmake)

set (IWYU_EXIT_STATUS_WRAPPER
     ${CMAKE_CURRENT_LIST_DIR}/util/IWYUExitStatusWrapper.cmake)

macro (_validate_include_what_you_use CONTINUE)

    if (NOT DEFINED IncludeWhatYouUse_FOUND)

        find_package (IncludeWhatYouUse ${ARGN})

    endif (NOT DEFINED IncludeWhatYouUse_FOUND)

    set (${CONTINUE} ${IncludeWhatYouUse_FOUND})

endmacro ()

function (iwyu_target_sources TARGET)

    set (IWYU_SOURCES_OPTION_ARGS CHECK_GENERATED WARN_ONLY)
    set (IWYU_SOURCES_SINGLEVAR_ARGS FORCE_LANGUAGE)
    set (IWYU_SOURCES_MULTIVAR_ARGS
         EXTERNAL_INCLUDE_DIRS
         INTERNAL_INCLUDE_DIRS
         DEFINES
         CPP_IDENTIFIERS
         DEPENDS)

    cmake_parse_arguments (IWYU_SOURCES
                           "${IWYU_SOURCES_OPTION_ARGS}"
                           "${IWYU_SOURCES_SINGLEVAR_ARGS}"
                           "${IWYU_SOURCES_MULTIVAR_ARGS}"
                           ${ARGN})

    psq_strip_extraneous_sources (FILES_TO_CHECK ${TARGET})
    psq_handle_check_generated_option (IWYU_SOURCES FILES_TO_CHECK
                                       SOURCES ${FILES_TO_CHECK})

    set (IWYU_WRAPPER_OPTIONS
         -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
         -DIWYU_EXECUTABLE=${IWYU_EXECUTABLE})

    psq_add_switch (IWYU_WRAPPER_OPTIONS IWYU_SOURCES_WARN_ONLY
                    ON -DWARN_ONLY=TRUE
                    OFF -DWARN_ONLY=FALSE)

    psq_get_target_command_attach_point (${TARGET} WHEN)

    psq_append_each_to_options_with_prefix (IWYU_TARGET_ARGS
                                            -isystem
                                            LIST ${IWYU_SOURCES_EXTERNAL_INCLUDE_DIRS})
    psq_append_each_to_options_with_prefix (IWYU_TARGET_ARGS
                                            -I
                                            LIST ${IWYU_SOURCES_INTERNAL_INCLUDE_DIRS})
    psq_append_each_to_options_with_prefix (IWYU_TARGET_ARGS
                                            -D
                                            LIST ${IWYU_SOURCES_DEFINES})

    psq_forward_options (IWYU_SOURCES DETERMINE_LANG_FORWARD_OPTIONS
                         SINGLEVAR_ARGS FORCE_LANGUAGE
                         MULTIVAR_ARGS CPP_IDENTIFIERS)

    psq_sort_sources_to_languages (C_SOURCES CXX_SOURCES HEADERS
                                   INCLUDES
                                   ${IWYU_SOURCES_INTERNAL_INCLUDE_DIRS}
                                   SOURCES ${FILES_TO_CHECK}
                                   ${DETERMINE_LANG_FORWARD_OPTIONS})

    foreach (SOURCE ${FILES_TO_CHECK})

        list (FIND CXX_SOURCES ${SOURCE} CXX_INDEX)

        if (NOT CXX_INDEX EQUAL -1)

            set (IWYU_SOURCE_ARGS
                 "${CMAKE_CXX_FLAGS} -x c++")
            set (LANGUAGE_STAMP_OPTION "cxx")

        else (NOT CXX_INDEX EQUAL -1)

            set (IWYU_SOURCE_ARGS "${CMAKE_C_FLAGS}")
            set (LANGUAGE_STAMP_OPTION "c")

        endif (NOT CXX_INDEX EQUAL -1)

        # Convert spaces in IWYU_SOURCE_ARGS to "," delimiter
        string (REPLACE " " "," IWYU_SOURCE_ARGS "${IWYU_SOURCE_ARGS}")

        set (IWYU_ARGUMENTS
             ${IWYU_TARGET_ARGS}
             ${IWYU_SOURCE_ARGS})
        string (REPLACE ";" "," IWYU_ARGUMENTS "${IWYU_ARGUMENTS}")

        psq_forward_options (IWYU_SOURCES RUN_TOOL_ON_SOURCE_FORWARD
                             MULTIVAR_ARGS DEPENDS)
        psq_run_tool_on_source (${TARGET}
                                ${SOURCE}
                                "include-what-you-use.${LANGUAGE_STAMP_OPTION}"
                                ${RUN_TOOL_ON_SOURCE_FORWARD}
                                COMMAND
                                ${CMAKE_COMMAND}
                                -DIWYU_SOURCE=${SOURCE}
                                -DIWYU_COMPILER_ARGS="${IWYU_ARGUMENTS}"
                                ${IWYU_WRAPPER_OPTIONS}
                                -P
                                ${IWYU_EXIT_STATUS_WRAPPER}
                                VERBATIM)

    endforeach (SOURCE ${FILES_TO_CHECK})

endfunction ()