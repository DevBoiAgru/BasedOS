#pragma once

#include "stdint.h"
#include "bios.h"



namespace fat {


#pragma pack(1)

struct BiosParameterBlock {
    uint8_t JumpInst[3];
    uint8_t OEMIdentifier[8];
    uint8_t BytesPerSector[2];
    uint8_t SectorsPerCluster;
    uint8_t NumReservedSectors[2];
    uint8_t NumberOfFAT;
    uint8_t NumRootDirectoryEntries[2];
    uint8_t SectorsCountSMALL[2];
    uint8_t MediaDescriptorType;
    uint8_t NumberOfSectorsPerFAT1216[2];
    uint8_t NumberOfSectorsPerTrack[2];
    uint8_t NumberOfHeadsInMedia[2];
    uint8_t NumberOfHiddenSectors[2];
    uint8_t SectorCountLARGE[4];

    // FAT32 specific fields
    uint8_t SectorsPerFAT32[4];
    uint8_t Flags[2];
    uint8_t FATVersionNumber[2];
    uint8_t RootDirectoryClusterNum[4];
    uint8_t FSInfoStructSectorNum[2];
    uint8_t BackupBootSectorNum[2];
    uint8_t RESERVED[12];
    uint8_t DriveNumber;
    uint8_t WinNTFlags;
    uint8_t Signature;
    uint8_t VolumeIDSerialNum[4];
    uint8_t VolumeLabelString[11];
    uint8_t SystemIdString[8];
    uint8_t BootCode[420];
    uint8_t BootSignature[2];
};


struct FSInfo {
    uint8_t LeadSignature[4];
    uint8_t RESERVED[480];
    uint8_t Signature2[4];
    uint8_t LastFreeClusterCount[4];
    uint8_t AvailableClusterHint[4];
    uint8_t RESERVED2[12];
    uint8_t Signature3[4];
};

#pragma pack()





} //namespace fat