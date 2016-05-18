# /CMakeLists.txt
#
# Main entry point for IncludeWhatYouUse tests.
#
# See /LICENCE.md for Copyright information

include ("${CMAKE_CURRENT_LIST_DIR}/conanbuildinfo.cmake")
set (CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_LIST_DIR}"
     ${CONAN_CMAKE_MODULE_PATH}  # NOLINT:correctness/quotes
     ${CMAKE_MODULE_PATH})  # NOLINT:correctness/quotes

cmake_minimum_required (VERSION 2.8)

set (_CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

include ("cmake/cmake-module-common/Common")

include (IncludeWhatYouUse)

if (NOT CMAKE_SCRIPT_MODE_FILE)

    iwyu_validate (IWYU_AVAILABLE)

else ()

    set (IWYU_AVAILABLE TRUE)

endif ()

function (_iwyu_fill_with_default VARIABLE DEFAULT)

    string (LENGTH "${${VARIABLE}}" STR_LEN)
    if ("${STR_LEN}" STREQUAL "0")

        set (${VARIABLE} "${DEFAULT}" PARENT_SCOPE)

    endif ()

endfunction ()

function (_iwyu_create_target TARGET)

    set (TARGET_OPTION_ARGS
         FAILURE_MODE
         GENERATE_FILE)
    set (TARGET_SINGLEVAR_ARGS
         SOURCE_EXT
         UTIL_EXT
         GENERATED_EXT)
    set (TARGET_MULTIVAR_ARGS
         CREATE_HEADER_ARGS
         CREATE_UTIL_ARGS
         CREATE_SOURCE_ARGS
         CREATE_GENERATED_ARGS)

    cmake_parse_arguments (TARGET
                           "${TARGET_OPTION_ARGS}"
                           "${TARGET_SINGLEVAR_ARGS}"
                           "${TARGET_MULTIVAR_ARGS}"
                           ${ARGN})

    _iwyu_fill_with_default (TARGET_SOURCE_EXT "cpp")
    _iwyu_fill_with_default (TARGET_UTIL_EXT "cpp")
    _iwyu_fill_with_default (TARGET_GENERATED_EXT "cpp")

    set (SUCCESS_CONTENTS
         "int main()"
         "{"
         "    return library()@SEMICOLON@"
         "}")
    set (FAILURE_CONTENTS
         "int main()"
         "{"
         "    return 0@SEMICOLON@"
         "}")

    psq_add_switch (PREPEND_CONTENTS_VAR
                    TARGET_FAILURE_MODE
                    OFF SUCCESS_CONTENTS
                    ON FAILURE_CONTENTS)


    foreach (SRC_NAME IN ITEMS HEADER UTIL SOURCE GENERATED)
        psq_forward_options (TARGET
                             "CREATE_${SRC_NAME}_FWD"
                             MULTIVAR_ARGS DEFINES
                             SINGLEVAR_ARGS FUNCTIONS_EXPORT_TARGET)
    endforeach ()

    cmake_unit_create_source_file_before_build (NAME Header.h
                                                FUNCTIONS "library"
                                                GENERATING_FILE
                                                "${_CURRENT_LIST_FILE}"
                                                ${CREATE_HEADER_FWD})
    cmake_unit_create_source_file_before_build (NAME
                                                "Util.${TARGET_UTIL_EXT}"
                                                PREPEND_CONTENTS
                                                "int library()"
                                                "{"
                                                "    return 1@SEMICOLON@"
                                                "}"
                                                GENERATING_FILE
                                                "${_CURRENT_LIST_FILE}"
                                                ${CREATE_SOURCE_FWD})
    cmake_unit_create_source_file_before_build (NAME
                                                "Source.${TARGET_SOURCE_EXT}"
                                                INCLUDES "Header.h"
                                                PREPEND_CONTENTS
                                                "${${PREPEND_CONTENTS_VAR}}"
                                                GENERATING_FILE
                                                "${_CURRENT_LIST_FILE}"
                                                ${CREATE_UTIL_FWD})

    set (SOURCES_LIST
         "${SOURCE_DIR}/Source.${TARGET_SOURCE_EXT}"
         "${SOURCE_DIR}/Util.${TARGET_UTIL_EXT}"
         "${SOURCE_DIR}/Header.h")

    if (TARGET_GENERATE_FILE)

        set (GENERATED_CONTENTS
             "int generated()"
             "{"
             "    return library()@SEMICOLON@"
             "}")
        set (GEN_SOURCE_EXT "${TARGET_GENERATED_EXT}")
        cmake_unit_generate_source_file_during_build (GENERATED_FILE_TARGET
                                                      NAME
                                                      "Gen.${GEN_SOURCE_EXT}"
                                                      INCLUDES "Header.h"
                                                      PREPEND_CONTENTS
                                                      "${GENERATED_CONTENTS}"
                                                      GENERATING_FILE
                                                      "${_CURRENT_LIST_FILE}"
                                                      ${CREATE_GENERATED_FWD})

        list (APPEND SOURCES_LIST "Gen.${GEN_SOURCE_EXT}")

    endif ()

    include_directories ("${SOURCE_DIR}")
    add_executable (${TARGET}
                    ${SOURCES_LIST})

endfunction ()


# Create a target and run IWYU on it.
function (iwyu_test_iwyu_arguments_passed_correctly)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}")
        iwyu_target_sources ("${EXECUTABLE}" INTERNAL_INCLUDE_DIRS
                             "${SOURCE_DIR}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (EXPECTED_REGEX "^.*include-what-you-use.*-I${SOURCE_DIR}")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*${EXPECTED_REGEX}.*$")

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it. The target has
# include-what-you-use violations (no usage of Header.h)
function (iwyu_test_iwyu_fatal_error_on_failure)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}" FAILURE_MODE)
        iwyu_target_sources ("${EXECUTABLE}" INTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_get_log_for (INVOKE_BUILD ERROR BUILD_ERROR)
        file (READ ${BUILD_OUTPUT} BUILD_OUTPUT_CONTENTS)
        file (READ ${BUILD_ERROR} BUILD_ERROR_CONTENTS)
        set (ALL_BUILD "${BINARY_DIR}/ALL_BUILD")
        file (WRITE ${ALL_BUILD} ${BUILD_OUTPUT_CONTENTS}
              ${BUILD_ERROR_CONTENTS})
        cmake_unit_assert_that (${ALL_BUILD} file_contents any_line
                                matches_regex
                                "^.*include-what-you-use found problems .*$")

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   INVOKE_BUILD OPTIONS ALLOW_FAIL
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it.
function (iwyu_test_iwyu_pass_c_flags_for_c_files)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (CMAKE_C_FLAGS "-DUSING_C_FLAGS")  # NOLINT:unused/var_in_func
        cmake_unit_create_source_file_before_build (NAME "Source.c"
                                                    FUNCTIONS "main"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.c")
        iwyu_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_C_FLAGS.*Source.c.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it.
function (iwyu_test_iwyu_pass_c_flags_for_c_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        set (CMAKE_C_FLAGS "-DUSING_C_FLAGS")  # NOLINT:unused/var_in_func
        _iwyu_create_target ("${EXECUTABLE}"
                             UTIL_EXT "c"
                             SOURCE_EXT "c")
        iwyu_target_sources ("${EXECUTABLE}"
                             INTERNAL_INCLUDE_DIRS "${SOURCE_DIR}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_C_FLAGS.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it, our
# header should get marked as a C++ header because it has
# special C++ identifiers in it.
function (iwyu_test_iwyu_pass_cxx_flags_for_c_headers_cpp_identifiers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (CMAKE_CXX_FLAGS "-DUSING_CXX_FLAGS")  # NOLINT:unused/var_in_func
        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}"
                             CREATE_HEADER_ARGS
                             DEFINES HEADER_IS_CPP)
        iwyu_target_sources ("${EXECUTABLE}" INTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}"
                             CPP_IDENTIFIERS
                             HEADER_IS_CPP)

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it, our
# header should get marked as a C++ header because it has
# special C++ identifiers in it.
function (iwyu_test_iwyu_pass_cxx_flags_for_c_headers_force_language)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        set (CMAKE_CXX_FLAGS "-DUSING_CXX_FLAGS")  # NOLINT:unused/var_in_func
        _iwyu_create_target ("${EXECUTABLE}")
        iwyu_target_sources ("${EXECUTABLE}" INTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}"
                             FORCE_LANGUAGE
                             CXX)

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it, ensuring that
# CMAKE_CXX_FLAGS are passed for C++ sources.
function (iwyu_test_iwyu_pass_cxx_flags_for_cxx_files)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}")
        set (CMAKE_CXX_FLAGS "-DUSING_CXX_FLAGS")  # NOLINT:unused/var_in_func
        iwyu_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*-x.*c.*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it.
function (iwyu_test_iwyu_pass_cxx_flags_for_cxx_headers)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}")
        set (CMAKE_CXX_FLAGS "-DUSING_CXX_FLAGS")  # NOLINT:unused/var_in_func
        iwyu_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (IWYU_COMMAND
             "^.*include-what-you-use.*-DUSING_CXX_FLAGS.*-x.*c.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${IWYU_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it. Pass some
# defines.
function (iwyu_test_iwyu_pass_defines)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        cmake_unit_create_source_file_before_build (NAME "Source.cpp"
                                                    PREPEND_CONTENTS
                                                    "int main()"
                                                    "{"
                                                    "    return DEF@SEMICOLON@"
                                                    "}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")
        set (EXECUTABLE executable)
        add_definitions (-DDEF=1)
        add_executable ("${EXECUTABLE}"
                        "${SOURCE_DIR}/Source.cpp")
        iwyu_target_sources ("${EXECUTABLE}"
                             DEFINES DEF=1)

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (SOURCE_COMMAND
             "^.*include-what-you-use.*-DDEF=1.*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents any_line matches_regex
                                ${SOURCE_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it. Pass some
# includes.
function (iwyu_test_iwyu_pass_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        include_directories ("${BINARY_DIR}/internal")
        include_directories ("${BINARY_DIR}/external")
        _iwyu_create_target ("${EXECUTABLE}")

        iwyu_target_sources ("${EXECUTABLE}"
                             INTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}"
                             "${BINARY_DIR}/internal"
                             EXTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}/external")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        set (HEADERS_REGEX ".*-isystem.*external.*-I.*internal.*")
        set (SOURCE_COMMAND
             "^.*include-what-you-use${HEADERS_REGEX}Source.cpp.*$")
        set (HEADER_COMMAND
             "^.*include-what-you-use${HEADERS_REGEX}Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                ${SOURCE_COMMAND})
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                ${HEADER_COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it.
function (iwyu_test_iwyu_target_sources)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}")
        iwyu_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*include-what-you-use.*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*include-what-you-use.*Header.h.*$")

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target with a generated file and runs
# include-what-you-use on it, with CHECK_GENERATED
function (iwyu_test_iwyu_target_sources_check_generated)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}" GENERATE_FILE)
        iwyu_target_sources ("${EXECUTABLE}" CHECK_GENERATED)

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*include-what-you-use .*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*include-what-you-use .*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*include-what-you-use .*Gen.cpp*$")

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target with a generated file and runs
# include-what-you-use on it.
function (iwyu_test_iwyu_target_sources_no_check_generated_default)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}" GENERATE_FILE)
        iwyu_target_sources ("${EXECUTABLE}")

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_assert_that (${BUILD_OUTPUT} file_contents any_line
                                matches_regex
                                "^.*include-what-you-use.*Source.cpp.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                file_contents
                                any_line
                                matches_regex
                                "^.*include-what-you-use.*Header.h.*$")
        cmake_unit_assert_that (${BUILD_OUTPUT}
                                not
                                file_contents
                                any_line
                                matches_regex
                                "^.*in.*w.*you-use .*Gen.cpp*$")

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Sets up a target and runs include-what-you-use on it. The target has
# include-what-you-use violations (no usage of Header.h), but we are
# only warning for this target.
function (iwyu_test_iwyu_warn_only_on_failure)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (iwyu_configure)

        set (EXECUTABLE executable)
        _iwyu_create_target ("${EXECUTABLE}" FAILURE_MODE)
        iwyu_target_sources ("${EXECUTABLE}" INTERNAL_INCLUDE_DIRS
                             "${BINARY_DIR}"
                             WARN_ONLY)

    endfunction ()

    function (iwyu_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)
        cmake_unit_get_log_for (INVOKE_BUILD ERROR BUILD_ERROR)
        file (READ ${BUILD_OUTPUT} BUILD_OUTPUT_CONTENTS)
        file (READ ${BUILD_ERROR} BUILD_ERROR_CONTENTS)
        set (ALL_BUILD "${BINARY_DIR}/ALL_BUILD")
        file (WRITE ${ALL_BUILD} ${BUILD_OUTPUT_CONTENTS}
              ${BUILD_ERROR_CONTENTS})
        set (COMMAND "^.*include-what-you-use found problems with.*$")
        cmake_unit_assert_that (${ALL_BUILD} not file_contents any_line
                                matches_regex
                                ${COMMAND})

    endfunction ()

    if (IWYU_AVAILABLE)

        cmake_unit_configure_test (INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX
                                   CONFIGURE COMMAND iwyu_configure
                                   VERIFY COMMAND iwyu_verify)

    endif ()

endfunction ()

# Runs if include-what-you-use is not available
function (iwyu_test_not_available)

    if (NOT IWYU_AVAILABLE OR NOT CMAKE_SCRIPT_MODE_FILE)

        cmake_unit_configure_test ()

    endif ()

endfunction ()

set (_CURRENT_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")
set (_UTIL_DIR "${_CURRENT_LIST_DIR}/util")
set (CMAKE_FILES
     "${_CURRENT_LIST_DIR}/IncludeWhatYouUse.cmake"
     "${_CURRENT_LIST_DIR}/FindIWYU.cmake"
     "${_UTIL_DIR}/IWYUExitStatusWrapper.cmake"
     "${_CURRENT_LIST_DIR}/CMakeLists.txt")
set (MARKDOWN_FILES
     "${_CURRENT_LIST_DIR}/LICENSE.md"
     "${_CURRENT_LIST_DIR}/README.md")

cmake_module_add_common_targets (NAMESPACE "iwyu"
                                 CMAKE_FILES ${CMAKE_FILES}
                                 DOCUMENTATION_FILES ${MARKDOWN_FILES})
