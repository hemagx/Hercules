# This file is part of Hercules.
# http://herc.ws - http://github.com/HerculesWS/Hercules
#
# Copyright (C) 2026 Hercules Dev Team
#
# Hercules is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.19)

set(PROJECT_NAME hercules LANGUAGES C)
project(${PROJECT_NAME})

# CMake settings
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS CACHE BOOL ON)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules")

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "In-source builds are not allowed. Please create a separate build directory.")
endif()

if(NOT CMAKE_BUILD_TYPE)
  message(FATAL_ERROR "Build type not specified. Specify it with -DCMAKE_BUILD_TYPE=type (type can be one of Release, RelWithDebInfo, Debug)")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(RUNNING_ON_LINUX ON)
else()
  set(RUNNING_ON_LINUX OFF)
endif()

include(CMakeDependentOption)
# Configuration options
cmake_dependent_option(ENABLE_LIBBACKTRACE "Compiles with libbacktrace. (off by default - experimental)" ON ${RUNNING_ON_LINUX} OFF)
set(WITH_HTTP_PARSER "http-parser" CACHE STRING "select http parser. Allowed values: http-parser, llhttp")
option(ENABLE_GDB "Compiles with gdb specific optimzations for better debugging. (off by default)" OFF)

if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  if(${ENABLE_GDB})
    message(FATAL_ERROR "ENABLE_GDB can be only used in debug builds")
  endif()
endif()

include(LanguageFeatureHelper)
# Check for headers
test_header_def(sys/stat "" OFF)
test_header_def(sys/types "" OFF)
test_header_def(xlocale "" OFF) # Libconfig

# Check for functions
test_function_def(uselocale "" OFF) # Libconfig
test_function_def(newlocale "" OFF) # Libconfig
test_function_def(freelocale "" OFF) # Libconfig
test_function_def(setrlimit "" OFF)

# Check for mandatory compile flags (currently it's just a list of all default flag using just ./configure)
include(CompilerFlagHelpers)
testadd_compiler_flag(pipe ON)
testadd_compiler_flag(ffast-math ON)
testadd_compiler_flag(fno-finite-math-only ON)
testadd_compiler_flag(fsigned-char ON)
testadd_compiler_flag(fcf-protection=none ON)
testadd_compiler_flag(fno-strict-aliasing ON)
testadd_compiler_flag(fno-omit-frame-pointer ON)
testadd_compiler_flag(fno-var-tracking ON)

# Warnings we explictily require or disable
testadd_warning_compiler_flag(all OFF)
testadd_warning_compiler_flag(extra OFF)
testadd_warning_compiler_flag(no-sign-compare OFF)
testadd_warning_compiler_flag(no-unused-parameter OFF)
testadd_warning_compiler_flag(no-clobbered OFF)
testadd_warning_compiler_flag(empty-body OFF)
testadd_warning_compiler_flag(int-conversion OFF)
testadd_warning_compiler_flag(init-self OFF)
testadd_warning_compiler_flag(pointer-arith OFF)
testadd_warning_compiler_flag(switch-bool OFF)
testadd_warning_compiler_flag(enum-conversion OFF)
testadd_warning_compiler_flag(format-security OFF)
testadd_warning_compiler_flag(format OFF)
testadd_warning_compiler_flag(format-signedness OFF)
testadd_warning_compiler_flag(format-y2k OFF)
testadd_warning_compiler_flag(format-overflow=2 OFF)
testadd_warning_compiler_flag(format-diag OFF)
testadd_warning_compiler_flag(suggest-attribute=noreturn OFF)
testadd_warning_compiler_flag(suggest-attribute=format OFF)
testadd_warning_compiler_flag(undef OFF)
testadd_warning_compiler_flag(nested-externs OFF)
testadd_warning_compiler_flag(old-style-definition OFF)
testadd_warning_compiler_flag(overlength-strings OFF)
testadd_warning_compiler_flag(redundant-decls OFF)
testadd_warning_compiler_flag(misleading-indentation OFF)
testadd_warning_compiler_flag(null-dereference OFF)
testadd_warning_compiler_flag(vla OFF)
testadd_warning_compiler_flag(vla-parameter OFF)
testadd_warning_compiler_flag(switch-enum OFF)
testadd_warning_compiler_flag(mismatched-dealloc OFF)
testadd_warning_compiler_flag(sizeof-array-div OFF)
testadd_warning_compiler_flag(stringop-overflow=4 OFF)
testadd_warning_compiler_flag(stringop-overread OFF)
testadd_warning_compiler_flag(string-compare OFF)
testadd_warning_compiler_flag(zero-length-bounds OFF)
testadd_warning_compiler_flag(absolute-value OFF)
testadd_warning_compiler_flag(shift-overflow=2 OFF)
testadd_warning_compiler_flag(enum-int-mismatch OFF)
testadd_warning_compiler_flag(no-switch OFF)
testadd_warning_compiler_flag(no-missing-field-initializers OFF)
testadd_warning_compiler_flag(no-discarded-qualifiers OFF)
testadd_warning_compiler_flag(no-unused-but-set-variable OFF)
testadd_warning_compiler_flag(shadow OFF)
testadd_warning_compiler_flag(no-deprecated-non-prototype OFF)

# Linker flags

# Check if the linker supports/accepts -rdynamic
# Generally only needed by the ELF linker, in order to produce backtraces.
# On non-ELF platforms, some compilers (i.e. gcc < 5 and clang on OSX) are able to ignore it, others will error out.
testadd_linker_flag(rdynamic OFF)

# Checks for language features and behavior
include(CheckCSourceCompiles)
include(CheckSourceRuns)

# Check if thread local storage is supported
# TODO: remove the check in source as we mandate C11 now
add_compile_definitions(HAS_TLS)

# CLOCK_MONOTONIC clock for clock_gettime
# Normally defines _POSIX_TIMERS > 0 and _POSIX_MONOTONIC_CLOCK (for posix
# compliant systems) and __FreeBSD_cc_version >= 500005 (for FreeBSD
# >= 5.1.0, which does not have the posix defines (ref. r11983)) would be
# checked but some systems define them even when they do not support it
# (ref. bugreport:1003).
check_source_runs(C [[
	#include <sys/time.h>
	#include <time.h>
	#include <unistd.h>

	int main(int argc, char** argv)
	{
		struct timespec tval;
		return clock_gettime(CLOCK_MONOTONIC, &tval);
	}
]] HAVE_MONOTONIC_CLOCK)
if(${HAVE_MONOTONIC_CLOCK})
  message(STATUS "CLOCK_MONOTONIC is supported and working")
  add_compile_definitions(HAVE_MONOTONIC_CLOCK)
else()
  message(STATUS "CLOCK_MONOTONIC is either unsupported or not working as expected")
endif()

# Check for libraries
if(ENABLE_LIBBACKTRACE)
  find_package(Backtrace REQUIRED)
  if(Backtrace_FOUND)
    test_header_def(execinfo HAVE_EXECINFO OFF)
    testadd_compiler_flag(funwind-tables ON)
    add_compile_definitions(HAVE_LIBBACKTRACE)
    # There's more checks in configure.ac but they seem to be meant for compiling libbacktrace but we're not doing that
  endif()
endif()

if("${WITH_HTTP_PARSER}" STREQUAL "http-parser")
  add_compile_definitions(USE_HTTP_PARSER)
  message(STATUS "Use http-parser as http library")
elseif("${WITH_HTTP_PARSER}" STREQUAL "llhttp")
  message(STATUS "Use llhttp as http library")
else()
  message(FATAL_ERROR "unknown http_parser selected '${WITH_HTTP_PARSER}'. Allowed values: http-parser, llhttp. ... stopping")
endif()

# Check for compile settings

# Debug setting
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  add_compile_definitions(DEBUG)
  if(${ENABLE_GDB})
    testadd_compiler_flag(ggdb ON)
  else()
    testadd_compiler_flag(g ON)
  endif()
endif()

# Run sysinfogen.sh whenever src/common/sysinfo.inc is required in a build
add_custom_command(
  OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/common/sysinfo.inc"
  COMMAND
    ./sysinfogen.sh
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common/sysinfo.inc
    ${CMAKE_C_FLAGS}
    ${CMAKE_CPP_FLAGS}
  DEPENDS sysinfogen.sh
)

get_directory_property(MYDEFS LINK_OPTIONS)
message("LDFLAGS=${MYDEFS}")
get_directory_property(MYDEFS COMPILE_OPTIONS)
message("CFLAGS=${MYDEFS}")
get_directory_property(MYDEFS COMPILE_DEFINITIONS)
message("DEFS=${MYDEFS}")

include_directories(${PROJECT_SOURCE_DIR}/src)
include_directories(${PROJECT_SOURCE_DIR}/3rdparty)
add_subdirectory(3rdparty)
