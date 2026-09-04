$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "      Creating SyndromeOS Disk Image"
Write-Host "========================================"
Write-Host ""

$image = Join-Path $PWD "build\syndrome.img"
$efi   = Join-Path $PWD "build\SyndromeOS.efi"

if (!(Test-Path $efi)) {
    throw "SyndromeOS.efi not found. Run .\tools\build.ps1 first."
}

# Remove old image
if (Test-Path $image) {
    Remove-Item $image -Force
}

Write-Host "[1/3] Creating FAT image..."

docker run --rm `
    -v "${PWD}:/src" `
    syndromeos-build `
    bash -c "dd if=/dev/zero of=/src/build/syndrome.img bs=1M count=64 && mkfs.fat -F 32 /src/build/syndrome.img"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create FAT image."
}

Write-Host "[2/3] Creating EFI directory..."

docker run --rm `
    -v "${PWD}:/src" `
    syndromeos-build `
    bash -c "mmd -i /src/build/syndrome.img ::/EFI && mmd -i /src/build/syndrome.img ::/EFI/BOOT"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create EFI directories."
}

Write-Host "[3/3] Copying bootloader..."

docker run --rm `
    -v "${PWD}:/src" `
    syndromeos-build `
    bash -c "mcopy -i /src/build/syndrome.img /src/build/SyndromeOS.efi ::/EFI/BOOT/BOOTX64.EFI"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to copy bootloader."
}

Write-Host ""
Write-Host "========================================"
Write-Host "       Disk image created"
Write-Host "========================================"
Write-Host ""

Write-Host "Image:"
Write-Host "  build/syndrome.img"
Write-Host ""

Get-Item $image