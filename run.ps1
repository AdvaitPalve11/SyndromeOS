<#
.SYNOPSIS
    SyndromeOS automated build pipeline and runner.
.DESCRIPTION
    Builds the toolchain container, compiles SyndromeOS via CMake, creates the bootable
    UEFI disk image, and launches QEMU with OVMF firmware.
.PARAMETER SkipBuild
    Skips compilation and image generation, launching QEMU directly with the current image.
.PARAMETER EnableDebug
    Enables QEMU GDB stub (-s -S) and redirects serial output to stdio.
#>

[CmdletBinding()]
param (
    [switch]$SkipBuild,
    [switch]$EnableDebug
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = $PSScriptRoot

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host ""
    Write-Host "[$Step] " -ForegroundColor Cyan -NoNewline
    Write-Host "$Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host "$Message" -ForegroundColor White
}

function Write-Info {
    param([string]$Message)
    Write-Host "  -> " -ForegroundColor DarkGray -NoNewline
    Write-Host "$Message" -ForegroundColor Gray
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                  SyndromeOS Pipeline                      " -ForegroundColor White
Write-Host "             64-bit Bare-Metal x86_64 OS                   " -ForegroundColor DarkGray
Write-Host "==========================================================" -ForegroundColor Cyan

# Locate QEMU and OVMF firmware
Write-Step "1/4" "Detecting virtualization tools (QEMU & OVMF)..."

$QemuCandidates = @(
    "C:\msys64\ucrt64\bin\qemu-system-x86_64.exe",
    "C:\Program Files\qemu\qemu-system-x86_64.exe",
    (Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
)

$QemuPath = $QemuCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $QemuPath) {
    throw "QEMU not found. Please ensure qemu-system-x86_64 is installed or in PATH."
}
Write-Success "QEMU: $QemuPath"

$OvmfCandidates = @(
    "C:\msys64\ucrt64\share\qemu\edk2-x86_64-code.fd",
    "C:\msys64\share\qemu\edk2-x86_64-code.fd",
    "C:\Program Files\qemu\share\edk2-x86_64-code.fd",
    (Join-Path $WorkspaceRoot "build\ovmf.fd")
)

$OvmfPath = $OvmfCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $OvmfPath) {
    throw "OVMF UEFI firmware not found. Please ensure edk2-x86_64-code.fd is installed."
}
Write-Success "OVMF: $OvmfPath"

$DiskImage = Join-Path $WorkspaceRoot "build\syndrome.img"
$EfiBinary = Join-Path $WorkspaceRoot "build\SyndromeOS.efi"

if ($SkipBuild) {
    if (-not (Test-Path $DiskImage)) {
        throw "Cannot skip build: Disk image does not exist ($DiskImage). Run without -SkipBuild first."
    }
    Write-Info "Skipping compilation & image generation (-SkipBuild)."
} else {
    # Terminate running QEMU instance to release disk image locks
    $RunningQemu = Get-Process "qemu-system-x86_64" -ErrorAction SilentlyContinue
    if ($RunningQemu) {
        Write-Info "Closing previous QEMU instance to release disk image locks..."
        $RunningQemu | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }

    # Check and initialize Docker daemon
    Write-Step "2/4" "Checking Docker build engine..."

    $DockerRunning = $false
    try {
        $null = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            $DockerRunning = $true
        }
    } catch {}

    if (-not $DockerRunning) {
        Write-Info "Docker daemon not running. Attempting to start Docker Desktop..."
        $DockerDesktopCandidates = @(
            (Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\Docker Desktop.exe"),
            "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        )
        $DockerExe = $DockerDesktopCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($DockerExe) {
            Start-Process -FilePath $DockerExe
            Write-Info "Waiting for Docker daemon to respond..."
            $Retries = 30
            while ($Retries -gt 0) {
                Start-Sleep -Seconds 2
                try {
                    $null = docker info 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $DockerRunning = $true
                        break
                    }
                } catch {}
                $Retries--
            }
        }

        if (-not $DockerRunning) {
            throw "Failed to connect to Docker engine. Please ensure Docker Desktop is started."
        }
    }
    Write-Success "Docker engine is ready."

    # Build container image and compile SyndromeOS
    Write-Step "3/4" "Compiling SyndromeOS & building disk image..."

    Write-Info "Building container image 'syndromeos-build'..."
    docker build -t syndromeos-build (Join-Path $WorkspaceRoot "buildenv")
    if ($LASTEXITCODE -ne 0) {
        throw "Docker image build failed."
    }

    Write-Info "Running CMake build inside container..."
    docker run --rm `
        -v "${WorkspaceRoot}:/src" `
        syndromeos-build `
        bash -c "rm -rf /src/build && mkdir -p /src/build && cmake -S /src -B /src/build && cmake --build /src/build"

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $EfiBinary)) {
        throw "Compilation failed. SyndromeOS.efi was not generated."
    }
    Write-Success "SyndromeOS.efi built successfully."

    # Create FAT32 disk image and copy bootloader
    Write-Info "Formatting FAT32 disk image and copying /EFI/BOOT/BOOTX64.EFI..."
    docker run --rm `
        -v "${WorkspaceRoot}:/src" `
        syndromeos-build `
        bash -c "dd if=/dev/zero of=/src/build/syndrome.img bs=1M count=64 && mkfs.fat -F 32 /src/build/syndrome.img && mmd -i /src/build/syndrome.img ::/EFI && mmd -i /src/build/syndrome.img ::/EFI/BOOT && mcopy -i /src/build/syndrome.img /src/build/SyndromeOS.efi ::/EFI/BOOT/BOOTX64.EFI"

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $DiskImage)) {
        throw "Failed to create bootable disk image."
    }
    Write-Success "Bootable disk image ready: build/syndrome.img"
}

# Launch QEMU with UEFI firmware
Write-Step "4/4" "Booting SyndromeOS in QEMU..."

$QemuArgs = @(
    "-machine", "q35",
    "-m", "512M",
    "-drive", "if=pflash,format=raw,readonly=on,file=$OvmfPath",
    "-drive", "format=raw,file=$DiskImage"
)

if ($EnableDebug) {
    Write-Info "Debug mode active: listening on gdb:1234 (-s -S) and piping serial to stdio."
    $QemuArgs += @("-s", "-S", "-serial", "stdio")
}

Write-Host ""
Write-Host "  -> Starting VM now..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

& $QemuPath $QemuArgs
