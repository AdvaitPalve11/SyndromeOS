#pragma once
#include <stdint.h>

#define PIT_BASE_FREQUENCY 1193182
#define PIT_CHANNEL0_DATA  0x40
#define PIT_CHANNEL1_DATA  0x41
#define PIT_CHANNEL2_DATA  0x42
#define PIT_COMMAND_PORT   0x43


void pit_init(uint32_t frequency);
void pit_sleep_ms(uint32_t ms);
uint64_t timer_get_ms();
