cmake_minimum_required(VERSION 3.20)

project(SyndromeOS LANGUAGES C CXX ASM)

# Target: x86_64 UEFI
set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Locate GNU-EFI components
find_path(EFI_INCLUDE_DIR
    NAMES efi.h
    PATHS
        /usr/local/include/efi
        /usr/include/efi
    REQUIRED
)

set(EFI_ARCH_INCLUDE_DIR
    /usr/local/include/efi/x86_64
)

find_file(EFI_LINKER_SCRIPT
    NAMES elf_x86_64_efi.lds
    PATHS
        /usr/local/lib
        /usr/lib
        /usr/lib64
        /usr/lib/x86_64-linux-gnu
        /usr/lib/gnuefi
    REQUIRED
)

find_file(EFI_CRT
    NAMES crt0-efi-x86_64.o
    PATHS
        /usr/local/lib
        /usr/lib
        /usr/lib64
        /usr/lib/x86_64-linux-gnu
        /usr/lib/gnuefi
    REQUIRED
)

find_library(EFI_LIBRARY
    NAMES efi
    PATHS
        /usr/local/lib
        /usr/lib
        /usr/lib64
        /usr/lib/x86_64-linux-gnu
        /usr/lib/gnuefi
    REQUIRED
)

find_library(GNUEFI_LIBRARY
    NAMES gnuefi
    PATHS
        /usr/local/lib
        /usr/lib
        /usr/lib64
        /usr/lib/x86_64-linux-gnu
        /usr/lib/gnuefi
    REQUIRED
)

# Output definitions
set(BOOT_OBJECTS
    ${CMAKE_BINARY_DIR}/entry.o
    ${CMAKE_BINARY_DIR}/graphics.o
    ${CMAKE_BINARY_DIR}/kmain.o
    ${CMAKE_BINARY_DIR}/pit.o
)

set(BOOT_ELF
    ${CMAKE_BINARY_DIR}/SyndromeOS.so
)

set(BOOT_EFI
    ${CMAKE_BINARY_DIR}/SyndromeOS.efi
)

# Common flags for freestanding UEFI
set(EFI_COMMON_FLAGS
    -I${EFI_INCLUDE_DIR}
    -I${EFI_ARCH_INCLUDE_DIR}
    -I${CMAKE_SOURCE_DIR}/src
    -I${CMAKE_SOURCE_DIR}/src/kernel
    -I${CMAKE_SOURCE_DIR}/src/boot
    -DEFI_FUNCTION_WRAPPER
    -fpic
    -ffreestanding
    -fno-stack-protector
    -fno-stack-check
    -fshort-wchar
    -mno-red-zone
    -mcmodel=small
)

set(EFI_CXX_FLAGS
    ${EFI_COMMON_FLAGS}
    -fno-exceptions
    -fno-rtti
    -fno-use-cxa-atexit
    -fpermissive
)

# Compile source files
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/entry.o
    COMMAND ${CMAKE_CXX_COMPILER}
        ${EFI_CXX_FLAGS}
        -c ${CMAKE_SOURCE_DIR}/src/boot/uefi/entry.cpp
        -o ${CMAKE_BINARY_DIR}/entry.o
    DEPENDS
        ${CMAKE_SOURCE_DIR}/src/boot/uefi/entry.cpp
        ${CMAKE_SOURCE_DIR}/src/boot/graphics/graphics.h
        ${CMAKE_SOURCE_DIR}/src/kernel/bootinfo.h
    COMMENT "Compiling UEFI bootloader entry"
)

add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/graphics.o
    COMMAND ${CMAKE_C_COMPILER}
        ${EFI_COMMON_FLAGS}
        -c ${CMAKE_SOURCE_DIR}/src/boot/graphics/graphics.c
        -o ${CMAKE_BINARY_DIR}/graphics.o
    DEPENDS
        ${CMAKE_SOURCE_DIR}/src/boot/graphics/graphics.c
        ${CMAKE_SOURCE_DIR}/src/boot/graphics/graphics.h
        ${CMAKE_SOURCE_DIR}/src/boot/graphics/logo.h
    COMMENT "Compiling graphics renderer"
)

add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/kmain.o
    COMMAND ${CMAKE_CXX_COMPILER}
        ${EFI_CXX_FLAGS}
        -c ${CMAKE_SOURCE_DIR}/src/kernel/kmain.cpp
        -o ${CMAKE_BINARY_DIR}/kmain.o
    DEPENDS
        ${CMAKE_SOURCE_DIR}/src/kernel/kmain.cpp
        ${CMAKE_SOURCE_DIR}/src/kernel/bootinfo.h
    COMMENT "Compiling kernel main"
)

add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/pit.o
    COMMAND ${CMAKE_CXX_COMPILER}
        ${EFI_CXX_FLAGS}
        -c ${CMAKE_SOURCE_DIR}/src/kernel/pit.cpp
        -o ${CMAKE_BINARY_DIR}/pit.o
    DEPENDS
        ${CMAKE_SOURCE_DIR}/src/kernel/pit.cpp
        ${CMAKE_SOURCE_DIR}/src/kernel/pit.h
        ${CMAKE_SOURCE_DIR}/src/kernel/io.h
    COMMENT "Compiling PIT driver"
)

# Link bootloader using GNU-EFI
add_custom_command(
    OUTPUT ${BOOT_ELF}
    COMMAND /usr/bin/ld
        -nostdlib
        -znocombreloc
        -T${EFI_LINKER_SCRIPT}
        -shared
        -Bsymbolic
        -L/usr/local/lib
        ${EFI_CRT}
        ${BOOT_OBJECTS}
        -lgnuefi
        -lefi
        -o ${BOOT_ELF}
    DEPENDS ${BOOT_OBJECTS}
    COMMENT "Linking UEFI binary"
)

# Convert ELF to PE/COFF EFI executable
add_custom_command(
    OUTPUT ${BOOT_EFI}
    COMMAND ${CMAKE_OBJCOPY}
        -j .text
        -j .sdata
        -j .data
        -j .rodata
        -j .dynamic
        -j .dynsym
        -j .rel
        -j .rela
        -j .rel.*
        -j .rela.*
        -j .reloc
        --target=efi-app-x86_64
        ${BOOT_ELF}
        ${BOOT_EFI}
    DEPENDS ${BOOT_ELF}
    COMMENT "Creating SyndromeOS.efi"
)

# Default target
add_custom_target(uefi ALL
    DEPENDS ${BOOT_EFI}
)

# Build configuration status
message(STATUS "SyndromeOS Build")
message(STATUS "EFI include : ${EFI_INCLUDE_DIR}")
message(STATUS "EFI arch    : ${EFI_ARCH_INCLUDE_DIR}")
message(STATUS "EFI linker  : ${EFI_LINKER_SCRIPT}")
message(STATUS "EFI CRT     : ${EFI_CRT}")
message(STATUS "EFI library : ${EFI_LIBRARY}")
message(STATUS "GNU-EFI     : ${GNUEFI_LIBRARY}")