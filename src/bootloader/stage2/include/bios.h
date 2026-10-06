#pragma once

extern "C" void __cdecl bios_putc(char c);
extern "C" void __cdecl bios_disk_read(uint16_t sectorsNum, uint16_t destinationOffset, uint16_t destinationSegment, uint64_t LBA);

void bios_puts(char* str);