#include "stdint.h"
#include "ttyio.h"
#include "bios.h"

extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::puts("INFO: Hello from the bootloader, stage 2!\r\n");
    ttyio::putd(69);

    bios_disk_read(1, 0x9000, 0, 0);
    ttyio::puts((char*)(0x9000 + 0xC5));
    

    for (;;)
    {
        // Halt
    }
}