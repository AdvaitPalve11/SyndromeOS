#include <efi.h>
#include <efilib.h>
#include "graphics.h"
#include "logo.h"

static BOOLEAN BrailleCellIsSet(CHAR16 Character) {
    return Character >= 0x2801 && Character <= 0x28FF;
}

static CHAR16 BraillePairToAscii(UINT8 Dots, UINT8 FirstBit, UINT8 SecondBit) {
    UINTN Count = 0;

    if ((Dots & (1 << FirstBit)) != 0) {
        Count++;
    }
    if ((Dots & (1 << SecondBit)) != 0) {
        Count++;
    }

    return Count == 2 ? L'#' : (Count == 1 ? L'.' : L' ');
}

static VOID PrintBrailleHalf(CHAR16 Character, UINTN Row) {
    UINT8 Dots;

    if (Character < 0x2800 || Character > 0x28FF) {
        Print(L"  ");
        return;
    }

    Dots = (UINT8)(Character - 0x2800);
    if (Row == 0) {
        Print(
            L"%c%c",
            BraillePairToAscii(Dots, 0, 1),
            BraillePairToAscii(Dots, 3, 4)
        );
        return;
    }

    Print(
        L"%c%c",
        BraillePairToAscii(Dots, 2, 6),
        BraillePairToAscii(Dots, 5, 7)
    );
}

VOID GraphicsDrawLogo(EFI_SYSTEM_TABLE *SystemTable) {
    UINTN RowCount = sizeof(syndromeos_logo) / sizeof(syndromeos_logo[0]);
    UINTN FirstColumn = 0xFFFFFFFF;
    UINTN LastColumn = 0;
    UINTN LogoWidth;
    UINTN Indent;

    uefi_call_wrapper(SystemTable->ConOut->ClearScreen, 1, SystemTable->ConOut);

    for (UINTN Row = 0; Row < RowCount; Row++) {
        UINTN Column = 0;

        while (syndromeos_logo[Row][Column] != L'\0') {
            if (BrailleCellIsSet(syndromeos_logo[Row][Column])) {
                if (Column < FirstColumn) {
                    FirstColumn = Column;
                }
                if (Column > LastColumn) {
                    LastColumn = Column;
                }
            }
            Column++;
        }
    }

    if (FirstColumn == 0xFFFFFFFF) {
        return;
    }

    LogoWidth = (LastColumn - FirstColumn + 1) * 2;
    Indent = LogoWidth < 80 ? (80 - LogoWidth) / 2 : 0;

    for (UINTN Row = 0; Row < RowCount; Row++) {
        for (UINTN Half = 0; Half < 2; Half++) {
            Print(L"\r\n");
            for (UINTN Column = 0; Column < Indent; Column++) {
                Print(L" ");
            }

            for (UINTN Column = FirstColumn; Column <= LastColumn; Column++) {
                PrintBrailleHalf(syndromeos_logo[Row][Column], Half);
            }
        }
    }
}