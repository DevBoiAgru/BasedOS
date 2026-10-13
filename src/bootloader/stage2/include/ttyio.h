#pragma once
#include "stdint.h"


namespace ttyio {

void puts(char* str);
void putc(char ch);
void putln(char* str);

// Only print a specific number of characters
void putsn(char* str, uint16_t n);
void putd(uint16_t n);

} // namespace ttyio