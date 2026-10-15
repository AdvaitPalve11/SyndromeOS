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

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Message" -ForegroundColor Yellow
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                  SyndromeOS Pipeline                      " -ForegroundColor White
Write-Host "             64-bit Bare-Metal x86_64 OS                   " -ForegroundColor DarkGray
Write-Host "==========================================================" -ForegroundColor Cyan

# Locate QEMU virtualization tool
Write-Step "1/4" "Detecting virtualization tools (QEMU)..."

$QemuCandidates = @(
    (Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "C:\Program Files\qemu\qemu-system-x86_64.exe",
    "C:\msys64\ucrt64\bin\qemu-system-x86_64.exe",
    "C:\msys64\mingw64\bin\qemu-system-x86_64.exe",
    (Join-Path $env:USERPROFILE "scoop\apps\qemu\current\qemu-system-x86_64.exe"),
    (Join-Path $env:USERPROFILE "scoop\shims\qemu-system-x86_64.exe"),
    "C:\ProgramData\chocolatey\bin\qemu-system-x86_64.exe"
)

$QemuPath = $QemuCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $QemuPath) {
    Write-Host ""
    Write-Host "[ERROR] QEMU executable (qemu-system-x86_64.exe) was not found." -ForegroundColor Red
    Write-Host "Please install QEMU via one of the following commands:" -ForegroundColor Yellow
    Write-Host "  winget install SoftwareFreedomConservancy.QEMU" -ForegroundColor Cyan
    Write-Host "  choco install qemu" -ForegroundColor Cyan
    Write-Host "  scoop install qemu" -ForegroundColor Cyan
    throw "QEMU not installed."
}
Write-Success "QEMU: $QemuPath"

$DiskImage = Join-Path $WorkspaceRoot "build\syndrome.img"
$EfiBinary = Join-Path $WorkspaceRoot "build\SyndromeOS.efi"
$BuildDir  = Join-Path $WorkspaceRoot "build"

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
            "C:\Program Files\Docker\Docker\Docker Desktop.exe",
            (Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe")
        )
        $DockerExe = $DockerDesktopCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

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
            Write-Host ""
            Write-Host "[ERROR] Docker engine is not running or not installed." -ForegroundColor Red
            Write-Host "Please start Docker Desktop or install it from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
            throw "Docker engine not available."
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

    # Create FAT32 disk image and copy bootloader + extract firmware
    Write-Info "Formatting FAT32 disk image and provisioning EFI boot structure..."
    docker run --rm `
        -v "${WorkspaceRoot}:/src" `
        syndromeos-build `
        bash -c "dd if=/dev/zero of=/src/build/syndrome.img bs=1M count=64 && mkfs.fat -F 32 /src/build/syndrome.img && mmd -i /src/build/syndrome.img ::/EFI && mmd -i /src/build/syndrome.img ::/EFI/BOOT && mcopy -i /src/build/syndrome.img /src/build/SyndromeOS.efi ::/EFI/BOOT/BOOTX64.EFI && (cp /usr/share/OVMF/OVMF_CODE_4M.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/ovmf/OVMF.fd /src/build/ovmf.fd 2>/dev/null || true)"

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $DiskImage)) {
        throw "Failed to create bootable disk image."
    }
    Write-Success "Bootable disk image ready: build/syndrome.img"
}

# Locate OVMF UEFI firmware
$QemuDir = Split-Path $QemuPath
$OvmfCandidates = @(
    (Join-Path $WorkspaceRoot "build\ovmf.fd"),
    (Join-Path $QemuDir "share\edk2-x86_64-code.fd"),
    (Join-Path $QemuDir "share\qemu\edk2-x86_64-code.fd"),
    (Join-Path $QemuDir "edk2-x86_64-code.fd"),
    "C:\Program Files\qemu\share\edk2-x86_64-code.fd",
    "C:\Program Files\qemu\share\qemu\edk2-x86_64-code.fd",
    "C:\Program Files\qemu\edk2-x86_64-code.fd",
    "C:\msys64\ucrt64\share\qemu\edk2-x86_64-code.fd",
    "C:\msys64\mingw64\share\qemu\edk2-x86_64-code.fd",
    (Join-Path $env:USERPROFILE "scoop\apps\qemu\current\share\edk2-x86_64-code.fd"),
    "C:\ProgramData\chocolatey\lib\qemu\tools\share\edk2-x86_64-code.fd"
)

$OvmfPath = $OvmfCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $OvmfPath) {
    # If not found locally, try extracting it from docker image if docker is available
    Write-Info "OVMF firmware not found locally. Extracting from build image..."
    try {
        if (-not (Test-Path $BuildDir)) { New-Item -ItemType Directory -Path $BuildDir | Out-Null }
        docker run --rm -v "${WorkspaceRoot}:/src" syndromeos-build cp /usr/share/OVMF/OVMF_CODE_4M.fd /src/build/ovmf.fd 2>&1 | Out-Null
        $BuildOvmf = Join-Path $WorkspaceRoot "build\ovmf.fd"
        if (Test-Path $BuildOvmf) {
            $OvmfPath = $BuildOvmf
        }
    } catch {}
}

if (-not $OvmfPath) {
    Write-Host ""
    Write-Host "[ERROR] OVMF UEFI firmware (edk2-x86_64-code.fd / OVMF_CODE.fd) was not found." -ForegroundColor Red
    Write-Host "Please ensure QEMU is installed with UEFI support or run the build pipeline first." -ForegroundColor Yellow
    throw "OVMF firmware missing."
}
Write-Success "OVMF Firmware: $OvmfPath"

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
