$ErrorActionPreference = "Stop"
$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Build Docker development environment
Write-Host "[1/2] Building Docker build image..."
docker build -t syndromeos-build (Join-Path $WorkspaceRoot "buildenv")

if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed."
}

# Compile SyndromeOS inside container
Write-Host "`n[2/2] Compiling SyndromeOS..."
docker run --rm `
    -v "${WorkspaceRoot}:/src" `
    syndromeos-build `
    bash -c "rm -rf /src/build && mkdir -p /src/build && cmake -S /src -B /src/build && cmake --build /src/build"

if ($LASTEXITCODE -ne 0) {
    throw "SyndromeOS build failed."
}

Write-Host "`nBuild complete: build/SyndromeOS.efi"