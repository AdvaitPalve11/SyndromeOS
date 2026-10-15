# SyndromeOS Root Makefile
.PHONY: all run run-fast debug native clean help

all: run

run:
	@if [ "$$(uname -s 2>/dev/null)" = "Linux" ] || [ "$$(uname -s 2>/dev/null)" = "Darwin" ]; then \
		chmod +x ./scripts/run.sh && ./scripts/run.sh; \
	else \
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/run.ps1; \
	fi

run-fast:
	@if [ "$$(uname -s 2>/dev/null)" = "Linux" ] || [ "$$(uname -s 2>/dev/null)" = "Darwin" ]; then \
		chmod +x ./scripts/run.sh && ./scripts/run.sh --skip-build; \
	else \
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/run.ps1 -SkipBuild; \
	fi

debug:
	@if [ "$$(uname -s 2>/dev/null)" = "Linux" ] || [ "$$(uname -s 2>/dev/null)" = "Darwin" ]; then \
		chmod +x ./scripts/run.sh && ./scripts/run.sh --debug; \
	else \
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/run.ps1 -EnableDebug; \
	fi

native:
	@if [ "$$(uname -s 2>/dev/null)" = "Linux" ] || [ "$$(uname -s 2>/dev/null)" = "Darwin" ]; then \
		chmod +x ./scripts/run.sh && ./scripts/run.sh --native; \
	else \
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./scripts/run.ps1; \
	fi

clean:
	@if [ -d "build" ]; then \
		rm -rf build/; \
		echo "Cleaned build directory."; \
	fi

help:
	@echo "SyndromeOS Makefile targets:"
	@echo "  make (or make run)   - Build and launch SyndromeOS in QEMU"
	@echo "  make run-fast        - Launch existing disk image without rebuilding"
	@echo "  make debug           - Launch QEMU with GDB stub on port 1234"
	@echo "  make native          - Build using host toolchain directly (Linux/macOS)"
	@echo "  make clean           - Remove build directory"
