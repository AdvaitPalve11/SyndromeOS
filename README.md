<p align="center">
  <img src="Assets/BlackandWhiteEye.jpg" width="100" alt="SyndromeOS Logo">
</p>

<h1 align="center">SyndromeOS</h1>

<p align="center">
  <i>A 64-bit x86_64 operating system built from scratch.</i><br><br>
  <img src="https://img.shields.io/badge/Arch-x86__64-blue.svg" alt="Architecture">
  <img src="https://img.shields.io/badge/Firmware-UEFI%202.x-brightgreen.svg" alt="Firmware">
  <img src="https://img.shields.io/badge/Build-CMake%20%7C%20Docker-orange.svg" alt="Build">
</p>

<p align="center">
  <img src="Assets/BootImage.png" width="700" alt="SyndromeOS Boot Image">
</p>

---

## Overview

**SyndromeOS** is a bare-metal `x86_64` operating system written in C, C++, Assembly, and Rust. It boots via a custom UEFI 2.x bootloader (`BOOTX64.EFI`), initializes a Graphics Output Protocol (GOP) linear framebuffer, retrieves the hardware memory map, exits Boot Services, and jumps into a freestanding 64-bit Long Mode kernel.

## Quick Start

Requires **Docker** and **QEMU** (`winget install SoftwareFreedomConservancy.QEMU`, `apt install qemu-system-x86 ovmf`, or `brew install qemu`).

| Task | Linux / macOS | Windows (PowerShell) |
| :--- | :--- | :--- |
| **Build & Run** | `./scripts/run.sh` (or `make run`) | `.\scripts\run.ps1` |
| **Skip Build** | `./scripts/run.sh --skip-build` | `.\scripts\run.ps1 -SkipBuild` |
| **Debug (GDB)** | `./scripts/run.sh --debug` | `.\scripts\run.ps1 -EnableDebug` |
| **Native Linux** | `./scripts/run.sh --native` | *N/A* |

**Debugging:** After launching with `--debug` / `-EnableDebug`, attach GDB via:
```bash
gdb build/SyndromeOS.so -ex "target remote localhost:1234" -ex "b efi_main" -ex "c"
```

## Architecture

- **`src/boot/`** — UEFI entry point (`entry.cpp`), GOP framebuffer initialization, and Boot Services handoff.
- **`src/kernel/`** — Freestanding 64-bit kernel (`kmain.cpp`), PIT timer, hardware I/O, and memory management.
- **`buildenv/` & `scripts/`** — Dockerized Ubuntu 24.04 cross-compiler toolchain and automated QEMU runners.