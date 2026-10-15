#include "bootinfo.h"

// Set a single pixel in the 32-bit linear framebuffer (0x00RRGGBB)
static inline void put_pixel(const Framebuffer& fb, uint32_t x, uint32_t y, uint32_t color) {
    if (x >= fb.width || y >= fb.height) return;
    fb.base[y * fb.pitch + x] = color;
}

// Draw a filled colored box
void fill_rect(const Framebuffer& fb, uint32_t x, uint32_t y, uint32_t w, uint32_t h, uint32_t color) {
    for (uint32_t curr_y = y; curr_y < y + h; ++curr_y) {
        for (uint32_t curr_x = x; curr_x < x + w; ++curr_x) {
            put_pixel(fb, curr_x, curr_y, color);
        }
    }
}

// Pure bare-metal kernel entry point from entry.cpp
extern "C" void kernel_main(const BootInfo* boot_info){

    // discover where the physical screen pixels are located in RAM.
    const Framebuffer& fb = boot_info->fb;

    // Clear the entire display(0x001E293B)
    for (uint32_t y = 0; y < fb.height; ++y) {
        for (uint32_t x = 0; x < fb.width; ++x) {
            fb.base[y * fb.pitch + x] = 0x001E293B;
        }
    }

    // Halt the CPU and wait for interrupts
    while (true) {
        asm volatile("hlt");
    }
}