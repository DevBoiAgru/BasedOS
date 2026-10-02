#include "bios.h"
#include "stdint.h"

void bios_puts(char* str) {
    while (*str) {
        bios_putc(*str++);
    }
}
