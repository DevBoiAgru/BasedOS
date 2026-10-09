#include "stdint.h"
#include "ttyio.h"
#include "bios.h"

extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::puts("[BOOTLOADER - S2][INFO]: Hello from the bootloader, stage 2!\r\n");

    

    for (;;)
    {
        // Halt
    }
}