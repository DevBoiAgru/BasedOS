#include "stdint.h"
#include "ttyio.h"
#include "bios.h"
#include "fat.hpp"
#include "utils.hpp"

extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::putln("[BOOTLOADER - S2][INFO]: Hello from the bootloader, stage 2!");

    // Memory Layout (RAM):
    // 0x0000 - 0x7c00      - Stack for the bootloader
    // 0x7c00 - 0x7e00      - Stage 1 bootloader
    // 0x8000 - 0x8c00      - Stage 2 bootloader
    // 0x9000 - Onwards     - Buffer for disk reading

    uint16_t diskDestAddr = 0x9000;
    // Read the BPB for information about the FAT32 volume
    bios::bios_disk_read(1, diskDestAddr, 0x0000, 2048);

    fat::BiosParameterBlock* BPB = reinterpret_cast<fat::BiosParameterBlock*>(diskDestAddr);
    
    ttyio::puts("Volume OEM Identifier: ");
    ttyio::putsn((char*)BPB->OEMIdentifier, 8);
    ttyio::putln("");
    ttyio::puts("Volume Label: ");
    ttyio::putsn((char*)BPB->VolumeLabelString, 11);
    ttyio::putln("");
    

    for (;;)
    {
        // Halt
    }
}