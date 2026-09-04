cmake_minimum_required(VERSION 3.20)

project(SyndromeOS LANGUAGES C ASM)

# ------------------------------------------------------------
# SyndromeOS
# Target: x86_64 UEFI
# ------------------------------------------------------------

set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# ------------------------------------------------------------
# GNU-EFI
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# UEFI Bootloader
# ------------------------------------------------------------

set(BOOT_SOURCE
    ${CMAKE_SOURCE_DIR}/boot/uefi/main.c
)

set(BOOT_OBJECT
    ${CMAKE_BINARY_DIR}/main.o
)

set(BOOT_ELF
    ${CMAKE_BINARY_DIR}/SyndromeOS.so
)

set(BOOT_EFI
    ${CMAKE_BINARY_DIR}/SyndromeOS.efi
)

# ------------------------------------------------------------
# Compile bootloader
# ------------------------------------------------------------

add_custom_command(
    OUTPUT ${BOOT_OBJECT}

    COMMAND ${CMAKE_C_COMPILER}
        -I${EFI_INCLUDE_DIR}
        -I${EFI_ARCH_INCLUDE_DIR}
        -DEFI_FUNCTION_WRAPPER
        -fpic
        -ffreestanding
        -fno-stack-protector
        -fno-stack-check
        -fshort-wchar
        -mno-red-zone
        -mcmodel=small
        -c ${BOOT_SOURCE}
        -o ${BOOT_OBJECT}

    DEPENDS ${BOOT_SOURCE}

    COMMENT "Compiling UEFI bootloader"
)

# ------------------------------------------------------------
# Link bootloader using GNU-EFI
# ------------------------------------------------------------

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
        ${BOOT_OBJECT}
        -lgnuefi
        -lefi
        -o ${BOOT_ELF}

    DEPENDS ${BOOT_OBJECT}

    COMMENT "Linking UEFI bootloader"
)

# ------------------------------------------------------------
# Convert ELF -> PE/COFF EFI executable
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# UEFI target
# ------------------------------------------------------------

add_custom_target(uefi ALL
    DEPENDS ${BOOT_EFI}
)

# ------------------------------------------------------------
# Build information
# ------------------------------------------------------------

message(STATUS "")
message(STATUS "========================================")
message(STATUS "          SyndromeOS Build")
message(STATUS "========================================")
message(STATUS "EFI include : ${EFI_INCLUDE_DIR}")
message(STATUS "EFI arch    : ${EFI_ARCH_INCLUDE_DIR}")
message(STATUS "EFI linker  : ${EFI_LINKER_SCRIPT}")
message(STATUS "EFI CRT     : ${EFI_CRT}")
message(STATUS "EFI library : ${EFI_LIBRARY}")
message(STATUS "GNU-EFI     : ${GNUEFI_LIBRARY}")
message(STATUS "========================================")
message(STATUS "")