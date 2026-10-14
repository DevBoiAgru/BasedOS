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

// There is no 32 bit integer multiplication (atleast i couldnt find it) without having to link
// runtimes so gotta use this instead
template <typename T>
uint32_t u32_multiply(uint32_t a, T b) {
    uint32_t res = 0;
    for (T i = 0; i < b; i++) {
        res += a; 
    }
    return res;
}


} //namespace utils
