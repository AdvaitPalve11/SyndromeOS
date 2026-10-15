#include <iostream>
#include <stdint.h>

typedef uint64_t UINT;
typedef void* EFI_HADLE;
typedef UINT EFI_STATUS;

#define EFI_SUCCESS 0

struct EFI_GUID{

    uint32_t Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t Data4[8];
};

struct EFI_TABLE_HEADER{
    uint64_t Signature;
    uint32_t Revision;
    uint32_t HeaderSize;
    uint32_t CRC32;
    uint32_t Reserved;
};


