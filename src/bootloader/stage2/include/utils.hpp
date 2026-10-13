#pragma once

#include "stdint.h"


namespace utils {

// Convert a 2 element array of uint8s in little endian to a uint16
inline uint16_t u8_to_u16_le(const uint8_t* arr) {
    uint16_t res = 0;
    res = arr[1];
    res <<= 8;
    res |= arr[0];
    return res;
}

// Convert a 4 element array of uint8s in little endian to a uint32
inline uint32_t u8_to_u32_le(const uint8_t* arr) {
    uint32_t res = 0;
    res = arr[3];
    res <<= 8;
    res |= arr[2];
    
    res <<= 8;
    res |= arr[1];
    
    res <<= 8;
    res |= arr[0];

    return res;
}


} //namespace utils
