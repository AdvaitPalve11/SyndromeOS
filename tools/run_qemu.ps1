$ErrorActionPreference = "Stop"
$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$DiskImage = Join-Path $WorkspaceRoot "build\syndrome.img"

if (-not (Test-Path $DiskImage)) {
    throw "SyndromeOS disk image not found: $DiskImage. Run build/image creation first."
}

# Locate QEMU binary
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
    throw "QEMU executable not found. Please install QEMU (e.g. winget install SoftwareFreedomConservancy.QEMU)."
}

# Locate OVMF firmware
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
    throw "OVMF UEFI firmware not found. Please ensure QEMU or edk2-x86_64-code.fd is installed."
}

# Launch QEMU
Write-Host "Starting QEMU with SyndromeOS..."
& $QemuPath `
    -machine q35 `
    -m 512M `
    -drive "if=pflash,format=raw,readonly=on,file=$OvmfPath" `
    -drive "format=raw,file=$DiskImage"