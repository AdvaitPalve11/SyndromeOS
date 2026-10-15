#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Framebuffer {
    uint32_t* base;
    uint64_t  size;
    uint32_t  width;
    uint32_t  height;
    uint32_t  pitch;
} Framebuffer;

typedef struct BootInfo {
    Framebuffer fb;
} BootInfo;

#ifdef __cplusplus
}
#endif
