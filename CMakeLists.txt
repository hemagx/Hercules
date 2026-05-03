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

cmake_minimum_required(VERSION 3.25)

# CMake Policies
cmake_policy(SET CMP0140 NEW)

set(PROJECT_NAME hercules LANGUAGES C CXX)
project(${PROJECT_NAME})

# CMake settings
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Enable compile commands" FORCE)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(CMAKE_INSTALL_LIBDIR "lib")
else()
  set(CMAKE_INSTALL_LIBDIR ".")
endif()
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules")

# RPATH settings
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(CMAKE_INSTALL_RPATH "\$ORIGIN/${CMAKE_INSTALL_LIBDIR}/")
  else()
    sset(CMAKE_INSTALL_RPATH "@rpath/${CMAKE_INSTALL_LIBDIR}/")
  endif()
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH OFF)
endif()

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "In-source builds are not allowed. Please create a separate build directory.")
endif()

if(NOT CMAKE_INSTALL_PREFIX)
  message(FATAL_ERROR "Installation path is missing. Please pass it to cmake.")
endif()

if(NOT CMAKE_BUILD_TYPE)
  message(FATAL_ERROR "Build type not specified. Specify it with -DCMAKE_BUILD_TYPE=type (type can be one of Release, RelWithDebInfo, Debug)")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "32-bit builds are not supported. Please use a 64-bit generator/toolchain.")
endif()

# Global variables
set(SOFLAGS "")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(RUNNING_ON_LINUX ON)
else()
  set(RUNNING_ON_LINUX OFF)
endif()

# Auto generated files directory in build dir
set(AUTOGEN_DIR "${CMAKE_BINARY_DIR}/autogen")
file(MAKE_DIRECTORY "${AUTOGEN_DIR}")
include_directories(${AUTOGEN_DIR})

include(CMakeDependentOption)
# Configuration options
set(ENABLE_MEMORY_MANAGER "builtin" CACHE STRING "memory managers: no, builtin, memwatch, dmalloc, gcollect, bcheck (defaults to builtin)")
set(ENABLE_PACKETVER "" CACHE STRING "Sets the PACKETVER define. (see src/common/mmo.h)")
option(CASHSHOP_PREVIEW_PATCH "Enable Nemo patch ExtendCashShopPreview." OFF)
option(OLD_CASHSHOP_PREVIEW_PATCH "Enable Nemo patch ExtendOldCashShopPreview." OFF)
option(ENABLE_PACKETVER_RE "Sets or unsets the PACKETVER_RE define - see src/common/mmo.h (currently disabled by default)" OFF)
option(ENABLE_PACKETVER_ZERO "Sets or unsets the PACKETVER_ZERO define - see src/common/mmo.h (currently disabled by default)" OFF)
option(ENABLE_PACKETVER_AD "Sets or unsets the PACKETVER_AD define - see src/common/mmo.h (currently disabled by default)" OFF)
option(ENABLE_PACKETVER_SAK "Sets or unsets the PACKETVER_SAK define - see src/common/mmo.h (currently disabled by default)" OFF)
option(ENABLE_EPOLL "use epoll(4) on Linux" OFF)
set(OBFUSCATIONKEY1 "" CACHE STRING "Sets the first obfuscation key (ignored unless the other two are also specified)")
set(OBFUSCATIONKEY2 "" CACHE STRING "Sets the second obfuscation key (ignored unless the other two are also specified)")
set(OBFUSCATIONKEY3 "" CACHE STRING "Sets the third obfuscation key (ignored unless the other two are also specified)")
option(ENABLE_GDB "Compiles with gdb specific optimzations for better debugging. (off by default)" OFF)
cmake_dependent_option(ENABLE_LIBBACKTRACE "Compiles with libbacktrace. (off by default - experimental)" ON ${RUNNING_ON_LINUX} OFF)
option(ENABLE_BUILDBOT "(available options: ON, OFF)" OFF)
option(ENABLE_RDTSC "Uses rdtsc as timing source (disabled by default)
			Enable it when you've timing issues.

			(For example:  in conjunction with XEN or Other Virtualization mechanisms)

			Note:
				Please ensure that you've disabled dynamic CPU-Frequencys, such as power saving options.
				(On most modern Dedicated Servers cpufreq is preconfigured, see your distribution's
				 manual how to disable it).
				Furthermore, If your CPU has built-in CPU-Frequency scaling features (such as Intel's
				 SpeedStep(R)), do not enable this option. Recent CPUs (Intel Core or newer) guarantee
				 a fixed increment rate for their TSC, so it should be safe to use, but please doublecheck
				 the documentation of both your CPU and OS before enabling this option." OFF)
set(ENABLE_PROFILER "no" CACHE STRING "Profilers: no, gprof (disabled by default)")
option(ENABLE_RENEWAL "Enable renewal" ON)
option(ENABLE_LTO "Enables or Disables Linktime Code Optimization (LTO is disabled by default)" OFF)
option(ENABLE_STATIC_LINKING "Enables or Disables Statick Linking (STATIC is disabled by default)" OFF)
option(ENABLE_SANITIZE "Enables sanitizer. (disabled by default)" OFF)
option(ENABLE_WERROR "Enables -Werror in the compiler flags. (disabled by default)" OFF)
option(DISABLE_RENEWAL "Disable Ragnarok Renewal support (override settings in src/config/renewal.h)" OFF)
set(MAX_CONNECTIONS "" CACHE STRING "optionally set the maximum connections the core can handle (Without epoll enabled, default: 1024. With epol enabled: 3072)")
set(WITH_HTTP_PARSER "http-parser" CACHE STRING "select http parser. Allowed values: http-parser, llhttp")

if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
  message(FATAL_ERROR "bigendian is not supported... stopping")
elseif(NOT CMAKE_C_BYTE_ORDER STREQUAL "LITTLE_ENDIAN")
  set(WORDS_BIGENDIAN FALSE)
  message(WARNING "unable to determine endianess, only little endian is supported")
endif()

# [START] conan settings
# MAKE SURE THIS BLOCK EXISTS BEFORE THE FIRST find_package() CALL OR ELSE IT WON'T WORK
set(HERCULES_CONAN_NAME "hercules")

list(APPEND CONAN_INSTALL_ARGS "--deployer=runtime_deploy" "--deployer-folder=runtime-lib")
install(
  DIRECTORY "${CMAKE_BINARY_DIR}/runtime-lib/"
  TYPE LIB
)

if(ENABLE_LIBBACKTRACE)
  list(APPEND CONAN_INSTALL_ARGS "-o" "${HERCULES_CONAN_NAME}/*:with_libbacktrace=True")
endif()

# [END] conan settings

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

# Check for mandatory compile flags
include(CompilerFlagHelpers)
testadd_compiler_flag(pipe ON)
testadd_compiler_flag(ffast-math ON)
testadd_compiler_flag(fsigned-char OFF)
testadd_compiler_flag(fcf-protection=none OFF)
testadd_compiler_flag(fno-strict-aliasing ON)
testadd_compiler_flag(fno-omit-frame-pointer ON)
testadd_compiler_flag(fno-var-tracking OFF)

# Warnings we explictily require or disable
testadd_warning_compiler_flag(all ON)
testadd_warning_compiler_flag(extra ON)
testadd_warning_compiler_flag(no-sign-compare ON)
testadd_warning_compiler_flag(no-unused-parameter OFF)
testadd_warning_compiler_flag(no-clobbered OFF)
testadd_warning_compiler_flag(empty-body OFF)
testadd_warning_compiler_flag(newline-eof OFF)
testadd_warning_compiler_flag(int-conversion OFF)
testadd_warning_compiler_flag(init-self OFF)
testadd_warning_compiler_flag(pointer-arith OFF)
testadd_warning_compiler_flag(switch-bool OFF)
testadd_warning_compiler_flag(enum-conversion OFF)
testadd_warning_compiler_flag(shorten-64-to-32 OFF)
testadd_warning_compiler_flag(constant-conversion OFF)
testadd_warning_compiler_flag(bool-conversion OFF)
testadd_warning_compiler_flag(format-security OFF)
testadd_warning_compiler_flag(format OFF)
testadd_warning_compiler_flag(format-signedness OFF)
testadd_warning_compiler_flag(format-y2k OFF)
testadd_warning_compiler_flag(format-overflow=2 OFF)
testadd_warning_compiler_flag(format-diag OFF)
# testadd_warning_compiler_flag(format-truncation=2 OFF)
testadd_warning_compiler_flag(missing-include-dirs OFF)
testadd_warning_compiler_flag(suggest-attribute=noreturn OFF)
testadd_warning_compiler_flag(suggest-attribute=format OFF)
# testadd_warning_compiler_flag(suggest-attribute=malloc OFF)
testadd_warning_compiler_flag(undef OFF)
#testadd_warning_compiler_flag(cast-align OFF)
#testadd_warning_compiler_flag(logical-op OFF) # some useless warnings
testadd_warning_compiler_flag(nested-externs OFF)
testadd_warning_compiler_flag(old-style-definition OFF)
testadd_warning_compiler_flag(overlength-strings OFF)
testadd_warning_compiler_flag(redundant-decls OFF)
# testadd_warning_compiler_flag(cast-qual OFF)
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
#testadd_warning_compiler_flag(unreachable-code OFF)
#testadd_warning_compiler_flag(unused-const-variable=2 OFF)
#testadd_warning_compiler_flag(write-strings OFF)
#testadd_warning_compiler_flag(no-format-nonliteral OFF)
testadd_warning_compiler_flag(no-switch OFF)
testadd_warning_compiler_flag(no-missing-field-initializers OFF)
# testadd_warning_compiler_flag(no-suggest-attribute=format OFF)
testadd_warning_compiler_flag(no-incompatible-pointer-types-discards-qualifiers OFF)
testadd_warning_compiler_flag(no-discarded-qualifiers OFF)
testadd_warning_compiler_flag(no-deprecated-non-prototype OFF)
testadd_warning_compiler_flag(no-unused-but-set-variable OFF)
testadd_warning_compiler_flag(no-enum-enum-conversion OFF)

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  testadd_warning_compiler_flag(no-deprecated-declarations OFF)
endif()

# Certain versions of gcc make -Wshadow completely useless by making it flood
# you with unnecessary warnings <https://lkml.org/lkml/2006/11/28/239>
# Let's check if we can really use it
set(OLD_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -Werror -Wshadow")
check_c_source_compiles([[
  int foo(void) {
		return 0;
	}

	int main(int argc, int *argv[]) {
		int foo = 0;
		return foo + 1;
	}
]] IS_WSHADOW_GOOD)
if(${IS_WSHADOW_GOOD})
  testadd_warning_compiler_flag(shadow OFF)
endif()
set(CMAKE_REQUIRED_FLAGS ${OLD_CMAKE_REQUIRED_FLAGS})

# Certain versions of gcc implement -Wformat-truncation in a naive way,
# disregarding the actual values that an integer can take in every code path
# and assuming a worst case of INT_MAX. That makes it not very useful as it
# produces meaningless warnings.
has_compiler_flag(Wno-format-truncation HAS_NO_FORMAT_TRANSACTION)
if(NOT ${HAS_NO_FORMAT_TRANSACTION})
  set(OLD_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
  set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -Werror")
  check_c_source_compiles([[
      #include <stdio.h>
			int foo(int argc, char *argv[]) {
				char buf[3];
				for (int i = 0; i < 4; i++) {
					snprintf(buf, sizeof(buf), "a%d", i);
				}
				return buf[1];
			}
  ]] IS_FORMAT_TRANSACTION_GOOD)

  if(NOT ${IS_FORMAT_TRANSACTION_GOOD})
    testadd_warning_compiler_flag(no-format-truncation OFF)
  endif()
  set(CMAKE_REQUIRED_FLAGS ${OLD_CMAKE_REQUIRED_FLAGS})
endif()

# Plugin flags
testwrite_compiler_flag(fPIC OFF SOFLAGS)

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

# Check if epoll is available and we're on linux
if(${ENABLE_EPOLL})
  check_source_runs(C [[
	  #ifndef __linux__
		#error This is not Linux
		#endif
		#include <sys/epoll.h>
    int main(int argc, char** argv)
	  {
	  	return 0;
	  }
  ]] HAVE_LINUX_EPOLL)

  if(NOT ${HAVE_LINUX_EPOLL})
    message(FATAL_ERROR "epoll support explicitly enabled but not available")
  else()
    add_compile_definitions(SOCKET_EPOLL)
  endif()
endif()

# Check for libraries
if(ENABLE_LIBBACKTRACE)
  find_package(libbacktrace REQUIRED)
  test_header_def(execinfo HAVE_EXECINFO OFF)
  testadd_compiler_flag(funwind-tables ON)
  add_compile_definitions(HAVE_LIBBACKTRACE)
endif()

if("${WITH_HTTP_PARSER}" STREQUAL "http-parser")
  add_compile_definitions(USE_HTTP_PARSER)
  message(STATUS "Use http-parser as http library")
elseif("${WITH_HTTP_PARSER}" STREQUAL "llhttp")
  message(STATUS "Use llhttp as http library")
else()
  message(FATAL_ERROR "unknown http_parser selected '${WITH_HTTP_PARSER}'. Allowed values: http-parser, llhttp. ... stopping")
endif()

find_package(cJSON REQUIRED)
find_package(mariadb-connector-c REQUIRED)
find_package(pcre REQUIRED)
find_package(ZLIB REQUIRED)

# Check for compile settings

# Memory manager setting
set(ENABLE_MEMORY_MANAGER_ALLOWED
  no
  builtin
  memwatch
  dmalloc
  gcollect
  bcheck
)

if(NOT ${ENABLE_MEMORY_MANAGER} IN_LIST ENABLE_MEMORY_MANAGER_ALLOWED)
  message(FATAL_ERROR "unknown memory manager '${ENABLE_MEMORY_MANAGER}'... stopping")
elseif(${ENABLE_MEMORY_MANAGER} STREQUAL "no")
  add_compile_definitions(NO_MEMMGR)
elseif(${ENABLE_MEMORY_MANAGER} STREQUAL "memwatch")
  test_header_def(memwatch "" ON)
  add_compile_definitions(MEMWATCH)
elseif(${ENABLE_MEMORY_MANAGER} STREQUAL "dmalloc")
  test_header_def(dmalloc "" ON)
  add_compile_definitions(DMALLOC DMALLOC_FUNC_CHECK)
  set(COMMON_MEMORY_MANAGER_LINK "dmalloc")
elseif(${ENABLE_MEMORY_MANAGER} STREQUAL "gcollect")
  test_header_def(gc "" ON)
  add_compile_definitions(GCOLLECT)
  set(COMMON_MEMORY_MANAGER_LINK "gc")
elseif(${ENABLE_MEMORY_MANAGER} STREQUAL "bcheck")
  add_compile_definitions(BCHECK)
endif()

if(${ENABLE_PACKETVER})
  add_compile_definitions("PACKETVER=${ENABLE_PACKETVER}")
endif()

if(${ENABLE_PACKETVER_RE})
  add_compile_definitions(ENABLE_PACKETVER_RE)
endif()

if(${ENABLE_PACKETVER_ZERO})
  add_compile_definitions(ENABLE_PACKETVER_ZERO)
endif()

if(${ENABLE_PACKETVER_SAK})
  add_compile_definitions(ENABLE_PACKETVER_SAK)
endif()

if(${ENABLE_PACKETVER_AD})
  add_compile_definitions(ENABLE_PACKETVER_AD)
endif()

if(${CASHSHOP_PREVIEW_PATCH})
  add_compile_definitions(ENABLE_CASHSHOP_PREVIEW_PATCH)
endif()

if(${OLD_CASHSHOP_PREVIEW_PATCH})
  add_compile_definitions(ENABLE_OLD_CASHSHOP_PREVIEW_PATCH)
endif()

if(${ENABLE_EPOLL})
  add_compile_definitions(SOCKET_EPOLL)
endif()

if(NOT "${OBFUSCATIONKEY1}" STREQUAL "" OR NOT "${OBFUSCATIONKEY2}" STREQUAL "" OR NOT "${OBFUSCATIONKEY3}" STREQUAL "")
  if("${OBFUSCATIONKEY1}" STREQUAL "" OR "${OBFUSCATIONKEY2}" STREQUAL "" OR "${OBFUSCATIONKEY3}" STREQUAL "")
    message(FATAL_ERROR "Less than three obfuscation keys have been specified. They will all be ignored.")
  elseif(NOT OBFUSCATIONKEY1 MATCHES "^0x[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9]$")
    message(FATAL_ERROR "Invalid OBFUSCATIONKEY1 format specified. It should be in the 0xNNNNNNNN format (with 8 hex digits).")
  elseif(NOT OBFUSCATIONKEY2 MATCHES "^0x[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9]$")
    message(FATAL_ERROR "Invalid OBFUSCATIONKEY2 format specified. It should be in the 0xNNNNNNNN format (with 8 hex digits).")
  elseif(NOT OBFUSCATIONKEY3 MATCHES "^0x[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9]$")
    message(FATAL_ERROR "Invalid OBFUSCATIONKEY3 format specified. It should be in the 0xNNNNNNNN format (with 8 hex digits).")
  else()
    add_compile_definitions("OBFUSCATIONKEY1=${OBFUSCATIONKEY1}" "OBFUSCATIONKEY2=${OBFUSCATIONKEY2}" "OBFUSCATIONKEY3=${OBFUSCATIONKEY3}")
  endif()
endif()

# Debug setting
if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  if(${ENABLE_GDB})
    message(FATAL_ERROR "ENABLE_GDB can be only used in debug builds")
  endif()
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  add_compile_definitions(DEBUG)
  if(${ENABLE_GDB})
    testadd_compiler_flag(ggdb ON)
  else()
    testadd_compiler_flag(g ON)
  endif()
endif()

if(${ENABLE_BUILDBOT})
  add_compile_definitions(BUILDBOT)
endif()

if(${ENABLE_RDTSC})
  add_compile_definitions(ENABLE_RDTSC)
endif()

if("${ENABLE_PROFILER}" STREQUAL "no")
elseif("${ENABLE_PROFILER}" STREQUAL "gprof")
  add_compile_options(pg)
  add_link_options(pg)
else()
  message(FATAL_ERROR "Unknown profiler option ${ENABLE_PROFILER}")
endif()

if(${DISABLE_RENEWAL})
  set(ENABLE_RENEWAL OFF)
endif()

if(NOT ${ENABLE_RENEWAL})
  add_compile_definitions(DISABLE_RENEWAL)
endif()

if(${ENABLE_STATIC_LINKING})
  set(OLD_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
  set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -static")
  check_source_runs(C [[
  	int main(int argc, char **argv){
			return 0;
		}
  ]] STATIC_LINK_SERVER)
  set(CMAKE_REQUIRED_FLAGS ${OLD_CMAKE_REQUIRED_FLAGS})

  if(${STATIC_LINK_SERVER})
    add_compile_options(-static)
  endif()

  set(OLD_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
  set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -static-libgcc")
  check_source_runs(C [[
  	int main(int argc, char **argv){
			return 0;
		}
  ]] STATIC_LINK_PLUGIN)
  set(CMAKE_REQUIRED_FLAGS ${OLD_CMAKE_REQUIRED_FLAGS})

  if(${STATIC_LINK_PLUGIN})
    list(APPEND ${SOFLAGS} "-static-libgcc")
  endif()
endif()

if(${ENABLE_WERROR})
  testadd_warning_compiler_flag(error ON)
endif()

if(${ENABLE_LTO})
  testadd_compiler_flag(flto ON)
  testadd_compiler_flag(ffat-lto-objects ON)
  testadd_linker_flag(flto ON)
  testadd_linker_flag(ffat-lto-objects ON)
endif()

if(${ENABLE_SANITIZE})
  add_compile_definitions(SANITIZE)
  testadd_sanitizer_flag(address OFF)
  testadd_sanitizer_flag(shift OFF)
  testadd_sanitizer_flag(integer-divide-by-zero OFF)
  testadd_sanitizer_flag(unreachable OFF)
  testadd_sanitizer_flag(vla-bound OFF)
  testadd_sanitizer_flag(null OFF)
  testadd_sanitizer_flag(return OFF)
  testadd_sanitizer_flag(signed-integer-overflow OFF)
  testadd_sanitizer_flag(bounds OFF)
  testadd_sanitizer_flag(bounds-strict OFF)
  testadd_sanitizer_flag(object-size OFF)
  testadd_sanitizer_flag(float-divide-by-zero OFF)
  testadd_sanitizer_flag(float-cast-overflow OFF)
  testadd_sanitizer_flag(nonnull-attribute OFF)
  testadd_sanitizer_flag(returns-nonnull-attribute OFF)
  testadd_sanitizer_flag(bool OFF)
  testadd_sanitizer_flag(enum OFF)
  testadd_sanitizer_flag(vptr OFF)
  testadd_sanitizer_flag(address-use-after-scope OFF)
  testadd_sanitizer_flag(pointer-overflow OFF)
  testadd_sanitizer_flag(builtin OFF)
  testadd_sanitizer_flag(pointer-compare OFF)
  testadd_sanitizer_flag(pointer-subtract OFF)
  testadd_sanitizer_flag(shift-exponent OFF)
  testadd_sanitizer_flag(shift-base OFF)
  testadd_sanitizer_flag(sanitize-address-use-after-scope OFF)
endif()

if(${MAX_CONNECTIONS})
  if(${MAX_CONNECTIONS} GREATER 0)
    add_compile_definitions("MAXCONN=${MAX_CONNECTIONS}")
  endif()
endif()

get_directory_property(MYDEFS LINK_OPTIONS)
message("LDFLAGS=${MYDEFS}")
get_directory_property(MYDEFS COMPILE_OPTIONS)
message("CFLAGS=${MYDEFS}")
get_directory_property(MYDEFS COMPILE_DEFINITIONS)
message("DEFS=${MYDEFS}")

include_directories(${PROJECT_SOURCE_DIR}/src)
include_directories(${PROJECT_SOURCE_DIR}/3rdparty)
add_subdirectory(3rdparty)
add_subdirectory(src)
