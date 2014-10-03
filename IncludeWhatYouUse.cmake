# /IncludeWhatYouUse.cmake
# CMake macro to run include-what-you-use on each target source file.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)
include (${CMAKE_CURRENT_LIST_DIR}/tooling-cmake-util/PolysquareToolingUtil.cmake)

set (IWYU_EXIT_STATUS_WRAPPER
     ${CMAKE_CURRENT_LIST_DIR}/util/IWYUExitStatusWrapper.cmake)

function (_validate_include_what_you_use CONTINUE)

  find_program (IWYU_EXECUTABLE include-what-you-use)

  if (NOT IWYU_EXECUTABLE)

    set (${CONTINUE} FALSE PARENT_SCOPE)
    return ()

  endif (NOT IWYU_EXECUTABLE)

  set (${CONTINUE} TRUE PARENT_SCOPE)
  set (IWYU_EXECUTABLE ${IWYU_EXECUTABLE} PARENT_SCOPE)

endfunction ()

function (iwyu_target_sources TARGET)

    set (IWYU_SOURCES_OPTION_ARGS CHECK_GENERATED WARN_ONLY)
    set (IWYU_SOURCES_SINGLEVAR_ARGS FORCE_LANGUAGE)
    set (IWYU_SOURCES_MULTIVAR_ARGS
         EXTERNAL_INCLUDE_DIRS
         INTERNAL_INCLUDE_DIRS
         DEFINES
         CPP_IDENTIFIERS)

    cmake_parse_arguments (IWYU_SOURCES
                           "${IWYU_SOURCES_OPTION_ARGS}"
                           "${IWYU_SOURCES_SINGLEVAR_ARGS}"
                           "${IWYU_SOURCES_MULTIVAR_ARGS}"
                           ${ARGN})

    psq_strip_add_custom_target_sources (FILES_TO_CHECK ${TARGET})
    psq_handle_check_generated_option (IWYU_SOURCES FILES_TO_CHECK
                                       SOURCES ${FILES_TO_CHECK})

    set (IWYU_WRAPPER_OPTIONS
         -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
         -DIWYU_EXECUTABLE=${IWYU_EXECUTABLE})

    psq_add_switch (IWYU_WRAPPER_OPTIONS IWYU_SOURCES_WARN_ONLY
                    ON -DWARN_ONLY=TRUE
                    OFF -DWARN_ONLY=FALSE)

    psq_get_target_command_attach_point (${TARGET} WHEN)

    set (ALL_INCLUDE_DIRS
         ${IWYU_SOURCES_EXTERNAL_INCLUDE_DIRS}
         ${IWYU_SOURCES_INTERNAL_INCLUDE_DIRS})

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
                                   INCLUDES ${ALL_INCLUDE_DIRS}
                                   SOURCES ${FILES_TO_CHECK}
                                   ${DETERMINE_LANG_FORWARD_OPTIONS})

    foreach (SOURCE ${FILES_TO_CHECK})

        list (FIND CXX_SOURCES ${SOURCE} CXX_INDEX)

        if (NOT CXX_INDEX EQUAL -1)

            set (IWYU_SOURCE_ARGS
                 "${CMAKE_CXX_FLAGS} -x c++")

        else (NOT CXX_INDEX EQUAL -1)

            set (IWYU_SOURCE_ARGS "${CMAKE_C_FLAGS}")

        endif (NOT CXX_INDEX EQUAL -1)

        set (IWYU_ARGUMENTS
             ${IWYU_TARGET_ARGS}
             ${IWYU_SOURCE_ARGS})
        string (REPLACE ";" " " IWYU_ARGUMENTS "${IWYU_ARGUMENTS}")

        add_custom_command (TARGET ${TARGET}
                            ${WHEN}
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