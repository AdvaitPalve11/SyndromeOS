#include <efi.h>
#include <efilib.h>
#include "../graphics/graphics.h"

EFI_STATUS EFIAPI efi_main(
    EFI_HANDLE ImageHandle,
    EFI_SYSTEM_TABLE *SystemTable
) {
    InitializeLib(ImageHandle, SystemTable);
    GraphicsDrawLogo(SystemTable);

    Print(L"\r\n");
    Print(L"Architecture : x86_64\r\n");
    Print(L"Boot mode    : UEFI\r\n");
    Print(L"\r\n");
    Print(L"Press any key to exit...\r\n");

    WaitForSingleEvent(
        SystemTable->ConIn->WaitForKey,
        0
    );

    return EFI_SUCCESS;
}