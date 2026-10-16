extern "C" {
#include <efi.h>
#include <efilib.h>
}
#include "../graphics/graphics.h"
#include "../../kernel/bootinfo.h"

#define EFI_STR(s) ((CHAR16*)(s))

extern "C" void kernel_main(const BootInfo* boot_info);

extern "C" EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable){

    InitializeLib(ImageHandle, SystemTable);

    // Draw ASCII logo in UEFI text mode
    GraphicsDrawLogo(SystemTable);

    //print basic bootloader details
    Print(EFI_STR(L"\r\n"));
    Print(EFI_STR(L"SyndromeOS Bootloader\r\n"));
    Print(EFI_STR(L"Architecture : x86_64\r\n"));
    Print(EFI_STR(L"Firmware : UEFI 2.x\r\n"));
    Print(EFI_STR(L"Locating GOP (Graphics Output Protocol)\r\n"));

    // Query GOP for linear framebuffer
    EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gop = nullptr;

    EFI_STATUS status = uefi_call_wrapper((void*)SystemTable->BootServices->LocateProtocol, 3, &gopGuid, NULL, (void**)&gop);

    if (EFI_ERROR(status) || gop == nullptr || gop->Mode == nullptr || gop->Mode->Info == nullptr) {
        Print(EFI_STR(L"ERROR Failed to locate GOP: %r\r\n"), status);
        Print(EFI_STR(L"Press any key to exit: \r\n"));
        WaitForSingleEvent(SystemTable->ConIn->WaitForKey, 0);
        return status;
    }

    Print(EFI_STR(L"GOP Resolution : %ux%u (PixelsPerScanLine: %u)\r\n"),
          gop->Mode->Info->HorizontalResolution,
          gop->Mode->Info->VerticalResolution,
          gop->Mode->Info->PixelsPerScanLine);

    Print(EFI_STR(L"Framebuffer : 0x%lx (Size: %lu bytes)\r\n"),
          gop->Mode->FrameBufferBase,
          gop->Mode->FrameBufferSize);

    // Prepare BootInfo structure for kernel handoff
    BootInfo boot_info;
    boot_info.fb.base   = (uint32_t*)(uintptr_t)gop->Mode->FrameBufferBase;
    boot_info.fb.size   = (uint64_t)gop->Mode->FrameBufferSize;
    boot_info.fb.width  = gop->Mode->Info->HorizontalResolution;
    boot_info.fb.height = gop->Mode->Info->VerticalResolution;
    boot_info.fb.pitch  = gop->Mode->Info->PixelsPerScanLine;

    Print(EFI_STR(L"Booting kernel in 1 second...\r\n"));
    uefi_call_wrapper((void*)SystemTable->BootServices->Stall, 1, 1000000);

    // Terminate UEFI Boot Services (Long Mode handoff)
    UINTN memMapSize = 0;
    EFI_MEMORY_DESCRIPTOR *memMap = nullptr;
    UINTN mapKey = 0;
    UINTN descriptorSize = 0;
    UINT32 descriptorVersion = 0;

    status = uefi_call_wrapper((void*)SystemTable->BootServices->GetMemoryMap, 5, &memMapSize, memMap, &mapKey, &descriptorSize, &descriptorVersion);

    memMapSize += 4 * descriptorSize;
    status = uefi_call_wrapper((void*)SystemTable->BootServices->AllocatePool, 3, EfiLoaderData, memMapSize, (void**)&memMap);

    if (!EFI_ERROR(status)) {
        status = uefi_call_wrapper((void*)SystemTable->BootServices->GetMemoryMap, 5, &memMapSize, memMap, &mapKey, &descriptorSize, &descriptorVersion);
        if (!EFI_ERROR(status)) {
            status = uefi_call_wrapper((void*)SystemTable->BootServices->ExitBootServices, 2, ImageHandle, mapKey);
            if (EFI_ERROR(status)) {
                // Map key can change if an interrupt occurred, retry once
                status = uefi_call_wrapper((void*)SystemTable->BootServices->GetMemoryMap, 5, &memMapSize, memMap, &mapKey, &descriptorSize, &descriptorVersion);
                if (!EFI_ERROR(status)) {
                    uefi_call_wrapper((void*)SystemTable->BootServices->ExitBootServices, 2, ImageHandle, mapKey);
                }
            }
        }
    }

    // Jump into bare-metal kernel
    kernel_main(&boot_info);

    return EFI_SUCCESS;
}
