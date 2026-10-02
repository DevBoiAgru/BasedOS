#pragma once
#include "stdint.h"


namespace math {

template <typename T>
T pow(T num, uint8_t exp) {
    T res = 1;
    for (uint8_t i = 0; i < exp; i++) {
        res = res * num; 
    }
    return res;
}

} //namespace math