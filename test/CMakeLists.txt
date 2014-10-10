# /tests/CMakeLists.txt
# Main entry point for the include-what-you-use-target-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)
project (IncludeWhatYouUseTargetCMakeTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (IWYU_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (IWYU_CMAKE_DIRECTORY
                        ${IWYU_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)
set (CMAKE_UNIT_DIRECTORY
     ${IWYU_CMAKE_DIRECTORY}/cmake-unit)

set (IWYU_INITIAL_CACHE_CONTENTS
     "set (CMAKE_C_COMPILER\n"
     "     ${CMAKE_C_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n"
     "set (CMAKE_CXX_COMPILER\n"
     "     ${CMAKE_CXX_COMPILER}\n"
     "     CACHE STRING \"\" FORCE)\n")

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${IWYU_CMAKE_DIRECTORY}
     ${CMAKE_MODULE_PATH})

foreach (PATH ${CMAKE_MODULE_PATH})
     set (IWYU_INITIAL_CACHE_CONTENTS
          "${IWYU_INITIAL_CACHE_CONTENTS}\n"
          "set (CMAKE_MODULE_PATH ${PATH} \${CMAKE_MODULE_PATH}\n"
          "     CACHE STRING \"\" FORCE)\n")
endforeach ()

# Include IncludeWhatYouUse.cmake too so that we can figure out which tests we can run
include (IncludeWhatYouUse)
_validate_include_what_you_use (CONTINUE)

if (NOT CONTINUE)

    message (FATAL_ERROR "include-what-you-use not found, cannot continue")

endif (NOT CONTINUE)

include (CMakeUnitRunner)

bootstrap_cmake_unit (INITIAL_CACHE_CONTENTS
                      IWYU_INITIAL_CACHE_CONTENTS)

add_cmake_build_test (IWYUTargetSources
                      IWYUTargetSourcesVerify)
add_cmake_build_test (IWYUTargetSourcesNoCheckGeneratedDefault
                      IWYUTargetSourcesNoCheckGeneratedDefaultVerify)
add_cmake_build_test (IWYUTargetSourcesCheckGenerated
                      IWYUTargetSourcesCheckGeneratedVerify)
add_cmake_build_test (IWYUFatalErrorOnFailure
                      IWYUFatalErrorOnFailureVerify ALLOW_BUILD_FAIL)
add_cmake_build_test (IWYUWarnOnlyOnFailure
                      IWYUWarnOnlyOnFailureVerify)
add_cmake_build_test (IWYUPassCFlagsForCFiles
                      IWYUPassCFlagsForCFilesVerify)
add_cmake_build_test (IWYUPassCXXFlagsForCXXFiles
                      IWYUPassCXXFlagsForCXXFilesVerify)
add_cmake_build_test (IWYUPassCFlagsForCHeaders
                      IWYUPassCFlagsForCHeadersVerify)
add_cmake_build_test (IWYUPassCXXFlagsForCHeadersCPPIdentifiers
                      IWYUPassCXXFlagsForCHeadersCPPIdentifiersVerify)
add_cmake_build_test (IWYUPassCXXFlagsForCHeadersForceLanguage
                      IWYUPassCXXFlagsForCHeadersForceLanguageVerify)
add_cmake_build_test (IWYUPassCXXFlagsForCXXHeaders
                      IWYUPassCXXFlagsForCXXHeadersVerify)
add_cmake_build_test (IWYUPassDefines
                      IWYUPassDefinesVerify)
add_cmake_build_test (IWYUPassIncludes
                      IWYUPassIncludesVerify)
add_cmake_build_test (IWYUArgumentsPassedCorrectly
                      IWYUArgumentsPassedCorrectlyVerify)