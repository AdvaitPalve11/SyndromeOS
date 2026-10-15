$ErrorActionPreference = "Stop"
$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$DiskImage = Join-Path $WorkspaceRoot "build\syndrome.img"

if (-not (Test-Path $DiskImage)) {
    throw "SyndromeOS disk image not found: $DiskImage. Run build/image creation first."
}

# Locate QEMU binary
$QemuCandidates = @(
    "C:\msys64\ucrt64\bin\qemu-system-x86_64.exe",
    "C:\Program Files\qemu\qemu-system-x86_64.exe",
    (Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
)
$QemuPath = $QemuCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $QemuPath) {
    throw "QEMU executable not found."
}

# Locate OVMF firmware
$OvmfCandidates = @(
    "C:\msys64\ucrt64\share\qemu\edk2-x86_64-code.fd",
    "C:\msys64\share\qemu\edk2-x86_64-code.fd",
    "C:\Program Files\qemu\share\edk2-x86_64-code.fd",
    (Join-Path $WorkspaceRoot "build\ovmf.fd")
)
$OvmfPath = $OvmfCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $OvmfPath) {
    throw "OVMF UEFI firmware not found."
}

# Launch QEMU
Write-Host "Starting QEMU with SyndromeOS..."
& $QemuPath `
    -machine q35 `
    -m 512M `
    -drive "if=pflash,format=raw,readonly=on,file=$OvmfPath" `
    -drive "format=raw,file=$DiskImage"