#include "pit.h"
#include "io.h"

//Programmable Interval Timer

void pit_init(uint32_t frequency){

    if (frequency == 0) return;

    uint32_t divisor = PIT_BASE_FREQUENCY / frequency;
    if (divisor > 65535) divisor = 65535;
    if (divisor < 1) divisor = 1;

    // Command byte: Channel 0, access mode low/high byte, Mode 3 (square wave), binary 16-bit
    outb(PIT_COMMAND_PORT, 0x36);
    io_wait();
    outb(PIT_CHANNEL0_DATA, (uint8_t)(divisor & 0xFF));
    io_wait();
    outb(PIT_CHANNEL0_DATA, (uint8_t)((divisor >> 8) & 0xFF));

}

void pit_sleep_ms(uint32_t ms) {
    // Channel 2 one-shot polling delay using PIT oscillator ticks
    // Each millisecond corresponds to approximately 1193 ticks
    for (uint32_t i = 0; i < ms; ++i) {
        // Channel 2, mode 0 (interrupt on terminal count), binary
        outb(PIT_COMMAND_PORT, 0xB0);
        outb(PIT_CHANNEL2_DATA, (uint8_t)(1193 & 0xFF));
        outb(PIT_CHANNEL2_DATA, (uint8_t)((1193 >> 8) & 0xFF));

        // Reset gate
        uint8_t gate = inb(0x61);
        outb(0x61, (gate & ~1));
        outb(0x61, (gate | 1));

        // Poll until output bit goes high (bit 5 of port 0x61)
        while ((inb(0x61) & 0x20) == 0) {
            __asm__ volatile("pause");
        }
    }
}
