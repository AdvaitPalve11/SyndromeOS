$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "          Building SyndromeOS"
Write-Host ""

& "$PSScriptRoot\build.ps1"

if ($LASTEXITCODE -ne 0) {
    throw "SyndromeOS build failed."
}

Write-Host ""
Write-Host "       Creating Disk Image"
Write-Host ""

& "$PSScriptRoot\create_image.ps1"

if ($LASTEXITCODE -ne 0) {
    throw "Disk image creation failed."
}

Write-Host ""
Write-Host "          Starting QEMU"
Write-Host ""

& "$PSScriptRoot\run_qemu.ps1"