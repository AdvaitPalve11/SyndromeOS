#!/usr/bin/env bash
# ==============================================================================
# SyndromeOS automated build pipeline and runner (Linux & macOS)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORKSPACE_ROOT"

# Color definitions
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

write_step() {
    echo -e "\n${CYAN}[$1]${NC} ${YELLOW}$2${NC}"
}

write_success() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

write_info() {
    echo -e "  ${GRAY}->${NC} $1"
}

write_warn() {
    echo -e "  ${YELLOW}[!]${NC} $1"
}

# Default options
SKIP_BUILD=false
ENABLE_DEBUG=false
FORCE_NATIVE=false

for arg in "$@"; do
    case "$arg" in
        --skip-build|-s)
            SKIP_BUILD=true
            ;;
        --debug|-d)
            ENABLE_DEBUG=true
            ;;
        --native|-n)
            FORCE_NATIVE=true
            ;;
        --help|-h)
            echo "SyndromeOS Pipeline Runner"
            echo "Usage: ./run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-build, -s   Skip compilation and run existing disk image"
            echo "  --debug, -d        Launch QEMU with GDB stub (-s -S) and serial output"
            echo "  --native, -n       Build using host toolchain directly without Docker"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use ./run.sh --help for available options."
            exit 1
            ;;
    esac
done

echo -e "${CYAN}==========================================================${NC}"
echo -e "                  SyndromeOS Pipeline                      "
echo -e "             64-bit Bare-Metal x86_64 OS                   "
echo -e "${CYAN}==========================================================${NC}"

# 1. Locate QEMU
write_step "1/4" "Detecting virtualization tools (QEMU)..."

QEMU_BIN=""
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    QEMU_BIN="$(command -v qemu-system-x86_64)"
fi

if [ -z "$QEMU_BIN" ]; then
    echo -e "\n${RED}[ERROR] qemu-system-x86_64 was not found.${NC}"
    echo -e "Please install QEMU using your package manager:"
    echo -e "  Ubuntu/Debian: ${CYAN}sudo apt install qemu-system-x86 ovmf${NC}"
    echo -e "  Fedora:        ${CYAN}sudo dnf install qemu-system-x86 edk2-ovmf${NC}"
    echo -e "  Arch Linux:    ${CYAN}sudo pacman -S qemu-system-x86 edk2-ovmf${NC}"
    echo -e "  macOS:         ${CYAN}brew install qemu${NC}"
    exit 1
fi
write_success "QEMU: $QEMU_BIN"

DISK_IMAGE="$WORKSPACE_ROOT/build/syndrome.img"
EFI_BINARY="$WORKSPACE_ROOT/build/SyndromeOS.efi"

# 2. Build pipeline
if [ "$SKIP_BUILD" = true ]; then
    if [ ! -f "$DISK_IMAGE" ]; then
        echo -e "${RED}[ERROR] Cannot skip build: Disk image does not exist ($DISK_IMAGE).${NC}"
        echo "Run without --skip-build first to compile."
        exit 1
    fi
    write_info "Skipping compilation & image generation (--skip-build)."
else
    # Terminate running QEMU if it holds locks
    if pgrep -x "qemu-system-x86_64" >/dev/null 2>&1; then
        write_info "Stopping existing QEMU instances..."
        pkill -x "qemu-system-x86_64" 2>/dev/null || true
        sleep 0.5
    fi

    # Determine build method (Docker vs Native)
    USE_DOCKER=false
    if [ "$FORCE_NATIVE" = false ] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        USE_DOCKER=true
    fi

    if [ "$USE_DOCKER" = true ]; then
        write_step "2/4" "Checking Docker build engine..."
        write_success "Docker engine is ready."

        write_step "3/4" "Compiling SyndromeOS & building disk image via Docker..."
        write_info "Building container image 'syndromeos-build'..."
        docker build -t syndromeos-build "$WORKSPACE_ROOT/buildenv"

        write_info "Building SyndromeOS inside container..."
        docker run --rm \
            -v "$WORKSPACE_ROOT:/src" \
            syndromeos-build \
            bash -c "rm -rf /src/build && mkdir -p /src/build && cmake -S /src -B /src/build && cmake --build /src/build && dd if=/dev/zero of=/src/build/syndrome.img bs=1M count=64 && mkfs.fat -F 32 /src/build/syndrome.img && mmd -i /src/build/syndrome.img ::/EFI && mmd -i /src/build/syndrome.img ::/EFI/BOOT && mcopy -i /src/build/syndrome.img /src/build/SyndromeOS.efi ::/EFI/BOOT/BOOTX64.EFI && (cp /usr/share/ovmf/OVMF.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/OVMF/OVMF.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/OVMF/OVMF_CODE_4M.fd /src/build/ovmf.fd 2>/dev/null || true)"
    else
        write_step "2/4" "Checking native build toolchain..."
        MISSING_TOOLS=()
        for tool in cmake make gcc dd mkfs.fat mcopy mmd; do
            if ! command -v "$tool" >/dev/null 2>&1; then
                MISSING_TOOLS+=("$tool")
            fi
        done

        if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
            echo -e "\n${RED}[ERROR] Required build tools are missing: ${MISSING_TOOLS[*]}${NC}"
            echo -e "You can either:"
            echo -e "  1. Start Docker to build in a containerized environment, or"
            echo -e "  2. Install the native dependencies:"
            echo -e "     Ubuntu/Debian: ${CYAN}sudo apt install build-essential cmake gnu-efi dosfstools mtools${NC}"
            echo -e "     Fedora:        ${CYAN}sudo dnf install @development-tools cmake gnu-efi dosfstools mtools${NC}"
            echo -e "     Arch Linux:    ${CYAN}sudo pacman -S base-devel cmake gnu-efi dosfstools mtools${NC}"
            exit 1
        fi
        write_success "Native toolchain is ready."

        write_step "3/4" "Compiling SyndromeOS natively..."
        rm -rf "$WORKSPACE_ROOT/build"
        mkdir -p "$WORKSPACE_ROOT/build"
        cmake -S "$WORKSPACE_ROOT" -B "$WORKSPACE_ROOT/build"
        cmake --build "$WORKSPACE_ROOT/build"

        write_info "Generating FAT32 bootable image..."
        dd if=/dev/zero of="$DISK_IMAGE" bs=1M count=64 status=none
        mkfs.fat -F 32 "$DISK_IMAGE" >/dev/null
        mmd -i "$DISK_IMAGE" ::/EFI
        mmd -i "$DISK_IMAGE" ::/EFI/BOOT
        mcopy -i "$DISK_IMAGE" "$EFI_BINARY" ::/EFI/BOOT/BOOTX64.EFI
    fi

    if [ ! -f "$EFI_BINARY" ] || [ ! -f "$DISK_IMAGE" ]; then
        echo -e "\n${RED}[ERROR] Build failed. Artifacts were not generated.${NC}"
        exit 1
    fi
    write_success "SyndromeOS.efi built successfully."
    write_success "Bootable disk image ready: build/syndrome.img"
fi

# 3. Locate OVMF UEFI firmware
OVMF_PATH=""
OVMF_CANDIDATES=(
    "$WORKSPACE_ROOT/build/ovmf.fd"
    "/usr/share/OVMF/OVMF_CODE.fd"
    "/usr/share/OVMF/OVMF_CODE_4M.fd"
    "/usr/share/ovmf/OVMF.fd"
    "/usr/share/edk2/ovmf/OVMF_CODE.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
    "/usr/share/qemu/edk2-x86_64-code.fd"
    "/usr/share/qemu/OVMF.fd"
    "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
    "/usr/local/share/qemu/edk2-x86_64-code.fd"
)

for candidate in "${OVMF_CANDIDATES[@]}"; do
    if [ -f "$candidate" ]; then
        OVMF_PATH="$candidate"
        break
    fi
done

# If not found, try extracting from Docker container if available
if [ -z "$OVMF_PATH" ] && command -v docker >/dev/null 2>&1; then
    write_info "Extracting OVMF firmware from build container..."
    mkdir -p "$WORKSPACE_ROOT/build"
    docker run --rm -v "$WORKSPACE_ROOT:/src" syndromeos-build bash -c "cp /usr/share/ovmf/OVMF.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/OVMF/OVMF.fd /src/build/ovmf.fd 2>/dev/null || cp /usr/share/OVMF/OVMF_CODE_4M.fd /src/build/ovmf.fd 2>/dev/null || true"
    if [ -f "$WORKSPACE_ROOT/build/ovmf.fd" ]; then
        OVMF_PATH="$WORKSPACE_ROOT/build/ovmf.fd"
    fi
fi

if [ -z "$OVMF_PATH" ]; then
    echo -e "\n${RED}[ERROR] OVMF UEFI firmware was not found.${NC}"
    echo -e "Please install OVMF firmware using your package manager:"
    echo -e "  Ubuntu/Debian: ${CYAN}sudo apt install ovmf${NC}"
    echo -e "  Fedora:        ${CYAN}sudo dnf install edk2-ovmf${NC}"
    echo -e "  Arch Linux:    ${CYAN}sudo pacman -S edk2-ovmf${NC}"
    exit 1
fi
write_success "OVMF Firmware: $OVMF_PATH"

# 4. Launch QEMU
write_step "4/4" "Booting SyndromeOS in QEMU..."

QEMU_ARGS=(
    "-machine" "q35"
    "-m" "512M"
    "-drive" "if=pflash,format=raw,readonly=on,file=$OVMF_PATH"
    "-drive" "format=raw,file=$DISK_IMAGE"
)

if [ "$ENABLE_DEBUG" = true ]; then
    write_info "Debug mode active: listening on gdb:1234 (-s -S) and piping serial to stdio."
    QEMU_ARGS+=("-s" "-S" "-serial" "stdio")
fi

echo -e "\n  ${GREEN}-> Starting VM now...${NC}"
echo -e "${CYAN}==========================================================${NC}"

exec "$QEMU_BIN" "${QEMU_ARGS[@]}"
