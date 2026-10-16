#include "stdint.h"
#include "ttyio.h"
#include "bios.h"
#include "fat.hpp"
#include "utils.hpp"


// This is the number of sectors left blank before the FAT32 volume
// it is where BasedOS keeps the bootloader (Both Stage 1 and 2)
const uint16_t NUMBER_BLANK_SECTORS = 2048;

extern "C" void __cdecl cstart_(uint16_t bootDrive) {
    (void)bootDrive;

    ttyio::putln("[BOOTLOADER - S2][INFO]: Hello from C++!");

    // Memory Layout (RAM):
    // 0x0000 - 0x7c00      - Stack for the bootloader
    // 0x7c00 - 0x7e00      - Stage 1 bootloader
    // 0x8000 - 0x8c00      - Stage 2 bootloader
    // 0x9000 - 0x9511      - BPB read from the disk
    // 0x9512 - Onwards     - Buffer for reading other stuff from disk

    uint16_t bpbDestAddr = 0x9000;
    // Read the BPB for information about the FAT32 volume
    bios::bios_disk_read(1, bpbDestAddr, 0x0000, NUMBER_BLANK_SECTORS);

    fat::BiosParameterBlock* BPB = reinterpret_cast<fat::BiosParameterBlock*>(bpbDestAddr);
    
    ttyio::putln("Disk information: ");
    ttyio::puts(" - Volume Label: ");
    ttyio::putsn((char*)BPB->VolumeLabelString, 11);
    ttyio::putln("");
    ttyio::puts(" - Volume OEM Identifier: ");
    ttyio::putsn((char*)BPB->OEMIdentifier, 8);
    ttyio::putln("");
    ttyio::puts(" - Sectors per cluster: ");
    ttyio::putd(BPB->SectorsPerCluster);
    ttyio::putln("");
    ttyio::puts(" - Drive number: ");
    ttyio::putd(BPB->DriveNumber);
    ttyio::putln("");

    // Our disc format:
    // LBA 0                                    - MBR (Stage 1 BL etc)
    // LBA 1 - 6                                - Stage 2 BL
    // LBA 7 - NUMBER_BLANK_SECTORS - 1         - Empty?? Free space for bootloader or misc stuff
    // LBA NUMBER_BLANK_SECTORS - onwards       - FAT32 Volume
    // FAT32 Structure:
    //     - Reserved sectors
    //     - FAT Tables
    //     - Data region

    // Calculate the address for the first FAT table (Assume its the main one)
    uint32_t FirstFAT_LBA = (NUMBER_BLANK_SECTORS + utils::u8_to_u16_le(BPB->NumReservedSectors));

    // Address just after the FAT tables (Data portion)
    uint32_t Data_LBA = FirstFAT_LBA + utils::u32_multiply(
        utils::u8_to_u32_le(BPB->SectorsPerFAT32),
        BPB->NumberOfFAT
    );

    uint32_t ROOT_LBA = fat::ClusterToLBA(utils::u8_to_u32_le(BPB->RootDirectoryClusterNum), Data_LBA, BPB);

    uint8_t sectorsPerFAT16B[2] = {BPB->SectorsPerFAT32[0], BPB->SectorsPerFAT32[1]};
    // Read the root directory clusters
    bios::bios_disk_read(utils::u8_to_u16_le(sectorsPerFAT16B), 0x9512, 0, ROOT_LBA);



    // fat::ClusterToLBA(1);
    

    for (;;)
    {
        // Halt
    }
}