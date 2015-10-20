# Include-What-You-Use CMake Targets #

CMake macro to add per-source level checks on individual targets for
include-what-you-use violations

## Status ##

| Travis CI (Ubuntu) | AppVeyor (Windows) | Coverage | Biicode | Licence |
|--------------------|--------------------|----------|---------|---------|
|[![Travis](https://img.shields.io/travis/polysquare/iwyu-target-cmake.svg)](http://travis-ci.org/polysquare/iwyu-target-cmake)|[![AppVeyor](https://img.shields.io/appveyor/ci/smspillaz/include-what-you-use-target-cmake.svg)](https://ci.appveyor.com/project/smspillaz/include-what-you-use-target-cmake)|[![Coveralls](https://img.shields.io/coveralls/polysquare/iwyu-target-cmake.svg)](http://coveralls.io/polysquare/iwyu-target-cmake)|[![Biicode](https://webapi.biicode.com/v1/badges/smspillaz/smspillaz/iwyu-target-cmake/master)](https://www.biicode.com/smspillaz/iwyu-target-cmake)|[![License](https://img.shields.io/github/license/polysquare/iwyu-target-cmake.svg)](http://github.com/polysquare/iwyu-target-cmake)|

## Description ##

`iwyu-target-cmake` can be used to scan individual source files for
include-what-you-use violations. The check is added to target and automatically
run over all of it its source files.

## Usage ##

`include-what-you-use-target-cmake` works by scanning source files for `#include`
statements and then checks the passed include directories for files matching the
name of files specified in the `#include` statements.

### Checking a target ###

#### `iwyu_target_sources` ####

Examine the sources attached to TARGET for include-what-you-use
violations. The compiler flags as indicated in the arguments
are passed to include-what-you-use to determine whether or not
included files are not necessary.

* `TARGET`: Target to check
* [Optional] `CHECK_GENERATED`: Also check generated files, off by default.
* [Optional] `WARN_ONLY`: Don't abort the build on violations, just warn.
* [Optional] `FORCE_LANGUAGE`: Treat source files for this target as either
                               C or CXX.
* [Optional] `EXTERNAL_INCLUDE_DIRS`: System-level include directories
                                      (will not be transitively examined).
* [Optional] `INTERNAL_INCLUDE_DIRS`: Include directories in this project
                                      (will be transitively examined).
* [Optional] `DEFINES`: Definitions to set when preprocessing.
* [Optional] `CPP_IDENTIFIERS`: Identifiers which indicate that a header
                                file scanned is always C++.
* [Optional] `DEPENDS`: Targets to run or source files to generate before
                        checking the sources for violations.