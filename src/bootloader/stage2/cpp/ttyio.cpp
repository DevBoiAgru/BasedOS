#include "ttyio.h"
#include "math.h"
#include "bios.h"


void ttyio::putc(char ch) {
    bios::bios_putc(ch);
}

void ttyio::puts(char* str) {
    while (*str) {
        bios::bios_putc(*str++);
    }
}

void ttyio::putln(char* str) {
    while (*str) {
        bios::bios_putc(*str++);
    }
    bios::bios_putc('\r');
    bios::bios_putc('\n');
}

void ttyio::putsn(char* str, uint16_t n) {
    for (uint16_t i = 0; i < n; i++) {
        bios::bios_putc(str[i]);
    }
}

void ttyio::putd(uint16_t num) {
    uint16_t divisor = 10000;       // Highest power of 10 with same number of digits as uint16_max

    while (divisor > 0) {
        uint8_t digit = num / divisor;
        num %= divisor;
        divisor /= 10;

        if (digit || divisor == 0) {
            bios::bios_putc('0' + digit);
        }
    }
}