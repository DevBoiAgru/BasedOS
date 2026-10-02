#include "stdint.h"
#include "bios.h"


extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    bios_puts("INFO: Hello from the bootloader, stage 2!\r\n");

    for (;;)
    {
        // Wait here
    }
}