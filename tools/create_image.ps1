$ErrorActionPreference = "Stop"
$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$DiskImage = Join-Path $WorkspaceRoot "build\syndrome.img"
$EfiBinary = Join-Path $WorkspaceRoot "build\SyndromeOS.efi"

if (-not (Test-Path $EfiBinary)) {
    throw "SyndromeOS.efi not found. Run build script first."
}

# Remove existing disk image
if (Test-Path $DiskImage) {
    Remove-Item $DiskImage -Force
}

# Create FAT32 image and copy UEFI bootloader
Write-Host "Creating bootable FAT32 disk image..."
docker run --rm `
    -v "${WorkspaceRoot}:/src" `
    syndromeos-build `
    bash -c "dd if=/dev/zero of=/src/build/syndrome.img bs=1M count=64 && mkfs.fat -F 32 /src/build/syndrome.img && mmd -i /src/build/syndrome.img ::/EFI && mmd -i /src/build/syndrome.img ::/EFI/BOOT && mcopy -i /src/build/syndrome.img /src/build/SyndromeOS.efi ::/EFI/BOOT/BOOTX64.EFI && (cp /usr/share/OVMF/OVMF_CODE_4M.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/ovmf/OVMF.fd /src/build/ovmf.fd 2>/dev/null || true)"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $DiskImage)) {
    throw "Failed to create FAT disk image."
}

Write-Host "Disk image ready: build/syndrome.img"
Get-Item $DiskImage