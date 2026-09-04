$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host "        Building SyndromeOS"
Write-Host "========================================"
Write-Host ""

# Build the Docker development environment
Write-Host "[1/2] Building Docker environment..."

docker build `
    -t syndromeos-build `
    ./buildenv

if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed."
}

# Build SyndromeOS inside the container
Write-Host ""
Write-Host "[2/2] Building SyndromeOS..."

docker run --rm `
    -v "${PWD}:/src" `
    syndromeos-build `
    bash -c "rm -rf /src/build && mkdir -p /src/build && cmake -S /src -B /src/build && cmake --build /src/build"

    
if ($LASTEXITCODE -ne 0) {
    throw "SyndromeOS build failed."
}

Write-Host ""
Write-Host "========================================"
Write-Host "      SyndromeOS build successful"
Write-Host "========================================"
Write-Host ""

Write-Host "Output:"
Write-Host "  build/SyndromeOS.efi"
Write-Host ""