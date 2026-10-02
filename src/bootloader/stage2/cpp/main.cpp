#include "stdint.h"
#include "ttyio.h"


extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::puts("INFO: Hello from the bootloader, stage 2!\r\n");
    ttyio::putd(69);


    for (;;)
    {
        // Halt
    }
}