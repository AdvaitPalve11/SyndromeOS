$ErrorActionPreference = "Stop"

$qemu = "C:\msys64\ucrt64\bin\qemu-system-x86_64.exe"
$ovmf = "C:\msys64\ucrt64\share\qemu\edk2-x86_64-code.fd"
$image = Join-Path $PWD "build\syndrome.img"

if (!(Test-Path $qemu)) {
    throw "QEMU not found: $qemu"
}

if (!(Test-Path $ovmf)) {
    throw "OVMF firmware not found: $ovmf"
}

if (!(Test-Path $image)) {
    throw "SyndromeOS disk image not found: $image"
}

Write-Host ""
Write-Host "========================================"
Write-Host "          Starting SyndromeOS"
Write-Host "========================================"
Write-Host ""

& $qemu `
    -machine q35 `
    -m 512M `
    -drive "if=pflash,format=raw,readonly=on,file=$ovmf" `
    -drive "format=raw,file=$image"