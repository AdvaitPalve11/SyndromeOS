#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

//write a byte to a port ( b = byte )
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

//read a byte from a port ( b = byte )
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

//write a word to a port (w = word)
static inline void outw(uint16_t port, uint16_t val) {
    __asm__ volatile("outw %0, %1" : : "a"(val), "Nd"(port));
}

//read a word from a port (w = word)
static inline uint16_t inw(uint16_t port) {
    uint16_t ret;
    __asm__ volatile("inw %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

//write a double word to a port (l = long/double word)
static inline void outl(uint16_t port, uint32_t val) {
    __asm__ volatile("outl %0, %1" : : "a"(val), "Nd"(port));
}

//read a double word from a port (l = long/double word)
static inline uint32_t inl(uint16_t port) {
    uint32_t ret;
    __asm__ volatile("inl %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}
    
//wait for a short time (busy wait)
static inline void io_wait(void) {
    outb(0x80, 0);
}

#ifdef __cplusplus
}
#endif
