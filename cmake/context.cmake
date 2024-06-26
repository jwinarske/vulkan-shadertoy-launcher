#
# Copyright 2023 Toyota Connected North America
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if (CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    set(BUILD_STANDALONE ON)
else()
    set(BUILD_STANDALONE OFF)
endif()

#
# Branch
#
execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

if (GIT_BRANCH)
    message(STATUS "GIT Branch ............. ${GIT_BRANCH}")
    add_definitions("-DGIT_BRANCH=\"${GIT_BRANCH}\"")
else ()
    add_definitions("-DGIT_BRANCH=\"unkown\"")
endif ()

#
# Commit Hash
#
execute_process(
        COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

if (GIT_COMMIT_HASH)
    message(STATUS "GIT Hash ............... ${GIT_COMMIT_HASH}")
    add_definitions("-DGIT_HASH=\"${GIT_COMMIT_HASH}\"")
else ()
    add_definitions("-DGIT_HASH=\"unknown\"")
endif ()

#
# libc++
#
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    execute_process(
            COMMAND llvm-config --version
            OUTPUT_VARIABLE LLVM_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (LLVM_VERSION)
        message(STATUS "LLVM Version ........... ${LLVM_VERSION}")
    endif ()

    if (NOT LLVM_ROOT)
        execute_process(
                COMMAND llvm-config --prefix
                OUTPUT_VARIABLE LLVM_ROOT
                OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif ()

    if (NOT LLVM_ROOT)
        message(WARNING "LLVM_ROOT not detected, using default")
        set(LLVM_ROOT "/usr")
    endif ()

    message(STATUS "LLVM Root .............. ${LLVM_ROOT}")
    message(STATUS "C++ header path ........ ${LLVM_ROOT}/include/c++/v1/")

    list(APPEND CMAKE_CXX_FLAGS -stdlib=libc++)
    set(CONTEXT_COMPILE_OPTIONS $<$<COMPILE_LANGUAGE:CXX>:-stdlib=libc++> $<$<COMPILE_LANGUAGE:CXX>:-isystem${LLVM_ROOT}/include/c++/v1/>)

    execute_process(
            COMMAND llvm-config --cmakedir
            OUTPUT_VARIABLE LLVM_CMAKE_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (LLVM_CMAKE_DIR)
        message(STATUS "Clang CMake Path ....... ${LLVM_CMAKE_DIR}")
        list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
    endif ()

endif ()

#
# Toolchain IPO/LTO support
#
if (ENABLE_LTO)
    cmake_policy(SET CMP0069 NEW)
    include(CheckIPOSupported)
    check_ipo_supported(
            RESULT IPO_SUPPORT_RESULT
            OUTPUT IPO_SUPPORT_OUTPUT
            LANGUAGES C CXX
    )
    if (IPO_SUPPORT_RESULT)
        message(STATUS "IPO .................... supported")
    else ()
        message(STATUS "IPO .................... not supported: ${IPO_SUPPORT_OUTPUT}")
    endif ()
endif ()