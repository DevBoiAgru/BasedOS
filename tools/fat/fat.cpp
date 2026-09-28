#include <cstdio>
#include <cstdint>
#include <cstring>
#include <fstream>

struct [[gnu::packed]] BootSector {
    uint8_t BootJumpInstruction[3];
    uint8_t OEMIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FATCount;
    uint16_t DirectoryEntriesCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptorType;
    uint16_t SectorsPerFAT;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;


    // extended boot record
    uint8_t EBRDriveNumber;
    uint8_t ReservedByte;
    uint8_t EBRSignature;
    uint32_t EBRVolumeID;
    uint8_t EBRVolumeLabel[11];
    uint8_t EBRSystemID[8];

    // Code starts
};

struct [[gnu::packed]] DirectoryEntry {
    uint8_t FileName[11];
    uint8_t Attributes;
    uint8_t _Reserved;
    uint8_t CreationTimeHundredths;
    uint16_t CreationTime;
    uint16_t CreationDate;
    uint16_t LastAccessedDate;
    uint16_t FirstClusterHigh;
    uint16_t LastModifiedTime;
    uint16_t LastModifiedDate;
    uint16_t FirstClusterLow;
    uint32_t FileSize;
};

BootSector g_BootSector;
uint8_t* g_FAT;
DirectoryEntry* g_RootDir;


void readBootSector(std::ifstream& file) {
    file.read(&g_BootSector, sizeof(BootSector));
}

void diskRead(std::ifstream& disk, uint32_t lba, uint8_t sectorCount, void* buffer) {
    uint32_t addr = lba * g_BootSector.BytesPerSector;

    disk.seekg(addr);
    disk.read(buffer, sectorCount * g_BootSector.BytesPerSector);
}

void readFAT(std::ifstream& disk) {
    g_FAT = new uint8_t[g_BootSector.SectorsPerFAT * g_BootSector.BytesPerSector];
    diskRead(disk, g_BootSector.ReservedSectors, 1, g_FAT);
}

void readRootDir(std::ifstream& disk) {
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.SectorsPerFAT * g_BootSector.BytesPerSector;
    uint32_t size = sizeof(DirectoryEntry) * g_BootSector.DirectoryEntriesCount;
    uint32_t sectors = (size / g_BootSector.BytesPerSector);
    if (size % g_BootSector.BytesPerSector > 0) {
        sectors++;
    }

    g_RootDir = (DirectoryEntry*)malloc(sectors * g_BootSector.BytesPerSector);
    diskRead(disk, lba, sectors,g_RootDir);

}

DirectoryEntry* readFile(const char* name) {
    for (uint32_t i = 0; i < g_BootSector.DirectoryEntriesCount; i++) {
        if (memcmp(name, g_RootDir[i].FileName, 11) == 0) {
            return &g_RootDir[i];
        }
    } return nullptr;
}

int main(int argc, char* argv[]) {
    if (argc < 4) {
        printf("Syntax: %s <disk image> <file name>\n", argv[0]);
        return -1;
    }

    std::ifstream diskImg(argv[1]);

    readBootSector(diskImg);
    readFAT(diskImg);
    readRootDir(diskImg);

    DirectoryEntry* fileEntry = readFile(argv[2]);
    if (!fileEntry) {
        printf("File %s not found.\n", argv[2]);
    }

    delete g_FAT;
}
