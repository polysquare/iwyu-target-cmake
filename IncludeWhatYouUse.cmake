# /IncludeWhatYouUse.cmake
# CMake macro to run include-what-you-use on each target source file.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)
include (${CMAKE_CURRENT_LIST_DIR}/determine-header-language/DetermineHeaderLanguage.cmake)

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

# TODO: Deduplicate
function (_strip_add_custom_target_sources RETURN_SOURCES TARGET)

    get_target_property (_sources ${TARGET} SOURCES)
    list (GET _sources 0 _first_source)
    string (FIND "${_first_source}" "/" LAST_SLASH REVERSE)
    math (EXPR LAST_SLASH "${LAST_SLASH} + 1")
    string (SUBSTRING "${_first_source}" ${LAST_SLASH} -1 END_OF_SOURCE)

    if (END_OF_SOURCE STREQUAL "${TARGET}")

        list (REMOVE_AT _sources 0)

    endif (END_OF_SOURCE STREQUAL "${TARGET}")

    set (${RETURN_SOURCES} ${_sources} PARENT_SCOPE)

endfunction ()

function (_filter_out_generated_sources RESULT_VARIABLE)

    set (FILTER_OUT_MUTLIVAR_OPTIONS SOURCES)

    cmake_parse_arguments (FILTER_OUT
                           ""
                           ""
                           "${FILTER_OUT_MUTLIVAR_OPTIONS}"
                           ${ARGN})

    set (${RESULT_VARIABLE} PARENT_SCOPE)
    set (FILTERED_SOURCES)

    foreach (SOURCE ${FILTER_OUT_SOURCES})

        get_property (SOURCE_IS_GENERATED
                      SOURCE ${SOURCE}
                      PROPERTY GENERATED)

        if (NOT SOURCE_IS_GENERATED)

            list (APPEND FILTERED_SOURCES ${SOURCE})

        endif (NOT SOURCE_IS_GENERATED)

    endforeach ()

    set (${RESULT_VARIABLE} ${FILTERED_SOURCES} PARENT_SCOPE)

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

    _strip_add_custom_target_sources (FILES_TO_CHECK ${TARGET})

    if (NOT IWYU_SOURCES_CHECK_GENERATED)
        _filter_out_generated_sources (FILES_TO_CHECK
                                       SOURCES ${FILES_TO_CHECK})
    endif (NOT IWYU_SOURCES_CHECK_GENERATED)

    if (IWYU_SOURCES_WARN_ONLY)
        set (WARN_ONLY_OPTION TRUE)
    else (IWYU_SOURCES_WARN_ONLY)
        set (WARN_ONLY_OPTION FALSE)
    endif (IWYU_SOURCES_WARN_ONLY)

    get_property (TARGET_TYPE
                  TARGET ${TARGET}
                  PROPERTY TYPE)

    if (TARGET_TYPE STREQUAL "UTILITY")

        set (WHEN PRE_BUILD)

    else (TARGET_TYPE STREQUAL "UTILITY")

        set (WHEN PRE_LINK)

    endif (TARGET_TYPE STREQUAL "UTILITY")

    set (ALL_INCLUDE_DIRS
         ${IWYU_SOURCES_EXTERNAL_INCLUDE_DIRS}
         ${IWYU_SOURCES_INTERNAL_INCLUDE_DIRS})

    foreach (INTERNAL_INCLUDE ${IWYU_SOURCES_INTERNAL_INCLUDE_DIRS})

        list (APPEND IWYU_TARGET_ARGS
              "-I${INTERNAL_INCLUDE} ")

    endforeach ()

    foreach (EXTERNAL_INCLUDE ${IWYU_SOURCES_EXTERNAL_INCLUDE_DIRS})

        list (APPEND IWYU_TARGET_ARGS
              "-isystem${EXTERNAL_INCLUDE} ")

    endforeach ()

    foreach (DEFINE ${IWYU_SOURCES_DEFINES})

        list (APPEND IWYU_TARGET_ARGS
              "-D${DEFINE}")

    endforeach ()

    foreach (SOURCE ${FILES_TO_CHECK})

        polysquare_scan_source_for_headers (SOURCE ${SOURCE}
                                            INCLUDES
                                            ${ALL_INCLUDE_DIRS}
                                            CPP_IDENTIFIERS
                                            ${IWYU_SOURCES_CPP_IDENTIFIERS})

        set (LANGUAGE ${IWYU_SOURCES_FORCE_LANGUAGE})
        if (NOT LANGUAGE)

            polysquare_determine_language_for_source (${SOURCE}
                                                      LANGUAGE
                                                      SOURCE_WAS_HEADER
                                                      INCLUDES
                                                      ${ALL_INCLUDE_DIRS})

        endif (NOT LANGUAGE)

        list (FIND LANGUAGE "CXX" CXX_INDEX)

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
                            -DIWYU_EXECUTABLE=${IWYU_EXECUTABLE}
                            -DIWYU_SOURCE=${SOURCE}
                            -DIWYU_COMPILER_ARGS="${IWYU_ARGUMENTS}"
                            -DVERBOSE=${CMAKE_VERBOSE_MAKEFILE}
                            -DWARN_ONLY=${WARN_ONLY_OPTION}
                            -P
                            ${IWYU_EXIT_STATUS_WRAPPER}
                            VERBATIM)

    endforeach (SOURCE ${FILES_TO_CHECK})

endfunction ()