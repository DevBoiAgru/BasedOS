#include "stdint.h"
#include "ttyio.h"
#include "bios.h"

extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::putln("[BOOTLOADER - S2][INFO]: Hello from the bootloader, stage 2!");


    // Memory Layout (RAM):
    // 0x0000 - 0x7c00      - Stack for the bootloader
    // 0x7c00 - 0x7e00      - Stage 1 bootloader
    // 0x8000 - 0x8c00      - Stage 2 bootloader

    for (;;)
    {
        // Halt
    }
}