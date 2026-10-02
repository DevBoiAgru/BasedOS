#include "ttyio.h"
#include "math.h"
#include "bios.h"


void ttyio::puts(char* str) {
    while (*str) {
        bios_putc(*str++);
    }
}

void ttyio::putd(uint16_t num) {
    uint16_t divisor = 10000;       // Highest power of 10 with same number of digits as uint16_max

    while (divisor > 0) {
        uint8_t digit = num / divisor;
        num %= divisor;
        divisor /= 10;

        if (digit || divisor == 0) {
            bios_putc('0' + digit);
        }
    }
}